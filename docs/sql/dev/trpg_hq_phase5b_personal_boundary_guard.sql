-- DEV ONLY: defensive boundaries for legacy team events and Clara personal questions.
-- Leaves historical test rows immutable; future events follow the tighter contract.

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
  -- Personal knowledge/attitudes must use NPC x agent immutable interactions.
  -- Do not write them to the team's generic NPC snapshot, where they could
  -- be mistakenly reused as another agent's private relationship.
  if exists(
    select 1 from jsonb_each(
      case when jsonb_typeof(p_actor_changes)='object'
        then p_actor_changes else '{}'::jsonb end) x(key,value)
    where x.key like 'npc:%'
      and jsonb_typeof(x.value)='object'
      and x.value ?| array['known_facts','attitudes','relationship',
        'relationships','agent_relations','personal_history','personal_memory',
        'player_relations','agent_memories']
  ) then
    raise exception 'hq_npc_personal_data_requires_individual_memory_rpc';
  end if;
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
  -- The exact player's question is stored ONLY in hq_clara_releases.
  -- Do not duplicate a personal query in the team-wide event ledger.
  v_data:=jsonb_build_object('record_id',p_record_id,
    'privacy','personal_question_in_private_release_record');
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

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
