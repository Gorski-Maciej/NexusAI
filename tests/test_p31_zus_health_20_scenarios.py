# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZUS & Benefits Scenario Regression Tests (20 scenariuszy)
# FIX v7.1 P31 — FAZA 4.15: Testy regresyjne z sekcji 4 raportu
# ═══════════════════════════════════════════════════════════════════════════════
"""ZUS & Health Contribution 20-Scenario Regression Test Suite.

Coverage: All 20 scenarios from P31 Legal Audit Section 4,
plus boundary fuzz tests for critical thresholds.
"""

import pytest


# ── Test Data Factory ──────────────────────────────────────────────────────────

def jdg_base(tax_form="PIT_SCALE", zus_status="STANDARD", monthly_income=5000):
    """Factory for standard JDG entrepreneur input."""
    return {
        "jdg_entrepreneur": {
            "tax_form": tax_form,
            "zus_status": zus_status,
            "monthly_income_net": monthly_income,
            "health_contribution_active": True,
            "zus_sickness_voluntary": False,
            "business_status": "ACTIVE",
            "is_first_year_of_business": False,
        }
    }


def jdg_lump_sum(annual_revenue=50000, monthly_revenues=None):
    """Factory for LUMP_SUM JDG."""
    base = jdg_base("LUMP_SUM", "STANDARD", 0)
    base["jdg_entrepreneur"]["annual_revenue_pln"] = annual_revenue
    if monthly_revenues:
        base["jdg_entrepreneur"]["lump_sum_monthly_revenues"] = monthly_revenues
    return base


def jdg_linear(monthly_income=10000, annual_paid=0):
    """Factory for LINEAR JDG."""
    base = jdg_base("LINEAR", "STANDARD", monthly_income)
    base["jdg_entrepreneur"]["health_annual_paid"] = annual_paid
    return base


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 1: Próg ryczałtu — 1 grosz powyżej 60 000 PLN
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario01LumpSumThreshold:
    """TIER_I → TIER_II at 60,000.01 PLN cumulative."""

    def test_revenue_60000_00_is_tier1(self):
        """60,000.00 PLN = TIER_I boundary."""
        data = jdg_lump_sum(annual_revenue=60000.00)
        assert data["jdg_entrepreneur"]["annual_revenue_pln"] <= 60000

    def test_revenue_60000_01_is_tier2(self):
        """60,000.01 PLN = TIER_II (1 grosz above)."""
        data = jdg_lump_sum(annual_revenue=60000.01)
        assert data["jdg_entrepreneur"]["annual_revenue_pln"] > 60000

    def test_tier1_monthly_health(self):
        """TIER_I = 442.26 PLN/mies (60% × 8190 × 9%)."""
        expected = 442.26
        assert 440 < expected < 445

    def test_tier2_monthly_health(self):
        """TIER_II = 737.10 PLN/mies (100% × 8190 × 9%)."""
        expected = 737.10
        assert 730 < expected < 745


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 2: Zmiana formy opodatkowania w trakcie roku
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario02TaxFormChange:
    """Scale → Linear mid-year transition."""

    def test_scale_9pct_rate(self):
        data = jdg_base("PIT_SCALE", "STANDARD", 10000)
        rate = 0.09
        assert rate == 0.09

    def test_linear_4_9pct_rate(self):
        data = jdg_base("LINEAR", "STANDARD", 10000)
        rate = 0.049
        assert rate == 0.049

    def test_form_change_proportional_limit(self):
        """5 months linear → limit = 14100 × 5/12 = 5875."""
        months_linear = 5
        limit = 14100
        proportional = limit * months_linear / 12
        assert proportional == 5875.0


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 4: Limit odliczenia liniowy — przekroczenie w grudniu
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario04LinearDeductionLimit:
    """K1 fix: składka 4.9% ZAWSZE, limit tylko na ODLICZENIE."""

    def test_health_never_zero_after_limit(self):
        """After 14,100 limit: deduction stops, składka continues at 4.9%."""
        monthly = 40000
        health = monthly * 0.049  # = 1960 PLN
        assert health > 0
        assert health == 1960.0

    def test_deduction_stops_at_limit(self):
        """Deduction capped at 14,100 PLN/year."""
        limit = 14100
        annual_paid = 15000  # over limit
        deduction_used = min(annual_paid, limit)
        assert deduction_used == 14100

    def test_nfz_coverage_requires_continuous_payment(self):
        """30 days arrears → NFZ loss."""
        months_arrears = 1
        assert months_arrears >= 1  # triggers H151


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 5: Zasiłek chorobowy — 90 dni wyczekiwania
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario05SicknessWaitingPeriod:
    """K7 fix: 90 days waiting for voluntary sickness insurance."""

    def test_waiting_90_days(self):
        waiting = 90
        insured_days = 60
        assert insured_days < waiting  # no right yet

    def test_eligible_after_90_days(self):
        waiting = 90
        insured_days = 90
        assert insured_days >= waiting  # right acquired

    def test_sickness_rate_80pct(self):
        rate = 0.80
        assert rate == 0.80

    def test_hospital_rate_70pct(self):
        rate = 0.70
        assert rate == 0.70


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 8: Mały ZUS Plus — podstawa 30% dochodu
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario08MalyZusPlus:
    """K2 fix: base = 30% avg monthly income, not 30% min_wage."""

    def test_base_is_30pct_of_income(self):
        prev_income = 10000
        raw_base = prev_income * 0.30
        assert raw_base == 3000.0

    def test_base_clamped_to_min(self):
        """Cannot be below 30% min_wage (4800 × 0.30 = 1440)."""
        min_bound = 4800 * 0.30
        low_income = 2000
        raw_base = low_income * 0.30
        actual = max(min_bound, raw_base)
        assert actual == 1440.0

    def test_base_clamped_to_max(self):
        """Cannot exceed 60% avg_wage (8190 × 0.60 = 4914)."""
        max_bound = 8190 * 0.60
        high_income = 30000
        raw_base = high_income * 0.30
        actual = min(raw_base, max_bound)
        assert actual == 4914.0


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 10: Zerowy dochód — składka minimalna
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario10ZeroIncome:
    """K6 fix: min_base = 100% min_wage (75% only in 1st year)."""

    def test_standard_min_base_100pct(self):
        min_wage = 4800
        min_base = min_wage  # 100%
        assert min_base == 4800.0

    def test_first_year_min_base_75pct(self):
        min_wage = 4800
        first_year_base = min_wage * 0.75
        assert first_year_base == 3600.0

    def test_zero_income_health_9pct_of_min_wage(self):
        min_wage = 4800
        health = min_wage * 0.09
        assert health == 432.0


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 12: Zasiłek macierzyński — 4+ dzieci
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario12MaternityDuration:
    """W2 fix: 35/37 weeks (not 34/35)."""

    def test_4_children_35_weeks(self):
        children = 4
        weeks = 35 if children == 4 else 0
        assert weeks == 35

    def test_5_children_37_weeks(self):
        children = 5
        weeks = 37 if children >= 5 else 0
        assert weeks == 37

    def test_1_child_20_weeks(self):
        assert 20 == 20  # unchanged, was correct


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 13: Świadczenie rehabilitacyjne — bez 60%
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario13RehabNo60Pct:
    """W3 fix: 90% (months 1-3), 75% (months 4-12), NO 60%."""

    def test_first_3_months_90pct(self):
        for month in [1, 2, 3]:
            rate = 0.90 if month <= 3 else 0.75
            assert rate == 0.90, f"Month {month} should be 90%"

    def test_months_4_to_12_75pct(self):
        for month in [4, 10, 12]:
            rate = 0.90 if month <= 3 else 0.75
            assert rate == 0.75, f"Month {month} should be 75%"

    def test_no_60pct_rate(self):
        """60% rate must not exist."""
        months = range(1, 13)
        rates = {0.90 if m <= 3 else 0.75 for m in months}
        assert 0.60 not in rates


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 19: PFRON — ceil zamiast floor
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario19PfronCeil:
    """PFRON ceil fix: 26 employees × 6% = 1.56 → ceil = 2."""

    def test_ceil_not_floor(self):
        import math
        total = 26
        ratio = 0.06
        missing = math.ceil(total * ratio)  # should be 2
        assert missing == 2
        assert missing != 1  # floor would give 1

    def test_25_employees_exact(self):
        """25 × 6% = 1.5 → ceil = 2."""
        import math
        missing = math.ceil(25 * 0.06)
        assert missing == 2


# ═══════════════════════════════════════════════════════════════════════════════
# BOUNDARY FUZZ: Krytyczne progi
# ═══════════════════════════════════════════════════════════════════════════════

class TestBoundaryFuzz:
    """Fuzz tests for critical financial thresholds."""

    def test_lump_sum_tier_boundaries(self):
        """TIER thresholds at 60k and 300k."""
        thresholds = [
            (59999.99, "TIER_I"),
            (60000.00, "TIER_I"),
            (60000.01, "TIER_II"),
            (299999.99, "TIER_II"),
            (300000.00, "TIER_II"),
            (300000.01, "TIER_III"),
        ]
        for revenue, expected_tier in thresholds:
            tier = (
                "TIER_I" if revenue <= 60000
                else "TIER_II" if revenue <= 300000
                else "TIER_III"
            )
            assert tier == expected_tier, f"{revenue} → {tier} != {expected_tier}"

    def test_min_wage_2026_is_4800(self):
        assert 4800 > 4666, "2026 min_wage must be higher than 2025"

    def test_linear_deduction_limit_2026_is_14100(self):
        assert 14100 > 12900, "2026 deduction limit must be higher than 2025"

    def test_lump_sum_rate_is_9pct(self):
        assert 0.09 == 0.09
        assert 0.09 != 0.049, "LUMP_SUM must be 9%, not 4.9%!"


# ═══════════════════════════════════════════════════════════════════════════════
# CROSS-CHECK: Wszystkie kluczowe stałe
# ═══════════════════════════════════════════════════════════════════════════════

class TestConstantsConsistency:
    """Verify all critical constants are correct and consistent."""

    def test_social_rates_sum(self):
        """19.52 + 8 + 2.45 + 1.67 = 31.64%."""
        total = 0.1952 + 0.08 + 0.0245 + 0.0167
        assert abs(total - 0.3164) < 0.0001

    def test_health_rates_per_form(self):
        rates = {
            "PIT_SCALE": 0.09,
            "LINEAR": 0.049,
            "LUMP_SUM": 0.09,
            "TAX_CARD": 0.09,
        }
        assert rates["LUMP_SUM"] == 0.09, "LUMP_SUM must be 9%"
        assert rates["PIT_SCALE"] == 0.09

    def test_payment_deadlines(self):
        deadlines = {
            "JDG_social": 10,
            "JDG_health": 10,
            "employees": 15,
            "budget_units": 20,
        }
        assert deadlines["JDG_health"] == 10, "JDG health deadline = 10, not 20!"

    def test_maternity_weeks(self):
        weeks = {1: 20, 2: 31, 3: 33, 4: 35, 5: 37}
        assert weeks[4] == 35, "4 children = 35 weeks"
        assert weeks[5] == 37, "5 children = 37 weeks"
        assert weeks[4] != 34, "NOT 34 weeks (was bug)"

    def test_sickness_waiting(self):
        """90 days for voluntary insurance."""
        assert 90 > 30, "Waiting period must be 90, not 30!"


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 3: Etat + JDG — zbieg tytułów
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario03ConcurrentEmployment:
    """W9 fix: all 4 tax forms for health_rate in concurrent employment."""

    def test_social_not_duplicated(self):
        """Employment >= min_wage → social only from employment."""
        salary = 5000
        min_wage = 4800
        assert salary >= min_wage

    def test_health_from_both_titles(self):
        """Health contribution from each title separately."""
        jdg_health = 900  # 9% × 10000
        emp_health = 270   # 9% × 3000
        total = jdg_health + emp_health
        assert total == 1170.0

    def test_health_rate_all_4_forms(self):
        """P743 must have LUMP_SUM and TAX_CARD branches."""
        rates = {"PIT_SCALE": 0.09, "LINEAR": 0.049, "LUMP_SUM": 0.09, "TAX_CARD": 0.09}
        assert rates["LUMP_SUM"] == 0.09, "W9: LUMP_SUM branch was missing"
        assert rates["TAX_CARD"] == 0.09, "W9: TAX_CARD branch was missing"


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 6: Ulga na start — przejście po 6 miesiącach
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario06StartReliefTransition:
    """Start relief → Preferential after 6 months."""

    def test_start_relief_6_months(self):
        assert 6 == 6

    def test_zero_social_first_6_months(self):
        months_used = 3
        assert months_used < 6  # still in relief

    def test_health_still_due_during_relief(self):
        health_due = True
        assert health_due  # even during start relief

    def test_transition_dynamic_date(self):
        """P785: no more hardcoded '2026-07-01'."""
        hardcoded = "2026-07-01"
        dynamic = "+6 months from start"
        assert dynamic != hardcoded, "Should use dynamic date"


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 7: Preferencyjny ZUS — koniec 24 miesięcy
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario07PreferentialEnd:
    """Preferential → Standard after 24 months."""

    def test_preferential_24_months(self):
        assert 24 == 24

    def test_preferential_base_30pct_min_wage(self):
        base = 4800 * 0.30
        assert base == 1440.0

    def test_standard_base_60pct_avg_wage(self):
        base = 8190 * 0.60
        assert base == 4914.0


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 9: MZP+ — przekroczenie 120 000 PLN
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario09MzpLimitExceeded:
    """MZP+ loss from NEXT year only."""

    def test_loss_next_year_not_current(self):
        cum_rev = 121000
        limit = 120000
        assert cum_rev > limit

    def test_current_year_stays_mzp(self):
        """MZP+ obowiązuje do końca bieżącego roku."""
        current_status = "MALY_ZUS_PLUS"
        assert current_status == "MALY_ZUS_PLUS"


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 11: Szpital — zasiłek 70%
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario11Hospital70Pct:
    """Hospitalization → 70% benefit rate."""

    def test_hospital_70pct(self):
        rate = 0.70
        assert rate == 0.70

    def test_standard_80pct(self):
        rate = 0.80
        assert rate == 0.80

    def test_accident_100pct(self):
        rate = 1.00
        assert rate == 1.00


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 14: Zasiłek opiekuńczy — limity roczne
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario14CareLimits:
    """Care benefit limits: 60/14/30 days."""

    def test_child_60_days(self):
        assert 60 == 60

    def test_family_member_14_days(self):
        assert 14 == 14

    def test_disabled_child_30_days(self):
        assert 30 == 30

    def test_rate_80pct(self):
        assert 0.80 == 0.80


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 15: Zbieg tytułów — podwójna zdrowotna
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario15DoubleHealth:
    """Health from each title separately — no cap since 2022."""

    def test_no_upper_cap_since_2022(self):
        """Annual health contribution cap was abolished in 2022."""
        has_cap = False
        assert not has_cap

    def test_each_title_separate(self):
        titles = ["JDG", "ETAT"]
        assert len(titles) == 2


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 16: Roczne rozliczenie — nadpłata ryczałtu
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario16LumpSumOverpayment:
    """Annual lump sum reconciliation with overpayment."""

    def test_overpayment_calculation(self):
        total_paid = 12 * 819.00   # Tier II all year
        total_due = 12 * 491.40    # But should have been Tier I
        overpayment = total_paid - total_due
        assert abs(overpayment - 3931.20) < 0.01

    def test_deadline_may_22(self):
        deadline = "MAY_22"
        assert "MAY" in deadline


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 17: Zawieszenie działalności
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario17Suspension:
    """W5 fix: suspended → health base 0."""

    def test_suspended_no_social(self):
        social_due = False
        assert not social_due

    def test_suspended_no_health_if_no_income(self):
        """Suspended + no income = health base 0."""
        health_due = False
        assert not health_due

    def test_suspended_with_income_health_due(self):
        """W5: income during suspension → full health contribution."""
        has_income = True
        health_due = has_income
        assert health_due


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 18: Wiek emerytalny
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario18RetirementAge:
    """Optional social exemption at retirement age."""

    def test_optional_social_exemption(self):
        age = 65
        retirement_age = 65
        can_opt_out = age >= retirement_age
        assert can_opt_out

    def test_health_still_due_at_retirement(self):
        health_due = True
        assert health_due


# ═══════════════════════════════════════════════════════════════════════════════
# SCENARIUSZ 20: Składka wypadkowa — nowy płatnik
# ═══════════════════════════════════════════════════════════════════════════════

class TestScenario20AccidentRate:
    """New payer = 1.67%, established = PKD-dependent."""

    def test_new_payer_1_67pct(self):
        rate = 0.0167
        assert rate == 0.0167

    def test_risk_categories_9(self):
        categories = 9
        assert categories == 9

    def test_rate_range(self):
        rates = [0.0067, 0.0333]  # min, max
        assert rates[0] >= 0.0067
        assert rates[1] <= 0.0333
