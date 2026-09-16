#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 NOWE NARZĘDZIA FORTECY — RUNNER (konwencja P51–P64).
Uruchamia: (1) narzędzia P65 (kontrakt I01, tamper I08, adoption I11,
doc generator I12), (2) 12 silników I01–I12, zbiera wyniki do bundla
zbiorczego. Exit 0 tylko gdy wszystkie silniki działają (exit 0).
"""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
BUNDLES = TOOLS.parent / "bundles"
sys.path.insert(0, str(TOOLS))

ORDER = [f"I{n:02d}" for n in range(1, 13)]
PRE_TOOLS = [("v3_p65_tool_contract.py", []),        # I01
             ("v3_p65_semantic_diff.py", []),        # I02
             ("v3_p65_rule_to_tests.py", []),        # I03
             ("v3_p65_worm_tamper_test.py", []),     # I08
             ("v3_p65_adoption_metrics.py", []),     # I11
             ("v3_p65_doc_generator.py", [])]        # I12


def main() -> int:
    now = datetime.now(timezone.utc).isoformat()
    failures = []

    # Faza 1: narzędzia (produkują bundla wejściowe silników)
    tool_results = {}
    for script, extra in PRE_TOOLS:
        proc = subprocess.run([sys.executable, str(TOOLS / script), *extra],
                              capture_output=True, text=True)
        tool_results[script] = proc.returncode
        if proc.returncode != 0:
            failures.append(script)

    # Faza 2: 12 silników (bundla i01_engine..i12_engine + run_all)
    results = {}
    for key in ORDER:
        proc = subprocess.run([sys.executable, str(TOOLS / "v3_p65_engines.py"), key],
                              capture_output=True, text=True)
        line = (proc.stdout or "").strip().splitlines()
        results[key] = {"exit": proc.returncode,
                        "output": line[-1] if line else (proc.stderr or "").strip()[-200:]}
        if proc.returncode != 0:
            failures.append(key)

    summary = {
        "schema": "jdg.v3_p65.run_all.v1",
        "part": "P65", "slug": "NOWE_NARZEDZIA",
        "generated_at": now,
        "tools_run": len(PRE_TOOLS),
        "tool_results": tool_results,
        "engines_run": len(ORDER),
        "failures": failures,
        "gate": "PASS" if not failures else "FAIL",
        "results": results,
    }
    (BUNDLES / "v3_p65_run_all.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[P65:RUN_ALL] tools={len(PRE_TOOLS)} engines={len(ORDER)} "
          f"failures={failures or 'none'} gate={summary['gate']}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
