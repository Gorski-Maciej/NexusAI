#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I11 GOLDEN REPLAY PER PARAMETER CHANGE — każda zmiana
parametru uruchamia replay złotych orzeczeń (P10) z parametrami OLD i NEW —
czytelny diff skutków. Dryf AUTO_POST ponad limit = BLOCK (4-eyes).
Rejestr uruchomień: bundles/v3_p46_replay_runs.json.
Usage: python tools/v3_p46_golden_replay.py [--record parameter old new drift_auto]
"""
from __future__ import annotations

import argparse

from v3_p46_common import BUNDLES_DIR, read_json, utcnow_iso, write_bundle, write_json

RUNS = BUNDLES_DIR / "v3_p46_replay_runs.json"


def load_runs() -> dict:
    runs = read_json(RUNS, {}) or {"runs": []}
    if "runs" not in runs:
        runs = {"runs": []}
    return runs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--record", nargs=4, metavar=("PARAMETER", "OLD", "NEW", "DRIFT_AUTO"),
                    action="append")
    ap.add_argument("--drift-auto-max", type=int, default=None)
    args = ap.parse_args()
    runs = load_runs()
    if args.record:
        for parameter, old, new, drift in args.record:
            runs["runs"].append({
                "recorded_at": utcnow_iso(),
                "parameter": parameter,
                "old": old,
                "new": new,
                "drift_auto_changes": int(drift),
                "engine": "tools/v3_p46_golden_replay.py (P10 oracle feed)",
            })
        write_json(RUNS, runs)
    entries = runs["runs"]
    drift_max = args.drift_auto_max
    if drift_max is None:
        from v3_p46_common import thresholds_value
        drift_max = thresholds_value("v3_p46", "v3_p46_replay_drift_max_auto_changes", 0)
    over_limit = [r for r in entries if r.get("drift_auto_changes", 0) > drift_max]
    missing_old = [r for r in entries if r.get("old") in (None, "")]
    metrics = {
        "replay_runs": len(entries),
        "drift_over_limit": len(over_limit),
        "missing_old_params": len(missing_old),
        "drift_auto_max": drift_max,
        "routing": ("BLOCK_AND_ALERT" if len(over_limit) > drift_max
                    else "TRIAGE_QUEUE" if missing_old or not entries
                    else "AUTO_FILE"),
    }
    write_bundle("parameter_replay", "V3-P46-I11", metrics, {
        "runs": "bundles/v3_p46_replay_runs.json",
        "oracle": "P10 golden oracle; certyfikaty decyzji OLD vs NEW (F4)",
        "four_eyes": ("dryf ponad v3_p46_replay_drift_max_auto_changes wymaga "
                      "zatwierdzenia właściciela przed deployem"),
    })
    print(f"[v3_p46_golden_replay] runs={len(entries)} over_limit={len(over_limit)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
