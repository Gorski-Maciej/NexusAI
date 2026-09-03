#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I09 DATA FRESHNESS DASHBOARD
==================================================
Świeżość i weryfikacja źródeł każdego parametru: wiek (od changed_at),
akt prawny (source_act), ostatni audyt. Alerty na parametry bez źródła /
bez weryfikacji / starsze niż cykl roczny.

Usage:
  python tools/v3_p06_freshness_dashboard.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
DATA_JSON = BUNDLES / "thresholds_data.json"
REFERENCE_DATE = datetime(2026, 9, 3, tzinfo=timezone.utc)


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    data = json.loads(DATA_JSON.read_text(encoding="utf-8"))
    params = data.get("parameters", {})
    audit = data.get("changed_by_audit", [])

    rows = []
    for key, entry in params.items():
        versions = entry.get("versions", [])
        if not versions:
            rows.append({"key": key, "status": "NO_VERSION"})
            continue
        latest = max(versions, key=lambda v: v.get("changed_at", ""))
        try:
            age_days = (REFERENCE_DATE - datetime.fromisoformat(latest["changed_at"])
                        ).days
        except Exception:
            age_days = -1
        rows.append({
            "key": key, "value": latest.get("value"),
            "source_act": latest.get("source_act", ""),
            "changed_by": latest.get("changed_by", ""),
            "changed_at": latest.get("changed_at", ""),
            "age_days": age_days,
            "verified": False,   # [NIEZWERYFIKOWANE] — źródła zewnętrzne poza sesją
        })

    stale = [r for r in rows if r.get("age_days", 0) > 365 or r.get("status") == "NO_VERSION"]
    no_source = [r for r in rows if not r.get("source_act")]
    missing_audit = [r for r in rows
                     if not any(a.get("key") == r["key"] for a in audit)]

    checks.append({"name": "freshness_rows",
                   "status": "OK",
                   "detail": f"parametrów w dashboardzie: {len(rows)}"})
    checks.append({"name": "stale_params",
                   "status": "WARN" if not stale else "FAIL",
                   "detail": f"parametry starsze niż rok / bez wersji: {len(stale)}"})
    checks.append({"name": "source_verification",
                   "status": "WARN",
                   "detail": "źródła zewnętrzne [NIEZWERYFIKOWANE] — status verified=False dla "
                             "wszystkich (weryfikacja ISAP/MF/ZUS poza sesją)"})

    if no_source:
        findings.append({"id": "V3-P06-L14", "severity": "P3",
                         "evidence": f"parametry bez source_act: {no_source}",
                         "fix": "wymóg schema v2: source_act + article obowiązkowe"})
    if stale:
        findings.append({"id": "V3-P06-L15", "severity": "P2",
                         "evidence": f"parametry nieświeże: {[r['key'] for r in stale]} "
                                     f"(wiek > 365 dni lub brak wersji)",
                         "fix": "cykl odświeżania wg feedera (I06) + alert P37"})
    findings.append({"id": "V3-P06-L16", "severity": "P3",
                     "evidence": "zerowa weryfikacja źródeł (verified=False) — wszystkie parametry "
                                 "store pochodzą z seedu systemowego",
                     "fix": "rejestr mediacji ISAP/RCL (P06 kontrakt, 9.05) + cykliczny audyt"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I09", "generated_at": now(), "gate": gate,
        "metrics": {"params": len(rows), "stale": len(stale),
                    "no_source": len(no_source), "audit_entries": len(audit)},
        "rows": rows,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P37 (dashboard świeżości — metryki), P08 (Law Radar — źródła), "
                                "P06-I06 (feedery)",
                     "metric_names": ["parameter_count", "parameter_age_max_days",
                                      "parameter_source_verified_pct",
                                      "parameter_feed_freshness_days"]},
    }
    (BUNDLES / "v3_p06_freshness_dashboard.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I09] gate={gate} params={len(rows)} stale={len(stale)} "
          f"no_source={len(no_source)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
