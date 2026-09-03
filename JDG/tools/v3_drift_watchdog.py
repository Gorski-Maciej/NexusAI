#!/usr/bin/env python3
"""
NexusAI JDG — DRIFT WATCHDOG DOCS↔CODE (P00-I04)
=================================================
Stały porównywacz liczby/typów artefaktów w dokumentach (README, MANIFEST,
MANIFEST_2_0, COVERAGE_REPORT, INWENTARYZACJA_PLIKOW, docs/*.md) vs
rzeczywisty stan katalogów (scan wg v3_snapshot_engine). Każda
rozbieżność = konflikt dokumentacyjny Cxx z alarmem BLOCKER dla CI.

Usage:
  python v3_drift_watchdog.py               # raport rozbieżności (bramka)
  python v3_drift_watchdog.py --json
  python v3_drift_watchdog.py --write
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_drift_watchdog.json"

DOC_SOURCES = [
    ("JDG/README.md", "README modułu JDG"),
    ("JDG/MANIFEST.md", "MANIFEST (auto-generowany)"),
    ("JDG/COVERAGE_REPORT.md", "Raport pokrycia"),
    ("JDG/docs/MANIFEST_2_0.md", "MANIFEST 2.0"),
    ("JDG/docs/INWENTARYZACJA_PLIKOW.md", "Inwentaryzacja plików"),
    ("JDG/docs/KATALOG_REGUL.md", "Katalog reguł"),
    ("JDG/docs/KATALOG_NARZEDZI.md", "Katalog narzędzi"),
]

# Wzorce deklaracji liczbowych w dokumentach
PATTERNS = {
    "rego_files": re.compile(r"(\d{2,4})\s*(?:plików|plikow|files)\s*(?:Rego|\.rego|rego)", re.I),
    "rule_ids": re.compile(r"(\d{3,6})\s*(?:unikalnych\s+)?rule_id", re.I),
    "tools": re.compile(r"(\d{2,3})\s*(?:narzędzi|narzedzi|tools)", re.I),
    "pytest": re.compile(r"(\d{2,3})\s*(?:testów|testow|testy)\s*pytest", re.I),
}


def extract_declarations(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict = {}
    for metric, pattern in PATTERNS.items():
        vals = [int(m.group(1)) for m in pattern.finditer(text)]
        if vals:
            out[metric] = vals
    return out


def actual_counts() -> dict:
    import importlib.util
    spec = importlib.util.spec_from_file_location("v3_snapshot_engine", Path(__file__).parent / "v3_snapshot_engine.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    snap = mod.build_snapshot()
    c = snap["counts"]
    return {
        "rego_files": c["rego_files"],
        "rule_ids": c["rego_rule_id_unique"],
        "tools": c["tools_py"],
        "pytest": c["pytest_files"],
    }


def build() -> dict:
    actual = actual_counts()
    per_doc: list[dict] = []
    conflicts: list[dict] = []
    for rel, label in DOC_SOURCES:
        path = BASE_DIR.parent / rel if rel.startswith("JDG/") else BASE_DIR / rel
        if not path.exists():
            per_doc.append({"doc": rel, "label": label, "status": "BRAK_PLIKU"})
            conflicts.append({"kind": "BRAK_DOKUMENTU", "doc": rel, "message": "Dokument z listy źródeł nie istnieje."})
            continue
        decl = extract_declarations(path)
        doc_conflicts = []
        for metric, actual_val in actual.items():
            if metric in decl:
                declared = decl[metric]
                # dopuszczamy, jeśli jakakolwiek deklaracja w dokumencie pokrywa stan faktyczny
                if actual_val not in declared:
                    doc_conflicts.append({"metric": metric, "declared": declared, "actual": actual_val})
        entry = {"doc": rel, "label": label, "declarations": decl, "conflicts": doc_conflicts}
        per_doc.append(entry)
        for c in doc_conflicts:
            conflicts.append({"kind": "DRYF_DOKUMENTACJA", "doc": rel, "metric": c["metric"],
                              "declared": c["declared"], "actual": c["actual"],
                              "message": f"{label} deklaruje {c['declared']} dla {c['metric']}, stan faktyczny: {c['actual']}."})
    return {
        "schema_version": "1.0.0",
        "report": "V3_DRIFT_WATCHDOG",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "actual_state": actual,
        "documents": per_doc,
        "conflicts": conflicts,
        "conflict_count": len(conflicts),
        "status": "DRYF_WYKRYTO" if conflicts else "ZSYNCHRONIZOWANE",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Drift Watchdog Docs↔Code")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    data = build()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        a = data["actual_state"]
        print(f"V3 DRIFT WATCHDOG: {data['status']} — {data['conflict_count']} rozbieżności dokumentów vs kod")
        print(f"  stan faktyczny: rego={a['rego_files']}, rule_id={a['rule_ids']}, tools={a['tools']}, pytest={a['pytest']}")
        for c in data["conflicts"]:
            print(f"  ! {c['kind']}: {c['message']}")
    return 1 if data["conflicts"] else 0


if __name__ == "__main__":
    sys.exit(main())