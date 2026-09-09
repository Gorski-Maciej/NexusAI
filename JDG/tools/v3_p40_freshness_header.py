#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I08 FRESHNESS HEADER — każda odpowiedź z
X-Legal-Freshness (data ostatniej weryfikacji ISAP dla domeny) — przejrzystość
ryzyka; spójna z radarem P34 i SLA świeżości P37. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p40_common import emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P40-I08"
RULE = "jdg.v3_p40_api_dane_ui.freshness_header"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p40_freshness_sla_max_days")
    checks.append({"name": "freshness_sla_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p40_freshness_sla_max_days w data.thresholds: {t}"})

    # Radar P34 — źródło daty ostatniej weryfikacji ISAP
    radar = __import__("v3_p40_common").TOOLS / "law_radar.py"
    radar_ok = radar.exists()
    checks.append({"name": "law_radar_source_exists", "status": "OK" if radar_ok else "FAIL",
                   "detail": f"tools/law_radar.py (P34): {radar_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "freshness_sla_as_data": t,
            "law_radar_source_exists": radar_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_freshness_header")


if __name__ == "__main__":
    raise SystemExit(main())
