#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I05 ACTIVE CORRECTION ADVISOR (art. 81 OrdPU).

Dowód wdrożenia: doradca korekty czynnej — przed wszczęciem postępowania pełny
benefit (art. 81 § 1); po wszczęciu tylko uzupełniająca (art. 81b) z
konsekwencjami; invariant: korekta zawsze audytowana (I11) — bez audytu BLOCK.
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, emit

INNOVATION = "V3-P17-I05"

RULE = "jdg.v3_p17_ordynacja_obrona.active_correction_advisor"


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_voluntary = '"proceeding_started"' in hay and "KOREKTA_CZYNNA_PRZED_WZSZCZECIEM" in hay
    has_supplementary = "art. 81b" in hay and "_ca_late" in hay
    has_audit_inv = "_ca_not_audited" in hay and "ORD_INV-003" in hay
    has_legal = "Art. 81 i 81b OrdPU" in hay

    checks.append({"name": "correction_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "czynna_przed_wszczeciem", "status": "OK" if has_voluntary else "FAIL",
                   "detail": "korekta czynna przed wszczęciem (art. 81 § 1)"})
    checks.append({"name": "uzupelniajaca_po", "status": "OK" if has_supplementary else "FAIL",
                   "detail": "korekta uzupełniająca po wszczęciu (art. 81b)"})
    checks.append({"name": "audit_invariant", "status": "OK" if has_audit_inv else "FAIL",
                   "detail": "invariant ORD_INV-003: korekta zawsze audytowana"})

    if not has_audit_inv:
        findings.append({"id": "V3-P17-L05", "severity": "P0",
                         "evidence": "korekta bez wymogu audytu (AP07: cichy AUTO_POST)",
                         "fix": "I05: BLOCK przy korekcie bez audytu (invariant P04)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "czynna": has_voluntary, "uzupelniajaca": has_supplementary,
                    "audit_invariant": has_audit_inv},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 81 i 81b OrdPU; invariant V3_P04 (korekta audytowana); "
                                "kontrakt V3_P36",
                     "rule": "doradca korekty czynnej/uzupełniającej z benefitami i audytem"}}
    return emit(bundle, "v3_p17_correction_advisor")


if __name__ == "__main__":
    raise SystemExit(main())
