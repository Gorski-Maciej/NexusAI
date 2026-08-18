# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 HYPER PLAN45 / KONTEKSTY / KALENDARZ / LIMITY / SANKCJE —
# pytest (GLM52 P16)
# ═══════════════════════════════════════════════════════════════════════════════
import sys
from datetime import date
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(JDG_ROOT / "tools"))

from deadline_engine import (ALERT_DAYS, LEGAL_INTEREST, LEGAL_OP,  # noqa: E402
                             PUBLIC_HOLIDAYS, countdown, due_date_for,
                             is_holiday, late_interest, shifted_deadline)
from limits_registry import (ALERT_RATIO, LIMITS, check_limit,  # noqa: E402
                             forecast, get_limit)
from sanction_calculator import (SANCTIONS, calculate,  # noqa: E402
                                 sanction_amount)


# ── DEADLINE ENGINE (art. 12 § 5 OP — przesunięcia, alerty 7/3/1, art. 56) ───
class TestDeadlineEngine:
    def test_shifted_deadline_weekend(self):
        # 2026-04-25 = sobota → przesunięcie na 27.04 (poniedziałek)
        r = shifted_deadline(date(2026, 4, 25))
        assert r["shifted"] is True
        assert r["shifted_date"] == "2026-04-27"
        assert LEGAL_OP in r["legal_basis"]

    def test_shifted_deadline_working_day(self):
        r = shifted_deadline(date(2026, 4, 20))
        assert r["shifted"] is False
        assert r["shifted_date"] == "2026-04-20"

    def test_is_holiday_fixed(self):
        assert is_holiday(date(2026, 5, 1)) is True   # Święto Pracy
        assert is_holiday(date(2026, 11, 11)) is True  # Niepodległość
        assert is_holiday(date(2026, 4, 20)) is False

    def test_public_holidays_catalog(self):
        assert (1, 1) in PUBLIC_HOLIDAYS
        assert (12, 25) in PUBLIC_HOLIDAYS
        assert len(PUBLIC_HOLIDAYS) >= 9

    def test_due_date_vat_25th(self):
        due = due_date_for("vat_jpk_v7", date(2026, 4, 1))
        assert due == date(2026, 4, 27)  # 25.04 = sobota → 27.04

    def test_due_date_pit_annual(self):
        due = due_date_for("pit_annual", date(2026, 1, 15))
        assert due == date(2026, 4, 30)

    def test_due_date_offset_pcc3(self):
        due = due_date_for("pcc3", date(2026, 8, 1))
        assert due == date(2026, 8, 17)  # 14 dni → 15.08 (sobota) → przesunięcie na 17.08

    def test_due_date_unknown(self):
        assert due_date_for("nieznany", date(2026, 1, 1)) is None

    def test_countdown_red_alert(self):
        r = countdown("vat_jpk_v7", today=date(2026, 4, 26),
                      reference=date(2026, 4, 1))
        assert r["alert_level"] == "RED"
        assert r["due_date"] == "2026-04-27"
        assert r["overdue"] is False

    def test_countdown_amber_alert(self):
        r = countdown("vat_jpk_v7", today=date(2026, 4, 24),
                      reference=date(2026, 4, 1))
        assert r["alert_level"] == "AMBER"

    def test_countdown_overdue(self):
        r = countdown("vat_jpk_v7", today=date(2026, 5, 2),
                      reference=date(2026, 4, 1))
        assert r["overdue"] is True
        assert r["days_remaining"] == 0

    def test_alert_days_config(self):
        assert ALERT_DAYS == (7, 3, 1)

    def test_late_interest(self):
        r = late_interest(10_000, 30)
        assert r["interest_pln"] == round(10_000 * 0.0975 * 30 / 365, 2)
        assert LEGAL_INTEREST in r["legal_basis"]


# ── LIMITS REGISTRY (ADR-002 — jeden punkt prawdy) ────────────────────────────
class TestLimitsRegistry:
    def test_get_limit_vat113(self):
        r = get_limit("vat_113")
        assert r["value"] == 200_000
        assert r["unit"] == "PLN"
        assert "Art. 113" in r["legal_basis"]

    def test_get_limit_unknown(self):
        r = get_limit("nieznany")
        assert "error" in r

    def test_check_limit_below(self):
        r = check_limit("vat_113", 100_000)
        assert r["status"] == "BELOW"
        assert r["ratio"] == 0.5

    def test_check_limit_near(self):
        r = check_limit("vat_113", 195_000)
        assert r["status"] == "NEAR"
        assert r["ratio"] >= ALERT_RATIO

    def test_check_limit_exceeded(self):
        r = check_limit("vat_113", 250_000)
        assert r["status"] == "EXCEEDED"

    def test_forecast_projection(self):
        r = forecast("vat_113", current=100_000, monthly_rate=20_000,
                     as_of=date(2026, 1, 1))
        assert r["months_to_exceed"] == 6  # (200k-100k)/20k + 1
        assert r["projected_exceedance"] == "2026-07-01"

    def test_forecast_no_growth(self):
        r = forecast("vat_113", current=50_000, monthly_rate=0)
        assert r["status"] == "NO_GROWTH"
        assert r["projected_exceedance"] is None

    def test_registry_covers_glm52_domains(self):
        for key in ["vat_113", "pit0_young", "tax_scale_threshold",
                    "lump_sum_2m_eur", "mpp_15k", "maly_zus_120k",
                    "donations_6pct", "ksef_sanction", "bdo_fine_194",
                    "rodo_fine_max", "aml_sanction_max"]:
            assert key in LIMITS, f"brak limitu {key}"


# ── SANCTION CALCULATOR (VAT 112b, KSeF 112e, KKS, BDO, RODO, AML + ulgi) ────
class TestSanctionCalculator:
    def test_vat_30pct(self):
        r = sanction_amount("vat_30pct", tax_understated=100_000)
        assert r["amount"] == 30_000
        assert "Art. 112b" in r["legal_basis"]

    def test_ksef_fixed(self):
        r = sanction_amount("ksef_500k")
        assert r["amount"] == 500_000

    def test_kks_daily(self):
        r = sanction_amount("kks_daily")
        assert r["amount"] == 270.0 * 30

    def test_bdo_fixed(self):
        r = sanction_amount("bdo_5000")
        assert r["amount"] == 5_000
        assert "odpadach" in r["legal_basis"]

    def test_rodo_20m_eur(self):
        r = sanction_amount("rodo_20m_eur")
        assert r["amount"] == 20_000_000
        assert r["unit"] == "EUR"

    def test_aml_1m_pln(self):
        r = sanction_amount("aml_1m_pln")
        assert r["amount"] == 1_000_000
        assert "praniu pieniędzy" in r["legal_basis"]

    def test_unknown_sanction(self):
        r = sanction_amount("nieznana")
        assert "error" in r

    def test_calculate_total(self):
        r = calculate(["vat_30pct", "bdo_5000"], tax_understated=100_000)
        assert r["total_pln"] == 35_000
        assert len(r["offenses"]) == 2

    def test_calculate_mitigation_czynny_zal(self):
        r = calculate(["vat_30pct"], tax_understated=100_000,
                      mitigation="czynny_żal")
        assert r["mitigation"]["reduction_pct"] == 0.0
        assert r["total_pln"] == 0.0
        assert "Kodeks karny skarbowy" in r["mitigation"]["legal_basis"]

    def test_calculate_mitigation_dobrowolne(self):
        r = calculate(["vat_30pct"], tax_understated=100_000,
                      mitigation="dobrowolne_poddanie")
        assert r["mitigation"]["reduction_pct"] == 50.0
        assert r["total_pln"] == 15_000

    def test_catalog_keys(self):
        for key in ["vat_30pct", "ksef_500k", "kks_daily", "bdo_5000",
                    "rodo_20m_eur", "aml_1m_pln"]:
            assert key in SANCTIONS


# ── WIRING PAS 53 (main_jdg.rego) ─────────────────────────────────────────────
class TestWiringP53:
    def test_final_verdict_p53_exists(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p53 = safe_merge(final_verdict_p52," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p53," in text

    def test_hyper_imports_present(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        for pkg in ["general", "deadlines", "limits", "sanctions", "audit",
                    "family", "force_majeure", "fx", "edelivery", "procurement",
                    "solidarity", "wis", "mdr", "misc"]:
            assert f"import data.jdg.hyper.{pkg} as hyper_{pkg}" in text

    def test_deadline_monitor_wired(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "import data.jdg.deadline_monitor" in text
        assert '"jdg.deadline_monitor": deadline_monitor.decide' in text

    def test_hyper_thresholds_present(self):
        f = JDG_ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "hyper :=" in text
        assert "hyper_contexts :=" in text
        assert '"deadline_alert_7"' in text
        assert '"solidarity_threshold_pln"' in text
        assert '"interest_rate_annual_pct"' in text

    def test_hyper_legal_basis_canonical(self):
        # 107 reguł hyper skanonizowanych — brak placeholderów UNKNOWN_ACT
        for rel in ["rules/jdg/hyper/general/plan45.rego",
                    "rules/jdg/hyper/limits/plan45.rego",
                    "rules/jdg/hyper/deadlines/plan45.rego",
                    "rules/jdg/hyper/sanctions/plan45.rego"]:
            text = (JDG_ROOT / rel).read_text(encoding="utf-8")
            assert "UNKNOWN_ACT" not in text
            assert "Przepisy prawa podatkowego" not in text

    def test_hyper_quality_gate_tool_exists(self):
        f = JDG_ROOT / "tools" / "hyper_quality.py"
        assert f.exists()
        text = f.read_text(encoding="utf-8")
        assert "--gate" in text
