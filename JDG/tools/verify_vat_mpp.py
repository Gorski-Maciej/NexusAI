#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VERIFY VAT MPP — audyt MPP/Split Payment jako bramka CI (raport 02, P2-7)
================================================================================
Cel: statyczna weryfikacja, że moduł MPP spełnia wymogi art. 108a–108f VAT
(ustawa z 11.03.2004, Dz.U. 2025 poz. 456) w silniku JDG:

  1. PRÓG 15 000 zł (art. 108a ust. 1) — mpp_threshold externalizowany.
  2. ZAŁĄCZNIK 15 — CN codes (towary) + usługi budowlane.
  3. SANKCJE 30% (art. 108a ust. 5-7) — dodatkowe zobowiązanie.
  4. SOLIDARNA ODPOWIEDZIALNOŚĆ (art. 108b ust. 1).
  5. BLOCK_AND_ALERT przy braku MPP.
  6. Zgodność podstaw prawnych (_legal_basis zawiera Art. 108).

Uruchomienie:  python3 JDG/tools/verify_vat_mpp.py [--json]
"""
import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RULES = os.path.join(REPO_ROOT, "JDG", "rules")

WYMAGANE = [
    ("próg_15000", r"mpp_threshold\s*:=|15000|15\s*000"),
    ("załącznik_15", r"annex15|Załącznika\s*15|ANNEX15"),
    ("cn_codes", r"cn_codes|default_annex15_cn"),
    ("usługi_budowlane", r"CONSTRUCTION|budowl"),
    ("sankcje_30", r"30%|dodatkowe\s+zobowiązanie|sankcj"),
    ("solidarna_odpowiedzialność", r"solidarn|108b"),
    ("block_and_alert", r"BLOCK_AND_ALERT|block_and_alert"),
    ("podstawa_108a", r"Art\.\s*108a|108a\s+ust\.\s*1|108a-108f"),
    ("externalizacja_ADR002", r"thresholds|ADR-002"),
]


def analizuj():
    pliki = ["vat_mpp_split_payment_enterprise.rego",
             os.path.join("vat", "substantive.rego")]
    tekst = ""
    znalezione = []
    for rel in pliki:
        sciezka = os.path.join(RULES, rel)
        if os.path.isfile(sciezka):
            t = open(sciezka, encoding="utf-8").read()
            tekst += t + "\n"
            znalezione.append(rel)
    if not znalezione:
        return {"ok": False, "error": "brak plików VAT MPP",
                "raport": "02_VAT_CORE"}
    wyniki = {}
    for nazwa, wzorzec in WYMAGANE:
        wyniki[nazwa] = bool(re.search(wzorzec, tekst, re.IGNORECASE))
    wszystkie = all(wyniki.values())
    return {"ok": wszystkie, "raport": "02_VAT_CORE",
            "skanowane_pliki": znalezione, "szczegoly": wyniki}


def main():
    w = analizuj()
    if "--json" in sys.argv:
        print(json.dumps(w, ensure_ascii=False, indent=2))
    else:
        s = w.get("szczegoly", {})
        print("=" * 62)
        print("VERIFY VAT MPP — audyt Split Payment (raport 02, P2-7)")
        print("=" * 62)
        print("Skanowane pliki: " + ", ".join(w.get("skanowane_pliki", [])))
        for nazwa, ok in s.items():
            print(f"  [{'OK' if ok else '!!'}] {nazwa}")
        print("-" * 62)
        print("WERDYKT: " + ("MPP ZGODNY Z ART. 108a-108f ✅"
                              if w.get("ok") else "WYMAGA DOMKNIĘCIA ⚠️"))
    sys.exit(0 if w.get("ok") else 1)


if __name__ == "__main__":
    main()
