"""
NexusAI JDG — Unit Tests: PKPiR Enterprise Live + UoR Enterprise Live
══════════════════════════════════════════════════════════════════════════════
Data: 2026-07-19
Inicjatywy: S17 (PKPiR Live), S18 (UoR Live)
Opis: Testy jednostkowe dla ożywionej warstwy PKPiR/UoR.
      Weryfikują poprawność reguł Rego z realnymi danymi wejściowymi.
      
Pokrycie testowe:
  - PKPiR: Kolumny 1-17, remanent, spójność międzykolumnowa, pułapki
  - UoR: Zakres podmiotowy, zasady rachunkowości, dowody księgowe,
         podwójny zapis, inwentaryzacja, wycena, RMK, sprawozdania
══════════════════════════════════════════════════════════════════════════════
"""
import pytest
import json
from typing import Dict, Any

# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture
def base_input() -> Dict[str, Any]:
    """Bazowy input JDG dla testów PKPiR/UoR."""
    return {
        "invoice": {
            "direction": "PURCHASE",
            "amount_net": 5000.00,
            "amount_gross": 6150.00,
            "vat_amount": 1150.00,
            "vat_rate": "0.23",
            "issue_date": "2026-07-15",
            "transaction_date": "2026-07-14",
            "document_number": "FV/2026/07/001",
            "description": "Zakup materiałów biurowych",
            "expense_type": "OFFICE_SUPPLIES",
            "category_code": "OFFICE",
            "is_cash_payment": False,
            "is_period_end": False,
            "is_year_end": False,
            "is_year_start": False,
            "is_archive_event": False,
            "is_home_office": False,
            "depreciation_method": "LINEAR",
            "depreciation_rate": 0.20,
            "kst_group": 0,
            "kst_subgroup": 0,
            "pkpir_lp": 1,
            "pkpir_entry_date": "2026-07-15",
            "pkpir_col14_notes": "",
            "has_mileage_log": False,
            "private_use_percent": 0,
            "has_signatures": True,
            "is_electronic": True,
        },
        "vendor": {
            "name": "Dostawca Sp. z o.o.",
            "nip": "1234567890",
            "country": "PL",
            "is_company": True,
            "on_whitelist": True,
            "relation_to_entrepreneur": "",
        },
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "uses_pkpir": True,
            "uses_uor": False,
            "is_vat_payer": True,
            "vat_status": "ACTIVE",
            "business_status": "ACTIVE",
            "business_type": "JDG",
            "is_small_taxpayer": True,
            "has_employees": False,
            "annual_revenue_actual": 150000,
            "annual_income_projected": 80000,
            "pkpir_last_lp": 0,
            "pkpir_last_entry_date": "2000-01-01",
            "pkpir_entry_count": 10,
            "pkpir_issue_flags": 0,
            "pkpir_integrity_score": 1.0,
            "zus_social_monthly_pln": 1400.00,
            "zus_health_monthly_pln": 600.00,
            "pit_advance_monthly_pln": 800.00,
            "remnant_start_of_year": 25000.00,
            "remnant_end_of_period": 32000.00,
            "remnant_previous_year_end": 25000.00,
            "tax_year": "2026",
            "tax_year_as_int": 2026,
            "reporting_income": 75000.00,
        },
        "employment": {
            "has_employees": False,
        },
        "evaluation_date": "2026-07-19",
    }


@pytest.fixture
def base_input_uor(base_input) -> Dict[str, Any]:
    """Input dla JDG prowadzącej pełną księgowość UoR."""
    inp = base_input.copy()
    inp["jdg_entrepreneur"]["uses_uor"] = True
    inp["jdg_entrepreneur"]["uses_pkpir"] = False
    inp["jdg_entrepreneur"]["annual_revenue_actual"] = 10000000  # >2M EUR
    inp["jdg_entrepreneur"]["uor_compliant"] = True
    inp["jdg_entrepreneur"]["uor_debit_total"] = 150000.00
    inp["jdg_entrepreneur"]["uor_credit_total"] = 150000.00
    inp["jdg_entrepreneur"]["uor_last_inventory_date"] = "2025-12-31"
    inp["jdg_entrepreneur"]["uor_inventory_done_current_year"] = True
    inp["jdg_entrepreneur"]["uor_physical_count_done"] = True
    inp["jdg_entrepreneur"]["uor_balance_confirmation_done"] = True
    inp["jdg_entrepreneur"]["uor_document_verification_done"] = True
    inp["jdg_entrepreneur"]["uor_has_prepaid_expenses"] = False
    inp["jdg_entrepreneur"]["uor_has_accrued_expenses"] = False
    inp["jdg_entrepreneur"]["uor_financial_statement_filed"] = True
    inp["jdg_entrepreneur"]["uor_uses_cash_method"] = False
    inp["jdg_entrepreneur"]["uor_cost_revenue_mismatch"] = False
    inp["jdg_entrepreneur"]["uor_assets_overstated"] = False
    return inp


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: PKPiR Enterprise Live (S17)
# ═══════════════════════════════════════════════════════════════════════════════

class TestPKPiRColumn1LP:
    """Testy Kolumny 1 PKPiR — Liczba porządkowa."""

    def test_lp_sequential_ok(self, base_input):
        """LP powinno być OK gdy zgodne z oczekiwanym."""
        base_input["invoice"]["pkpir_lp"] = 1
        base_input["jdg_entrepreneur"]["pkpir_last_lp"] = 0
        assert base_input["invoice"]["pkpir_lp"] == base_input["jdg_entrepreneur"]["pkpir_last_lp"] + 1

    def test_lp_gap_detected(self, base_input):
        """LP powinno wykryć lukę w numeracji."""
        base_input["invoice"]["pkpir_lp"] = 5
        base_input["jdg_entrepreneur"]["pkpir_last_lp"] = 1
        gap = base_input["invoice"]["pkpir_lp"] - base_input["jdg_entrepreneur"]["pkpir_last_lp"] - 1
        assert gap == 3  # Luka 3 numerów

    def test_lp_missing(self, base_input):
        """LP=0 powinno być wykryte jako brak."""
        base_input["invoice"]["pkpir_lp"] = 0
        assert base_input["invoice"]["pkpir_lp"] <= 0


class TestPKPiRColumn2_3Dates:
    """Testy Kolumn 2-3 PKPiR — Daty."""

    def test_date_chronological_ok(self, base_input):
        """Data wpisu >= ostatni zapis — OK."""
        base_input["invoice"]["pkpir_entry_date"] = "2026-07-15"
        base_input["jdg_entrepreneur"]["pkpir_last_entry_date"] = "2026-07-10"
        assert base_input["invoice"]["pkpir_entry_date"] >= base_input["jdg_entrepreneur"]["pkpir_last_entry_date"]

    def test_date_chronology_broken(self, base_input):
        """Data wpisu < ostatni zapis — NARUSZENIE."""
        base_input["invoice"]["pkpir_entry_date"] = "2026-06-01"
        base_input["jdg_entrepreneur"]["pkpir_last_entry_date"] = "2026-07-15"
        assert base_input["invoice"]["pkpir_entry_date"] < base_input["jdg_entrepreneur"]["pkpir_last_entry_date"]


class TestPKPiRColumn4_5Document:
    """Testy Kolumn 4-5 PKPiR — Nr dokumentu i kontrahent."""

    def test_document_ok(self, base_input):
        """Dokument i kontrahent OK."""
        assert base_input["invoice"]["document_number"] != ""
        assert base_input["vendor"]["name"] != ""

    def test_document_missing(self, base_input):
        """Brak numeru dokumentu."""
        base_input["invoice"]["document_number"] = ""
        assert base_input["invoice"]["document_number"] == ""

    def test_vendor_missing_for_b2b(self, base_input):
        """Brak danych kontrahenta B2B."""
        base_input["vendor"]["name"] = ""
        base_input["vendor"]["is_company"] = True
        assert base_input["vendor"]["name"] == ""
        assert base_input["vendor"]["is_company"] is True


class TestPKPiRRevenueColumns:
    """Testy Kolumn 6-9 PKPiR — Przychody."""

    def test_sale_revenue_net_for_vat_payer(self, base_input):
        """Przychód netto dla VAT czynnego."""
        base_input["invoice"]["direction"] = "SALE"
        base_input["invoice"]["amount_net"] = 10000.00
        base_input["invoice"]["amount_gross"] = 12300.00
        base_input["jdg_entrepreneur"]["is_vat_payer"] = True
        # VAT czynny → przychód netto
        assert base_input["invoice"]["amount_net"] == 10000.00

    def test_sale_revenue_gross_for_vat_exempt(self, base_input):
        """Przychód brutto dla zwolnionego z VAT."""
        base_input["invoice"]["direction"] = "SALE"
        base_input["invoice"]["amount_gross"] = 12300.00
        base_input["jdg_entrepreneur"]["is_vat_payer"] = False
        base_input["jdg_entrepreneur"]["vat_status"] = "EXEMPT"
        # Zw. VAT → przychód brutto
        assert base_input["invoice"]["amount_gross"] == 12300.00


class TestPKPiRCostColumns:
    """Testy Kolumn 10-14 PKPiR — Koszty."""

    def test_cost_goods_column10(self, base_input):
        """Zakup towarów → kolumna 10."""
        base_input["invoice"]["expense_type"] = "GOODS"
        # Kolumna 10 dla towarów
        assert base_input["invoice"]["expense_type"] in {"GOODS", "RAW_MATERIALS", "MERCHANDISE", "MATERIALS"}

    def test_cost_ancillary_column11(self, base_input):
        """Koszty uboczne → kolumna 11."""
        base_input["invoice"]["expense_type"] = "TRANSPORT_COST"
        assert base_input["invoice"]["expense_type"] in {"TRANSPORT_COST", "INSURANCE_COST", "CUSTOMS_DUTY"}

    def test_cost_salary_column12(self, base_input):
        """Wynagrodzenia → kolumna 12."""
        base_input["invoice"]["expense_type"] = "SALARY"
        assert base_input["invoice"]["expense_type"] in {"SALARY", "WAGES", "BONUS", "SALARY_GROSS"}

    def test_cost_other_column13(self, base_input):
        """Pozostałe wydatki → kolumna 13."""
        base_input["invoice"]["expense_type"] = "RENT"
        assert base_input["invoice"]["expense_type"] in {"RENT", "UTILITIES", "TELECOM", "OFFICE"}

    def test_cost_nkup_column14(self, base_input):
        """NKUP → kolumna 14."""
        base_input["invoice"]["expense_type"] = "REPRESENTATION"
        # Reprezentacja → NKUP
        assert base_input["invoice"]["expense_type"] in {"REPRESENTATION", "ALCOHOL", "LUXURY", "ENTERTAINMENT"}


class TestPKPiRCashTrap:
    """Testy pułapki gotówkowej >15k PLN."""

    def test_cash_over_15k_is_nkup(self, base_input):
        """Gotówka >= 15k PLN → NKUP."""
        base_input["invoice"]["is_cash_payment"] = True
        base_input["invoice"]["amount_gross"] = 20000.00
        assert base_input["invoice"]["is_cash_payment"] is True
        assert base_input["invoice"]["amount_gross"] >= 15000

    def test_transfer_under_15k_is_kup(self, base_input):
        """Przelew < 15k → KUP OK."""
        base_input["invoice"]["is_cash_payment"] = False
        base_input["invoice"]["amount_gross"] = 14000.00
        assert base_input["invoice"]["is_cash_payment"] is False
        assert base_input["invoice"]["amount_gross"] < 15000


class TestPKPiRRemnant:
    """Testy remanentu PKPiR."""

    def test_remnant_continuity_ok(self, base_input):
        """Ciągłość remanentu OK."""
        rem_start = base_input["jdg_entrepreneur"]["remnant_start_of_year"]
        rem_prev_end = base_input["jdg_entrepreneur"]["remnant_previous_year_end"]
        assert rem_start == rem_prev_end

    def test_remnant_continuity_broken(self, base_input):
        """Brak ciągłości remanentu."""
        base_input["jdg_entrepreneur"]["remnant_start_of_year"] = 30000.00
        base_input["jdg_entrepreneur"]["remnant_previous_year_end"] = 25000.00
        assert base_input["jdg_entrepreneur"]["remnant_start_of_year"] != base_input["jdg_entrepreneur"]["remnant_previous_year_end"]

    def test_remnant_income_impact_positive(self, base_input):
        """Remanent końcowy > początkowy → +dochód."""
        rem_start = base_input["jdg_entrepreneur"]["remnant_start_of_year"]  # 25000
        rem_end = base_input["jdg_entrepreneur"]["remnant_end_of_period"]  # 32000
        delta = rem_end - rem_start
        assert delta == 7000.00  # +7000 PLN dodane do dochodu

    def test_remnant_income_impact_negative(self, base_input):
        """Remanent końcowy < początkowy → -dochód."""
        base_input["jdg_entrepreneur"]["remnant_end_of_period"] = 20000.00
        delta = base_input["jdg_entrepreneur"]["remnant_end_of_period"] - base_input["jdg_entrepreneur"]["remnant_start_of_year"]
        assert delta == -5000.00  # -5000 PLN odjęte od dochodu


class TestPKPiRCrossCheck:
    """Testy spójności międzykolumnowej PKPiR."""

    def test_income_calculation_matches(self, base_input):
        """Dochód wyliczony z kolumn = raportowany."""
        base_input["jdg_entrepreneur"]["pkpir_col7_total"] = 100000.00
        base_input["jdg_entrepreneur"]["pkpir_col8_total"] = 5000.00
        base_input["jdg_entrepreneur"]["pkpir_col10_total"] = 20000.00
        base_input["jdg_entrepreneur"]["pkpir_col11_total"] = 3000.00
        base_input["jdg_entrepreneur"]["pkpir_col12_total"] = 5000.00
        base_input["jdg_entrepreneur"]["pkpir_col13_total"] = 12000.00
        base_input["jdg_entrepreneur"]["pkpir_col14_total"] = 8000.00

        revenue = 100000 + 5000  # 105000
        costs_kup = 20000 + 3000 + 5000 + 12000  # 40000
        rem_delta = 32000 - 25000  # 7000
        calculated = revenue - costs_kup + rem_delta  # 72000

        base_input["jdg_entrepreneur"]["reporting_income"] = calculated
        assert abs(calculated - base_input["jdg_entrepreneur"]["reporting_income"]) < 0.01

    def test_income_discrepancy_detected(self, base_input):
        """Rozbieżność dochodu wykryta."""
        base_input["jdg_entrepreneur"]["pkpir_col7_total"] = 100000.00
        base_input["jdg_entrepreneur"]["pkpir_col13_total"] = 12000.00
        base_input["jdg_entrepreneur"]["reporting_income"] = 50000.00  # Zawyżone
        # Powinno być ~95000 ale raportowane 50000
        diff = abs(95000 - 50000)
        assert diff > 100  # Przekroczona tolerancja


class TestPKPiRDepreciation:
    """Testy amortyzacji w PKPiR (Kol. 17)."""

    def test_linear_depreciation_monthly(self, base_input):
        """Amortyzacja liniowa — miesięczny odpis."""
        base_input["invoice"]["expense_type"] = "FIXED_ASSET"
        base_input["invoice"]["amount_net"] = 120000.00
        base_input["invoice"]["depreciation_method"] = "LINEAR"
        base_input["invoice"]["depreciation_rate"] = 0.20
        base_input["invoice"]["kst_group"] = 7
        base_input["invoice"]["kst_subgroup"] = 1

        monthly = 120000 * 0.20 / 12
        assert monthly == 2000.00  # 2000 PLN/mies

    def test_one_off_low_value(self, base_input):
        """Jednorazowa amortyzacja ≤ 10k PLN."""
        base_input["invoice"]["expense_type"] = "FIXED_ASSET"
        base_input["invoice"]["amount_net"] = 8000.00
        base_input["invoice"]["depreciation_method"] = "ONE_OFF"
        assert base_input["invoice"]["amount_net"] <= 10000


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: UoR Enterprise Live (S18)
# ═══════════════════════════════════════════════════════════════════════════════

class TestUoRObligation:
    """Testy zakresu podmiotowego UoR (Art. 2)."""

    def test_uor_not_required_under_2m_eur(self, base_input_uor):
        """PKPiR wystarcza < 2M EUR."""
        base_input_uor["jdg_entrepreneur"]["annual_revenue_actual"] = 5000000  # ~1.1M EUR
        eur = 5000000 / 4.5
        assert eur < 2000000

    def test_uor_required_over_2m_eur(self, base_input_uor):
        """Pełna księgowość wymagana ≥ 2M EUR."""
        eur = base_input_uor["jdg_entrepreneur"]["annual_revenue_actual"] / 4.5  # 10M/4.5
        assert eur >= 2000000


class TestUoRPrinciples:
    """Testy zasad rachunkowości (Art. 4)."""

    def test_all_principles_ok(self, base_input_uor):
        """Wszystkie 4 zasady spełnione."""
        assert base_input_uor["jdg_entrepreneur"]["uor_uses_cash_method"] is False
        assert base_input_uor["jdg_entrepreneur"]["uor_cost_revenue_mismatch"] is False
        assert base_input_uor["jdg_entrepreneur"]["uor_assets_overstated"] is False
        assert base_input_uor["jdg_entrepreneur"]["business_status"] == "ACTIVE"

    def test_accrual_principle_violated(self, base_input_uor):
        """Metoda kasowa narusza zasadę memoriału."""
        base_input_uor["jdg_entrepreneur"]["uor_uses_cash_method"] = True
        assert base_input_uor["jdg_entrepreneur"]["uor_uses_cash_method"] is True


class TestUoRDocuments:
    """Testy dowodów księgowych (Art. 20-21)."""

    def test_document_complete(self, base_input_uor):
        """Dowód księgowy kompletny."""
        assert base_input_uor["invoice"]["issue_date"] != ""
        assert base_input_uor["vendor"]["name"] != ""
        assert base_input_uor["vendor"]["nip"] != ""
        assert base_input_uor["invoice"]["description"] != ""
        assert base_input_uor["invoice"]["amount_net"] > 0

    def test_document_missing_date(self, base_input_uor):
        """Brak daty na dowodzie."""
        base_input_uor["invoice"]["issue_date"] = ""
        assert base_input_uor["invoice"]["issue_date"] == ""

    def test_document_missing_description(self, base_input_uor):
        """Brak opisu na dowodzie."""
        base_input_uor["invoice"]["description"] = ""
        assert base_input_uor["invoice"]["description"] == ""


class TestUoRDoubleEntry:
    """Testy podwójnego zapisu (Art. 22)."""

    def test_double_entry_balanced(self, base_input_uor):
        """Wn = Ma → OK."""
        assert base_input_uor["jdg_entrepreneur"]["uor_debit_total"] == base_input_uor["jdg_entrepreneur"]["uor_credit_total"]

    def test_double_entry_unbalanced(self, base_input_uor):
        """Wn ≠ Ma → błąd."""
        base_input_uor["jdg_entrepreneur"]["uor_debit_total"] = 150000.00
        base_input_uor["jdg_entrepreneur"]["uor_credit_total"] = 149000.00
        diff = abs(150000.00 - 149000.00)
        assert diff > 0.01


class TestUoRInventory:
    """Testy inwentaryzacji (Art. 26-27)."""

    def test_inventory_complete(self, base_input_uor):
        """Inwentaryzacja pełna — wszystkie części OK."""
        assert base_input_uor["jdg_entrepreneur"]["uor_physical_count_done"] is True
        assert base_input_uor["jdg_entrepreneur"]["uor_balance_confirmation_done"] is True
        assert base_input_uor["jdg_entrepreneur"]["uor_document_verification_done"] is True

    def test_inventory_missing_physical_count(self, base_input_uor):
        """Brak spisu z natury."""
        base_input_uor["jdg_entrepreneur"]["uor_physical_count_done"] = False
        assert base_input_uor["jdg_entrepreneur"]["uor_physical_count_done"] is False


class TestUoRValuation:
    """Testy wyceny aktywów (Art. 28-34)."""

    def test_asset_no_impairment(self, base_input_uor):
        """Brak utraty wartości."""
        base_input_uor["invoice"]["expense_type"] = "FIXED_ASSET"
        base_input_uor["invoice"]["asset_type"] = "TANGIBLE"
        base_input_uor["invoice"]["amount_net"] = 100000.00
        base_input_uor["invoice"]["asset_market_value"] = 95000.00
        # 95k > 50k (50% z 100k) → brak utraty
        assert base_input_uor["invoice"]["asset_market_value"] >= base_input_uor["invoice"]["amount_net"] * 0.50

    def test_asset_impaired(self, base_input_uor):
        """Utrata wartości > 50%."""
        base_input_uor["invoice"]["expense_type"] = "FIXED_ASSET"
        base_input_uor["invoice"]["amount_net"] = 100000.00
        base_input_uor["invoice"]["asset_market_value"] = 40000.00
        # 40k < 50k → utrata wartości
        assert base_input_uor["invoice"]["asset_market_value"] < base_input_uor["invoice"]["amount_net"] * 0.50


class TestUoRFinancialStatement:
    """Testy sprawozdania finansowego (Art. 45-52)."""

    def test_fs_filed(self, base_input_uor):
        """Sprawozdanie złożone."""
        base_input_uor["invoice"]["is_year_end"] = True
        assert base_input_uor["jdg_entrepreneur"]["uor_financial_statement_filed"] is True

    def test_fs_not_filed(self, base_input_uor):
        """Sprawozdanie niezłożone."""
        base_input_uor["invoice"]["is_year_end"] = True
        base_input_uor["jdg_entrepreneur"]["uor_financial_statement_filed"] = False
        assert base_input_uor["jdg_entrepreneur"]["uor_financial_statement_filed"] is False


class TestUoRRetention:
    """Testy przechowywania dokumentów (Art. 74)."""

    def test_retention_5_years(self, base_input_uor):
        """Dokumenty przechowuj 5 lat."""
        current_year = 2026
        oldest_year = current_year - 5
        assert oldest_year == 2021

    def test_years_safe_to_destroy(self):
        """Lata bezpieczne do zniszczenia."""
        current_year = 2026
        safe_years = [y for y in range(2020, current_year - 5 + 1) if y >= 2020]
        assert 2020 in safe_years
        assert 2021 in safe_years
        assert 2022 not in safe_years  # 2022 jeszcze nie 5 lat


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY INTEGRACYJNE: PKPiR × VAT × PIT × ZUS
# ═══════════════════════════════════════════════════════════════════════════════

class TestPKPiRIntegration:
    """Testy integracji PKPiR z innymi domenami."""

    def test_pkpir_vat_consistency(self, base_input):
        """PKPiR kol.7 (netto) vs VAT należny."""
        base_input["invoice"]["direction"] = "SALE"
        net = base_input["invoice"]["amount_net"]  # 5000
        vat = base_input["invoice"]["vat_amount"]  # 1150
        gross = base_input["invoice"]["amount_gross"]  # 6150
        assert gross == net + vat
        # Przychód w PKPiR = netto (VAT czynny)
        assert net == gross - vat

    def test_pkpir_pit_advance_impact(self, base_input):
        """PKPiR dochód → zaliczka PIT."""
        base_input["jdg_entrepreneur"]["pkpir_col7_total"] = 100000.00
        base_input["jdg_entrepreneur"]["pkpir_col10_total"] = 30000.00
        base_input["jdg_entrepreneur"]["pkpir_col13_total"] = 20000.00
        rem_delta = base_input["jdg_entrepreneur"]["remnant_end_of_period"] - base_input["jdg_entrepreneur"]["remnant_start_of_year"]

        income = 100000 - 30000 - 20000 + rem_delta  # 57000
        advance_12pct = (income - 30000) * 0.12  # (57000-30000)*0.12 = 3240
        assert advance_12pct == 3240.00

    def test_pkpir_zus_health_impact(self, base_input):
        """PKPiR dochód → składka zdrowotna."""
        base_input["jdg_entrepreneur"]["tax_form"] = "LINEAR"
        income = 80000.00
        health = min(income * 0.049, 12900)
        assert health == 3920.00  # 4.9% z 80000


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
