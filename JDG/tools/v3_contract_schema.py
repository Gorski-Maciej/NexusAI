#!/usr/bin/env python3
"""
NexusAI JDG — CONTRACT SCHEMA DSL (P00-I03)
============================================
Deklaratywny schemat kontraktów międzyczęściowych serii V3 (YAML/JSON):
jakie sekcje, tabele i identyfikatory musi zawierać KAŻDY raport, żeby
żadna część nie złamała standardu P00. Walidator raportów w CI.

Usage:
  python v3_contract_schema.py              # wypisz schemat + waliduj istniejące raporty
  python v3_contract_schema.py --json
  python v3_contract_schema.py --write
  python v3_contract_schema.py --report PATH  # walidacja pojedynczego raportu
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
REPORTS_DIR = BASE_DIR / "raporty_glm52_v3"
OUT_JSON = BASE_DIR / "bundles" / "v3_contract_schema.json"

# Deklaratywny schemat kontraktu raportu V3 (P00-I03 / P00-I12)
CONTRACT_SCHEMA = {
    "schema_version": "1.0.0",
    "contract": "RAPORT_V3_CONTRACT",
    "required_sections": [
        "EXECUTIVE SUMMARY",
        "ZAKRES I OGRANICZENIA",
        "STAN OBECNY",
        "PODANALIZY",
        "MACIERZ PRAWO",
        "REJESTR LUK",
        "INNOWACJE ENTERPRISE",
        "KONTRAKT WYJŚCIOWY",
        "PLAN WDROŻENIA",
        "PLAN TESTÓW",
        "PYTAŃ DO CZŁOWIEKA",
        "ZAAŁOŻENIA JAWNE",
    ],
    "required_tables": [
        "T1 tabela dowodów",
        "T2 macierz PRAWO",
        "T3 rejestr luk",
        "T4 rejestr innowacji",
        "T5 kontrakt wyjściowy",
        "T6 plan wdrożenia",
        "T7 plan testów",
        "T8 pytania do człowieka",
        "T9 założenia jawne",
        "T10 przekazywane artefakty",
        "T11 matryca podanaliza",
        "T12 rejestr konfliktów",
    ],
    "id_patterns": {
        "luka": r"V3-P\d\d-L\d{2}",
        "innowacja": r"V3-P\d\d-I\d{2}",
        "konflikt": r"V3-P\d\d-C\d{2}",
        "pytanie": r"V3-P\d\d-Q\d{2}",
        "krzyżowe": r"V3-P\d\d-X\d{2}",
    },
    "status_markers": ["WDROŻONY_100", "NIE_WDROŻONY"],
    "file_naming": "RAPORT_V3_<KOD>_<SLUG>.txt",
    "min_innovations": 12,
    "binding": "P00-I03: schemat kontraktu międzyczęściowego — wiążący dla P01–P68",
}

SECTION_RE = {
    "EXECUTIVE SUMMARY": re.compile(r"EXECUTIVE SUMMARY", re.I),
    "ZAKRES I OGRANICZENIA": re.compile(r"ZAKRES I OGRANICZENIA", re.I),
    "STAN OBECNY": re.compile(r"STAN OBECNY", re.I),
    "PODANALIZY": re.compile(r"PODANALIZY", re.I),
    "MACIERZ PRAWO": re.compile(r"MACIERZ PRAWO|PRAWO.*REGUŁA.*TEST", re.I),
    "REJESTR LUK": re.compile(r"REJESTR LUK", re.I),
    "INNOWACJE ENTERPRISE": re.compile(r"INNOWACJE ENTERPRISE|INNOWACJE", re.I),
    "KONTRAKT WYJŚCIOWY": re.compile(r"KONTRAKT WYJŚCIOWY", re.I),
    "PLAN WDROŻENIA": re.compile(r"PLAN WDROŻENIA", re.I),
    "PLAN TESTÓW": re.compile(r"PLAN TESTÓW", re.I),
    "PYTAŃ DO CZŁOWIEKA": re.compile(r"PYTAŃ DO CZŁOWIEKA|PYTAŃ", re.I),
    "ZAAŁOŻENIA JAWNE": re.compile(r"ZAAŁOŻENIA JAWNE", re.I),
}


def validate_report(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    missing_sections = [s for s, rx in SECTION_RE.items() if not rx.search(text)]
    status_markers_found = [m for m in CONTRACT_SCHEMA["status_markers"] if m in text]
    id_counts = {}
    for name, pattern in CONTRACT_SCHEMA["id_patterns"].items():
        id_counts[name] = len(re.findall(pattern, text))
    innovations = id_counts.get("innowacja", 0)
    return {
        "report": path.name,
        "valid": not missing_sections,
        "missing_sections": missing_sections,
        "status_markers": status_markers_found,
        "id_counts": id_counts,
        "innovations_count": innovations,
        "innovations_ok": innovations >= CONTRACT_SCHEMA["min_innovations"],
    }


def build() -> dict:
    validations = []
    if REPORTS_DIR.exists():
        for report in sorted(REPORTS_DIR.glob("*.txt")):
            validations.append(validate_report(report))
    valid = all(v["valid"] and v["innovations_ok"] for v in validations) if validations else True
    return {
        "schema_version": "1.0.0",
        "report": "V3_CONTRACT_SCHEMA",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "schema": CONTRACT_SCHEMA,
        "validated_reports": validations,
        "reports_valid": valid,
        "status": "ZGODNE_Z_KONTRAKTEM" if valid else "NARUSZENIE_KONTRAKTU",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Contract Schema DSL")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--report", metavar="PATH")
    args = parser.parse_args()

    if args.report:
        result = validate_report(Path(args.report))
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result["valid"] else 1

    data = build()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3 CONTRACT SCHEMA: {data['status']} — {len(data['validated_reports'])} raportów zwalidowanych")
        for v in data["validated_reports"]:
            ok = "OK" if v["valid"] and v["innovations_ok"] else "FAIL"
            print(f"  [{ok}] {v['report']}: innowacje={v['innovations_count']}, brak sekcji={v['missing_sections'] or '—'}")
    return 0 if data["reports_valid"] else 1


if __name__ == "__main__":
    sys.exit(main())