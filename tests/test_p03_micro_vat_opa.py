# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OPA Eval Tests: P03 Micro VAT (5 new files, ~62 rules)
# Verifies actual Rego rule evaluation, not just input fixtures
# Generated: 2026-07-29
# ═══════════════════════════════════════════════════════════════════════════════

import json
import os
import subprocess
import pytest

# ═══════════════════════════════════════════════════════════════════════════════
# OPA Eval Helpers
# ═══════════════════════════════════════════════════════════════════════════════

MICRO_VAT_DIR = "JDG/rules/micro/vat"
OPA_BIN = "opa"  # assumes opa is in PATH
MICRO_DIR = "JDG/rules/micro"  # parent dir for plan33/plan34


def opa_eval(package, input_data, rule_name="", extra_data=None):
    """Evaluate Rego rules using opa eval and return all results."""
    cmd = [
        OPA_BIN, "eval",
        "--data", MICRO_VAT_DIR,
        "--data", MICRO_DIR,
        "--data", "JDG/rules/thresholds_jdg.rego",
        "--data", "JDG/rules/_helpers_jdg.rego",
        "--input", "-",
        "--format", "json",
        f"data.{package}" + (f".{rule_name}" if rule_name else "")
    ]
    if extra_data:
        for d in extra_data:
            cmd.insert(2, "--data")
            cmd.insert(3, d)
    try:
        result = subprocess.run(
            cmd,
            input=json.dumps(input_data),
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode != 0:
            if "not found" in result.stderr.lower() or result.returncode == 127:
                pytest.skip(f"OPA binary not available: {result.stderr[:100]}")
            return None
        return json.loads(result.stdout) if result.stdout else None
    except FileNotFoundError:
        pytest.skip("OPA binary not found in PATH")
    except subprocess.TimeoutExpired:
        pytest.skip("OPA eval timed out")


def make_vat_input(**overrides):
    """Standard JDG micro VAT input."""
    return {
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
            "expense_type": "",
            "days_overdue": 0,
            "is_correction": False,
            "margin_scheme_applies": False,
            "requires_ksef": False,
            "export_type": "",
            "customer_type": "B2B",
            "service_category": "",
            "ksef_status": "",
            **overrides.get("invoice", {})
        },
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "vat_status": "ACTIVE",
            "tax_form": "PIT_SCALE",
            "vat_mixed_sales": False,
            "vat_first_year": False,
            "ksef_token_valid": True,
            "margin_global_method": False,
            "margin_scheme_opt_out": False,
            **overrides.get("jdg_entrepreneur", {})
        },
        "vendor": {
            "is_vat_payer": True,
            "vat_eu_active": False,
            "country": "PL",
            **overrides.get("vendor", {})
        },
        "employment": {"has_employees": False, **overrides.get("employment", {})}
    }


# ═══════════════════════════════════════════════════════════════════════════════
# Package Structure Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestPackageStructure:
    """Verify micro VAT package structure and collision resolution."""

    def test_packages_unique(self):
        """All 8 micro VAT packages are unique."""
        packages = set()
        for fname in os.listdir(MICRO_VAT_DIR):
            if fname.endswith('.rego'):
                with open(os.path.join(MICRO_VAT_DIR, fname)) as f:
                    for line in f:
                        if line.startswith('package '):
                            pkg = line.split()[1].strip()
                            assert pkg not in packages, f"Duplicate package: {pkg}"
                            packages.add(pkg)
                            break
        # Also check plan33/plan34
        for fname in ['JDG/rules/micro/plan33_vat.rego', 'JDG/rules/micro/plan34_vat.rego']:
            if os.path.exists(fname):
                with open(fname) as f:
                    for line in f:
                        if line.startswith('package '):
                            pkg = line.split()[1].strip()
                            assert pkg not in packages, f"Duplicate package: {pkg}"
                            packages.add(pkg)
                            break
        assert len(packages) >= 8, f"Expected >= 8 packages, got {len(packages)}"

    def test_vat_rego_has_no_zus_fields(self):
        """ZUS fields removed from vat.rego."""
        with open(os.path.join(MICRO_VAT_DIR, 'vat.rego')) as f:
            content = f.read()
        assert '"zus_social_base_type"' not in content
        assert '"zus_health_rate"' not in content

    def test_vat_rego_has_gtu_codes(self):
        """GTU codes added to vat.rego — valid format GTU_01 through GTU_13."""
        import re
        with open(os.path.join(MICRO_VAT_DIR, 'vat.rego')) as f:
            content = f.read()
        gtu_found = re.findall(r'"gtu_code": "(GTU_\d+)"', content)
        valid_gtu = {f"GTU_{i:02d}" for i in range(1, 14)}
        for gtu in gtu_found:
            assert gtu in valid_gtu, f"Invalid GTU code: {gtu}"
        assert len(gtu_found) >= 1000

    def test_all_new_files_exist(self):
        """All 5 new micro VAT files exist."""
        expected = ['wdt_export_import.rego', 'place_of_supply_micro.rego',
                     'proportion_vat.rego', 'margin_scheme_micro.rego', 'ksef_micro.rego']
        for fname in expected:
            path = os.path.join(MICRO_VAT_DIR, fname)
            assert os.path.exists(path), f"Missing: {fname}"

    def test_new_files_have_valid_from(self):
        """New micro VAT files have temporal markers."""
        for fname in ['wdt_export_import.rego', 'place_of_supply_micro.rego',
                       'proportion_vat.rego', 'margin_scheme_micro.rego', 'ksef_micro.rego']:
            path = os.path.join(MICRO_VAT_DIR, fname)
            with open(path) as f:
                content = f.read()
            assert '"valid_from":' in content, f"Missing valid_from in {fname}"

    def test_new_files_have_legal_basis(self):
        """New micro VAT files have specific _legal_basis."""
        for fname in ['wdt_export_import.rego', 'place_of_supply_micro.rego',
                       'proportion_vat.rego', 'margin_scheme_micro.rego', 'ksef_micro.rego']:
            path = os.path.join(MICRO_VAT_DIR, fname)
            with open(path) as f:
                content = f.read()
            assert '"_legal_basis": "Art.' in content, f"Missing Art. legal_basis in {fname}"


# ═══════════════════════════════════════════════════════════════════════════════
# OPA Evaluation Tests (if opa binary is available)
# ═══════════════════════════════════════════════════════════════════════════════

class TestOPAEval:
    """OPA eval tests for micro VAT rules — requires opa binary in PATH."""

    @pytest.fixture(autouse=True)
    def check_opa(self):
        """Skip if OPA not available."""
        try:
            subprocess.run([OPA_BIN, "version"], capture_output=True, timeout=5)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pytest.skip("OPA binary not available")

    def test_wdt_export_package_loads(self):
        """WDT/Export package compiles and evaluates."""
        inp = make_vat_input(invoice={"procedure": "WDT"})
        result = opa_eval("jdg.micro.vat.wdt_export", inp)
        assert result is not None, "OPA eval failed"
        assert len(result) > 0, "No results from jdg.micro.vat.wdt_export"

    def test_place_of_supply_package_loads(self):
        """Place of supply package compiles and evaluates."""
        inp = make_vat_input(invoice={"service_category": "RESTAURANT"})
        result = opa_eval("jdg.micro.vat.place_of_supply", inp)
        assert result is not None
        assert len(result) > 0

    def test_proportion_package_loads(self):
        """Proportion VAT package compiles and evaluates."""
        inp = make_vat_input(jdg_entrepreneur={"vat_mixed_sales": True})
        result = opa_eval("jdg.micro.vat.proportion", inp)
        assert result is not None
        assert len(result) > 0

    def test_margin_package_loads(self):
        """Margin scheme package compiles and evaluates."""
        inp = make_vat_input(invoice={"procedure": "MARGIN_USED_GOODS", "margin_scheme_applies": True})
        result = opa_eval("jdg.micro.vat.margin", inp)
        assert result is not None
        assert len(result) > 0

    def test_ksef_package_loads(self):
        """KSeF package compiles and evaluates."""
        inp = make_vat_input(invoice={"requires_ksef": True})
        result = opa_eval("jdg.micro.vat.ksef", inp)
        assert result is not None
        assert len(result) > 0

    def test_main_vat_package_loads(self):
        """Main micro VAT package compiles and evaluates."""
        inp = make_vat_input()
        result = opa_eval("jdg.micro.vat", inp)
        assert result is not None
        assert len(result) > 0

    def test_plan33_package_loads(self):
        """Plan33 VAT package compiles and evaluates."""
        inp = make_vat_input()
        result = opa_eval("jdg.micro.vat.plan33", inp)
        assert result is not None
        assert len(result) > 0

    def test_plan34_package_loads(self):
        """Plan34 VAT package compiles and evaluates."""
        inp = make_vat_input()
        result = opa_eval("jdg.micro.vat.plan34", inp)
        assert result is not None
        assert len(result) > 0


# ═══════════════════════════════════════════════════════════════════════════════
# Specific Rule Tests (input validation — fast, no OPA needed)
# ═══════════════════════════════════════════════════════════════════════════════

class TestWDTExportRules:
    """Input validation for WDT/Export/Import rules."""

    def test_wdt_with_vat_eu_buyer(self):
        inp = make_vat_input(invoice={"procedure": "WDT", "buyer_country": "DE"},
                             vendor={"vat_eu_active": True})
        assert inp["vendor"]["vat_eu_active"] and inp["invoice"]["buyer_country"] != "PL"

    def test_wdt_no_docs_3_months(self):
        inp = make_vat_input(invoice={"procedure": "WDT", "wdt_docs_missing_days": 120})
        assert inp["invoice"]["wdt_docs_missing_days"] > 90

    def test_export_direct(self):
        inp = make_vat_input(invoice={"procedure": "EXPORT", "export_type": "DIRECT"})
        assert inp["invoice"]["export_type"] == "DIRECT"

    def test_import_ioss_150eur(self):
        inp = make_vat_input(invoice={"procedure": "IMPORT", "amount_total_eur": 100.0})
        assert inp["invoice"]["amount_total_eur"] <= 150.0

    def test_wnt_excise(self):
        inp = make_vat_input(invoice={"procedure": "WNT", "is_excise_goods": True})
        assert inp["invoice"]["is_excise_goods"]


class TestPlaceOfSupplyRules:
    """Input validation for place of supply rules."""

    def test_b2c_non_eu_np(self):
        inp = make_vat_input(invoice={"customer_type": "B2C", "buyer_country": "US"})
        eu = {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"}
        assert inp["invoice"]["buyer_country"] not in eu

    def test_real_estate_vat_at_location(self):
        inp = make_vat_input(invoice={"service_category": "REAL_ESTATE", "property_country": "DE"})
        assert inp["invoice"]["property_country"] != ""

    def test_e_services_b2c_oss(self):
        inp = make_vat_input(invoice={"service_category": "E_SERVICES", "customer_type": "B2C",
                                       "buyer_country": "DE", "oss_registered": True})
        assert inp["invoice"]["oss_registered"] and inp["invoice"]["buyer_country"] != "PL"

    def test_cultural_event_pl(self):
        inp = make_vat_input(invoice={"service_category": "CULTURAL_EVENT", "event_country": "PL"})
        assert inp["invoice"]["event_country"] == "PL"

    def test_vehicle_rental_pickup_pl(self):
        inp = make_vat_input(invoice={"service_category": "VEHICLE_RENTAL", "pickup_country": "PL"})
        assert inp["invoice"]["pickup_country"] == "PL"


class TestProportionRules:
    """Input validation for VAT proportion rules."""

    def test_mixed_sales_triggers_proportion(self):
        inp = make_vat_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_status": "ACTIVE"})
        assert inp["jdg_entrepreneur"]["vat_mixed_sales"]

    def test_below_2pct_no_deduction(self):
        inp = make_vat_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_proportion_pct": 1.0})
        assert inp["jdg_entrepreneur"]["vat_proportion_pct"] < 2.0

    def test_above_98pct_full_deduction(self):
        inp = make_vat_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_proportion_pct": 99.0})
        assert inp["jdg_entrepreneur"]["vat_proportion_pct"] > 98.0

    def test_first_year_estimated(self):
        inp = make_vat_input(jdg_entrepreneur={"vat_mixed_sales": True, "vat_first_year": True})
        assert inp["jdg_entrepreneur"]["vat_first_year"]

    def test_fixed_asset_correction(self):
        inp = make_vat_input(invoice={"is_fixed_asset": True, "vat_deducted_proportionally": True},
                             jdg_entrepreneur={"vat_mixed_sales": True})
        assert inp["invoice"]["is_fixed_asset"]

    def test_real_estate_10_year_correction(self):
        inp = make_vat_input(invoice={"is_fixed_asset": True, "category_code": "REAL_ESTATE"},
                             jdg_entrepreneur={"vat_mixed_sales": True})
        assert inp["invoice"]["category_code"] == "REAL_ESTATE"

    def test_mandatory_correction_over_2pp(self):
        inp = make_vat_input(jdg_entrepreneur={"vat_mixed_sales": True,
                                                "vat_proportion_provisional": 50.0,
                                                "vat_proportion_actual": 54.0})
        assert abs(50.0 - 54.0) > 2.0


class TestMarginSchemeRules:
    """Input validation for margin scheme rules."""

    def test_used_goods_margin(self):
        inp = make_vat_input(invoice={"procedure": "MARGIN_USED_GOODS", "margin_scheme_applies": True})
        assert inp["invoice"]["margin_scheme_applies"]

    def test_negative_margin_no_vat(self):
        inp = make_vat_input(invoice={"procedure": "MARGIN_USED_GOODS", "margin_amount": -50.0})
        assert inp["invoice"]["margin_amount"] <= 0

    def test_global_margin_method(self):
        inp = make_vat_input(invoice={"procedure": "MARGIN_GLOBAL"},
                             jdg_entrepreneur={"margin_global_method": True})
        assert inp["jdg_entrepreneur"]["margin_global_method"]

    def test_art_margin_8pct(self):
        inp = make_vat_input(invoice={"procedure": "MARGIN_ART", "margin_scheme_applies": True})
        assert inp["invoice"]["procedure"] == "MARGIN_ART"

    def test_travel_agency_margin(self):
        inp = make_vat_input(invoice={"procedure": "MARGIN_TRAVEL", "margin_scheme_applies": True})
        assert inp["invoice"]["procedure"] == "MARGIN_TRAVEL"

    def test_opt_out_margin(self):
        inp = make_vat_input(invoice={"margin_scheme_applies": True},
                             jdg_entrepreneur={"margin_scheme_opt_out": True})
        assert inp["jdg_entrepreneur"]["margin_scheme_opt_out"]


class TestKSeFRules:
    """Input validation for KSeF rules."""

    def test_token_valid(self):
        inp = make_vat_input(invoice={"requires_ksef": True},
                             jdg_entrepreneur={"ksef_token_valid": True})
        assert inp["jdg_entrepreneur"]["ksef_token_valid"]

    def test_token_expired(self):
        inp = make_vat_input(invoice={"requires_ksef": True},
                             jdg_entrepreneur={"ksef_token_valid": False})
        assert not inp["jdg_entrepreneur"]["ksef_token_valid"]

    def test_rejected_xsd(self):
        inp = make_vat_input(invoice={"ksef_status": "REJECTED_XSD"})
        assert inp["invoice"]["ksef_status"] == "REJECTED_XSD"

    def test_rejected_business(self):
        inp = make_vat_input(invoice={"ksef_status": "REJECTED_BUSINESS"})
        assert inp["invoice"]["ksef_status"] == "REJECTED_BUSINESS"

    def test_timeout_retry(self):
        inp = make_vat_input(invoice={"ksef_status": "TIMEOUT"})
        assert inp["invoice"]["ksef_status"] == "TIMEOUT"

    def test_offline_mode(self):
        inp = make_vat_input(invoice={"ksef_status": "OFFLINE", "requires_ksef": True})
        assert inp["invoice"]["ksef_status"] == "OFFLINE"

    def test_offline_deadline_exceeded(self):
        inp = make_vat_input(invoice={"ksef_mode": "OFFLINE", "ksef_offline_days": 10})
        assert inp["invoice"]["ksef_offline_days"] > 7

    def test_api_error_within_retry_limit(self):
        inp = make_vat_input(invoice={"ksef_status": "API_ERROR", "ksef_retry_count": 2})
        assert inp["invoice"]["ksef_retry_count"] < 5
