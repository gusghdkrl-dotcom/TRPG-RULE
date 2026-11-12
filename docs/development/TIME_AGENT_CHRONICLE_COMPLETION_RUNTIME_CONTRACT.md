# 시간요원 본부 — 첫 연대기 전체 완주·정식 인증·훈장/특별 보상 실행 계약

> **개발 전용**: GitHub `dev/time-agent-hq` / Supabase `trpg-time-agent-dev` (`tvrfuljncwefbioasxgo`). 운영 `main` / `trpg-state-v2`에 적용하지 않았다.
> 원 설계: `TIME_AGENT_CONCEPT_DRAFT.md` §§18.1–18.2, 19.1–19.3, 29–30. 개발 검증용 가상 캠페인/캐릭터/세이브를 사용했으며 실제 원작 세계 결과가 아니다.

## 구현 파일

1. `docs/sql/dev/trpg_hq_phase6a_chronicle_completion_and_medals.sql`: `hq_chronicle_completions`, `hq_agent_full_certifications`, `hq_chronicle_honors`; `approve_chronicle_completion`, `load_chronicle_honors`.
2. `docs/sql/dev/trpg_hq_phase6b_chronicle_special_choice.sql`: `chronicle_special_options`, `resolve_chronicle_special`.
3. `docs/sql/dev/trpg_hq_phase6c_chronicle_award_integrity.sql`: 완주 승인/첫 정식 인증의 불변 원장·훈장 단 한 번 선택의 무결성 트리거.
4. 세 파일 모두 개발 Supabase의 실제 **마이그레이션 설치 성공** 후 RPC와 카드/성장 원장 재조회를 수행함.

## 플레이 경험/권한 구분

- **현지 연대기 전체 완주** → 기존 `verified` 체크포인트와 세션 최신 버전, 본부로 귀환한 각 챕터의 성공·평가 결과 확인 → 마틴의 실제 평가를 설명하면서 정식 자격 인정 → 영구 훈장과 독립적인 특별 A/B 1택 자격.
- **훈련 완료는 정식 시간요원이 아님.** 첫 연대기 전체 완주에서만 `training_qualified` → `full_agent` 전환하고 `hq_agent_full_certifications`에 영구 첫 인증 1건 저장. 추후 새로운 연대기를 완주해도 새 훈장은 받을 수 있지만 '첫 정식 인증'을 재발급하지 않고 임의 승진 점수도 주지 않는다.
- **훈장**은 원래 한 연대기 완료 `mission_id × 영구 player UUID`마다 1개. 훈장은 영구 서사·공적으로 별도 수치 효과 없음. 최종 챕터 기존 **일반 보상**의 `campaign_id + chapter:<ID> + player_id` 식별자·발행 흐름을 건드리지 않는다.
- **특별 보상 A**: 본래 66장 중 `common/rare/epic`의 `미보유` 1장 **실제 ID**를 플레이어가 직접 선택. 전설(`legendary`) 금지, 후보 무작위/드래프트 없음. 다른 클래스 카드도 소유할 수 있으나 장착은 기존 주 클래스/4슬롯 규칙 그대로다.
- **특별 보상 B**: 실제 8종 `STR/CON/SIZ/DEX/APP/INT/POW/EDU` 중 현재 `Lv < 5` 1개를 플레이어가 선택해 **확률 판정 없이 정확히 +1**. 신규 성장 row는 Lv.1. 이미 해당 종류 Lv.5면 선택 거부. 이미 연결된 현지 PC의 능력치를 소급 변경하지 않는다.
- **A/B는 둘 중 하나만 선택**. 두 번째 선택, 기존 선택 취소/재선택, 같은 선택 중복 지급 모두 차단. 정상 재조회/중복 재요청은 `applied:false`. 보상 미선택 상태는 `awaiting_choice`로 계속 보존한다.
- **모든 카드·성장이 한도에 도달한 경우**: 원 설계에서 대체 처리 미확정. 후보가 없는 상태를 드러내되 임의 보상·환불·전설 카드/추가 성장 등을 만들지 않는다. 정식 자격과 이미 획득한 훈장을 취소하지 않고 특별 선택권만 보류한다.
- **등급·진급 점수**: 현지 마틴 챕터 평가 S/A/B/C/F와 첫 정식 인증은 분리. 이 단계에서 제안 계급 명칭·임의 +3/+2/1 점수, 6/15/27점 컷, 자동 선임 승진은 도입하지 않는다.

## 검증 계약

`trpg_hq.approve_chronicle_completion(final_segment_id,expected_revision,martin_assessment)`은 같은 팀을 잠그고 다음이 모두 실제 DB에 존재하는지 확인한다.

1. 해당 캠페인은 `chronicle`; 최종 구간은 실제 `returned` + `terminal_status=completed` + `terminal_scope=CHRONICLE_TERMINAL`.
2. 해당 최종 챕터 및 앞선 모든 준비된 구간은 검증된 체크포인트로 반환·평가를 완료. 앞 구간은 `CHAPTER_TERMINAL`; 같은 세션/세계, 앞선 체크포인트 버전은 최종보다 작음. 실패/미귀환/미평가 구간이 있으면 인증 거부.
3. 각 구간의 체크포인트 원문 SHA와 저장된 종료 결과가 맞고 최종 구간은 해당 세션의 **최신 verified** 버전.
4. 최종 checkpoint의 `campaign_id`/`mission_id`/`ending_state`가 해당 임무와 일치.
5. 기존 카드 캠페인에 실제 등록된 팀원의 UUID 목록과 최종 귀환 UUID 목록이 **정확히 일치**. 이전 챕터도 동일 귀환 집합. `pcs`에 각 요원의 실제 `player_id`/생존 `alive=true`가 정확히 한 번 나타나고 인원 수가 동일.
6. 모든 참가자 `hq_agents.training_completed=true` 및 실제 연대기 참가 자격 유지.
7. `p_martin_assessment`는 키퍼가 실제 성과에 근거해 제공하는 문장. 임의로 플레이어의 감정이나 서약·대사·명령 수락을 생성하는 필드가 아니다.

검증이 통과하면 한 DB 트랜잭션에서 완료/훈장/첫 정식 인증/본부 이벤트를 기록한다. 중간 오류 시 전체 취소. 새 챕터 일반 보상 지급 단계는 여기에 포함되지 않는다.

`trpg_hq.chronicle_special_options(mission_id,player_id)`는 DB의 실소유 카드와 실제 성장 레벨을 읽어 적격 선택 대상만 돌려준다. `trpg_hq.resolve_chronicle_special(mission_id,player_id,expected_revision,'card'|'growth',card_id|stat)`은 한 선택의 **원자적** 카드 보유/성장 반영→완주 보상 상태→본부 지급 사건을 처리한다. 같은 팀의 revision 충돌은 다시 상태를 읽은 뒤 사용자 원래 선택을 보존해 처리해야 한다.

`load_chronicle_honors(team_id)`는 **권한 있는 키퍼 서버 내부**에서 훈장/선택 상태를 재독하며 원래 카드 보유 `acquisition_event`, 기존 성장 레벨과 원장 정합 여부를 표시한다. 직접 플레이어 UI에 전체 개인 이벤트/비밀을 투사하지 않는다. 일반 `anon`/`authenticated` 직접 RPC·테이블 접근 금지.

## 9차 다인 혼합 A/B와 일반 수령 실원장 합동 회귀

- 2인/3인 팀 모두 V2 verified 2장 연대기 성공·본부 귀환·마틴 평가를 거쳐 각자 `chronicle_special_options` → `resolve_chronicle_special` (A 직접 카드 또는 B 확정 성장) 처리.
- 각 요원의 최종 보통 챕터도 `approve_general_reward` → `offer_general_reward` → `resolve_general_reward`까지 실행해 원래 `trpg_cards.drafts.status=resolved` 및 카드 소유/성장 증가 확인. 특별/일반 양쪽 `load_*_rewards/honors` 정합, 중복 지급 없음.
- 후속 verified 실패 임무에서는 새 훈장/완주 보상을 주지 않고 앞선 **실제 지급 완료 `resolved` 일반 보상 및 특별 A/B·훈장·영구 자격** 보존.
- 보상 개인 이벤트의 `audience`는 자기 요원 1명뿐; 보상 처리가 개인 NPC 관계·클라라 대화를 멋대로 생성하지 않음.
- 테스트는 적격 `draft_pool` 고정 후보에 의한 보상 경로 검사이지 실제 Python SystemRandom 희귀도 추첨 검증이 아님. SQL 2개 `docs/sql/dev/tests/trpg_hq_phase9_*_rollback.sql`; 상세 `TIME_AGENT_MULTIPLAYER_REWARDS_REGRESSION.md`.
- 열린 일반 후보가 다른 경로에서 소유되면 원래 카드 엔진에서는 같은 카드 중복 수령 거부/다른 슬롯 수령 가능하지만 **HQ 특별 A를 통한 순서 충돌은 다음 단계**로 남음.

## 8차 동일 정식 요원 후속 연대기 실제 검증

- 이미 첫 완주에서 인증된 동일 `player_id`·팀으로 별도 연대기 2장 verified 완료. `approve_chronicle_completion` 결과는 새 훈장1, 새로운 최초 정식 인증0. 원래 `hq_agent_full_certifications.first_mission_id`와 발급 시각 영구 보존.
- 새 훈장에 특별 B 성장 POW +1을 실제 지급한 뒤 중복 요청 `applied:false`, 다른 A 선택 재시도 거부. 처음 받았던 특별 A `RO-A-3` 카드/소유·획득 이벤트는 변경 없음.
- 세 번째 연대기 verified 최종 실패 후에는 신규 훈장/인증/보상0. 이전 정식 인증·2개 훈장·과거 특별 카드·성장 레벨과 `load_chronicle_honors`의 원장 정합 유지.
- 반복 경로 검증은 `docs/sql/dev/tests/trpg_hq_phase8_repeat_chronicle_rollback.sql`에서 실DB 수행 후 전체 **롤백**. 새 함수 마이그레이션 없이 6a/6b/6c/7a/7b 기존 계약이 충족함을 확인. 보고서 `TIME_AGENT_REPEAT_CHRONICLE_REGRESSION.md`.
- 아직 미검증: 다인 각자 A/B 선택 및 일반 챕터 `resolved` 보상, 다팀 동시 요청, 실제 현지 PC HP/사망 확정, 최종 사용자 UI 연결.

## 7차 다인 연대기 실행 경계

- phase7a_immediate_chapter_failure: 1장 등 중간 verified CHAPTER_TERMINAL failed에서도 전체 작전 상태를 즉시 failed로 확정. 다음 챕터 출격/상태 부활 거부. 기존 합법적 구조/생존과 앞선 보상 원장은 유지.
- phase7b_chronicle_terminal_roster_consistency: verified checkpoint의 모든 등록 PC UUID 및 살아 있음 boolean을 확인. 사망한 PC가 귀환하거나 사망자·미귀환자를 두고 마지막 CHRONICLE_TERMINAL completed로 선언하면 원문 수정 없이 본부 종료 확인 거부. 최종 완주 인증은 전원 생존·귀환.
- dev/tests/trpg_hq_phase7_multi_team_rollback_regression.sql의 9개 합성 시나리오가 설치된 트리거와 기존 V2 commit/verify/본부 RPC에서 통과. 테스트 임시 요원/보상은 롤백.
- 실제 게임의 HP·사망 직전 생존 특성·전설 강화가 최종 사망 여부를 확정하는 원본 절차는 이 테스트의 alive 플래그 대체 입력과 구별. 2번째 완주/특별 A/B 다인 선택/운영 이식은 별도 미구현.

## 개발 DB에서 실제 수행한 테스트 (2026-11-12)

- 구판 시뮬레이션에 남아 있던 **훈련 미완료 요원의 가상 연대기**는 완주 기록이 존재하더라도 정식 인증 거부. 대사건 최종 구간을 연대기 완주로 위장해 승인 시도도 거부. 사전 생성된 완주·훈장·인증 원장 0건 유지.
- **실제 훈련 완료 이력이 있는 테스트 요원**을 사용해 별도 합성 연대기 `hq-dev-qualified-chronicle`의 1장·2장 생성/시작→원래 V2 `trpg_v2_commit/verify`→현지 종료 확인/귀환(`+4320`분 매 장)→마틴 등급 B/A 평가를 실행. 기존 테스트 정본과 마찬가지로 이 데이터는 원작 이야기가 아니라 **개발 테스트 픽스처**.
- 최종 2장 `CHRONICLE_TERMINAL` 성공 후 **정식 인증 1건 + 훈장 1건 + 미선택 특별 보상 1건** 실제 생성. 같은 완료 승인 재요청은 `applied:false`; 두 번 지급 안 됨.
- 특별 보상 적격 조회: 당시 **미보유 일반/희귀/영웅 카드 37종·성장 가능 8종** 표시.
- B `POW` 0→1 성장 +1 **실제 함수 실행과 성장 DB 읽기 검증**. 해당 테스트는 **성공 검증 후 서브트랜잭션 롤백**으로 원복했다. 확률 판정/난수 0회; 대사건/시트 변경 없음.
- A 전설 `GU-A-4`, 이미 보유한 `GU-A-0`, 잘못된 성장 `FOO`, 낡은 revision 선택 거부. A `RO-A-3`(원래 66장 중 타 클래스 영웅 자산) **직접 실제 개발 카드 보유 원장에 1장 지급**. 이는 플레이어가 실제 본 게임에서 선택한 카드가 아닌 테스트용 자동 선택이다.
- 같은 A 재시도는 `applied:false`; B로 재선택하거나 다른 A 카드로 변경하려는 시도 거부. 특별 선택 이벤트 1건, 실제 카드 1장, 훈장 원장 `resolved` 및 읽기 `ledger_consistent=true`.
- 그 후 최종 챕터 기존 일반 보상 `chapter:02`을 **별도로 승인**하는 데 성공. 기존 드래프트 자동 발행/선택은 이 단계에서 수행하지 않았으므로 '일반 보상 지급 완료'가 아니라 **승인 상태**다. 특별 보상 처리는 기존 `trpg_cards.drafts`를 수정/생성하지 않았다.
- 완주 기록·첫 인증·해결된 훈장의 직접 UPDATE/DELETE를 DB 트리거에서 거부. 익명/일반 인증 사용자 직접 조회·실행 불허를 재검증할 것.

## 남은 필수 작업

- [ ] **다인 2~3명 성공/한 명 확정 사망·미귀환·한 챕터 실패** 테스트 픽스처. 해당 연대기 실패는 팀 전체 정식 인증/훈장/특별 보상을 막지만, 이전 챕터의 정당한 일반 보상을 취소하지 않는다. 현지 생존자·후일담의 실제 사실도 덮어쓰지 않는다.
- [ ] **두 번째 연대기 정상 완주** 시 추가 훈장/보상 1회는 가능, 최초 정식 인증은 여전히 정확히 1건임을 실저장 검증.
- [ ] **A/B 선택지 소진**(미보유 카드 없음·성장 8종 전부 만렙)과 동시 지급 요청/다른 팀에 속한 동일 영구 UUID의 경쟁 및 기존 카드 보상 RPC와의 충돌 회귀. 대체 보상 정책은 사용자 미확정.
- [ ] **새 ChatGPT 테스트 프로젝트와 실제 게임 연결**: 플레이어가 A/B를 직접 선택할 때에만 호출; 마틴의 개인 경력·실제 평가에 따라 대사/증서 출력. 카드/성장 소유 원장 재조회 후 수여 완료 표시, 본부 NPC별 개인 관계 변화는 해당 요원이 실제 들은 말로만 별도 저장.
- [ ] **일반 최종 챕터 드래프트까지 발행·선택·지급** 후 두 독립 원장의 합계·성장 중복 및 복원 재검증. 현재 이 신규 가상 연대기의 일반 보상은 승인까지만 완료.
- [ ] 실제 서사에서 최종 성공 선언이 검증된 `ending_state`에 정당하게 저장되는 절차와 새 `main` SAN/저장/시나리오 판본의 충돌 점검. 개발 픽스처로 이를 대신할 수 없음.
- [ ] 보안 인증·다인 본부 관계·NPC↔NPC 기억, 현재 `hq_events`/카드의 익명 RPC 공개 경계 및 운영 이식 전 DB 백업.
