#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I07 DANGEROUS CHANGE GUARD
=================================================
Blokada deklaracji niebezpiecznych: brak podstawy prawnej (P01/LKG), konflikt
z invariantami (P04), zmiana poza granicami deklaratywności (nowe domeny,
zmiana invariantów). Deklaracja niebezpieczna = MANUAL_REVIEW, nigdy cichy
AUTO_POST.

Usage:
  python tools/v3_p09_dangerous_change_guard.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

# Granice deklaratywności (P09-AN07): co NIGDY nie jest deklaratywne
NEVER_DECLARATIVE = [
    "nowa domena", "nowej domeny", "zmiana invariantów P04", "zmiana kontraktu werdyktu",
    "zmiana schematu diffu", "nowa warstwa architektury",
]

DANGEROUS_SAMPLES = [
    {"id": "DEC-NO-BASIS", "desc": "zmiana bez podstawy prawnej",
     "legal_basis": None, "expected": "BLOCK"},
    {"id": "DEC-NEW-DOMAIN", "desc": "wprowadzenie nowej domeny",
     "legal_basis": "art. 41 VAT", "expected": "MANUAL_REVIEW"},
    {"id": "DEC-VALID", "desc": "zmiana stawki z podstawą",
     "legal_basis": "Art. 41 ustawy o VAT", "expected": "OK"},
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def guard(decl: dict) -> str:
    if not decl.get("legal_basis"):
        return "BLOCK"
    for n in NEVER_DECLARATIVE:
        if n in json.dumps(decl, ensure_ascii=False).lower():
            return "MANUAL_REVIEW"
    return "OK"


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    # realne wywołanie strażnika wymagałoby subprocess/importu narzędzia — sam tekst
    # „invariants" w planie to nie egzekucja
    guards_in_tool = ("subprocess" in dc) or ("import invariant_checker" in dc)
    results = {d["id"]: guard(d) for d in DANGEROUS_SAMPLES}

    checks.append({"name": "guard_model", "status": "OK",
                   "detail": f"decyzje strażnika: {results} (BLOCK/MANUAL_REVIEW/OK)"})
    checks.append({"name": "wired_in_tool", "status": "FAIL" if not guards_in_tool else "OK",
                   "detail": "declarative_change.py nie woła invariant_checker (P04) ani "
                             "legal_basis_audit przed wykonaniem"})

    findings.append({"id": "V3-P09-L07", "severity": "P0",
                     "evidence": "declarative_change.py execute --execute-data zapisuje "
                                 "zmianę bez sprawdzenia podstawy prawnej i invariantów; "
                                 "invariant_checker.py (P04) i legal_basis_audit.py istnieją, "
                                 "ale nie są wywoływane na ścieżce deklaracji — deklaracja "
                                 "bez podstawy (DEC-NO-BASIS → BLOCK) przeszłaby dziś do "
                                 "zapisu (fail-open)",
                     "fix": "I07 Dangerous Change Guard: przed EXECUTE — legal_basis w LKG "
                            "(P01) + invariant_checker CI (P04); BLOCK/MANUAL_REVIEW zamiast "
                            "zapisu"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I07", "generated_at": now(), "gate": gate,
        "metrics": {"never_declarative": len(NEVER_DECLARATIVE),
                    "guard_results": results, "wired_in_tool": guards_in_tool},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty), P01 (LKG), P43 (RBAC), P03 (fail-closed)",
                     "rule": "bez podstawy prawnej = BLOCK; poza granicami deklaratywności = "
                             "MANUAL_REVIEW; nigdy cichy zapis"}}
    (BUNDLES / "v3_p09_dangerous_change_guard.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I07] gate={gate} results={results}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
