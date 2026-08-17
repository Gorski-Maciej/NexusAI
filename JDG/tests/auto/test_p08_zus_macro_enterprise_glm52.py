#!/usr/bin/env python3
"""
NexusAI JDG — Testy GLM52 P08 (ZUS MAKRO + ZDROWOTNA)
================================================================
Pokrycie: zus_calculator.py (składki z dowodem groszowym), health_tier_engine.py
(progi ryczałtu, korekta roczna, monitor 12 900 zł), zus_calendar.py (terminy
5/10/15/20 + weekend), reguła jdg.zus.health.tier_switch, allowlist niemutowalna,
thresholds ZUS (stopy, progi, 30-krotność).
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys_path_hack = __import__("sys")
sys_path_hack.path.insert(0, str(ROOT / "tools"))

from zus_calculator import (  # noqa: E402
    HEALTH_LINEAR_DEDUCT_LIMIT,
    MALY_PLUS_REVENUE_LIMIT,
    RATES,
    calculate,
    health_lump,
    relief_base,
    social_contributions,
)
from health_tier_engine import (  # noqa: E402
    TIER_AMOUNTS,
    annual_correction,
    linear_tracker,
    monthly_for,
    predict,
    simulate_tiers,
    tier_for,
)
from zus_calendar import (  # noqa: E402
    DEADLINES,
    annual_health_settlement,
    deadline_for,
    month_deadlines,
)

MAIN_REGO = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
HEALTH_REGO = ROOT / "rules" / "zus" / "health_contribution_enterprise.rego"


# ═══════════════ ZUS CALCULATOR — składki z dowodem ═══════════════

class TestZusCalculator:
    def test_social_rates_2026(self):
        assert RATES["pension"] == 0.1952
        assert RATES["disability"] == 0.08
        assert RATES["sickness"] == 0.0245
        assert RATES["accident"] == 0.0167

    def test_social_with_sickness_total(self):
        proofs = social_contributions(10000, sickness=True)
        total = sum(p.amount for p in proofs)
        assert total == pytest.approx(10000 * 0.3164, abs=0.01)

    def test_social_without_sickness(self):
        proofs = social_contributions(10000, sickness=False)
        total = sum(p.amount for p in proofs)
        assert total == pytest.approx(10000 * 0.2919, abs=0.01)

    def test_health_scale_9pct(self):
        r = calculate(10000, "PIT_SCALE", revenue=10000)
        assert r["health"]["amount"] == pytest.approx(900, abs=0.01)
        assert r["total_health"] == pytest.approx(900, abs=0.01)

    def test_health_linear_4_9pct(self):
        r = calculate(10000, "PIT_LINEAR", revenue=10000)
        assert r["health"]["amount"] == pytest.approx(490, abs=0.01)

    def test_health_lump_tiers(self):
        assert health_lump(40000).amount == 491.40
        assert health_lump(150000).amount == 819.00
        assert health_lump(350000).amount == 1474.20

    def test_proof_grosz_invariant(self):
        r = calculate(10000, "PIT_SCALE", revenue=10000)
        assert r["proof_grosz"] is True
        assert r["invariant_sum"] is True

    def test_relief_start_zero_social(self):
        base, msg = relief_base(4800, 8190, "start")
        assert base == 0.0
        assert "art. 18a" in msg.lower()

    def test_relief_preferential_30pct(self):
        base, _ = relief_base(4800, 8190, "preferential")
        assert base == pytest.approx(1440, abs=0.01)

    def test_relief_maly_plus_clamp(self):
        # dochód 120k/rok → 30% = 3000/mies, clamp [1440, 4914] → 3000
        base, msg = relief_base(4800, 8190, "maly_plus", prev_year_income=120000)
        assert base == pytest.approx(3000, abs=0.01)
        assert "18c" in msg

    def test_relief_maly_plus_low_clamp(self):
        # dochód 24k/rok → 30% = 600/mies < min 1440 → 1440
        base, _ = relief_base(4800, 8190, "maly_plus", prev_year_income=24000)
        assert base == pytest.approx(1440, abs=0.01)

    def test_maly_plus_revenue_limit(self):
        assert MALY_PLUS_REVENUE_LIMIT == 120000


# ═══════════════ HEALTH TIER ENGINE — progi ryczałtu ═══════════════

class TestHealthTierEngine:
    def test_tier_boundaries(self):
        assert tier_for(60000) == "TIER_I"
        assert tier_for(60001) == "TIER_II"
        assert tier_for(300000) == "TIER_II"
        assert tier_for(300001) == "TIER_III"

    def test_monthly_amounts(self):
        assert monthly_for(40000) == 491.40
        assert monthly_for(150000) == 819.00
        assert monthly_for(350000) == 1474.20
        assert TIER_AMOUNTS == (491.40, 819.00, 1474.20)

    def test_tier_switch_simulation(self):
        sim = simulate_tiers([40000, 50000, 20000, 10000])
        assert sim[0].tier == "TIER_I"
        # 90k cumulative → TIER_II
        assert sim[1].tier == "TIER_II"
        assert sim[1].tier_changed is True
        assert sim[1].previous_tier == "TIER_I"

    def test_tier3_transition(self):
        sim = simulate_tiers([250000, 100000])
        assert sim[1].tier == "TIER_III"
        assert sim[1].monthly_pln == 1474.20

    def test_annual_correction_overpayment(self):
        # zapłacono za 12 mies. TIER_II (819), ale przychód roczny 100k → nadpłata? nie:
        # należne = monthly_for(100k) * 12 = 819*12 = 9828; zapłacono 9828 → 0
        c = annual_correction([8000, 8000, 8000, 8000, 8000, 8000,
                               8000, 8000, 8000, 8000, 8000, 8000], 9828.0)
        assert c.difference == pytest.approx(0, abs=0.01)
        assert c.deadline == "2027-05-22"

    def test_annual_correction_underpayment(self):
        c = annual_correction([8000] * 12, 4000.0)
        assert c.is_overpayment is False

    def test_linear_tracker_12900_limit(self):
        # 12 × 10000 × 4,9% = 5880 < 12900 → brak nadwyżki
        t = linear_tracker([10000] * 12)
        assert t["annual_total"] == pytest.approx(5880, abs=0.01)
        assert t["excess_over_limit"] == 0.0
        assert t["deductible"] == pytest.approx(5880, abs=0.01)

    def test_linear_tracker_excess(self):
        # 12 × 30000 × 4,9% = 17640 > 14100 (2026) → nadwyżka 3540
        t = linear_tracker([30000] * 12)
        assert t["annual_total"] == pytest.approx(17640, abs=0.01)
        assert t["excess_over_limit"] == pytest.approx(3540, abs=0.01)
        assert t["deductible"] == pytest.approx(14100, abs=0.01)
        assert HEALTH_LINEAR_DEDUCT_LIMIT == 14100

    def test_predict_projection(self):
        p = predict([10000, 12000, 14000])
        assert p["projected_annual_revenue"] == pytest.approx(144000, abs=0.01)
        assert p["projected_tier"] == "TIER_II"


# ═══════════════ ZUS CALENDAR — terminy 5/10/15/20 ═══════════════

class TestZusCalendar:
    def test_deadline_days(self):
        assert set(DEADLINES.keys()) == {5, 10, 15, 20}

    def test_10th_weekday_no_shift(self):
        # 10.01.2026 to sobota? sprawdźmy: 2026-01-10 to sobota → przesunięcie
        due, shifted, _ = deadline_for(2026, 1, 10)
        assert shifted is True
        assert due.isoformat() == "2026-01-09"

    def test_10th_midweek_no_shift(self):
        # 2026-03-10 to wtorek → bez przesunięcia
        due, shifted, _ = deadline_for(2026, 3, 10)
        assert shifted is False
        assert due.isoformat() == "2026-03-10"

    def test_month_deadlines_count(self):
        hits = month_deadlines(2026, 2)
        assert len(hits) == 4

    def test_annual_health_settlement_may22(self):
        # 22.05.2027 to sobota → przesunięcie na piątek 21.05 (art. 47 ust. 3 SUS)
        a = annual_health_settlement(2026)
        assert a["due_date"] == "2027-05-21"
        assert a["shifted"] is True
        assert "22 maja" in a["obligation"]


# ═══════════════ REGUŁY — tier_switch + struktura ═══════════════

class TestZusRulesStructure:
    def test_tier_switch_rule_present(self):
        text = HEALTH_REGO.read_text(encoding="utf-8")
        assert "jdg.zus.health.tier_switch" in text
        assert "health_tier_switch_check" in text
        assert "lump_sum_cumulative_revenue" in text
        assert "Art. 81 ust. 2e-2f" in text

    def test_tier_switch_before_fallback(self):
        text = HEALTH_REGO.read_text(encoding="utf-8")
        assert text.index("health.tier_switch") < text.index("health.fallback")

    def test_braces_balanced(self):
        src = HEALTH_REGO.read_text(encoding="utf-8")
        clean = re.sub(r"#.*", "", src)
        clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', clean)
        assert clean.count("{") == clean.count("}")

    def test_zus_thresholds_present(self):
        text = THRESHOLDS.read_text(encoding="utf-8")
        for key in ["pension_rate", "disability_rate", "sickness_voluntary_rate",
                    "accident_rate", "health_lump_tier_1_limit",
                    "health_lump_tier_2_limit", "health_lump_tier_1_amount",
                    "health_lump_tier_2_amount", "health_lump_tier_3_amount",
                    "start_relief_months", "social_base_standard"]:
            assert key in text, f"Brak progu {key}"

    def test_native_zus_macro_test_exists(self):
        assert (ROOT / "tests" / "rego" / "test_native_zus_macro.rego").exists()

    def test_p08_tools_exist(self):
        for tool in ["zus_calculator", "health_tier_engine", "zus_calendar"]:
            assert (ROOT / "tools" / f"{tool}.py").exists(), f"Brak tools/{tool}.py"


# ═══════════════ OKABLOWANIE — main_jdg + niemutowalność ═══════════════

class TestZusWiring:
    def test_zus_packages_imported(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        for pkg in ["data.jdg.zus", "data.jdg.zus.sickness_benefits",
                    "data.jdg.zus.health_contribution"]:
            assert pkg in text, f"Brak importu {pkg}"

    def test_precision_engine_named_rules_present(self):
        # precision_engine to pakiet nazwanych reguł queryable (tier_transition,
        # maly_zus_plus_formula itd.) — sprawdzamy obecność reguł
        text = (ROOT / "rules" / "zus" / "health_precision_engine_v8.rego").read_text(
            encoding="utf-8")
        for rule in ["tier_transition", "maly_zus_plus_formula",
                     "annual_reconciliation", "deadline_calendar",
                     "sickness_waiting_tracker", "maternity_matrix"]:
            assert rule in text, f"Brak reguły {rule} w precision_engine"

    def test_immutable_allowlist_contains_zus(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.zus"' in text
        assert '"jdg.zus.health_contribution"' in text
        assert "immutable_verdict_allowlist" in text

    def test_zus_in_registry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.zus":' in text
        assert '"jdg.zus.health_contribution":' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p45" in text
        assert "final_verdict_post_merge" in text
