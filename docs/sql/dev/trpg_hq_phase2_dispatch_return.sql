-- DEV ONLY: HQ mission dispatch, verified local terminal, one-time +3d return.
-- Requires trpg_hq_phase1.sql and existing original V2/card/private canon schemas.
-- ON-only proposed runtime DB1 contract: runtime.hq={enabled:true,mission_id,segment_key};
-- runtime.ending_state={scope,status,finalization_event_id,returning_agent_ids:[uuid...]};
-- No existing OFF/legacy ON checkpoint is automatically promoted to an HQ mission.

alter table trpg_hq.hq_mission_segments
  add column terminal_event_id text,
  add column terminal_scope text
    check (terminal_scope is null or terminal_scope in
      ('CAMPAIGN_TERMINAL','CHAPTER_TERMINAL','CHRONICLE_TERMINAL')),
  add column terminal_status text
    check (terminal_status is null or terminal_status in ('completed','failed')),
  add column returning_agent_ids uuid[] not null default '{}'::uuid[],
  add column terminal_verified_at timestamptz,
  add column returned_at timestamptz;

create or replace function trpg_hq.prepare_mission(
  p_team_id uuid, p_campaign_id text, p_mission_scale text,
  p_risk_level text, p_objectives jsonb, p_briefing jsonb,
  p_segment_key text, p_session_id text, p_expected_revision bigint
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_campaign trpg_cards.campaigns%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_count integer;
  v_enrolled integer;
  v_event text;
  v_data jsonb;
begin
  if p_campaign_id is null or char_length(p_campaign_id) not between 1 and 120
    or p_segment_key is null or char_length(p_segment_key) not between 1 and 180
    or p_session_id is null or char_length(p_session_id) not between 1 and 180
    or p_mission_scale not in ('major','chronicle')
    or p_risk_level not in ('I','II','III','IV','V','unassessed')
    or jsonb_typeof(p_objectives) is distinct from 'array'
    or jsonb_array_length(p_objectives)=0
    or jsonb_typeof(p_briefing) is distinct from 'object' then
    raise exception 'hq_invalid_dispatch';
  end if;
  if exists(select 1 from jsonb_array_elements(p_objectives) as x(v)
    where jsonb_typeof(x.v) is distinct from 'object'
      or nullif(btrim(x.v->>'id'),'') is null
      or nullif(btrim(x.v->>'description'),'') is null
      or x.v->>'importance' not in ('core','major','support')) then
    raise exception 'hq_invalid_preassigned_objective';
  end if;
  if (select count(distinct x.v->>'id') from jsonb_array_elements(p_objectives) x(v))
     <> jsonb_array_length(p_objectives) then
    raise exception 'hq_duplicate_objectives';
  end if;
  select * into v_team from trpg_hq.hq_teams where team_id=p_team_id for update;
  if not found then raise exception 'hq_team_not_found'; end if;

  select * into v_mission from trpg_hq.hq_missions where campaign_id=p_campaign_id;
  if found then
    select * into v_segment from trpg_hq.hq_mission_segments
      where mission_id=v_mission.mission_id and segment_key=p_segment_key;
    if v_mission.team_id is distinct from p_team_id
       or v_mission.mission_scale is distinct from p_mission_scale
       or v_mission.risk_level is distinct from p_risk_level
       or v_mission.preassigned_objectives is distinct from p_objectives
       or v_mission.briefing_record is distinct from p_briefing
       or v_segment.segment_id is null
       or v_segment.session_id is distinct from p_session_id then
      raise exception 'hq_dispatch_conflict';
    end if;
    return jsonb_build_object('applied',false,'mission_id',v_mission.mission_id,
      'segment_id',v_segment.segment_id,'current_revision',v_team.revision);
  end if;

  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  select * into v_campaign from trpg_cards.campaigns where campaign_id=p_campaign_id;
  if not found then raise exception 'hq_card_campaign_not_found'; end if;
  if v_campaign.campaign_mode is distinct from p_mission_scale
    or (v_campaign.source_session_id is not null
      and v_campaign.source_session_id is distinct from p_session_id) then
    raise exception 'hq_campaign_dispatch_identity_conflict';
  end if;
  select count(*) into v_count from trpg_hq.hq_team_members
    where team_id=p_team_id and left_at_minutes is null;
  select count(*) into v_enrolled
  from trpg_cards.campaign_members cm
  join trpg_hq.hq_team_members tm
    on tm.agent_id=cm.player_id and tm.team_id=p_team_id
    and tm.left_at_minutes is null
  where cm.campaign_id=p_campaign_id;
  if v_count not between 1 and 3 or v_enrolled<>v_count
    or (select count(*) from trpg_cards.campaign_members where campaign_id=p_campaign_id)<>v_count then
    raise exception 'hq_campaign_member_mismatch';
  end if;
  if exists(select 1 from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where m.team_id=p_team_id and s.status in ('prepared','field_active','terminal_confirmed')) then
    raise exception 'hq_team_has_unfinished_segment';
  end if;
  insert into trpg_hq.hq_missions(team_id,campaign_id,mission_scale,risk_level,
    preassigned_objectives,briefing_record,created_at_hq_minutes)
  values(p_team_id,p_campaign_id,p_mission_scale,p_risk_level,
    p_objectives,p_briefing,v_team.hq_elapsed_minutes)
  returning * into v_mission;
  insert into trpg_hq.hq_mission_segments(mission_id,segment_key,session_id)
    values(v_mission.mission_id,p_segment_key,p_session_id)
    returning * into v_segment;
  v_event:='segment:'||v_segment.segment_id::text||':prepared';
  v_data:=jsonb_build_object('campaign_id',p_campaign_id,'mission_id',v_mission.mission_id,
    'segment_id',v_segment.segment_id,'segment_key',p_segment_key);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,summary,event_data,request_sha256)
  values(p_team_id,v_event,'mission_prepared',v_team.hq_elapsed_minutes,
    '본부 작전 및 사전 소목표 확정',v_data,encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=p_team_id;
  return jsonb_build_object('applied',true,'mission_id',v_mission.mission_id,
    'segment_id',v_segment.segment_id,'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.start_segment(
  p_segment_id uuid, p_expected_revision bigint
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_data jsonb;
begin
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments where segment_id=p_segment_id for update;
  if v_segment.status='field_active' then
    return jsonb_build_object('applied',false,'segment_id',p_segment_id,
      'current_revision',v_team.revision);
  end if;
  if v_segment.status<>'prepared' or v_mission.status not in ('preparing','field_active') then
    raise exception 'hq_segment_not_prepared';
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  update trpg_hq.hq_mission_segments set status='field_active' where segment_id=p_segment_id;
  update trpg_hq.hq_missions set status='field_active' where mission_id=v_mission.mission_id;
  v_data:=jsonb_build_object('segment_id',p_segment_id,'mission_id',v_mission.mission_id);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,summary,event_data,request_sha256)
  values(v_team.team_id,'segment:'||p_segment_id::text||':started',
    'mission_departure',v_team.hq_elapsed_minutes,'동기화 출격',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'segment_id',p_segment_id,
    'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.confirm_segment_terminal(
  p_segment_id uuid, p_checkpoint_version bigint, p_checkpoint_sha256 text,
  p_expected_revision bigint
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_cp public.gm_checkpoint_history%rowtype;
  v_doc jsonb;
  v_end jsonb;
  v_canon jsonb;
  v_id text;
  v_scope text;
  v_status text;
  v_ret_ids uuid[];
  v_ret_count integer;
  v_data jsonb;
begin
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams
    where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments
    where segment_id=p_segment_id for update;
  if v_segment.status='returned' then raise exception 'hq_segment_already_returned'; end if;
  if v_segment.status not in ('field_active','terminal_confirmed') then
    raise exception 'hq_segment_not_active';
  end if;
  if p_checkpoint_version is null or p_checkpoint_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'hq_invalid_checkpoint_reference';
  end if;
  select * into v_cp from public.gm_checkpoint_history
    where session_id=v_segment.session_id
      and version=p_checkpoint_version and status='verified';
  if not found then raise exception 'hq_verified_checkpoint_not_found'; end if;
  if p_checkpoint_sha256 is distinct from v_cp.state_sha256
    or encode(sha256(convert_to(v_cp.state_json,'UTF8')),'hex') is distinct from v_cp.state_sha256
    or public.trpg_v2_payload_issue(v_cp.state_json) is not null then
    raise exception 'hq_checkpoint_hash_or_format_mismatch';
  end if;
  if exists(select 1 from public.gm_checkpoint_history
    where session_id=v_segment.session_id and status='verified'
      and version>p_checkpoint_version) then
    raise exception 'hq_checkpoint_not_latest_verified';
  end if;
  v_doc:=v_cp.state_json::jsonb;
  v_canon:=v_doc->'canon_ref';
  v_end:=v_doc->'runtime'->'ending_state';
  if v_doc->>'campaign_id' is distinct from v_mission.campaign_id
    or v_doc->>'session_id' is distinct from v_segment.session_id
    or v_doc->'runtime'->'hq'->'enabled' is distinct from 'true'::jsonb
    or v_doc->'runtime'->'hq'->>'mission_id' is distinct from v_mission.mission_id::text
    or v_doc->'runtime'->'hq'->>'segment_key' is distinct from v_segment.segment_key then
    raise exception 'hq_checkpoint_not_bound_to_segment';
  end if;
  if not exists(select 1 from trpg_private.gm_canon_documents c
      where c.campaign_id=v_mission.campaign_id
        and c.canon_id=v_canon->>'canon_id'
        and c.revision=(v_canon->>'revision')::integer
        and c.filename=v_canon->>'filename'
        and c.document_format=v_canon->>'document_format'
        and c.rules_version=v_doc->>'rules_version'
        and c.file_sha256=v_cp.canon_file_sha256
        and c.file_sha256=v_canon->>'file_sha256') then
    raise exception 'hq_checkpoint_canon_not_verified';
  end if;
  v_scope:=v_end->>'scope';
  v_status:=v_end->>'status';
  v_id:=v_end->>'finalization_event_id';
  if nullif(v_id,'') is null or char_length(v_id)>255
    or v_status not in ('completed','failed')
    or v_scope not in ('CAMPAIGN_TERMINAL','CHAPTER_TERMINAL','CHRONICLE_TERMINAL')
    or (v_mission.mission_scale='major' and v_scope<>'CAMPAIGN_TERMINAL')
    or (v_mission.mission_scale='chronicle' and v_scope='CAMPAIGN_TERMINAL')
    or jsonb_typeof(v_end->'returning_agent_ids') is distinct from 'array' then
    raise exception 'hq_checkpoint_terminal_contract_invalid';
  end if;
  if exists(select 1 from jsonb_array_elements(v_end->'returning_agent_ids') as x(value)
    where jsonb_typeof(x.value) is distinct from 'string') then
    raise exception 'hq_invalid_returning_agents';
  end if;
  select coalesce(array_agg(z.uuid order by z.uuid),'{}'::uuid[]),count(*)
  into v_ret_ids,v_ret_count
  from (select e.value::uuid as uuid
        from jsonb_array_elements_text(v_end->'returning_agent_ids') e(value)) z;
  if v_ret_count is distinct from (select count(distinct unnest_id)
    from unnest(v_ret_ids) unnest_id) then
    raise exception 'hq_duplicate_returning_agents';
  end if;
  if exists(select 1 from unnest(v_ret_ids) v(agent_id)
    where not exists(select 1 from trpg_cards.campaign_members cm
      join trpg_hq.hq_team_members tm
        on tm.agent_id=cm.player_id and tm.team_id=v_team.team_id
      where cm.campaign_id=v_mission.campaign_id and cm.player_id=v.agent_id)) then
    raise exception 'hq_returning_agent_not_in_mission';
  end if;
  if v_segment.status='terminal_confirmed' then
    if v_segment.verified_checkpoint_version is distinct from p_checkpoint_version
      or v_segment.verified_state_sha256 is distinct from p_checkpoint_sha256
      or v_segment.terminal_event_id is distinct from v_id then
      raise exception 'hq_terminal_already_confirmed_with_different_evidence';
    end if;
    return jsonb_build_object('applied',false,'segment_id',p_segment_id,
      'terminal_event_id',v_id,'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  update trpg_hq.hq_mission_segments set
    status='terminal_confirmed',
    verified_checkpoint_version=p_checkpoint_version,
    verified_state_sha256=p_checkpoint_sha256,
    terminal_result=v_end,
    terminal_event_id=v_id,
    terminal_scope=v_scope,
    terminal_status=v_status,
    returning_agent_ids=v_ret_ids,
    terminal_verified_at=now()
    where segment_id=p_segment_id;
  v_data:=jsonb_build_object('segment_id',p_segment_id,'mission_id',v_mission.mission_id,
    'checkpoint_version',p_checkpoint_version,'state_sha256',p_checkpoint_sha256,
    'terminal_event_id',v_id,'scope',v_scope,'status',v_status,
    'returning_agent_ids',to_jsonb(v_ret_ids));
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,summary,event_data,request_sha256)
  values(v_team.team_id,'segment:'||p_segment_id::text||':terminal_verified',
    'terminal_verified',v_team.hq_elapsed_minutes,'현지 검증 종료 확인',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'segment_id',p_segment_id,
    'terminal_event_id',v_id,'returning_agents',v_ret_count,
    'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.return_segment(
  p_segment_id uuid, p_expected_revision bigint
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_checkpoint_version bigint;
  v_checkpoint_sha text;
  v_event text;
  v_now bigint;
  v_data jsonb;
begin
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments
    where segment_id=p_segment_id for update;
  if v_segment.status='returned' then
    return jsonb_build_object('applied',false,'segment_id',p_segment_id,
      'return_event_key',v_segment.return_event_key,
      'hq_minute',v_segment.return_hq_minute,'current_revision',v_team.revision);
  end if;
  if v_segment.status<>'terminal_confirmed'
    or v_segment.terminal_verified_at is null
    or coalesce(array_length(v_segment.returning_agent_ids,1),0)=0 then
    raise exception 'hq_return_requires_confirmed_terminal_and_surviving_returnee';
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  select max(version) into v_checkpoint_version
    from public.gm_checkpoint_history
    where session_id=v_segment.session_id and status='verified';
  if v_checkpoint_version is distinct from v_segment.verified_checkpoint_version then
    raise exception 'hq_newer_verified_checkpoint_requires_review';
  end if;
  select state_sha256 into v_checkpoint_sha from public.gm_checkpoint_history
    where session_id=v_segment.session_id and version=v_checkpoint_version and status='verified';
  if v_checkpoint_sha is distinct from v_segment.verified_state_sha256 then
    raise exception 'hq_terminal_verified_checkpoint_changed';
  end if;
  v_event:='return:'||p_segment_id::text;
  v_now:=v_team.hq_elapsed_minutes+4320;
  v_data:=jsonb_build_object('segment_id',p_segment_id,'mission_id',v_mission.mission_id,
    'terminal_event_id',v_segment.terminal_event_id,
    'verified_checkpoint_version',v_segment.verified_checkpoint_version,
    'returning_agent_ids',to_jsonb(v_segment.returning_agent_ids),
    'minutes_added',4320);
  update trpg_hq.hq_mission_segments set
    status='returned',return_event_key=v_event,
    return_hq_minute=v_now,returned_at=now() where segment_id=p_segment_id;
  if v_segment.terminal_scope in ('CAMPAIGN_TERMINAL','CHRONICLE_TERMINAL') then
    update trpg_hq.hq_missions set
      status=case when v_segment.terminal_status='failed' then 'failed' else 'completed' end
      where mission_id=v_mission.mission_id;
  end if;
  update trpg_hq.hq_teams set
    hq_elapsed_minutes=v_now,revision=revision+1 where team_id=v_team.team_id;
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,summary,event_data,request_sha256)
  values(v_team.team_id,v_event,'mission_return',v_now,
    '검증된 임무 귀환: 본부 시간 3일 경과',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  return jsonb_build_object('applied',true,'segment_id',p_segment_id,
    'return_event_key',v_event,'hq_minute',v_now,
    'minutes_added',4320,'current_revision',v_team.revision+1);
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
