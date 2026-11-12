-- DEV ONLY / TIME AGENT HQ phase 11A:
-- ON entry identity, actual induction attendance ledger, 8 NPC service routes,
-- and a derived "where to resume" index for the entry->field->return loop.
-- Does NOT change START_GAME OFF, grant dialogue consent, or automate game plot.

create table trpg_hq.hq_entry_sessions (
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  entry_key text not null check(char_length(entry_key) between 1 and 160),
  roster_sha256 text not null check(roster_sha256 ~ '^[0-9a-f]{64}$'),
  entry_route text not null check(entry_route in ('entrance','sync_room')),
  hq_minute bigint not null check(hq_minute>=0),
  created_at timestamptz not null default now(),
  primary key(team_id,entry_key)
);
create index hq_entry_sessions_recent on trpg_hq.hq_entry_sessions(team_id,created_at desc);

create table trpg_hq.hq_agent_inductions (
  agent_id uuid primary key references trpg_hq.hq_agents(agent_id) on delete restrict,
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  event_key text not null,
  acknowledged_activity text not null check(char_length(acknowledged_activity) between 1 and 1000),
  completed_at_hq_minute bigint not null check(completed_at_hq_minute>=0),
  created_at timestamptz not null default now(),
  unique(team_id,event_key,agent_id)
);

-- NPC "service" = responsibility/routing capability, not automatic NPC
-- appearance, invented dialogue, affinity change, or new mechanical reward.
create table trpg_hq.hq_npc_service_catalog (
  npc_key text primary key,
  npc_name text not null,
  home_area text not null,
  duties jsonb not null check(jsonb_typeof(duties)='array'),
  interaction_mode text not null default 'keeper_scene'
    check(interaction_mode='keeper_scene')
);
insert into trpg_hq.hq_npc_service_catalog(npc_key,npc_name,home_area,duties)
values
('npc:martin','마틴 헤일','작전실','[
 {"service":"induction_interview","handler":"keeper_actual_interview_and_record_npc_interaction"},
 {"service":"mission_planning","handler":"keeper_world_setup_then_prepare_mission"},
 {"service":"mission_briefing","handler":"keeper_verified_canon_before_departure"},
 {"service":"evaluation","handler":"evaluate_segment"},
 {"service":"reward_authorization","handler":"approve_general_reward"},
 {"service":"chronicle_certificate","handler":"approve_chronicle_completion"}]'::jsonb),
('npc:jayden','제이든 콜','동기화실','[
 {"service":"first_welcome","handler":"keeper_scene"},
 {"service":"field_departure","handler":"start_segment_after_actual_player_choice"},
 {"service":"field_return","handler":"return_segment_after_verified_terminal"},
 {"service":"death_link_exception","handler":"keeper_03_danger_and_actual_eligibility_only"},
 {"service":"social_interaction","handler":"record_npc_interaction"}]'::jsonb),
('npc:clara','클라라 베넷','기록·분석실','[
 {"service":"predeparture_observed_world_intel","handler":"keeper_only_existing_observed_sources"},
 {"service":"field_world_archive","handler":"clara_record"},
 {"service":"document_disclosure","handler":"clara_release"},
 {"service":"personal_followup_question","handler":"clara_record_followup_question"}]'::jsonb),
('npc:dominic','도미닉 리드','의료·지원 구역','[
 {"service":"cards_and_loadout","handler":"original_09_cards_and_card_collection"},
 {"service":"training_equipment","handler":"keeper_original_equipment_rules"},
 {"service":"normal_reward_offer","handler":"offer_general_reward"},
 {"service":"normal_reward_resolution","handler":"resolve_general_reward"},
 {"service":"special_chronicle_choice","handler":"resolve_chronicle_special"}]'::jsonb),
('npc:samira','사미라 카디르','휴게·생활 구역','[
 {"service":"veteran_field_perspective","handler":"keeper_scene"},
 {"service":"personal_conversation","handler":"record_npc_interaction"}]'::jsonb),
('npc:leo','레오 나바로','휴게·생활 구역','[
 {"service":"peer_exchange","handler":"keeper_scene"},
 {"service":"personal_conversation","handler":"record_npc_interaction"}]'::jsonb),
('npc:seorin','최서린','의료·지원 구역','[
 {"service":"field_medical_perspective","handler":"keeper_original_healing_rules"},
 {"service":"personal_conversation","handler":"record_npc_interaction"}]'::jsonb),
('npc:maya','마야 싱','휴게·생활 구역','[
 {"service":"field_discussion","handler":"keeper_scene"},
 {"service":"personal_conversation","handler":"record_npc_interaction"}]'::jsonb);

alter table trpg_hq.hq_entry_sessions enable row level security;
alter table trpg_hq.hq_agent_inductions enable row level security;
alter table trpg_hq.hq_npc_service_catalog enable row level security;
revoke all on trpg_hq.hq_entry_sessions,
 trpg_hq.hq_agent_inductions,trpg_hq.hq_npc_service_catalog
 from public,anon,authenticated;

-- The interface's ON choice is a prerequisite already made by the user.
-- Existing player cards are linked through nickname -> permanent UUID;
-- no parallel account, oath or character motivation is generated here.
create or replace function trpg_hq.begin_hq_on_visit(
  p_team_key text,p_nicknames text[],p_entry_key text
) returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team_id uuid;
  v_team trpg_hq.hq_teams%rowtype;
  v_ids uuid[]:='{}'::uuid[];
  v_name text;
  v_count integer;
  v_existing_count integer;
  v_same integer;
  v_input_names text[];
  v_actual_names text[];
  v_hash text;
  v_route text;
  v_old trpg_hq.hq_entry_sessions%rowtype;
  v_field_segment uuid;
  v_field_session text;
  v_field_status text;
begin
  v_count:=coalesce(cardinality(p_nicknames),0);
  if p_team_key is null or char_length(p_team_key) not between 1 and 180
    or p_entry_key is null or char_length(p_entry_key) not between 1 and 160
    or v_count not between 1 and 3
    or exists(select 1 from unnest(p_nicknames) n
       where n is null or char_length(btrim(n)) not between 2 and 24
         or btrim(n) ~ '[[:cntrl:]]')
  then raise exception 'hq_entry_invalid_team_or_nicknames';end if;
  select array_agg(lower(btrim(n)) order by lower(btrim(n)))
    into v_input_names from unnest(p_nicknames) n;
  if (select count(distinct x) from unnest(v_input_names) x)<>v_count then
    raise exception 'hq_entry_duplicate_nicknames';
  end if;

  -- Read an existing team BEFORE account registration, so a field resume
  -- does not create any extra card accounts or a fake HQ visit.
  select team_id into v_team_id from trpg_hq.hq_teams where team_key=p_team_key;
  if v_team_id is not null then
    select array_agg(p.nickname_key order by p.nickname_key) into v_actual_names
    from trpg_hq.hq_team_members tm
    join trpg_cards.players p on p.id=tm.agent_id
    where tm.team_id=v_team_id and tm.left_at_minutes is null;
    if v_actual_names is distinct from v_input_names then
      raise exception 'hq_entry_existing_team_roster_conflict';
    end if;
    select s.segment_id,s.session_id,s.status into
      v_field_segment,v_field_session,v_field_status
    from trpg_hq.hq_mission_segments s
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    where m.team_id=v_team_id and s.status in ('field_active','terminal_confirmed')
    order by s.segment_id limit 1;
    if v_field_segment is not null then
      return jsonb_build_object('applied',false,'route','resume_field',
        'team_id',v_team_id,'segment_id',v_field_segment,
        'session_id',v_field_session,'segment_status',v_field_status,
        'hq_visit_created',false,'must_restore_actual_field_checkpoint',true);
    end if;
  end if;
  for v_name in select unnest(p_nicknames) loop
    v_ids:=array_append(v_ids,(
      trpg_cards.register_player(btrim(v_name))->>'player_id')::uuid);
  end loop;
  v_team_id:=(trpg_hq.create_team(p_team_key,v_ids)->>'team_id')::uuid;
  select * into v_team from trpg_hq.hq_teams where team_id=v_team_id for update;
  v_hash:=encode(sha256(convert_to(to_jsonb(v_input_names)::text,'UTF8')),'hex');
  select * into v_old from trpg_hq.hq_entry_sessions
    where team_id=v_team_id and entry_key=p_entry_key;
  if found then
    if v_old.roster_sha256 is distinct from v_hash then
      raise exception 'hq_entry_event_key_roster_conflict';
    end if;
    return jsonb_build_object('applied',false,'route',v_old.entry_route,
      'team_id',v_team_id,'entry_key',p_entry_key,
      'current_revision',v_team.revision,'needs_new_induction',
      exists(select 1 from trpg_hq.hq_team_members tm
        where tm.team_id=v_team_id and tm.left_at_minutes is null
        and not exists(select 1 from trpg_hq.hq_agent_inductions i
          where i.agent_id=tm.agent_id)));
  end if;

  -- Once a real first visit happened, new ON games start at sync room.
  -- Mixed groups start at entrance for the still-uninducted new agents,
  -- WITHOUT re-inducting existing veteran agents.
  v_route:=case when exists(
    select 1 from trpg_hq.hq_team_members tm
    where tm.team_id=v_team_id and tm.left_at_minutes is null
    and not exists(select 1 from trpg_hq.hq_agent_inductions i
      where i.agent_id=tm.agent_id)
    and not exists(
      select 1 from trpg_hq.hq_missions m
        join trpg_cards.campaign_members cm on cm.campaign_id=m.campaign_id
        where cm.player_id=tm.agent_id and m.status='completed')
  ) then 'entrance' else 'sync_room' end;
  insert into trpg_hq.hq_entry_sessions(
    team_id,entry_key,roster_sha256,entry_route,hq_minute
  ) values(v_team_id,p_entry_key,v_hash,v_route,v_team.hq_elapsed_minutes);
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team_id;
  return jsonb_build_object('applied',true,'route',v_route,
    'team_id',v_team_id,'entry_key',p_entry_key,
    'current_revision',v_team.revision+1,
    'hq_minute',v_team.hq_elapsed_minutes,
    'needs_new_induction',v_route='entrance');
end $hq$;

-- Attendance only. This cannot invent an oath, promise, character
-- motivation, interview answer, individual reaction or an NPC relationship.
create or replace function trpg_hq.record_hq_induction(
  p_team_id uuid,p_event_key text,p_expected_revision bigint,
  p_participant_ids uuid[],p_actual_scene_summary text,
  p_elapsed_minutes bigint
) returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_old trpg_hq.hq_events%rowtype;
  v_ids uuid[];
  v_hash text;
  v_request jsonb;
  v_agent uuid;
  v_next bigint;
begin
  if p_event_key is null or char_length(p_event_key) not between 1 and 160
    or p_actual_scene_summary is null
    or char_length(btrim(p_actual_scene_summary)) not between 1 and 1000
    or coalesce(cardinality(p_participant_ids),0) not between 1 and 3
    or p_elapsed_minutes is null or p_elapsed_minutes<0 then
    raise exception 'hq_induction_invalid_request';
  end if;
  select array_agg(x order by x) into v_ids from unnest(p_participant_ids) x;
  if cardinality(v_ids)<>(select count(distinct x) from unnest(v_ids) x)
    or exists(select 1 from unnest(v_ids) x
        where x is null or not exists(
          select 1 from trpg_hq.hq_team_members tm
          where tm.team_id=p_team_id and tm.agent_id=x
            and tm.left_at_minutes is null)) then
    raise exception 'hq_induction_invalid_participants';
  end if;
  v_request:=jsonb_build_object('agents',to_jsonb(v_ids),
    'summary',p_actual_scene_summary,'elapsed',p_elapsed_minutes);
  v_hash:=encode(sha256(convert_to(v_request::text,'UTF8')),'hex');
  select * into v_team from trpg_hq.hq_teams
    where team_id=p_team_id for update;
  if not found then raise exception 'hq_team_not_found';end if;
  select * into v_old from trpg_hq.hq_events
    where team_id=p_team_id and event_key='hq-induction:'||p_event_key;
  if found then
    if v_old.request_sha256 is distinct from v_hash then
      raise exception 'hq_induction_event_key_conflict';
    end if;
    return jsonb_build_object('applied',false,'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',
      p_expected_revision,v_team.revision;
  end if;
  if exists(select 1 from unnest(v_ids) x
    where exists(select 1 from trpg_hq.hq_agent_inductions i where i.agent_id=x)) then
    raise exception 'hq_induction_agent_already_recorded';
  end if;
  v_next:=v_team.hq_elapsed_minutes+p_elapsed_minutes;
  foreach v_agent in array v_ids loop
    insert into trpg_hq.hq_agent_inductions(
      agent_id,team_id,event_key,acknowledged_activity,completed_at_hq_minute)
    values(v_agent,p_team_id,p_event_key,p_actual_scene_summary,v_next);
  end loop;
  insert into trpg_hq.hq_events(
    team_id,event_key,event_kind,hq_minute,actor_key,
    listened_by,audience,summary,event_data,request_sha256)
  values(p_team_id,'hq-induction:'||p_event_key,
    'hq_induction_attendance',v_next,'npc:martin',
    to_jsonb(v_ids),to_jsonb(v_ids),
    '실제로 진행된 본부 입단 장면의 참가 사실',
    jsonb_build_object('participant_ids',to_jsonb(v_ids),
      'actual_scene_summary',p_actual_scene_summary),
    v_hash);
  update trpg_hq.hq_teams set revision=revision+1,
    hq_elapsed_minutes=v_next where team_id=p_team_id;
  return jsonb_build_object('applied',true,'new_inducted_count',
    cardinality(v_ids),'current_revision',v_team.revision+1,
    'current_hq_minute',v_next);
end $hq$;

-- Purely derived from persisted facts; no new world time, NPC speech,
-- consent or user choice. All NPC records remain private GM information.
create or replace function trpg_hq.hq_loop_status(p_team_id uuid)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_s record;
  v_missing jsonb;
  v_pending_normal integer;
  v_pending_special integer;
  v_returned_unevaluated integer;
  v_next text;
  v_last_entry text;
  v_service_data jsonb;
begin
  select * into v_team from trpg_hq.hq_teams where team_id=p_team_id;
  if not found then raise exception 'hq_team_not_found';end if;
  select coalesce(jsonb_agg(jsonb_build_object(
     'agent_id',tm.agent_id,'nickname',p.nickname)
     order by tm.joined_at_minutes,tm.agent_id),'[]'::jsonb)
  into v_missing
  from trpg_hq.hq_team_members tm
  join trpg_cards.players p on p.id=tm.agent_id
  where tm.team_id=p_team_id and tm.left_at_minutes is null
    and not exists(select 1 from trpg_hq.hq_agent_inductions a
      where a.agent_id=tm.agent_id);
  select e.entry_route into v_last_entry from trpg_hq.hq_entry_sessions e
    where e.team_id=p_team_id order by e.created_at desc,e.entry_key desc limit 1;
  select s.segment_id,s.status,s.segment_key,s.session_id,m.mission_id,
    m.mission_scale,m.status as mission_status
   into v_s
  from trpg_hq.hq_mission_segments s
  join trpg_hq.hq_missions m on m.mission_id=s.mission_id
  where m.team_id=p_team_id and s.status in (
       'field_active','terminal_confirmed','prepared')
  order by case s.status when 'field_active' then 1
        when 'terminal_confirmed' then 2 else 3 end,
        m.created_at desc,s.segment_key desc limit 1;
  select count(*) into v_returned_unevaluated
    from trpg_hq.hq_mission_segments s
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    where m.team_id=p_team_id and s.status='returned'
      and s.evaluation is null;
  select count(*) into v_pending_normal
    from trpg_hq.hq_reward_grants g
    join trpg_hq.hq_mission_segments s on s.segment_id=g.segment_id
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    where m.team_id=p_team_id and g.status in ('approved','offered');
  select count(*) into v_pending_special
    from trpg_hq.hq_chronicle_honors h
    join trpg_hq.hq_chronicle_completions c on c.mission_id=h.mission_id
    where c.team_id=p_team_id and h.status='awaiting_choice';
  v_next:=case
    when v_s.segment_id is not null and v_s.status='field_active'
      then 'resume_saved_field'
    when v_s.segment_id is not null and v_s.status='terminal_confirmed'
      then 'verified_return_processing'
    when v_returned_unevaluated>0 then 'martin_evaluation'
    when v_s.segment_id is not null and v_s.status='prepared'
      then 'complete_briefing_and_choose_departure'
    when jsonb_array_length(v_missing)>0 then 'first_induction_scene'
    when v_pending_normal>0 or v_pending_special>0 then 'available_reward_choices'
    else 'hq_free_play_or_plan_mission' end;
  select coalesce(jsonb_agg(jsonb_build_object(
    'npc_key',npc_key,'npc_name',npc_name,
    'home_area',home_area,'duties',duties)
    order by npc_key),'[]'::jsonb) into v_service_data
  from trpg_hq.hq_npc_service_catalog;
  return jsonb_build_object('team_id',p_team_id,
    'hq_elapsed_minutes',v_team.hq_elapsed_minutes,
    'revision',v_team.revision,
    'entry_route',v_last_entry,
    'uninducted_agents',v_missing,'next_checkpoint',v_next,
    'field_segment',case when v_s.segment_id is not null
      then jsonb_build_object('segment_id',v_s.segment_id,
        'segment_key',v_s.segment_key,'session_id',v_s.session_id,
        'status',v_s.status,'mission_id',v_s.mission_id,
        'mission_scale',v_s.mission_scale,'mission_status',v_s.mission_status)
      else null end,
    'returned_unevaluated',v_returned_unevaluated,
    'approved_or_offered_general_rewards',v_pending_normal,
    'unselected_chronicle_special_rewards',v_pending_special,
    'available_npc_structural_services',v_service_data,
    'not_a_player_ui_secret_dump',true);
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
alter default privileges in schema trpg_hq
  revoke execute on functions from public;
