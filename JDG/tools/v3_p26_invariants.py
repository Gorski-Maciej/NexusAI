#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I07 ZUS INVARIANTS PACK (konstytucja składkowa).

Dowód wdrożenia: invarianty V3_P04 jako rozszerzenia: składki ≥ 0
(CONTRIBUTION_NEGATIVE), podstawa w zakresie (BASE_OUT_OF_RANGE), kolejność
ulg (RELIEF_ORDER_INVALID), precyzja groszowa (GROSZ_PRECISION_INVALID);
każde naruszenie = BLOCK_AND_ALERT.
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I07"
RULE = "jdg.v3_p26_zus_skladki.invariants_pack"
VIOLATIONS = ["CONTRIBUTION_NEGATIVE", "BASE_OUT_OF_RANGE",
              "RELIEF_ORDER_INVALID", "GROSZ_PRECISION_INVALID"]


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_violations = all(v in hay for v in VIOLATIONS)
    has_routing = "BLOCK_AND_ALERT" in hay.split("invariants_pack_decision")[0][-2000:]
    has_active = threshold_present("v3_p26_invariants_active")
    has_p04 = "V3_P04" in hay

    checks.append({"name": "invariants_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "violation_codes", "status": "OK" if has_violations else "FAIL",
                   "detail": f"kody naruszeń: {VIOLATIONS}"})
    checks.append({"name": "block_routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "naruszenie = BLOCK_AND_ALERT (nigdy cichy AUTO_POST)"})
    checks.append({"name": "active_flag", "status": "OK" if has_active else "FAIL",
                   "detail": "v3_p26_invariants_active z zus26 (konstytucja włączona)"})
    checks.append({"name": "p04_contract", "status": "OK" if has_p04 else "FAIL",
                   "detail": "rozszerzenie konstytucji V3_P04 (runtime invariants)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_violations:
        findings.append({"id": "V3-P26-L07", "severity": "P1",
                         "evidence": "brak kompletnego zestawu kodów naruszeń",
                         "fix": "I07: 4 kody naruszeń konstytucji składkowej"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "violation_codes": len(VIOLATIONS),
                    "p04_contract": has_p04},
        "checks": checks, "findings": findings,
        "contract": {"binding": "INV pack wiąże P04 (konstytucja runtime) i P44 "
                                "(certyfikacja): 4 kody naruszeń fail-closed",
                     "rule": "każde naruszenie = BLOCK_AND_ALERT z listą"}}
    return emit(bundle, "v3_p26_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
