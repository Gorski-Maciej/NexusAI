#!/usr/bin/env python3
"""ETAP GLM 5.2 / PROMPT_01 — Orchestrator Wiring Gate (Kontrakt C1/C4).

Weryfikuje integralność wiring'u orkiestratora main_jdg.rego:
  1. Każde `import data.jdg.<pkg>` w main_jdg.rego musi mieć odpowiadający
     plik z `package jdg.<pkg>` w rules/ (inaczej OPA ewaluacja padnie).
  2. Każde wywołanie `<pkg>.decide` / `<pkg>.enforce` / `<pkg>.report`
     musi mieć zaimportowany pakiet.
  3. Raport pakietów ORPHAN (istnieją, ale nie są zaimportowane) — INFO,
     nie błąd (mogą być wołane przez inne pakiety lub testy).

Wyjście: JSON (--json) lub tekst. Exit code: 0 = wiring kompletny.
Zgodność: ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md §3.2 (bramka IMPACT),
Kontrakt C1/C4 kampanii GLM 5.2.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / "rules"
MAIN = RULES_DIR / "main_jdg.rego"

IMPORT_RE = re.compile(
    r'import\s+data\.jdg\.([a-zA-Z0-9_.]+)(?:\s+as\s+([a-zA-Z0-9_]+))?'
)
PACKAGE_RE = re.compile(r'package\s+jdg\.([a-zA-Z0-9_.]+)')
USE_RE = re.compile(r'\b([a-zA-Z0-9_]+)\.(?:decide|enforce|report)\b')


def main() -> int:
    ap = argparse.ArgumentParser(description="Orchestrator Wiring Gate (Kontrakt C1/C4)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    main_txt = MAIN.read_text(encoding="utf-8", errors="replace")
    # pełna ścieżka pakietu → lokalna nazwa (ostatni segment lub alias `as`)
    imports: dict[str, str] = {}  # lokalna_nazwa -> pełna ścieżka
    for full, alias in IMPORT_RE.findall(main_txt):
        local = alias or full.rsplit(".", 1)[-1]
        imports[local] = full

    packages: dict[str, Path] = {}
    for p in RULES_DIR.rglob("*.rego"):
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in PACKAGE_RE.finditer(txt):
            packages.setdefault(m.group(1), p)

    missing = sorted(full for local, full in imports.items() if full not in packages)
    used = set(USE_RE.findall(main_txt))
    used_no_import = sorted(u for u in used if u not in imports and u != "data")
    orphan = sorted(set(packages) - set(imports.values()))

    report = {
        "bramka": "orchestrator_wiring_gate",
        "kontrakt": "C1/C4 (wiring kompletny, brak brakujących pakietów)",
        "main_jdg": str(MAIN.relative_to(ROOT)),
        "importy_w_main": len(imports),
        "pakiety_w_rules": len(packages),
        "brakujace_pakiety": missing,
        "uzyte_bez_importu": used_no_import,
        "pakiety_orphan": orphan,
        "ok": not missing and not used_no_import,
    }
    if args.json:
        print(json.dumps(report, indent=1, ensure_ascii=False))
    else:
        print(f"Orchestrator Wiring Gate — importy: {len(imports)}, pakiety: {len(packages)}")
        print(f"  BRAKUJĄCE pakiety (import bez definicji): {len(missing)}")
        for m in missing:
            print(f"    MISSING {m}")
        print(f"  Użycia bez importu: {len(used_no_import)}")
        for u in used_no_import:
            print(f"    USED_NO_IMPORT {u}")
        print(f"  Pakiety orphan (niezaimportowane w main): {len(orphan)}")
        print("  WYNIK:", "OK — wiring kompletny" if report["ok"] else "NARUSZENIE — patrz wyżej")
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
