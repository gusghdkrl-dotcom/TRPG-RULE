-- PHASE 10: DEV ONLY. Order-sensitive HQ special A versus already-offered or already-resolved general draft.
-- Synthetic candidates are deterministic fixtures to test ledger/ownership flow,
-- NOT a replacement for live Keeper Python SystemRandom draw/rarity distribution.
-- Every new agent/campaign/checkpoint/reward is rolled back per scenario.
create temporary table hq_phase10_reports(
  scenario text not null, result jsonb not null
) on commit drop;

do $test$
declare
  sc record;
  ids uuid[];
  pid uuid;
  teamid uuid;
  missionid uuid;
  completed_mission uuid;
  segid uuid;
  campaign text;
  session text;
  canonsha text;
  chapter int;
  roundnum int;
  i int;
  rev bigint;
  resultj jsonb;
  approval jsonb;
  opts jsonb;
  offers jsonb;
  pool jsonb;
  doc jsonb;
  pcs jsonb;
  cpstr text;
  cpsha text;
  parent_sha text;
  outcome jsonb;
  draft trpg_cards.drafts%rowtype;
  current_offer text;
  all_offer text;
  growth_offer text;
  neutral_offer text;
  special_card constant text:='NE-A-4';
  chosen_slot smallint;
  card_count integer;
  growth_count integer;
  medal_count integer;
  cert_count integer;
  resolved_count integer;
  first_chapter_reward_count integer;
  report jsonb;
  individual_results jsonb;
  special_owned_map jsonb;
  normal_owned_map jsonb;
  saved_json jsonb;
begin
 for sc in select * from (values ('two_agents',2),('three_agents',3)) s(scenario,participants)
 loop
   report:=null;
   begin
     ids:='{}'::uuid[];
     for i in 1..sc.participants loop
       pid:=(trpg_cards.register_player('HQ10_'||sc.participants||'_'||i)->>'player_id')::uuid;
       ids:=array_append(ids,pid);
     end loop;
     teamid:=(trpg_hq.create_team('hq10-'||sc.scenario,ids)->>'team_id')::uuid;
     -- ONLY synthetic cohort qualification: real agent training has its own RPC.
     update trpg_hq.hq_agents set qualification='training_qualified',
       training_completed=true where agent_id=any(ids);
     individual_results:='[]'::jsonb;
     special_owned_map:='{}'::jsonb;
     normal_owned_map:='{}'::jsonb;

     for roundnum in 1..2 loop
       campaign:='hq10-'||sc.scenario||'-r'||roundnum;
       session:='hq10-session-'||sc.scenario||'-r'||roundnum;
       perform trpg_cards.open_campaign(campaign,'chronicle',session);
       for i in 1..sc.participants loop
         perform trpg_cards.enroll_player(campaign,ids[i],
           case i when 1 then 'guardian' when 2 then 'rogue' else 'seeker' end);
       end loop;
       insert into trpg_private.gm_canon_documents(
         campaign_id,canon_id,revision,filename,
         document_format,rules_version,content_md,file_sha256)
       select campaign,'hq10-canon',1,'PRIVATE_CANON_HQ9.md',
         document_format,rules_version,content_md,file_sha256
       from trpg_private.gm_canon_documents
       where campaign_id='hq-dev-chronicle-20261112'
         and canon_id='hq-dev-chronicle-canon' and revision=1;
       select file_sha256 into canonsha
         from trpg_private.gm_canon_documents
         where campaign_id=campaign and canon_id='hq10-canon';
       if canonsha is null then raise exception 'fixture_canon_not_installed'; end if;
       select revision into rev from trpg_hq.hq_teams where team_id=teamid;
       resultj:=trpg_hq.prepare_mission(teamid,campaign,'chronicle','I',
         '[{"id":"dev9-goal","description":"다인 검증용 연대기 목표","importance":"core"}]'::jsonb,
         '{"fixture":true}'::jsonb,'chapter:01',session,rev);
       missionid:=(resultj->>'mission_id')::uuid;
       segid:=(resultj->>'segment_id')::uuid;
       parent_sha:=null;

       for chapter in 1..(case when roundnum=1 then 2 else 1 end) loop
         if chapter=2 then
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.prepare_next_chapter(
             missionid,'chapter:02',session,rev);
           segid:=(resultj->>'segment_id')::uuid;
         end if;
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.start_segment(segid,rev);
         select state_json::jsonb into doc from public.gm_checkpoint_history
         where session_id='hq-dev-chronicle-session-20261112'
           and version=chapter and status='verified';
         if doc is null then raise exception 'fixture_checkpoint_template_missing'; end if;
         pcs:='{}'::jsonb;
         for i in 1..sc.participants loop
           pcs:=pcs||jsonb_build_object('P'||i::text,
             jsonb_build_object('player_id',ids[i]::text,'alive',true));
         end loop;
         doc:=jsonb_set(doc,'{campaign_id}',to_jsonb(campaign));
         doc:=jsonb_set(doc,'{session_id}',to_jsonb(session));
         doc:=jsonb_set(doc,'{canon_ref,campaign_id}',to_jsonb(campaign));
         doc:=jsonb_set(doc,'{canon_ref,canon_id}',to_jsonb('hq10-canon'::text));
         doc:=jsonb_set(doc,'{canon_ref,filename}',to_jsonb('PRIVATE_CANON_HQ9.md'::text));
         doc:=jsonb_set(doc,'{canon_ref,file_sha256}',to_jsonb(canonsha));
         doc:=jsonb_set(doc,'{runtime,hq,mission_id}',to_jsonb(missionid::text));
         doc:=jsonb_set(doc,'{runtime,hq,segment_key}',
           to_jsonb('chapter:0'||chapter::text));
         doc:=jsonb_set(doc,'{pcs}',pcs);
         doc:=jsonb_set(doc,'{runtime,ending_state}',
           jsonb_build_object(
             'scope',case when roundnum=1 and chapter=1
                then 'CHAPTER_TERMINAL' else 'CHRONICLE_TERMINAL' end,
             'status',case when roundnum=2 then 'failed' else 'completed' end,
             'returning_agent_ids',to_jsonb(ids),
             'finalization_event_id',campaign||':terminal:'||chapter::text));
         doc:=jsonb_set(doc,'{checkpoint}',jsonb_build_object(
           'version',chapter,'event_id',session||':cp'||chapter::text,
           'attempt_id','hq10-attempt-'||chapter::text,
           'parent_version',case when chapter=1 then null else 1 end,
           'parent_sha256',parent_sha));
         cpstr:=doc::text;
         if public.trpg_v2_payload_issue(cpstr) is not null then
           raise exception 'fixture_checkpoint_payload_invalid: %',
             public.trpg_v2_payload_issue(cpstr);
         end if;
         cpsha:=encode(sha256(convert_to(cpstr,'UTF8')),'hex');
         perform public.trpg_v2_commit(session,chapter,
           session||':cp'||chapter::text,'hq10-attempt-'||chapter::text,
           case when chapter=1 then null else 1 end,parent_sha,cpstr,cpsha);
         perform public.trpg_v2_verify(session,chapter,
           session||':cp'||chapter::text,'hq10-attempt-'||chapter::text,cpsha);
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.confirm_segment_terminal(segid,chapter,cpsha,rev);
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.return_segment(segid,rev);
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.evaluate_segment(segid,rev,
           case when roundnum=2 then 'F' else 'A' end,
           '[{"id":"dev9-goal","result":"achieved","reason":"검증용 가상 평가"}]'::jsonb,
           'DEV10 가상 마틴 평가',
           jsonb_build_object('dev_fixture',true,'round',roundnum));
         parent_sha:=cpsha;
       end loop;

       select revision into rev from trpg_hq.hq_teams where team_id=teamid;
       if roundnum=1 then
         completed_mission:=missionid;
         approval:=trpg_hq.approve_chronicle_completion(
           segid,rev,'DEV10 전체 성공·귀환에 따른 마틴 완주 평가');
         if approval->>'applied'<>'true'
           or (approval->>'medals')::integer<>sc.participants then
           raise exception 'fixture_team_completion_not_confirmed';
         end if;

         -- Order A: draft offered -> special A acquires current-slot card ->
         -- current slot is unavailable -> the original second slot remains
         -- selectable. Order B: general current slot resolved -> special A
         -- refuses already-owned current card -> pick a different eligible
         -- special A card. This is real HQ RPC, not raw card insertion.
         for i in 1..sc.participants loop
           pid:=ids[i];
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.approve_general_reward(
             segid,pid,rev,'DEV10 최종 챕터 독립 일반 보상 승인');
           if resultj->>'status'<>'approved' then
             raise exception 'fixture_general_reward_not_approved';end if;
           pool:=trpg_cards.draft_pool(campaign,pid);
           select x->>'id' into current_offer from jsonb_array_elements(pool->'current') x limit 1;
           select x->>'id' into all_offer from jsonb_array_elements(pool->'all') x
             where x->>'id' is distinct from current_offer limit 1;
           select x->>'id' into growth_offer from jsonb_array_elements(pool->'growth') x limit 1;
           select x->>'id' into neutral_offer from jsonb_array_elements(pool->'neutral') x limit 1;
           if current_offer is null or all_offer is null then
             raise exception 'test_fixture_draft_offer_candidates_missing';end if;
           offers:=jsonb_build_object('current',current_offer,'all',all_offer,
             'growth',growth_offer,'neutral',neutral_offer);
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.offer_general_reward(segid,pid,rev,offers);
           if resultj->>'status'<>'offered' then
             raise exception 'fixture_draft_not_offered';end if;
           if (i%2)=1 then
             -- Offered draft still holds this card as option 1.
             select revision into rev from trpg_hq.hq_teams where team_id=teamid;
             outcome:=trpg_hq.resolve_chronicle_special(
               completed_mission,pid,rev,'card',current_offer);
             if outcome->>'applied'<>'true' then
               raise exception 'fixture_special_A_not_awarded_first';end if;
             select revision into rev from trpg_hq.hq_teams where team_id=teamid;
             begin
               perform trpg_hq.resolve_general_reward(segid,pid,rev,1::smallint,null::integer);
               raise exception 'test_duplicate_slot_claimed_after_special';
             exception when others then
               if sqlerrm<>'card_already_owned_before_selection' then raise;end if;
             end;
             if not exists(select 1 from trpg_hq.hq_reward_grants
               where segment_id=segid and player_id=pid and status='offered')
               then raise exception 'test_failed_open_draft_after_collision';end if;
             chosen_slot:=2::smallint;
             select revision into rev from trpg_hq.hq_teams where team_id=teamid;
             resultj:=trpg_hq.resolve_general_reward(segid,pid,rev,chosen_slot,null);
             if resultj->>'applied'<>'true'
               or resultj->'outcome'->>'card_id' is distinct from all_offer then
               raise exception 'fixture_normal_other_slot_not_settled';end if;
             special_owned_map:=special_owned_map||jsonb_build_object(pid::text,current_offer);
             normal_owned_map:=normal_owned_map||jsonb_build_object(pid::text,all_offer);
           else
             -- First take the offered normal card, THEN attempt same A card.
             chosen_slot:=1::smallint;
             select revision into rev from trpg_hq.hq_teams where team_id=teamid;
             resultj:=trpg_hq.resolve_general_reward(segid,pid,rev,chosen_slot,null);
             if resultj->>'applied'<>'true'
               or resultj->'outcome'->>'card_id' is distinct from current_offer then
               raise exception 'fixture_normal_card_not_settled_first';end if;
             select revision into rev from trpg_hq.hq_teams where team_id=teamid;
             begin
               perform trpg_hq.resolve_chronicle_special(
                 completed_mission,pid,rev,'card',current_offer);
               raise exception 'test_special_same_owned_card_granted';
             exception when others then
               if sqlerrm<>'hq_special_card_already_owned' then raise;end if;
             end;
             if not exists(select 1 from trpg_hq.hq_chronicle_honors
               where mission_id=completed_mission and player_id=pid
                 and status='awaiting_choice') then
               raise exception 'test_failed_special_choice_destroyed';end if;
             select revision into rev from trpg_hq.hq_teams where team_id=teamid;
             outcome:=trpg_hq.resolve_chronicle_special(
               completed_mission,pid,rev,'card',all_offer);
             if outcome->>'applied'<>'true' then
               raise exception 'fixture_special_A_alternate_not_awarded';end if;
             special_owned_map:=special_owned_map||jsonb_build_object(pid::text,all_offer);
             normal_owned_map:=normal_owned_map||jsonb_build_object(pid::text,current_offer);
           end if;

           -- Each claim has an independent source / one card, not two
           -- copies; repeated caller choice is a no-op.
           if (select count(*) from trpg_cards.owned_cards
             where player_id=pid
               and card_id in (special_owned_map->>pid::text,
                               normal_owned_map->>pid::text))<>2
             or not exists(select 1 from trpg_cards.owned_cards oc
               where oc.player_id=pid and oc.card_id=special_owned_map->>pid::text
                 and oc.acquisition_event='medal:'||completed_mission::text||':'||pid::text||':special')
             or not exists(select 1 from trpg_cards.owned_cards oc
               where oc.player_id=pid and oc.card_id=normal_owned_map->>pid::text
                 and oc.acquisition_event=campaign||':chapter:02') then
             raise exception 'fixture_ownership_or_sources_collided';end if;
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.resolve_chronicle_special(completed_mission,pid,rev,
             'card',special_owned_map->>pid::text);
           if resultj->>'applied'<>'false' then
             raise exception 'test_duplicate_special_payout';end if;
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.resolve_general_reward(segid,pid,rev,chosen_slot,null);
           if resultj->>'applied'<>'false' then
             raise exception 'test_duplicate_general_payout';end if;
           individual_results:=individual_results||jsonb_build_array(jsonb_build_object(
             'agent_index',i,'order',case when (i%2)=1
               then 'offered_then_special_then_general_alternate'
               else 'general_resolved_then_special_alternate' end,
             'special_card',special_owned_map->>pid::text,
             'normal_card',normal_owned_map->>pid::text,
             'duplicate_card_blocked',true,
             'unaffected_alternative_received',true));
         end loop;
         if (select count(*) from trpg_hq.hq_reward_grants
           where campaign=campaign_id and event_key='chapter:02' and status='resolved')
              <>sc.participants then raise exception 'fixture_general_resolution_count';end if;
         if exists(select 1 from jsonb_array_elements(
           trpg_hq.load_team_rewards(teamid)) x(v)
           where x.v->>'ledger_consistent'<>'true') then
           raise exception 'fixture_general_reward_ledger_mismatch';
         end if;
         if exists(select 1 from jsonb_array_elements(
           trpg_hq.load_chronicle_honors(teamid)) x(v)
           where x.v->>'ledger_consistent'<>'true') then
           raise exception 'fixture_special_reward_ledger_mismatch';
         end if;
         if (select count(*) from trpg_hq.hq_npc_agent_relations
           where team_id=teamid)<>0
           or (select count(*) from trpg_hq.hq_clara_releases
             where team_id=teamid)<>0 then
           raise exception 'fixture_rewards_invented_npc_personal_memories';
         end if;
       else
         if (select status from trpg_hq.hq_missions
               where mission_id=missionid)<>'failed' then
           raise exception 'fixture_followup_failed_chronicle_not_failed';
         end if;
         begin
           perform trpg_hq.approve_chronicle_completion(
             segid,rev,'DEV10 후속 실패를 성공으로 가장');
           raise exception 'fixture_false_success';
         exception when others then
           if sqlerrm<>'hq_chronicle_not_verified_completed_and_evaluated'
             then raise; end if;
         end;
         select count(*) into medal_count from trpg_hq.hq_chronicle_honors
           where mission_id=completed_mission;
         select count(*) into cert_count from trpg_hq.hq_agent_full_certifications
           where player_id=any(ids);
         select count(*) into resolved_count from trpg_hq.hq_reward_grants g
           where g.campaign_id=case when sc.participants=2
              then 'hq10-two_agents-r1' else 'hq10-three_agents-r1' end
              and g.event_key='chapter:02' and g.status='resolved';
         if medal_count<>sc.participants or cert_count<>sc.participants
           or resolved_count<>sc.participants
           or (select count(*) from trpg_hq.hq_chronicle_honors
                where mission_id=missionid)<>0 then
           raise exception 'fixture_prior_honors_or_normal_payouts_lost';
         end if;
         for i in 1..sc.participants loop
           pid:=ids[i];
           if not exists(select 1 from trpg_cards.owned_cards
             where player_id=pid and card_id=special_owned_map->>pid::text
               and acquisition_event='medal:'||completed_mission::text||':'||pid::text||':special')
             or not exists(select 1 from trpg_cards.owned_cards
               where player_id=pid and card_id=normal_owned_map->>pid::text
                 and acquisition_event=case when sc.participants=2
                   then 'hq10-two_agents-r1:chapter:02' else 'hq10-three_agents-r1:chapter:02' end)
             then raise exception 'fixture_followup_failure_revoked_card';end if;
         end loop;
         report:=jsonb_build_object(
           'participants',sc.participants,
           'special_A_count',sc.participants,
           'special_B_count',0,
           'normal_drafts_resolved',resolved_count,
           'total_first_certifications',cert_count,
           'successful_medals',medal_count,
           'failed_followup_new_medals',0,
           'earlier_normal_rewards_preserved',true,
           'earlier_special_rewards_preserved',true,
           'both_claim_orders_tested',true,
           'independent_NPC_personal_records_unchanged',true,
           'reloaded_normal_ledger',trpg_hq.load_team_rewards(teamid),
           'individual_results',individual_results,
           'all_synthetic_changes_rolled_back',true);
       end if;
     end loop;
     raise exception 'HQ10_SUCCESS_ROLLBACK';
   exception when others then
     if sqlerrm<>'HQ10_SUCCESS_ROLLBACK' then
       raise exception 'HQ10 scenario % failed: %',sc.scenario,sqlerrm;
     end if;
   end;
   if report is null then raise exception 'HQ10_null_report';end if;
   insert into pg_temp.hq_phase10_reports(scenario,result)
   values(sc.scenario,report);
 end loop;
end $test$;
select scenario,
  result->>'participants' as participants,
  result->>'special_A_count' as special_A,
  result->>'special_B_count' as special_B,
  result->>'normal_drafts_resolved' as general_resolved,
  result->>'successful_medals' as medals,
  result->>'total_first_certifications' as first_certifications,
  result->>'failed_followup_new_medals' as failed_followup_medals,
  result->>'earlier_normal_rewards_preserved' as normal_preserved,
  result->>'earlier_special_rewards_preserved' as special_preserved,
  result->>'independent_NPC_personal_records_unchanged' as npc_memory_not_invented,
  result->'individual_results' as per_agent,
  result->>'all_synthetic_changes_rolled_back' as rolled_back
from pg_temp.hq_phase10_reports order by scenario;
