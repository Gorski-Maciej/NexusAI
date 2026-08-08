#!/usr/bin/env python3
"""
NexusAI JDG — HARDCODED AUDIT GATE (P03 GLM52 — Orkiestrator, Sekcja 4)
========================================================================
Zero-Hardcode Audit: skanuje WSZYSTKIE pliki .rego w rules/ i kataloguje
zakodowane wartości (duże liczby, stawki dziesiętne, okresy czasowe), które
powinny żyć w data.thresholds (thresholds_jdg.rego / DuckDB — hot-reload
< 1 min, V1 §7 / V2 §8 Data API).

BRAMKA CI (HARDCODED_AUDIT): --gate <N> — exit 1 gdy liczba znalezisk
przekracza N (cel: 0 hardcoded w nowych regułach; legacy skatalogowane).

Usage:
  python hardcoded_audit_gate.py scan                # pełny audyt + raport
  python hardcoded_audit_gate.py scan --gate 250     # bramka CI (FAIL > 250)
  python hardcoded_audit_gate.py per-file            # tabela per plik
  python hardcoded_audit_gate.py --help
"""

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES_DIR = BASE / "rules"
REPORT_PATH = BASE / "bundles" / "hardcoded_audit.json"

# Wzorce zakodowanych wartości (analogiczne do hardcoded_audit.py R7)
HARDCODED_PATTERNS = [
    (r"(?<!thresholds\.jdg\.)(?<!thresholds\.)(?<!\")(?<![\w.])(\d{4,})(?![\w.])(?!\s*//)", "large_integer"),
    (r"(?<!thresholds\.jdg\.)(?<!thresholds\.)\b0\.\d{2,3}\b(?!\s*//)", "decimal_rate"),
    (r"(?<![\w/\"])(\d{2,3})\s*(?:dni|days|miesi[ęe]cy|months|lat|years)(?![\w/])", "time_period"),
]

# Wykluczenia: pliki infrastrukturalne, w których wartości NIE są progami
INFRASTRUCTURE_FILES = {
    "main_jdg.rego",
    "_metadata_jdg.rego",
    "_helpers_jdg.rego",
    "thresholds_jdg.rego",
    "temporal.rego",
    "routing.rego",
    "fallback.rego",
    "api_fallback.rego",
    "provenance.rego",
    "validation.rego",
    "risk.rego",
}


def scan_file(path: Path) -> list[dict]:
    """Skanuj pojedynczy plik .rego w poszukiwaniu hardcoded wartości."""
    content = path.read_text(encoding="utf-8")
    findings = []
    for pattern, category in HARDCODED_PATTERNS:
        for match in re.finditer(pattern, content, re.IGNORECASE):
            line_start = content.rfind("\n", 0, match.start()) + 1
            line = content[line_start : content.find("\n", match.start())]
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            # Metadane nie są progami: priorytety reguł, daty valid_from/valid_to,
            # wersje i identyfikatory — pomijamy (migracji podlegają wartości
            # NUMERYCZNE w logice reguł, nie metadane werdyktu).
            if re.search(r'"priority"\s*:', line):
                continue
            if re.search(r'"(?:valid_from|valid_to|rule_id|package|version)"\s*:', line):
                continue
            if category == "large_integer" and re.match(r"\d{4}-\d{2}", line[max(0, match.start() - line_start) :]):
                continue
            # Pomijaj sekcje METADATA/komentarze blokowe — linie wewnątrz opisów
            findings.append({
                "file": str(path.relative_to(RULES_DIR)),
                "value": match.group(0).strip(),
                "category": category,
                "line": content[: match.start()].count("\n") + 1,
                "context": stripped[:110],
            })
    return findings


def scan_all() -> list[dict]:
    all_findings = []
    for root, _dirs, files in os.walk(RULES_DIR):
        for fname in files:
            if not fname.endswith(".rego"):
                continue
            path = Path(root) / fname
            if fname in INFRASTRUCTURE_FILES and fname != "thresholds_jdg.rego":
                continue
            all_findings.extend(scan_file(path))
    return all_findings


def per_file_table(findings: list[dict]) -> list[dict]:
    by_file = Counter(f["file"] for f in findings)
    return [{"file": f, "hardcoded": n} for f, n in by_file.most_common()]


def main() -> int:
    parser = argparse.ArgumentParser(description="HARDCODED_AUDIT gate (P03 GLM52)")
    sub = parser.add_subparsers(dest="cmd", required=True)
    scan = sub.add_parser("scan", help="pełny audyt + bramka")
    scan.add_argument("--gate", type=int, default=None, help="FAIL gdy znaleziska > N")
    scan.add_argument("--report-only", action="store_true", help="bez bramki, tylko raport")
    sub.add_parser("per-file", help="tabela znalezisk per plik")
    args = parser.parse_args()

    if args.cmd == "scan":
        findings = scan_all()
        by_cat = Counter(f["category"] for f in findings)
        files = len({f["file"] for f in findings})
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║  NexusAI JDG — HARDCODED AUDIT GATE (P03 GLM52 §4)          ║")
        print("║  Cel: 0 hardcoded → 100% data.thresholds (hot-reload <1 min) ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print(f"\n📊 Wyniki: {len(findings)} hardcoded wartości w {files} plikach")
        print(f"   large_integer: {by_cat.get('large_integer', 0)}")
        print(f"   decimal_rate:  {by_cat.get('decimal_rate', 0)}")
        print(f"   time_period:   {by_cat.get('time_period', 0)}")
        print("\n📄 Top 10 plików:")
        for row in per_file_table(findings)[:10]:
            print(f"   {row['file']}: {row['hardcoded']}")

        report = {
            "generated_at": datetime.now().isoformat(),
            "tool": "hardcoded_audit_gate.py (P03 GLM52)",
            "total_hardcoded": len(findings),
            "files_affected": files,
            "categories": dict(by_cat),
            "top_files": per_file_table(findings)[:20],
            "migration_target": "data.thresholds (thresholds_jdg.rego / DuckDB — hot-reload < 1 min, V1 §7; V2 §8)",
            "gate": args.gate,
            "findings": findings[:100],
        }
        REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
        REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\n📄 Raport: {REPORT_PATH}")

        if not args.report_only and args.gate is not None:
            if len(findings) > args.gate:
                print(f"\n❌ BRAMKA HARDCODED_AUDIT: {len(findings)} > {args.gate} — MERGE ZABLOKOWANY")
                return 1
            print(f"\n✅ BRAMKA HARDCODED_AUDIT: {len(findings)} <= {args.gate} — merge dozwolony")
        return 0

    if args.cmd == "per-file":
        findings = scan_all()
        for row in per_file_table(findings):
            print(f"{row['file']}: {row['hardcoded']}")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
