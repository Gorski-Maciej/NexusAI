#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — TP DOCUMENTATION ENGINE (GLM52 P12)
# Ceny transferowe (art. 23m-23zf PIT — domknięcie „pustyni pokrycia"):
# detektor powiązań (≥25% udział kapitałowy/rodzinny/zarządczy — art. 23m ust. 1
# pkt 4), monitor progów dokumentacyjnych (10M towarowe / 2M usługowe / 2.5M
# finansowe — art. 23zf), zasada ceny rynkowej (art. 23o), TP-R z countdownem
# (6 miesięcy), ryzyko korekty 10% (art. 23zb).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parents[1]


def _load_thresholds() -> dict:
    fallback = {
        "tp_related_party_share_pct": 0.25,
        "tp_goods_transactions_pln": 10000000,
        "tp_services_transactions_pln": 2000000,
        "tp_financial_transactions_pln": 2500000,
        "tp_documentation_months": 6,
        "tp_adjustment_sanction_pct": 0.10,
    }
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return fallback
    text = path.read_text(encoding="utf-8")
    m = re.search(r"crossborder := \{([^}]*)\}", text, re.S)
    if not m:
        return fallback
    body = m.group(1)
    for key in list(fallback.keys()):
        fm = re.search(rf'"{key}"\s*:\s*([\d.]+)', body)
        if fm:
            fallback[key] = float(fm.group(1))
    return fallback


def round2(x: float) -> float:
    return round(x * 100) / 100


def related_party_detector(
    share_pct: float = 0.0,
    family_ties: bool = False,
    management_ties: bool = False,
) -> dict[str, Any]:
    """Detektor powiązań (art. 23m ust. 1 pkt 4 PIT): ≥25% udział lub powiązania."""
    ths = _load_thresholds()
    related = share_pct >= ths["tp_related_party_share_pct"] or family_ties or management_ties
    return {
        "related_party": related,
        "share_pct": share_pct,
        "share_threshold_pct": ths["tp_related_party_share_pct"],
        "family_ties": family_ties,
        "management_ties": management_ties,
        "legal": "Art. 23m ust. 1 pkt 4 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    }


def documentation_threshold_monitor(
    goods_value_pln: float,
    services_value_pln: float,
    financial_value_pln: float,
) -> dict[str, Any]:
    """Monitor progów dokumentacyjnych TP-R (art. 23zf PIT)."""
    ths = _load_thresholds()
    hits = {
        "towarowe": goods_value_pln > ths["tp_goods_transactions_pln"],
        "usługowe": services_value_pln > ths["tp_services_transactions_pln"],
        "finansowe": financial_value_pln > ths["tp_financial_transactions_pln"],
    }
    required = any(hits.values())
    return {
        "documentation_required": required,
        "thresholds_hit": hits,
        "values_pln": {
            "goods": goods_value_pln,
            "services": services_value_pln,
            "financial": financial_value_pln,
        },
        "thresholds_pln": {
            "goods": ths["tp_goods_transactions_pln"],
            "services": ths["tp_services_transactions_pln"],
            "financial": ths["tp_financial_transactions_pln"],
        },
        "legal": "Art. 23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    }


def tpr_countdown(deadline_date: str, today: str = "") -> dict[str, Any]:
    """Countdown do terminu złożenia TP-R / dokumentacji (6 miesięcy)."""
    from datetime import date
    ths = _load_thresholds()
    dl = date.fromisoformat(deadline_date)
    td = date.fromisoformat(today) if today else date.today()
    days_left = (dl - td).days
    return {
        "deadline": deadline_date,
        "days_left": days_left,
        "status": "KRYTYCZNY" if days_left <= 30 else ("ALERT" if days_left <= 90 else "OK"),
        "documentation_months": int(ths["tp_documentation_months"]),
        "legal": "Art. 23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    }


def market_price_benchmark(
    charged_price_pln: float,
    market_price_pln: float,
) -> dict[str, Any]:
    """Zasada ceny rynkowej (art. 23o): rozbieżność >10% → ryzyko korekty 10%."""
    ths = _load_thresholds()
    if market_price_pln <= 0:
        return {"benchmark_valid": False, "error": "brak ceny rynkowej"}
    divergence = abs(charged_price_pln - market_price_pln) / market_price_pln * 100
    adjustment_risk = divergence > 10
    return {
        "benchmark_valid": True,
        "divergence_pct": round2(divergence),
        "adjustment_risk": adjustment_risk,
        "adjustment_sanction_pct": ths["tp_adjustment_sanction_pct"],
        "charged_pln": round2(charged_price_pln),
        "market_pln": round2(market_price_pln),
        "legal": "Art. 23o i 23zb ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    rp = related_party_detector(share_pct=0.30)
    if not rp["related_party"]:
        failures.append("30% udział → powiązany")
    rp2 = related_party_detector(share_pct=0.10)
    if rp2["related_party"]:
        failures.append("10% udział bez innych więzi → NIE powiązany")
    doc = documentation_threshold_monitor(12000000, 0, 0)
    if not doc["documentation_required"]:
        failures.append("12M towarowe → dokumentacja wymagana")
    doc2 = documentation_threshold_monitor(100000, 100000, 100000)
    if doc2["documentation_required"]:
        failures.append("małe transakcje → brak dokumentacji")
    bm = market_price_benchmark(12000, 10000)
    if not bm["adjustment_risk"]:
        failures.append("20% rozbieżność → ryzyko korekty")
    bm_ok = market_price_benchmark(10800, 10000)
    if bm_ok["adjustment_risk"]:
        failures.append("8% rozbieżność → brak ryzyka korekty")
    cd = tpr_countdown("2026-03-01", today="2026-02-20")
    if cd["days_left"] != 9:
        failures.append(f"countdown: oczekiwano 9, jest {cd['days_left']}")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="TP Documentation Engine (GLM52 P12)")
    ap.add_argument("--share", type=float, default=0.0)
    ap.add_argument("--family", action="store_true")
    ap.add_argument("--goods", type=float, default=0.0)
    ap.add_argument("--services", type=float, default=0.0)
    ap.add_argument("--financial", type=float, default=0.0)
    ap.add_argument("--charged", type=float, default=0.0)
    ap.add_argument("--market", type=float, default=0.0)
    ap.add_argument("--deadline", default="")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        failures = self_test()
        if failures:
            print("SELF-TEST: FAIL")
            for f in failures:
                print(f"  ❌ {f}")
            return 1
        print("SELF-TEST: PASS")
        return 0

    out = {
        "related_party": related_party_detector(args.share, args.family),
        "documentation": documentation_threshold_monitor(args.goods, args.services, args.financial),
    }
    if args.charged or args.market:
        out["benchmark"] = market_price_benchmark(args.charged, args.market)
    if args.deadline:
        out["tpr_countdown"] = tpr_countdown(args.deadline)
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
