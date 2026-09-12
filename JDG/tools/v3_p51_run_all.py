#!/usr/bin/env python3
"""NexusAI JDG — V3-P51 RUNNER — kolejność zależności narzędzi I01–I12.

Uruchamia wszystkie silniki dowodowe P51 w kolejności zależności (jedno
źródło prawdy: rejestr pustyni I01/I02 → karty/metryki/sweepy). Wyjście:
bundles/v3_p51_run_all_evidence.json (rejestr [V3-P51] — protokół 08 P45:
zero dryfu prefiksów).
"""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
BUNDLES = TOOLS.parent / "bundles"

ORDER = [
    ("I01+I02", "v3_p51_desert_register.py"),
    ("I03", "v3_p51_desert_cards.py"),
    ("I04", "v3_p51_chain_metric.py"),
    ("I05", "v3_p51_semi_auto_drafting.py"),
    ("I06", "v3_p51_systemic_sweep.py"),
    ("I07", "v3_p51_law_radar_block.py"),
    ("I08", "v3_p51_desert_heatmap.py"),
    ("I09", "v3_p51_testless_sweep.py"),
    ("I10", "v3_p51_quarterly_goals.py"),
    ("I11", "v3_p51_vacancy_bridge.py"),
    ("I12", "v3_p51_attestation.py"),
]


def main() -> int:
    started = time.time()
    log, failed = [], []
    for tag, script in ORDER:
        t0 = time.time()
        proc = subprocess.run([sys.executable, str(TOOLS / script)],
                              capture_output=True, text=True)
        ok = proc.returncode == 0
        if not ok:
            failed.append(script)
        log.append({"step": tag, "script": script, "ok": ok,
                    "seconds": round(time.time() - t0, 2),
                    "stdout_tail": proc.stdout[-400:] if proc.stdout else "",
                    "stderr_tail": proc.stderr[-400:] if proc.stderr else ""})
        print(f"[V3-P51] {tag:8s} {script:38s} "
              f"{'OK' if ok else 'FAIL'} ({log[-1]['seconds']}s)")
    evidence = {
        "innovation": "V3-P51-RUNNER",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S+00:00",
                                      time.gmtime()),
        "gate": "PASS" if not failed else "FAIL",
        "metrics": {"steps": len(ORDER), "failed": len(failed),
                    "total_seconds": round(time.time() - started, 2)},
        "log": log,
    }
    out = BUNDLES / "v3_p51_run_all_evidence.json"
    out.write_text(__import__("json").dumps(evidence, ensure_ascii=False,
                                            indent=2), encoding="utf-8")
    print(f"[V3-P51] runner evidence → {out.name} "
          f"gate={evidence['gate']}")
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
