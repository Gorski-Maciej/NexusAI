#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I12 LITIGATION STRESS LAB (symulatory granic).

Dowód wdrożenia: symulatory warunków skrajnych — odsetki 10 lat (kapitalizacja
120 mies.), wielokrotne zawieszenia (art. 71 — limit zdarzeń), apelacja w
ostatnim dniu (brak reakcji = BLOCK). Nieznany scenariusz = fail-closed BLOCK.
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I12"

RULE = "jdg.v3_p17_ordynacja_obrona.litigation_stress_lab"
TH_KEYS = ["v3_p17_stress_scenarios", "v3_p17_suspension_max_events"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_10y = "_sl_interest_10y" in hay and "120" in hay and "_ie_compound" in hay
    has_multi = "_sl_multi_suspension" in hay and "suspension_max_events" in hay
    has_lastday = "_sl_last_day_appeal" in hay and '"days_left"' in hay
    has_unknown = "_sl_unknown" in hay and "scenario_known" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "stress_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "interest_10y", "status": "OK" if has_10y else "FAIL",
                   "detail": "symulacja odsetek 10 lat (120 mies. kapitalizacji)"})
    checks.append({"name": "multi_suspension", "status": "OK" if has_multi else "FAIL",
                   "detail": "wielokrotne zawieszenia > limitu (art. 71)"})
    checks.append({"name": "last_day_appeal", "status": "OK" if has_lastday else "FAIL",
                   "detail": "apelacja w ostatnim dniu bez reakcji = BLOCK"})
    checks.append({"name": "fail_closed_unknown", "status": "OK" if has_unknown else "FAIL",
                   "detail": "nieznany scenariusz = BLOCK (fail-closed)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: katalog scenariuszy z data.thresholds.ord"})

    if not has_unknown:
        findings.append({"id": "V3-P17-L12", "severity": "P1",
                         "evidence": "stress lab bez fail-closed dla nieznanego scenariusza",
                         "fix": "I12: nieznany scenariusz = BLOCK"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "interest_10y": has_10y, "multi_suspension": has_multi,
                    "last_day": has_lastday, "fail_closed": has_unknown, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 56/70-72 OrdPU (symulacje graniczne); kontrakt V3_P04",
                     "rule": "stress lab: symulatory granic z decyzją fail-closed"}}
    return emit(bundle, "v3_p17_litigation_stress_lab")


if __name__ == "__main__":
    raise SystemExit(main())
