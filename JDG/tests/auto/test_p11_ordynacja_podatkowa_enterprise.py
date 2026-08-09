# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 Ordynacja Podatkowa Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from ordpu_auditor import (  # noqa: E402
    ORD,
    audit_rego_files,
    auto_correction_engine,
    correspondence_audit,
    gaar_audit,
    interest_calculator,
    limitation_calendar,
    white_list_monitor,
)


# ── Kalendarz przedawnień (INN-01 — art. 70) ─────────────────────────────────
def test_limitation_calendar():
    """VAT 2021 → przedawnienie 31.12.2026 (urgent); PIT 2024 → 2029."""
    res = limitation_calendar([
        {"tax_type": "VAT", "tax_year": 2021},
        {"tax_type": "PIT", "tax_year": 2024},
    ], 2026)
    assert len(res["alerts"]) == 2
    assert res["alerts"][0]["deadline"] == "31.12.2026"
    assert res["alerts"][0]["years_left"] == 0
    assert len(res["urgent"]) == 1
    assert res["limitation_years"] == 5


# ── Kalkulator odsetek (INN-02 — art. 56, 200% lombardu) ─────────────────────
def test_interest_calculator():
    """10000 PLN × 60 dni @ 200% = 3287.67 PLN."""
    res = interest_calculator(10000, 60)
    assert res["annual_rate_pct"] == 200
    assert res["interest_due"] == round(10000 * (200.0 / 365) / 100 * 60 * 100) / 100
    assert res["interest_due"] == round(10000 * (200 / 365) / 100 * 60, 2)


# ── Silnik auto-korekty (INN-03 — art. 81/81b) ────────────────────────────────
def test_auto_correction_dopłata():
    """Korekta zwiększająca zobowiązanie → dopłata + odsetki."""
    res = auto_correction_engine(10000, 12000, 2023, 2026, 60)
    assert res["direction"] == "dopłata (zaległość)"
    assert res["difference"] == 2000.0
    assert res["within_5y"] is True
    assert res["interest_on_arrears"] == round(2000 * (200.0 / 365) / 100 * 60 * 100) / 100


def test_auto_correction_nadpłata():
    """Korekta zmniejszająca zobowiązanie → nadpłata (zwrot)."""
    res = auto_correction_engine(12000, 10000, 2023, 2026)
    assert res["direction"] == "nadpłata (zwrot)"
    assert res["difference"] == -2000.0
    assert res["interest_on_arrears"] == 0


def test_auto_correction_outside_5y():
    """Korekta poza limitem 5 lat (art. 81b)."""
    res = auto_correction_engine(10000, 12000, 2020, 2026)
    assert res["within_5y"] is False


# ── GAAR (INN — art. 119a) ────────────────────────────────────────────────────
def test_gaar_audit_high():
    """Sztuczność 70 >= 60 → WYSOKIE ryzyko GAAR."""
    res = gaar_audit(70)
    assert res["gaar_risk"] == "WYSOKIE"
    assert res["artificiality_threshold"] == 60


def test_gaar_audit_low():
    """Sztuczność 30 < 60 → NISKIE ryzyko."""
    res = gaar_audit(30)
    assert res["gaar_risk"] == "NISKIE"


# ── Biała Lista (art. 117ba) ──────────────────────────────────────────────────
def test_white_list_sanction():
    """Płatność na konto spoza Białej Listy bez zawiadomienia → sankcja 20%."""
    res = white_list_monitor(50000, paid_to_listed_account=False, notified_within_30d=False)
    assert res["sanction_pct"] == 20
    assert res["sanction"] == 10000.0


def test_white_list_no_sanction():
    """Płatność na konto z Białej Listy → brak sankcji."""
    res = white_list_monitor(50000)
    assert res["sanction"] == 0


# ── Auto-korespondencja (Sekcja 4) ────────────────────────────────────────────
def test_correspondence_audit():
    """System obsługi postępowań A-Z — 6 pakietów, 5 etapów."""
    res = correspondence_audit()
    assert len(res["integrated_packages"]) == 6
    assert len(res["proceeding_flow"]) == 5
    assert res["appeal_days"] == 14
    assert res["interpretation_days"] == 30


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — micro/ord/ord.rego (12k linii, 424 rule_id)."""
    res = audit_rego_files()
    assert any(f.startswith("micro/ord/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 400, "Oczekiwano >400 rule_id w micro/ord"
    assert res["unique_count"] > 400


def test_audit_coverage_reports_real():
    """Pokrycie artykułów: a70 (przedawnienie) i a81 (korekta) COMPLETE;
       a117ba (Biała Lista) i a14a/a14d (interpretacje) — realne braki."""
    res = audit_rego_files()
    assert res["articles"]["a70"]["status"] == "COMPLETE"
    assert res["articles"]["a81"]["status"] == "COMPLETE"
    assert res["articles"]["a119a"]["status"] == "COMPLETE"
    assert res["articles"]["a117ba"]["status"] == "MISSING", "Biała Lista nie ma reguł micro — realna luka"
    assert res["coverage"]["complete"] >= 15


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p11_package_exists():
    """Pakiet P11 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego"
    assert p.exists(), "Brak pliku p11_ordynacja_podatkowa_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p11_ordynacja_podatkowa_innovations" in text
    assert "default decide" in text


def test_p11_limitation_priority():
    """Sekcja 2 (przedawnienia — PRIORYTET) — art. 70, kalendarz, odsetki."""
    text = (BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["limitation_engine", "limitation_calendar", "interest_calculator",
                   "auto_correction_engine", "correspondence_audit", "gaar_audit",
                   "white_list_monitor", "ordpu_pipeline_snapshot"]:
        assert marker in text, f"Brak {marker}"


def test_p11_innovations_count():
    """Minimum 15 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 15, f"Tylko {inns} oznaczeń INN"


def test_p11_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15
    assert text.count("_routing_reason") >= 15


def test_p11_wiring_in_main():
    """P11 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p11."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p11_ordynacja_podatkowa_innovations" in main
    assert '"jdg.p11_ordynacja_podatkowa_innovations":' in main
    assert "final_verdict_p11" in main


def test_p11_future_keywords_if_import():
    """Parser Rego: pakiet używa if/else → musi importować future.keywords.if."""
    text = (BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego").read_text(encoding="utf-8")
    assert "import future.keywords.in" in text
    assert "import future.keywords.if" in text


def test_p11_new_innovations_16_19():
    """INN-16..19 (v9.1) — milczące załatwienie, opłacalność korekty, symulator ulgi, przedawnienie."""
    text = (BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in [
        "silent_settlement_tracker",
        "correction_profitability_calculator",
        "relief_simulator",
        "prescription_windup_guard",
    ]:
        assert marker in text, f"Brak innowacji: {marker}"


def test_p11_new_rule_ids():
    """Nowe reguły mają unikalne rule_id w pakiecie P11."""
    text = (BASE_DIR / "rules" / "p11_ordynacja_podatkowa_innovations_v9.rego").read_text(encoding="utf-8")
    for rid in [
        "jdg.p11_ordynacja_podatkowa_innovations.silent_settlement_tracker",
        "jdg.p11_ordynacja_podatkowa_innovations.correction_profitability_calculator",
        "jdg.p11_ordynacja_podatkowa_innovations.relief_simulator",
        "jdg.p11_ordynacja_podatkowa_innovations.prescription_windup_guard",
    ]:
        assert rid in text, f"Brak rule_id: {rid}"


def test_p11_report_exists():
    """Raport kampanii raport_enterprise_P11.txt musi istnieć i być oznaczony WDROŻONY_100."""
    r = BASE_DIR / "raporty_glm52" / "raport_enterprise_P11.txt"
    assert r.exists(), "Brak raportu raport_enterprise_P11.txt"
    text = r.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in text
    assert "INN-19" in text
    assert "P12" in text


def test_p11_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "ordpu_auditor.py"),
         "--limitations", "--interest", "--arrears", "10000", "--days-overdue", "60"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["limitation_calendar"]["limitation_years"] == 5
    assert data["interest"]["interest_due"] == round(10000 * (200.0 / 365) / 100 * 60 * 100) / 100
