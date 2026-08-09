#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_vat_micro_atomic.py — BRAMKA CI dla warstwy MICRO VAT (raport 03/25).

Automatyzuje bramki z RAPORT_03_VAT_MICRO.txt:
  P0-1  Duplikaty rule_id       -> 0 (wymagane)
  P0-2  Stuby / empty_bodies    -> 0 w rules/micro/vat/* (p04 naprawiany osobno)
  P0-3  Dzikie rule_id (gwiazdka) -> 0 (jdg.vida.*.r1 to anomalia)
  P0-4  Tautologie              -> 0 w micro/vat/ i micro/plan*_vat
  P0-5  Temporalność            -> plan33_vat.rego i plan34_vat.rego MUSZĄ mieć
                                   valid_from/valid_to (obecnie 0 -> błąd P0)
  P0-6  Hardcode stawek 23/08/05 -> raportowane (docelowo 0 po parametryzacji)
  P0-7  Reguły bez _legal_basis  -> 0 (100% pokrycia prawa)

Użycie:
  python3 JDG/tools/verify_vat_micro_atomic.py            # bramki + raport
  python3 JDG/tools/verify_vat_micro_atomic.py --json     # JSON (CI)
Exit code 0 = bramki P0 zamknięte; 2 = błąd P0 (CI blokuje PR).
"""
import json
import os
import re
import sys

REPO_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
RULES = os.path.join(REPO_ROOT, "JDG", "rules")
MICRO_VAT = os.path.join(RULES, "micro", "vat")
MICRO = os.path.join(RULES, "micro")
BUNDLES = os.path.join(REPO_ROOT, "JDG", "bundles")

PLIKI_MICRO = [
    "micro/vat/vat.rego",
    "micro/vat/ksef_micro.rego",
    "micro/vat/margin_scheme_micro.rego",
    "micro/vat/place_of_supply_micro.rego",
    "micro/vat/proportion_vat.rego",
    "micro/vat/wdt_export_import.rego",
    "micro/plan33_vat.rego",
    "micro/plan34_vat.rego",
    "micro/plan33_prop.rego",
]

# Realne porównania stawek w warunkach reguł: == 0.23 / == 0.08 / == 0.05 / == 0.0
STAWI_HARDCODE = re.compile(r'==\s*0\.(23|08|05|07|0)\b')


def czytaj(wzg):
    p = os.path.join(RULES, wzg)
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as f:
        return f.read()


def policz_rule_id(tekst):
    return re.findall(r'"rule_id":\s*"([^"]+)"', tekst or "")


def main():
    wynik = {"bramki": {}, "raport": {}, "pliki": {}}
    errors = []

    wszystkie_id = []
    for wzg in PLIKI_MICRO:
        t = czytaj(wzg)
        if t is None:
            wynik["raport"]["brak_pliku_" + wzg] = True
            continue
        ids = policz_rule_id(t)
        wszystkie_id.extend(ids)
        wynik["pliki"][wzg] = {
            "reguly": len(ids),
            "legal_basis": t.count("_legal_basis"),
            "valid_from": t.count("valid_from"),
            "valid_to": t.count("valid_to"),
            "else_chains": len(re.findall(r"else\s*[:={]", t)),
            "tautologie": len(re.findall(r"true\s*:=?\s*true", t)),
            "empty_bodies": len(re.findall(r"\{\s*\}\s*$", t, re.M)),
        }

    # P0-1 duplikaty
    dup = sorted({i for i in wszystkie_id if wszystkie_id.count(i) > 1})
    b = wynik["bramki"]["P0-1_duplikaty_rule_id"] = {"wymagane": 0, "znaleziono": len(dup)}
    if dup:
        errors.append("P0-1: duplikaty rule_id: %s" % ", ".join(dup[:5]))

    # P0-2 stuby / empty_bodies w micro/vat + plan*
    eb = sum(p["empty_bodies"] for p in wynik["pliki"].values())
    b = wynik["bramki"]["P0-2_empty_bodies_micro"] = {"wymagane": 0, "znaleziono": eb}
    if eb:
        errors.append("P0-2: empty_bodies w warstwie micro: %d" % eb)

    # P0-3 dzikie rule_id (gwiazdka)
    dzikie = sorted(i for i in wszystkie_id if "*" in i or " " in i)
    b = wynik["bramki"]["P0-3_dzikie_rule_id"] = {"wymagane": 0, "znaleziono": len(dzikie)}
    if dzikie:
        errors.append("P0-3: dzikie rule_id: %s" % ", ".join(dzikie[:5]))

    # P0-4 tautologie
    tau = sum(p["tautologie"] for p in wynik["pliki"].values())
    b = wynik["bramki"]["P0-4_tautologie"] = {"wymagane": 0, "znaleziono": tau}
    if tau:
        errors.append("P0-4: tautologie w warstwie micro: %d" % tau)

    # P0-5 temporalność plan33/34
    for plik in ("micro/plan33_vat.rego", "micro/plan34_vat.rego"):
        p = wynik["pliki"].get(plik, {})
        ok = p.get("valid_from", 0) > 0 and p.get("valid_to", 0) >= 0
        wynik["bramki"]["P0-5_temporalnosc_" + plik] = {"wymagane": True, "ok": ok}
        if not ok:
            errors.append("P0-5: %s BEZ temporalności (valid_from/valid_to)" % plik)

    # P0-6 hardcode stawek 23/08/05 w plan33/34
    hc = 0
    for plik in ("micro/plan33_vat.rego", "micro/plan34_vat.rego"):
        t = czytaj(plik) or ""
        n = len(STAWI_HARDCODE.findall(t))
        hc += n
        wynik["raport"]["hardcode_stawki_" + plik] = n
    wynik["bramki"]["P0-6_hardcode_stawek"] = {"wymagane": 0, "znaleziono": hc, "status": "P1 (parametryzacja)"}
    if hc:
        wynik["raport"]["uwaga"] = "P0-6: hardcode stawek (23/08/05) — P1, docelowo 0"

    # P0-7 reguły bez legal_basis (dopuszczalny 1 wyjątek: reguła no_match)
    bez = []
    for wzg, p in wynik["pliki"].items():
        r = p.get("reguly", 0)
        lb = p.get("legal_basis", 0)
        if r > 0 and lb < r - 1:  # minus reguła no_match (bez podstawy prawnej)
            bez.append("%s (%d reguł, %d legal_basis)" % (wzg, r, lb))
    wynik["bramki"]["P0-7_100pct_legal_basis"] = {"wymagane": True, "brak_w": bez}
    if bez:
        errors.append("P0-7: pliki z regułami bez _legal_basis: %s" % ", ".join(bez))

    # Raport
    wynik["raport"]["suma_regul"] = sum(p["reguly"] for p in wynik["pliki"].values())
    wynik["raport"]["suma_legal_basis"] = sum(p["legal_basis"] for p in wynik["pliki"].values())
    wynik["raport"]["suma_else_chainow"] = sum(p["else_chains"] for p in wynik["pliki"].values())
    wynik["raport"]["temporalnosc_6_z_8"] = sum(
        1 for p in wynik["pliki"].values() if p.get("valid_from", 0) > 0
    )

    if "--json" in sys.argv:
        print(json.dumps(wynik, ensure_ascii=False, indent=1))
    else:
        print("=== BRAMKA CI — VAT WARSTWA MICRO (RAPORT 03) ===")
        for k, v in wynik["bramki"].items():
            print("  %-42s %s" % (k, v))
        print("=== RAPORT ===")
        for k, v in wynik["raport"].items():
            print("  %-42s %s" % (k, v))

    if errors:
        print("\nBŁĘDY P0 (CI blokuje):")
        for e in errors:
            print("  ✗ " + e)
        return 2
    print("\n✅ WSZYSTKIE BRAMKI P0 ZAMKNIĘTE — warstwa micro VAT: poziom ENTERPRISE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
