#!/usr/bin/env python3
"""NexusAI JDG — V3-P50 RUNNER — kolejność zależności narzędzi I01–I12.

Uruchamia wszystkie silniki dowodowe P50 w kolejności zależności
(jedno źródło prawdy: I01 → I02/I12; p50_common rejestruje [V3-P50] w
v3_p50_run_all_evidence.json — brak bloków [V3-P48]/[V3-P49] = zero
dryfu prefiksów, protokół 08 P45).

Kolejność:
  1. v3_p50_duplicate_detector (I01+I02 surowe pary + I12 liczby)  [OPA AST]
  2. v3_p50_contradictions      (I02 klasyfikacja + rozstrzygnięcia)
  3. v3_p50_ruleid_uniqueness   (I03)
  4. v3_p50_single_source_register (I04; + indeks zapytywalny)
  5. v3_p50_dead_tool_archive   (I05)
  6. v3_p50_orphan_data         (I06)
  7. v3_p50_ghost_docs          (I07)
  8. v3_p50_duplication_guard --rebuild (I08: indeks hashy dla strażnika)
  9. v3_p50_generator_prevention (I08 weryfikacja generatorów)
 10. v3_p50_consolidation_ledger (I09)
 11. v3_p50_intentful_variants  (I10)
 12. v3_p50_reachability        (I11)
 13. v3_p50_burden_metric       (I12 metryka + trend)

Wyjście: bundles/v3_p50_run_all_evidence.json.
"""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
BUNDLES = TOOLS.parent / "bundles"

ORDER = [
    ("I01+I02+I12", "v3_p50_duplicate_detector.py"),
    ("I02", "v3_p50_contradictions.py"),
    ("I03", "v3_p50_ruleid_uniqueness.py"),
    ("I04", "v3_p50_single_source_register.py"),
    ("I05", "v3_p50_dead_tool_archive.py"),
    ("I06", "v3_p50_orphan_data.py"),
    ("I07", "v3_p50_ghost_docs.py"),
    ("I08", "v3_p50_duplication_guard.py"),
    ("I08", "v3_p50_generator_prevention.py"),
    ("I09", "v3_p50_consolidation_ledger.py"),
    ("I10", "v3_p50_intentful_variants.py"),
    ("I11", "v3_p50_reachability.py"),
    ("I12", "v3_p50_burden_metric.py"),
]


def main() -> int:
    results = []
    failed = 0
    for inn, script in ORDER:
        t0 = time.time()
        proc = subprocess.run([sys.executable, str(TOOLS / script)],
                              capture_output=True, text=True, timeout=1200)
        ok = proc.returncode == 0
        failed += 0 if ok else 1
        results.append({
            "innovation": inn, "script": script, "ok": ok,
            "duration_s": round(time.time() - t0, 2),
            "stdout_tail": (proc.stdout or "")[-300:],
            "stderr_tail": (proc.stderr or "")[-300:],
        })
        print(("OK  " if ok else "FAIL"), script)

    from v3_p49_common import utcnow_iso
    evidence = {
        "steps": results,
        "failed": failed,
        "scanned_at": utcnow_iso(),
        "note": "gate=PASS = wszystkie silniki uruchomione i dowody zapisane; "
                "decyzje TRIAGE/BLOCK w metrics.routing bundli częśćiowych.",
    }
    bundle = {
        "innovation": "V3-P50-RUNNER",
        "generated_at": utcnow_iso(),
        "gate": "PASS" if failed == 0 else "FAIL",
        "metrics": {"steps_total": len(ORDER), "steps_failed": failed},
        "evidence": evidence,
    }
    out = BUNDLES / "v3_p50_run_all_evidence.json"
    out.write_text(_json(bundle), encoding="utf-8")
    print(f"[V3-P50-RUNNER] steps={len(ORDER)} failed={failed} → {out.name}")
    return 0 if failed == 0 else 1


def _json(obj) -> str:
    import json
    return json.dumps(obj, ensure_ascii=False, indent=2) + "\n"


if __name__ == "__main__":
    raise SystemExit(main())
