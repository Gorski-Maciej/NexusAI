#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I07 ORACLE HEALTH DASHBOARD
==================================================
Metryki zdrowia oracle: pokrycie decyzji (liczba werdyktów × domeny),
% uzasadnionych delt, wiek setu, częstotliwość re-generacji. Czyta
golden_verdicts.json + metrics_pewnosci.json (uvr) i liczy wskaźniki.

Usage:
  python tools/v3_p10_oracle_health_dashboard.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    golden = BUNDLES / "golden_verdicts.json"
    metrics = BUNDLES / "metrics_pewnosci.json"

    verdicts, packages, recorded, uvr = {}, set(), [], None
    if golden.exists():
        d = json.loads(golden.read_text(encoding="utf-8"))
        verdicts = d.get("verdicts", {})
        for rec in verdicts.values():
            packages.add(rec.get("verdict", {}).get("package", "?"))
            if rec.get("recorded_at"):
                recorded.append(rec["recorded_at"])
    if metrics.exists():
        m = json.loads(metrics.read_text(encoding="utf-8"))
        uvr = m.get("uvr")

    age_days = None
    if recorded:
        first = min(recorded)
        try:
            from datetime import datetime as dt
            age_days = round((dt.now(timezone.utc) - dt.fromisoformat(first)).days, 1)
        except Exception:
            age_days = None

    verdict_count = len(verdicts)
    domain_count = len(packages)
    checks.append({"name": "golden_present", "status": "OK" if verdict_count else "FAIL",
                   "detail": f"golden set: {verdict_count} werdyktów / {domain_count} pakietów"})
    checks.append({"name": "age_computed", "status": "OK" if age_days is not None else "FAIL",
                   "detail": f"wiek setu (od pierwszego recorded_at): {age_days} dni"})
    checks.append({"name": "metrics_pewnosci", "status": "OK" if uvr is not None else "FAIL",
                   "detail": f"metrics_pewnosci.json: uvr={uvr}"})

    if verdict_count < 50:
        findings.append({"id": "V3-P10-L07", "severity": "P2",
                         "evidence": f"golden set ma {verdict_count} werdyktów w {domain_count} "
                                     f"pakietach — poniżej progu reprezentatywności (50) dla "
                                     f"~12k rule_id; brak dashboardu zdrowia oracle (pokrycie, "
                                     f"% uzasadnionych, wiek) jako artefaktu",
                         "fix": "I07/I09: dashboard oracle health (JSON+md) w CI + plan domykania "
                                "pokrycia per domena (priorytety ryzyka)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I07",
        "name": "Oracle Health Dashboard — metryki pokrycia, wieku, uzasadnień",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"verdict_count": verdict_count, "domain_count": domain_count,
                    "set_age_days": age_days, "uvr": uvr,
                    "regen_frequency_days": None},
        "health": {"score_0_100": min(100, round(verdict_count / 50 * 100, 1)),
                   "coverage_domains": sorted(packages)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P37 (obserwowalność), P44 (certyfikacja)",
                     "rule": "zdrowie oracle jest mierzone i raportowane przy każdej re-generacji; "
                             "spadek % uzasadnionych delt = alarm"}}
    (BUNDLES / "v3_p10_oracle_health_dashboard.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I07] gate={gate} verdicts={verdict_count} domains={domain_count}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
