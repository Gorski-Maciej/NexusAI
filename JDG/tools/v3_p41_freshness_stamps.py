#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I09 DOC FRESHNESS STAMPS — „ostatnia weryfikacja"
per dokument; odświeżanie po walidacji P34. Podanalizy: AN01.
"""
from __future__ import annotations

from datetime import datetime, timezone

from v3_p41_common import (DOC_REGISTRY, SECTION6_DOCS, DOCS,
                           emit, main_jdg_wired, now, read_json, rule_present, threshold_present)

INNOVATION = "V3-P41-I09"
RULE = "jdg.v3_p41_dokumentacja.freshness_stamps"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(DOC_REGISTRY)
    entries = reg.get("documents", {}) if isinstance(reg, dict) else {}
    stamped = [d for d, v in entries.items()
               if isinstance(v, dict) and v.get("last_verified")]
    stamped_ok = len(stamped) >= len(SECTION6_DOCS)
    checks.append({"name": "stamps_in_registry", "status": "OK" if stamped_ok else "FAIL",
                   "detail": f"stemple last_verified: {len(stamped)}/{len(SECTION6_DOCS)}"})

    t = threshold_present("v3_p41_doc_freshness_max_days")
    checks.append({"name": "freshness_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p41_doc_freshness_max_days w data.thresholds: {t}"})

    # Validator P34 jako mechanizm odświeżania
    validator_ok = (DOCS.parent / "tools" / "doc_consistency_validator.py").exists()
    checks.append({"name": "refresh_mechanism_exists", "status": "OK" if validator_ok else "FAIL",
                   "detail": f"tools/doc_consistency_validator.py (P34): {validator_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "stamps_in_registry": len(stamped),
            "freshness_threshold_as_data": t,
            "refresh_mechanism_exists": validator_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_freshness_stamps")


if __name__ == "__main__":
    raise SystemExit(main())
