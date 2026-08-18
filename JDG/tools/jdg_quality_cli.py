#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — JDG QUALITY CLI (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Konsolidacja narzędzi jakości w JEDNO CLI: health dashboard jakości
# (duplikaty, stuby, hardcode, RV, pokrycie, mutation) — wejście do
# PEWNOSC_DASHBOARD (PROMPT 17). Uruchamia bramki jako infrastrukturę.
#  • health  — dashboard jakości (agregacja narzędzi),
#  • gate    — BRAMKA CI: wszystkie bramki jakości,
#  • list    — katalog zintegrowanych narzędzi.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
TOOLS = JDG_ROOT / "tools"

# Zintegrowane bramki: nazwa → komenda
GATES = {
    "validate_rules": ["validate_rules.py"],
    "invariant_ci": ["invariant_checker.py", "ci"],
    "runtime_invariants": ["runtime_invariants_check.py", "ci"],
    "test_coverage": ["test_coverage_gate.py", "gate", "--threshold", "95"],
    "property_suite": ["property_suite.py", "gate"],
    "fuzz_runner": ["fuzz_runner.py", "gate", "--count", "10000"],
    "mutation_runner": ["mutation_runner.py", "gate", "--threshold", "75"],
    "chaos_runner": ["chaos_runner.py", "gate"],
    "golden_autojustify": ["golden_autojustify.py", "gate"],
}


def health() -> dict:
    """Dashboard jakości: uruchamia bramki szybkie (bez OPA) i agreguje wyniki."""
    results = {}
    for name, cmd in GATES.items():
        script = TOOLS / cmd[0]
        if not script.exists():
            results[name] = {"status": "TOOL_MISSING", "detail": f"brak {cmd[0]}"}
            continue
        try:
            proc = subprocess.run(
                [sys.executable, str(script), *cmd[1:]],
                capture_output=True, text=True, timeout=120, cwd=JDG_ROOT)
            out = proc.stdout.strip().splitlines()
            tail = out[-1] if out else ""
            results[name] = {"status": "OK" if proc.returncode == 0 else "FAIL",
                             "exit": proc.returncode, "tail": tail[:120]}
        except subprocess.TimeoutExpired:
            results[name] = {"status": "TIMEOUT"}
        except Exception as e:  # noqa: BLE001
            results[name] = {"status": "ERROR", "detail": str(e)[:120]}
    failed = sum(1 for r in results.values() if r["status"] not in ("OK",))
    return {"gates": results, "failed": failed, "total": len(GATES),
            "health": "GREEN" if failed == 0 else "RED"}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Quality CLI (P18)")
    sub = p.add_subparsers(dest="cmd", required=True)
    h = sub.add_parser("health"); h.set_defaults(fn=lambda a: print(json.dumps(health(), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.set_defaults(fn=lambda a: print(json.dumps(health(), ensure_ascii=False, indent=1)))
    l = sub.add_parser("list")
    l.set_defaults(fn=lambda a: print(json.dumps({"gates": list(GATES.keys()),
                                                  "count": len(GATES)}, ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
