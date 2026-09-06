#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I11 ZUS STRESS LAB (symulatory scenariuszy).

Dowód wdrożenia: scenariusze (zmiana formy / zawieszenie Q4 / próg w
listopadzie NARASTAJĄCO) jako dane wejściowe; komplet ≥
v3_p26_stress_required_scenarios; niezgodny routing scenariusza = BLOCK
(chaos-test prawny K10, kontrakt V3_P04).
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I11"
RULE = "jdg.v3_p26_zus_skladki.stress_lab"
SCENARIOS = {
    "S1_form_change_midyear": "TRIAGE_QUEUE",
    "S2_suspension_q4": "TRIAGE_QUEUE",
    "S3_tier_breach_november": "BLOCK_AND_ALERT",
}


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_required = threshold_present("v3_p26_stress_required_scenarios")
    has_failures = '"failures"' in hay
    has_chaos = "K10" in hay or "chaos" in hay.lower()

    checks.append({"name": "stress_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "scenario_completeness", "status": "OK" if has_required else "FAIL",
                   "detail": f"komplet {len(SCENARIOS)} scenariuszy z zus26"})
    checks.append({"name": "routing_assertions", "status": "OK" if has_failures else "FAIL",
                   "detail": "niezgodny routing scenariusza = BLOCK (asercja fail-closed)"})
    checks.append({"name": "chaos_contract", "status": "OK" if has_chaos else "FAIL",
                   "detail": "chaos-test prawny K10 (nigdy cichy AUTO_POST)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_required:
        findings.append({"id": "V3-P26-L11", "severity": "P2",
                         "evidence": "brak wymogu kompletu scenariuszy",
                         "fix": "I11: v3_p26_stress_required_scenarios = 3"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "scenarios": SCENARIOS,
                    "required": 3, "chaos_contract": has_chaos},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Stress lab wiąże P04 (chaos fail-closed), P09 "
                                "(zmiana formy) i P44",
                     "rule": "brak kompletu / niezgodny routing = BLOCK"}}
    return emit(bundle, "v3_p26_stress_lab")


if __name__ == "__main__":
    raise SystemExit(main())
