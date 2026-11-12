-- DEV-only: isolate pre-offered ordinary draft vs independent acquisition race.
create temporary table hq9_collision_result(note text, result jsonb) on commit drop;
do $t$
declare
  p uuid;
  campaign text:='hq9-collision-test';
  pool jsonb;
  offers jsonb;
  primary_card text;
  other_card text;
  growth_option text;
  neutral_card text;
  outcome jsonb;
  payload jsonb;
begin
  begin
    p:=(trpg_cards.register_player('HQ9_COLLISION_1')->>'player_id')::uuid;
    perform trpg_cards.open_campaign(campaign,'chronicle','hq9-collision-session');
    perform trpg_cards.enroll_player(campaign,p,'guardian');
    pool:=trpg_cards.draft_pool(campaign,p);
    select x->>'id' into primary_card from jsonb_array_elements(pool->'current') x limit 1;
    select x->>'id' into other_card from jsonb_array_elements(pool->'all') x
      where x->>'id' is distinct from primary_card limit 1;
    select x->>'id' into growth_option from jsonb_array_elements(pool->'growth') x limit 1;
    select x->>'id' into neutral_card from jsonb_array_elements(pool->'neutral') x limit 1;
    offers:=jsonb_build_object('current',primary_card,'all',other_card,
      'growth',growth_option,'neutral',neutral_card);
    perform trpg_cards.issue_draft(campaign,p,'chapter:01','synthetic_verified_source',offers);
    -- Simulated external card acquisition after four slots were fixed.
    insert into trpg_cards.owned_cards(player_id,card_id,acquisition_event)
    values(p,primary_card,'synthetic-special-owned-during-open-draft');
    begin
      perform trpg_cards.resolve_draft(campaign,p,'chapter:01',1,null);
      raise exception 'test_failed_duplicate_card_slot_claimed';
    exception when others then
      if sqlerrm<>'card_already_owned_before_selection' then raise; end if;
    end;
    if not exists(select 1 from trpg_cards.drafts where player_id=p
       and campaign_id=campaign and event_key='chapter:01' and status='offered')
    then raise exception 'test_failed_draft_lost_after_collision';end if;
    outcome:=trpg_cards.resolve_draft(campaign,p,'chapter:01',2,null);
    if outcome->>'type'<>'card' or outcome->>'card_id' is distinct from other_card
      or (select count(*) from trpg_cards.owned_cards
         where player_id=p and card_id=primary_card)<>1
      or (select count(*) from trpg_cards.owned_cards
         where player_id=p and card_id=other_card)<>1 then
      raise exception 'test_failed_alternate_valid_slot_not_preserved';
    end if;
    payload:=jsonb_build_object(
      'colliding_card_already_owned_rejected',true,
      'original_draft_still_offered_after_rejection',true,
      'alternate_existing_slot_resolved',true,
      'card_ownership_not_duplicated',true,
      'open_draft_candidate_not_automatically_replaced',true,
      'full_HQ_special_award_ordering_still_requires_integration_test',true,
      'rollback',true);
    raise exception 'HQ9_COLLISION_SUCCESS_ROLLBACK';
  exception when others then
    if sqlerrm<>'HQ9_COLLISION_SUCCESS_ROLLBACK' then raise; end if;
  end;
  insert into pg_temp.hq9_collision_result(note,result)
    values('original_card_draft_collision_under_independent_acquisition',payload);
end $t$;
select note,result from pg_temp.hq9_collision_result;