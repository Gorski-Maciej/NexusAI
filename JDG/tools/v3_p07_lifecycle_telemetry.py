#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I10 LIFECYCLE TELEMETRY
=============================================
Dashboard SLO cyklu życia (P07-AN11): czas PR→produkcja, MTTR, liczba
rollbacków, delta shadow, wiek SHADOW/CANDIDATE. Oblicza z dostępnych danych
(deployments.json, rule_registry.json) i definiuje metryki dla P37 — pierwsza
emisja (bez pomiaru runtime).

Usage:
  python tools/v3_p07_lifecycle_telemetry.py
"""
from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
REFERENCE = datetime(2026, 9, 3, tzinfo=timezone.utc)


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    depl = json.loads((BUNDLES / "deployments.json").read_text(encoding="utf-8"))
    deployments = depl.get("deployments", {})
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))

    phases = Counter(e.get("phase", "?") for e in deployments.values())
    rollbacks = phases.get("ROLLED_BACK", 0)
    rollback_pct = 100.0 * rollbacks / max(len(deployments), 1)
    with_delta = sum(1 for e in deployments.values() if e.get("shadow_delta_pct") is not None)
    quality_ok = sum(1 for e in deployments.values()
                     if e.get("quality", 100) >= 95)

    # wiek statusów w rejestrze (od registered_at)
    shadow_age = []
    for rid, e in registry.items():
        for v in e.get("versions", []):
            st = v.get("status")
            if st in ("SHADOW", "CANDIDATE"):
                try:
                    age = (REFERENCE - datetime.fromisoformat(v["registered_at"])).days
                except Exception:
                    age = -1
                shadow_age.append({"rule": rid, "status": st, "age_days": age})

    metrics = {
        "deployments_total": len(deployments),
        "rollbacks_total": rollbacks,
        "rollback_rate_pct": round(rollback_pct, 1),
        "shadow_delta_evidence_pct": round(100.0 * with_delta / max(len(deployments), 1), 1),
        "quality_gte95_pct": round(100.0 * quality_ok / max(len(deployments), 1), 1),
        "shadow_candidate_age_max_days": max([a["age_days"] for a in shadow_age], default=0),
        "registry_rules": len(registry),
        "pr_to_prod_hours": "NOT_RECORDED",
        "mttr_minutes": "NOT_RECORDED",
        "auto_rollback_minutes": "NOT_RECORDED",
    }

    checks.append({"name": "dashboard_emitted",
                   "status": "OK",
                   "detail": f"metryki: {json.dumps(metrics, ensure_ascii=False)[:150]}"})
    checks.append({"name": "runtime_slo_recorded",
                   "status": "FAIL",
                   "detail": "PR→produkcja, MTTR, auto-rollback NIE są rejestrowane w danych — "
                             "pomiar wymaga znaczników czasowych operacji (P37/P38)"})

    findings.append({"id": "V3-P07-L15", "severity": "P2",
                     "evidence": "SLO lifecycle (PR→prod, MTTR ≤ 15 min, auto-rollback ≤ 5 min) "
                                 "niewymierne — brak znaczników czasowych operacji w rejestrze "
                                 "i deploymentach",
                     "fix": "Lifecycle Telemetry (I10): rejestracja timestampów operacji "
                            "(register→promote→active) + pomiar runtime z P37"})
    findings.append({"id": "V3-P07-L16", "severity": "P3",
                     "evidence": "telemetria pierwsza emisja — dashboard bez połączenia z P37",
                     "fix": "podpięcie metryk do P37 (nazwy poniżej)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I10", "generated_at": now(), "gate": gate,
        "metrics": metrics,
        "rollback_rate_note": f"rollbacki: {rollbacks}/{len(deployments)} "
                              f"({rollback_pct:.0f}%) — patrz I03 (L07)",
        "checks": checks, "findings": findings,
        "metric_names": ["lifecycle_pr_to_prod_hours", "lifecycle_mttr_minutes",
                         "lifecycle_auto_rollback_minutes", "lifecycle_rollback_count",
                         "lifecycle_shadow_delta_pct", "lifecycle_shadow_age_days"],
        "contract": {"binding": "P37 (dashboard SLO), P38 (deployment), P43 (DR — MTTR), "
                                "P07-I01/I03 (bramki)",
                     "rule": "SLO: PR→prod < 24 h, MTTR ≤ 15 min, auto-rollback ≤ 5 min — "
                             "alarm przy przekroczeniu (P37)"},
    }
    (BUNDLES / "v3_p07_lifecycle_telemetry.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I10] gate={gate} depl={len(deployments)} rollback_rate="
          f"{rollback_pct:.0f}% quality_ok={quality_ok}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
