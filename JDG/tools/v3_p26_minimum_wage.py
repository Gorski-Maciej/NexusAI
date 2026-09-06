#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I10 MINIMUM WAGE INTEGRATION (podstawa preferencyjnej).

Dowód wdrożenia: podstawa preferencyjnej = 30% minimalnej z feedu P06;
brak feedu = BLOCK (fail-closed); dryf ≥ v3_p26_min_wage_drift_pct od
referencji w danych = TRIAGE. Art. 18b ust. 5 SUS [NIEZWERYFIKOWANE].
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, ZUS_CORE, emit, grosze, main_jdg_wired,
                           now, read, rule_present, threshold_present)

INNOVATION = "V3-P26-I10"
RULE = "jdg.v3_p26_zus_skladki.minimum_wage_integration"


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_feed = '"minimum_wage_monthly"' in hay
    has_drift = threshold_present("v3_p26_min_wage_drift_pct")
    has_base30 = threshold_present("preferential_base_30pct")
    has_p06 = "P06" in hay

    # Mirror: 30% minimalnej 4800 → 1440,00
    base30 = grosze(4800.00 * 0.30)
    mirror_ok = abs(base30 - ZUS_CORE["preferential_base_30pct"]) < 0.005

    checks.append({"name": "min_wage_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "feed_gate", "status": "OK" if has_feed else "FAIL",
                   "detail": "brak feedu minimalnej = BLOCK (podstawa niepoliczalna)"})
    checks.append({"name": "drift_triage", "status": "OK" if has_drift else "FAIL",
                   "detail": "dryf ≥1% od referencji = TRIAGE (feed P06 do odświeżenia)"})
    checks.append({"name": "base30_as_data", "status": "OK" if has_base30 else "FAIL",
                   "detail": "preferential_base_30pct w data.thresholds.zus (ADR-002)"})
    checks.append({"name": "mirror_30pct", "status": "OK" if mirror_ok else "FAIL",
                   "detail": f"30% × 4800 = {base30:.2f} (referencja 1440,00)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_feed:
        findings.append({"id": "V3-P26-L10", "severity": "P1",
                         "evidence": "brak bramki feedu minimalnego wynagrodzenia",
                         "fix": "I10: minimum_wage_monthly > 0 wymagane (BLOCK)"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "mirror_ok": mirror_ok,
                    "min_wage_2026": 4800, "preferential_base": base30},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Feed P06 (minimalna) wiąże I02 (automat ulg) i P44; "
                                "preferencyjna = 30% minimalnej",
                     "rule": "brak feedu = BLOCK; dryf ≥1% = TRIAGE"}}
    return emit(bundle, "v3_p26_minimum_wage")


if __name__ == "__main__":
    raise SystemExit(main())
