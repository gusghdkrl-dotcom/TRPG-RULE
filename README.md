# TRPG-RULE

일반 ChatGPT 프로젝트 채팅에서 사용하는 한국어 AI 키퍼용 생존 호러 룰북이다. 별도 게임 앱/서버를 만드는 프로젝트가 아니다.

현재 판은 **생존 호러 통합 경량판 2026-11-08**이다. 인스트럭션은 스토리 진행·실제 위협·선택·페이싱을 우선하고 공간·행동·대사·감각의 구체적인 서술 원칙을 상시 유지한다. 룰북은 상황별 수치/절차/예외를 담당한다. 원작 요소가 실제 접촉·생존·발견·목표 변화·큰 난관과 해결로 이어지도록 세계를 설계한다.

## 설치와 교체

**[최신 프로젝트 ZIP 다운로드](https://github.com/gusghdkrl-dotcom/TRPG-RULE/raw/refs/heads/main/dist/TRPG-RULE-project.zip)**

1. ZIP의 PROJECT_INSTRUCTIONS.md를 프로젝트 지침에 복사한다.
2. 기존 게임용 룰북 소스를 제거/교체하고 sources의 **9개 Markdown(00-index~08-visual)**을 등록한다. 구판·개발 문서·삭제된09-notebook을 함께 남겨 검색이 섞이지 않게 한다. 실제 캠페인 비공개 정본은 별도로 보존한다.
3. START_GAME.md로 새 게임을 준비한다. 필수는 인원1~3·인지도·대사건/연대기. 시작 시드는 실제 Python 자동 생성이다.
4. 기존 게임은 새 설정을 실행하지 말고 저장본이 지정한 정본과 누적 상태로 복원한다. 확정된 세계/PC/성과·구판 세이브를 소급 덮지 않는다. 규칙 전환은 STATE_COMPATIBILITY를 따른다.

ZIP에는 실행 지침·시작 입력·게임용 소스·업로드 안내·SHA256.json만 포함한다. 개발 일지/검토/과거 자료·실제 캠페인 비밀/세이브/인증 정보는 포함하지 않는다. 파일 업로드·프로젝트 도구 지원 여부는 실제 클라이언트 환경에 따른다.

## 이번 판의 주요 변경

- 상시 인스트럭션에서 보조 업무의 목적 단위 처리와 중심 사건 복귀 기준을 구체화했다. 사소한 확인마다 입력 대기를 만들지 않으며 지문·NPC 대사·HUD의 추리 평가/검증 안내를 금지한다. 중요한 선택·교류·협상과 실제 새 비용/위험은 보존한다.
- 세계는 대사건/연대기 규모의 중심 인과·주요 소재의 목적/중요성·실제 실행력 있는 위협·구체적 개입/해결/탈출과 조건부 진행 설계도를 갖춘다. 피해를 예약하지 않으면서 도달한 HP/SAN·상태 효과는 실제 처리한다.
- 원작/직업 후보4개, 배우 레퍼런스 필수, 전문 분야/특성 후보3개. 고정 태그·공명 후보·무료직업소품·의무 생활 흔적·완료작 이력 제외·다단계 필수 추첨을 제거했다. 기존 판정/전투 수치는 승인된 변경 외 보존한다.
- 반복 이동/회의/조사와 교대 확인을 압축하고 자연스러운 결과 경계/대기 순서로 PC를 전환한다. 고정30턴 사건 마감·3/5회 교대·A/B 이미지 대기는 제거했다.
- 인벤토리는 매 일반 턴 유지한다. 씬 요약·연출 의도 의무와 생활 버프, 공개 수첩 기능 전체는 삭제했다. 판정 내역은 실제 요구/양측 값/결과를1~2줄로 표시한다.
- 영구 스탯 성장은 연대기만. 일일 시작SAN20% 누적 손실·안전한 충분 휴식 하루1회1d3·실제 행동구간/라운드의 질식 처리를 명확히 했다. 수치 성장과 현재치 회복/실제 획득은 구분한다.
- 엔딩 뒤 Highlight Reel / The Silent Stage / Cast & Crew / The Hidden Truth / Ultimate Butterfly를 순서대로 한 출력씩 자세히 연출한다.
- 세이브는 정확한 현재값과 이야기의 연결·NPC 말투/태도/이유·공동 경험·마지막 대화/입력 대기·잔존 인과를 함께 보존/적용한다. [검토와 한계](docs/SAVE_CONTINUITY_REVIEW.md).

## 도구·저장과 검증 범위

PC d100은 플레이어, 그 밖의 실제 무작위는 Python 실행을 사용한다. 실제 입력 폼이 없으면 채팅 입력으로 진행한다. 룰북은 클라이언트에 없는 입력/검색/파일 기능을 만들지 않는다.

저장 수단은 기존 **비공개 프로젝트 정본 + Supabase 검증 체크포인트(DOCUMENT_BOUND/DB1), 인증된 비공개 GitHub 백업/비상본**을 유지한다. 운영 DB/함수/권한/앱을 변경하지 않았다. 신규 동적 맥락의 실제 수용/보존은 서버 계약과 read-back으로 확인해야 한다. 차단/실패는 완료라 하지 않고 현재 확인 가능한 플레이는 계속한다. 기존20턴 정본 재독·30턴 저장 경계는 유지하고 같은 원문/상태를 재사용한다.

검증 명령:

```bash
python3 scripts/rulebook.py check
python3 scripts/rulebook.py stats
python3 scripts/test_python_random.py
python3 scripts/test_stat_generation.py
python3 scripts/test_resume_semantics.py
python3 scripts/test_rulebook_contract.py
python3 scripts/rulebook.py export
git diff --check
```

[대표/경계 사례](docs/REVIEW_CASES.md), [원작별 합성 설계/분기](docs/INTEGRATED_SCENARIO_REVIEW.md), [361개 이전ID 대응](docs/rule-reorganization.json), [최초403개 원문 대응](docs/rule-migration.json), [담당ID 카탈로그](docs/RULE_CATALOG.md), [개발 일지](DEVLOG.md)를 제공한다. 정적 검사·합성 JSON 왕복은 실제 ChatGPT 장기 플레이·외부 저장 왕복·응답시간·재미/몰입의 실측이 아니다. 특정 응답시간이나 무손실 기억을 보장하지 않는다.
