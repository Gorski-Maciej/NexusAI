#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I12 LEGACY DOC RETIREMENT — statusy
CURRENT/ARCHIVED/SUPERSEDED w rejestrze; zero kanibalizmu wersji.
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p41_common import (DOC_REGISTRY, SECTION6_DOCS,
                           emit, main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P41-I12"
RULE = "jdg.v3_p41_dokumentacja.legacy_retirement"
VALID_STATUSES = {"CURRENT", "ARCHIVED", "SUPERSEDED"}


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(DOC_REGISTRY)
    entries = reg.get("documents", {}) if isinstance(reg, dict) else {}
    with_status = [d for d, v in entries.items()
                   if isinstance(v, dict) and v.get("status") in VALID_STATUSES]
    status_ok = len(with_status) >= len(SECTION6_DOCS)
    checks.append({"name": "all_docs_have_status", "status": "OK" if status_ok else "FAIL",
                   "detail": f"statusy lifecycle: {len(with_status)}/{len(SECTION6_DOCS)}"})

    current = [d for d, v in entries.items()
               if isinstance(v, dict) and v.get("status") == "CURRENT"]
    # Kanibalizm: więcej niż 1 CURRENT w tej samej warstwie
    layers = {}
    for d in current:
        layer = entries[d].get("layer", "?") if isinstance(entries.get(d), dict) else "?"
        layers.setdefault(layer, []).append(d)
    cannibals = {k: v for k, v in layers.items() if len(v) > 1 and k != "?"}
    checks.append({"name": "no_version_cannibalism", "status": "OK" if not cannibals else "FAIL",
                   "detail": f"warstwy z wieloma CURRENT: {cannibals if cannibals else 'brak'}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "docs_with_status": len(with_status),
            "current_docs": len(current),
            "no_version_cannibalism": not cannibals,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_legacy_retirement")


if __name__ == "__main__":
    raise SystemExit(main())
