-- DEV ONLY: re-dispatch into the same chronicle after verified chapter return.
-- Existing field session/world/PC continuity belongs to verified checkpoint + private canon.
create or replace function trpg_hq.prepare_next_chapter(
  p_mission_id uuid, p_segment_key text, p_session_id text,
  p_expected_revision bigint
)
returns jsonb language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_previous trpg_hq.hq_mission_segments%rowtype;
  v_data jsonb;
begin
  if p_segment_key is null or char_length(p_segment_key) not between 1 and 180
    or p_session_id is null or char_length(p_session_id) not between 1 and 180 then
    raise exception 'hq_invalid_chapter_segment';
  end if;
  select * into v_mission from trpg_hq.hq_missions where mission_id=p_mission_id;
  if not found then raise exception 'hq_mission_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams
    where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments
    where mission_id=p_mission_id and segment_key=p_segment_key;
  if found then
    if v_segment.session_id is distinct from p_session_id then
      raise exception 'hq_chapter_segment_replay_conflict';
    end if;
    return jsonb_build_object('applied',false,'segment_id',v_segment.segment_id,
      'mission_id',p_mission_id,'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  if v_mission.mission_scale<>'chronicle'
    or v_mission.status<>'field_active' then
    raise exception 'hq_not_active_chronicle';
  end if;
  if exists(select 1 from trpg_hq.hq_mission_segments s
     where s.mission_id=p_mission_id and s.status<>'returned') then
    raise exception 'hq_chronicle_has_unfinished_chapter';
  end if;
  select * into v_previous from trpg_hq.hq_mission_segments
     where mission_id=p_mission_id order by returned_at desc limit 1;
  if not found or v_previous.terminal_scope<>'CHAPTER_TERMINAL' then
    raise exception 'hq_chronicle_previous_chapter_not_returned';
  end if;
  insert into trpg_hq.hq_mission_segments(mission_id,segment_key,session_id)
  values(p_mission_id,p_segment_key,p_session_id) returning * into v_segment;
  v_data:=jsonb_build_object('mission_id',p_mission_id,
    'previous_segment_id',v_previous.segment_id,
    'segment_id',v_segment.segment_id,
    'segment_key',p_segment_key,'session_id',p_session_id);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    summary,event_data,request_sha256)
  values(v_team.team_id,'segment:'||v_segment.segment_id::text||':prepared',
    'chronicle_chapter_prepared',v_team.hq_elapsed_minutes,
    '동일 연대기 세계에 다음 챕터 재출격 준비',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'segment_id',v_segment.segment_id,
    'mission_id',p_mission_id,'current_revision',v_team.revision+1);
end $hq$;
revoke all on function trpg_hq.prepare_next_chapter(uuid,text,text,bigint)
  from public,anon,authenticated;
