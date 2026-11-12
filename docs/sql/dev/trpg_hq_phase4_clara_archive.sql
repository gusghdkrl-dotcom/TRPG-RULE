-- DEV ONLY. Clara archive v1: verified-field provenance vs post-return attributed observations.
-- Original canon / checkpoint / epilogues immutable. All records isolated to trpg_hq.
-- DB verifies checkpoint byte provenance; later reports are only attributed evidence,
-- never claimed independently verified or generated while user is away.

create table trpg_hq.hq_clara_observations (
  record_id uuid primary key default gen_random_uuid(),
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  segment_id uuid not null references trpg_hq.hq_mission_segments(segment_id) on delete restrict,
  record_key text not null check (char_length(record_key) between 1 and 180),
  subject_kind text not null check (subject_kind in ('synchronized_pc','field_npc','place','organization','community','world','threat')),
  subject_id text not null check (char_length(subject_id) between 1 and 180),
  subject_label text not null check (char_length(subject_label) between 1 and 180),
  topic text not null check (char_length(topic) between 1 and 400),
  source_kind text not null check (source_kind in ('verified_field','later_report')),
  evidence_status text not null check (evidence_status in ('exact_checkpoint_value','attributed_report')),
  world_time_label text not null check (char_length(world_time_label) between 1 and 180),
  received_hq_minute bigint not null check (received_hq_minute >= 0),
  checkpoint_version bigint,
  checkpoint_sha256 text,
  source_path text[],
  source_value jsonb,
  source_reference text,
  source_method text,
  source_excerpt text,
  finding jsonb not null,
  summary text not null check (char_length(summary) between 1 and 4000),
  access_level text not null check (access_level in ('internal','available')),
  listable boolean not null default false,
  input_sha256 text not null check (input_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  unique (team_id,record_key),
  check (not listable or access_level='available'),
  check (
    (source_kind='verified_field' and evidence_status='exact_checkpoint_value'
      and checkpoint_version is not null and checkpoint_sha256 is not null
      and source_path is not null and source_value is not null
      and source_reference is null and source_method is null and source_excerpt is null)
    or
    (source_kind='later_report' and evidence_status='attributed_report'
      and checkpoint_version is null and checkpoint_sha256 is null
      and source_path is null and source_value is null
      and source_reference is not null and source_method is not null
      and source_excerpt is not null)
  )
);
create index hq_clara_subject_lookup
  on trpg_hq.hq_clara_observations(team_id,subject_kind,subject_id,created_at);
create index hq_clara_available_catalog
  on trpg_hq.hq_clara_observations(team_id,created_at)
  where listable and access_level='available';

create table trpg_hq.hq_clara_releases (
  record_id uuid primary key references trpg_hq.hq_clara_observations(record_id) on delete restrict,
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  requested_by uuid not null references trpg_hq.hq_agents(agent_id) on delete restrict,
  question_text text not null check (char_length(question_text) between 1 and 4000),
  released_hq_minute bigint not null check (released_hq_minute >= 0),
  event_key text not null unique,
  released_at timestamptz not null default now()
);
create index hq_clara_releases_by_team
  on trpg_hq.hq_clara_releases(team_id,released_at desc);

alter table trpg_hq.hq_clara_observations enable row level security;
alter table trpg_hq.hq_clara_releases enable row level security;
revoke all on trpg_hq.hq_clara_observations,trpg_hq.hq_clara_releases from public,anon,authenticated;

create or replace function trpg_hq.clara_record(
  p_team_id uuid,
  p_segment_id uuid,
  p_record_key text,
  p_expected_revision bigint,
  p_detail jsonb
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_existing trpg_hq.hq_clara_observations%rowtype;
  v_checkpoint public.gm_checkpoint_history%rowtype;
  v_id uuid;
  v_kind text;
  v_evidence_status text;
  v_path text[];
  v_value jsonb;
  v_sha text;
  v_reference text;
  v_method text;
  v_excerpt text;
  v_cp_version bigint;
  v_cp_sha text;
  v_source_kind text;
  v_access text;
  v_listable boolean;
  v_received bigint;
  v_data jsonb;
  v_hash text;
begin
  if p_record_key is null or char_length(p_record_key) not between 1 and 180
    or jsonb_typeof(p_detail) is distinct from 'object'
    or nullif(btrim(p_detail->>'subject_id'),'') is null
    or char_length(p_detail->>'subject_id')>180
    or nullif(btrim(p_detail->>'subject_label'),'') is null
    or char_length(p_detail->>'subject_label')>180
    or nullif(btrim(p_detail->>'topic'),'') is null
    or char_length(p_detail->>'topic')>400
    or nullif(btrim(p_detail->>'world_time_label'),'') is null
    or char_length(p_detail->>'world_time_label')>180
    or nullif(btrim(p_detail->>'summary'),'') is null
    or char_length(p_detail->>'summary')>4000
    or p_detail->>'subject_kind' not in
       ('synchronized_pc','field_npc','place','organization','community','world','threat')
    or p_detail->>'source_kind' not in ('verified_field','later_report')
    or p_detail->>'access_level' not in ('internal','available')
    or jsonb_typeof(p_detail->'finding') is null then
      raise exception 'hq_clara_invalid_record';
  end if;
  if jsonb_typeof(p_detail->'listable') is distinct from 'boolean'
    or jsonb_typeof(p_detail->'received_hq_minute') is distinct from 'number'
    or (p_detail->>'received_hq_minute') !~ '^[0-9]+$' then
    raise exception 'hq_clara_invalid_record_shape';
  end if;
  v_received:=(p_detail->>'received_hq_minute')::bigint;
  v_source_kind:=p_detail->>'source_kind';
  v_access:=p_detail->>'access_level';
  v_listable:=(p_detail->>'listable')::boolean;
  if v_access='internal' and v_listable then raise exception 'hq_clara_private_topic_cannot_be_listed'; end if;
  v_hash:=encode(sha256(convert_to(p_detail::text,'UTF8')),'hex');
  select * into v_team from trpg_hq.hq_teams where team_id=p_team_id for update;
  if not found then raise exception 'hq_team_not_found'; end if;
  select * into v_existing from trpg_hq.hq_clara_observations
     where team_id=p_team_id and record_key=p_record_key;
  if found then
    if v_existing.segment_id is distinct from p_segment_id
      or v_existing.input_sha256 is distinct from v_hash then
      raise exception 'hq_clara_record_key_conflict';
    end if;
    return jsonb_build_object('applied',false,'record_id',v_existing.record_id,
      'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  select * into v_segment from trpg_hq.hq_mission_segments where segment_id=p_segment_id;
  if not found then raise exception 'hq_clara_segment_not_found'; end if;
  select * into v_mission from trpg_hq.hq_missions where mission_id=v_segment.mission_id;
  if v_mission.team_id is distinct from p_team_id
    or v_segment.status<>'returned'
    or v_segment.terminal_verified_at is null then
    raise exception 'hq_clara_requires_same_team_returned_field_segment';
  end if;
  if v_received>v_team.hq_elapsed_minutes then
    raise exception 'hq_clara_future_observation_not_allowed';
  end if;
  if v_source_kind='verified_field' then
    if jsonb_typeof(p_detail->'source_path') is distinct from 'array'
      or jsonb_typeof(p_detail->'source_value') is null
      or p_detail ? 'source_reference'
      or p_detail ? 'source_method'
      or p_detail ? 'source_excerpt' then
      raise exception 'hq_clara_field_provenance_shape';
    end if;
    if jsonb_array_length(p_detail->'source_path') not between 2 and 7
      or exists(select 1 from jsonb_array_elements(p_detail->'source_path') as e(value)
        where jsonb_typeof(e.value)<>'string'
        or char_length(e.value#>>'{}')=0) then
      raise exception 'hq_clara_invalid_field_path';
    end if;
    select array_agg(value order by n) into v_path from
      jsonb_array_elements_text(p_detail->'source_path') with ordinality as e(value,n);
    if v_path[1] not in ('pcs','world_delta','npc_contexts','story_context',
      'scene_context','ongoing_consequences','runtime')
      or (v_path[1]='runtime' and v_path[2]<>'ending_state') then
      raise exception 'hq_clara_field_path_not_permitted';
    end if;
    select * into v_checkpoint from public.gm_checkpoint_history
      where session_id=v_segment.session_id
        and version=v_segment.verified_checkpoint_version
        and state_sha256=v_segment.verified_state_sha256
        and status='verified';
    if not found or encode(sha256(convert_to(v_checkpoint.state_json,'UTF8')),'hex')
      is distinct from v_checkpoint.state_sha256 then
      raise exception 'hq_clara_verified_field_checkpoint_unavailable';
    end if;
    v_value:=jsonb_extract_path(v_checkpoint.state_json::jsonb,variadic v_path);
    if v_value is null or v_value is distinct from p_detail->'source_value' then
      raise exception 'hq_clara_claim_not_exact_checkpoint_value';
    end if;
    v_evidence_status:='exact_checkpoint_value';
    v_cp_version:=v_checkpoint.version;
    v_cp_sha:=v_checkpoint.state_sha256;
  else
    if nullif(btrim(p_detail->>'source_reference'),'') is null
      or nullif(btrim(p_detail->>'source_method'),'') is null
      or nullif(btrim(p_detail->>'source_excerpt'),'') is null
      or char_length(p_detail->>'source_reference')>2000
      or char_length(p_detail->>'source_method')>180
      or char_length(p_detail->>'source_excerpt')>10000
      or p_detail ? 'source_path'
      or p_detail ? 'source_value' then
      raise exception 'hq_clara_later_report_missing_attribution';
    end if;
    if v_received<v_segment.return_hq_minute then
      raise exception 'hq_clara_later_report_predates_return';
    end if;
    v_reference:=p_detail->>'source_reference';
    v_method:=p_detail->>'source_method';
    v_excerpt:=p_detail->>'source_excerpt';
    v_evidence_status:='attributed_report';
  end if;
  insert into trpg_hq.hq_clara_observations(
    team_id,segment_id,record_key,subject_kind,subject_id,subject_label,
    topic,source_kind,evidence_status,world_time_label,received_hq_minute,
    checkpoint_version,checkpoint_sha256,source_path,source_value,
    source_reference,source_method,source_excerpt,finding,summary,
    access_level,listable,input_sha256
  ) values(
    p_team_id,p_segment_id,p_record_key,p_detail->>'subject_kind',
    p_detail->>'subject_id',p_detail->>'subject_label',
    p_detail->>'topic',v_source_kind,v_evidence_status,
    p_detail->>'world_time_label',v_received,
    v_cp_version,v_cp_sha,v_path,v_value,
    v_reference,v_method,v_excerpt,p_detail->'finding',p_detail->>'summary',
    v_access,v_listable,v_hash
  ) returning record_id into v_id;
  -- Keep metadata generic: private/unreleased subject and details never enter HQ common event log.
  v_data:=jsonb_build_object('record_id',v_id,'segment_id',p_segment_id,
    'access_level',v_access,'evidence_status',v_evidence_status);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,actor_key,
    listened_by,audience,summary,event_data,request_sha256)
  values(p_team_id,'clara:'||v_id::text||':recorded','clara_archive_recorded',
    v_team.hq_elapsed_minutes,'npc:clara','[]'::jsonb,'[]'::jsonb,
    '클라라가 출처가 구분된 비공개 기록을 보관했다',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=p_team_id;
  return jsonb_build_object('applied',true,'record_id',v_id,
    'evidence_status',v_evidence_status,'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.clara_catalog(
  p_team_id uuid,p_player_id uuid
)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
begin
  if not exists(select 1 from trpg_hq.hq_team_members
       where team_id=p_team_id and agent_id=p_player_id) then
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
       where team_id=v_team.team_id and agent_id=p_player_id) then
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
       where team_id=p_team_id and agent_id=p_player_id) then
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
alter default privileges in schema trpg_hq revoke execute on functions from public;
