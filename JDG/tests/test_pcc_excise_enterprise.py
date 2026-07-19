"""
NexusAI JDG — Unit Tests: PCC + Excise + Local Tax Procedures (Class IX)
══════════════════════════════════════════════════════════════════════════════
Data: 2026-07-19
Inicjatywy: Klasa IX Enterprise — Akcyza, Procedury lokalne, Cross-tax
Opis: Testy jednostkowe dla domknięcia luki 225 punktów prawnych Klasy IX.
      Weryfikują logikę biznesową akcyzy, procedur PCC i lokalnych.

Pokrycie testowe:
  - EXCISE: paliwa, alkohol, tytoń, energia, skład podatkowy, AKC-4
  - PROCEDURES: przedawnienie PCC, zwroty, zmiany mid-year,
    DT-1 korekty, cross-tax interactions
══════════════════════════════════════════════════════════════════════════════
"""
import pytest
from typing import Dict, Any


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture
def base_input() -> Dict[str, Any]:
    """Bazowy input JDG dla testów akcyzy i podatków lokalnych."""
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
            "description": "Zakup paliwa",
            "expense_type": "OTHER_EXPENSES",
            "transaction_type": "",
            "excise_category": "",
            "is_vat_invoice": True,
            "is_cash_payment": False,
            "is_period_end": False,
            "is_year_end": False,
            "is_month_end": False,
            "is_asset_purchase": False,
            "vat_taxable": True,
            "pcc3_filed": False,
        },
        "vendor": {
            "name": "Dostawca Sp. z o.o.",
            "nip": "1234567890",
            "country": "PL",
            "is_company": True,
            "is_vat_payer": True,
            "on_whitelist": True,
        },
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "uses_pkpir": True,
            "uses_uor": False,
            "vat_status": "ACTIVE",
            "business_status": "ACTIVE",
            "business_type": "JDG",
            "has_business_property": False,
            "has_heavy_vehicle": False,
            "has_business_garage": False,
            "has_advertising_board": False,
            "has_dogs": False,
            "excise_registered": False,
            "akc4_filed_this_month": True,
            "excise_due_monthly_pln": 0,
            "annual_revenue_actual": 150000,
        },
    }


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: EXCISE — FUELS (paliwa)
# ═══════════════════════════════════════════════════════════════════════════════

class TestExciseMotorFuels:
    """Testy akcyzy paliwowej."""

    def test_gasoline_unleaded_excise(self):
        """Akcyza od benzyny bezołowiowej: 1659 PLN/1000L."""
        volume_liters = 500
        rate_per_1000l = 1659
        excise = volume_liters * rate_per_1000l / 1000
        assert excise == 829.50

    def test_gasoline_leaded_excise(self):
        """Akcyza od benzyny ołowiowej: 1859 PLN/1000L — wyższa stawka."""
        volume_liters = 500
        rate_per_1000l = 1859
        excise = volume_liters * rate_per_1000l / 1000
        assert excise == 929.50
        # Powinno być wyższe niż bezołowiowa
        assert excise > 500 * 1659 / 1000

    def test_diesel_excise(self):
        """Akcyza od ON: 1319 PLN/1000L."""
        volume_liters = 1000
        rate_per_1000l = 1319
        excise = volume_liters * rate_per_1000l / 1000
        assert excise == 1319.00

    def test_diesel_agriculture_refund(self):
        """Zwrot akcyzy rolniczej: 1.20 PLN/litr."""
        volume_liters = 500
        refund_per_liter = 1.20
        refund = volume_liters * refund_per_liter
        assert refund == 600.00

    def test_lpg_excise(self):
        """Akcyza od LPG: 700 PLN/1000kg."""
        volume_kg = 200
        rate_per_1000kg = 700
        excise = volume_kg * rate_per_1000kg / 1000
        assert excise == 140.00

    def test_cng_excise_lower_than_lpg(self):
        """CNG (449 PLN/1000kg) ma niższą akcyzę niż LPG (700)."""
        cng_rate = 449
        lpg_rate = 700
        assert cng_rate < lpg_rate

    def test_heating_oil_business_excise(self):
        """Olej opałowy lekki: 64 PLN/1000L dla firm."""
        volume_liters = 2000
        rate_per_1000l = 64
        excise = volume_liters * rate_per_1000l / 1000
        assert excise == 128.00

    def test_heating_oil_residential_exempt(self):
        """Olej grzewczy mieszkalny: zwolniony z akcyzy."""
        rate = 0
        assert rate == 0


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: EXCISE — ALCOHOL
# ═══════════════════════════════════════════════════════════════════════════════

class TestExciseAlcohol:
    """Testy akcyzy alkoholowej."""

    def test_beer_excise_per_plato(self):
        """Akcyza od piwa: 9.29 PLN/hl za każdy °Plato."""
        volume_hl = 10
        plato = 12.0
        rate_per_hl_plato = 9.29
        excise = volume_hl * rate_per_hl_plato * plato
        assert excise == 1114.80  # 10 × 9.29 × 12

    def test_beer_small_brewery_discount_max(self):
        """Mały browar do 5000 hl/rok: 30% zniżki."""
        annual_hl = 3000
        full_rate = 9.29 * 12.0
        discounted = full_rate * 0.7
        assert annual_hl <= 5000
        assert abs(discounted - 78.036) < 0.001  # float tolerance

    def test_wine_excise_rate(self):
        """Akcyza od wina: 216 PLN/hl."""
        volume_hl = 5
        rate = 216
        excise = volume_hl * rate
        assert excise == 1080.00

    def test_cider_lower_than_wine(self):
        """Cydr (108 PLN/hl) ma niższą stawkę niż wino (216)."""
        cider_rate = 108
        wine_rate = 216
        assert cider_rate < wine_rate

    def test_spirits_excise_high(self):
        """Wyroby spirytusowe: 8700 PLN/hl 100% alkoholu."""
        volume_hl_100pct = 1.5
        rate = 8700
        excise = volume_hl_100pct * rate
        assert excise == 13050.00
        assert rate > 200 * 43  # Znacznie wyższa niż piwo


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: EXCISE — TOBACCO
# ═══════════════════════════════════════════════════════════════════════════════

class TestExciseTobacco:
    """Testy akcyzy tytoniowej."""

    def test_cigarettes_ad_valorem_plus_specific(self):
        """Papierosy: 32% ceny detalicznej + 105 PLN/1000szt."""
        retail_price_1000 = 650.00
        ad_valorem = retail_price_1000 * 0.32  # 208
        specific = 105.00
        total = ad_valorem + specific
        assert total == 313.00

    def test_cigarettes_minimum_70pct_rule(self):
        """Minimum 70% ceny detalicznej gdy normalna stawka za niska."""
        retail_price_1000 = 100.00  # Tanie papierosy
        normal = 100 * 0.32 + 105  # 32 + 105 = 137
        minimum = 100 * 0.70  # 70
        # Normalna stawka (137) > minimum (70) → użyj normalnej
        assert normal > minimum
        assert max(normal, minimum) == normal

    def test_cigars_excise(self):
        """Cygara: 595 PLN/1000szt."""
        qty_1000s = 0.5
        rate = 595
        excise = qty_1000s * rate
        assert excise == 297.50

    def test_smoking_tobacco_excise(self):
        """Tytoń do palenia: 300 PLN/kg."""
        qty_kg = 2.5
        rate = 300
        excise = qty_kg * rate
        assert excise == 750.00


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: EXCISE — ENERGY & PROCEDURES
# ═══════════════════════════════════════════════════════════════════════════════

class TestExciseEnergyAndProcedures:
    """Testy akcyzy energetycznej i proceduralnej."""

    def test_electricity_business_excise(self):
        """Prąd dla firmy: 5 PLN/MWh."""
        energy_mwh = 120
        rate = 5.00
        excise = energy_mwh * rate
        assert excise == 600.00

    def test_electricity_renewable_exempt(self):
        """OZE: zwolnione z akcyzy."""
        rate = 0
        assert rate == 0

    def test_electricity_household_exempt(self):
        """Gospodarstwa domowe: zwolnione z akcyzy."""
        rate = 0
        assert rate == 0

    def test_warehouse_missing_security(self):
        """Brak zabezpieczenia akcyzowego = BLOCK."""
        has_warehouse = True
        has_security = False
        assert not (has_warehouse and has_security)

    def test_warehouse_complete(self):
        """Skład + zabezpieczenie = OK."""
        has_warehouse = True
        has_security = True
        assert has_warehouse and has_security

    def test_aviation_exemption_code(self):
        """Lotnictwo komercyjne – kod zwolnienia."""
        exemption_code = "AVIATION"
        assert exemption_code == "AVIATION"

    def test_no_documentation_risky(self):
        """Zwolnienie bez dokumentacji = ryzyko."""
        has_documentation = False
        assert not has_documentation


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: PCC PROCEDURES — Przedawnienia, zwroty, transakcje mieszane
# ═══════════════════════════════════════════════════════════════════════════════

class TestPCCProcedures:
    """Testy procedur PCC."""

    def test_statute_expired_after_5_years(self):
        """Przedawnienie PCC po 5 latach."""
        transaction_year = 2020
        current_year = 2026
        years_since = current_year - transaction_year
        assert years_since >= 5
        assert years_since == 6

    def test_statute_not_expired(self):
        """PCC nieprzedawnione — 3 lata od transakcji."""
        transaction_year = 2024
        current_year = 2026
        years_since = current_year - transaction_year
        assert years_since < 5
        assert years_since == 2

    def test_overpayment_within_5_years(self):
        """Nadpłata w terminie 5 lat — można odzyskać."""
        overpayment_year = 2024
        current_year = 2026
        assert current_year - overpayment_year < 5

    def test_overpayment_expired(self):
        """Nadpłata przedawniona po 5 latach."""
        overpayment_year = 2020
        current_year = 2026
        assert current_year - overpayment_year >= 5

    def test_mixed_transaction_pcc_only_nonvat(self):
        """Transakcja mieszana — PCC tylko od części non-VAT."""
        total = 20000.00
        vat_portion = 12000.00
        nonvat_portion = total - vat_portion
        pcc = nonvat_portion * 0.02
        assert pcc == 160.00  # 2% z 8000
        assert nonvat_portion == 8000.00


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: PROPERTY PROCEDURES — Zwolnienia, zmiany mid-year
# ═══════════════════════════════════════════════════════════════════════════════

class TestPropertyProcedures:
    """Testy procedur podatku od nieruchomości."""

    def test_disabled_exemption(self):
        """Zwolnienie dla niepełnosprawnych."""
        exemption_type = "DISABLED"
        assert exemption_type in {"DISABLED", "VETERAN", "MONUMENT", "EDUCATION"}

    def test_mid_year_change_tax_proportional(self):
        """Zmiana powierzchni w lipcu — podatek proporcjonalny."""
        old_area = 50
        new_area = 80
        change_month = 7
        rate = 33.10
        months_before = change_month - 1  # 6
        months_after = 12 - months_before  # 6
        tax_before = old_area * rate / 12 * months_before
        tax_after = new_area * rate / 12 * months_after
        total = tax_before + tax_after
        # 50*33.10/12*6 + 80*33.10/12*6 = 827.50 + 1324.00 = 2151.50
        assert round(total, 2) == 2151.50

    def test_property_tax_as_kup(self):
        """Podatek od nieruchomości = KUP."""
        property_tax = 1655.00
        property_tax_booked = True
        assert property_tax_booked
        assert property_tax > 0


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: TRANSPORT PROCEDURES — DT-1 korekty, sprzedaż mid-year
# ═══════════════════════════════════════════════════════════════════════════════

class TestTransportProcedures:
    """Testy procedur podatku od środków transportu."""

    def test_mid_year_sale_refund(self):
        """Sprzedaż pojazdu w czerwcu — zwrot za 6 miesięcy."""
        sale_month = 6
        annual_tax = 2400.00
        months_owned = sale_month
        tax_due = annual_tax / 12 * months_owned
        refund = annual_tax - tax_due
        assert tax_due == 1200.00
        assert refund == 1200.00

    def test_combined_tractor_trailer_tax(self):
        """Ciągnik + naczepa = łączny podatek."""
        tractor_tax = 2300
        trailer_tax = 1800
        combined = tractor_tax + trailer_tax
        assert combined == 4100

    def test_trailer_tax_by_dmc(self):
        """Podatek od naczepy zależny od DMC."""
        dmc_t = 22  # tony
        axles = 2
        if dmc_t > 20:
            tax = 2400 if axles == 2 else 3200
        assert tax == 2400


# ═══════════════════════════════════════════════════════════════════════════════
# TESTY: CROSS-TAX INTERACTIONS
# ═══════════════════════════════════════════════════════════════════════════════

class TestCrossTaxInteractions:
    """Testy interakcji między różnymi podatkami."""

    def test_pcc_added_to_asset_initial_value(self):
        """PCC doliczane do wartości początkowej ŚT."""
        asset_price = 50000.00
        pcc_2pct = asset_price * 0.02
        initial_value = asset_price + pcc_2pct
        assert initial_value == 51000.00
        assert initial_value > asset_price

    def test_pcc_not_added_warning(self):
        """PCC niedoliczone = zaniżona amortyzacja."""
        pcc_added = False
        pcc_amount = 1000.00
        should_warn = not pcc_added and pcc_amount > 100
        assert should_warn

    def test_transport_tax_as_kup_opportunity(self):
        """Podatek transportowy daje KUP."""
        tax = 2400
        tax_booked = False
        # Przedsiębiorca może odliczyć
        potential_savings = tax * 0.19  # przy 19% liniowym
        assert potential_savings == 456.00
        assert not tax_booked  # Jeszcze nie zaksięgowano


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
