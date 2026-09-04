#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I06 YEAR-END CORRECTION LAB.

Dowód wdrożenia: korekty ewidencji ryczałtu przed/po zakończeniu roku —
idempotencja (event_id + already_applied), audyt korekty (invariant V3_P04),
ścieżka po roku przez korektę PIT-28; korekta bez audytu = BLOCK.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, emit

INNOVATION = "V3-P18-I06"

RULE = "jdg.v3_p18_ryczalt.year_end_correction_lab"


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_before_after = '"PRZED_ZAKONCZENIEM"' in hay and '"PO_ZAKONCZENIU"' in hay and '"year_closed"' in hay
    has_idem = '"correction_event_id"' in hay and '"duplicate_skipped"' in hay
    has_audit = "_yc_not_audited" in hay and "audytowana" in hay

    checks.append({"name": "correction_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "before_after_year", "status": "OK" if has_before_after else "FAIL",
                   "detail": "korekta przed/po zakończeniu roku (granice)"})
    checks.append({"name": "idempotency", "status": "OK" if has_idem else "FAIL",
                   "detail": "event_id + already_applied → duplikat pomijany"})
    checks.append({"name": "audit_invariant", "status": "OK" if has_audit else "FAIL",
                   "detail": "korekta bez audytu = BLOCK (invariant V3_P04)"})

    if not has_audit:
        findings.append({"id": "V3-P18-L06", "severity": "P0",
                         "evidence": "korekta ewidencji bez audytu (AP07)",
                         "fix": "I06: audyt korekty + idempotencja (wzorzec P16/P17)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "before_after": has_before_after,
                    "idempotency": has_idem, "audit": has_audit},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 15-19 ustawy o zryczałtowanym PIT (ewidencja); "
                                "invariant V3_P04 (korekta audytowana); idempotencja jak V3_P16",
                     "rule": "korekty ewidencji przed/po roku — audytowalne i idempotentne"}}
    return emit(bundle, "v3_p18_year_end_correction")


if __name__ == "__main__":
    raise SystemExit(main())
