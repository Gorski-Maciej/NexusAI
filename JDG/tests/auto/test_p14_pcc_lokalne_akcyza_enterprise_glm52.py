# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 PCC / LOKALNE / AKCYZA / ROLNY — pytest (GLM52 P14)
# ═══════════════════════════════════════════════════════════════════════════════
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(JDG_ROOT / "tools"))

from pcc_engine import (EXEMPTION_LIMIT, PCC3_DEADLINE_DAYS, detect_transaction,  # noqa: E402
                        generate_pcc3, rate_pct)
from gmina_rates_engine import (DN1_DEADLINE_DAYS, get_gmina_rates,  # noqa: E402
                                real_estate_tax, transport_tax)
from akcyza_classifier import classify, excise_due  # noqa: E402
from dn1_dt1_generator import generate_dn1, generate_dt1  # noqa: E402


# ── PCC ENGINE ────────────────────────────────────────────────────────────────
class TestPccEngine:
    def test_sale_2pct(self):
        r = detect_transaction("sale", 100_000)
        assert r["rate_pct"] == 2.0
        assert r["tax_due"] == 2000.0
        assert r["pcc_obligation"] is True
        assert r["small_value_exempt"] is False

    def test_loan_05pct(self):
        r = detect_transaction("loan", 100_000)
        assert r["rate_pct"] == 0.5
        assert r["tax_due"] == 500.0

    def test_vat_exclusion(self):
        r = detect_transaction("sale", 100_000, vat_applicable=True)
        assert r["pcc_obligation"] is False
        assert r["tax_due"] == 0.0
        assert "art. 2 pkt 4" in r["reason"].lower()

    def test_small_value_exempt(self):
        r = detect_transaction("sale", 500)
        assert r["small_value_exempt"] is True
        assert r["tax_due"] == 0.0

    def test_rate_pct_table(self):
        assert rate_pct("sale") == 2.0
        assert rate_pct("loan") == 0.5
        assert rate_pct("company") == 0.5

    def test_pcc3_generator_countdown(self):
        r = generate_pcc3("sale", 100_000, days_elapsed=12)
        assert r["tax_due"] == 2000.0
        assert r["deadline_days"] == 14
        assert r["days_remaining"] == 2
        assert r["urgency_alert"] is True
        assert "PCC-3" in r["form"]

    def test_pcc3_legal_basis(self):
        r = generate_pcc3("sale", 100_000)
        assert "Dz.U. 2025 poz. 789" in r["legal_basis"]

    def test_constants(self):
        assert EXEMPTION_LIMIT == 1000.0
        assert PCC3_DEADLINE_DAYS == 14


# ── GMINA RATES ENGINE ────────────────────────────────────────────────────────
class TestGminaRatesEngine:
    def test_rates_2026(self):
        r = get_gmina_rates("Warszawa")
        assert r["rates"]["building_business"] == 33.10
        assert r["rates"]["land_business"] == 1.43
        assert r["rates_changed_ytd"] is True
        assert r["building_rate_delta_pct"] > 0

    def test_real_estate_tax(self):
        r = real_estate_tax("building_business", 200)
        assert r["annual_tax"] == 6620.0
        assert r["dn1_deadline_days"] == 14
        assert r["form"] == "DN-1"

    def test_transport_tax_heavy(self):
        r = transport_tax(4.5)
        assert r["taxable"] is True
        assert r["threshold_t"] == 3.5
        assert r["form"] == "DT-1"

    def test_transport_tax_light(self):
        r = transport_tax(2.5)
        assert r["taxable"] is False

    def test_legal_basis(self):
        r = get_gmina_rates("Warszawa")
        assert "Dz.U. 2025 poz. 1234" in r["legal_basis"]


# ── AKCYZA CLASSIFIER ─────────────────────────────────────────────────────────
class TestAkcyzaClassifier:
    def test_gasoline(self):
        r = classify("gasoline")
        assert r["category"] == "fuel"
        assert r["rate"] == 1566.0

    def test_diesel(self):
        r = classify("diesel")
        assert r["rate"] == 1206.0

    def test_ethanol_warehouse(self):
        r = classify("ethanol")
        assert r["category"] == "alcohol"
        assert r["rate"] == 6900.0
        assert r["warehouse_required"] is True

    def test_wine_no_warehouse(self):
        r = classify("wine")
        assert r["rate"] == 185.0
        assert r["warehouse_required"] is False

    def test_excise_due(self):
        r = excise_due("gasoline", 1000)
        assert r["excise_due"] == 1566.0
        assert r["edd_required"] is True

    def test_non_excise(self):
        r = classify("stal")
        assert r["category"] == "non_excise"
        assert r["rate"] == 0.0

    def test_legal_basis(self):
        assert "Dz.U. 2025 poz. 1220" in classify("gasoline")["legal_basis"]


# ── DN-1 / DT-1 GENERATOR ─────────────────────────────────────────────────────
class TestDn1Dt1Generator:
    def test_dn1(self):
        r = generate_dn1("Warszawa", "building_business", 200)
        assert r["annual_tax"] == 6620.0
        assert r["quarterly_installment"] == 1655.0
        assert r["deadline_days"] == 14
        assert r["auto_filled"] is True

    def test_dt1(self):
        r = generate_dt1(4.5)
        assert r["taxable"] is True
        assert r["deadline"] == "15.02"
        assert r["auto_filled"] is True


# ── WIRING PAS 51 (main_jdg.rego) ─────────────────────────────────────────────
class TestWiringP51:
    def test_final_verdict_p51_exists(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p51 = safe_merge(final_verdict_p50," in text

    def test_imports_present(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "import data.jdg.micro.pcc as micro_pcc_full" in text
        assert "import data.jdg.micro.akcyza as micro_akcyza_full" in text
        assert "import data.jdg.micro.pcc_lokalne_atomic_p14" in text

    def test_package_decisions_entries(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert '"jdg.micro.pcc": micro_pcc_full.decide' in text
        assert '"jdg.micro.akcyza": micro_akcyza_full.decide' in text
        assert '"jdg.micro.pcc_lokalne_atomic_p14": pcc_lokalne_atomic_p14.decide' in text

    def test_plan33_pcc_package_fixed(self):
        f = JDG_ROOT / "rules" / "micro" / "plan33_pcc.rego"
        text = f.read_text(encoding="utf-8")
        assert "package jdg.micro.pcc.plan33" in text

    def test_plan26_local_package_fixed(self):
        f = JDG_ROOT / "rules" / "local_taxes" / "plan26_local.rego"
        text = f.read_text(encoding="utf-8")
        assert "package jdg.local_taxes.plan26" in text

    def test_atomic_legal_basis_canonical(self):
        f = JDG_ROOT / "rules" / "micro" / "pcc_lokalne_atomic_p14.rego"
        text = f.read_text(encoding="utf-8")
        assert "Dz.U. 2025 poz. 789" in text
        assert "Dz.U. 2025 poz. 1234" in text
        assert "Dz.U. 2025 poz. 1220" in text
        assert "Dz.U. 2000 nr 86 poz. 959" not in text

    def test_thresholds_extended(self):
        f = JDG_ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "pcc_sale_rate" in text
        assert "pcc_loan_rate" in text
        assert "pcc3_deadline_days" in text
        assert "building_business_rate" in text
        assert "excise_gasoline" in text
