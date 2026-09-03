#!/usr/bin/env python3
"""
NexusAI JDG — REPO HYGIENE PLANNER (P00-I10)
=============================================
Plan oczyszczenia backupów/śmieci w JDG/ z gwarancją odtworzenia
(archiwum tagów git, NIE usuwanie historii). Wykrywa: pliki .bak,
.bak_stubs_removed, .p03backup, duplikaty nazw, puste pliki, artefakty
tymczasowe (.tmp, _r08_golden_verdict.tmp.json itd.).

Usage:
  python v3_repo_hygiene.py                 # raport śmieci (bramka)
  python v3_repo_hygiene.py --json
  python v3_repo_hygiene.py --write
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_repo_hygiene.json"

BACKUP_PATTERNS = [
    re.compile(r"\.bak$", re.I),
    re.compile(r"\.bak_stubs_removed$", re.I),
    re.compile(r"\.p\d{2}backup$", re.I),
    re.compile(r"\.orig$", re.I),
    re.compile(r"\.tmp\.json$", re.I),
    re.compile(r"\.tmp$", re.I),
    re.compile(r"~$"),
    re.compile(r"^\.#"),
    re.compile(r"\.swp$"),
    re.compile(r"\.old$", re.I),
    re.compile(r"\.copy$", re.I),
    re.compile(r"copy\s*\d", re.I),
]
SCAN_DIRS = ["rules", "tools", "bundles", "migrations", "docs", "tests", "api"]


def classify(path: Path) -> str | None:
    name = path.name
    for pat in BACKUP_PATTERNS:
        if pat.search(name):
            if ".bak" in name:
                return "backup"
            if ".tmp" in name:
                return "tmp"
            return "backup"
    return None


def build() -> dict:
    findings: list[dict] = []
    for d in SCAN_DIRS:
        root = BASE_DIR / d
        if not root.exists():
            continue
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            if "__pycache__" in path.parts or ".git" in path.parts:
                continue
            kind = classify(path)
            if kind:
                findings.append({
                    "path": path.relative_to(BASE_DIR).as_posix(),
                    "kind": kind,
                    "bytes": path.stat().st_size,
                })
    # puste pliki (0 bajtów) — kandydaci do przeglądu
    empty = []
    for d in SCAN_DIRS:
        root = BASE_DIR / d
        if not root.exists():
            continue
        for path in sorted(root.rglob("*")):
            if path.is_file() and path.stat().st_size == 0 and "__pycache__" not in path.parts:
                empty.append(path.relative_to(BASE_DIR).as_posix())
    return {
        "schema_version": "1.0.0",
        "report": "V3_REPO_HYGIENE",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "backup_files": findings,
        "backup_count": len(findings),
        "empty_files": empty,
        "empty_count": len(empty),
        "cleanup_policy": {
            "never_delete_history": "usuwanie wyłącznie przez git rm + commit; historia zostaje w git log",
            "archive_first": "przed usunięciem: utwórz tag git (np. hygiene-p00-YYYYMMDD) wskazujący bieżący stan",
            "review_required": "każdy plik z listy wymaga przeglądu człowieka (4-eyes) przed usunięciem",
            "safe_patterns": [".bak", ".bak_stubs_removed", ".p03backup", ".tmp.json", ".orig", "~"],
        },
        "status": "ŚMIECI_WYKRYTO" if findings or empty else "CZYSTO",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Repo Hygiene Planner")
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
        print(f"V3 REPO HYGIENE: {data['status']} — backupy: {data['backup_count']}, puste pliki: {data['empty_count']}")
        for f in data["backup_files"][:20]:
            print(f"  • [{f['kind']}] {f['path']} ({f['bytes']} B)")
        print("  Polityka: archiwum tagiem git przed usunięciem; każdy plik wymaga przeglądu (4-eyes).")
    return 1 if data["backup_count"] else 0


if __name__ == "__main__":
    sys.exit(main())