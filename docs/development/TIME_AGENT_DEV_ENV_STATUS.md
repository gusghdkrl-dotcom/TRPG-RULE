# 시간요원 본부 — 개발 환경 실행 현황 (DEV ONLY)

> 이 문서는 **개발 브랜치에서 진행한 실제 작업 기록**이다. `main`이나 운영 DB의 구현 상태가 아니다. 최종 게임 정본은 아직 기존 `START_GAME.md`, `rules/*` 및 v0.8 설계와 구별해야 한다.

## 5차 — NPC별 요원 관계·개별 청취/클라라 질문 보호 (2026-11-12)

**개발 환경에서 실행·검증. 기존 본프로젝트 main 및 운영 Supabase는 변경하지 않음.**

- 적용 SQL: `docs/sql/dev/trpg_hq_phase5_personal_npc_memory.sql`, `docs/sql/dev/trpg_hq_phase5b_personal_boundary_guard.sql`.
- 새 표: `hq_npc_agent_relations`(팀·NPC·요원 UUID별 영구 태도/지식/관계 현재값), `hq_npc_interactions`(불변 사건/발화자/청취자/실제 변화 이유·시간).
- 새 RPC: `record_npc_interaction`(한 대화에서 실제 청취 요원에 한정한 개인 기억 저장), `load_npc_agent_context`(요원별 대화·관계·클라라 실제 개인질문 기록 재독). 익명 조회 금지, 사용자에게 GM 원문 직접 출력 금지.
- 구식 `record_event`의 NPC 공통 상태에 개인 `known_facts`/태도/관계를 저장하려는 요청은 차단, NPC 일반 위치 갱신은 허용. `clara_release` 새 기록의 질문 원문/질문자 UUID는 공동 이벤트 데이터에 넣지 않음.
- 가상 2인 요원 A/B 클라라 장면: A는 현지 인물 안부, B는 관측법 관심. `load_npc_agent_context`는 **A/B 각 2개 실제 청취 대사만** 반환; A가 별도 후속 질문을 하면 A 관계 revision 1→2, B revision 1/새 질문 없음 유지.
- 마틴과 A 별도 상담은 마틴-B 관계를 만들지 않음. 제이든·도미닉·사미라·레오·최서린·마야까지 총 8종 NPC 테스트 데이터 기록 성공. 개인 질문은 기존 클라라의 해당 요원 질문 3건을 개별 문맥으로 실제 재조회.
- 같은 사건 재요청 중복 저장/시간 증가 없음. 미참석자 기록·청취자 위조, 구식 공통 NPC 개인지식 주입, 낡은 revision, 이미 저장된 원문 변경, 다른 event_key 내용 재사용 시도 모두 거부. 함수/테이블 `anon` 접근 차단.
- 개인 질문 원문 보호 추가 실제 검증: 새 클라라 `clara_release` 후 공동 `hq_events.event_data`에 `question_text` 및 `requested_by`가 **모두 없음**, 개인 기록 원장에만 원문 보존. 과거 가상 테스트 기록은 보존하고 소급 정리하지 않음.
- 전체 기능/근거/남은 차단 사항: `docs/development/TIME_AGENT_NPC_RELATION_RUNTIME_CONTRACT.md`, `TIME_AGENT_IMPLEMENTATION_BACKLOG.md`.
- **구분할 미완료**: DB는 요원별 문맥을 반환하지만 ChatGPT 게임 키퍼가 실제 NPC 말투를 구사하며 본문에 안전하게 사용하는 엔드투엔드 시험은 아직 없음. 입력된 발화/청취/변경 사유의 실제 장면 인과는 DB만으로 증명 불가. 팀 공동 `record_event`의 자유형 `summary/event_data` 등에는 별도 공개 필터·엄격한 호출 계약 추가 필요. NPC↔NPC 기억·관계, 사용자 인증, 동시 호출, 연대기 특별 완주/정식 요원 인증도 다음 작업.

## 4차 — 클라라 영구 아카이브 구현 및 실저장 검증 (2026-11-12)

**모든 개발·테스트는 `trpg-time-agent-dev` 전용. 운영 DB와 본 프로젝트의 기존 룰북/세이브는 변경하지 않았다.**

### 신규 적용 파일

- `docs/sql/dev/trpg_hq_phase4_clara_archive.sql`: `hq_clara_observations`, `hq_clara_releases` 및 `clara_record`, `clara_catalog`, `clara_release`, `clara_read_shared`.
- `docs/sql/dev/trpg_hq_phase4b_clara_integrity.sql`: 테이블 직접 INSERT의 체크포인트 출처·세계/본부 시각·팀 연결 검증, 사후 기록 UPDATE/DELETE 차단, 비공개 기록의 직접 공개 INSERT 차단.
- `docs/sql/dev/trpg_hq_phase4c_clara_active_membership.sql`: 자료 목록·공개·재조회는 현재 팀에 **활성 참가 중인 요원**에게만 허용.
- `docs/development/TIME_AGENT_CLARA_RUNTIME_CONTRACT.md`: 정확한 호출 절차, 출처 필드·구분, 접근권/마음대로 '관측'을 만들어선 안 되는 경계, 테스트 및 운영 연결 전 미완료 요건.

### 동작과 출처 구분

- `verified_field`: 검증된 현지 세이브의 **JSON 경로와 값·SHA/버전이 정확히 일치**하는 자료만 원본 귀속. 현지 엔딩·정본은 수정·재실행하지 않음.
- `later_report`: 귀환 이후 실제 경과에 근거한 출처·관측 방식·원문 발췌가 있는 자료만 **`attributed_report`**로 별도 저장. 외부 보고서 자체의 진위는 DB가 보장하지 않음.
- `internal` 자료는 사용자 목록·열람에서 제외. `available`에 허용된 주제만 목록으로 표시하고, 플레이어가 **실제로 질문해 공개한 뒤**에만 본문 열람 가능. 팀에 공개한 정보는 파티 공통 공개 정보지만 본부 다른 NPC에게 자동 전달되지 않음.
- 클라라 기록은 **append-only**. 후속 세계 변화가 새로 관측되면 새 출처/새 레코드를 추가하고 과거 검증 기록을 고치지 않음.
- 출처 메타데이터/세계의 관측 시각과 본부의 `hq_elapsed_minutes`는 구분. 질문·열람만으로 본부 시간이 자동 경과하지 않음.

### 실제 테스트 결과

1. 검증된 대사건 `pcs.P1.alive=true`를 정확한 현지 관측값으로 저장; 반대값은 거부. 종료 상태 `runtime.ending_state.status=completed`의 정확한 확인도 허용.
2. 가상 현지 생활 후속 보고서는 `attributed_report`로 저장. 본부 시각보다 미래인 수신 시점은 거부. **테스트 보고서는 가짜 테스트 출처이며 실제 현지 원작의 후속 삶을 확인한 사실이 아니다.**
3. 총 가상 기록 **4건**, 그중 실제 질문에 따라 공개된 **3건**, 내부 전용 **1건**. 공개 전 본문 0건, 공개 후에는 해당 3건만 로드; 내부 기록 직접 공개 시도 차단.
4. 동일 기록 재요청 `applied:false`, 다른 팀 요청 차단. 기존 자료 덮어쓰기/공개 이력 삭제/비공개 자료 우회 INSERT 모두 DB에서 거부.
5. 활성 팀원을 가상으로 탈퇴시킨 동안 목록/본문/공개 접근을 모두 거부. 시험 종료 전에 기존 팀 참가 상태 복구.
6. 시간 관련 테스트: 본부 기록실에서 가상 30분 활동은 `record_event`로 별도 반영, 클라라의 질의·공개/재조회는 추가 시간 0분. 최종 테스트 팀 본부 경과 **4,365분**.
7. 기존 현지 검증 체크포인트 및 원작 세계 비공개 정본의 원문을 수정하지 않았으며, 운영 데이터도 복사하지 않았다.

**아직 미완료:** 클라라가 실제 원작 세계로부터 후속 관측을 획득하는 플레이 중 인과·수단/시간 판정, 다섯 후일담과 아카이브 내용 연결, 별도 ChatGPT 테스트 프로젝트의 도구 호출 및 안전한 UI 공개 필터, 연대기 완주 특별 보상 및 정식 요원 승격, 통합 ON/OFF 시작 라우팅, 사망/재투입. 서버의 "정확한 체크포인트 값" 검증은 플레이어가 묻는 모든 후일담 내용의 서사적 진위를 자동 증명하는 장치가 아니다.


## 3차-B/C — 마틴 승인·도미닉 실제 지급·훈련 자격 (2026-11-12)

**모든 항목은 격리된 `trpg-time-agent-dev`에서 실제 함수 호출/원장 재조회로 확인. 실제 게임 운영 프로젝트·룰북·세이브는 미변경.**

### 신규 개발 SQL과 상태

- `docs/sql/dev/trpg_hq_phase3b_general_rewards.sql` → `dev_hq_phase3b_general_reward_authorize_issue_resolve` 설치.
- `trpg_hq.hq_reward_grants`는 종료 구간·실제 플레이어 UUID 단위 승인/발행/해결/소진 상태 및 `(campaign_id,event_key,player_id)` 중복 방지 유일키를 저장. RLS 활성, 일반 클라이언트의 직접 접근 불가.
- `approve_general_reward`는 **실제 검증 종료 + 본부 귀환 + 마틴 평가** 이후 참가 요원별 보상 승인. 대사건 `final`, 연대기 `chapter:<실제 챕터 ID>` 기존 사건 키를 사용. **현지 PC 사망 자체가 플레이어 UUID의 종결 보상 자격을 자동 박탈하지 않음.**
- `offer_general_reward`는 원래 `trpg_cards.issue_draft`를 같은 DB 트랜잭션에서 호출하고, 적격 후보/이벤트 출처·후보 동일성을 확인하며 `approved`→`offered` 또는 `exhausted` 전환.
- `resolve_general_reward`는 원래 `trpg_cards.resolve_draft`를 호출해 한 선택만 실제 보유 카드 또는 성장 레벨에 반영하고 본부 원장과 대조한다. 반복은 기존 결과 반환·다른 선택 거부.
- 후보는 **키퍼의 Python SystemRandom**과 `rules/09-cards.md`의 클래스 희귀:영웅:전설 30:15:5 재정규화 및 소진 시 재분배 규칙으로 생성. DB는 `draft_pool`에 대한 적격성/중복/소진을 재검사한다. 서버가 외부 난수의 진위를 증명한다고 주장하지 않는다.
- `docs/sql/dev/trpg_hq_phase3c_training_and_reward_resume.sql` → `dev_hq_phase3c_training_qualifications_and_reward_readback` 설치.
- `certify_training`: 대사건 성공적 종결+실제 귀환+평가와 요원의 실제 귀환 참가를 확인한 경우 `recruit`→`training_qualified`로 1회 기록. 임무 후 귀환하지 못한 리타이어자의 훈련 완료를 자동 인정하지 않음.
- `hq_chronicle_requires_qualified_team` 트리거: **새로 준비하는 연대기**에 참가 중인 팀원 모두 훈련 완료 필요. 기존 2차 검증 시 생성한 가상 연대기 이력은 자격 게이트 이전 테스트 픽스처로 유지하며 운영 자격 판정의 근거로 사용하지 않는다.
- `load_team_rewards(team_id)`: 승인·발행·해결 상태와 기존 카드 DB의 실제 드래프트/결과를 함께 조회. 원장 동기화 여부를 표시해 새 채팅에서 실패 복구와 불일치 확인에 활용.

### 실제 DB 테스트 결과

1. 미귀환/미평가 가상 임무의 보상 승인 요청 거부. 정상 종료된 대사건 보상 승인 후 동일 요청 재실행 `applied:false`.
2. 기본 지급 카드 `GU-A-0`을 드래프트 신규 후보로 위조하려는 요청 거부. Python SystemRandom으로 뽑은 4개 적격 후보는 정식 카드 드래프트에 1회 기록·재요청에도 최초 후보 유지.
3. 가상 요원이 보유 18장에서 중립 강화 카드 `NE-E-6` 1장 선택: **19장**으로 증가. 재요청에도 19장 유지. 본부 `resolved`와 카드 DB `resolved` 및 실제 소유 원장 일치.
4. 연대기 1장: 기존 성장 `CON` Lv.0 → **Lv.1 확정** (기존 규칙). 연대기 최종 2장: 성장 `CON` 재등장 **반복 강화 테스트 픽스처**를 사용하고 실제 Python 난수 71, 기존 확률 80% 적용 → Lv.2 성공. 재요청에도 추가 성장 없음. 가상 테스트용 고정 `CON` 재등장은 실제 게임의 무작위 후보 선정 방식이 아님.
5. 다른 선택으로 과거 보상 변경 또는 후보 재추첨 요구는 거부. `trpg_hq` 익명 권한 없음; 새 보상 원장 테이블 `anon` SELECT 불가, 신규 보상 지급 함수 `anon` 실행 불가.
6. 보상 원장 복원: 연대기 2개 원장과 기존 카드 드래프트 2개가 일치(`ledger_consistent` 결과 불일치 0건).
7. 검증된 대사건 종료·귀환·평가 근거로 훈련 자격을 부여, 같은 요청 재실행 무변경. 별도 무자격 시험 요원은 연대기 출격 거부되고 신규 임무 0건, 기존 팀 revision 0 유지. 훈련 자격 취득 요원은 신규 연대기 준비 성공.

### 구현 경계 및 남은 과제

- 기존 일반 드래프트·영구 성장 데이터에 임의 보너스를 추가하지 않았다. `09-cards`의 실제 보상 발행/소유·성장 원장을 재사용했다.
- **연대기 전체 완주 특별 보상**(영구 훈장 + 전설 제외 미보유 카드 직접 선택 *또는* Lv.5 미만 성장 1회 확정 +1)은 새 별도 RPC/원장 설계가 필요한 상태. 일반 드래프트로 대체하지 않는다.
- **정식 요원 승격·진급 점수/임계치**는 별도 구현 대상이다. 미합의 수치는 생성하지 않는다.
- **클라라의 관측 출처와 이후 인물들의 삶 아카이브, 실제 동기화/입단 장면, 처음 ON/OFF 라우터, 현지 5개 후일담, 사망/재투입, ChatGPT 테스트 프로젝트의 실제 자동 호출**은 아직 구현·통합 검증되지 않았다.
- **Supabase 보안 자문**: 새 HQ 테이블에는 RLS와 비공개 권한이 있고 `anon` 직접 접근 검증 결과는 차단. 보안 자문 INFO `rls_enabled_no_policy`는 의도적인 비공개 원장 설정; WARN `anon_security_definer_function_executable`은 원래 닉네임만으로 이용하는 기존 카드 공개 RPC에 대한 기존 설계상 위험이다. 임의로 공개 권한을 확장하지 않았다.
- 추가 검증 권장: 다인 팀/동시 요청 경쟁, 성장 실패(80% 판정 실패)와 보상 소진, 재접속에서 드래프트 미선택 복원, 전지적 NPC 기록 누출 방지, 실패한 현지 임무와 재투입 경계, 이식 시 기존 레거시 카드 ON/요원 OFF 회귀 테스트.


## 3차-A — 마틴의 정성 평가 저장 기능 (개발 DB 검증)

- 개발 SQL: `docs/sql/dev/trpg_hq_phase3a_evaluation.sql`. 테스트 DB 마이그레이션 `dev_hq_phase3a_qualitative_evaluation` 실제 적용.
- `trpg_hq.evaluate_segment(segment_id, expected_revision, grade, objective_results, assessment, observed_outcomes)`는 **실제 verified 종료·귀환 완료된 구간에서만** 공식 평가를 기록한다.
- S/A/B/C/F 등급, 사전 소목표의 원래 ID별 달성/부분달성/미달성/불가능 결과 및 실제 이유, 서술형 총평·관측한 실제 성과를 기록한다. 미리 부여하지 않은 소목표를 끼워 넣으면 거부한다.
- 마틴의 평가를 해당 원래 `terminal_event_id` 및 verified 체크포인트 버전과 함께 저장하며, 변경 없이 재호출 시 `applied:false`, 다른 평가로 사후 덮어쓰기는 거부.
- 실제 가상 대사건: 2개 원래 소목표를 근거로 B 등급 공식 평가 저장. 동등 반복은 추가 기록이 없고 다른 S 등급으로 바꾸려는 호출은 거부. 본부 시각은 4,335분 유지. `mission_evaluated` 사건 1건만 생성. 익명 실행 권한 없음.
- **주의:** 실제 평가를 내리는 근거는 현지 플레이 정본/후일담과 NPC의 합당한 지식에 따라 키퍼가 제시해야 한다. SQL은 논리적 행/식별자 일관성을 검사하지만 공포 세계의 서사적 진위를 스스로 판단하지 못한다. 정량 진급 점수/보상은 발명하거나 지급하지 않음.
- **남은 핵심 기능:** 평가 후 마틴의 보상 승인, 기존 `trpg_cards` 실제 발행/선택과 중복 복구, 훈련 합격/연대기 자격, 클라라 관측기록, ON 첫 입단/현지 로드/귀환 라우터, 재투입·치명상 특성, 실제 별도 ChatGPT 프로젝트 실행 검증.

## 환경 및 격리 기준

- GitHub 소스: `gusghdkrl-dotcom/TRPG-RULE` → **`dev/time-agent-hq`**
- 운영 GitHub 기준 커밋: `e3b33384f8a6048fa8af072836a62771137e8d7c`
- 운영 Supabase 프로젝트: `trpg-state-v2` / `taoaffdyssqtnjszumpq` (**읽기 전용 기준, 이 개발 작업으로는 변경 금지**)
- 독립 테스트 Supabase: `trpg-time-agent-dev` / `tvrfuljncwefbioasxgo` (서울, PostgreSQL 17)
- ChatGPT: 사용자가 새 별도 테스트 프로젝트를 생성했다고 확인했으나, 이 채팅에서는 해당 프로젝트의 파일/설정에 직접 접근하거나 수정하지 못한다.
- 본부 구현이 완료되기 전 운영 `START_GAME.md`, 00~09 룰북, `dist/` 및 기존 세이브/카드/실제 정본을 변경하지 않는다.
- 최초 합의와 최신 확정/미확정 경계는 `docs/development/TIME_AGENT_CONCEPT_DRAFT.md` v0.8 §§0–33을 따른다.

## 실제 설치된 개발 DB 구조

테스트 프로젝트에 다음 순서로 Supabase 마이그레이션을 적용하고 성공 결과를 확인했다.

1. `dev_baseline_trpg_state_v2`: 원본 `docs/sql/trpg-state-v2.sql` → `public.gm_checkpoint_history`와 저장 RPC.
2. `dev_baseline_trpg_card_collection_v1`: `docs/sql/dev/bootstrap_trpg_card_collection_v1.sql` → `trpg_cards` 9개 테이블 및 카드 66종.
3. `dev_baseline_card_nickname_public_v1`: `docs/sql/dev/bootstrap_trpg_card_nickname_public_v1.sql` → 기존 공개 카드 닉네임 함수.
4. `dev_baseline_card_growth_mode_v1`: `docs/sql/dev/bootstrap_trpg_card_growth_mode_v1.sql` → 영구 성장 모드 연결.
5. `dev_baseline_trpg_private_canon_v1`: 원본 `docs/sql/trpg-private-canon-v1.sql` → 비공개 세계 정본 테이블/불변 트리거.
6. `dev_hq_phase1_schema_and_event_ledger`: `docs/sql/dev/trpg_hq_phase1.sql` → 신규 `trpg_hq` 영구 기록 스키마.

**참고:** 기존 카드 SQL 자료의 일부 함수 종료 `end $function$` 뒤 세미콜론이 빠져 원본 그대로는 빈 DB에 재설치되지 않았다. 운영 원본은 수정하지 않고 개발 전용 부트스트랩 파일에 필요한 세미콜론과 마이그레이션 래퍼 처리만 보정했다. `docs/sql/document_bound_payload_v1.sql`은 명시적으로 ARCHIVE 전용이므로 설치하지 않았다. 실제 운영 DB가 이 설치 스크립트와 완전히 동일한지 확인하는 회귀 검증은 별도로 필요하다.

### 신규 `trpg_hq` v1 테이블

- `hq_agents`: 기존 `trpg_cards.players.id` UUID 연결과 훈련/정식 자격 저장(실제 자격 변경 기능은 미구현).
- `hq_teams` / `hq_team_members`: 팀·멤버·팀별 HQ 논리 시간(분)·동시 수정용 revision.
- `hq_actor_states`: NPC/요원별 현재 기억/관계/지식 상태. 다른 인물에게 지식 자동 공유 없음.
- `hq_missions` / `hq_mission_segments`: 임무 ↔ 캠페인/챕터/세션 연결을 위한 틀. **현재는 외부 검증 종료/귀환/평가/지급을 수행하지 않음.**
- `hq_events`: 사건 고유키, 시점, 발화자, 실제 청취자, 공개 대상, 중요한 발언/근거를 저장.

### 현재 설치된 함수

- `trpg_hq.create_team(team_key, agent_ids)`: 기존 카드 플레이어 1–3명을 팀에 등록. 동일 팀 키의 반복 요청은 멤버 동일성을 검사.
- `trpg_hq.jsonb_deep_merge(base, patch)`: 기존 관계/지식의 다른 중첩 필드를 없애지 않도록 병합.
- `trpg_hq.record_event(...)`: 원자적 이벤트 이력 + 팀 시각/스냅샷 + 지정된 인물의 상태 변경. 동일 사건·내용 반복 시 중복 적용 없음; 동일 키 다른 내용 거부; 기대 revision 불일치 거부. `mission_return`, `reward_granted` 등 보호 이벤트는 이 일반 함수에서 거부하며 별도 검증 절차 구현 전까지 사용하지 않음.

### 실제 통과한 개발 테스트 (2026-11-12)

- 테스트 전용 가상 닉네임 `HQ_DEV_SMOKE_01`을 새 **개발 DB에만** 등록해 기존 카드 시작 지급 18장 확인.
- 단일 테스트 팀 생성 확인. 진짜 플레이어 계정/카드/세이브는 복사하지 않음.
- 입단 면담 사건 1회 저장: revision 1, HQ 경과 10분.
- 같은 키·내용 재실행: `applied=false`, revision 1/10분 유지.
- 후속 대화 기록 및 중첩 상태 병합: revision 2, 총 15분; 원래 마틴 지식과 새로 알게 된 정보 모두 남음.
- 관련 없는 클라라의 기억 레코드 생성 없음.
- 기대 revision 0으로 새 사건 쓰기 시 충돌 거부. 기존 사건 키에 다른 내용으로 쓰기 시 충돌 거부. 두 요청 후 revision 2 / 15분 / 사건 2건 유지.
- `anon` 및 `authenticated`의 `trpg_hq` 스키마 사용 권한 없음; `anon`의 HQ 사건 SELECT 및 함수 EXECUTE 없음. 신규 모든 HQ 테이블 RLS 활성화.
- 아직 동시 쓰기 스트레스 시험, 실제 ChatGPT 프로젝트의 도구 호출, 새 채팅 복원, 인증 모델, 현지 종료 검증을 통합 테스트한 것은 아니다.

## 2차 구현 및 검증 (2026-11-12, 테스트 DB에서 실제 실행)

**GitHub 개발 브랜치와 독립 Supabase 테스트 프로젝트에만 설치. 운영 DB·운영 카드·실제 세이브 불변.** 이전 1차 작성 시의 미구현 목록은 아래 본 절 및 후속 계획으로 갱신한다.

### 실제 적용한 개발용 SQL (추가 3개 마이그레이션)

- `docs/sql/dev/trpg_hq_phase2_dispatch_return.sql`: `prepare_mission`, `start_segment`, `confirm_segment_terminal`, `return_segment`. 임무-현지 `campaign_id/session_id` 연결, 사전 목표/위험 등급, verified 체크포인트·실제 비공개 정본 SHA 연결, 귀환 1회당 정확히 4,320분.
- `docs/sql/dev/trpg_hq_phase2b_invariants_and_load.sql`: 종료 결과의 DB 제약·임무 내 고유 `finalization_event_id` 보장, `load_team` 현재 스냅샷 + 최근 100 사건, `load_events_page` 전체 역사 페이지 조회. **비공개 NPC 상태를 담으므로 원문을 플레이어 UI에 그대로 공개하지 않을 것.**
- `docs/sql/dev/trpg_hq_phase2c_chronicle.sql`: `prepare_next_chapter`. 동일 연대기에서 이전 챕터의 검증된 실제 귀환이 있어야 다음 챕터를 등록·출격할 수 있게 연결.

### HQ ON 신규 DB1 속성 — 개발용 제안, 운영 룰북 미적용

- `runtime.hq = {enabled:true, mission_id:<UUID>, segment_key:<챕터 고유 ID>}`
- `runtime.ending_state = {scope:CAMPAIGN_TERMINAL|CHAPTER_TERMINAL|CHRONICLE_TERMINAL, status:completed|failed, finalization_event_id:<실제 종료 이벤트 ID>, returning_agent_ids:[<실제로 귀환 가능한 요원 UUID>]}`
- 서버는 본부 임무와 검증된 현지 `session_id`/`campaign_id`/segment, `canon_ref`와 불변 `gm_canon_documents`의 전체 SHA, 체크포인트의 실해시·부모·최신 verified 상태를 확인한다. 실제 귀환 가능 요원이 없으면 +3일 지급을 거부한다. 단 **DB의 해시·필드 검증은 실제 서사 결과의 의미적 타당성을 스스로 판정하지 못한다.** 키퍼의 룰북 절차와 실플레이 세이브 검증이 추가되어야 한다.
- 본부 내부 시간은 시작점이 확정되지 않은 논리 경과 분. `return_segment`는 `terminal_confirmed` 상태의 실제 생존 귀환 요원이 존재할 때에만 진행; 고유 `return:<segment_id>` 사건으로 멱등성 보장. 기존 `OFF` 또는 레거시 `ON` 체크포인트를 자동 HQ 귀환으로 해석하지 않는다.

### 실제 검증 결과

1. **대사건**: 본부 15분에 출격한 가상 요원 → 실제 `trpg_v2_commit/verify`로 가상 현지 `DB1` 저장 → 정확한 해시/정본 대조 `terminal_confirmed` → 첫 귀환 15+4320=4335분. 재호출은 `applied:false`, 시간 4335분 불변.
2. 잘못된 체크포인트 SHA는 거부. 마틴 면담 기록의 같은 `event_key` 재사용·오래된 팀 revision은 거부. 기존 지식 보존과 타인 NPC 지식 비전파 확인.
3. **연대기 1장**: 같은 세계·캠페인의 첫 장 `CHAPTER_TERMINAL` verified 후 +4320분. 전체 임무는 계속 활성.
4. **연대기 최종 2장**: `prepare_next_chapter` + 새로운 챕터 식별자로 실제 verified v2 부모해시 체인 확인. 1장 checkpoint를 2장 증거로 재사용하려는 요청 거부. `CHRONICLE_TERMINAL` 귀환 뒤 총 8640분(6일), 귀환 기록 2건, 전체 임무 `completed`. 재실행에도 이중 +3일 없음.
5. **부정 테스트**: 별도 가상 요원의 출격 후 verified 세이브가 하나도 없는 상황에서 terminal 확인 및 귀환 시도는 모두 거부. 팀 경과 0분, 귀환 사건 0건 유지.
6. **로드**: `load_team`에서 팀원, 마틴의 독립적 기억, 누적 시간, 임무/챕터, 사건 수 조회 성공.
7. **권한**: `anon`/`authenticated`의 HQ 스키마 사용 권한 없음. 익명자의 `hq_mission_segments` SELECT·`return_segment`·`load_team` 호출 권한 없음.
8. 실제 테스트 DB 결과: verified 가상 체크포인트 3개, 완료 임무 2개(대사건+연대기), 귀환 사건 총 3건. 가상 플레이어 3명은 **운영 계정과 별도**.

### 2차 구현이 아직 의미하지 않는 것

- ChatGPT 테스트 프로젝트에서 실제 플레이하면서 Supabase 함수 호출/저장/복원이 자동으로 실행되는지는 **아직 통합 테스트 안 됨**.
- `ending_state` 내용의 인과적 진실성을 서버가 독자 검증하는 것은 아니므로 저장한 현지 종결의 실제 확인·후일담·NPC 생사·성공/실패 의미 규칙을 런타임과 연결해야 함.
- 마틴 공식 수행 평가/승인, 훈련 자격 변경, 클라라 세계 후속 아카이브, 도미닉 실제 카드 보상/성장 지급, 실제 HQ 신규 첫 입단 장면·ON/OFF 라우팅, 연대기 치명상/대사건 재투입은 미구현. 운영판 이식은 승인/백업 전 금지.

## Phase1 당시 미구현 / 다음 구간 (2차 결과는 위 최신 절 참조)

1. **검증된 현지 종료 판정과 귀환당 +3일의 정확히 1회 처리**: 서버가 `verified` 원본·정본을 교차 확인하는 전용 함수. 최종 챕터/실패/재투입/로드/중복을 구별.
2. **마틴 평가·도미닉 기존 카드 보상 발행/실제 해결**: 기존 `trpg_cards` 지급 원장이 유일 권위. 연대기 완주 확정 선택/성장 RPC 별도 필요.
3. **클라라 이후 세계 아카이브**: 검증된 현지 상태와 관측 시점/출처 연결. 미래 전지적 조회 금지.
4. **ON 입단·본부 장면 → 현지 시작/로드 → 귀환**을 개발 브랜치 실행 룰북에 연결하고 테스트 ZIP 제작. `OFF`와 기존 카드 ON 레거시 세션은 불변.
5. 입단 면담·휴게실 관계·시간 등 실제 새 테스트 ChatGPT 프로젝트를 통한 체험/장면 경계 및 영속 복원 확인.
6. 훈련 사망 NPC 재투입·연대기 치명상 특성 및 카드 충돌은 담당 규칙의 정확한 수치·예외를 확정한 뒤 구현.
7. 전 과정을 테스트 DB에서 검증한 뒤 **운영 DB 백업과 이식 계획을 다시 검토**하고 명시적으로 승인받아 운영에 적용. 개발 프로젝트는 운영 안정화 뒤 삭제.

## 실행/보안 주의

- 테스트 프로젝트 ID를 운영 프로젝트 ID와 바꾸어 입력하지 말 것.
- 현지 게임의 운영 데이터, 실제 비공개 세계 원문, 실제 이용자의 개인/카드 데이터는 개발 프로젝트에 복제하지 말 것.
- GitHub `dev/time-agent-hq`의 SQL은 일부 단계만 검증된 개발 자료로, 현재 `main`이나 운영 `trpg-state-v2`에 그대로 적용할 수 있는 완성본이 아님.
- 연대기 계급 점수/컷, 원작 지리/본부 실측, 사망 방지 정확한 수치는 미확정. 테스트 편의상 정본으로 채우지 말 것.
