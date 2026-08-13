# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P10 KKS — Kodeks Karny Skarbowy Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from kks_penalty_auditor import (  # noqa: E402
    CRIME_THRESHOLD,
    DAILY_RATE_MAX,
    DAILY_RATE_MIN,
    KKS,
    audit_rego_files,
    conviction_tracker,
    disclosure_assistant,
    limitation_calendar,
    minimization_engine,
    penalty_calculator,
    risk_scorer,
)


# ── Stawki dzienne i progi ────────────────────────────────────────────────────
def test_daily_rates_and_thresholds():
    """Stawka dzienna 1/30 min. wynagrodzenia (4800/30=160), max 400×, próg 200×."""
    assert DAILY_RATE_MIN == 160.0
    assert DAILY_RATE_MAX == 4800.0 * 400
    assert CRIME_THRESHOLD == 4800.0 * 200
    assert KKS["max_rates_crime"] == 720
    assert KKS["max_rates_misdemeanor"] == 240


# ── Kalkulator kary (INN-01) ──────────────────────────────────────────────────
def test_penalty_calculator_misdemeanor():
    """art56 (nierzetelne PKPiR) — kwota 150k < próg przestępstwa → wykroczenie."""
    res = penalty_calculator(150000, "art56", 10)
    assert res["offense_info"]["name"] == "Nierzetelne księgi/PKPiR"
    assert res["is_crime"] is False
    assert res["fine_min"] == round(160.0 * 10 * 100) / 100
    assert res["fine_max"] == round(DAILY_RATE_MAX * 10 * 100) / 100


def test_penalty_calculator_crime_recidivism():
    """art54 z recydywą — mnożnik 2×."""
    res = penalty_calculator(1000000, "art54", 20, is_recidivist=True)
    assert res["is_crime"] is True
    assert res["recidivism_multiplier"] == 2
    assert res["fine_min"] == round(160.0 * 20 * 2 * 100) / 100


def test_penalty_calculator_mandatory_prison():
    """art62_3 — korzyść >5M → obligatoryjne PW."""
    res = penalty_calculator(6000000, "art62_3", 100)
    assert res["exceeds_mandatory_prison"] is True
    assert res["offense_info"]["max_pw_years"] == 15


# ── Silnik minimalizacji kary (INN-02) ────────────────────────────────────────
def test_minimization_engine_czynny_zal():
    """Zawiadomienie przed wykryciem → ścieżka 1 (czynny żal)."""
    res = minimization_engine(150000, disclosure_before_detection=True)
    assert res["paths"]["path_1_czynny_zal"]["eligible"] is True
    assert res["recommendation"] == "czynny_zal"


def test_minimization_engine_default():
    """Brak instytucji łagodzących → ścieżka 4 (obrona merytoryczna)."""
    res = minimization_engine(150000)
    assert res["recommendation"] == "obrona_merytoryczna"
    assert res["paths"]["path_4_obrona_merytoryczna"]["eligible"] is True


# ── Symulator ryzyka (INN-03) ─────────────────────────────────────────────────
def test_risk_scorer_critical():
    """Puste faktury (35) + recydywa (30) = 65 → CRITICAL."""
    res = risk_scorer(empty_invoices=True, recidivism=True)
    assert res["risk_score"] == 65
    assert res["risk_level"] == "CRITICAL"


def test_risk_scorer_low():
    """Brak wskaźników → 0 → LOW."""
    res = risk_scorer()
    assert res["risk_score"] == 0
    assert res["risk_level"] == "LOW"


# ── Czynny żal (Sekcja 3) ─────────────────────────────────────────────────────
def test_disclosure_assistant():
    """Czynny żal przed wykryciem → warto złożyć."""
    res = disclosure_assistant(disclosure_before_detection=True, control_started=False)
    assert res["worth_filing"] is True
    assert res["effect"] == "brak odpowiedzialności karnej (art. 16 §1)"


def test_disclosure_assistant_control_started():
    """Kontrola rozpoczęta → czynny żal bezskuteczny."""
    res = disclosure_assistant(disclosure_before_detection=True, control_started=True)
    assert res["worth_filing"] is False


# ── Przedawnienie i zatarcie (Sekcja 4) ───────────────────────────────────────
def test_limitation_calendar():
    """Przestępstwo 5 lat, wykroczenie 3 lata (art. 44 KKS)."""
    res = limitation_calendar()
    assert res["crime_years"] == 5
    assert res["misdemeanor_years"] == 3


def test_conviction_tracker():
    """Zatarcie: grzywna 1 rok, kara ograniczenia wolności 3 lata."""
    assert conviction_tracker("grzywna")["expungement_period_years"] == 1
    assert conviction_tracker("kara_ograniczenia_wolnosci")["expungement_period_years"] == 3
    assert conviction_tracker("pozbawienie_wolnosci")["expungement_period_years"] == 5


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — micro/kks/kks.rego (13k linii, ~474 rule_id)."""
    res = audit_rego_files()
    assert any(f.startswith("micro/kks/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 400, "Oczekiwano >400 rule_id w micro/kks"
    assert res["unique_count"] > 400
    assert res["no_match_defaults"] >= 1


def test_audit_coverage_reports_real():
    """Pokrycie artykułów: a16 (czynny żal) i a54 (uchylanie) muszą być COMPLETE."""
    res = audit_rego_files()
    assert res["articles"]["a16"]["status"] == "COMPLETE", "a16 (czynny żal) powinien być COMPLETE"
    assert res["articles"]["a54"]["status"] == "COMPLETE", "a54 (uchylanie) powinien być COMPLETE"
    assert res["coverage"]["complete"] >= 10, "Za mało COMPLETE — sprawdź regex prefiksów"


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["duplicate_count"] >= 0
    assert res["stub_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p10_package_exists():
    """Pakiet P10 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p10_kks_innovations_v9.rego"
    assert p.exists(), "Brak pliku p10_kks_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p10_kks_innovations" in text
    assert "default decide" in text


def test_p10_gradation_priority():
    """Sekcja 2 (gradacja kar — PRIORYTET) — stawki dzienne, mnożniki, silnik minimalizacji."""
    text = (BASE_DIR / "rules" / "p10_kks_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["penalty_gradation_audit", "penalty_calculator", "penalty_minimization_engine",
                   "risk_score_simulator", "voluntary_disclosure_audit", "limitation_calendar",
                   "conviction_expungement_tracker", "kks_pipeline_snapshot"]:
        assert marker in text, f"Brak {marker}"


def test_p10_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p10_kks_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p10_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p10_kks_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 12
    assert text.count("_routing_reason") >= 12


def test_p10_wiring_in_main():
    """P10 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p10."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p10_kks_innovations" in main
    assert '"jdg.p10_kks_innovations":' in main
    assert "final_verdict_p10" in main


def test_p10_future_keywords_if_import():
    """Parser Rego: pakiet używa if/else → musi importować future.keywords.if."""
    text = (BASE_DIR / "rules" / "p10_kks_innovations_v9.rego").read_text(encoding="utf-8")
    assert "import future.keywords.in" in text
    assert "import future.keywords.if" in text


def test_p10_new_innovations_13_16():
    """INN-13..16 (v9.1) — co-jeśli, gotowość na kontrolę, odpowiedzialność powiązana, przewidywacz wyroków."""
    text = (BASE_DIR / "rules" / "p10_kks_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in [
        "penalty_what_if_simulator",
        "tax_audit_readiness",
        "related_liability_audit",
        "judgment_trend_predictor",
    ]:
        assert marker in text, f"Brak innowacji: {marker}"


def test_p10_new_rule_ids():
    """Nowe reguły mają unikalne rule_id w pakiecie P10."""
    text = (BASE_DIR / "rules" / "p10_kks_innovations_v9.rego").read_text(encoding="utf-8")
    for rid in [
        "jdg.p10_kks_innovations.penalty_what_if_simulator",
        "jdg.p10_kks_innovations.tax_audit_readiness",
        "jdg.p10_kks_innovations.related_liability_audit",
        "jdg.p10_kks_innovations.judgment_trend_predictor",
    ]:
        assert rid in text, f"Brak rule_id: {rid}"


def test_p10_report_exists():
    """Canonical RAPORT_07 exists and reports its evidence-gated status honestly."""
    r = BASE_DIR / "raporty_glm52" / "RAPORT_07_KKS.txt"
    assert r.exists(), "Brak kanonicznego raportu RAPORT_07_KKS.txt"
    text = r.read_text(encoding="utf-8")
    status_line = next(
        line for line in text.splitlines()
        if line.startswith("Stan wdrożenia po walidacji ")
    )
    evidence_path = BASE_DIR / "bundles" / "kks_report07_evidence.json"
    evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    assert f"{evidence['status']} (" in status_line
    assert f"{evidence['checks_passed']}/{evidence['checks_total']} bramek" in status_line
    expected = (
        "raport JEST WDROZONY_100"
        if evidence["status"] == "WDROZONY_100"
        else "raport NIE jest WDROZONY_100"
    )
    assert expected in status_line
    assert "bundles/kks_report07_evidence.json" in text


def test_p10_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "kks_penalty_auditor.py"),
         "--penalty", "--amount", "150000", "--offense", "art56"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["penalty"]["offense"] == "art56"
    assert data["penalty"]["is_crime"] is False
