# 시간요원 본부 — 운영 DB 이식 준비 / 출시 게이트 (2026-11-13)

> **상태: 설계·호환성 사전검사 완료, 운영 이식 보류.** 이 파일은 운영 DB에 SQL을 실행했다는 뜻이 아니다. 운영 DB를 개발 DB로 대체하지 않는다. 이 저장소 통합 PR #6은 실제 플레이와 운영 DB 검증 전까지 DRAFT를 유지한다.

## 실제 검사 기준선

- 운영: Supabase `trpg-state-v2` / `taoaffdyssqtnjszumpq`. 개발: `trpg-time-agent-dev` / `tvrfuljncwefbioasxgo`.
- 운영 DB는 `trpg_hq` 스키마 없음. `public`/`trpg_cards`/`trpg_private`의 공통 25개 함수 시그니처, 공통 77개 컬럼과 66개 제약 정의는 DEV와 일치. 운영에만 `trpg_private.gm_cleanup_archive`(6컬럼, 2개 제약)가 있어 그대로 유지한다.
- 유일한 공통 함수 본문 MD5 불일치는 `trpg_cards.save_loadout`의 **주석 문구**이며, 주석/공백을 제거한 본문 MD5는 운영/DEV 모두 `df5e283e1780093f2c4cee34c6c9a1b3`이다. 본부 이식을 이유로 기존 카드 함수를 교체하지 않는다.
- 이번 사전 조회 당시 운영의 각 행 수: 체크포인트 **3**, 비공개 정본 **9**, 별도 복구 아카이브 **38**, 카드 카탈로그 **66**, 일반 카드 플레이어 **0**. 이 수치는 *시점 기록*이며 배포 직전 반드시 새로 조회한다. **데이터 내용 지문은 공개 GitHub 문서에 기록하지 않는다.**
- DEV의 본부 테이블 **20개**, 함수 **43개**, NPC 서비스 **8개**. 전부 해당 스키마에서 RLS가 활성화되고 본부 함수의 `anon`/`authenticated` 실행 권한은 **0개**. 운영 이식 후 같은 수치와 권한을 재검증한다.
- `hq_readonly_preflight.sql`은 운영에서 읽기 전용 실행 확인됨. 내용 지문은 **백업 파일이 아니며 복원 수단이 아니다.**

## 이식 대상 선택

DEV의 총 **26개 마이그레이션**에서 초기화/기본 복제 **5개는 운영에 적용하지 않는다.** `bootstrap_trpg_*.sql` 3개도 운영 기존 카드 구조를 덮어쓸 위험이 있어 **적용하지 않는다.** 대신 이미 운영에 존재하는 V2·카드·비공개 정본을 참조하는 아래 **본부 전용 21단계**만 검사 대상으로 둔다.

**이 목록은 테스트된 원본 순서다. DEV ONLY로 작성된 원본 SQL을 그대로 운영에 실행하라는 승인이 아니다.** 운영용 패키지는 독립 데이터 백업/복원 시험, 격리 복제 DB에서의 21단계 전체 설치 및 실제 동작 시험, 권한 감사 뒤에 확정한다. 단계 사이의 `CREATE OR REPLACE FUNCTION`은 **최종 후속 단계에서 재정의된 함수**까지 포함해서 모두 적용해야 한다.

01. [`trpg_hq_phase1.sql`](../dev/trpg_hq_phase1.sql)
02. [`trpg_hq_phase2_dispatch_return.sql`](../dev/trpg_hq_phase2_dispatch_return.sql)
03. [`trpg_hq_phase2b_invariants_and_load.sql`](../dev/trpg_hq_phase2b_invariants_and_load.sql)
04. [`trpg_hq_phase2c_chronicle.sql`](../dev/trpg_hq_phase2c_chronicle.sql)
05. [`trpg_hq_phase3a_evaluation.sql`](../dev/trpg_hq_phase3a_evaluation.sql)
06. [`trpg_hq_phase3b_general_rewards.sql`](../dev/trpg_hq_phase3b_general_rewards.sql)
07. [`trpg_hq_phase3c_training_and_reward_resume.sql`](../dev/trpg_hq_phase3c_training_and_reward_resume.sql)
08. [`trpg_hq_phase4_clara_archive.sql`](../dev/trpg_hq_phase4_clara_archive.sql)
09. [`trpg_hq_phase4b_clara_integrity.sql`](../dev/trpg_hq_phase4b_clara_integrity.sql)
10. [`trpg_hq_phase4c_clara_active_membership.sql`](../dev/trpg_hq_phase4c_clara_active_membership.sql)
11. [`trpg_hq_phase5_personal_npc_memory.sql`](../dev/trpg_hq_phase5_personal_npc_memory.sql)
12. [`trpg_hq_phase5b_personal_boundary_guard.sql`](../dev/trpg_hq_phase5b_personal_boundary_guard.sql)
13. [`trpg_hq_phase5c_clara_repeat_personal_questions.sql`](../dev/trpg_hq_phase5c_clara_repeat_personal_questions.sql)
14. [`trpg_hq_phase6a_chronicle_completion_and_medals.sql`](../dev/trpg_hq_phase6a_chronicle_completion_and_medals.sql)
15. [`trpg_hq_phase6b_chronicle_special_choice.sql`](../dev/trpg_hq_phase6b_chronicle_special_choice.sql)
16. [`trpg_hq_phase6c_chronicle_award_integrity.sql`](../dev/trpg_hq_phase6c_chronicle_award_integrity.sql)
17. [`trpg_hq_phase7a_immediate_chapter_failure.sql`](../dev/trpg_hq_phase7a_immediate_chapter_failure.sql)
18. [`trpg_hq_phase7b_chronicle_terminal_roster_consistency.sql`](../dev/trpg_hq_phase7b_chronicle_terminal_roster_consistency.sql)
19. [`trpg_hq_phase11a_entry_induction_npc_loop_router.sql`](../dev/trpg_hq_phase11a_entry_induction_npc_loop_router.sql)
20. [`trpg_hq_phase11b_verified_briefing_and_full_loop.sql`](../dev/trpg_hq_phase11b_verified_briefing_and_full_loop.sql)
21. [`trpg_hq_phase11c_keep_pending_reward_first.sql`](../dev/trpg_hq_phase11c_keep_pending_reward_first.sql)

위 21단계의 DDL 대상은 `trpg_hq` 전용이다. 카드/성장 테이블 직접 쓰기는 기존 실적격 특별 보상 RPC의 *실행 시점*에만 가능하며, 마이그레이션 자체가 운영 카드 소유를 이관·재지급하면 안 된다.

## 실제 출시 순서와 통과 조건

1. **최신 운영 기준선 재확인**: GitHub `main` SHA와 운영 DB 스키마·함수, SQL `hq_readonly_preflight.sql` 결과 수집. 기존 플레이 중이면 동시 변경 동결 또는 타임스탬프 범위 대조.
2. **독립 백업과 복원 시험**: 기존 운영 DB 전체(비공개 정본/세이브/카드/성장/복구 아카이브 포함)를 Supabase 외부의 보호된 위치에 논리 백업하고, **별도의 격리 DB에 실제 복원해** 전 테이블 수/원문 SHA/함수·트리거/권한을 검사. 별도 백업 없이는 운영 변경 금지. 이 연결에는 자동 파일 백업·복원 기능이 없으므로 **현재 미완료**. 관리자: [Supabase Backup and Restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore).
3. **격리 운영 복제에 본부 스키마 테스트**: 복구한 격리 DB 또는 운영과 *완전히 동일한 스키마의 격리 복제*에서 본부 21단계를 **순서대로** 적용. 5개 DEV 기본 초기화나 `bootstrap`은 제외하고, 기존 `public/trpg_cards/trpg_private` 객체 변경이 0인지 전후 비교한다. 오류 시 격리 환경에서 수정·재시험.
4. **실제 통합 시험**: OFF 원작/기존 세이브 정상 복원과 ON 첫 입단, 닉네임/4슬롯/세계 정본/마틴 브리핑/제이든 출격, 실제 플레이의 verified 종결, 귀환 1회(+4320분), 마틴 평가, 클라라 명시 요청, 도미닉 플레이어별 일반·특별 보상, 재접속 및 중복 실행 거부. 기존 DEV 롤백형 합성 SQL 테스트만으로 이 항목을 완료로 표시하지 않는다.
5. **권한 감사/보안 확인**: `hq_readonly_postflight.sql`의 테이블 20/함수 43/NPC 8/RLS 미적용 0/일반 역할 호출 0을 확인하고 Supabase 보안 자문 확인. 기존 `public.card_*` 익명 호출 경고는 별도 보안 검토로 남기며 임의로 권한을 바꾸지 않는다.
6. **운영 이식 승인 후 적용**: 복원 가능한 백업과 격리 시험 성적, 실제 게임 테스트를 확보한 후 운영에 마이그레이션. 직후 `hq_readonly_preflight.sql` 재실행·사전 기준선과 원장 fingerprint 비교. 기존 레코드를 건드리는 새 SQL은 배포 실패로 취급한다.
7. **출시**: 운영 DB/본부 접근이 검증된 뒤에만 통합 PR #6 → `main`, 새 통합 ZIP/초상 8장/ON·OFF를 확인. DEV DB와 개발 브랜치는 독립 복구 근거를 보관한 뒤 나중에 정리한다.

## 중단 조건

- 원본 세이브/비공개 정본/복구 아카이브의 독립 백업 미존재 또는 실제 복원 실패.
- 본부 이식이 기존 V2·카드·정본 테이블/함수에 변경을 요구하거나 권한이 예상과 다름.
- 다른 사용자/기존 PC/카드·성장/저장 데이터를 소급 수정하는 쿼리.
- 익명·일반 인증 역할이 본부 개인정보 및 NPC 기억을 읽거나 쓸 수 있는 경로.
- 본부 ON 실제 전체 플레이 또는 일반 OFF 회귀 테스트 실패.

## 이번 작업 범위

이 문서, 읽기 전용 점검 SQL, 정적 이식 소스 검사만 **통합 GitHub 브랜치에 추가**한다. Supabase 운영 `trpg-state-v2`는 조회만 했으며, 독립 데이터 백업·복원, 운영 21단계 적용, 실제 게임 테스트, PR 병합, 개발 브랜치 삭제는 수행하지 않았다.
