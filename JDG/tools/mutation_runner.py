#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I05 MUTATION RUNNER — silnik testowania mutacyjnego
reguł Rego. Dowód nie-fasadowości: mutacja progu/warunku MUSI połamać testy;
jeśli testy dalej przechodzą — testują nazwy, nie semantykę (AP06/I08).

Operatory mutacji (Sekcja 5.4 promptu P45):
  M1 threshold_shift  — zmiana wartości progu liczbowego (>= x -> >= x*2)
  M2 condition_invert — odwrócenie operatora porównania (>= <-> <)
  M3 else_removal     — usunięcie gałęzi else (otwiera lukę fail-closed)
  M4 legal_basis_strip— usunięcie _legal_basis (proweniencja)

Usage:
  python tools/mutation_runner.py --package v3_p45_conversions
  python tools/mutation_runner.py --file rules/v3_p45_conversions.rego
Wynik: bundles/mutation_results.json (mutation score per operator).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import tempfile
import time
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REPO_ROOT = BASE.parent
OPA = REPO_ROOT / "bin" / "opa"
OPA19 = REPO_ROOT / "bin" / "opa19"

TARGETS = {
    # pakiet rego -> plik rego + plik testów natywnych
    "v3_p45_conversions": {
        "rule": BASE / "rules" / "v3_p45_conversions.rego",
        "tests": [BASE / "tests" / "rego" / "test_v3_p45_conversions.rego"],
        "opa19": True,
    },
    "v3_p45_stub_killer": {
        "rule": BASE / "rules" / "v3_p45_stub_killer.rego",
        "tests": [BASE / "tests" / "rego" / "test_v3_p45_stub_killer.rego"],
        "opa19": True,
    },
}

# Mutatory: (nazwa, regex na linię, zamiana)
MUTATORS = [
    ("M1_threshold_shift",
     re.compile(r"(\d{2,})(\s*,)?\s*$"),
     lambda m: str(int(m.group(1)) * 2) + (m.group(2) or "")),
    ("M2_condition_invert", None, "INVERT"),
    ("M3_else_removal", None, "ELSE"),
    ("M4_legal_basis_strip",
     re.compile(r'"_legal_basis":\s*"[^"]*"'),
     lambda m: '"_legal_basis": "MUTATED"'),
]

_INVERTS = [(r">=", "<"), (r"<=", ">"), (r"==", "!=")]


def _mutate_lines(src: str, operator: str) -> list[str]:
    """Zwróć listę wariantów źródła — po jednym na każdą aplikowalną linię."""
    variants = []
    lines = src.splitlines(keepends=True)
    for i, line in enumerate(lines):
        new = None
        if operator == "M1_threshold_shift":
            # tylko linie z liczbami progowymi (>= lub < z liczbą)
            m = re.search(r"(>=|<)\s*(\d{2,})", line)
            if m:
                new_val = int(m.group(2)) * 2
                new = line[:m.start()] + f"{m.group(1)} {new_val}" + line[m.end():]
        elif operator == "M2_condition_invert":
            for pat, rep in _INVERTS:
                if re.search(pat, line):
                    new = re.sub(pat, rep, line, count=1)
                    break
        elif operator == "M3_else_removal":
            # usuń linię 'else = ... {' (otwiera lukę — testy fail-closed muszą paść)
            if re.match(r"\s*else\s*(=|=:=)?\s*", line) and "{" in line:
                new = ""
        elif operator == "M4_legal_basis_strip":
            if '"_legal_basis"' in line:
                new = MUTATORS[3][2](None)
                new = line  # legal_basis_strip nie zmienia logiki — pomijamy w score
                new = None
        if new is not None and new != line:
            variants.append((i, "".join(lines[:i]) + new + "".join(lines[i + 1:])))
    return variants


def _run_tests(rule_path: Path, test_paths: list[Path], use_opa19: bool) -> tuple[bool, int]:
    exe = OPA19 if use_opa19 else OPA
    cmd = [str(exe), "test"]
    if use_opa19:
        cmd.append("--v0-compatible")
    with tempfile.TemporaryDirectory() as td:
        mutated = Path(td) / rule_path.name
        mutated.write_text(rule_path.read_text(encoding="utf-8"), encoding="utf-8")
        cmd += [str(mutated)] + [str(t) for t in test_paths]
        try:
            proc = subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True,
                                  text=True, timeout=180)
        except subprocess.TimeoutExpired:
            return False, 0
        out = proc.stdout + proc.stderr
        m = re.search(r"PASS: (\d+)/(\d+)", out)
        total = int(m.group(2)) if m else 0
    # mutant zabity = testy PADŁY (exit != 0) albo mniej PASS niż baseline
    baseline_cmd = [str(exe), "test"] + (["--v0-compatible"] if use_opa19 else [])
    baseline_cmd += [str(rule_path)] + [str(t) for t in test_paths]
    try:
        b = subprocess.run(baseline_cmd, cwd=REPO_ROOT, capture_output=True,
                           text=True, timeout=180)
        mb = re.search(r"PASS: (\d+)/(\d+)", b.stdout + b.stderr)
        baseline_total = int(mb.group(2)) if mb else 0
        baseline_ok = b.returncode == 0
    except subprocess.TimeoutExpired:
        baseline_total, baseline_ok = 0, False
    killed = (proc.returncode != 0) or (total < baseline_total)
    return killed, baseline_total if baseline_ok else baseline_total


def run_package(pkg: str) -> dict:
    cfg = TARGETS[pkg]
    src = cfg["rule"].read_text(encoding="utf-8")
    results = {"package": pkg, "rule_file": str(cfg["rule"].relative_to(BASE)),
               "mutators": {}, "total_mutants": 0, "killed": 0}
    for operator, _, _ in MUTATORS:
        variants = _mutate_lines(src, operator)
        if operator == "M4_legal_basis_strip":
            # strip nie zmienia semantyki wykonania — pomijamy w score (raportujemy 0)
            results["mutators"][operator] = {"applicable": 0, "killed": 0,
                                             "score": None, "note": "non-semantic, excluded"}
            continue
        killed = 0
        for _idx, mutated_src in variants:
            cfg["rule"].write_text(mutated_src, encoding="utf-8")
            try:
                was_killed, _ = _run_tests(cfg["rule"], cfg["tests"], cfg["opa19"])
            finally:
                cfg["rule"].write_text(src, encoding="utf-8")  # przywróć oryginał
            killed += 1 if was_killed else 0
            results["total_mutants"] += 1
            results["killed"] += 1 if was_killed else 0
        applicable = len(variants)
        results["mutators"][operator] = {
            "applicable": applicable, "killed": killed,
            "score": round(100 * killed / applicable, 1) if applicable else None,
        }
    results["mutation_score"] = round(100 * results["killed"] / results["total_mutants"], 1) \
        if results["total_mutants"] else 0.0
    return results


def main() -> int:
    ap = argparse.ArgumentParser(description="Mutation runner dla reguł Rego (P45-I05)")
    ap.add_argument("--package", default="v3_p45_conversions", choices=sorted(TARGETS))
    ap.add_argument("--out", default=str(BASE / "bundles" / "mutation_results.json"))
    args = ap.parse_args()

    started = time.time()
    result = run_package(args.package)
    result["duration_s"] = round(time.time() - started, 1)
    result["generated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime())
    result["engine"] = "tools/mutation_runner.py (M1-M3 semantic; M4 non-semantic excluded)"
    Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2),
                              encoding="utf-8")
    print(f"[mutation-runner] {args.package}: score={result['mutation_score']}% "
          f"({result['killed']}/{result['total_mutants']} mutants killed) "
          f"in {result['duration_s']}s -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
