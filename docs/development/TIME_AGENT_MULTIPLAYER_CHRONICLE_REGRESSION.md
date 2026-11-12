# 시간요원 본부 7차 — 2~3인 연대기 생존·실패·귀환 검증

> **개발 환경 전용**, 2026-11-12. GitHub `dev/time-agent-hq` / Supabase `trpg-time-agent-dev`. 메인 게임 규칙과 운영 DB/세이브를 수정하지 않음. 실제 원작 플레이의 사망·선택·보상 사례가 아니라 **가상 검증 픽스처**.

## 이번 단계에서 발견해 고친 결함

### A. 중간 챕터 확정 실패가 연대기 전체 실패로 이어지지 않는 문제

기존에는 `return_segment`에서 `CAMPAIGN_TERMINAL` 또는 `CHRONICLE_TERMINAL`만 임무 상태를 `completed/failed`로 확정했으므로, 1장의 `CHAPTER_TERMINAL + failed`가 verified로 확인돼도 해당 연대기의 임무 상태는 `field_active`로 남을 수 있었다. 이렇게 되면 `prepare_next_chapter`가 2장 진행을 허용할 수 있는 구조였다.

- 보완 SQL `docs/sql/dev/trpg_hq_phase7a_immediate_chapter_failure.sql` 설치 완료.
- `hq_mission_segments`가 **검증된** `terminal_confirmed`로 전환될 때 기존 verified checkpoint와 성공/실패·생존 내용을 참조한다.
- 연대기 최종뿐 아니라 **중간 챕터 실패·명시된 요원 사망**에서도 임무 상태를 같은 트랜잭션 안에서 `failed`로 즉시 확정한다. 기존 귀환 규칙은 전원 사망(귀환0명) 시 본부 귀환/시간 +3일을 실행하지 않는다.
- 실패 상태를 직접 `field_active/completed`로 되돌리는 시도는 `hq_chronicle_failed_mission_cannot_reactivate`로 거부한다. 다른 사람의 현지 생사를 강제로 바꾸거나 과거 성과/보상을 몰수하지 않는다.

### B. 세이브의 생존·귀환 명단과 성공 선언이 서로 모순돼도 정상 종료로 넘어갈 수 있는 문제

- 보완 SQL `docs/sql/dev/trpg_hq_phase7b_chronicle_terminal_roster_consistency.sql` 설치 완료.
- 최종 종료의 `completed` 표기가 팀 전원 실제 귀환을 뜻하려면 **카드 캠페인에 등록된 동일 UUID 전부**가 `returning_agent_ids`에 정확히 포함되어야 한다.
- verified checkpoint의 `pcs`는 참가자 전원을 정확히 한 번씩 포함하고 `alive`는 명시적인 boolean이어야 한다. 누락·중복/대상 불명·정보 타입 모순 시 확정 거부.
- `alive=false` 요원을 귀환 명단에 넣지 못한다. 적어도 한 요원이 사망했다면 `terminal_status=completed`로 승인하지 못한다.
- 모순된 verified 세이브 원문은 자동 수정·소급 변조하지 않는다. 올바른 종결 체크포인트의 재검증 절차가 필요하다. 미귀환자를 자동 사망시키거나 나머지 생존자의 종료 결과를 무효로 하지 않는다.

## 실제 실행한 테스트

영속 작업 SQL: [2–3인 다인 롤백 검증](../sql/dev/tests/trpg_hq_phase7_multi_team_rollback_regression.sql)

테스트 스크립트는 **개발 전용 가상 카드 계정, 훈련 후보 자격, 2~3인 팀, 연대기 캠페인, 비공개 정본, 두 챕터의 V2 commit/verify 체크포인트, 현지 종료·본부 귀환·마틴 평가**를 실제 DB 함수에 거친다. 각 시나리오의 모든 작업을 서브트랜잭션으로 실행하고 검증 성공 시 **고의 예외로 롤백**, 결과 설명만 임시 테이블에 남긴 후 해당 SQL 요청 종료와 함께 삭제한다.

**중요한 검증 경계:** `training_completed=true`/후보 자격은 이번 다인 수용·완주 검증을 위해 *가상 생성 요원에 한해 테스트 안에서 부여*했다. 이는 개별 요원의 실제 원작 대사건 훈련을 완주했다는 새 증거가 아니다. 훈련 인증 출처·실전 플레이 접속은 다음 통합 검증 대상으로 남는다.

| 케이스 | 참가자 | 실제 검증 결과 |
|---|---:|---|
| `two_survive` | 2 | 2명 모두 verified 귀환·평가 후 첫 정식 인증2/훈장2; 동일 승인 반복 `applied:false` |
| `three_survive` | 3 | 3명 모두 verified 귀환·평가 후 첫 정식 인증3/훈장3; 동일 승인 반복 `applied:false` |
| `two_one_dead` | 2 | 최종 구간에서 1명 `alive=false`, `failed`, 생존자만 귀환: 신규 인증·훈장·특별 지급 **0** |
| `three_failed` | 3 | 3명 생존/귀환이어도 최종 임무 `failed`: 신규 인증·훈장·특별 지급 **0** |
| `three_missing` | 3 | 한 명 미귀환인데 최종 종료를 `completed`로 위장: **terminal 확인 단계에서 거절**. 1장 일반 보상 승인 보존 |
| `two_early_failed` | 2 | **1장**에서 1명 `alive=false` 및 `failed`: 임무 즉시 `failed`, 2장 준비 거부, 실패→진행중 상태 직접 변경 거부, 인증·훈장·특별 지급 **0** |
| `dead_labeled_win` | 2 | 사망자를 `pcs`에 남긴 채 최종 `completed`로 선언: 검증 거절, 인증·훈장 **0** |
| `dead_returned` | 3 | `alive=false` 인물을 최종 귀환 명단에 포함: 검증 거절, 인증·훈장 **0** |
| `two_all_dead` | 2 | 1장에서 **전원 사망**, 귀환자 0명: 임무 즉시 실패, `return_segment` 거절, 본부 시간 +0분, 인증·훈장·특별 지급 **0** |

세이브 검증과 상태 전환의 정상 호출 전체에서 **테스트용 특별 A/B 보상을 자동 선택/지급하지 않았다.** 사망이나 일부 귀환 시 생성된 구조·피해 경감·현지 생존자 상태를 재작성하는 로직도 두 트리거에 없다.

`two_one_dead`·`three_failed`·`three_missing`에서는 **이전 1장의 일반 보상 `approved` 원장이 그대로 존재**하는 것을 테스트 내부에서 확인했다. *기존 일반 보상의 카드/성장 실제 지급 완료 후 몰수 없음*은 별도 end-to-end 테스트가 필요하며, 여기서는 **승인 기록 보존**까지 직접 검증했다.

## 도구·보안·주도권 경계

- `trpg_hq.hq_mission_segments` 실패 감지 트리거는 원래의 `confirm_segment_terminal`에서 verified checkpoint가 갱신되는 단계에만 반응한다. 공개 RPC를 추가하지 않았다.
- 모델은 사망을 임의 지정하지 않는다. 여기서 사용한 `alive=false`는 실제 캐릭터의 HP/빈사/생존 특성 규칙을 대신한 **테스트 입력값**이며, 실제 플레이에서는 02-checks/03-danger 및 연대기 생존권 규칙에 따라 사망이 최종 확정된 뒤에만 이 값이 정당하게 기록되어야 한다.
- 실제 1~3인 게임 클라이언트의 본부 귀환 안내·마틴 대사·클라라 개인 기록·도미닉 보상 선택 UI·최종 플레이 도구 접근권은 여전히 별도 미구현이다.
- SQL은 전원 본부 기록이 성공한 것처럼 꾸며 실제 위험·피해를 삭제하지 않으며, 미귀환을 자동 사망 판정하지 않는다.

## 후속 필수 검증

- [ ] 연대기 **죽음 직전 특성 1회/전설 강화 우선 적용** 뒤 실제 확정 사망만 `alive=false`로 들어오는 현지→본부 전 과정.
- [ ] 중간 챕터의 **생존했으나 미귀환** 상태에 대한 임무 지속/재동기화 정책. 현재 전체 완주 인증은 막히지만 중간 챕터 출격 가능성/실제 구출 경로는 원작 인과와 사용자 확정안이 필요하다.
- [ ] 2–3명에 대한 **정식 인증 이후 특별 A/B 각자 다른 선택**, 전부 소진·서로 경쟁하는 카드 소유, 일반 챕터 보상 실제 지급까지 하나의 사건으로 검증.
- [ ] 동일 UUID의 **두 번째 연대기 완주** 후 훈장만 추가·첫 정식 인증은 1건 유지 및 실패했을 때 과거 정식 자격/훈장 보존.
- [ ] 기존 `main` 최신 룰북(특히 02-checks HP/사망, 03-danger 환경 위해, 07-state 종료 검증)의 호환성 테스트. 운영에 적용하지 않음.
