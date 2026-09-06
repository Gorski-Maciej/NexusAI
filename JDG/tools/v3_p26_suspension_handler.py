#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I05 SUSPENSION CONTRIBUTION HANDLER (zawieszenie).

Dowód wdrożenia: zawieszenie wymaga pauzy ulgi (aktywna ulga bez pauzy = BLOCK);
dni zdrowotnej w zawieszeniu = TRIAGE; długie zawieszenie (≥24 mies.) = TRIAGE;
integracja z cyklem życia V3_P23.
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I05"
RULE = "jdg.v3_p26_zus_skladki.suspension_handler"


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_pauza = "_su_relief_paused" in hay and "_su_relief_active" in hay
    has_health_days = '"health_contribution_days"' in hay
    has_alert = threshold_present("v3_p26_suspension_alert_months")
    has_p23 = "V3_P23" in hay

    checks.append({"name": "suspension_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "relief_pauza_block", "status": "OK" if has_pauza else "FAIL",
                   "detail": "aktywna ulga w zawieszeniu bez pauzy = BLOCK"})
    checks.append({"name": "health_days_triage", "status": "OK" if has_health_days else "FAIL",
                   "detail": "dni zdrowotnej w zawieszeniu = TRIAGE"})
    checks.append({"name": "long_suspension_alert", "status": "OK" if has_alert else "FAIL",
                   "detail": "próg alertu 24 mies. z zus26 (P05)"})
    checks.append({"name": "lifecycle_contract", "status": "OK" if has_p23 else "FAIL",
                   "detail": "kontrakt cyklu życia V3_P23"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_pauza:
        findings.append({"id": "V3-P26-L05", "severity": "P1",
                         "evidence": "brak wymuszenia pauzy ulgi przy zawieszeniu",
                         "fix": "I05: BLOCK dla relief_active && !relief_paused"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "pauza_block": has_pauza,
                    "alert_months": 24, "p23_contract": has_p23},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Skutki składkowe zawieszenia wiążą P23 (zawieszenie CEIDG) "
                                "i P24 (zasiłki); symulacja ścieżki składkowej",
                     "rule": "ulga bez pauzy = BLOCK; dni zdrowotnej = TRIAGE"}}
    return emit(bundle, "v3_p26_suspension_handler")


if __name__ == "__main__":
    raise SystemExit(main())
