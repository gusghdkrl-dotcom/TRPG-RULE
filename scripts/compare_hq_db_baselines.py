#!/usr/bin/env python3
"""Compare confidential production/restore preflight JSON without printing data or fingerprints."""
import argparse
import json
from pathlib import Path

REQUIRED_TABLES = frozenset({
    "public.gm_checkpoint_history",
    "trpg_private.gm_canon_documents",
    "trpg_private.gm_cleanup_archive",
    "trpg_cards.players",
    "trpg_cards.card_catalog",
    "trpg_cards.owned_cards",
    "trpg_cards.growth_levels",
    "trpg_cards.campaigns",
    "trpg_cards.campaign_members",
    "trpg_cards.character_links",
    "trpg_cards.drafts",
    "trpg_cards.loadouts",
})

def unwrap(value):
    if isinstance(value, list) and len(value) == 1:
        value = value[0]
    if "production_baseline" in value:
        value = value["production_baseline"]
    return value

def differences(original, restored, allow_hq_added=False):
    """Return names of mismatched checks; never return private data or hashes."""
    issues = []
    for label, value in (("original", original), ("restored", restored)):
        if not isinstance(value, dict) or set(value.get("existing_data", {})) != REQUIRED_TABLES:
            issues.append(label + ": missing/unexpected protected table")
            continue
        for name in REQUIRED_TABLES:
            item = value["existing_data"][name]
            if not isinstance(item, dict) or not isinstance(item.get("rows"), int) or not isinstance(item.get("fingerprint"), str) or len(item["fingerprint"]) != 32:
                issues.append(label + ": invalid metadata: " + name)
    if issues:
        return issues
    for name in sorted(REQUIRED_TABLES):
        if original["existing_data"][name] != restored["existing_data"][name]:
            issues.append("protected contents changed: " + name)
    for key in ("core_function_count", "card_catalog_count", "canonical_loadout_normalized_md5", "append_only_triggers_enabled"):
        if key not in original or key not in restored or original[key] != restored[key]:
            issues.append("legacy invariant changed: " + key)
    left = original.get("db_schema", {})
    right = restored.get("db_schema", {})
    for key in ("checkpoint_exists", "private_canon_exists", "archive_exists", "cards_exists"):
        if left.get(key) is not True or right.get(key) is not True:
            issues.append("missing protected schema: " + key)
    if left.get("hq_absent") is not True:
        issues.append("initial baseline must precede HQ installation")
    if allow_hq_added:
        if right.get("hq_absent") is not False:
            issues.append("after-HQ snapshot does not show installed HQ")
    elif right.get("hq_absent") is not True:
        issues.append("restore snapshot must precede HQ installation")
    return issues

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("original", help="Private preflight JSON from production")
    parser.add_argument("restored", help="Private preflight JSON from isolated restored database")
    parser.add_argument("--after-hq", action="store_true", help="Allow a new HQ schema while requiring legacy data unchanged")
    args = parser.parse_args()
    try:
        before = unwrap(json.loads(Path(args.original).read_text(encoding="utf-8")))
        after = unwrap(json.loads(Path(args.restored).read_text(encoding="utf-8")))
        errors = differences(before, after, args.after_hq)
    except (OSError, ValueError, TypeError, KeyError) as exc:
        parser.exit(2, "Invalid or inaccessible private preflight JSON: " + type(exc).__name__ + "\n")
    if errors:
        for error in errors:
            print("FAIL:", error)
        return 1
    print("PASS: protected table counts and content fingerprints, legacy functions, and immutability safeguards match")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
