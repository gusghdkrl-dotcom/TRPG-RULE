-- DEV ONLY: integrity constraints and private HQ restore/replay API.
-- Requires dev_hq_phase2_dispatch_verified_terminal_return.

alter table trpg_hq.hq_mission_segments
add constraint hq_terminal_evidence_required
check (
  case when status in ('terminal_confirmed','returned') then
      terminal_event_id is not null and terminal_event_id<>'' and
      terminal_scope is not null and terminal_status is not null and
      verified_checkpoint_version is not null and
      verified_state_sha256 is not null and
      terminal_verified_at is not null and
      jsonb_typeof(terminal_result)='object'
    else true end
);
alter table trpg_hq.hq_mission_segments
add constraint hq_return_evidence_required
check (
  case when status='returned' then
      return_event_key is not null and return_event_key<>'' and
      return_hq_minute is not null and returned_at is not null and
      coalesce(array_length(returning_agent_ids,1),0)>=1
    else true end
);
create unique index hq_one_terminal_event_per_mission
  on trpg_hq.hq_mission_segments(mission_id,terminal_event_id)
  where terminal_event_id is not null;

create or replace function trpg_hq.load_team(p_team_id uuid)
returns jsonb
language plpgsql stable
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_members jsonb;
  v_actor_states jsonb;
  v_missions jsonb;
  v_recent jsonb;
  v_event_count bigint;
begin
  select * into v_team from trpg_hq.hq_teams where team_id=p_team_id;
  if not found then raise exception 'hq_team_not_found'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'agent_id',tm.agent_id,'nickname',p.nickname,'qualification',a.qualification,
    'training_completed',a.training_completed,'chronicle_completed',a.chronicle_completed,
    'personal_state',a.personal_state,'joined_at_minutes',tm.joined_at_minutes,
    'left_at_minutes',tm.left_at_minutes)
    order by tm.joined_at_minutes,tm.agent_id),'[]'::jsonb)
  into v_members from trpg_hq.hq_team_members tm
  join trpg_hq.hq_agents a on a.agent_id=tm.agent_id
  join trpg_cards.players p on p.id=tm.agent_id where tm.team_id=p_team_id;

  select coalesce(jsonb_object_agg(actor_key,
    jsonb_build_object('state',state_data,'revision',revision,
      'last_event_key',last_event_key)),'{}'::jsonb)
  into v_actor_states from trpg_hq.hq_actor_states where team_id=p_team_id;

  select coalesce(jsonb_agg(
    jsonb_build_object('mission_id',m.mission_id,'campaign_id',m.campaign_id,
      'scale',m.mission_scale,'status',m.status,'risk_level',m.risk_level,
      'general_goal',m.general_goal,'objectives',m.preassigned_objectives,
      'briefing',m.briefing_record,
      'segments',(
        select coalesce(jsonb_agg(jsonb_build_object(
          'segment_id',s.segment_id,'segment_key',s.segment_key,
          'session_id',s.session_id,'status',s.status,
          'terminal_scope',s.terminal_scope,'terminal_event_id',s.terminal_event_id,
          'terminal_status',s.terminal_status,
          'verified_checkpoint_version',s.verified_checkpoint_version,
          'verified_state_sha256',s.verified_state_sha256,
          'returning_agent_ids',s.returning_agent_ids,
          'return_event_key',s.return_event_key,
          'return_hq_minute',s.return_hq_minute,'evaluation',s.evaluation)
          order by s.segment_key),'[]'::jsonb)
        from trpg_hq.hq_mission_segments s where s.mission_id=m.mission_id
      )) order by m.created_at desc),'[]'::jsonb)
  into v_missions from trpg_hq.hq_missions m where m.team_id=p_team_id;

  select count(*) into v_event_count from trpg_hq.hq_events where team_id=p_team_id;
  select coalesce(jsonb_agg(jsonb_build_object(
      'event_key',q.event_key,'kind',q.event_kind,'hq_minute',q.hq_minute,
      'actor',q.actor_key,'listened_by',q.listened_by,'audience',q.audience,
      'summary',q.summary,'data',q.event_data,'created_at',q.created_at)
      order by q.created_at,q.event_key),'[]'::jsonb)
    into v_recent from
      (select * from trpg_hq.hq_events where team_id=p_team_id
       order by created_at desc,event_key desc limit 100) q;

  return jsonb_build_object('team_id',v_team.team_id,
    'team_key',v_team.team_key,'hq_elapsed_minutes',v_team.hq_elapsed_minutes,
    'revision',v_team.revision,'current_state',v_team.current_state,
    'members',v_members,'actor_states',v_actor_states,'missions',v_missions,
    'event_count',v_event_count,'recent_events',v_recent,
    'recent_events_limit',100,'historical_events_available',v_event_count>100);
end $hq$;

create or replace function trpg_hq.load_events_page(
  p_team_id uuid,
  p_before_created_at timestamptz default null,
  p_before_event_key text default null,
  p_limit integer default 100
)
returns table(event_key text,event_kind text,hq_minute bigint,
  actor_key text,listened_by jsonb,audience jsonb,summary text,
  event_data jsonb,created_at timestamptz)
language plpgsql stable
set search_path to 'pg_catalog'
as $hq$
begin
  if p_limit is null or p_limit not between 1 and 100
    or (p_before_created_at is null and p_before_event_key is not null)
    or (p_before_created_at is not null and p_before_event_key is null) then
    raise exception 'hq_invalid_event_pagination';
  end if;
  if not exists(select 1 from trpg_hq.hq_teams where team_id=p_team_id) then
    raise exception 'hq_team_not_found';
  end if;
  return query
  select e.event_key,e.event_kind,e.hq_minute,e.actor_key,e.listened_by,
    e.audience,e.summary,e.event_data,e.created_at
    from trpg_hq.hq_events e where e.team_id=p_team_id
      and (p_before_created_at is null
        or (e.created_at,e.event_key)<(p_before_created_at,p_before_event_key))
    order by e.created_at desc,e.event_key desc limit p_limit;
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
