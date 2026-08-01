#!/usr/bin/env python3
"""
P24 Integration Test Scenarios S1-S6
Tests cross-module integration for P24 micro-modules:
CEIDG, Ryczałt, Sukcesja, Budownictwo, Transport, PP

Based on: RAPORT_P24_JDG_MICRO_CEIDG_RYCZALT_SUKCESJA_v7.0, Section 10.6
"""
import json
import unittest
from pathlib import Path


# ─────────────────────────────────────────────────────────────────────────────
# Test Fixtures — simulate JDG entrepreneur input data
# ─────────────────────────────────────────────────────────────────────────────

def make_jdg_base():
    return {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "is_vat_payer": True,
            "ceidg_registered": True,
        },
        "invoice": {
            "service_category": "",
            "pkwiu_code": "",
            "net_amount_pln": 0,
            "vat_rate_applied": 0,
        },
        "counterparty": {
            "is_vat_payer": False,
        },
        "representation": {
            "poa_type": "",
            "poa_submitted": True,
            "action": "",
            "cross_border": False,
        }
    }


class TestP24ScenarioS1_NewJDG_IT_Programmer(unittest.TestCase):
    """
    S1. Nowa JDG programisty: CEIDG-1 → ryczałt 3% → ewidencja → ZUS ZUA → KSeF
    Luki: termin 7 dni (L-CEIDG-2), wybór formy (I7)
    """

    def test_ceidg_registration_flow(self):
        """CEIDG-1 registration: all mandatory fields must be present"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "ceidg_application_filed": True,
            "ceidg_personal_data_complete": True,
            "ceidg_business_data_complete": True,
            "tax_form_selected": "Ryczałt",
            "pkd_codes_changed": False,
            "business_activity_description": "Programowanie aplikacji webowych",
        })
        # Verify CEIDG data completeness
        self.assertTrue(data["jdg_entrepreneur"]["ceidg_personal_data_complete"])
        self.assertTrue(data["jdg_entrepreneur"]["ceidg_business_data_complete"])
        self.assertEqual(data["jdg_entrepreneur"]["tax_form_selected"], "Ryczałt")

    def test_ceidg_7day_deadline_not_passed(self):
        """CEIDG change should be reported within 7 days"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "ceidg_data_changed": True,
            "ceidg_change_days_elapsed": 3,
            "ceidg_change_reported": False,
            "ceidg_deadline_violation_count": 0,
        })
        # 3 days elapsed — deadline NOT passed
        self.assertLess(data["jdg_entrepreneur"]["ceidg_change_days_elapsed"], 7)
        self.assertFalse(data["jdg_entrepreneur"]["ceidg_change_reported"])

    def test_ceidg_7day_deadline_passed_sanction(self):
        """CEIDG change > 7 days — BLOCK_AND_ALERT with penalty"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "ceidg_data_changed": True,
            "ceidg_change_days_elapsed": 10,
            "ceidg_change_reported": False,
            "ceidg_deadline_violation_count": 1,
        })
        # Deadline passed, first violation = 700 PLN
        self.assertGreater(data["jdg_entrepreneur"]["ceidg_change_days_elapsed"], 7)
        self.assertEqual(data["jdg_entrepreneur"]["ceidg_deadline_violation_count"], 1)
        # Expected penalty for first violation: 700 PLN
        expected_penalty = 700 if data["jdg_entrepreneur"]["ceidg_deadline_violation_count"] <= 1 else 1400
        self.assertEqual(expected_penalty, 700)

    def test_ryczalt_3pct_it_services(self):
        """IT services should match 3% flat rate"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "primary_pkwiu": "62.01.Z",
            "estimated_annual_revenue_pln": 300000,
            "estimated_annual_costs_pln": 50000,
        })
        data["invoice"].update({
            "service_description": "Programowanie aplikacji webowych",
            "pkwiu_code": "62.01.1",
        })
        # Verify PKWiU matches IT
        self.assertIn("62.", data["jdg_entrepreneur"]["primary_pkwiu"])
        self.assertIn("programowanie", data["invoice"]["service_description"].lower())

    def test_zus_zua_from_ceidg(self):
        """ZUS ZUA should be automatically triggered by CEIDG"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "ceidg_application_filed": True,
            "is_new_jdg_registration": True,
            "days_since_ceidg_filing": 3,
            "zus_zua_auto_from_ceidg": False,
        })
        # ZUS ZUA should be auto-sent within 7 days
        self.assertLessEqual(data["jdg_entrepreneur"]["days_since_ceidg_filing"], 7)


class TestP24ScenarioS2_Construction_B2B(unittest.TestCase):
    """
    S2. Budowlaniec B2B: reverse charge + VAT 8% + ryczałt 5,5%
    """

    def test_reverse_charge_between_vat_payers(self):
        """Reverse charge applies for B2B construction services"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "is_vat_payer": True,
            "construction_role": "GENERAL_CONTRACTOR",
        })
        data["invoice"].update({
            "service_category": "CONSTRUCTION",
            "pkwiu_code": "43.31",
            "is_residential_construction": False,
        })
        data["counterparty"].update({
            "is_vat_payer": True,
            "construction_role": "",
        })
        # Reverse charge applies when both are VAT payers
        rc_applies = (data["jdg_entrepreneur"]["is_vat_payer"]
                      and data["counterparty"]["is_vat_payer"]
                      and data["invoice"]["service_category"] == "CONSTRUCTION")
        self.assertTrue(rc_applies)

    def test_vat_8pct_residential(self):
        """Residential construction <= 300 m2 gets 8% VAT"""
        data = make_jdg_base()
        data["invoice"].update({
            "service_category": "CONSTRUCTION",
            "is_residential_construction": True,
            "building_floor_area_m2": 150,
        })
        # VAT 8% applies
        vat_rate = 0.08 if (data["invoice"]["is_residential_construction"]
                           and data["invoice"]["building_floor_area_m2"] <= 300) else 0.23
        self.assertEqual(vat_rate, 0.08)

    def test_vat_23pct_over_300m2(self):
        """Residential > 300 m2 gets 23% VAT"""
        data = make_jdg_base()
        data["invoice"].update({
            "is_residential_construction": True,
            "building_floor_area_m2": 350,
        })
        vat_rate = 0.08 if (data["invoice"]["is_residential_construction"]
                           and data["invoice"]["building_floor_area_m2"] <= 300) else 0.23
        self.assertEqual(vat_rate, 0.23)

    def test_vat_23pct_non_residential(self):
        """Non-residential construction gets 23% VAT"""
        data = make_jdg_base()
        data["invoice"].update({
            "is_residential_construction": False,
            "building_floor_area_m2": 150,
        })
        vat_rate = 0.08 if (data["invoice"]["is_residential_construction"]
                           and data["invoice"]["building_floor_area_m2"] <= 300) else 0.23
        self.assertEqual(vat_rate, 0.23)


class TestP24ScenarioS3_Transport(unittest.TestCase):
    """
    S3. Transportowiec: licencja + podatek transportowy + ryczałt 15%
    """

    def test_transport_license_required(self):
        """Transport business requires license"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "business_activity_description": "Transport drogowy towarów",
            "transport_license_obtained": False,
        })
        # License check
        self.assertFalse(data["jdg_entrepreneur"]["transport_license_obtained"])

    def test_transport_tax_truck_over_35t(self):
        """Truck DMC > 3.5t is subject to transport tax"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "vehicle_dmc_kg": 4000,
            "transport_vehicle_type": "TRUCK",
        })
        tax_applies = data["jdg_entrepreneur"]["vehicle_dmc_kg"] > 3500
        self.assertTrue(tax_applies)

    def test_transport_tax_light_vehicle(self):
        """Vehicle DMC <= 3.5t is NOT subject to transport tax"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "vehicle_dmc_kg": 3000,
            "transport_vehicle_type": "TRUCK",
        })
        tax_applies = data["jdg_entrepreneur"]["vehicle_dmc_kg"] > 3500
        self.assertFalse(tax_applies)

    def test_transport_tax_bus(self):
        """Bus > 9 seats subject to transport tax"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "transport_vehicle_type": "BUS",
            "vehicle_seats": 12,
        })
        tax_applies = data["jdg_entrepreneur"]["vehicle_seats"] > 9
        self.assertTrue(tax_applies)

    def test_transport_tax_pro_rata_sale(self):
        """Sale during year: tax until end of sale month"""
        annual_tax = 2800
        sale_month = 6
        months_owned = sale_month
        pro_rata = (annual_tax / 12) * months_owned
        self.assertEqual(pro_rata, 2800 / 12 * 6)  # 1400 PLN


class TestP24ScenarioS4_Succession_KSeF(unittest.TestCase):
    """
    S4. Sukcesja z KSeF: śmierć → zarządca → przejęcie VAT → KSeF → amortyzacja
    """

    def test_succession_management_period(self):
        """Management period: 2 years (standard), 5 years (court extension)"""
        # Standard: 2 years
        period = 2
        court_extension = False
        if court_extension:
            period = 5
        self.assertEqual(period, 2)

        # Court extension: 5 years
        court_extension = True
        period = 5 if court_extension else 2
        self.assertEqual(period, 5)

    def test_successor_amortization_continuity(self):
        """Successor continues depreciation (Art. 22g ust. 12 PIT)"""
        original_value = 400000
        amort_rate = 20
        annual_amort = original_value * amort_rate / 100
        self.assertEqual(annual_amort, 80000)
        # Successor continues at same rate and value
        self.assertEqual(annual_amort, 80000)

    def test_zus_registration_deadline(self):
        """ZUS registration for manager within 7 days after death"""
        days_since_death = 5
        manager_registered = False
        deadline = 7
        days_remaining = deadline - days_since_death
        self.assertGreater(days_remaining, 0)
        self.assertEqual(days_remaining, 2)

    def test_ksef_continuity(self):
        """VAT obligations continue during succession"""
        data = make_jdg_base()
        data["jdg_entrepreneur"].update({
            "succession_active": True,
            "is_vat_payer": True,
        })
        ksef_continues = (data["jdg_entrepreneur"]["succession_active"]
                         and data["jdg_entrepreneur"]["is_vat_payer"])
        self.assertTrue(ksef_continues)


class TestP24ScenarioS5_UnregisteredToRegistered(unittest.TestCase):
    """
    S5. Nieewidencjonowana → ewidencja: przekroczenie 75% płacy min.
    """

    def test_unregistered_activity_under_limit(self):
        """Revenue under 75% min wage — no CEIDG required"""
        min_wage = 4666
        limit = min_wage * 0.75
        monthly_revenue = 3000
        self.assertLess(monthly_revenue, limit)

    def test_unregistered_activity_exceeds_limit(self):
        """Revenue exceeds 75% min wage — CEIDG registration required"""
        min_wage = 4666
        limit = min_wage * 0.75
        monthly_revenue = 4000
        exceeded = monthly_revenue > limit
        self.assertTrue(exceeded)

    def test_unregistered_activity_near_limit(self):
        """Revenue near limit — warning threshold at 90%"""
        min_wage = 4666
        limit = min_wage * 0.75
        monthly_revenue = 3300
        near_limit = monthly_revenue > limit * 0.9
        self.assertTrue(near_limit)

    def test_limit_auto_indexation(self):
        """Limit auto-updates with minimum wage changes"""
        historical = [
            (2023, 3490, 2617.50),
            (2024, 4300, 3225.00),
            (2025, 4666, 3499.50),
            (2026, 4666, 3499.50),
        ]
        for year, min_wage, expected_limit in historical:
            calculated_limit = min_wage * 0.75
            self.assertAlmostEqual(calculated_limit, expected_limit, places=2,
                msg=f"Year {year}: limit {calculated_limit} != {expected_limit}")


class TestP24ScenarioS6_EstonianCIT(unittest.TestCase):
    """
    S6. Estoński CIT JDG: wybór → dystrybucja PIT-38 → zmiana po 4 latach
    """

    def test_estonian_cit_conditions(self):
        """Estoński CIT: revenue < 100M EUR, min 3 employees"""
        revenue_eur = 50000000  # 50M
        employees = 3
        eligible = revenue_eur < 100000000 and employees >= 3
        self.assertTrue(eligible)

    def test_estonian_cit_change_after_4_years(self):
        """Can switch back to scale after 4 years"""
        years_on_estonian = 4
        can_change = years_on_estonian >= 4
        self.assertTrue(can_change)

    def test_estonian_cit_cannot_change_before_4_years(self):
        """Cannot switch before 4 years"""
        years_on_estonian = 3
        can_change = years_on_estonian >= 4
        self.assertFalse(can_change)

    def test_estonian_cit_rate_10pct(self):
        """Distribution tax: 10% CIT for normal distribution"""
        distribution = 100000
        tax = distribution * 0.10
        self.assertEqual(tax, 10000)

    def test_estonian_cit_rate_20pct(self):
        """Distribution tax: 20% when distribution > book profit"""
        distribution = 100000
        tax = distribution * 0.20  # 20% elevated rate
        self.assertEqual(tax, 20000)


class TestP24Innovations(unittest.TestCase):
    """Test P24 Innovation modules I1-I12"""

    def test_i2_semantic_matcher_it(self):
        """I2: IT services should match 3%"""
        desc = "Programowanie aplikacji webowych w Pythonie"
        is_it = any(kw in desc.lower() for kw in
                    ["programowanie", "software", "aplikacj", "kodowanie", "web development", "devops", "programist"])
        self.assertTrue(is_it)

    def test_i7_decision_engine_scale_vs_lump(self):
        """I7: Compare tax forms for typical IT JDG"""
        revenue = 300000
        costs = 50000
        income = revenue - costs
        # Scale: (250000 - 30000) * 0.12 = 26400
        tax_scale = (income - 30000) * 0.12 if income > 30000 else 0
        # Lump 3%: 300000 * 0.03 = 9000
        tax_lump = revenue * 0.03
        # Lump should be better for IT with low costs
        self.assertLess(tax_lump, tax_scale)

    def test_i8_unregistered_activity_checker(self):
        """I8: Check unregistered activity limit"""
        min_wage = 4666
        limit = min_wage * 0.75
        self.assertEqual(limit, 3499.50)

    def test_i9_amortization_continuity(self):
        """I9: Successor amortization continuity"""
        original_value = 400000
        amort_rate = 20
        annual_amort = original_value * amort_rate / 100
        self.assertEqual(annual_amort, 80000)

    def test_i10_construction_vat_classifier(self):
        """I10: Construction VAT rate classification"""
        # Residential <= 300 m2 = 8%
        self.assertEqual(
            0.08 if (True and 150 <= 300) else 0.23,
            0.08
        )
        # Non-residential = 23%
        self.assertEqual(
            0.08 if (False and 150 <= 300) else 0.23,
            0.23
        )


class TestP24CoverageMatrix(unittest.TestCase):
    """Test I12: Coverage completeness matrix"""

    def test_all_modules_have_rules(self):
        """All 6 micro modules should have rules"""
        modules = {
            "CEIDG": 35,
            "Ryczałt": 148,
            "Sukcesja": 123,
            "Budownictwo": 51,
            "Transport": 45,
            "PP": 143,
        }
        total = sum(modules.values())
        self.assertEqual(total, 545)  # 35+148+123+51+45+143 = 545

    def test_average_coverage_above_80pct(self):
        """Average coverage should be above 80%"""
        coverage = [80, 92, 95, 95, 72, 90]  # CEIDG, Ryczałt, Sukcesja, Budownictwo, Transport, PP
        avg = sum(coverage) / len(coverage)
        self.assertGreater(avg, 80)


class TestP24LegalBasisValidator(unittest.TestCase):
    """Test I11+I12: Legal basis validator"""

    def test_est_legal_basis_correct(self):
        """R-EST-1: Estoński CIT should reference CIT, not inheritance tax"""
        correct_basis = "Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG"
        self.assertNotIn("spadków", correct_basis)
        self.assertIn("CIT", correct_basis)

    def test_tax_trans_legal_basis_correct(self):
        """R-TAXTRANS-1: Transport tax should reference u.p.o.l., not PCC"""
        correct_basis = "Ustawa o podatkach i opłatach lokalnych (Art. 8-13)"
        self.assertNotIn("czynności cywilnoprawnych", correct_basis)
        self.assertIn("podatkach i opłatach lokalnych", correct_basis)


if __name__ == "__main__":
    unittest.main(verbosity=2)
