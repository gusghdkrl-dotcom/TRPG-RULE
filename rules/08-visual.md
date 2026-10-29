# 지도·시각화

규칙판: 플레이 개선판 2026-10-29. 규칙 ID는 버전과 독립적으로 유지한다. 필요한 절만 조회한다. 전체 경로는 `00-index.md`를 따른다.

## MAP_RUNTIME_INTERACTION

지도는 확정된 장소·경로와 실제 세계 상태를 참조한다. 이미지의 픽셀 거리가 이동 시간의 정본은 아니다.
- 지도 보기·공개 경로 질문은 시간 정지다. 현재 PC가 실제로 알고 공유받은 `player_map_state`만 보여준다.
- 지도에서 목적지를 고르는 선언은 실제 이동이다. 경로의 봉쇄·거리·수단·위험·시간을 처리한다. 순간이동이나 무료 탐사가 아니다.
- 여러 공개 경로의 차이가 의미 있으면 알려진 차이를 설명하고 선택을 받는다. 미발견 지름길은 제안하지 않는다.
- 발견·개통·폐쇄 등이 실제 확인됐을 때 공개 지도 투영을 갱신한다. 지도 때문에 장소나 단서를 생성하지 않는다.
- PC가 남긴 표식은 `map_annotations_by_pc`에 기록한다. 분리된 개인 표식은 전달 전 공유하지 않는다.
- 클릭 UI가 실제 제공되지 않으면 공개 장소·경로의 이름을 자연어로 지정한다. 이미지 속 부수 표현은 세계의 정본이 아니다.

## START_MAP_HANDOUT_GATE

- `게임 시작`으로 PLAY가 반영된 신규 Run에서 최초 PC Scene을 열기 전에, `player_map_state.start_map_handout.status=pending`이면 **현재 캠페인/Chapter의 시작 지역 지도 이미지 1장**을 자동 생성·전달한다. 이는 플레이어가 이미 요청한 캠페인 handout 정책이며 별도 `A/B` Visual Choice를 요구하지 않는다.
- handout은 `canonical_map_model`에서 공개 가능한로 파생한 `player_map_state`만 사용한다. 기본 지형·공개 생활권·알려진 주요 Route·공개 시설/랜드마크·북쪽/범례·시대/계절감은 표현할 수 있으나 Hidden POI·비밀통로·미발견 Evidence/Threat 위치·다른 PC의 비공개 시작 위치를 표시하지 않는다.
- 지도 생성/전달은 **시간 정지**다. Scene Turn, timeline, World Momentum, NPC/Threat, RNG, HP/SAN/Luck/Inventory를 진행하지 않는다. 지도 handout이 실제 전달된 뒤 `status=delivered`로 반영하고, 저장 규칙의 Play Start Checkpoint verified 이후에만 첫 PC Scene을 연다.
- 이미지 자체는 공간 정본이 아니다. 픽셀 배치와 실제 world state가 충돌하면 `canonical_map_model + 현재 world/location/route state`가 우선한다. 이미지가 그리지 않은 장식 요소를 새 장소/경로로 사용할 수 없다.
- stable asset ref가 실제로 있으면 저장할 수 있고, 없으면 map model + visual manifest로 재현한다. 이미지 생성 실패 시 geography를 즉석 재창작하지 않고 handout을 pending으로 유지한 채 같은 frozen spec으로 재시도한다.

## FUNCTIONAL_MAP_RENDERING

[SCOPE]
- 이 Lock은 [START_MAP_HANDOUT_GATE](08-visual.md#start_map_handout_gate)와 플레이 중 지도 재표시의 **player-facing render 품질만** 담당한다. 공간 정본은 `canonical_map_model`, 공개 상태는 `player_map_state`, 실제 이동 처리는 [MAP_RUNTIME_INTERACTION](08-visual.md#map_runtime_interaction)이 계속 담당한다.

[VALID FUNCTIONAL MAP]
- 플레이어 지도는 분위기용 풍경 삽화나 시네마틱 배경이 아니라 **이동·탐사·공간 판단에 실제 사용할 수 있는 기능형 지도**여야 한다. top-down/준탑다운 조감도/명확한 schematic 지역도/도면형처럼 상대 위치와 Route 연결이 읽히는 형식을 사용한다.
- 거리 풍경, 마을 전경 일러스트, 캐릭터 중심 장면 카드, Route 연결을 판독할 수 없는 콘셉트 아트는 시작 지도 성공으로 취급하지 않는다.
- 현재 공개 범위에서 최소 `공개 장소 라벨 / 공개 Route와 연결 / 방향 또는 orientation anchor / 이동 판단에 필요한 지형·경계 / 확인된 Route 상태`를 읽을 수 있게 한다. 플레이 중에서 Current Focus PC의 실제 위치가 revealed node/region에 대응하고 정보 공개 범위를 침해하지 않으면 현재 위치 마커를 표시한다. 첫 shared handout에 안전하게 공유할 current location이 없으면 다른 PC의 비공개 시작 위치를 노출하기 위해 마커를 강제하지 않는다.
- 지도에 표시하는 장소/Route는 각각 기존 `location_nodes{}`/`route_edges[]`의 stable ref에서 파생해야 한다. 그림의 장식 건물·길·아이콘은 새 이동 가능 장소/통로가 아니다.
- 생성된 이미지가 위 조건을 충족하지 않거나 공개 topology와 모순되면 `start_map_handout.status=delivered`로 반영하지 않는다. geography를 재생성하지 말고 같은 frozen map/player projection으로 기능형 지도를 다시 렌더링한다.
- 새 장소/Route 공개나 확인된 Route 상태 변화가 `player_map_state`에 반영되면 지도를 매 턴 자동 재생성하지 않는다. 다음 명시적 지도 열람 또는 새 handout이 필요한 시점에 최신 projection을 렌더링한다.

## CANONICAL_CAMPAIGN_MAP

- 신규 Campaign/현재 Chronicle Chapter의 사건 핵심이 확정될 때, 실제 플레이의 공간 연속성을 위해 **비공개 `canonical_map_model{}`**을 World/Foundation/POI/Route 정본에서 파생해 확정한다. 이미 확정된 지형을 그림에 맞춰 바꾸는 것이 아니라 그림이 이 모델을 따른다.
- 권장 최소 구조는 `map_id / scope / regions[] / location_nodes{} / route_edges[] / scale_mode / public_baseline_refs[] / hidden_refs[] / frozen=true`다. `route_edges[]`는 연결·이동 수단·대략적 시간/거리 band·초기 route state처럼 플레이에 필요한 것만 담고, 실제 장면의 물리 상태가 정본이다.
- 실제 도시/지역의 정확한 좌표를 확인하지 않은 채 정밀 실측 지도로 꾸미지 않는다. 정확성이 확보되지 않은 경우 `schematic/not-to-scale` 성격을 내부 spec과 player handout에 명확히 두되, 상대 위치·연결·Route 관계는 캠페인 내내 일관되게 유지한다.
- Hidden POI·비밀통로·미발견 Evidence 위치·Threat 거점·세계 법칙 정답은 GM map에는 ref로 존재할 수 있으나 player projection에는 발견 전 넣지 않는다. 지도 이미지의 장식 때문에 새 POI/Route/Evidence를 정본으로 승격하지 않는다.
- 각 PC의 `scenario_connection_by_pc.first_collision_surface`, 시작 배치, 멀티 PC `multi_pc_convergence`는 이미 존재하는 map node/route/world ref와 연결해야 한다. Connection 때문에 map topology를 소급 재설계하지 않는다.
- 신규 Chapter가 실제로 새 지역을 열면 그 Chapter Core에서 기존 world 결과를 보존한 채 해당 scope의 map model/version을 추가할 수 있다. 이전에 파괴·폐쇄·개통된 Route는 실제 world state를 상속한다.

## SCENE_VISUALIZATION_CAST_CONTINUITY

플레이어가 현재 상황을 `이미지로 보여줘 / 시각화해줘 / 장면을 그려줘`처럼 요청하면 필요한 정확도를 구분한다. 현재 PC/사건의 실제 장면을 그리는 요청은 사용 가능한 이미지 생성 기능으로 정본을 재현한다. 직업·풍경·상황 예시는 [WEB_VISUAL_REFERENCE](08-visual.md#web_visual_reference)에 따라 실제 웹 자료로 보완할 수 있다.
- 장면에 등장하는 PC는 [PC_APPEARANCE_FROM_APP](04-setup.md#pc_appearance_from_app)로 확정한 APP 반영 외형과 배우 레퍼런스를 함께 사용한다. APP 수치만 쓰고 이미지를 일률적으로 미화하거나 평범하게 만들지 않는다. NPC도 사전 확정된 배우/외형 레퍼런스가 있으면 동일하게 적용한다.
- 배우 레퍼런스는 단순 이름 장식이 아니라 얼굴형·인상·헤어·체격 등 캐릭터의 시각적 연속성을 유지하기 위한 기준이다. 현재 캐릭터의 나이, 시대 의상, 직업 복장, 상처·피·오염, 들고 있는 장비와 위치는 **현재 GM_STATE의 실제 상태**를 우선한다.
- 배우 레퍼런스가 없는 인물은 이미 확정된 외형 묘사를 사용한다. 시각화할 때마다 임의로 다른 얼굴·체격·민족적 특징으로 재설계하지 않는다.
- 동일 PC/NPC를 후속 이미지에서 다시 그릴 때 이미 확정된 외형 특징을 유지한다. 실제 변장, 부상, 복장 교체, 시간 경과가 있을 때만 그 부분을 바꾼다.
- 이미지도 정보 공개 범위_OF_WAR를 따른다. 현재 POV가 보지 못한 위협, 숨은 인물, 미발견 방·물건, 비공개 진실을 장면을 멋있게 만들기 위해 배경에 선행 노출하지 않는다.

## VISUALIZATION_CANON_BOUNDARY

- 웹 참고 이미지는 [WEB_VISUAL_REFERENCE](08-visual.md#web_visual_reference)의 reference_only 자료다. 아래의 생성 그림 부수 요소 수용 규칙을 웹 사진에 적용해 게임 사실을 새로 만들지 않는다.
- 생성형 시각화는 현재 GM_STATE와 정보 공개 범위를 우선 재현한다. 사전 정본에 없던 이미지 모델의 부수 표현은 이미지에 보였다는 이유만으로 비공개 진실, Evidence, 자원, 통로, 위협 약점, 비공개 인물·공간이 되지 않는다.
- 플레이어가 이미지의 평범한 부수 요소를 실제로 지목해 상호작용하려 하면, 시대·장소·Homage·Foundation·현재 세계 상태와 자연스럽고 기존 정본·정보 공개 범위와 충돌하지 않는 범위에서 **평범한 세계 세부로 받아들여 정상 플레이할 수 있다.** 한번 플레이 결과에 사용되어 확정된 사실은 소급 삭제하지 않는다.
- 깨진 글자, 명백한 시대·구조 모순, 정보 공개 범위 침범 요소는 비정본 시각 표현으로 취급한다.
- 시각화 요청 때마다 새 상호작용 훅을 의도적으로 심지 않는다. 이미지의 목적은 현재 세계를 보여주는 것이다.

## EVENT_DRIVEN_VISUAL_ROUTER

목적: 이미지 시스템이 일반 Turn 응답시간을 늘리지 않도록 **Event가 있을 때만** Visual 담당 규칙을 활성화한다.
- 정본 생성 비주얼의 Visual Event는 다음 다섯 경우다: `final_profile_frozen`, `location_id_changed`, `major_visual_state_changed`, `ending_state_finalized`, `explicit_visual_request`.
- 직업 후보/낯선 환경/상황 설명의 첫 제공은 [WEB_VISUAL_REFERENCE](08-visual.md#web_visual_reference)의 경량 참고 자료 계기다. 이 경우 웹 참고를 보탤 수 있지만 자동 생성 비주얼 Gate를 만들지 않으며 시간·선택 단계·난수를 진행하지 않는다.
- 위 Event와 경량 참고 자료 계기가 없으면 이번 응답에서 Visual priority, 과거 이미지, 전체 장소 목록, 인물 외형 목록을 재검토하지 않고 즉시 SKIP한다. 일반 대화·판정·탐사·전투 행동마다 `그림을 만들까`를 다시 판단하지 않는다.
- `final_profile_frozen`: 해당 PC의 [CHARACTER_VISUAL_CANON](08-visual.md#character_visual_canon)과 [STARTING_VISUAL_BASELINE](08-visual.md#starting_visual_baseline)을 확정하고 프로필 [VISUAL_CHOICE_GATE](06-play.md#visual_choice_gate) 후보가 된다.
- `location_id_changed`: 아래 [LOCATION_VISUAL_PRIORITY](08-visual.md#location_visual_priority)만 경량 검사한다. 적격하지 않으면 Gate 없이 기존 텍스트 플레이를 계속한다.
- `major_visual_state_changed`: 이미 시각화된 중요 인물/장소의 **질적인 가시 변화**가 현재 POV에 실제 보일 때만 새 version 후보가 된다. 장기적 외형 손상·대표 복장 정체성 변화·대표 소지품 세트 변화는 포함할 수 있으나 Turn 경과·단순 재등장·일회성 진흙/피/소품만으로 Trigger하지 않는다.
- `ending_state_finalized`: Campaign Terminal의 공개 엔딩 상태가 확정된 직후 1회 엔딩 변화 비주얼 후보가 된다. Chapter close만인 경우 기본 SKIP한다.
- `explicit_visual_request`: 플레이어 명시 요청은 priority와 무관하게 현재 정보 공개 범위에서 처리한다.
- Combat/Chase/긴급 Reaction/진행 중 절차은 자동 Visual Gate보다 우선한다. 자동 Gate는 직접 결과 뒤 안전한 장면 전환 경계에서만 연다.

## CHARACTER_VISUAL_CANON

- Final Investigator Profile이 확정되면 이미지 생성 여부와 무관하게 각 PC의 **Visual Identity Canon**을 함께 확정한다. Story/반복/중요 NPC도 얼굴·외형 재현이 실제 플레이에 가치가 있을 때만 같은 구조를 둘 수 있으며 Extra/일회 NPC에게 자동 Visual Canon packet을 만들지 않는다.
- Identity Canon은 확정 APP와 그 수치를 구현한 구체적 외형, 배우 레퍼런스의 연결을 정본으로 삼고, `identity_fingerprint{}`에는 **후속 재현에 실제 필요한 특징만** 저장한다. face/eyes/brows/nose/mouth/hair/skin/build 등 모든 슬롯을 의무적으로 채우지 않으며 Profile/Story Entity에 이미 같은 외형 사실이 있으면 의미를 중복 저장하지 않는다.
- 초상·조사자 카드·현재 장면·엔딩·새 채팅에서 재현할 때 같은 APP 반영 외형을 참조한다. 프로필 원문과 이미지가 충돌하면 기존 외형을 보존해 이미지를 수정하며, 그림에 맞춰 APP나 인물 정체성을 바꾸지 않는다.
- 복장·부상·피·오염·변장·머리/수염 변화·들고 있는 장비의 원인은 기존 PC/NPC/world/inventory state가 정본이다. Visual Canon은 필요할 때 현재 보이는 projection만 참조하며 독립된 세계 사실을 만들지 않는다.
- **Profile Visual의 기본 출력은 portrait-only가 아니라 [INVESTIGATOR_VISUAL_HANDOUT_TEMPLATE](08-visual.md#investigator_visual_handout_template)의 조사자 배포형 프로필**이다. 대표 초상은 그 시트의 중심 요소이며 시대 복식·직업적 생활 흔적·Homage 조명을 반영한다. 배우/배역의 성격은 PC 성격 정본으로 복사하지 않는다.
- 대표 소지품/공개 배경/관계/사건 연결 고리는 기존 Profile·Inventory·Scenario Connection·공개 관계 사실에서 읽은 projection이다. 시각화가 새 소지품·관계·동기·Scenario 사실을 만들지 않는다.
- 대표 Portrait/Handout가 생성된 뒤에도 플레이 중에서 영구 재사용 가능한 stable asset reference가 실제 제공되지 않는다면 존재한다고 가정하지 않는다. Resume은 저장된 Identity Canon/Visual Baseline을 사용하며 픽셀 동일성을 보장한다고 주장하지 않는다.
- 이미 확정된 기존 상세 Visual Canon은 문서 정리 때문에 축약·재설계하지 않는다. 이후 신규 기록부터 sparse policy를 적용한다.

## GOLD_START_PROFILE_REFERENCE

`gold_start_profile_reference`는 **Final Investigator Profile의 기본 시각 출력 템플릿**이다. 현재 source에 이 키로 연결된 예시 이미지를 사용할 수 있으면 조사자 프로필 비주얼 생성 때 항상 함께 참조한다.

예시 이미지의 구판 항목보다 현재 [FINAL_INVESTIGATOR_PROFILE_OUTPUT_CONTRACT](04-setup.md#final_investigator_profile_output_contract)가 우선한다. 폐기한 항목을 이미지에 다시 넣지 않는다.

[FIXED VISUAL GRAMMAR]
- **세로형 1페이지 조사자 dossier**. 낡은 종이, 사진 콜라주, 메모·도장·인쇄물 질감, 어두운 외곽 프레임을 유지한다.
- **좌측 대형 메인 초상**을 가장 강한 시각 중심으로 두고, 같은 인물의 직업/여행/현장 맥락을 보여주는 작은 보조 사진 3~4장을 좌측 또는 하단에 배치한다. 보조 사진은 새 사건·Evidence를 만들지 않는다.
- **상단 중앙 Identity Card**에는 `이름 / 영문명·별칭 / 나이·성별 / 직업·역할`을 둔다. 상단에는 PC를 대표하는 공개 한 줄 문구를 둘 수 있으나 플레이어의 감정·신념을 새로 작성하지 않는다.
- **우상단 Actor/Face Reference Card**에는 사용자가 지정했거나 최종 프로필에 확정된 배우/외형 레퍼런스와 APP를 반영한 객관적 외형 요약을 둔다. 배우의 실제 성격·배역 성격은 PC 성격으로 복사하지 않는다.
- **중앙 서사 블록**은 기본적으로 `지금 여기 있는 이유 / 공개 과거·상처 또는 중요한 과거 사실 / 이번에 원하는 공개 목표·업무`의 정보 위계를 따른다. 플레이어가 확정하지 않은 감정·윤리·장기 목표는 쓰지 않는다.
- **우측 세로 블록**에는 `캐릭터 태그 3개`만 둔다. 삭제한 역할극 안내를 예전 참조 이미지에 있다는 이유로 다시 넣지 않는다.
- **중단 능력 블록**은 `HP / SAN / 행운(Luck) / MOV / DB / Build / 현금`, `근력(STR)/건강(CON)/체격(SIZ)/민첩(DEX)/외모(APP)/지능(INT)/정신력(POW)/교육(EDU)`, `직업 기능 / 취미 기능`을 한눈에 읽히는 표로 유지한다. 내부 필드명과 수치는 변경하지 않는다.
- **하단 전체 폭 Inventory Strip**은 `시작 소지품`을 `메인 / 파우치 / 직업품 / 키템`으로 나누고 실제 Item/Stack을 작은 실물 vignette/icon과 짧은 이름으로 보여준다. 점유 칸이 정본에 있으면 `[N칸]`을 표시한다. 없는 아이템을 그림 편의를 위해 추가하지 않는다.
- **배경/하단 스트립**은 시대·지역·생활권·캠페인명·연도·짧은 슬로건을 보여줄 수 있다. 공식 상용 게임 로고/고유 카드 프레임을 복제하지 않고 프로젝트 전용 표식으로 번역한다.

[CONSISTENCY]
- 캐릭터가 바뀌어도 **블록 순서·시각 위계·정보 밀도·사진 콜라주 계열은 유지하고 안의 내용만 바꾼다.**
- 이미지 생성 특성상 픽셀 좌표 동일성을 보장한다고 주장하지 않지만, 임의의 portrait card/간단 캐릭터 카드로 축약하지 않는다.
- 이미지 내 한글은 자연스러운 한국어 우선이며 HP/SAN/Luck, MOV/DB/Build, 특성 약어는 기존 현지화 정본을 따른다.

## PORTRAIT_COMPOSITION_VARIANCE

- `gold_start_profile_reference`가 고정하는 것은 **시트 UI/블록 위계/콜라주 미감**이지 모든 PC의 동일한 정면 흉상 구도가 아니다. 메인 초상 패널의 위치는 유지하되 패널 안 촬영은 캐릭터마다 달라야 한다.
- 신규 PC의 프로필 비주얼은 `shot distance / camera angle / body pose / gaze direction / current action or prop interaction / environment relation`을 현재 직업·생활 흔적·외형·시대·장소에 맞게 조합한다. 다른 PC와 이 조합이 사실상 동일하면 아직 생성 전인 구도만 재선택한다.
- 예: 정면 흉상 반복 대신 전신 3/4, 앉은 중경, 작업 중 측면, 로우/하이 앵글, 뒤돌아보는 자세, 도구/가방/책상/기계와 상호작용하는 장면 등 인물의 삶을 드러내는 구도를 사용할 수 있다. 얼굴 식별 가능성과 Visual Identity 연속성은 유지한다.
- 배우/얼굴 reference의 **얼굴 특징과 체격**은 캐스팅 기준으로 유지하지만 reference 이미지의 포즈·프레이밍·배경을 그대로 복사하지 않는다.
- 게임 중 Scene Visualization은 프로필 초상의 composition을 상속하지 않는다. 현재 액션·공간·위협·POV에 가장 적합한 카메라를 새로 잡고, 얼굴/체격/복장/부상/장비의 연속성만 Visual Canon에서 가져온다.
- 다양성을 위해 시대/직업/현재 상황과 맞지 않는 과장된 패션 포즈를 강제하지 않는다.

## GOLD_EPILOGUE_PROFILE_REFERENCE

`gold_epilogue_profile_reference`는 **Campaign/Chronicle Terminal의 PC별 엔딩 변화 시트**용 기준 키다.
- 전용 reference asset이 source에 실제 등록되기 전에는 `gold_start_profile_reference`의 dossier 계열·동일 얼굴 연속성·종이/사진/도장 미감을 시각 family로 사용하고, 내용 구조는 [EPILOGUE_CHARACTER_EVOLUTION_HANDOUT](08-visual.md#epilogue_character_evolution_handout)이 정본이다. 전용 asset이 나중에 이 키로 공급되면 그 asset이 composition reference의 최우선이 된다.
- 시작 시트와 같은 인물임이 즉시 보이도록 얼굴/체격/시각 Identity를 유지하되, 종료 시점의 실제 부상·흉터·수척함·복장·장비·소지품 변화만 반영한다.
- 엔딩 시트는 최소 `이름/Run/엔딩 상태`, `BEFORE`, `AFTER`, `눈에 보이는 변화`, `대표 소지품 변화`, `공개 관계 변화`, `남겨진 흔적`, `한 줄 에필로그`를 같은 1페이지 dossier 안에서 명확히 분리한다.
- 시작/종료 비교를 위해 존재하지 않았던 비극·구원·감정·정신질환·비공개 진실 이해도를 새로 창작하지 않는다.

## INVESTIGATOR_VISUAL_HANDOUT_TEMPLATE

- 시트의 **UI layout·정보 위계·블록 위치·시각 밀도·질감**은 [GOLD_START_PROFILE_REFERENCE](08-visual.md#gold_start_profile_reference) / `gold_start_profile_reference`를 우선한다. 인물 초상의 촬영 구도는 아래 [PORTRAIT_COMPOSITION_VARIANCE](08-visual.md#portrait_composition_variance)을 따르며, 아래 항목은 템플릿에 들어갈 사실 내용의 정본이다.
조사자 프로필 Gate의 `B`는 기본적으로 **크툴루 보드게임풍 배포형 조사자 파일**을 한 장 생성한다. 특정 공식 게임의 로고·카드 프레임·고유 그래픽을 그대로 복제하지 않고, `aged occult dossier / investigator file / 1920s cosmic-horror boardgame`의 일반적 인상으로 번역한다.
- 기본 단위: **PC 1인당 1장**. 요청 시 duo/party spread를 추가할 수 있으나 개별 시트를 대체하지 않는다.
- 필수 블록:
 1. `P슬롯 · 이름 · 별칭 · 직업/역할 · 한 줄 캐치프레이즈`
 2. **대표 초상** — 얼굴/복장/시대감이 명확한 메인 비주얼
 3. **기본 외형** — 나이·성별·키·체형·머리·눈·피부·대표 인상
 4. **외형 특징 / 복장 스타일** — 흉터·자세·손버릇·생활 흔적·대표 복식
 5. **대표 소지품 4~6개** — 작은 vignette/icon + 실제 아이템명/짧은 라벨
 6. **공개 배경 요약 2~4문장**
 7. **사건 연결 고리 1~3문장** — player-known `scenario_connection/involvement_stake` 중 공개 가능한 객관적 이해관계만
 8. **관계 요약** — 동행 PC/NPC와 이미 공개·확립된 객관적 관계만
 9. **배경 요소** — 생활권/직업 환경/여행 환경을 암시하는 간단한 공간 질감
- `🎒 시작 소지품`/현재 Inventory가 기계 정본이며, 시각 시트의 대표 소지품은 플레이 인지용 projection이다. 시각 시트에서 보인 모델 부수 소품을 새 Inventory로 승격하지 않는다.
- 정보 공개 범위: 숨은 과거, 비공개 Scenario Connection, 비공개 진실, 세계 법칙 정답, 비공개 Agenda, 미발견 Evidence는 넣지 않는다.
- 밀도: 긴 전기보다 한 장 배포물로 읽히는 짧은 레이블/요약을 우선한다.

## STARTING_VISUAL_BASELINE

- `final_profile_frozen` 시점에 엔딩 비교를 위한 **starting visual baseline**을 PC별로 한 번 확정한다. 픽셀 이미지 자체가 아니라 `Visual Identity Canon + 당시 APP와 반영 외형/대표 복장/대표 소지품/공개 배경/관계 요약/대표 인상`의 compact snapshot이다.
- 세이브/로드마다 새 baseline을 만들지 않는다. 이미 확정된 baseline은 이후 부상·소지품 변화·관계 변화 때문에 소급 변경하지 않는다.
- legacy save에 baseline이 없으면 당시 최종 프로필/Visual Canon/검증 Checkpoint에서 **확정적으로 복원 가능한 공개 사실만** 보수적으로 재구성하고, 기억에 없는 시작 상태를 새로 꾸미지 않는다.

## EPILOGUE_CHARACTER_EVOLUTION_HANDOUT

- 시각 composition/layout은 [GOLD_EPILOGUE_PROFILE_REFERENCE](08-visual.md#gold_epilogue_profile_reference) / `gold_epilogue_profile_reference`를 우선한다.
엔딩 비주얼 Gate의 `B`는 시작 baseline과 실제 종료 상태를 비교하는 **PC 1인당 1장의 엔딩 변화 카드**를 생성한다.
- 카드의 정보 원본은 [STARTING_VISUAL_BASELINE](08-visual.md#starting_visual_baseline) + 엔딩 시점의 실제 PC/world/inventory/공개 relationship/ending state다. Keeper가 PC의 감정·인생관을 새로 결론내리지 않는다.
- 필수 블록:
 1. `이름 · 별칭 · 역할 · Run/사건 제목 · 엔딩 상태`
 2. **BEFORE** — 시작 초상 또는 시작 요약 + 시작 시점 핵심 인상 1~2줄
 3. **AFTER** — 종료 초상 + 종료 시점 핵심 인상 1~2줄
 4. **눈에 보이는 변화** — 지속 상처·흉터·수척함·머리/수염·자세·복장·장비 등 실제 남은 변화
 5. **대표 소지품 변화** — 남은 것/잃은 것/새로 생긴 것 중 서사적으로 대표할 3~6개
 6. **관계 변화 요약** — 실제 사건·약속·동행 결과에서 공개 가능한 객관적 변화만
 7. **남겨진 흔적** — 공개 가능한 습관/감각 cue/상징적 흔적. 정신질환을 임의 진단하거나 PC 감정을 대필하지 않는다.
 8. **한 줄 에필로그 캡션** — 실제 엔딩 결과만 압축하고 미발생 비극/구원을 추가하지 않는다.
- 사망/실종/붕괴/귀환/생존 같은 태그는 실제 공개 엔딩 상태만 사용한다. `진실을 이해했다` 같은 비공개 진실 평가는 실제 confirmed conclusions/public facts가 있을 때만 표현한다.
- 일시적인 진흙/피/일회 소품은 종료 장면에 실제 남아 있어 시각적으로 중요한 경우에만 반영한다. 장기 변화인 척 영구화하지 않는다.
- 카드 생성은 Sitting/Chapter close마다 반복하지 않고 전체 Campaign/Chronicle terminal에서 1회가 기본이다.

## LOCATION_VISUAL_PRIORITY

자동 장소 컷은 **모든 새 장소**에 만들지 않는다. `location_id_changed`에서만 현재 새 장소를 다음처럼 분류한다.
- `VISUAL_A`: 첫 방문/새 visual version이며 아래 조건 중 **2개 이상**이 실제로 성립한다: 주요 반복 장소·허브; 공간 구조 이해가 선택/조사/이동에 중요; 현재 보이는 상호작용 표면이 3개 이상; 원작 특징의 공간 미학을 강하게 대표; 파괴·시설·Route 등 장소 상태가 후속 재방문에 지속; 큰 장소 전환으로 위치 인식 자체가 중요.
- `VISUAL_B`: 새롭고 개성은 있으나 위 기준을 충족하지 못하는 중간 장소. 자동 Gate 없음, 명시 요청 시 시각화.
- `VISUAL_C`: 복도·계단참·대기실·단순 연결방·유사 반복실·짧은 통과 구간 등. 자동 Gate 없음, 명시 요청만 허용.
- `VISUAL_A`라도 같은 `location_id + visual_state_version`을 이미 시각화했다면 재방문만으로 Gate를 다시 열지 않는다.
- 화재·침수·정전으로 인한 조명 체계 대변화·대규모 파괴/오염·바리케이드/시설 설치·중대한 인적 배치 변화처럼 **질적인 가시 변화**가 생기면 `visual_state_version`을 올릴 수 있다. 의자 이동, Turn 경과, 단순 NPC 재등장은 version 상승 사유가 아니다.

## LOCATION_VISUAL_CANON

- 중요 장소의 시각 연속성은 실제 세계 상태를 복제하는 새 정본이 아니라 **다음 시각화가 같은 장소로 보이게 하는 projection anchor**다. `visual_locations{}`는 실제 Visual Gate를 거쳤거나 반복 시각화 가치가 있는 장소에만 신규 생성한다.
- `architecture_anchor{}`에는 공간 비례, 주요 출입구/계단/창, 천장 높이, 핵심 동선처럼 쉽게 변하지 않는 구조 중 재현에 필요한 것만 compact하게 기록한다.
- `surface_anchor{}`에는 재질·마감·가구 시대성·간판/표지 계열·색감처럼 Homage/시대에 맞는 지속적 시각 특징 중 필요한 것만 둔다.
- `atmosphere_anchor{}`에는 조명원·광질·날씨 영향·먼지/습기/연무 등 장소의 현재 시각 언어를 둔다. 실제 정전·화재·날씨 변화가 있으면 world state에서 파생해 갱신한다.
- 파괴·열린 문·설치물·시체·시설 같은 실제 상태의 정본은 `irreversible_world_state/living_locations/evidence_web/...`에 남기고 Visual state에는 현재 보이는 projection/version만 연결한다. 같은 사실을 독립 정본으로 중복 저장하지 않는다.
- `visual_version`은 화재·침수·대규모 파괴·조명 체계 전환·중대한 인적 배치 등 **질적인 visible/spatial 변화**가 있을 때만 올린다. Turn 경과·의자 이동·단순 재등장은 version 상승 사유가 아니다.

## VISUAL_AFFORDANCE_MANIFEST

- 장소 비주얼을 생성하기 직전 현재 POV가 실제로 볼 수 있는 `visual_affordance_manifest[]`를 **2~4개**만 확정한다. 이는 현재 위치의 `👁️ 현재 상호작용`과 기존 world/POI 상태에서 가져오며 새 Evidence/훅 생성 단계가 아니다.
- Manifest에는 출입구, 접수대, 장치, 가구, 표지판, 눈에 보이는 흔적처럼 실제 상호작용 가능한 표면만 넣는다. Hidden POI, 아직 못 본 시체/인물, 비밀통로, 의미가 미확인인 숨은 단서의 정답을 넣지 않는다.
- 이미지 생성 모델이 Manifest 밖의 평범한 장식물을 덧붙일 수 있으나 [VISUALIZATION_CANON_BOUNDARY](08-visual.md#visualization_canon_boundary)에 따라 자동 Evidence가 되지 않는다.
- 웹 참고 이미지는 실제 공간 Manifest를 대체하지 않는다. A 텍스트와 HUD는 게임 정본만 따른다.
- 정본을 재현한 `B` 비주얼을 먼저 본 경우 Manifest의 요소는 현재 POV가 실제로 볼 수 있는 범위이므로 이후 `A` 텍스트 Establishing Cutscene과 HUD가 같은 공간 배치와 표면을 유지한다. 이미지와 텍스트가 서로 다른 방처럼 재설계되지 않는다.

## PHOTOREAL_CINEMATIC_CUTBOARD

정본 장면을 생성 그림으로 재현할 때의 기본 형식은 **실사 영화 프레임의 질감 + 웹툰/만화식 패널 구성을 한 장에 결합한 Cinematic Cutboard**다. 사용자가 다른 스타일을 명시하면 그 요청을 우선하되 원작 특징/시대/정보 공개 범위는 유지한다.
- 장소 Cutboard 기본은 3패널: `A Establishing 50~60%`(공간 전체·동선·조명), `B Character/Spatial 20~25%`(현재 POV/관련 인물과 공간 관계), `C Investigation Detail 20~25%`(Manifest에서 고른 물리 디테일). 필요할 때만 4패널까지 허용한다.
- 한 장소를 설명하기 위해 자동으로 여러 장을 연속 생성하지 않는다. 기본은 **한 이미지 안의 3패널**이다.
- 컷의 배경 요소는 장식용 빈 풍경이 아니라 공간 인식과 실제 상호작용 표면을 읽을 수 있게 배치하되, 단서 의미를 해설하거나 중요도를 빛·화살표·과장된 클로즈업으로 정답처럼 표시하지 않는다.
- PC/NPC가 나오면 [SCENE_VISUALIZATION_CAST_CONTINUITY](08-visual.md#scene_visualization_cast_continuity)과 [CHARACTER_VISUAL_CANON](08-visual.md#character_visual_canon)을 적용하고 현재 복장·부상·오염·장비를 반영한다.

## VISUAL_ASSET_PERSISTENCE_BOUNDARY

- 자동/수동 Checkpoint에는 이미지 binary나 장문의 이미지 프롬프트를 넣지 않는다. 대신 실제 재현 가치가 남은 `visual_style_profile{}`, 필요한 `visual_continuity_by_entity{}`, 적격 `visual_locations{}`, 현재 pending에 필요한 `visual_runtime{}`의 compact Visual Canon만 전체 GM_STATE snapshot과 함께 저장한다.
- 웹 참고의 출처·제목·목적·reference_only 표시는 정본 장면 asset과 구분해 필요한 것만 보존한다. 사진에 보이는 미확정 물건을 Evidence/POI로 등록하지 않는다.
- 런타임/플랫폼이 실제로 새 채팅에서도 다시 읽을 수 있는 **stable asset reference**를 제공한 경우에만 `canonical_asset_ref`와 `asset_recoverable=true`를 저장한다. 확인되지 않은 이미지 ID, 현재 대화에서만 유효한 opaque ID, 추측 URL을 durable ref로 만들지 않는다.
- stable asset이 없으면 `asset_recoverable=false`로 두고 Resume에서 Identity/Location Canon으로 재현한다. 이 경우 같은 배우 레퍼런스·필요한 fingerprint·공간 anchor·현재 가시 변화를 유지하되 픽셀 단위 동일성을 보장하지 않는다.
- 완료되어 더 이상 pending/재현에 필요 없는 image prompt/manifest/플레이 중 record를 장기 역사처럼 누적 저장하지 않는다.
- 개별 시각화 생성/Visual Canon 갱신 자체는 별도 자동 Checkpoint Trigger가 아니다. 다음 [STATE_CADENCE](07-state.md#state_cadence) 또는 수동 Checkpoint에서 최신 compact Visual Canon을 다른 GM_STATE와 함께 보존한다.

## WEB_VISUAL_REFERENCE

직업·시대 복식·풍경·건축·도구·상황의 이해를 돕는 그림은 적절한 웹 이미지가 있으면 활용한다. 생성 그림만을 유일한 선택으로 두지 않는다. 현재 사용 가능한 이미지 검색/열람 도구로 실제 확인한 자료만 사용한다.

- 사용 시점: 직업 후보를 처음 보여줄 때, 낯선 장소/풍경을 처음 정착시킬 때, 말로 이해하기 어려운 상황·복식·도구가 처음 등장할 때, 또는 플레이어가 참고 그림을 요청할 때다. 설명에 도움이 되면 키퍼가 별도 동의를 반복해 묻지 않고 참고 이미지를 보탤 수 있다. 시작 설정 입력 대기·열린 판정·전투/추격 반응을 이미지 검색으로 지연시키지 않는다.
- 같은 응답에서 필요한 자료를 묶어 한 차례 탐색하고 적합한 소수(보통 1~2개)를 고른다. 여섯 직업 각각의 사진을 의무적으로 찾지 않는다. 같은 대상의 확인된 자료는 재사용하고 일반 턴마다 검색하지 않는다. 결과가 없거나 도구가 느리거나 지원되지 않으면 텍스트를 계속 제공한다. 생성 이미지가 필요하면 기존 요청/선택 절차를 따른다.
- 시대·지역·기술·직업/상황의 실제 묘사가 맞는지 확인한다. 명백한 시대착오, 미발견 위협·스포일러·단서로 오해할 요소가 있는 그림은 제외한다. 공개 가능한 직업/환경 정보만 검색어로 쓰며 PC 비밀·미발견 진실·개인 정보·비공개 상태를 검색 서비스에 보내지 않는다.
- 화면에는 `참고 이미지 — 직업/풍경/상황 예시`와 원본 출처 링크·짧은 설명을 붙인다. 원본 페이지에서 확인한 제목/제작자 정보가 있으면 함께 표시한다. 실제로 확인하지 않은 이미지 URL이나 출처를 만들지 않는다. 화면 표시가 안 되면 확인된 출처 링크로 안내하며 이미지를 보여줬다고 주장하지 않는다. 사용 가능한 플랫폼의 표시/공유 기능과 원본의 이용 조건을 따른다.
- 참고 사진은 분위기·복식·구조 이해용이다. 사진 속 사람을 PC/NPC로 확정하거나 사진의 사물·출입구·피해를 게임의 증거/소지품/지도에 추가하지 않는다. `추가 배경 설명`과 `현재 사건의 실제 장면`을 구분한다. 사진에 없는 요소가 실제 세계에 없다고 판정하지도 않는다.
- 현재 PC의 정확한 얼굴·APP·부상·장비를 보여주는 초상/프로필/장면, 현재 지도·증거·엔딩의 실제 변화를 재현해야 할 때는 정본에 맞는 생성/렌더링을 사용한다. 다른 인물의 사진이나 일반 지도로 대체 완료하지 않는다. 사용자가 정확한 장면을 그려 달라고 했다면 일반 참고 사진만으로 완료 처리하지 않는다.
- 확인된 출처·표시 목적·관련 공개 대상 ref·실제 제공한 형태를 필요한 경우 compact하게 보존하고 `reference_only`임을 구분한다. URL이 있다는 이유로 영구 재열람·저장 성공을 보장하지 않는다. 수첩에는 NOTEBOOK_MEDIA의 실제 원본·권한·단일 Writer 조건을 지키며 참고 이미지임을 유지한다.
