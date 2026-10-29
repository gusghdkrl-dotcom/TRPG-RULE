# 구판에서 1차 정리판으로

기준 원본: `2a19727043c3a42d8d2f80ef96a1afabe8dfbe62`.

## 파일 교체

| 이전 파일 | 현재 위치/처리 |
|---|---|
| PROJECT_INSTRUCTIONS_SETUP_ORDER_ROUTER_A24.txt | PROJECT_INSTRUCTIONS.md |
| TRPG_GPT_RULEBOOK_STAGE_DURABILITY_A24.txt | rules/01~09 분야별 정본; 각 블록의 상세 위치는 rule-migration.json |
| OPTIONAL_PRIVATE_STATE_STORE_SETUP_FINAL_ONLY_A24.txt | rules/07-state.md, 공개 투영은 08/09; 영구 프로필·성장·소설 종속 부분 삭제 |
| 시작_프롬프트_PC먼저_세계나중_최종1회저장_A24.txt | START_GAME.md; 중복 규칙은 전문 문서로 통합 |
| 조사자_수첩_Lite_전용_패치_프롬프트_v32_A24_20261024.txt | 실행 계약은 rules/09-notebook.md, 개발 절차는 NOTEBOOK_MAINTENANCE.md |
| 패치 프롬포트.txt | README.md, EDITING.md, 개발 감사·일지 |

구판 원문은 Git 이력에 보존돼 있다. 실행 폴더에 사본을 두지 않는다. 프로젝트 소스에서도 구판을 제거한 뒤 현재 업로드 묶음만 사용한다. GitHub 변경이 이미 업로드된 프로젝트 파일을 자동 교체하지는 않는다.

## 블록 추적

rule-migration.json은 원본 주 룰북의 SYSTEM_LOCK/SYS_RULE/SYS_DIRECTIVE 403개 블록을 전부 분류한다. `original_line_normalized`는 원문의 잘못된 리터럴 줄바꿈 두 곳을 실제 줄바꿈으로 정규화한 뒤의 줄 번호다. `source_sha256`은 해당 블록에서 태그/구분선만 정리한 본문의 UTF-8 hash이며 원본 파일 전체 hash가 아니다.

- 정리·이동: 의미·수치 보존을 중심으로 태그·이력·참조와 삭제 기능에 종속된 표현을 정리했다.
- 재작성: 중복·충돌 또는 사용자 변경 범위를 현재 절차로 합쳤다.
- 통합: 다른 규칙/새 공통 절차로 옮겼다.
- 삭제: 명시적으로 제거한 기능 또는 그 기능에만 필요한 분기다.

비공개 저장의 별도 계약은 STATE_AUTHORITY/SCHEMA/IDENTITY/INTEGRITY/CADENCE/COMMIT/RECOVERY/RESUME/COMPATIBILITY로 통합했다. 공개 지도·시각 정체성·수첩 상태는 각 전문 문서와 STATE_SCHEMA에서 다룬다. 오래된 필드의 의미를 바꿔 재사용하지 않는다.

## 기존 세이브

이번 문서 개편은 DB migration이나 데이터 삭제가 아니다. 기존 verified 저장의 필드·hash·version을 변경하지 않는다. 삭제된 모드·MP를 사용하는 구판 캠페인은 구판으로 이어가거나 별도로 합의한 변환을 거쳐야 한다.

새 문서판과 DB schema version을 혼동하지 않는다. 실제 서버가 새 상태를 허용하는지 확인해야 한다. 특히 MP 필수 여부, 영구 프로필 검사, 종료 처리의 보상 의존성, 공개 수첩 입력 검증기를 확인한다. 가짜 빈 값으로 기존 검증을 통과시키지 않는다.

## 실제 연동 검증 범위

이 작업에서 Supabase·Render·수첩 앱의 실행 도구가 제공되지 않았다. 문서의 함수·프로젝트 식별은 기존 계약에서 유지한 것이며 실시간 존재/권한/호환성 확인 결과가 아니다. 실제 새 캠페인 전체 payload의 pending → verify → 동일 version read-back → 새 채팅 복원은 별도의 연결 환경에서 검증해야 한다.

## 플레이 개선판 적용

최신 ZIP의 sources 10개와 PROJECT_INSTRUCTIONS를 함께 교체한다. 새 게임은 최신 START_GAME 양식에 필수 시드 두 개·인원·인지도·규모를 입력한다. 배제할 세계관·직접 지정·사전 관계는 비워 두면 자동 `없음`이다. 이미 시작한 캠페인은 새 게임 입력으로 재생성하지 않는다. 기존 규칙판·참가 슬롯·확정 세계·진행 대기를 먼저 확인한다.

프로필 표시를 간소화해도 이미 존재하는 사람·약속·관계나 PC가 정한 성향을 지우지 않는다. 기존 verified 프로필 원문/hash는 보존한다. 진행 중 캠페인의 연출·업무 압축 개선은 현재 사실을 보존하는 범위에서 적용할 수 있으나, 삭제한 모드/자원을 쓰는 세이브의 변환은 별도 호환 확인이 필요하다. 이번 피드백 로그에는 삭제 대상 자원이 남아 있어 최신 문서가 실제 세션에 적용됐다고 확인할 수 없다.

이미 30턴을 넘겼다면 과거 턴을 재연하거나 설정을 뒤집지 않는다. 현재 사실·NPC 목적·약속에서 다음 접촉과 가능한 선택을 복구한다. 실제 기존 인과가 없는 새 사건을 과거부터 있었던 일로 추가하지 않는다.
