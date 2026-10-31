-- DOCUMENT_BOUND(DB1): opt-in compact checkpoints; legacy full snapshots are not rewritten.
-- Existing commit/verify/load_version functions, raw state_json hash and version/event rules remain unchanged.
-- The keeper MUST independently check the private Markdown file's full SHA-256 and semantic delta coverage.
CREATE OR REPLACE FUNCTION public.trpg_checkpoint_semantic_validate_document_bound(p_state_json text)
RETURNS TABLE(ok boolean, reason text)
LANGUAGE plpgsql STABLE
SET search_path TO 'public', 'extensions'
AS $db1$
DECLARE
 j jsonb; k text; slot text; pc text; n int; elem jsonb;
 required text[]:=ARRAY['session_id','state_schema_version','rules_version','save_mode','document_bound_format','campaign_id','canon_ref','change_coverage','world_delta','setup_start_settings','world_seed','start_seed','participants','pcs_by_identity','scenario_connection_by_pc','public_facts_by_pc','player_map_state','first_scene_orientation_by_pc','current_focus','pending','timeline','rng_mapping_version','rng_queue','rng_queue_next_consumption','checkpoint_cadence_state','save_cadence','critical_state_registry','ending_state','scene_turn','phase'];
 ns text[]:=ARRAY['npcs','evidence','locations','routes','drivers','threats'];
 banned text[]:=ARRAY['campaign_canon_text','chapter_canon_text_by_ref','pc_canon_text_by_identity','scenario_core','world_dna','canonical_map_model','world_state'];
BEGIN
 BEGIN j:=p_state_json::jsonb; EXCEPTION WHEN others THEN
  RETURN QUERY SELECT false,'db1_invalid_json'::text; RETURN; END;
 IF jsonb_typeof(j)<>'object' THEN RETURN QUERY SELECT false,'db1_not_object'::text; RETURN; END IF;
 IF j->>'state_schema_version'<>'TRPG2026_10_30'
 OR j->>'rules_version'<>'통합 연출판 2026-10-30'
 OR j->>'save_mode'<>'DOCUMENT_BOUND'
 OR j->>'document_bound_format'<>'DB1'
 THEN RETURN QUERY SELECT false,'db1_mode_or_version'::text; RETURN; END IF;
 FOREACH k IN ARRAY required LOOP
  IF NOT j ? k OR j->k IS NULL OR j->k='null'::jsonb THEN
   RETURN QUERY SELECT false,('db1_missing:'||k)::text; RETURN;
  END IF;
 END LOOP;
 FOREACH k IN ARRAY banned LOOP
  IF j ? k THEN RETURN QUERY SELECT false,('db1_embedded_canon:'||k)::text; RETURN; END IF;
 END LOOP;
 IF coalesce(j->>'session_id','')='' OR length(j->>'session_id')>128
 OR j->>'campaign_id'<>j#>>'{canon_ref,campaign_id}'
 OR jsonb_typeof(j->'canon_ref')<>'object'
 OR coalesce(j#>>'{canon_ref,canon_id}','')=''
 OR coalesce(j#>>'{canon_ref,filename}','')=''
 OR coalesce(j#>>'{canon_ref,document_format}','')=''
 OR coalesce(j#>>'{canon_ref,revision}','') !~ '^[1-9][0-9]*$'
 OR coalesce(j#>>'{canon_ref,file_sha256}','') !~ '^[0-9a-f]{64}$'
 OR jsonb_typeof(j#>'{canon_ref,section_ids}')<>'array'
 THEN RETURN QUERY SELECT false,'db1_invalid_canon_ref'::text; RETURN; END IF;
 FOREACH k IN ARRAY ARRAY['CANON_INDEX','WORLD_BASELINE','HIDDEN_TRUTH','WORLD_RULES','NPC_BASELINES','EVIDENCE_BASELINES','LOCATION_BASELINES','DRIVER_BASELINES','ENDING_CONDITIONS','PC_CONNECTIONS'] LOOP
  IF NOT (j#>'{canon_ref,section_ids}') ? k THEN
   RETURN QUERY SELECT false,('db1_missing_section:'||k)::text; RETURN;
  END IF;
 END LOOP;
 IF jsonb_typeof(j->'change_coverage')<>'object'
 OR j#>>'{change_coverage,complete_since_revision}'<>'true'
 OR jsonb_typeof(j#>'{change_coverage,baseline_entity_ids}')<>'object'
 OR jsonb_typeof(j#>'{change_coverage,changed_entity_ids}')<>'object'
 OR jsonb_typeof(j->'world_delta')<>'object'
 OR jsonb_typeof(j#>'{world_delta,new_entities}')<>'object'
 OR jsonb_typeof(j#>'{world_delta,tombstones}')<>'object'
 OR jsonb_typeof(j#>'{world_delta,processed_event_ids}')<>'array'
 THEN RETURN QUERY SELECT false,'db1_incomplete_coverage'::text; RETURN; END IF;
 FOREACH k IN ARRAY ns LOOP
  IF jsonb_typeof(j#>ARRAY['change_coverage','baseline_entity_ids',k])<>'array'
  OR jsonb_typeof(j#>ARRAY['change_coverage','changed_entity_ids',k])<>'array'
  OR jsonb_typeof(j#>ARRAY['world_delta',k])<>'object' THEN
   RETURN QUERY SELECT false,('db1_missing_namespace:'||k)::text; RETURN;
  END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(j#>ARRAY['world_delta',k])) <>
  (SELECT count(*) FROM jsonb_array_elements_text(j#>ARRAY['change_coverage','changed_entity_ids',k]))
  OR EXISTS(
   SELECT 1 FROM jsonb_object_keys(j#>ARRAY['world_delta',k]) x(id)
   WHERE NOT (j#>ARRAY['change_coverage','changed_entity_ids',k]) ? x.id
  ) THEN
   RETURN QUERY SELECT false,('db1_delta_coverage_mismatch:'||k)::text; RETURN;
  END IF;
 END LOOP;
 IF jsonb_typeof(j->'setup_start_settings')<>'object'
 OR j#>>'{setup_start_settings,all_required_valid}'<>'true'
 OR jsonb_typeof(j->'world_seed')<>'number'
 OR jsonb_typeof(j->'start_seed')<>'number'
 OR j->'world_seed' IS DISTINCT FROM j#>'{setup_start_settings,world_seed}'
 OR j->'start_seed' IS DISTINCT FROM j#>'{setup_start_settings,start_seed}'
 THEN RETURN QUERY SELECT false,'db1_bad_start'::text; RETURN; END IF;
 IF jsonb_typeof(j#>'{participants,count}')<>'number'
 OR jsonb_typeof(j#>'{participants,slots}')<>'object'
 OR jsonb_typeof(j->'pcs_by_identity')<>'object'
 OR jsonb_typeof(j->'scenario_connection_by_pc')<>'object'
 OR jsonb_typeof(j->'public_facts_by_pc')<>'object'
 OR jsonb_typeof(j->'player_map_state')<>'object'
 OR jsonb_typeof(j->'first_scene_orientation_by_pc')<>'object'
 OR jsonb_typeof(j->'current_focus')<>'object'
 OR jsonb_typeof(j->'timeline')<>'object'
 THEN RETURN QUERY SELECT false,'db1_bad_runtime'::text; RETURN; END IF;
 n:=(j#>>'{participants,count}')::int;
 IF n NOT BETWEEN 1 AND 3
 OR (SELECT count(*) FROM jsonb_object_keys(j#>'{participants,slots}'))<>n
 OR (SELECT count(*) FROM jsonb_object_keys(j->'pcs_by_identity'))<>n
 OR (j#>>'{setup_start_settings,participant_count}')::int<>n
 THEN RETURN QUERY SELECT false,'db1_bad_participants'::text; RETURN; END IF;
 FOR slot,pc IN SELECT key,value FROM jsonb_each_text(j#>'{participants,slots}') LOOP
  IF slot NOT IN ('P1','P2','P3')
  OR NOT (j->'pcs_by_identity' ? pc)
  OR j#>>ARRAY['pcs_by_identity',pc,'identity_id']<>pc
  OR j#>>ARRAY['pcs_by_identity',pc,'slot']<>slot
  OR NOT (j->'scenario_connection_by_pc' ? slot)
  OR NOT (j->'player_map_state' ? slot)
  OR NOT (j->'first_scene_orientation_by_pc' ? slot)
  THEN RETURN QUERY SELECT false,'db1_bad_pc_refs'::text; RETURN; END IF;
 END LOOP;
 IF j#>>'{current_focus,slot}' IS NULL
 OR j#>>'{current_focus,pc_identity_id}' IS DISTINCT FROM j#>>ARRAY['participants','slots',j#>>'{current_focus,slot}']
 THEN RETURN QUERY SELECT false,'db1_bad_focus'::text; RETURN; END IF;
 IF jsonb_typeof(j->'pending')<>'object'
 OR NOT (j->'pending' ?& ARRAY['roll','luck','combat','chase','madness','handoff','visual_choice','action_menu'])
 THEN RETURN QUERY SELECT false,'db1_bad_pending'::text; RETURN; END IF;
 IF jsonb_typeof(j->'rng_queue')<>'array'
 OR j->>'rng_mapping_version'<>'A19_REJECTION100'
 OR jsonb_typeof(j->'rng_queue_next_consumption')<>'number'
 THEN RETURN QUERY SELECT false,'db1_bad_rng'::text; RETURN; END IF;
 IF (j->>'rng_queue_next_consumption')::int<0
 OR (j->>'rng_queue_next_consumption')::int>jsonb_array_length(j->'rng_queue')
 THEN RETURN QUERY SELECT false,'db1_bad_rng_offset'::text; RETURN; END IF;
 FOR elem IN SELECT value FROM jsonb_array_elements(j->'rng_queue') LOOP
  IF jsonb_typeof(elem)<>'number'
  OR (elem::text)::numeric NOT BETWEEN 1 AND 100
  OR trunc((elem::text)::numeric)<>(elem::text)::numeric
  THEN RETURN QUERY SELECT false,'db1_bad_rng_entry'::text; RETURN; END IF;
 END LOOP;
 IF jsonb_typeof(j#>'{critical_state_registry,actual_paths}')<>'array'
 OR jsonb_array_length(j#>'{critical_state_registry,actual_paths}')=0
 THEN RETURN QUERY SELECT false,'db1_bad_registry'::text; RETURN; END IF;
 FOR k IN SELECT value FROM jsonb_array_elements_text(j#>'{critical_state_registry,actual_paths}') LOOP
  IF NOT (j ? k) OR j->k='null'::jsonb THEN
   RETURN QUERY SELECT false,('db1_missing_critical:'||k)::text; RETURN;
  END IF;
 END LOOP;
 IF jsonb_typeof(j->'scene_turn')<>'number'
 OR (j->>'scene_turn')::int<0
 OR j->>'phase' NOT IN ('setup','play','ending','settlement')
 OR (j->>'phase'='setup' AND (j->>'scene_turn')::int<>0)
 OR jsonb_typeof(j->'checkpoint_cadence_state')<>'object'
 OR jsonb_typeof(j->'save_cadence')<>'object'
 OR jsonb_typeof(j->'ending_state')<>'object'
 THEN RETURN QUERY SELECT false,'db1_bad_phase_or_cadence'::text; RETURN; END IF;
 RETURN QUERY SELECT true,'db1_ok'::text;
END
$db1$;

CREATE OR REPLACE FUNCTION public.trpg_checkpoint_semantic_validate_20261030(p_state_json text)
 RETURNS TABLE(ok boolean, reason text)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
 j jsonb; k text; pc_ref text; slot text; n integer; saved_hash text; a jsonb; raw text;
 required_keys text[]:=ARRAY[
 'session_id','state_schema_version','rules_version','setup_start_settings',
 'world_seed','start_seed','participants','pcs_by_identity','world_dna',
 'scenario_core','world_state','scenario_connection_by_pc','public_facts_by_pc',
 'canonical_map_model','player_map_state','current_focus','pending',
 'first_scene_orientation_by_pc','rng_mapping_version','rng_queue',
 'rng_queue_next_consumption','campaign_canon_text','chapter_canon_text_by_ref',
 'pc_canon_text_by_identity','checkpoint_canon_manifest','critical_state_registry',
 'save_cadence','ending_state','scene_turn','phase'
 ];
BEGIN
 BEGIN j:=p_state_json::jsonb;
 EXCEPTION WHEN others THEN RETURN QUERY SELECT false,'invalid_json_20261029'::text; RETURN; END;
 IF jsonb_typeof(j)<>'object' THEN RETURN QUERY SELECT false,'not_object_20261029'::text; RETURN; END IF;
 IF j->>'state_schema_version'<>'TRPG2026_10_30' OR j->>'rules_version'<>'통합 연출판 2026-10-30'
 THEN RETURN QUERY SELECT false,'version_or_rules_mismatch_20261029'::text; RETURN; END IF;
 IF coalesce(j->>'save_mode','LEGACY_FULL')='DOCUMENT_BOUND' THEN
  RETURN QUERY SELECT x.ok,x.reason FROM public.trpg_checkpoint_semantic_validate_document_bound(p_state_json) x;
  RETURN;
 END IF;
 FOREACH k IN ARRAY required_keys LOOP
  IF NOT (j ? k) OR j->k IS NULL OR j->k='null'::jsonb
  THEN RETURN QUERY SELECT false,('missing_required_20261029:'||k)::text; RETURN; END IF;
 END LOOP;
 IF coalesce(j->>'session_id','')='' OR length(j->>'session_id')>128
 THEN RETURN QUERY SELECT false,'bad_session_20261029'::text; RETURN; END IF;
 IF jsonb_typeof(j->'setup_start_settings')<>'object'
 OR j#>>'{setup_start_settings,all_required_valid}'<>'true'
 THEN RETURN QUERY SELECT false,'bad_start_settings_20261029'::text; RETURN; END IF;
 IF jsonb_typeof(j->'world_seed')<>'number' OR jsonb_typeof(j->'start_seed')<>'number'
 OR (j->>'world_seed')::numeric NOT BETWEEN 1 AND 100
 OR (j->>'start_seed')::numeric NOT BETWEEN 1 AND 100
 OR j->'world_seed' IS DISTINCT FROM j#>'{setup_start_settings,world_seed}'
 OR j->'start_seed' IS DISTINCT FROM j#>'{setup_start_settings,start_seed}'
 THEN RETURN QUERY SELECT false,'seed_mismatch_20261029'::text; RETURN; END IF;
 IF jsonb_typeof(j#>'{participants,count}')<>'number'
 OR jsonb_typeof(j#>'{participants,slots}')<>'object'
 THEN RETURN QUERY SELECT false,'bad_participants_20261029'::text; RETURN; END IF;
 n:=(j#>>'{participants,count}')::integer;
 IF n NOT BETWEEN 1 AND 3 OR
 (SELECT count(*) FROM jsonb_object_keys(j#>'{participants,slots}'))<>n OR
 (j#>>'{setup_start_settings,participant_count}')::integer<>n OR
 jsonb_typeof(j->'pcs_by_identity')<>'object' OR
 (SELECT count(*) FROM jsonb_object_keys(j->'pcs_by_identity'))<>n
 THEN RETURN QUERY SELECT false,'participant_count_mismatch_20261029'::text; RETURN; END IF;
 FOR slot,pc_ref IN SELECT key,value FROM jsonb_each_text(j#>'{participants,slots}') LOOP
  IF slot NOT IN ('P1','P2','P3') OR NOT (j->'pcs_by_identity' ? pc_ref)
     OR j#>>ARRAY['pcs_by_identity',pc_ref,'identity_id']<>pc_ref
     OR j#>>ARRAY['pcs_by_identity',pc_ref,'slot']<>slot
     OR NOT (j->'scenario_connection_by_pc' ? slot)
     OR NOT (j->'player_map_state' ? slot)
     OR NOT (j->'first_scene_orientation_by_pc' ? slot)
     OR NOT (j->'pc_canon_text_by_identity' ? pc_ref)
  THEN RETURN QUERY SELECT false,'pc_slot_identity_mismatch_20261029'::text; RETURN; END IF;
 END LOOP;
 IF j#>>'{current_focus,slot}' IS NULL OR
 NOT (j#>'{participants,slots}' ? (j#>>'{current_focus,slot}')) OR
 j#>>'{current_focus,pc_identity_id}' IS DISTINCT FROM
  j#>>ARRAY['participants','slots',j#>>'{current_focus,slot}']
 THEN RETURN QUERY SELECT false,'invalid_focus_20261029'::text; RETURN; END IF;
 IF jsonb_typeof(j->'world_state')<>'object' OR
 jsonb_typeof(j#>'{world_state,npcs}')<>'object' OR
 jsonb_typeof(j#>'{world_state,evidence_placement}')<>'object' OR
 jsonb_typeof(j->'scenario_core')<>'object' OR
 j#>>'{scenario_core,frozen}'<>'true' OR
 jsonb_typeof(j#>'{scenario_core,truth}')<>'object' OR
 jsonb_typeof(j#>'{scenario_core,causal_endgame_precommit}')<>'object' OR
 jsonb_typeof(j#>'{scenario_core,terminal_boundary}')<>'object' OR
 jsonb_typeof(j->'canonical_map_model')<>'object'
 THEN RETURN QUERY SELECT false,'incomplete_world_20261029'::text; RETURN; END IF;
 IF jsonb_typeof(j->'pending')<>'object' OR
 NOT (j->'pending' ?& ARRAY['roll','luck','combat','chase','madness','handoff','visual_choice','action_menu'])
 THEN RETURN QUERY SELECT false,'missing_pending_20261029'::text; RETURN; END IF;
 IF jsonb_typeof(j->'rng_queue')<>'array' OR
 j->>'rng_mapping_version'<>'A19_REJECTION100' OR
 jsonb_typeof(j->'rng_queue_next_consumption')<>'number' OR
 (j->>'rng_queue_next_consumption')::integer<0 OR
 (j->>'rng_queue_next_consumption')::integer>jsonb_array_length(j->'rng_queue')
 THEN RETURN QUERY SELECT false,'bad_rng_20261029'::text; RETURN; END IF;
 FOR a IN SELECT value FROM jsonb_array_elements(j->'rng_queue') LOOP
  IF jsonb_typeof(a)<>'number' OR (a::text)::numeric NOT BETWEEN 1 AND 100 OR
  trunc((a::text)::numeric)<>(a::text)::numeric
  THEN RETURN QUERY SELECT false,'bad_rng_element_20261029'::text; RETURN; END IF;
 END LOOP;
 IF jsonb_typeof(j#>'{critical_state_registry,actual_paths}')<>'array'
 OR jsonb_array_length(j#>'{critical_state_registry,actual_paths}')=0
 THEN RETURN QUERY SELECT false,'missing_critical_registry_20261029'::text; RETURN; END IF;
 FOR k IN SELECT value FROM jsonb_array_elements_text(j#>'{critical_state_registry,actual_paths}') LOOP
  IF NOT j ? k OR j->k='null'::jsonb
  THEN RETURN QUERY SELECT false,('critical_path_missing_20261029:'||k)::text; RETURN; END IF;
 END LOOP;
 IF jsonb_typeof(j->'checkpoint_canon_manifest')<>'object'
 OR jsonb_typeof(j->'chapter_canon_text_by_ref')<>'object'
 OR jsonb_typeof(j->'pc_canon_text_by_identity')<>'object'
 OR jsonb_typeof(j#>'{checkpoint_canon_manifest,chapter_anchor_sha256_by_ref}')<>'object'
 OR jsonb_typeof(j#>'{checkpoint_canon_manifest,pc_anchor_sha256_by_identity}')<>'object'
 OR (SELECT count(*) FROM jsonb_object_keys(j->'chapter_canon_text_by_ref'))=0
 OR (SELECT count(*) FROM jsonb_object_keys(j->'pc_canon_text_by_identity'))=0
 THEN RETURN QUERY SELECT false,'missing_canon_manifest_20261029'::text; RETURN; END IF;
 raw:=j->>'campaign_canon_text';
 IF raw IS NULL OR length(raw)=0 OR
 encode(extensions.digest(convert_to(raw,'UTF8'),'sha256'),'hex') IS DISTINCT FROM
 j#>>'{checkpoint_canon_manifest,campaign_anchor_sha256}'
 THEN RETURN QUERY SELECT false,'campaign_anchor_mismatch_20261029'::text; RETURN; END IF;
 IF (SELECT count(*) FROM jsonb_object_keys(j->'chapter_canon_text_by_ref'))<>
 (SELECT count(*) FROM jsonb_object_keys(j#>'{checkpoint_canon_manifest,chapter_anchor_sha256_by_ref}'))
 THEN RETURN QUERY SELECT false,'chapter_manifest_count_20261029'::text; RETURN; END IF;
 FOR k,raw IN SELECT key,value FROM jsonb_each_text(j->'chapter_canon_text_by_ref') LOOP
  IF length(raw)=0 OR encode(extensions.digest(convert_to(raw,'UTF8'),'sha256'),'hex') IS DISTINCT FROM
  j#>>ARRAY['checkpoint_canon_manifest','chapter_anchor_sha256_by_ref',k]
  THEN RETURN QUERY SELECT false,('chapter_anchor_mismatch_20261029:'||k)::text; RETURN; END IF;
 END LOOP;
 IF (SELECT count(*) FROM jsonb_object_keys(j->'pc_canon_text_by_identity'))<>
 (SELECT count(*) FROM jsonb_object_keys(j#>'{checkpoint_canon_manifest,pc_anchor_sha256_by_identity}'))
 THEN RETURN QUERY SELECT false,'pc_manifest_count_20261029'::text; RETURN; END IF;
 FOR k,raw IN SELECT key,value FROM jsonb_each_text(j->'pc_canon_text_by_identity') LOOP
  IF length(raw)=0 OR encode(extensions.digest(convert_to(raw,'UTF8'),'sha256'),'hex') IS DISTINCT FROM
  j#>>ARRAY['checkpoint_canon_manifest','pc_anchor_sha256_by_identity',k]
  THEN RETURN QUERY SELECT false,('pc_anchor_mismatch_20261029:'||k)::text; RETURN; END IF;
 END LOOP;
 IF jsonb_typeof(j->'scene_turn')<>'number' OR (j->>'scene_turn')::integer<0 OR
 j->>'phase' NOT IN ('setup','play','ending','settlement')
 THEN RETURN QUERY SELECT false,'invalid_phase_or_turn_20261029'::text; RETURN; END IF;
 IF j->>'phase'='setup' AND (j->>'scene_turn')::integer<>0
 THEN RETURN QUERY SELECT false,'setup_turn_mismatch_20261029'::text; RETURN; END IF;
 RETURN QUERY SELECT true,'ok_20261029'::text;
END $function$

