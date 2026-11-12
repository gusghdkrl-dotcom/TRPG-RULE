-- DEV ONLY. Active team membership is required to list, disclose, or read Clara archives.
-- Prevent former teammates from accessing new/old records after leaving the team.
create or replace function trpg_hq.clara_catalog(
  p_team_id uuid,p_player_id uuid
)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
begin
  if not exists(select 1 from trpg_hq.hq_team_members
       where team_id=p_team_id and agent_id=p_player_id and left_at_minutes is null) then
    raise exception 'hq_clara_catalog_not_team_member';
  end if;
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'record_id',o.record_id,'subject_kind',o.subject_kind,
      'subject_id',o.subject_id,'subject_label',o.subject_label,
      'topic',o.topic,'world_time_label',o.world_time_label,
      'source_kind',o.source_kind,'already_shared',r.record_id is not null)
      order by o.created_at,o.record_id),'[]'::jsonb)
    from trpg_hq.hq_clara_observations o
    left join trpg_hq.hq_clara_releases r on r.record_id=o.record_id
    where o.team_id=p_team_id and o.access_level='available'
      and (o.listable or r.record_id is not null)
  );
end $hq$;

create or replace function trpg_hq.clara_release(
  p_record_id uuid,p_player_id uuid,p_expected_revision bigint,p_question_text text
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_record trpg_hq.hq_clara_observations%rowtype;
  v_team trpg_hq.hq_teams%rowtype;
  v_release trpg_hq.hq_clara_releases%rowtype;
  v_event text;
  v_data jsonb;
begin
  if p_question_text is null or char_length(btrim(p_question_text)) not between 1 and 4000 then
    raise exception 'hq_clara_question_required';
  end if;
  select * into v_record from trpg_hq.hq_clara_observations where record_id=p_record_id;
  if not found then raise exception 'hq_clara_record_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams
    where team_id=v_record.team_id for update;
  if not exists(select 1 from trpg_hq.hq_team_members
       where team_id=v_team.team_id and agent_id=p_player_id and left_at_minutes is null) then
    raise exception 'hq_clara_requester_not_team_member';
  end if;
  if v_record.access_level<>'available' then
    raise exception 'hq_clara_record_not_releasable';
  end if;
  select * into v_release from trpg_hq.hq_clara_releases where record_id=p_record_id;
  if found then
    return jsonb_build_object('applied',false,'record_id',p_record_id,
      'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  v_event:='clara:'||p_record_id::text||':shared';
  insert into trpg_hq.hq_clara_releases(
    record_id,team_id,requested_by,question_text,released_hq_minute,event_key
  ) values(p_record_id,v_team.team_id,p_player_id,p_question_text,
     v_team.hq_elapsed_minutes,v_event);
  v_data:=jsonb_build_object('record_id',p_record_id,
    'requested_by',p_player_id,'question_text',p_question_text,
    'subject_id',v_record.subject_id,
    'source_kind',v_record.source_kind,'evidence_status',v_record.evidence_status);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,v_event,'clara_archive_shared',v_team.hq_elapsed_minutes,
    'npc:clara',to_jsonb(array[p_player_id::text]),
    '[]'::jsonb,'클라라의 기록이 요청에 따라 플레이어에게 공개됐다',
    v_data,encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1
    where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'record_id',p_record_id,
    'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.clara_read_shared(
  p_team_id uuid,p_player_id uuid,p_subject_id text default null
)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
begin
  if not exists(select 1 from trpg_hq.hq_team_members
       where team_id=p_team_id and agent_id=p_player_id and left_at_minutes is null) then
    raise exception 'hq_clara_reader_not_team_member';
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object(
    'record_id',o.record_id,'segment_id',o.segment_id,
    'subject_kind',o.subject_kind,'subject_id',o.subject_id,
    'subject_label',o.subject_label,'topic',o.topic,
    'world_time_label',o.world_time_label,'received_hq_minute',o.received_hq_minute,
    'source_kind',o.source_kind,'evidence_status',o.evidence_status,
    'checkpoint_version',o.checkpoint_version,'checkpoint_sha256',o.checkpoint_sha256,
    'source_path',o.source_path,'source_value',o.source_value,
    'source_reference',o.source_reference,'source_method',o.source_method,
    'source_excerpt',o.source_excerpt,'finding',o.finding,
    'summary',o.summary)
    order by o.created_at,o.record_id),'[]'::jsonb)
  from trpg_hq.hq_clara_observations o
  join trpg_hq.hq_clara_releases r on r.record_id=o.record_id
  where o.team_id=p_team_id and o.access_level='available'
    and (p_subject_id is null or o.subject_id=p_subject_id));
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
