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
 ('keeper_principle_rewritten',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','그 대응과 결과가 진실과 다음 선택으로 이어지게 한다','플레이어의 대응과 무관하게 예정된 사건을 실행한다')),
 ('keeper_reminder_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','> 키퍼 숙지: 위 5요소를 이번 장면과 다음 진행에 적용한다.','')),
 ('keeper_footer_not_last',lambda r:change(r,'rules/06-play.md','이 블록 뒤에 다른 게임 정보를 붙이지 않는다','블록 뒤에 게임 정보를 이어 쓴다')),
 ('keeper_footer_only_rolls',lambda r:change(r,'rules/06-play.md','판정이 없는 일반 장면에도 표시','판정이 있는 때만 표시')),
 ('keeper_rule_application_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','> 4. 지침을 숙지하고 묘사·판정·결과 처리에 규칙이 필요한 상황이면, 해당 룰북 본문을 확인해 적용한다.','')),
 ('keeper_focus_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','> 5. 사소한 절차는 압축하고, 중요한 발견·대면·사투·돌파에 집중한다.','')),
 ('rulebook_file_route_missing',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','| 08-visual.md |','| 88-missing.md |')),
 ('rulebook_route_wrong_owner',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN_EXPOSURE_GATE / COMBAT_ORDER','HEALING / COMBAT_ORDER')),
 ('rulebook_route_unknown_id',lambda r:change(r,'PROJECT_INSTRUCTIONS.md','SAN_EXPOSURE_GATE / COMBAT_ORDER','UNKNOWN_EXPOSURE_RULE / COMBAT_ORDER')),
 ('keeper_footer_large',lambda r:change(r,'rules/06-play.md','Markdown 6단계','Markdown 1단계')),
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
