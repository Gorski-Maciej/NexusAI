#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I04 LEAD-TIME SLA DASHBOARD
=================================================
Pomiar lead time per nowelizacja vs deadline (gotowe 30/14/7 dni przed
wejściem w życie). Każda zmiana w kalendarzu musi mieć ścieżkę 30→14→7
z egzekucją w CI; przekroczenie dowolnego progu = alert + blokada.

Usage:
  python tools/v3_p08_lead_time_sla.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

SLA_BUCKETS_DAYS = [30, 14, 7]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    radar = json.loads((BUNDLES / "law_radar.json").read_text(encoding="utf-8"))
    cal = json.loads((BUNDLES / "legal_change_calendar.json").read_text(encoding="utf-8"))
    drafts = radar.get("drafts", {})
    changes = cal.get("changes", {})
    kpi = radar.get("kpi", {})

    per_change = []
    for cid, ch in changes.items():
        cd = ch.get("countdown_days")
        prepared = ch.get("rules_prepared", [])
        buckets = {b: (cd is not None and cd >= b) for b in SLA_BUCKETS_DAYS}
        per_change.append({"id": cid, "countdown_days": cd, "buckets_ok": buckets,
                           "rules_prepared": len(prepared)})
    no_bucket_ready = [p for p in per_change if not all(p["buckets_ok"].values())]

    checks.append({"name": "sla_bucket_30_14_7", "status": "FAIL" if no_bucket_ready else "OK",
                   "detail": f"zmiany: {len(per_change)}; niespełniające progu 7 dni: "
                             f"{[p['id'] for p in no_bucket_ready] or 'brak'}"})
    checks.append({"name": "lead_kpi_target", "status": "FAIL" if not kpi else "OK",
                   "detail": f"kpi lead_time_avg_days={kpi.get('lead_time_avg_days')} "
                             f"vs target={kpi.get('target_lead_days')}"})
    # czy dashboard istnieje jako artefakt raportujący per-nowelizację
    dash = (BUNDLES / "v3_p08_lead_time_sla_dashboard.json").exists()
    checks.append({"name": "dashboard_artifact", "status": "OK" if dash else "FAIL",
                   "detail": "brak artefaktu dashboardu per-nowelizacja (30/14/7)"})

    findings.append({"id": "V3-P08-L04", "severity": "P1",
                     "evidence": "law_radar.json KPI: lead_time_avg_days=26595 (draft testowy "
                                 "2099) — brak pomiaru lead time per nowelizacja; kalendarz: "
                                 f"{len(changes)} zmiana(y) bez ścieżki 30→14→7 w CI",
                     "fix": "I04 Lead-Time SLA Dashboard: buckets 30/14/7 per zmiana z alertem "
                            "i blokadą; KPI lead per akt (nie globalna średnia)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I04", "generated_at": now(), "gate": gate,
        "metrics": {"changes": len(changes), "sla_buckets": SLA_BUCKETS_DAYS,
                    "lead_time_avg_days": kpi.get("lead_time_avg_days"),
                    "target_lead_days": kpi.get("target_lead_days")},
        "per_change": per_change, "checks": checks, "findings": findings,
        "contract": {"binding": "P08-I05 (impact na brak gotowości), P07 (SHADOW przed "
                                "wejściem), P38 (bundle z datą wejścia), P37 (SLO)",
                     "rule": "każda zmiana: SHADOW gotowy ≥ 30 dni, CANDIDATE ≥ 14, "
                             "ACTIVE ≥ 7 dni przed wejściem; inaczej alert P1"},
    }
    (BUNDLES / "v3_p08_lead_time_sla.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I04] gate={gate} changes={len(changes)} "
          f"not_7d_ready={len(no_bucket_ready)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
