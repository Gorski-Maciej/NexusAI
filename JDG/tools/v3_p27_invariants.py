#!/usr/bin/env python3
"""NexusAI JDG — V3-P27-I08 INTERNATIONAL INVARIANTS PACK.

Dowód wdrożenia: INV-X01 MDR human-only / INV-X02 exit tax advisor-only / INV-X03 CFC need-advice / INV-X04 zero AUTO_POST (kontrakt P04)
"""
from __future__ import annotations

from v3_p27_common import (P27_RULES, THRESHOLDS, MAIN_JDG, emit, legacy_stub_hits,
                           main_jdg_wired, now, read, rule_present,
                           stub_scan, threshold_present)

INNOVATION = "V3-P27-I08"
RULE = "jdg.v3_p27_cfc_exit_mdr.international_invariants_pack"


def main() -> int:
    hay = read(P27_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    keys_missing = [k for k in ["v3_p27_invariants_active", "v3_p27_mdr_human_only", "v3_p27_exit_tax_advisor_only", "v3_p27_cfc_needs_advice_only"] if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})
    has_routing = "BLOCK_AND_ALERT" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: BLOCK_AND_ALERT (naruszenie = BLOCK)"})
    legacy = legacy_stub_hits()
    ap_hits = {k: len(v) for k, v in legacy.items() if v}
    checks.append({"name": "legacy_ap_scan", "status": "OK" if not ap_hits else "FAIL",
                   "detail": f"anty-wzorce w plikach legacy: {ap_hits or 'brak'}"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p91"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p27_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
