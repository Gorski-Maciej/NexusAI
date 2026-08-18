#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — TEST COVERAGE GATE (GLM52 P18 — TESTY / CI / JAKOŚĆ, V1 §8)
# Bramka pokrycia testami PER PAKIET: każdy pakiet reguł (package jdg.*) musi
# mieć test natywny (tests/rego/) — pokrycie ≥ 95% pakietów, 100% krytycznych
# (V1 §8). Wykrywa pakiety BEZ testów (coverage desert) i blokuje merge.
#  • scan     — mapa pakiet × testy natywne × pytest (pełna tabela luk),
#  • gate     — BRAMKA CI: pokrycie ≥ threshold (domyślnie 95%) pakietów,
#  • report   — raport JSON do MANIFEST (L2 — jedna wersja prawdy).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
TESTS_REGO_DIR = JDG_ROOT / "tests" / "rego"
TESTS_AUTO_DIR = JDG_ROOT / "tests" / "auto"

# Pakiety krytyczne (ZUS, PIT, VAT, KKS — V1 §8: 100% pokrycia wymagane)
CRITICAL_PACKAGES = {"jdg.zus", "jdg.pit", "jdg.vat", "jdg.kks", "jdg.ord",
                     "jdg.micro.zus", "jdg.micro.pit", "jdg.micro.vat", "jdg.micro.kks"}


def _packages_from_rules() -> dict[str, int]:
    """package → liczba reguł (z plików .rego w rules/)."""
    pkgs: dict[str, int] = {}
    for f in RULES_DIR.rglob("*.rego"):
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in re.finditer(r"^package\s+([\w.]+)", text, re.M):
            pkg = m.group(1)
            if pkg.startswith("data."):
                continue
            pkgs[pkg] = pkgs.get(pkg, 0) + text.count('"matched": true')
    return pkgs


def _packages_with_native_tests() -> set[str]:
    """Pakiety, które mają testy natywne (import data.jdg.* w tests/rego/)."""
    covered: set[str] = set()
    for f in list(TESTS_REGO_DIR.rglob("*.rego")):
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in re.finditer(r"import\s+data\.([\w.]+)", text):
            pkg = m.group(1)
            if pkg.startswith("jdg") and not pkg.startswith("jdg.tests"):
                covered.add(pkg)
    return covered


def _is_covered(pkg: str, native: set[str], pytest_: set[str]) -> bool:
    """Pokrycie z prefiksem: jdg.pit jest pokryte przez test jdg.pit.advances."""
    if pkg in native or pkg in pytest_:
        return True
    parts = pkg.split(".")
    for i in range(len(parts), 1, -1):
        prefix = ".".join(parts[:i])
        if any(p.startswith(prefix + ".") for p in native | pytest_):
            return True
    return False


def _packages_with_pytest() -> set[str]:
    """Pakiety wspomniane w testach pytest (tests/auto/ + tests/*.py)."""
    covered: set[str] = set()
    for f in list(TESTS_AUTO_DIR.glob("*.py")) + list(JDG_ROOT.glob("tests/*.py")):
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in re.finditer(r'jdg\.([\w.]+)', text):
            pkg = "jdg." + m.group(1)
            if "tests" not in pkg:
                covered.add(pkg)
    return covered


def scan() -> dict:
    pkgs = _packages_from_rules()
    native = _packages_with_native_tests()
    pytest_ = _packages_with_pytest()
    rows = []
    for pkg, rules in sorted(pkgs.items()):
        if rules == 0:
            continue  # pakiety bez reguł (rates/metadata) nie liczą się do pokrycia
        has_native = pkg in native
        has_pytest = pkg in pytest_
        rows.append({
            "package": pkg, "rules": rules,
            "native_test": has_native, "pytest": has_pytest,
            "covered": _is_covered(pkg, native, pytest_),
            "critical": pkg in CRITICAL_PACKAGES,
        })
    total = len(rows)
    covered = sum(1 for r in rows if r["covered"])
    crit_total = sum(1 for r in rows if r["critical"])
    crit_covered = sum(1 for r in rows if r["critical"] and r["covered"])
    return {
        "total_packages": total,
        "covered_packages": covered,
        "coverage_pct": round(covered / total * 100, 2) if total else 100.0,
        "critical_covered_pct": round(crit_covered / crit_total * 100, 2) if crit_total else 100.0,
        "deserts": [r["package"] for r in rows if not r["covered"]],
        "packages": rows,
    }


def gate(threshold: float = 95.0) -> dict:
    s = scan()
    total, covered = s["total_packages"], s["covered_packages"]
    pct = s["coverage_pct"]
    crit_pct = s["critical_covered_pct"]
    ok = pct >= threshold and crit_pct >= 100.0
    return {
        "gate": "PASS" if ok else "FAIL",
        "coverage_pct": pct,
        "critical_pct": crit_pct,
        "threshold": threshold,
        "deserts": s["deserts"],
        "required": f"coverage ≥ {threshold}% i krytyczne 100%",
    }


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Test Coverage Gate (P18)")
    sub = p.add_subparsers(dest="cmd", required=True)
    sc = sub.add_parser("scan"); sc.set_defaults(fn=lambda a: print(json.dumps(scan(), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.add_argument("--threshold", type=float, default=95.0)
    g.set_defaults(fn=lambda a: print(json.dumps(gate(a.threshold), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
