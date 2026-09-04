#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I09 DEFENSE PACKET GENERATOR (paczka obronna).

Dowód wdrożenia: generator paczki obronnej — odpowiedź + dokumenty + indeks
dowodów + review doradcy. Wysyłka niekompletnej paczki = BLOCK; kompletna =
SUGGEST; braki = TRIAGE z checklistą.
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, emit

INNOVATION = "V3-P17-I09"

RULE = "jdg.v3_p17_ordynacja_obrona.defense_packet_generator"


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_checklist = '"response_drafted"' in hay and '"documents_collected"' in hay and '"evidence_indexed"' in hay and '"advisor_reviewed"' in hay
    has_block = "_dp_incomplete_filing" in hay and "BLOCK" in hay
    has_types = '"APELACJA"' in hay and '"SKARGA_WSA"' in hay and '"ZALECENIA_POKONTROLNE"' in hay

    checks.append({"name": "defense_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "checklist", "status": "OK" if has_checklist else "FAIL",
                   "detail": "checklista: odpowiedź, dokumenty, dowody, review"})
    checks.append({"name": "incomplete_block", "status": "OK" if has_block else "FAIL",
                   "detail": "wysyłka niekompletnej paczki = BLOCK"})
    checks.append({"name": "case_types", "status": "OK" if has_types else "FAIL",
                   "detail": "typy spraw: apelacja/skarga/odpowiedź/zalecenia"})

    if not has_block:
        findings.append({"id": "V3-P17-L09", "severity": "P1",
                         "evidence": "paczka obronna bez blokady niekompletnej wysyłki",
                         "fix": "I09: BLOCK przy braku elementów checklisty"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "checklist": has_checklist, "block": has_block,
                    "types": has_types},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 187-234 OrdPU; art. 53 PPSA; kontrakt V3_P41 (UI spraw)",
                     "rule": "generator paczki obronnej z checklistą braków"}}
    return emit(bundle, "v3_p17_defense_packet")


if __name__ == "__main__":
    raise SystemExit(main())
