#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I05 TP THRESHOLD SENTINEL (art. 23o/23zf PIT).

Monitoring progów dokumentacji TP (towary 10M / usługi 2M / finansowe 2,5M PLN)
z alertami dokumentacyjnymi. Dowód: reguła tp_threshold_sentinel + parametry
tp_*_transactions_pln w thresholds.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I05"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.tp_threshold_sentinel", hay)
    has_triage = "TRIAGE_QUEUE" in hay and "tp_status" in hay
    missing = thresholds_missing(["tp_goods_transactions_pln", "tp_services_transactions_pln",
                                  "tp_financial_transactions_pln", "tp_documentation_months"])

    checks.append({"name": "tp_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła tp_threshold_sentinel: {has_rule}"})
    checks.append({"name": "triage_on_exceed", "status": "OK" if has_triage else "FAIL",
                   "detail": "przekroczenie progu → TRIAGE_QUEUE + checklista dokumentacyjna"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów tp_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P15-L06", "severity": "P2",
                         "evidence": f"brak parametrów progów TP w thresholds: {missing}",
                         "fix": "I05: parametry progów TP (ADR-002) + alert dokumentacyjny"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"tp_rule": has_rule, "triage": has_triage, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P36 (kalendarz terminów), P44",
                     "rule": "przekroczenie progu TP = TRIAGE_QUEUE z checklistą dokumentacyjną i terminem 6 mies."}}
    return emit(bundle, "v3_p15_tp_threshold_sentinel")


if __name__ == "__main__":
    raise SystemExit(main())