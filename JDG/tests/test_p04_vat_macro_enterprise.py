"""
Testy P04 GLM52 VAT MACRO ENTERPRISE (raport_enterprise_P04.txt).

Pokrycie: p04_vat_macro_enterprise_v9.rego (Sekcje 8-10 + INN-01..INN-14) ·
main_jdg.rego (wiring: import + _package_decisions + POST-MERGE chain) ·
natywne testy Rego (tests/rego/test_p04_vat_macro_enterprise.rego) ·
zgodność z ADR-002 (progi z data.jdg.thresholds — zero hardcode).
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"

P04_REGO = RULES / "p04_vat_macro_enterprise_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"
P04_NATIVE_TEST = JDG_ROOT / "tests" / "rego" / "test_p04_vat_macro_enterprise.rego"


# ═══════════════════ SEKCJA 8 — ROZWIĄZANIA SYSTEMOWE ═══════════════════

class TestSection8Systemic:
    @pytest.fixture(scope="class")
    def text(self):
        return P04_REGO.read_text(encoding="utf-8")

    def test_proportion_calculator_present(self, text):
        assert "proportion_calculator :=" in text
        assert "multi_year_period_years :=" in text
        assert "Art. 90" in text and "Art. 91" in text

    def test_multi_year_5_10_years(self, text):
        assert "multi_year_period_years := 10 {" in text
        assert "} else := 5 {" in text
        assert "is_real_estate" in text

    def test_bad_debt_tracker_present(self, text):
        assert "bad_debt_tracker :=" in text
        assert "creditor_correction_allowed" in text
        assert "debtor_sanction_30pct" in text
        assert "Art. 89a" in text and "Art. 89b" in text

    def test_bad_debt_90_days_threshold(self, text):
        assert "bad_debt_days" in text
        assert "90" in text

    def test_ksef_sanction_monitor_present(self, text):
        assert "ksef_sanction_monitor :=" in text
        assert "106na" in text
        assert "2026-02-01" in text

    def test_kasowa_monitor_present(self, text):
        assert "kasowa_monitor :=" in text
        assert "Art. 21" in text


# ═══════════════════ SEKCJA 9 — GENIALNE POMYSŁY (14) ═══════════════════

class TestSection9Genius:
    @pytest.fixture(scope="class")
    def text(self):
        return P04_REGO.read_text(encoding="utf-8")

    def test_14_innovations_marked(self, text):
        count = len(re.findall(r"P04-INN-\d+", text))
        assert count >= 14, f"Oznaczonych innowacji: {count} < 14"

    def test_innovations_present(self, text):
        for name in [
            "vat_digital_twin",
            "carousel_detector",
            "twin_rate_from_keywords",
            "zero_defect_vat",
            "defect_list",
            "reconciliation_engine",
            "auto_mpp_system",
            "whitelist_guard",
            "rate_drift_guard",
            "sanctions_calculator",
            "correcting_invoice_detector",
            "innovations_summary",
        ]:
            assert name in text, f"Brak innowacji: {name}"

    def test_activation_flag(self, text):
        assert "p04_vat_macro_check" in text

    def test_digital_twin_sandbox(self, text):
        assert '"sandboxed": true' in text
        assert '"verdict_class": "SIMULATED"' in text

    def test_carousel_mtic(self, text):
        assert "mtic_risk" in text
        assert "CRITICAL" in text

    def test_zero_defect_invariants(self, text):
        assert "F2-VAT-ZERO-DEFECT" in text
        assert "RATE_NOT_IN_SET" in text

    def test_polish_declension_stems(self, text):
        # Odporność na deklinację: "pieczywa i mleka" → rdzenie "pieczyw"/"mlek"
        assert '"pieczyw"' in text
        assert '"mlek"' in text
        assert '"książk"' in text

    def test_annex15_fallback(self, text):
        assert "annex15_cn_map" in text
        assert "p04_default_annex15_cn" in text
        assert '"7207"' in text

    def test_safe_report_accessors(self, text):
        for acc in ["report_proportion", "report_bad_debt", "report_twin",
                    "report_carousel", "report_recon", "report_mpp",
                    "report_whitelist", "report_drift", "report_sanctions"]:
            assert acc in text, f"Brak akcesora raportu: {acc}"


# ═══════════════════ ADR-002 — ZERO HARDCODE PROGÓW ═══════════════════

class TestAdr002Thresholds:
    @pytest.fixture(scope="class")
    def text(self):
        return P04_REGO.read_text(encoding="utf-8")

    def test_thresholds_from_data(self, text):
        assert "data.jdg.thresholds" in text
        assert "mpp_mandatory_threshold" in text
        assert "bad_debt_days" in text

    def test_progi_definitions_use_data(self, text):
        # Każda definicja progu (także ksef_sanction_cap) musi czytać z
        # data.jdg.thresholds — zero hardcode (ADR-002), bez ślepej plamki
        # dla sekcji progów.
        progi = text.split("PROGI ZEWNĘTRZNE")[1].split("SEKCJA 8")[0]
        for name in ["mpp_threshold", "bad_debt_days", "exemption_limit",
                     "ksef_sanction_cap", "eur_pln_rate"]:
            line = next(l for l in progi.splitlines() if l.strip().startswith(name))
            assert "data.jdg.thresholds" in line, f"Twardy próg: {name}"
        assert "2000000 * 4.3" not in text  # kurs EUR hardcoded
        assert "eur_pln_rate" in text

    def test_no_hardcoded_comparisons_in_rules(self, text):
        # Odejmij sekcję progów — same reguły nie mogą zawierać twardych
        # porównań (fallbacki w object.get są dozwolone przez ADR-002).
        body = text.split("PROGI ZEWNĘTRZNE")[-1]
        for token in [">= 15000", "> 15000", ">= 90", "> 90", ">= 200000",
                      "> 200000", ">= 500000", "8600000"]:
            assert token not in body, f"Twarde porównanie w regułach: {token}"


# ═══════════════════ MAIN_JDG WIRING ═══════════════════

class TestMainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.p04_vat_macro_enterprise" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.p04_vat_macro_enterprise": p04_vat_macro_enterprise.decide' in text

    def test_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "safe_merge(p04_vat_macro_enterprise.decide," in text

    def test_chain_order(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        # P04 najgłębiej w łańcuchu: po p03_vat_macro_innovations, przed fallback
        p03_pos = text.find("safe_merge(p03_vat_macro_innovations.decide,")
        p04_pos = text.find("safe_merge(p04_vat_macro_enterprise.decide,")
        fb_pos = text.find("fallback.decide", p04_pos)
        assert p03_pos != -1 and p04_pos != -1 and fb_pos != -1
        assert p03_pos < p04_pos < fb_pos


# ═══════════════════ NATYWNE TESTY REGO ═══════════════════

class TestNativeRegoTests:
    def test_native_test_file_exists(self):
        assert P04_NATIVE_TEST.exists(), "Brak tests/rego/test_p04_vat_macro_enterprise.rego"

    def test_native_test_cover_all_innovations(self):
        text = P04_NATIVE_TEST.read_text(encoding="utf-8")
        for name in [
            "test_proportion_",
            "test_bad_debt_",
            "test_digital_twin_",
            "test_carousel_",
            "test_zero_defect_",
            "test_reconciliation_",
            "test_auto_mpp_",
            "test_whitelist_",
            "test_rate_drift_",
            "test_sanctions_calculator",
            "test_correcting_invoice_",
            "test_kasowa_",
            "test_p04_main_report",
        ]:
            assert name in text, f"Brak natywnego testu: {name}"

    def test_native_test_min_count(self):
        text = P04_NATIVE_TEST.read_text(encoding="utf-8")
        assert text.count("test_") >= 20
