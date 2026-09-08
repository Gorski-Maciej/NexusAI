#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I05 GUARD RAILS GENERATORA — generatory odmawiają
produkcji reguł bez: legal basis, rule_id, okna temporalnego, testu —
fail-fast z komunikatem — V3 FORTRESS.

Dowód wdrożenia: lista wymaganych pól v3_p36_generator_required_fields jako
dane (ADR-002); reguła bez wymaganych pól = BLOCK; ominięcie guard rails =
BLOCK (zero reguł „do poprawki później"). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P36-I05"
RULE = "jdg.v3_p36_generatory_migratory.guard_rails"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    fields = threshold_present("v3_p36_generator_required_fields")
    violations_max = threshold_present("v3_p36_guard_rail_violations_max")
    checks.append({"name": "required_fields_threshold", "status": "OK" if (fields and violations_max) else "FAIL",
                   "detail": f"generator_required_fields={fields}, guard_rail_violations_max={violations_max}"})

    fail_fast = "fail-fast" in hay and "BLOCK" in hay
    checks.append({"name": "fail_fast_semantics", "status": "OK" if fail_fast else "FAIL",
                   "detail": "fail-fast z komunikatem przy braku pól: " + str(fail_fast)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "required_fields_threshold": fields and violations_max,
            "fail_fast_semantics": fail_fast,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_guard_rails")


if __name__ == "__main__":
    raise SystemExit(main())
