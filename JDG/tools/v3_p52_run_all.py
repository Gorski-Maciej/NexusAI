#!/usr/bin/env python3
"""NexusAI JDG — V3-P52 RUNNER — kolejność zależności narzędzi I01–I12.

Uruchamia wszystkie silniki dowodowe P52 w kolejności zależności (rejestr
standardów I01 → progi I02 → waluty I03/I04 → inwarianty I05-I08 → telemetria
I10 → fuzz/doomsday I11/I12 → audyt kalendarza I09). Wyjście:
bundles/v3_p52_run_all_evidence.json (protokół 08 P45 — zero dryfu prefiksów).
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
BUNDLES = TOOLS.parent / "bundles"

ORDER = [
    ("I01", "v3_p52_standards_register.py"),
    ("I02", "v3_p52_engines.py I02"),
    ("I03", "v3_p52_engines.py I03"),
    ("I04", "v3_p52_engines.py I04"),
    ("I05", "v3_p52_engines.py I05"),
    ("I06", "v3_p52_engines.py I06"),
    ("I07", "v3_p52_engines.py I07"),
    ("I08", "v3_p52_engines.py I08"),
    ("I10", "v3_p52_engines.py I10"),
    ("I11", "v3_p52_engines.py I11"),
    ("I12", "v3_p52_engines.py I12"),
    ("I09", "v3_p52_standards_register.py --calendar-only"),
]


def main() -> int:
    started = time.time()
    log, failed = [], []
    for tag, script in ORDER:
        t0 = time.time()
        proc = subprocess.run([sys.executable] + [TOOLS / script.split()[0]] +
                              script.split()[1:],
                              capture_output=True, text=True)
        ok = proc.returncode == 0
        if not ok:
            failed.append(script)
        log.append({"step": tag, "script": script, "ok": ok,
                    "seconds": round(time.time() - t0, 2),
                    "stdout_tail": proc.stdout[-400:] if proc.stdout else "",
                    "stderr_tail": proc.stderr[-400:] if proc.stderr else ""})
        print(f"[V3-P52] {tag:4s} {script:44s} "
              f"{'OK' if ok else 'FAIL'} ({log[-1]['seconds']}s)")
    evidence = {
        "innovation": "V3-P52-RUNNER",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime()),
        "gate": "PASS" if not failed else "FAIL",
        "metrics": {"steps": len(ORDER), "failed": len(failed),
                    "total_seconds": round(time.time() - started, 2)},
        "log": log,
    }
    out = BUNDLES / "v3_p52_run_all_evidence.json"
    out.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n",
                   encoding="utf-8")
    print(f"[V3-P52] runner evidence → {out.name} gate={evidence['gate']}")
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
