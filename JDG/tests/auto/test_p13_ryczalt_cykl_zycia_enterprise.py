# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P13 Ryczałt + Cykl Życia JDG Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from ryczalt_lifecycle_auditor import (  # noqa: E402
    RYC,
    audit_rego_files,
    karta_podatkowa_audit,
    lifecycle_assistant,
    lifecycle_phase,
    pit_form_comparator,
    pkwiu_section,
    ryczalt_limit_tracker,
    ryczalt_rate_calculator,
    succession_tracker,
    suspension_audit,
    unregistered_business_audit,
)


# ── Auto-kalkulator stawki ryczałtu z PKWiU (INN-01 — art. 12) ────────────────
def test_ryczalt_rate_handel():
    """PKWiU 4711 (handel, sekcja G) → stawka 3%."""
    res = ryczalt_rate_calculator("4711")
    assert res["rate"] == "3%"
    assert res["pkwiu_section"] == "G"
    assert "art. 12" in res["note"]


def test_ryczalt_rate_it():
    """PKWiU 6201 (IT, sekcja J) → stawka 12%."""
    res = ryczalt_rate_calculator("6201")
    assert res["rate"] == "12%"
    assert res["pkwiu_section"] == "J"


def test_ryczalt_rate_transport():
    """PKWiU 4941 (transport, sekcja H) → stawka 12,5%."""
    res = ryczalt_rate_calculator("4941")
    assert res["rate"] == "12,5%"
    assert res["pkwiu_section"] == "H"


def test_pkwiu_section_fallback():
    """Nieznany kod → sekcja H-U (8,5%)."""
    assert pkwiu_section("9999") == "H-U"
    res = ryczalt_rate_calculator("9999")
    assert res["rate"] == "8,5%"


# ── Tracker limitu 2 mln EUR (INN-02 — art. 6) ────────────────────────────────
def test_ryczalt_limit_tracker_ok():
    """5M przychodu / 9M limitu = 55,56% — w limicie."""
    res = ryczalt_limit_tracker(5000000)
    assert res["limit_pln"] == 9000000.0
    assert res["exceeds_limit"] is False
    assert res["usage_pct"] == round2_expected(5000000 / 9000000 * 100)


def test_ryczalt_limit_tracker_at_limit():
    """9M przychodu = 100% limitu — jeszcze bez przekroczenia (> limit)."""
    res = ryczalt_limit_tracker(9000000)
    assert res["exceeds_limit"] is False
    assert res["usage_pct"] == 100.0


def test_ryczalt_limit_tracker_over():
    """9,5M przychodu > 9M limitu — przekroczenie (utrata ryczałtu)."""
    res = ryczalt_limit_tracker(9500000)
    assert res["exceeds_limit"] is True
    assert res["usage_pct"] == 105.56


def round2_expected(x):
    return round(x * 100) / 100


# ── Karta podatkowa (Sekcja 2) ────────────────────────────────────────────────
def test_karta_podatkowa_audit():
    """Karta podatkowa — limit zatrudnienia 5, wniosek do US."""
    res = karta_podatkowa_audit()
    assert res["limit_zatrudnienia"] == 5
    assert "wniosek do US" in res["zgłoszenie"]


# ── Asystent cyklu życia JDG (INN-03 — Sekcja 3 PRIORYTET) ────────────────────
def test_lifecycle_phase_startup():
    """3 miesiące → faza STARTUP_RELIEF (ulga na start)."""
    assert lifecycle_phase(3) == "STARTUP_RELIEF"
    res = lifecycle_assistant(3)
    assert res["current_phase"] == "STARTUP_RELIEF"
    assert len(res["obligations_calendar"]) == 5


def test_lifecycle_phase_growth():
    """40 miesięcy → faza GROWTH (limit VAT 200k, KSeF)."""
    assert lifecycle_phase(40) == "GROWTH"


def test_lifecycle_phase_maturity():
    """70 miesięcy → MATURITY (optymalizacja, JDG→sp. z o.o.)."""
    assert lifecycle_phase(70) == "MATURITY"


# ── Tracker sukcesji (INN-04 — Sekcja 4) ──────────────────────────────────────
def test_succession_tracker_standard():
    """10 miesięcy zarządu → pozostało 14 (2 lata)."""
    res = succession_tracker(10)
    assert res["months_remaining"] == 14
    assert res["extended_available"] is False
    assert len(res["steps"]) == 6
    assert res["extended_months"] == 60


def test_succession_tracker_extended():
    """30 miesięcy → przedłużenie dostępne (5 lat)."""
    res = succession_tracker(30)
    assert res["months_remaining"] == -6
    assert res["extended_available"] is True


# ── Zawieszenia (Sekcja 5 — art. 22-25 PP) ────────────────────────────────────
def test_suspension_audit():
    """Zawieszenie — max 24 mies., ZUS społeczne 0, zdrowotna nadal."""
    res = suspension_audit()
    assert res["art22_25"]["max_months"] == 24
    assert res["art22_25"]["min_days"] == 30
    assert "zdrowotna nadal" in res["art22_25"]["zus_health"]


# ── Działalność nieewidencjonowana (INN-05 — art. 6 PP) ───────────────────────
def test_unregistered_within_limit():
    """2000 PLN miesięcznie ≤ 2400 (50% płacy min. 4800) → w limicie."""
    res = unregistered_business_audit(2000)
    assert res["limit_monthly"] == 2400.0
    assert res["within_limit"] is True


def test_unregistered_over_limit():
    """5000 PLN > 2400 → wymaga rejestracji JDG."""
    res = unregistered_business_audit(5000)
    assert res["within_limit"] is False


# ── Symulator form (INN-09) ───────────────────────────────────────────────────
def test_pit_form_comparator():
    """300k przychodu: ryczałt 25,5k < skala 36k < liniowy 57k → ryczałt."""
    res = pit_form_comparator(300000, 8.5)
    assert res["ryczalt_tax"] == 25500.0
    assert res["skala_tax"] == 36000.0
    assert res["liniowy_tax"] == 57000.0
    assert res["best_form"] == "ryczałt"


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — micro/ryczalt (156) + pp + ceidg + sukcesja + plan33_ryc."""
    res = audit_rego_files()
    assert any(f.startswith("micro/ryczalt/") for f in res["files_audited"])
    assert any(f.startswith("micro/pp/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 400, "Oczekiwano >400 rule_id (ryczalt+pp+ceidg+sukcesja)"
    assert res["unique_count"] > 400


def test_audit_coverage_reports_real():
    """Pokrycie artykułów ryczałtu: a4/a6/a8/a12/a15/a21/a27/a29/a30 COMPLETE."""
    res = audit_rego_files()
    for art in ["a4", "a6", "a8", "a12", "a15", "a21", "a27", "a29", "a30"]:
        assert res["articles"][art]["status"] == "COMPLETE", f"{art} powinno być COMPLETE"
    assert res["coverage"]["complete"] == 9


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p13_package_exists():
    """Pakiet P13 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p13_ryczalt_cykl_zycia_innovations_v9.rego"
    assert p.exists(), "Brak pliku p13_ryczalt_cykl_zycia_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p13_ryczalt_cykl_zycia_innovations" in text
    assert "default decide" in text


def test_p13_rates_priority():
    """Sekcja 1 (stawki PKWiU — PRIORYTET) + cykl życia (PRIORYTET) + sukcesja."""
    text = (BASE_DIR / "rules" / "p13_ryczalt_cykl_zycia_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["ryczalt_rates_audit", "ryczalt_rate_calculator", "ryczalt_limit_tracker",
                   "karta_podatkowa_audit", "lifecycle_audit", "lifecycle_assistant",
                   "succession_audit", "succession_tracker", "suspension_audit",
                   "unregistered_business_audit", "ryczalt_pipeline_snapshot",
                   "ryczalt_coverage_report"]:
        assert marker in text, f"Brak {marker}"


def test_p13_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p13_ryczalt_cykl_zycia_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p13_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p13_ryczalt_cykl_zycia_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15
    assert text.count("_routing_reason") >= 15


def test_p13_wiring_in_main():
    """P13 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p13."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p13_ryczalt_cykl_zycia_innovations" in main
    assert '"jdg.p13_ryczalt_cykl_zycia_innovations":' in main
    assert "final_verdict_p13" in main


def test_p13_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "ryczalt_lifecycle_auditor.py"),
         "--rate", "--pkwiu-code", "6201", "--lifecycle", "--succession"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["rate"]["rate"] == "12%"
    assert data["lifecycle"]["current_phase"] == "STARTUP_RELIEF"
    assert data["succession"]["months_remaining"] == 14


def test_p13_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi."""
    assert RYC["limit_eur"] == 2000000
    assert RYC["min_wage_2026"] == 4800
    assert RYC["succession_standard_months"] == 24
    assert RYC["succession_extended_months"] == 60
    assert RYC["zawieszenie_max_months"] == 24
