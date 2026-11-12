-- DEV ONLY: independently remembered personal questions on a Clara record already
-- shared to the team. Shared factual access != identical personal curiosity.
-- New repeat question needs its own event key and its actual agent UUID.

create table trpg_hq.hq_clara_followup_questions (
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  question_key text not null check (char_length(question_key) between 1 and 150),
  record_id uuid not null references trpg_hq.hq_clara_observations(record_id) on delete restrict,
  requested_by uuid not null references trpg_hq.hq_agents(agent_id) on delete restrict,
  question_text text not null check (char_length(question_text) between 1 and 4000),
  asked_at_hq_minute bigint not null check (asked_at_hq_minute>=0),
  request_sha256 text not null check (request_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  primary key(team_id,question_key),
  foreign key(team_id,requested_by)
    references trpg_hq.hq_team_members(team_id,agent_id) on delete restrict
);
create index hq_clara_followups_by_agent
  on trpg_hq.hq_clara_followup_questions(team_id,requested_by,asked_at_hq_minute);

alter table trpg_hq.hq_clara_followup_questions enable row level security;
revoke all on trpg_hq.hq_clara_followup_questions from public,anon,authenticated;

create or replace function trpg_hq.clara_record_followup_question(
  p_record_id uuid,p_requested_by uuid,p_question_key text,
  p_expected_revision bigint,p_question_text text
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_record trpg_hq.hq_clara_observations%rowtype;
  v_team trpg_hq.hq_teams%rowtype;
  v_old trpg_hq.hq_clara_followup_questions%rowtype;
  v_hash text;
  v_data jsonb;
begin
  if p_question_key is null or char_length(p_question_key) not between 1 and 150
    or p_question_text is null or char_length(btrim(p_question_text)) not between 1 and 4000 then
    raise exception 'hq_clara_invalid_personal_question';
  end if;
  select * into v_record from trpg_hq.hq_clara_observations where record_id=p_record_id;
  if not found then raise exception 'hq_clara_record_not_found';end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_record.team_id for update;
  if not exists(select 1 from trpg_hq.hq_team_members
    where team_id=v_team.team_id and agent_id=p_requested_by
      and left_at_minutes is null) then
    raise exception 'hq_clara_questioner_not_active_team_member';
  end if;
  if v_record.access_level<>'available'
    or not exists(select 1 from trpg_hq.hq_clara_releases r
      where r.record_id=p_record_id and r.team_id=v_team.team_id) then
    raise exception 'hq_clara_followup_requires_released_available_record';
  end if;
  v_hash:=encode(sha256(convert_to(jsonb_build_object(
    'record_id',p_record_id,'requested_by',p_requested_by,
    'question_key',p_question_key,'question_text',p_question_text)::text,'UTF8')),'hex');
  select * into v_old from trpg_hq.hq_clara_followup_questions
    where team_id=v_team.team_id and question_key=p_question_key;
  if found then
    if v_old.request_sha256 is distinct from v_hash then
      raise exception 'hq_clara_personal_question_key_conflict';
    end if;
    return jsonb_build_object('applied',false,'question_key',p_question_key,
      'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',
      p_expected_revision,v_team.revision;
  end if;
  insert into trpg_hq.hq_clara_followup_questions(
    team_id,question_key,record_id,requested_by,question_text,
    asked_at_hq_minute,request_sha256
  ) values(v_team.team_id,p_question_key,p_record_id,p_requested_by,
    p_question_text,v_team.hq_elapsed_minutes,v_hash);
  -- Generic shared metadata: neither the actual question nor its author's UUID.
  v_data:=jsonb_build_object('record_id',p_record_id,
    'privacy','separate_personal_question_record');
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,
    'clara-followup:'||encode(sha256(convert_to(p_question_key,'UTF8')),'hex'),
    'clara_personal_followup',v_team.hq_elapsed_minutes,
    'npc:clara','[]'::jsonb,'[]'::jsonb,
    '클라라의 이미 공개된 자료에 대한 개인별 추가 질문이 비공개 원장에 기록됨',
    v_data,encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'question_key',p_question_key,
    'current_revision',v_team.revision+1);
end $hq$;

-- Preserve original first-release question + every later per-agent question.
create or replace function trpg_hq.load_npc_agent_context(
 p_team_id uuid,p_npc_key text,p_agent_id uuid
) returns jsonb
language plpgsql stable
set search_path to 'pg_catalog'
as $hq$
declare
  v_relation trpg_hq.hq_npc_agent_relations%rowtype;
  v_recent jsonb;
  v_clara_questions jsonb:='[]'::jsonb;
begin
  if p_npc_key not in ('npc:martin','npc:jayden','npc:clara','npc:dominic',
    'npc:samira','npc:leo','npc:seorin','npc:maya') then
    raise exception 'hq_npc_invalid_npc_key';
  end if;
  if not exists(select 1 from trpg_hq.hq_team_members m
    where m.team_id=p_team_id and m.agent_id=p_agent_id
      and m.left_at_minutes is null) then
    raise exception 'hq_npc_context_requires_active_team_member';
  end if;
  select * into v_relation from trpg_hq.hq_npc_agent_relations
    where team_id=p_team_id and npc_key=p_npc_key and agent_id=p_agent_id;
  select coalesce(jsonb_agg(jsonb_build_object(
     'event_key',x.event_key,'location',x.location,'hq_minute',x.hq_minute,
     'actually_heard',(
       select coalesce(jsonb_agg(jsonb_build_object(
         'speaker',v.value->>'speaker','text',v.value->>'text')
         order by v.ordinality),'[]'::jsonb)
       from jsonb_array_elements(x.utterances) with ordinality as v(value,ordinality)
       where (v.value->'heard_by') ? ('agent:'||p_agent_id::text)
          or v.value->>'speaker'='agent:'||p_agent_id::text))
      order by x.hq_minute,x.event_key),'[]'::jsonb)
  into v_recent from (
    select * from trpg_hq.hq_npc_interactions e
    where e.team_id=p_team_id and e.npc_key=p_npc_key
      and p_agent_id=any(e.present_agents)
    order by e.created_at desc,e.event_key desc limit 100
  ) x;
  if p_npc_key='npc:clara' then
    select coalesce(jsonb_agg(jsonb_build_object(
      'record_id',q.record_id,'subject_id',o.subject_id,
      'subject_label',o.subject_label,'question_text',q.question_text,
      'asked_at_hq_minute',q.question_hq_minute,
      'question_kind',q.question_kind,'question_key',q.question_key,
      'shared_fact_source',o.evidence_status)
      order by q.question_hq_minute,q.question_key),'[]'::jsonb)
    into v_clara_questions
    from (
      select r.record_id,r.question_text,r.released_hq_minute as question_hq_minute,
        'initial_release'::text as question_kind,
        ('initial:'||r.record_id::text) as question_key
      from trpg_hq.hq_clara_releases r
      where r.team_id=p_team_id and r.requested_by=p_agent_id
      union all
      select f.record_id,f.question_text,f.asked_at_hq_minute,
        'followup_question'::text,f.question_key
      from trpg_hq.hq_clara_followup_questions f
      where f.team_id=p_team_id and f.requested_by=p_agent_id
    ) q join trpg_hq.hq_clara_observations o on o.record_id=q.record_id;
  end if;
  return jsonb_build_object(
    'team_id',p_team_id,'agent_id',p_agent_id,'npc_key',p_npc_key,
    'relation_state',coalesce(v_relation.state_data,'{}'::jsonb),
    'relation_revision',coalesce(v_relation.revision,0),
    'last_personal_event_key',v_relation.last_event_key,
    'experienced_interactions',v_recent,
    'clara_personal_questions',v_clara_questions
  );
end $hq$

create trigger hq_clara_followups_immutable
 before update or delete on trpg_hq.hq_clara_followup_questions
 for each row execute function trpg_hq.clara_forbid_mutation();

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
