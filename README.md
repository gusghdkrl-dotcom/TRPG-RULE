# TRPG-RULE

AI 키퍼가 원작 테마에 맞는 세계를 만들고, 플레이어가 PC의 선택과 탐험을 진행하는 공포·미스터리·스릴러 TRPG 규칙이다. 비공개 세계 상태는 Supabase의 검증된 전체 Checkpoint로 보존하고 새 채팅에서 복원한다.

현재 판은 **2026-10-29 플레이 개선판**이다. 아르카나·장기 생존·캠페인 간 영구 성장·MP·소설화를 제거했고, 일반 생존 판정·캠페인 내부 기능 성장·연대기는 유지한다. 세계 법칙은 원작의 정수와 테마를 살리는 최소 2개다.

## 사용

**[최신 게임용 ZIP 다운로드](https://github.com/gusghdkrl-dotcom/TRPG-RULE/raw/refs/heads/main/dist/TRPG-RULE-project.zip)** — 이 주소는 유지하며, 룰북 패치 때 같은 파일을 갱신한다. 압축을 풀고 아래 순서대로 설정한다. GitHub 변경이 기존 ChatGPT 프로젝트에 자동 반영되지는 않으므로 프로젝트 파일도 교체해야 한다.

START_GAME 양식에서 **핵심 시드·시작 시드(각 1~100), 인원(1~3명), 인지도, 이야기 규모, 배제 세계관(없으면 없음)**을 직접 입력한다. 장르/오마주/시대와 PC 사전 관계는 선택 사항이다. 키퍼는 누락 항목만 묻고 대기하며, 인원만 받았다고 원작 후보를 생성하지 않는다. 설정 전체 확정 → 원작 A~F 선택(또는 직접 지정) → 전원 PC 생성 → 세계 생성 순서다.

1. [PROJECT_INSTRUCTIONS.md](PROJECT_INSTRUCTIONS.md)를 프로젝트 지침에 넣는다.
2. [rules/00-index.md](rules/00-index.md)와 `rules/01-core.md`부터 `rules/09-notebook.md`까지의 **현재 파일 10개**를 프로젝트 소스로 올린다. 이전 TXT·구판·개발 문서와 함께 올리지 않는다.
3. 연결된 Supabase의 실제 프로젝트/함수 권한을 확인한다. 저장 절차는 [상태 문서](rules/07-state.md)에 있다. 공개 수첩 연결은 선택 사항이다.
4. [START_GAME.md](START_GAME.md)를 채팅에 입력한다. 시작 설정 확정 → 원작 A~F → 전원 PC → 세계 → 최종 프로필 → 설정 저장 검증 → 게임 시작 순서다.

문서 업로드만으로 규칙의 정확한 조회나 저장 API 호출이 보장되지는 않는다. 필수 저장 경계마다 실제 verify/read-back 결과가 있어야 한다. 이번 작업에서 문서 검증은 수행했지만 **Supabase·수첩 서버의 새 규칙판 호환 및 실제 저장/복원은 미검증**이다.

이번 개선판은 원작 특징의 실제 세계 구현, 실패·방치·도주의 중대한 대가, 첫 업무 완료 뒤 사건 연결, 30턴 안의 본격 사건 입구, 목적 단위의 작업 처리와 일반 응답 경량화를 적용한다. 20초 응답은 목표이며 실제 성능은 아직 측정하지 않았다. [속도 측정 및 다음 개선 단계](docs/RESPONSE_TIME.md)를 참고한다.

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

export는 GitHub 배포용 `dist/TRPG-RULE-project.zip`을 갱신하고, 로컬용 `build/TRPG-RULE-project.zip`과 `build/project-pack/`도 생성한다. `sources/`의 10개 파일만 프로젝트 소스로 올리고, 지침과 시작 입력은 별도로 사용한다. 개발 일지·변환 감사·구판은 묶음에 포함하지 않는다. ZIP 손상과 manifest의 SHA-256을 검사하며, 같은 입력으로 다시 생성하면 같은 ZIP을 만든다.

## 편집

규칙은 담당 문서의 한 절에서 수정한다. ID는 버전과 독립적으로 유지하고 다른 문서에는 링크를 쓴다. 수치·상태·예외를 바꾸면 관련 대표 사례와 검증 계약도 점검한다. 다음 판을 기존 규칙 뒤에 Override로 누적하지 않는다.

사용자의 적용 지시가 있는 패치는 검증 후 이 저장소에 커밋·푸시하고 DEVLOG.md에 기록한다. 규칙 문서 변경과 운영 DB·수첩 앱 배포는 별개다. 실제 운영 자료를 지우거나 DB 스키마를 자동 변경하지 않는다.
