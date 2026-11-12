-- DEV ONLY PHASE 7A: fail chronicle at verified chapter terminal,
-- not only at final CHRONICLE_TERMINAL. Previous valid chapter rewards,
-- living PCs and any already earned prior chronicle honors remain untouched.

create or replace function trpg_hq.guard_chronicle_terminal_failure()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_mission trpg_hq.hq_missions%rowtype;
  v_doc jsonb;
  v_dead boolean;
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
  select exists(
    select 1 from jsonb_each(v_doc->'pcs') p(pc_key,pc_value)
    join trpg_cards.campaign_members cm
      on cm.campaign_id=v_mission.campaign_id
       and p.pc_value->>'player_id'=cm.player_id::text
    where p.pc_value->'alive'='false'::jsonb
  ) into v_dead;
  if v_dead and new.terminal_status<>'failed' then
    raise exception 'hq_chronicle_verified_death_requires_failed_terminal';
  end if;
  if new.terminal_status='failed' or v_dead then
    update trpg_hq.hq_missions set status='failed'
      where mission_id=v_mission.mission_id and status<>'failed';
  end if;
  return new;
end $hq$;

create trigger hq_chronicle_terminal_failure_guard
 before update of status on trpg_hq.hq_mission_segments
 for each row execute function trpg_hq.guard_chronicle_terminal_failure();

create or replace function trpg_hq.guard_chronicle_failed_mission_sticky()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
begin
  if old.mission_scale='chronicle'
    and old.status='failed' and new.status<>'failed' then
    raise exception 'hq_chronicle_failed_mission_cannot_reactivate';
  end if;
  return new;
end $hq$;

create trigger hq_chronicle_failed_mission_sticky
 before update of status on trpg_hq.hq_missions
 for each row execute function trpg_hq.guard_chronicle_failed_mission_sticky();

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
