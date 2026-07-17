#!/usr/bin/env python3
"""
NexusAI JDG — Micro Plan33 Legal Basis Fixer
Fixes empty _legal_basis and _warnings in plan33_*.rego files.
Maps rule_id patterns to proper Polish legal bases.
"""

import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
PLAN33_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"

# ─── LEGAL BASIS MAPPING ─────────────────────────────────────────────────────

# Package-level defaults
PKG_BASIS = {
    "vat": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "pit": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "zus": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "ord": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "kks": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "uor": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "ryc": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "health": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "ksef": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "jpk": "Rozporządzenie MF w sprawie JPK_VAT",
    "cb": "Dyrektywy UE, UPO, TP, CFC",
    "ceidg": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "succ": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "pcc": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "rodo": "RODO — Rozporządzenie UE 2016/679",
    "est": "Ustawa o podatku od spadków i darowizn",
    "mdr": "Art. 86a-86o Ordynacji Podatkowej (MDR)",
    "tp": "Art. 23o-23zf PIT (Ceny transferowe)",
    "tax_trans": "Ustawa o podatku od czynności cywilnoprawnych",
    "prop": "Ustawa o podatku od nieruchomości",
    "agricultural_tax": "Ustawa o podatku rolnym",
    "prop_transport": "Ustawa o podatkach i opłatach lokalnych",
    "zasilkowa": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
}

# Article-specific mappings — more detailed where known
ARTICLE_BASIS = {
    # VAT articles
    "vat.a106e": "Art. 106e VAT — Faktury: wymogi formalne",
    "vat.a106j": "Art. 106j VAT — Faktury korygujące",
    "vat.a106na": "Art. 106na VAT — KSeF obowiązek",
    "vat.a106ne": "Art. 106ne VAT — KSeF tryb awaryjny",
    "vat.a106ng": "Art. 106ng VAT — KSeF UPO",
    "vat.a106nh": "Art. 106nh VAT — KSeF QR kod",
    "vat.a20": "Art. 20 VAT — Obowiązek podatkowy WNT",
    "vat.a41": "Art. 41 VAT — Stawki VAT",
    "vat.a43": "Art. 43 VAT — Zwolnienia przedmiotowe",
    "vat.a86": "Art. 86 VAT — Odliczenie VAT",
    "vat.a86a": "Art. 86a VAT — VAT od samochodów",
    "vat.a88": "Art. 88 VAT — Wyłączenia z odliczenia",
    "vat.a89a": "Art. 89a VAT — Złe długi: wierzyciel",
    "vat.a89b": "Art. 89b VAT — Złe długi: dłużnik",
    "vat.a8": "Art. 8 VAT — Świadczenie usług",
    "vat.a99": "Art. 99 VAT — Deklaracje VAT",

    # PIT articles
    "pit.a14": "Art. 14 PIT — Przychody z działalności gospodarczej",
    "pit.a14c": "Art. 14c PIT — Różnice kursowe",
    "pit.a22": "Art. 22 PIT — Koszty uzyskania przychodów",
    "pit.a23": "Art. 23 PIT — Wyłączenia z KUP",
    "pit.a26h": "Art. 26h PIT — Ulga termomodernizacyjna",
    "pit.a27": "Art. 27 PIT — Skala podatkowa 12%/32%",
    "pit.a27a": "Art. 27f PIT — Ulga na dzieci",
    "pit.a30a": "Art. 30a PIT — Dochody kapitałowe",
    "pit.a30b": "Art. 30e PIT — Sprzedaż nieruchomości",
    "pit.a31": "Art. 44 PIT — Zaliczki na podatek",
    "pit.a32": "Art. 30c PIT / Ustawa o ryczałcie — Zaliczki uproszczone",
    "pit.a44": "Art. 44 PIT — Zaliczki uproszczone",
    "pit.a45": "Art. 45 PIT — Zeznania roczne",
    "pit.a9a": "Art. 9a PIT — Wybór formy opodatkowania",

    # ZUS articles
    "zus.a11": "Art. 11-12 SUS — Obowiązek ubezpieczeń",
    "zus.a13": "Art. 13 SUS — Powstanie/ustanie ubezpieczeń",
    "zus.a16": "Art. 16-18 SUS — Podstawa wymiaru",
    "zus.a18": "Art. 18 SUS — Podstawa wymiaru składek JDG",
    "zus.a22": "Art. 22 SUS — Stopy procentowe składek",
    "zus.a24": "Art. 104-105 ustawy o promocji zatrudnienia / FGSP",
    "zus.a26": "Ustawa zasiłkowa — Zasiłki chorobowe/macierzyńskie",
    "zus.a32": "Art. 104a-104b ustawy o promocji zatrudnienia — Fundusz Pracy",
    "zus.a35": "Art. 21 ustawy o FGSP",
    "zus.a36": "Art. 36 SUS — Świadczenia gwarantowane",
    "zus.a46": "Art. 46 SUS — Deklaracje ZUS DRA/RCA",
    "zus.a47": "Art. 47 SUS — Terminy płatności składek",
    "zus.a6": "Art. 6 SUS — Podmioty podlegające ubezpieczeniom",
    "zus.a8": "Art. 8-9 SUS — Zbieg tytułów ubezpieczenia",
    "zus.a9": "Art. 9 SUS — Wyłączenia ze składek",
    "zus.base": "Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG",
    "zus.benefit": "Ustawa zasiłkowa — Świadczenia z ZUS",
    "zus.deadline": "Art. 47 SUS — Terminy płatności składek",
    "zus.rate": "Art. 22 SUS — Stopy procentowe składek ZUS",
    "zus.small_plus": "Art. 18c SUS — Mały ZUS Plus",
    "zus.start": "Art. 18a SUS — Ulga na start (6 mies.)",
}



def extract_pkg_art(rule_id):
    """Extract package and article from rule_id like 'jdg.vat.a106e.r11' or 'jdg.zus.base.r1'"""
    # Remove 'jdg.' prefix
    rest = rule_id.replace("jdg.", "")
    parts = rest.split(".")

    if len(parts) >= 2:
        pkg = parts[0]
        # Check if this looks like an article (starts with 'a' followed by numbers)
        if len(parts) >= 3 and re.match(r'^a\d', parts[1]):
            art = ".".join(parts[1:-1])  # everything between pkg and rN
        elif len(parts) >= 3:
            art = parts[1]
        else:
            art = parts[1] if len(parts) > 1 else ""
        return pkg, art
    elif len(parts) == 1:
        return parts[0], ""
    return "", ""


def find_legal_basis(rule_id, routing_reason=""):
    """Find the appropriate legal basis for a rule_id."""
    pkg, art = extract_pkg_art(rule_id)

    # Try exact article mapping first
    if art:
        full_key = f"{pkg}.{art}"
        if full_key in ARTICLE_BASIS:
            return ARTICLE_BASIS[full_key]

    # Try package-level default
    if pkg in PKG_BASIS:
        return PKG_BASIS[pkg]

    # Fallback: try to extract from routing_reason
    if "VAT" in routing_reason or "vat" in pkg:
        return "Ustawa o VAT"
    if "PIT" in routing_reason or "pit" in pkg:
        return "Ustawa o PIT"
    if "ZUS" in routing_reason or "zus" in pkg:
        return "Ustawa o SUS"

    return ""  # unchanged


def find_warning(rule_id, routing_reason=""):
    """Generate a warning for a rule."""
    pkg, art = extract_pkg_art(rule_id)

    # Extract a short description from routing_reason
    if routing_reason:
        # Truncate to max 100 chars
        short = routing_reason[:100] if len(routing_reason) > 100 else routing_reason
        return f"[MICRO] {short}"

    if art:
        return f"[MICRO] {pkg}/{art} — reguła automatyczna"

    return f"[MICRO] {pkg} — reguła automatyczna"


def fix_file(filepath, dry_run=False):
    """Fix empty _legal_basis and _warnings in a plan33 file."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    fixed_count = 0
    new_lines = []

    i = 0
    while i < len(lines):
        line = lines[i]

        # Check if this line contains _legal_basis:""
        if '_legal_basis":""' in line or '_legal_basis": ""' in line:
            # Extract rule_id from this or nearby lines
            rule_id = ""
            routing_reason = ""

            # Look for rule_id in current line
            rid_match = re.search(r'"rule_id":"([^"]+)"', line)
            if rid_match:
                rule_id = rid_match.group(1)

            # Look for _routing_reason in current line
            rr_match = re.search(r'"_routing_reason":"([^"]*)"', line)
            if rr_match:
                routing_reason = rr_match.group(1)

            # If not found in current line, check surrounding lines
            if not rule_id:
                for j in range(max(0, i-3), min(len(lines), i+3)):
                    rid_match = re.search(r'"rule_id":"([^"]+)"', lines[j])
                    if rid_match:
                        rule_id = rid_match.group(1)
                        break

            if not routing_reason:
                for j in range(max(0, i-3), min(len(lines), i+3)):
                    rr_match = re.search(r'"_routing_reason":"([^"]*)"', lines[j])
                    if rr_match:
                        routing_reason = rr_match.group(1)
                        break

            if rule_id:
                new_basis = find_legal_basis(rule_id, routing_reason)
                if new_basis:
                    line = line.replace('"_legal_basis":""', f'"_legal_basis":"{new_basis}"')
                    line = line.replace('"_legal_basis": ""', f'"_legal_basis":"{new_basis}"')
                    fixed_count += 1

        # Also check for empty warnings on the same line as fixed legal_basis
        if '_warnings":[]' in line:
            # Only fix if we also fixed legal_basis or if routing_reason gives us something
            rr_match = re.search(r'"_routing_reason":"([^"]*)"', line)
            rid_match = re.search(r'"rule_id":"([^"]+)"', line)
            if rr_match and rr_match.group(1):
                routing_reason = rr_match.group(1)
            elif rid_match:
                # Check nearby lines
                rule_id = rid_match.group(1)
                for j in range(max(0, i-3), min(len(lines), i+3)):
                    rr_match2 = re.search(r'"_routing_reason":"([^"]*)"', lines[j])
                    if rr_match2 and rr_match2.group(1):
                        routing_reason = rr_match2.group(1)
                        break

            if routing_reason:
                short = routing_reason[:120] if len(routing_reason) > 120 else routing_reason
                line = line.replace('"_warnings":[]', f'"_warnings":["[MICRO] {short}"]')
            elif rid_match:
                pkg, art = extract_pkg_art(rid_match.group(1))
                line = line.replace('"_warnings":[]', f'"_warnings":["[MICRO] {pkg}/{art} — walidacja automatyczna"]')

        new_lines.append(line)
        i += 1

    new_content = "\n".join(new_lines)

    if not dry_run and fixed_count > 0:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)

    return fixed_count


def main():
    dry_run = "--dry-run" in sys.argv

    print("=" * 70)
    print("NexusAI JDG — Micro Plan33 Legal Basis Fixer v1.0")
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print("=" * 70)

    plan33_files = sorted(PLAN33_DIR.glob("plan33_*.rego"))
    if not plan33_files:
        print("  ❌ No plan33 files found!")
        return

    total_fixed = 0
    for fp in plan33_files:
        count = fix_file(fp, dry_run=dry_run)
        pkg_name = fp.stem.replace("plan33_", "")
        if count > 0:
            print(f"  ✅ {pkg_name:25s} → {count:4d} rules fixed")
            total_fixed += count
        else:
            print(f"  ⬜ {pkg_name:25s} → {count:4d} (nothing to fix)")

    print("=" * 70)
    print(f"  📊 TOTAL: {total_fixed} rules fixed across {len(plan33_files)} files")
    if dry_run:
        print(f"  🔍 DRY RUN — no files modified")
    print("=" * 70)


if __name__ == "__main__":
    main()
