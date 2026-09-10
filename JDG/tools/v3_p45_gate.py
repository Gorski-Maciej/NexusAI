#!/usr/bin/env python3
"""NexusAI JDG — V3-P45 CI GATE — bramka jakości reguł: odrzuca PR
wprowadzający NOWĄ regułę-stub (warunek zawsze prawdziwy bez
CHECKPOINT-STUB), szablon bez treści materiałowej (I07) albo nową regułę
materiałową bez _legal_basis z aktem (I11).

Tryby:
  python tools/v3_p45_gate.py          # gate merge: porównuje naruszenia
                                       # plików zmienionych (git diff) z HEAD —
                                       # blokuje TYLKO nowe naruszenia
  python tools/v3_p45_gate.py --all    # audyt całości rules/ (backlog →
                                       # bundles/v3_p45_gate_full_audit.json);
                                       # exit 1 = backlog istnieje (cel zero: P68)

Exit 0 = PASS (merge dozwolony), exit 1 = BLOCK/BACKLOG.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REPO_ROOT = BASE.parent

# Dozwolony stub: { true } w kontekście oznaczonym CHECKPOINT-STUB (konwencja repo)
CHECKPOINT_RE = re.compile(r"CHECKPOINT-STUB", re.IGNORECASE)
STUB_RE = re.compile(r"\{\s*true\s*\}")
ACT_REF = re.compile(r"(art\.|artykuł|ustawa|rozporządzenie|dyrektywa|konwencja)", re.IGNORECASE)
MATERIAL_HINT = re.compile(r"(stawka|limit|próg|podatek|składka|ulga|zwolnienie|kary|termin)", re.IGNORECASE)
# Surowy placeholding = TODO/TBD bez właściciela (TODO P46/P47/... = zarządzany dług, I07)
PLACEHOLDER = re.compile(r"\b(TODO(?! P\d\d)|TBD|PLACEHOLDER_[A-Z_]+)\b")


def _violations(path: Path) -> list[str]:
    """Zwróć listę naruszeń polityki stub-free w pojedynczym pliku.

    Sygnatura naruszenia jest CONTENT-BASED (bez numeru linii): porównanie
    HEAD↔now keyed on line numbers karało każdy wstawiony wiersz powyżej
    komentarza jako "nowy stub" — sprzeczne z kontraktem bramki (blokowane
    są TYLKO treściowo nowe naruszenia).
    """
    violations: list[str] = []
    if not path.exists():
        return violations
    src = path.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines()
    for lineno, line in enumerate(lines, 1):
        if STUB_RE.search(line):
            context = "\n".join(lines[max(0, lineno - 4):lineno])
            if not CHECKPOINT_RE.search(context):
                violations.append(f"reguła-stub {{true}} bez CHECKPOINT-STUB :: {line.strip()[:90]}")
        if (MATERIAL_HINT.search(line) and '"_legal_basis"' in line
                and not ACT_REF.search(line)):
            violations.append(f"reguła materiałowa bez aktu w _legal_basis (I11) :: {line.strip()[:90]}")
    if PLACEHOLDER.search(src):
        violations.append("szablon bez treści materiałowej (surowe TODO/TBD/PLACEHOLDER — I07)")
    return violations


def changed_rego_files() -> list[Path]:
    try:
        proc = subprocess.run(["git", "diff", "--name-only", "HEAD", "--", "JDG/rules", "rules"],
                              cwd=BASE, capture_output=True, text=True, timeout=30)
        files = []
        for line in (proc.stdout or "").splitlines():
            rel = line.strip()
            if not rel.endswith(".rego"):
                continue
            p = BASE.parent / rel
            if p.exists():
                files.append(p)
        return files
    except (subprocess.TimeoutExpired, OSError):
        return []


def _head_violations(path: Path) -> list[str]:
    """Naruszenia w wersji pliku z HEAD (baseline — dług istniejący)."""
    try:
        rel = path.relative_to(BASE.parent)
        proc = subprocess.run(["git", "show", f"HEAD:{rel}"],
                              cwd=BASE, capture_output=True, text=True, timeout=30)
        if proc.returncode != 0:
            return []  # nowy plik — brak baseline
        src = proc.stdout
        lines = src.splitlines()
        violations: list[str] = []
        for lineno, line in enumerate(lines, 1):
            if STUB_RE.search(line):
                context = "\n".join(lines[max(0, lineno - 4):lineno])
                if not CHECKPOINT_RE.search(context):
                    violations.append(f"reguła-stub {{true}} bez CHECKPOINT-STUB :: {line.strip()[:90]}")
            if (MATERIAL_HINT.search(line) and '"_legal_basis"' in line
                    and not ACT_REF.search(line)):
                violations.append(f"reguła materiałowa bez aktu w _legal_basis (I11) :: {line.strip()[:90]}")
        if PLACEHOLDER.search(src):
            violations.append("szablon bez treści materiałowej (surowe TODO/TBD/PLACEHOLDER — I07)")
        return violations
    except (subprocess.TimeoutExpired, OSError):
        return []


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P45 CI gate — zero NOWYCH stubów")
    ap.add_argument("--all", action="store_true",
                    help="audyt całego rules/ (backlog), zamiast gate merge")
    args = ap.parse_args()

    if args.all:
        files = sorted(RULES_DIR.rglob("*.rego")) if (RULES_DIR := BASE / "rules").exists() else []
        backlog: dict[str, list[str]] = {}
        for f in files:
            v = _violations(f)
            if v:
                backlog[str(f.relative_to(BASE))] = v
        total = sum(len(v) for v in backlog.values())
        (BASE / "bundles" / "v3_p45_gate_full_audit.json").write_text(
            json.dumps({"generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                        "mode": "full-audit", "files_with_violations": len(backlog),
                        "total_violations": total,
                        "zero_target": "P68 RECERTYFIKACJA_FINALNA",
                        "backlog": backlog}, ensure_ascii=False, indent=2),
            encoding="utf-8")
        print(f"[v3_p45_gate] AUDYT: {total} naruszeń w {len(backlog)} plikach "
              f"(backlog legacy → eliminacja wg SLA rejestru I01; cel zero: P68)")
        return 1 if total else 0

    files = changed_rego_files()
    if not files:
        print("[v3_p45_gate] brak zmienionych plików rego — PASS")
        return 0

    new_violations: list[str] = []
    fixed_count = 0
    for f in files:
        now_v = _violations(f)
        head_v = _head_violations(f)
        new_violations.extend(f"{f.name}:{v}" for v in now_v if v not in head_v)
        fixed_count += sum(1 for v in head_v if v not in now_v)

    if new_violations:
        print("[v3_p45_gate] BLOCK — NOWE naruszenia polityki stub-free:")
        for v in new_violations[:50]:
            print(f"  - {v}")
        print(f"  łącznie nowych: {len(new_violations)}; nowe stuby są ZAKAZANE (P45-I01/I07/I11)")
        return 1

    print(f"[v3_p45_gate] PASS — {len(files)} zmienionych plików bez NOWYCH stubów "
          f"(usunięte istniejące naruszenia: {fixed_count})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
