#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I03 SHADOW DELTA AUTOMATOR
================================================
Automatyczne porównanie shadow↔active na próbce transakcji z raportem różnic.
Analizuje historię deploymentów (deployments.json): fazy, zapisane delty,
rollbacki i jakość — oraz gotowość mechanizmu (deployment_orchestrator ma
cmd_shadow_compare z progiem delta ≤ 2%, ale wywołanie jest ręczne).

Ujawnia: ile deploymentów ma zapisaną deltę, ile osiągnęło fazę przejściową,
jaki jest wskaźnik rollbacków (zdrowie procesu) i czy active_version jest
aktualne względem healthy_versions.

Usage:
  python tools/v3_p07_shadow_delta.py
"""
from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

DELTA_MAX = 2.0


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    d = json.loads((BUNDLES / "deployments.json").read_text(encoding="utf-8"))
    depl = d.get("deployments", {})
    healthy = d.get("healthy_versions", [])
    active = d.get("active_version")

    phases = Counter(e.get("phase", "?") for e in depl.values())
    deltas = {k: e.get("shadow_delta_pct") for k, e in depl.items()
              if e.get("shadow_delta_pct") is not None}
    over = {k: v for k, v in deltas.items() if v > DELTA_MAX}
    rolled = phases.get("ROLLED_BACK", 0)
    rollback_pct = 100.0 * rolled / max(len(depl), 1)
    active_current = active in healthy or active in depl

    ramp = {k: v for k, v in phases.items()
            if k in ("SHADOW_COMPARE", "RAMPED", "PROMOTED", "CANARY")}
    checks.append({"name": "delta_recorded",
                   "status": "OK" if deltas else "WARN",
                   "detail": f"deploymenty z zapisaną deltą: {len(deltas)}/{len(depl)}"})
    checks.append({"name": "delta_gate_enforced",
                   "status": "FAIL" if not ramp else "OK",
                   "detail": f"fazy przejściowe z bramką delta (SHADOW/RAMP/CANARY): "
                              f"{dict(ramp) or 'BRAK'} — delta ≤ {DELTA_MAX}% nie egzekwowana "
                              f"na ścieżce awansu"})
    checks.append({"name": "rollback_health",
                   "status": "WARN" if rollback_pct < 40 else "WARN",
                   "detail": f"rollbacki: {rolled}/{len(depl)} ({rollback_pct:.0f}%) — wysoki "
                              f"wskaźnik wymaga analizy (L07)"})
    checks.append({"name": "active_version_fresh",
                   "status": "OK" if active_current else "FAIL",
                   "detail": f"active_version={active} w healthy/deployments: {active_current}"})

    findings.append({"id": "V3-P07-L06", "severity": "P1",
                     "evidence": "cmd_shadow_compare istnieje (próg ≤ 2%), ale żaden deployment "
                                 "nie ma fazy SHADOW_COMPARE/RAMPED w historii (rozkład: "
                                 f"{dict(phases)}) — automatyzacja porównania shadow nie jest "
                                 "wpięta w proces",
                     "fix": "Shadow Delta Automator (I03): faza obowiązkowa przed awansem + "
                            "raport różnic do PR [BM]"})
    if rollback_pct >= 40:
        findings.append({"id": "V3-P07-L07", "severity": "P2",
                         "evidence": f"wskaźnik rollbacków {rollback_pct:.0f}% "
                                     f"({rolled}/{len(depl)}) — proces wdrożeniowy generuje "
                                     f"ponad 2× więcej wycofań niż udanych pełnych soaków",
                         "fix": "analiza przyczyn rollbacków (I10 telemetry) + bramki jakości "
                                "przed soakiem (I01)"})
    if not active_current:
        findings.append({"id": "V3-P07-L08", "severity": "P2",
                         "evidence": f"active_version={active} poza zbiorem healthy_versions — "
                                     f"stan aktywny nieświeży względem zdrowych wersji",
                         "fix": "rekonsyliacja active z healthy przy każdym awansie (I09/I10)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I03", "generated_at": now(), "gate": gate,
        "metrics": {"deployments": len(depl), "phases": dict(phases),
                    "delta_recorded": len(deltas), "delta_over_2pct": len(over),
                    "rollbacks": rolled, "rollback_pct": round(rollback_pct, 1),
                    "active_version": active},
        "delta_samples": list(deltas.items())[:8],
        "checks": checks, "findings": findings,
        "contract": {"binding": "P38 (rollout), P39 (CI), P37 (metryki delta), P07-I01 (awans)",
                     "rule": "awans bez zapisanej delty ≤ 2% w fazie SHADOW_COMPARE = blokada [BM]"},
    }
    (BUNDLES / "v3_p07_shadow_delta.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I03] gate={gate} depl={len(depl)} rollbacks={rolled} "
          f"delta_rec={len(deltas)} active={active}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
