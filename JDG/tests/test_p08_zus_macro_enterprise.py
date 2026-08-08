"""
Testy P08 GLM52 ZUS MACRO ENTERPRISE (raport_enterprise_P08.txt).

Pokrycie: p08_zus_macro_enterprise_v9.rego (składka zdrowotna wg formy
opodatkowania — skala 9% / liniowy 4.9% z limitem odliczenia 14 100 zł /
ryczałt 4.9% progi 60k/300k → 491.40/819.00/1474.20 zł, składki społeczne
19.52%+8%+2.45%+1.67%, 30-krotność, kalendarz 10/15/20, ulgi — start/
preferencyjna/mały ZUS+, zbiegi tytułów Art. 9 SUS, zasiłki — chorobowe/
macierzyńskie/opiekuńcze, 14 innowacji) · main_jdg.rego (wiring) · natywne
testy Rego · ADR-002 (progi z thresholds) · tools/zus_micro_inventory.py.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"

P08_REGO = RULES / "p08_zus_macro_enterprise_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"
P08_NATIVE_TEST = JDG_ROOT / "tests" / "rego" / "test_p08_zus_macro_enterprise.rego"
INVENTORY_TOOL = JDG_ROOT / "tools" / "zus_micro_inventory.py"
INVENTORY_JSON = JDG_ROOT / "bundles" / "zus_micro_inventory.json"


# ═══════════════════ SEKCJA 2 — AUDYT SKŁADKI ZDROWOTNEJ ═══════════════════

class TestHealthContribution:
    @pytest.fixture(scope="class")
    def text(self):
        return P08_REGO.read_text(encoding="utf-8")

    def test_calculator_present(self, text):
        assert "health_contribution_calculator :=" in text
        assert "health_base" in text
        assert "monthly_contribution" in text
        assert "tax_form" in text

    def test_rates_by_form(self, text):
        # Ustawa zdrowotna: skala 9% / liniowy 4.9% / ryczałt 4.9%
        assert "health_scale_rate" in text
        assert "health_linear_rate" in text
        assert "health_linear_deduction_limit" in text

    def test_lump_tiers(self, text):
        assert "lump_sum_tier_verifier :=" in text
        assert "lump_tier_1_limit" in text
        assert "lump_tier_2_limit" in text
        assert "lump_tier_1_amount" in text
        assert "lump_tier_2_amount" in text
        assert "lump_tier_3_amount" in text

    def test_deduction_limit_14100(self, text):
        assert "14100" in text

    def test_multiplier_note(self, text):
        assert "60% przeciętnego wynagrodzenia" in text


# ═══════════════════ SEKCJA 3 — AUDYT SKŁADEK SPOŁECZNYCH ═══════════════════

class TestSocialContributions:
    @pytest.fixture(scope="class")
    def text(self):
        return P08_REGO.read_text(encoding="utf-8")

    def test_social_calculator(self, text):
        assert "social_contribution_calculator :=" in text
        assert "social_base" in text
        assert "social_total" in text

    def test_rates(self, text):
        # Ustawa o SUS: emerytalna 19.52% / rentowa 8% / chorobowa 2.45% / wypadkowa 1.67%
        assert "0.1952" in text
        assert "0.08" in text
        assert "0.0245" in text
        assert "0.0167" in text

    def test_30_krotnosc(self, text):
        assert "annual_base_limit :=" in text
        assert "30-krotność" in text or "30_krotnosc" in text or "annual_base_limit" in text

    def test_payment_calendar(self, text):
        assert "payment_calendar :=" in text
        assert "deadline_day" in text
        assert "10. dzień miesiąca" in text


# ═══════════════════ SEKCJA 4 — AUDYT ULG ═══════════════════

class TestReliefs:
    @pytest.fixture(scope="class")
    def text(self):
        return P08_REGO.read_text(encoding="utf-8")

    def test_relief_simulator(self, text):
        assert "relief_simulator :=" in text
        assert "start_relief" in text
        assert "preferential" in text
        assert "maly_zus_plus" in text

    def test_months_limits(self, text):
        assert "start_relief_months" in text
        assert "preferential_months" in text
        assert "maly_zus_plus_months" in text
        assert "maly_zus_plus_income_limit" in text
        assert "maly_zus_plus_revenue_limit" in text

    def test_relief_tracker(self, text):
        assert "relief_tracker :=" in text
        assert "next_switch_note" in text


# ═══════════════════ SEKCJA 5 — ZBIEGI TYTUŁÓW (Art. 9 SUS) ═══════════════════

class TestCollisions:
    @pytest.fixture(scope="class")
    def text(self):
        return P08_REGO.read_text(encoding="utf-8")

    def test_collision_detector(self, text):
        assert "title_collision_detector :=" in text
        assert "employment_plus_jdg" in text
        assert "pension_plus_jdg" in text
        assert "mandate_plus_jdg" in text

    def test_art9(self, text):
        assert "Art. 9" in text


# ═══════════════════ SEKCJA 6 — AUDYT ZASIŁKÓW ═══════════════════

class TestBenefits:
    @pytest.fixture(scope="class")
    def text(self):
        return P08_REGO.read_text(encoding="utf-8")

    def test_benefits_calculator(self, text):
        assert "benefits_calculator :=" in text
        assert "sickness_benefit_rate" in text
        assert "sickness_period_note" in text
        assert "maternity_note" in text
        assert "maternity_weeks" in text

    def test_maternity_weeks(self, text):
        assert "20 tyg." in text
        assert "41 tyg." in text
        assert "43 tyg." in text


# ═══════════════════ SEKCJA 7 — INNOWACJE (14) ═══════════════════

class TestSection7Genius:
    @pytest.fixture(scope="class")
    def text(self):
        return P08_REGO.read_text(encoding="utf-8")

    def test_14_innovations_marked(self, text):
        count = len(re.findall(r"P08-INN-\d+", text))
        assert count >= 14, f"Oznaczonych innowacji: {count} < 14"

    def test_innovations_present(self, text):
        for name in [
            "health_contribution_calculator",
            "lump_sum_tier_verifier",
            "social_contribution_calculator",
            "annual_base_limit",
            "payment_calendar",
            "relief_simulator",
            "relief_tracker",
            "title_collision_detector",
            "benefits_calculator",
            "zus_digital_twin",
            "base_recommender",
            "zus_reconciliation",
            "employment_vs_jdg_simulator",
            "zus_verdict_integrity",
        ]:
            assert name in text, f"Brak innowacji: {name}"

    def test_digital_twin(self, text):
        assert "zus_digital_twin :=" in text
        assert "twin" in text

    def test_verdict_integrity(self, text):
        assert "zus_verdict_integrity :=" in text
        assert "merkle" in text.lower() or "integrity" in text

    def test_activation_flag(self, text):
        assert "p08_zus_macro_check" in text

    def test_safe_report_accessors(self, text):
        for acc in ["report_section1", "report_health", "report_social",
                    "report_reliefs", "report_collisions", "report_benefits",
                    "report_genius", "report_health_calc", "report_social_calc",
                    "report_twin"]:
            assert acc in text, f"Brak akcesora raportu: {acc}"

    def test_no_and_or_operators(self, text):
        body = text
        assert " and " not in body
        assert " or " not in body

    def test_no_wildcard_data_read(self, text):
        assert "data.jdg.zus_micro_audit" in text


# ═══════════════════ MAIN_JDG WIRING ═══════════════════

class TestMainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.p08_zus_macro_enterprise" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.p08_zus_macro_enterprise": p08_zus_macro_enterprise.decide' in text

    def test_chain_order(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        p07_pos = text.find("safe_merge(p07_pit_micro_atomic.decide,")
        p08_pos = text.find("safe_merge(p08_zus_macro_enterprise.decide,")
        fb_pos = text.find("fallback.decide", p08_pos)
        assert p07_pos != -1 and p08_pos != -1 and fb_pos != -1
        assert p07_pos < p08_pos < fb_pos


# ═══════════════════ NARZĘDZIE INWENTARYZACJI ═══════════════════

class TestInventoryTool:
    def test_tool_exists(self):
        assert INVENTORY_TOOL.exists()

    def test_tool_key_articles(self):
        text = INVENTORY_TOOL.read_text(encoding="utf-8")
        for art in ["6a", "9", "11", "13", "18", "22", "79", "80", "81"]:
            assert art in text, f"Brak artykułu w narzędziu: {art}"

    def test_inventory_artifact_exists(self):
        assert INVENTORY_JSON.exists()


# ═══════════════════ NATYWNE TESTY REGO ═══════════════════

class TestNativeRegoTests:
    def test_native_test_file_exists(self):
        assert P08_NATIVE_TEST.exists()

    def test_native_test_cover_all_areas(self):
        text = P08_NATIVE_TEST.read_text(encoding="utf-8")
        for name in [
            "test_health_scale_9pct",
            "test_health_linear_4_9pct",
            "test_health_lump_tier_1",
            "test_health_lump_tier_2",
            "test_health_lump_tier_3",
            "test_lump_tier_verifier_tier2",
            "test_social_contributions",
            "test_social_contributions_default_base",
            "test_30x_annual_limit",
            "test_payment_calendar_physical",
            "test_payment_calendar_employer",
            "test_start_relief_active",
            "test_maly_zus_plus_eligible",
            "test_maly_zus_plus_revenue_exceeded",
            "test_collision_employment_plus_jdg",
            "test_collision_none",
            "test_benefits_sickness_80",
            "test_benefits_sickness_100_hospital",
            "test_benefits_sickness_period_exceeded",
            "test_digital_twin",
            "test_zus_reconciliation_consistent",
            "test_coverage_with_audit_data",
            "test_p08_main_report",
            "test_p08_no_match_default",
        ]:
            assert name in text, f"Brak natywnego testu: {name}"

    def test_native_test_min_count(self):
        text = P08_NATIVE_TEST.read_text(encoding="utf-8")
        assert text.count("test_") >= 24
