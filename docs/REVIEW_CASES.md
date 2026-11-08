# 통합 경량판 대표·경계 대조

2026-11-08. 현행 담당 본문과 합의의 문서 대조다. 실제 ChatGPT 게임 실행/운영 저장 결과가 아니다. 자동 검사와 실제 이어쓰기 평가는 구분한다. 구판 검토 이력은 Git 기록에 보존되어 있다.

## 서사·원작·스케일·페이싱

| 상황 | 수용할 결과 / 거부할 결과 | 담당 |
|---|---|---|
| 평범한 직업/방문으로 시작 | 초반 직접 충돌·걸린 것·실제 접근. 업무/소문만 무기한 반복은 거부 | 지침 / SCENARIO_BLUEPRINT |
| 원작 요소가 설정에만 존재 | 직접 접촉·갈등·생존·선택·활용으로 연결될 때 완료 | FULL_DIVE_CROSS_ANALYSIS |
| 중요한 장치를 파헤침 | 원래 목적/중요성·악용/진실·위험·활용 연결. 의미 없는 고장으로 모든 공포 소거는 거부 | SCENARIO_BLUEPRINT |
| 큰 사건 생성 | 여러 사람/기관/공동체의 중대한 결과와 실제 위협 실행력/해결. 장소·문서·적 숫자만 증가는 거부 | STORY_SCALE / FINAL_THREAT_DESIGN |
| 영화 예시 반영 | 대응 결과→발견→목표/접근 변화→다음 난관. 배송/강제물림/백신의 공통대본은 거부 | 지침 / SCENARIO_BLUEPRINT |
| PC가 다른 목표에 관심 | 실제 세계가 반응하고 남은 위협은 계속. 같은 예정 장면으로 강제 복귀는 거부 | SCENARIO_OBJECTIVES |
| 중심 원인을 일찍 차단 | 유효한 조기 해결 인정. 추가 보스로 성과 취소는 거부 | FINAL_THREAT_DESIGN |
| 반복 회의/신문 색인/이동 | 목적 단위 압축, 의미 있는 발견/대면/새 비용에서 선택 | CINEMATIC_ELLIPSIS |
| 같은 공간에서 연속 대화 | 직전 변화에서 이어쓰기. 매 응답 공간 소개/같은 질문 반복은 거부 | 지침 / CINEMATIC_ACTION_CONTINUITY |
| 위기와 평온/환기 | 행동/거리/결과의 실제 긴장과 짧은 인물/상황 유머. 매 장면 말장난/공격 의무 없음 | 지침 / QUIET_AFTERMATH_BEAT |
| NPC가 적극 협력/거절 | 실제 목적/정보/비용·관계에서 이유와 선제 행동. 자동동의/반대·무료공격 없음 | NPC_AGENDA_AND_SECRECY / NPC_AGENDA_INTERVENTION |
| 특이한 NPC의 유머 | 행동·관계·상황/타이밍에서 자연스럽게, 위험/인물 일관성 보존 | 지침 |
| 전투 밖 실제 참극/위해 도달 | PC의 필요한 대응·SAN/HP·상태/후속까지 적용. 전조로 되돌리지 않음 | REACHED_DANGER_EXECUTION_GATE |
| 젖음/경미 부상 | 관련 행동의 실제 영향/처치·해제. 이름만 기록/전행동 일괄벌점 모두 거부 | EXTREME_HAZARDS |

## 생성·판정·생존·성장

| 입력/조건 | 기대 | 담당 |
|---|---|---|
| 인원/인지도/규모 누락 | 해당 항목만 질문. 시작 시드는Python자동, 핵심시드입력 없음 | START_SETTINGS_GATE |
| 원작/직업 자동 후보 | 각4개A~D, 직접지정 우선. 기본/테마/조커 슬롯 없음 | HOMAGE_DRAFT_SELECTION / PROFESSION_DRAFT |
| 특성 후보 | 8개합400·각30~80·5단위, Luck20~80별도·균등생성, 안혼합금지 | STAT_DRAFT_GENERATION |
| DEX60·일반 회피 | 회피30/MOV8. 취미/직업이면max(배정,30) | PC_DERIVED_STATS / PC_SKILL_START_VALUES |
| 전문 행동·배우 | 실제 자격/상식/고유 성과, 자동성공없음. 배우1명필수·APP뒤확정 | PROFESSION_SPECIALTY / PC_APPEARANCE_FROM_APP |
| 신문 찾기·명백한 의미 | 자료조사 기본, 읽기/이해를 자동 별도 역사판정하지 않음 | INVESTIGATION_SKILL_ROUTING |
| 기능55의11/27/28 | Extreme/Hard/Regular. 원래45에서96은Fumble | SUCCESS_LEVELS |
| PC 보너스1·기본99/추가98 | 공통일의자리9·십의자리9/9→99/99→99 | BONUS_PENALTY_DICE |
| 보너스2와패널티1 | 상쇄 뒤보너스1. 독립원인을중복가산하지않음 | BONUS_PENALTY_DICE |
| 보통설득60·64·행운체크·Luck10 | 최소4자동차감·잔여6·Regular. 비용숫자입력/재확인없음 | LUCK_SPENDING |
| 요구Hard인데행운Regular전환만가능 | Luck0차감. 성공단계상승없음 | LUCK_SPENDING |
| 양측실패·기능60대55 | 현행 일반대항은동단계·원래기능우위60승. 공식CoC동일주장아님 | GENERIC_OPPOSED_ROLL |
| 회피동단계·반격동단계 | 회피성공/반격은공격개시자우세. 일반대항과구분 | MELEE_OPPOSED |
| 준비총기·엄폐도약 | 발사순서DEX+50, 엄폐Dodge성공공격자패널티1·성패무관다음공격포기 | COMBAT_ORDER / FIREARMS |
| HP11에서단일6피해 | 중상,CON실패의식불명. 중상없는HP0은빈사아닌의식불명 | HP_AND_DEATH / WOUNDS |
| 파우치의료품 | 실제행동/시간·성공1d3, 중상해제불가. 시간정지없음 | HEALING |
| 하루시작SAN53·손실6+5·중간회복3 | 누적11로장기광기기준충족. 분모/손실을회복/로드로초기화하지않음 | INSANITY_CONDITIONS |
| 단일SAN5손실 | INT성공발작/실패즉시발작모면 | INSANITY_CONDITIONS |
| 안전한충분휴식 | 하루1회1d3·최대치이내, 광기자동치료없음.같은휴식중복없음 | DIEGETIC_SAN_RECOVERY |
| 질식중대화/굴림입력·실제행동 | 입력마다피해없음.실제위험구간CON1회/전투라운드1회·실패1d6 | EXTREME_HAZARDS |
| 대사건에서기능성장요구 | 신규영구수치상승없음.획득/지식/현재치회복은유효 | SKILL_IMPROVEMENT / CTHULHU_MYTHOS_SKILL |
| 연대기기능65/79/80/94/95 | 적격경계67/81/81/95/95, 마지막은후보제외.최대2개·중복/소급없음 | SKILL_IMPROVEMENT |

## 시간·UI·기록·엔딩

| 상황 | 기대 | 담당 |
|---|---|---|
| 익숙한경로20분이동 | 실제충돌없으면출발~도착한번,도착후상호작용기회.재검색/전원행동질문없음 | ROUTINE_MOVEMENT_FAST_PATH |
| 5분작업과12분이동병렬 | 5분지점중단이면이동7분남음.12분재계산/25분합산없음 | PARALLEL_TIMELINE_SYNC |
| 다음PC교대 | 자연스러운결과경계·대기우선,고정3/5회·준비A없음,교대시간0 | MULTI_PC_SPOTLIGHT_CONTRACT |
| 정상응답 | 본문/필요입력+정확HUD/인벤토리.별도씬요약·연출의도없음 | BOTTOM_HUD_CONTRACT |
| 메인/파우치/소지물 | 목록/점유량상시,삭제한무료직업품/버프/태그/수첩은신규생성없음 | INVENTORY / STATE_SCHEMA |
| 공개대항결과 | 요구·PC/상대실제값·단계·비교/결과1~2줄.비공개사건/전체시트는숨김 | BOTTOM_HUD_CONTRACT |
| 이미지실패 | 텍스트계속.시작지도는같은공간연결도로대체·이미지성공으로가장하지않음 | START_MAP_HANDOUT_GATE |
| 종료 | 실제성과/손실·열린대응먼저,다섯후일담은한응답씩자세히.이미지Gate로잠그지않음 | ENDING_FINALIZATION_GATE / OPTIONAL_POST_CREDITS_VIEWS |
| 로드 | 이야기/인물/현재장면을첫지문전에복원·완료한의사소통/합의재질문없음 | STATE_EXPERIENCE_CONTINUITY / STATE_RESUME |
| 값은같지만NPC태도이유/마지막질문누락 | 의미/재개문맥검증실패.해시/서버verified만으로완전복원주장없음 | STATE_INTEGRITY |
| 저장장애 | 현재플레이계속·성공은가장하지않음·사건/난수재실행없음 | STATE_SAVE_FAILURE_CONTINUE |

[원작별 합성 설계와 분기 대조](INTEGRATED_SCENARIO_REVIEW.md), [검증 계약 변경 근거](VALIDATION_CONTRACT_CHANGES.md)를 함께 확인한다.

자동 검사: check의154개 의미계약과361/403대응, Python난수분포, 합성세이브30건(실제파일/별도프로세스), 고의규칙훼손18건의거부. 이 표는 실제장기AI플레이/운영저장/응답시간을실행한증거가아니다.
