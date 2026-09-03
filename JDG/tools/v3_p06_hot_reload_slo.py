#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I05 HOT-RELOAD SLO WATCH
==============================================
Pomiar łańcucha hot-reload: zatwierdzenie → zapis JSON → eksport OPA Data API →
wejście w życie w ewaluacji. SLO: < 1 min (cel ADR-002; twarde < 15 min).
Weryfikuje realny stan: thresholds_export.json (artefakt eksportu) i ścieżkę
data_service export w repo.

Usage:
  python tools/v3_p06_hot_reload_slo.py
"""
from __future__ import annotations

import json
import time
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
DATA_JSON = BUNDLES / "thresholds_data.json"
EXPORT_JSON = BUNDLES / "thresholds_export.json"

SLO_SOFT_S = 60   # < 1 min
SLO_HARD_S = 900  # < 15 min

STEPS = ["approve", "write_json", "validate", "export", "data_api_push", "eval_active"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    import subprocess, sys

    timings = {}
    # krok write_json: realny zapis (kopiujemy dane; nie mutujemy store)
    data = json.loads(DATA_JSON.read_text(encoding="utf-8"))
    t0 = time.perf_counter()
    (BUNDLES / "v3_p06_slo_probe.json").write_text(
        json.dumps({"parameters": data.get("parameters", {}), "probe": True},
                   ensure_ascii=False), encoding="utf-8")
    timings["write_json"] = round((time.perf_counter() - t0) * 1000, 2)
    (BUNDLES / "v3_p06_slo_probe.json").unlink(missing_ok=True)

    # krok validate: realne wywołanie data_service.validate (znany TypeError)
    t0 = time.perf_counter()
    r = subprocess.run([sys.executable, str(BASE / "tools" / "data_service.py"), "validate"],
                       capture_output=True, text=True, cwd=str(BASE))
    timings["validate"] = round((time.perf_counter() - t0) * 1000, 2)
    validate_rc = r.returncode

    # krok export: czy artefakt istnieje (end-to-end nieaktywny bez niego);
    # celowo NIE wywołujemy export (analiza read-only — bez mutacji repo)
    export_exists = EXPORT_JSON.exists()
    export_rc = 0 if export_exists else 1

    model_total_s = (sum(timings.values()) / 1000.0) + 0.5  # +0.5 s push/aktywacja (model)
    checks.append({"name": "slo_soft_1min",
                   "status": "OK" if model_total_s < SLO_SOFT_S else "WARN",
                   "detail": f"modelowy czas łańcucha: {model_total_s:.2f} s (SLO < {SLO_SOFT_S} s)"})
    checks.append({"name": "validate_gate",
                   "status": "OK" if validate_rc == 0 else "FAIL",
                   "detail": f"data_service validate rc={validate_rc} — "
                             f"{'OK' if validate_rc==0 else 'TypeError schema string vs float (L05)'}"})
    checks.append({"name": "export_artifact",
                   "status": "OK" if export_exists and export_rc == 0 else "FAIL",
                   "detail": f"thresholds_export.json {'istnieje' if export_exists else 'BRAK'} "
                             f"(export rc={export_rc})"})

    if validate_rc != 0:
        findings.append({"id": "V3-P06-L05", "severity": "P1",
                         "evidence": "hot-reload SLO mierzalny, ale walidacja danych pęka "
                                     "(TypeError schema string vs float) — łańcuch nie może być zielony",
                         "fix": "naprawa typów schema (number) — patrz I01"})
    if not (export_exists and export_rc == 0):
        findings.append({"id": "V3-P06-L10", "severity": "P1",
                         "evidence": "brak artefaktu thresholds_export.json w repo — eksport OPA "
                                     "Data API nie jest częścią pipeline'u; hot-reload nieaktywny "
                                     "end-to-end (SLO niemierzalne w runtime)",
                         "fix": "podpięcie export do CI/pipeline (P38 deployment) + pomiar SLO "
                                "z zegara wstrzykiwanego (P05-I08)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I05", "generated_at": now(), "gate": gate,
        "metrics": {"model_total_s": round(model_total_s, 2),
                    "step_ms": timings, "slo_soft_s": SLO_SOFT_S, "slo_hard_s": SLO_HARD_S,
                    "steps": STEPS},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P38 (deployment — pomiar SLO), P09 (declarative change), P39 (CI)",
                     "rule": "hot-reload SLO < 1 min od zatwierdzenia; przekroczenie = alarm (P37); "
                             "rollback = I08"},
    }
    (BUNDLES / "v3_p06_hot_reload_slo.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I05] gate={gate} model_total={model_total_s:.2f}s "
          f"validate_rc={validate_rc} export={'OK' if export_rc==0 else 'FAIL'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
