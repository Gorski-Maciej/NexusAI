#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PROMPT 06 — zus_law_radar.py
# Law Radar ZUS: monitor ISAP/RCL dla ustawy o SUS i ustawy o świadczeniach
# opieki zdrowotnej. Wykrywa nowelizacje wpływające na stawki, progi, limity.
# Poziom ENTERPRISE: proaktywne alerty przed wejściem zmian w życie.
# ═══════════════════════════════════════════════════════════════════════════════
"""Monitor zmian prawa ZUS — SUS + u.ś.o.z."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date, timedelta
from typing import Any

# Akty prawne do monitorowania
MONITORED_ACTS: list[dict[str, Any]] = [
    {
        "act_id": "SUS",
        "title": "Ustawa o systemie ubezpieczeń społecznych",
        "dz_u": "Dz.U. 2025 poz. 345 ze zm.",
        "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19981370887",
        "key_articles": [6, 9, 18, 19, 22, 30, 36, 47],
        "thresholds_affected": [
            "zus_social_base_percent",
            "zus_pension_rate",
            "zus_disability_rate",
            "zus_sickness_rate",
            "zus_accident_rate",
            "zus_labour_fund_rate",
            "zus_annual_base_cap_multiplier",
        ],
    },
    {
        "act_id": "U_S_O_Z",
        "title": "Ustawa o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych",
        "dz_u": "Dz.U. 2025 poz. 890",
        "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU20042102135",
        "key_articles": [66, 79, 80, 81, 82],
        "thresholds_affected": [
            "health_scale_rate",
            "health_linear_rate",
            "health_linear_deduction_limit",
            "health_lump_tier_1_limit",
            "health_lump_tier_2_limit",
            "health_tax_card_rate",
        ],
    },
    {
        "act_id": "USTAWA_ZASILKOWA",
        "title": "Ustawa o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
        "dz_u": "Dz.U. 2025 poz. 1234",
        "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19990600636",
        "key_articles": [4, 6, 7, 8, 9, 11, 18, 29, 30, 31, 32, 33, 34, 35, 48],
        "thresholds_affected": [
            "sickness_benefit_rate_80",
            "sickness_benefit_rate_100",
            "maternity_weeks",
            "rehab_rate_90",
            "rehab_rate_75",
            "sickness_waiting_days",
            "sickness_annual_limit",
        ],
    },
]

def scan_for_changes() -> dict[str, Any]:
    """Skanuje akty prawne pod kątem potencjalnych zmian.

    W wersji produkcyjnej: integruje się z isap_crawler.py i AI-Reader.
    W wersji deweloperskiej: zwraca struktury do monitorowania.
    """
    monitored_rules = []
    for act in MONITORED_ACTS:
        for art in act["key_articles"]:
            monitored_rules.append({
                "act_id": act["act_id"],
                "article": art,
                "thresholds": act["thresholds_affected"],
                "last_checked": date.today().isoformat(),
                "status": "MONITORED",
            })

    return {
        "tool": "zus_law_radar",
        "generated_at": date.today().isoformat(),
        "monitored_acts": len(MONITORED_ACTS),
        "monitored_articles": len(monitored_rules),
        "thresholds_watched": sum(
            len(act["thresholds_affected"]) for act in MONITORED_ACTS
        ),
        "acts": [
            {
                "act_id": act["act_id"],
                "title": act["title"],
                "dz_u": act["dz_u"],
                "key_articles": act["key_articles"],
                "thresholds_count": len(act["thresholds_affected"]),
            }
            for act in MONITORED_ACTS
        ],
        "change_feed": [],  # W produkcji: lista wykrytych zmian
        "alerts": [],
    }


def impact_analysis(article_changed: int, act_id: str) -> dict[str, Any]:
    """Analiza wpływu zmiany artykułu na reguły ZUS."""
    # Mapowanie artykułów na pliki reguł
    impact_map = {
        "SUS": {
            6: ["JDG/rules/zus.rego"],
            9: ["JDG/rules/zus.rego", "JDG/rules/zus/plan23_interactions.rego"],
            18: ["JDG/rules/zus.rego", "JDG/rules/zus/plan42_benefits.rego"],
            19: ["JDG/rules/zus/zus_enterprise_zero_doubt.rego"],
            22: ["JDG/rules/zus.rego", "JDG/rules/zus/plan42_benefits.rego"],
            30: ["JDG/rules/zus/zus_enterprise_zero_doubt.rego"],
            36: ["JDG/rules/zus.rego"],
            47: ["JDG/rules/zus.rego", "JDG/rules/zus/plan23_interactions.rego"],
        },
        "U_S_O_Z": {
            66: ["JDG/rules/zus/plan23_interactions.rego"],
            79: ["JDG/rules/zus.rego"],
            80: ["JDG/rules/zus.rego"],
            81: [
                "JDG/rules/zus.rego",
                "JDG/rules/zus/health_contribution_enterprise.rego",
                "JDG/rules/zus/health_precision_engine_v8.rego",
                "JDG/rules/zus/cumulative_revenue_engine.rego",
            ],
            82: ["JDG/rules/zus/health_precision_engine_v8.rego"],
        },
        "USTAWA_ZASILKOWA": {
            4: [
                "JDG/rules/zus.rego",
                "JDG/rules/zus/sickness_benefits_enterprise.rego",
            ],
            9: ["JDG/rules/zus.rego"],
            11: ["JDG/rules/zus.rego"],
            18: ["JDG/rules/zus.rego"],
            29: ["JDG/rules/zus.rego", "JDG/rules/zus/enterprise_benefits.rego"],
        },
    }

    affected = impact_map.get(act_id, {}).get(article_changed, [])

    return {
        "article": article_changed,
        "act_id": act_id,
        "affected_files": affected,
        "affected_rules_estimate": len(affected) * 5,  # ~5 reguł per plik
        "priority": "P0" if article_changed in (22, 81) else "P1",
        "sla_hours": 4 if article_changed in (22, 81) else 24,
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="NexusAI JDG — ZUS Law Radar (monitor SUS + u.ś.o.z.)"
    )
    p.add_argument("--scan", action="store_true", help="Skanuj akty prawne")
    p.add_argument(
        "--impact",
        type=int,
        default=0,
        help="Analiza wpływu zmiany artykułu (podaj numer art.)",
    )
    p.add_argument(
        "--act",
        choices=["SUS", "U_S_O_Z", "USTAWA_ZASILKOWA"],
        default="SUS",
        help="Akt prawny do analizy",
    )
    p.add_argument("--json", action="store_true")
    args = p.parse_args(argv)

    result: dict[str, Any] = {"tool": "zus_law_radar", "generated_at": date.today().isoformat()}

    if args.scan:
        result["scan"] = scan_for_changes()

    if args.impact > 0:
        result["impact"] = impact_analysis(args.impact, args.act)

    if not (args.scan or args.impact > 0):
        result["scan"] = scan_for_changes()

    if args.json or True:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())