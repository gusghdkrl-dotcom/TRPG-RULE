-- DEV ONLY / PHASE 8 REPEAT CHRONICLE REGRESSION
-- Uses the existing, already full-certified DEV-only agent in the same team.
-- An intentionally raised exception at the END of the fixture rolls ALL
-- new campaigns, checkpoints, honors, new growth, and team time back.
-- Only the one-row TEMP test report survives the inner subtransaction.

create temporary table hq_phase8_repeat_report(
  scenario text not null, result jsonb not null
) on commit drop;

do $t$
declare
 v_agent constant uuid:='e0c56a38-d1c6-4814-9468-2b54c3ca59e8'::uuid;
 v_team constant uuid:='32cebe3d-6cd7-43b7-ae3c-fe0d40093f7c'::uuid;
 v_before_cert trpg_hq.hq_agent_full_certifications%rowtype;
 v_first_honor trpg_hq.hq_chronicle_honors%rowtype;
 v_prev_card_event text;
 v_base_medals integer;
 v_base_completed integer;
 v_base_cards integer;
 v_base_growth integer;
 v_base_revision bigint;
 v_base_hq_minutes bigint;
 v_team_hours integer;
 v_current_medals integer;
 v_current_certs integer;
 v_current_completed integer;
 v_current_growth integer;
 v_mission uuid;
 v_segment uuid;
 v_success_mission uuid;
 v_success_medal_key text;
 v_campaign text;
 v_session text;
 v_canon_sha text;
 v_ch integer;
 v_round integer;
 v_rev bigint;
 v_document jsonb;
 v_pcs jsonb;
 v_state text;
 v_hash text;
 v_parent text;
 v_result jsonb;
 v_approved jsonb;
 v_replay jsonb;
 v_choice jsonb;
 v_options jsonb;
 v_previous_general integer;
 v_report jsonb;
 v_failure_reason text;
begin
 v_report:=null;
 begin
   select * into v_before_cert from trpg_hq.hq_agent_full_certifications
     where player_id=v_agent;
   select * into v_first_honor from trpg_hq.hq_chronicle_honors
     where mission_id=v_before_cert.first_mission_id and player_id=v_agent;
   select acquisition_event into v_prev_card_event
      from trpg_cards.owned_cards
      where player_id=v_agent and card_id='RO-A-3';
   select count(*) into v_base_medals
      from trpg_hq.hq_chronicle_honors where player_id=v_agent;
   select count(*) into v_base_completed
      from trpg_hq.hq_chronicle_completions
      where v_agent=any(completed_players);
   select count(*) into v_base_cards
      from trpg_cards.owned_cards where player_id=v_agent;
   select coalesce(level,0) into v_base_growth
      from trpg_cards.growth_levels where player_id=v_agent and stat='POW';
   v_base_growth:=coalesce(v_base_growth,0);
   select revision,hq_elapsed_minutes into v_base_revision,v_base_hq_minutes
      from trpg_hq.hq_teams where team_id=v_team;
   if v_before_cert.first_mission_id is null
       or v_first_honor.status<>'resolved'
       or v_prev_card_event is null
       or v_base_medals<>1 or v_base_completed<>1
       or (select qualification from trpg_hq.hq_agents where agent_id=v_agent)<>'full_agent'
   then
       raise exception 'phase8_existing_full_certified_agent_fixture_missing';
   end if;

   -- ROUND 1: same permanent player+team, DIFFERENT campaign/world,
   -- two consecutive verified chapters, second chronicle fully completed.
   -- ROUND 2: third distinct campaign, verified failure and no new medal.
   for v_round in 1..2 loop
     v_campaign:=case when v_round=1 then 'hq8-repeat-success'
       else 'hq8-repeat-failure' end;
     v_session:='hq8-session-'||v_round::text;
     perform trpg_cards.open_campaign(v_campaign,'chronicle',v_session);
     perform trpg_cards.enroll_player(v_campaign,v_agent,'guardian');
     insert into trpg_private.gm_canon_documents(
       campaign_id,canon_id,revision,filename,
       document_format,rules_version,content_md,file_sha256)
     select v_campaign,'hq8-canon',1,'PRIVATE_CANON_HQ8.md',
       document_format,rules_version,content_md,file_sha256
     from trpg_private.gm_canon_documents
     where campaign_id='hq-dev-chronicle-20261112'
       and canon_id='hq-dev-chronicle-canon' and revision=1;
     select file_sha256 into v_canon_sha
       from trpg_private.gm_canon_documents
       where campaign_id=v_campaign and canon_id='hq8-canon';
     if v_canon_sha is null then raise exception 'phase8_fixture_canon_not_copied';end if;
     select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
     v_result:=trpg_hq.prepare_mission(v_team,v_campaign,'chronicle','I',
       '[{"id":"p8-objective","description":"개발 가상 연대기","importance":"core"}]'::jsonb,
       '{"synthetic_test":true}'::jsonb,'chapter:01',v_session,v_rev);
     v_mission:=(v_result->>'mission_id')::uuid;
     v_segment:=(v_result->>'segment_id')::uuid;
     v_parent:=null;

     for v_ch in 1..(case when v_round=1 then 2 else 1 end) loop
       if v_ch=2 then
         select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
         v_result:=trpg_hq.prepare_next_chapter(
           v_mission,'chapter:02',v_session,v_rev);
         v_segment:=(v_result->>'segment_id')::uuid;
       end if;
       select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
       perform trpg_hq.start_segment(v_segment,v_rev);

       select state_json::jsonb into v_document
       from public.gm_checkpoint_history
       where session_id='hq-dev-chronicle-session-20261112'
         and version=v_ch and status='verified';
       if v_document is null then raise exception 'phase8_template_missing';end if;
       v_pcs:=jsonb_build_object('P1',jsonb_build_object(
         'player_id',v_agent::text,'alive',true));
       v_document:=jsonb_set(v_document,'{campaign_id}',to_jsonb(v_campaign));
       v_document:=jsonb_set(v_document,'{session_id}',to_jsonb(v_session));
       v_document:=jsonb_set(v_document,'{canon_ref,campaign_id}',to_jsonb(v_campaign));
       v_document:=jsonb_set(v_document,'{canon_ref,canon_id}',to_jsonb('hq8-canon'::text));
       v_document:=jsonb_set(v_document,'{canon_ref,filename}',to_jsonb('PRIVATE_CANON_HQ8.md'::text));
       v_document:=jsonb_set(v_document,'{canon_ref,file_sha256}',to_jsonb(v_canon_sha));
       v_document:=jsonb_set(v_document,'{runtime,hq,mission_id}',to_jsonb(v_mission::text));
       v_document:=jsonb_set(v_document,'{runtime,hq,segment_key}',
         to_jsonb('chapter:0'||v_ch::text));
       v_document:=jsonb_set(v_document,'{pcs}',v_pcs);
       v_document:=jsonb_set(v_document,'{runtime,ending_state}',
         jsonb_build_object(
           'scope',case when v_round=1 and v_ch=1 then 'CHAPTER_TERMINAL'
             else 'CHRONICLE_TERMINAL' end,
           'status',case when v_round=2 then 'failed' else 'completed' end,
           'returning_agent_ids',jsonb_build_array(v_agent::text),
           'finalization_event_id',v_campaign||':terminal:'||v_ch::text));
       v_document:=jsonb_set(v_document,'{checkpoint}',
          jsonb_build_object('version',v_ch,'event_id',v_session||':cp'||v_ch,
           'attempt_id','hq8-attempt-'||v_ch,
           'parent_version',case when v_ch=1 then null else 1 end,
           'parent_sha256',v_parent));
       v_state:=v_document::text;
       if public.trpg_v2_payload_issue(v_state) is not null then
         raise exception 'phase8_invalid_checkpoint: %',
            public.trpg_v2_payload_issue(v_state);
       end if;
       v_hash:=encode(sha256(convert_to(v_state,'UTF8')),'hex');
       perform public.trpg_v2_commit(
         v_session,v_ch,v_session||':cp'||v_ch,
         'hq8-attempt-'||v_ch,
         case when v_ch=1 then null else 1 end,
         v_parent,v_state,v_hash);
       perform public.trpg_v2_verify(
         v_session,v_ch,v_session||':cp'||v_ch,
         'hq8-attempt-'||v_ch,v_hash);
       select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
       perform trpg_hq.confirm_segment_terminal(v_segment,v_ch,v_hash,v_rev);
       select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
       perform trpg_hq.return_segment(v_segment,v_rev);
       select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
       perform trpg_hq.evaluate_segment(v_segment,v_rev,
         case when v_round=2 then 'F' else 'A' end,
         '[{"id":"p8-objective","result":"achieved","reason":"가상 테스트 검증"}]'::jsonb,
         'phase8 합성 시나리오 마틴 정성 평가',
         jsonb_build_object('fixture',true,'round',v_round));
       v_parent:=v_hash;
     end loop;

     select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
     if v_round=1 then
       v_success_mission:=v_mission;
       v_approved:=trpg_hq.approve_chronicle_completion(
          v_segment,v_rev,'DEV8 두 번째 연대기 정상 완주·평가');
       if v_approved->>'applied'<>'true'
         or (v_approved->>'new_full_certifications')::integer<>0
         or (v_approved->>'medals')::integer<>1 then
         raise exception 'phase8_repeat_completion_wrong_result: %',v_approved;
       end if;
       v_replay:=trpg_hq.approve_chronicle_completion(
          v_segment,v_rev,'DEV8 두 번째 연대기 정상 완주·평가');
       if v_replay->>'applied'<>'false' then
         raise exception 'phase8_repeat_completion_duplicate';
       end if;
       select medal_key into v_success_medal_key
         from trpg_hq.hq_chronicle_honors
         where mission_id=v_success_mission and player_id=v_agent
           and status='awaiting_choice';
       if v_success_medal_key is null then
         raise exception 'phase8_second_medal_or_choice_missing';
       end if;
       v_options:=trpg_hq.chronicle_special_options(v_success_mission,v_agent);
       if v_options->>'status'<>'awaiting_choice'
         or (select count(*) from trpg_hq.hq_agent_full_certifications
             where player_id=v_agent)<>1 then
          raise exception 'phase8_repeat_first_certificate_duplicated';
       end if;
       select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
       v_choice:=trpg_hq.resolve_chronicle_special(
         v_success_mission,v_agent,v_rev,'growth','POW');
       if v_choice->>'applied'<>'true'
         or (v_choice->'outcome'->>'after_level')::integer<>v_base_growth+1 then
          raise exception 'phase8_second_growth_choice_failed';
       end if;
       v_replay:=trpg_hq.resolve_chronicle_special(
         v_success_mission,v_agent,v_rev,'growth','POW');
       if v_replay->>'applied'<>'false' then
         raise exception 'phase8_second_special_replay_granted_again';
       end if;
       -- Different reward for same medal cannot be selected later.
       begin
         perform trpg_hq.resolve_chronicle_special(
           v_success_mission,v_agent,v_rev,'card','SE-A-3');
         raise exception 'phase8_second_award_doubled';
       exception when others then
         if sqlerrm<>'hq_chronicle_special_already_chosen_other_reward' then raise;end if;
       end;
     else
       if (select status from trpg_hq.hq_missions where mission_id=v_mission)<>'failed' then
         raise exception 'phase8_followup_failure_not_sticky';
       end if;
       begin
         perform trpg_hq.approve_chronicle_completion(
           v_segment,v_rev,'DEV8 실패를 완주로 위장');
         raise exception 'phase8_failed_followup_was_approved';
       exception when others then
         if sqlerrm<>'hq_chronicle_not_verified_completed_and_evaluated'
           then raise;end if;
       end;
       select count(*) into v_current_medals
         from trpg_hq.hq_chronicle_honors where player_id=v_agent;
       select count(*) into v_current_certs
         from trpg_hq.hq_agent_full_certifications where player_id=v_agent;
       select count(*) into v_current_completed
         from trpg_hq.hq_chronicle_completions
         where v_agent=any(completed_players);
       select coalesce(level,0) into v_current_growth
         from trpg_cards.growth_levels where player_id=v_agent and stat='POW';
       v_current_growth:=coalesce(v_current_growth,0);
       if v_current_medals<>v_base_medals+1
         or v_current_certs<>1
         or v_current_completed<>v_base_completed+1
         or v_current_growth<>v_base_growth+1
         or (select qualification from trpg_hq.hq_agents where agent_id=v_agent)<>'full_agent'
         or (select first_mission_id from trpg_hq.hq_agent_full_certifications
                where player_id=v_agent) is distinct from v_before_cert.first_mission_id
         or (select granted_at from trpg_hq.hq_agent_full_certifications
                where player_id=v_agent) is distinct from v_before_cert.granted_at
         or (select medal_key from trpg_hq.hq_chronicle_honors
                where mission_id=v_before_cert.first_mission_id and player_id=v_agent)
              is distinct from v_first_honor.medal_key
         or (select acquisition_event from trpg_cards.owned_cards
                where player_id=v_agent and card_id='RO-A-3')
              is distinct from v_prev_card_event
         or (select count(*) from trpg_cards.owned_cards where player_id=v_agent)<>v_base_cards
         or (select status from trpg_hq.hq_chronicle_honors
                where mission_id=v_success_mission and player_id=v_agent)<>'resolved'
         or (select count(*) from trpg_hq.hq_chronicle_honors
                where mission_id=v_mission and player_id=v_agent)<>0 then
          raise exception 'phase8_followup_failure_erased_or_mutated_prior_achievement';
       end if;
       if exists(select 1 from jsonb_array_elements(
            trpg_hq.load_chronicle_honors(v_team)) h(value)
          where h.value->>'ledger_consistent'<>'true') then
          raise exception 'phase8_load_honors_ledger_mismatch';
       end if;
       if jsonb_array_length(trpg_hq.load_chronicle_honors(v_team))
             <> v_base_medals+1 then
          raise exception 'phase8_honors_not_restored';
       end if;
       v_report:=jsonb_build_object(
        'permanent_player_same_uuid',v_agent,
        'first_certifications_before',1,
        'first_certifications_after',v_current_certs,
        'first_certification_mission_unchanged',true,
        'old_medals_before',v_base_medals,
        'total_medals_after_second_success',v_current_medals,
        'new_certifications_second_success',0,
        'special_second_chronicle','growth_POW_plus_one',
        'growth_after_special',v_current_growth,
        'second_special_duplicate_rejected',true,
        'third_chronicle_status','failed',
        'third_chronicle_new_medals',0,
        'old_card_award_unchanged',true,
        'past_honors_and_special_reward_preserved',true,
        'reconnected_honor_count',jsonb_array_length(trpg_hq.load_chronicle_honors(v_team)),
        'all_synthetic_changes_rolled_back',true);
     end if;
   end loop;
   raise exception 'HQ8_SUCCESS_ROLLBACK';
 exception when others then
   if sqlerrm<>'HQ8_SUCCESS_ROLLBACK' then raise;end if;
 end;
 if v_report is null then raise exception 'phase8_test_did_not_finish';end if;
 insert into pg_temp.hq_phase8_repeat_report(scenario,result)
 values('same_agent_second_success_then_third_failure',v_report);
end $t$;

select scenario,result from pg_temp.hq_phase8_repeat_report;