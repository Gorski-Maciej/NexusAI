#!/usr/bin/env python3
"""
NexusAI JDG — ZUS Micro Quality Gate (GLM52 P09, Enterprise)
=============================================================
Linter mikro-warstwy ZUS (rules/micro/sus, rules/micro/zdrowotna,
rules/micro/zasilkowa, plan33/plan34 zus) — wdrożenie PROMPT 09:

  • konwerter stubów → reguł warunkowych (auto-fix):
      --fix  kanonizuje _legal_basis per artykuł (canon: Dz.U. 2025 poz. 345
             dla SUS, Dz.U. 2025 poz. 890 dla u.ś.o.z.),
  • detekcja wzorców stubowych:
      matched:true bez warunków merytorycznych (business_type == "JDG",
      *_pass / *_condition_met / *_check flagi — tzw. "generic conditions"),
  • detekcja reguł no_match bez _legal_basis,
  • detekcja duplikatów rule_id (cross-file, w tym micro↔macro jdg.zus.*),
  • detekcja hardcoded wartości (ADR-002 — próg/stawka w treści reguły),
  • raport "zdrowia" per plik (rule_count, stubs, dups, legal_basis, hardcode).

Usage:
  python3 tools/zus_micro_quality.py                # raport (exit 1 przy błędach)
  python3 tools/zus_micro_quality.py --fix          # auto-fix _legal_basis + raport
  python3 tools/zus_micro_quality.py --gate         # bramka CI: 0 błędów wymagane
"""

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
MICRO_DIRS = [
    JDG_ROOT / "rules" / "micro" / "sus",
    JDG_ROOT / "rules" / "micro" / "zdrowotna",
    JDG_ROOT / "rules" / "micro" / "zasilkowa",
]
EXTRA_FILES = [
    JDG_ROOT / "rules" / "micro" / "plan33_zus.rego",
    JDG_ROOT / "rules" / "micro" / "plan34_zus.rego",
    JDG_ROOT / "rules" / "micro" / "_zus_micro_rates.rego",
    JDG_ROOT / "rules" / "micro" / "zus_micro_atomic_p09.rego",
]

# ── Kanon aktów prawnych (LEGAL_REFERENCE_ACTS.md + legal_reference_canon.json) ──
CANON_SUS = "Ustawa z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)"
CANON_HEALTH = ("Ustawa z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej "
                "finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)")
CANON_ZASILK = ("Ustawa z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia "
                "społecznego w razie choroby i macierzyństwa")

# Stare, niekanoniczne zapisy → opis artykułu (wypełniany z nagłówków sekcji)
OLD_SUS = "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)"
OLD_HEALTH_1 = "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)"
OLD_HEALTH_2 = "Ustawa o świadczeniach zdrowotnych z 27.08.2004"
OLD_ZASILK = "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)"

# Mapa artykuł → kanoniczna podstawa (art./ust./pkt wg sekcji plików mikro)
SUS_ARTICLE_LEGAL = {
    "a6": "Art. 6 ust. 1 pkt 4 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a6b": "Art. 6b ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a9": "Art. 9 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a11": "Art. 11 ust. 2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a13": "Art. 13 pkt 4 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a14": "Art. 14 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a18": "Art. 18 ust. 8 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a18a": "Art. 18a ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a18c": "Art. 18c ust. 4-5 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a19": "Art. 19 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a22": "Art. 22 ust. 1-4 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a24": "Art. 24 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a36": "Art. 36 ust. 1-2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a40": "Art. 40 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "a47": "Art. 47 ust. 1 pkt 2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
}

HEALTH_ARTICLE_LEGAL = {
    "a79": "Art. 79 ust. 1 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "a81": "Art. 81 ust. 2 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "a81b": "Art. 81 ust. 2c ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "a81c": "Art. 81 ust. 2e-2f ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "a81d": "Art. 81 ust. 2g-2h ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "a82": "Art. 82 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
}

ZASILK_ARTICLE_LEGAL = {
    "a19": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "a29": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "a32": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "a33": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
}

SECTION_HEADER_RE = re.compile(r"║\s+(\w+)\.(a[0-9a-z]+)\s+—")
OLD_LEGAL_RE = re.compile(r'"_legal_basis"\s*:\s*"([^"]*)"')

# Wzorce stubowe (generic conditions) — matched:true bez warunków merytorycznych
GENERIC_CONDITION_RE = [
    (re.compile(r'business_type\s*==\s*"JDG"'), "generic condition: business_type == JDG"),
    (re.compile(r'"(?:sus|zdrowotna|zasilkowa)_a[0-9a-z]+_r[0-9]+_(?:pass|met|flag)"\s*,\s*false\)\s*==\s*true'),
     "generic condition: *_pass/_met/_flag flaga"),
    (re.compile(r'"sus_condition_met"'), "generic condition: sus_condition_met"),
    (re.compile(r'_check"\s*,\s*false\)\s*==\s*true'), "generic condition: *_check flaga"),
]

HARDCODED_NUM_RE = re.compile(r'"(?:rate|base|limit|amount|threshold|pln)"\s*:\s*[0-9]')
HARDCODED_AMOUNT_RE = re.compile(r'[^"a-z_]\d{4,}(?:\.\d{2})?[^"\d]')

LEGAL_BASIS_OLD_MAP = {
    OLD_SUS: CANON_SUS,
    OLD_HEALTH_1: CANON_HEALTH,
    OLD_HEALTH_2: CANON_HEALTH,
    OLD_ZASILK: CANON_ZASILK,
}


def iter_rego_files():
    files = []
    for d in MICRO_DIRS:
        if d.is_dir():
            files.extend(sorted(d.glob("*.rego")))
    for f in EXTRA_FILES:
        if f.exists():
            files.append(f)
    return files


def detect_sections(lines):
    """Zwraca {start_line_idx: (domain, article)} z nagłówków sekcji."""
    sections = []
    for i, line in enumerate(lines):
        m = SECTION_HEADER_RE.search(line)
        if m:
            sections.append((i, m.group(1), m.group(2)))
    return sections


def canonical_legal_basis_for(domain, article):
    if domain == "sus":
        return SUS_ARTICLE_LEGAL.get(article)
    if domain == "zdrowotna":
        return HEALTH_ARTICLE_LEGAL.get(article)
    if domain == "zasilkowa":
        return ZASILK_ARTICLE_LEGAL.get(article)
    return None


def fix_legal_basis_in_file(path: Path) -> tuple[int, int]:
    """Kanonizuje _legal_basis per sekcja artykułu. Zwraca (zamienione, pozostałe_old)."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    sections = detect_sections(lines)
    if not sections:
        return 0, 0

    replaced = 0
    for idx, (start, domain, article) in enumerate(sections):
        end = sections[idx + 1][0] if idx + 1 < len(sections) else len(lines)
        canon = canonical_legal_basis_for(domain, article)
        if not canon:
            continue
        for j in range(start, end):
            m = OLD_LEGAL_RE.search(lines[j])
            if not m:
                continue
            old = m.group(1)
            if old in LEGAL_BASIS_OLD_MAP or old.startswith("Ustawa o SUS") or "Dz.U. 1998 nr 137" in old \
                    or "Dz.U. 2004 nr 210" in old or "Dz.U. 1999 nr 60" in old:
                lines[j] = OLD_LEGAL_RE.sub(lambda mm: f'"_legal_basis": "{canon}"', lines[j])
                replaced += 1

    path.write_text("\n".join(lines), encoding="utf-8")
    remaining = sum(1 for ln in lines for k in LEGAL_BASIS_OLD_MAP if k in ln)
    return replaced, remaining


def analyze_file(path: Path) -> dict:
    """Raport zdrowia pojedynczego pliku mikro."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rule_ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    legal_bases = re.findall(r'"_legal_basis"\s*:\s*"([^"]*)"', text)
    matched_rules = re.findall(r'"matched"\s*:\s*true', text)

    stubs = []
    for i, line in enumerate(lines, 1):
        for pat, desc in GENERIC_CONDITION_RE:
            if pat.search(line):
                stubs.append((i, desc))
                break

    hardcoded = []
    for i, line in enumerate(lines, 1):
        if line.strip().startswith("#") or line.strip().startswith(("package ", "import ")):
            continue
        if HARDCODED_AMOUNT_RE.search(line):
            hardcoded.append((i, "hardcoded numeric value"))

    no_basis = matched_rules and not legal_bases
    return {
        "file": str(path.relative_to(JDG_ROOT)),
        "rule_count": len(rule_ids),
        "unique_rule_ids": len(set(rule_ids)),
        "matched_true": len(matched_rules),
        "legal_basis_count": len(legal_bases),
        "legal_basis_distinct": len(set(legal_bases)),
        "generic_conditions": stubs,
        "hardcoded": hardcoded,
        "no_legal_basis_any": no_basis,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fix", action="store_true", help="auto-fix _legal_basis (kanonizacja)")
    ap.add_argument("--gate", action="store_true", help="bramka CI — exit 1 przy błędach")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    files = iter_rego_files()
    errors, warnings = [], []
    all_rule_ids = Counter()

    if args.fix:
        for f in files:
            if f.name in ("plan34_zus.rego",):
                continue
            replaced, remaining = fix_legal_basis_in_file(f)
            if replaced:
                print(f"[FIX] {f.name}: kanonizowano {replaced} _legal_basis (pozostało old: {remaining})")

    for f in sorted(files):
        rep = analyze_file(f)
        # zbierz rule_id globalnie
        text = f.read_text(encoding="utf-8")
        for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text):
            all_rule_ids[rid] += 1

        # Biblioteka stawek (_zus_micro_rates.rego) z założenia nie ma reguł decide — pomiń
        if rep["rule_count"] == 0 and f.name != "_zus_micro_rates.rego":
            errors.append(f"[ERROR] {rep['file']}: plik pusty/stub — zero reguł (rule_id)")
        if rep["no_legal_basis_any"]:
            errors.append(f"[ERROR] {rep['file']}: reguły matched:true bez _legal_basis")
        for ln, desc in rep["generic_conditions"]:
            warnings.append(f"[WARNING] {rep['file']}:{ln} — {desc}")
        for ln, desc in rep["hardcoded"]:
            warnings.append(f"[WARNING] {rep['file']}:{ln} — {desc} (ADR-002)")
        if rep["rule_count"] != rep["unique_rule_ids"]:
            dupes = [rid for rid, c in Counter(
                re.findall(r'"rule_id"\s*:\s*"([^"]+)"', f.read_text(encoding="utf-8"))).items() if c > 1]
            errors.append(f"[ERROR] {rep['file']}: duplikaty rule_id w pliku: {dupes[:8]}")

    # Duplikaty cross-file + kolizja micro↔macro (jdg.zus.* bez prefiksu micro)
    for rid, c in all_rule_ids.items():
        if c > 1:
            errors.append(f"[ERROR] rule_id '{rid}' zduplikowany {c}× (cross-file)")
        if re.fullmatch(r"jdg\.zus\.a\d+\.r\d+", rid):
            errors.append(f"[ERROR] rule_id '{rid}' — kolizja namespace z makro (jdg.zus.*); wymagany prefiks jdg.micro.zus.*")

    report = {
        "files_scanned": len(files),
        "total_rule_ids": sum(all_rule_ids.values()),
        "errors": errors,
        "warnings": warnings,
        "health": [analyze_file(f) for f in sorted(files)],
    }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print("═" * 72)
        print("NexusAI JDG — ZUS MICRO QUALITY GATE (GLM52 P09)")
        print(f"Pliki: {report['files_scanned']} · Rule ID (łączna liczba wystąpień): {report['total_rule_ids']}")
        print(f"BŁĘDY: {len(errors)} · OSTRZEŻENIA: {len(warnings)}")
        for e in errors[:40]:
            print(" ", e)
        for w in warnings[:30]:
            print(" ", w)
        print("═" * 72)
        for h in report["health"]:
            print(f"  {h['file']}: reguł={h['rule_count']} (uniq {h['unique_rule_ids']}) "
                  f"matched={h['matched_true']} legal_basis={h['legal_basis_count']} "
                  f"(distinct {h['legal_basis_distinct']}) generic={len(h['generic_conditions'])} "
                  f"hardcode={len(h['hardcoded'])}")

    ok = len(errors) == 0
    if args.gate:
        print("BRAMKA:", "PASS" if ok else "FAIL")
        sys.exit(0 if ok else 1)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
