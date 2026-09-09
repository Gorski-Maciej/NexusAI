#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I02 EXPLAIN CHAIN — /explain zwraca graf:
fakt → reguła(rule_id) → przepis(art. z ISAP) → decyzja, z linkami do źródeł.
RODO art. 15/22 (wyjaśnienie decyzji zautomatyzowanej). Podanalizy: AN01/AN03.
"""
from __future__ import annotations

from v3_p40_common import API_REF, emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P40-I02"
RULE = "jdg.v3_p40_api_dane_ui.explain_chain"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    api_ref = read(API_REF)
    has_explain = "/explain" in api_ref
    checks.append({"name": "api_reference_explain_path", "status": "OK" if has_explain else "FAIL",
                   "detail": f"docs/API_REFERENCJA.md zawiera /explain: {has_explain}"})

    t = threshold_present("v3_p40_explain_nodes_without_link_max")
    checks.append({"name": "isap_link_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p40_explain_nodes_without_link_max w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "api_reference_explain_path": has_explain,
            "isap_link_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_explain_chain")


if __name__ == "__main__":
    raise SystemExit(main())
