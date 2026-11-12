-- DEV ONLY: Martin's qualitative evaluation after verified return.
-- No numeric ranks, free rewards, or unverified field outcome fabrication.

alter table trpg_hq.hq_mission_segments
add constraint hq_evaluation_grade_shape
check (evaluation is null or
  (jsonb_typeof(evaluation)='object'
   and evaluation->>'grade' in ('S','A','B','C','F')
   and jsonb_typeof(evaluation->'objectives')='array'));

create or replace function trpg_hq.evaluate_segment(
  p_segment_id uuid, p_expected_revision bigint,
  p_grade text, p_objective_results jsonb,
  p_assessment text, p_observed_outcomes jsonb
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_result jsonb;
  v_expected_ids text[];
  v_actual_ids text[];
  v_audience jsonb;
begin
  if p_grade is null or p_grade not in ('S','A','B','C','F')
    or jsonb_typeof(p_objective_results) is distinct from 'array'
    or jsonb_typeof(p_observed_outcomes) is distinct from 'object'
    or p_assessment is null or char_length(btrim(p_assessment))=0
    or char_length(p_assessment)>10000 then
    raise exception 'hq_invalid_evaluation';
  end if;
  if exists(select 1 from jsonb_array_elements(p_objective_results) as x(v)
    where jsonb_typeof(x.v) is distinct from 'object'
      or nullif(btrim(x.v->>'id'),'') is null
      or x.v->>'result' not in ('achieved','partial','unmet','impossible')
      or nullif(btrim(x.v->>'reason'),'') is null) then
    raise exception 'hq_invalid_objective_result';
  end if;
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments
    where segment_id=p_segment_id for update;
  if v_segment.status<>'returned' then
    raise exception 'hq_evaluation_requires_actual_return';
  end if;
  select array_agg(x.v->>'id' order by x.v->>'id')
    into v_expected_ids
    from jsonb_array_elements(v_mission.preassigned_objectives) x(v);
  select array_agg(x.v->>'id' order by x.v->>'id')
    into v_actual_ids
    from jsonb_array_elements(p_objective_results) x(v);
  if v_expected_ids is distinct from v_actual_ids then
    raise exception 'hq_evaluation_objective_ids_mismatch';
  end if;
  v_result:=jsonb_build_object('grade',p_grade,
    'objectives',p_objective_results,
    'assessment',p_assessment,
    'observed_outcomes',p_observed_outcomes,
    'verified_terminal_event_id',v_segment.terminal_event_id,
    'verified_checkpoint_version',v_segment.verified_checkpoint_version);
  if v_segment.evaluation is not null then
    if v_segment.evaluation is distinct from v_result then
      raise exception 'hq_evaluation_already_finalized';
    end if;
    return jsonb_build_object('applied',false,'segment_id',p_segment_id,
      'grade',p_grade,'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  update trpg_hq.hq_mission_segments
    set evaluation=v_result where segment_id=p_segment_id;
  v_audience:=to_jsonb(v_segment.returning_agent_ids);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,'evaluation:'||p_segment_id::text,'mission_evaluated',
    v_team.hq_elapsed_minutes,'npc:martin',v_audience,v_audience,
    p_assessment,v_result,
    encode(sha256(convert_to(v_result::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'segment_id',p_segment_id,
    'grade',p_grade,'current_revision',v_team.revision+1);
end $hq$;

revoke all on function trpg_hq.evaluate_segment(uuid,bigint,text,jsonb,text,jsonb)
  from public,anon,authenticated;
