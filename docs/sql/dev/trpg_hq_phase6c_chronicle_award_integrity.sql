-- DEV ONLY PHASE 6C: historical chronicle certification and permanent medal
-- integrity. A resolved A/B choice cannot be rewritten or deleted.

create or replace function trpg_hq.reject_chronicle_certification_mutation()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
begin
  raise exception 'hq_chronicle_certification_append_only';
end $hq$;

create trigger hq_chronicle_completed_history_immutable
 before update or delete on trpg_hq.hq_chronicle_completions
 for each row execute function trpg_hq.reject_chronicle_certification_mutation();

create trigger hq_agent_full_certification_immutable
 before update or delete on trpg_hq.hq_agent_full_certifications
 for each row execute function trpg_hq.reject_chronicle_certification_mutation();

create or replace function trpg_hq.guard_chronicle_honor_mutation()
returns trigger language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
 v_card trpg_cards.card_catalog%rowtype;
 v_level smallint;
begin
 if tg_op='DELETE' then
   raise exception 'hq_chronicle_medal_cannot_be_deleted';
 end if;
 if old.status<>'awaiting_choice' or new.status<>'resolved'
   or new.mission_id is distinct from old.mission_id
   or new.player_id is distinct from old.player_id
   or new.medal_key is distinct from old.medal_key
   or new.granted_at is distinct from old.granted_at then
   raise exception 'hq_chronicle_medal_only_single_resolution';
 end if;
 if new.choice_kind='card' then
   select * into v_card from trpg_cards.card_catalog where card_id=new.choice_id;
   if not found or v_card.rarity not in ('common','rare','epic')
     or new.outcome->>'type'<>'direct_card'
     or new.outcome->>'card_id' is distinct from new.choice_id
     or new.outcome->>'acquisition_event' is distinct from new.medal_key||':special'
     or not exists(
       select 1 from trpg_cards.owned_cards oc
       where oc.player_id=new.player_id and oc.card_id=new.choice_id
         and oc.acquisition_event=new.medal_key||':special'
     ) then
     raise exception 'hq_chronicle_card_award_ledger_not_matched';
   end if;
 elsif new.choice_kind='growth' then
   select level into v_level from trpg_cards.growth_levels
     where player_id=new.player_id and stat=new.choice_id;
   if new.choice_id not in ('STR','CON','SIZ','DEX','APP','INT','POW','EDU')
     or new.outcome->>'type'<>'guaranteed_growth'
     or new.outcome->>'stat' is distinct from new.choice_id
     or new.outcome->'no_random_roll' is distinct from 'true'::jsonb
     or new.outcome->'retroactive_local_pc_change' is distinct from 'false'::jsonb
     or (new.outcome->>'after_level')::integer is distinct from v_level
     or (new.outcome->>'before_level')::integer is distinct from (v_level::integer-1)
   then
     raise exception 'hq_chronicle_growth_award_ledger_not_matched';
   end if;
 else
   raise exception 'hq_chronicle_invalid_award_type';
 end if;
 return new;
end $hq$;

create trigger hq_chronicle_honor_resolve_guard
 before update or delete on trpg_hq.hq_chronicle_honors
 for each row execute function trpg_hq.guard_chronicle_honor_mutation();

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
