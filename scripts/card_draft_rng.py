#!/usr/bin/env python3
"""TRPG 4-candidate draft RNG. Input: JSON pool from trpg_cards.draft_pool.

This file generates *only* random candidate IDs; Supabase validates and records
the resulting offer atomically. PC d100 rolls are never generated here.
Run: python3 scripts/card_draft_rng.py < pool.json
     python3 scripts/card_draft_rng.py --growth-roll
"""
from __future__ import annotations

import argparse
import json
import secrets
import sys

SYSTEM_RANDOM = secrets.SystemRandom()
CLASS_RARITY_WEIGHT = {"rare": 30, "epic": 15, "legendary": 5}


def choose(items: list[dict], label: str, audit: list, exclude=()):
    eligible = [x for x in items if x["id"] not in exclude]
    if not eligible:
        audit.append({"slot": label, "status": "exhausted"})
        return None
    if label in {"current", "all"}:
        tiers = {rarity: [x for x in eligible if x["rarity"] == rarity]
                 for rarity in CLASS_RARITY_WEIGHT}
        live = [(rarity, weight) for rarity, weight in CLASS_RARITY_WEIGHT.items()
                if tiers[rarity]]
        total = sum(weight for _, weight in live)
        ticket = SYSTEM_RANDOM.randrange(total)
        remain = ticket
        for rarity, weight in live:
            if remain < weight:
                chosen_tier = rarity
                break
            remain -= weight
        matches = tiers[chosen_tier]
        index = SYSTEM_RANDOM.randrange(len(matches))
        choice = matches[index]["id"]
        audit.append({"slot": label, "rarity_weights": dict(live),
                      "weight_ticket": ticket, "candidate_index": index,
                      "candidate_count": len(matches), "selected_rarity": chosen_tier})
    else:
        index = SYSTEM_RANDOM.randrange(len(eligible))
        choice = eligible[index]["id"]
        audit.append({"slot": label, "candidate_index": index,
                      "candidate_count": len(eligible)})
    return choice


def draft(pool: dict) -> dict:
    for slot in ("current", "all", "growth", "neutral"):
        if not isinstance(pool.get(slot), list):
            raise ValueError(f"Missing/invalid pool: {slot}")
    audit = []
    current = choose(pool["current"], "current", audit)
    all_classes = choose(pool["all"], "all", audit,
                         exclude={current} if current is not None else set())
    growth = choose(pool["growth"], "growth", audit)
    neutral = choose(pool["neutral"], "neutral", audit)
    return {"offers": {"current": current, "all": all_classes,
                       "growth": growth, "neutral": neutral},
            "rng": "PYTHON_SYSTEM_RANDOM_V1", "audit": audit}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--growth-roll", action="store_true",
                        help="One new 1..100 Python roll for an already selected Lv.1..4 Growth")
    args = parser.parse_args()
    if args.growth_roll:
        print(json.dumps({"roll": SYSTEM_RANDOM.randrange(1, 101),
                          "rng": "PYTHON_SYSTEM_RANDOM_V1"}))
    else:
        obj = json.load(sys.stdin)
        print(json.dumps(draft(obj), ensure_ascii=False, separators=(",", ":")))


if __name__ == "__main__":
    main()
