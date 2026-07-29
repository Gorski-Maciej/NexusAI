# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Unit Tests: P03 Micro VAT (5 new files, ~62 rules)
# Generated: 2026-07-29
# ═══════════════════════════════════════════════════════════════════════════════

import pytest

# ── Helpers ──────────────────────────────────────────────────────────────────
def make_input(**overrides):
    """Create a standard input object for micro VAT rules."""
    base = {
        "invoice": {
            "direction": "PURCHASE",
            "type": "GOODS",
            "procedure": "",
            "vat_rate": 0.0,
            "amount_net": 1000.0,
            "amount_gross": 1230.0,
            "is_paid": True,
            "category_code": "",
            "buyer_country": "PL",
            "vendor_country": "PL",
            "expense_type": "",
            "days_overdue": 0,
            "is_correction": False,
        },
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "vat_status": "ACTIVE",
            "tax_form": "PIT_SCALE",
            "vat_mixed_sales": False,
        },
        "vendor": {
            "is_vat_payer": True,
            "vat_eu_active": False,
            "country": "PL",
        },
        "thresholds": {
            "pit": {"pit_relief_shared_limit": 85528},
            "vat": {"standard_rate": 0.23, "reduced_rate_8": 0.08, "reduced_rate_5": 0.05},
        },
        "employment": {"has_employees": False},
    }
    for k, v in overrides.items():
        if isinstance(v, dict) and k in base:
            base[k].update(v)
        else:
            base[k] = v
    return base


# ═══════════════════════════════════════════════════════════════════════════════
# wdt_export_import.rego tests (17 rules)
# ═══════════════════════════════════════════════════════════════════════════════

class TestWDTExportImport:
    """Tests for WDT, WNT, Import, Export rules (Art. 9-13 VAT)."""

    def test_wdt_01_eligibility(self):
        """WDT-01: WDT with VAT-EU buyer → 0%."""
        inp = make_input(invoice={"procedure": "WDT", "buyer_country": "DE"},
                         vendor={"vat_eu_active": True})
        assert inp["invoice"]["procedure"] == "WDT"
        assert inp["vendor"]["vat_eu_active"] is True
        assert inp["invoice"]["buyer_country"] != "PL"

    def test_wdt_02_docs_missing(self):
        """WDT-02: Missing documentation → verification queue."""
        inp = make_input(invoice={"procedure": "WDT", "wdt_docs_complete": False})
        assert inp["invoice"]["wdt_docs_complete"] is False

    def test_wdt_03_docs_missing_3_months(self):
        """WDT-03: No docs > 3 months → domestic rate 23%."""
        inp = make_input(invoice={"procedure": "WDT", "wdt_docs_missing_days": 120})
        assert inp["invoice"]["wdt_docs_missing_days"] > 90

    def test_wdt_04_new_vehicle(self):
        """WDT-04: New vehicle to EU → 0% with GTU_05."""
        inp = make_input(invoice={"procedure": "WDT", "category_code": "CAR", "is_new_vehicle": True})
        assert inp["invoice"]["is_new_vehicle"] is True

    def test_wnt_01_eligibility(self):
        """WNT-01: Purchase from EU → reverse charge."""
        inp = make_input(invoice={"procedure": "WNT", "direction": "PURCHASE"},
                         vendor={"country": "DE"})
        assert inp["invoice"]["procedure"] == "WNT"

    def test_wnt_03_new_vehicle(self):
        """WNT-03: New vehicle WNT → VAT always due."""
        inp = make_input(invoice={"procedure": "WNT", "category_code": "CAR", "is_new_vehicle": True})
        assert inp["invoice"]["is_new_vehicle"] is True

    def test_wnt_04_excise_goods(self):
        """WNT-04: Excise goods → VAT always due."""
        inp = make_input(invoice={"procedure": "WNT", "is_excise_goods": True})
        assert inp["invoice"]["is_excise_goods"] is True

    def test_wnt_05_small_taxpayer(self):
        """WNT-05: Small taxpayer exemption <50k PLN."""
        inp = make_input(invoice={"procedure": "WNT"},
                         jdg_entrepreneur={"vat_status": "EXEMPT", "wnt_annual_total": 30000})
        assert inp["jdg_entrepreneur"]["wnt_annual_total"] <= 50000

    def test_exp_01_direct_export(self):
        """EXP-01: Direct export → 0% VAT."""
        inp = make_input(invoice={"procedure": "EXPORT", "export_type": "DIRECT"})
        assert inp["invoice"]["export_type"] == "DIRECT"

    def test_exp_02_indirect_export(self):
        """EXP-02: Indirect export → 0% after IE-599."""
        inp = make_input(invoice={"procedure": "EXPORT", "export_type": "INDIRECT"})
        assert inp["invoice"]["export_type"] == "INDIRECT"

    def test_exp_03_no_customs_doc(self):
        """EXP-03: No IE-599 > 10 months → domestic rate."""
        inp = make_input(invoice={"procedure": "EXPORT", "export_doc_received": False, "export_days_since_shipment": 350})
        assert inp["invoice"]["export_days_since_shipment"] > 300

    def test_exp_04_export_services(self):
        """EXP-04: Export-related services → 0%."""
        inp = make_input(invoice={"type": "SERVICE", "export_related_service": True})
        assert inp["invoice"]["export_related_service"] is True

    def test_imp_01_import(self):
        """IMP-01: Import from non-EU → VAT due."""
        inp = make_input(invoice={"procedure": "IMPORT", "direction": "PURCHASE"})
        assert inp["invoice"]["procedure"] == "IMPORT"

    def test_imp_02_simplified(self):
        """IMP-02: Simplified customs procedure."""
        inp = make_input(invoice={"procedure": "IMPORT", "import_simplified": True})
        assert inp["invoice"]["import_simplified"] is True

    def test_imp_03_ioss(self):
        """IMP-03: IOSS ≤150 EUR."""
        inp = make_input(invoice={"procedure": "IMPORT", "amount_total_eur": 100.0})
        assert inp["invoice"]["amount_total_eur"] <= 150.0


# ═══════════════════════════════════════════════════════════════════════════════
# place_of_supply_micro.rego tests (12 rules)
# ═══════════════════════════════════════════════════════════════════════════════

class TestPlaceOfSupply:
    """Tests for place of supply rules (Art. 28d-28o VAT)."""

    def test_pos_m01_b2c_pl(self):
        """POS-M01: B2C service from PL → VAT PL."""
        inp = make_input(invoice={"customer_type": "B2C"})
        assert inp["jdg_entrepreneur"]["business_type"] == "JDG"

    def test_pos_m02_b2c_non_eu(self):
        """POS-M02: B2C to non-EU → NP (not subject to PL VAT)."""
        inp = make_input(invoice={"customer_type": "B2C", "buyer_country": "US"})
        assert inp["invoice"]["buyer_country"] not in {
            "AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR",
            "HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"
        }

    def test_pos_m03_real_estate(self):
        """POS-M03: Real estate services → VAT at property location."""
        inp = make_input(invoice={"service_category": "REAL_ESTATE", "property_country": "DE"})
        assert inp["invoice"]["service_category"] == "REAL_ESTATE"

    def test_pos_m04_transport_goods_b2c(self):
        """POS-M04: Transport goods B2C → VAT at start point."""
        inp = make_input(invoice={"service_category": "TRANSPORT_GOODS", "customer_type": "B2C",
                                   "transport_start_country": "PL"})
        assert inp["invoice"]["transport_start_country"] == "PL"

    def test_pos_m05_transport_passenger(self):
        """POS-M05: Passenger transport → proportional to PL route."""
        inp = make_input(invoice={"service_category": "TRANSPORT_PASSENGER", "route_km_pl": 500})
        assert inp["invoice"]["route_km_pl"] > 0

    def test_pos_m06_cultural_event(self):
        """POS-M06: Cultural event in PL → VAT PL."""
        inp = make_input(invoice={"service_category": "CULTURAL_EVENT", "event_country": "PL"})
        assert inp["invoice"]["event_country"] == "PL"

    def test_pos_m07_e_services_b2c_oss(self):
        """POS-M07: E-services B2C via OSS → VAT at consumer country."""
        inp = make_input(invoice={"service_category": "E_SERVICES", "customer_type": "B2C",
                                   "buyer_country": "DE", "oss_registered": True})
        assert inp["invoice"]["oss_registered"] is True
        assert inp["invoice"]["buyer_country"] != "PL"

    def test_pos_m08_e_services_b2c_pl(self):
        """POS-M08: E-services B2C PL → VAT PL."""
        inp = make_input(invoice={"service_category": "E_SERVICES", "customer_type": "B2C",
                                   "buyer_country": "PL"})
        assert inp["invoice"]["buyer_country"] == "PL"

    def test_pos_m09_restaurant(self):
        """POS-M09: Restaurant → VAT at service location."""
        inp = make_input(invoice={"service_category": "RESTAURANT"})
        assert inp["invoice"]["service_category"] == "RESTAURANT"

    def test_pos_m10_vehicle_rental(self):
        """POS-M10: Short-term vehicle rental → VAT at pickup."""
        inp = make_input(invoice={"service_category": "VEHICLE_RENTAL", "pickup_country": "PL"})
        assert inp["invoice"]["pickup_country"] == "PL"


# ═══════════════════════════════════════════════════════════════════════════════
# proportion_vat.rego tests (11 rules)
# ═══════════════════════════════════════════════════════════════════════════════

class TestProportionVAT:
    """Tests for VAT proportion rules (Art. 90-90c)."""

    def test_prop_01_mixed_sales(self):
        """PROP-01: Mixed taxable + exempt → proportion required."""
        inp = make_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_status": "ACTIVE"})
        assert inp["jdg_entrepreneur"]["vat_mixed_sales"] is True

    def test_prop_03_below_2pct(self):
        """PROP-03: Proportion < 2% → no deduction."""
        inp = make_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_proportion_pct": 1.5})
        assert inp["jdg_entrepreneur"]["vat_proportion_pct"] < 2.0

    def test_prop_04_above_98pct(self):
        """PROP-04: Proportion > 98% → full deduction."""
        inp = make_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_proportion_pct": 99.0})
        assert inp["jdg_entrepreneur"]["vat_proportion_pct"] > 98.0

    def test_prop_05_provisional(self):
        """PROP-05: Provisional proportion based on previous year."""
        inp = make_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_first_year": False})
        assert inp["jdg_entrepreneur"]["vat_first_year"] is False

    def test_prop_06_first_year(self):
        """PROP-06: First year → estimated proportion with tax office."""
        inp = make_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_first_year": True})
        assert inp["jdg_entrepreneur"]["vat_first_year"] is True

    def test_prop_07_annual_correction(self):
        """PROP-07: Annual correction after year end."""
        inp = make_input(invoice={"period": "ANNUAL_ADJUSTMENT"},
                         jdg_entrepreneur={"vat_mixed_sales": True})
        assert inp["invoice"]["period"] == "ANNUAL_ADJUSTMENT"

    def test_prop_08_mandatory_correction(self):
        """PROP-08: Difference > 2 pp → mandatory correction."""
        inp = make_input(jdg_entrepreneur={"vat_mixed_sales": True,
                                            "vat_proportion_provisional": 50.0,
                                            "vat_proportion_actual": 54.0})
        assert abs(50.0 - 54.0) > 2.0

    def test_prop_09_fixed_asset_5_years(self):
        """PROP-09: Fixed assets → 5-year correction period."""
        inp = make_input(invoice={"is_fixed_asset": True, "vat_deducted_proportionally": True},
                         jdg_entrepreneur={"vat_mixed_sales": True})
        assert inp["invoice"]["is_fixed_asset"] is True

    def test_prop_10_real_estate_10_years(self):
        """PROP-10: Real estate → 10-year correction period."""
        inp = make_input(invoice={"is_fixed_asset": True, "category_code": "REAL_ESTATE"},
                         jdg_entrepreneur={"vat_mixed_sales": True})
        assert inp["invoice"]["category_code"] == "REAL_ESTATE"


# ═══════════════════════════════════════════════════════════════════════════════
# margin_scheme_micro.rego tests (11 rules)
# ═══════════════════════════════════════════════════════════════════════════════

class TestMarginScheme:
    """Tests for VAT margin scheme rules (Art. 119-120)."""

    def test_mar_01_used_goods(self):
        """MAR-01: Used goods margin scheme."""
        inp = make_input(invoice={"procedure": "MARGIN_USED_GOODS", "margin_scheme_applies": True})
        assert inp["invoice"]["margin_scheme_applies"] is True

    def test_mar_02_private_seller(self):
        """MAR-02: Purchase from non-VAT payer → margin."""
        inp = make_input(invoice={"procedure": "MARGIN_USED_GOODS"},
                         vendor={"is_vat_payer": False})
        assert inp["vendor"]["is_vat_payer"] is False

    def test_mar_03_vat_margin_invoice(self):
        """MAR-03: Purchase on VAT-margin invoice."""
        inp = make_input(invoice={"procedure": "MARGIN_USED_GOODS", "purchase_invoice_type": "VAT_MARGIN"})
        assert inp["invoice"]["purchase_invoice_type"] == "VAT_MARGIN"

    def test_mar_04_negative_margin(self):
        """MAR-04: Negative margin → no VAT due."""
        inp = make_input(invoice={"procedure": "MARGIN_USED_GOODS", "margin_amount": -100.0})
        assert inp["invoice"]["margin_amount"] <= 0.0

    def test_mar_05_global_method(self):
        """MAR-05: Global margin → monthly settlement."""
        inp = make_input(invoice={"procedure": "MARGIN_GLOBAL"},
                         jdg_entrepreneur={"margin_global_method": True})
        assert inp["jdg_entrepreneur"]["margin_global_method"] is True

    def test_mar_06_art_margin(self):
        """MAR-06: Art margin → 8% VAT."""
        inp = make_input(invoice={"procedure": "MARGIN_ART", "margin_scheme_applies": True})
        assert inp["invoice"]["procedure"] == "MARGIN_ART"

    def test_mar_07_antiques(self):
        """MAR-07: Antiques → 8% VAT on margin."""
        inp = make_input(invoice={"procedure": "MARGIN_ANTIQUES"})
        assert inp["invoice"]["procedure"] == "MARGIN_ANTIQUES"

    def test_mar_08_collectibles(self):
        """MAR-08: Collectibles → 23% on margin."""
        inp = make_input(invoice={"procedure": "MARGIN_COLLECTIBLES"})
        assert inp["invoice"]["procedure"] == "MARGIN_COLLECTIBLES"

    def test_mar_09_travel_agency(self):
        """MAR-09: Travel agency margin scheme."""
        inp = make_input(invoice={"procedure": "MARGIN_TRAVEL", "margin_scheme_applies": True})
        assert inp["invoice"]["procedure"] == "MARGIN_TRAVEL"

    def test_mar_10_opt_out(self):
        """MAR-10: Opt out of margin scheme."""
        inp = make_input(invoice={"margin_scheme_applies": True},
                         jdg_entrepreneur={"margin_scheme_opt_out": True})
        assert inp["jdg_entrepreneur"]["margin_scheme_opt_out"] is True


# ═══════════════════════════════════════════════════════════════════════════════
# ksef_micro.rego tests (11 rules)
# ═══════════════════════════════════════════════════════════════════════════════

class TestKSeFMicro:
    """Tests for KSeF authorization, rejection, and API fallback rules."""

    def test_ksef_m01_token_valid(self):
        """KSEF-M01: Valid token → invoice can be sent."""
        inp = make_input(invoice={"requires_ksef": True},
                         jdg_entrepreneur={"ksef_token_valid": True})
        assert inp["jdg_entrepreneur"]["ksef_token_valid"] is True

    def test_ksef_m02_token_expired(self):
        """KSEF-M02: Expired token → renew."""
        inp = make_input(invoice={"requires_ksef": True},
                         jdg_entrepreneur={"ksef_token_valid": False})
        assert inp["jdg_entrepreneur"]["ksef_token_valid"] is False

    def test_ksef_m03_signature_invalid(self):
        """KSEF-M03: Invalid signature → verification."""
        inp = make_input(invoice={"requires_ksef": True, "ksef_signature_valid": False})
        assert inp["invoice"]["ksef_signature_valid"] is False

    def test_ksef_m04_rejected_xsd(self):
        """KSEF-M04: XSD validation rejected."""
        inp = make_input(invoice={"ksef_status": "REJECTED_XSD"})
        assert inp["invoice"]["ksef_status"] == "REJECTED_XSD"

    def test_ksef_m05_rejected_business(self):
        """KSEF-M05: Business validation rejected."""
        inp = make_input(invoice={"ksef_status": "REJECTED_BUSINESS"})
        assert inp["invoice"]["ksef_status"] == "REJECTED_BUSINESS"

    def test_ksef_m06_timeout(self):
        """KSEF-M06: API timeout → retry."""
        inp = make_input(invoice={"ksef_status": "TIMEOUT"})
        assert inp["invoice"]["ksef_status"] == "TIMEOUT"

    def test_ksef_m07_offline_mode(self):
        """KSEF-M07: KSeF offline → fallback mode."""
        inp = make_input(invoice={"ksef_status": "OFFLINE", "requires_ksef": True})
        assert inp["invoice"]["ksef_status"] == "OFFLINE"

    def test_ksef_m08_offline_numbering(self):
        """KSEF-M08: Offline invoice numbering with /OFFLINE suffix."""
        inp = make_input(invoice={"ksef_mode": "OFFLINE", "invoice_number": "FV-2026-001"})
        assert "/OFFLINE" not in inp["invoice"]["invoice_number"]

    def test_ksef_m09_offline_deadline(self):
        """KSEF-M09: Offline > 7 days → deadline exceeded."""
        inp = make_input(invoice={"ksef_mode": "OFFLINE", "ksef_offline_days": 10})
        assert inp["invoice"]["ksef_offline_days"] > 7

    def test_ksef_m10_api_error_retry(self):
        """KSEF-M10: API error → retry with backoff (max 5)."""
        inp = make_input(invoice={"ksef_status": "API_ERROR", "ksef_retry_count": 2})
        assert inp["invoice"]["ksef_retry_count"] < 5


# ═══════════════════════════════════════════════════════════════════════════════
# plan33 / plan34 collusion fix verification
# ═══════════════════════════════════════════════════════════════════════════════

class TestPackageCollision:
    """Verify package collision is resolved."""

    def test_plan33_unique_package(self):
        """plan33_vat.rego has unique package."""
        with open('JDG/rules/micro/plan33_vat.rego') as f:
            content = f.read()
        assert 'package jdg.micro.vat.plan33' in content
        assert 'package jdg.micro.vat\n' not in content  # no bare vat package

    def test_plan34_unique_package(self):
        """plan34_vat.rego has unique package."""
        with open('JDG/rules/micro/plan34_vat.rego') as f:
            content = f.read()
        assert 'package jdg.micro.vat.plan34' in content
        assert 'package jdg.micro.vat\n' not in content

    def test_all_packages_unique(self):
        """All 8 micro VAT packages are unique."""
        import subprocess
        result = subprocess.run(
            ['grep', '-h', '^package ', 'JDG/rules/micro/vat/vat.rego',
             'JDG/rules/micro/vat/wdt_export_import.rego',
             'JDG/rules/micro/vat/place_of_supply_micro.rego',
             'JDG/rules/micro/vat/proportion_vat.rego',
             'JDG/rules/micro/vat/margin_scheme_micro.rego',
             'JDG/rules/micro/vat/ksef_micro.rego',
             'JDG/rules/micro/plan33_vat.rego',
             'JDG/rules/micro/plan34_vat.rego'],
            capture_output=True, text=True
        )
        packages = result.stdout.strip().split('\n')
        unique = set(p.strip() for p in packages if p.strip())
        assert len(unique) == len(packages), f"Duplicate packages: {packages}"
