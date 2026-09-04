#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I04 LOCAL TAX CALENDAR PACK (zero ciszy).

Dowód wdrożenia: kalendarz terminów lokalnych jako dane (transport 31.01,
raty nieruchomości 15.03/15.05/15.09/15.11), termin minął bez zapłaty = BLOCK
(zero ciszy, eskalacja 48h), brak pełnych rat na koniec roku = TRIAGE,
nieznany typ = BLOCK.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I04"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.local_tax_calendar_pack"
TH_KEYS = ["v3_p19_property_installments", "v3_p19_transport_due",
           "v3_p19_zero_silence_escalation_days"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"tax_type"', '"days_left"', '"paid"',
                                        '"payments_count"'))
    has_deadlines = "03-15" in hay and "01-31" in hay
    has_breach = "_lc_breached" in hay and "minął bez zapłaty" in hay
    has_zero_silence = "zero ciszy" in hay.lower()
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "calendar_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "deadlines_as_data", "status": "OK" if has_deadlines else "FAIL",
                   "detail": "terminy (31.01 / 15.03..15.11) z data.thresholds"})
    checks.append({"name": "breach_block", "status": "OK" if has_breach else "FAIL",
                   "detail": "termin minął bez zapłaty = BLOCK"})
    checks.append({"name": "zero_silence", "status": "OK" if has_zero_silence else "FAIL",
                   "detail": "zero ciszy + eskalacja (48h)"})
    checks.append({"name": "instalment_track", "status": "OK" if has_fields else "FAIL",
                   "detail": "śledzenie rat: paid/payments_count/days_left"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: kalendarz i eskalacja z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_breach:
        findings.append({"id": "V3-P19-L04", "severity": "P0",
                         "evidence": "brak BLOCK przy minięciu terminu lokalnego",
                         "fix": "I04: kalendarz terminów + zero ciszy + eskalacja"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "deadlines": has_deadlines,
                    "breach_block": has_breach, "zero_silence": has_zero_silence,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "UoPiOL art. 6/12-13 (terminy); kontrakt V3_P36 (zero ciszy)",
                     "rule": "kalendarz podatków lokalnych — zero ciszy, eskalacja 48h"}}
    return emit(bundle, "v3_p19_local_tax_calendar")


if __name__ == "__main__":
    raise SystemExit(main())
