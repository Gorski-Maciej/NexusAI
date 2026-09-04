#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I07 LOSS HARVESTING PLANNER (art. 9 ust. 3 PIT).

Plan wykorzystania straty: max 50% straty rocznie, 5 lat od roku straty
(okno: rok straty + 5 lat). Harmonogram 5-letni + monitoring okien; podwójne
odliczenie straty = BLOCK_AND_ALERT (BLOCKER); braki danych = NEEDS_ADVICE.
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, pit_domain_file, emit

INNOVATION = "V3-P14-I07"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.loss_harvesting_planner", hay)
    has_505 = "annual_cap_pct" in hay and "last_usable_year" in hay and "schedule" in hay
    has_window = "window_years" in hay and "remaining_after_this_year_pln" in hay
    has_blocker = "double_counting_risk" in hay and "BLOCK_AND_ALERT" in hay
    missing = thresholds_missing(["loss_carry_forward_years", "loss_carry_forward_max_pct"])
    domain_ok = pit_domain_file("tax_loss_harvesting_enterprise.rego")

    checks.append({"name": "loss_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła loss_harvesting_planner: {has_rule}"})
    checks.append({"name": "50pct_5yr", "status": "OK" if has_505 else "FAIL",
                   "detail": "50%/rok + okno 5 lat + harmonogram (schedule)"})
    checks.append({"name": "window_monitor", "status": "OK" if has_window else "FAIL",
                   "detail": "monitoring okien (pozostało do wykorzystania)"})
    checks.append({"name": "double_count_blocker", "status": "OK" if has_blocker else "FAIL",
                   "detail": "podwójne odliczenie straty → BLOCK_AND_ALERT"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów straty: {missing or 'BRAK'}"})
    checks.append({"name": "domain_loss", "status": "OK" if domain_ok else "FAIL",
                   "detail": "rules/pit/tax_loss_harvesting_enterprise.rego obecny — rozszerzenie"})

    if not has_blocker:
        findings.append({"id": "V3-P14-L07", "severity": "P1",
                         "evidence": "brak BLOCKERA podwójnego odliczenia straty",
                         "fix": "I07: wykrycie podwójnego użycia straty → BLOCK_AND_ALERT (art. 9 ust. 3)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "cap_50_5yr": has_505, "window": has_window,
                    "blocker": has_blocker, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty), P36 (kalendarz), P05 (okna temporalne)",
                     "rule": "plan wykorzystania straty 50%/5 lat z monitoringiem okien i BLOCKEREM duplikatu"}}
    return emit(bundle, "v3_p14_loss_harvesting")


if __name__ == "__main__":
    raise SystemExit(main())
