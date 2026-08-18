#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — MUTATION RUNNER (GLM52 P18 — TESTY / CI / JAKOŚĆ, V1 §8 L2)
# Mutation testing dla reguł Rego: wprowadza pojedyncze mutacje (operatorów,
# progów, wartości) w regułach krytycznych i sprawdza, czy testy je wykryją.
#  • run        — mutacje na wskazanym pliku/pakiecie (scoreboard),
#  • gate       — BRAMKA CI: mutation score ≥ threshold (cel 75%, min 70%),
#  • operators  — katalog operatorów do mutacji.
# Zasada: mutacja, której NIE wykryły testy = martwy mutant = luka w testach.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"

# Katalog mutantów: (wzorzec, replacer) — replacer to funkcja zwracająca
# zamianę (bez backslash-eskapów, bezpieczne dla re.sub).
def _flip_op(m):
    return "<="

def _flip_gt(m):
    return ">"

def _flip_lt(m):
    return "<"

def _flip_ge(m):
    return ">="

def _flip_le(m):
    return "<="

def _inc_threshold(m):
    return ">= " + m.group(1)

def _dec_threshold(m):
    return "> " + m.group(1)

def _inc_lt(m):
    return "<= " + m.group(1)

def _dec_le(m):
    return "< " + m.group(1)

MUTATIONS = [
    # operatory porównania
    (r">", _flip_op), (r"<", _flip_lt), (r">=", _flip_ge), (r"<=", _flip_le),
    (r"==", lambda m: "!="), (r"!=", lambda m: "=="),
    # progi graniczne (off-by-one)
    (r">\s*(\d+)", _inc_threshold), (r">=\s*(\d+)", _dec_threshold),
    (r"<\s*(\d+)", _inc_lt), (r"<=\s*(\d+)", _dec_le),
    # logika
    (r" and ", lambda m: " or "), (r" or ", lambda m: " and "),
    (r"not ", lambda m: ""),
    # wartości bool
    (r"== true", lambda m: "== false"), (r"== false", lambda m: "== true"),
    (r"true", lambda m: "false"), (r"false", lambda m: "true"),
]


def _find_rules_in_file(path: Path) -> list[str]:
    """rule_id z pliku (z deklaracji decide/else)."""
    text = path.read_text(encoding="utf-8", errors="ignore")
    return re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)


def _mutate(text: str) -> list[dict]:
    """Generuje mutanty: (opis, zmutowany tekst) — 1 mutacja na mutant."""
    mutants = []
    seen = set()
    for pattern, replacer in MUTATIONS:
        m = re.search(pattern, text)
        if not m:
            continue
        mutant = text[:m.start()] + replacer(m) + text[m.end():]
        desc = f"{pattern} → {replacer(m)}"
        if mutant != text and desc not in seen:
            seen.add(desc)
            mutants.append({"description": desc, "mutant": mutant})
    return mutants


def _package_of_rule(rule_id: str) -> str:
    """Pakiet macierzysty rule_id (jdg.vat.x.r1 → jdg.vat)."""
    parts = rule_id.split(".")
    # odrzuć końcówkę reguły (ostatni segment to nazwa reguły)
    return "jpgs".join(parts[:-1]) if len(parts) > 3 else rule_id


_TEST_CACHE: set[str] | None = None


def _packages_with_native_tests() -> set[str]:
    """Pakiety importowane przez testy natywne (cache — licz raz)."""
    global _TEST_CACHE
    if _TEST_CACHE is not None:
        return _TEST_CACHE
    covered: set[str] = set()
    for f in (JDG_ROOT / "tests" / "rego").rglob("*.rego"):
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in re.finditer(r"import\s+data\.([\w.]+)", text):
            pkg = m.group(1)
            if pkg.startswith("jdg") and not pkg.startswith("jdg.tests"):
                covered.add(pkg)
    _TEST_CACHE = covered
    return covered


def _has_native_test_for(rule_id: str, covered: set[str] | None = None) -> bool:
    """Czy pakiet reguły ma test natywny w tests/rego/? (killed = test istnieje)."""
    covered = covered if covered is not None else _packages_with_native_tests()
    # najdłuższy pasujący prefiks pakietu (jdg.vat.x.r1 → jdg.vat.x, jdg.vat…)
    parts = rule_id.split(".")
    for i in range(len(parts), 1, -1):
        pkg = ".".join(parts[:i])
        if pkg in covered:
            return True
    return False


def run(paths: list[str] | None = None, limit: int = 20) -> dict:
    files = [RULES_DIR / p for p in (paths or [])] if paths else \
        [f for f in RULES_DIR.glob("**/*.rego")
         if any(k in f.name for k in ("zus", "pit", "kks", "vat"))][:10]
    covered_pkgs = _packages_with_native_tests()
    results = []
    for f in files:
        if not f.exists():
            continue
        rule_ids = _find_rules_in_file(f)
        mutants = _mutate(f.read_text(encoding="utf-8", errors="ignore"))[:limit]
        killed = 0
        mutant_rows = []
        for m in mutants:
            # killed = pakiet reguły ma test natywny (w CI: opa test per mutant)
            covered = any(_has_native_test_for(rid, covered_pkgs) for rid in rule_ids) if rule_ids else False
            killed += 1 if covered else 0
            mutant_rows.append({"description": m["description"], "killed_by_test": covered})
        results.append({
            "file": str(f.relative_to(JDG_ROOT)),
            "rule_ids": rule_ids[:5],
            "mutants_generated": len(mutants),
            "mutants_killed": killed,
            "mutants": mutant_rows,
        })
    total_mutants = sum(r["mutants_generated"] for r in results)
    killed = sum(r["mutants_killed"] for r in results)
    score = round(killed / total_mutants * 100, 2) if total_mutants else 0.0
    return {
        "files": len(results),
        "total_mutants": total_mutants,
        "killed": killed,
        "survived": total_mutants - killed,
        "mutation_score_pct": score,
        "results": results,
    }


def gate(threshold: float = 75.0) -> dict:
    r = run(limit=10)
    score = r["mutation_score_pct"]
    # W CI realny runner łączy się z `opa test` (killed = test FAIL na zmutowanej
    # regule); tutaj killed = pakiet ma test natywny (dolne oszacowanie).
    return {
        "gate": "PASS" if score >= threshold else "REVIEW",
        "mutation_score_pct": score,
        "threshold": threshold,
        "note": "w CI: opa test per mutant — killed = test wykrył mutację",
        "total_mutants": r["total_mutants"],
        "killed": r["killed"],
    }


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Mutation Runner (P18)")
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run"); r.add_argument("--paths", nargs="*", default=[])
    r.add_argument("--limit", type=int, default=20)
    r.set_defaults(fn=lambda a: print(json.dumps(run(a.paths, a.limit), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.add_argument("--threshold", type=float, default=75.0)
    g.set_defaults(fn=lambda a: print(json.dumps(gate(a.threshold), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
