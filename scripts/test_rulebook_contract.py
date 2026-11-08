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
