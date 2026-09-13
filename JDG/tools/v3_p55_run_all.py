#!/usr/bin/env python3
"""
NexusAI JDG — V3-P55 ZUS DOMKNIĘCIE — RUNNER (konwencja P51–P54).
Uruchamia 12 silników I01–I12, zbiera wyniki do bundla zbiorczego + raport run_all.
Exit 0 tylko gdy wszystkie bramki PASS.
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
from v3_p55_engines import ENGINES  # noqa: E402

ORDER = [f"I{n:02d}" for n in range(1, 13)]


def main() -> int:
    now = datetime.now(timezone.utc).isoformat()
    results, failures = {}, []
    for key in ORDER:
        proc = subprocess.run(
            [sys.executable, str(TOOLS / "v3_p55_engines.py"), key],
            capture_output=True, text=True)
        line = (proc.stdout or "").strip().splitlines()
        results[key] = {"exit": proc.returncode,
                        "output": line[-1] if line else (proc.stderr or "").strip()[-200:]}
        if proc.returncode != 0:
            failures.append(key)

    summary = {
        "schema": "jdg.v3_p55.run_all.v1",
        "part": "P55", "slug": "ZUS_DOMKNIECIE",
        "generated_at": now,
        "engines_run": len(ORDER),
        "failures": failures,
        "gate": "PASS" if not failures else "FAIL",
        "results": results,
    }
    (BUNDLES / "v3_p55_run_all.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[P55:RUN_ALL] engines={len(ORDER)} failures={failures or 'none'} "
          f"gate={summary['gate']}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
