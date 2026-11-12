-- DEV ONLY. Clara archive defensive integrity: only append observed records.
-- Enforces provenance/temporal bounds even if a privileged client bypasses the RPC.

create or replace function trpg_hq.clara_guard_observation_insert()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_team trpg_hq.hq_teams%rowtype;
  v_checkpoint public.gm_checkpoint_history%rowtype;
  v_value jsonb;
  v_path text[];
begin
  select * into v_segment from trpg_hq.hq_mission_segments
    where segment_id=new.segment_id;
  if not found then raise exception 'hq_clara_guard_segment_missing'; end if;
  if not exists(select 1 from trpg_hq.hq_missions m
    where m.mission_id=v_segment.mission_id and m.team_id=new.team_id) then
    raise exception 'hq_clara_guard_team_mission_mismatch';
  end if;
  select * into v_team from trpg_hq.hq_teams where team_id=new.team_id;
  if v_segment.status<>'returned'
    or v_segment.terminal_verified_at is null
    or v_segment.return_hq_minute is null
    or new.received_hq_minute<v_segment.return_hq_minute
    or new.received_hq_minute>v_team.hq_elapsed_minutes then
    raise exception 'hq_clara_guard_observation_outside_real_returned_hq_time';
  end if;
  if new.source_kind='verified_field' then
    v_path:=new.source_path;
    if array_length(v_path,1) not between 2 and 7
      or exists(select 1 from unnest(v_path) x(k) where x.k is null or x.k='') then
      raise exception 'hq_clara_guard_invalid_field_path';
    end if;
    if v_path[1] not in ('pcs','world_delta','npc_contexts','story_context',
      'scene_context','ongoing_consequences','runtime')
      or (v_path[1]='runtime' and v_path[2]<>'ending_state') then
      raise exception 'hq_clara_guard_secret_source_path';
    end if;
    select * into v_checkpoint from public.gm_checkpoint_history
      where session_id=v_segment.session_id
      and version=v_segment.verified_checkpoint_version
      and state_sha256=v_segment.verified_state_sha256
      and status='verified';
    if not found or new.checkpoint_version is distinct from v_checkpoint.version
      or new.checkpoint_sha256 is distinct from v_checkpoint.state_sha256
      or encode(sha256(convert_to(v_checkpoint.state_json,'UTF8')),'hex')
        is distinct from v_checkpoint.state_sha256 then
      raise exception 'hq_clara_guard_checkpoint_mismatch';
    end if;
    v_value:=jsonb_extract_path(v_checkpoint.state_json::jsonb,variadic v_path);
    if v_value is null or new.source_value is distinct from v_value
      or new.evidence_status<>'exact_checkpoint_value' then
      raise exception 'hq_clara_guard_not_extracted_checkpoint_value';
    end if;
  elsif new.source_kind='later_report' then
    if new.evidence_status<>'attributed_report'
      or nullif(btrim(new.source_reference),'') is null
      or nullif(btrim(new.source_method),'') is null
      or nullif(btrim(new.source_excerpt),'') is null then
      raise exception 'hq_clara_guard_unattributed_later_report';
    end if;
  end if;
  return new;
end $hq$;
create trigger hq_clara_observation_insert_guard
 before insert on trpg_hq.hq_clara_observations
 for each row execute function trpg_hq.clara_guard_observation_insert();

create or replace function trpg_hq.clara_guard_release_insert()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_record trpg_hq.hq_clara_observations%rowtype;
  v_team trpg_hq.hq_teams%rowtype;
begin
  select * into v_record from trpg_hq.hq_clara_observations where record_id=new.record_id;
  select * into v_team from trpg_hq.hq_teams where team_id=new.team_id;
  if not found or v_record.team_id is distinct from new.team_id
    or v_record.access_level<>'available'
    or new.released_hq_minute is distinct from v_team.hq_elapsed_minutes
    or not exists(select 1 from trpg_hq.hq_team_members
        where team_id=new.team_id and agent_id=new.requested_by
          and left_at_minutes is null) then
    raise exception 'hq_clara_guard_illegal_release';
  end if;
  return new;
end $hq$;
create trigger hq_clara_release_insert_guard
 before insert on trpg_hq.hq_clara_releases
 for each row execute function trpg_hq.clara_guard_release_insert();

create or replace function trpg_hq.clara_forbid_mutation()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
begin
  raise exception 'hq_clara_append_only_history';
end $hq$;
create trigger hq_clara_observation_immutable
 before update or delete on trpg_hq.hq_clara_observations
 for each row execute function trpg_hq.clara_forbid_mutation();
create trigger hq_clara_release_immutable
 before update or delete on trpg_hq.hq_clara_releases
 for each row execute function trpg_hq.clara_forbid_mutation();

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
