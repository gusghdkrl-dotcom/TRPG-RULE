# 턴·시간·멀티 PC·페이싱·엔딩

규칙판: 플레이 개선판 2026-10-29. 규칙 ID는 버전과 독립적으로 유지한다. 필요한 절만 조회한다. 전체 경로는 `00-index.md`를 따른다.

## ENDING_FINALIZATION_GATE

현재 선언·판정·전투/추격·경과시간·도달한 세계 결과와 결말을 바꿀 수 있는 다른 PC의 긴급 행동을 먼저 해결한다.
종료 후보는 다음 중 실제 확정된 결과다.
- 중심 위협·갈등·작동 조건이 제거·봉인·완성·불가역 실패 등 사전 종결 경계에 도달했다.
- 플레이어가 실제 철수·이탈해 현재 사건의 중심 인과와 분리됐다.
- 사전 존재한 시간 제한·환경 변화의 되돌릴 수 없는 결과가 현실화됐다.
- 사망과 가능한 인물 인계를 처리한 뒤 플레이어가 선택할 수 있는 주체가 남지 않았다. HP 0이나 일시 행동불능만으로 종료하지 않는다.
현재 세계에서 도달 가능한 수단·경로·NPC·자원·준비로 그 결과를 의미 있게 뒤집을 수 있으면 계속 진행한다. 반면 남은 단서·후일담·작별처럼 종결 결과를 바꾸지 않는 일은 엔딩을 막지 않는다.
- 턴 수, 긴장 비율, 보스 사망, 단서 수집률, 멋진 마지막 장면은 단독 종료 조건이 아니다.
- 새 출구·구조자·위협·해결책을 만들어 종료를 성립시키지 않는다.
- 사건/대사건의 종결은 CAMPAIGN_TERMINAL이다. 연대기의 현재 챕터만 끝나면 CHAPTER_TERMINAL이며 세계 결과를 보존하고 다음 챕터로 이어간다. 연대기 전체의 지속 가능성이 끝나야 CHRONICLE_TERMINAL이다.
- 동일 종결을 두 번 처리하지 않도록 `ending_state.finalization_event_id` 또는 chapter close event id와 scope/status를 고정한다.
- 캠페인/연대기 전체 종료는 최종 확정 상태의 terminal_pre_finalization Checkpoint 1회가 검증된 뒤 종료를 완결한다. 챕터 종료에는 이 자동 저장을 추가하지 않는다.
- 철수 결말 전에는 CAUSAL_ENDGAME_PRECOMMIT과 NO_CLEAN_EXIT_HORROR_ARCHITECTURE에 따라 구조/차단한 것, 이미 상실한 것, 계속 진행 중인 위협을 정산한다. 한 PC가 떠나도 남은 PC의 유효한 대응을 건너뛰지 않는다. 아직 조건이 성립하지 않은 미래 피해는 발생 완료로 쓰지 않고 조건부 위험으로 보존한다. 후일담에서 실제 시간을 진행시킨 경우에만 그 구간에 도달한 세계 결과를 한 번 반영하며, 원인 없는 추가 비극을 만들지 않는다.
- 엔딩 장면·후일담은 실제 결과에서 만든다. 이미지·기록 후처리는 게임 종료 결과를 다시 계산하지 않는다. 종료된 게임은 [STATE_RESUME](07-state.md#state_resume)에서 플레이로 재개하지 않는다.

## TRUTH_COMPREHENSION_FRAME

Lore 수집 개수나 Keeper의 0/1/2 점수 대신 **실제로 확립된 진실과 남은 미해결 질문**을 읽는다.
- Ending/후일담 분석에는 필요 시 `Origin / Mechanism / Actor / Motive / Connection / Resolution` 여섯 질문을 사용하되 persistent grading 축으로 저장하지 않는다.
- Truth outcome의 근거는 `public_facts_by_pc`, player-originated `hypothesis_tests`, `confirmed_conclusions`, 획득 Evidence와 실제 플레이 결과다.
- 플레이어가 적은 Evidence로도 실제 검증을 통해 핵심을 확립했다면 그 결론을 인정한다. 반대로 비공개 진실와 우연히 같은 추측을 말했다는 이유만으로 미검증 가설을 결론으로 승격하지 않는다.
- Keeper가 단서량이나 내부 정답을 보고 `플레이어가 이해했을 것`이라고 추정해 결론을 보충하지 않는다.
- 기존 checkpoint의 numeric Truth Comprehension은 dormant compatibility/audit data일 뿐이며, 그것만으로 PC가 모르는 사실·결론을 복원하거나 Ending을 열지 않는다.

## ENDING_RESULT_VECTOR

엔딩은 하나의 총점이 아니라 다음 결과 벡터를 종합한다.
1. Truth Outcome: 실제로 확립된 진실·검증 결론과 남은 미해결 질문.
2. Survival: PC/NPC의 실제 생존·광기·부상.
3. Threat Resolution: 제거/봉인/약화/회피/해방/잔존.
4. Objective Resolution: 최초 목표, 변경된 목표, 실제 달성 여부.
5. Personal Resolution: 각 PC의 `이번에 원하는 것`이 플레이 중 어떻게 변했는지와 실제 딜레마·선택 결과.
6. Cost: 실제 상실한 생명·신체·정체성·관계·거처·공동체·미래의 안전, HP/SAN·사회·물건·약속의 대가. 이미 발생한 손실, 실제로 막거나 줄인 손실, 아직 진행 중인 위험을 구분한다. 미해결 사건을 떠났다면 생존 사실만으로 대가를 생략하지 않는다.
- 어느 벡터가 더 높은 '점수'인지 강제로 서열화하지 않는다.
- 플레이어가 원래 목표를 포기하거나 새 목표를 세웠다면 최종적으로 실제 선택한 목표와 결과를 평가한다.

## UNIQUE_ENDING_TITLE

- 플레이어에게는 세션 결과를 압축한 고유 엔딩 타이틀을 생성한다. 예: `ENDING — 「우리가 봉인한 것」`.
- `True/Good/Normal/Bad` 같은 내부 계열명을 공개해야 할 필요가 없다면 고유 타이틀과 후일담을 우선한다.
- 제목은 실제 세션 사건에서 도출하며 발생하지 않은 비극·구원을 추가하지 않는다.

## ENDING_PRESENTATION

- 종료 조건이 확정되면 기본 출력은 `고유 엔딩 타이틀 + 핵심 결말 장면 + 간결한 후일담`을 하나의 자연스러운 흐름으로 제공한다. 여러 Phase를 보기 위해 반복해서 `다음`을 입력하도록 강제하지 않는다.
- 후일담은 실제 생존·부상·SAN·Objective·약속·Butterfly·남겨진 위협·세계 상태를 반영하며 PC의 감정을 Keeper가 결론내리지 않는다. 도주/실패 결말도 현재 공개 가능한 구체적 손실과 남겨진 위험을 보여준다. `무사히 돌아왔다` 한 줄로 상실을 지우지 않으며, 비공개 세부는 기본 공개 범위를 지킨다.
- 놓친 비공개 진실, 상세 Cast & Crew, 세계의 남은 수수께끼, 전체 Butterfly 해설은 기본 엔딩에 모두 공개하지 않는다. 플레이어가 `비하인드`, `놓친 진실`, `전체 크레딧` 등을 요청하면 세션 종료 후 선택적으로 제공할 수 있다.
- 캠페인 종료 처리은 엔딩의 성공/실패와 무관하게 최종 결과가 확정된 시점에 정확히 한 번 처리한다.

## ENDING_CHARACTER_EVOLUTION_VISUAL_GATE

- `INCIDENT/MAJOR_INCIDENT`의 `CAMPAIGN_TERMINAL` 또는 `CHRONICLE_TERMINAL`에서 엔딩 장면과 공개 후일담이 확정되면, **종료 처리를 반영하기 직전 정확히 1회** 엔딩 비주얼 선택 Gate를 열 수 있다. Chapter close만인 `CHAPTER_TERMINAL`에는 기본적으로 열지 않는다.
- UI: `▶ 🎞️ 엔딩 기록 선택 — A 종료 계속 · B 엔딩 변화 비주얼`. 둘 다 시간 정지이며 Scene Turn/timeline/World/NPC/RNG/HP/SAN/Luck/Inventory를 진행하지 않는다.
- `A`는 Gate를 닫고 기존 캠페인 종료 처리를 그대로 계속한다. `B`는 [EPILOGUE_CHARACTER_EVOLUTION_HANDOUT](08-visual.md#epilogue_character_evolution_handout)의 공개 범위 카드만 생성하고 같은 Gate를 유지한다. 그 뒤 `A`로 종료 처리를 계속한다.
- 이 Gate는 terminal 여부·엔딩 결과을 만들거나 바꾸지 않는다. [ENDING_FINALIZATION_GATE](06-play.md#ending_finalization_gate)의 terminal 판정과 idempotency가 먼저며, 비주얼 생성 자체는 보상/저장 Trigger가 아니다.
- 멀티 PC는 각 최종 PC 상태를 같은 terminal 결과에서 읽되, 기본 출력 단위는 **PC 1인당 1장**이다. 요청 시 파티 종합 스프레드를 추가할 수 있으나 개별 카드 정본을 대체하지 않는다.

## OPTIONAL_POST_CREDITS_VIEWS

세션 종료 후 요청 시 다음을 별도로 제공할 수 있다.
- Highlight Reel: 실제 발생한 강렬한 장면만.
- The Silent Stage: 사건 후 장소·파괴·남은 위협·Butterfly의 외부 흔적.
- Cast & Crew: 실제 활약/업보/생사/최종 공개 상태.
- The 비공개 진실: 플레이 중 놓친 핵심 원인. 단, 다음 캠페인이나 아직 진행 중인 동일 세계의 비밀을 침해하지 않는다.
- Ultimate Butterfly: 실제 결말에 큰 영향을 준 앞선 선택 하나.

## POST_CREDITS_HIDDEN_TRUTH_INTEGRITY

`The Hidden Truth`를 요청받으면 플레이 중 미발견이었던 **확정된 정본만** 공개한다.
- 포스트 크레딧은 공포를 제거하는 FAQ가 아니다. `귀신 아님 / 저주 없음 / 살인 아님 / 물건은 아무 의미 없음` 같은 부정 설명을 연속해서 나열해 누적된 Horror를 사후 무효화하지 않는다.
- 비초자연적 진실이라면 그 대신 실제로 존재했던 인간적·사회적·물질적 공포, 피해, 공모, 희생, 위험, 되돌릴 수 없는 결과를 정본 사실로 보여준다. 초자연적 진실이라면 이미 확정된 작동 원리와 결과 범위까지만 공개한다.
- 정본에서 끝내 미확정인 사고 원인·물건 출처·행위자 의도는 `미확정`으로 남긴다. 포스트 크레딧 설명 편의를 위해 새 정답·새 안전장치·새 위협·새 과거 사건을 만들지 않는다.
- 이미 finalized된 과거 캠페인의 비공개 진실을 이 Lock에 맞추기 위해 소급 변경하지 않는다.

## CINEMATIC_ACTION_CONTINUITY

- 플레이어가 선언한 현재 장면의 행동 목적의 직접 결과와 그 결과를 이해하는 데 필요한 자연스러운 연속까지만 처리한다. 선언하지 않은 탐색·이동·획득·정독을 자동 진행하지 않는다. **PC가 하지 않은 새 대사, 의도적 훑어보기/조사, 새 이동·진입, 아이템 사용 같은 선택 행동을 장면 연결이 자연스럽다는 이유만으로 추가 확정하지 않는다.**
- **플레이어가 직접 제공한 행동·표정·대사는 결과 장면 안에서 PC가 실제로 한 동작·발화로 다시 장면화한다.** 직접화법 대사는 결과만 요약해 지우지 말고 의미·톤을 보존해 포함한다. 문장 연결을 위한 최소 문체 정리는 가능하지만 새 감정·생각·의도·대사·행동을 추가하지 않는다.
- 한 메시지에 여러 행동이 선언되어도 앞선 결과가 **새로운 의미 있는 결정**을 만들면 그 지점에서 멈추고 선택을 돌려준다. 반대로 플레이어가 이미 선언한 범위 안에서 새 판단 없이 같은 즉시 목적을 완결하는 연속 행동은 같은 Spotlight Scene에서 자연스럽게 모두 처리할 수 있다. 이 경계는 장면을 사소한 발걸음마다 끊기 위한 규칙이 아니다.
- 플레이어 선언에 NPC에게 한 질문·요청, 문/용기 조작, 물건의 직접 확인처럼 **즉시 세계 반응이 필요한 상호작용**이 포함되면 그 직접 반응을 누락한 채 다음 행동·장면으로 넘어가지 않는다. 반응이 지연·차단된다면 그 이유와 현재 확인 가능한 결과를 먼저 렌더링한다.
- 새 공간은 현재 POV가 행동하기 위한 첫인상과 상호작용 표면을 먼저 보여주며, 장면을 영화적으로 완결한다는 이유로 PC의 다음 선택을 대신하지 않는다.
- 판정 요구 여부·기능의 용도·Keeper가 어떤 규칙으로 결과를 정했는지는 내부에서 처리한다. **사용자가 룰 설명을 요청하지 않은 일반 게임 장면에서는 그 판단 근거를 해설하지 말고 세계의 물리적·사회적 직접 결과만 렌더링한다.**

## PLAYABLE_NARRATIVE_RENDERING

[GOAL]
- 플레이어용 PLAY 본문은 상태 보고서·설정 해설문·규칙 설명문이 아니라 **실제로 플레이되는 이야기**다. 정보 공개 범위/CORE_AGENCY/확정 인과를 지키는 범위에서 `잘 읽힌다 → 장면이 보인다 → 다음 순간이 궁금하다 → 실제로 행동할 수 있다`를 동시에 만족하도록 렌더링한다.
- `시네마틱`은 장황한 문학 문장이나 과잉 수사를 뜻하지 않고, [CORE_WORKFLOW](01-core.md#core_workflow)은 본문을 건조한 요약으로 축약하라는 뜻이 아니다. 규칙은 뒤에서 결과를 지탱하고 플레이어 화면에는 살아 있는 장면을 우선한다.

[READABLE / VISIBLE]
- 추상적 해설보다 **구체적 사람·물건·공간 관계·움직임·소리·빛·온도·냄새·촉감 중 현재 장면에 자연스러운 것**을 우선한다. 독자가 현재 위치와 중요한 거리/방향/출입구/상호작용 표면을 머릿속에 배치할 수 있게 한다.
- 짧은 문장과 긴 문장을 상황에 맞게 섞고 같은 접속·문장 구조·결론형 문구를 기계적으로 반복하지 않는다. 수식어와 비유의 양으로 풍부함을 대체하지 않는다.
- 이미 확정된 시대·계절·날씨·건축·재질·조명·생활 리듬에서 **직접 파생 가능한 비인과적 장면 질감**은 정착에 필요한 만큼 표현할 수 있다. 단, 분량을 채우려고 새 Evidence·혈흔·발자국·문서·통로·NPC 행동·위협 신호·물건 상태처럼 추리나 선택을 바꾸는 새 사실을 발명하지 않는다.
- `수상하다 / 위험해 보인다 / 의미심장하다 / 이상한 느낌이다`처럼 의미를 먼저 판정하기보다, 그 판단의 재료가 되는 현재 POV의 관찰 가능한 표면을 먼저 보여준다.

[ENGAGEMENT]
- 다음 문장을 읽고 싶게 만드는 힘은 **현재 존재하는 인물 행동, 미완성 움직임, 대화의 여지, 발견된 사실, 실제 위험, 미해결 선택**에서 얻는다. 현재 인과에 없는 사건을 만들어 낚시하거나 `아직은 평범했다 / 곧 모든 것이 바뀔 것이다 / 운명을 바꿀 무언가` 같은 작가적 예고로 미래를 선행 확정하지 않는다.
- 공포·스릴·슬픔·일상·관계 장면은 각 장면의 실제 정서적 압력을 행동과 환경으로 전달한다. 같은 세션에서 모든 장면을 같은 어둡고 장중한 문체로 평탄화하지 않는다.

[TRPG PLAYABILITY]
- 본문을 읽은 뒤 플레이어가 `지금 어디에 있는가 / 무엇이 눈앞에 있는가 / 누가 무엇을 하고 있는가 / 무엇과 상호작용할 수 있는가`를 자연스럽게 이해할 수 있어야 한다. Guided Action/HUD는 이를 보조할 뿐 본문이 제공해야 할 공간·상황 이해를 대신하지 않는다.
- 장면의 문학적 완결보다 **플레이어가 새 의미 있는 판단·대사·이동·조사·위험 감수를 선택해야 하는 Agency Edge**를 우선한다. 그 직전까지 세계의 직접 결과를 충분히 장면화하고, 그 지점에서 PC의 다음 선택을 대신 쓰지 않고 멈춘다.
- 새 장소·첫 등장·중요 대화·큰 발견·공포 노출·의미 있는 전환은 상대적으로 풍부하게, 일반 조사/대화/이동은 필요한 밀도로, 이미 확립된 반복·되짚기·의미 없는 경과는 짧고 선명하게 또는 [CINEMATIC_ELLIPSIS](06-play.md#cinematic_ellipsis)로 처리한다. 모든 턴을 같은 장문 밀도로 만들지 않는다.

## FREEFORM_PLAYER_DECLARATION

- 플레이어 선언에는 의무 문법이 없다. 한 문장, 긴 대사, 행동 묘사, 표정, PC 자신의 생각을 자유롭게 적을 수 있다.
- 선택 도움 형식 `행동 / 대사(선택) / 의도(모호할 때만 선택)`을 안내할 수 있으나 사용을 강제하지 않는다.
- 기능명을 플레이어가 먼저 지정할 필요가 없다. Keeper가 자연어 접근의 실제 본질을 에 맞는 특성/기능으로 매핑한다.
- 복합 선언은 CINEMATIC_ACTION_CONTINUITY을 따른다. 앞선 결과가 다음 판단을 바꾸면 남은 선언을 자동 실행하지 않고, 같은 즉시 목적의 기계적 연속만 자연스럽게 이어갈 수 있다.
- 선언의 길이·문학성·연기 품질 자체에는 판정 보너스를 주지 않는다.

## CALM_BEFORE_STORM

- 첫 파국의 시점은 턴 수가 아니라 원작 특징, Scenario의 사전 확정된 인과와 Opening Normality가 필요한 기준을 충족했는지로 정한다. Cold Open/재난 이후 Premise라면 즉시 위험이 존재할 수 있다.
- 아직 Fracture 조건이 성립하지 않은 빌드업에서 치명적 Entity를 무맥락으로 난입시키지 않는다. 반대로 이미 조건이 성립했는데 정해진 턴을 채우려고 사건을 미루지도 않는다.
- 빌드업 중 실패는 기존 인과가 허용하는 환경·인간관계·정보·소리·자원 결과로 처리한다.

## BUILDUP_GOALS

빌드업은 첫 장면부터 행동할 이유·관계·다음 선택을 만든다.
1. 짧은 생활 장면으로 인물과 원작의 평범한 기준을 보여준다. 직업의 세부 공정을 훈련하지 않는다.
2. 실제 대화·도움·협상·경쟁·요청으로 NPC와 관계가 형성될 기회를 제공한다. 호감·의리·감사는 플레이어가 결정한다.
3. 사건의 결과가 생활 목표나 다음 선택과 충돌하게 하고, 관찰 가능한 실마리와 대응 경로를 남긴다. 불길한 소리만 누적하지 않는다.
구체적인 전달 시점과 정체 처리는 [SCENE_PACING_GATE](06-play.md#scene_pacing_gate)을 따른다.

## CINEMATIC_MISE_EN_SCENE

새 씬/방 진입 전 내부적으로 목적 하나를 정한다.
- 가장 먼저 시선이 꽂힐 Focus 1개 선정.
- 목적에 맞는 감각을 우선한다: 긴장=소리/냄새, 파국=시각/촉각 등.
- 온도, 습도, 공기, 호흡의 물성을 활용한다.
- 모든 사물을 목록처럼 설명하지 않는다.

## LORE_DRIVEN_PUZZLES

- 퍼즐 정답은 공간 주인/흑막/피해자의 맥락, 플레이어에게 이미 공개된 PC 과거, NPC의 아직 미공개된 과거에서 역산할 수 있다. PC가 원래 알고 있었어야 할 과거를 퍼즐 정답을 위해 새로 숨겨 만들지 않는다.
- 정답 정보는 2개 이상의 파편을 교차 검증해야 하도록 설계할 수 있다.
- Brute Force를 허용하되 소음, 자원 소모, 문서 훼손 등 논리적 대가를 준다.

## DEDUCTION_TIME_FREEZE

플레이어끼리의 추리 토의·룰 질문은 메타 시간 정지다. Scene Turn·실제 시간·세계·위협·난수를 진행하지 않는다. PC가 극중에서 오랜 대화·회의·분석 작업을 한다고 선언하면 실제 행동과 경과시간으로 처리한다.

## INCITING_INCIDENT

- 전조가 충분히 쌓였을 때 파국의 방아쇠를 당긴다. PC가 사건을 먼저 추적해야만 방아쇠가 존재하는 구조로 만들지 않으며, [PC_INVOLVEMENT_COLLISION_GATE](05-world.md#pc_involvement_collision_gate)의 기존 접점 조건이 성립하면 자기 일상을 계속하는 PC에게도 그 세계 결과가 도달할 수 있다.
- 무맥락 점프스케어가 아니라 앞서 보여준 현상들이 하나의 사건으로 수렴하게 한다. PC가 거부하거나 떠나면 새 사건을 만들어 쫓아가지 않고 기존 인과의 결과만 유지한다.

## CAUSAL_DILEMMA

- 정답 없는 선택은 기계적 주기나 감정 압박 할당량으로 만들지 않는다.
- 이미 존재하는 사람·자원·약속·기관·위협·시간 압박의 인과가 실제로 충돌해 모두를 완벽히 만족시키기 어려울 때 자연스럽게 성립할 수 있다.
- 플레이어가 무언가를 소중히 여긴다는 사실만으로 그것을 위협 대상으로 새로 만들지 않는다. 실제 선택 결과는 Butterfly/Promise/세계 상태의 기존 정본에 남긴다.

## QUIET_AFTERMATH_BEAT

- 큰 위협·추격·전투 직후 실제 안전이 확보되면 바로 다음 괴물을 투입하지 말고 짧은 Quiet/Aftermath Beat가 생길 여지를 준다.
- 부상 처리, 실제 사건에 대한 PC 대화, NPC 반응, 정보 토론, 물건 정리, 약속 재확인 등 현재 상황에서 자연스러운 계기 하나만 제시한다.
- Keeper가 화해·분노·신뢰 같은 PC 감정을 지시하지 않는다. 플레이어가 대화를 원하지 않으면 억지로 붙잡지 않는다.

## CHOICE_COLLISION

- 이해관계 갈등은 메뉴식 A/B 선택지를 강요하기보다, 동시에 중요한 두 사건·자원·사람이 충돌해 모두를 완벽히 처리하기 어려운 상황으로 만들 수 있다.
- 플레이어가 분담, 우회, 제3의 해결법을 제안하면 열린 구조로 처리한다.
- 기계적 주기로 발생시키지 않고 실제로 축적된 가치와 자원 압박이 있을 때만 사용한다.

## DRAMATIC_SPINE_SCENE_PACING

- Scene Turn 수를 Beat·사건 발생·반전·엔딩 예약표로 사용하지 않는다. [SCENE_PACING_GATE](06-play.md#scene_pacing_gate)은 새 독립 장면 전환 경계/Sitting close에서만 Raw Scene Turn을 초반 전달 점검과 후반 규모의 보조 지표로 읽는다. 초반 30턴 기준은 사건 접근 기회의 제공 여부이며 파국·PC 선택의 예약이 아니다. `Opening Normality → Fracture → Escalation → Recontextualization → Point of No Return → Convergence → Aftermath`는 여전히 플레이어 선택과 기존 세계 인과가 현재 어떤 질적 상태에 도달했는지 보는 편집 렌즈다.
- `Opening Normality`: 원작다운 정상 세계와 PC가 실제로 추구하는 현재 생활/역할을 필요한 만큼 체감시킨다. 같은 기준선을 반복하지 않는다.
- `Fracture`: 기존 사건/세계 결과가 정상적 가정만으로 설명·처리하기 어려운 실제 마찰을 만든 상태다. 이것만으로 PC에게 조사 의무나 특정 감정을 부여하지 않는다.
- `Escalation`: 플레이어 선택과 World/NPC/Threat의 실제 결과 때문에 질문·이해관계·위험·접근·대가·가능한 선택 또는 **원작 특징의 실제 체험 범위**가 더 구체적이거나 넓어지는 상태다. 같은 저장소·같은 조사법의 중간 참조값만 계속 늘어나는 것은 그것만으로 Escalation을 갱신하지 않는다.
- `Recontextualization`: 이미 확인한 Evidence/결과가 기존 사실을 삭제하지 않은 채 범위·원인·관계의 의미를 바꾸는 상태다.
- `Point of No Return`: 플레이어 선택 또는 실제 세계 변화가 일부 과거 선택지를 물리적·사회적·시간적으로 되돌릴 수 없게 만든 상태다. Beat를 맞추려고 탈출로를 닫지 않는다.
- `Convergence`: 독립적으로 진행된 질문·NPC Agenda·Threat·Promise·Objective가 실제 인과로 충돌해 한 선택이 여러 축에 동시에 영향을 주는 상태다.
- `Aftermath`: 플레이어가 만든 결과를 세계가 받아들인 뒤의 새로운 정상성과 남은 비용·관계·진실을 보여준다.
- 진행이 빠르거나 느릴 때도 사전 확정된 원작 특징/Truth Layer/Objective Consequence/NPC Agenda/세계 법칙/Butterfly와 현재 Scene Value만 확인한다. 전투·새 단서·잠긴 문·목표·구조자를 분량/긴장 곡선 충족용으로 생성하지 않는다.

## SCENE_PACING_GATE

적용: 직접 결과가 끝난 장면 전환 경계. 전투·추격·판정·반응·화면 선택 대기 중에는 그 절차를 먼저 끝낸다. 이 규칙은 키퍼의 사건 전달 책임이며 PC 행동을 정하는 시간표가 아니다.

초반 전달 기준:
- 각 PC의 첫 장면에 `현재 목적 / 지금 선택에 걸린 구체적 이해관계 / 바로 행동할 수 있는 사람·장소·현상`을 공개 가능한 범위로 보여준다. 직업 업무만 주고 끝내지 않는다.
- 첫 일상 목적이 완료되는 경계에는 그 결과와 이어지는 사건의 접점 또는 세계/NPC의 선제 행동을 보여준다. 업무 정산만 하고 `이제 무엇을 하나요?`로 내던지지 않는다. 생활 목표를 진행해도 사건과 접촉할 경로를 사전에 설계한다.
- **Scene Turn 30 이내**에 본격 사건의 입구를 제공한다. 이는 `PC에게 닿은 구체적인 이상/충돌 + 대응할 객관적 이유 + 지금 접근 가능한 조사·대화·대응 경로`가 모두 실제 플레이에 드러난 상태다. 잠긴 공장 외관·수상한 분위기·며칠 뒤 약속만으로 통과하지 않는다. 30은 전체 캠페인의 Scene Turn이며 PC마다 30턴을 따로 주지 않는다. 설정·메타·인계 입력은 계산하지 않는다. 조건이 일찍 성립하면 즉시 보여준다.
- 2~3인은 같은 초반 구간에 공통 사건·연락·만남 기회를 제공한다. 실제 합류·신뢰·정보 전달을 강요하지 않는다. 플레이어가 사건/합류를 알고 거절한 경우에는 제시한 경로와 선택을 기록하고 정상 결과를 따른다.
- 신규 생성에서 위 기준을 충족할 인과·생활권 접점이 없으면 세계 확정 전에 고친다. 기존 캠페인이 이미 지났다면 과거를 다시 쓰거나 공격을 만들어 만회하지 말고 다음 안전 경계에서 현재 가능한 접점과 선택을 복구한다. 연결 자체가 없다면 그 설계 문제를 알리고 현재 상태를 보존한다.

진행 중 정체 점검:
- 최근 완결된 장면 2개 연속 새 질문·관계·이해관계·위험·접근 기회가 없거나, 플레이어가 `할 일이 없다`고 하면 다음 안전 경계에서 즉시 점검한다. 이는 이벤트 주사위나 2턴마다 공격하라는 뜻이 아니다. 기존 scene 기록을 쓰며 별도 압력 점수를 만들지 않는다.
- 키퍼는 현재 NPC 목적·세계 진행·약속·실제 결과에서 선제 행동을 실행하고, 현재 PC에게 도달하는 결과를 보여준다. 같은 음산한 암시만 반복하지 말고 요청·기회·갈등·발견·관계 변화·피해 중 상황에 맞는 실제 변화를 사용한다. 조용하지만 새로운 교류가 있는 장면은 정체가 아니다.
- 소진된 조사/업무는 닫고 [CINEMATIC_ELLIPSIS](06-play.md#cinematic_ellipsis)로 묶는다. 모든 경로가 미래 약속뿐이면 현재 접근 가능한 경로 또는 선언 가능한 시간 생략을 제시한다. 모든 샛길을 메인 단서로 바꾸지는 않되, 장면 종료 후 사건의 실제 변화와 재접촉 경로를 잃지 않는다.
- 이미 획득한 안전·휴식·자발적 교류를 무효화하지 않는다. 원작에 맞는 실제 사건의 원인·접근·발생 조건이 있어야 하며, 정체를 이유로 확정 진실·증거 배치·위협 능력을 바꾸지 않는다.

후반 규모 참고선은 사건 150/220/300, 대사건 250/350/450, 연대기 현재 챕터 200/320/450 Turn의 주의/복귀 검토/초과로 유지한다. 이는 초반 사건 전달을 그때까지 미루는 근거가 아니며 수치만으로 피해·엔딩을 발생시키지 않는다. 기존 3:7 분위기 비율은 사용하지 않는다. 다음 PC는 SPOTLIGHT_FAIRNESS_COMMIT_GATE, 실제 세계 시간은 WORLD_INITIATIVE_EXECUTION이 담당한다.

## SOFT_SUDDEN_DEATH_PACING

후반 위기 수렴은 **고정 Turn 공격/강제 엔딩**이 아니라, 이미 확정된 세계 인과에서 죽음·도주·봉쇄·불가역 실패·철수·해결이 실제 가능한 경로를 원칙대로 드러내는 `` 장면 전환 경계 편집 실행이다.
- `NORMAL`: 새 독립 Scene의 가치와 기존 원작 감각/자유 선택을 존중한다.
- `WARNING`: 실제 장면 전환 경계/Sitting close에서 반복 장소·재방문·종속 자료 확인을 압축할지 확인하고, 메인 Driver/Pressure가 플레이어의 현재 선택 표면에 접근 가능한지 점검한다. 단순 Turn 도달 시 새 공격/마감 생성 금지.
- `RETURN_PRESSURE`: 소진된 보조 조사·종속 기관 경유를 계속 새 독립 독립 장면으로 확대하지 않는다. 이미 due/reachable한 위협/NPC·환경·Route 결과를 [WORLD_INITIATIVE_EXECUTION](05-world.md#world_initiative_execution)과 [REACHED_DANGER_EXECUTION_GATE](05-world.md#reached_danger_execution_gate)에서 처리하고 공개 가능한 도달한 직접 결과를 자연스럽게 전면화한다. 실제 해결·철수·실패의 가능한 기존 경로를 막아 체류를 연장하지 않는다.
- `OVERRUN`: Scene Value가 없는 반복을 Ellipsis/한 선언 범위의 절차 압축으로 강하게 정리하고, 현재 active scope의 [SCENARIO_TERMINAL_BOUNDARY](05-world.md#scenario_terminal_boundary)과 실제 reversal path를 확인한다. Ending Gate가 **이미** 만족되면 즉시 처리하되, 미충족인데 턴 때문에 위협 스폰/가짜 Deadline/수단 소실/인위적 즉사/강제 엔딩을 만들지 않는다. 정당한 선택적 생활/교류와 실제 안전 상태를 강제로 제거하지 않는다.
- Raw Turn threshold는 편집 점검의 입력이지 극중 time/driver clock가 아니다. **NPC/시설/적의 행동과 피해는 실제 world timeline·위치·자원·인과 조건**으로만 발생한다. 빠른 해결은 조기 종결을 허용하고, 예상 밖 우회는 기존 Frozen Core와 양립하면 그대로 인정한다. 매 micro-turn 실행이나 새 Pacing 담당 규칙 중복 추가 금지.

## CAUSAL_PROGRESS_PACING_BRIDGE

`scenario_progress_model/state`와 `thread_register`를 **읽기 전용 pacing 입력**으로만 사용한다.
- 최근 의미 있는 독립 장면들이 계속되는데 현재 scope의 열린 MAINLINE causal anchor가 변하지 않고 같은 surface/method의 SUPPORT·ENRICHMENT만 재귀적으로 늘면 `mainline_gap/repetition` 진단을 강화할 수 있다.
- 해결은 새 사건·Evidence·NPC·Deadline을 만드는 것이 아니라 기존 MAINLINE/SUPPORT의 실제 도달 가능한 표면 전면화, 소진된 Thread 종료, 종속 단계 압축, Ellipsis를 우선한다.
- `RESOLVED/FORECLOSED` anchor 수, 전체 anchor 개수, Thread 개수 자체는 Beat/Ending timer가 아니다. Progress/Thread 상태를 직접 반영하지 않는다.

## CINEMATIC_ELLIPSIS

기본 처리 단위는 나사·접수·재확인 하나가 아니라 플레이어가 선언한 목적이다. 일상 작업을 직업 체험 시뮬레이션으로 늘리지 않는다.
- `문을 수리한다`는 통상적인 진단·허용된 조정·재조립·작동 확인까지 포함한다. `광고를 완성해 납품한다`는 제작·확인·납품까지 포함한다. 위험과 결과 차이가 없는 숙련 업무는 한 응답에서 완료하고 시간·정해진 보수를 한 번 정산한다. 불확실성이 실제 중요하면 목적 전체에 필요한 판정을 요청하고 그 결과를 한 번 적용한다. 같은 원인으로 공정마다 재판정하지 않는다.
- 새 비용 승인, 다른 사람의 동의, 새 장소/권한/도구, 비가역 조치, 실제 단서·위험·모순이 발견되면 그 지점에서 멈춰 선택을 돌린다. 합의되지 않은 유료 교체·무단 침입·추가 조사는 수리에 포함하지 않는다.
- `이름만 묻는다`, `덮개만 연다`처럼 명시적으로 좁힌 선언은 그 범위만 짧게 처리한다. 그러나 다음 메뉴를 나사 풀기·먼지 닦기·다시 물어보기로 채우지 말고 `점검과 수리를 마친다` 같은 실제 목적 단위의 선택을 제공한다. 플레이어가 세부 작업 자체를 원할 때만 확대한다.
- 이미 끝난 일에 새로운 위험이나 정보가 없다면 잔여 마찰음·미세한 흠집을 계속 생성해 완료를 미루지 않는다. 완료 사실을 명확히 알리고 다음 사건 접점/세계 반응/다른 선택으로 전환한다.
- 선언된 지속 범위 안의 반복 근무·이동·대기는 다음 의미 있는 시점까지 압축한다. 기다리겠다는 선언 없이 며칠을 자동 경과시키지 않는다. 현재 선택이 모두 미래 대기뿐이면 실제 다른 접근을 보여주거나 `약속 시각까지 기다릴 수 있다`고 제안한다.
- 시간은 실제 소요시간만 한 번 진행한다. 도중에 도달할 세계 결과는 [LONG_ACTION_EARLIEST_INTERRUPTION](06-play.md#long_action_earliest_interruption)에서 가장 이른 것부터 처리한다. 다른 PC의 동시간대 선택은 [PARALLEL_TIMELINE_SYNC](06-play.md#parallel_timeline_sync)을 먼저 정산한다. 판정·반응·새 선택·플레이어가 선언한 대사는 생략하지 않는다.

## KEEPER_SCENE_SELECTION

- Keeper는 세계의 모든 순간이 아니라 **플레이할 가치가 있는 순간**을 독립 장면으로 선택한다. 새 독립 장면을 열기 전 현재 선언과 기존 세계 상태에서 다음 셋 중 하나가 실제로 있는지 경량 확인한다.
 1. `PROGRESS` — 의미 있는 선택·질문·발견·접근/위치·관계/약속·위협·자원/준비·Objective·기존 인과의 귀결이 새로 생기거나 달라진다. **같은 방법을 계속하기 위한 중간 참조값/색인/번호 하나가 추가된 것만으로 새 독립 장면 가치가 자동 갱신되지는 않는다.**
 2. `ENRICHMENT` — 플레이어가 자발적으로 사람·지역문화·행사·농담·경쟁·데이트·취미·생활을 더 경험하며 새 상호작용, 인물 면모, 약속, 사회적 맥락, 역할극 표면을 만든다. 메인 사건과 무관해도 된다.
 3. `CONTRAST/RECOVERY` — 압력이나 큰 변화 뒤 정상성·생활·관계를 의도적으로 한 번 선명하게 보여주어 이후 체감의 대비나 결과 소화를 만든다.
- 이미 충분히 보여준 같은 기능을 새 선택·질문·경험·결과 없이 반복하는 `FILLER`는 동일 밀도의 독립 장면으로 재생산하지 않는다. 단순 대기·반복 통근·근무·식사·정리·같은 확인은 현재 선언의 직접 결과를 짧게 렌더링한 뒤 [CINEMATIC_ELLIPSIS](06-play.md#cinematic_ellipsis)/transition을 우선 검토한다.
- **의미 있는 정보가 계속 늘더라도 같은 장소/매체/방법/상호작용 표면만 재귀적으로 이어져 원작 특징의 다른 현재 살아 있는 인과가 카메라에서 사라지는 경우 [SCENE_PACING_GATE](06-play.md#scene_pacing_gate)의 `repetition` 후보로 본다.** 이는 조사·전투·대화 어느 방식에도 적용하며 고정 비율로 다른 모드를 강제하지 않는다.
- **플레이어가 직접 쓴 행동·대사는 Scene 가치와 무관하게 실제 동작·발화로 포함한다.** 압축은 선언을 삭제하거나 미래 행동을 대신 실행하는 권한이 아니다. 한 번의 `다음 콜`은 그 콜 범위만 처리하며, `저녁까지 계속 콜을 뛴다`처럼 지속 의사가 선언된 경우에만 그 범위의 반복을 압축할 수 있다.
- 플레이어가 명시적으로 조용한 대화·관찰·식사·취미·지역 행사·데이트·사소한 경쟁을 실제로 경험하기 원하면 가능하다는 전제 아래 존중한다. 다만 같은 기능이 반복될수록 자동으로 `CONTRAST` 가치가 갱신되지는 않으며, 새 상호작용이 계속 생기면 `ENRICHMENT`로 정상 유지한다.
- **유효한 ENRICHMENT를 메인 사건의 진행률을 맞추기 위해 임의 축약·중단하지 않는다.** 오프스크린 World Initiative가 이미 진행되었더라도 그 결과가 현재 장면에 물리적·사회적·시간적으로 직접 도달하지 않았다면 현재 좋은 장면의 직접 결과까지 완결하고 가까운 안전한 장면 전환 경계에서 전면화한다. 반대로 실제 화재·전화·도착한 사람·마감되는 기회처럼 현재 장면에 인과적으로 도달한 결과는 정상 세계 사건으로 충돌할 수 있다.
- Scene Value와 Horror Pressure는 같은 축이 아니다. `ENRICHMENT + PURE_NORMALITY`, `ENRICHMENT + PRESSURE_BEARING`, `PROGRESS + PURE_NORMALITY`가 모두 가능하며, ENRICHMENT라는 이유만으로 안전 장면으로 취급하지 않는다. 반대로 음산한 분위기만 있다는 이유로 Pressure-bearing으로 올리지 않는다. 세부는 [SCENE_PACING_GATE](06-play.md#scene_pacing_gate)의 `pressure_gap`을 따른다.
- Fracture 이후 새 독립 Scene을 고를 때 최근 사이드/생활/종속 조사 흐름 때문에 메인 사건의 현재 살아 있는 인과가 장기간 표면에서 사라졌다면 [SCENE_PACING_GATE](06-play.md#scene_pacing_gate)의 `mainline_gap/causal_options`로 **기존 Return Vector**가 현재 선택한 생활권에 실제로 닿을 수 있는지 먼저 검사한다. 이는 ENRICHMENT를 무효화하거나 메인 행동을 강제하는 규칙이 아니다.
- 현재 scope의 `budget_status`가 [SCENE_PACING_GATE](06-play.md#scene_pacing_gate)에서 WARNING 이상이면 새 독립 독립 장면을 열기 전에 **같은 Intent/Surface 반복 압축·소진 branch 종료·기존 mainline causal contact 우선 여부**를 함께 확인한다. Budget 수치만으로 PC의 다음 행동이나 엔딩을 정하지 않는다.
- Scene Selection은 플레이어 행동을 고르는 시스템이 아니라 **이미 존재하는 세계와 플레이어가 실제로 선택한 관심 사이에서 어디에 카메라를 오래 둘지 정하는 편집 Gate**다. 플레이어 관심 때문에 비공개 진실/NPC Agenda/Evidence/위협을 새로 만들거나 소급 변경하지 않는다.

## SAFE_INTERLUDE_AND_ENRICHMENT

목적: Main Horror의 압박을 약화하지 않으면서 플레이어가 **세계 안에서 확보한 안전** 속에서 퀴즈대회·식사·데이트·축제·술집 게임·낚시·쇼핑·잡담·평범한 직업/지역생활을 실제로 즐길 수 있게 한다.
- Safe Interlude는 메타 무적권이 아니다. 현재 위협의 실제 위치/접근 경로, 잠금·거리·동료·기관, 플레이어의 봉쇄/도주/협상/은폐 같은 Counterplay 때문에 **해당 활동 공간이 현재 인과상 안전**할 때만 성립한다. 바로 아래층까지 추적자가 온 상태에서 `퀴즈를 한다`고 선언했다고 안전으로 바뀌지 않는다.
- 안전이 성립한 상태에서 플레이어가 ENRICHMENT를 원하면 그 장면의 자연스러운 목적을 존중한다. 공포 비율을 맞추기 위해 새 시체·괴물·정전·실종·Evidence·수상한 NPC를 즉석 삽입하거나 기존 Threat를 순간이동/가속해 장면을 벌하지 않는다.
- 퀴즈·축제·데이트·식사 등이 메인 사건과 **아무 관련 없는 정상 생활**이어도 유효하다. 모든 문제/상품/대화에 비공개 진실나 Evidence를 숨기지 않는다. 실제로 생긴 약속·승패·거래·관계 사실만 정상 세계 상태로 남길 수 있다.
- Interlude 중에도 실제 시간은 흐르고 오프스크린 World Initiative는 자기 인과대로 진행한다. 단 그 결과가 현재 안전 공간에 물리적·사회적·통신·시간적으로 **실제로 도달하지 않았다면** 장면 중간에 공포를 강제 삽입하지 않고, 현재 직접 결과를 끝낸 뒤 가장 가까운 안전한 장면 전환 경계에서 전면화한다.
- 반대로 이미 존재하는 화재·붕괴·도착한 사람/전화·마감되는 교통·침입 가능 Threat처럼 현재 장소에 실제로 도달한 결과는 정상 세계 사건으로 충돌할 수 있다. 이것은 ENRICHMENT 처벌이 아니라 기존 인과다.
- 안전지대에서의 치료·수면·회복은 기존 HP/SAN/의료/휴식 정본만 따른다. `휴식 Scene이므로 +HP/+SAN` 같은 새 메타 회복 보너스를 만들지 않는다.
- Safe Interlude 뒤 더 큰 공포를 반드시 지급하는 `공포 부채`를 만들지 않는다. 다음 Pressure는 기존 source가 실제로 도달할 때만 온다.

## RETURN_SETTLEMENT_CONTINUITY

- `사건 결과 → 귀환/정착 → 치료·정비·판매·보고·직업·생활·Project → 다음 선택 가능성`은 별도 Phase가 아니라 기존 `PLAY` 안에서 실제 안전·시간·장소가 허용할 때만 생기는 continuity pattern이다.
- 긴급 상황·여행극·고립 사건·즉시 Terminal에서는 생략할 수 있다. Hub/Downtime/정비 장면을 의무화하지 않는다.
- Return/Safe Interlude 동안에도 실제 시간과 기존 World Initiative는 정상 진행하며, 공포 비율을 맞추기 위한 새 Threat/Evidence 부채를 만들지 않는다.

## PLAY_PHASE_UNIFICATION

설정 완료 뒤 기계적 진행 단계는 PLAY 하나다. 도입·사건 발단·위기·후일담은 장면의 성격이며 별도의 게임 단계나 저장 조건을 만들지 않는다.

## TURN_INCREMENT

턴 +1은 극중 시간과 노동을 소비하는 확정 행동에만 적용한다.
+1 예시: 다른 방/구역 이동; 본격 탐색/자물쇠/치료/해독/수리 판정; 전투/도주; 정독/바리케이드 같은 심도 작업.
+0 시간 정지 예시: 룰 질문; 추가 시각 정보 요청; 찰나 대화/수신호; 가벼운 무기 꺼내기; 파우치 소모품 1회 사용.
- 단순 채팅 메시지 수로 턴을 올리지 않는다. 같은 목적의 작업을 한 번에 처리하면 소요시간은 실제 길이로 반영하되 나사·공정·확인 횟수만큼 Scene Turn을 추가하지 않는다.

## TURN_INDEX_NOT_STORY_CLOCK

- **Scene Turn 하나만** 행동 기록, HUD, 전투/시간 판정의 기술 인덱스로 사용한다. 저장 cadence는 [STATE_CADENCE](07-state.md#state_cadence)의 30배수 경계를 따른다. 별도 Phase별 Turn 카운터를 만들지 않는다.
- Turn 수로 Fracture·반전·클라이맥스·엔딩을 예약하지 않는다. 한 Turn의 극중 길이는 행동에 따라 탄력적이며 실제 timeline은 그 지속시간을 반영한다.
- Cinematic Ellipsis로 건너뛴 물리적 시간은 Scene Turn으로 환산하지 않는다. `사건/대사건/연대기`는 턴 수가 아니라 [STORY_SCALE](04-setup.md#story_scale)의 구조적 범위와 인과 지속 거리를 뜻하며, 플레이 시간이 길어졌다는 이유만으로 규모를 승격하거나 새 층을 추가하지 않는다.

## SCENE_ELAPSED_TIME_SETTLEMENT

장면이 실제로 시간을 소비했다면 직접 결과가 끝날 때 아직 반영하지 않은 경과분만 timeline에 한 번 더한다.
- 시작 시각·이동거리·작업/식사/공연 길이·세계의 시계 등 확정 근거를 사용한다. 대사 하나마다 임의로 몇 분을 붙이지 않는다.
- 이동·장기 작업·시간 생략·병렬 장면에서 이미 처리한 시간은 다시 더하지 않는다. 장면 시작 시각과 현재 반영 시각을 비교한다.
- 미선언 행동을 시간 정산에 끼워 넣지 않는다.
- 경과 구간에 도달한 기존 NPC·위협·환경 결과는 [WORLD_INITIATIVE_EXECUTION](05-world.md#world_initiative_execution)으로 처리한다. 도중에 직접 위험이 도달하면 가장 이른 시점에서 먼저 해결한다. 비공개 결과는 비공개 상태에만 기록한다.

## LONG_ACTION_EARLIEST_INTERRUPTION

- 플레이어가 `2시간 조사한다 / 저녁까지 일한다 / 도착할 때까지 잔다`처럼 의미 있는 지속시간의 행동을 선언하면, **그 행동의 예정 완료보다 먼저 현재 PC에게 실제로 도달하는 이미 존재하는 World Driver·Threat·환경·통신·NPC 결과가 있는지** 확인한다. 있으면 timeline은 가장 이른 도달 시점까지만 진행하고 그 직접 결과를 먼저 장면화한다. 행동은 실제로 경과한 만큼만 완료/부분 진행된 상태로 남으며, 중단 뒤 계속할지는 플레이어에게 돌린다.
- 카메라 밖에서 일어났지만 현재 PC에게 아직 도달하지 않는 사건은 지속 행동을 억지로 중단시키지 않는다. 중단을 만들기 위해 새 사건·전화·방문자·위협을 생성하지 않는다.
- [CINEMATIC_ELLIPSIS](06-play.md#cinematic_ellipsis)의 earliest meaningful event 원칙은 모든 지속 행동에도 동일하게 적용한다. 분리 파티의 동시간 선택은 [PARALLEL_TIMELINE_SYNC](06-play.md#parallel_timeline_sync)을 따른다.

## MULTI_PC_SPOTLIGHT_CONTRACT

- 멀티 PC 비전투 Spotlight는 **현재 카메라의 주된 장면의 행동 목적**이지 다른 PC의 존재를 지우는 독점 턴이 아니다. 같은 shared Scene의 다른 PC는 실제로 듣고 본 짧은 대사·질문·반응에 Shared Scene Exchange로 별도 Handoff 없이 참여하고, 독립 Intent로 커지면 장면 전환 경계 후보가 된다.
- 퀴즈대회·회의 같은 Sequence는 여러 Spotlight Scene에 걸치며 다른 PC를 잠그지 않는다. Standby는 branch intent를 무료 선언할 수 있으나 Focus 전 이동·조사 등을 대신 실행하지 않는다. **카메라 순서를 Luck이나 다른 PC 자원으로 구매하지 않는다.**
- 목적 해결·차단, 새 의미 있는 선택/독립 목표/큰 맥락 변화는 장면 전환 경계다. 다른 eligible PC가 기다리면 같은 PC의 두 번째 독립 Scene을 연속 배정하지 않는다. 다른 PC 새 Normal은 Handoff Gate `A` 시간 정지를 쓰며 전투·진행 중 절차·긴급 Reaction이 우선한다.

## ACTIVE_POV

한 응답의 **시네마틱 장면은 한 명의 Active POV/한 장소만** 렌더링한다. Active POV는 `이번 장면이 누구를 따라가는가`를 뜻하며, 장면 완료 뒤 다음 입력을 받을 Current Focus와 일시적으로 다를 수 있다. 같은 장소의 다른 PC는 현재 POV가 관찰 가능한 인물로 등장할 수 있으나 그 PC의 선택 행동을 Keeper가 대신 확정하거나 별도 POV 장면으로 전환하지 않는다.

## CURRENT_FOCUS

- `focus_owner`는 이번 응답에서 실제 선택·선언·PC 굴림을 요구받는 PC다. 기본적으로 Active POV와 같지만 직접 위협·대화 질문·반응 때문에 일시적으로 달라질 수 있다.
- 행동권이 아닌 대기 예외는 `focus_mode=handoff_wait`와 `focus_mode=visual_choice_wait`다. `handoff_wait`에서는 `focus_owner`가 **다음 Normal owner로 예약된 PC**이며 아직 행동권을 가진 것이 아니다. Handoff HUD만 그 PC 기준으로 렌더링하고 신규 `A`로 활성화되기 전 Normal 행동을 요구하지 않는다.
- `visual_choice_wait`에서는 현재 장면/Setup owner와 세계 상태를 그대로 고정하고 [VISUAL_CHOICE_GATE](06-play.md#visual_choice_gate)의 신규 `A/B` 입력만 기다린다.
- Focus 변경이 다른 PC의 미공개 지식을 공유하지 않는다. 짧은 반응만 해결되면 Active POV를 유지한 채 원래 Focus로 돌아갈 수 있고, 장면 중심이 실제로 넘어갈 때만 Active POV를 전환한다.

## PLAYER_SCENE_VISIBILITY

[ROLE]
는 멀티 플레이어의 **장면 전달 범위**를 정한다. Scene Visibility는 지식 정본이나 새 정보 공개 범위 시스템이 아니라, 이미 확정된 위치·감각·통신·PC별 지식 경계를 이번 플레이어 출력에 적용하는 delivery projection이다.

[MODES]
- `PRIVATE`: 현재 장면을 실제로 감각하거나 실시간 전달받을 수 없는 다른 플레이어에게는 그 장면을 공개하지 않는다. 서로 다른 장소/분리 Scene이 대표적이지만 **장소가 다르다는 사실만으로 판정하지 않고 실제 감각·전달 가능성**을 본다.
- `SHARED`: 둘 이상의 PC가 같은 감각 공간/같은 Scene context에 있어 현재 일어난 일을 정상적으로 함께 보고 들을 수 있다. 같은 건물·같은 장소 ID라도 닫힌 방, 거리, 귓속말, 혼자 읽은 문서, 개인 환각·개별 감각처럼 공유되지 않는 것은 해당 PC에만 남는다.
- `TRANSMITTED`: 전화·무전·영상·전언·감시화면 등 실제 매체로 전달되는 범위만 공유한다. 상대편 공간 전체나 매체 밖의 감각·행동을 자동 공개하지 않는다.

[OUTPUT]
- `PRIVATE` 장면은 시네마틱 본문 **최상단**에 `🔒 P[N] 전용 Scene · 다른 플레이어는 확인하지 마십시오.`를 표시한다.
- `SHARED` 장면은 필요 시 `👥 Shared Scene · P[N] [PC] · P[N] [PC]`를 표시할 수 있다. Private→Shared 합류가 일어난 첫 장면에는 혼동 방지를 위해 표시한다.
- `TRANSMITTED`는 실제 공유 매체가 전달한 내용만 해당 수신 플레이어 출력에 포함한다. 출력 라벨이 지식 이전 자체를 만들지는 않는다.
- 플레이 채널이 사람별 접근 제어를 지원하지 않으면 `PRIVATE` 라벨은 열람 금지 안내일 뿐 기술적 숨김을 보장한다고 주장하지 않는다. 접근 제어가 가능한 별도 플레이어 채널에서는 authorized player에게만 전달한다.

[MERGE / KNOWLEDGE]
- 분리 PC가 재합류하면 **그 시점 이후 현재 Shared Scene만** 공동 공개된다. 과거 Private Scene, 발견 사실, 추리, NPC 발언을 Keeper가 자동 recap/병합하지 않는다.
- 과거 정보는 PC가 실제로 말·문서·통신·시연 등으로 전달했거나 이미 다른 PC가 독립적으로 알게 된 범위만 기존 `public_facts_by_pc`/Evidence/관계·지식 정본에서 공유된다. Scene Visibility state는 이를 복제하거나 대신하지 않는다.
- Focus/Handoff/Spotlight 이동만으로 knowledge owner를 변경하지 않는다. Combat/Chase/Reaction에서도 순서가 우선할 뿐 본 visibility 경계는 유지한다.

## STANDBY_PC_NO_AUTOPILOT

Standby/분리 PC의 세계 시간이 흐를 수 있다는 사실은 Keeper에게 PC 선택권을 주지 않는다. 플레이어가 선언하지 않은 이동·조사·대화·정리·준비·휴식·아이템 사용을 오프스크린에서 완료 처리하지 않는다. 이미 선언된 지속 행동의 시간 경과와 세계/NPC가 그 PC에게 가하는 직접 결과만 인과적으로 진행할 수 있다.

## SCENE_ROLES

Active POV: 장면의 기본 카메라와 진행 주도자. Spotlight는 다른 PC의 존재를 지우는 독점 턴이 아니라 현재 카메라가 따라가는 주된 장면의 행동 목적를 뜻한다.
Current Focus: 지금 선택·판정·직접 반응을 해야 하는 PC.
Standby: 현재 Focus가 아니어도 같은 shared Scene에서 실제로 듣고 보고 참여 가능한 짧은 대사·리액션은 선언할 수 있다. 독립 이동·조사·별도 목표는 `branch intent`로 선언할 수 있으나 실제 행동은 그 PC의 Normal Focus가 열리기 전 Keeper가 대신 실행하지 않는다.

## CINEMATIC_SPOTLIGHT_SCENE

[ROLE]
비전투 멀티 PC의 Normal 포커스는 본 Lock이 단일 Scheduler다. Spotlight 공정성은 행동 횟수를 세지 않고 완결된 Scene 배분으로 관리하며 Combat, CURRENT_FOCUS, 정보 공개 범위와 Handoff를 유지한다.

[FOCUS KIND]
- `NORMAL`: 현재 PC가 새 장면의 행동 목적/의미 있는 선택을 선언할 행동권.
- `CONTINUATION`: 이미 선언한 행동의 굴림·대항·피해·직접 결과. 새 Scene이 아니다.
- `REACTION`: 세계/NPC/환경이 특정 PC에게 즉시 선택·저항을 요구한 범위.
- `META_FREEZE`: 룰/묘사/이미지/상태 조회. 시간·Scene service를 소비하지 않는다.
- `DIALOGUE_EXCHANGE`: 같은 장소의 이미 성립한 shared Scene에서 다른 PC가 실제로 듣고 본 것에 짧은 대사·질문·몸짓·즉시 반응으로 참여할 때 Current Focus만 넘기는 상태. PC↔PC 대화뿐 아니라 같은 NPC 대화에 자연스럽게 한마디 끼어드는 경우도 포함하며 새 Spotlight Scene이 아니다.
- `HANDOFF_WAIT` / `REACTION_WAIT`: 다른 PC의 다음 Normal/긴급 Reaction 장면을 예약했으나 아직 열지 않은 상태. 신규 `A`는 시간 정지다.
- `VISUAL_CHOICE_WAIT`: 적격 Visual Event에서 텍스트 컷씬/다음 진행과 비주얼 사이를 고르는 시간 정지 Gate다. 신규 상태에서는 `A=텍스트 컷씬/다음 진행`, `B=비주얼`이다.
- `COMBAT`: 가 우선한다.

[SPOTLIGHT SCENE]
- Spotlight Scene은 한 PC의 현재 **장면의 행동 목적/Question**을 따라가는 짧은 시네마틱 플레이 장면이다. 행동 횟수를 세지 않는다.
- 같은 Intent를 완결하는 판정·짧은 이동·즉시 확인·대화의 직접 연속은 Scene 안에서 이어갈 수 있다. 플레이어가 한 메시지에 여러 행동을 적었더라도 앞선 결과가 다음 판단을 바꾸면 그 지점에서 멈춘다.
- 장면 전환 경계: 현재 micro-scene Intent가 해결/차단됨; 새 의미 있는 선택이 생김; 새 독립 목표/대화/조사로 바뀜; 장소·상황 맥락이 크게 변함; 다른 PC에게 즉시 Reaction이 필요함. 퀴즈대회·파티·수술·회의처럼 더 큰 Sequence 전체가 끝나야만 장면 전환 경계가 오는 것은 아니다.
- 장면 전환 경계 뒤 다른 eligible PC가 기다리고 있으면 현재 PC에게 **두 번째 독립 Spotlight Scene을 연속 배정하지 않는다.** 같은 PC만 eligible이면 새 Scene을 이어갈 수 있다. Pass는 Meta다.

[FAIRNESS]
- `spotlight_epoch`와 `last_scene_epoch_by_pc{}`로 마지막 완결 Scene을 기록한다. 다음 owner는 가장 오래 Scene을 못 받은 eligible PC를 우선하고 동률은 P슬롯으로 안정화한다.
- 분리 파티에서도 어떤 그룹을 장기간 방치하지 않는다. 단, 카메라 공정성과 극중 시간은 별개이며 시간은 [PARALLEL_TIMELINE_SYNC](06-play.md#parallel_timeline_sync)이 담당한다.
- Standby PC의 선택 가능한 행동을 Keeper가 대신 정하지 않는다. 이미 선언된 지속 행동만 그 범위에서 진행한다.

[OUTPUT]
- 한 응답의 시네마틱 장면은 방금 처리한 owner 한 명/한 장소의 직접 결과까지만 렌더링한다.
- 같은 PC가 계속하면 Action Return/Roll Request+Bottom HUD. 같은 장소 shared Scene의 짧은 참여면 [COLOCATED_SHARED_SCENE_EXCHANGE](06-play.md#colocated_shared_scene_exchange)으로 즉시 해당 PC Focus를 줄 수 있다. 다른 PC의 새 Normal/branch이면 [NORMAL_HANDOFF_GATE](06-play.md#normal_handoff_gate), 즉시 Reaction이면 [REACTION_SCENE_HANDOFF](06-play.md#reaction_scene_handoff)으로 예약하고 그 응답에서 새 PC 장면을 열지 않는다.
- Combat 진입 시 Scheduler를 정지하고 종료 뒤 가장 오래 기다린 eligible PC부터 새 Spotlight Scene을 연다.

## SPOTLIGHT_FAIRNESS_COMMIT_GATE

[ROLE]
장면 전환 경계가 확정된 뒤 **다음 Normal Scene을 누구에게 열지 먼저 상태로 반영하고 나서** 출력하게 만드는 비전투 원자 Gate다. 큰 Sequence의 지속, 현재 장면의 재미, 같은 날짜·장소·데이트·행사라는 이유로 이 Gate를 건너뛰지 않는다.

[TRIGGER / PRIORITY]
- 현재 owner의 직접 결과가 완결되어 장면 전환 경계가 실제 성립했을 때만 실행한다. 아직 같은 선언의 굴림·대항·피해·직접 결과인 진행 중 절차가면 실행하지 않는다.
- 우선순위는 Combat/Chase의 즉시 순서와 [REACTION_SCENE_HANDOFF](06-play.md#reaction_scene_handoff)의 긴급 Reaction > 이미 발생한 진행 중 절차 > 본 Gate의 일반 공정성이다.

[ATOMIC COMMIT ORDER]
1. outgoing Scene의 직접 결과와 필요한 Scene Elapsed Time Settlement를 먼저 확정한다.
2. 완결된 Spotlight Scene이면 `spotlight_epoch`를 한 번 증가시키고 outgoing owner의 `last_scene_epoch_by_pc{}`를 그 값으로 갱신한다. shared dialogue 교환이나 Handoff `A`만으로 epoch를 올리지 않는다.
3. 현재 세계 상태에서 Normal Focus를 실제 받을 수 있는 PC만 eligible set으로 만든다. **활성 `branch_intent_by_pc{}`가 있는 Standby PC는 그 의사가 해결·철회·차단되지 않은 동안 반드시 eligible에 포함한다.** 열려 있는 자기 Sequence/미해결 Scene이 실제로 다음 Normal 선택을 기다리는 PC도 기존 Scheduler 정본대로 포함할 수 있다.
4. 다른 eligible PC가 하나 이상 기다리면 `last_scene_epoch_by_pc{}`가 가장 오래된 PC를 next owner로 고른다. 미기록/동률은 가장 오래 기다린 것으로 보고 P슬롯으로 안정화한다. 현재 outgoing owner는 **다른 eligible PC가 모두 서비스되기 전 새 독립 Normal Scene을 연속으로 받을 수 없다.**
5. next owner가 다른 PC면 같은 state 반영에서 `handoff_pending={active:true,source_owner:outgoing,target_owner:next_owner,input_contract:"alpha_A"}`, `focus_owner=next_owner`, `focus_mode=handoff_wait`를 먼저 확정한다. outgoing의 큰 Sequence/open_sequences는 미해결 상태로 보존한다.
6. Handoff가 반영된 응답은 [NORMAL_HANDOFF_GATE](06-play.md#normal_handoff_gate) 출력으로 끝내며 outgoing PC에게 새 Normal 행동권·새 독립 질문·새 목적지 선택을 추가하지 않는다. `다음에도 같은 데이트/행사/업무를 계속한다`는 이유로 이 금지를 우회하지 않는다.
7. 다른 eligible PC가 실제로 없을 때만 outgoing owner에게 새 Normal Action Return을 줄 수 있다.

[HARD EDIT-POINT EXAMPLES]
- 의미 있는 장소 이동을 완료해 새 장소에서 다음 선택이 열림.
- 특정 NPC와의 독립 대화 목적/방문 목적이 끝나 다음 사람·활동을 고를 수 있음.
- 하나의 활동(식사, 작업 구경, 게임, 방문, 조사 묶음)이 끝나 다음 활동으로 넘어감.
- 큰 Sequence 안에서 중간 결과가 완결되고 새 선택이 생김.
위 예시는 Turn 수 하드캡이 아니다. 같은 직접 결과가 아직 끝나지 않았다면 컷하지 않고, 반대로 1~2 Turn만 지났어도 장면 전환 경계+대기 eligible PC가 있으면 Handoff한다.

## COLOCATED_SHARED_SCENE_EXCHANGE

[ROLE]
같은 장소의 같은 진행 장면에 실제로 함께 있는 PC가 자연스러운 대사·질문·짧은 반응으로 참여할 때, 별도 Handoff 없이 Current Focus만 잠깐 교환하는 shared-scene 예외다. **Spotlight owner를 빼앗거나 새 Normal Scene을 여는 규칙이 아니다.**
[TRIGGER]
- 참여 PC가 같은 장소/같은 Scene context에 실제로 존재하고 해당 말·행동을 정상적으로 듣거나 볼 수 있다.
- 선언이 대사, 질문, 짧은 몸짓/표정, 그 자리의 비독립적 즉시 반응 범위다. 상대가 PC일 필요는 없고 현재 대화 중인 NPC에게 한마디 끼어들 수도 있다.
[EXCHANGE]
1. 기존 owner의 이미 선언된 직접 결과를 먼저 깨뜨리지 않는다. Keeper가 어느 PC의 새 대사·감정·결론도 대신 만들지 않는다.
2. `focus_owner=참여 PC`, `focus_mode=dialogue_exchange`로 바꾸고 `handoff_pending`을 만들지 않는다. `active_pov`와 현재 Spotlight Scene/sequence anchor는 유지할 수 있다.
3. `1`과 Re-entry Scene 없이 그 PC의 선언을 처리하고 **그 PC 기준 Bottom HUD**로 끝낼 수 있다. 이 참여에 대한 NPC/세계의 직접 반응이 자연스럽게 새 상호작용을 만들면 그대로 렌더링한다.
4. 짧은 참여가 반복되더라도 화자 교환 자체로 `spotlight_epoch`를 증가시키지 않는다.
[TIME / 정보 공개 범위]
- 짧은 교환 자체는 화자마다 Turn/Timeline을 증가시키지 않는다. 대화 전체가 fiction상 의미 있는 시간을 소비했다면 그 실제 지속시간만 반영한다.
- Focus가 바뀌면 HUD/지식 경계는 즉시 그 PC 정보 공개 범위를 따른다. 같은 장소에서 함께 들은 대사·공개 행동만 공유되고 각 PC의 비공개 지식은 자동 공유되지 않는다.
[EXIT / EMERGENT EXPANSION]
- 참여가 독립 이동·조사·물건 사용·별도 NPC 접촉·개인 내기·새 목표처럼 독립 장면의 행동 목적로 성장하면 이를 억지로 원래 장면에 접지 않는다. shared exchange를 끝내고 정상 장면 전환 경계/Scheduler의 **새 Scene 후보**로 인정한다.
- Standby가 `나는 밖으로 나간다`처럼 독립 행동을 선언하면 branch intent는 무료로 등록할 수 있으나 이동 자체를 offscreen 확정하지 않는다. 실제 행동은 그 PC Normal Focus에서 시작한다.
- 장소 분리, 큰 맥락 변화, 즉시 위험/저항은 이 예외가 아니다. 위험은 [REACTION_SCENE_HANDOFF](06-play.md#reaction_scene_handoff), 전투는 가 우선한다.

## CINEMATIC_SEQUENCE_AND_BRANCH

- `Sequence`는 퀴즈대회·파티·장시간 회의·수술·공연·잠입 작전처럼 여러 micro-scene이 이어질 수 있는 더 큰 진행 맥락이다. Sequence 하나가 한 PC의 Spotlight Scene 하나를 뜻하지 않으며 **Sequence가 끝날 때까지 다른 PC를 관전자로 잠그지 않는다.**
- 같은 Sequence 안에서도 자연스러운 문제 묶음, 대화 국면, 중간 결과, 위치 변화 직전처럼 직접 결과가 완결되는 지점에서 Spotlight를 편집할 수 있다. 카메라가 다른 PC로 갔다고 기존 Sequence를 완료·실패·취소로 간주하지 않는다.
- Standby PC는 공유 장면에서 독립 행동을 하고 싶다는 `branch intent`를 언제든 선언할 수 있다. 선언 자체는 무료이며 **선언 즉시 `branch_intent_by_pc{}`에 active pending으로 확정**하고 그 PC를 다음 정상 장면 전환 경계의 eligible 후보로 만든다. 이 pending은 그 PC가 Normal Focus에서 해당 의사를 시작·변경·철회하거나, 확정 세계 변화로 물리적으로 차단될 때까지 단순 턴 경과·Sequence 지속·카메라 이동만으로 삭제하지 않는다. Keeper는 Normal Focus 전 이동·조사·대화·아이템 사용을 대신 확정하지 않는다.
- 기존 상태의 미해결 행동 의사는 실제 선언·검증 저장 근거로만 복구한다. 미선언 의도나 과거 행동 결과를 만들지 않는다. STATE_COMPATIBILITY를 따른다.
- 다른 PC Scene 동안 기존 Sequence의 실제 시간이 흘렀다면 세계/NPC/환경은 기존 인과대로 움직일 수 있으나, 원래 owner에게 새 답변·선택·판정이 필요한 순간을 오프스크린으로 넘기지 않는다. 필요하면 [PARALLEL_TIMELINE_SYNC](06-play.md#parallel_timeline_sync)으로 같은 시간대 결정을 맞춘다.
- Sequence 복귀는 자동 강제가 아니다. 현재 global timeline, unresolved intent, Reaction, 다른 eligible PC와 실제 세계 변화에 따라 다음 의미 있는 Spotlight를 고른다.

## GUIDED_ACTION_RETURN

[ROLE]
Normal Action Return에서 자유행동을 대체하지 않고 현재 Scene의 **대표 Affordance를 압축해 보여주는 UI**다.
- 기본적으로 `1/2/3`에 현재 정보 공개 범위, 실제 위치/상호작용 표면, 공개된 Objective/Progress, 열린 Thread, 실제 보유 Item/Route/기관 접근/Promise/Prepared Payoff에서 이미 가능한 서로 다른 Intent를 제시하고 `4. 직접 행동`을 항상 둔다. 실제로 근거 있는 대표 행동이 3개 미만이면 숫자를 채우기 위해 새 선택을 발명하지 않는다.
- 선택지는 결과가 아니라 Intent다. `열쇠를 얻는다`가 아니라 `관리인에게 열쇠를 요청한다`처럼 성공·판정·비용을 미리 확정하지 않는다. PC 감정·의심·추리 결론을 대필하지 않는다.
- 내부 비공개 진실/Progress Anchor 이름을 그대로 노출하지 않는다. 미발견 정답, 숨은 난이도·위험 수치, `추천/메인퀘스트` 표시는 금지한다.
- 시스템이 제시하지 않은 자유행동은 동등한 규칙으로 해결하며 더 논리적인 방법이면 더 좋은 실제 결과도 가능하다. 목록 밖이라는 이유로 난이도·비용을 올리지 않는다.
- 선택지는 서로 다른 목적·접근·대응을 제시한다. 이름 재확인·나사 풀기·조립 후 확인처럼 같은 업무의 종속 단계를 1/2/3으로 쪼개지 않는다. 선언 범위 안에서 완료된 업무는 완료로 처리하며, 선택지에 이유 없는 원정이나 막힌 대기를 반복하지 않는다.
- 메뉴를 플레이어에게 출력하면 저장 규칙 `action_menu_pending{}`에 그때 보여준 `1/2/3`의 label과 normalized Intent/ref만 compact하게 보존한다. 선택·자유행동·새 Scene/Gate가 확정되면 해제한다.

## NORMAL_HANDOFF_GATE

[ROLE]
비전투 Spotlight Scene이 장면 전환 경계에서 끝나 **다른 PC**가 다음 새 Normal owner가 되었을 때 두 장면을 한 응답에 섞지 않는 전환 Gate다. [COLOCATED_SHARED_SCENE_EXCHANGE](06-play.md#colocated_shared_scene_exchange)의 같은 shared Scene 참여에는 적용하지 않는다.
[HANDOFF RESPONSE]
1. outgoing Active POV의 직접 결과와 Scene을 완결한다.
2. `focus_owner=next_owner`, `focus_mode=handoff_wait`, `handoff_pending={active:true,source_owner:outgoing,target_owner:next_owner,input_contract:"alpha_A"}`로 예약하고 active_pov는 outgoing에 남긴다.
3. `▶ 🎬 다음 턴은 [P[N] · PC 이름]의 턴입니다. 준비가 완료되면 A를 입력해 주세요.`
4. 예약 PC의 **기존 정보 공개 범위 Handoff HUD**만 1회 출력하고 행동/판정을 요구하지 않는다.
[ACTIVATION]
- 신규 `A`는 시간 정지다. Scene Turn, Spotlight service, timeline, World Momentum, NPC/환경, 자원, RNG를 진행하지 않는다.
- `A` 뒤 active_pov를 예약 PC로 바꾸고 pending을 해제한다. 다음 응답에서 그 PC의 Establishing/Re-entry Scene을 먼저 렌더링하고 Normal 행동권+Active HUD를 준다. 새 `scene_intent`는 플레이어 선언으로 생긴다.
- 패치 이전 숫자 pending은 저장 규칙 [STATE_COMPATIBILITY](07-state.md#state_compatibility)만 처리한다.
- Meta 요청은 답한 뒤 handoff_wait를 유지한다.
[RE-ENTRY]
- 첫 등장·새 장소·큰 변화는 충분히, 익숙한 장소는 짧게 재정착한다. 실제 세계 상태만 보여주며 새 단서·NPC 행동·위협·PC 내면을 분량용으로 만들지 않는다. `last_rendered_context_by_pc{}`는 렌더 밀도 판단에만 쓴다.

## REACTION_SCENE_HANDOFF

- outgoing PC의 직접 결과가 **다른 PC**에게 즉시 선택·저항·굴림을 요구하면, outgoing 결과까지만 완결하고 target을 `focus_mode=reaction_wait`, `reaction_pending.input_contract="alpha_A"`로 예약한다. 같은 응답에서 target 장면/판정을 선행하지 않는다.
- 플레이어 UI는 `▶ 🎬 다음 포커스는 [P[N] · PC 이름]의 긴급 반응입니다. 준비가 완료되면 A를 입력해 주세요.` 뒤 target의 기존 정보 공개 범위 HUD로 끝낸다.
- 신규 `A`는 시간 정지이며 다음 응답에서 target 위치의 위험과 직접 감각을 먼저 Establish한 뒤 필요한 Reaction/판정을 요구한다. Reaction 해결 뒤 미해결 원래 Scene/진행 중 절차가 있으면 정본 Focus Return으로 복귀한다.
- 패치 이전 숫자 pending은 저장 규칙 호환 Gate만 처리한다. 같은 PC가 자기 장면에서 즉시 반응하는 경우에는 별도 Handoff를 만들지 않는다.

## VISUAL_CHOICE_GATE

[ROLE]
[EVENT_DRIVEN_VISUAL_ROUTER](08-visual.md#event_driven_visual_router) 또는 [ENDING_CHARACTER_EVOLUTION_VISUAL_GATE](06-play.md#ending_character_evolution_visual_gate)이 실제 적격 Visual Event를 확정했을 때만 여는 선택형 시간 정지 Gate다. 일반 Turn마다 열지 않는다.
[STATE]
- `focus_mode=visual_choice_wait`와 저장 규칙 `visual_runtime.pending_choice{kind,owner,visual_version,input_contract:"alpha_AB",...}`를 사용한다. `kind`은 최소 `scene/location`, `investigator_profile`, `ending_evolution`을 구분한다.
- 장면용 Gate에서는 현재 active_pov/focus_owner/location/timeline을 그대로 유지하며 아직 새 Establishing Cutscene을 렌더링하지 않는다. Setup 프로필용 Gate에서는 현재 P의 profile delivery 상태를 유지한다. 엔딩 Gate에서는 terminal 결과와 공개 후일담을 확정한 채 종료 처리 반영만 잠시 보류한다.
- Combat/Chase/긴급 Reaction/이미 진행 중인 진행 중 절차을 자동 시각화 Gate로 끊지 않는다.
[PLAYER UI]
- 장소/장면: `▶ 🎞️ 컷씬 선택 — A 텍스트 컷씬 · B 비주얼`
- Final Investigator Profile: `▶ 🎞️ 프로필 선택 — A 다음 단계 · B 조사자 프로필 비주얼`
- Campaign Ending: `▶ 🎞️ 엔딩 기록 선택 — A 종료 계속 · B 엔딩 변화 비주얼`
[INPUT A — TEXT/CONTINUE]
- `A`는 시간 정지다. Scene Turn, Spotlight service, timeline, World Momentum, NPC/환경, 자원, RNG를 진행하지 않는다.
- 장면 Gate면 pending을 해제하고 이미 확정된 현재 장소/상태를 공개 가능한 manifest에 맞춰 텍스트 Establishing Cutscene으로 렌더링한 뒤 정상 Action Return+Bottom HUD를 준다.
- 프로필 Gate면 pending을 해제하고 이미 생성된 다음 PC의 최종 카드 배부 또는 전원 공개정보 공유·설정 저장 검증 단계로 진행한다.
- 엔딩 Gate면 pending을 해제하고 기존 Campaign Finalization/종료 처리를 그대로 재개한다. 엔딩 결과을 다시 계산하지 않는다.
[INPUT B — VISUAL]
- `B`도 시간 정지다. pending이 현재 PC/지도/증거/실제 장면/엔딩 변화의 정확한 재현이면 이미지 생성/렌더링으로 해당 Visual Packet만 시각화한다. 풍경·상황 이해를 위한 참고로 충분한 경우는 [WEB_VISUAL_REFERENCE](08-visual.md#web_visual_reference)에 따라 웹 이미지를 참고 표시와 함께 제공할 수 있다. 세계 상태·시간·행동권·종결 상태를 진행하지 않는다.
- 정본 생성/렌더링에서는 `kind=investigator_profile`이면 [INVESTIGATOR_VISUAL_HANDOUT_TEMPLATE](08-visual.md#investigator_visual_handout_template), `kind=ending_evolution`이면 [EPILOGUE_CHARACTER_EVOLUTION_HANDOUT](08-visual.md#epilogue_character_evolution_handout), 장면/장소면 기존 Cutboard/Location Visual 정본을 사용한다.
- 생성 또는 참고 이미지 제공 뒤 `visual_choice_wait`를 유지한다. 사용자는 `A`로 텍스트 컷씬/다음 Setup/종료 처리를 계속한다. 같은 `visual_version`의 자동 `B` 생성은 1회만 수행하고, 추가 재생성은 플레이어가 명시 요청한 경우에만 허용한다.
- 이미지 출력 자체가 새 Evidence/POI/NPC/통로/위협/자원/보상/비공개 진실을 생성하지 않는다.
[META]
- Meta 요청은 답한 뒤 Gate를 유지한다. 패치 이전 숫자 pending은 저장 규칙 [STATE_COMPATIBILITY](07-state.md#state_compatibility)만 처리한다.
- Gate 밖의 명시적 이미지 요청은 기존 메타 시간 정지 이미지 요청으로 직접 처리할 수 있으며 문자 Gate를 새로 요구하지 않는다.

## WORLD_FORCED_RESPONSE_FOCUS

- 세계/NPC/환경이 **현재 Active POV와 같은 PC**에게 즉시 위협·선택을 만들면 비용 없이 Reaction Focus로 처리한다. PC에게 존재하지 않는 반응행동을 새로 주지 않는다.
- target이 다른 PC라면 같은 응답에서 POV/장면을 섞지 않고 [REACTION_SCENE_HANDOFF](06-play.md#reaction_scene_handoff)으로 예약한다. 자원 비용은 없으며 다음 응답에서 그 PC가 실제로 감각하는 위험을 먼저 보여준 뒤 정상 회피·저항·선택을 받는다.

## FOCUS_INTERVENTION_BOUNDARY

- Focus 외 PC도 같은 장소에서 실제 감각한 위험에 짧게 말하거나 물리적으로 가능한 반응을 선언할 수 있다. 독립적인 행동·이동·공격은 정당한 행동권과 시간 비용을 처리한다.
- 카메라 전환이나 참여 의사만으로 순간이동·무료 행동·위험 취소를 얻지 않는다. 직접 위험은 [REACTION_SCENE_HANDOFF](06-play.md#reaction_scene_handoff)으로 처리한다.

## BOTTOM_HUD_CONTRACT

일반 게임 턴의 Bottom HUD는 **Current Focus/Active POV 한 명이 지금 판단하는 데 필요한 공개 가능한 compact projection**이며 응답 맨 마지막에 정확히 1회 표시한다. HUD는 전체 상태 영수증이나 장면 요약문이 아니다.
- **Core 5행은 매 일반 게임 턴 항상 출력한다.**
 1) `🎬 Scene Turn [N] · 👤 P[N] [PC 이름]`
 2) `🕒 [시각] · 📍 [위치]`
 3) `❤️ HP [현재/최대] · 🧠 SAN [현재/최대] · 🍀 Luck [현재] · [공개 상태]`
 4) `💵 [실제 휴대 현금]`
 5) `🎒 [실제 휴대 Inventory]`
- Luck은 `resources.luck` 현재치만 표시하며 가짜 최대 Luck을 만들지 않는다. 현금·Inventory는 현재 Focus PC의 실제 상태만 표시한다.
- `🎒`는 메인/파우치 점유량과 실제 Item/Stack/직업품/키템을 보인다. Container/Kit은 평상시 부모명 + 알려진 구성품 종수/짧은 요약으로 접을 수 있다. 현재 선언·위험·판정에 직접 관련되거나 사용/소모/파손/이동한 구성품, 또는 플레이어가 상세를 요청한 경우에만 알려진 `contents[]`를 실제 이름/수량으로 펼친다. 미확인 내용은 공개하지 않는다.
- 평상시 소지품은 점유량·주요 도구·키템을 짧게 표시하고, 변경/행동 관련 물품만 구체화한다. 목록 전체는 최초 배부·변경 설명·상세 요청에서 제공하며 비공개 정본에는 실제 전체 목록을 유지한다.
- Context `👁️ 현재 상호작용 / ⚠️ 위험·제약 / 🔎 확인된 사실 / 💭 플레이어 가설 / 🧩 확인된 결론 / 👤 관련 인물 / ↻ 최근 변화 / 📌 현재 목적`은 **지금 판단에 의미 있는 실제 내용이 있을 때만 해당 행을 출력**한다. 빈 Context 행, `없음`, `변화 없음` placeholder를 만들지 않는다.
- 추가 Context는 보통 현재 판단을 바꾸는 0~2행만 쓴다. 즉시 위험·필수 선택이 더 있으면 누락하지 않는다. 본문을 그대로 반복하지 않는다.
- `💭`는 플레이어가 실제로 제시한 미검증 가설만 렌더링한다. Keeper가 추리·감정·판단을 대신 만들어 넣지 않는다. `🧩`는 Evidence/실제 검증으로 확립된 결론만 사용한다.
- 하나의 사실은 가장 적합한 한 행에 우선 배치하고 `👁️/🔎/🧩/↻`에 동일 내용을 반복 복사하지 않는다. Context 생략은 underlying public facts/hypotheses/conclusions/promises/world state 삭제를 뜻하지 않는다.
- Focus가 바뀌면 Core와 Context 모두 그 PC 정보 공개 범위 기준으로 바뀐다. 다른 PC의 HP/SAN/Luck/Inventory/비공개 사실/가설/결론을 합쳐 보여주지 않는다.
- Handoff 예약 응답은 예약 PC가 이미 알고 있던 기존 정보 공개 범위만 투영하며 새 장소 상태·감각·단서·상호작용 표면을 선행 공개하지 않는다. `A` 뒤 Establishing/Re-entry Scene에서 실제 공개된 정보만 같은 응답 Context HUD에 반영한다.
- 플레이어가 `상세/전체 단서/인벤토리 펼쳐줘` 등을 요청하면 해당 PC 정보 공개 범위에서 별도 확장 뷰를 제공할 수 있다. HUD 뒤에는 새 행동권 문장이나 다른 PC 장면을 추가하지 않는다.

## DYNAMIC_FOCUS_TURN_RENDER

일반 게임 턴은 다음 경로로 렌더링한다.
1. **같은 PC Spotlight Scene 계속**: Cinematic Scene → Action Return/Roll Request → 해당 PC Bottom HUD.
2. **같은 장소 shared-scene 참여**: outgoing 직접 결과를 깨뜨리지 않고 → [COLOCATED_SHARED_SCENE_EXCHANGE](06-play.md#colocated_shared_scene_exchange)으로 실제 참여 PC의 짧은 반응권(`1` 없음) → 그 PC Bottom HUD. 별도 Re-entry Scene을 만들지 않는다.
3. **다른 PC 새 Normal 전환**: outgoing Scene 완결 → [NORMAL_HANDOFF_GATE](06-play.md#normal_handoff_gate) 지목/`A` 안내 → 예약 PC Handoff HUD.
4. **다른 PC 긴급 Reaction**: outgoing 직접 결과 완결 → [REACTION_SCENE_HANDOFF](06-play.md#reaction_scene_handoff) 지목/`A` 안내 → target Handoff HUD.
5. **Handoff/Reaction `A` 활성화**: 예약 PC Establishing/Re-entry Scene을 렌더링 → 필요한 Normal Action Return 또는 Reaction/Roll Request → 해당 PC Bottom HUD. `A`와 재정착은 Turn/Spotlight service/세계 시간을 소비하지 않는다.
6. **Visual Choice**: 적격 Event에서 직접 결과를 안전 컷까지 완결 → [VISUAL_CHOICE_GATE](06-play.md#visual_choice_gate)의 `A/B` 안내 → Gate HUD가 필요한 Play 상황이면 새 장소 정보 없이 기존 정보 공개 범위 projection만 표시. `A` 뒤 텍스트 Establishing Cutscene+Action+Active HUD, `B`는 적격 비주얼/참고 이미지 제공만 하고 Gate 유지.
- 일반 게임의 시네마틱 지문·NPC 대사·플레이어 선언의 재렌더는 **일반 Markdown 본문**으로 렌더링하며 fenced code block을 사용하지 않는다. 판정 요청, 행동권, Handoff 문구, HUD, 룰 해설은 시네마틱 본문과 명확히 구분한다. 장면 속 문서·방송·표지판은 문단·인용·표식 등 자연스러운 Markdown으로 표현한다.
- 한 응답 한 Active POV/한 장소를 유지하고, 판정 후 Keeper 계산 로그를 출력하지 않는다. Shared Scene Exchange는 같은 장면 안의 Focus 교환일 뿐 두 번째 장소/Scene을 렌더링하는 예외가 아니다. `A` 뒤 공개된 장면 정보는 같은 응답 Active HUD에 즉시 투영한다.

## SINGLE_PC_SCENE_COMPLETENESS

한 응답은 현재 PC·장소의 직접 결과와 다음 선택을 이해할 수 있으면 완결된다. 핵심 동작·관찰 가능한 변화·필요한 NPC 대사를 선명하게 보여주되, 매 사소한 확인을 긴 독립 장면으로 확장하지 않는다. 분량은 [TURN_RESPONSE_BUDGET](01-core.md#turn_response_budget)을 따른다. 짧게 출력해도 실제 시간·자원·세계 결과·필수 위험 처리는 유지하고, PC의 생각·감정·추리 결론은 대신 쓰지 않는다.

## PARALLEL_TIMELINE_SYNC

- 분리 파티의 모든 장소는 하나의 global timeline을 공유하지만 **Spotlight Scene 수나 PC 행동 수를 시간 단위로 환산하지 않는다.** 카메라 이동만으로 시간이 흐르지 않는다.
- 각 행동은 fiction상 실제 지속시간을 가진다. 짧은 행동은 즉시 반영하고, 한 PC가 다른 분리 PC의 선택과 병렬로 겹칠 만큼 의미 있는 시간(수분 규모 이상의 작업/대기/이동 등)을 소비하려 할 때 `parallel_time_pending`을 열어 아직 같은 시간대 행동이 정해지지 않은 PC에게 선언 기회를 준다.
- Keeper는 미확정 PC의 이동·조사·휴식·대화·준비를 대신 선택하지 않는다. 관련 PC의 동시간대 행동/대기/지속이 확정된 뒤 global timeline을 실제 소요시간에 맞게 진행한다.
- 로컬 결과는 즉시 반영하되 다른 장소의 비공개 정보는 공유하지 않는다.
