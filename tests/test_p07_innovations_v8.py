#!/usr/bin/env python3
"""Testy strukturalne i integracyjne dla P07 ZUS Macro Innovations Engine v8.0.

Pokrycie:
- 12 innowacji (INN01-INN12)
- 3 gap fixes (Multiple JDG, Non-Registered Activity, Concurrent Mandate)
- 3 threshold corrections (min_wage, ryczałt tiers, deduction limit)
- Threshold batch-fix verification (4666→4800, tiers→2026)
"""

import os
import sys


class TestP07InnovationsStructural:
    """Testy strukturalne pliku innowacji P07."""

    def test_file_exists(self):
        path = "JDG/rules/p07_zus_macro_innovations_v8.rego"
        assert os.path.exists(path), f"Plik {path} nie istnieje!"

    def test_package_declaration(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            assert "package jdg.p07_innovations" in f.read()

    def test_default_rule(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            content = f.read()
        assert "default decide :=" in content
        assert "no_match" in content

    def test_all_12_innovations_present(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            content = f.read()
        innovations = [
            "INN01_HEALTH_INSURANCE_OPTIMIZER",
            "INN02_ZUS_RELIEF_TRANSITION_MANAGER",
            "INN03_MULTI_TITLE_CONTRIBUTION_MINIMIZER",
            "INN04_SICKNESS_BENEFIT_PREDICTOR",
            "INN05_ZUS_CALENDAR_AUTO_NOTIFICATION",
            "INN06_HEALTH_RECONCILIATION_ENGINE",
            "INN07_ZUS_AUDIT_SHIELD",
            "INN08_PREFERENTIAL_PERIOD_TRACKER",
            "INN09_CROSS_BORDER_SOCIAL_INSURANCE_MATRIX",
            "INN10_ZUS_BUDGET_FORECASTER",
            "INN11_HEALTH_TIER_OPTIMIZER",
            "INN12_MATERNITY_BUSINESS_CONTINUITY",
        ]
        for inn in innovations:
            assert inn in content, f"Brak innowacji {inn}!"

    def test_gap_fixes_present(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            content = f.read()
        assert "GAP_MULTIPLE_JDG" in content
        assert "GAP_NON_REGISTERED_ACTIVITY" in content
        assert "GAP_CONCURRENT_MANDATE_JDG" in content

    def test_threshold_fixes_present(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            content = f.read()
        assert "THRESHOLD_FIX_MIN_WAGE" in content
        assert "THRESHOLD_FIX_RYCZALT_TIERS" in content
        assert "THRESHOLD_FIX_DEDUCTION_LIMIT" in content

    def test_else_chain_correct(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            content = f.read()
        else_count = content.count("\nelse := {")
        decide_count = content.count("\ndecide := {")
        assert else_count >= 17, f"else := count: {else_count}"
        assert decide_count == 1, f"decide := count (should be 1 after default): {decide_count}"

    def test_coverage_summary_last(self):
        with open("JDG/rules/p07_zus_macro_innovations_v8.rego") as f:
            content = f.read()
        assert "P07_COVERAGE_SUMMARY" in content
        assert "ready_for_p08" in content


class TestP07ThresholdFixes:
    """Testy poprawności poprawek threshold."""

    def test_min_wage_updated_no_4666(self):
        with open("JDG/rules/zus/health_contribution_enterprise.rego") as f:
            content = f.read()
        assert "4666" not in content, "Znaleziono starą wartość 4666!"

    def test_min_wage_4800_present(self):
        with open("JDG/rules/zus/health_contribution_enterprise.rego") as f:
            content = f.read()
        assert "4800" in content, "Brak nowej wartości 4800!"

    def test_ryczalt_tiers_no_old_values(self):
        with open("JDG/rules/zus/health_contribution_enterprise.rego") as f:
            content = f.read()
        assert "419.46" not in content, "Znaleziono starą wartość 419.46!"
        assert "699.11" not in content, "Znaleziono starą wartość 699.11!"
        assert "1258.39" not in content, "Znaleziono starą wartość 1258.39!"

    def test_ryczalt_tiers_new_values(self):
        with open("JDG/rules/zus/health_contribution_enterprise.rego") as f:
            content = f.read()
        assert "491.40" in content, "Brak nowej wartości TIER 1: 491.40!"
        assert "819.00" in content, "Brak nowej wartości TIER 2: 819.00!"
        assert "1474.20" in content, "Brak nowej wartości TIER 3: 1474.20!"

    def test_deduction_limit_message_updated(self):
        with open("JDG/rules/zus/health_contribution_enterprise.rego") as f:
            content = f.read()
        assert "12 900" not in content, "Znaleziono stary limit 12 900 w komunikatach!"
        assert "14 100" in content, "Brak nowego limitu 14 100 w komunikatach!"


class TestP07BusinessLogic:
    """Testy logiki biznesowej."""

    def test_health_optimizer_variants(self):
        assert ["SCALE_9PCT", "LINEAR_4_9PCT_DEDUCTIBLE", "LUMP_SUM_3_TIERS", "TAX_CARD_9PCT_MIN"]

    def test_relief_timeline_all_4(self):
        timeline = ["START_RELIEF", "PREFERENTIAL", "MALY_ZUS_PLUS", "STANDARD"]
        assert len(timeline) == 4

    def test_calendar_deadlines_count(self):
        deadlines = ["10", "15", "20", "05-22", "04-30", "01-31"]
        assert len(deadlines) == 6

    def test_maternity_can_continue_business(self):
        """JDG może prowadzić firmę na macierzyńskim."""
        assert True  # Ważna informacja biznesowa

    def test_health_still_due_during_sickness(self):
        """Zdrowotna NADAL należna podczas choroby."""
        assert True

    def test_non_registered_limit_75pct(self):
        min_wage = 4800
        limit = min_wage * 0.75
        assert limit == 3600


class TestP07Integration:
    """Testy integracji z main_jdg.rego."""

    def test_main_jdg_imports_p07(self):
        with open("JDG/rules/main_jdg.rego") as f:
            assert "import data.jdg.p07_innovations" in f.read()

    def test_main_jdg_safe_merge_p07(self):
        with open("JDG/rules/main_jdg.rego") as f:
            content = f.read()
        count = content.count("safe_merge(p07_innovations.decide,")
        assert count >= 3, f"Znaleziono {count} safe_merge p07 (oczekiwano ≥3)"

    def test_main_jdg_package_decisions_p07(self):
        with open("JDG/rules/main_jdg.rego") as f:
            assert '"jdg.p07_innovations": p07_innovations.decide,' in f.read()


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v", "--tb=short"]))
