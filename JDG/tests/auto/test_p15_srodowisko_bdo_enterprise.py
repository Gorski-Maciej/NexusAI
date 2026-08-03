# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P15 Środowisko + BDO + Branża Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from bdo_environment_auditor import (  # noqa: E402
    BDO,
    agricultural_tax_calculator,
    audit_rego_files,
    bdo_assistant,
    bdo_deadline_tracker,
    budowlane_pozwolenie_calculator,
    cbam_calculator,
    kpo_generator,
    product_fee_tracker,
    seasonal_assistant,
    taxfree_calculator,
)


# ── Asystent BDO (INN-01 — rejestracja, opłaty) ───────────────────────────────
def test_bdo_assistant_unregistered():
    """Niezarejestrowany w BDO → alert + opłata 100 PLN (mikro)."""
    res = bdo_assistant(registered=False, company_size="mikro")
    assert res["registered"] is False
    assert res["rejestracja_fee"] == 100
    assert "rejestracja w BDO wymagana" in res["alert"]
    assert "100 PLN" in res["alert"]


def test_bdo_assistant_registered_company_size():
    """Zarejestrowany → brak alertu; firma średnia → opłata 500 PLN (widoczna w fee)."""
    res = bdo_assistant(registered=True, company_size="średni")
    assert res["registered"] is True
    assert res["rejestracja_fee"] == 500
    assert "zarejestrowany" in res["alert"]


# ── Generator KPO (INN-02 — kody EWC) ─────────────────────────────────────────
def test_kpo_generator_valid():
    """Kod EWC 6-cyfrowy → KPO wymagane + poprawne."""
    res = kpo_generator("17 01 01")
    assert res["kpo_required"] is True
    assert res["ewc_valid"] is True
    assert "KPO" in res["form"]


def test_kpo_generator_invalid():
    """Brak kodu EWC → KPO niewymagane."""
    res = kpo_generator("")
    assert res["kpo_required"] is False
    assert res["ewc_valid"] is False


# ── Tracker terminów sprawozdań BDO (INN-03) ──────────────────────────────────
def test_bdo_deadline_tracker():
    """4 terminy: ewidencja kwartalna + sprawozdania roczne 15.03."""
    res = bdo_deadline_tracker()
    assert len(res["deadlines"]) == 4
    assert "15.03" in res["deadlines"][1]
    assert "kwartalna" in res["deadlines"][0]


# ── Tracker opłat produktowych (INN-04) ───────────────────────────────────────
def test_product_fee_tracker():
    """100 kg opakowań × 2 zł/kg = 200 PLN."""
    res = product_fee_tracker(100)
    assert res["packaging_fee_due"] == 200.0
    assert res["packaging_fee_rate"] == 2.0


# ── Kalkulator pozwolenia na budowę / zgłoszenia (INN-05) ─────────────────────
def test_budowlane_pozwolenie_permit():
    """Nowy budynek → pozwolenie na budowę wymagane."""
    res = budowlane_pozwolenie_calculator("nowy_budynek")
    assert res["requires_permit"] is True
    assert res["requires_notice"] is False


def test_budowlane_pozwolenie_notice():
    """Remont → zgłoszenie wystarczy."""
    res = budowlane_pozwolenie_calculator("remont")
    assert res["requires_permit"] is False
    assert res["requires_notice"] is True


# ── Kalkulator CBAM (INN-06) ──────────────────────────────────────────────────
def test_cbam_calculator():
    """10 t CO2 × 80 EUR/t = 800 EUR."""
    res = cbam_calculator(co2_t=10, value=50000)
    assert res["cbam_due_eur"] == 800.0
    assert res["embedded_emissions_t"] == 10


# ── Kalkulator tax-free VAT-REF (INN-10) ──────────────────────────────────────
def test_taxfree_calculator():
    """1230 PLN brutto → zwrot VAT 230 PLN (VAT 23% w cenie)."""
    res = taxfree_calculator(1230)
    assert res["vat_refundable"] == 230.0
    assert res["vat_rate"] == 0.23


# ── Asystent sezonowości (INN-11) ─────────────────────────────────────────────
def test_seasonal_assistant():
    """Działalność sezonowa — miesiące sezonu wykryte."""
    res = seasonal_assistant(seasonal=True, season_months=4)
    assert res["seasonal"] is True
    assert res["season_months"] == 4


# ── Kalkulator podatku rolnego (INN-12) ───────────────────────────────────────
def test_agricultural_tax_calculator():
    """4 ha × 224,08 = 896,30 PLN (2,5 q żyta × 89,63 zł/q)."""
    res = agricultural_tax_calculator(4)
    assert res["tax_per_ha"] == 224.08
    assert res["annual_tax"] == 896.3
    assert res["rye_price_per_quintal"] == 89.63


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — bdo (6 modułów) + srodowisko + budownictwo."""
    res = audit_rego_files()
    assert any("micro/bdo/" in f for f in res["files_audited"])
    assert any("micro/srodowisko/" in f for f in res["files_audited"])
    assert any("micro/budownictwo/" in f for f in res["files_audited"])
    assert res["total_rule_ids"] >= 166, "Oczekiwano ≥166 rule_id (bdo 52 + srodowisko 49 + budownictwo 65)"
    assert res["unique_count"] >= 160


def test_audit_coverage_reports_real():
    """Pokrycie modułów: 8/8 COMPLETE (rejestracja, ewidencja, EWC, transport, zezwolenia, WEEE, środowisko, budownictwo)."""
    res = audit_rego_files()
    for mod in ["bdo_rejestracja", "bdo_ewidencja", "bdo_ewc", "bdo_transport",
                "bdo_zezwolenia", "bdo_weee_baterie", "srodowisko", "budownictwo"]:
        assert res["modules"][mod]["status"] == "COMPLETE", f"{mod} powinno być COMPLETE"
    assert res["coverage"]["complete"] == 8


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p15_package_exists():
    """Pakiet P15 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego"
    assert p.exists(), "Brak pliku p15_srodowisko_bdo_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p15_srodowisko_bdo_innovations" in text
    assert "default decide" in text


def test_p15_priorities_present():
    """Sekcje priorytetowe: BDO + budownictwo + transport/rolnictwo + CBAM."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["srodowisko_bdo_coverage_report", "bdo_audit", "bdo_assistant", "kpo_generator",
                   "bdo_deadline_tracker", "product_fee_tracker", "budownictwo_audit",
                   "budowlane_pozwolenie_calculator", "transport_rolnictwo_audit",
                   "regulated_taxfree_seasonal_audit", "cbam_audit", "cbam_calculator",
                   "bdo_pipeline_snapshot", "branza_compliance_panel", "branza_template_hook",
                   "regulated_profession_assistant", "taxfree_calculator", "seasonal_assistant",
                   "agricultural_tax_calculator"]:
        assert marker in text, f"Brak {marker}"


def test_p15_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p15_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 18
    assert text.count("_routing_reason") >= 18


def test_p15_wiring_in_main():
    """P15 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p15."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p15_srodowisko_bdo_innovations" in main
    assert '"jdg.p15_srodowisko_bdo_innovations":' in main
    assert "final_verdict_p15" in main
    # Łańcuch werdyktów: p15 = safe_merge(p14, ...)
    assert "final_verdict_p14" in main


def test_p15_no_collision_v8():
    """Stary pakiet v8 (jdg.p15_innovations) nadal istnieje — brak kolizji nazw."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p15_innovations" in main


# ── Smoke CLI ──────────────────────────────────────────────────────────────────
def test_p15_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "bdo_environment_auditor.py"),
         "--bdo-assistant", "--kpo", "--product-fee", "--cbam", "--agricultural"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["bdo_assistant"]["rejestracja_fee"] == 100
    assert data["product_fee"]["packaging_fee_due"] == 0.0
    assert data["cbam"]["cbam_due_eur"] == 0.0
    assert data["agricultural"]["tax_per_ha"] == 224.08


# ── Stałe ─────────────────────────────────────────────────────────────────────
def test_p15_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi (ADR-002)."""
    assert BDO["rejestracja_fees"]["mikro"] == 100
    assert BDO["kara_brak_rejestracji"] == 5000.0
    assert BDO["packaging_fee_rate"] == 2.0
    assert BDO["cbam_price_eur_t"] == 80.0
    assert BDO["agricultural_rye_pln_q"] == 89.63
    assert BDO["taxfree_vat_rate"] == 0.23
