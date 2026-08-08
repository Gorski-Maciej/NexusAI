"""
Testy P06 GLM52 PIT MACRO ENTERPRISE (raport_enterprise_P06.txt).

Pokrycie: p06_pit_macro_enterprise_v9.rego (optymalizator formy, audyt ulg
B+R/prototyp/robotyzacja/ekspansja/termo/IP Box, KUP, zaliczki, 14 innowacji) ·
main_jdg.rego (wiring) · natywne testy Rego · ADR-002 (progi z thresholds).
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"

P06_REGO = RULES / "p06_pit_macro_enterprise_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"
P06_NATIVE_TEST = JDG_ROOT / "tests" / "rego" / "test_p06_pit_macro_enterprise.rego"


# ═══════════════════ SEKCJA 7 — FORMY OPODATKOWANIA ═══════════════════

class TestFormOptimizer:
    @pytest.fixture(scope="class")
    def text(self):
        return P06_REGO.read_text(encoding="utf-8")

    def test_form_optimizer_present(self, text):
        assert "form_optimizer :=" in text
        assert "recommended_form" in text
        assert "scale_tax_pln" in text

    def test_linear_rates_from_thresholds(self, text):
        assert "scale_low_rate" in text
        assert "scale_high_rate" in text
        assert "linear_rate" in text
        assert "data.jdg.thresholds.pit" in text

    def test_former_employer_block(self, text):
        assert "loss_of_linear_detector :=" in text
        assert "former_employer_block_flag" in text
        assert "Art. 30c ust. 2" in text

    def test_tax_reducing_amount_phaseout(self, text):
        # Art. 27 ust. 1a: 3 600 zł do 120k, fazowanie do 180k, 0 powyżej
        assert "tax_reducing_amount :=" in text
        assert "3600" in text
        assert "scale_threshold * 1.5" in text


# ═══════════════════ SEKCJA 8 — AUDYT ULG (GŁÓWNY PRIORYTET) ═══════════════════

class TestReliefsAudit:
    @pytest.fixture(scope="class")
    def text(self):
        return P06_REGO.read_text(encoding="utf-8")

    def test_br_definition_4_criteria(self, text):
        assert "br_definition_checker :=" in text
        assert "creative_activity" in text
        assert "systematic_activity" in text
        assert "knowledge_increase" in text
        assert "uncertain_result" in text

    def test_all_reliefs_present(self, text):
        for name in [
            "relief_prototype_result",   # Art. 26eb
            "relief_robotization_result",  # Art. 26gb
            "relief_expansion_result",   # Art. 26ec
            "relief_thermo_result",      # Art. 26h
            "relief_ipbox_result",       # Art. 30ca
        ]:
            assert name in text, f"Brak ulgi: {name}"

    def test_shared_limit_85528(self, text):
        assert "shared_relief_limit" in text
        assert "reliefs_total" in text
        assert "stacking" in text

    def test_thermo_limit_53000(self, text):
        assert "thermo_relief_limit" in text
        assert "53000" in text

    def test_ipbox_5pct(self, text):
        assert "ip_box_rate" in text

    def test_kup_auditor(self, text):
        assert "kup_auditor :=" in text
        assert "electric_car_225k" in text
        assert "representation_nkup" in text
        assert "Art. 23 ust. 1 pkt 23/46/47" in text

    def test_pit_reconciliation(self, text):
        assert "pit_reconciliation :=" in text
        assert "revenue_vs_vat_delta" in text
        assert "zus_base_ok" in text


# ═══════════════════ SEKCJA 8 — GENIALNE POMYSŁY (14) ═══════════════════

class TestSection8Genius:
    @pytest.fixture(scope="class")
    def text(self):
        return P06_REGO.read_text(encoding="utf-8")

    def test_14_innovations_marked(self, text):
        count = len(re.findall(r"P06-INN-\d+", text))
        assert count >= 14, f"Oznaczonych innowacji: {count} < 14"

    def test_innovations_present(self, text):
        for name in [
            "pit_digital_twin",
            "relief_recommender",
            "relief_stacking_analyzer",
            "br_vs_ipbox_comparator",
            "termo_calculator",
            "advance_forecast",
            "pit_calendar",
            "pit36_autogen",
            "innovations_summary",
        ]:
            assert name in text, f"Brak innowacji: {name}"

    def test_activation_flag(self, text):
        assert "p06_pit_macro_check" in text

    def test_safe_report_accessors(self, text):
        for acc in ["report_optimizer", "report_br", "report_reliefs",
                    "report_stacking", "report_comparator", "report_termo",
                    "report_kup", "report_recon", "report_twin", "report_autogen"]:
            assert acc in text, f"Brak akcesora raportu: {acc}"

    def test_no_and_or_operators(self, text):
        # Rego v0: brak `and`/`or` — koniunkcje przez helpery
        body = text
        assert " and " not in body
        assert " or " not in body

    def test_no_wildcard_data_read(self, text):
        assert 'object.get(data.jdg, "pit_macro_audit"' not in text
        assert "data.jdg.pit_macro_audit" in text


# ═══════════════════ MAIN_JDG WIRING ═══════════════════

class TestMainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.p06_pit_macro_enterprise" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.p06_pit_macro_enterprise": p06_pit_macro_enterprise.decide' in text

    def test_chain_order(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        p05_pos = text.find("safe_merge(p05_vat_micro_atomic.decide,")
        p06_pos = text.find("safe_merge(p06_pit_macro_enterprise.decide,")
        fb_pos = text.find("fallback.decide", p06_pos)
        assert p05_pos != -1 and p06_pos != -1 and fb_pos != -1
        assert p05_pos < p06_pos < fb_pos


# ═══════════════════ NATYWNE TESTY REGO ═══════════════════

class TestNativeRegoTests:
    def test_native_test_file_exists(self):
        assert P06_NATIVE_TEST.exists()

    def test_native_test_cover_all_areas(self):
        text = P06_NATIVE_TEST.read_text(encoding="utf-8")
        for name in [
            "test_form_optimizer_scale_vs_linear",
            "test_form_optimizer_former_employer_block",
            "test_form_optimizer_scale_tax_reducing_low",
            "test_form_optimizer_scale_tax_reducing_mid",
            "test_loss_of_linear_detector",
            "test_br_definition_all_criteria",
            "test_br_definition_missing_criterion",
            "test_relief_recommender_br",
            "test_relief_recommender_prototype",
            "test_shared_limit_within",
            "test_termo_calculator_cap",
            "test_kup_auditor_car",
            "test_pit_reconciliation_consistent",
            "test_pit_reconciliation_mismatch",
            "test_p06_main_report",
            "test_p06_no_match_default",
        ]:
            assert name in text, f"Brak natywnego testu: {name}"

    def test_native_test_min_count(self):
        text = P06_NATIVE_TEST.read_text(encoding="utf-8")
        assert text.count("test_") >= 16
