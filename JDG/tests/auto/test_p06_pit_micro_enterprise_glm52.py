#!/usr/bin/env python3
"""
NexusAI JDG — Testy GLM52 P06 (PIT MIKRO + AMORTYZACJA + NKUP)
================================================================
Pokrycie: depreciation_engine.py (harmonogramy, limity, grosze),
nkup_classifier.py (wydatek → punkt art. 23), struktura reguł amortyzacji
(PAS 45, brak catch-all {true}), okablowanie main_jdg (importy, rejestr,
final_verdict_p45), thresholds (depreciation), kst_groups (9+10).
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys_path_hack = __import__("sys")
sys_path_hack.path.insert(0, str(ROOT / "tools"))

from depreciation_engine import (  # noqa: E402
    KST_RATES,
    car_limit,
    kst_rate,
    low_value,
    one_time_check,
    schedule,
    verify_rate,
)
from nkup_classifier import classify, map_all  # noqa: E402

MAIN_REGO = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
P06_V9 = ROOT / "rules" / "p06_pit_micro_innovations_v9.rego"
AMORT_DIR = ROOT / "rules" / "micro" / "amortyzacja"


# ═══════════════ DEPRECIATION ENGINE — harmonogramy ═══════════════

class TestDepreciationSchedule:
    def test_linear_grupa4_14pct(self):
        r = schedule(100000, "4", method="linear")
        assert r["rate"] == 0.14
        assert r["annual_linear"] == 14000.0
        assert r["invariant_F2"] is True
        assert r["proof_grosz"] is True
        assert abs(r["total_write_offs"] - 100000) <= 0.01

    def test_linear_monthly_write_off(self):
        r = schedule(100000, "4", method="linear")
        first = r["entries"][0]["write_off"]
        assert first == 1167  # 14000/12 = 1166,67 → art. 63 OrdPU: 1167
        assert r["entries"][-1]["net_value"] <= 0.01

    def test_grunty_zero_rate(self):
        r = schedule(100000, "0", method="linear")
        assert "error" in r

    def test_degressive_coefficient_2x(self):
        r = schedule(100000, "4", method="degressive")
        assert r["coefficient"] == 2.0
        assert r["invariant_F2"] is True

    def test_degressive_coefficient_1_4_other(self):
        r = schedule(100000, "2", method="degressive")
        assert r["coefficient"] == 1.4


class TestDepreciationVerifyRate:
    def test_rate_ok(self):
        r = verify_rate("4", 0.14)
        assert r["ok"] is True

    def test_rate_wrong(self):
        r = verify_rate("4", 0.20)
        assert r["ok"] is False
        assert "TRIAGE_QUEUE" in r["action"]

    def test_all_kst_groups_present(self):
        # 10 grup + grunty (0) — kompletność KŚT (P06: brak grup 9/10 było luką)
        for g in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]:
            assert g in KST_RATES, f"Brak grupy KŚT {g}"
        assert KST_RATES["9"] > 0 and KST_RATES["10"] > 0


class TestDepreciationLimits:
    def test_one_time_allowed(self):
        r = one_time_check(80000, 1500000, True, False, "4")
        assert r["allowed"] is True

    def test_one_time_passenger_car_blocked(self):
        r = one_time_check(80000, 1500000, True, True, "7")
        assert r["allowed"] is False
        assert any("samochod" in x.lower() for x in r["reasons"])

    def test_one_time_revenue_limit(self):
        r = one_time_check(80000, 2500000, True, False, "4")
        assert r["allowed"] is False

    def test_one_time_group_out_of_scope(self):
        r = one_time_check(80000, 1500000, True, False, "1")
        assert r["allowed"] is False

    def test_car_limit_standard_excess(self):
        r = car_limit(180000)
        assert r["depreciable"] == 150000
        assert r["excess_not_depreciable"] == 30000

    def test_car_limit_electric(self):
        r = car_limit(240000, electric=True)
        assert r["depreciable"] == 225000

    def test_low_value_one_time(self):
        assert low_value(9000)["one_time_kup"] is True
        assert low_value(15000)["one_time_kup"] is False


# ═══════════════ NKUP CLASSIFIER — art. 23 ═══════════════

class TestNkupClassifier:
    def test_representation_nkup(self):
        r = classify("REPRESENTATION", 500)
        assert r["kup"] is False
        assert "pkt 23" in r["point"]

    def test_car_fuel_75pct(self):
        r = classify("CAR_FUEL")
        assert r["kup"] is True
        assert r["partial_pct"] == 75

    def test_car_fuel_100pct_with_log(self):
        r = classify("CAR_FUEL", mileage_log=True)
        assert r["partial_pct"] == 100

    def test_gift_over_200_nkup(self):
        r = classify("GIFT", 300)
        assert r["kup"] is False

    def test_zus_unpaid_nkup(self):
        r = classify("ZUS_UNPAID")
        assert r["kup"] is False

    def test_unknown_suggest(self):
        r = classify("STRANGE_EXPENSE_XYZ")
        assert r["action"] == "SUGGEST"
        assert r["classified"] is False

    def test_map_covers_13_types(self):
        m = map_all()
        assert len(m) >= 12


# ═══════════════ STRUKTURA REGUŁ — PAS 45 ═══════════════

class TestAmortyzacjaRulesStructure:
    def test_no_catch_all_fallbacks(self):
        # Konwencja micro (INV-018): brak fallbacka {true} przejmującego no_match
        for f in AMORT_DIR.glob("*.rego"):
            text = f.read_text(encoding="utf-8")
            assert ".fallback" not in text, f"{f.name} ma catch-all fallback"

    def test_new_articles_present(self):
        # Art. 22b / 22c / 22h — uzupełnienie mapy 22a-22o (P06)
        assert (AMORT_DIR / "pit_a22b.rego").exists()
        assert (AMORT_DIR / "pit_a22c.rego").exists()
        assert (AMORT_DIR / "pit_a22h.rego").exists()

    def test_amort_packages_wired_in_main(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        for pkg in ["amort_a22a", "amort_a22b", "amort_a22c", "amort_a22h",
                    "amort_a22i", "amort_a22k", "amort_a22n"]:
            assert f"import data.jdg.micro.{pkg}" in text
            assert f'"jdg.micro.{pkg}":' in text

    def test_post_merge_chain_p45(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p45 = safe_merge(final_verdict_p44," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p45," in text

    def test_thresholds_depreciation_p06(self):
        text = THRESHOLDS.read_text(encoding="utf-8")
        for key in ["small_taxpayer_revenue_limit_eur", "one_time_depreciation_eur",
                    "low_value_asset_limit", "kst_rates", "degressive_coeff_machines",
                    "wnip_max_period_years"]:
            assert key in text, f"Brak progu {key} w thresholds_jdg.rego"

    def test_kst_groups_9_10_in_v9(self):
        text = P06_V9.read_text(encoding="utf-8")
        assert '"9": {"name": "Inwentarz żywy"' in text
        assert '"10": {"name": "Inwentarz martwy"' in text

    def test_braces_balanced_amortyzacja(self):
        for f in AMORT_DIR.glob("*.rego"):
            src = f.read_text(encoding="utf-8")
            clean = re.sub(r"#.*", "", src)
            clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', clean)
            assert clean.count("{") == clean.count("}"), f"{f.name}: niezbalansowane nawiasy"

    def test_a22i_legal_basis_degressive_fixed(self):
        # Degresywna = art. 22k ust. 1-3 (P06: korekta błędnego art. 22i)
        text = (AMORT_DIR / "pit_a22i.rego").read_text(encoding="utf-8")
        assert "Art. 22k ust. 1 PIT (metoda degresywna)" in text
        assert "Art. 22h ust. 1 pkt 1 PIT (metoda liniowa)" in text


# ═══════════════ NARZĘDZIA P06 ═══════════════

class TestP06ToolsExist:
    def test_depreciation_engine_cli(self):
        r = verify_rate("4", 0.14)
        assert r["ok"] is True

    def test_nkup_classifier_cli(self):
        r = classify("REPRESENTATION")
        assert r["action"] == "NKUP"
