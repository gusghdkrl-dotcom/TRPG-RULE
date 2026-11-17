# TRPG-RULE

**현재 정본 — 생존 호러 안정화판 2026-11-17.** 프로젝트 지침·시작 입력·룰북 10개가 실행 정본이다. 본부 ON은 본부/영구 카드·성장, OFF는 일반 게임이다. 기본 ON, 인원 1~3명이며 게임 앱/서버를 새로 만드는 프로젝트는 아니다.

이번 안정화는 모든 PC의 각 E 현장 직접 체험 → 모든 E 이후 최종 국면, 원격 기여 불인정·E 위기 발생 보장·조기 종결 없음으로 통일했다. 비PC HP0 즉사, SAN0 게임 오버, 전멸 무보상과 카드/판정 순서를 명확히 했다. 기존 캠페인은 당시 검증 판본과 확정 결과를 보존한다.

신규 PC HP는 `floor((최종 CON+최종 SIZ)/10)+2`, SAN은 SAN_CORE, HUD는 BOTTOM_HUD_CONTRACT의 고정 행 순서다. Scene Turn 40/80/120… 자동 저장과 20턴 정본 재독을 구별한다. 본부 ON 챕터 종료도 귀환용 terminal 저장을 사용한다. 정확한 신규 저장 판본은 ZIP의 `RULESET.json`이며 날짜 표제만으로 구별하지 않는다.

[안정화 항목별 처리 기록](docs/RULEBOOK_STABILIZATION_2026-11-17.md) · [이전 README 이력](docs/archive/README-release-notes-through-2026-11-16.md). 운영 본부 마이그레이션 설치 기록은 docs/sql/release/README.md에 있으며 이번 작업에서 운영 DB/API·실제 캠페인 플레이를 실행하지 않았다.

이번 생성 보완은 정본 초안/최초 STATE를 검토보다 먼저 만들고 실제 상태로 준비 완료를 판단한다. 추적·지속 압박, 경비·수호, 배회·순찰을 담당할 충분한 실제 적 전력을 초기부터 구성하며 인간 적대자도 포함할 수 있다. 최초 상태·E/최종 경계·진실의 실제 필요성·위해/회복/자원·NPC/사이드 후속·인계와 보상 소진을 같은 생성/진행/저장 흐름에 연결했다. [원인·항목별 조치와 검증 범위](docs/GENERATION_HANDOFF_REVIEW.md).

## 설치와 교체

**[최신 프로젝트 ZIP 다운로드](https://github.com/gusghdkrl-dotcom/TRPG-RULE/raw/refs/heads/main/dist/TRPG-RULE-project.zip)**

별도 신규 캠페인: **[SCREAM_survival_rebuild_project.zip 다운로드](https://github.com/gusghdkrl-dotcom/TRPG-RULE/raw/refs/heads/main/dist/SCREAM_survival_rebuild_project.zip)**. 사용자가 이 패키지만 예외로 공개 승인했다. 범인·숨은 설정을 포함하므로 플레이어는 먼저 PLAYER_BRIEFING.md를 확인한다. 공통 룰북 ZIP과 별도이며, 기존 캠페인 정본/진행을 교체하는 세이브가 아니다.

1. ZIP의 PROJECT_INSTRUCTIONS.md를 프로젝트 지침에 복사한다.
2. 기존 게임용 룰북 소스를 제거/교체하고 sources의 **10개 Markdown(00-index~09-cards)**을 등록한다. 구판·개발 문서·삭제된09-notebook을 함께 남겨 검색이 섞이지 않게 한다. 실제 캠페인 비공개 정본은 별도로 보존한다.
3. RULESET.json과 읽기용 RULESET.md도 같은 ZIP에서 함께 보관/등록하고 START_GAME.md로 새 게임을 준비한다. 첫 항목은 **시간요원 본부 ON/OFF**다. ON이면 인원 1~3·요원별 닉네임을 먼저 확정하고 본부 입단으로, OFF이면 기존 일반 게임의 인원·인지도·대사건/연대기 설정으로 간다. 시작 시드는 실제 Python 자동 생성이다.
4. 기존 게임은 새 설정을 실행하지 말고 저장본이 지정한 정본과 누적 상태로 복원한다. 확정된 세계/PC/성과·구판 세이브를 소급 덮지 않는다. 규칙 전환은 STATE_COMPATIBILITY를 따른다.

ZIP에는 실행 지침·시작 입력·게임용 소스·업로드 안내·RULESET.json/RULESET.md·SHA256.json과 **본부 공식 NPC 8장 PNG/manifest.json**을 포함한다. 개발 일지/검토/과거 자료·실제 캠페인 비밀/세이브/인증 정보는 포함하지 않는다. 파일 업로드·프로젝트 도구 지원 여부는 실제 클라이언트 환경에 따른다.

**기존 프로젝트의 독립 재시험:** GitHub main이나 ZIP이 바뀌어도 이미 업로드된 프로젝트 파일·이전 채팅의 정본/세이브는 자동 교체되지 않는다. 지침/룰북/START_GAME과 배포 메타데이터를 같은 새 ZIP으로 교체하고 구판 실행 소스·요약이 섞이지 않게 한다. 비공개 캠페인 원본은 보존한다. 새 세계 테스트는 새 campaign/session으로 생성하며 기존 세이브를 로드하지 않는다. 기존 캠페인 재개는 반대로 해당 저장 판본으로 복원한다. 같은 원작·같은 시드도 이전 세계를 자동 재사용할 근거는 아니다. 실제 생성 입력과 판본을 확인하지 못한 과거 반복의 원인을 저장 스키마나 난수 하나로 단정하지 않는다.

채팅을 옮길 때는 `지금 입력 대기 지점 그대로 저장하고 검증 결과와 이동표를 줘`라고 요청한다. 새 채팅은 이동표의 정확한 session/version/SHA·정본·당시 룰북판으로 마지막 질문/판정을 복원한다. 작은 기억/약속·실물 위치·인물별 체험도 저장 대상이다. 파일 인계에는 전체 STATE+정본+판본 정보가 필요하다. [저장·파일 보관·새 채팅 로드 절차와 요청 예](docs/STATE_FLOW.md#다른-채팅으로-옮기는-방법)를 따른다.

## 유지한 기능과 현재 경계
+
+- 원작 확인·PC별 생활/관계·유한 적과 사전 적 풀·실재 지도/물품·자율 NPC·선택적 생활/S는 04-setup의 단일 설계 본문을 따른다. PC의 이동·수락·감정/추리는 대필하지 않는다.
+- 카드66장(자산33/강화33), 성장8종·4슬롯과 기존 개별 효과를 유지한다. 추가 피해/경감 순서와 보너스 상쇄·사용 제한은 09-cards를 따른다.
+- 비PC HP0 즉사와 PC 구조형 HP0을 구별하고, SAN0은 게임 오버다. 전멸에는 새 보상을 주지 않는다. 실제 안전·방어/구조·무상처 생존은 보존한다.
+- 인벤토리 실물명·수량/점유를 매 일반 HUD에 표시한다. 장착품도 점유하며 상시 카드4칸은 표시하지 않는다. [현행 HUD 참고](docs/HUD_PREVIEW.md).
+- 본부 ON의 현지 종결은 제이든 귀환 대화·마틴 평가를 거친다. 다섯 후일담은 클라라에게 직접 요청할 때 한 편씩, 보상은 적격 승인 후 도미닉에게 실제 요청할 때 처리한다. OFF의 엔딩/후일담 순서는 06-play를 따른다.
+- 정본·세계 변화와 PC별 실제 지식·행동권·말투/합의·마지막 대화/판정 대기를 함께 저장·복원한다. 기존 캠페인을 새 생성 기준으로 재설계하지 않는다.
+
+## 도구·저장과 검증 범위

PC d100은 플레이어, 그 밖의 실제 무작위는 Python 실행을 사용한다. 실제 입력 폼이 없으면 채팅 입력으로 진행한다. 룰북은 클라이언트에 없는 입력/검색/파일 기능을 만들지 않는다.

저장 수단은 **Supabase `trpg-state-v2`의 비공개 정본 전문(`trpg_private.gm_canon_documents`) + 검증된 동적 체크포인트(`public.gm_checkpoint_history`, DOCUMENT_BOUND/DB1) + 소유자에게 전달하는 동일 원문 .md 파일**이다. 게임 정상 저장·복원에서 GitHub 자동 미러·비상 세이브를 생성하지 않는다. 신규 Supabase project ref는 `taoaffdyssqtnjszumpq`이고, 서버 RPC와 정확한 호출/검증/복원 계약은 [07-state](rules/07-state.md)의 STATE_CANON_SAVE_BINDING·STATE_COMMIT에 있다. [DB V2 재구축 SQL](docs/sql/trpg-state-v2.sql)은 구형 DB를 복제하지 않고 독립 구축하기 위한 이력이며, [신규 비공개 정본 테이블 SQL](docs/sql/trpg-private-canon-v1.sql)은 개정 저장 구조를 기록한다. 신규 DB에서 합성 2버전의 commit→verify→같은 version exact read-back/SHA, 부모충돌 차단, 중복attempt 재생, 필수문맥·coverage 거부와 권한 제한을 검증했으며 테스트 저장본은 제거했다. 신규 비공개 정본 테이블에서 합성 문서 insert/전체 원문·SHA read-back 및 접근 차단을 확인했다. 실제 캠페인의 새 정본 저장/장기재개 결합은 신규 게임에서 검증해야 하며, 과거 GitHub 백업은 삭제하지 않고 신규 자동 미러만 중단한다. 차단/실패는 완료라 하지 않고 현재 확인 가능한 플레이는 계속한다. 20턴 정본 재독과 신규 **40턴 간격 저장 경계**를 적용하고 같은 원문/상태를 재사용한다. 구 30턴 예약은 호환 규칙에 따라 처리한다.

검증 명령:

```bash
python3 scripts/rulebook.py check
python3 scripts/rulebook.py stats
python3 scripts/test_python_random.py
python3 scripts/test_stat_generation.py
python3 scripts/test_resume_semantics.py
python3 scripts/test_rulebook_contract.py
python3 scripts/test_four_layer_scenarios.py
python3 scripts/check_hq_release_contract.py
python3 scripts/test_compare_hq_db_baselines.py
python3 scripts/rulebook.py export
git diff --check
```

[대표/경계 사례](docs/REVIEW_CASES.md), [원작별 합성 설계/분기](docs/INTEGRATED_SCENARIO_REVIEW.md), [361개 이전ID 대응](docs/rule-reorganization.json), [최초403개 원문 대응](docs/rule-migration.json), [담당ID 카탈로그](docs/RULE_CATALOG.md), [개발 일지](DEVLOG.md)를 제공한다. 정적 검사·합성 JSON 왕복은 실제 ChatGPT 장기 플레이·외부 저장 왕복·응답시간·재미/몰입의 실측이 아니다. 특정 응답시간이나 무손실 기억을 보장하지 않는다.
