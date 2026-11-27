# 02a · 시나리오 모범 예시

02-scenario의 기준을 **실제 제출 형태로, 생성 단계 순서대로** 보인 예시다. 단계마다 그 단계의 절만 읽는다.

| 생성 단계 | 엔진 도구 | 이 문서 |
|---|---|---|
| 원작 분석서 | `trpg_v2_submit_source_analysis` | 1절 《죠스》 |
| 시나리오 뼈대 | `trpg_v2_submit_skeleton` | 2절 《죠스》, 3절 《힐 하우스의 유령》(실체 없는 최종 시련) |
| 세계 상세 | `trpg_v2_submit_world_detail` | 4절 《죠스》 발췌 |
| 합류 사건 | `trpg_v2_submit_majors` | 5절 《컨저링》 |
| 개인 이해관계 | `trpg_v2_submit_personal_stakes` | 6절 《컨저링》 |

**어떻게 쓰나.** 예시는 문장의 밀도와 구체성, 필드를 채우는 방식의 기준이다. 틀이 아니다. 예시의 인물·사건·장소·반전 구조·문장을 다른 캠페인에 옮기지 않는다. 원작마다 원인, 공포 문법, 무대가 다르면 진상의 층도, 위협의 단계도, 최종 시련의 형태도 달라야 한다. 세 원작을 쓴 것도 그 때문이다. 각 절의 "좋은 점"과 "나쁜 예와 고친 예"가 따라야 할 기준이다.

**검증.** 1~4절의 JSON은 엔진의 실제 검사를 통과한 제출물이다(엔진 저장소 `v2/examples/`, 검사 `v2/tests/examples.test.mjs`). 엔진 형식이 바뀌면 그 검사가 실패하고 예시도 함께 고친다. 예시를 "통과하는 최소한"으로 읽지 말고, 각 문장이 이 정도로 구체적이어야 한다는 기준으로 읽는다.

## 1. 원작 분석서 — 《죠스》(1975)

**가정:** 인지도 메이저, 장르 괴물·생물, 2인. 원작은 실제로 조사해 쓴다. 지어낸 사실은 `facts`에 `unconfirmed`로 두거나 빼고, 이번 캠페인이 새로 만든 무대는 `adapted`로 표시한다.

```json
{
 "worldLaws": [
  {
   "condition": "사람이 물에 들어가 있거나 물가에 피가 흐른다",
   "effect": "상어가 물속 진동과 피 냄새를 따라 다가온다",
   "limit": "물 밖으로는 나오지 못한다. 그러나 작은 배는 아래에서 들이받혀 뒤집히고, 잔교 끝은 물과 한 몸이다",
   "counter": "물에서 나오고, 피를 물에 흘리지 않고, 큰 배와 작살·드럼통 부표로 위치를 붙든다"
  },
  {
   "condition": "여름 관광 성수기",
   "effect": "마을 의회와 상인들이 해변을 열어 두려고 사고를 덮는다",
   "limit": "시신과 목격자가 여럿이면 덮을 수 없다",
   "counter": "증거(검시 기록, 이빨 조각, 장부)를 사람들 앞에 내놓는다"
  }
 ],
 "representativeThreats": [
  {
   "name": "거대 백상아리",
   "behavior": "해안 가까이 머물며 물에 든 사람을 노리고, 배를 들이받는다",
   "senses": "물속 진동, 피 냄새",
   "attack": "물어 물속으로 끌고 들어간다",
   "weakness": "드럼통 부표가 박히면 잠수하지 못하고 수면에 드러난다",
   "memory": "피 냄새가 남은 물길은 하루 넘게 다시 찾아온다",
   "giveUp": "냄새가 끊기고 먹이가 없으면 반나절 뒤 사람 많은 물가로 옮겨 간다",
   "blockedBy": "뭍, 썰물 때 드러난 모래톱, 촘촘한 그물",
   "signature": "부표가 끌려가듯 물살을 거슬러 움직이고, 물린 자리는 반달 모양 이빨 자국이 줄지어 남는다",
   "chasePattern": "지느러미만 보이며 원을 좁히다가 아래에서 단번에 올라온다"
  }
 ],
 "iconicElements": ["밤바다 수영 중 첫 희생", "7월 4일 해변 개장", "현상금 낚시꾼이 몰린 부두", "노란 드럼통 부표", "작은 배로 나가는 상어 사냥", "압축 공기통", "고쳐 쓴 검시 기록"],
 "lifeAndMood": {
  "era": "1975년 7월",
  "region": "뉴잉글랜드의 섬 휴양지 애미티",
  "daily": "여름 한철 관광객 장사, 어선과 페리, 굴과 조개잡이",
  "speech": "섬 토박이의 짧고 무뚝뚝한 말과 관광객의 도시 말씨",
  "money": "달러. 여름 석 달 장사가 섬의 1년을 먹여 살린다",
  "transport": "페리, 자전거, 작은 어선",
  "comms": "유선 전화, 경찰 무전, 섬 신문"
 },
 "horrorGrammar": "보이지 않는 물 아래의 공포. 위협은 좀처럼 모습을 보이지 않고 지느러미, 흔적, 사람들의 반응으로만 다가온다. 어른들은 돈 때문에 위험을 부정하고, 가장 안전해 보이는 여름 바다가 사냥터가 된다.",
 "fanMoments": ["물속에 늘어진 다리만 보이는 시점의 긴장", "해변의 사람들이 일제히 물 밖으로 달아나는 순간", "박아 넣은 드럼통이 다시 떠오르는 장면", "이 배로는 부족하다는 깨달음"],
 "ongoingSourceEvent": {
  "summary": "남쪽 애미티 해변에서 브로디 서장이 연이은 상어 사고를 조사하고, 본 시장은 7월 4일 해변 개장을 밀어붙인다. 퀸트가 사냥 값을 부르고 해양학자 후퍼가 섬에 온다",
  "people": ["마틴 브로디", "래리 본 시장", "퀸트", "매트 후퍼"],
  "places": ["애미티 남쪽 해변", "애미티 경찰서", "퀸트의 작업장", "오르카호"]
 },
 "facts": [
  {"claim": "1975년 스티븐 스필버그 감독의 영화이며 피터 벤츨리의 1974년 소설이 원작이다", "status": "confirmed"},
  {"claim": "무대는 가상의 섬 애미티다", "status": "confirmed"},
  {"claim": "이번 캠페인의 북쪽 쿼호그 어항과 냉동 창고는 원작에 나오지 않는다", "status": "adapted"}
 ],
 "sourceOrder": [0, 6, 2, 1, 4, 3, 5],
 "sourceCause": {
  "what": "애미티 앞바다에 자리 잡은 거대한 백상아리",
  "why": "먹이가 많은 여름 해안을 사냥터로 삼았다",
  "premiseCause": "natural",
  "scale": "town",
  "coreHorror": "늘 보던 여름 바다 아래에 나를 먹으려는 것이 있고, 어른들은 돈 때문에 그것을 부정한다"
 },
 "worldBestiary": [
  {"name": "뱀상어", "from": "《죠스》(1975) 현상금 낚시꾼들이 잡은 엉뚱한 상어", "behavior": "항구 근처에서 미끼를 물고, 잡히면 사람들이 범인을 잡았다고 착각한다"},
  {"name": "두 번째 백상아리", "from": "《죠스 2》(1978)", "behavior": "사고 해역의 작은 배와 아이들을 노리고 전선·불빛에 달려든다"},
  {"name": "현상금 사냥꾼 무리", "from": "《죠스》(1975) 부두 장면", "behavior": "총과 다이너마이트를 들고 아무 배나 몰려나가 피를 뿌린다"}
 ],
 "coreExperience": {"what": "작은 배로 바다에 나가 보이지 않는 거대 상어를 쫓고, 부표로 붙들어 맞선다", "where": "애미티 앞바다"},
 "genreFrame": {
  "rules": [
   {"id": "cre_senses", "how": "상어는 물속의 피 냄새와 첨벙대는 진동으로 먹이를 찾는다. 조용히 떠 있는 사람보다 허우적대는 사람이 먼저 물린다"},
   {"id": "cre_territory", "how": "애미티 앞바다가 놈의 사냥터다. 얕은 해변에서 먼바다로 나갈수록, 배가 작을수록 놈의 영역이다"},
   {"id": "cre_bigger", "how": "처음엔 물린 시체와 지느러미뿐이다. 배 옆에 떠오른 몸이 배보다 길다는 것을 알게 되는 건 나중이다"}],
  "scenes": [
   {"id": "cre_glimpse", "how": "해수욕장 수면 위로 지느러미만 스치고 사라진다"},
   {"id": "cre_hide", "how": "뒤집힌 보트 밑에서 숨을 참고 그림자가 지나가길 기다린다"},
   {"id": "cre_trap", "how": "압축 공기통을 물려 놓고 소총으로 맞힌다"}]
 },
 "fanAssumptions": [
  {"id": "fa_culprit", "about": "culprit", "assumes": "사고를 덮는 건 본 시장 한 사람의 욕심이다"},
  {"id": "fa_solution", "about": "solution", "assumes": "베테랑 상어잡이와 큰 배로 나가 상어를 죽이면 끝난다"},
  {"id": "fa_safe", "about": "safePlace", "assumes": "해변을 닫고 물에만 안 들어가면 안전하다"},
  {"id": "fa_ally", "about": "ally", "assumes": "해양 연구소 사람들은 진실 편이다"},
  {"id": "fa_final", "about": "finalThreat", "assumes": "마지막에는 거대 백상아리와 맞선다"}
 ],
 "sourceFinalThreat": {"what": "거대 백상아리", "entity": true, "why": "원작의 마지막 장면에서 사냥꾼들이 배 위에서 그 상어와 직접 맞선다"},
 "sourcePeople": [{"name": "마틴 브로디", "from": "source", "kind": "person", "who": "뉴욕에서 온 지 얼마 안 된 애미티의 경찰서장. 물을 무서워한다", "type": "protector", "fate": "alive"}, {"name": "맷 후퍼", "from": "source", "kind": "person", "who": "해양학 연구소에서 온 젊은 상어 전문가", "type": "curious", "fate": "alive"}, {"name": "퀸트", "from": "source", "kind": "person", "who": "상어 사냥으로 먹고사는 늙은 뱃사람", "type": "fixer", "fate": "alive"}, {"name": "래리 본 시장", "from": "source", "kind": "person", "who": "여름 장사를 지키려는 애미티 시장", "type": "coverup", "fate": "alive"}, {"name": "크리시 왓킨스", "from": "source", "kind": "person", "who": "첫 희생자", "type": "easygoing", "fate": "gone"}, {"name": "애미티 상인", "from": "source", "kind": "group", "who": "여름 한 철 벌이에 한 해를 거는 가게 주인들"}, {"name": "피서객", "from": "source", "kind": "group", "who": "7월 4일 연휴에 몰려온 본토 사람들"}, {"name": "어부와 현상금 사냥꾼", "from": "source", "kind": "group", "who": "상금을 노리고 배를 끌고 나온 사람들"}, {"name": "해안 경비대원", "from": "world", "kind": "group", "who": "섬을 오가는 순찰정의 사람들"}],
 "sourcePlaces": [{"name": "애미티 해수욕장", "from": "source"}, {"name": "오르카호", "from": "source"}, {"name": "애미티 부두", "from": "source"}, {"name": "시청 회의실", "from": "source"}, {"name": "연못 어귀", "from": "source"}, {"name": "등대 곶", "from": "world"}],
 "sourceThings": [{"name": "노란 부표통", "from": "source"}, {"name": "상어 우리", "from": "source"}, {"name": "압축 공기 탱크", "from": "source"}, {"name": "현상금 벽보", "from": "source"}, {"name": "물린 서프보드", "from": "world"}]
}
```

좋은 점:
- `worldLaws`는 "상어가 위험하다"가 아니라 **조건 → 결과 → 한계 → 대응**이다. 키퍼는 이걸로 판정과 피해를 판단하고, 플레이어는 배울 수 있다. 두 번째 법칙(돈 때문에 덮는다)이 원작 공포의 절반이라 같이 적었다.
- `horrorGrammar`는 장르 설명이 아니라 **이 작품만의 공포가 작동하는 방식**이다. 이후 모든 단계가 이 문장을 따른다(위협은 지느러미와 흔적으로 다가온다).
- `fanAssumptions`는 원작을 아는 사람이 **이번 이야기에서** 당연히 여길 것이다. 뼈대의 진상 층이 이 중 사람·안전한 곳·해법을 뒤집는다. 원인(`cause`)과 마지막 위협(`finalThreat`)은 적어도 뒤집지 않는다.
- `sourceFinalThreat`는 원작의 마지막 위협이 몸을 가진 존재인지 정한다. 《죠스》는 그 상어와 배 위에서 맞서므로 `entity: true`이고, 그래서 최종 시련은 실체 보스여야 한다. 《힐 하우스의 유령》처럼 마지막이 집 자체면 `false`다.
- `worldBestiary`는 지어낸 괴물이 아니라 같은 세계에 실제로 있는 위협(뱀상어 소동, 속편의 상어, 현상금 무리)이다. 세계 상세의 적은 여기와 `representativeThreats`에서만 나온다.

| 항목 | 나쁜 예 | 고친 예 |
|---|---|---|
| 세계 법칙 | 상어는 위험하다. 물을 조심해야 한다 | 사람이 물에 있으면 진동과 피 냄새를 따라온다 / 물 밖으론 못 나오지만 작은 배는 뒤집힌다 / 부표로 위치를 붙든다 |
| 공포 문법 | 상어가 나오는 무서운 영화 | 보이지 않는 물 아래의 공포. 어른들이 돈 때문에 부정하고, 가장 안전한 여름 바다가 사냥터가 된다 |
| 팬의 예상 | 상어가 나온다 (예상이 아니라 사실) | 베테랑과 큰 배로 나가 상어를 죽이면 끝난다 |

## 2. 시나리오 뼈대 — 《죠스》

**가정:** 엔진이 추첨한 계기는 P1 `loved_one`(소중한 사람), P2 `profession`(직업상 일)이다. 주연 관계는 끈 판(처음 보는 사이)이라 `leadsTogether`가 없다. `pcSlots`는 추첨 결과를 그대로 따르고, 자리마다 풀어야 할 질문의 조각(1·2층)과 완전한 답(3층)을 진상 단서에 박는다.

```json
{
 "centralCause": {
  "summary": "거대 백상아리가 애미티 앞바다를 사냥터로 삼았다. 섬 북쪽 쿼호그 어항의 냉동 창고가 밤마다 흘려보내는 생선 찌꺼기 때문에, 상어는 해변이 아니라 항구 안쪽까지 드나든다.",
  "sourceLink": "원작의 그 상어다. 브로디 서장이 남쪽 해변을 지키는 동안 상어는 북쪽 어항의 배출구 냄새를 따라 항구 안까지 들어온다. 이 무대는 원작 사건의 북쪽 절반이다.",
  "startedAtMinute": -720, "irreversible": true
 },
 "premise": {"cause": "natural", "scale": "town", "stage": "town", "threat": "mixed"},
 "grandCarrot": {
  "goal": "7월 4일 연휴가 끝나기 전에 상어를 항구로 끌어들이는 배출과 그것을 덮는 거래를 끊고, 상어를 처치하거나 섬에서 떼어 내 어항 사람들을 살린다.",
  "alreadyLost": "어제 새벽 굴을 따던 소년 토미 피어스가 방파제에서 사라졌다. 의회는 익사로 처리하고 수색을 끝냈다.",
  "ifUnchecked": [
   {"atMinute": 720, "afterMajor": 2, "happens": "새벽 조개잡이 배가 항구 입구에서 뒤집혀 선원 한 명이 끌려간다. 의회는 '보트 사고'로 발표한다.", "pcImpact": "어항 사람들이 입을 닫고 PC에게 배를 빌려주지 않는다.", "deepens": {"where": "항구 입구 바깥 물길과 뒤집힌 배 주변", "danger": "물에 빠진 사람을 건지려면 상어의 물길에 들어가야 한다"}, "ifCut": {"cutBy": "새벽 조개잡이 배들의 출항을 막는다", "keeps": "선원이 끌려가지 않는다", "continuesVia": "th_council"}},
   {"atMinute": 1800, "afterMajor": 4, "happens": "7월 4일 북쪽 해변 수영 대회가 강행되고, 물에 들어간 아이 둘이 다친다.", "pcImpact": "해안 경비대가 몰려와 북쪽 바다 출입을 막고, 의회는 PC들을 소동의 원인으로 지목한다.", "deepens": {"where": "북쪽 해변 수영 대회장과 그 앞 모래톱", "danger": "얕은 물에 모인 사람들 사이로 등지느러미가 들어온다"}, "ifCut": {"cutBy": "대회 전에 해변 출입을 막을 증거를 경비대에 넘긴다", "keeps": "아이들이 다치지 않는다", "continuesVia": "th_hunters"}},
   {"atMinute": 2880, "afterMajor": 6, "happens": "상어가 페리 잔교 아래까지 들어와 대기줄 끝의 사람들을 덮치고 페리 운항이 끊긴다.", "pcImpact": "섬을 떠날 길이 바다뿐인데, 그 바다에 상어가 있다.", "deepens": {"where": "페리 잔교 밑과 배출구 안쪽 수로(원작의 상어가 드나든 곳)", "danger": "잔교 기둥 사이에서 상어와 마주한다"}, "ifCut": {"cutBy": "대기줄을 언덕으로 옮기고 잔교를 닫는다", "keeps": "잔교 습격이 일어나지 않는다", "continuesVia": "th_shark"}}
  ]
 },
 "stage": {"name": "애미티섬 북쪽 쿼호그 어항", "areaIds": ["loc_breakwater", "loc_outfall", "loc_jetty", "loc_ferry_pier", "loc_harbor_mouth", "loc_sandbar"],
  "containment": {"reason": "연휴 동안 의회가 페리 표를 관광객에게 먼저 돌리고, 폭풍 주의보로 작은 배 출항이 막혔다.", "releaseCondition": "상어를 처리하고 배출을 끊은 증거가 경찰이나 해안 경비대에 넘어가 페리가 다시 정상 운항한다."}},
 "truthLayers": [
  {"layer": 1, "fact": "어항 앞바다의 연이은 실종은 익사가 아니라 큰 상어의 공격이다. 상어는 해변이 아니라 방파제와 잔교 밑까지 들어온다.",
   "outerAppearance": "의회와 섬 신문은 익사와 보트 사고라고 한다. 해변은 닫혔으니 괜찮다고 한다.", "overturns": "fa_safe",
   "discoveryPaths": [
    {"id": "l1_pile_marks", "via": "location", "ref": "loc_breakwater", "how": "썰물 때 방파제 아래 나무 말뚝을 살핀다", "reveals": "사람 팔뚝 높이에 반달 모양으로 줄지어 박힌 이빨 자국이 있다", "tier": "core", "points": {"to": "loc_harbor_mouth", "how": "방파제 말뚝의 긁힌 자국이 항구 입구 쪽으로 깊어진다"}},
    {"id": "l1_tooth", "via": "item", "ref": "it_tooth", "how": "토미 피어스의 굴 바구니를 뒤집어 본다", "reveals": "끊어진 바구니 끈에 톱니 달린 세모꼴 이빨 조각이 끼어 있다", "tier": "core", "points": {"to": "npc_dale", "how": "이빨을 본 사람은 수산 시장의 데일을 찾으라고 한다"}},
    {"id": "l1_fin", "via": "phenomenon", "ref": "loc_harbor_mouth", "how": "새벽 항구 입구를 지켜본다", "reveals": "항로 부표보다 큰 지느러미가 원을 그리며 방파제 안으로 들어온다", "tier": "core", "points": {"to": "loc_outfall", "how": "지느러미는 배수구 쪽으로 사라진다"}}
   ],
   "unlocks": {"means": ["이빨 조각을 증거로 내밀 수 있다"], "avoid": ["새벽과 해 질 녘에는 방파제·잔교 끝 물가에 서지 않는다"]}},
  {"layer": 2, "fact": "냉동 창고 주인 엘런 크레인이 의회 관광 기금에서 돈을 받고 밤마다 생선 찌꺼기를 항구 안 배출구로 흘려보낸다. 해양 연구소 조교 데일 코빈은 상어가 항구에 머문다는 결론을 지우고 연구비를 받았다.",
   "outerAppearance": "냉동 창고는 섬의 일자리를 지키는 사업장이고, 연구소는 상어가 이미 먼바다로 떠났다고 발표했다.", "overturns": "fa_culprit",
   "discoveryPaths": [
    {"id": "l2_outfall", "via": "location", "ref": "loc_outfall", "how": "자정에 냉동 창고 뒤 배출구를 지켜본다", "reveals": "피 섞인 찌꺼기가 쏟아지고 몇 분 뒤 항구 안쪽 물이 크게 갈라진다", "tier": "core", "points": {"to": "npc_dale", "how": "배수구 밸브에 데일의 회사 표식이 찍혀 있다"}},
    {"id": "l2_ledger", "via": "item", "ref": "it_ledger", "how": "냉동 창고 사무실의 장부를 뒤진다", "reveals": "관광 기금에서 '위생 처리비'라는 이름으로 매달 크레인에게 돈이 나갔다", "tier": "core", "points": {"to": "loc_sandbar", "how": "장부에 모래톱으로 나간 기록이 줄지어 있다"}},
    {"id": "l2_dale", "via": "npc", "ref": "npc_dale", "how": "데일 코빈에게 연구소 보고서 초안을 들이밀며 묻는다", "reveals": "상어가 항구에 머문다는 원래 결론이 위에서 지워졌다", "tier": "core", "points": {"to": "npc_hal", "how": "데일이 할에게 물어보라며 말을 끊는다"}},
    {"id": "l2_fund_stub", "via": "location", "ref": "loc_outfall", "how": "배출구 옆 관리 상자의 젖은 서류 뭉치를 뒤진다", "reveals": "관광 기금 수표 부본에 엘런 크레인의 서명과 '배출 비용'이라는 메모가 남아 있다", "tier": "bonus", "points": {"to": "npc_dale", "how": "부본 뒷면에 연구소 전화번호가 적혀 있다"}}
   ],
   "unlocks": {"trust": ["데일 코빈을 설득하면 상어 이동 기록을 얻는다"], "means": ["배출구를 닫는 수문 손잡이가 창고 지하에 있다"]}},
  {"layer": 3, "fact": "상어는 찌꺼기 냄새가 끊기면 반나절 안에 먹이를 찾아 사람이 가장 많은 물가로 간다. 배출만 끊으면 수영 대회 해변으로 향한다. 사람들을 살리려면 배출을 끊는 동시에 마지막 미끼로 상어를 썰물의 북쪽 모래톱까지 끌어내 부표를 박아야 한다.",
   "outerAppearance": "배출만 끊으면 상어가 떠날 것처럼 보이고, 큰 배만 구하면 바다에서 끝낼 수 있을 것처럼 보인다.", "overturns": "fa_solution",
   "discoveryPaths": [
    {"id": "l3_tracklog", "via": "item", "ref": "it_corbin_log", "how": "데일의 상어 이동 기록과 배출 시각을 나란히 맞춰 본다", "reveals": "배출이 멈춘 날마다 상어가 반나절 안에 남쪽 해변 쪽으로 옮겨 갔다", "tier": "core", "points": {"to": "loc_sandbar", "how": "항적 기록이 모래톱에서 멈춘다"}},
    {"id": "l3_hal", "via": "npc", "ref": "npc_hal", "how": "늙은 상어잡이 핼 마시에게 굶은 상어를 끌어내는 법을 묻는다", "reveals": "굶은 상어는 피 냄새 띠를 따라 얕은 모래톱까지 올라온다. 거기서는 등이 드러난다", "tier": "core", "points": {"to": "loc_sandbar", "how": "할이 모래톱 쪽을 턱짓한다"}},
    {"id": "l3_sandbar", "via": "location", "ref": "loc_sandbar", "how": "썰물 때 북쪽 모래톱을 직접 걸어 본다", "reveals": "썰물에는 물이 허리 깊이라 큰 몸이 들어오면 등이 드러나고, 부표를 박을 거리가 된다", "tier": "core", "points": {"to": "npc_hal", "how": "모래톱에 할의 부표가 떠 있다"}},
    {"id": "l3_hal_tide", "via": "npc", "ref": "npc_hal", "how": "할에게 썰물 때 모래톱 물길이 어떻게 갈라지는지 캐묻는다", "reveals": "썰물 두 시간 전에만 북쪽 모래톱 안쪽으로 배가 들어갈 수 있다", "tier": "bonus", "points": {"to": "loc_sandbar", "how": "할이 모래톱 들머리의 낡은 말뚝을 가리킨다"}}
   ],
   "unlocks": {"means": ["피 냄새 띠로 상어를 모래톱까지 끌어낸다", "드럼통 부표 셋으로 잠수를 막는다"], "places": ["썰물 때의 북쪽 모래톱"]}}
 ],
 "threats": [
  {"id": "th_shark", "name": "백상아리", "tier": 2, "roles": ["chase"],
   "stages": [
    {"id": "th_shark_s1", "order": 1, "anchor": "start", "windowMinMinutes": 60, "windowMaxMinutes": 240, "does": "항구 입구에 지느러미가 보이고, 작은 배 주위를 맴돌다 사라진다", "omens": ["갈매기 떼가 한곳에 내려앉았다 흩어진다", "부표 줄이 물살과 반대로 끌려간다"], "reach": {"how": "물가와 배 위의 사람이 목격한다", "targets": ["loc_harbor_mouth", "loc_breakwater"]}, "responses": ["물가에서 물러난다", "배를 잔교에 묶고 기다린다", "지느러미가 간 방향을 기록한다"], "ifCut": {"cutBy": "항구 입구에 그물을 치고 배출구 냄새를 끊는다", "keeps": "작은 배가 입구에서 습격당하지 않는다", "continuesVia": "th_hunters"}},
    {"id": "th_shark_s2", "order": 2, "anchor": "prevStage", "windowMinMinutes": 300, "windowMaxMinutes": 900, "does": "방파제 아래와 잔교 밑까지 들어와 물에 다리를 담근 사람을 노린다", "omens": ["잔교 기둥에 붙은 따개비가 한 줄로 긁혀 떨어져 있다", "밤에 배출구 쪽 물이 크게 출렁인다"], "reach": {"how": "물가에 있는 사람을 덮친다", "targets": ["loc_breakwater", "loc_jetty", "loc_outfall"]}, "responses": ["물에서 나온다", "다친 사람을 물가에서 끌어올린다", "배출구 근처에 사람을 들이지 않는다"], "ifCut": {"cutBy": "방파제와 잔교의 물가 출입을 막고 사람을 물러나게 한다", "keeps": "물에 발을 담근 사람이 끌려가지 않는다", "continuesVia": "th_council"}},
    {"id": "th_shark_s3", "order": 3, "anchor": "prevStage", "windowMinMinutes": 600, "windowMaxMinutes": 1200, "does": "작은 배를 아래에서 들이받아 뒤집고, 물에 빠진 사람을 끌고 간다", "omens": ["배 밑바닥을 무언가가 길게 긁는 소리", "드럼통 하나가 물속으로 끌려갔다가 멀리서 떠오른다"], "reach": {"how": "항구 안의 작은 배를 들이받는다", "targets": ["loc_harbor_mouth", "loc_jetty"]}, "responses": ["배를 잔교에 붙인다", "물에 빠진 사람에게 구명 고리를 던진다", "작살과 부표를 준비한다"], "ifCut": {"cutBy": "작은 배 출항을 모두 묶어 둔다", "keeps": "배가 뒤집혀 사람이 빠지는 일이 멈춘다", "continuesVia": "th_hunters"}},
    {"id": "th_shark_s4", "order": 4, "anchor": "prevStage", "windowMinMinutes": 600, "windowMaxMinutes": 1200, "does": "페리 잔교 아래까지 들어와 대기줄 끝의 사람들을 덮친다", "omens": ["페리 잔교 아래 물이 검붉게 흐려진다", "잔교 끝 기둥이 한 번 크게 흔들린다"], "reach": {"how": "잔교 위의 사람을 물로 끌어내린다", "targets": ["loc_ferry_pier"]}, "responses": ["대기줄을 잔교 안쪽으로 물린다", "잔교 끝을 막는다", "미끼로 상어를 다른 곳으로 끈다"], "ifCut": {"cutBy": "페리 대기줄을 잔교에서 언덕 위 창고로 옮긴다", "keeps": "잔교 습격이 일어나지 않고 페리 운항이 이어진다", "continuesVia": "th_council"}}
   ],
   "traits": {"senses": "물속 진동, 피 냄새", "attacks": ["물어 끌고 들어가기", "배 들이받기"], "weakness": "드럼통 부표가 박히면 잠수하지 못한다", "chasePattern": "물속에서는 사람보다 훨씬 빠르다. 물 밖으로는 쫓지 못한다", "learnableLimits": ["물 밖으로 나오지 못한다", "썰물 모래톱에서는 등이 드러난다"]},
   "outOfReach": "물에서 서너 걸음 떨어진 뭍과 언덕 위 창고, 북쪽 모래톱의 썰물 때 마른 땅까지는 오지 못한다", "grammar": {"chase": {"follows": "물속 진동과 피 냄새의 띠"}}},
  {"id": "th_council", "name": "의회의 입막음", "tier": 1, "roles": ["guard"],
   "stages": [
    {"id": "th_council_s1", "order": 1, "anchor": "start", "windowMinMinutes": 120, "windowMaxMinutes": 600, "does": "보안관 대리 보이드가 부두에서 상어 얘기를 하는 사람을 쫓아내고, 섬 신문은 익사 기사를 낸다", "omens": ["잔교 게시판의 '수영 주의' 쪽지가 떼어져 있다", "상점 주인들이 PC를 보면 말을 멈춘다"], "reach": {"how": "질문하는 사람을 막고 소문을 끊는다", "targets": ["loc_jetty", "npc_boyd"]}, "responses": ["증거를 숨긴다", "의회 밖의 사람을 찾는다", "보이드에게 따로 말을 건다"], "ifCut": {"cutBy": "신문사에 이빨 조각과 사진을 먼저 넘긴다", "keeps": "부두 사람들이 상어 이야기를 할 수 있게 된다", "continuesVia": "th_shark"}},
    {"id": "th_council_s2", "order": 2, "anchor": "prevStage", "windowMinMinutes": 600, "windowMaxMinutes": 1200, "does": "냉동 창고 앞에 경비를 세우고 사무실 장부를 치운다", "omens": ["창고 사무실 창에 늦게까지 불이 켜져 있다", "트럭이 상자를 싣고 페리 잔교로 간다"], "reach": {"how": "창고 출입을 막는다", "targets": ["loc_outfall"]}, "responses": ["장부가 실린 트럭을 쫓는다", "다른 날 밤에 숨어 들어간다", "크레인에게 거래를 건다"], "ifCut": {"cutBy": "장부를 치우기 전에 사무실에서 빼낸다", "keeps": "배출 거래의 증거가 PC 손에 남는다", "continuesVia": "th_hunters"}},
    {"id": "th_council_s3", "order": 3, "anchor": "prevStage", "windowMinMinutes": 900, "windowMaxMinutes": 1800, "does": "PC를 '관광 방해'로 유치장에 넣고 페리 표를 빼앗으려 한다", "omens": ["보이드가 PC의 숙소 앞에 차를 세워 둔다", "섬 신문에 '외지인 소동' 기사가 실린다"], "reach": {"how": "PC를 붙잡아 가둔다", "targets": ["P1", "P2", "loc_ferry_pier"]}, "responses": ["브로디 서장에게 직접 증거를 넘긴다", "숨는다", "의회 회의장에 증거를 들고 나선다"], "ifCut": {"cutBy": "해안 경비대 무전으로 체포 전에 외부에 알린다", "keeps": "유치장에 갇히지 않고 페리 표도 지킨다", "continuesVia": "th_shark"}}
   ],
   "traits": {"senses": "소문과 신고", "attacks": ["체포", "증거 압수"], "weakness": "여러 사람 앞에서 증거가 드러나면 버티지 못한다", "chasePattern": "차와 무전으로 섬 안을 돈다", "learnableLimits": ["브로디 서장은 의회 편이 아니다"]},
   "outOfReach": "해안 경비대 초소와 본토 신문사 지국 안에서는 보안관 대리가 손을 못 쓴다", "grammar": {"guard": {"protects": "냉동 창고와 관광 기금 장부", "boundary": "창고 철문과 의회 사무실 문턱"}}},
  {"id": "th_hunters", "name": "현상금 낚시꾼들", "tier": 1, "roles": ["patrol"],
   "stages": [
    {"id": "th_hunters_s1", "order": 1, "anchor": "start", "windowMinMinutes": 180, "windowMaxMinutes": 480, "does": "현상금이 붙자 외지 낚시꾼들이 잔교에 몰려 미끼 피를 물에 뿌린다", "omens": ["잔교에 피 묻은 미끼 통이 줄지어 놓인다", "낯선 배들이 항구 입구에 닻을 내린다"], "reach": {"how": "잔교와 항구를 차지한다", "targets": ["loc_jetty", "loc_harbor_mouth"]}, "responses": ["낚시꾼들에게 물가가 위험하다고 알린다", "미끼 피를 치운다", "그들 배를 빌린다"], "ifCut": {"cutBy": "현상금이 가짜라는 소문을 낸다", "keeps": "잔교에 미끼 피가 뿌려지지 않는다", "continuesVia": "th_shark"}},
    {"id": "th_hunters_s2", "order": 2, "anchor": "prevStage", "windowMinMinutes": 300, "windowMaxMinutes": 900, "does": "총과 다이너마이트를 든 무리가 밤 부두를 돌며 움직이는 것마다 쏜다", "omens": ["밤 부두에 총성이 한 번 울린다", "다이너마이트 포장지가 잔교에 흩어져 있다"], "reach": {"how": "밤 부두의 사람을 위협한다", "targets": ["loc_jetty", "loc_ferry_pier"]}, "responses": ["불빛을 끄고 피한다", "무리의 우두머리와 말한다", "그들이 잡은 엉뚱한 상어를 확인한다"], "ifCut": {"cutBy": "다이너마이트 상자를 먼저 치운다", "keeps": "밤 부두의 총격과 폭발이 멈춘다", "continuesVia": "th_council"}},
    {"id": "th_hunters_s3", "order": 3, "anchor": "prevStage", "windowMinMinutes": 600, "windowMaxMinutes": 1200, "does": "작은 배로 몰려나가다 한 척이 뒤집히고 물에 빠진 사람이 생긴다", "omens": ["항구 입구에 배 여러 척이 엉켜 있다", "누군가 구명 고리를 찾는 고함"], "reach": {"how": "항구 안에 물에 빠진 사람을 만든다", "targets": ["loc_harbor_mouth"]}, "responses": ["물에 빠진 사람을 건진다", "배들을 항구 밖으로 물린다"], "ifCut": {"cutBy": "작은 배들이 나가기 전에 연료를 빼 둔다", "keeps": "낚시꾼 배가 뒤집혀 사람이 빠지지 않는다", "continuesVia": "th_shark"}}
   ],
   "traits": {"senses": "소문, 피 냄새 나는 물", "attacks": ["엽총", "다이너마이트"], "weakness": "현상금이 사라지거나 엉뚱한 상어를 잡으면 흩어진다", "chasePattern": "작은 배로 무리 지어 움직인다", "learnableLimits": ["밤에는 술에 취해 엉뚱한 곳을 쏜다"]},
   "outOfReach": "페리 잔교 너머 마을 언덕과 교회 마당에는 오지 않는다", "grammar": {"patrol": {"route": "잔교에서 방파제를 거쳐 배출구까지 밤 부두를 돈다", "gaps": "새벽 세 시 무렵 술집으로 몰려가 한 시간쯤 비운다"}}}
 ],
 "encounterPool": [
  {"id": "pool_tiger", "kind": "enemy", "ref": "en_tiger", "locations": ["loc_jetty"], "maxCount": 1},
  {"id": "pool_hunters", "kind": "enemy", "ref": "en_hunter", "locations": ["loc_jetty", "loc_ferry_pier"], "maxCount": 4}
 ],
 "sourceCrossing": {
  "ongoingEventSummary": "남쪽 애미티 해변에서는 브로디 서장이 사고를 조사하고 본 시장이 7월 4일 개장을 밀어붙인다. 퀸트가 사냥 값을 부르고 후퍼가 섬에 도착한다.",
  "crossingPoints": [
   {"id": "x_bounty", "where": "쿼호그 어항 잔교", "how": "현상금 소식에 외지 낚시꾼들이 몰려와, 남쪽에서 벌어진 엉뚱한 상어 소동이 북쪽 잔교에서도 벌어진다"},
   {"id": "x_brody", "where": "애미티 경찰서 북쪽 분소", "how": "브로디 서장이 북쪽 실종 신고를 확인하러 들르지만, 의회 연락을 받고 남쪽으로 돌아간다"},
   {"id": "x_orca", "where": "항구 입구 바깥", "how": "연휴 뒤 오르카호가 북쪽 항구 앞을 지나간다. PC들이 부표를 박는 바로 그 바다다"}
  ]
 },
 "pcSlots": [
  {"slot": "P1", "hookType": "loved_one", "situation": "P1의 조카 토미 피어스가 어제 새벽 방파제에서 굴을 따다 사라졌다. 의회는 익사로 처리하고 수색을 끝냈다.", "alreadyTouched": "토미의 빈 굴 바구니를 돌려받았는데, 끈 한쪽이 톱니에 썰린 것처럼 끊겨 있다.",
   "question": {"asks": "토미를 데려간 것은 무엇이고, 왜 하필 방파제 안쪽까지 들어왔나", "fragmentPathIds": ["l1_tooth", "l1_pile_marks", "l2_outfall"], "answerPathId": "l3_tracklog"}},
  {"slot": "P2", "hookType": "profession", "situation": "P2는 본토 보험사에서 냉동 창고 화재보험 갱신 실사를 나왔다. 연휴 안에 실사를 끝내야 회사가 페리 표를 내준다.", "alreadyTouched": "창고 냉동기 가동 기록과 실제 생선 입고량이 맞지 않는다.",
   "question": {"asks": "냉동기 기록과 입고량은 왜 맞지 않고, 그 차이는 어디로 흘러가나", "fragmentPathIds": ["l2_ledger", "l2_fund_stub", "l1_fin"], "answerPathId": "l3_hal"}}
 ],
 "sourceKnowledge": [
  {"approach": "identity", "gain": "상어라고 곧장 말하면 핼 마시가 일찍 귀를 기울인다", "stillNeeds": "의회가 믿게 하려면 이빨 조각 같은 물증이 따로 있어야 한다"},
  {"approach": "expert", "gain": "해양 연구소 조교 데일을 일찍 찾으면 상어의 습성을 빨리 안다", "stillNeeds": "데일의 지워진 결론을 되살릴 기록을 찾아야 한다"},
  {"approach": "direct", "gain": "원작처럼 배를 타고 바로 사냥에 나서면 상어를 일찍 본다", "stillNeeds": "이번 상어는 배출 냄새를 따라 항구 안에 있어 먼바다에서는 못 잡는다"},
  {"approach": "knownFix", "gain": "원작의 압축 공기통 수법은 상어를 한 번 크게 다치게 한다", "stillNeeds": "공기통은 냉동 창고 안에 있고, 끝내려면 모래톱에서 부표를 박아야 한다"}
 ],
 "questionsMeet": "찌꺼기가 상어를 항구 안에 붙잡아 두었고(P2의 답), 찌꺼기가 끊기면 상어는 사람 많은 물가로 간다(P1의 답). 둘을 합쳐야 배출만 끊으면 해변이 위험해진다는 핵심에 닿는다.",
 "finalBoss": {
  "id": "boss_shark", "form": "entity", "threatId": "th_shark", "tier": 2,
  "learnFrom": ["th_shark_s1", "th_shark_s3", "l1_fin", "l3_hal"],
  "reuses": [{"ref": "l3_sandbar", "how": "썰물 시각을 알아 둔 모래톱으로 상어를 끌어올려 등이 드러나게 한다"}, {"ref": "l2_outfall", "how": "배출구 찌꺼기를 미끼 띠로 다시 흘려 상어를 모래톱 쪽으로 이끈다"}, {"ref": "th_shark_s2", "how": "방파제 밑까지 들어오던 길목을 알기에, 부표를 실은 배를 그 물길 밖에 둔다"}],
  "gimmick": {"what": "다치면 깊이 잠수해 숨을 돌리고, 배 바로 밑에서 다시 올라온다", "effect": "깊은 물에서 작살 몇 번 맞혀 봐야 사라졌다 돌아오고, 작은 배는 아래에서 들이받혀 뒤집힌다"},
  "phases": [
   {"trigger": "피 냄새 띠를 따라 모래톱 근처에 처음 올라올 때", "change": "배 주위를 돌며 미끼만 채 가고 사람을 떠본다"},
   {"trigger": "부표가 하나 이상 박히면", "change": "잠수하지 못하고 수면에서 배를 정면으로 들이받는다"},
   {"trigger": "부표가 셋 박히거나 크게 다치면", "change": "얕은 모래톱으로 몸부림치며 올라와 물속에 선 사람을 노린다"}
  ],
  "weakness": {"what": "드럼통 부표가 박히면 잠수하지 못해 수면에 드러나고, 썰물 모래톱에서는 몸을 돌리기 어렵다", "learnFrom": ["l3_hal", "l3_sandbar", "th_shark_s3"]},
  "counter": "배출을 끊어 상어를 굶긴 뒤 피 냄새 띠로 썰물 모래톱까지 끌어내고, 작살로 드럼통 부표 셋을 박아 잠수를 막는다",
  "withoutCounter": "깊은 물에서 작은 배로 맞서면 상어가 아래에서 배를 뒤집고, 물에 빠진 사람을 하나씩 끌고 들어간다",
  "resolutions": [
   {"kind": "defeat", "how": "부표로 수면에 붙든 상어를 모래톱에서 작살과 총으로 쓰러뜨린다", "needs": "드럼통 부표 셋, 작살, 썰물 시각", "cost": "모래톱 물속에 선 사람이 크게 다칠 수 있다"},
   {"kind": "driveOff", "how": "배출을 끊고 마지막 미끼를 항구 밖 깊은 바다로 끌고 나가 상어를 섬에서 떼어 낸다", "needs": "배출을 멈출 장부 증거, 미끼를 실은 배", "cost": "상어는 살아서 다른 해안에 나타나고, 미끼 배는 잃는다"},
   {"kind": "escape", "how": "상어가 남쪽 해변을 덮치는 사이 장부를 들고 마지막 페리로 섬을 떠난다", "needs": "페리 표와 장부", "cost": "수영 대회 날 남쪽 해변에서 사람들이 다친다"}
  ]
 },
 "finalKey": {
  "items": [{"id": "fk_barrels", "itemId": "it_barrels", "obtainPaths": ["냉동 창고 뒤 빈 드럼통을 몰래 빼낸다", "핼 마시의 헛간에서 빌린다"]}],
  "knowledge": [{"id": "fk_bait", "truthLayerMin": 3}],
  "preparations": [{"id": "fk_outfall_shut", "description": "냉동 창고 배출구 수문을 닫아 상어를 굶긴다", "obtainPaths": ["장부로 크레인을 압박해 직접 닫게 한다", "밤에 창고 지하로 숨어 들어가 수문 손잡이를 부순다"]}],
  "minimumToWin": {"items": 1, "knowledge": 1, "preparations": 1}
 },
 "exitTrial": {"description": "상어를 처리한 뒤에도 폭풍 주의보 속 마지막 페리까지 가야 한다. 현상금 낚시꾼들의 배와 의회 경비가 잔교를 막고 있다.", "threatIds": ["th_hunters", "th_council"], "releaseCondition": "상어 처리 증거를 브로디 서장이나 해안 경비대에 넘겨 페리 운항이 다시 열린다."}
}
```

좋은 점:
- **원인은 그대로, 길은 새로.** 원인은 원작의 그 상어(`natural`, `town`)다. 바뀐 것은 원인에 이르는 길이다. 무대를 남쪽 해변에서 북쪽 어항으로 옮기고, 상어를 항구 안까지 끌어들이는 사람의 거래를 붙였다. 원작을 아는 플레이어도 범인(상어)은 알지만, 누가 상어를 부르고 있는지, 어떻게 해야 사람들이 사는지는 모른다.
- **진상 세 층이 각각 팬의 예상 하나를 뒤집는다.** 1층은 "해변만 닫으면 안전하다", 2층은 "본 시장 한 사람의 욕심이다", 3층은 "큰 배로 나가 죽이면 끝난다"를 틀리게 만든다. 3층이 가장 무겁다. 배출만 끊으면 오히려 사람 많은 해변으로 간다는 사실이 최종장의 방법을 바꾼다.
- **발견 경로가 장소·물건·현상·NPC로 갈린다.** 한 경로를 놓쳐도 다른 길로 같은 층에 닿는다. 모두 판정 없이 찾는 핵심 단서(`tier:"core"`)이고, 하나하나가 `points`로 다음 걸음을 가리킨다(말뚝의 긁힌 자국이 항구 입구 쪽으로 깊어진다). 막다른 단서가 없다. `reveals`는 "단서를 찾는다"가 아니라 PC가 실제로 보는 것(말뚝의 반달 자국, 끈에 낀 이빨 조각)이다.
- **거대 당근의 단계가 세계와 PC를 함께 바꾼다.** 단계마다 누가 다치고, 무엇이 막히고, PC에게 무엇이 닥치는지(배를 안 빌려준다, 바다 출입이 막힌다, 떠날 길이 바다뿐이다)가 있다.
- **위협 셋이 역할도 종류도 다르다.** 상어(쫓는다), 의회(지킨다·막는다), 현상금 무리(돌아다니며 일을 키운다). 사람 위협이 둘이라 상어가 없는 장면에도 압박이 있다. 단계의 `omens`는 위협이 오기 전에 보이는 구체적 조짐이다.
- **최종 시련은 배워서 이긴다.** 기믹(잠수해 숨을 돌린다)과 약점(부표가 박히면 잠수를 못 한다)을 앞선 위협 단계와 진상 경로에서 배운다. 끝내는 방법 셋은 대가가 다르다. 쓰러뜨리면 사람이 다칠 수 있고, 쫓아내면 상어가 살아남고, 도망치면 남쪽 해변이 희생된다.
- **PC 자리는 추첨된 이유 그대로다.** P1은 사라진 조카(소중한 사람), P2는 보험 실사(직업)로 같은 냉동 창고에 닿는다. 서로 다른 이유로 들어와 같은 진상으로 모인다.

| 항목 | 나쁜 예 | 고친 예 |
|---|---|---|
| 중심 원인 | 사실 상어가 아니라 냉동 창고의 오염 때문이다 (원인을 작게 바꿈) | 원작의 그 상어다. 창고의 배출이 상어를 항구 안까지 끌어들인다 (원인 그대로, 길만 새로) |
| 진상 층 | 2층: 무언가 숨겨진 비밀이 있다 | 2층: 크레인이 관광 기금에서 돈을 받고 밤마다 배출하고, 데일은 결론을 지우고 연구비를 받았다 |
| 위협 단계 | 상어가 점점 위험해진다 | 페리 잔교 아래까지 들어와 대기줄 끝의 사람들을 덮친다 |
| 징조 | 불길한 분위기가 감돈다 | 잔교 기둥의 따개비가 한 줄로 긁혀 떨어져 있다 |
| 거대 당근 단계 | 상황이 악화된다 | 7월 4일 수영 대회가 강행되고 아이 둘이 다친다 / 해안 경비대가 바다 출입을 막는다 |
| 끝내는 방법 | 상어를 죽인다, 상어를 쫓아낸다 (방법과 대가가 없음) | 미끼를 깊은 바다로 끌고 나가 떼어 낸다 / 필요한 것: 장부 증거와 미끼 배 / 대가: 상어는 살아남는다 |

## 3. 실체 없는 최종 시련 — 《힐 하우스의 유령》

최종 시련에 실체 적이 꼭 있어야 하는 것은 아니다. 원작의 마지막 위협이 존재가 아니라 장소·현상·재난·의식 자체일 때만(`sourceFinalThreat.entity: false`) `form:"ordeal"`로 쓴다. 원작에 맞설 괴물이나 사람이 있으면 실체 보스로 쓴다. 쉬워 보여서 고르는 형식이 아니다. 아래는 뼈대의 `finalBoss` 한 블록만 보인 것이다(원작의 원인은 휴 크레인이 지은 집 자체, 무대는 그 집).

```json
{
 "id": "ordeal_house",
 "form": "ordeal",
 "threatId": "th_house",
 "tier": 3,
 "learnFrom": ["th_house_s2", "l2_letters", "l3_contract"],
 "reuses": [{"ref": "l2_letters", "how": "앞에서 읽은 편지 속 이름들을 소리 내어 부르며 서로를 한 방에 붙잡아 둔다"}, {"ref": "l3_contract", "how": "계약서의 조건대로 새벽 햇빛이 드는 동쪽 방까지 버틴다"}],
 "gimmick": {
  "what": "집이 밤마다 방과 복도의 이어짐을 바꾸고, 일행 중 가장 외로운 사람을 골라 '여기 남으라'고 부른다",
  "effect": "길을 외워도 소용없다. 부름에 대답한 사람은 스스로 서재 탑의 철제 계단을 오르고, 붙잡으러 간 사람까지 함께 위험해진다"
 },
 "phases": [
  {"trigger": "자정, 2층 복도에서 문 두드리는 소리가 시작될 때", "change": "복도와 방의 이어짐이 바뀌어 일행이 흩어진다"},
  {"trigger": "한 사람이 자기 이름을 부르는 소리에 대답하면", "change": "그 사람이 서재 탑 계단을 오르기 시작하고, 계단이 벽에서 떨어져 나가기 시작한다"},
  {"trigger": "새벽 4시가 지나도 일행이 흩어져 있으면", "change": "집이 정문을 지우고, 남은 사람들의 방이 서로 닿지 않는다"}
 ],
 "hazards": [
  {
   "id": "hz_knock",
   "trigger": "자정, 복도의 문 두드림이 어느 방 앞에서 멈출 때",
   "target": "그 방 안의 모두",
   "where": "2층 복도 끝 방",
   "check": {"skill": "POW", "required": "regular"},
   "sanTier": 3,
   "stop": "서로 손을 잡고 소리 내어 이름을 부르면 두드림이 다음 방으로 옮겨 간다"
  },
  {
   "id": "hz_stair",
   "trigger": "부름에 대답한 사람이 서재 탑 계단에 오를 때",
   "target": "계단 위의 사람과 붙잡으러 올라간 사람",
   "where": "서재의 철제 나선 계단",
   "check": {"skill": "민첩", "required": "hard"},
   "hp": "3d6",
   "stop": "계단 아래 고정 볼트를 다시 조이거나, 올라간 사람을 등 뒤에서 끌어안아 함께 내려온다"
  },
  {
   "id": "hz_cold",
   "trigger": "아이 방 문 앞의 차가운 자리를 지날 때",
   "target": "지나가는 사람",
   "where": "2층 아이 방 문 앞",
   "check": {"skill": "건강", "required": "regular"},
   "hp": "1d6",
   "stop": "아이 방 문을 열어 두고 불을 켜 두면 차가운 자리가 줄어든다"
  }
 ],
 "weakness": {"what": "집은 서로의 이름을 소리 내어 부르며 한 방에 모인 사람들을 갈라놓지 못한다. 새벽 햇빛이 들면 문이 제자리로 돌아온다", "learnFrom": ["l2_letters", "th_house_s2", "l3_contract"]},
 "counter": "모두 한 방에 모여 서로 이름을 부르며 새벽까지 버티고, 부름에 대답한 사람은 계단 볼트를 조인 뒤 끌어내린다",
 "withoutCounter": "흩어진 채 각자 길을 찾으면 집이 한 사람씩 탑 계단으로 불러올리고, 남은 사람은 문이 없는 방에 갇힌다",
 "resolutions": [
  {
   "kind": "rescue",
   "how": "부름을 받은 사람을 탑 계단에서 끌어내리고 새벽까지 한 방에서 함께 버틴다",
   "needs": "계단 볼트 위치, 서로 부를 이름, 한 방에 모일 시간",
   "cost": "집은 그대로 남아 다음 손님을 기다린다"
  },
  {
   "kind": "severSource",
   "how": "휴 크레인이 딸들에게 남긴 서약서를 찾아 집 밖 햇빛 아래에서 태운다",
   "needs": "서재 비밀 서랍의 서약서, 정문까지의 길",
   "cost": "태우는 사람이 집의 마지막 부름을 듣는다(이성 판정)"
  },
  {"kind": "escape", "how": "새벽 첫 햇빛에 정문이 돌아오는 순간 모두 함께 빠져나간다", "needs": "정문까지의 길, 모두가 한 방에 모여 있을 것", "cost": "집의 비밀은 묻히고, 누군가는 그 집에 이름을 남긴다"}
 ]
}
```

좋은 점:
- **괴물 수치를 지어내지 않았다.** 위험은 `hazards`에 실제 값으로 있다. 언제(`trigger`) 누구에게(`target`) 어디서(`where`), PC가 어떤 판정으로 맞서고(`check`), 실패하면 얼마나 다치거나(`hp`) 어떤 이성 판정을 겪는지(`sanTier`), 무엇을 하면 멈추는지(`stop`)가 정해져 있다. 키퍼는 이걸로 피해와 이성 판정을 실제로 집행한다.
- **보스에 필적한다.** 실체 없는 시련은 실체 보스의 최소치보다 높아야 한다. 3등급이면 한 번에 12 이상과 이성 판정 3등급이다. 탑 계단(`3d6`, 최대 18)과 문 두드림(3등급)이 채운다.
- **쓰러뜨리기가 없다.** 없는 적을 쓰러뜨리는 형식으로 바꾸지 않았다. 끝내는 방법은 구조(`rescue`), 근원 차단(`severSource`), 탈출(`escape`)이다.
- **약점이 원작의 공포 문법에서 나온다.** 집은 외로운 사람을 고른다. 그래서 모두 한 방에 모여 서로 이름을 부르면 갈라놓지 못한다.

| 항목 | 나쁜 예 | 고친 예 |
|---|---|---|
| 형태 | 집의 원령(HP 40, 할퀴기 1d10) (없는 괴물을 만듦) | `form:"ordeal"`, 위험 셋을 실제 값으로 |
| 위험 | 집이 사람을 공격한다 | 부름에 대답한 사람이 서재 탑 계단에 오르면 계단이 벽에서 떨어진다(민첩 어려움, 3d6) |
| 멈추는 조건 | 용기를 내면 이겨 낸다 | 계단 아래 고정 볼트를 다시 조이거나, 올라간 사람을 등 뒤에서 끌어안아 함께 내려온다 |

## 4. 세계 상세 발췌 — 《죠스》

세계 상세는 장소 12곳, NPC 15명, 적 5종 이상이다. 아래는 종류마다 하나씩만 뽑았다(문서는 2개 이상, 소소한 사건은 5개 이상이 필수라 그만큼 실었다). 나머지도 이만큼 구체적이어야 한다. 날씨(`weather`)는 필수, 물때(`tide`)·여닫는 시간(`hours`)·퍼즐(`puzzles`)은 원작에 맞을 때만 넣는다.

```json
{
 "conditions": [
  "7월 초 여름밤은 9시에야 어두워진다",
  "연휴 내내 폭풍 주의보로 바다가 거칠다"
 ],
 "weather": {
  "season": "summer",
  "climate": "coast"
 },
 "tide": {
  "highAt": "17:30"
 },
 "documents": [
  {
   "id": "doc_ledger_page",
   "kind": "ledger",
   "title": "냉동 창고 출하 장부의 한 장",
   "author": "창고 주임의 글씨",
   "date": "6월",
   "body": "6월 3일 — 대구 240상자 출하. 잔여 폐기 0.\n6월 10일 — 고등어 310상자 출하. 잔여 폐기 0.\n6월 17일 — 출하 없음. 위생 처리비 입금(관광 기금).\n6월 24일 — 출하 없음. 위생 처리비 입금(관광 기금).\n\n연필로 덧쓴 글씨: 폐기는 0인데 드럼통은 왜 매주 비는가.",
   "attach": {
    "pathId": "l2_ledger"
   }
  },
  {
   "id": "doc_report_draft",
   "kind": "note",
   "title": "찢긴 보고서 초안",
   "author": "D. 코빈",
   "pieces": [
    {
     "body": "…표지를 단 개체는 5월 말부터 항구 입구를 떠나지 않았다. 먹이가 매일 같은 자리에서 나오기 때문으로 보인다. 결론:",
     "attach": {
      "locationId": "loc_outfall"
     }
    },
    {
     "body": "이 개체는 항구에 머문다. 배출이 계속되는 한 떠나지 않을 것이다. (이 문단 전체에 붉은 줄이 그어져 있다.)",
     "attach": {
      "pathId": "l3_tracklog"
     }
    }
   ],
   "completes": "l2_dale"
  }
 ],
 "incidents": [
  {
   "id": "inc_gulls",
   "text": "갈매기 떼가 생선 상자를 쪼다가 한꺼번에 날아오른다.",
   "where": [
    "shore",
    "dock"
   ],
   "when": "day"
  },
  {
   "id": "inc_radio",
   "text": "잔교 끝 낚시꾼의 라디오에서 야구 중계가 지직거린다.",
   "where": [
    "dock"
   ]
  },
  {
   "id": "inc_truck",
   "text": "아이스크림 트럭의 종소리가 해변 쪽에서 가까워졌다 멀어진다.",
   "when": "day"
  },
  {
   "id": "inc_flags",
   "text": "연휴 깃발 줄이 바람에 한 번 크게 펄럭인다.",
   "where": [
    "road",
    "dock",
    "shore"
   ]
  },
  {
   "id": "inc_compressor",
   "text": "냉동 창고 압축기가 덜컹 멈췄다가 다시 돈다.",
   "where": [
    "loc_outfall"
   ]
  },
  {
   "id": "inc_bell",
   "text": "항로 부표의 종이 밤바다에서 느리게 울린다.",
   "where": [
    "shore",
    "dock",
    "water"
   ],
   "when": "night"
  }
 ],
 "puzzles": [
  {
   "id": "pz_locker",
   "kind": "lock",
   "title": "주임의 사물함 자물쇠",
   "prompt": "사물함 문 안쪽에 분필로 적힌 글: '첫 배가 들어온 해, 거꾸로.'\n벽의 액자에는 '크레인 수산 — 1948년 첫 출하'라고 적혀 있다.",
   "answer": [
    "8491"
   ],
   "hint": "액자의 연도를 뒤에서부터 읽는다.",
   "attach": {
    "locationId": "loc_outfall"
   },
   "reward": {
    "pathId": "l2_ledger"
   }
  }
 ],
 "map": {
  "areas": [
   {
    "id": "ar_amity",
    "name": "애미티 섬",
    "x": 55,
    "y": 50,
    "kind": "island",
    "note": "여름 휴양지. 연휴 손님으로 붐빈다"
   },
   {
    "id": "ar_mainland",
    "name": "본토 항구",
    "x": 15,
    "y": 30,
    "kind": "town",
    "note": "페리로 40분"
   }
  ],
  "regions": [
   {
    "id": "rg_town",
    "areaId": "ar_amity",
    "name": "애미티 시내",
    "open": true
   },
   {
    "id": "rg_harbor",
    "areaId": "ar_amity",
    "name": "어항과 방파제",
    "open": false
   }
  ],
  "routes": [
   {
    "from": "ar_mainland",
    "to": "ar_amity",
    "how": "페리",
    "minutes": 40
   }
  ]
 },
 "locations": [
  {
   "id": "loc_outfall",
   "name": "냉동 창고 뒤 배출구",
   "regionId": "rg_harbor",
   "pos": {
    "x": 72,
    "y": 64
   },
   "terrain": "shore",
   "look": "생선 기름이 번들거리는 배출구와 빈 드럼통 더미",
   "ambience": {
    "calm": "seaside_day",
    "dread": "harbor_storm"
   },
   "connections": [
    {
     "to": "loc_jetty",
     "minutes": 4
    },
    {
     "to": "loc_breakwater",
     "minutes": 6
    }
   ],
   "exits": [
    "창고 옆 좁은 자갈길을 따라 4분이면 어항 잔교",
    "물가 바위를 타고 6분 내려가면 방파제 뿌리"
   ],
   "hidingSpots": [
    "빈 드럼통 더미 뒤",
    "창고 지하 수문실 계단 밑"
   ],
   "items": [
    "it_barrels"
   ],
   "conditions": [
    "바닥이 생선 기름으로 미끄럽다",
    "배출구 바로 앞은 발이 닿지 않는 깊은 물",
    "자정에는 찌꺼기 냄새로 숨쉬기 힘들다"
   ]
  }
 ],
 "npcs": [
  {
   "id": "npc_hal",
   "name": "핼 마시",
   "age": 67,
   "profession": "은퇴한 상어잡이",
   "appearance": "한쪽 귀가 없는 늙은 어부, 소금기에 하얗게 바랜 모자",
   "looks": {
    "face": "깊게 팬 주름과 가는 눈",
    "hair": "짧게 깎은 흰 머리",
    "mark": "왼쪽 귀가 없다",
    "outfit": "소금기에 바랜 모자와 기름 먹인 작업복"
   },
   "knownBy": [
    "P1"
   ],
   "depth": "core",
   "basis": "어부와 현상금 사냥꾼",
   "type": "fixer",
   "typeLine": "상어는 자기만 안다고 믿는다. 누가 작살을 잘못 쥐면 말없이 빼앗아 고쳐 쥐여 준다",
   "origin": {
    "kind": "resident",
    "since": "이 섬에서 나고 자랐다"
   },
   "incident": {
    "exposure": "saw",
    "line": "토미가 사라지기 전날 밤, 배출구 근처 물 위로 올라온 지느러미를 잔교 끝에서 봤다"
   },
   "want": {
    "line": "토미 일을 신고하지 않은 걸 누구에게든 털어놓고 용서받는 것",
    "about": "npc_tommy_mother",
    "toward": "avoid",
    "ifLeft": "토미 어머니가 잔교에 찾아오면 핼은 헛간 문을 걸고 나오지 않는다. 그녀는 문 앞에 꽃을 두고 간다"
   },
   "first": "낯선 사람이 잔교에 들어서면 그물 깁던 손을 멈추고 신발부터 본다. 뱃사람 신발이 아니면 다시 그물을 집는다",
   "crisis": {
    "does": "작살을 들고 물가로 먼저 뛰어든다. 남이 막아도 듣지 않는다",
    "effect": "lead"
   },
   "protects": [
    "자기 헛간의 작살과 드럼통",
    "토미 가족"
   ],
   "knows": [
    "굶은 상어는 피 냄새 띠를 따라 얕은 모래톱까지 올라온다",
    "냉동 창고가 밤마다 무언가를 흘려보낸다는 것"
   ],
   "doesNotKnow": [
    "의회 기금에서 크레인에게 돈이 나간다는 것"
   ],
   "hides": [
    {
     "what": "토미가 사라지기 전날 밤, 배출구 근처에서 지느러미를 보고도 신고하지 않았다",
     "why": "크레인 창고에서 헐값에 얼음을 얻어 겨우 배를 유지하고 있어서, 창고 일이 알려지면 배를 잃는다"
    }
   ],
   "voice": {
    "samples": [
     "바다는 거짓말을 안 해. 거짓말은 뭍에서 하지.",
     "그놈은 배고플 때 얕은 데로 와. 배부를 땐 너희 따위 안 봐."
    ],
    "honorific": "반말",
    "register": "짧고 거칠다"
   },
   "schedule": [
    {
     "fromMinute": 0,
     "toMinute": 300,
     "locationId": "loc_jetty",
     "doing": "잔교 끝에서 그물을 깁는다"
    },
    {
     "fromMinute": 300,
     "toMinute": 1440,
     "locationId": "loc_hal_shed",
     "doing": "헛간에서 술을 마시며 작살을 간다"
    }
   ],
   "ifPcAbsent": "연휴 둘째 날 밤 혼자 작은 배를 끌고 나가 상어를 잡으려다 배가 뒤집힌다",
   "helpLimit": "작살과 드럼통은 빌려주지만, 크레인 창고에 대해서는 증거를 보기 전엔 말하지 않는다",
   "refuses": "의회 사람과 같은 자리에 서는 것",
   "quirk": "상어 얘기만 나오면 무섭게 진지하다가, 갈매기가 모자를 채 가면 온 잔교를 뛰어다니며 욕을 한다",
   "values": [
    "정직함",
    "용감함"
   ],
   "socialSkill": 55,
   "profile": {
    "likes": "새벽 썰물 때의 잔교, 독한 럼 한 모금",
    "dislikes": "넥타이 맨 의회 사람들, 상어를 그냥 '물고기'라고 부르는 말",
    "fears": "토미 어머니의 얼굴을 다시 마주하는 것"
   },
   "favoriteGift": "철물점의 새 낚싯줄 한 타래(헛간의 줄은 다 삭았다)",
   "personalStories": [
    {
     "id": "ps_hal_boat",
     "ask": "압류 딱지가 붙기 전에 자기 배 '메리 엘런'의 엔진 부품을 크레인 창고에서 몰래 되찾아 와 달라",
     "steps": "냉동 창고 뒤 배출구 옆의 부품 상자를 열고, 잔교의 핼에게 가져간다",
     "reward": "상어가 배를 들이받는 순간 핼이 키를 꺾어 한 번 피하게 한다",
     "clueFragment": {
      "pathId": "l2_outfall",
      "text": "부품 상자 옆 배수 밸브는 밤 열 시마다 열린다"
     }
    },
    {
     "id": "ps_hal_tommy",
     "ask": "토미 어머니에게 그날 밤 자기가 본 것을 대신 전해 달라. 자기는 그 집 문을 두드릴 수 없다",
     "steps": "토미의 집에 가서 핼의 말을 전하고, 어머니의 대답을 핼에게 가져온다",
     "reward": "최종전에서 핼이 자기 작살을 PC에게 넘기고 드럼통을 직접 박는다",
     "clueFragment": {
      "pathId": "l3_hal",
      "text": "굶은 상어는 피 냄새 띠를 따라 얕은 모래톱까지 올라온다"
     }
    }
   ],
   "onThreat": "바다 쪽을 보지 않으려 등을 돌리고 그물만 만진다",
   "lie": {
    "claim": "토미가 사라진 날 밤엔 배출구 근처에 가지도 않았다",
    "truth": "그날 밤 핼은 배출구 옆에서 크레인 창고의 얼음을 받다가 지느러미를 보고도 신고하지 않았다",
    "breakers": [
     "l2_outfall"
    ],
    "lieLine": 1,
    "afterBreak": "confess",
    "testimony": [
     {
      "line": "그날은 독감이라 하루 종일 헛간에 누워 있었어.",
      "pressed": "난로 옆에서 땀만 뻘뻘 흘렸지. 장화? 그건 아침에 젖은 거고.",
      "tell": "장화 쪽으로 눈길이 갔다가 얼른 돌아온다."
     },
     {
      "line": "배출구? 난 그 근처엔 얼씬도 안 해. 냄새가 지독하거든.",
      "pressed": "얼음은…… 크레인네 창고에서 받긴 했지. 낮에. 낮에 말이야.",
      "tell": "말하면서 손가락에 낀 비늘을 바지에 문지른다."
     },
     {
      "line": "토미는 바다를 무서워할 줄 몰랐어. 그게 다야.",
      "pressed": "그 애가 부두 끝에서 손 흔들던 게 마지막이야.",
      "tell": "토미 이름에서 목소리가 갈라진다."
     }
    ],
    "motive": "guilt",
    "askBack": {
     "question": "……내가 그날 봤다고 치자고. 그럼 내가 그 애를 죽인 거야?",
     "answers": [
      {
       "text": "당신 탓이 아닙니다. 지금 말하면 다음 아이는 살릴 수 있어요.",
       "fits": "yes"
      },
      {
       "text": "그건 들어 봐야 알죠.",
       "fits": "maybe"
      },
      {
       "text": "신고 안 했으면 공범이나 마찬가지죠.",
       "fits": "no"
      }
     ]
    },
    "confessLine": "……봤어. 지느러미를. 문짝만 한 걸. 근데 그걸 누가 믿어 줘.",
    "afterHelp": "크레인 창고 뒷문 열쇠가 어디 있는지 알려 준다"
   },
   "turnConditions": [
    {
     "to": "ally",
     "condition": "PC가 토미의 이빨 조각을 보여 주며 그를 탓하지 않는다"
    },
    {
     "to": "flee",
     "condition": "보이드가 그의 배를 압류하겠다고 위협한다"
    }
   ],
   "stats": {
    "HP": 11
   },
   "sheet": {
    "characteristics": {
     "STR": 55,
     "CON": 60,
     "SIZ": 60,
     "DEX": 45,
     "APP": 35,
     "INT": 60,
     "POW": 55,
     "EDU": 40
    },
    "san": 48,
    "luck": 35,
    "skills": {
     "던지기": 60,
     "조종(배)": 70,
     "자연사": 55,
     "듣기": 50
    },
    "inventory": [
     {
      "name": "녹슨 작살",
      "sizeClass": "large",
      "quantity": 1,
      "desc": "자루에 소금 결정이 낀 손작살"
     }
    ],
    "knowsNpcs": [
     "npc_boyd",
     "npc_crane"
    ]
   }
  }
 ],
 "enemies": [
  {
   "id": "en_white",
   "name": "애미티의 백상아리",
   "appearance": "작은 배보다 긴 회색 등과 하얀 배, 수면 위로 드러나는 세모 지느러미와 검고 둥근 눈",
   "tier": 2,
   "threatId": "th_shark",
   "attacks": [
    {
     "name": "물어 끌고 들어가기",
     "damageExpr": "2d6+DB",
     "range": "접촉(물속·물가)",
     "skill": "물기"
    },
    {
     "name": "배 들이받기",
     "damageExpr": "1d6",
     "range": "배 한 척",
     "skill": "들이받기"
    }
   ],
   "chasePattern": {
    "speed": "fast",
    "givesUpRounds": 3
   },
   "sanTier": 2,
   "stats": {
    "HP": 32,
    "DB": "1d6",
    "DEX": 60,
    "물기": 55,
    "들이받기": 50,
    "장갑": 2
   },
   "tier2Banish": "부표 셋이 박히고 크게 다치면 깊은 바다로 물러나 다시 돌아오지 않는다",
   "origin": "source",
   "basis": "거대 백상아리",
   "memory": "피 냄새가 남은 물길은 하루 넘게 다시 돌아와 맴돈다",
   "giveUp": "냄새가 끊기고 먹이가 없으면 반나절 뒤 사람 많은 물가로 옮겨 간다",
   "blockedBy": "뭍, 썰물에 드러난 모래톱, 촘촘한 그물",
   "signature": "부표가 물살을 거슬러 끌려가고, 물린 자리에 반달 모양 이빨 자국이 줄지어 남는다",
   "weakness": {
    "what": "굶은 채 얕은 모래톱으로 올라오면 등이 드러나 부표를 박을 수 있다",
    "learnFrom": ["l3_hal", "l3_sandbar", "th_shark.th_shark_s2"]
   }
  }
 ],
 "items": [
  {
   "id": "it_barrels",
   "name": "노란 드럼통 부표 세 개",
   "sizeClass": "haul",
   "locationId": "loc_outfall",
   "quantity": 3,
   "desc": "빈 노란 드럼통에 밧줄과 작살 고리를 단 것. 물에 띄우면 사람 둘이 매달려도 가라앉지 않는다",
   "lore": "크레인은 찌꺼기를 이 드럼통에 담아 버리다가, 감사가 나온다는 소식에 비워서 창고 뒤에 숨겼다. 통 안쪽에 아직 비린 기름이 말라붙어 있다",
   "concealed": {
    "where": "냉동 창고 뒤 빈 드럼통 더미 맨 아래, 방수포 밑",
    "requires": "자정 배출 때 경비가 자리를 비우는 틈을 노리거나, 핼 마시가 위치를 알려 준다"
   },
   "lies": {
    "kind": "noisy",
    "how": "빈 드럼통 더미를 무너뜨려야 맨 아래 세 개가 나온다. 쇠통 구르는 소리가 부두 끝까지 울린다",
    "quietBy": ["밧줄로 위의 통을 하나씩 매달아 내리기", "자정 배출 소음에 맞춰 끌어내기"]
   },
   "ownerId": "npc_hal"
  }
 ],
 "kitMoments": [
  {
   "slot": "P1",
   "item": "방수 손전등",
   "locationId": "loc_outfall",
   "how": "자정 배출 때 수문실 계단 밑은 빛 한 점 없다. 손전등이 있으면 드럼통 더미 아래 방수포를 찾아낸다"
  },
  {
   "slot": "P1",
   "item": "나일론 밧줄 한 타래",
   "locationId": "loc_outfall",
   "how": "배출구 앞 깊은 물에 빠진 사람을 끌어올리거나 드럼통 셋을 한 줄로 묶어 부표를 만든다"
  },
  {
   "slot": "P1",
   "item": "아버지의 수중 칼",
   "locationId": "loc_outfall",
   "how": "상어가 물고 끌어갈 때 아가미를 찔러 한 번 놓치게 만든다"
  }
 ],
 "start": {
  "settling": {
   "unease": [
    "어항 잔교에 앉은 갈매기들이 물 쪽으로는 한 마리도 내려앉지 않는다",
    "굴 따는 아이들이 오늘은 하나도 보이지 않는데, 아무도 그 이유를 말하지 않는다",
    "식당 주인이 '해산물 오늘 없음' 팻말을 걸었다가 손님이 오자 급히 뗀다",
    "새벽 3시, 항구 안쪽에서 무언가 큰 것이 수면을 치는 소리가 한 번 들린다"
   ],
   "traces": [
    {
     "what": "방파제 아래 말뚝에 반달 모양으로 줄지어 파인 자국",
     "enemyId": "en_white"
    },
    {
     "what": "잔교 끝에 묶어 둔 고깃배 그물이 통째로 찢겨 물에 늘어져 있다",
     "enemyId": "en_white"
    },
    {
     "what": "섬 신문 구석 '익사 사고' 기사 옆, 누군가 볼펜으로 지느러미를 그려 놓았다",
     "enemyId": "en_white"
    }
   ]
  }
 },
 "townAttitude": {
  "kind": "hushed",
  "how": "애미티 사람들은 상어 이야기가 나오면 관광철 걱정으로 말을 돌린다"
 },
 "outsideHelp": {
  "means": "항만 사무소의 해안 경비대 무선",
  "ifCalled": "해안 경비대 순시선 한 척이 잠수부 둘을 싣고 온다",
  "why": "시장이 '상어는 이미 잡혔다'고 먼저 보고해서, 경비대는 7월 4일 행사가 끝난 뒤에야 확인하러 나선다",
  "arrivesAtMinute": 3000,
  "withExit": {"kind": "meet", "how": "순시선은 행사가 끝난 뒤에야 항구 밖에 닿는다. 그 전에 PC가 배로 모래톱까지 나가 상어를 묶어 두어야 순시선이 그 배를 받아 준다"}
 },
 "redHerrings": [
  {
   "id": "rh_tiger",
   "claim": "잔교에 매달린 뱀상어가 바로 아이들을 문 그 상어다",
   "foundAt": "loc_outfall",
   "points": "npc_dale",
   "refutedBy": "l3_tracklog",
   "alsoUseful": "데일은 그 뱀상어의 배를 갈라 보자며 연구소 냉장 창고 열쇠를 빌려주고, 거기서 항적 기록 이야기를 꺼낸다",
   "believedBy": "npc_dale",
   "why": "자기 배로 그 뱀상어를 잡아 올린 날, 시장이 사진을 찍고 상금을 줬다. 아니라면 그 돈을 돌려줘야 한다"
  }
 ]
}
```

좋은 점:
- **핼은 가까워질 거리와 거짓말을 함께 지닌다.** 좋아하는 행동(정직함·용감함), 프로필, 좋아하는 선물, 개인 이야기 둘(끝내면 위기 때 한 번 돕고 본편 단서 조각을 준다)이 그의 처지에서 나온다. 거짓말("배출구 근처에 가지도 않았다")은 숨기는 것(`hides`)과 같은 일이고, 깨는 증거는 정상 경로 위의 핵심 단서(`l2_outfall`)다. 증언 셋 중 둘째 줄에 거짓말이 있고, 캐물으면 손에 묻은 얼음 부스러기가 보인다.
- **엇나간 단서도 헛걸음이 아니다.** 잔교에 매달린 뱀상어는 "잡혔다"는 착각을 주지만 항적 기록(`l3_tracklog`)으로 쉽게 반박되고, 그것을 따라간 데일에게서 다른 쓸모(연구소 창고 열쇠)를 얻는다.
- **장소의 `exits`는 실제 길이다.** "북쪽 문, 남쪽 문"을 복사하지 않고 무엇을 따라 몇 분 가면 어디인지 쓴다. `conditions`는 판정의 근거다(기름으로 미끄러운 바닥, 발이 닿지 않는 깊은 물).
- **핵심 NPC는 자기 사정으로 움직인다.** 핼 마시는 아는 것과 모르는 것, 숨기는 것과 그 이유(얼음을 헐값에 얻어 배를 유지한다)가 있다. PC가 없으면 혼자 나가 일을 벌이고(`ifPcAbsent`), 도움에는 한계가 있다(`helpLimit`). 말투 예시는 다른 NPC와 겹치지 않는다.
- **핵심 NPC에게 허당끼(`quirk`)가 있다.** 상어 앞에서 무섭게 진지한 늙은 어부가 갈매기에게 모자를 뺏기면 잔교를 뛰어다닌다. 공포 사이의 웃음은 이런 엇갈림에서 나온다(04a 7절).
- **시작 물건 후보마다 빛날 자리가 있다(`kitMoments`).** P1이 손전등·밧줄·수중 칼 중 무엇을 골라도 배출구에서 그 물건이 판을 바꾼다.
- **동행 후보에게는 `sheet`가 있다.** 신뢰까지 쌓인 뒤(04 8절) PC를 잃은 플레이어가 핼 마시를 이어받을 수 있게 능력치·이성·행운·기능이 실제 값으로 있다(05 7절).
- **보스 적이 뼈대와 맞는다.** 위협 `th_shark`의 2등급 적으로 HP 32, 한 번에 최대 18, 이성 판정 2등급, 퇴거 조건이 있다. 공격은 원작의 공격(물어 끌고 들어가기, 배 들이받기)을 그대로 쓴다.
- **최종장 열쇠 물건은 숨어 있다.** 드럼통은 그냥 놓여 있지 않고 숨은 자리와 찾는 조건(`concealed`)이 있다. 사연(`lore`)이 물건과 진상을 잇는다(찌꺼기를 담아 버리던 통).
- **바깥의 도움에 언제와 왜가 있다(`outsideHelp`).** 일찍 무전을 쳐도 시장의 거짓 보고 때문에 경비대는 행사가 끝난 뒤에야 온다. 연락이 이야기를 끝내지 않고 오히려 시장의 은폐를 드러낸다. 순시선은 출항 시련의 끝에서 PC의 배를 받을 뿐(`withExit: meet`), 모래톱의 최종장을 대신 치르지 않는다.
- **유예 30턴의 재료가 이 무대에만 맞는다.** 위화감은 평소와 어긋난 작은 것(물 쪽에 안 내려앉는 갈매기)이고, 흔적은 위협이 남긴 것(말뚝의 자국)이다.

| 항목 | 나쁜 예 | 고친 예 |
|---|---|---|
| 출구 | 북쪽 길, 남쪽 길 (모든 장소에 같은 문장) | 창고 옆 좁은 자갈길을 따라 4분이면 어항 잔교 |
| NPC가 숨기는 것 | 무언가 비밀이 있다 / 사정이 있다 | 토미가 사라지기 전날 밤 지느러미를 보고도 신고하지 않았다 / 창고에서 얼음을 헐값에 얻어 배를 유지해서 |
| 위화감 | 분위기가 이상하다 | 굴 따는 아이들이 오늘은 하나도 보이지 않는데 아무도 이유를 말하지 않는다 |
| 물건 사연 | 오래된 드럼통 | 크레인이 찌꺼기를 담아 버리다 감사 소식에 비워 숨겼다. 안쪽에 비린 기름이 말라붙어 있다 |

## 5. 합류 사건 — 《컨저링》 (한 번에 1~3개씩 낸다)

**가정:** 《컨저링》 교차형, 1971년 10월 로드아일랜드 해리스빌(04a와 같은 세계). 원작의 원인(1863년 마녀 밧세바의 저주, `ritual`·`town`)은 그대로 두고, 저주가 교구 세례 기록에 이름이 오른 다른 가문에도 번져 있다는 쪽으로 길을 새로 냈다. 진상 2층은 "교구 사람들은 피해 가족 편이다"를, 3층은 "원작처럼 퇴마하면 끝난다"를 뒤집는다.

```json
{
 "id": "ev_wardrobe",
 "order": 3,
 "title": "에드나네 아이 방 장롱",
 "crisisType": "rescue",
 "locationId": "loc_fellows_house",
 "preState": "에드나는 손녀 루시를 재우고 부엌에서 뜨개질을 한다. 아이 방 장롱 문이 저녁마다 조금씩 열려 있다.",
 "crisis": "자정 무렵 장롱 안에서 손뼉이 두 번 울리고, 루시가 대답하듯 따라 친다. 다음 손뼉이 울리면 루시는 장롱 안으로 걸어 들어가고 문이 안에서 잠긴다.",
 "responses": ["장롱 문을 몸으로 막는다", "루시를 안고 방을 나간다", "손뼉에 먼저 대답해 주의를 끈다"],
 "outcomes": {
  "success": "루시가 무사하고, 장롱 바닥 판자 밑에서 1863년 세례명이 새겨진 아이 신발 한 짝이 나온다.",
  "partial": "루시를 끌어내지만 PC 하나가 장롱 안 어둠에 팔을 붙잡혀 다친다.",
  "failure": "루시가 사라지고, 다음 날 아침 우물가에서 젖은 채 발견된다. 말을 하지 않는다.",
  "ignored": "에드나가 혼자 방에 들어갔다가 계단에서 굴러 떨어진다."
 },
 "next": ["신발에 새겨진 이니셜이 교구 세례 기록으로 이어진다"],
 "triggeredBy": "th_child_s2",
 "sourceElement": {"iconic": 1, "how": "손뼉 숨바꼭질을 아이 방에서 직접 듣고, 대답하면 무엇이 오는지 겪는다"},
 "twist": {
  "expect": "장롱 속에서 손뼉을 치며 루시를 부르는 건 밧세바다.",
  "actual": "손뼉을 치는 건 밧세바에게 먼저 잡힌 아이의 혼이다. 루시에게 숨으라고 부르는 것이고, 장롱 문을 안에서 잠그는 손이 밧세바다.",
  "axis": "identity",
  "layer": 0
 },
 "onSite": {
  "hazards": [{"what": "장롱 안 어둠이 팔을 붙잡아 판자 모서리에 짓누른다", "skill": "근력", "hp": "1d6"}],
  "sanChecks": [{"tier": 2, "what": "잠긴 장롱 안에서 루시와 다른 아이가 함께 웃는 소리"}]
 },
 "smallCarrots": [
  {"id": "sc_ward_a", "goal": "에드나가 손녀 방 장롱 얘기를 하다 말을 끊는 이유를 알아낸다", "via": {"kind": "npc", "ref": "npc_edna"}},
  {"id": "sc_ward_b", "goal": "고모 편지에 적힌 '손뼉 치는 집' 주소를 찾아간다", "via": {"kind": "item", "ref": "it_aunt_letter"}}
 ],
 "pcTest": [{"slot": "P1", "of": "flaw", "choice": "장롱 안 손뼉에 직접 대답해 루시 대신 자신이 불려 갈지, 루시만 안고 나와 장롱 속 다른 아이의 혼을 버려둘지"}],
 "aftermath": {
  "reactions": "에드나는 루시를 품에 안고 밤새 장롱 문에 의자를 괴어 둔다. 이웃들은 아침부터 펠로스네 집 앞을 일부러 돌아서 간다.",
  "relationships": "에드나는 그동안 숨겨 온 손녀 이야기를 PC들에게 처음 털어놓는다. 대신 교구 신부에게는 더 말을 아낀다."
 },
 "pcRoles": [
  {"slot": "P1", "does": "장롱 문을 붙잡아 루시가 들어갈 시간을 늦춘다(시간)"},
  {"slot": "P2", "does": "부엌의 에드나를 데려와 루시가 따르는 할머니 목소리로 부르게 한다(사람)"}
 ],
 "onlyOne": {"choices": ["npc_lucy", "npc_edna"], "why": "장롱이 루시를 끌어당기는 순간 에드나가 계단에서 발을 헛디딘다. 팔은 둘, 손은 한 사람에게만 닿는다"},
 "ifFailed": "루시를 놓쳐도 우물가로 이어지는 젖은 발자국이 남아, 다음 날 아침 우물에서 루시를 되찾을 길이 열린다.",
 "reusedLater": "장롱 바닥의 아이 신발은 최종장에서 그 아이의 혼을 이름으로 불러 밧세바의 손을 놓게 하는 데 쓰인다."
}
```

좋은 점:
- `crisis`가 장면이다. 누가(루시), 언제(자정), 무엇이(손뼉 → 걸어 들어감 → 문이 잠김) 일어나는지 보인다.
- 결과 네 가지가 서로 다르게 세계를 바꾼다. 실패해도 이야기가 이어진다.
- `twist`는 이 장면의 누가 무엇을 하는지에 대한 예상을 뒤집는다. 원인(밧세바)은 그대로다. 게임 조작에 대한 예상이 아니다. 진상의 층(기록을 숨긴 사람, 풀리는 방법)은 말하지 않으므로 `layer:0`이다. 진상은 뒤쪽 기점이 연다.
- 작은 당근은 실제 사람(에드나)과 물건(편지)이 PC를 부른다. 글에는 id 대신 이름을 쓴다.
- 적·이성 판정을 개수에 맞춰 채우지 않았다. 이 사건의 공포(아이를 지키는 일)에 맞는 위험 하나와 이성 판정 하나다.
- `pcTest`가 P1의 결점(먼저 몸이 나가는 성격)을 실제 선택으로 건다. 두 길 모두 대가가 있고, 고르는 건 플레이어다.
- `aftermath`가 사건 뒤 사람들이 어떻게 달라졌는지 보여 준다(만남 → 이상한 일 → 추리 → 각자의 대응 → 결과 → 달라진 관계의 마지막 칸).
- `pcRoles`로 두 주연이 같은 위기에서 서로 다른 것을 바꾼다(시간·사람). 직업이 아니라 그 자리의 위치·관계로 나뉜다.
- `onlyOne`이 한 명만 구할 수 있는 순간을 준비해 둔다. 누구를 붙잡을지는 플레이어가 고르고, 다른 쪽 사람과의 관계가 내려갈 수 있다.
- `ifFailed`와 `reusedLater`: 실패해도 길이 남고, 여기서 얻은 것이 최종장에서 다시 쓰인다.

### 합류 사건의 나쁜 예와 고친 예

| 항목 | 나쁜 예 (작성 기준 미달) | 고친 예 |
|---|---|---|
| 작은 당근 | 현장에서 구조를 요청한 주민을 만난다 | 에드나가 손녀 방 장롱 얘기를 하다 말을 끊는 이유를 알아낸다 |
| 위기 | 손뼉 숨바꼭질의 공포를 체험한다 (`how`와 같은 말) | 다음 손뼉이 울리면 루시는 장롱 안으로 걸어 들어가고 문이 안에서 잠긴다 |
| 비틀기 expect | 세이브룸은 안전하다 (게임 조작) | 장롱 속에서 손뼉을 치며 루시를 부르는 건 밧세바다 |
| 비틀기 actual | 사실 원인은 밧세바가 아니라 공사 업자의 실수다 (원인을 작게 바꿈) | 손뼉은 먼저 잡힌 아이의 혼이 숨으라고 부르는 것이고, 문을 잠그는 손이 밧세바다 |
| 위험 | 현장의 위험 요소가 PC를 위협한다 | 장롱 안 어둠이 팔을 붙잡아 판자 모서리에 짓누른다 |

나쁜 예는 어느 기점에 붙여도 말이 된다. 그래서 틀 문장이다. 고친 예는 이 기점에만 맞는다.

## 6. PC의 개인 사정 — 《컨저링》

**P2에게 전달할 시작 정보:** 아모스는 교구 기록 상자를 운반하다 다리가 막혀 마을에 갇혔다. 상자 수가 하나 부족하다. 어머니는 기록에 이름이 남은 가문의 집에서 간병 중이며, 어젯밤 통화 때 문을 잠갔는데도 아이 손뼉 소리가 들린다고 했다. 마지막으로 들은 부탁은 “해 뜨기 전에 와 줘”였다. 아모스는 원인이나 사라진 상자의 행방을 아직 모른다.

**키퍼 전용 연결:** 사라진 상자는 노크로스 신부가 옮겼고, 안에 1863년 세례 기록이 있다. 어머니가 돌보는 가족도 그 기록에 연결돼 있다. 어머니를 잠시 대피시키는 성취는 실제 안전과 시간을 주지만, 해당 가문의 연결을 끊으려면 준비된 최종 시련에서 기록의 진상을 이용해야 한다. 이 사실을 시작 자료에 그대로 공개하지 않는다.

좋은 점: 일자리만이 아니라 소중한 사람의 위험과 위협의 원인이 같은 사건에 걸려 있다. 진상이 열릴수록 그가 지키려던 것과 밝혀야 할 것이 부딪친다.

**사연 · 동기 · 대가로 나누면** (02 5절, 엔진이 뽑은 대가가 '소중한 사람의 죽음'인 경우):
- **사연:** 기록 상자를 옮기다 다리가 막혀 갇혔고, 상자 하나가 없어졌다. 어머니는 손뼉 소리가 들리는 집에서 간병 중이다.
- **동기:** ① 질문(각본에서 정함) "사라진 상자에는 무엇이 들었고, 누가 왜 가져갔나" — 그 기록에 어머니가 돌보는 가문의 이름이 있다. ② 끝내야 할 일: 그 가문과 기록의 연결을 끊는다. 최종 시련에서 기록의 진상을 써야만 끊긴다. ③ 오늘: "해 뜨기 전에 와 줘"가 어머니의 마지막 부탁이었다.
- **대가:** 진실도 해결도 못 하고 나가면, 어머니가 그 집에서 마지막 손뼉 소리를 들은 사람이 된다. 조짐: 위협 2단계에 어머니의 전화가 끊기고, 3단계에 그 집 창문이 안에서 하나씩 닫힌다.
