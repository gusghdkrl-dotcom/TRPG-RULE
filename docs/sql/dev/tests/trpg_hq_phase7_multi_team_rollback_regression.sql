-- DEV-ONLY ROLLBACK REGRESSION: all generated team/agent/canon/checkpoint
-- data is intentionally rolled back. No real game rewards are generated.
create temporary table hq_phase7_test_results(
 scenario text not null, result jsonb not null
) on commit drop;

do $test$
declare
  cs record;
  v_ids uuid[];
  v_id uuid;
  v_j integer;
  v_ch integer;
  v_team uuid;
  v_mission uuid;
  v_segment uuid;
  v_session text;
  v_campaign text;
  v_rev bigint;
  v_canon_hash text;
  v_checkpoint jsonb;
  v_pcs jsonb;
  v_return uuid[];
  v_scope text;
  v_status text;
  v_json text;
  v_sha text;
  v_previous_sha text;
  v_result jsonb;
  v_approval jsonb;
  v_problem text;
  v_medals integer;
  v_certificates integer;
  v_general integer;
  v_replay jsonb;
  v_report jsonb;
  v_payouts integer;
begin
 for cs in select * from (values
   ('two_survive',2,'success'),
   ('three_survive',3,'success'),
   ('two_one_dead',2,'death'),
   ('three_missing',3,'missing'),
   ('three_failed',3,'failed')
 ) c(scenario,participants,outcome)
 loop
  v_report:=null;
  begin
    v_ids:='{}'::uuid[];
    for v_j in 1..cs.participants loop
      v_id:=(trpg_cards.register_player(
        'HQ7_'||cs.scenario||'_'||v_j)->>'player_id')::uuid;
      v_ids:=array_append(v_ids,v_id);
    end loop;
    v_team:=(trpg_hq.create_team('hq7-'||cs.scenario,v_ids)->>'team_id')::uuid;
    -- Development fixture only: emulate already verified training state.
    update trpg_hq.hq_agents set qualification='training_qualified',
       training_completed=true where agent_id=any(v_ids);
    v_campaign:='hq7-'||cs.scenario;
    v_session:='hq7-session-'||cs.scenario;
    perform trpg_cards.open_campaign(v_campaign,'chronicle',v_session);
    for v_j in 1..cs.participants loop
      perform trpg_cards.enroll_player(v_campaign,v_ids[v_j],
        case when v_j=1 then 'guardian'
          when v_j=2 then 'rogue' else 'seeker' end);
    end loop;
    insert into trpg_private.gm_canon_documents(campaign_id,canon_id,
      revision,filename,document_format,rules_version,content_md,file_sha256)
    select v_campaign,'hq7-canon',1,'PRIVATE_CANON_HQ7.md',
      document_format,rules_version,content_md,file_sha256
    from trpg_private.gm_canon_documents
    where campaign_id='hq-dev-chronicle-20261112'
      and canon_id='hq-dev-chronicle-canon' and revision=1;
    select file_sha256 into v_canon_hash
    from trpg_private.gm_canon_documents
    where campaign_id=v_campaign and canon_id='hq7-canon';
    if v_canon_hash is null then
      raise exception 'fixture_canon_copy_failed';
    end if;
    v_result:=trpg_hq.prepare_mission(v_team,v_campaign,'chronicle','I',
      '[{"id":"dev-proof","description":"가상 연대기 대응 테스트","importance":"core"}]'::jsonb,
      '{"synthetic_fixture":true}'::jsonb,
      'chapter:01',v_session,0);
    v_mission:=(v_result->>'mission_id')::uuid;
    v_segment:=(v_result->>'segment_id')::uuid;
    v_previous_sha:=null;

    for v_ch in 1..2 loop
      if v_ch=2 then
        select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
        v_result:=trpg_hq.prepare_next_chapter(v_mission,
          'chapter:02',v_session,v_rev);
        v_segment:=(v_result->>'segment_id')::uuid;
      end if;
      select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
      perform trpg_hq.start_segment(v_segment,v_rev);

      select state_json::jsonb into v_checkpoint
      from public.gm_checkpoint_history
      where session_id='hq-dev-chronicle-session-20261112'
         and version=v_ch and status='verified';
      if v_checkpoint is null then raise exception 'fixture_template_missing';end if;
      v_pcs:='{}'::jsonb;
      for v_j in 1..cs.participants loop
        v_pcs:=v_pcs||jsonb_build_object('P'||v_j,
          jsonb_build_object('player_id',v_ids[v_j]::text,
            'alive',not(cs.outcome='death' and v_ch=2 and v_j=2)));
      end loop;
      v_return:=v_ids;
      if v_ch=2 and cs.outcome in ('death','missing') then
        v_return:=array_remove(v_return,v_ids[2]);
      end if;
      v_scope:=case when v_ch=1 then 'CHAPTER_TERMINAL'
        else 'CHRONICLE_TERMINAL' end;
      v_status:=case when v_ch=2 and cs.outcome in ('death','failed')
        then 'failed' else 'completed' end;

      v_checkpoint:=jsonb_set(v_checkpoint,'{campaign_id}',to_jsonb(v_campaign));
      v_checkpoint:=jsonb_set(v_checkpoint,'{session_id}',to_jsonb(v_session));
      v_checkpoint:=jsonb_set(v_checkpoint,'{canon_ref,campaign_id}',to_jsonb(v_campaign));
      v_checkpoint:=jsonb_set(v_checkpoint,'{canon_ref,canon_id}',to_jsonb('hq7-canon'::text));
      v_checkpoint:=jsonb_set(v_checkpoint,'{canon_ref,filename}',to_jsonb('PRIVATE_CANON_HQ7.md'::text));
      v_checkpoint:=jsonb_set(v_checkpoint,'{canon_ref,file_sha256}',to_jsonb(v_canon_hash));
      v_checkpoint:=jsonb_set(v_checkpoint,'{runtime,hq,mission_id}',to_jsonb(v_mission::text));
      v_checkpoint:=jsonb_set(v_checkpoint,'{runtime,hq,segment_key}',
        to_jsonb('chapter:0'||v_ch::text));
      v_checkpoint:=jsonb_set(v_checkpoint,'{pcs}',v_pcs);
      v_checkpoint:=jsonb_set(v_checkpoint,'{runtime,ending_state}',
        jsonb_build_object('scope',v_scope,'status',v_status,
          'returning_agent_ids',to_jsonb(v_return),
          'finalization_event_id',v_campaign||'-terminal-'||v_ch));
      v_checkpoint:=jsonb_set(v_checkpoint,'{checkpoint}',jsonb_build_object(
        'version',v_ch,'event_id',v_session||':cp'||v_ch,
        'attempt_id','attempt-'||v_ch,
        'parent_version',case when v_ch=1 then null else 1 end,
        'parent_sha256',v_previous_sha));
      v_json:=v_checkpoint::text;
      v_problem:=public.trpg_v2_payload_issue(v_json);
      if v_problem is not null then
        raise exception 'fixture_invalid_%: %',cs.scenario,v_problem;
      end if;
      v_sha:=encode(sha256(convert_to(v_json,'UTF8')),'hex');
      perform public.trpg_v2_commit(
        v_session,v_ch,v_session||':cp'||v_ch,'attempt-'||v_ch,
        case when v_ch=1 then null else 1 end,v_previous_sha,v_json,v_sha);
      perform public.trpg_v2_verify(
        v_session,v_ch,v_session||':cp'||v_ch,'attempt-'||v_ch,v_sha);
      select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
      perform trpg_hq.confirm_segment_terminal(v_segment,v_ch,v_sha,v_rev);
      select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
      perform trpg_hq.return_segment(v_segment,v_rev);
      select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
      perform trpg_hq.evaluate_segment(v_segment,v_rev,'B',
        '[{"id":"dev-proof","result":"achieved","reason":"롤백형 가상 검증"}]'::jsonb,
        'DEV7 가상 다인 연대기 마틴 평가',
        jsonb_build_object('synthetic',true,'scenario',cs.scenario));
      v_previous_sha:=v_sha;
      if v_ch=1 and cs.outcome in ('death','missing','failed') then
        select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
        perform trpg_hq.approve_general_reward(v_segment,v_ids[1],
          v_rev,'DEV7 첫 장 완료에 대한 독립 일반 보상');
      end if;
    end loop;

    select revision into v_rev from trpg_hq.hq_teams where team_id=v_team;
    if cs.outcome='success' then
      v_approval:=trpg_hq.approve_chronicle_completion(
         v_segment,v_rev,'DEV7 전원 생존·귀환 검증 후 최초 정식 인증');
      if v_approval->>'applied'<>'true'
       or (v_approval->>'medals')::integer<>cs.participants
       or (v_approval->>'new_full_certifications')::integer<>cs.participants then
        raise exception 'fixture_success_expected_%: %',cs.scenario,v_approval;
      end if;
      select count(*) into v_medals from trpg_hq.hq_chronicle_honors
        where mission_id=v_mission;
      select count(*) into v_certificates
        from trpg_hq.hq_agent_full_certifications
        where first_mission_id=v_mission;
      if v_medals<>cs.participants or v_certificates<>cs.participants then
        raise exception 'fixture_medals_or_certificates_mismatch';
      end if;
      v_replay:=trpg_hq.approve_chronicle_completion(
        v_segment,v_rev,'DEV7 전원 생존·귀환 검증 후 최초 정식 인증');
      if v_replay->>'applied'<>'false' then
        raise exception 'fixture_duplicate_completion_granted';
      end if;
    else
      begin
        perform trpg_hq.approve_chronicle_completion(
          v_segment,v_rev,'DEV7 실패를 완료로 위장한 승인');
        raise exception 'fixture_failure_incorrectly_certified_%',cs.scenario;
      exception when others then
        if sqlerrm is distinct from (case when cs.outcome='missing'
          then 'hq_chronicle_not_all_qualified_agents_survived_and_returned'
          else 'hq_chronicle_not_verified_completed_and_evaluated' end) then
          raise;
        end if;
      end;
      select count(*) into v_medals from trpg_hq.hq_chronicle_honors
        where mission_id=v_mission;
      select count(*) into v_certificates
        from trpg_hq.hq_agent_full_certifications
        where first_mission_id=v_mission;
      if v_medals<>0 or v_certificates<>0 then
        raise exception 'fixture_failure_unearned_medal';
      end if;
      select count(*) into v_general from trpg_hq.hq_reward_grants
       where campaign_id=v_campaign and event_key='chapter:01' and status='approved';
      if v_general<>1 then
        raise exception 'fixture_prior_chapter_approved_reward_deleted';
      end if;
    end if;
    select count(*) into v_payouts
      from trpg_hq.hq_chronicle_honors where mission_id=v_mission
        and status='resolved';
    v_report:=jsonb_build_object(
      'participants',cs.participants,
      'outcome',cs.outcome,
      'medals',v_medals,
      'first_certificates',v_certificates,
      'chapter1_general_reward_preserved',
        case when cs.outcome='success' then null else v_general=1 end,
      'automatic_special_payouts',v_payouts,
      'all_synthetic_changes_rolled_back',true);
    raise exception 'DEV7_ROLLBACK_COMPLETED';
  exception when others then
    if sqlerrm<>'DEV7_ROLLBACK_COMPLETED' then
      raise exception 'DEV7 scenario % failed: %',cs.scenario,sqlerrm;
    end if;
  end;
  insert into pg_temp.hq_phase7_test_results(scenario,result)
    values(cs.scenario,v_report);
 end loop;
end $test$;
select scenario,result from pg_temp.hq_phase7_test_results order by scenario;