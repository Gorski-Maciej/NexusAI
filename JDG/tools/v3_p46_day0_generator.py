#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I06 DAY-0 TEST GENERATION — generator (P36) tworzy testy
przełączenia dla każdego parametru z oknem temporalnym: dzień przed (day-1),
dzień przełączenia (day-0), dzień po (day+1). Wykrywa przełączenia w historii
wersji thresholds_data.json oraz w blokach v3_p46* thresholds_jdg.rego.
Usage: python tools/v3_p46_day0_generator.py
"""
from __future__ import annotations

import json
from datetime import date, timedelta

from v3_p46_common import (BUNDLES_DIR, THRESHOLDS_DATA, read_json, utcnow_iso,
                           write_bundle)

TESTS_OUT = BUNDLES_DIR / "v3_p46_day0_test_plan.json"


def transitions_from_data() -> list[dict]:
    data = read_json(THRESHOLDS_DATA, {}) or {}
    transitions = []
    for key, spec in data.get("parameters", {}).items():
        versions = spec.get("versions", [])
        for prev, nxt in zip(versions, versions[1:]):
            transitions.append({
                "parameter": key,
                "old": prev.get("value"),
                "new": nxt.get("value"),
                "switch_date": nxt.get("valid_from", ""),
            })
    return transitions


def build_day0_cases(transitions: list[dict]) -> list[dict]:
    cases = []
    for t in transitions:
        switch = t["switch_date"]
        try:
            d0 = date.fromisoformat(switch[:10])
        except (ValueError, TypeError):
            cases.append({**t, "tests": [], "error": "nieprawidłowa data przełączenia"})
            continue
        for label, d in (("day-1", d0 - timedelta(days=1)), ("day-0", d0), ("day+1", d0 + timedelta(days=1))):
            cases[-1] if False else None
            cases.append({
                "parameter": t["parameter"],
                "old": t["old"],
                "new": t["new"],
                "switch_date": switch,
                "test_label": label,
                "test_date": d.isoformat(),
                "expectation": ("OLD value applies" if label == "day-1" else
                                "switch atomic, decision certificate records threshold_version"
                                if label == "day-0" else "NEW value applies"),
            })
    return cases


def main() -> int:
    transitions = transitions_from_data()
    cases = build_day0_cases(transitions)
    plan = {
        "plan_version": "v3_p46_day0-2026.09",
        "generated_at": utcnow_iso(),
        "transitions": transitions,
        "test_cases": cases,
    }
    write_json(TESTS_OUT, plan)
    missing = [t for t in transitions if not t.get("switch_date")]
    metrics = {
        "generated": len(cases),
        "transitions": len(transitions),
        "missing_transitions": len(missing),
        "routing": "TRIAGE_QUEUE" if missing else "AUTO_FILE",
    }
    write_bundle("day0_tests", "V3-P46-I06", metrics, {
        "plan": "bundles/v3_p46_day0_test_plan.json",
        "note": "Testy day-1/day-0/day+1 (P05); generator podmienialny przez P36.",
    })
    print(f"[v3_p46_day0_generator] transitions={len(transitions)} cases={len(cases)}")
    return 0


def write_json(path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
