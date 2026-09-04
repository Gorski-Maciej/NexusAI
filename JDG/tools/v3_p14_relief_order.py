#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I04 RELIEF ORDER OPTIMIZER.

Optymalna kolejność odliczeń pod invariant P04 „suma odliczeń ≤ dochód”.
Kolejność kanoniczna: PIT-0 (zwolnienia) → darowizna (6%) → ulgi od dochodu →
IP Box; nadwyżka ponad dochód = BLOCK_AND_ALERT (nigdy cichy nadmierny odliczenie).
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, pit_domain_file, emit

INNOVATION = "V3-P14-I04"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.relief_order_optimizer", hay)
    has_order = "_canonical_order" in hay and "_order_index_map" in hay and "applied_pln" in hay
    has_invariant = "within_invariant" in hay and "BLOCK_AND_ALERT" in hay and "total_claimed_pln" in hay
    missing = thresholds_missing(["donation_limit_pct"])
    domain_ok = pit_domain_file("cross_relief_optimizer_enterprise.rego")

    checks.append({"name": "order_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła relief_order_optimizer: {has_rule}"})
    checks.append({"name": "canonical_order", "status": "OK" if has_order else "FAIL",
                   "detail": "kolejność kanoniczna + indeks porządku + kwoty zastosowane"})
    checks.append({"name": "invariant_p04", "status": "OK" if has_invariant else "FAIL",
                   "detail": "invariant suma odliczeń ≤ dochód → BLOCK_AND_ALERT przy naruszeniu"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})
    checks.append({"name": "domain_optimizer", "status": "OK" if domain_ok else "FAIL",
                   "detail": "rules/pit/cross_relief_optimizer_enterprise.rego obecny — rozszerzenie"})

    if not has_invariant:
        findings.append({"id": "V3-P14-L04", "severity": "P0",
                         "evidence": "brak invariantu P04 (suma odliczeń ≤ dochód) w optimizerze",
                         "fix": "I04: wymusić invariant + BLOCK_AND_ALERT przy nadwyżce (dokument święty)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "order": has_order, "invariant": has_invariant,
                    "missing_params": missing, "domain_ok": domain_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty runtime), P28 (księgowość), P44 (deklaracje)",
                     "rule": "optymalna kolejność odliczeń pod invariant suma ≤ dochód (BLOCK przy nadwyżce)"}}
    return emit(bundle, "v3_p14_relief_order")


if __name__ == "__main__":
    raise SystemExit(main())
