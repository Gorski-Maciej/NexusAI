#!/usr/bin/env python3
"""
Auto-Testy dla P05 PIT MAKRO — kampania GLM 5.2 (RAPORT_GLM52_P05_PIT_MAKRO.txt)
================================================================================
Pokrycie sekcji 8.6–8.9 raportu P05:
  • pit_annual_engine v2 — groszowe zaokrąglenia (art. 63 § 1 OrdPU), granice
    progu skali 120 000 (art. 27), degresja kwoty zmniejszającej, PIT-28 per
    kategoria PKWiU (2/3/5,5/8,5/12/15/17%), zaliczki miesięczne/kwartalne/
    uproszczone, rozliczenie nadpłaty/niedopłaty (art. 45 ust. 6 + art. 77 OrdPU)
  • form_simulator v2 — 4-ścieżkowa symulacja, prognoza 3-letnia (INN-01),
    wpływ składki zdrowotnej (9%/4,9%/ryczałt) na wybór formy
  • struktura Rego — nowe rule_id (what_if_recommendation, annual_limits_monitor,
    grosz_rounding, quarterly_due_dates, shared_limit_monitor), okablowanie
    main_jdg (importy pit.*), progi w thresholds (ADR-002)

Wygenerowano: 2026-08-16 · kampania GLM 5.2 · moduł JDG
"""

import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"
BASE_DIR = Path(__file__).resolve().parent.parent.parent

sys.path.insert(0, str(TOOLS_DIR))

import pit_annual_engine as pae          # noqa: E402
import form_simulator as fsim            # noqa: E402

VERDICTS = [
    {"direction": "SALE", "amount_net": 250000},
    {"kup_amount": 50000},
    {"zus_social_paid": 24000},
]


# ═══════════════════════════════════════════════════════════════════════════
# PIT ANNUAL ENGINE — GROSZE (art. 63 § 1 OrdPU) I KWOTA ZMNIEJSZAJĄCA (art. 27)
# ═══════════════════════════════════════════════════════════════════════════

class TestPitAnnualEngineGrosz:
    def test_round_grosz_down_49(self):
        # końcówka 0–49 gr → zaokrąglenie W DÓŁ
        assert pae.round_grosz(100.49) == 100

    def test_round_grosz_up_50(self):
        # końcówka 50 gr → zaokrąglenie W GÓRĘ (art. 63 § 1 OrdPU)
        assert pae.round_grosz(100.50) == 101

    def test_round_grosz_up_51(self):
        # końcówka 51 gr → zaokrąglenie W GÓRĘ
        assert pae.round_grosz(100.51) == 101

    def test_round_grosz_99(self):
        # 99,99 zł → 100 zł (pełne złote)
        assert pae.round_grosz(99.99) == 100

    def test_tax_reducing_full_below_30k(self):
        # kwota zmniejszająca pełna 3 600 zł do 30 000 zł dochodu
        assert pae.tax_reducing_amount(30000) == 3600.0

    def test_tax_reducing_degression_midpoint(self):
        # degresja liniowa 30k–120k: 75 000 → 1 800 zł
        assert pae.tax_reducing_amount(75000) == 1800.0

    def test_tax_reducing_zero_above_120k(self):
        # zero od 120 000 zł dochodu
        assert pae.tax_reducing_amount(120000) == 0.0
        assert pae.tax_reducing_amount(150000) == 0.0


class TestPitAnnualEngineScale:
    def test_scale_bracket_low_below_threshold(self):
        assert pae.scale_tax(119999.99)["bracket"] == "LOW"

    def test_scale_bracket_low_at_threshold(self):
        # dochód dokładnie 120 000 → pierwszy próg 12% (art. 27 ust. 1)
        assert pae.scale_tax(120000)["bracket"] == "LOW"

    def test_scale_bracket_high_above_threshold(self):
        assert pae.scale_tax(120000.01)["bracket"] == "HIGH"

    def test_scale_tax_amount_at_threshold(self):
        # 120 000 × 12% = 14 400, kwota zmniejszająca zero ≥ 120k
        r = pae.scale_tax(120000)
        assert r["tax_after_reducing"] == 14400.0
        assert r["tax_reducing_amount"] == 0.0


class TestPitAnnualEngineLump:
    def test_lump_rate_trade_2pct(self):
        assert pae.lump_tax(100000, 0, "trade") == 2000.0

    def test_lump_rate_construction_5_5pct(self):
        assert pae.lump_tax(100000, 0, "construction") == 5500.0

    def test_lump_rate_services_8_5pct(self):
        assert pae.lump_tax(100000, 0, "services") == 8500.0

    def test_lump_rate_it_high_12pct(self):
        assert pae.lump_tax(100000, 0, "it_high") == 12000.0

    def test_lump_rate_management_15pct(self):
        assert pae.lump_tax(100000, 0, "management") == 15000.0

    def test_lump_rate_transport_17pct(self):
        assert pae.lump_tax(100000, 0, "transport") == 17000.0


class TestPitAnnualEngineCompute:
    def test_compute_scale_pit36(self):
        r = pae.compute(VERDICTS, "PIT_SCALE")
        assert r["form"] == "PIT-36"
        assert r["income"] == 176000.0
        assert r["tax"] == 32320.0

    def test_compute_linear_pit36l(self):
        r = pae.compute(VERDICTS, "LINEAR")
        assert r["form"] == "PIT-36L"
        assert r["tax"] == 33440.0

    def test_compute_lump_pit28(self):
        r = pae.compute(VERDICTS, "LUMP_SUM", lump_category="it_high")
        assert r["form"] == "PIT-28"

    def test_verify_invariant_grosz(self):
        # dowód matematyczny: podatek = f(podstawa, stawki) ± 0,01
        r = pae.compute(VERDICTS, "PIT_SCALE")
        assert pae.verify(r)["consistent"] is True


class TestPitAnnualEngineAdvances:
    def test_advances_monthly(self):
        r = pae.advances("PIT_SCALE", 120000)
        assert r["frequency"] == "MONTHLY"
        assert len(r["payments"]) == 12
        assert r["payments"][0]["amount"] == 1200.0
        assert r["total_advances"] == 14400.0

    def test_advances_quarterly_small_taxpayer(self):
        r = pae.advances("PIT_SCALE", 120000, quarterly=True)
        assert r["frequency"] == "QUARTERLY"
        assert len(r["payments"]) == 4
        assert all(p["amount"] == 3600.0 for p in r["payments"])
        # terminy: 20.04 / 20.07 / 20.10 / 20.01 (art. 44 ust. 3g)
        due_months = [p["due_date"][5:7] for p in r["payments"]]
        assert due_months == ["04", "07", "10", "01"]

    def test_advances_simplified_1_12(self):
        # 1/12 podatku z roku poprzedniego (art. 44 ust. 6b)
        r = pae.advances("PIT_SCALE", 120000, prev_year_income=60000, simplified=True)
        assert r["frequency"] == "SIMPLIFIED_1_12"
        assert len(r["payments"]) == 12
        assert r["payments"][0]["amount"] == 400.0
        assert r["total_advances"] == 4800.0


class TestPitAnnualEngineSettlement:
    def test_settlement_niedoplata(self):
        r = pae.settlement(25000, 22000)
        assert r["type"] == "NIEDOPŁATA"
        assert r["amount"] == 3000.0
        assert r["interest_rate"] == 0.145

    def test_settlement_nadplata(self):
        r = pae.settlement(22000, 25000)
        assert r["type"] == "NADPŁATA"
        assert r["amount"] == 3000.0
        assert r["refund_days"] == 45

    def test_settlement_zerowe(self):
        r = pae.settlement(25000, 25000)
        assert r["type"] == "ZEROWE"
        assert r["amount"] == 0.0


# ═══════════════════════════════════════════════════════════════════════════
# FORM SIMULATOR — 4 ŚCIEŻKI, PROGNOZA 3-LETNIA, SKŁADKA ZDROWOTNA
# ═══════════════════════════════════════════════════════════════════════════

class TestFormSimulator:
    def test_simulate_four_paths_recommendation(self):
        r = fsim.simulate(250000, 50000, 24000)
        assert r["income"] == 176000.0
        assert set(r["paths"].keys()) == {
            "PIT_SCALE (12/32%)", "LINEAR (19%)", "LUMP_SUM (ryczałt)", "CARD (karta)"}
        assert r["paths"]["LUMP_SUM (ryczałt)"] == 17000.0
        assert r["recommendation"] == "LUMP_SUM (ryczałt)"
        assert r["savings_vs_scale"] == 19000.0

    def test_compare_break_even(self):
        r = fsim.compare(250000, 50000, 24000)
        assert r["scale"] == 32320.0
        assert r["linear"] == 33440.0
        assert r["delta_linear_vs_scale"] == 1120.0
        assert r["break_even_income"] == 120000

    def test_health_impact_scale_9pct(self):
        r = fsim.health_impact("PIT_SCALE", 100000)
        assert r["annual"] == 9000.0
        assert "9%" in r["rate"]

    def test_health_impact_linear_4_9pct(self):
        r = fsim.health_impact("LINEAR", 100000)
        assert r["annual"] == 4900.0
        assert "4.9%" in r["rate"]

    def test_health_impact_lump_tier1(self):
        r = fsim.health_impact("LUMP_SUM", 100000, revenue=50000)
        assert r["tier"] == "TIER_1 (≤ 60k przychodu)"
        assert r["monthly"] == 491.40
        assert r["annual"] == 5896.80

    def test_simulate_3y_long_term(self):
        r = fsim.simulate_3y(100000, 20000, 10000, growth=0.1)
        assert r["horizon_years"] == 3
        assert len(r["yearly"]) == 3
        assert set(r["total_by_form"].keys()) == {
            "PIT_SCALE (12/32%)", "LINEAR (19%)", "LUMP_SUM (ryczałt)", "CARD (karta)"}
        assert r["recommendation_long_term"] == "LUMP_SUM (ryczałt)"

    def test_risk_linear(self):
        r = fsim.risk(250000, "LINEAR")
        assert r["current_form"] == "LINEAR"
        assert any("BRAK kwoty wolnej" in x for x in r["risks"])


# ═══════════════════════════════════════════════════════════════════════════
# STRUKTURA REGO P05 — NOWE RULE_ID, OKABLOWANIE, PROGI (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════

class TestP05RegoStructure:
    def test_new_rule_ids_present(self):
        checks = {
            "rules/pit/forms.rego": "jdg.pit.forms.what_if_recommendation",
            "rules/pit/kup.rego": "jdg.pit.kup.annual_limits_monitor",
            "rules/pit/advances_returns.rego": "jdg.pit.advances.grosz_rounding",
            "rules/pit/exemptions.rego": "jdg.pit.exemptions.shared_limit_monitor",
        }
        for rel, rule_id in checks.items():
            text = (BASE_DIR / rel).read_text(encoding="utf-8")
            assert rule_id in text, f"Brak {rule_id} w {rel}"

    def test_quarterly_due_dates_rule(self):
        text = (BASE_DIR / "rules" / "pit" / "advances_returns.rego").read_text(encoding="utf-8")
        assert "jdg.pit.advances.quarterly_due_dates" in text

    def test_advances_imports_thresholds(self):
        # reguły grosz_rounding/quarterly_due_dates używają thresholds.pit/rates
        text = (BASE_DIR / "rules" / "pit" / "advances_returns.rego").read_text(encoding="utf-8")
        assert "import data.jdg.thresholds" in text

    def test_thresholds_p05_present(self):
        text = (BASE_DIR / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
        for key in ["\"advance_due_day\"", "\"advance_grosz_rounding\"",
                    "\"quarterly_advance_due_months\"", "\"annual_return_pit36_deadline\"",
                    "\"annual_return_pit28_deadline\"", "\"exemption_shared_limit_alert_pct\"",
                    "\"pit_relief_shared_limit\"", "\"health_linear_deduction_limit\"",
                    "\"card_tax_estimation_pct\""]:
            assert key in text, f"Brak progu {key} w thresholds_jdg.rego"

    def test_main_jdg_wiring(self):
        main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
        for imp in ["import data.jdg.pit.forms", "import data.jdg.pit.kup",
                    "import data.jdg.pit.advances_returns", "import data.jdg.pit.exemptions"]:
            assert imp in main, f"Brak importu {imp} w main_jdg.rego"
        for reg in ["\"jdg.pit.forms\": forms.decide", "\"jdg.pit.kup\": kup.decide",
                    "\"jdg.pit.advances_returns\": advances_returns.decide",
                    "\"jdg.pit.exemptions\": exemptions.decide"]:
            assert reg in main, f"Brak wpisu rejestru {reg} w main_jdg.rego"
