-- READ-ONLY. Target: current production trpg-state-v2. Never use as a backup.
-- Captures only counts and row fingerprints; private original content is not exported.
-- Preserve this query's result securely outside the live database before any migration.
SELECT jsonb_build_object(
  'checked_at_utc', (now() AT TIME ZONE 'UTC'),
  'db_schema', jsonb_build_object(
    'hq_absent', to_regnamespace('trpg_hq') IS NULL,
    'checkpoint_exists', to_regclass('public.gm_checkpoint_history') IS NOT NULL,
    'private_canon_exists', to_regclass('trpg_private.gm_canon_documents') IS NOT NULL,
    'archive_exists', to_regclass('trpg_private.gm_cleanup_archive') IS NOT NULL,
    'cards_exists', to_regclass('trpg_cards.card_catalog') IS NOT NULL
  ),
  'core_function_count', (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','trpg_cards','trpg_private')),
  'card_catalog_count', (SELECT count(*) FROM trpg_cards.card_catalog),
  'canonical_loadout_normalized_md5',
     (SELECT md5(regexp_replace(regexp_replace(p.prosrc,E'--[^\n]*','','g'),'[[:space:]]+','','g'))
      FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
      WHERE n.nspname='trpg_cards' AND p.proname='save_loadout'),
  'append_only_triggers_enabled', jsonb_build_object(
    'canon', EXISTS(SELECT 1 FROM pg_trigger
      WHERE tgrelid='trpg_private.gm_canon_documents'::regclass
        AND tgname='gm_canon_no_update_or_delete' AND tgenabled='O')
  ),
  'existing_data', jsonb_build_object(
    'public.gm_checkpoint_history', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM public.gm_checkpoint_history t),
    'trpg_private.gm_canon_documents', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_private.gm_canon_documents t),
    'trpg_private.gm_cleanup_archive', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_private.gm_cleanup_archive t),
    'trpg_cards.players', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.players t),
    'trpg_cards.card_catalog', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.card_catalog t),
    'trpg_cards.owned_cards', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.owned_cards t),
    'trpg_cards.growth_levels', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.growth_levels t),
    'trpg_cards.campaigns', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.campaigns t),
    'trpg_cards.campaign_members', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.campaign_members t),
    'trpg_cards.character_links', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.character_links t),
    'trpg_cards.drafts', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.drafts t),
    'trpg_cards.loadouts', (SELECT jsonb_build_object('rows',count(*),'fingerprint',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),''))) FROM trpg_cards.loadouts t)
  )
) AS production_baseline;
