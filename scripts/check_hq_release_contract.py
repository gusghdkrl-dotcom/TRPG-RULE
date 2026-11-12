#!/usr/bin/env python3
"""Static gate for HQ-only release candidates; never applies SQL or contacts DB."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
PHASES=(
  'trpg_hq_phase1.sql',
  'trpg_hq_phase2_dispatch_return.sql',
  'trpg_hq_phase2b_invariants_and_load.sql',
  'trpg_hq_phase2c_chronicle.sql',
  'trpg_hq_phase3a_evaluation.sql',
  'trpg_hq_phase3b_general_rewards.sql',
  'trpg_hq_phase3c_training_and_reward_resume.sql',
  'trpg_hq_phase4_clara_archive.sql',
  'trpg_hq_phase4b_clara_integrity.sql',
  'trpg_hq_phase4c_clara_active_membership.sql',
  'trpg_hq_phase5_personal_npc_memory.sql',
  'trpg_hq_phase5b_personal_boundary_guard.sql',
  'trpg_hq_phase5c_clara_repeat_personal_questions.sql',
  'trpg_hq_phase6a_chronicle_completion_and_medals.sql',
  'trpg_hq_phase6b_chronicle_special_choice.sql',
  'trpg_hq_phase6c_chronicle_award_integrity.sql',
  'trpg_hq_phase7a_immediate_chapter_failure.sql',
  'trpg_hq_phase7b_chronicle_terminal_roster_consistency.sql',
  'trpg_hq_phase11a_entry_induction_npc_loop_router.sql',
  'trpg_hq_phase11b_verified_briefing_and_full_loop.sql',
  'trpg_hq_phase11c_keep_pending_reward_first.sql'
)
REQUIRED={
    'trpg_hq_phase1.sql':['create schema if not exists trpg_hq','revoke all on schema trpg_hq'],
    'trpg_hq_phase11a_entry_induction_npc_loop_router.sql':['begin_hq_on_visit','hq_npc_service_catalog'],
    'trpg_hq_phase11b_verified_briefing_and_full_loop.sql':['hq_field_preflight','depart_after_actual_briefing'],
    'trpg_hq_phase11c_keep_pending_reward_first.sql':['hq_full_loop_next'],
}
assert len(PHASES)==21 and len(set(PHASES))==21, 'Unexpected migration phase count/order'
for name in PHASES:
    source=ROOT/'docs/sql/dev'/name
    assert source.is_file(), f'Missing migration: {name}'
    body=source.read_text(encoding='utf-8')
    uncommented=re.sub(r'--[^\n]*','',body)
    assert 'trpg_hq' in uncommented, f'Not a HQ-only migration: {name}'
    for fragment in REQUIRED.get(name,[]):
        assert fragment.lower() in body.lower(), f'{name}: missing {fragment}'
    forbidden=[
        r'\b(?:drop|truncate)\s+(?:table|schema)\b',
        r'\b(?:create|alter|drop)\s+(?:table|schema|function)\s+(?:if\s+not\s+exists\s+|if\s+exists\s+)?(?:public|trpg_cards|trpg_private)\.',
        r'\b(?:delete\s+from|update|insert\s+into)\s+(?:public\.gm_checkpoint_history|trpg_private\.gm_canon_documents|trpg_private\.gm_cleanup_archive)\b',
        r'\bgrant\s+[^;]+\bto\s+(?:public|anon|authenticated)\b',
    ]
    for p in forbidden:
        assert not re.search(p,uncommented,re.IGNORECASE), f'Unsafe legacy-object statement: {name}: {p}'
for name in ('hq_readonly_preflight.sql','hq_readonly_postflight.sql'):
    text=(ROOT/'docs/sql/release'/name).read_text(encoding='utf-8')
    stripped=re.sub(r'--[^\n]*','',text)
    assert re.match(r'^\s*SELECT\s',stripped,re.IGNORECASE)
    assert not re.search(r'\b(?:insert|update|delete|drop|truncate|create|alter|grant|revoke|call|do)\b',stripped,re.IGNORECASE),f'Unsafe read-only SQL: {name}'
print('PASS: 21 ordered HQ-only SQL source phases; legacy mutation and public grants barred; audit SQL read-only')
