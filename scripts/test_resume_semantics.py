"""Synthetic regression cases; no actual campaign data or network."""
from copy import deepcopy
import json,subprocess,sys,tempfile
from pathlib import Path
from check_resume_semantics import compare

state={'session':'SYNTHETIC','turn':41,'canon_revision':2,
       'entities':{'ENTITY_A':{'communication':{'understands':{'ENTITY_B':{'status':'confirmed','value':True}},
                  'speaks':False,'signal_meaning':'unknown'},'held_item':'ITEM_A'}},
       'agreement':{'status':'proposed','accepted':False},'route':{'blocked':True},
       'pending':{'kind':'player_response'},'processed':['EVENT_A'],'optional':None}
state['resume_context']={
 'story_context':{'current_goal':'stop_flooding','changed_because':'pump_damaged','source_ref':'EVENT_A'},
 'npc_contexts':{'ENTITY_A':{'address':'formal','interaction':'terse_cooperation',
                           'attitude_reason':'shared_rescue','source_ref':'EVENT_A'}},
 'scene_context':{'last_question':'use_the_gate','answer_owner':'PC_A',
                  'completed_check':'speech_understood','ongoing_action':'holding_gate'},
 'ongoing_consequences':{'THREAT_A':{'status':'blocked','condition':'gate_held','applied':['EVENT_A']}}
}
paths=['/session','/turn','/canon_revision','/entities/ENTITY_A/communication','/entities/ENTITY_A/held_item',
       '/agreement','/route','/pending','/processed','/optional','/resume_context']
def at(obj,path):
    for key in path[1:].split('/'):obj=obj[key]
    return obj
probes={'format':'RESUME_PROBES_V1','probes':[{'path':p,'expected':deepcopy(at(state,p)),'source_ref':'SYNTHETIC_EVENT'} for p in paths]}
cases=0
assert compare(probes,state)['passed'];cases+=1
mutations=[
 lambda s:s['entities']['ENTITY_A']['communication']['understands']['ENTITY_B'].update(status='unknown'),
 lambda s:s['entities']['ENTITY_A']['communication']['understands']['ENTITY_B'].update(value=False),
 lambda s:s['entities']['ENTITY_A']['communication'].update(speaks=True),
 lambda s:s['entities']['ENTITY_A']['communication']['understands'].update(ENTITY_C=s['entities']['ENTITY_A']['communication']['understands'].pop('ENTITY_B')),
 lambda s:s['agreement'].update(status='accepted',accepted=True),
 lambda s:s['route'].update(blocked=False),
 lambda s:s.update(pending=None),
 lambda s:s['entities']['ENTITY_A'].update(held_item='ITEM_B'),
 lambda s:s.update(turn=40),
 lambda s:s.update(canon_revision=1),
 lambda s:s.update(processed=[]),
 lambda s:s.pop('optional'),
 lambda s:s.update(session='OTHER'),
 lambda s:s['entities']['ENTITY_A']['communication'].update(speaks=0),
 lambda s:s.pop('resume_context'),
 lambda s:s['resume_context']['story_context'].update(current_goal='investigate_noise'),
 lambda s:s['resume_context']['npc_contexts']['ENTITY_A'].update(address='casual'),
 lambda s:s['resume_context']['npc_contexts']['ENTITY_A'].pop('attitude_reason'),
 lambda s:s['resume_context']['scene_context'].update(last_question='understand_speech'),
 lambda s:s['resume_context']['scene_context'].update(answer_owner='PC_B'),
 lambda s:s['resume_context']['scene_context'].update(ongoing_action='idle'),
 lambda s:s['resume_context']['ongoing_consequences']['THREAT_A'].update(status='active'),
]
for mutate in mutations:
    bad=deepcopy(state);mutate(bad);assert not compare(probes,bad)['passed'];cases+=1
# JSON file round trip and a new interpreter, not the original object in memory.
with tempfile.TemporaryDirectory() as tmp:
    p=Path(tmp);(p/'probes.json').write_text(json.dumps(probes));(p/'state.json').write_text(json.dumps(state))
    cmd=[sys.executable,str(Path(__file__).with_name('check_resume_semantics.py')),str(p/'probes.json'),str(p/'state.json')]
    result=subprocess.run(cmd,capture_output=True,text=True);assert result.returncode==0 and json.loads(result.stdout)['passed'];cases+=1
    bad=deepcopy(state);bad['pending']=None;(p/'state.json').write_text(json.dumps(bad))
    result=subprocess.run(cmd,capture_output=True,text=True);assert result.returncode==1 and 'ENTITY_A' not in result.stdout;cases+=1
    (p/'state.json').write_text('{"a":1,"a":2}')
    result=subprocess.run(cmd,capture_output=True,text=True);assert result.returncode==2;cases+=1
for manifest in [{'format':'RESUME_PROBES_V1','probes':[]}, {'format':'BAD','probes':[]},
                 {'format':'RESUME_PROBES_V1','probes':[probes['probes'][0]]*2}]:
    try:compare(manifest,state)
    except ValueError:pass
    else:raise AssertionError('invalid manifest accepted')
    cases+=1
# Escaped entity IDs work without ambiguous path parsing.
assert compare({'format':'RESUME_PROBES_V1','probes':[{'path':'/a~1b/~0x/0','expected':False,'source_ref':'E'}]}, {'a/b':{'~x':[False]}})['passed'];cases+=1
print(f'PASS: {cases} synthetic resume comparisons/rejections; file round-trip and separate-process CLI; no live save/load tested')
