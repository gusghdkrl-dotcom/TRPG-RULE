"""Reject consequential document regressions in an isolated copy; no game service."""
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
import importlib.util,json,shutil,tempfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('rulebook_check',ROOT/'scripts/rulebook.py')
checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker)

def change(root,path,old,new):
    p=root/path;s=p.read_text();assert old in s,(path,old);p.write_text(s.replace(old,new,1))

def move_priority_last(root):
    p=root/'PROJECT_INSTRUCTIONS.md';s=p.read_text()
    a=s.index('## 최우선 기준');b=s.index('## 진행 순서와 규칙 조회')
    p.write_text(s[:a]+s[b:]+'\n'+s[a:b])

def validate(root):
    checker.ROOT=root;checker.RULES=root/'rules'
    with redirect_stdout(StringIO()):checker.validate()

mutations=[
 ('major_incident_growth',lambda r:change(r,'rules/02-checks.md','CHRONICLE(연대기)에서만','모든 규모에서')),
 ('growth_cap',lambda r:change(r,'rules/02-checks.md','상한은 95','상한은 100')),
 ('san_accumulation',lambda r:change(r,'rules/03-danger.md','회복은 누적 손실을 차감하지 않는다','회복은 손실을 지운다')),
 ('san_recovery',lambda r:change(r,'rules/03-danger.md','극중 하루 1회 SAN 1d3','매 응답 SAN 1d6')),
 ('drowning_scope',lambda r:change(r,'rules/03-danger.md','행동 구간마다 CON1회','채팅마다 CON1회')),
 ('opposed_digits',lambda r:change(r,'rules/02-checks.md','결합 결과 00은 100','결합 결과 00은 0')),
 ('inventory_hidden',lambda r:change(r,'rules/06-play.md','인벤토리 목록과 메인/파우치 점유량은 상시 유지','인벤토리는 표시하지 않음')),
 ('credits_optional',lambda r:change(r,'rules/06-play.md','기본 엔딩의 다섯','요청할 때만 제공하는 다섯')),
 ('scene_context_missing',lambda r:change(r,'rules/07-state.md','scene_context','omitted_context')),
 ('world_scale_weak',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','실행력·파급','장식')),
 ('npc_voice_forgotten',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','상대별 호칭','일반 대화')),
 ('routine_micro_gates',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','단순 확인마다 긴 대사·서류 전문·새 메뉴·입력 대기를 만들지 않는다','모든 확인에서 메뉴를 만들고 입력을 기다린다')),
 ('routine_new_consent',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','미선언 증언·동의는 만들지 않는다','통상 업무의 증언과 동의는 대신 결정한다')),
 ('routine_erases_important_scene',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','중요한 협상·발견·갈등은 직업 업무라는 이유로 축약하지 않는다','직업 업무의 협상과 갈등은 모두 생략한다')),
 ('threat_hud_only',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','살아 있는 위협을 HUD의 경고로만 남겨두지 않는다','위협은 HUD 경고로만 유지한다')),
 ('narrator_inference_coaching',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','지문·NPC 대사·HUD에 플레이어의 추리를 평가하는 검증 안내·면책 해설을 넣지 않는다','플레이어의 추리를 평가하고 추가 검증을 안내한다')),
 ('danger_only_at_finale',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','최종전만 위험하고 나머지는 무손실 조사인 구조를 피한다','최종전까지 모든 조사는 무위험으로 처리한다')),
 ('danger_waits_for_optin',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','플레이어가 위험한 선택지를 고를 때까지 기다리지 않는다','위험 선택지를 고를 때까지 위협을 중지한다')),
 ('san_deferred_to_finale',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN 규칙을 적용하고 전투나 절정까지 미루지 않는다','SAN 처리는 최종전에만 적용한다')),
 ('fixed_injury_quota',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','피해·희생·감염을 할당하지 않는다','매 장면 피해를 할당한다')),
 ('guess_missing_mechanics',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','본문이 없으면 결과 확정 전에 해당 절을 조회','본문이 없으면 일반 기억으로 처리')),
 ('keeper_principle_rewritten',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','그 대응과 결과가 이야기와 세계의 반응으로 이어지게 한다','플레이어의 대응과 무관하게 예정된 사건을 실행한다')),
 ('keeper_reminder_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','> 키퍼 숙지: 위 5요소를 이번 장면과 다음 진행에 적용한다.','')),
 ('keeper_footer_not_last',lambda r:change(r,'rules/06-play.md','이 블록 뒤에 다른 게임 정보를 붙이지 않는다','블록 뒤에 게임 정보를 이어 쓴다')),
 ('keeper_footer_only_rolls',lambda r:change(r,'rules/06-play.md','판정이 없는 일반 장면에도 표시','판정이 있는 때만 표시')),
 ('keeper_rule_application_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','> 4. 준비·세계 생성부터 플레이·상태 관리·저장·복원·종결까지 지침을 숙지하고, 상황별 라우팅으로 필요한 룰북 본문을 확인해 적용한다.','')),
 ('keeper_continuity_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','> 5. 플레이어의 선택과 세계의 인과를 존중하고, 확정된 사실·성과·상태·관계와 진행 맥락을 보존해 이후 장면에 이어간다.','')),
 ('rulebook_file_route_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','| 08-visual.md |','| 88-missing.md |')),
 ('rulebook_route_wrong_owner',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN_EXPOSURE_GATE / COMBAT_ORDER','HEALING / COMBAT_ORDER')),
 ('rulebook_route_unknown_id',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN_EXPOSURE_GATE / COMBAT_ORDER','UNKNOWN_EXPOSURE_RULE / COMBAT_ORDER')),
 ('keeper_footer_large',lambda r:change(r,'rules/06-play.md','Markdown 6단계','Markdown 1단계')),
 ('source_world_immersion_lost',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','원작 안에 들어온 감각을 주며','원작 이름만 표시하며')),
 ('investigation_spiral',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','증거 완전성·세부 모순·추가 검증을 계속 요구하며 조사 단계를 늘이지 않는다','증거가 완벽해질 때까지 추가 조사를 계속 요구한다')),
 ('chosen_deep_inquiry_erased',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','핵심 난관과 플레이어가 선택한 심층 탐구는 보존한다','플레이어가 원해도 심층 탐구는 전부 생략한다')),
 ('presentation_overrides_priority',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','재미·속도·5요소를 위해 상위 기준을 뒤집지 않는다','재미를 위해 PC 주도권과 확정 결과를 바꾼다')),
 ('regenerate_existing_canon',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','신규 캠페인 또는 새 챕터의 미확정 범위에 적용한다','기존 세계도 매 응답 다시 생성한다')),
 ('meta_advances_danger',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','메타 질문·재표시는 답만 제공하며 극중 시간·위험을 진행시키지 않는다','메타 질문마다 시간과 위협을 진행한다')),
 ('every_routine_is_important',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','생존·목표·수단·관계·진실 이해·이후 선택을 바꾸는 순간','모든 접수와 확인을 별도 장면으로')),
 ('lookup_failure_guessed_success',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','조회 실패 시 영향을 받는 처리만 보류하고 확인 가능한 진행은 계속한다','조회 실패 시 결과를 추측해 확정한다')),
 ('routine_without_decision_stops',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','이미 선언한 목적/발언의 통상 실행에 새 판단이 없으면','이미 선언한 통상 확인도 매번 멈춰')),
 ('priority_at_bottom',move_priority_last),
 ('choice_buttons_dropped',lambda r:change(r,'rules/06-play.md','실제 버튼/선택 UI를 제공하면','버튼 UI가 지원되어도')),
 ('fake_click_fallback',lambda r:change(r,'rules/06-play.md','작동하지 않는 HTML/가짜 링크로 클릭 기능을 가장하지 않으며','가짜 클릭 링크를 제공하며')),
 ('status_panel_flattened',lambda r:change(r,'rules/06-play.md','Markdown 상태 카드','상태 한 줄')),
 ('resource_icons_removed',lambda r:change(r,'rules/06-play.md','❤️ 체력 HP','HP')),
 ('bag_sections_merged',lambda r:change(r,'rules/06-play.md','각각 빈 줄로 나눈 독립 문단/별도 UI 영역에 표시한다','합쳐 한 문단에 표시한다')),
 ('inventory_rearranged_for_style',lambda r:change(r,'rules/06-play.md','기존 소지 위치·수량·점유량을 서식 때문에 재배치하거나 예시 값/새 물품으로 채우지 않는다','패널에 맞춰 물품의 위치와 수량을 바꾼다')),
 ('ui_instruction_reminder_removed',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','선택지·상태 패널·아이콘·메인/파우치 구분은06-play를 따른다','UI 서식은 자유다')),
 ('retired_router',lambda r:(r/'rules/01-core.md').write_text((r/'rules/01-core.md').read_text()+'\nNOTEBOOK_PUBLIC_PATCH\n')),
 ('notebook_shipped',lambda r:(r/'rules/09-notebook.md').write_text('# retired\n')),
 ('pi_too_long',lambda r:(r/'PROJECT_INSTRUCTIONS.md').write_text((r/'PROJECT_INSTRUCTIONS.md').read_text()+'가'*7801)),
 ('duplicate_rule',lambda r:(r/'rules/03-danger.md').write_text((r/'rules/03-danger.md').read_text()+'\n## SUCCESS_LEVELS\n\nDuplicate\n')),
 ('catalog_missing',lambda r:(r/'docs/RULE_CATALOG.md').write_text('# empty\n')),
 ('parent_inventory_missing',lambda r:(r/'docs/rule-reorganization.json').write_text(json.dumps(json.loads((r/'docs/rule-reorganization.json').read_text())[:-1]))),
 ('original_inventory_missing',lambda r:(r/'docs/rule-migration.json').write_text(json.dumps(json.loads((r/'docs/rule-migration.json').read_text())[:-1]))),
]
with tempfile.TemporaryDirectory() as tmp:
    baseline=Path(tmp)/'baseline';(baseline/'docs').mkdir(parents=True)
    shutil.copytree(ROOT/'rules',baseline/'rules')
    for name in ['PROJECT_INSTRUCTIONS.md','START_GAME.md']:shutil.copyfile(ROOT/name,baseline/name)
    for name in ['rule-migration.json','rule-reorganization.json','validation-contract.json','RULE_CATALOG.md']:
        shutil.copyfile(ROOT/'docs'/name,baseline/'docs'/name)
    validate(baseline)
    for name,mutate in mutations:
        target=Path(tmp)/name;shutil.copytree(baseline,target);mutate(target)
        try:validate(target)
        except (SystemExit,ValueError):pass
        else:raise AssertionError('invalid change accepted: '+name)
print(f'PASS: valid integrated documents; {len(mutations)} consequential regression mutations rejected; no live play tested')
