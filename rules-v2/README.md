# 룰북 v2 색인

AI 키퍼가 읽는 룰북이다. 항상 읽는 지침은 `PROJECT_INSTRUCTIONS.md`, 나머지는 필요할 때 해당 파일만 연다. 수치·계산·저장은 엔진 담당이며 엔진 명세는 trpg-engine `docs/spec/`에 있다. 결정 근거는 `docs/restructure/DECISIONS.md`.

| 파일 | 이럴 때 연다 |
|---|---|
| `PROJECT_INSTRUCTIONS.md` | 항상 (ChatGPT 프로젝트 지침으로 등록) |
| `00-vision.md` | 게임의 목표, 원칙, AI와 엔진의 역할이 헷갈릴 때 |
| `01-source.md` | 장르, 원작 후보, 원작 분석서, 원작 반영(교차형), 시작 브리핑 |
| `02-scenario.md` | 시나리오 뼈대, 진상 3층, 위협과 시간 창, 사건, 개인 이해관계, 최종장 열쇠, 분량 목표 |
| `02a-scenario-example.md` | 공동 기점·비틀기·작은 당근·개인 사정을 실제 제출 형태로 쓴 모범 예시 |
| `03-characters.md` | PC 생성, 이름, NPC 정본과 행동, 적 정본 |
| `04-play.md` | 한 턴의 흐름, 장면 쓰기, 카메라와 공동 행동권, 빈 시간 금지, 선택지, 이야기 기록과 재개 |
| `04a-scene-examples.md` | 장면 분량과 문체의 실제 예시 |
| `05-checks.md` | 판정, 보너스·패널티, 부상·죽음·구출, 치료, SAN, 전투, 추격·은신, 위해, 소지품 |
| `06-ending.md` | 종결 조건, 엔딩, 기록실 |

보류(나중 확장): 본부, 카드·장기 성장, 연대기, 지도·이미지, 3인 초과.

## 설치·재개

[최신 MCP v2 룰북 ZIP 다운로드](https://github.com/gusghdkrl-dotcom/TRPG-RULE/raw/refs/heads/docs/restructure-decisions-20261122/dist/TRPG-RULE-v2-project.zip)

`PROJECT_INSTRUCTIONS.md`를 프로젝트 지침에 복사하고, 같은 ZIP의 나머지 v2 Markdown을 프로젝트 소스로 교체한다. 실제 설치·재개 순서는 ZIP의 `UPLOAD_GUIDE.txt`에 있다. 구판 `rules/`·START_GAME·정본 템플릿을 함께 실행하지 않는다. v2의 작성 폼은 연결된 엔진의 도구 스키마와 `keeperNext`다.

MCP 앱이 연결되어야 도구를 쓸 수 있다. 기존 게임은 현재 `requestId`로 재개하며 과거 사건·시트·정본을 재생성하지 않는다. 룰북 교체는 진행 중 세계의 자동 리뉴얼이 아니다. `RULESET.json`/`RULESET.md`는 배포 출처, `SHA256.json`은 파일 바이트 확인용이다. 과거 판본 고정을 재개 조건으로 요구하지 않는다.
