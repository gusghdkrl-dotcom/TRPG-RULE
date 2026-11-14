#!/usr/bin/env python3
"""Finite, offline four-layer design probes, NOT a game engine or AI play test.

The invented source and partial canon below are public synthetic data. Three E
nodes exercise ordering; this is not a full 8-12 E / 18-30 S campaign. Test-only
keys are not a save schema. See docs/FOUR_LAYER_SCENARIO_REVIEW.md.
"""
from collections import deque
from copy import deepcopy
from pathlib import Path
import json
import subprocess
import sys
import tempfile

from check_resume_semantics import compare


# Synthetic source: a valley where underground echoes repeat a living person's
# voice. A broken sound barrier has already released the resonance. It travels
# through stone, not radio; fleeing people and affected facilities carry its
# consequences. Existing silence screens and genuine shelter still work.
CANON = {
    'scope': 'partial_synthetic_contract',
    'mandate': 'Keep the valley inhabited while containing the released echo.',
    'fixed_loss': 'The lower tram tunnel collapsed before the opening.',
    'spine': ['E14', 'E03', 'E27'],  # Deliberately not numeric order.
    'events': {
        'E14': {'after': [], 'meaning': 'Loss of ordinary transit; choose how to reach shelter.'},
        'E03': {'after': ['E14'], 'meaning': 'Protect residents and decide which shelter can stay usable.'},
        'E27': {'after': ['E03'], 'meaning': 'Use preserved people/tools to contain the source or leave.'},
        'E99': {'after': [], 'meaning': 'Independent offscreen damage; not a spine completion.'},
    },
    'places': ['station', 'quay', 'shelter', 'ridge', 'outside'],
    # Every edge has an actual medium, physical duration and known map source.
    'routes': {
        'R_walk': ('station', 'shelter', 7, None),
        'R_quay': ('station', 'quay', 4, None),
        'R_boat': ('quay', 'shelter', 6, 'boat'),
        'R_ridge': ('shelter', 'ridge', 12, None),
        'R_exit': ('ridge', 'outside', 9, None),
    },
    'goals': {
        'M_delivery': {'place': 'shelter', 'toward': 'E14', 'direct_next': None},
        'M_repair': {'place': 'station', 'toward': 'E14', 'direct_next': None},
        'M_protect': {'place': 'shelter', 'toward': 'E03', 'direct_next': None},
        'M_ridge': {'place': 'ridge', 'toward': 'E27', 'direct_next': None},
        'M_contain': {'place': 'ridge', 'toward': 'E27', 'direct_next': None},
        'S_song': {'place': 'station', 'toward': None, 'direct_next': None},
        'S_family': {'place': 'shelter', 'toward': None, 'direct_next': None},
    },
    'life': {
        'station': ['W_tea', 'S_song'], 'quay': ['W_fishing'],
        'shelter': ['W_meal', 'S_family'], 'ridge': ['W_view'],
    },
    'facts': {
        'F_delivery': ['M_delivery'], 'F_tools': ['M_repair'],
        'F_shelter_sign': ['M_protect'], 'F_ridge_map': ['M_ridge'],
        'F_source_brief': ['M_contain'], 'F_song': ['S_song'],
        'F_family': ['S_family'],
    },
    'npcs': {
        'N_keeper': {'place': 'shelter', 'knows': ['F_source_brief'], 'alive': True},
        'N_host': {'place': 'station', 'knows': ['F_song'], 'alive': True},
    },
    'spine_gates': [],  # No side-count, elapsed-time or goal-completion quota.
    'side_required_for_main': [],
}


def snapshot(entry='daily', count=1, hq=False):
    facts = ['F_delivery', 'F_tools', 'F_shelter_sign']
    if entry == 'informed':
        facts += ['F_ridge_map', 'F_source_brief']
    return {
        'entry': entry, 'hq': hq, 'status': 'active', 'phase': 'normal',
        'pcs': {f'P{i}': {'place': 'station', 'facts': facts.copy(),
                         'known_routes': list(CANON['routes']), 'accepted': []}
                for i in range(1, count + 1)},
        'closed': [], 'blocked_routes': [], 'resources': ['boat'],
        'world_events': [], 'experienced': {}, 'resolved': {},
        'deliveries': [], 'sides': {}, 'legacy_timer': None,
    }


def destinations(canon, state, pc):
    reached = {pc['place']}
    work = deque(reached)
    while work:
        here = work.popleft()
        for ref in pc['known_routes']:
            if ref not in canon['routes'] or ref in state['blocked_routes']:
                continue
            a, b, duration, resource = canon['routes'][ref]
            if a != here or duration <= 0 or resource and resource not in state['resources']:
                continue
            if b not in reached:
                reached.add(b)
                work.append(b)
    return reached


def inspect(canon, state):
    """Check this finite fixture's declared links, not arbitrary natural language."""
    errors = set()
    seen = set()
    for ref in canon['spine']:
        if ref in seen or ref not in canon['events']:
            errors.add('spine_ref')
            continue
        if not set(canon['events'][ref]['after']) <= seen:
            errors.add('spine_dependency')
        seen.add(ref)
    if not canon['spine'] or not canon['mandate']:
        errors.add('no_spine')
    if canon['spine_gates']:
        errors.add('quota_or_clock')
    if canon['side_required_for_main']:
        errors.add('side_gate')
    for ref, goal in canon['goals'].items():
        if goal['place'] not in canon['places'] or goal['toward'] and goal['toward'] not in canon['events']:
            errors.add('dangling_goal')
    for a, b, duration, resource in canon['routes'].values():
        if a not in canon['places'] or b not in canon['places'] or duration <= 0:
            errors.add('route_physics')
    visible = {}
    for ident, pc in state['pcs'].items():
        known = {g for f in pc['facts'] for g in canon['facts'].get(f, [])}
        accessible = destinations(canon, state, pc)
        visible[ident] = {g for g in known if g in canon['goals']
                          and g not in state['closed']
                          and canon['goals'][g]['place'] in accessible}
        if state['status'] == 'active':
            if not any(canon['goals'][g]['toward'] for g in visible[ident]):
                errors.add('main_gap')
            # Normal intervals, not each combat action, need optional life.
            if state['phase'] == 'normal' and not canon['life'].get(pc['place']):
                errors.add('life_gap')
    for d in state['deliveries']:
        npc = canon['npcs'][d['from']]
        pc = state['pcs'][d['to']]
        if not npc['alive'] or d['fact'] not in npc['knows']:
            errors.add('invalid_carrier')
        if d['medium'] == 'speech' and npc['place'] != pc['place']:
            errors.add('undelivered')
        if d['medium'] == 'radio' and not d['receiver_working']:
            errors.add('undelivered')
        if d['elapsed'] < d['required']:
            errors.add('undelivered')
    for ref, result in state['resolved'].items():
        if result == 'experienced' and not state['experienced'].get(ref):
            errors.add('news_is_not_experience')
    return errors, visible


def main():
    accepted = rejected = 0

    def good(state, canon=CANON):
        nonlocal accepted
        errors, visible = inspect(canon, state)
        assert not errors, errors
        accepted += 1
        return visible

    def bad(state, expected, canon=CANON):
        nonlocal rejected
        errors, _ = inspect(canon, state)
        assert expected in errors, (expected, errors)
        rejected += 1

    # The same world supports different initial knowledge without erasing it.
    for entry in ['daily', 'informed']:
        for count in [1, 2, 3]:
            for hq in [False, True]:
                s = snapshot(entry, count, hq)
                visible = good(s)
                assert ('M_contain' in visible['P1']) == (entry == 'informed')
                assert s['pcs']['P1']['accepted'] == []

    # N26: a small goal closes with no direct followup; other main goals remain.
    s = snapshot(); s['closed'] = ['M_repair']
    assert CANON['goals']['M_repair']['direct_next'] is None
    assert 'M_delivery' in good(s)['P1']
    # Failure/avoidance/lost boat does not invent a receiver or new route.
    s['resources'] = []; s['blocked_routes'] = ['R_boat']
    good(s)
    # Last known main goal closes; an already encountered map supplies the path.
    s = snapshot(); s['closed'] = ['M_repair', 'M_delivery', 'M_protect']
    bad(s, 'main_gap')
    s['pcs']['P1']['facts'].append('F_ridge_map')
    assert good(s)['P1'] == {'M_ridge'}
    # A distant goal may be visible via a real journey; no immediate arrival.
    assert s['pcs']['P1']['place'] == 'station'
    # A side alone cannot pass; refusing all sides leaves main access intact.
    s = snapshot(); s['closed'] = ['M_repair', 'M_delivery', 'M_protect']
    s['pcs']['P1']['facts'].append('F_song'); bad(s, 'main_gap')
    s = snapshot(); s['sides'] = {'S_song': 'refused', 'S_family': 'resolved_without_pc'}
    good(s)
    # Transport failure with no real alternate route is a generation defect.
    s['closed'] = ['M_repair']; s['resources'] = []; s['blocked_routes'] = ['R_walk']
    bad(s, 'main_gap')
    for terminal in ['safe_withdrawal', 'all_dead', 'resolved']:
        s['status'] = terminal; good(s)
    # Split PC knowledge is independent. Offscreen occurrence grants no facts.
    s = snapshot(count=2); s['pcs']['P2']['place'] = 'shelter'
    s['pcs']['P2']['facts'] = ['F_ridge_map', 'F_source_brief']
    s['world_events'] = ['E99']; visible = good(s)
    assert 'M_contain' not in visible['P1'] and 'M_contain' in visible['P2']
    s['resolved']['E99'] = 'experienced'; bad(s, 'news_is_not_experience')
    s['resolved'] = {}; s['experienced'] = {'E14': ['P1']}
    s['resolved']['E14'] = 'experienced'; good(s)
    # A valid pre-emption is a distinct resolution, not fake experienced harm.
    s['resolved']['E03'] = 'prevented'; good(s)
    # Real delivery conditions; no transitive/omniscient NPC knowledge.
    d = {'from': 'N_keeper', 'to': 'P1', 'fact': 'F_source_brief',
         'medium': 'radio', 'receiver_working': False, 'elapsed': 1, 'required': 1}
    s['deliveries'] = [d]; bad(s, 'undelivered')
    d['receiver_working'] = True; good(s)
    d['elapsed'] = 0; bad(s, 'undelivered')
    d['elapsed'] = 1; d['medium'] = 'speech'; bad(s, 'undelivered')
    d['to'] = 'P2'; good(s)
    c = deepcopy(CANON); c['npcs']['N_keeper']['alive'] = False
    bad(s, 'invalid_carrier', c)
    c = deepcopy(CANON); c['npcs']['N_keeper']['knows'] = []
    bad(s, 'invalid_carrier', c)
    s = snapshot()
    c = deepcopy(CANON); c['spine'] = sorted(c['spine']); bad(s, 'spine_dependency', c)
    c = deepcopy(CANON); c['spine'] = []; bad(s, 'no_spine', c)
    for gate in ['three_small_goals', 'five_sides', 'ten_chat_turns', '20_minutes']:
        c = deepcopy(CANON); c['spine_gates'] = [gate]; bad(s, 'quota_or_clock', c)
    c = deepcopy(CANON); c['side_required_for_main'] = ['S_song']; bad(s, 'side_gate', c)
    c = deepcopy(CANON); c['life']['station'] = []; bad(s, 'life_gap', c)
    s['phase'] = 'combat'; good(s, c)  # no mandatory leisure popup in combat
    c = deepcopy(CANON); c['routes']['R_walk'] = ('station', 'shelter', 0, None)
    bad(s, 'route_physics', c)
    c = deepcopy(CANON); c['goals']['M_delivery']['place'] = 'invented_destination'
    bad(s, 'dangling_goal', c)

    # Offline preservation probes use existing V2 containers, not new columns.
    # This is a partial snapshot, not a valid production commit payload.
    preserved = {
        'canon_ref': {'revision': 1},
        'world_delta': {'drivers': {
            'E14': {'world': 'resolved', 'contact': {'P1': True, 'P2': False}},
            'E03': {'world': 'prevented', 'reason': 'existing_executor_captured'},
            'M_repair': {'result': 'failed', 'direct_next': None},
            'S_song': {'decision': 'refused', 'npc_activity': 'continues'},
        }},
        'story_context': {'spine': ['E14', 'E03', 'E27'],
                          'known_open': {'P1': ['M_ridge'], 'P2': ['M_contain']}},
        'scene_context': {'awaiting': 'P1', 'offer': 'M_ridge', 'accepted': False},
        'ongoing_consequences': {'R_boat': 'blocked', 'legacy_timer': 'unchanged'},
        'processed_event_ids': ['SYNTH_E14_RESOLVED', 'SYNTH_E03_PREVENTED'],
    }
    probes = {'format': 'RESUME_PROBES_V1', 'probes': [
        {'path': '/' + k, 'expected': deepcopy(v), 'source_ref': 'SYNTHETIC_ONLY'}
        for k, v in preserved.items()
    ]}
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp); pp = root/'probes.json'; sp = root/'state.json'
        pp.write_text(json.dumps(probes)); sp.write_text(json.dumps(preserved))
        cmd = [sys.executable, str(Path(__file__).with_name('check_resume_semantics.py')), str(pp), str(sp)]
        result = subprocess.run(cmd, capture_output=True, text=True)
        assert result.returncode == 0 and json.loads(result.stdout)['passed']
        accepted += 1
        mutations = [
            lambda x: x['story_context'].update(spine=['E03', 'E14', 'E27']),
            lambda x: x['story_context']['known_open'].update(P1=['M_contain']),
            lambda x: x['scene_context'].update(accepted=True),
            lambda x: x['world_delta']['drivers']['E03'].update(world='active'),
            lambda x: x['world_delta']['drivers']['S_song'].update(decision='offered'),
            lambda x: x['world_delta']['drivers']['E14']['contact'].update(P2=True),
            lambda x: x['ongoing_consequences'].update(legacy_timer='recreated'),
            lambda x: x['processed_event_ids'].append('SYNTH_E14_RESOLVED'),
            lambda x: x['world_delta']['drivers']['M_repair'].update(direct_next='invented_goal'),
        ]
        for mutate in mutations:
            altered = deepcopy(preserved); mutate(altered)
            assert not compare(probes, altered)['passed']; rejected += 1
    print(f'PASS: four-layer finite probes: {accepted} accepted, {rejected} rejected; '
          'two start types, 1-3 PCs, ON/OFF, physical paths, optional life and resume; '
          'no live AI play, complete campaign generation or DB call tested')


if __name__ == '__main__':
    main()
