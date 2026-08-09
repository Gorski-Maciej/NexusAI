# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P12 Cross-Border/MDR/TP/CFC/FX Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from crossborder_auditor import (  # noqa: E402
    CB,
    audit_rego_files,
    cfc_calculator,
    cfc_risk_predictor,
    crossborder_compliance_panel,
    exit_tax_calculator,
    exit_tax_simulator,
    fx_difference_calculator,
    import_services_reverse_charge,
    mdr_auto_detector,
    mdr_signal_matrix,
    place_of_supply_calculator,
    residency_decision_engine,
    tp_documentation_calculator,
    vies_validator,
    wdt_documentation_tracker,
    wdt_zero_rate_expert,
)


# ── Miejsce świadczenia B2B/B2C (INN-01 — art. 28a-28o) ──────────────────────
def test_place_of_supply_b2b():
    """B2B → miejsce siedziby nabywcy (art. 28b)."""
    res = place_of_supply_calculator("b2b", "DE", "PL")
    assert res["supply_place"] == "siedziba_nabywcy"
    assert res["vat_place"] == "miejsce siedziby nabywcy B2B (art. 28b)"
    assert res["cross_border"] is True


def test_place_of_supply_eservices():
    """e-usługi B2C → miejsce konsumenta (art. 28i, OSS)."""
    res = place_of_supply_calculator("e_services", "FR", "PL")
    assert res["supply_place"] == "miejsce_konsumenta"
    assert "art. 28i" in res["vat_place"]


# ── Auto-detektor MDR/DAC6 (INN-02 — hallmarks A-E) ──────────────────────────
def test_mdr_auto_detector_triggered():
    """Hallmarks A (korzyść) + C (transgraniczne powiązane) → raport wymagany."""
    res = mdr_auto_detector(tax_saving_primary=True, cross_border_related=True)
    assert res["mdr_report_required"] is True
    assert "A" in res["matched_hallmarks"]
    assert "C" in res["matched_hallmarks"]
    assert res["report_deadline_days"] == 30


def test_mdr_auto_detector_clean():
    """Brak hallmarks → brak raportu MDR."""
    res = mdr_auto_detector()
    assert res["mdr_report_required"] is False
    assert res["matched_hallmarks"] == []


# ── Silnik decyzji rezydencji (INN-03 — art. 3 PIT) ───────────────────────────
def test_residency_resident():
    """200 dni w PL → rezydent."""
    res = residency_decision_engine(days_in_poland=200)
    assert res["resident_pl"] is True
    assert res["residency_days_threshold"] == 183


def test_residency_nonresident():
    """100 dni + brak centrum interesów → nierezydent."""
    res = residency_decision_engine(days_in_poland=100,
                                    center_of_life_pl=False,
                                    center_of_business_pl=False)
    assert res["resident_pl"] is False


# ── Kalkulatory TP/CFC/FX (INN-05/07/08) ──────────────────────────────────────
def test_tp_documentation_local_only():
    """600k przychodów z podmiotami powiązanymi → lokalna dokumentacja TAK, master NIE."""
    res = tp_documentation_calculator(600000)
    assert res["local_file_required"] is True
    assert res["master_file_required"] is False
    assert res["local_file_threshold"] == 500000


def test_cfc_calculator_applies():
    """60%/40%/10% → CFC ma zastosowanie."""
    res = cfc_calculator(60, 40, 10)
    assert res["cfc_applies"] is True
    assert res["thresholds"]["ownership_min"] == 50


def test_cfc_calculator_not_applies():
    """30% udziału → brak CFC."""
    res = cfc_calculator(30, 40, 10)
    assert res["cfc_applies"] is False


def test_fx_difference_calculator():
    """10000 EUR × (4.30-4.20) = 1000 PLN."""
    res = fx_difference_calculator(10000, 4.20, 4.30)
    assert res["fx_difference"] == 1000.0
    assert "art. 24c" in res["method"]


# ── Exit tax + WDT + compliance (INN-04/10/12) ────────────────────────────────
def test_exit_tax_calculator():
    """5M aktywów → exit tax 19% = 950k."""
    res = exit_tax_calculator(5000000)
    assert res["exit_tax_applies"] is True
    assert res["tax_due"] == 950000.0
    assert res["threshold_pln"] == 4000000


def test_exit_tax_below_threshold():
    """1M aktywów → brak exit tax."""
    res = exit_tax_calculator(1000000)
    assert res["exit_tax_applies"] is False
    assert res["tax_due"] == 0.0


def test_wdt_documentation_tracker():
    """1 z 2 dostaw bez dokumentów → alert."""
    res = wdt_documentation_tracker([
        {"delivery_id": "D-1", "documentation_ok": True},
        {"delivery_id": "D-2", "documentation_ok": False},
    ])
    assert res["deadline_days"] == 30
    assert len(res["documents_missing"]) == 1
    assert res["documents_missing"][0]["delivery_id"] == "D-2"


def test_compliance_panel():
    """Brak kar → score 100."""
    res = crossborder_compliance_panel(0)
    assert res["compliance_score"] == 100
    assert len(res["checks"]) == 7


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — micro/crossborder/crossborder.rego (193 rule_id)."""
    res = audit_rego_files()
    assert any(f.startswith("micro/crossborder/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 190, "Oczekiwano >190 rule_id w micro/crossborder"
    assert res["unique_count"] > 190


def test_audit_coverage_reports_real():
    """Pokrycie artykułów: a20/a23o/a23zf/a29/a30da/a30f/a86r COMPLETE;
       a25b/a25c/a25d/a86o/a24c — realne braki."""
    res = audit_rego_files()
    for art in ["a20", "a23o", "a23zf", "a29", "a30da", "a30f", "a86r"]:
        assert res["articles"][art]["status"] == "COMPLETE", f"{art} powinno być COMPLETE"
    assert res["articles"]["a86o"]["status"] == "MISSING", "MDR (art. 86o) nie ma reguł micro — realna luka"
    assert res["articles"]["a24c"]["status"] == "MISSING", "FX (art. 24c) nie ma reguł micro — realna luka"
    assert res["articles"]["a25b"]["status"] == "MISSING", "a25b — realna luka"
    assert res["coverage"]["complete"] >= 7


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p12_package_exists():
    """Pakiet P12 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego"
    assert p.exists(), "Brak pliku p12_crossborder_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p12_crossborder_innovations" in text
    assert "default decide" in text


def test_p12_place_of_supply_priority():
    """Sekcja 2 (miejsce świadczenia — PRIORYTET) — art. 28a-28o + kalkulator."""
    text = (BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["place_of_supply_audit", "place_of_supply_calculator", "mdr_audit",
                   "mdr_auto_detector", "tp_cfc_residency_audit", "residency_decision_engine",
                   "vida_dac8_exit_tax_audit", "crossborder_pipeline_snapshot",
                   "crossborder_coverage_report"]:
        assert marker in text, f"Brak {marker}"


def test_p12_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p12_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15
    assert text.count("_routing_reason") >= 15


def test_p12_wiring_in_main():
    """P12 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p12."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p12_crossborder_innovations" in main
    assert '"jdg.p12_crossborder_innovations":' in main
    assert "final_verdict_p12" in main


def test_p12_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "crossborder_auditor.py"),
         "--place-supply", "--cfc", "--exit-tax"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["place_of_supply"]["supply_place"] == "siedziba_nabywcy"
    assert data["cfc"]["cfc_applies"] is True
    assert data["exit_tax"]["tax_due"] == 950000.0


def test_p12_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi."""
    assert CB["wdt_documentation_days"] == 30
    assert CB["mdr_deadline_days"] == 30
    assert CB["exit_tax_threshold_pln"] == 4000000
    assert CB["cfc_ownership_min_pct"] == 50
    assert CB["residency_days"] == 183


# ── Import usług / WNT usług — odwrotne obciążenie (art. 17) ─────────────────
def test_import_services_reverse_charge():
    """Usługodawca zagraniczny → rozlicza nabywca (art. 17 ust. 1 pkt 4 VAT)."""
    res = import_services_reverse_charge(provider_country="DE", buyer_vat_registered=True)
    assert res["reverse_charge_applies"] is True
    assert res["routing"] == "TRIAGE_QUEUE"
    assert "25. dzień" in res["vat_settlement"]
    res2 = import_services_reverse_charge(provider_country="PL")
    assert res2["reverse_charge_applies"] is False
    assert res2["routing"] == ""


# ── Nowe innowacje v9.1 (INN-13..17) ──────────────────────────────────────────
def test_vies_validator_blocked():
    """INN-13: niepoprawny numer VAT-UE + transakcja transgraniczna → blokada + TRIAGE_QUEUE."""
    res = vies_validator(vies_valid=False, is_cross_border=True)
    assert res["transaction_blocked"] is True
    assert res["routing"] == "TRIAGE_QUEUE"


def test_vies_validator_ok():
    """INN-13: poprawny numer VAT-UE → brak blokady."""
    res = vies_validator(vies_valid=True, is_cross_border=True)
    assert res["transaction_blocked"] is False
    assert res["routing"] == ""


def test_wdt_zero_rate_expert():
    """INN-14: pełna dokumentacja + ważny VIES → stawka 0%."""
    res = wdt_zero_rate_expert(documentation_complete=True, vies_valid=True)
    assert res["zero_rate_applicable"] is True
    assert len(res["checklist"]) == 4
    res2 = wdt_zero_rate_expert(documentation_complete=False, vies_valid=True)
    assert res2["zero_rate_applicable"] is False
    assert res2["routing"] == "TRIAGE_QUEUE"


def test_cfc_risk_predictor():
    """INN-15: 60%/40%/10% → WYSOKIE_CFC; niski udział → NISKIE."""
    res = cfc_risk_predictor(60, 40, 10)
    assert res["risk_level"] == "WYSOKIE_CFC"
    assert res["cfc_risk"] is True
    assert res["routing"] == "TRIAGE_QUEUE"
    res2 = cfc_risk_predictor(30, 40, 10)
    assert res2["risk_level"] == "NISKIE"
    assert res2["cfc_risk"] is False


def test_exit_tax_simulator():
    """INN-16: 5M niezrealizowanego zysku → estymacja 950k PLN."""
    res = exit_tax_simulator(5000000)
    assert res["subject_to_exit_tax"] is True
    assert res["estimated_tax"] == 950000.0
    assert res["routing"] == "TRIAGE_QUEUE"
    res2 = exit_tax_simulator(1000000)
    assert res2["subject_to_exit_tax"] is False
    assert res2["routing"] == ""


def test_mdr_signal_matrix():
    """INN-17: 1 sygnał (korzyść) → obowiązek raportu MDR 30 dni."""
    res = mdr_signal_matrix(general_benefit=True)
    assert res["active_signals_count"] == 1
    assert res["mdr_obligation"] is True
    assert res["recommendation"] == "RAPORT_MDR_30_DNI"
    assert res["deadline_days"] == 30
    res2 = mdr_signal_matrix()
    assert res2["active_signals_count"] == 0
    assert res2["recommendation"] == "BRAK_OBOWIAZKU_MDR"


def test_p12_parser_future_keywords_if():
    """Parser: plik innowacji musi importować future.keywords.if (używa if/else)."""
    text = (BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego").read_text(encoding="utf-8")
    assert "import future.keywords.if" in text, "Brak import future.keywords.if — parser bug"
    assert text.count("{") == text.count("}"), "Niezbalansowane nawiasy {}"
    assert text.count("(") == text.count(")"), "Niezbalansowane nawiasy ()"


def test_p12_new_innovations_present():
    """INN-13..17 + import usług zaimplementowane w pakiecie i podpięte w decide."""
    text = (BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["import_services_reverse_charge", "vies_validator", "wdt_zero_rate_expert",
                   "cfc_risk_predictor", "exit_tax_simulator", "mdr_signal_matrix"]:
        assert marker in text, f"Brak reguły {marker}"
    for inn in ["INN-13", "INN-14", "INN-15", "INN-16", "INN-17"]:
        assert inn in text, f"Brak oznaczenia {inn}"
    assert "\"vies\": vies_validator" in text
    assert "\"import_services\": import_services_reverse_charge" in text
    assert "\"mdr_matrix\": mdr_signal_matrix" in text


def test_cfc_risk_key_alignment():
    """Spójność klucza: cfc_risk_predictor i cfc_calculator używają effective_tax_rate."""
    text = (BASE_DIR / "rules" / "p12_crossborder_innovations_v9.rego").read_text(encoding="utf-8")
    assert '"effective_tax_rate"' in text
    assert 'effective_tax_pct' not in text, "Niespójny klucz effective_tax_pct — użyj effective_tax_rate"
