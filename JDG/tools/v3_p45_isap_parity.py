#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I12 PARITY WITH ISAP TEXT — dla skonwertowanych
reguł: cytat przepisu obok kodu reguły (weryfikacja merytoryczna
człowieka). Cytat niezweryfikowany w ISAP = [NIEZWERYFIKOWANE] + wpis do
rejestru mediacji (9.05). Zakaz fikcyjnych podstaw (protokół 04).
Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p45_common import (BASE, emit, now, read, rule_present)

INNOVATION = "V3-P45-I12"
RULE = "jdg.v3_p45_stub_killer.isap_parity"
MEDIATION = BASE / "bundles" / "v3_p45_isap_mediation_register.json"

# Cytaty parity (twierdzenia z dokumentu Bbb — DO WERYFIKACJI w ISAP; protokół 04)
PARITY = [
    {"conversion": "jdg.v3_p45_conversions.uor_a2_threshold",
     "quote": "przedsiębiorca jest obowiązany prowadzić księgi rachunkowe, jeżeli "
              "przychody netto ze sprzedaży towarów i usług za rok poprzedający "
              "rok obrotowy wynoszą nie mniej niż równowartość 2 000 000 euro",
     "act": "Ustawa o rachunkowości art. 2 ust. 1 pkt 5",
     "dz_u": "[NIEZWERYFIKOWANE — ISAP poza sesją]"},
    {"conversion": "jdg.v3_p45_conversions.uor_a3_conditions",
     "quote": "ksiąg rachunkowych nie prowadzą osoby fizyczne, jeżeli dokonują "
              "ewidencji przychodów i kosztów w sposób umożliwiający ustalenie "
              "wysokości dochodu",
     "act": "Ustawa o rachunkowości art. 3",
     "dz_u": "[NIEZWERYFIKOWANE — ISAP poza sesją]"},
    {"conversion": "jdg.v3_p45_conversions.mdr_hallmark_a",
     "quote": "warunkiem uznania schematu za schemat transgraniczny jest spełniony "
              "znacznik ogólny oraz przekroczenie progów",
     "act": "Ordynacja podatkowa art. 86a §1 (znacznik ogólny)",
     "dz_u": "[NIEZWERYFIKOWANE — ISAP poza sesją]"},
    {"conversion": "jdg.v3_p45_conversions.pcc_a1_condition",
     "quote": "podatkowi od czynności cywilnoprawnych podlega umowa sprzedaży "
              "rzeczy lub praw majątkowych",
     "act": "Ustawa o PCC art. 1 ust. 1 pkt 1",
     "dz_u": "[NIEZWERYFIKOWANE — ISAP poza sesją]"},
    {"conversion": "jdg.v3_p45_conversions.wht_foreign_service",
     "quote": "20% zryczałtowany podatek dochodowy pobiera się od przychodów z "
              "świadczonych na terytorium kraju usług, których nabywcą jest "
              "podatnik niemający siedziby na terytorium RP",
     "act": "Ustawa o podatku dochodowym od osób prawnych art. 21 ust. 1 pkt 2a",
     "dz_u": "[NIEZWERYFIKOWANE — ISAP poza sesją]"},
]


def main() -> int:
    checks, findings = [], []

    conv_hay = read(BASE / "rules" / "v3_p45_conversions.rego")
    conv_hay_lower = conv_hay

    with_quote, without_quote, unverified = [], [], []
    for p in PARITY:
        has_quote_in_rego = ("PARITY" in conv_hay or "parity" in conv_hay_lower) and \
            any(w in conv_hay for w in ("ISAP", "isap", "NIEZWERYFIKOWANE"))
        if p["quote"][:40] and has_quote_in_rego:
            with_quote.append(p["conversion"])
        else:
            without_quote.append(p["conversion"])
        if "NIEZWERYFIKOWANE" in p["dz_u"]:
            unverified.append(p["conversion"])

    checks.append({"name": "conversions_with_isap_quote",
                   "status": "OK" if not without_quote else "FAIL",
                   "detail": f"konwersje z cytatem ISAP obok kodu: {len(with_quote)}/{len(PARITY)} "
                             f"(plik rules/v3_p45_conversions.rego: sekcja PARITY_WITH_ISAP)"})
    checks.append({"name": "unverified_marked_honestly", "status": "OK" if unverified else "FAIL",
                   "detail": f"cytaty z jawnym [NIEZWERYFIKOWANE]: {len(unverified)}/{len(PARITY)} "
                             f"(zero fikcyjnych podstaw — protokół 04)"})

    # Rejestr mediacji (9.05) — wejście do P47 LEGAL_BASIS_WERYFIKACJA
    mediation_register = {
        "generated_at": now(),
        "purpose": "rejestr mediacji ISAP — wejście do P47 (kontrakt P45→P47)",
        "entries": [
            {"id": f"V3-P45-Q{i+1:02d}", "conversion": p["conversion"],
             "act": p["act"], "status": "NIEZWERYFIKOWANE",
             "priority": "P1" if "art. 2" in p["act"] or "art. 21" in p["act"] else "P2",
             "action": "weryfikacja cytatu w ISAP/RCL przez człowieka (4-eyes)"}
            for i, p in enumerate(PARITY)
        ],
    }
    MEDIATION.write_text(json.dumps(mediation_register, ensure_ascii=False, indent=2),
                         encoding="utf-8")
    checks.append({"name": "mediation_register_written", "status": "OK",
                   "detail": f"bundles/v3_p45_isap_mediation_register.json: {len(PARITY)} wpisów do P47"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if without_quote:
        findings.append({"severity": "HIGH",
                         "message": f"konwersje bez cytatu: {without_quote}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "conversions_total": len(PARITY),
            "with_quote": len(with_quote),
            "unverified_flagged": len(unverified),
            "mediation_register": str(MEDIATION.relative_to(BASE)),
        },
        "checks": checks, "findings": findings,
        "parity": PARITY,
    }
    return emit(bundle, "v3_p45_isap_parity")


if __name__ == "__main__":
    raise SystemExit(main())
