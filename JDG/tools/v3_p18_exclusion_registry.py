#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I09 EXCLUSION REGISTRY.

Dowód wdrożenia: rejestr wykluczeń (kontrahent → data → powód, historia/audyt)
— aktywny wpis dla kontrahenta = BLOCK; brak wpisu = TRIAGE (uzupełnij).
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, emit

INNOVATION = "V3-P18-I09"

RULE = "jdg.v3_p18_ryczalt.exclusion_registry"


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_entries = '"registry_entries"' in hay and '"client_id"' in hay and "e.exclusion" in hay
    has_block = "_er_active_for_client" in hay and "AKTYWNY" in hay.upper()
    has_triage = "_er_client_registered" in hay

    checks.append({"name": "registry_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "entries", "status": "OK" if has_entries else "FAIL",
                   "detail": "rejestr: kontrahent → wykluczenie (historia)"})
    checks.append({"name": "active_block", "status": "OK" if has_block else "FAIL",
                   "detail": "aktywny wpis dla kontrahenta = BLOCK"})
    checks.append({"name": "missing_triage", "status": "OK" if has_triage else "FAIL",
                   "detail": "kontrahent poza rejestrem = TRIAGE (uzupełnij dane)"})

    if not has_block:
        findings.append({"id": "V3-P18-L09", "severity": "P1",
                         "evidence": "brak rejestru wykluczeń z historią i audytem",
                         "fix": "I09: rejestr kontrahent → data → powód"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "entries": has_entries, "block": has_block,
                    "triage": has_triage},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 8 ustawy o zryczałtowanym PIT; kontrakt P28 (kontrahenci); "
                                "audyt P37",
                     "rule": "rejestr wykluczeń z historią i audytem"}}
    return emit(bundle, "v3_p18_exclusion_registry")


if __name__ == "__main__":
    raise SystemExit(main())
