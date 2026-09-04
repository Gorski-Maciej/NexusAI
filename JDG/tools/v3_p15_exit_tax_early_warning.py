#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I07 EXIT TAX EARLY WARNING (art. 24cg/30da PIT).

Wczesne wykrywanie zdarzeń exit tax (przeniesienie majątku / zmiana rezydencji)
powyżej progu 4M PLN — alert + checklista; odroczenie EOG. Dowód: reguła
exit_tax_early_warning + parametry exit_tax_* w thresholds.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I07"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.exit_tax_early_warning", hay)
    has_block = "BLOCK_AND_ALERT" in hay and "exit_tax_status" in hay
    has_deferral = "deferral_years_eea" in hay
    missing = thresholds_missing(["exit_tax_threshold_pln", "exit_tax_rate_pct",
                                  "exit_tax_deferral_years_eea"])

    checks.append({"name": "exit_tax_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła exit_tax_early_warning: {has_rule}"})
    checks.append({"name": "block_on_trigger", "status": "OK" if has_block else "FAIL",
                   "detail": "zdarzenie powyżej progu → BLOCK_AND_ALERT + checklista"})
    checks.append({"name": "deferral_eea", "status": "OK" if has_deferral else "FAIL",
                   "detail": "odroczenie EOG (5 lat) uwzględnione"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów exit_tax_*: {missing or 'BRAK'}"})

    if not has_block:
        findings.append({"id": "V3-P15-L08", "severity": "P1",
                         "evidence": "exit tax bez BLOCK_AND_ALERT przy przekroczeniu progu",
                         "fix": "I07: alert + checklista dokumentacyjna; odroczenie EOG"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"exit_tax_rule": has_rule, "block": has_block,
                    "deferral": has_deferral, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P44, P10 (golden), P04 (inwarianty)",
                     "rule": "zdarzenie exit tax powyżej progu = BLOCK_AND_ALERT + checklista; odroczenie EOG rozważane"}}
    return emit(bundle, "v3_p15_exit_tax_early_warning")


if __name__ == "__main__":
    raise SystemExit(main())