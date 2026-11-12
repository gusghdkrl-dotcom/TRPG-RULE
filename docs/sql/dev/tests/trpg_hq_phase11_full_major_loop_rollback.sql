-- DEV ONLY 11B full-cycle rollback:
-- first ON visit -> induction -> verified PC & loadout & canon -> Martin
-- briefing -> Jayden departure -> existing V2 verified ending -> return
-- +3d -> Martin evaluation/approval -> Dominic draft resolution ->
-- training certification -> free HQ and next ON visit from sync room.
create temporary table hq11_full_loop_test(k text,v jsonb) on commit drop;
do $test$
declare
 a jsonb;
 b jsonb;
 st jsonb;
 team uuid;
 agent uuid;
 rev bigint;
 mission uuid;
 segment uuid;
 canon_sha text;
 doc jsonb;
 body text;
 sha text;
 pool jsonb;
 offers jsonb;
 cur text;
 other text;
 growth text;
 neutral text;
 actual_event text:='dev11-final-completion';
 actual_time bigint;
 report jsonb;
begin
 begin
  a:=trpg_hq.begin_hq_on_visit('hq11-full-loop',
   array['HQ11_LOOP_A'],'hq11:entry1');
  team:=(a->>'team_id')::uuid;
  if a->>'route'<>'entrance' then raise exception 'first_loop_entry_not_entrance';end if;
  select agent_id into agent from trpg_hq.hq_team_members where team_id=team;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.record_hq_induction(team,'hq11:first-induction',
    rev,array[agent],'가상의 첫 입단식 참가, 미확정 대사나 개인 서약 저장 안 함',5);
  perform trpg_cards.open_campaign('hq11-loop-campaign','major','hq11-loop-session');
  perform trpg_cards.enroll_player('hq11-loop-campaign',agent,'guardian');
  perform trpg_cards.link_character_with_growth_mode(
    'hq11-loop-campaign',agent,'P1',
    '{"STR":50,"CON":50,"SIZ":50,"DEX":50,"APP":50,"INT":50,"POW":50,"EDU":50}'::jsonb,true);
  perform trpg_cards.save_loadout(
    'hq11-loop-campaign',agent,'start','GU-A-0','GU-E-0','NE-A-0','NE-E-0');
  insert into trpg_private.gm_canon_documents(
    campaign_id,canon_id,revision,filename,document_format,
    rules_version,content_md,file_sha256)
  select 'hq11-loop-campaign','hq11-test-canon',1,
    'HQ11_TEST_CANON.md',document_format,rules_version,content_md,file_sha256
  from trpg_private.gm_canon_documents
  where campaign_id='hq-dev-major-20261112' and canon_id='hq-dev-canon';
  select file_sha256 into canon_sha from trpg_private.gm_canon_documents
    where campaign_id='hq11-loop-campaign' and canon_id='hq11-test-canon';
  if canon_sha is null then raise exception 'canon_fixture_missing';end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  a:=trpg_hq.prepare_mission(team,'hq11-loop-campaign','major','unassessed',
    '[{"id":"dev11_critical","description":"가상 중심 임무","importance":"core"}]'::jsonb,
    '{"public_background":"synthetic only"}'::jsonb,'major:final',
    'hq11-loop-session',rev);
  mission:=(a->>'mission_id')::uuid;
  segment:=(a->>'segment_id')::uuid;
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'world_pc_equipment_and_martin_briefing' then
    raise exception 'world_or_briefing_gate_not_visible: %',st->>'next_checkpoint';
  end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  begin
    perform trpg_hq.depart_after_actual_briefing(segment,rev);
    raise exception 'dispatch_without_briefing_accepted';
  exception when others then
    if sqlerrm not like 'hq_field_departure_preflight_failed_%' then raise;end if;
  end;
  a:=trpg_hq.record_martin_formal_briefing(
    segment,'hq11-test-canon',1,
    '실제 테스트 정본·공개 가능한 위험도를 바탕으로 마틴의 가상 브리핑이 있었음',
    rev,6);
  if a->>'applied'<>'true' then raise exception 'briefing_not_saved';end if;
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'jayden_departure_on_player_choice' then
    raise exception 'verified_departure_gate_not_ready: %',st->>'next_checkpoint';
  end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  a:=trpg_hq.depart_after_actual_briefing(segment,rev);
  if a->>'route'<>'field_game' then raise exception 'field_launch_failed';end if;
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'resume_saved_field' then raise exception 'not_in_field';end if;

  select state_json::jsonb into doc from public.gm_checkpoint_history
   where session_id='hq-dev-field-session-20261112'
    and version=1 and status='verified';
  if doc is null then raise exception 'verified_template_missing';end if;
  doc:=jsonb_set(doc,'{campaign_id}',to_jsonb('hq11-loop-campaign'::text));
  doc:=jsonb_set(doc,'{session_id}',to_jsonb('hq11-loop-session'::text));
  doc:=jsonb_set(doc,'{canon_ref,campaign_id}',to_jsonb('hq11-loop-campaign'::text));
  doc:=jsonb_set(doc,'{canon_ref,canon_id}',to_jsonb('hq11-test-canon'::text));
  doc:=jsonb_set(doc,'{canon_ref,filename}',to_jsonb('HQ11_TEST_CANON.md'::text));
  doc:=jsonb_set(doc,'{canon_ref,file_sha256}',to_jsonb(canon_sha));
  doc:=jsonb_set(doc,'{runtime,hq,mission_id}',to_jsonb(mission::text));
  doc:=jsonb_set(doc,'{runtime,hq,segment_key}',to_jsonb('major:final'::text));
  doc:=jsonb_set(doc,'{pcs}',jsonb_build_object('P1',
    jsonb_build_object('player_id',agent::text,'alive',true)));
  doc:=jsonb_set(doc,'{runtime,ending_state}',jsonb_build_object(
    'scope','CAMPAIGN_TERMINAL','status','completed',
    'returning_agent_ids',jsonb_build_array(agent::text),
    'finalization_event_id',actual_event));
  doc:=jsonb_set(doc,'{checkpoint}',jsonb_build_object(
    'version',1,'event_id','hq11-loop-session:cp1',
    'attempt_id','hq11-attempt','parent_version',null,'parent_sha256',null));
  body:=doc::text;
  if public.trpg_v2_payload_issue(body) is not null then
    raise exception 'test_v2_payload_invalid: %',public.trpg_v2_payload_issue(body);end if;
  sha:=encode(sha256(convert_to(body,'UTF8')),'hex');
  perform public.trpg_v2_commit('hq11-loop-session',1,
    'hq11-loop-session:cp1','hq11-attempt',null,null,body,sha);
  perform public.trpg_v2_verify('hq11-loop-session',1,
    'hq11-loop-session:cp1','hq11-attempt',sha);
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.confirm_segment_terminal(segment,1,sha,rev);
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'verified_return_processing' then
    raise exception 'return_verified_route_missing';end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.return_segment(segment,rev);
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'martin_evaluation' then
    raise exception 'evaluation_not_next: %',st->>'next_checkpoint';end if;
  if (st->>'hq_elapsed_minutes')::bigint<>5+6+4320 then
    raise exception 'not_exactly_three_days_on_return';end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.evaluate_segment(segment,rev,'A',
    '[{"id":"dev11_critical","result":"achieved","reason":"DEV 가상 종결 평가"}]'::jsonb,
    '가상 임무 평가: 구조와 확인 성과', '{"fixture":true}'::jsonb);
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'martin_reward_eligibility_review' then
    raise exception 'post_evaluation_reward_gate_missing: %',st->>'next_checkpoint';end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.approve_general_reward(segment,agent,rev,
    'DEV11 마틴의 적격 보상 승인');
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'available_reward_choices' then
    raise exception 'dominic_reward_not_offered_for_choice';end if;
  pool:=trpg_cards.draft_pool('hq11-loop-campaign',agent);
  select x->>'id' into cur from jsonb_array_elements(pool->'current') x limit 1;
  select x->>'id' into other from jsonb_array_elements(pool->'all') x
   where x->>'id' is distinct from cur limit 1;
  select x->>'id' into growth from jsonb_array_elements(pool->'growth') x limit 1;
  select x->>'id' into neutral from jsonb_array_elements(pool->'neutral') x limit 1;
  offers:=jsonb_build_object('current',cur,'all',other,'growth',growth,'neutral',neutral);
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.offer_general_reward(segment,agent,rev,offers);
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.resolve_general_reward(segment,agent,rev,4::smallint,null::integer);
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'martin_training_certification' then
    raise exception 'training_followup_route_missing: %',st->>'next_checkpoint';end if;
  select revision into rev from trpg_hq.hq_teams where team_id=team;
  perform trpg_hq.certify_training(segment,agent,rev);
  st:=trpg_hq.hq_full_loop_next(team);
  if st->>'next_checkpoint'<>'hq_free_play_or_plan_mission' then
    raise exception 'HQ_free_after_reward_missing: %',st->>'next_checkpoint';end if;
  b:=trpg_hq.begin_hq_on_visit('hq11-full-loop',
    array['HQ11_LOOP_A'],'hq11:next-game');
  if b->>'route'<>'sync_room' then raise exception 'returning_game_route_bad';end if;
  report:=jsonb_build_object(
    'entry','entrance','induction','actually_recorded',
    'npc_structural_services',jsonb_array_length(st->'available_npc_structural_services'),
    'departure_without_verified_briefing_denied',true,
    'canon_field_PC_loadout_briefing_preflight',true,
    'jayden_departure',true,
    'field_checkpoint_verified',true,
    'return_elapsed_minutes',4320,
    'martin_evaluation',true,
    'martin_reward_approval',true,
    'dominic_actual_draft_resolved',true,
    'training_certification',true,
    'HQ_next_free_loop',true,
    'subsequent_new_ON_start','sync_room',
    'all_synthetic_changes_rolled_back',true);
  raise exception 'HQ11_FULL_LOOP_ROLLBACK_SUCCESS';
 exception when others then
   if sqlerrm<>'HQ11_FULL_LOOP_ROLLBACK_SUCCESS' then raise;end if;
 end;
 insert into pg_temp.hq11_full_loop_test(k,v) values('first_major_training_full_loop',report);
end $test$;
select k,v from pg_temp.hq11_full_loop_test;