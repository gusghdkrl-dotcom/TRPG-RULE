-- READ-ONLY post-migration inspection. Does not prove actual game RPC behavior.
-- All counts below are expected on an empty newly migrated trpg_hq schema.
-- Re-run hq_readonly_preflight.sql and compare ALL legacy data counts/fingerprints
-- against the saved preflight result. A changed fingerprint needs investigation.
SELECT jsonb_build_object(
  'checked_at_utc',(now() AT TIME ZONE 'UTC'),
  'hq_schema_present',to_regnamespace('trpg_hq') IS NOT NULL,
  'hq_table_count',(SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='trpg_hq' AND c.relkind IN ('r','p')),
  'hq_function_count',(SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='trpg_hq'),
  'hq_npc_services',(SELECT count(*) FROM trpg_hq.hq_npc_service_catalog),
  'hq_tables_without_rls',(SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='trpg_hq' AND c.relkind IN ('r','p') AND NOT c.relrowsecurity),
  'hq_functions_executable_by_anon',(SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='trpg_hq' AND has_function_privilege('anon',p.oid,'EXECUTE')),
  'hq_functions_executable_by_authenticated',(SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='trpg_hq' AND has_function_privilege('authenticated',p.oid,'EXECUTE')),
  'legacy_card_count',(SELECT count(*) FROM trpg_cards.card_catalog),
  'legacy_private_archive_exists',to_regclass('trpg_private.gm_cleanup_archive') IS NOT NULL
) AS release_postflight;
