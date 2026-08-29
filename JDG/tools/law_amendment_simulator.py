#!/usr/bin/env python3
"""
NexusAI JDG — LAW AMENDMENT SIMULATOR (PROMPT 21 CONTROL PLANE, V2 F5 §6.3)
==========================================================================
Symulator nowelizacji — „co gdyby prawo weszło wczoraj\". Przepisuje scenariusz
zmiany prawa na projekcję werdyktów: przyjmuje proponowany diff prawny
(artykuł → nowa stawka/próg/limit), wybiera wersję temporalną reguł i
wylicza, które reguły zmienią werdykt i ile transakcji ulegnie zmianie.

To narzędzie ANALITYCZNE (shadow): nigdy nie modyfikuje reguł ani danych.
Wynik to plan wdrożenia (rules_affected + impact pct) dla F6 declarative_change.

  • simulate — symulacja zmiany prawa na podstawie diffa + bazy werdyktów,
  • report   — raport ostatnich symulacji (append-only log).

Usage:
  python law_amendment_simulator.py simulate \
      --title "Podniesienie limitu zwolnienia VAT" \
      --rule-id jdg.vat.exemption.limit_200k \
      --field limit_amount --old-value 200000 --new-value 240000 \
      --verdicts verdicts.json
  python law_amendment_simulator.py report
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
SIM_LOG = JDG_ROOT / "bundles" / "amendment_simulations.json"
VERDICTS_DEFAULT = JDG_ROOT / "bundles" / "golden_verdicts.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _load() -> dict:
    if SIM_LOG.exists():
        return json.loads(SIM_LOG.read_text(encoding="utf-8"))
    return {"schema_version": "1.0.0", "simulations": []}


def _save(data: dict) -> None:
    SIM_LOG.parent.mkdir(parents=True, exist_ok=True)
    SIM_LOG.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _load_verdicts(path: Path) -> list[dict]:
    if not path.exists():
        return []
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, dict):
        verdicts = raw.get("verdicts", [])
        if isinstance(verdicts, dict):
            return [v.get("verdict", v) for v in verdicts.values()]
        return list(verdicts) if isinstance(verdicts, list) else []
    return raw if isinstance(raw, list) else []


def _extract_numeric(verdict: dict, field: str):
    """Odczyt wartości z werdyktu: pola płaskie lub _decisions[].<field>."""
    if field in verdict:
        return verdict.get(field)
    for decision in (verdict.get("_decisions") or []):
        if isinstance(decision, dict) and field in decision:
            return decision.get(field)
    return None


def simulate(title: str, rule_id: str, field: str, old_value: float,
             new_value: float, verdicts: list[dict]) -> dict:
    affected = []
    for v in verdicts:
        if not isinstance(v, dict):
            continue
        current = _extract_numeric(v, field)
        if current is None:
            continue
        # reguła dotyczy werdyktu tylko gdy rule_id się zgadza albo pasuje domena
        matched = v.get("rule_id") == rule_id
        if not matched:
            continue
        # „co gdyby prawo weszło wczoraj": werdykt zapisany pod starą wartością
        # parametru (różną od nowej) podlega ponownej ewaluacji po nowelizacji.
        changed = abs(current - new_value) > 1e-9
        affected.append({
            "rule_id": v.get("rule_id"),
            "input_hash": v.get("input_hash") or v.get("_input_hash"),
            "field": field,
            "current_value": current,
            "would_change": changed,
            "verdict_hash": v.get("verdict_hash") or v.get("_verdict_hash"),
        })
    impacted = [a for a in affected if a["would_change"]]
    total = len(affected)
    impact_pct = round(len(impacted) / total * 100, 2) if total else 0.0
    return {
        "simulation_id": f"SIM-{len(_load()['simulations']) + 1:04d}",
        "title": title,
        "rule_id": rule_id,
        "field": field,
        "old_value": old_value,
        "new_value": new_value,
        "verdicts_scanned": len(verdicts),
        "verdicts_matching_rule": total,
        "verdicts_impacted": len(impacted),
        "impact_pct": impact_pct,
        "affected": impacted[:50],
        "mode": "SHADOW_ANALYSIS_ONLY",
        "simulated_at": now(),
        "recommendation": "WDRÓŻ PRZEZ F6 declarative_change z bramkami "
                          "(LEGAL_SOURCE → IMPACT → GOLDEN_REPLAY → TESTS → FOUR_EYES → ROLLOUT)",
    }


def cmd_simulate(args) -> None:
    verdicts = _load_verdicts(Path(args.verdicts) if args.verdicts else VERDICTS_DEFAULT)
    result = simulate(args.title, args.rule_id, args.field,
                      float(args.old_value), float(args.new_value), verdicts)
    data = _load()
    data["simulations"].append(result)
    _save(data)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if result["impact_pct"] > 50:
        print("⚠️  Wpływ > 50% transakcji — wymagana pełna bramka golden replay przed wdrożeniem")


def cmd_report(args) -> None:
    data = _load()
    print(json.dumps({"simulations": len(data["simulations"]),
                      "recent": [
                          {"simulation_id": s["simulation_id"], "title": s["title"],
                           "impact_pct": s["impact_pct"],
                           "verdicts_impacted": s["verdicts_impacted"]}
                          for s in data["simulations"][-10:]],
                      "mode": "SHADOW_ANALYSIS_ONLY"},
                     indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Law Amendment Simulator — V2 F5 §6.3")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("simulate")
    s.add_argument("--title", required=True)
    s.add_argument("--rule-id", required=True)
    s.add_argument("--field", required=True)
    s.add_argument("--old-value", required=True)
    s.add_argument("--new-value", required=True)
    s.add_argument("--verdicts", default=None)
    s.set_defaults(fn=cmd_simulate)
    r = sub.add_parser("report"); r.set_defaults(fn=cmd_report)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
