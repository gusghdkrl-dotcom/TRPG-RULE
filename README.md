# TRPG-RULE

AI 키퍼가 원작 테마에 맞는 세계를 만들고, 플레이어가 PC의 선택과 탐험을 진행하는 공포·미스터리·스릴러 TRPG 규칙이다. 비공개 세계 상태는 Supabase의 검증된 전체 Checkpoint로 보존하고 새 채팅에서 복원한다.

현재 판은 **2026-10-29 1차 정리판**이다. 아르카나·장기 생존·캠페인 간 영구 성장·MP·소설화를 제거했고, 일반 생존 판정·캠페인 내부 기능 성장·연대기는 유지한다. 세계 법칙은 원작의 정수와 테마를 살리는 최소 2개다.

## 사용

1. [PROJECT_INSTRUCTIONS.md](PROJECT_INSTRUCTIONS.md)를 프로젝트 지침에 넣는다.
2. [rules/00-index.md](rules/00-index.md)와 `rules/01-core.md`부터 `rules/09-notebook.md`까지의 **현재 파일 10개**를 프로젝트 소스로 올린다. 이전 TXT·구판·개발 문서와 함께 올리지 않는다.
3. 연결된 Supabase의 실제 프로젝트/함수 권한을 확인한다. 저장 절차는 [상태 문서](rules/07-state.md)에 있다. 공개 수첩 연결은 선택 사항이다.
4. [START_GAME.md](START_GAME.md)를 채팅에 입력한다. 원작 A~F → 전원 PC → 세계 → 최종 프로필 → 설정 저장 검증 → 게임 시작 순서다.

문서 업로드만으로 규칙의 정확한 조회나 저장 API 호출이 보장되지는 않는다. 필수 저장 경계마다 실제 verify/read-back 결과가 있어야 한다. 이번 작업에서 문서 검증은 수행했지만 **Supabase·수첩 서버의 새 규칙판 호환 및 실제 저장/복원은 미검증**이다.

## 파일 역할

| 경로 | 용도 |
|---|---|
| `PROJECT_INSTRUCTIONS.md` | 항상 적용할 키퍼 지침 |
| `START_GAME.md` | 새 캠페인 시작 입력 |
| `rules/` | 게임 실행 정본·검색 색인 |
| `docs/RULE_CATALOG.md` | 개발용 전체 규칙 목록 |
| `docs/rule-migration.json` | 이전 주 룰북 403개 블록의 이동·통합·삭제 기록 |
| `docs/REVIEW_CASES.md` | 대표 상황의 문서상 결과 대조 |
| `docs/DECISIONS.md` | 확정한 방향과 다음 설계에서 판단할 항목 |
| `docs/PLAY_OPTIONS.md` | 프로젝트 방식과 대안 비교 |
| `docs/MIGRATION.md` | 구판 교체·기존 세이브·서버 연동 주의점 |
| `DEVLOG.md` | 변경 이유·내용·검증 결과 |

## 문서 검증과 업로드 묶음

Python 3 표준 라이브러리만 사용한다. 저장소 루트에서:

```sh
python3 scripts/rulebook.py check
python3 scripts/rulebook.py stats
python3 scripts/rulebook.py export
```

export는 `build/TRPG-RULE-project.zip`과 `build/project-pack/`을 생성한다. `sources/`의 10개 파일만 프로젝트 소스로 올리고, 지침과 시작 입력은 별도로 사용한다. 개발 일지·변환 감사·구판은 묶음에 포함하지 않는다.

## 편집

규칙은 담당 문서의 한 절에서 수정한다. ID는 버전과 독립적으로 유지하고 다른 문서에는 링크를 쓴다. 수치·상태·예외를 바꾸면 관련 대표 사례와 검증 계약도 점검한다. 다음 판을 기존 규칙 뒤에 Override로 누적하지 않는다.

사용자의 적용 지시가 있는 패치는 검증 후 이 저장소에 커밋·푸시하고 DEVLOG.md에 기록한다. 규칙 문서 변경과 운영 DB·수첩 앱 배포는 별개다. 실제 운영 자료를 지우거나 DB 스키마를 자동 변경하지 않는다.
