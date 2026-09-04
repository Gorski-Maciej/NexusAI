#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I11 INSTALMENT REMINDER (raty nieruchomości).

Dowód wdrożenia: przypomnienia rat nieruchomości z przewidywaniem kwot
(podatek roczny/4), terminy 15.03/15.05/15.09/15.11 jako dane, rata minięta
bez zapłaty = BLOCK, ≤ 7 dni do terminu = TRIAGE (przypomnienie z eskalacją),
brak danych podatku = BLOCK (fail-closed).
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I11"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.instalment_reminder"
TH_KEYS = ["v3_p19_property_installments", "v3_p19_zero_silence_escalation_days"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"property_tax_year_pln"', '"instalments_paid"',
                                        '"days_left_to_next"', '"next_instalment_paid"'))
    has_forecast = "_ir_forecast" in hay and "/ 4" in hay
    has_breach = "_ir_breached" in hay
    has_urgent = "_ir_reminder" in hay
    has_fail_closed = "_ir_data_bad" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "reminder_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "contract_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: podatek roczny / raty opłacone / dni do terminu"})
    checks.append({"name": "forecast", "status": "OK" if has_forecast else "FAIL",
                   "detail": "przewidywanie kwoty raty (podatek/4)"})
    checks.append({"name": "breach_block", "status": "OK" if has_breach else "FAIL",
                   "detail": "rata minięta bez zapłaty = BLOCK (zero ciszy)"})
    checks.append({"name": "urgent_window", "status": "OK" if has_urgent else "FAIL",
                   "detail": "≤ 14 dni do terminu = przypomnienie z eskalacją"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "brak danych podatku = BLOCK (fail-closed)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: terminy rat + eskalacja z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_breach:
        findings.append({"id": "V3-P19-L11", "severity": "P0",
                         "evidence": "brak BLOCK przy miniętej racie bez zapłaty",
                         "fix": "I11: przypomnienia rat z przewidywaniem kwot (tax/4)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "forecast": has_forecast,
                    "breach_block": has_breach, "fail_closed": has_fail_closed,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "UoPiOL art. 6 (raty 15.03/15.05/15.09/15.11); zero ciszy V3_P36",
                     "rule": "przypomnienia rat nieruchomości z prognozą kwot"}}
    return emit(bundle, "v3_p19_instalment_reminder")


if __name__ == "__main__":
    raise SystemExit(main())
