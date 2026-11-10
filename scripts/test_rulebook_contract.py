"""Reject consequential document regressions in an isolated copy; no game service."""
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
import importlib.util,json,shutil,tempfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('rulebook_check',ROOT/'scripts/rulebook.py')
checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker)

def change(root,path,old,new):
    p=root/path;s=p.read_text();assert old in s,(path,old);p.write_text(s.replace(old,new,1))

def move_priority_last(root):
    p=root/'PROJECT_INSTRUCTIONS.md';s=p.read_text()
    a=s.index('## 최우선 기준');b=s.index('## 진행 순서와 규칙 조회')
    p.write_text(s[:a]+s[b:]+'\n'+s[a:b])

def validate(root):
    checker.ROOT=root;checker.RULES=root/'rules'
    with redirect_stdout(StringIO()):checker.validate()

mutations=[
 ('card_scope_type_lost',lambda r:change(r,'rules/09-cards.md','자산(Asset) 33장','자산 32장')),
 ('card_asset_guardian_companion_missing',lambda r:change(r,'rules/09-cards.md','`[GU-A-3]`','`[GU-A-X]`')),
 ('card_asset_wildcard_companion_missing',lambda r:change(r,'rules/09-cards.md','`[WI-A-4]`','`[WI-A-X]`')),
 ('card_neutral_cargo_replaced',lambda r:change(r,'rules/09-cards.md','밀폐 운반통','접이식 관찰 거울')),
 ('card_survivor_death_ignored',lambda r:change(r,'rules/09-cards.md','HP 1이 남도록 1회 경감','HP 0으로 죽음을 확정')),
 ('card_growth_probability_changed',lambda r:change(r,'rules/09-cards.md','**80%**','**99%**')),
 ('card_slot_requirements_omitted',lambda r:change(r,'rules/09-cards.md','자산 전용1','자산 전용0')),
 ('card_bonus_double_dice',lambda r:change(r,'rules/09-cards.md','같은 판정에 함께 사용 불가','같은 판정에서 중첩 가능')),
 ('card_reward_current_class_removed',lambda r:change(r,'rules/09-cards.md','현재 클래스','다른 클래스')),
 ('card_rule_route_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','| 09-cards.md |','| 09-missing.md |')),
 ('start_loadout_expanded',lambda r:change(r,'rules/04-setup.md','직업 관련 필수 물품 정확히 1개','시작부터 장비 여러 개')),
 ('kit_counts_as_one',lambda r:change(r,'rules/04-setup.md','별개로 사용할 수 있는 여러 도구가 든 키트','키트 안의 무료 별도 도구 전부 지급')),
 ('starting_item_not_acquired_in_world',lambda r:change(r,'rules/04-setup.md','정상적인 획득','자동으로 지급')),
 ('specialty_selection_returns',lambda r:change(r,'rules/04-setup.md','전문 분야 A/B/C 선택과 별도 전문성 성장','전문 분야 A/B/C와 별도 전문성 성장')),
 ('roll_for_dramatic_arbitrariness',lambda r:change(r,'rules/02-checks.md','극적 연출만으로 판정을 만들지 않는다','극적 연출만으로 판정을 만든다')),
 ('luck_invents_legendary_clue',lambda r:change(r,'rules/02-checks.md','이전에 없던 전설적 단서·강력한 무기','우연으로 강력한 보상을 만든다')),
 ('early_exit_hazards_require_plot_optin',lambda r:change(r,'rules/04-setup.md','조사/의뢰/핵심 장소 방문에 동의해야만 모든 위험이 켜지고 초반 귀가에는 아무 원인도 닿지 않는 설계는 보완한다','모든 위험은 본편을 수락한 뒤에만 시작하고 초반 귀가는 무조건 안전하게 한다')),
 ('leaving_intent_spawns_attack',lambda r:change(r,'rules/04-setup.md','출발 의도 자체를 공격 스위치로 쓰지 않고','출발 의도 자체를 새 공격과 봉쇄의 스위치로 쓰고')),
 ('schedule_only_escape_design_passes',lambda r:change(r,'rules/04-setup.md','단순 운항 일정/요금만 두고 생존 위협이 없거나, 본편 수락/최종 의례에만 모든 위해를 모아 두면 이탈 설계는 미완료다','초기 이탈은 운항 일정과 요금만 정하면 설계 완료다')),
 ('escape_harm_warning_only',lambda r:change(r,'rules/04-setup.md','도달한 위해는 담당 판정 뒤 HP·SAN·부상·광기·소모·추격 지속·사망 가능성으로 실제 처리한다','탈출 중 도달한 위해는 경고만 출력하고 실제 피해는 적용하지 않는다')),
 ('escape_charges_flat_hp_san',lambda r:change(r,'rules/04-setup.md','대가는 실제 명중/노출/소모에서 발생하며 출구 통행료처럼 고정 HP/SAN을 차감하지 않는다','출구를 지날 때 누구나 고정 HP와 SAN을 차감한다')),
 ('failed_escape_returns_safe',lambda r:change(r,'rules/06-play.md','이탈 실패는 자동 안전 귀환이 아니며 현재 위치·부상/광기·손실·남은 수단/추격을 유지한다','이탈에 실패하면 피해와 추격을 없애고 안전 구역에 도착시킨다')),
 ('transport_booking_finishes_campaign',lambda r:change(r,'rules/06-play.md','떠나겠다는 의사·교통편 확보·한 구역 이동만으로 엔딩을 확정하지 않고','떠나겠다고 하거나 교통편을 확보하면 즉시 엔딩을 확정하고')),
 ('canon_omits_escape_survival_design',lambda r:change(r,'rules/07-state.md','운항 일정이나 ‘안전하면 철수’라는 결론만으로 이탈 설계를 대신하지 않는다','정본의 이탈 설계는 운항 일정과 안전하면 철수라는 결론만으로 대신한다')),
 ('uninjured_escape_forbidden',lambda r:change(r,'rules/04-setup.md','준비·협력·후속 위해 회피/차단에 성공해 무상처로 벗어날 가능성도 보존하며 피해를 입어야만 엔딩 자격을 주지 않는다','준비와 예방에 성공했어도 반드시 피해를 입어야 엔딩 자격을 준다')),
 ('horror_left_abstract_after_procedures',lambda r:change(r,'rules/04-setup.md','의식/장치의 발동·중지 절차만 상세하고 공포는 ‘기괴한 공간/무서운 존재’로 비어 있으면 해당 체험을 보완한다','의식과 장치의 절차가 상세하면 공포가 추상적이어도 설계 완료다')),
 ('all_horror_forced_guilt_symbolism',lambda r:change(r,'rules/04-setup.md','모든 형상을 죄책감/심리의 상징으로 만들거나 설정 해설을 들어야만 대응하게 하지 않는다','모든 공포를 PC의 죄책감 상징으로 만들고 설정 해설을 들은 뒤 대응하게 한다')),
 ('climax_payoff_only_in_recap',lambda r:change(r,'rules/04-setup.md','마지막에 회상/설명하는 것으로 완료하지 않는다','마지막에 회상/설명하는 것만으로 완료한다')),
 ('every_item_required_at_climax',lambda r:change(r,'rules/04-setup.md','모든 경험/인물/물품의 사용, 고정 보스전·새 퍼즐·필수 손실은 요구하지 않는다','모든 경험과 물품을 사용하고 고정 보스전과 필수 손실을 거쳐야 한다')),
 ('resume_triggers_scenario_redesign',lambda r:change(r,'rules/04-setup.md','기존 캠페인의 새 채팅 재개는 신규 생성이 아니며 이 보강을 이유로 저장된 정본·진행을 재설계하지 않는다','기존 캠페인도 새 채팅에서 재개할 때마다 이 기준으로 정본과 진행을 다시 설계한다')),
 ('shock_twist_required_to_pass',lambda r:change(r,'rules/04-setup.md','주요 동기를 더 복잡하게 만들거나 목표를 뒤집는 충격적 반전을 합격 조건으로 추가하지 않는다','복잡한 동기와 목표를 뒤집는 충격적 반전이 있어야 설계에 합격한다')),
 ('simple_prevention_rejected_for_climax',lambda r:change(r,'rules/04-setup.md','이미 시작된 난관에서 피해를 줄이거나 국지적 차단·생존/탈출에 성공하면 인정하고','예방이나 간단한 차단은 무효로 하고 반드시 마지막 난관을 거치게 하며')),
 ('truth_without_meaning_or_choice',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','원작의 핵심 진실은 겪은 현상/인물/물건의 의미와 목표·신뢰·위협·대응·결말에 실질적 차이를 만든다','핵심 진실은 결말 뒤 설명으로만 제공한다.')),
 ('truth_invented_after_discovery',lambda r:change(r,'rules/04-setup.md','핵심 진실은 앞서 겪을 현상·물건·인물 행동의 의미를 바꾸는 사전 원인으로 설계한다','진실은 발견 뒤 이전 사실에 맞춰 소급 발명한다')),
 ('central_cause_left_as_unknown',lambda r:change(r,'rules/04-setup.md','이번 사건의 의미와 결정적 선택을 떠받치는 내막은 ‘알 수 없는 힘’으로 비워 두지 않는다','이번 사건의 핵심 원인은 알 수 없는 힘으로만 둔다')),
 ('climax_replaced_by_work_report',lambda r:change(r,'rules/04-setup.md','작업 완료 보고나 더 강한 적의 등장만으로 절정을 대신하지 않는다','작업 완료 보고나 새 강적 등장만으로 절정을 완성한다')),
 ('early_success_undone_for_twist',lambda r:change(r,'rules/04-setup.md','반전을 보여주려고 해결을 취소하거나 성공 뒤 숨은 다음 적을 추가하지 않는다','반전을 보여주기 위해 초기 해결을 취소하고 다음 적을 추가한다')),
 ('discovery_only_adds_archive_tasks',lambda r:change(r,'rules/05-world.md','설명을 들은 뒤 다음 자료를 확인하는 과제로만 끝내지 않는다','새 사실은 항상 다음 자료를 확인하는 과제로 이어진다')),
 ('all_sources_same_cosmic_plot',lambda r:change(r,'rules/04-setup.md','모든 세계를 같은 음모/유물/우주적 재앙으로 번역하지 않는다','모든 세계에 같은 유물과 우주적 재앙을 추가한다')),
 ('victim_count_substitutes_depth',lambda r:change(r,'rules/04-setup.md','그 진실을 빼도 모든 경험/선택/결과가 같고 피해 대상 수·작업량·설명 분량만 늘면 서사 심화를 보완한다','주요 진실을 빼도 피해 대상 수와 작업량이 많으면 깊은 시나리오다')),
 ('cash_hidden_between_trades',lambda r:change(r,'rules/06-play.md','현금은 매 일반 HUD에 실제 통화/잔액을 표시한다','현금은 거래를 할 때만 표시한다')),
 ('unpaid_added_to_cash',lambda r:change(r,'rules/06-play.md','미지급 대금/외상은 현재 잔액에 더하지 않고','미지급 대금/외상은 현재 잔액에 즉시 더하고')),
 ('important_item_frees_inventory_slot',lambda r:change(r,'rules/06-play.md','메인/파우치 물품을 중요하다는 이유로 다시 나열하거나0칸으로 옮기지 않는다','중요한 메인/파우치 물품은 중요 물품으로 옮겨0칸 처리한다')),
 ('historical_save_marked_current',lambda r:change(r,'rules/06-play.md','과거 성공을 현재 저장으로 재표시하거나 UI 표시 때문에 저장을 실행하지 않는다','과거 저장 성공을 매번 현재 저장 성공으로 표시한다')),
 ('native_status_split_into_cards',lambda r:change(r,'rules/06-play.md','기본 레이아웃은 선택지 → 구분선 → 단일 상태 카드다','기본 레이아웃은 선택지 → 여러 개의 상태 카드다')),
 ('five_choices_always_required',lambda r:change(r,'rules/06-play.md','개수 고정이나 별도4번 직접 행동 안내는 없다','선택지는 항상5개를 채워야 한다')),
 ('vague_design_marked_complete',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','설계 완료는 ‘가능하다’는 설명이 아니라 정본의 실제 연결로 판단한다','가능성만 적으면 설계 완료다')),
 ('source_cause_only_background',lambda r:change(r,'rules/04-setup.md','원작의 깊은 원인/갈등 → 고유한 현상·공간·위협의 작동 → PC가 겪는 난관·관계/행동 선택','원작의 깊은 원인은 배경 설명으로만 둔다')),
 ('world_change_without_conditions',lambda r:change(r,'rules/04-setup.md','어떤 기존 상태/원인이 성립하면 어느 범위의 공간·접근·위해·사람/정보 전달이 달라지고 무엇은 유지되는지','키퍼가 필요할 때 모든 공간과 능력을 바꾸는지')),
 ('safety_after_generic_movement',lambda r:change(r,'rules/06-play.md','남은 위협의 접근이 끊기는 경로/목적지·차단/보호 상태','어느 구역이든 이동하기만 한 상태')),
 ('npc_relationship_never_changes_action',lambda r:change(r,'rules/05-world.md','어떤 실제 변화가 협력·역할 분담·갈등·이탈을 바꾸는지','관계와 실제 행동을 연결하지 않고')),
 ('possibilities_pass_compatibility',lambda r:change(r,'rules/04-setup.md','가능성만 적고 발동/억제·체험 접점·대응·실제 안전/종결이 비었으면 그 연결은 미완료다','모든 항목에 가능하다고 적으면 설계 완료다')),
 ('full_design_review_every_reply',lambda r:change(r,'rules/04-setup.md','매 응답 전수 검토·검토표 출력·추가 검수 모델/저장 호출은 만들지 않는다','매 응답 전체 설계를 재검토하고 검토표와 저장을 실행한다')),
 ('canon_headers_replace_actual_design',lambda r:change(r,'rules/07-state.md','필수 절의 제목/원인 요약만으로 완성하지 않는다','필수 절의 제목만 존재하면 정본 완성이다')),
 ('mandatory_boss_and_full_truth',lambda r:change(r,'rules/04-setup.md','근원 전체의 소멸·고정 보스전·모든 진상 규명은 공통 필수가 아니다','모든 캠페인은 근원 전체 소멸과 보스전과 전모 규명을 요구한다')),
 ('major_incident_not_inevitable',lambda r:change(r,'rules/04-setup.md','캠페인 전체의 모든 주요 재난·습격·변형·붕괴·확산은 PC가 발생 자체를 예방할 수 없는 사건으로 정본에 확정한다','첫 사건만 필연적이고 다른 주요 사건은 전부 예방 가능하다')),
 ('major_incident_cannot_reduce_harm',lambda r:change(r,'rules/04-setup.md','PC는 발생 후 피해·확산·구조·일부 적 격퇴·퇴로·생존을 바꾼다','PC의 행동과 무관하게 피해와 사망을 확정한다')),
 ('world_only_first_inevitable',lambda r:change(r,'rules/05-world.md','**모든 주요 사건의 독립적 발생**','**첫 도입 사건의 독립적 발생**')),
 ('ending_erases_all_incidents',lambda r:change(r,'rules/06-play.md','필연적 주요 사건의 발생 자체를 지우는 전면 구원 대신','모든 사건을 미리 막으면 세계 전체를 구할 수 있다')),
 ('canon_leaves_later_incidents_blank',lambda r:change(r,'rules/07-state.md','첫 사건만 있고 후속 사건이 비어 있으면 미완성이다','첫 사건만 있으면 후속 사건은 비워도 된다')),
 ('retired_keeper_footer_returns',lambda r:(r/'PROJECT_INSTRUCTIONS.md').write_text((r/'PROJECT_INSTRUCTIONS.md').read_text()+'\n#### 🎬 키퍼 4요소\n#### 1. 반복 표시\n')),
 ('rulebook_requires_keeper_footer',lambda r:change(r,'rules/06-play.md','키퍼 원칙·숙지 문구·준수 보고를 게임 응답에 반복 출력하지 않는다','매 응답의 마지막에 키퍼 원칙과 숙지 문구를 표시한다')),
 ('experience_replaced_by_proof',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','추리·미스터리는 대응과 선택을 바꾸는 요소다','모든 진행은 진상 입증을 위한 조사다')),
 ('generic_source_reskin',lambda r:change(r,'rules/04-setup.md','원작 이름·가면·지명·용어만 바꾸어도 같은 자료 수사로 진행되는 설계는 다시 구성한다','원작의 이름만 바꾸면 체험 설계가 완성된다')),
 ('situation_network_missing',lambda r:change(r,'rules/04-setup.md','당면 목적 → 세계의 변화와 직접 경험 → 행동/관계/수단 선택 → 실제 결과 → 달라진 상황과 다음 목적','증언 → 문서 → 대조 → 입증')),
 ('npc_only_information_desk',lambda r:change(r,'rules/05-world.md','증언자/기관 창구를 넘어 함께 움직이고 갈등/유머/도움/손실을 겪을 사람','자료 문의에만 답하는 기관 창구')),
 ('unlisted_future_frozen',lambda r:change(r,'rules/05-world.md','미래 사건표에 없는 일은 발생 불가라고 세계를 멈추지 않는다','미래 사건표에 없는 일은 절대 발생하지 않는다')),
 ('all_choices_investigation',lambda r:change(r,'rules/06-play.md','매번 자료 찾기/증언 묻기/재확인만 나열하지 않는다','모든 선택지를 자료 찾기와 증언 확인으로 구성한다')),
 ('proof_required_for_all_endings',lambda r:change(r,'rules/06-play.md','진상 입증·범인 신원 확정·모든 증거 수집은 일반 종결 필수가 아니다','모든 진상을 입증하고 모든 증거를 모아야 종결한다')),
 ('experience_save_only_clues',lambda r:change(r,'rules/07-state.md','단서 목록만으로 현재 경험을 대신하지 않으며','현재 경험은 단서 목록만으로 대체하며')),
 ('major_incident_growth',lambda r:change(r,'rules/02-checks.md','CHRONICLE(연대기)에서만','모든 규모에서')),
 ('growth_cap',lambda r:change(r,'rules/02-checks.md','상한은 95','상한은 100')),
 ('san_accumulation',lambda r:change(r,'rules/03-danger.md','회복은 누적 손실을 차감하지 않는다','회복은 손실을 지운다')),
 ('san_recovery',lambda r:change(r,'rules/03-danger.md','극중 하루 1회 SAN 1d3','매 응답 SAN 1d6')),
 ('drowning_scope',lambda r:change(r,'rules/03-danger.md','행동 구간마다 CON1회','채팅마다 CON1회')),
 ('opposed_digits',lambda r:change(r,'rules/02-checks.md','결합 결과 00은 100','결합 결과 00은 0')),
 ('inventory_hidden',lambda r:change(r,'rules/06-play.md','인벤토리 목록과 메인/파우치 점유량은 상시 유지','인벤토리는 표시하지 않음')),
 ('credits_optional',lambda r:change(r,'rules/06-play.md','기본 엔딩의 다섯','요청할 때만 제공하는 다섯')),
 ('scene_context_missing',lambda r:change(r,'rules/07-state.md','| scene_context | 현재 행동권/장소·직전행동과 반응·대화주제/마지막질문','| omitted_context | 현재 행동권/장소·직전행동과 반응·대화주제/마지막질문')),
 ('world_scale_weak',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','실행력·파급','장식')),
 ('npc_voice_forgotten',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','상대별 호칭','일반 대화')),
 ('routine_micro_gates',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','단순 확인마다 긴 대사·서류 전문·새 메뉴·입력 대기를 만들지 않는다','모든 확인에서 메뉴를 만들고 입력을 기다린다')),
 ('routine_new_consent',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','미선언 증언·동의는 만들지 않는다','통상 업무의 증언과 동의는 대신 결정한다')),
 ('routine_erases_important_scene',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','중요한 협상·발견·갈등은 직업 업무라는 이유로 축약하지 않는다','직업 업무의 협상과 갈등은 모두 생략한다')),
 ('threat_hud_only',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','살아 있는 위협을 HUD의 경고로만 남겨두지 않는다','위협은 HUD 경고로만 유지한다')),
 ('narrator_inference_coaching',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','지문·NPC 대사·HUD에 플레이어의 추리를 평가하는 검증 안내·면책 해설을 넣지 않는다','플레이어의 추리를 평가하고 추가 검증을 안내한다')),
 ('danger_only_at_finale',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','최종전만 위험하고 나머지는 무손실 조사인 구조를 피한다','최종전까지 모든 조사는 무위험으로 처리한다')),
 ('danger_waits_for_optin',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','플레이어가 위험한 선택지를 고를 때까지 기다리지 않는다','위험 선택지를 고를 때까지 위협을 중지한다')),
 ('san_deferred_to_finale',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN 규칙을 적용하고 전투나 절정까지 미루지 않는다','SAN 처리는 최종전에만 적용한다')),
 ('fixed_injury_quota',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','피해·희생·감염을 할당하지 않는다','매 장면 피해를 할당한다')),
 ('guess_missing_mechanics',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','본문이 없으면 결과 확정 전에 해당 절을 조회','본문이 없으면 일반 기억으로 처리')),
 ('keeper_principle_rewritten',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','세계·적·NPC·환경은 실제 목적·정보·수단·위치·조건으로 먼저 움직인다','플레이어의 대응과 무관하게 예정된 사건을 실행한다')),
 ('keeper_rule_application_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','준비·세계 생성·플레이·상태 관리·저장·복원·종결의 규칙은 아래 상황별 라우팅을 따른다.','')),
 ('core_player_agency_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','PC의 행동·대사·생각·감정·수락·추리 결론은 플레이어가 결정한다','PC의 행동과 감정을 키퍼가 결정한다')),
 ('rulebook_file_route_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','| 08-visual.md |','| 88-missing.md |')),
 ('rulebook_route_wrong_owner',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN_EXPOSURE_GATE / COMBAT_ORDER','HEALING / COMBAT_ORDER')),
 ('rulebook_route_unknown_id',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN_EXPOSURE_GATE / COMBAT_ORDER','UNKNOWN_EXPOSURE_RULE / COMBAT_ORDER')),
 ('source_world_immersion_lost',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','원작 안에 들어온 감각을 주며','원작 이름만 표시하며')),
 ('investigation_spiral',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','증거 완전성·세부 모순·추가 검증을 계속 요구하며 조사 단계를 늘이지 않는다','증거가 완벽해질 때까지 추가 조사를 계속 요구한다')),
 ('chosen_deep_inquiry_erased',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','핵심 난관과 플레이어가 선택한 심층 탐구는 보존한다','플레이어가 원해도 심층 탐구는 전부 생략한다')),
 ('presentation_overrides_priority',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','재미·속도를 위해 상위 기준을 뒤집지 않는다','재미를 위해 PC 주도권과 확정 결과를 바꾼다')),
 ('regenerate_existing_canon',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','신규 캠페인/미확정 챕터에 적용한다','기존 세계도 매 응답 다시 생성한다')),
 ('meta_advances_danger',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','메타 질문·재표시는 답만 제공하며 극중 시간·위험을 진행시키지 않는다','메타 질문마다 시간과 위협을 진행한다')),
 ('every_routine_is_important',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','생존·목표·수단·관계·진실 이해·이후 선택을 바꾸는 순간','모든 접수와 확인을 별도 장면으로')),
 ('lookup_failure_guessed_success',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','조회 실패 시 영향을 받는 처리만 보류하고 확인 가능한 진행은 계속한다','조회 실패 시 결과를 추측해 확정한다')),
 ('routine_without_decision_stops',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','이미 선언한 목적/발언의 통상 실행에 새 판단이 없으면','이미 선언한 통상 확인도 매번 멈춰')),
 ('priority_at_bottom',move_priority_last),
 ('choice_buttons_dropped',lambda r:change(r,'rules/06-play.md','실제 버튼/선택 UI를 제공하면','버튼 UI가 지원되어도')),
 ('fake_click_fallback',lambda r:change(r,'rules/06-play.md','작동하지 않는 HTML/가짜 링크로 클릭 기능을 가장하지 않으며','가짜 클릭 링크를 제공하며')),
 ('status_panel_flattened',lambda r:change(r,'rules/06-play.md','Markdown 상태 카드','상태 한 줄')),
 ('resource_icons_removed',lambda r:change(r,'rules/06-play.md','❤️ HP','HP')),
 ('bag_sections_merged',lambda r:change(r,'rules/06-play.md','각각 빈 줄로 나눈 독립 문단/별도 UI 영역에 표시한다','합쳐 한 문단에 표시한다')),
 ('inventory_rearranged_for_style',lambda r:change(r,'rules/06-play.md','기존 소지 위치·수량·점유량을 서식 때문에 재배치하거나 예시 값/새 물품으로 채우지 않는다','패널에 맞춰 물품의 위치와 수량을 바꾼다')),
 ('ui_instruction_reminder_removed',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','선택지·상태 패널·아이콘·메인/파우치 구분은06-play를 따른다','UI 서식은 자유다')),
 ('retired_fifth_reminder_returns',lambda r:(r/'PROJECT_INSTRUCTIONS.md').write_text((r/'PROJECT_INSTRUCTIONS.md').read_text()+'\n###### 5. 추가\n')),
 ('hud_body_shrunk',lambda r:change(r,'rules/06-play.md','HUD 본문 18px·자원 수치 24px','HUD 본문 10px·자원 수치 12px')),
 ('retired_router',lambda r:(r/'rules/01-core.md').write_text((r/'rules/01-core.md').read_text()+'\nNOTEBOOK_PUBLIC_PATCH\n')),
 ('notebook_shipped',lambda r:(r/'rules/09-notebook.md').write_text('# retired\n')),
 ('pi_too_long',lambda r:(r/'PROJECT_INSTRUCTIONS.md').write_text((r/'PROJECT_INSTRUCTIONS.md').read_text()+'가'*7801)),
 ('duplicate_rule',lambda r:(r/'rules/03-danger.md').write_text((r/'rules/03-danger.md').read_text()+'\n## SUCCESS_LEVELS\n\nDuplicate\n')),
 ('catalog_missing',lambda r:(r/'docs/RULE_CATALOG.md').write_text('# empty\n')),
 ('parent_inventory_missing',lambda r:(r/'docs/rule-reorganization.json').write_text(json.dumps(json.loads((r/'docs/rule-reorganization.json').read_text())[:-1]))),
 ('original_inventory_missing',lambda r:(r/'docs/rule-migration.json').write_text(json.dumps(json.loads((r/'docs/rule-migration.json').read_text())[:-1]))),
]
with tempfile.TemporaryDirectory() as tmp:
    baseline=Path(tmp)/'baseline';(baseline/'docs').mkdir(parents=True)
    shutil.copytree(ROOT/'rules',baseline/'rules')
    for name in ['PROJECT_INSTRUCTIONS.md','START_GAME.md']:shutil.copyfile(ROOT/name,baseline/name)
    for name in ['rule-migration.json','rule-reorganization.json','validation-contract.json','RULE_CATALOG.md']:
        shutil.copyfile(ROOT/'docs'/name,baseline/'docs'/name)
    validate(baseline)
    for name,mutate in mutations:
        target=Path(tmp)/name;shutil.copytree(baseline,target);mutate(target)
        try:validate(target)
        except (SystemExit,ValueError):pass
        else:raise AssertionError('invalid change accepted: '+name)
print(f'PASS: valid integrated documents; {len(mutations)} consequential regression mutations rejected; no live play tested')
