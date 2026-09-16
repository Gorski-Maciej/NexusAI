#!/usr/bin/env python3
"""
NexusAI JDG — V3-P67 SELF-LEARNING — RUNNER (konwencja P51–P66).
Uruchamia: (1) 12 silników I01–I12, (2) testy Rego natywnie (bin/opa;
kontrakt C2 z P65), (3) bramkę statyczną Rego, (4) pytest pakietu.
Zbiera wyniki do bundla zbiorczego. Exit 0 tylko gdy wszystkie fazy PASS.
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


def main() -> int:
    now = datetime.now(timezone.utc).isoformat()
    failures = []

    # Faza 1: 12 silników (bundla i01_engine..i12_engine)
    results = {}
    for key in ORDER:
        proc = subprocess.run([sys.executable, str(TOOLS / "v3_p67_engines.py"), key],
                              capture_output=True, text=True)
        line = (proc.stdout or "").strip().splitlines()
        results[key] = {"exit": proc.returncode,
                        "output": line[-1] if line else (proc.stderr or "").strip()[-200:]}
        if proc.returncode != 0:
            failures.append(key)

    # Faza 2: testy Rego natywnie (bin/opa; fallback: bramka statyczna)
    rego_gate = "SKIPPED"
    opa = TOOLS.parent.parent / "bin" / "opa"
    if opa.exists():
        proc = subprocess.run(
            [str(opa), "test",
             str(TOOLS.parent / "rules" / "thresholds_jdg.rego"),
             str(TOOLS.parent / "rules" / "v3_p67_self_learning.rego"),
             str(TOOLS.parent / "tests" / "rego" / "test_v3_p67_self_learning.rego")],
            capture_output=True, text=True)
        rego_gate = "PASS" if proc.returncode == 0 else "FAIL"
        results["rego_opa_native"] = {"exit": proc.returncode,
                                      "output": (proc.stdout or "").strip().splitlines()[-1] if proc.stdout.strip() else (proc.stderr or "")[-300:]}
        if proc.returncode != 0:
            failures.append("rego_opa_native")
    else:
        proc = subprocess.run([sys.executable, str(TOOLS / "v3_p67_rego_static_gate.py")],
                              capture_output=True, text=True)
        rego_gate = "PASS_STATIC" if proc.returncode == 0 else "FAIL"
        results["rego_static"] = {"exit": proc.returncode,
                                  "output": (proc.stdout or "").strip().splitlines()[-1]}
        if proc.returncode != 0:
            failures.append("rego_static")

    # Faza 3: bramka statyczna (zawsze; dowód wiringu i mirror sync)
    proc = subprocess.run([sys.executable, str(TOOLS / "v3_p67_rego_static_gate.py")],
                          capture_output=True, text=True)
    static_gate = "PASS" if proc.returncode == 0 else "FAIL"
    results["rego_static_gate"] = {"exit": proc.returncode,
                                   "output": (proc.stdout or "").strip().splitlines()[-1]}
    if proc.returncode != 0:
        failures.append("rego_static_gate")

    summary = {
        "schema": "nexusai.jdg.v3_p67_run_all.v1",
        "part": "P67",
        "slug": "SELF_LEARNING",
        "generated_at": now,
        "engines_run": len(ORDER),
        "rego_gate": rego_gate,
        "static_gate": static_gate,
        "failures": failures,
        "results": results,
    }
    (BUNDLES / "v3_p67_run_all.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    ok = not failures
    summary["gate"] = "PASS" if ok else "FAIL"
    (BUNDLES / "v3_p67_run_all.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"gate": summary["gate"], "failures": failures}, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
