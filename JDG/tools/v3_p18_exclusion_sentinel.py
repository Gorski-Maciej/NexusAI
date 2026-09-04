#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I02 EXCLUSION SENTINEL (art. 8).

Dowód wdrożenia: monitoring wykluczeń z ryczałtu — usługi dla byłego pracodawcy
(ten sam zakres) = wykluczenie; naruszenie (ryczałt mimo wykluczenia) =
BLOCKER; brak danych kontrahenta = TRIAGE (fail-closed).
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I02"

RULE = "jdg.v3_p18_ryczalt.exclusion_sentinel"
TH_KEYS = ["v3_p18_exclusion_former_employer"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_flags = '"former_employer"' in hay and '"services_same_scope"' in hay and '"client_data_complete"' in hay
    has_block = "_es_violation" in hay and "BLOCKER" in hay.upper()
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "sentinel_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "flags", "status": "OK" if has_flags else "FAIL",
                   "detail": "flagi: b. pracodawca + zakres + kompletność danych"})
    checks.append({"name": "blocker", "status": "OK" if has_block else "FAIL",
                   "detail": "naruszenie wykluczenia = BLOCKER (ryczałt mimo wykluczenia)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: wykluczenie b. pracodawcy z data.thresholds.lump_sum"})

    if not has_block:
        findings.append({"id": "V3-P18-L02", "severity": "P0",
                         "evidence": "brak BLOCKER-a przy naruszeniu wykluczenia art. 8",
                         "fix": "I02: monitoring wykluczeń + alarm + konsekwencje"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "flags": has_flags, "blocker": has_block,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 8 ustawy o zryczałtowanym PIT; kontrakt P28 (kontrahenci)",
                     "rule": "sentinel wykluczeń z BLOCKER-em i kalkulacją konsekwencji"}}
    return emit(bundle, "v3_p18_exclusion_sentinel")


if __name__ == "__main__":
    raise SystemExit(main())
