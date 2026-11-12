"""Pure local unit tests of confidential-baseline comparison; no DB credentials or private records."""
import copy
from compare_hq_db_baselines import REQUIRED_TABLES, differences, unwrap

def fixture():
    return {
        "existing_data": {name: {"rows": 3, "fingerprint": "a" * 32} for name in REQUIRED_TABLES},
        "core_function_count": 25,
        "card_catalog_count": 66,
        "canonical_loadout_normalized_md5": "f" * 32,
        "append_only_triggers_enabled": {"canon": True},
        "db_schema": {
            "hq_absent": True,
            "checkpoint_exists": True,
            "private_canon_exists": True,
            "archive_exists": True,
            "cards_exists": True,
        },
    }

original = fixture()
assert unwrap([{"production_baseline": original}]) == original
restored = copy.deepcopy(original)
assert not differences(original, restored)
restored["existing_data"]["trpg_private.gm_canon_documents"]["rows"] += 1
assert any("trpg_private.gm_canon_documents" in s for s in differences(original, restored))
restored = copy.deepcopy(original)
restored["existing_data"]["trpg_private.gm_cleanup_archive"]["fingerprint"] = "b" * 32
assert any("trpg_private.gm_cleanup_archive" in s for s in differences(original, restored))
restored = copy.deepcopy(original)
restored["db_schema"]["hq_absent"] = False
assert differences(original, restored)
assert not differences(original, restored, allow_hq_added=True)
restored = copy.deepcopy(original)
restored["core_function_count"] = 26
assert any("core_function_count" in s for s in differences(original, restored))
restored = copy.deepcopy(original)
restored["existing_data"].pop("trpg_cards.card_catalog")
assert differences(original, restored)
print("PASS: production/restore baseline comparator rejects record, fingerprint, schema and core function drift")
