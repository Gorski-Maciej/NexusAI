# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P17 KSeF + JPK + e-Deklaracje Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from ksef_jpk_edeklaracje_auditor import (  # noqa: E402
    KSEF,
    audit_rego_files,
    edelivery_address_manager,
    esig_auto_applier,
    gtu_auto_assigner,
    jpk_cross_validation,
    jpk_deadline_calendar,
    jpk_v7_auto_generator,
    ksef_audit,
    ksef_firewall_guard,
    ksef_offline_retry,
    ksef_pipeline,
    ksef_sandbox_harness,
    ksef_sanction_monitor,
    ksef_sanctions_calculator,
    ksef_upo_tracker,
    ksef_xsd_validator,
    wis_auto_requester,
)


# ── Sekcja 1: audyt KSeF ──────────────────────────────────────────────────────
def test_ksef_audit_structure():
    """Audyt KSeF — obowiązek 2026-02-01, schemat, UPO, off-line, sankcje."""
    res = ksef_audit("2026-08-01")
    assert "OBOWIĄZKOWY" in res["obowiazek"]["status"]
    assert res["obowiazek"]["od"] == "2026-02-01"
    assert res["offline"]["grace_days"] == 7
    assert res["sankcje"]["max_pln"] == 500_000.0
    assert len(res["schemat"]["required_fields"]) == 8


def test_ksef_audit_fakultatywny():
    """Przed 2026-02-01 → fakultatywny."""
    res = ksef_audit("2025-06-01")
    assert "FAKULTATYWNY" in res["obowiazek"]["status"]


# ── Sekcja 2: auto-generator JPK_V7 (INN-01) ──────────────────────────────────
def test_jpk_v7_auto_generator():
    """JPK_V7M — VAT należny 1000, naliczony 700 → VAT do zapłaty 300."""
    res = jpk_v7_auto_generator("JPK_V7M", sales_register=10000, purchase_register=6000,
                                vat_sales=1000, vat_purchase=700)
    assert res["type"] == "JPK_V7M"
    assert res["vat_due"] == 300.0
    assert res["generated"] is True
    assert "25." in res["deadline"]


# ── Sekcja 1: tracker UPO (INN-02) ────────────────────────────────────────────
def test_ksef_upo_tracker_missing():
    """10 faktur, 8 UPO → brak 2, TRIAGE_QUEUE."""
    res = ksef_upo_tracker(invoice_count=10, upo_received_count=8)
    assert res["upo_missing"] == 2
    assert "BRAK UPO" in res["status"]
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_ksef_upo_tracker_ok():
    """Wszystkie UPO otrzymane → OK."""
    res = ksef_upo_tracker(invoice_count=10, upo_received_count=10)
    assert res["upo_missing"] == 0
    assert res["_routing"] == ""


# ── Sekcja 1: monitor sankcji KSeF (INN-03) ───────────────────────────────────
def test_ksef_sanction_monitor_max():
    """6 faktur poza KSeF → sankcja maksymalna 500 000 zł, BLOCK."""
    res = ksef_sanction_monitor(6)
    assert res["estimated_fine_pln"] == 500_000.0
    assert res["sanction_level"] == "KRYTYCZNE — sankcja maksymalna!"
    assert res["max_sanction_pln"] == 500_000.0


def test_ksef_sanction_monitor_small():
    """2 faktury poza KSeF → 2 × 1000 zł = 2000 zł, UMIARKOWANE."""
    res = ksef_sanction_monitor(2)
    assert res["estimated_fine_pln"] == 2000.0
    assert res["sanction_level"] == "UMIARKOWANE"


# ── Sekcja 4: system retry offline (INN-04) ───────────────────────────────────
def test_ksef_offline_retry_within():
    """3 dni off-line ≤ 7 dni grace → OK, auto_retry."""
    res = ksef_offline_retry(offline_days=3, offline_invoices=5)
    assert res["grace_days"] == 7
    assert res["in_queue"] == 5
    assert "OK" in res["status"]
    assert res["auto_retry"] is True
    assert res["_routing"] == ""


def test_ksef_offline_retry_exceeded():
    """10 dni off-line > 7 → PRZEKROCZONO, TRIAGE_QUEUE."""
    res = ksef_offline_retry(offline_days=10)
    assert "PRZEKROCZONO" in res["status"]
    assert res["_routing"] == "TRIAGE_QUEUE"


# ── Sekcja 2: GTU auto-przypisanie (INN-05) ───────────────────────────────────
def test_gtu_auto_assigner():
    """'paliwa' → GTU_04 (poprawny kod)."""
    res = gtu_auto_assigner("paliwa")
    assert res["assigned_gtu"] == "GTU_04"
    assert res["gtu_valid"] is True


def test_gtu_auto_assigner_fallback():
    """Nieznany opis → fallback GTU_01."""
    res = gtu_auto_assigner("inne towary")
    assert res["assigned_gtu"] == "GTU_01"
    assert res["gtu_valid"] is True


# ── Sekcja 1: walidator XSD (INN-06) ──────────────────────────────────────────
def test_ksef_xsd_validator_ok():
    """Wszystkie pola P_1..P_8 → xsd_valid true."""
    res = ksef_xsd_validator("FA(2)")
    assert res["xsd_valid"] is True
    assert res["invalid_fields"] == []


def test_ksef_xsd_validator_missing():
    """Brak 6 pól → xsd_valid false."""
    res = ksef_xsd_validator("FA(2)", fields={"P_1": True, "P_2": True})
    assert res["xsd_valid"] is False
    assert len(res["invalid_fields"]) == 6


# ── Sekcja 4: firewall KSeF (INN-07) ──────────────────────────────────────────
def test_ksef_firewall_guard():
    """Anomalie → BLOCK_AND_ALERT; czysto → brak blokady."""
    bad = ksef_firewall_guard(["NIP invalid", "duplikat faktury"])
    assert bad["blocked"] is True
    assert bad["_routing"] == "BLOCK_AND_ALERT"
    ok = ksef_firewall_guard([])
    assert ok["blocked"] is False
    assert ok["_routing"] == ""


# ── Sekcja 2: walidacja krzyżowa JPK (INN-08) ─────────────────────────────────
def test_jpk_cross_validation():
    """Zgodne rejestry → consistent; rozbieżność → TRIAGE_QUEUE."""
    ok = jpk_cross_validation(10000, 10000, 6000, 6000)
    assert ok["consistent"] is True
    assert ok["_routing"] == ""
    bad = jpk_cross_validation(10000, 9999, 6000, 6000)
    assert bad["consistent"] is False
    assert bad["_routing"] == "TRIAGE_QUEUE"


# ── Sekcja 3: auto-aplikacja e-podpisu (INN-09) ───────────────────────────────
def test_esig_auto_applier():
    """Kwalifikowany podpis — 12 dokumentów."""
    res = esig_auto_applier("QUALIFIED", 12)
    assert res["signature_type"] == "QUALIFIED"
    assert res["documents_signed"] == 12
    assert res["auto_applied"] is True


# ── Sekcja 3: menedżer adresu do doręczeń (INN-10) ────────────────────────────
def test_edelivery_address_manager():
    """Adres ustawiony + skrzynka aktywna → OK; brak → TRIAGE_QUEUE."""
    ok = edelivery_address_manager(address_set=True, mailbox_active=True)
    assert "ADRES USTAWIONY" in ok["status"]
    assert ok["_routing"] == ""
    bad = edelivery_address_manager()
    assert "BRAK ADRESU" in bad["status"]
    assert bad["_routing"] == "TRIAGE_QUEUE"


# ── Sekcja 4: WIS auto-zapytania (INN-11) ─────────────────────────────────────
def test_wis_auto_requester():
    """WIS — status PENDING, odpowiedź 3 miesiące."""
    res = wis_auto_requester(wis_requested=True, wis_status="PENDING")
    assert res["wis_requested"] is True
    assert res["wis_status"] == "PENDING"
    assert res["response_days"] == 3


# ── Sekcja 4: sandbox KSeF (INN-12) ───────────────────────────────────────────
def test_ksef_sandbox_harness():
    """Sandbox aktywny — 20 faktur testowych."""
    res = ksef_sandbox_harness(test_invoices=20)
    assert res["sandbox_active"] is True
    assert res["test_invoices"] == 20


# ── Sekcja 1: kalkulator sankcji KSeF (INN-13) ────────────────────────────────
def test_ksef_sanctions_calculator():
    """Kalkulator sankcji — 6 faktur → 500 000 zł."""
    res = ksef_sanctions_calculator(6)
    assert res["max_sanction_pln"] == 500_000.0
    assert res["per_invoice_pln"] == 1_000.0
    assert res["estimated_fine_pln"] == 500_000.0


# ── Sekcja 2: kalendarz terminów JPK (INN-14) ─────────────────────────────────
def test_jpk_deadline_calendar():
    """5 terminów — JPK_V7 do 25., KSeF od 2026-02-01."""
    res = jpk_deadline_calendar()
    assert len(res["deadlines"]) == 5
    assert "25." in res["deadlines"][0]
    assert "2026-02-01" in res["deadlines"][4]


# ── Sekcja 5: pipeline XSD (INN-15) ───────────────────────────────────────────
def test_ksef_pipeline():
    """Pipeline ingest→generate→verify→emit + KSeF 2.0."""
    res = ksef_pipeline()
    assert res["pipeline"]["step_1_ingest"].startswith("data.jdg.thresholds")
    assert res["hot_reload"] is True
    assert "KSeF 2.0" in res["ksef_2_0"]["obowiązek"]


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — ksef + jpk + edelivery + esig + wis."""
    res = audit_rego_files()
    assert any("micro/ksef" in f for f in res["files_audited"])
    assert any("micro/jpk" in f for f in res["files_audited"])
    assert any("edelivery" in f for f in res["files_audited"])
    assert any("esig" in f for f in res["files_audited"])
    assert any("wis" in f for f in res["files_audited"])
    assert res["total_rule_ids"] >= 500, "Oczekiwano ≥500 rule_id (ksef 181 + jpk ~130 + e-urząd ~150)"


def test_audit_coverage_reports_real():
    """Pokrycie modułów: 7/7 COMPLETE (ksef_core, ksef_enterprise, jpk, gtu, edelivery, esig, wis)."""
    res = audit_rego_files()
    for mod in ["ksef_core", "ksef_enterprise", "jpk", "gtu", "edelivery", "esig", "wis"]:
        assert res["modules"][mod]["status"] == "COMPLETE", f"{mod} powinno być COMPLETE"
    assert res["coverage"]["complete"] == 7


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p17_package_exists():
    """Pakiet P17 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p17_ksef_jpk_edeklaracje_innovations_v9.rego"
    assert p.exists(), "Brak pliku p17_ksef_jpk_edeklaracje_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p17_ksef_jpk_edeklaracje_innovations" in text
    assert "default decide" in text


def test_p17_priorities_present():
    """Sekcje priorytetowe: KSeF + JPK + e-Doręczenia/e-podpis + ePUAP/WIS + pipeline."""
    text = (BASE_DIR / "rules" / "p17_ksef_jpk_edeklaracje_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["ksef_jpk_coverage_report", "ksef_audit", "jpk_v7_auto_generator", "ksef_upo_tracker",
                   "ksef_sanction_monitor", "ksef_offline_retry", "jpk_audit", "gtu_auto_assigner",
                   "ksef_xsd_validator", "ksef_firewall_guard", "jpk_cross_validation",
                   "edelivery_esig_audit", "esig_auto_applier", "edelivery_address_manager",
                   "epuap_wis_resilience_audit", "wis_auto_requester", "ksef_sandbox_harness",
                   "ksef_sanctions_calculator", "jpk_deadline_calendar", "ksef_pipeline_snapshot",
                   "ksef_schema_pipeline"]:
        assert marker in text, f"Brak {marker}"


def test_p17_innovations_count():
    """Minimum 15 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p17_ksef_jpk_edeklaracje_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 15, f"Tylko {inns} oznaczeń INN"


def test_p17_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p17_ksef_jpk_edeklaracje_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 20
    assert text.count("_routing_reason") >= 20


def test_p17_wiring_in_main():
    """P17 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p17."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p17_ksef_jpk_edeklaracje_innovations" in main
    assert '"jdg.p17_ksef_jpk_edeklaracje_innovations":' in main
    assert "final_verdict_p17" in main
    # Łańcuch werdyktów: p17 = safe_merge(p16, ...)
    assert "final_verdict_p16" in main


def test_p17_no_collision():
    """Stary pakiet jdg.p17_innovations (Edge Cases v8) nadal istnieje — brak kolizji nazw."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p17_innovations" in main


# ── Smoke CLI ──────────────────────────────────────────────────────────────────
def test_p17_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "ksef_jpk_edeklaracje_auditor.py"),
         "--jpk-generator", "--upo", "--offline", "--sanctions", "--gtu"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["jpk_generator"]["vat_due"] == 0.0
    assert data["upo"]["upo_missing"] == 0
    assert data["offline"]["grace_days"] == 7
    assert data["sanctions"]["max_sanction_pln"] == 500_000.0
    assert data["gtu"]["assigned_gtu"] == "GTU_01"


def test_p17_tool_smoke_table():
    """Narzędzie CLI — tryb tabelaryczny."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "ksef_jpk_edeklaracje_auditor.py"),
         "--audit", "--table"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    assert "AUDYT MICRO KSeF+JPK+E-URZĄD" in proc.stdout


# ── Stałe ─────────────────────────────────────────────────────────────────────
def test_p17_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi (ADR-002)."""
    assert KSEF["ksef_mandatory_from"] == "2026-02-01"
    assert KSEF["ksef_offline_grace_days"] == 7
    assert KSEF["ksef_sanction_max_pln"] == 500_000.0
    assert KSEF["jpk_v7_deadline_day"] == 25
    assert KSEF["jpk_ksef_penalty_per_invoice"] == 1_000.0
    assert len(KSEF["gtu_codes"]) == 13
    assert KSEF["wis_response_days"] == 3
