#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I10 INTERPRETATION LIBRARY (LKG V3_P01).

Dowód wdrożenia: biblioteka interpretacji KIS per przepis z sentinelem zmiany
prawa — zmiana przepisu = utrata ochrony (TRIAGE); brak wpisu = luka
dokumentacyjna (→ wniosek I07); wpis ważny = SUGGEST (ochrona).
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I10"

RULE = "jdg.v3_p17_ordynacja_obrona.interpretation_library"
TH_KEYS = ["v3_p17_interpretation_law_change_sentinel"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_lookup = '"lookup_hit"' in hay and '"interpretation_valid"' in hay and '"law_changed"' in hay
    has_sentinel = "law_change_sentinel" in hay and "LKG" in hay
    has_protection = '"protection_active"' in hay and "ochrona wygasła" in hay.replace("_", " ")
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "library_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "lookup", "status": "OK" if has_lookup else "FAIL",
                   "detail": "wyszukiwanie per przepis (hit/ważność/zmiana prawa)"})
    checks.append({"name": "law_change_sentinel", "status": "OK" if has_sentinel else "FAIL",
                   "detail": "sentinel zmiany prawa = utrata ochrony"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: sentinel z data.thresholds.ord"})

    if not has_sentinel:
        findings.append({"id": "V3-P17-L10", "severity": "P1",
                         "evidence": "biblioteka interpretacji bez sentinela zmiany prawa",
                         "fix": "I10: zmiana prawa = utrata ochrony (sentinel)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "lookup": has_lookup, "sentinel": has_sentinel,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 14b-14d OrdPU; kontrakt LKG V3_P01; certainty V3_P03",
                     "rule": "biblioteka interpretacji KIS z datami ważności i sentinelem"}}
    return emit(bundle, "v3_p17_interpretation_library")


if __name__ == "__main__":
    raise SystemExit(main())
