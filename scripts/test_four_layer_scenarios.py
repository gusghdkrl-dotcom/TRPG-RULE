#!/usr/bin/env python3
"""Finite, offline four-layer design probes, NOT a game engine or AI play test.

The invented source and partial canon below are public synthetic data. Three E
nodes exercise ordering, first-state handoff and distinct enemy roles; this is
not a complete campaign. Test-only keys are not a save schema.
See docs/GENERATION_HANDOFF_REVIEW.md and docs/FOUR_LAYER_SCENARIO_REVIEW.md.
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
        'E14': {'after': [], 'meaning': 'Loss of ordinary transit; choose how to reach shelter.',
                'ends_in': 'shelter_reached'},
        'E03': {'after': ['E14'], 'meaning': 'Protect residents and decide which shelter can stay usable.',
                'ends_in': 'residents_protected'},
        'E27': {'after': ['E03'], 'meaning': 'Reconnect the isolation station while protecting its operators.',
                'ends_in': 'isolation_station_connected'},
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
        'R_return': ('shelter', 'station', 7, None),
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
    # Concrete facts for this finite sample, not fields for a production save.
    'preparation': {
        'first_place': 'station',
        'party_history': 'The investigators repaired the same valley tram last winter.',
        'main_places': ['shelter', 'ridge'],
        'outside_place': 'outside',
        'boss': {'ref': 'H_echo_warden', 'place': 'ridge', 'hp': 18,
                 'attack': '1d8', 'origin': 'the already released stone resonance',
                 'limit': 'cannot cross a severed resonant link',
                 'discovery': 'F_source_brief'},
        'finale': {'starts_in': 'isolation_station_connected',
                   'finishes_in': 'source_isolated_and_people_outside',
                   'necessary_fact': 'F_source_brief',
                   'residual_cause': 'The echo travels through stone after every raider is gone.',
                   'actual_use': 'Identify and cut the resonant link before crossing the stone exit.'},
        'hostiles': {
            'H_tracker': {'role': 'pursue', 'kind': 'human', 'place': 'station',
                          'knows': ['boot_trace'], 'next_route': 'R_walk',
                          'target': 'the witnessed radio thief',
                          'stop': 'no trace beyond shelter; search entrance then report back'},
            'H_guard': {'role': 'guard', 'kind': 'human', 'place': 'ridge',
                        'knows': [], 'target': 'isolation_key',
                        'stop': 'leave only after relief or actual danger to the key'},
            'H_patrol': {'role': 'roam', 'kind': 'human', 'place': 'shelter',
                         'knows': [], 'next_route': 'R_return',
                         'target': 'the station-shelter supply route',
                         'stop': 'return to shelter if the bridge is physically blocked'},
        },
        'items': {'isolation_key': {'quantity': 1, 'place': 'ridge', 'owner': 'H_guard'},
                  'bandage': {'quantity': 1, 'place': 'shelter', 'owner': 'N_keeper'}},
        'holdings': {'ridge': {'isolation_key': 1}, 'shelter': {'bandage': 1}},
        'hazard': {'exposure': 'crossing the already damaged ridge catwalk',
                   'response': 'secure the existing handline before crossing',
                   'failure': 'falling damage from the fixed platform height',
                   'damage': '1d6', 'stop': 'reach the intact platform or leave the catwalk'},
        'recovery': {'item': 'bandage', 'safe_place': 'shelter',
                     'access': 'ask its actual owner; refusal leaves the handline bypass available'},
        # Actual invented protection/cause facts, NOT a production save schema.
        'temporary_protection': {
            'place': 'shelter', 'capacity': 2, 'cost_per_pulse': 1,
            'source_actor': 'H_echo_warden',
            'trigger': 'the warden drives a pulse into the intact stone link',
            'link': {'from': 'ridge', 'to': 'shelter', 'medium': 'stone', 'duration': 3},
            'warning': 'the screen meter drops and the stone floor vibrates',
            'response': 'leave the exposed slab or defend at the arriving pulse',
            'permanent_end': 'source_isolated',
        },
        'failure_flow': ['pc_terminated', 'check_existing_companion_inheritance',
                         'campaign_failed_if_no_actor'],
        'san_rewards': [{'achievement': 'source_isolated', 'event': 'SYNTH_SOURCE_RESOLVED',
                         'methods': ['sever_link', 'seal_link']},
                        {'achievement': 'residents_saved', 'event': 'SYNTH_RESIDENTS_SAVED',
                         'methods': ['escort', 'safe_shelter']}],
    },
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
        'world_events': [], 'experienced': {}, 'remote': {}, 'resolved': {},
        'deliveries': [], 'sides': {}, 'legacy_timer': None,
        'source_isolated': False,
    }


def source_contact(canon, protection, elapsed, *, source_isolated=False, link_intact=True):
    """One explicitly started source action in this finite invented fixture.

    No chat timer, damage, forced PC choice or new hostile is generated here.
    Successful sheltering is preserved; source isolation ends future pressure.
    """
    remaining = protection
    p = canon['preparation']['temporary_protection']
    if source_isolated or not link_intact:
        return remaining, 'no_contact'
    if elapsed < p['link']['duration']:
        return remaining, 'approaching'
    if remaining >= p['cost_per_pulse']:
        return remaining - p['cost_per_pulse'], 'attack_blocked'
    return remaining, 'response_pending'


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
    for ref, participants in state['experienced'].items():
        if set(participants) & set(state['remote'].get(ref, [])):
            errors.add('remote_is_not_experience')
    # All PCs directly experience every E before the finale. A local attack
    # stopped without injury does not cancel the independently caused crisis.
    if state['phase'] == 'finale' or state['status'] in ('safe_withdrawal', 'resolved'):
        participation = state.get('participation', {
            pc: {'actor': pc, 'status': 'playing', 'joined_after': []}
            for pc in state['pcs']})
        for ref in canon['spine']:
            required = {p['actor'] for p in participation.values()
                        if p['status'] != 'terminated_spectator' and ref not in p['joined_after']}
            if not required <= set(state['experienced'].get(ref, [])):
                errors.add('finale_before_all_pc_field_experience')
            if ref not in state['world_events']:
                errors.add('crisis_did_not_occur')
            if state.get('event_end_states', {}).get(ref) != canon['events'][ref]['ends_in']:
                errors.add('finale_before_actual_e_end')
    if state['status'] in ('safe_withdrawal', 'resolved') and not state['source_isolated']:
        errors.add('shelter_is_not_source_resolution')
    # These probes inspect the sample's already written facts. They do not
    # certify arbitrary prose or simulate future PC choices/dice.
    prep = canon['preparation']
    if len(state['pcs']) > 1 and not prep.get('party_history'):
        errors.add('strangers_in_new_party')
    # Before entering the main venue, no normal physical route goes straight
    # outside. This checks a finite map, not the wording "entry is guaranteed".
    seen, pending = set(), [prep['first_place']]
    while pending:
        place = pending.pop()
        if place in seen or place in prep['main_places']:
            continue
        seen.add(place)
        if place == prep['outside_place']:
            errors.add('main_stage_bypass')
        pending.extend(b for a, b, _, _ in canon['routes'].values() if a == place)
    boss = prep.get('boss') or {}
    if (not all(boss.get(k) for k in ('ref', 'hp', 'attack', 'origin', 'limit', 'discovery'))
            or boss.get('place') not in prep['main_places']):
        errors.add('unprepared_final_boss')
    if state['phase'] == 'setup':
        expected = {pc: prep['first_place'] for pc in state['pcs']}
        if state.get('initial_public') != expected or state.get('initial_private') != expected:
            errors.add('initial_projection_conflict')
    roles = {h.get('role') for h in prep['hostiles'].values()}
    if not {'pursue', 'guard', 'roam'} <= roles:
        errors.add('missing_enemy_role')
    for h in prep['hostiles'].values():
        if (h.get('place') not in canon['places'] or not h.get('target') or not h.get('stop')
                or h.get('role') in ('pursue', 'roam') and h.get('next_route') not in canon['routes']):
            errors.add('unprepared_enemy_action')
    for action in state.get('hostile_actions', []):
        h = prep['hostiles'][action['actor']]
        if not set(action.get('used_information', [])) <= set(h['knows']):
            errors.add('enemy_omniscience')
        if action.get('route'):
            a, b, duration, _ = canon['routes'][action['route']]
            if a != h['place'] or action['destination'] != b or action['elapsed'] < duration:
                errors.add('enemy_teleport_or_frozen_time')
        if h['role'] == 'guard' and action['destination'] != h['place'] and not action.get('actual_leave_reason'):
            errors.add('guard_abandons_post_without_cause')
    final = prep['finale']
    if canon['spine']:
        last_state = canon['events'][canon['spine'][-1]].get('ends_in')
        if final['starts_in'] != last_state or final['finishes_in'] == last_state:
            errors.add('last_e_finale_boundary')
    if not all(final.get(k) for k in ('necessary_fact', 'residual_cause', 'actual_use')):
        errors.add('truth_is_only_password')
    for ref, item in prep['items'].items():
        holdings = [(place, items.get(ref, 0)) for place, items in prep['holdings'].items() if items.get(ref)]
        if sum(q for _, q in holdings) != item['quantity'] or holdings != [(item['place'], item['quantity'])]:
            errors.add('duplicate_or_missing_resource')
    if not all(prep['hazard'].get(k) for k in ('exposure', 'response', 'failure', 'damage', 'stop')):
        errors.add('hazard_only_warning')
    recovery = prep['recovery']
    if recovery['item'] not in prep['items'] or recovery['safe_place'] not in canon['places'] or not recovery['access']:
        errors.add('recovery_only_promise')
    protection = prep.get('temporary_protection', {})
    link = protection.get('link', {})
    if (protection.get('place') not in canon['places']
            or protection.get('source_actor') != boss.get('ref')
            or protection.get('capacity', 0) <= 0
            or protection.get('cost_per_pulse', 0) <= 0
            or link.get('from') != boss.get('place')
            or link.get('to') != protection.get('place')
            or link.get('medium') != 'stone' or link.get('duration', 0) <= 0
            or not all(protection.get(k) for k in ('trigger', 'warning', 'response'))
            or protection.get('permanent_end') != 'source_isolated'):
        errors.add('temporary_protection_missing_causal_return')
    if prep['failure_flow'] != ['pc_terminated', 'check_existing_companion_inheritance', 'campaign_failed_if_no_actor']:
        errors.add('campaign_failed_before_inheritance')
    reward_events = {}
    for reward in prep['san_rewards']:
        if reward['achievement'] in reward_events and reward_events[reward['achievement']] != reward['event']:
            errors.add('same_achievement_paid_twice')
        reward_events[reward['achievement']] = reward['event']
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
    s['status'] = 'all_dead'; good(s)  # failure need not reach a success finale
    for terminal in ['safe_withdrawal', 'resolved']:
        s['source_isolated'] = False
        s['status'] = terminal
        bad(s, 'finale_before_all_pc_field_experience')
        s['experienced'] = {e: list(s['pcs']) for e in CANON['spine']}
        bad(s, 'crisis_did_not_occur')
        s['world_events'] = CANON['spine'].copy()
        s['event_end_states'] = {e: CANON['events'][e]['ends_in'] for e in CANON['spine']}
        bad(s, 'shelter_is_not_source_resolution')
        s['source_isolated'] = True; good(s)
        s['experienced'] = {}; s['world_events'] = []
    for count in [1, 2, 3]:
        s = snapshot(count=count); s['phase'] = 'finale'
        s['world_events'] = CANON['spine'].copy()
        s['event_end_states'] = {e: CANON['events'][e]['ends_in'] for e in CANON['spine']}
        s['experienced'] = {e: list(s['pcs']) for e in CANON['spine']}
        good(s)
        s['remote'] = {'E03': ['P1']}; bad(s, 'remote_is_not_experience')
        s['remote'] = {}; s['experienced']['E03'].remove('P1')
        bad(s, 'finale_before_all_pc_field_experience')
    # Real world end, identity and participation are independent of old slots.
    s = snapshot(count=2); s['phase']='finale'
    s['world_events']=CANON['spine'].copy()
    s['event_end_states']={e:CANON['events'][e]['ends_in'] for e in CANON['spine']}
    s['experienced']={e:['ACTOR_A'] for e in CANON['spine']}
    s['participation']={'P1':{'actor':'ACTOR_A','status':'playing','joined_after':[]},
                        'P2':{'actor':'ACTOR_B','status':'terminated_spectator','joined_after':[]}}
    good(s)  # one survivor continues; death is not a missing live actor
    s['participation']['P2']['status']='unconscious'
    bad(s,'finale_before_all_pc_field_experience')
    for e in CANON['spine']:s['experienced'][e].append('ACTOR_B')
    good(s)  # previously experienced unconscious companion need not act
    s['participation']['P2']={'actor':'ACTOR_NEW','status':'playing','joined_after':['E14','E03']}
    bad(s,'finale_before_all_pc_field_experience')  # same slot != old identity
    s['experienced']['E27'].append('ACTOR_NEW');good(s)  # no replay of pre-join E
    s['event_end_states']['E03']='attack_blocked_but_residents_still_exposed'
    bad(s,'finale_before_actual_e_end')
    s['event_end_states']['E03']='residents_protected';good(s)
    # Split PC knowledge is independent. Offscreen occurrence grants no facts.
    s = snapshot(count=2); s['pcs']['P2']['place'] = 'shelter'
    s['pcs']['P2']['facts'] = ['F_ridge_map', 'F_source_brief']
    s['world_events'] = ['E99']; visible = good(s)
    assert 'M_contain' not in visible['P1'] and 'M_contain' in visible['P2']
    s['resolved']['E99'] = 'experienced'; bad(s, 'news_is_not_experience')
    s['resolved'] = {}; s['experienced'] = {'E14': ['P1']}
    s['resolved']['E14'] = 'experienced'; good(s)
    # Preventing one attack preserves safety, while the independent E crisis
    # occurs. Remote effects or late news never fill the missing field credit.
    s['world_events'].append('E03')
    s['resolved']['E03'] = 'local_attack_prevented'; good(s)
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

    # First state and actual role data must exist before calling a world ready.
    s = snapshot(count=2); s['phase'] = 'setup'
    s['initial_public'] = {pc: 'station' for pc in s['pcs']}
    s['initial_private'] = deepcopy(s['initial_public']); good(s)
    s['initial_private']['P2'] = 'shelter'; bad(s, 'initial_projection_conflict')
    s['initial_private']['P2'] = 'not_decided'; bad(s, 'initial_projection_conflict')
    s = snapshot()
    for actor in ('H_tracker', 'H_guard', 'H_patrol'):
        c = deepcopy(CANON); del c['preparation']['hostiles'][actor]
        bad(s, 'missing_enemy_role', c)
    c = deepcopy(CANON)
    c['preparation']['hostiles']['H_tracker']['stop'] = ''
    bad(s, 'unprepared_enemy_action', c)
    s['hostile_actions'] = [
        {'actor': 'H_tracker', 'route': 'R_walk', 'destination': 'shelter',
         'elapsed': 7, 'used_information': ['boot_trace']},
        {'actor': 'H_guard', 'destination': 'ridge', 'used_information': []},
        {'actor': 'H_patrol', 'route': 'R_return', 'destination': 'station',
         'elapsed': 7, 'used_information': []},
    ]; good(s)
    s['pcs']['P1']['place'] = 'ridge'
    s['pcs']['P1']['facts'].append('F_source_brief')
    good(s)  # tracker still uses its old real trace, not the PC's new knowledge
    s['hostile_actions'][0]['used_information'] = ['F_source_brief']
    bad(s, 'enemy_omniscience')
    s['hostile_actions'][0]['used_information'] = ['boot_trace']
    s['hostile_actions'][0]['elapsed'] = 0; bad(s, 'enemy_teleport_or_frozen_time')
    s['hostile_actions'][0]['elapsed'] = 7
    s['hostile_actions'][1]['destination'] = 'station'; bad(s, 'guard_abandons_post_without_cause')
    s = snapshot()
    c = deepcopy(CANON)
    c['preparation']['finale']['finishes_in'] = c['events']['E27']['ends_in']
    bad(s, 'last_e_finale_boundary', c)
    for missing in ('necessary_fact', 'residual_cause', 'actual_use'):
        c = deepcopy(CANON); c['preparation']['finale'][missing] = ''
        bad(s, 'truth_is_only_password', c)
    c = deepcopy(CANON); c['preparation']['holdings']['station'] = {'bandage': 1}
    bad(s, 'duplicate_or_missing_resource', c)
    c = deepcopy(CANON); c['preparation']['hazard']['damage'] = ''
    bad(s, 'hazard_only_warning', c)
    c = deepcopy(CANON); c['preparation']['recovery']['item'] = 'invented_medical_item'
    bad(s, 'recovery_only_promise', c)
    c = deepcopy(CANON); c['preparation']['failure_flow'].reverse()
    bad(s, 'campaign_failed_before_inheritance', c)
    c = deepcopy(CANON)
    c['preparation']['san_rewards'].append(
        {'achievement': 'source_isolated', 'event': 'SYNTH_SAME_SUCCESS_SECOND_NAME'})
    bad(s, 'same_achievement_paid_twice', c)

    # New party and mandatory venue checks retain later voluntary separation.
    s = snapshot(count=2); s['phase'] = 'setup'
    s['initial_public'] = s['initial_private'] = {'P1': 'station', 'P2': 'station'}
    good(s)
    c = deepcopy(CANON); c['preparation']['party_history'] = ''
    bad(s, 'strangers_in_new_party', c)
    s['initial_private'] = {'P1': 'station', 'P2': 'quay'}
    bad(s, 'initial_projection_conflict')
    s = snapshot(count=2); s['pcs']['P2']['place'] = 'shelter'
    good(s)  # real separation after starting together does not require reunion
    c = deepcopy(CANON)
    c['routes']['R_early_rescue'] = ('quay', 'outside', 6, 'boat')
    bad(s, 'main_stage_bypass', c)
    c = deepcopy(CANON); c['preparation']['boss'] = None
    bad(s, 'unprepared_final_boss', c)
    c = deepcopy(CANON); c['preparation']['boss']['place'] = 'outside'
    bad(s, 'unprepared_final_boss', c)
    # Nominated safe choices/S refusal do not switch off the real source.
    s = snapshot(); s['pcs']['P1']['place'] = 'shelter'
    s['sides'] = {'S_song': 'refused', 'S_family': 'refused'}
    good(s)
    charges = CANON['preparation']['temporary_protection']['capacity']
    charges, contact = source_contact(CANON, charges, 2)
    assert (charges, contact) == (2, 'approaching'); accepted += 1
    for expected in [1, 0]:
        charges, contact = source_contact(CANON, charges, 3)
        assert (charges, contact) == (expected, 'attack_blocked'); accepted += 1
    charges, contact = source_contact(CANON, charges, 3)
    assert (charges, contact) == (0, 'response_pending'); accepted += 1
    # Broken contact is real safety; it must not teleport/revive to fill scenes.
    assert source_contact(CANON, 0, 3, link_intact=False) == (0, 'no_contact'); accepted += 1
    assert source_contact(CANON, 0, 3, source_isolated=True) == (0, 'no_contact'); accepted += 1
    for field, value in [('trigger', ''), ('source_actor', 'invented_hunter'),
                         ('cost_per_pulse', 0), ('response', ''), ('permanent_end', 'shelter_reached')]:
        c = deepcopy(CANON); c['preparation']['temporary_protection'][field] = value
        bad(s, 'temporary_protection_missing_causal_return', c)
    c = deepcopy(CANON); c['preparation']['temporary_protection']['link']['from'] = 'station'
    bad(s, 'temporary_protection_missing_causal_return', c)
    # Offline preservation probes use existing V2 containers, not new columns.
    # This is a partial snapshot, not a valid production commit payload.
    preserved = {
        'canon_ref': {'revision': 1},
        'world_delta': {'drivers': {
            'E14': {'world': 'resolved', 'contact': {'P1': True, 'P2': False}},
            'E03': {'world': 'prevented', 'reason': 'existing_executor_captured'},
            'M_repair': {'result': 'failed', 'direct_next': None},
            'S_song': {'decision': 'refused', 'npc_activity': 'continues'},
        }, 'npcs': {'H_tracker': {'place': 'station', 'last_known_pc_place': 'station',
                                 'information': ['boot_trace'], 'next_route': 'R_walk',
                                 'stop': 'no trace beyond shelter'}}},
        'story_context': {'spine': ['E14', 'E03', 'E27'],
                          'known_open': {'P1': ['M_ridge'], 'P2': ['M_contain']}},
        'scene_context': {'awaiting': 'P1', 'offer': 'M_ridge', 'accepted': False},
        'ongoing_consequences': {'R_boat': 'blocked', 'legacy_timer': 'unchanged',
            'shelter': {'scope': 'shelter screen', 'charges': 1, 'source_isolated': False,
                        'source_actor': 'H_echo_warden', 'link': 'ridge_to_shelter_stone',
                        'started_action_elapsed': 2, 'required_duration': 3,
                        'last_attack': 'blocked', 'next_contact': 'approaching'}},
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
            lambda x: x['world_delta']['npcs']['H_tracker'].update(last_known_pc_place='ridge'),
            lambda x: x['world_delta']['npcs']['H_tracker'].update(stop=''),
            lambda x: x['ongoing_consequences']['shelter'].update(source_isolated=True),
            lambda x: x['ongoing_consequences']['shelter'].update(charges=2),
            lambda x: x['ongoing_consequences']['shelter'].update(started_action_elapsed=0),
            lambda x: x['ongoing_consequences']['shelter'].update(last_attack='ongoing_attack'),
        ]
        for mutate in mutations:
            altered = deepcopy(preserved); mutate(altered)
            assert not compare(probes, altered)['passed']; rejected += 1
    print(f'PASS: four-layer finite probes: {accepted} accepted, {rejected} rejected; '
          'two start types, 1-3 PCs, ON/OFF, physical paths, optional life and resume; '
          'no live AI play, complete campaign generation or DB call tested')


if __name__ == '__main__':
    main()
