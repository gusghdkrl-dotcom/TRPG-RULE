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
state['resume_context']['story_context']['main_track_by_pc']={
 'P1':{'e_ref':'E_SYN','public_direction':'reach_station','experience':'on_site','activity_ref':'S_SYN','source_ref':'EVENT_A'},
 'P2':{'e_ref':'E_SYN','public_direction':'travel_to_station','experience':'not_arrived','activity_ref':None,'source_ref':'EVENT_B'}
}
# Story files live outside the checkpoint; exact references and the separate
# manual workflow must survive without replacing the open gameplay input.
state['resume_context']['story_context']['story_save']={
 'latest_created':{'revision':2,'filename':'STORY_SAVE_SYN_r2.md',
                   'file_sha256':'a'*64,'manifest_filename':'STORY_SAVE_SYN_r2.manifest.json',
                   'manifest_sha256':'b'*64,'target_save':{'session_id':'SYNTHETIC','version':3,'state_sha256':'c'*64}},
 'request':{'request_id':'SYN_STORY_4','target_session_id':'SYNTHETIC','target_version':4,
            'previous_file_sha256':'a'*64,'expected_revision':3,
            'expected_filename':'STORY_SAVE_SYN_r3.md','expected_manifest':'STORY_SAVE_SYN_r3.manifest.json',
            'stage':'awaiting_input'}
}
state['resume_context']['ongoing_consequences']['RESCUE_SYN']={
 'patient':'P1','rescuer':'P2','access':'reachable','stage':'evacuation_pending','threat':'THREAT_A'
}
state['resume_context']['scene_context']['last_presented_change_ref']='EVENT_A'
state['resume_context']['story_context']['world_e_ref']='E_SYN_PARTIAL'
# Fine facts survive transfer even when no immediate plot consequence exists.
state['resume_context']['handoff_details']={
 'nickname':{'speaker':'NPC_SYN','listener':'ACTOR_OLD','quote':'작은 등불', 'event':'EVENT_A'},
 'promise':{'offered':'return_the_cup','accepted':False,'heard_by':['ACTOR_OLD']},
 'last_output':{'question':'어느 문을 지킬까?', 'menu':[{'number':1,'intent':'hold_north'},{'number':2,'intent':'hold_south'}]},
 'item':{'ref':'CUP_SYN','place':'floor_under_bench','owner':'NPC_SYN'},
 'hands':{'right':'LAMP_SYN','left':None},'fuel_minutes':17,
 'ammo':{'loaded':2,'reserve':4,'calibre':'SYN'},
 'tracker':{'actual_place':'yard','last_known_pc_place':'quay','trace_lost':True},
 'work':{'started_at':10,'elapsed':4,'remaining':6},
 'participation':{'slot':'P1','current_actor':'ACTOR_NEW','retired_actor':'ACTOR_OLD',
                  'joined_after':['E14'],'inheritance_used':True,'old_private_memory':'cup_promised'},
 'submitted_check':{'owner':'ACTOR_NEW','raw':37,'stage':'received_unapplied','luck_spent':0},
 'last_presented_event':'EVENT_A','spent_card':'CARD_SYN',
}
paths=['/session','/turn','/canon_revision','/entities/ENTITY_A/communication','/entities/ENTITY_A/held_item',
       '/agreement','/route','/pending','/processed','/optional','/resume_context']
def at(obj,path):
    for key in path[1:].split('/'):obj=obj[key]
    return obj
probes={'format':'RESUME_PROBES_V1','probes':[{'path':p,'expected':deepcopy(at(state,p)),'source_ref':'SYNTHETIC_EVENT'} for p in paths]}
probes['required_paths']=['/session','/pending','/resume_context/handoff_details','/resume_context/story_context']
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
 lambda s:s['resume_context']['story_context']['main_track_by_pc']['P2'].update(experience='on_site'),
 lambda s:s['resume_context']['story_context'].update(world_e_ref='E_SYN_DONE'),
 lambda s:s['resume_context']['ongoing_consequences']['RESCUE_SYN'].update(access='unreachable'),
 lambda s:s['resume_context']['scene_context'].pop('last_presented_change_ref'),
]
# Each mutation changes a real continuation fact, not an incidental test marker.
for field, replacement in {
 'nickname':{'speaker':'NPC_SYN','listener':'ACTOR_NEW','quote':'小灯','event':'EVENT_A'},
 'promise':{'offered':'return_the_cup','accepted':True,'heard_by':['ACTOR_OLD']},
 'last_output':{'question':'어느 문을 지킬까?', 'menu':[{'number':1,'intent':'hold_south'},{'number':2,'intent':'hold_north'}]},
 'item':{'ref':'CUP_SYN','place':'pack','owner':'ACTOR_NEW'},
 'hands':{'right':None,'left':None},'fuel_minutes':30,
 'ammo':{'loaded':6,'reserve':0,'calibre':'SYN'},
 'tracker':{'actual_place':'yard','last_known_pc_place':'station','trace_lost':False},
 'work':{'started_at':10,'elapsed':0,'remaining':10},
 'participation':{'slot':'P1','current_actor':'ACTOR_NEW','retired_actor':'ACTOR_OLD',
                  'joined_after':[],'inheritance_used':False,'old_private_memory':'cup_promised'},
 'submitted_check':{'owner':'ACTOR_NEW','raw':37,'stage':'applied','luck_spent':0},
 'last_presented_event':None,'spent_card':None,
}.items():
    mutations.append(lambda obj, f=field, v=replacement: obj['resume_context']['handoff_details'].update({f:v}))
story_mutations=[
 lambda s:s['resume_context']['story_context'].pop('story_save'),
 lambda s:s['resume_context']['story_context']['story_save']['latest_created'].update(filename='STORY_SAVE_OTHER_r2.md'),
 lambda s:s['resume_context']['story_context']['story_save']['latest_created'].update(file_sha256='d'*64),
 lambda s:s['resume_context']['story_context']['story_save']['latest_created']['target_save'].update(version=5),
 lambda s:s['resume_context']['story_context']['story_save']['request'].update(stage='completed'),
 lambda s:s['resume_context']['story_context']['story_save']['request'].update(previous_file_sha256='e'*64),
 lambda s:s['resume_context']['story_context']['story_save']['request'].update(target_version=5),
 lambda s:s['resume_context']['story_context']['story_save']['request'].update(expected_manifest='OTHER.manifest.json'),
]
mutations.extend(story_mutations)
for mutate in mutations:
    bad=deepcopy(state);mutate(bad);assert not compare(probes,bad)['passed'];cases+=1
# A manifest that only compares numbers must not pass declared memory coverage.
thin=deepcopy(probes);thin['probes']=[p for p in thin['probes'] if p['path']!='/resume_context']
assert any(e['reason']=='uncovered' for e in compare(thin,state)['errors']);cases+=1
prefix={'format':'RESUME_PROBES_V1','required_paths':['/ab/x'],
        'probes':[{'path':'/a','expected':{},'source_ref':'E'}]}
assert not compare(prefix,{'a':{},'ab':{'x':1}})['passed'];cases+=1
prefix['required_paths']=['/a/x'];prefix['probes'][0]['expected']={'x':1}
assert compare(prefix,{'a':{'x':1}})['passed'];cases+=1
prefix['probes'][0]['expected']={}
assert not compare(prefix,{'a':{}})['passed'];cases+=1
for required in [[],None,['/a','/a'],[''],['/missing/~2bad']]:
    bad=deepcopy(probes);bad['required_paths']=required
    try:compare(bad,state)
    except ValueError:pass
    else:raise AssertionError('invalid required path accepted')
    cases+=1
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
