#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PEWNOŚĆ METRICS — narzędzie wskaźników mierzalnej pewności JDG (raport 00, P0-1)
================================================================================
Cel: automatyczne liczenie wskaźników pewności prawnej silnika OPA JDG i
publikacja do bundles/metrics_pewnosci.json — fundament bramek CI
(LCI ≥99%, TCL 100%, RV ≥90%, UVR=0, duplikaty=0, stuby=0).

Wskaźniki (definicje z RAPORT_00_FUNDAMENT_ARCHITEKTURA.txt):
  LCI  Legal Coverage Index   = punkty prawne pokryte / wszystkie punkty ×100
  TCL  Total Canonical Cover. = reguły z _legal_basis kanoniczną / reguły ×100
  RV   Reference Validity     = reguły OK / reguły z podstawą ×100
  UVR  Unverified             = reguły MISSING + UNKNOWN_ACT (cel: 0)
  DUP  Duplikaty rule_id      = powtórzone rule_id w rules/ (cel: 0)
  STUB Stuby                  = reguły matched:false / placeholdery (cel: 0)

Uruchomienie:  python3 JDG/tools/pewnosc_metrics.py
Wyjście:       bundles/metrics_pewnosci.json + raport tekstowy na stdout.
"""
import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
JDG = os.path.join(REPO_ROOT, "JDG")
BUNDLES = os.path.join(JDG, "bundles")
RULES = os.path.join(JDG, "rules")

WYJSCIE = os.path.join(BUNDLES, "metrics_pewnosci.json")


def laduj_json(nazwa):
    sciezka = os.path.join(BUNDLES, nazwa)
    if not os.path.isfile(sciezka):
        print(f"[SKIP] brak pliku: {nazwa}")
        return None
    with open(sciezka, encoding="utf-8") as f:
        return json.load(f)


def licz_lci(coverage, legal_cover):
    """LCI na bazie legal_coverage_gaps.json + LEGAL_COVERAGE.md (1935 pkt)."""
    kompletne = 0
    luki = 0
    if isinstance(coverage, dict):
        by_status = coverage.get("by_status") or {}
        kompletne = int(by_status.get("COMPLETE", 0) or 0)
        luki = int(by_status.get("GAP", 0) or 0)
    # punkty deklarowane w LEGAL_COVERAGE.md (13 aktów = 1935 punktów)
    punkty_calosc = 1935
    pokryte = kompletne  # mapowanie: 15 COMPLETE w gaps.json to próbka 27 art.
    # ekstrapolacja: COMPLETE/(COMPLETE+GAP) z próbki na całość 1935 pkt
    proba = kompletne + luki
    if proba > 0:
        pokryte = round(punkty_calosc * kompletne / proba)
    lci = round(pokryte / punkty_calosc * 100, 2) if punkty_calosc else 0.0
    return {"lci": lci, "punkty_prawne_calosc": punkty_calosc,
            "punkty_pokryte_szac": pokryte, "proba_art": proba}


def licz_rv_tcl(audit):
    """RV i TCL na bazie legal_basis_audit.json."""
    stats = audit.get("stats") or {}
    ok = int(stats.get("OK", 0) or 0)
    non = int(stats.get("NON_CANONICAL", 0) or 0)
    miss = int(stats.get("MISSING", 0) or 0)
    unk = int(stats.get("UNKNOWN_ACT", 0) or 0)
    total = int(audit.get("rules_total", 0) or (ok + non + miss + unk))
    z_podstawa = ok + non
    rv = round(ok / z_podstawa * 100, 2) if z_podstawa else 0.0
    tcl = round(ok / total * 100, 2) if total else 0.0
    return {"rv": rv, "tcl": tcl, "ok": ok, "non_canonical": non,
            "missing": miss, "unknown_act": unk, "rules_total": total}


def licz_duplikaty():
    """Duplikaty rule_id w plikach rules/ (cel: 0)."""
    wzorzec = re.compile(r"\"rule_id\"\s*:\s*\"([^\"]+)\"")
    seen = {}
    for katalog, pod, pliki in os.walk(RULES):
        if ".benchmarks" in katalog or ".hypothesis" in katalog:
            continue
        for nazwa in pliki:
            if not nazwa.endswith(".rego"):
                continue
            pelna = os.path.join(katalog, nazwa)
            try:
                tekst = open(pelna, encoding="utf-8").read()
            except Exception:
                continue
            for m in wzorzec.finditer(tekst):
                rid = m.group(1)
                if rid == "no_match":
                    continue
                seen.setdefault(rid, []).append(
                    os.path.relpath(pelna, JDG))
    duplikaty = {rid: pliki for rid, pliki in seen.items() if len(pliki) > 1}
    return {"duplikaty": len(duplikaty), "unikalne_rule_id": len(seen),
            "szczegoly": duplikaty}


def licz_stuby():
    """Reguły z matched:false / placeholder w rules/ (cel: 0)."""
    wzorzec = re.compile(r"\"matched\"\s*:\s*(true|false)")
    stuby = 0
    pliki_ze_stubami = []
    for katalog, pod, pliki in os.walk(RULES):
        if ".benchmarks" in katalog or ".hypothesis" in katalog:
            continue
        for nazwa in pliki:
            if not nazwa.endswith(".rego"):
                continue
            pelna = os.path.join(katalog, nazwa)
            try:
                tekst = open(pelna, encoding="utf-8").read()
            except Exception:
                continue
            liczba_false = sum(
                1 for v in wzorzec.findall(tekst) if v == "false")
            if liczba_false:
                stuby += liczba_false
                pliki_ze_stubami.append(
                    (os.path.relpath(pelna, JDG), liczba_false))
    return {"stuby": stuby, "pliki_ze_stubami": pliki_ze_stubami[:20]}


def bramki(met):
    """Weryfikacja progów P0-1: LCI≥99%, TCL 100%, RV≥90%, UVR=0, DUP=0, STUB=0."""
    wyniki = []
    def spr(nazwa, warunek):
        wyniki.append({"wskaźnik": nazwa, "ok": bool(warunek),
                       "prog": "spełniony" if warunek else "NIESPEŁNIONY"})
    spr("LCI ≥ 99%", met["lci"] >= 99)
    spr("TCL = 100%", met["tcl"] >= 100)
    spr("RV ≥ 90%", met["rv"] >= 90)
    spr("UVR = 0", met["uvr"] == 0)
    spr("duplikaty = 0", met["duplikaty"] == 0)
    spr("stuby = 0", met["stuby"] == 0)
    return wyniki


def main():
    coverage = laduj_json("legal_coverage_gaps.json")
    audit = laduj_json("legal_basis_audit.json")
    lci = licz_lci(coverage, None)
    rvtcl = licz_rv_tcl(audit) if audit else {}
    dup = licz_duplikaty()
    stub = licz_stuby()
    uvr = int(rvtcl.get("missing", 0)) + int(rvtcl.get("unknown_act", 0))
    met = {
        "generated_at": None,
        "lci": lci["lci"],
        "tcl": rvtcl.get("tcl", 0.0),
        "rv": rvtcl.get("rv", 0.0),
        "uvr": uvr,
        "duplikaty": dup["duplikaty"],
        "stuby": stub["stuby"],
        "szczegoly": {
            "lci": lci,
            "legal_basis": rvtcl,
            "duplikaty_szczegoly": list(dup["szczegoly"].items())[:10],
            "stuby_szczegoly": stub["pliki_ze_stubami"],
        },
    }
    met["bramki_ci"] = bramki(met)
    with open(WYJSCIE, "w", encoding="utf-8") as f:
        json.dump(met, f, ensure_ascii=False, indent=2)

    print("=" * 62)
    print("PEWNOŚĆ METRICS JDG — wskaźniki mierzalnej pewności (raport 00, P0-1)")
    print("=" * 62)
    print(f"LCI  (Legal Coverage Index)      : {met['lci']:6.2f} %   (cel ≥ 99)")
    print(f"TCL  (Total Canonical Coverage)  : {met['tcl']:6.2f} %   (cel = 100)")
    print(f"RV   (Reference Validity)        : {met['rv']:6.2f} %   (cel ≥ 90)")
    print(f"UVR  (Unverified)                : {met['uvr']:6d}     (cel = 0)")
    print(f"DUP  (Duplikaty rule_id)         : {met['duplikaty']:6d}     (cel = 0)")
    print(f"STUB (Stuby matched:false)       : {met['stuby']:6d}     (cel = 0)")
    print("-" * 62)
    print("BRAMKI CI:")
    for b in met["bramki_ci"]:
        print(f"  [{('OK' if b['ok'] else '!!')}] {b['wskaźnik']}")
    print(f"\nZapisano: {WYJSCIE}")
    ok_all = all(b["ok"] for b in met["bramki_ci"])
    sys.exit(0 if ok_all else 2)


if __name__ == "__main__":
    main()
