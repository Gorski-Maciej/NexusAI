#!/usr/bin/env python3
"""NexusAI JDG — SCORING TELEMETRY (V3-P03-I08)
================================================
Pełna telemetria scoringu pewności — rozkłady klas pewności z alarmami dryfu
(P03-AN05). Spina: klasy CERTAIN/CONDITIONAL/NEEDS_ADVICE (I02), rejestr
metryk P02-I08, dashboard PEWNOSC (LCI/RV/TCL).

  • rozkład klas: CERTAIN / CONDITIONAL / NEEDS_ADVICE (% i liczby);
  • alarmy: NEEDS_ADVICE > próg (fail-closed), CONDITIONAL+NEEDS_ADVICE > próg,
    CERTAIN spada poniżej progu minimalnego;
  • metryki do obserwowalności (P37): nazwy wiążące z P02-I08.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_scoring_telemetry.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def build() -> dict:
    # Rozkład klas z próbki werdyktów reprezentatywnych (model, nie runtime).
    distribution = {
        "CERTAIN": 620,
        "CONDITIONAL": 180,
        "NEEDS_ADVICE": 200,
    }
    total = sum(distribution.values())
    pct = {k: round(v / total * 100, 2) for k, v in distribution.items()}

    alarms = []
    # Alarm 1: NEEDS_ADVICE > próg 15% (fail-closed wymaga weryfikacji).
    if pct["NEEDS_ADVICE"] > 15.0:
        alarms.append({
            "metric": "jdg_verdict_needs_advice_pct",
            "value": pct["NEEDS_ADVICE"], "threshold": 15.0,
            "severity": "ALERT",
            "message": "udział NEEDS_ADVICE powyżej progu — sprawdź dryf pokrycia reguł",
        })
    # Alarm 2: CONDITIONAL+NEEDS_ADVICE > 40%.
    combined = pct["CONDITIONAL"] + pct["NEEDS_ADVICE"]
    if combined > 40.0:
        alarms.append({
            "metric": "jdg_verdict_non_certain_pct",
            "value": combined, "threshold": 40.0,
            "severity": "WARNING",
            "message": "ponad 40% werdyktów wymaga uwagi człowieka — cel V2: spadek kwartalny",
        })
    # Alarm 3: CERTAIN < 50%.
    if pct["CERTAIN"] < 50.0:
        alarms.append({
            "metric": "jdg_verdict_certain_pct",
            "value": pct["CERTAIN"], "threshold": 50.0,
            "severity": "ALERT",
            "message": "CERTAIN poniżej 50% — automatyzacja księgowania zagrożona",
        })

    return {
        "innovation": "V3-P03-I08",
        "name": "Scoring Telemetry — rozkłady klas pewności + alarmy dryfu",
        "generated_at": now(),
        "distribution": distribution,
        "percent": pct,
        "total_verdicts": total,
        "alarms": alarms,
        "alarm_count": len(alarms),
        "metrics_to_p37": [
            {"name": "jdg_verdict_certain_pct", "type": "gauge", "threshold": ">= 50%"},
            {"name": "jdg_verdict_needs_advice_pct", "type": "gauge", "threshold": "<= 15%"},
            {"name": "jdg_verdict_non_certain_pct", "type": "gauge", "threshold": "<= 40%"},
            {"name": "jdg_verdict_certain_class_total", "type": "counter", "tags": ["certainty_class", "package"]},
        ],
        "gate": {
            "pass": len(alarms) == 0,
            "rule": "alarmy dryfu klas pewności (P03-AN05): NEEDS_ADVICE<=15%, "
                    "non-certain<=40%, CERTAIN>=50%; przekroczenie = alert do P37",
        },
        "note": "Rozkład MODELOWY (próbka reprezentatywna do demonstracji mechanizmu "
                "alarmów — nie pomiar runtime); wartości runtime z P37. Alarm=1 pokazuje "
                "mechanizm: NEEDS_ADVICE 20% > próg 15%. Dashboard PEWNOSC pokazuje "
                "CERTAIN=0.0% dla certyfikatów F4 — rozbieżność definicji do uzgodnienia "
                "(Q04). Bramka FAIL = dokumentacja progu, nie błąd implementacji.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Scoring Telemetry (V3-P03-I08)")
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
        print(f"V3-P03-I08 Scoring Telemetry: alarmy={data['alarm_count']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: dryf rozkładu klas pewności — alert do P37")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())