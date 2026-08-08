"""
Testy P07 GLM52 PIT MICRO ATOMIC ENTERPRISE (raport_enterprise_P07.txt).

Pokrycie: p07_pit_micro_atomic_v9.rego (kalkulator amortyzacji liniowa/degresywna/
jednorazowa Art. 22i, stawki KŚT, limity aut 150k/225k, niskocenne Art. 22n,
ulepszenia Art. 22g, remanent Art. 24a, NKUP Art. 23 — 57 pkt, symulator ulg
85 528, IP Box nexus 30ca, 14 innowacji) · main_jdg.rego (wiring) · natywne
testy Rego · ADR-002 (progi z thresholds) · tools/pit_micro_inventory.py.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"

P07_REGO = RULES / "p07_pit_micro_atomic_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"
P07_NATIVE_TEST = JDG_ROOT / "tests" / "rego" / "test_p07_pit_micro_atomic.rego"
INVENTORY_TOOL = JDG_ROOT / "tools" / "pit_micro_inventory.py"
INVENTORY_JSON = JDG_ROOT / "bundles" / "pit_micro_inventory.json"


# ═══════════════════ SEKCJA 2 — AUDYT AMORTYZACJI ═══════════════════

class TestDepreciation:
    @pytest.fixture(scope="class")
    def text(self):
        return P07_REGO.read_text(encoding="utf-8")

    def test_calculator_present(self, text):
        assert "amortization_calculator :=" in text
        assert "recommended_method" in text
        assert "declining_annual" in text

    def test_kst_rates_all_groups(self, text):
        # Załącznik KŚT: grupy 1-10 (1.5/2.5/4.5/4.5/7/10/10/20/20/25%)
        for rate in ["0.015", "0.025", "0.045", "0.07", "0.10", "0.20", "0.25"]:
            assert rate in text, f"Brak stawki KŚT: {rate}"

    def test_one_time_depreciation(self, text):
        assert "one_time_eligible" in text
        assert "de_minimis_limit" in text
        assert "small_taxpayer_eur" in text

    def test_car_limits(self, text):
        assert "car_limit_standard" in text
        assert "car_limit_ev" in text
        assert "car_value_limit_standard" in text

    def test_low_value_and_improvement(self, text):
        assert "low_value_asset :=" in text
        assert "one_off_low_value" in text
        assert "improvement_auditor :=" in text
        assert "Art. 22g" in text

    def test_remnant_tracker(self, text):
        assert "remnant_tracker :=" in text
        assert "opening_remnant" in text
        assert "closing_remnant" in text
        assert "Art. 24a" in text

    def test_initial_value_auditor(self, text):
        assert "initial_value_auditor :=" in text
        assert "initial_value_base" in text
        assert "Art. 22b" in text


# ═══════════════════ SEKCJA 3 — AUDYT NKUP ═══════════════════

class TestNkup:
    @pytest.fixture(scope="class")
    def text(self):
        return P07_REGO.read_text(encoding="utf-8")

    def test_nkup_auditor(self, text):
        assert "nkup_auditor :=" in text
        assert "representation_nkup" in text
        assert "car_pct_75_limit" in text
        assert "Art. 23" in text

    def test_nkup_57_points(self, text):
        assert "nkup_57pt_matrix :=" in text
        assert "pkt23_reprezentacja" in text
        assert "pkt46_auta_75pct" in text
        assert "pkt47_leasing_limit" in text


# ═══════════════════ SEKCJA 4 — AUDYT ULG ATOMOWYCH ═══════════════════

class TestReliefs:
    @pytest.fixture(scope="class")
    def text(self):
        return P07_REGO.read_text(encoding="utf-8")

    def test_relief_simulator(self, text):
        assert "relief_simulator :=" in text
        assert "relief_shared_limit" in text
        assert "shared_limit_guard" in text

    def test_ip_box_nexus(self, text):
        assert "ip_box_nexus :=" in text
        assert "nexus_ratio" in text
        assert "Art. 30ca" in text

    def test_thermo_limit(self, text):
        assert "thermo_limit" in text
        assert "53000" in text


# ═══════════════════ SEKCJA 5 — INNOWACJE (14) ═══════════════════

class TestSection5Genius:
    @pytest.fixture(scope="class")
    def text(self):
        return P07_REGO.read_text(encoding="utf-8")

    def test_14_innovations_marked(self, text):
        count = len(re.findall(r"P07-INN-\d+", text))
        assert count >= 14, f"Oznaczonych innowacji: {count} < 14"

    def test_innovations_present(self, text):
        for name in [
            "amortization_calculator",
            "kst_rate_verifier",
            "initial_value_auditor",
            "car_depreciation_limit",
            "low_value_asset",
            "improvement_auditor",
            "remnant_tracker",
            "depreciation_timeline",
            "nkup_auditor",
            "nkup_57pt_matrix",
            "relief_simulator",
            "ip_box_nexus",
            "proof_of_law",
            "golden_dataset",
            "micro_macro_conflict",
        ]:
            assert name in text, f"Brak innowacji: {name}"

    def test_proof_of_law(self, text):
        assert "proof_of_law :=" in text
        assert "_legal_basis" in text

    def test_activation_flag(self, text):
        assert "p07_pit_micro_check" in text

    def test_safe_report_accessors(self, text):
        for acc in ["report_section1", "report_depreciation", "report_nkup",
                    "report_reliefs", "report_genius", "report_calculator",
                    "report_nkup_audit", "report_relief_sim", "report_remnant"]:
            assert acc in text, f"Brak akcesora raportu: {acc}"

    def test_no_and_or_operators(self, text):
        body = text
        assert " and " not in body
        assert " or " not in body

    def test_no_wildcard_data_read(self, text):
        assert "data.jdg.pit_micro_audit" in text


# ═══════════════════ MAIN_JDG WIRING ═══════════════════

class TestMainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.p07_pit_micro_atomic" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.p07_pit_micro_atomic": p07_pit_micro_atomic.decide' in text

    def test_chain_order(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        p06_pos = text.find("safe_merge(p06_pit_macro_enterprise.decide,")
        p07_pos = text.find("safe_merge(p07_pit_micro_atomic.decide,")
        fb_pos = text.find("fallback.decide", p07_pos)
        assert p06_pos != -1 and p07_pos != -1 and fb_pos != -1
        assert p06_pos < p07_pos < fb_pos


# ═══════════════════ NARZĘDZIE INWENTARYZACJI ═══════════════════

class TestInventoryTool:
    def test_tool_exists(self):
        assert INVENTORY_TOOL.exists()

    def test_tool_key_articles(self):
        text = INVENTORY_TOOL.read_text(encoding="utf-8")
        for art in ["22a", "22b", "22n", "23", "24a", "26", "30ca"]:
            assert art in text, f"Brak artykułu w narzędziu: {art}"

    def test_inventory_artifact_exists(self):
        assert INVENTORY_JSON.exists()


# ═══════════════════ NATYWNE TESTY REGO ═══════════════════

class TestNativeRegoTests:
    def test_native_test_file_exists(self):
        assert P07_NATIVE_TEST.exists()

    def test_native_test_cover_all_areas(self):
        text = P07_NATIVE_TEST.read_text(encoding="utf-8")
        for name in [
            "test_amortization_calculator_linear",
            "test_amortization_calculator_degressive",
            "test_amortization_calculator_linear_default",
            "test_kst_rate_verifier_ok",
            "test_kst_rate_verifier_bad",
            "test_initial_value_purchase",
            "test_initial_value_production",
            "test_initial_value_gift",
            "test_car_depreciation_limit_standard",
            "test_car_depreciation_limit_ev",
            "test_low_value_asset",
            "test_low_value_asset_above",
            "test_remnant_tracker",
            "test_nkup_auditor_ok",
            "test_nkup_auditor_violations",
            "test_relief_simulator_within_limit",
            "test_relief_simulator_over_limit",
            "test_ip_box_nexus",
            "test_proof_of_law",
            "test_golden_dataset_boundaries",
            "test_coverage_status_with_audit_data",
            "test_p07_main_report",
            "test_p07_no_match_default",
        ]:
            assert name in text, f"Brak natywnego testu: {name}"

    def test_native_test_min_count(self):
        text = P07_NATIVE_TEST.read_text(encoding="utf-8")
        assert text.count("test_") >= 23
