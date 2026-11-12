-- DEV ONLY. NPC-specific per-agent relationships, speech listeners and personal experiences.
-- Source: TIME_AGENT_CONCEPT_DRAFT.md §§17,26,28,32.
-- All caller-access through privileged keeper-side, NOT direct public/anon/auth API.

create table trpg_hq.hq_npc_agent_relations (
  team_id uuid not null,
  agent_id uuid not null,
  npc_key text not null check (npc_key in
    ('npc:martin','npc:jayden','npc:clara','npc:dominic',
     'npc:samira','npc:leo','npc:seorin','npc:maya')),
  state_data jsonb not null default '{}'::jsonb check (jsonb_typeof(state_data)='object'),
  revision bigint not null default 0 check (revision>=0),
  last_event_key text,
  changed_at_hq_minute bigint not null default 0 check (changed_at_hq_minute>=0),
  primary key(team_id,agent_id,npc_key),
  foreign key (team_id,agent_id)
    references trpg_hq.hq_team_members(team_id,agent_id) on delete restrict
);

create table trpg_hq.hq_npc_interactions (
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  event_key text not null check (char_length(event_key) between 1 and 180),
  npc_key text not null check (npc_key in
    ('npc:martin','npc:jayden','npc:clara','npc:dominic',
     'npc:samira','npc:leo','npc:seorin','npc:maya')),
  present_agents uuid[] not null check (cardinality(present_agents) between 1 and 3),
  speaker_key text not null,
  location text not null check (char_length(location) between 1 and 240),
  summary text not null check (char_length(summary) between 1 and 4000),
  utterances jsonb not null check (jsonb_typeof(utterances)='array'),
  observations jsonb not null check (jsonb_typeof(observations)='object'),
  changes_by_agent jsonb not null check (jsonb_typeof(changes_by_agent)='object'),
  hq_minute bigint not null check (hq_minute>=0),
  elapsed_minutes bigint not null check (elapsed_minutes>=0),
  request_sha256 text not null check (request_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  primary key(team_id,event_key)
);
create index hq_npc_interactions_by_person
  on trpg_hq.hq_npc_interactions(team_id,npc_key,hq_minute desc);
create index hq_npc_relations_by_agent
  on trpg_hq.hq_npc_agent_relations(agent_id,npc_key);

alter table trpg_hq.hq_npc_agent_relations enable row level security;
alter table trpg_hq.hq_npc_interactions enable row level security;
revoke all on trpg_hq.hq_npc_agent_relations,trpg_hq.hq_npc_interactions
  from public,anon,authenticated;

create or replace function trpg_hq.record_npc_interaction(
 p_team_id uuid, p_event_key text, p_expected_revision bigint, p_payload jsonb
) returns jsonb
language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_existing trpg_hq.hq_npc_interactions%rowtype;
  v_npc text;
  v_speaker text;
  v_location text;
  v_summary text;
  v_elapsed bigint;
  v_minute bigint;
  v_participants uuid[];
  v_count integer;
  v_utterance jsonb;
  v_who text;
  v_listener text;
  v_key text;
  v_entry jsonb;
  v_patch jsonb;
  v_cause text;
  v_agent uuid;
  v_hash text;
  v_public_event_data jsonb;
begin
  if p_event_key is null or char_length(p_event_key) not between 1 and 180
    or jsonb_typeof(p_payload) is distinct from 'object' then
    raise exception 'hq_npc_invalid_interaction';
  end if;
  v_npc:=p_payload->>'npc_key';
  v_speaker:=p_payload->>'speaker_key';
  v_location:=p_payload->>'location';
  v_summary:=p_payload->>'summary';
  if v_npc not in ('npc:martin','npc:jayden','npc:clara','npc:dominic',
     'npc:samira','npc:leo','npc:seorin','npc:maya')
    or nullif(btrim(v_location),'') is null or char_length(v_location)>240
    or nullif(btrim(v_summary),'') is null or char_length(v_summary)>4000
    or jsonb_typeof(p_payload->'present_agents') is distinct from 'array'
    or jsonb_array_length(p_payload->'present_agents') not between 1 and 3
    or jsonb_typeof(p_payload->'utterances') is distinct from 'array'
    or jsonb_typeof(p_payload->'observations') is distinct from 'object'
    or jsonb_typeof(p_payload->'changes_by_agent') is distinct from 'object'
    or jsonb_typeof(p_payload->'elapsed_minutes') is distinct from 'number'
    or (p_payload->>'elapsed_minutes') !~ '^[0-9]+$' then
      raise exception 'hq_npc_invalid_interaction_payload';
  end if;
  v_elapsed:=(p_payload->>'elapsed_minutes')::bigint;
  if exists(select 1 from jsonb_array_elements(p_payload->'present_agents') a(v)
    where jsonb_typeof(a.v)<>'string') then
    raise exception 'hq_npc_present_agents_must_be_uuids';
  end if;
  select array_agg(x.id order by x.id),count(*) into v_participants,v_count
    from (select v::uuid as id from jsonb_array_elements_text(p_payload->'present_agents') q(v)) x;
  if v_count<>coalesce((select count(distinct id) from unnest(v_participants) k(id)),0) then
    raise exception 'hq_npc_duplicate_present_agent';
  end if;
  if v_speaker is distinct from v_npc and
     not exists(select 1 from unnest(v_participants) a(id)
       where v_speaker='agent:'||a.id::text) then
    raise exception 'hq_npc_speaker_not_present';
  end if;
  for v_utterance in select value from jsonb_array_elements(p_payload->'utterances')
  loop
    if jsonb_typeof(v_utterance) <> 'object'
      or nullif(btrim(v_utterance->>'text'),'') is null
      or char_length(v_utterance->>'text')>10000
      or jsonb_typeof(v_utterance->'heard_by')<>'array'
      or jsonb_array_length(v_utterance->'heard_by')=0 then
      raise exception 'hq_npc_invalid_utterance';
    end if;
    v_who:=v_utterance->>'speaker';
    if v_who is distinct from v_npc
      and not exists(select 1 from unnest(v_participants) a(id)
        where v_who='agent:'||a.id::text) then
      raise exception 'hq_npc_utterance_speaker_not_present';
    end if;
    for v_listener in select value from jsonb_array_elements_text(v_utterance->'heard_by')
    loop
      if v_listener is distinct from v_npc
        and not exists(select 1 from unnest(v_participants) a(id)
          where v_listener='agent:'||a.id::text) then
        raise exception 'hq_npc_listener_not_present';
      end if;
    end loop;
  end loop;
  for v_key,v_entry in select key,value from jsonb_each(p_payload->'changes_by_agent')
  loop
    if v_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'hq_npc_invalid_changed_agent_key';
    end if;
    v_agent:=v_key::uuid;
    if not (v_agent=any(v_participants)) then
      raise exception 'hq_npc_change_for_absent_agent';
    end if;
    if jsonb_typeof(v_entry)<>'object'
      or nullif(btrim(v_entry->>'basis'),'') is null
      or jsonb_typeof(v_entry->'patch')<>'object'
      or v_entry->'patch'='{}'::jsonb
      or (select bool_or(k not in ('attitude','known_facts',
        'relationship','personal_history','open_topics','commitments'))
          from jsonb_object_keys(v_entry->'patch') as k) is true then
      raise exception 'hq_npc_invalid_personal_change';
    end if;
  end loop;
  v_hash:=encode(sha256(convert_to(p_payload::text,'UTF8')),'hex');
  select * into v_team from trpg_hq.hq_teams
    where team_id=p_team_id for update;
  if not found then raise exception 'hq_team_not_found'; end if;
  select * into v_existing from trpg_hq.hq_npc_interactions
    where team_id=p_team_id and event_key=p_event_key;
  if found then
    if v_existing.request_sha256 is distinct from v_hash then
      raise exception 'hq_npc_interaction_replay_conflict';
    end if;
    return jsonb_build_object('applied',false,'event_key',p_event_key,
      'hq_minute',v_existing.hq_minute,'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',
      p_expected_revision,v_team.revision;
  end if;
  if (select count(*) from trpg_hq.hq_team_members t
       where t.team_id=p_team_id and t.left_at_minutes is null
       and t.agent_id=any(v_participants))<>v_count then
    raise exception 'hq_npc_present_agent_not_active_team_member';
  end if;
  v_minute:=v_team.hq_elapsed_minutes+v_elapsed;
  insert into trpg_hq.hq_npc_interactions(
    team_id,event_key,npc_key,present_agents,speaker_key,location,summary,
    utterances,observations,changes_by_agent,hq_minute,elapsed_minutes,request_sha256
  ) values(p_team_id,p_event_key,v_npc,v_participants,v_speaker,
    v_location,v_summary,p_payload->'utterances',
    p_payload->'observations',p_payload->'changes_by_agent',
    v_minute,v_elapsed,v_hash);
  -- Only update agent-specific states for explicitly specified agents.
  for v_key,v_entry in select key,value from jsonb_each(p_payload->'changes_by_agent')
  loop
    v_agent:=v_key::uuid;
    v_patch:=v_entry->'patch';
    v_cause:=v_entry->>'basis';
    insert into trpg_hq.hq_npc_agent_relations(
      team_id,agent_id,npc_key,state_data,revision,last_event_key,changed_at_hq_minute
    ) values (
      p_team_id,v_agent,v_npc,
      trpg_hq.jsonb_deep_merge(v_patch,
        jsonb_build_object('last_change_basis',
          jsonb_build_object('event_key',p_event_key,'reason',v_cause))),
      1,p_event_key,v_minute
    ) on conflict(team_id,agent_id,npc_key) do update set
      state_data=trpg_hq.jsonb_deep_merge(trpg_hq.hq_npc_agent_relations.state_data,
        excluded.state_data),
      revision=trpg_hq.hq_npc_agent_relations.revision+1,
      last_event_key=excluded.last_event_key,
      changed_at_hq_minute=excluded.changed_at_hq_minute;
  end loop;
  update trpg_hq.hq_teams set revision=revision+1,
    hq_elapsed_minutes=v_minute where team_id=p_team_id;
  -- Global event ledger has NO personal content, names, or individual relationships.
  v_public_event_data:=jsonb_build_object('interaction_key',p_event_key,
    'npc_key',v_npc,'privacy','individual_hearing_bound');
  insert into trpg_hq.hq_events(
    team_id,event_key,event_kind,hq_minute,actor_key,listened_by,audience,
    summary,event_data,request_sha256
  ) values(p_team_id,p_event_key,'npc_personal_interaction',v_minute,
    v_npc,'[]'::jsonb,'[]'::jsonb,
    '본부 직원과 요원 간 실제 교류가 비공개 개인별 원장에 기록됨',
    v_public_event_data,
    encode(sha256(convert_to(v_public_event_data::text,'UTF8')),'hex'));
  return jsonb_build_object('applied',true,'event_key',p_event_key,
    'npc_key',v_npc,'current_revision',v_team.revision+1,
    'hq_minute',v_minute);
end $hq$;

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
     ) order by x.hq_minute,x.event_key),'[]'::jsonb)
  into v_recent from (
    select * from trpg_hq.hq_npc_interactions e
    where e.team_id=p_team_id and e.npc_key=p_npc_key
      and p_agent_id=any(e.present_agents)
    order by e.created_at desc,e.event_key desc limit 100
  ) x;
  if p_npc_key='npc:clara' then
    select coalesce(jsonb_agg(jsonb_build_object(
      'record_id',r.record_id,'subject_id',o.subject_id,
      'subject_label',o.subject_label,'question_text',r.question_text,
      'asked_at_hq_minute',r.released_hq_minute,
      'shared_fact_source',o.evidence_status)
      order by r.released_at,r.record_id),'[]'::jsonb)
    into v_clara_questions
    from trpg_hq.hq_clara_releases r
    join trpg_hq.hq_clara_observations o on o.record_id=r.record_id
    where r.team_id=p_team_id and r.requested_by=p_agent_id;
  end if;
  return jsonb_build_object(
    'team_id',p_team_id,'agent_id',p_agent_id,'npc_key',p_npc_key,
    'relation_state',coalesce(v_relation.state_data,'{}'::jsonb),
    'relation_revision',coalesce(v_relation.revision,0),
    'last_personal_event_key',v_relation.last_event_key,
    'experienced_interactions',v_recent,
    'clara_personal_questions',v_clara_questions
  );
end $hq$;

-- Append-only dialogue sources; no editing private historical utterances or changed-by-agent basis.
create or replace function trpg_hq.reject_npc_interaction_mutation()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
begin
  raise exception 'hq_npc_interactions_append_only';
end $hq$;
create trigger hq_npc_interactions_immutable
 before update or delete on trpg_hq.hq_npc_interactions
 for each row execute function trpg_hq.reject_npc_interaction_mutation();

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
alter default privileges in schema trpg_hq revoke execute on functions from public;
