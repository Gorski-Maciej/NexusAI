#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I09 PARAMETER DRIFT ALARM — porównanie wartości w
thresholds_data.json z wartościami wytropionymi w ISAP (crawler P34). Rozjazd
niezaraportowany = BLOCK; zaraportowany = TRIAGE do Law Radar (P08). Zero
wartości „z pamięci": weryfikacja tylko z rejestru tropienia.
Usage: python tools/v3_p46_drift_alarm.py
"""
from __future__ import annotations

from v3_p46_common import BUNDLES_DIR, read_json, write_bundle

ISAP_TRACKER = BUNDLES_DIR / "v3_p46_isap_drift_tracker.json"


def main() -> int:
    tracker = read_json(ISAP_TRACKER, {}) or {"tracked": [], "reports": []}
    data = read_json(BUNDLES_DIR / "thresholds_data.json", {}) or {}
    tracked = {t["parameter"]: t for t in tracker.get("tracked", [])}
    unreported = []
    reported = []
    for key, spec in data.get("parameters", {}).items():
        versions = spec.get("versions", [])
        current = versions[-1].get("value") if versions else None
        if key in tracked:
            t = tracked[key]
            if t.get("isap_value") is not None and t["isap_value"] != current:
                entry = {"parameter": key, "data_value": current,
                         "isap_value": t["isap_value"],
                         "reported": bool(t.get("reported_to_law_radar")),
                         "report": t.get("report_id", "")}
                (reported if entry["reported"] else unreported).append(entry)
    metrics = {
        "tracked_parameters": len(tracked),
        "unreported_drifts": len(unreported),
        "reported_drifts": len(reported),
        "routing": ("BLOCK_AND_ALERT" if unreported
                    else "TRIAGE_QUEUE" if reported else "AUTO_FILE"),
    }
    write_bundle("drift_alarm", "V3-P46-I09", metrics, {
        "tracker": "bundles/v3_p46_isap_drift_tracker.json",
        "unreported": unreported,
        "reported": reported,
        "note": "Law Radar (P08) przyjmuje zgłoszenie dryfu z twardym dowodem diff.",
    })
    print(f"[v3_p46_drift_alarm] unreported={len(unreported)} reported={len(reported)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
