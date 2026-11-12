# 시간요원 본부 — 개발 환경 실행 현황 (DEV ONLY)

> 이 문서는 **개발 브랜치에서 진행한 실제 작업 기록**이다. `main`이나 운영 DB의 구현 상태가 아니다. 최종 게임 정본은 아직 기존 `START_GAME.md`, `rules/*` 및 v0.8 설계와 구별해야 한다.

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
