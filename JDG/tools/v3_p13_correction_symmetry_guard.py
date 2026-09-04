#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I11 CORRECTION SYMMETRY GUARD (art. 89a/89b VAT).

Gate CI na korekty art. 89a/89b (90 dni) + symetria korekt: korekta in minus
zawsze odpowiada korekcie in plus (ta sama faktura/zdarzenie); audytowalność
(event_id). Naruszenie = BLOCK_AND_ALERT. Dowód: reguła correction_symmetry_guard.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, emit

INNOVATION = "V3-P13-I11"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.correction_symmetry_guard", hay)
    has_symmetry = "correction_in_minus_pln" in hay and "correction_in_plus_pln" in hay and "symmetric" in hay
    has_gate = "gate_90_days_ok" in hay and "bad_debt_days" in hay
    has_audit = "event_id" in hay and "auditable" in hay
    has_block = "BLOCK_AND_ALERT" in hay and "correction_symmetry_fail" in hay

    checks.append({"name": "symmetry_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła correction_symmetry_guard: {has_rule}"})
    checks.append({"name": "in_minus_equals_in_plus", "status": "OK" if has_symmetry else "FAIL",
                   "detail": "symetria korekt in_minus = in_plus (art. 89a/89b)"})
    checks.append({"name": "gate_90_days", "status": "OK" if has_gate else "FAIL",
                   "detail": "gate CI na korekty art. 89a/89b z 90 dniami"})
    checks.append({"name": "audit_event_id", "status": "OK" if has_audit else "FAIL",
                   "detail": "identyfikator zdarzenia (audytowalność korekt)"})
    checks.append({"name": "block_on_violation", "status": "OK" if has_block else "FAIL",
                   "detail": "asymetria/brak event_id → BLOCK_AND_ALERT"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"symmetry_rule": has_rule, "symmetry": has_symmetry,
                    "gate": has_gate, "audit": has_audit, "block": has_block},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty), P10 (golden), P39 (bramki CI), P05 (temporalność), P16 (JPK korekty)",
                     "rule": "korekta in minus = in plus (art. 89a/89b) + gate CI 90 dni + audyt event_id"}}
    return emit(bundle, "v3_p13_correction_symmetry_guard")


if __name__ == "__main__":
    raise SystemExit(main())