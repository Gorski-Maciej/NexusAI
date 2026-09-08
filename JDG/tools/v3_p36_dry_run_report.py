#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I09 DRY-RUN REPORT — raport przed zmianą: ile plików,
jakie reguły, jakie ryzyka — do 4-eyes dla zmian krytycznych — V3 FORTRESS.

Dowód wdrożenia: zmiana bez raportu dry-run = BLOCK; zmiana krytyczna bez
zatwierdzenia 4-eyes = BLOCK (KKS: człowiek zatwierdza,
[NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano). Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present)

INNOVATION = "V3-P36-I09"
RULE = "jdg.v3_p36_generatory_migratory.dry_run_report"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    report_block = "Zmiany bez raportu dry-run" in hay
    checks.append({"name": "report_required", "status": "OK" if report_block else "FAIL",
                   "detail": "zmiana bez raportu dry-run = BLOCK: " + str(report_block)})

    four_eyes = "4-eyes" in hay and "BLOCK" in hay
    checks.append({"name": "four_eyes_critical", "status": "OK" if four_eyes else "FAIL",
                   "detail": "krytyczne bez 4-eyes = BLOCK: " + str(four_eyes)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "report_required": report_block,
            "four_eyes_critical": four_eyes,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_dry_run_report")


if __name__ == "__main__":
    raise SystemExit(main())
