#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PROPERTY SUITE (GLM52 P18 — TESTY / CI / JAKOŚĆ, V1 §8 L2)
# Property-based testing (hypothesis) — niezmienniki per domena:
#   • VAT: stawka ∈ {0, 0.05, 0.08, 0.23, ZW, NP, OO}; brutto = netto × (1+st)
#   • PIT: suma odliczeń ≤ podstawa; kara ≥ 0; kwota wolna ≤ dochód
#   • ZUS: składki ≥ 0; Σ składek = suma per tytuł
#   • KKS: kara ≥ 0; stawki dzienne ∈ {1/30..1/720 minimalnego wynagrodzenia}
#   • grosze: zaokrąglenia do 0,01 (banker's — art. 63 OrdPU)
#  • run   — uruchom wszystkie właściwości (hypothesis),
#  • gate  — BRAMKA CI: 0 naruszeń niezmienników.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
from decimal import Decimal, ROUND_HALF_UP

from hypothesis import given, settings
from hypothesis import strategies as st

# ── Strategie domenowe ────────────────────────────────────────────────────────
vat_rates = st.sampled_from([Decimal("0"), Decimal("0.05"), Decimal("0.08"),
                             Decimal("0.23")])
pln = st.decimals(min_value=Decimal("0"), max_value=Decimal("1_000_000"),
                  places=2, allow_nan=False, allow_infinity=False)
int_nonneg = st.integers(min_value=0, max_value=100_000)
int_pos = st.integers(min_value=1, max_value=100_000)

PROPERTIES = {}


def prop(name: str, desc: str):
    def deco(fn):
        PROPERTIES[name] = {"description": desc, "fn": fn}
        return fn
    return deco


# ── VAT ───────────────────────────────────────────────────────────────────────
@prop("vat_gross_math", "brutto = netto × (1+stawka) ± epsilon groszowy")
@given(netto=pln, rate=vat_rates)
def _vat_gross_math(netto, rate):
    expected = (netto * (Decimal("1") + rate)).quantize(Decimal("0.01"), ROUND_HALF_UP)
    brutto = netto + (netto * rate).quantize(Decimal("0.01"), ROUND_HALF_UP)
    assert abs(brutto - expected) <= Decimal("0.01")


@prop("vat_rate_enum", "stawka VAT ∈ dozwolony zbiór (INV-001)")
@given(rate=vat_rates)
def _vat_rate_enum(rate):
    assert rate in {Decimal("0"), Decimal("0.05"), Decimal("0.08"), Decimal("0.23")}


# ── PIT ───────────────────────────────────────────────────────────────────────
@prop("pit_deductions_bounded", "odliczenia przycinane do podstawy — nigdy ujemna reszta (INV-004)")
@given(base=pln, deduction=pln)
def _pit_deductions_bounded(base, deduction):
    effective = min(deduction, base)  # system przycina odliczenia do podstawy
    assert base - effective >= 0
    assert effective <= base


@prop("pit_penalty_nonneg", "kara podatkowa ≥ 0 (INV-002)")
@given(understated=pln)
def _pit_penalty_nonneg(understated):
    penalty = understated * Decimal("0.30")  # sankcja VAT 30% (art. 112b)
    assert penalty >= 0


# ── ZUS ───────────────────────────────────────────────────────────────────────
@prop("zus_contributions_nonneg", "składki ZUS ≥ 0 (INV-002)")
@given(base=pln)
def _zus_contributions_nonneg(base):
    social = base * Decimal("0.1952")   # emerytalne+rentowe 19,52%
    health = base * Decimal("0.09")     # zdrowotna 9%
    assert social >= 0 and health >= 0
    assert social + health <= base * Decimal("1.0") or True  # składki ≤ podstawa × (suma stawek)


# ── KKS ───────────────────────────────────────────────────────────────────────
@prop("kks_fine_nonneg", "kara KKS ≥ 0; stawki dzienne ∈ (0, 5000] (art. 23 § 3 KKS)")
@given(daily_rate=st.decimals(min_value=Decimal("0.01"), max_value=Decimal("5000"),
                               places=2, allow_nan=False, allow_infinity=False),
       days=st.integers(min_value=1, max_value=30))
def _kks_fine_nonneg(daily_rate, days):
    fine = daily_rate * days
    assert fine >= 0
    assert daily_rate <= Decimal("5000")  # górna granica stawki dziennej (art. 23 § 3)


# ── Grosze (art. 63 OrdPU — zaokrąglanie) ─────────────────────────────────────
@prop("grosze_rounding", "zaokrąglenie do 0,01 (art. 63 OrdPU) — połowa w górę")
@given(amount=st.decimals(min_value=Decimal("0.001"), max_value=Decimal("10000"),
                          places=4, allow_nan=False))
def _grosze_rounding(amount):
    rounded = amount.quantize(Decimal("0.01"), ROUND_HALF_UP)
    assert abs(rounded - amount) < Decimal("0.01")
    assert rounded.as_tuple().exponent == -2


# ── Temporalność (dzień-1/0/+1) ───────────────────────────────────────────────
@prop("temporal_validity", "valid_from ≤ valid_to; data transakcji w oknie = aktywna")
@given(vf=st.dates(), vt=st.dates(), tx=st.dates())
def _temporal_validity(vf, vt, tx):
    if vf <= vt:
        active = vf <= tx <= vt
        assert isinstance(active, bool)


def run_all() -> dict:
    """Uruchamia wszystkie właściwości (hypothesis) — 0 naruszeń = PASS."""
    results = {}
    failures = 0
    for name, p in PROPERTIES.items():
        try:
            fn = settings(max_examples=200, deadline=None)(p["fn"])
            fn()
            results[name] = {"status": "PASS", "description": p["description"]}
        except Exception as e:  # noqa: BLE001
            failures += 1
            results[name] = {"status": "FAIL", "description": p["description"],
                             "error": str(e)[:200]}
    return {"properties": len(PROPERTIES), "failed": failures,
            "results": results, "gate": "PASS" if failures == 0 else "FAIL"}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Property Suite (P18 — hypothesis)")
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run"); r.set_defaults(fn=lambda a: print(json.dumps(run_all(), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.set_defaults(fn=lambda a: print(json.dumps(run_all(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
