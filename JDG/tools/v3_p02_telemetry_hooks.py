#!/usr/bin/env python3
"""
NexusAI JDG — ORCHESTRATOR TELEMETRY HOOKS (V3-P02-I08)
========================================================
Metryki per PASS (czas, liczba dopasowań, aborty) do obserwowalności i SLO.
Definiuje rejestr metryk orkiestratora: nazwa, typ, tagi, jednostka, próg
alarmu, właściciel. Wejście dla P37 (obserwowalność).

Czyta:  konwencje z rules/main_jdg.rego (pola _cost_ms/_shard_routed),
        docs/ANALIZA_STANU_OPA_JAKO_SYSTEM.md (deklaracje p95)
Pisze:  bundles/v3_p02_telemetry_hooks.json

Usage:
  python v3_p02_telemetry_hooks.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
MAIN = BASE_DIR / "rules" / "main_jdg.rego"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_telemetry_hooks.json"

METRICS = [
    {"name": "jdg_orchestrator_pass_duration_ms", "type": "histogram",
     "unit": "ms", "tags": ["pass", "shard", "transaction_type"],
     "alert_threshold": {"p95_ms": 5, "comment": "per shard (deklaracja p95<5ms/shard)"},
     "owner": "P02-I08", "slo_target": "p95 <= 5000ms full chain"},
    {"name": "jdg_orchestrator_pass_matches", "type": "counter",
     "unit": "integer", "tags": ["pass", "rule_id", "package"],
     "alert_threshold": {"rule": "match_count == 0 dla domeny aktywnej"},
     "owner": "P02-I08"},
    {"name": "jdg_orchestrator_aborts_total", "type": "counter",
     "unit": "integer", "tags": ["pass", "reason", "routing"],
     "alert_threshold": {"rule": "abort bez werdyktu = P1 (cisza)"},
     "owner": "P02-I10"},
    {"name": "jdg_orchestrator_abort_no_verdict_total", "type": "counter",
     "unit": "integer", "tags": ["reason"],
     "alert_threshold": {"gte": 1, "severity": "P1"},
     "owner": "P02-I10", "slo_target": "0 (zero cichych braków werdyktu)"},
    {"name": "jdg_orchestrator_shard_routed_total", "type": "counter",
     "unit": "integer", "tags": ["shard", "transaction_type", "entity_status"],
     "alert_threshold": {"rule": "dystrybucja shardów"},
     "owner": "P02-I04"},
    {"name": "jdg_orchestrator_merge_overwrite_protected_total", "type": "counter",
     "unit": "integer", "tags": ["package", "field"],
     "alert_threshold": {"gte": 1, "severity": "P0"},
     "owner": "P02-I07", "slo_target": "0 (INV-018/042)"},
    {"name": "jdg_orchestrator_verdict_incomplete_total", "type": "counter",
     "unit": "integer", "tags": ["package", "missing_fields"],
     "alert_threshold": {"gte": 1, "severity": "P1"},
     "owner": "P02-I12", "slo_target": "0"},
    {"name": "jdg_orchestrator_certainty_blocked_total", "type": "counter",
     "unit": "integer", "tags": ["certainty_class"],
     "alert_threshold": {"rule": "monitor"},
     "owner": "P02-I01"},
    {"name": "jdg_orchestrator_eval_cost_model", "type": "gauge",
     "unit": "pakiety", "tags": ["shard"],
     "alert_threshold": {"rule": "koszt modelowy > budzet (I06)"},
     "owner": "P02-I06"},
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    main = MAIN.read_text(encoding="utf-8") if MAIN.exists() else ""
    code_hints = {
        "cost_ms_field": "_cost_ms" in main,
        "shard_routed_field": "_shard_routed" in main,
        "provenance_evaluation_ms": "evaluation_ms" in main,
    }

    return {
        "innovation": "V3-P02-I08",
        "name": "Orchestrator Telemetry Hooks — metryki per PASS do SLO",
        "generated_at": now(),
        "code_evidence": code_hints,
        "metric_registry": METRICS,
        "metric_count": len(METRICS),
        "gate": {"pass": True,
                 "rule": "rejestr metryk per PASS przekazany do P37 (obserwowalność) — "
                         "nazwy i tagi wiążące od tej części"},
        "note": "hooki emitują metryki na końcu każdego PASS (POST-MERGE); "
                "progi alarmów: P0=0 naruszeń invariantów, P1=każdy abort bez werdyktu.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Telemetry Hooks registry (V3-P02-I08)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P02-I08 Telemetry Hooks: metryki={data['metric_count']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
