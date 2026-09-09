#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I03 AUTO-ROLLBACK Z POWODEM — regresja → rollback +
raport z powodem + wpis do rejestru wdrożeń; MTTR ≤ SLA (V1: minuty).

Dowód wdrożenia: reguła I03 (BLOCK rollback bez powodu; TRIAGE MTTR > SLA)
+ progi v3_p38_rollback_mttr_max_min + gra wojenna (rollback drill). AN03.
"""
from __future__ import annotations

from v3_p38_common import DEPLOY_CONTRACT, emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P38-I03"
RULE = "jdg.v3_p38_bundle_deploy.auto_rollback"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p38_rollback_mttr_max_min")
    checks.append({"name": "mttr_sla_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p38_rollback_mttr_max_min w data.thresholds: {t}"})

    # Gra wojenna: procedura rollback w kontrakcie deploy (kroki + czas zmierzony)
    contract = __import__("json").loads(read(DEPLOY_CONTRACT)) if read(DEPLOY_CONTRACT) else {}
    drill = contract.get("rollback_drill", {})
    ok_drill = bool(drill.get("procedure_steps")) and isinstance(drill.get("measured_mttr_min"), (int, float))
    checks.append({"name": "rollback_war_game_procedure", "status": "OK" if ok_drill else "FAIL",
                   "detail": f"rollback_drill w kontrakcie: kroki={len(drill.get('procedure_steps', []))}, MTTR zmierzony={drill.get('measured_mttr_min')} min"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "mttr_sla_as_data": t,
            "rollback_drill_documented": ok_drill,
            "measured_mttr_min": drill.get("measured_mttr_min"),
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_auto_rollback")


if __name__ == "__main__":
    raise SystemExit(main())
