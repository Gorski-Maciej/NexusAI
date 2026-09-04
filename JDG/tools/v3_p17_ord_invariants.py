#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I11 ORD INVARIANTS PACK (kontrakt V3_P04).

Dowód wdrożenia: invarianty runtime warstwy obronnej — ORD_INV-001 odsetki ≥ 0,
ORD_INV-002 przedawnienie nie wcześniej niż koniec 5. roku, ORD_INV-003 korekta
zawsze audytowana. Naruszenie = BLOCK_AND_ALERT (nigdy cichy AUTO_POST).
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I11"

RULE = "jdg.v3_p17_ordynacja_obrona.ord_invariants_pack"
TH_KEYS = ["v3_p17_invariants_active", "v3_p17_statute_years"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_i1 = "ORD_INV-001" in hay and '"computed_interest_pln"' in hay
    has_i2 = "ORD_INV-002" in hay and "limitation_end_year" in hay
    has_i3 = "ORD_INV-003" in hay and "correction_audited" in hay
    has_list = '"violations"' in hay and "object.keys(_iv_flags)" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "invariants_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "ORD_INV_001", "status": "OK" if has_i1 else "FAIL",
                   "detail": "odsetki ≥ 0"})
    checks.append({"name": "ORD_INV_002", "status": "OK" if has_i2 else "FAIL",
                   "detail": "przedawnienie ≥ koniec 5. roku"})
    checks.append({"name": "ORD_INV_003", "status": "OK" if has_i3 else "FAIL",
                   "detail": "korekta zawsze audytowana"})
    checks.append({"name": "violation_list", "status": "OK" if has_list else "FAIL",
                   "detail": "lista naruszeń w certyfikacie"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: aktywacja/lata z data.thresholds.ord"})

    if not (has_i1 and has_i2 and has_i3):
        findings.append({"id": "V3-P17-L11", "severity": "P0",
                         "evidence": "brak invariantów runtime warstwy obronnej",
                         "fix": "I11: ORD_INV-001..003 + BLOCK przy naruszeniu (P04)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "i1": has_i1, "i2": has_i2, "i3": has_i3,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "kontrakt invariantów V3_P04; art. 56/70/81 OrdPU",
                     "rule": "pakiet invariantów ORD (odsetki/przedawnienie/korekta)"}}
    return emit(bundle, "v3_p17_ord_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
