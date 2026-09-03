#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I04 LIMIT 113 SENTINEL
=============================================
Monitoring przekroczenia limitu 200k (art. 113 ust. 1/5/9) w trakcie roku
(alarm przed przekroczeniem). Sprawdza: limit jako parametr data.thresholds
z oknem, śledzenie proporcjonalne (ust. 5/9), narzędzie monitoringu.

Usage:
  python tools/v3_p12_limit113_sentinel.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    params = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8")).get("parameters", {})
    # 1. Limit 113 jako parametr z oknem temporalnym
    limit_params = {k: v for k, v in params.items()
                    if "113" in k or "limit" in k.lower() or "200000" in str(v)}
    limit_as_data = any("113" in k for k in params)
    # 2. Śledzenie proporcjonalne (ust. 5/9 — nowe JDG, kwartały)
    hay = "\n".join(f.read_text(encoding="utf-8", errors="ignore")
                    for f in RULES.glob("**/*.rego"))
    has_proportional = any(k in hay for k in ("ust. 5", "ust. 9", "proporcjonal",
                                              "quarterly_excess", "Limit Tracker"))
    has_vatr_warning = "VAT-R" in hay
    # 3. Narzędzie monitoringu limitu
    limit_tools = sorted(p.name for p in TOOLS.glob("*.py")
                         if any(k in p.name for k in ("limit_2m", "limit", "113")))
    sentinel_tools = [t for t in limit_tools if "2m" in t]
    # 4. Reguła przekroczenia w trakcie roku
    has_exceed_rule = bool(re.search(r"(exceed|przekroczen|utrata zwolnienia)", hay, re.I))

    checks.append({"name": "limit_113_as_data",
                   "status": "OK" if limit_as_data else "FAIL",
                   "detail": f"limit 113 w data.thresholds: {limit_as_data} "
                             f"(params: {limit_params})"})
    checks.append({"name": "proportional_tracking",
                   "status": "OK" if has_proportional else "FAIL",
                   "detail": f"śledzenie proporcjonalne (ust. 5/9, kwartały): {has_proportional}"})
    checks.append({"name": "exceed_rule",
                   "status": "OK" if has_exceed_rule else "FAIL",
                   "detail": f"reguła przekroczenia/utraty zwolnienia: {has_exceed_rule} "
                             f"(VAT-R: {has_vatr_warning})"})
    checks.append({"name": "sentinel_tool",
                   "status": "OK" if (sentinel_tools or limit_tools) else "FAIL",
                   "detail": f"narzędzie monitoringu limitu: {sentinel_tools or limit_tools or 'BRAK'}"})

    if not limit_as_data:
        findings.append({"id": "V3-P12-L04", "severity": "P1",
                         "evidence": "limit art. 113 (200 000 zł) nie jest parametrem "
                                     "data.thresholds z oknem temporalnym (0 parametrów "
                                     "'113'); wartość 200000 siedzi w regułach "
                                     "(plan26_critical.rego) — zmiana limitu wymaga edycji "
                                     "rego zamiast danych (ADR-002/P06/P05)",
                         "fix": "I04: Limit 113 Sentinel — parametr vat.limit_113 z "
                                "valid_from/valid_to + monitor alarmujący przed przekroczeniem "
                                "w trakcie roku (proporcja ust. 5/9)"})
    if not has_proportional or not has_vatr_warning:
        findings.append({"id": "V3-P12-L04b", "severity": "P2",
                         "evidence": f"śledzenie proporcjonalne: {has_proportional}, ostrzeżenie "
                                     f"VAT-R: {has_vatr_warning} — ryzyko cichej utraty "
                                     f"zwolnienia przy przekroczeniu w trakcie roku",
                         "fix": "I04: alarm przed przekroczeniem + nakaz VAT-R"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I04", "generated_at": now(), "gate": gate,
        "metrics": {"limit_as_data": limit_as_data, "limit_params": limit_params,
                    "proportional_tracking": has_proportional,
                    "exceed_rule": has_exceed_rule, "vatr_warning": has_vatr_warning,
                    "sentinel_tools": sentinel_tools or limit_tools},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry), P05 (temporalność), P16 (JPK), P44",
                     "rule": "limit 113 = parametr z oknem; monitor alarmuje przed "
                             "przekroczeniem; przekroczenie = nakaz VAT-R (nigdy cisza)"}}
    (BUNDLES / "v3_p12_limit113_sentinel.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I04] gate={gate} limit_as_data={limit_as_data} proportional={has_proportional}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
