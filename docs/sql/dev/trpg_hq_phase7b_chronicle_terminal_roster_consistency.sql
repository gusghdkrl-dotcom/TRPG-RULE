-- DEV ONLY PHASE 7B: reject internally inconsistent verified chronicle
-- chapter/final evidence before HQ mission status or any reward is written.
-- The checkpoint itself remains immutable; the Keeper must resolve the
-- contradiction in the legitimate save/finalization workflow.

create or replace function trpg_hq.guard_chronicle_terminal_failure()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_mission trpg_hq.hq_missions%rowtype;
  v_doc jsonb;
  v_dead boolean;
  v_enrolled uuid[];
  v_checkpoint_pc_count integer;
begin
  if old.status is not distinct from new.status
    or new.status<>'terminal_confirmed'
    or old.status<>'field_active' then
    return new;
  end if;
  select * into v_mission from trpg_hq.hq_missions
    where mission_id=new.mission_id for update;
  if v_mission.mission_scale<>'chronicle' then
    return new;
  end if;
  select c.state_json::jsonb into v_doc
  from public.gm_checkpoint_history c
  where c.session_id=new.session_id
    and c.version=new.verified_checkpoint_version
    and c.state_sha256=new.verified_state_sha256
    and c.status='verified'
    and encode(sha256(convert_to(c.state_json,'UTF8')),'hex')
      =c.state_sha256;
  if v_doc is null
    or v_doc->'runtime'->'ending_state' is distinct from new.terminal_result
    or jsonb_typeof(v_doc->'pcs') is distinct from 'object' then
    raise exception 'hq_chronicle_terminal_checkpoint_not_verifiable';
  end if;
  select array_agg(cm.player_id order by cm.player_id)
    into v_enrolled from trpg_cards.campaign_members cm
    where cm.campaign_id=v_mission.campaign_id;
  select count(*) into v_checkpoint_pc_count from jsonb_each(v_doc->'pcs');
  if cardinality(v_enrolled) not between 1 and 3
    or v_checkpoint_pc_count is distinct from cardinality(v_enrolled)
    or exists(
      select 1 from unnest(v_enrolled) a(id)
      where (select count(*) from jsonb_each(v_doc->'pcs') p(pc_key,pc_value)
        where p.pc_value->>'player_id'=a.id::text
          and jsonb_typeof(p.pc_value->'alive')='boolean')<>1
    ) then
    raise exception 'hq_chronicle_checkpoint_pc_roster_invalid';
  end if;
  if exists(
    select 1 from unnest(new.returning_agent_ids) r(id)
    where not exists(
      select 1 from jsonb_each(v_doc->'pcs') p(pc_key,pc_value)
      where p.pc_value->>'player_id'=r.id::text
        and p.pc_value->'alive'='true'::jsonb)
  ) then
    raise exception 'hq_chronicle_returning_agent_not_alive';
  end if;
  select exists(
    select 1 from jsonb_each(v_doc->'pcs') p(pc_key,pc_value)
    where p.pc_value->'alive'='false'::jsonb
  ) into v_dead;
  if v_dead and new.terminal_status<>'failed' then
    raise exception 'hq_chronicle_verified_death_requires_failed_terminal';
  end if;
  if new.terminal_scope='CHRONICLE_TERMINAL'
    and new.terminal_status='completed'
    and v_enrolled is distinct from
      (select array_agg(x.id order by x.id)
         from unnest(new.returning_agent_ids) x(id)) then
    raise exception 'hq_chronicle_final_success_requires_all_returned';
  end if;
  if new.terminal_status='failed' or v_dead then
    update trpg_hq.hq_missions set status='failed'
      where mission_id=v_mission.mission_id and status<>'failed';
  end if;
  return new;
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
