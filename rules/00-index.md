# 규칙 색인

규칙판: 생존 호러 통합 경량판 2026-11-08. 상시 이야기·묘사·페이싱은 PROJECT_INSTRUCTIONS.md, 아래는 필요한 수치/상태/절차를 찾는 경로다. 같은 판본의 필요한 본문과 현재 상태가 확인 가능하면 재사용하고 유실/변경/충돌 부분만 조회한다. 매 응답 색인이나 전 규칙을 다시 읽지 않는다.

| 상황 | 담당 절 |
|---|---|
| 입력 의미·주도권·공개 범위 | [PLAYER_INPUT_NAMESPACE_ROUTER](01-core.md#player_input_namespace_router) · [CORE_AGENCY](01-core.md#core_agency) · [CORE_VISIBILITY](01-core.md#core_visibility) |
| 실제 난수·생성 분리 | [PYTHON_RANDOM_EXECUTION](01-core.md#python_random_execution) · [GENERATION_RNG_SEPARATION](04-setup.md#generation_rng_separation) |
| 일반 행동 판정·기능/난이도 | [FICTION_FIRST_ROLL_TRIGGER_GATE](02-checks.md#fiction_first_roll_trigger_gate) · [INVESTIGATION_SKILL_ROUTING](02-checks.md#investigation_skill_routing) · [DIFFICULTY_ASSIGNMENT](02-checks.md#difficulty_assignment) |
| 단계·유불리·대항 | [SUCCESS_LEVELS](02-checks.md#success_levels) · [BONUS_PENALTY_DICE](02-checks.md#bonus_penalty_dice) · [GENERIC_OPPOSED_ROLL](02-checks.md#generic_opposed_roll) |
| PC 굴림·행운·강행 | [ROLL_INPUT_FORM_CONTRACT](02-checks.md#roll_input_form_contract) · [LUCK_SPENDING](02-checks.md#luck_spending) · [PUSHED_ROLL](02-checks.md#pushed_roll) |
| HP·중상·치료·연대기 성장 | [HP_AND_DEATH](02-checks.md#hp_and_death) · [WOUNDS](02-checks.md#wounds) · [HEALING](02-checks.md#healing) · [SKILL_IMPROVEMENT](02-checks.md#skill_improvement) |
| SAN·광기·회복 | [SAN_EXPOSURE_GATE](03-danger.md#san_exposure_gate) · [SAN_ROLL](03-danger.md#san_roll) · [INSANITY_CONDITIONS](03-danger.md#insanity_conditions) · [DIEGETIC_SAN_RECOVERY](03-danger.md#diegetic_san_recovery) |
| 전투·총기·추격·위해 | [COMBAT_ORDER](03-danger.md#combat_order) · [MELEE_OPPOSED](03-danger.md#melee_opposed) · [FIREARMS](03-danger.md#firearms) · [CHASE](03-danger.md#chase) · [EXTREME_HAZARDS](03-danger.md#extreme_hazards) |
| 신규 시작·원작·PC | [START_SETTINGS_GATE](04-setup.md#start_settings_gate) · [CAMPAIGN_SETUP_PIPELINE](04-setup.md#campaign_setup_pipeline) · [HOMAGE_DRAFT_SELECTION](04-setup.md#homage_draft_selection) · [STAT_DRAFT_GENERATION](04-setup.md#stat_draft_generation) · [PROFESSION_DRAFT](04-setup.md#profession_draft) |
| 원작 체험·상황망/변화 조건·큰 사건·최종 대응/탈출·설계 완료 대조 | [FULL_DIVE_CROSS_ANALYSIS](04-setup.md#full_dive_cross_analysis) · [STORY_SCALE](04-setup.md#story_scale) · [SCENARIO_BLUEPRINT](04-setup.md#scenario_blueprint) · [FINAL_THREAT_DESIGN](04-setup.md#final_threat_design) · [COMPATIBILITY_GATE](04-setup.md#compatibility_gate) |
| 탐구·원문·가설 | [CLUE_FUNCTION](05-world.md#clue_function) · [IN_WORLD_DOCUMENT_HANDOUT](05-world.md#in_world_document_handout) · [HYPOTHESIS_TEST](05-world.md#hypothesis_test) |
| NPC 목적·선제 행동·말투·관계 | [NPC_AGENDA_AND_SECRECY](05-world.md#npc_agenda_and_secrecy) · [NPC_AGENDA_INTERVENTION](05-world.md#npc_agenda_intervention) · [NPC_INTERACTION_VOICE_COMPACT](05-world.md#npc_interaction_voice_compact) · [RELATIONSHIP_AND_NPC_MEMORY](05-world.md#relationship_and_npc_memory) |
| 물품·현금·준비/선택의 후속 인과 | [INVENTORY](05-world.md#inventory) · [PERSONAL_CASH_LEDGER](05-world.md#personal_cash_ledger) · [BUTTERFLY_AND_LIVING_WORLD](05-world.md#butterfly_and_living_world) |
| 화면 밖 진행·도달한 위험 | [WORLD_INITIATIVE_EXECUTION](05-world.md#world_initiative_execution) · [REACHED_DANGER_EXECUTION_GATE](05-world.md#reached_danger_execution_gate) |
| 시간·이동·교대·동시 진행 | [SCENE_ELAPSED_TIME_SETTLEMENT](06-play.md#scene_elapsed_time_settlement) · [ROUTINE_MOVEMENT_FAST_PATH](06-play.md#routine_movement_fast_path) · [MULTI_PC_SPOTLIGHT_CONTRACT](06-play.md#multi_pc_spotlight_contract) · [PARALLEL_TIMELINE_SYNC](06-play.md#parallel_timeline_sync) |
| 압축·대화 응답·행동 안내·HUD | [CINEMATIC_ELLIPSIS](06-play.md#cinematic_ellipsis) · [NPC_REPLY_AGENCY_GATE](06-play.md#npc_reply_agency_gate) · [GUIDED_ACTION_RETURN](06-play.md#guided_action_return) · [BOTTOM_HUD_CONTRACT](06-play.md#bottom_hud_contract) |
| 실제 종결·다섯 엔딩 후 출력 | [ENDING_FINALIZATION_GATE](06-play.md#ending_finalization_gate) · [OPTIONAL_POST_CREDITS_VIEWS](06-play.md#optional_post_credits_views) |
| 필요한 정본·현재 맥락·DB 접근 | [PRIVATE_CANON_ACCESS_ROUTER](07-state.md#private_canon_access_router) · [STATE_WORKING_CONTEXT](07-state.md#state_working_context) · [STATE_EXPERIENCE_CONTINUITY](07-state.md#state_experience_continuity) · [STATE_ACCESS_ROUTER](07-state.md#state_access_router) |
| 저장·정합성·복구·새채팅 재개 | [STATE_CADENCE](07-state.md#state_cadence) · [STATE_COMMIT](07-state.md#state_commit) · [STATE_INTEGRITY](07-state.md#state_integrity) · [STATE_RESUME](07-state.md#state_resume) · [STATE_COMPATIBILITY](07-state.md#state_compatibility) |
| 지도·프로필·장면/참고 이미지 | [MAP_RUNTIME_INTERACTION](08-visual.md#map_runtime_interaction) · [EVENT_DRIVEN_VISUAL_ROUTER](08-visual.md#event_driven_visual_router) · [WEB_VISUAL_REFERENCE](08-visual.md#web_visual_reference) |

사실 정본은 해당 캠페인의 정확한 문서 판본+현재 누적 상태다. 룰북의 일반 예시를 실제 NPC·단서·수치로 복사하지 않는다. ID/enum은 연결 식별자이며 실제 지원되지 않는 도구·입력·저장 기능을 만들지 않는다.
