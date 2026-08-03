# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 PCC + Podatki Lokalne + Akcyza Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from pcc_local_excise_auditor import (  # noqa: E402
    PCC,
    audit_rego_files,
    excise_alcohol_calculator,
    excise_fuel_calculator,
    excise_warehouse_tracker,
    gmina_rates_registry,
    pcc3_generator,
    pcc_calculator,
    real_estate_tax_calculator,
    transport_tax_calculator,
)


# ── Kalkulator PCC (INN — stawki art. 6-7) ────────────────────────────────────
def test_pcc_calculator_sale():
    """Sprzedaż 100k × 2% = 2000 PLN."""
    res = pcc_calculator("SALE_MOVABLE", 100000)
    assert res["rate_pct"] == 2.0
    assert res["tax_due"] == 2000.0
    assert res["small_value_exempt"] is False


def test_pcc_calculator_loan():
    """Pożyczka 100k × 0,5% = 500 PLN."""
    res = pcc_calculator("LOAN", 100000)
    assert res["rate_pct"] == 0.5
    assert res["tax_due"] == 500.0


def test_pcc_calculator_small_value():
    """Kwota 500 ≤ 1000 → zwolniona (art. 9 pkt 1)."""
    res = pcc_calculator("SALE_MOVABLE", 500)
    assert res["small_value_exempt"] is True


# ── Auto-generator PCC-3 (INN-01 — art. 10, 14 dni) ───────────────────────────
def test_pcc3_generator():
    """PCC-3: podatek 2000 PLN, termin 14 dni, formularz PCC-3/PCC-3/A."""
    res = pcc3_generator("SALE_MOVABLE", 100000)
    assert res["tax_due"] == 2000.0
    assert res["deadline_days"] == 14
    assert "PCC-3" in res["form"]
    assert "PCC-3/A" in res["form"]


# ── Symulator podatku od nieruchomości (INN-04 — DN-1) ────────────────────────
def test_real_estate_tax_calculator():
    """100 m² gruntów × 1,43 + 200 m² budynków × 33,10 = 143 + 6620 = 6763 PLN."""
    res = real_estate_tax_calculator(100, 200)
    assert res["land_tax"] == round(100 * 1.43 * 100) / 100
    assert res["building_tax"] == round(200 * 33.10 * 100) / 100
    assert res["total_annual"] == round((100 * 1.43 + 200 * 33.10) * 100) / 100
    assert res["rates"]["building_business"] == 33.10


# ── Kalkulator transportowy (INN-05 — >3,5t) ──────────────────────────────────
def test_transport_tax_heavy():
    """4,5t > 3,5t → opodatkowany."""
    res = transport_tax_calculator(4.5)
    assert res["taxable"] is True
    assert res["threshold_t"] == 3.5


def test_transport_tax_light():
    """2,5t ≤ 3,5t → nieopodatkowany."""
    res = transport_tax_calculator(2.5)
    assert res["taxable"] is False


# ── Rejestr stawek gminnych (INN-03) ──────────────────────────────────────────
def test_gmina_rates_registry():
    """Rejestr stawek gminnych — DN-1 14 dni, raty 4×."""
    res = gmina_rates_registry("Warszawa")
    assert res["gmina"] == "Warszawa"
    assert res["dn1_deadline_days"] == 14
    assert len(res["payment_schedule"]) == 4
    assert res["rates"]["building_business"] == 33.10


# ── Kalkulatory akcyzy (INN-07/08) ────────────────────────────────────────────
def test_excise_fuel_calculator():
    """1000 l benzyny × 1566/1000l = 1566 PLN."""
    res = excise_fuel_calculator("benzyna", 1000)
    assert res["excise_due"] == 1566.0
    assert res["rate_per_1000l"] == 1566.0


def test_excise_fuel_on():
    """1000 l ON × 1206/1000l = 1206 PLN."""
    res = excise_fuel_calculator("on", 1000)
    assert res["excise_due"] == 1206.0


def test_excise_alcohol_calculator():
    """1 hl alkoholu etylowego × 6900 = 6900 PLN; skład podatkowy wymagany."""
    res = excise_alcohol_calculator("alkohol_etylowy", 1)
    assert res["excise_due"] == 6900.0
    assert res["warehouse_required"] is True


def test_excise_alcohol_wine():
    """1 hl wina × 185 = 185 PLN."""
    res = excise_alcohol_calculator("wino", 1)
    assert res["excise_due"] == 185.0
    assert res["warehouse_required"] is False


# ── Tracker składu podatkowego (INN-11) ───────────────────────────────────────
def test_excise_warehouse_tracker():
    """Produkcja alkoholu → skład podatkowy wymagany + alert KKS."""
    res = excise_warehouse_tracker(produces_alcohol=True)
    assert res["warehouse_required"] is True
    assert "PRZESTĘPSTWO SKARBOWE" in res["alert"]


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — micro/pcc (90) + plan33_pcc (60) + akcyza (133) + transport (45)."""
    res = audit_rego_files()
    assert any(f.startswith("micro/pcc/") for f in res["files_audited"])
    assert any(f.startswith("micro/akcyza/") for f in res["files_audited"])
    assert any(f.startswith("micro/transport/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 300, "Oczekiwano >300 rule_id (pcc+akcyza+transport)"
    assert res["unique_count"] > 300


def test_audit_coverage_reports_real():
    """Pokrycie artykułów: a1-a7 (PCC), a8/a12/a16 (transport), a26/a30/a99 (akcyza) COMPLETE."""
    res = audit_rego_files()
    for art in ["a1", "a2", "a3", "a4", "a6", "a7", "a8", "a12", "a16", "a26", "a30", "a99"]:
        assert res["articles"][art]["status"] == "COMPLETE", f"{art} powinno być COMPLETE"
    assert res["coverage"]["complete"] == 12


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p14_package_exists():
    """Pakiet P14 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p14_pcc_lokalne_akcyza_innovations_v9.rego"
    assert p.exists(), "Brak pliku p14_pcc_lokalne_akcyza_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p14_pcc_lokalne_akcyza_innovations" in text
    assert "default decide" in text


def test_p14_local_taxes_priority():
    """Sekcja 2 (podatki lokalne — PRIORYTET) + PCC + akcyza."""
    text = (BASE_DIR / "rules" / "p14_pcc_lokalne_akcyza_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["pcc_audit", "pcc3_generator", "pcc_detector", "local_taxes_audit",
                   "gmina_rates_registry", "real_estate_tax_calculator", "transport_tax_calculator",
                   "excise_audit", "excise_fuel_calculator", "excise_alcohol_calculator",
                   "gaps_duplicates_audit", "local_taxes_pipeline_snapshot",
                   "pcc_local_excise_coverage_report"]:
        assert marker in text, f"Brak {marker}"


def test_p14_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p14_pcc_lokalne_akcyza_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p14_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p14_pcc_lokalne_akcyza_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15
    assert text.count("_routing_reason") >= 15


def test_p14_wiring_in_main():
    """P14 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p14."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p14_pcc_lokalne_akcyza_innovations" in main
    assert '"jdg.p14_pcc_lokalne_akcyza_innovations":' in main
    assert "final_verdict_p14" in main
    # Bez kolizji ze starym pakietem v8 (jdg.p14_innovations)
    assert "import data.jdg.p14_innovations" in main


def test_p14_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "pcc_local_excise_auditor.py"),
         "--pcc3", "--real-estate", "--fuel"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["pcc3"]["tax_due"] == 2000.0
    assert data["real_estate"]["total_annual"] == round((100 * 1.43 + 200 * 33.10) * 100) / 100
    assert data["fuel"]["excise_due"] == 1566.0


def test_p14_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi."""
    assert PCC["rates"]["SALE_MOVABLE"] == 2.0
    assert PCC["rates"]["LOAN"] == 0.5
    assert PCC["pcc3_deadline_days"] == 14
    assert PCC["real_estate_rates"]["building_business"] == 33.10
    assert PCC["excise_fuel"]["benzyna"] == 1566.0
    assert PCC["excise_alcohol"]["alkohol_etylowy_pln_hl"] == 6900.0
    assert PCC["transport_heavy_threshold_t"] == 3.5
