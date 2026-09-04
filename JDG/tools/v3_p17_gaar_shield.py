#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I03 GAAR SHIELD FRAMEWORK (art. 119a OrdPU).

Dowód wdrożenia: scoring OCHRONNY GAAR — MAE (korzyść < 1 mln = wyłączenie),
checklista wartości dodanej/uzasadnienia biznesowego, ukrycie, sztuczne kroki.
Sygnał = NEEDS_ADVICE + dokumentacja, NIGDY automatyczna wina; wysoki sygnał =
BLOCK do opinii doradcy.
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I03"

RULE = "jdg.v3_p17_ordynacja_obrona.gaar_shield_framework"
TH_KEYS = ["v3_p17_gaar_mae_threshold_pln"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_mae = "_ga_mae" in hay and '"mae_excluded"' in hay and "mae_threshold_pln" in hay
    has_checklist = '"documented"' in hay and "business_rationale_documented" in hay and "value_added_documented" in hay
    has_protective = '"protective": true' in hay and "NEEDS_ADVICE" in hay and "NIE" in hay
    has_not_guilt = "certainty_impact" in hay and "_ga_score" in hay
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "gaar_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "mae_1mln", "status": "OK" if has_mae else "FAIL",
                   "detail": "MAE: korzyść < 1 mln = wyłączenie (parametryzowane)"})
    checks.append({"name": "protective_checklist", "status": "OK" if has_checklist else "FAIL",
                   "detail": "checklista ochronna (wartość dodana, uzasadnienie biznesowe)"})
    checks.append({"name": "protective_scoring", "status": "OK" if has_protective else "FAIL",
                   "detail": "scoring ochronny — NIE wina, NEEDS_ADVICE"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: próg MAE z data.thresholds.ord"})

    if not has_mae:
        findings.append({"id": "V3-P17-L03", "severity": "P1",
                         "evidence": "GAAR bez parametryzowanej granicy MAE",
                         "fix": "I03: MAE 1 mln jako dane + test granicy"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "mae": has_mae, "checklist": has_checklist,
                    "protective": has_protective, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 119a OrdPU; certainty_class V3_P03 (klasa, nie wina); "
                                "interpretacje LKG V3_P01",
                     "rule": "scoring ochronny GAAR z MAE i ścieżką interpretacji"}}
    return emit(bundle, "v3_p17_gaar_shield")


if __name__ == "__main__":
    raise SystemExit(main())
