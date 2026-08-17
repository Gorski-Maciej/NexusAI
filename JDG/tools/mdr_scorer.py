#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — MDR SCORER + GENERATOR (GLM52 P12)
# MDR/DAC6 (art. 86a-86o OrdPU): hallmarks A-E, główna korzyść podatkowa (MBT),
# termin 30 dni (MDR-1), sankcja do 720 stawek (art. 80f-80h KKS), auto-generator
# MDR-1 (XML) — „obrona optymalizacji" (spójność GAAR PROMPT 07/11).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
from datetime import date, timedelta
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parents[1]

# Hallmarks MDR (dyrektywa 2011/16/UE, art. 86ab-86af OrdPU)
HALLMARKS = {
    "A": "Korzystający z poufności/anonimowości promotora",
    "B": "Płatność uzależniona od osiągnięcia korzyści podatkowej",
    "C1": "Nabycie spółki stratnej — przeniesienie zysków",
    "C2": "Konwersja dochodu na kapitał/zwolniony",
    "C3": "Transakcje okrężne / kompensaty",
    "C4": "Płatności transgraniczne na rzecz podmiotu w raju podatkowym",
    "D1": "Obniżenie podatku u źródła / podwójne odliczenie",
    "D2": "Nabycie składników z różnicą między wartością rynkową a podatkową",
    "E": "Korzyść >250k EUR i jedna z cech A-D (MBT)",
}


def _load_thresholds() -> dict:
    fallback = {
        "mdr_deadline_days": 30,
        "mdr_mbt_threshold_eur": 250000,
        "mdr_sanction_daily_rates": 720,
    }
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return fallback
    text = path.read_text(encoding="utf-8")
    m = re.search(r"crossborder := \{([^}]*)\}", text, re.S)
    if not m:
        return fallback
    body = m.group(1)
    for key in list(fallback.keys()):
        fm = re.search(rf'"{key}"\s*:\s*([\d.]+)', body)
        if fm:
            fallback[key] = float(fm.group(1))
    return fallback


def score(
    hallmarks: list[str],
    main_benefit_test: bool = False,
    tax_benefit_eur: float = 0.0,
    promoter_involved: bool = False,
) -> dict[str, Any]:
    """Scorer MDR: hallmark + MBT → raportowalne; zwraca prawdopodobieństwo."""
    ths = _load_thresholds()
    hallmark_hit = any(h in hallmarks for h in HALLMARKS)
    mbt_hit = main_benefit_test or (hallmark_hit and tax_benefit_eur > ths["mdr_mbt_threshold_eur"])
    reportable = hallmark_hit and mbt_hit

    # prawdopodobieństwo raportowania (heurystyka)
    prob = 0.0
    if hallmark_hit and mbt_hit:
        prob = 0.95
    elif hallmark_hit:
        prob = 0.45
    elif mbt_hit:
        prob = 0.30

    return {
        "reportable": reportable,
        "probability_pct": round(prob * 100),
        "hallmarks": hallmarks,
        "hallmark_hit": hallmark_hit,
        "main_benefit_test": mbt_hit,
        "tax_benefit_eur": tax_benefit_eur,
        "mbt_threshold_eur": ths["mdr_mbt_threshold_eur"],
        "deadline_days": int(ths["mdr_deadline_days"]),
        "sanction_daily_rates": int(ths["mdr_sanction_daily_rates"]),
        "legal": "Art. 86a-86o ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.) w zw. z art. 80f-80h ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    }


def deadline_calc(arrangement_date: str) -> dict[str, Any]:
    """Termin MDR-1: 30 dni od dnia uzgodnienia."""
    ths = _load_thresholds()
    arr = date.fromisoformat(arrangement_date)
    dl = arr + timedelta(days=int(ths["mdr_deadline_days"]))
    return {
        "arrangement_date": arrangement_date,
        "mdr1_deadline": dl.isoformat(),
        "deadline_days": int(ths["mdr_deadline_days"]),
        "legal": "Art. 86a § 1 pkt 2 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    }


def generate_mdr1_xml(
    entrepreneur_name: str,
    nip: str,
    arrangement_description: str,
    hallmarks: list[str],
) -> dict[str, Any]:
    """Auto-generator MDR-1 (struktura XML MDR-1)."""
    import xml.etree.ElementTree as ET

    root = ET.Element("MDR-1", {"version": "1.0"})
    ET.SubElement(root, "Podmiot").text = entrepreneur_name
    ET.SubElement(root, "NIP").text = nip
    ET.SubElement(root, "OpisUzgodnienia").text = arrangement_description
    hall = ET.SubElement(root, "Hallmarks")
    for h in hallmarks:
        ET.SubElement(hall, "Hallmark", {"code": h}).text = HALLMARKS.get(h, h)
    xml_str = ET.tostring(root, encoding="unicode")
    return {
        "xml": xml_str,
        "hallmarks": hallmarks,
        "legal": "Art. 86a-86o ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    s = score(["A"], main_benefit_test=True)
    if not s["reportable"]:
        failures.append("hallmark A + MBT → raportowalne")
    s2 = score([], main_benefit_test=False)
    if s2["reportable"]:
        failures.append("brak hallmark/MBT → NIE raportowalne")
    dl = deadline_calc("2026-01-15")
    if dl["mdr1_deadline"] != "2026-02-14":
        failures.append(f"termin: oczekiwano 2026-02-14, jest {dl['mdr1_deadline']}")
    xml = generate_mdr1_xml("Jan", "123", "test", ["A"])
    if "MDR-1" not in xml["xml"]:
        failures.append("XML MDR-1 nie wygenerowany")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="MDR Scorer + Generator (GLM52 P12)")
    ap.add_argument("--hallmarks", default="", help="hallmarks oddzielone przecinkiem (A,B,C1...)")
    ap.add_argument("--mbt", action="store_true")
    ap.add_argument("--benefit", type=float, default=0.0)
    ap.add_argument("--arrangement-date", default="")
    ap.add_argument("--name", default="Jan Kowalski")
    ap.add_argument("--nip", default="1234567890")
    ap.add_argument("--desc", default="Uzgodnienie transgraniczne")
    ap.add_argument("--xml", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        failures = self_test()
        if failures:
            print("SELF-TEST: FAIL")
            for f in failures:
                print(f"  ❌ {f}")
            return 1
        print("SELF-TEST: PASS")
        return 0

    halls = [h.strip() for h in args.hallmarks.split(",") if h.strip()]
    out = score(halls, main_benefit_test=args.mbt, tax_benefit_eur=args.benefit)
    if args.arrangement_date:
        out["deadline"] = deadline_calc(args.arrangement_date)
    if args.xml and halls:
        out["mdr1_xml"] = generate_mdr1_xml(args.name, args.nip, args.desc, halls)
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
