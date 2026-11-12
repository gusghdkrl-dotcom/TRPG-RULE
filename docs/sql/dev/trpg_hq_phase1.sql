-- DEV ONLY / TIME AGENT HQ phase 1. Target project: trpg-time-agent-dev.
-- This is a NEW isolated schema, not a migration for the existing production DB.
-- Source: TIME_AGENT_CONCEPT_DRAFT.md v0.8 §§16-17,26,28-32.
-- HQ time is an elapsed logical minute count; real-world date/year is not fixed by this schema.
-- Do not store secrets, private production saves, or real player state here.

create schema if not exists trpg_hq;
revoke all on schema trpg_hq from public, anon, authenticated;

create table trpg_hq.hq_agents (
  agent_id uuid primary key references trpg_cards.players(id) on delete restrict,
  qualification text not null default 'recruit'
    check (qualification in ('recruit','training_qualified','full_agent')),
  training_completed boolean not null default false,
  chronicle_completed boolean not null default false,
  personal_state jsonb not null default '{}'::jsonb
    check (jsonb_typeof(personal_state)='object'),
  joined_at timestamptz not null default now()
);

create table trpg_hq.hq_teams (
  team_id uuid primary key default gen_random_uuid(),
  team_key text not null unique check (char_length(team_key) between 1 and 180),
  hq_elapsed_minutes bigint not null default 0 check (hq_elapsed_minutes >= 0),
  revision bigint not null default 0 check (revision >= 0),
  current_state jsonb not null default '{}'::jsonb
    check (jsonb_typeof(current_state)='object'),
  created_at timestamptz not null default now()
);

create table trpg_hq.hq_team_members (
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  agent_id uuid not null references trpg_hq.hq_agents(agent_id) on delete restrict,
  joined_at_minutes bigint not null default 0 check (joined_at_minutes >= 0),
  left_at_minutes bigint check (left_at_minutes is null or left_at_minutes >= joined_at_minutes),
  primary key (team_id,agent_id)
);
create unique index hq_one_active_team_per_agent
 on trpg_hq.hq_team_members(agent_id) where left_at_minutes is null;

create table trpg_hq.hq_actor_states (
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  actor_key text not null check (char_length(actor_key) between 1 and 120),
  state_data jsonb not null default '{}'::jsonb
    check (jsonb_typeof(state_data)='object'),
  revision bigint not null default 0 check (revision >= 0),
  last_event_key text,
  primary key (team_id,actor_key)
);

create table trpg_hq.hq_missions (
  mission_id uuid primary key default gen_random_uuid(),
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  campaign_id text not null unique references trpg_cards.campaigns(campaign_id) on delete restrict,
  mission_scale text not null check (mission_scale in ('major','chronicle')),
  status text not null default 'preparing'
    check (status in ('preparing','field_active','completed','failed')),
  risk_level text not null default 'unassessed'
    check (risk_level in ('I','II','III','IV','V','unassessed')),
  general_goal text not null default '진실을 밝히고 피해를 최소화하라.',
  preassigned_objectives jsonb not null default '[]'::jsonb
    check (jsonb_typeof(preassigned_objectives)='array'),
  briefing_record jsonb not null default '{}'::jsonb
    check (jsonb_typeof(briefing_record)='object'),
  created_at_hq_minutes bigint not null check (created_at_hq_minutes >= 0),
  created_at timestamptz not null default now()
);
create index hq_missions_by_team on trpg_hq.hq_missions(team_id,created_at desc);

create table trpg_hq.hq_mission_segments (
  segment_id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references trpg_hq.hq_missions(mission_id) on delete restrict,
  segment_key text not null check (char_length(segment_key) between 1 and 180),
  session_id text not null check (char_length(session_id) between 1 and 180),
  status text not null default 'prepared'
    check (status in ('prepared','field_active','terminal_confirmed','returned')),
  verified_checkpoint_version bigint check (verified_checkpoint_version is null or verified_checkpoint_version>=1),
  verified_state_sha256 text check (verified_state_sha256 is null or verified_state_sha256 ~ '^[0-9a-f]{64}$'),
  terminal_result jsonb,
  evaluation jsonb,
  return_event_key text unique,
  return_hq_minute bigint check (return_hq_minute is null or return_hq_minute>=0),
  unique (mission_id,segment_key)
);
create index hq_segments_by_session on trpg_hq.hq_mission_segments(session_id);

create table trpg_hq.hq_events (
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  event_key text not null check (char_length(event_key) between 1 and 180),
  event_kind text not null check (char_length(event_kind) between 1 and 100),
  hq_minute bigint not null check (hq_minute >= 0),
  actor_key text,
  listened_by jsonb not null default '[]'::jsonb
    check (jsonb_typeof(listened_by)='array'),
  audience jsonb not null default '[]'::jsonb
    check (jsonb_typeof(audience)='array'),
  summary text not null,
  event_data jsonb not null default '{}'::jsonb
    check (jsonb_typeof(event_data)='object'),
  request_sha256 text not null check (request_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  primary key (team_id,event_key)
);
create index hq_events_recent_by_team on trpg_hq.hq_events(team_id,hq_minute desc,created_at desc);

alter table trpg_hq.hq_agents enable row level security;
alter table trpg_hq.hq_teams enable row level security;
alter table trpg_hq.hq_team_members enable row level security;
alter table trpg_hq.hq_actor_states enable row level security;
alter table trpg_hq.hq_missions enable row level security;
alter table trpg_hq.hq_mission_segments enable row level security;
alter table trpg_hq.hq_events enable row level security;
revoke all on all tables in schema trpg_hq from public,anon,authenticated;

create or replace function trpg_hq.jsonb_deep_merge(p_base jsonb,p_patch jsonb)
returns jsonb
language plpgsql immutable
set search_path to 'pg_catalog'
as $hq$
declare
  v_result jsonb;
  v_key text;
  v_value jsonb;
begin
  if jsonb_typeof(p_base) is distinct from 'object'
     or jsonb_typeof(p_patch) is distinct from 'object' then
    return p_patch;
  end if;
  v_result:=p_base;
  for v_key,v_value in select key,value from jsonb_each(p_patch)
  loop
    v_result:=jsonb_set(
      v_result,array[v_key],
      trpg_hq.jsonb_deep_merge(v_result->v_key,v_value),true);
  end loop;
  return v_result;
end $hq$;

create or replace function trpg_hq.create_team(p_team_key text,p_agent_ids uuid[])
returns jsonb
language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team_id uuid;
  v_total integer;
  v_distinct integer;
  v_existing integer;
  v_matches integer;
begin
  if p_team_key is null or char_length(p_team_key) not between 1 and 180 then
    raise exception 'hq_invalid_team_key';
  end if;
  v_total:=coalesce(array_length(p_agent_ids,1),0);
  if v_total not between 1 and 3 then raise exception 'hq_team_size_must_be_1_to_3'; end if;
  select count(distinct x),count(p.id) into v_distinct,v_matches
  from unnest(p_agent_ids) as u(x)
  left join trpg_cards.players p on p.id=u.x;
  if v_distinct <> v_total or v_matches <> v_total then
    raise exception 'hq_agents_must_be_distinct_registered_card_players';
  end if;
  insert into trpg_hq.hq_agents(agent_id)
    select unnest(p_agent_ids) on conflict (agent_id) do nothing;
  insert into trpg_hq.hq_teams(team_key) values(p_team_key)
    on conflict (team_key) do nothing;
  select team_id into v_team_id from trpg_hq.hq_teams
    where team_key=p_team_key for update;
  select count(*) into v_existing from trpg_hq.hq_team_members
    where team_id=v_team_id;
  if v_existing=0 then
    insert into trpg_hq.hq_team_members(team_id,agent_id)
      select v_team_id,unnest(p_agent_ids);
  else
    select count(*) into v_matches from trpg_hq.hq_team_members
      where team_id=v_team_id and left_at_minutes is null
        and agent_id=any(p_agent_ids);
    if v_existing<>v_total or v_matches<>v_total then
      raise exception 'hq_existing_team_membership_conflict';
    end if;
  end if;
  return jsonb_build_object('team_id',v_team_id,'team_key',p_team_key,'members',v_total);
end $hq$;

create or replace function trpg_hq.record_event(
  p_team_id uuid,
  p_event_key text,
  p_expected_revision bigint,
  p_event_kind text,
  p_actor_key text,
  p_listened_by jsonb,
  p_audience jsonb,
  p_summary text,
  p_event_data jsonb,
  p_team_changes jsonb,
  p_actor_changes jsonb,
  p_elapsed_minutes bigint default 0
)
returns jsonb
language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_existing trpg_hq.hq_events%rowtype;
  v_hash text;
  v_request jsonb;
  v_next_minute bigint;
  v_actor text;
  v_patch jsonb;
begin
  if p_event_key is null or char_length(p_event_key) not between 1 and 180
    or p_event_kind is null or char_length(p_event_kind) not between 1 and 100
    or p_summary is null or char_length(p_summary)=0 then
      raise exception 'hq_invalid_event_fields';
  end if;
  if p_event_kind in ('mission_return','reward_granted','terminal_verified','qualification_granted') then
    raise exception 'hq_protected_event_requires_specialized_verified_handler';
  end if;
  if p_elapsed_minutes is null or p_elapsed_minutes<0
    or jsonb_typeof(p_listened_by) is distinct from 'array'
    or jsonb_typeof(p_audience) is distinct from 'array'
    or jsonb_typeof(p_event_data) is distinct from 'object'
    or jsonb_typeof(p_team_changes) is distinct from 'object'
    or jsonb_typeof(p_actor_changes) is distinct from 'object' then
      raise exception 'hq_invalid_event_payload';
  end if;
  v_request:=jsonb_build_object('kind',p_event_kind,'actor',p_actor_key,
    'listeners',p_listened_by,'audience',p_audience,'summary',p_summary,
    'data',p_event_data,'team_patch',p_team_changes,
    'actor_patch',p_actor_changes,'elapsed',p_elapsed_minutes);
  v_hash:=encode(sha256(convert_to(v_request::text,'UTF8')),'hex');
  select * into v_team from trpg_hq.hq_teams
    where team_id=p_team_id for update;
  if not found then raise exception 'hq_team_not_found'; end if;
  select * into v_existing from trpg_hq.hq_events
    where team_id=p_team_id and event_key=p_event_key;
  if found then
    if v_existing.request_sha256<>v_hash then
      raise exception 'hq_same_event_key_with_different_content';
    end if;
    return jsonb_build_object('applied',false,'event_key',p_event_key,
      'event_hq_minute',v_existing.hq_minute,
      'current_revision',v_team.revision,'current_hq_minute',v_team.hq_elapsed_minutes);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  v_next_minute:=v_team.hq_elapsed_minutes+p_elapsed_minutes;
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
    values(p_team_id,p_event_key,p_event_kind,v_next_minute,
    p_actor_key,p_listened_by,p_audience,p_summary,p_event_data,v_hash);
  update trpg_hq.hq_teams set
    revision=revision+1,
    hq_elapsed_minutes=v_next_minute,
    current_state=trpg_hq.jsonb_deep_merge(current_state,p_team_changes)
    where team_id=p_team_id;
  for v_actor,v_patch in select key,value from jsonb_each(p_actor_changes)
  loop
    if char_length(v_actor) not between 1 and 120
      or jsonb_typeof(v_patch) is distinct from 'object' then
      raise exception 'hq_invalid_actor_patch';
    end if;
    insert into trpg_hq.hq_actor_states(team_id,actor_key,state_data,revision,last_event_key)
    values(p_team_id,v_actor,v_patch,1,p_event_key)
    on conflict (team_id,actor_key) do update set
      state_data=trpg_hq.jsonb_deep_merge(trpg_hq.hq_actor_states.state_data,excluded.state_data),
      revision=trpg_hq.hq_actor_states.revision+1,
      last_event_key=excluded.last_event_key;
  end loop;
  return jsonb_build_object('applied',true,'event_key',p_event_key,
    'current_revision',v_team.revision+1,'current_hq_minute',v_next_minute);
end $hq$;

revoke all on all functions in schema trpg_hq from public, anon, authenticated;
alter default privileges in schema trpg_hq revoke execute on functions from public;
