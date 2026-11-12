-- PHASE 9: DEV ONLY. 2/3 player special A/B + actual normal chapter draft settlement.
-- Synthetic candidates are deterministic fixtures to test ledger/ownership flow,
-- NOT a replacement for live Keeper Python SystemRandom draw/rarity distribution.
-- Every new agent/campaign/checkpoint/reward is rolled back per scenario.
create temporary table hq_phase9_reports(
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
  saved_json jsonb;
begin
 for sc in select * from (values ('two_agents',2),('three_agents',3)) s(scenario,participants)
 loop
   report:=null;
   begin
     ids:='{}'::uuid[];
     for i in 1..sc.participants loop
       pid:=(trpg_cards.register_player('HQ9_'||sc.participants||'_'||i)->>'player_id')::uuid;
       ids:=array_append(ids,pid);
     end loop;
     teamid:=(trpg_hq.create_team('hq9-'||sc.scenario,ids)->>'team_id')::uuid;
     -- ONLY synthetic cohort qualification: real agent training has its own RPC.
     update trpg_hq.hq_agents set qualification='training_qualified',
       training_completed=true where agent_id=any(ids);
     individual_results:='[]'::jsonb;

     for roundnum in 1..2 loop
       campaign:='hq9-'||sc.scenario||'-r'||roundnum;
       session:='hq9-session-'||sc.scenario||'-r'||roundnum;
       perform trpg_cards.open_campaign(campaign,'chronicle',session);
       for i in 1..sc.participants loop
         perform trpg_cards.enroll_player(campaign,ids[i],
           case i when 1 then 'guardian' when 2 then 'rogue' else 'seeker' end);
       end loop;
       insert into trpg_private.gm_canon_documents(
         campaign_id,canon_id,revision,filename,
         document_format,rules_version,content_md,file_sha256)
       select campaign,'hq9-canon',1,'PRIVATE_CANON_HQ9.md',
         document_format,rules_version,content_md,file_sha256
       from trpg_private.gm_canon_documents
       where campaign_id='hq-dev-chronicle-20261112'
         and canon_id='hq-dev-chronicle-canon' and revision=1;
       select file_sha256 into canonsha
         from trpg_private.gm_canon_documents
         where campaign_id=campaign and canon_id='hq9-canon';
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
         doc:=jsonb_set(doc,'{canon_ref,canon_id}',to_jsonb('hq9-canon'::text));
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
           'attempt_id','hq9-attempt-'||chapter::text,
           'parent_version',case when chapter=1 then null else 1 end,
           'parent_sha256',parent_sha));
         cpstr:=doc::text;
         if public.trpg_v2_payload_issue(cpstr) is not null then
           raise exception 'fixture_checkpoint_payload_invalid: %',
             public.trpg_v2_payload_issue(cpstr);
         end if;
         cpsha:=encode(sha256(convert_to(cpstr,'UTF8')),'hex');
         perform public.trpg_v2_commit(session,chapter,
           session||':cp'||chapter::text,'hq9-attempt-'||chapter::text,
           case when chapter=1 then null else 1 end,parent_sha,cpstr,cpsha);
         perform public.trpg_v2_verify(session,chapter,
           session||':cp'||chapter::text,'hq9-attempt-'||chapter::text,cpsha);
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.confirm_segment_terminal(segid,chapter,cpsha,rev);
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.return_segment(segid,rev);
         select revision into rev from trpg_hq.hq_teams where team_id=teamid;
         perform trpg_hq.evaluate_segment(segid,rev,
           case when roundnum=2 then 'F' else 'A' end,
           '[{"id":"dev9-goal","result":"achieved","reason":"검증용 가상 평가"}]'::jsonb,
           'DEV9 가상 마틴 평가',
           jsonb_build_object('dev_fixture',true,'round',roundnum));
         parent_sha:=cpsha;
       end loop;

       select revision into rev from trpg_hq.hq_teams where team_id=teamid;
       if roundnum=1 then
         completed_mission:=missionid;
         approval:=trpg_hq.approve_chronicle_completion(
           segid,rev,'DEV9 전체 성공·귀환에 따른 마틴 완주 평가');
         if approval->>'applied'<>'true'
           or (approval->>'medals')::integer<>sc.participants then
           raise exception 'fixture_team_completion_not_confirmed';
         end if;

         -- Every player selects their OWN special reward. Odd agents choose
         -- the SAME eligible neutral card across different UUIDs; even agent
         -- chooses guaranteed POW growth; no automatic or NPC choice.
         for i in 1..sc.participants loop
           pid:=ids[i];
           opts:=trpg_hq.chronicle_special_options(completed_mission,pid);
           if opts->>'status'<>'awaiting_choice' then
             raise exception 'fixture_special_not_pending';
           end if;
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           if (i % 2)=1 then
             if not exists(
               select 1 from jsonb_array_elements(opts->'eligible_direct_cards') c
                 where c->>'card_id'=special_card) then
               raise exception 'fixture_special_card_not_eligible';
             end if;
             outcome:=trpg_hq.resolve_chronicle_special(
                completed_mission,pid,rev,'card',special_card);
             if outcome->>'applied'<>'true'
                or not exists(select 1 from trpg_cards.owned_cards
                  where player_id=pid and card_id=special_card
                    and acquisition_event='medal:'||completed_mission::text||':'||pid::text||':special') then
               raise exception 'fixture_special_card_not_owned_by_exact_agent';
             end if;
           else
             outcome:=trpg_hq.resolve_chronicle_special(
                completed_mission,pid,rev,'growth','POW');
             if outcome->>'applied'<>'true'
               or (outcome->'outcome'->>'after_level')::integer<>1 then
               raise exception 'fixture_special_growth_not_added_to_exact_agent';
             end if;
           end if;
           -- Replaying choice cannot grant another card or growth.
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.resolve_chronicle_special(
             completed_mission,pid,rev,
             case when (i % 2)=1 then 'card' else 'growth' end,
             case when (i % 2)=1 then special_card else 'POW' end);
           if resultj->>'applied'<>'false' then
             raise exception 'fixture_special_replay_duplicated';
           end if;

           -- Final chapter NORMAL reward is independent of the medal.
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.approve_general_reward(
             segid,pid,rev,'DEV9 최종 챕터 일반 드래프트 독립 승인');
           if resultj->>'status'<>'approved' then
             raise exception 'fixture_general_reward_not_approved';
           end if;
           -- Deterministic fixtures are chosen FROM the LIVE eligible pool;
           -- they test official card selection, NOT random weights.
           pool:=trpg_cards.draft_pool(campaign,pid);
           select p->>'id' into current_offer from jsonb_array_elements(pool->'current') p limit 1;
           select p->>'id' into all_offer from jsonb_array_elements(pool->'all') p
             where p->>'id' is distinct from current_offer limit 1;
           select p->>'id' into growth_offer from jsonb_array_elements(pool->'growth') p limit 1;
           select p->>'id' into neutral_offer from jsonb_array_elements(pool->'neutral') p limit 1;
           offers:=jsonb_build_object('current',current_offer,'all',all_offer,
             'growth',growth_offer,'neutral',neutral_offer);
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.offer_general_reward(segid,pid,rev,offers);
           if resultj->>'status'<>'offered' then
             raise exception 'fixture_general_reward_not_offered: %',resultj;
           end if;
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.offer_general_reward(segid,pid,rev,offers);
           if resultj->>'applied'<>'false' then
             raise exception 'fixture_general_offer_reissued';
           end if;
           chosen_slot:=case i when 1 then 1 when 2 then 3 else 4 end;
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           outcome:=trpg_hq.resolve_general_reward(
             segid,pid,rev,chosen_slot,null);
           if outcome->>'applied'<>'true' then
             raise exception 'fixture_general_reward_not_settled';
           end if;
           select * into draft from trpg_cards.drafts
             where campaign_id=campaign and player_id=pid
               and event_key='chapter:02';
           if draft.status<>'resolved' or draft.chosen_slot<>chosen_slot
             or draft.outcome is distinct from outcome->'outcome' then
             raise exception 'fixture_original_card_draft_mismatch';
           end if;
           select revision into rev from trpg_hq.hq_teams where team_id=teamid;
           resultj:=trpg_hq.resolve_general_reward(
             segid,pid,rev,chosen_slot,null);
           if resultj->>'applied'<>'false' then
             raise exception 'fixture_general_reward_replay_doubled';
           end if;
           if (i%2)=1 and (
             (select count(*) from trpg_cards.owned_cards
                where player_id=pid and card_id=special_card)<>1
              or (select count(*) from trpg_cards.owned_cards
                where player_id=pid and acquisition_event=campaign||':chapter:02')<>1)
           then
             raise exception 'fixture_card_player_owner_mixed';
           end if;
           if i=2 and
              (coalesce((select level from trpg_cards.growth_levels
                where player_id=pid and stat='POW'),0)<>1
              or coalesce((select level from trpg_cards.growth_levels
                where player_id=pid and stat=growth_offer),0)<>1)
           then
             raise exception 'fixture_special_growth_and_general_growth_not_independent';
           end if;
           individual_results:=individual_results||jsonb_build_array(
             jsonb_build_object('agent_index',i,
               'special',case when (i%2)=1 then 'A_card' else 'B_growth' end,
               'general_slot',chosen_slot,'general_type',
                 outcome->'outcome'->>'type',
               'normal_draft_resolved',true,'separate_ownership',true));
         end loop;
         -- The four player-specific reward events must name exactly their
         -- own recipient, not send another agent's private choice to the team.
         if (select count(*) from trpg_hq.hq_events e
               where e.team_id=teamid and e.event_kind in (
                 'reward_approved','reward_offered',
                 'reward_resolved','chronicle_special_resolved')
               and e.event_data->>'player_id'=any(
                 select x.id::text from unnest(ids) x(id)))
              <>4*sc.participants
           or exists(select 1 from trpg_hq.hq_events e
             where e.team_id=teamid and e.event_kind in (
               'reward_approved','reward_offered',
               'reward_resolved','chronicle_special_resolved')
             and (jsonb_typeof(e.audience)<>'array'
                 or jsonb_array_length(e.audience)<>1
                 or e.audience->>0 is distinct from e.event_data->>'player_id')) then
           raise exception 'fixture_private_reward_event_audience_crossed';
         end if;
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
             segid,rev,'DEV9 후속 실패를 성공으로 가장');
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
              then 'hq9-two_agents-r1' else 'hq9-three_agents-r1' end
              and g.event_key='chapter:02' and g.status='resolved';
         if medal_count<>sc.participants or cert_count<>sc.participants
           or resolved_count<>sc.participants
           or (select count(*) from trpg_hq.hq_chronicle_honors
                where mission_id=missionid)<>0 then
           raise exception 'fixture_prior_honors_or_normal_payouts_lost';
         end if;
         for i in 1..sc.participants loop
           pid:=ids[i];
           if (i%2)=1 then
             if not exists(select 1 from trpg_cards.owned_cards
               where player_id=pid and card_id=special_card
                 and acquisition_event='medal:'||completed_mission::text||':'||pid::text||':special') then
               raise exception 'fixture_previous_special_card_revoked';
             end if;
           else
             if coalesce((select level from trpg_cards.growth_levels
               where player_id=pid and stat='POW'),0)<>1 then
               raise exception 'fixture_previous_special_growth_revoked';
             end if;
           end if;
         end loop;
         report:=jsonb_build_object(
           'participants',sc.participants,
           'special_A_count',((sc.participants+1)/2),
           'special_B_count',(sc.participants/2),
           'normal_drafts_resolved',resolved_count,
           'total_first_certifications',cert_count,
           'successful_medals',medal_count,
           'failed_followup_new_medals',0,
           'earlier_normal_rewards_preserved',true,
           'earlier_special_rewards_preserved',true,
           'independent_NPC_personal_records_unchanged',true,
           'reloaded_normal_ledger',trpg_hq.load_team_rewards(teamid),
           'individual_results',individual_results,
           'all_synthetic_changes_rolled_back',true);
       end if;
     end loop;
     raise exception 'HQ9_SUCCESS_ROLLBACK';
   exception when others then
     if sqlerrm<>'HQ9_SUCCESS_ROLLBACK' then
       raise exception 'HQ9 scenario % failed: %',sc.scenario,sqlerrm;
     end if;
   end;
   if report is null then raise exception 'HQ9_null_report';end if;
   insert into pg_temp.hq_phase9_reports(scenario,result)
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
from pg_temp.hq_phase9_reports order by scenario;
