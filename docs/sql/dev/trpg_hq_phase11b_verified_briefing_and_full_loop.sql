-- DEV ONLY / TIME AGENT HQ PHASE 11B
-- Verified field PC/card loadout + private world canon + Martin's actual briefing
-- -> explicit player-authorized Jayden departure.
-- Reuses existing verified return, Martin evaluation, Clara and Dominic handlers.

create table trpg_hq.hq_martin_briefings (
 segment_id uuid primary key references trpg_hq.hq_mission_segments(segment_id)
   on delete restrict,
 team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
 canon_id text not null,
 canon_revision integer not null check(canon_revision>=1),
 canon_file_sha256 text not null check(canon_file_sha256 ~ '^[0-9a-f]{64}$'),
 objective_sha256 text not null check(objective_sha256 ~ '^[0-9a-f]{64}$'),
 actual_public_briefing text not null
   check(char_length(actual_public_briefing) between 1 and 3000),
 briefed_at_hq_minute bigint not null check(briefed_at_hq_minute>=0),
 briefing_event_key text not null unique,
 created_at timestamptz not null default now()
);
alter table trpg_hq.hq_martin_briefings enable row level security;
revoke all on trpg_hq.hq_martin_briefings from public,anon,authenticated;

create or replace function trpg_hq.hq_field_preflight(
 p_segment_id uuid
) returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
declare
 s trpg_hq.hq_mission_segments%rowtype;
 m trpg_hq.hq_missions%rowtype;
 v_team uuid;
 v_members integer;
 v_linked integer;
 v_loadouts integer;
 v_uninducted integer;
 v_canon_count integer;
 v_latest_canon trpg_private.gm_canon_documents%rowtype;
 v_brief trpg_hq.hq_martin_briefings%rowtype;
 v_reasons jsonb:='[]'::jsonb;
begin
 select * into s from trpg_hq.hq_mission_segments
    where segment_id=p_segment_id;
 if not found then raise exception 'hq_field_segment_not_found';end if;
 select * into m from trpg_hq.hq_missions where mission_id=s.mission_id;
 v_team:=m.team_id;
 select count(*) into v_members from trpg_hq.hq_team_members tm
   where tm.team_id=v_team and tm.left_at_minutes is null;
 if v_members not between 1 and 3 then
   v_reasons:=v_reasons||'"invalid_active_team_size"'::jsonb;end if;
 select count(*) into v_uninducted
   from trpg_hq.hq_team_members tm
   where tm.team_id=v_team and tm.left_at_minutes is null
      and not exists(select 1 from trpg_hq.hq_agent_inductions i
         where i.agent_id=tm.agent_id)
      and not exists(select 1 from trpg_hq.hq_missions previous
          join trpg_cards.campaign_members cm on cm.campaign_id=previous.campaign_id
          where cm.player_id=tm.agent_id and previous.status='completed');
 if v_uninducted>0 then
   v_reasons:=v_reasons||'"first_induction_not_recorded"'::jsonb;end if;
 select count(*) into v_linked from trpg_cards.character_links cl
    join trpg_hq.hq_team_members tm
      on tm.agent_id=cl.player_id and tm.team_id=v_team
        and tm.left_at_minutes is null
    where cl.campaign_id=m.campaign_id;
 if v_linked<>v_members then
   v_reasons:=v_reasons||'"field_characters_not_all_linked"'::jsonb;end if;
 select count(*) into v_loadouts from trpg_cards.loadouts l
    join trpg_hq.hq_team_members tm on tm.agent_id=l.player_id
     and tm.team_id=v_team and tm.left_at_minutes is null
    where l.campaign_id=m.campaign_id and l.boundary_key='start';
 if v_loadouts<>v_members then
    v_reasons:=v_reasons||'"initial_card_loadouts_not_all_saved"'::jsonb;end if;
 select * into v_latest_canon from trpg_private.gm_canon_documents c
   where c.campaign_id=m.campaign_id
   order by c.revision desc,c.created_at desc,c.canon_id limit 1;
 if v_latest_canon.canon_id is null then
    v_reasons:=v_reasons||'"private_world_canon_missing"'::jsonb;
 else
   if encode(sha256(convert_to(v_latest_canon.content_md,'UTF8')),'hex')
      is distinct from v_latest_canon.file_sha256 then
      v_reasons:=v_reasons||'"private_world_canon_hash_mismatch"'::jsonb;
   end if;
 end if;
 select * into v_brief from trpg_hq.hq_martin_briefings where segment_id=p_segment_id;
 if v_brief.segment_id is null then
   v_reasons:=v_reasons||'"martin_formal_briefing_not_recorded"'::jsonb;
 elsif v_brief.canon_id is distinct from v_latest_canon.canon_id
    or v_brief.canon_revision is distinct from v_latest_canon.revision
    or v_brief.canon_file_sha256 is distinct from v_latest_canon.file_sha256
    or v_brief.objective_sha256 is distinct from
       encode(sha256(convert_to(m.preassigned_objectives::text,'UTF8')),'hex')
 then
   v_reasons:=v_reasons||'"martin_briefing_or_world_version_stale"'::jsonb;
 end if;
 if s.status not in ('prepared','field_active') or
   m.status not in ('preparing','field_active') then
   v_reasons:=v_reasons||'"segment_not_in_departure_state"'::jsonb;end if;
 return jsonb_build_object('team_id',v_team,'mission_id',m.mission_id,
   'segment_id',p_segment_id,'segment_status',s.status,
   'active_members',v_members,'linked_field_characters',v_linked,
   'saved_initial_loadouts',v_loadouts,
   'uninducted_new_agents',v_uninducted,
   'canon_present',v_latest_canon.canon_id is not null,
   'formal_briefing_recorded',v_brief.segment_id is not null,
   'ready_for_explicit_departure',jsonb_array_length(v_reasons)=0,
   'missing_or_conflicting_preconditions',v_reasons);
end $hq$;

-- Confirmation records that an actual Martin briefing was already delivered.
-- It is NOT an AI-generated line or permission/decision by any player.
create or replace function trpg_hq.record_martin_formal_briefing(
 p_segment_id uuid,p_canon_id text,p_canon_revision integer,
 p_actual_public_summary text,p_expected_revision bigint,p_elapsed_minutes bigint
) returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
 s trpg_hq.hq_mission_segments%rowtype;
 m trpg_hq.hq_missions%rowtype;
 t trpg_hq.hq_teams%rowtype;
 c trpg_private.gm_canon_documents%rowtype;
 old trpg_hq.hq_martin_briefings%rowtype;
 v_hash text;
 v_event text;
 v_check jsonb;
 v_count integer;
 v_next bigint;
 v_payload jsonb;
begin
 if p_canon_id is null or char_length(btrim(p_canon_id))=0
   or p_canon_revision is null or p_canon_revision<1
   or p_actual_public_summary is null
   or char_length(btrim(p_actual_public_summary)) not between 1 and 3000
   or p_elapsed_minutes is null or p_elapsed_minutes<0
   then raise exception 'hq_formal_briefing_invalid_request';end if;
 select * into s from trpg_hq.hq_mission_segments where segment_id=p_segment_id;
 if not found then raise exception 'hq_field_segment_not_found';end if;
 select * into m from trpg_hq.hq_missions where mission_id=s.mission_id;
 select * into t from trpg_hq.hq_teams where team_id=m.team_id for update;
 if s.status<>'prepared' or m.status not in ('preparing','field_active')
   then raise exception 'hq_formal_briefing_requires_prepared_segment';end if;
 select * into c from trpg_private.gm_canon_documents
  where campaign_id=m.campaign_id and canon_id=p_canon_id
   and revision=p_canon_revision;
 if not found or
     exists(select 1 from trpg_private.gm_canon_documents newer
       where newer.campaign_id=m.campaign_id and newer.revision>p_canon_revision)
   or encode(sha256(convert_to(c.content_md,'UTF8')),'hex')
     is distinct from c.file_sha256 then
   raise exception 'hq_formal_briefing_requires_latest_verified_private_canon';end if;
 v_hash:=encode(sha256(convert_to(m.preassigned_objectives::text,'UTF8')),'hex');
 select * into old from trpg_hq.hq_martin_briefings where segment_id=p_segment_id;
 if found then
   if old.canon_id is distinct from p_canon_id
     or old.canon_revision is distinct from p_canon_revision
     or old.canon_file_sha256 is distinct from c.file_sha256
     or old.objective_sha256 is distinct from v_hash
     or old.actual_public_briefing is distinct from p_actual_public_summary then
       raise exception 'hq_formal_briefing_replay_conflict';end if;
   return jsonb_build_object('applied',false,
     'current_revision',t.revision,'segment_id',p_segment_id);
 end if;
 if p_expected_revision is distinct from t.revision then
   raise exception 'hq_revision_conflict_expected_%_actual_%',
     p_expected_revision,t.revision;end if;
 -- A concrete PC for EACH enrolled player and confirmed original loadout.
 select count(*) into v_count from trpg_hq.hq_team_members tm
   where tm.team_id=m.team_id and tm.left_at_minutes is null
     and exists(select 1 from trpg_cards.character_links cl
       where cl.player_id=tm.agent_id and cl.campaign_id=m.campaign_id)
     and exists(select 1 from trpg_cards.loadouts l
       where l.player_id=tm.agent_id and l.campaign_id=m.campaign_id
         and l.boundary_key='start')
     and (exists(select 1 from trpg_hq.hq_agent_inductions i
        where i.agent_id=tm.agent_id)
       or exists(select 1 from trpg_hq.hq_missions previous
         join trpg_cards.campaign_members cm on cm.campaign_id=previous.campaign_id
          where cm.player_id=tm.agent_id and previous.status='completed'));
 if v_count<>(select count(*) from trpg_hq.hq_team_members tm
       where tm.team_id=m.team_id and tm.left_at_minutes is null) then
   raise exception 'hq_formal_briefing_missing_field_setup_or_entry';end if;
 v_event:='segment:'||p_segment_id::text||':martin-briefing';
 v_next:=t.hq_elapsed_minutes+p_elapsed_minutes;
 insert into trpg_hq.hq_martin_briefings(segment_id,team_id,
   canon_id,canon_revision,canon_file_sha256,objective_sha256,
   actual_public_briefing,briefed_at_hq_minute,briefing_event_key)
 values(p_segment_id,m.team_id,p_canon_id,p_canon_revision,
   c.file_sha256,v_hash,p_actual_public_summary,v_next,v_event);
 v_payload:=jsonb_build_object('mission_id',m.mission_id,
   'segment_id',p_segment_id,'canon_id',p_canon_id,
   'canon_revision',p_canon_revision,'public_summary',p_actual_public_summary);
 insert into trpg_hq.hq_events(team_id,event_key,event_kind,
   hq_minute,actor_key,listened_by,audience,summary,event_data,request_sha256)
 values(m.team_id,v_event,'martin_formal_briefing',
    v_next,'npc:martin','[]'::jsonb,'[]'::jsonb,
    '검증된 세계 정본과 현지 인물을 바탕으로 공식 작전 하달 완료',
    v_payload,encode(sha256(convert_to(v_payload::text,'UTF8')),'hex'));
 update trpg_hq.hq_teams set revision=revision+1,hq_elapsed_minutes=v_next
   where team_id=m.team_id;
 return jsonb_build_object('applied',true,
   'segment_id',p_segment_id,'current_revision',t.revision+1,
   'current_hq_minute',v_next,'departure_requires_player_explicit_action',true);
end $hq$;

create or replace function trpg_hq.depart_after_actual_briefing(
 p_segment_id uuid,p_expected_revision bigint
) returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
 t trpg_hq.hq_teams%rowtype;
 s trpg_hq.hq_mission_segments%rowtype;
 status jsonb;
 v_res jsonb;
begin
 select * into s from trpg_hq.hq_mission_segments where segment_id=p_segment_id;
 if not found then raise exception 'hq_field_segment_not_found';end if;
 select * into t from trpg_hq.hq_teams tm
  join trpg_hq.hq_missions m on m.team_id=tm.team_id
  where m.mission_id=s.mission_id for update of tm;
 status:=trpg_hq.hq_field_preflight(p_segment_id);
 if status->>'ready_for_explicit_departure'<>'true' then
    raise exception 'hq_field_departure_preflight_failed_%',
      (status->'missing_or_conflicting_preconditions')::text;
 end if;
 v_res:=trpg_hq.start_segment(p_segment_id,p_expected_revision);
 return v_res||jsonb_build_object(
   'route','field_game','reopen_at_verified_field_checkpoint_only',true,
   'do_not_warp_back_on_midgame_save',true);
end $hq$;

-- Overlay on existing runtime loop so rewards and prerequisite checks are
-- visible, without forcing Clara visit or filling in player choices.
create or replace function trpg_hq.hq_full_loop_next(p_team_id uuid)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
declare
 snapshot jsonb;
 next text;
 seg uuid;
 pf jsonb;
 unapproved int;
 training_pending int;
 formal_pending int;
begin
 snapshot:=trpg_hq.hq_loop_status(p_team_id);
 next:=snapshot->>'next_checkpoint';
 if next='complete_briefing_and_choose_departure' then
   seg:=(snapshot->'field_segment'->>'segment_id')::uuid;
   pf:=trpg_hq.hq_field_preflight(seg);
   next:=case
     when pf->>'formal_briefing_recorded'<>'true'
        then 'world_pc_equipment_and_martin_briefing'
     when pf->>'ready_for_explicit_departure'='true'
        then 'jayden_departure_on_player_choice'
     else 'world_preflight_needs_correction' end;
 elsif next in ('hq_free_play_or_plan_mission','available_reward_choices') then
   select count(*) into unapproved
    from trpg_hq.hq_mission_segments s
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    where m.team_id=p_team_id and s.status='returned'
      and s.evaluation is not null and s.terminal_status='completed'
      and not exists(select 1 from trpg_hq.hq_reward_grants g
       where g.segment_id=s.segment_id);
   select count(*) into training_pending
    from trpg_hq.hq_mission_segments s
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    join trpg_cards.campaign_members cm on cm.campaign_id=m.campaign_id
    join trpg_hq.hq_agents a on a.agent_id=cm.player_id
    where m.team_id=p_team_id and m.mission_scale='major'
      and m.status='completed' and s.status='returned'
      and s.terminal_status='completed' and s.evaluation is not null
      and cm.player_id=any(s.returning_agent_ids)
      and a.training_completed=false;
   select count(*) into formal_pending
    from trpg_hq.hq_missions m
    where m.team_id=p_team_id and m.mission_scale='chronicle'
      and m.status='completed'
      and not exists(select 1 from trpg_hq.hq_chronicle_completions c
       where c.mission_id=m.mission_id);
   if unapproved>0 then next:='martin_reward_eligibility_review';
   elsif formal_pending>0 then next:='martin_chronicle_completion_review';
   elsif training_pending>0 then next:='martin_training_certification';
   end if;
 end if;
 return snapshot||jsonb_build_object(
   'next_checkpoint',next,
   'npc_interaction_is_optional_when_not_related_to_actual_action',true,
   'no_auto_player_speech_or_reward_choice',true,
   'field_to_hq_only_after_verified_terminal',true);
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
