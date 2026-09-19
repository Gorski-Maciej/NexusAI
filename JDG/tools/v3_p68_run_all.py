#!/usr/bin/env python3
"""
NexusAI JDG — V3-P68 RE-CERTYFIKACJA — RUNNER (konwencja P51–P67).
Uruchamia: (1) 12 silników I01–I12 (dowody re-certyfikacji), (2) testy Rego
natywnie (bin/opa; kontrakt C2 z P65; fallback: bramka statyczna),
zbiera wyniki do bundla zbiorczego. Exit 0 tylko gdy wszystkie fazy działają.
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

    # Faza 1: 12 silników (bundli i01_engine..i12_engine)
    results = {}
    for key in ORDER:
        proc = subprocess.run([sys.executable, str(TOOLS / "v3_p68_engines.py"), key],
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
             str(TOOLS.parent / "rules" / "v3_p68_recertification_final.rego"),
             str(TOOLS.parent / "tests" / "rego" / "test_v3_p68_recertification_final.rego")],
            capture_output=True, text=True)
        rego_gate = "PASS" if proc.returncode == 0 else "FAIL"
        results["rego_opa_native"] = {"exit": proc.returncode,
                                      "output": (proc.stdout or "").strip().splitlines()[-1] if proc.stdout.strip() else (proc.stderr or "")[-300:]}
        if proc.returncode != 0:
            failures.append("rego_opa_native")
    else:
        proc = subprocess.run([sys.executable, str(TOOLS / "v3_p68_rego_static_gate.py")],
                              capture_output=True, text=True)
        rego_gate = "PASS_STATIC" if proc.returncode == 0 else "FAIL"
        results["rego_static"] = {"exit": proc.returncode,
                                  "output": (proc.stdout or "").strip().splitlines()[-1]}
        if proc.returncode != 0:
            failures.append("rego_static")

    # Faza 3: bramka statyczna (zawsze — integracja progów/wiringu/mirror)
    proc = subprocess.run([sys.executable, str(TOOLS / "v3_p68_rego_static_gate.py")],
                          capture_output=True, text=True)
    static_gate = "PASS" if proc.returncode == 0 else "FAIL"
    results["static_gate"] = {"exit": proc.returncode,
                              "output": (proc.stdout or "").strip().splitlines()[-1]}
    if proc.returncode != 0:
        failures.append("static_gate")

    # Hard gate I01: BLOCK w silniku = brak re-certyfikacji (runner FAIL)
    i01 = json.loads((BUNDLES / "v3_p68_i01_engine.json").read_text(encoding="utf-8"))
    if i01.get("decision") == "BLOCK":
        failures.append("hard_gate_i01")

    summary = {
        "schema": "nexusai.jdg.v3_p68.run_all.v1",
        "part": "P68", "slug": "RECERTYFIKACJA_FINALNA",
        "generated_at": now,
        "phases": {"engines": len(ORDER), "rego": rego_gate, "static": static_gate},
        "engines_run": len(ORDER),
        "rego_gate": rego_gate,
        "static_gate": static_gate,
        "hard_gates": i01.get("metrics", {}),
        "failures": failures,
        "gate": "PASS" if not failures else "FAIL",
        "results": results,
    }
    (BUNDLES / "v3_p68_run_all.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[P68:RUN_ALL] engines={len(ORDER)} rego={rego_gate} static={static_gate} "
          f"failures={failures or 'none'} gate={summary['gate']}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
