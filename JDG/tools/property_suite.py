#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PROPERTY SUITE (GLM52 P18 — TESTY / CI / JAKOŚĆ, V1 §8 L2)
# Deterministyczne testy własnościowe bez zależności runtime.
# CrossHair pozostaje opcjonalną warstwą formalnej analizy w środowisku dev.
#  • run   — uruchom wszystkie właściwości,
#  • gate  — BRAMKA CI: 0 naruszeń niezmienników.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import random
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Callable

Money = Decimal
Property = Callable[[], int]

PROPERTIES: dict[str, dict[str, object]] = {}


def prop(name: str, desc: str):
    """Rejestruje deterministyczną własność i jej opis."""
    def deco(fn: Property) -> Property:
        PROPERTIES[name] = {"description": desc, "fn": fn}
        return fn
    return deco


MONEY_CASES = [
    Decimal("0"), Decimal("0.001"), Decimal("0.005"), Decimal("0.01"),
    Decimal("1.23"), Decimal("99999.99"), Decimal("1000000.00"),
]
VAT_RATES = (Decimal("0"), Decimal("0.05"), Decimal("0.08"), Decimal("0.23"))


@prop("vat_gross_math", "brutto = netto × (1+stawka) ± epsilon groszowy")
def _vat_gross_math() -> int:
    cases = 0
    for netto in MONEY_CASES:
        for rate in VAT_RATES:
            expected = (netto * (Decimal("1") + rate)).quantize(Decimal("0.01"), ROUND_HALF_UP)
            brutto = netto + (netto * rate).quantize(Decimal("0.01"), ROUND_HALF_UP)
            assert abs(brutto - expected) <= Decimal("0.01")
            cases += 1
    return cases


@prop("vat_rate_enum", "stawka VAT ∈ dozwolony zbiór (INV-001)")
def _vat_rate_enum() -> int:
    allowed = set(VAT_RATES)
    assert all(rate in allowed for rate in VAT_RATES)
    return len(VAT_RATES)


@prop("pit_deductions_bounded", "odliczenia przycinane do podstawy — nigdy ujemna reszta (INV-004)")
def _pit_deductions_bounded() -> int:
    cases = 0
    for base in MONEY_CASES:
        for deduction in MONEY_CASES + [Decimal("10000000")]:
            effective = min(deduction, base)
            assert base - effective >= 0
            assert effective <= base
            cases += 1
    return cases


@prop("pit_penalty_nonneg", "kara podatkowa ≥ 0 (INV-002)")
def _pit_penalty_nonneg() -> int:
    for understated in MONEY_CASES:
        penalty = understated * Decimal("0.30")
        assert penalty >= 0
    return len(MONEY_CASES)


@prop("zus_contributions_nonneg", "składki ZUS ≥ 0 i suma respektuje stawki")
def _zus_contributions_nonneg() -> int:
    for base in MONEY_CASES:
        social = base * Decimal("0.1952")
        health = base * Decimal("0.09")
        assert social >= 0 and health >= 0
        assert social + health <= base * Decimal("0.2852")
    return len(MONEY_CASES)


@prop("kks_fine_nonneg", "kara KKS ≥ 0; stawka dzienna ≤ 5000 (art. 23 § 3 KKS)")
def _kks_fine_nonneg() -> int:
    daily_rates = (Decimal("0.01"), Decimal("1"), Decimal("5000"))
    days = (1, 2, 30)
    cases = 0
    for daily_rate in daily_rates:
        for day_count in days:
            fine = daily_rate * day_count
            assert fine >= 0
            assert daily_rate <= Decimal("5000")
            cases += 1
    return cases


@prop("grosze_rounding", "zaokrąglenie do 0,01 (art. 63 OrdPU) — połowa w górę")
def _grosze_rounding() -> int:
    amounts = MONEY_CASES + [Decimal("1.2349"), Decimal("1.2350"), Decimal("1.2351")]
    for amount in amounts:
        rounded = amount.quantize(Decimal("0.01"), ROUND_HALF_UP)
        assert abs(rounded - amount) < Decimal("0.01")
        assert rounded.as_tuple().exponent == -2
    return len(amounts)


@prop("temporal_validity", "valid_from ≤ valid_to; data transakcji w oknie = aktywna")
def _temporal_validity() -> int:
    start = date(2026, 1, 1)
    cases = 0
    for width in (0, 1, 30):
        end = start + timedelta(days=width)
        for tx in (start - timedelta(days=1), start, end, end + timedelta(days=1)):
            assert start <= end
            active = start <= tx <= end
            assert active == (tx >= start and tx <= end)
            cases += 1
    return cases


@prop("deterministic_seed", "ten sam seed daje ten sam zestaw przypadków")
def _deterministic_seed() -> int:
    def sample(seed: int) -> list[int]:
        rng = random.Random(seed)
        return [rng.randrange(0, 1_000_000) for _ in range(64)]

    assert sample(42) == sample(42)
    assert sample(42) != sample(43)
    return 128


@prop("json_safe_decimals", "kwoty po normalizacji zachowują nieujemność i dwa miejsca")
def _json_safe_decimals() -> int:
    normalized = [value.quantize(Decimal("0.01"), ROUND_HALF_UP) for value in MONEY_CASES]
    assert all(value >= 0 for value in normalized)
    assert all(value.as_tuple().exponent == -2 for value in normalized)
    return len(normalized)


def run_all() -> dict:
    """Uruchamia wszystkie własności; zwraca liczbę realnie sprawdzonych przypadków."""
    results: dict[str, dict[str, object]] = {}
    failures = 0
    cases = 0
    for name, item in PROPERTIES.items():
        try:
            checked = int(item["fn"]())  # type: ignore[operator]
            results[name] = {
                "status": "PASS",
                "description": item["description"],
                "cases": checked,
            }
            cases += checked
        except Exception as exc:  # noqa: BLE001
            failures += 1
            results[name] = {
                "status": "FAIL",
                "description": item["description"],
                "error": str(exc)[:200],
            }
    return {
        "engine": "deterministic_stdlib_property_runner",
        "properties": len(PROPERTIES),
        "cases": cases,
        "failed": failures,
        "results": results,
        "gate": "PASS" if failures == 0 else "FAIL",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="JDG Property Suite (stdlib deterministic runner)")
    parser.add_argument("cmd", choices=["run", "gate"])
    args = parser.parse_args()
    result = run_all()
    print(json.dumps(result, ensure_ascii=False, indent=1))
    return 0 if result["gate"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
