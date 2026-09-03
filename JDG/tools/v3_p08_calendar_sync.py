#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I06 LEGAL CHANGE CALENDAR SYNC
====================================================
Kalendarz zmian z alertami N-dni i integracją z lifecycle (P07) i bundle (P38):
każda zmiana prawa ma wpis kalendarza, powiązane reguły SHADOW oraz
powiadomienie N dni przed wejściem.

Usage:
  python tools/v3_p08_calendar_sync.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

ALERT_NDAYS = [90, 30, 14, 7]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    cal = json.loads((BUNDLES / "legal_change_calendar.json").read_text(encoding="utf-8"))
    cal_src = (TOOLS / "legal_change_calendar.py").read_text(encoding="utf-8")
    changes = cal.get("changes", {})

    has_alert = "alert" in cal_src
    has_nday = any(str(n) in cal_src for n in ALERT_NDAYS)
    prepared = sum(1 for ch in changes.values() if ch.get("rules_prepared"))

    checks.append({"name": "calendar_entries", "status": "OK" if changes else "FAIL",
                   "detail": f"zmiany w kalendarzu: {len(changes)}"})
    checks.append({"name": "nday_alerts", "status": "OK" if (has_alert and has_nday) else "FAIL",
                   "detail": f"alerty N-dni ({ALERT_NDAYS}) w legal_change_calendar.py: "
                             f"alert={has_alert}"})
    checks.append({"name": "lifecycle_sync", "status": "FAIL" if prepared == 0 else "OK",
                   "detail": f"zmiany z przygotowanymi regułami SHADOW: {prepared}/{len(changes)}"
                             " — brak integracji z P07"})

    findings.append({"id": "V3-P08-L06", "severity": "P2",
                     "evidence": "legal_change_calendar.json zawiera 1 zmianę demo (DRL-0001, "
                                 "2099) z rules_prepared=[] — kalendarz nie jest zasilany "
                                 "realnymi zmianami ani nie ostrzega N-dni przed wejściem; "
                                 f"alerty N-dni: {has_alert and has_nday}",
                     "fix": "I06 Legal Change Calendar Sync: sync z radar (każdy ENACTED → "
                            "wpis kalendarza), alerty 90/30/14/7, status reguł SHADOW per wpis"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I06", "generated_at": now(), "gate": gate,
        "metrics": {"changes": len(changes), "with_prepared_rules": prepared,
                    "alert_ndays": ALERT_NDAYS, "nday_alerts_impl": has_alert and has_nday},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07 (status lifecycle per zmiana), P38 (bundle per zmiana), "
                                "P37 (metryki lead)",
                     "rule": "ENACTED w radarze → wpis kalendarza tego samego dnia; "
                             "countdown < 90 → alert; reguły SHADOW wymagane ≥ 30 dni przed"},
    }
    (BUNDLES / "v3_p08_calendar_sync.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I06] gate={gate} changes={len(changes)} prepared={prepared}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
