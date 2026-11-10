-- Private TRPG canon archive. Applied to Supabase project trpg-state-v2 (2026-11-11).
-- Not exposed via Data API. Match UTF-8 bytes of delivered PRIVATE_CANON_*.md.
create schema if not exists trpg_private;
revoke all on schema trpg_private from public, anon, authenticated;
create table if not exists trpg_private.gm_canon_documents (
  campaign_id text not null,
  canon_id text not null,
  revision integer not null check (revision > 0),
  filename text not null,
  document_format text not null,
  rules_version text not null,
  content_md text not null check (length(content_md) > 0),
  file_sha256 text not null check (file_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  primary key (campaign_id, canon_id, revision),
  constraint gm_canon_documents_exact_hash
    check (file_sha256 = encode(sha256(convert_to(content_md, 'UTF8')), 'hex')),
  constraint gm_canon_documents_filename_check
    check (filename not like '%/%' and filename not like '%\%')
);
alter table trpg_private.gm_canon_documents enable row level security;
revoke all on trpg_private.gm_canon_documents from public, anon, authenticated;
create or replace function trpg_private.reject_gm_canon_mutation()
returns trigger language plpgsql security invoker
set search_path = pg_catalog, trpg_private
as $$
begin
  raise exception 'Private canon is immutable: insert a new revision instead of %', tg_op
    using errcode = '55000';
end;
$$;
revoke all on function trpg_private.reject_gm_canon_mutation() from public, anon, authenticated;
drop trigger if exists gm_canon_no_update_or_delete on trpg_private.gm_canon_documents;
create trigger gm_canon_no_update_or_delete
before update or delete on trpg_private.gm_canon_documents
for each row execute function trpg_private.reject_gm_canon_mutation();
-- Store exactly once by campaign_id/canon_id/revision, SELECT/read-back exact
-- content and SHA before creating the DOCUMENT_BOUND DB1 setup checkpoint.
-- Do not push private canon or game snapshots to GitHub.
