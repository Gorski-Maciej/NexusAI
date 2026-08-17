#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CBAM MONITOR (GLM52 P12)
# Mechanizm dostosowywania cen na granicach z uwzględnieniem emisji dwutlenku
# węgla (rozporządzenie UE 2023/956): próg rejestracji 150 EUR na przesyłkę,
# raporty kwartalne, certyfikaty CBAM, pełny mechanizm od 2026, kalkulator
# emisji wbudowanych. Spójność z DAC8 (krypto) i ViDA (e-fakturowanie 2030+).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
from datetime import date
from typing import Any

# CBAM: towary objęte (sektory) + stawki emisji wbudowanych (t CO2/t)
CBAM_GOODS = {
    "cement": {"cn_code": "2507", "embedded_emissions_t": 0.86},
    "stal": {"cn_code": "7207", "embedded_emissions_t": 1.89},
    "aluminium": {"cn_code": "7601", "embedded_emissions_t": 16.60},
    "nawozy": {"cn_code": "3102", "embedded_emissions_t": 2.60},
    "elektrycznosc": {"cn_code": "2716", "embedded_emissions_t": 0.65},
    "wodor": {"cn_code": "2804", "embedded_emissions_t": 9.30},
}

CBAM_PRICE_PER_TONNE = 90.0  # EUR/t CO2 (orientacyjna cena ETS 2026)


def round2(x: float) -> float:
    return round(x * 100) / 100


def monitor(
    goods_category: str,
    shipment_value_eur: float,
    quantity_t: float,
    importer_registered: bool = False,
) -> dict[str, Any]:
    """Monitor CBAM: próg 150 EUR, rejestracja, certyfikat, pełny mechanizm 2026."""
    info = CBAM_GOODS.get(goods_category)
    if not info:
        return {"valid_category": False, "error": f"nieznana kategoria: {goods_category}"}

    under_threshold = shipment_value_eur <= 150.0
    embedded = round2(quantity_t * info["embedded_emissions_t"])
    cbam_cost = round2(embedded * CBAM_PRICE_PER_TONNE)

    return {
        "valid_category": True,
        "category": goods_category,
        "cn_code": info["cn_code"],
        "shipment_value_eur": round2(shipment_value_eur),
        "threshold_eur": 150.0,
        "under_threshold": under_threshold,          # przesyłki ≤150 EUR wyłączone
        "importer_registered": importer_registered,
        "registration_required": (not under_threshold) and (not importer_registered),
        "embedded_emissions_t": embedded,
        "cbam_estimated_cost_eur": cbam_cost,
        "full_mechanism_2026": True,                  # od 1.01.2026 pełny mechanizm
        "quarterly_report_due": (not under_threshold) and importer_registered,
        "certificate_required": (not under_threshold),
        "legal": "rozporządzenie Parlamentu Europejskiego i Rady (UE) 2023/956 z dnia 10 maja 2023 r. ustanawiające mechanizm dostosowywania cen na granicach z uwzględnieniem emisji dwutlenku węgla (CBAM)",
    }


def quarter_report_calendar(year: int = 2026) -> dict[str, Any]:
    """Terminy raportów kwartalnych CBAM (koniec miesiąca po kwartale)."""
    quarters = {
        "Q1": f"{year}-04-30",
        "Q2": f"{year}-07-31",
        "Q3": f"{year}-10-31",
        "Q4": f"{year + 1}-01-31",
    }
    return {
        "year": year,
        "quarterly_deadlines": quarters,
        "legal": "art. 35 rozporządzenia (UE) 2023/956 (CBAM)",
    }


def dac8_tracker(crypto_transactions: int, threshold: int = 50000) -> dict[str, Any]:
    """Tracker DAC8: kryptoaktywa — raportowanie od 2026 (progi transakcji)."""
    return {
        "crypto_transactions": crypto_transactions,
        "reporting_threshold": threshold,
        "dac8_reporting_due": crypto_transactions > threshold,
        "reporting_start": "2026-01-01",
        "legal": "dyrektywa Rady (UE) 2023/2226 z dnia 17 października 2023 r. (DAC8) — kryptoaktywa",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    m = monitor("stal", 5000, 10.0, importer_registered=True)
    if m["under_threshold"]:
        failures.append("5000 EUR > 150 → nie poniżej progu")
    if not m["quarterly_report_due"]:
        failures.append("zarejestrowany importer powyżej progu → raport kwartalny")
    if m["embedded_emissions_t"] != round2(10 * 1.89):
        failures.append("10 t stali × 1.89 = 18.9 t CO2")
    m2 = monitor("stal", 100, 1.0)
    if not m2["under_threshold"]:
        failures.append("100 EUR ≤ 150 → poniżej progu (wyłączone)")
    cal = quarter_report_calendar()
    if cal["quarterly_deadlines"]["Q1"] != "2026-04-30":
        failures.append("Q1 deadline 2026-04-30")
    d = dac8_tracker(60000)
    if not d["dac8_reporting_due"]:
        failures.append("60k transakcji krypto > 50k → raportowanie DAC8")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="CBAM Monitor (GLM52 P12)")
    ap.add_argument("--category", default="stal", choices=sorted(CBAM_GOODS))
    ap.add_argument("--value", type=float, default=5000.0)
    ap.add_argument("--quantity", type=float, default=10.0)
    ap.add_argument("--registered", action="store_true")
    ap.add_argument("--calendar", action="store_true")
    ap.add_argument("--dac8", type=int, default=0)
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

    if args.calendar:
        print(json.dumps(quarter_report_calendar(), ensure_ascii=False, indent=2))
    elif args.dac8:
        print(json.dumps(dac8_tracker(args.dac8), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(monitor(args.category, args.value, args.quantity, args.registered),
                         ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
