# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P09 Ksiegowosc PKPiR + UoR + Amortyzacja Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from ksiegowosc_pkpir_uor_auditor import (  # noqa: E402
    ACCOUNTING,
    audit_rego_files,
    car_limit_audit,
    kst_depreciation,
    leasing_comparator,
    one_time_depreciation,
    pkpir_structure_audit,
    pkpir_validator,
    remanent_simulator,
    uor_obligation_engine,
)


# ── Silnik decyzji "PKPiR czy UoR?" (INN-01 — PRIORYTET) ─────────────────────
def test_uor_obligation_engine_exceeds():
    """Przychód 9M PLN = 2M EUR → obowiązek UoR."""
    res = uor_obligation_engine(9000000)
    assert res["annual_revenue_eur"] == 2000000.0
    assert res["threshold_eur"] == 2000000
    assert res["exceeds"] is True
    assert res["decision"] == "UoR"


def test_uor_obligation_engine_early_warning():
    """Przychód 7.5M PLN → 75% progu, ostrzeżenie aktywne, decyzja PKPiR."""
    res = uor_obligation_engine(7500000)
    assert res["exceeds"] is False
    assert res["early_warning_active"] is True
    assert res["decision"] == "PKPiR"


def test_uor_obligation_engine_below():
    """Przychód 3M PLN → daleko od progu, PKPiR bez ostrzeżenia."""
    res = uor_obligation_engine(3000000)
    assert res["exceeds"] is False
    assert res["early_warning_active"] is False
    assert res["decision"] == "PKPiR"


# ── Struktura PKPiR (kolumny 1-17) ────────────────────────────────────────────
def test_pkpir_structure_17_columns():
    """Kolumny 1-17, 14 wymaganych, dekretacja operacji."""
    res = pkpir_structure_audit()
    assert res["column_count"] == 17
    assert res["required_columns"] == 14
    assert res["column_mapping"]["sale_goods"] == "7"
    assert res["column_mapping"]["wages"] == "12"


def test_pkpir_validator_consistent():
    """Walidator: kol. 9 = 7+8 i kol. 14 = 10+11+12+13."""
    ok = pkpir_validator(1000, 200, 1200, 300, 50, 100, 150, 600)
    assert ok["income_ok"] is True
    assert ok["expenses_ok"] is True
    assert ok["consistent"] is True
    bad = pkpir_validator(1000, 200, 1300, 300, 50, 100, 150, 600)
    assert bad["consistent"] is False


# ── Amortyzacja i leasing (Sekcja 3) ──────────────────────────────────────────
def test_kst_depreciation_dual():
    """KŚT grupa 4 (14%) vs stawka bilansowa 20% — różnica 6 000."""
    res = kst_depreciation(100000, "4", 0.20)
    assert res["tax_rate"] == 0.14
    assert res["tax_annual"] == 14000.0
    assert res["book_annual"] == 20000.0
    assert res["difference"] == 6000.0


def test_one_time_depreciation_limit():
    """Jednorazowa amortyzacja: limit 450k PLN (100k EUR × 4.50)."""
    ok = one_time_depreciation(350000)
    assert ok["limit_pln"] == 450000.0
    assert ok["within_limit"] is True
    assert ok["excess"] == 0
    over = one_time_depreciation(500000)
    assert over["within_limit"] is False
    assert over["excess"] == 50000.0


def test_car_limit_audit():
    """Auto osobowe: limit 150k, nadwyżka 30k; elektryk: limit 225k."""
    res = car_limit_audit(180000)
    assert res["limit"] == 150000
    assert res["excess"] == 30000.0
    electric = car_limit_audit(180000, is_electric=True)
    assert electric["limit"] == 225000
    assert electric["excess"] == 0


def test_leasing_comparator():
    """Leasing operacyjny (cała rata KUP) vs finansowy (tylko odsetki 20%)."""
    res = leasing_comparator(2000, 0.20)
    assert res["operating_kup_monthly"] == 2000.0
    assert res["financial_kup_monthly"] == 400.0
    assert res["annual_difference"] == 19200.0
    assert res["recommendation"] == "operacyjny"


# ── Remanent (Sekcja 4) ───────────────────────────────────────────────────────
def test_remanent_simulator():
    """Remanent: różnica zamknięcie-otwarcie = wpływ na dochód roku następnego."""
    res = remanent_simulator(10000, 45000)
    assert res["income_impact_next_year"] == 35000.0


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — katalogi micro/pkpir i uor."""
    res = audit_rego_files()
    assert any(f.startswith("micro/pkpir/") for f in res["pkpir_files"])
    assert any(f.startswith("uor/") for f in res["uor_files"])
    assert res["pkpir_unique_count"] > 0
    assert res["uor_unique_count"] > 0


def test_audit_coverage_reports_real():
    """Pokrycie artykułów UoR i kolumn PKPiR musi raportować realne COMPLETE."""
    res = audit_rego_files()
    assert res["uor_coverage"]["complete"] >= 1, "Za mało COMPLETE artykułów UoR"
    assert res["articles"]["a2"]["status"] == "COMPLETE", "a2 (obowiązek UoR) powinien być COMPLETE"
    assert res["pkpir_columns_coverage"]["complete"] >= 1
    assert res["rates_packages"]["pkpir_rates"] is True
    assert res["rates_packages"]["uor_rates"] is True


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p09_package_exists():
    """Pakiet P09 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p09_ksiegowosc_pkpir_uor_innovations_v9.rego"
    assert p.exists(), "Brak pliku p09_ksiegowosc_pkpir_uor_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p09_ksiegowosc_pkpir_uor_innovations" in text
    assert "default decide" in text


def test_p09_uor_priority():
    """Sekcja 2 (UoR — PRIORYTET) — próg 2M EUR, silnik decyzji, memoriał."""
    text = (BASE_DIR / "rules" / "p09_ksiegowosc_pkpir_uor_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["uor_obligation_engine", "uor_audit", "pkpir_structure_audit",
                   "amortization_dual_calculator", "remanent_simulator",
                   "pkpir_uor_transformation_audit", "accounting_pipeline_snapshot"]:
        assert marker in text, f"Brak {marker}"


def test_p09_innovations_count():
    """Minimum 15 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p09_ksiegowosc_pkpir_uor_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 15, f"Tylko {inns} oznaczeń INN"


def test_p09_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p09_ksiegowosc_pkpir_uor_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15
    assert text.count("_routing_reason") >= 15


def test_p09_wiring_in_main():
    """P09 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p09."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p09_ksiegowosc_pkpir_uor_innovations" in main
    assert '"jdg.p09_ksiegowosc_pkpir_uor_innovations":' in main
    assert "final_verdict_p09" in main


def test_p09_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "ksiegowosc_pkpir_uor_auditor.py"),
         "--uor", "--revenue", "9000000"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["uor_obligation"]["decision"] == "UoR"
    assert data["uor_obligation"]["annual_revenue_eur"] == 2000000.0
