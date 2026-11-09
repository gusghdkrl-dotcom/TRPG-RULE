-- TRPG-RULE: isolated TRPG State V2 checkpoint store.
-- Source version: 생존 호러 통합 경량판 2026-11-08.
-- Target: a new/empty Supabase project; never apply blindly to a live project.
-- Stored state_json is the exact original UTF-8 text, SHA-256 checked server-side.
-- Private canon documents are not stored here; their SHA must be externally verified.
-- Game writes require an authenticated *privileged Supabase connector*; ordinary
-- public/anon/authenticated Data API roles have no table/RPC permissions.
begin;

create table public.gm_checkpoint_history (
  session_id text not null check (length(session_id) between 1 and 180),
  version bigint not null check (version >= 1),
  event_id text not null check (length(event_id) between 1 and 255),
  attempt_id text not null check (length(attempt_id) between 1 and 180),
  parent_version bigint,
  parent_sha256 text,
  state_json text not null check (octet_length(state_json) between 2 and 5242880),
  state_sha256 text not null check (state_sha256 ~ '^[0-9a-f]{64}$'),
  canon_file_sha256 text not null check (canon_file_sha256 ~ '^[0-9a-f]{64}$'),
  rules_version text not null,
  state_schema_version text not null,
  save_mode text not null check (save_mode = 'DOCUMENT_BOUND'),
  document_bound_format text not null check (document_bound_format = 'DB1'),
  status text not null default 'pending' check (status in ('pending','verified')),
  created_at timestamptz not null default now(),
  verified_at timestamptz,
  primary key (session_id,version),
  unique (session_id,attempt_id),
  unique (session_id,event_id),
  check (
    (parent_version is null and parent_sha256 is null and version=1)
    or (parent_version=version-1 and parent_sha256 ~ '^[0-9a-f]{64}$')
  ),
  check (
    (status='pending' and verified_at is null)
    or (status='verified' and verified_at is not null)
  )
);
create index gm_checkpoint_latest_verified_idx
 on public.gm_checkpoint_history(session_id,version desc)
 where status='verified';
alter table public.gm_checkpoint_history enable row level security;
revoke all on table public.gm_checkpoint_history from public,anon,authenticated;

CREATE OR REPLACE FUNCTION public.trpg_v2_payload_issue(p_state_json text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  doc jsonb;
  k text;
  section text;
  a text[];
  b text[];
  required_sections constant text[] := array[
    'CANON_INDEX','WORLD_BASELINE','HIDDEN_TRUTH','WORLD_RULES',
    'NPC_BASELINES','EVIDENCE_BASELINES','LOCATION_BASELINES',
    'DRIVER_BASELINES','ENDING_CONDITIONS','PC_CONNECTIONS'];
begin
  if p_state_json is null or octet_length(p_state_json) < 2
     or octet_length(p_state_json) > 5242880 then
    return 'payload_size_invalid';
  end if;
  begin
    doc := p_state_json::jsonb;
  exception when others then
    return 'invalid_json';
  end;
  if jsonb_typeof(doc) is distinct from 'object' then return 'root_not_object'; end if;
  if doc->>'state_schema_version' is distinct from 'TRPG_STATE_V2' then
    return 'schema_version_mismatch';
  end if;
  if doc->>'save_mode' is distinct from 'DOCUMENT_BOUND'
     or doc->>'document_bound_format' is distinct from 'DB1' then
    return 'save_mode_mismatch';
  end if;
  foreach k in array array['session_id','campaign_id','rules_version'] loop
    if nullif(btrim(doc->>k),'') is null then return 'missing:'||k; end if;
  end loop;
  foreach k in array array[
    'checkpoint','canon_ref','change_coverage','world_delta','new_entities',
    'tombstones','pcs','runtime','story_context','npc_contexts',
    'scene_context','ongoing_consequences','critical_state_registry','manifest'
  ] loop
    if jsonb_typeof(doc->k) is distinct from 'object' then return 'object_required:'||k; end if;
  end loop;
  if jsonb_typeof(doc->'processed_event_ids') is distinct from 'array' then
    return 'array_required:processed_event_ids';
  end if;
  foreach k in array array['version','event_id','attempt_id','parent_version','parent_sha256'] loop
    if not (doc->'checkpoint' ? k) then return 'checkpoint_missing:'||k; end if;
  end loop;
  if (doc->'checkpoint'->>'version') !~ '^[1-9][0-9]*$'
     or nullif(doc->'checkpoint'->>'event_id','') is null
     or nullif(doc->'checkpoint'->>'attempt_id','') is null then
    return 'checkpoint_identity_invalid';
  end if;
  if doc->'checkpoint'->'parent_version' <> 'null'::jsonb and
     (doc->'checkpoint'->>'parent_version') !~ '^[1-9][0-9]*$' then
    return 'checkpoint_parent_invalid';
  end if;
  if doc->'checkpoint'->'parent_sha256' <> 'null'::jsonb and
     (doc->'checkpoint'->>'parent_sha256') !~ '^[0-9a-f]{64}$' then
    return 'checkpoint_parent_hash_invalid';
  end if;
  foreach k in array array['campaign_id','canon_id','filename','document_format','file_sha256','revision','section_ids'] loop
    if not (doc->'canon_ref' ? k) then return 'canon_missing:'||k; end if;
  end loop;
  if doc->'canon_ref'->>'campaign_id' is distinct from doc->>'campaign_id'
     or nullif(btrim(doc->'canon_ref'->>'canon_id'),'') is null
     or nullif(btrim(doc->'canon_ref'->>'filename'),'') is null
     or nullif(btrim(doc->'canon_ref'->>'document_format'),'') is null
     or (doc->'canon_ref'->>'file_sha256') !~ '^[0-9a-f]{64}$'
     or (doc->'canon_ref'->>'revision') !~ '^[1-9][0-9]*$' then
    return 'canon_identity_invalid';
  end if;
  if jsonb_typeof(doc->'canon_ref'->'section_ids') is distinct from 'array' then
    return 'canon_section_ids_invalid';
  end if;
  foreach section in array required_sections loop
    if not ((doc->'canon_ref'->'section_ids') ? section) then
      return 'canon_section_missing:'||section;
    end if;
  end loop;
  if doc->'change_coverage'->'complete_since_revision' is distinct from 'true'::jsonb then
    return 'coverage_not_complete';
  end if;
  if jsonb_typeof(doc->'change_coverage'->'baseline_entity_ids') is distinct from 'object'
     or jsonb_typeof(doc->'change_coverage'->'changed_entity_ids') is distinct from 'object' then
    return 'coverage_shape_invalid';
  end if;
  foreach k in array array['npcs','evidence','locations','routes','drivers','threats'] loop
    if jsonb_typeof(doc->'change_coverage'->'baseline_entity_ids'->k) is distinct from 'array'
       or jsonb_typeof(doc->'change_coverage'->'changed_entity_ids'->k) is distinct from 'array'
       or jsonb_typeof(doc->'world_delta'->k) is distinct from 'object' then
      return 'coverage_namespace_invalid:'||k;
    end if;
    if exists (
      select 1 from jsonb_array_elements(doc->'change_coverage'->'baseline_entity_ids'->k) e
      where jsonb_typeof(e.value) <> 'string'
    ) or exists (
      select 1 from jsonb_array_elements(doc->'change_coverage'->'changed_entity_ids'->k) e
      where jsonb_typeof(e.value) <> 'string'
    ) then return 'coverage_non_string:'||k; end if;
    if exists (
      select 1 from jsonb_array_elements_text(doc->'change_coverage'->'changed_entity_ids'->k) x
      group by x.value having count(*) > 1
    ) then return 'coverage_duplicate_changed:'||k; end if;
    select coalesce(array_agg(value order by value),array[]::text[])
       into a from jsonb_array_elements_text(doc->'change_coverage'->'changed_entity_ids'->k);
    select coalesce(array_agg(key order by key),array[]::text[])
       into b from jsonb_object_keys(doc->'world_delta'->k) as t(key);
    if a is distinct from b then return 'changed_delta_mismatch:'||k; end if;
  end loop;
  if jsonb_array_length(doc->'processed_event_ids') <> (
    select count(distinct value) from jsonb_array_elements_text(doc->'processed_event_ids')
  ) then return 'processed_event_duplicate'; end if;
  if jsonb_typeof(doc->'runtime'->'pending') is null
     or nullif(doc->'runtime'->>'phase','') is null
     or (doc->'runtime'->>'scene_turn') !~ '^[0-9]+$' then
    return 'runtime_incomplete';
  end if;
  if not (doc->'runtime' ? 'current_pc') then return 'runtime_current_pc_missing'; end if;
  if (select count(*) from jsonb_object_keys(doc->'pcs')) not between 1 and 3 then
    return 'pc_slot_count_invalid';
  end if;
  if exists (select 1 from jsonb_object_keys(doc->'pcs') as t(k) where t.k !~ '^P[1-3]$') then
    return 'pc_slot_invalid';
  end if;
  return null;
end;
$function$;

CREATE OR REPLACE FUNCTION public.trpg_v2_commit(p_session_id text, p_version bigint, p_event_id text, p_attempt_id text, p_parent_version bigint, p_parent_sha256 text, p_state_json text, p_state_sha256 text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  doc jsonb;
  issue text;
  actual_hash text;
  last_version bigint;
  last_hash text;
  prev public.gm_checkpoint_history%rowtype;
begin
  if nullif(p_session_id,'') is null or nullif(p_event_id,'') is null
     or nullif(p_attempt_id,'') is null or p_version is null then
    raise exception 'invalid_checkpoint_identity';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_session_id,0));
  issue := public.trpg_v2_payload_issue(p_state_json);
  if issue is not null then raise exception 'invalid_payload: %', issue; end if;
  doc := p_state_json::jsonb;
  actual_hash := encode(sha256(convert_to(p_state_json,'UTF8')),'hex');
  if actual_hash is distinct from p_state_sha256 then raise exception 'state_sha256_mismatch'; end if;
  if doc->>'session_id' is distinct from p_session_id
     or (doc->'checkpoint'->>'version')::bigint is distinct from p_version
     or doc->'checkpoint'->>'event_id' is distinct from p_event_id
     or doc->'checkpoint'->>'attempt_id' is distinct from p_attempt_id
     or (doc->'checkpoint'->>'parent_version')::bigint is distinct from p_parent_version
     or doc->'checkpoint'->>'parent_sha256' is distinct from p_parent_sha256 then
    raise exception 'checkpoint_tuple_mismatch';
  end if;
  if p_event_id is distinct from p_session_id||':cp'||p_version::text then
    raise exception 'checkpoint_event_id_mismatch';
  end if;
  select * into prev from public.gm_checkpoint_history
    where session_id=p_session_id and attempt_id=p_attempt_id;
  if found then
    if prev.version=p_version and prev.event_id=p_event_id
       and prev.parent_version is not distinct from p_parent_version
       and prev.parent_sha256 is not distinct from p_parent_sha256
       and prev.state_sha256=p_state_sha256 and prev.state_json=p_state_json then
      return jsonb_build_object('status',prev.status,'session_id',p_session_id,
         'version',p_version,'event_id',p_event_id,'attempt_id',p_attempt_id,
         'state_sha256',p_state_sha256,'idempotent_replay',true);
    end if;
    raise exception 'attempt_conflict';
  end if;
  if exists(select 1 from public.gm_checkpoint_history
     where session_id=p_session_id and status='pending') then
    raise exception 'unresolved_pending_conflict';
  end if;
  select version,state_sha256 into last_version,last_hash
    from public.gm_checkpoint_history
    where session_id=p_session_id and status='verified'
    order by version desc limit 1;
  if found then
    if p_version <> last_version+1 or p_parent_version is distinct from last_version
       or p_parent_sha256 is distinct from last_hash then
      raise exception 'verified_parent_conflict';
    end if;
  else
    if p_version <> 1 or p_parent_version is not null or p_parent_sha256 is not null then
      raise exception 'first_checkpoint_parent_invalid';
    end if;
  end if;
  insert into public.gm_checkpoint_history(
    session_id, version, event_id, attempt_id, parent_version, parent_sha256,
    state_json, state_sha256, canon_file_sha256, rules_version,
    state_schema_version, save_mode, document_bound_format, status
  ) values (
    p_session_id, p_version, p_event_id, p_attempt_id, p_parent_version, p_parent_sha256,
    p_state_json, actual_hash, doc->'canon_ref'->>'file_sha256',
    doc->>'rules_version', doc->>'state_schema_version',
    doc->>'save_mode', doc->>'document_bound_format','pending'
  );
  return jsonb_build_object('status','pending','session_id',p_session_id,
    'version',p_version,'event_id',p_event_id,'attempt_id',p_attempt_id,
    'state_sha256',actual_hash,'idempotent_replay',false);
end;
$function$;

CREATE OR REPLACE FUNCTION public.trpg_v2_verify(p_session_id text, p_version bigint, p_event_id text, p_attempt_id text, p_state_sha256 text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  rec public.gm_checkpoint_history%rowtype;
  last_version bigint;
  last_hash text;
  issue text;
  actual_hash text;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_session_id,0));
  select * into rec from public.gm_checkpoint_history
    where session_id=p_session_id and version=p_version for update;
  if not found then raise exception 'checkpoint_not_found'; end if;
  if rec.event_id is distinct from p_event_id
     or rec.attempt_id is distinct from p_attempt_id
     or rec.state_sha256 is distinct from p_state_sha256 then
    raise exception 'checkpoint_tuple_mismatch';
  end if;
  issue := public.trpg_v2_payload_issue(rec.state_json);
  actual_hash := encode(sha256(convert_to(rec.state_json,'UTF8')),'hex');
  if issue is not null or rec.state_sha256 is distinct from actual_hash then
    raise exception 'stored_payload_invalid: %', coalesce(issue,'sha256_mismatch');
  end if;
  if rec.status='verified' then
    return jsonb_build_object('status','verified','session_id',p_session_id,
      'version',p_version,'event_id',p_event_id,'state_sha256',actual_hash,'idempotent_replay',true);
  end if;
  select version,state_sha256 into last_version,last_hash
    from public.gm_checkpoint_history
    where session_id=p_session_id and status='verified' order by version desc limit 1;
  if found then
    if rec.parent_version is distinct from last_version
       or rec.parent_sha256 is distinct from last_hash
       or rec.version is distinct from last_version+1 then
      raise exception 'verify_parent_conflict';
    end if;
  else
    if rec.version<>1 or rec.parent_version is not null or rec.parent_sha256 is not null then
      raise exception 'verify_first_checkpoint_conflict';
    end if;
  end if;
  update public.gm_checkpoint_history set status='verified',verified_at=clock_timestamp()
    where session_id=p_session_id and version=p_version;
  return jsonb_build_object('status','verified','session_id',p_session_id,
    'version',p_version,'event_id',p_event_id,'state_sha256',actual_hash,'idempotent_replay',false);
end;
$function$;

CREATE OR REPLACE FUNCTION public.trpg_v2_load_version(p_session_id text, p_version bigint)
 RETURNS TABLE(session_id text, version bigint, event_id text, attempt_id text, parent_version bigint, parent_sha256 text, status text, state_sha256 text, state_json text, rules_version text, canon_file_sha256 text, verified_at timestamp with time zone)
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select h.session_id,h.version,h.event_id,h.attempt_id,
    h.parent_version,h.parent_sha256,h.status,
    h.state_sha256,h.state_json,h.rules_version,
    h.canon_file_sha256,h.verified_at
  from public.gm_checkpoint_history h
  where h.session_id=p_session_id and h.version=p_version and h.status='verified'
$function$;

CREATE OR REPLACE FUNCTION public.trpg_v2_load(p_session_id text)
 RETURNS TABLE(session_id text, version bigint, event_id text, attempt_id text, parent_version bigint, parent_sha256 text, status text, state_sha256 text, state_json text, rules_version text, canon_file_sha256 text, verified_at timestamp with time zone)
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select * from public.trpg_v2_load_version(
    p_session_id,
    (select max(h.version) from public.gm_checkpoint_history h
      where h.session_id=p_session_id and h.status='verified')
  )
$function$;

CREATE OR REPLACE FUNCTION public.trpg_v2_list()
 RETURNS TABLE(session_id text, version bigint, event_id text, state_sha256 text, verified_at timestamp with time zone)
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select distinct on (h.session_id)
    h.session_id,h.version,h.event_id,h.state_sha256,h.verified_at
  from public.gm_checkpoint_history h
  where h.status='verified'
  order by h.session_id, h.version desc
$function$;

CREATE OR REPLACE FUNCTION public.trpg_v2_inspect_pending(p_session_id text)
 RETURNS TABLE(session_id text, version bigint, event_id text, attempt_id text, parent_version bigint, parent_sha256 text, state_sha256 text, state_json text, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select h.session_id,h.version,h.event_id,h.attempt_id,h.parent_version,
    h.parent_sha256,h.state_sha256,h.state_json,h.created_at
  from public.gm_checkpoint_history h
  where h.session_id=p_session_id and h.status='pending'
$function$;

revoke all on function public.trpg_v2_payload_issue(text) from public,anon,authenticated;
revoke all on function public.trpg_v2_commit(text,bigint,text,text,bigint,text,text,text) from public,anon,authenticated;
revoke all on function public.trpg_v2_verify(text,bigint,text,text,text) from public,anon,authenticated;
revoke all on function public.trpg_v2_load_version(text,bigint) from public,anon,authenticated;
revoke all on function public.trpg_v2_load(text) from public,anon,authenticated;
revoke all on function public.trpg_v2_list() from public,anon,authenticated;
revoke all on function public.trpg_v2_inspect_pending(text) from public,anon,authenticated;

commit;
