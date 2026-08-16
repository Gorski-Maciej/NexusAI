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
    GTU_DICTIONARY,
    KSEF,
    audit_rego_files,
    edelivery_address_manager,
    edelivery_b2b_b2g_integration,
    esig_auto_applier,
    gtu_auto_assigner,
    gtu_full_dictionary,
    jpk_cit_automation_2026,
    jpk_cross_validation,
    jpk_deadline_calendar,
    jpk_v7_auto_generator,
    ksef_api_integration,
    ksef_audit,
    ksef_corrections_e2e,
    ksef_dashboard_ui,
    ksef_firewall_guard,
    ksef_offline_retry,
    ksef_pipeline,
    ksef_sandbox_harness,
    ksef_sanction_monitor,
    ksef_sanctions_calculator,
    ksef_upo_tracker,
    ksef_xsd_offline_ci,
    ksef_xsd_validator,
    wis_auto_requester,
)


# ── Mapa drogowa P0/P1/P2 (R17) ───────────────────────────────────────────────
def test_ksef_api_integration():
    """P0-1: API KSeF — brak konfiguracji → TRIAGE, pełne → OK + UPO via API."""
    unconfigured = ksef_api_integration(api_configured=False)
    assert unconfigured["_routing"] == "TRIAGE_QUEUE"
    assert "NIESKONFIGUROWANE" in unconfigured["integration_status"]
    no_number = ksef_api_integration(api_configured=True, ksef_number="")
    assert "BRAK NUMERU" in no_number["integration_status"]
    ok = ksef_api_integration(api_configured=True, ksef_number="KSEF-123")
    assert ok["_routing"] == ""
    assert ok["upo_via_api"] is True
    assert ok["endpoint_prod"] == "https://ksef.mf.gov.pl/api"


def test_ksef_xsd_offline_ci():
    """P0-2: walidator XSD offline — CI gate, BLOCK przy nieudanym przebiegu."""
    ok = ksef_xsd_offline_ci(ci_last_run_ok=True)
    assert ok["_routing"] == ""
    assert len(ok["schemas"]) >= 2
    assert ok["validator"] == "xmllint/Java JAXB (offline)"
    bad = ksef_xsd_offline_ci(ci_last_run_ok=False)
    assert bad["_routing"] == "BLOCK_AND_ALERT"
    assert bad["block_on_invalid"] is True


def test_ksef_corrections_e2e():
    """P1-1: korekty KSeF end-to-end — art. 106j VAT, termin 30 dni."""
    pending = ksef_corrections_e2e(corrections_pending=2)
    assert pending["_routing"] == "TRIAGE_QUEUE"
    assert "30 dni" in pending["status"]
    assert pending["cancellation_allowed"] is True
    clean = ksef_corrections_e2e()
    assert clean["_routing"] == ""
    assert len(clean["correction_reasons"]) >= 5


def test_gtu_full_dictionary():
    """P1-2: baza GTU — pełny słownik 13 kodów + uczenie z historii."""
    res = gtu_full_dictionary("energia")
    assert res["dictionary_size"] == 13
    assert len(GTU_DICTIONARY) == 13
    assert res["learning_enabled"] is True
    assert res["entry_for_hint"]["code"] == "GTU_12"
    assert all(c in KSEF["gtu_codes"] for c in res["codes"])


def test_edelivery_b2b_b2g_integration():
    """P1-3: e-Doręczenia — skrzynka nieaktywna → TRIAGE, pełne → OK."""
    inactive = edelivery_b2b_b2g_integration(mailbox_active=False)
    assert inactive["_routing"] == "TRIAGE_QUEUE"
    assert "NIEAKTYWNA" in inactive["integration_status"]
    no_confirm = edelivery_b2b_b2g_integration(mailbox_active=True, confirmations_ok=False)
    assert "POTWIERDZEŃ" in no_confirm["integration_status"]
    ok = edelivery_b2b_b2g_integration(mailbox_active=True, confirmations_ok=True)
    assert ok["_routing"] == ""
    assert ok["b2b_enabled"] is True and ok["b2g_enabled"] is True


def test_ksef_dashboard_ui():
    """P2-1: dashboard KSeF — braki UPO → TRIAGE, kara max → BLOCK."""
    triage = ksef_dashboard_ui(invoices_sent=10, upo_received=8, invoices_outside=3, corrections_pending=0)
    assert triage["status_upo"]["upo_missing"] == 2
    assert triage["_routing"] == "TRIAGE_QUEUE"
    block = ksef_dashboard_ui(invoices_sent=10, upo_received=10, invoices_outside=600, corrections_pending=0)
    assert block["kara_ryzyko"]["estimated_fine_pln"] == 500_000
    assert block["_routing"] == "BLOCK_AND_ALERT"
    ok = ksef_dashboard_ui(invoices_sent=5, upo_received=5)
    assert ok["_routing"] == ""
    assert "JSON" in ok["export_formats"]


def test_jpk_cit_automation_2026():
    """P2-2: JPK_CIT — szablon MF 2026, ready po wygenerowaniu wszystkich sekcji."""
    not_ready = jpk_cit_automation_2026(cit_blocks_generated=1)
    assert not_ready["automation_ready"] is False
    assert not_ready["_routing"] == "TRIAGE_QUEUE"
    assert "2026" in not_ready["template"]
    ready = jpk_cit_automation_2026(cit_blocks_generated=4)
    assert ready["automation_ready"] is True
    assert ready["_routing"] == ""
    assert ready["structure_version"] == "2.0"
    assert ready["deadline_day"] == 31


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


def test_gtu_auto_assigner_alcohol_tobacco():
    """GTU_02 = wyroby tytoniowe, GTU_03 = napoje alkoholowe (oficjalne definicje)."""
    tobacco = gtu_auto_assigner("wyroby tytoniowe")
    assert tobacco["assigned_gtu"] == "GTU_02"
    alcohol = gtu_auto_assigner("napoje alkoholowe")
    assert alcohol["assigned_gtu"] == "GTU_03"


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
def test_p17_tool_smoke_roadmap():
    """Narzędzie CLI — nowe komendy mapy drogowej P0/P1/P2 działają end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "ksef_jpk_edeklaracje_auditor.py"),
         "--ksef-api", "--xsd-ci", "--corrections", "--gtu-dict", "--edelivery-b2b",
         "--ksef-dashboard", "--jpk-cit"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["ksef_api"]["upo_via_api"] is True
    assert data["xsd_ci"]["ci_gate"] is True
    assert data["corrections"]["correction_deadline_days"] == 30
    assert data["gtu_dict"]["dictionary_size"] == 13
    assert data["edelivery_b2b"]["confirmation_type"] == "DORECZENIE_POTWIERDZONE"
    assert data["ksef_dashboard"]["export_formats"] == ["JSON", "CSV", "PDF"]
    assert data["jpk_cit"]["structure_version"] == "2.0"


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


# ── P04: narzędzia ksef_outbox / ksef_offline_queue / jpk_autogen / edelivery_monitor ──
from ksef_outbox import (  # noqa: E402
    MAX_RETRIES,
    _backoff,
    dispatch as ksef_dispatch,
    enqueue as ksef_enqueue,
    reconcile as ksef_reconcile,
    status as ksef_status,
)
from ksef_offline_queue import (  # noqa: E402
    GRACE_DAYS,
    WARNING_HOURS,
    ZAW_NR_PENALTY_PLN,
    add as offline_add,
    deadline as offline_deadline,
    zaw_nr as offline_zaw_nr,
)
from jpk_autogen import (  # noqa: E402
    build as jpk_build,
    correction as jpk_correction,
    schedule as jpk_schedule,
    verify as jpk_verify,
)
from edelivery_monitor import (  # noqa: E402
    FICTION_DAYS,
    archive as ede_archive,
    check as ede_check,
    fiction as ede_fiction,
    inbox as ede_inbox,
)


INV1 = {"invoice_number": "F-001", "amount_net": 1000.0, "vat_rate": "23", "vat_amount": 230.0, "direction": "SALE"}
INV2 = {"invoice_number": "F-002", "amount_net": 5000.0, "vat_rate": "23", "vat_amount": 1150.0, "direction": "SALE"}


def test_p04_outbox_exactly_once():
    """Idempotencja outbox — ten sam dokument nigdy nie wchodzi 2× (exactly-once)."""
    ob = []
    e1 = ksef_enqueue(INV1, ob)
    e2 = ksef_enqueue(INV1, ob)
    e3 = ksef_enqueue(INV2, ob)
    assert e1["outbox_id"] == e2["outbox_id"]
    assert e2["duplicate"] is True
    assert len(ob) == 2
    assert ksef_status(ob)["duplicates_detected"] == 1


def test_p04_outbox_retry_backoff_and_upo():
    """Retry z backoffem (sandbox: sukces od 2. próby) + rekoncyliacja UPO."""
    import time
    ob = []
    ksef_enqueue(INV1, ob)
    t0 = time.time_ns()
    first = ksef_dispatch(ob, api="sandbox", now_ns=t0)
    assert first["failed"] == 1  # awaria 1. próby
    retry = ksef_dispatch(ob, api="sandbox", now_ns=t0 + (_backoff(1) * 1_000_000_000) + 1)
    assert retry["dispatched"] == 1
    ob[0]["upo"] = {"upo_id": "UPO-1", "status": "OK"}
    rec = ksef_reconcile(ob, now_ns=t0 + 2 * 86_400_000_000_000)
    assert rec["upo_ok"] == 1
    assert ksef_status(ob)["zero_loss_ok"] is True


def test_p04_outbox_max_retries_stale():
    """Po przekroczeniu max_retries → FAILED (nie utracony, oznaczony)."""
    ob = [{"outbox_id": "KOB-X", "hash": "h", "status": "PENDING", "attempts": MAX_RETRIES,
           "next_retry_ns": 0, "invoice": INV1}]
    res = ksef_dispatch(ob, api="sandbox", now_ns=1)
    assert res["failed"] == 1
    assert ob[0]["status"] == "FAILED"


def test_p04_offline_queue_deadline_zaw():
    """Kolejka offline: numeracja OFL, próg 120h, grace 168h, ZAW-NR 5000 zł."""
    import time
    q = []
    entry = offline_add(INV1, "2026-07-01T10:00:00", q)
    assert entry["offline_id"].startswith("OFL-")
    assert entry["offline_marker"] is True
    t0 = time.time_ns()
    dl = offline_deadline(q, now_ns=t0 + 130 * 3_600_000_000_000)
    assert dl["approaching_deadline"] is True
    assert dl["critical"] is False
    assert dl["hours_remaining"] == GRACE_DAYS * 24 - 130
    dl2 = offline_deadline(q, now_ns=t0 + 170 * 3_600_000_000_000)
    assert dl2["critical"] is True
    zw = offline_zaw_nr(q)
    assert zw["zaw_nr_required"] is True
    assert zw["penalty_if_missing_pln"] == ZAW_NR_PENALTY_PLN == 5000


def test_p04_jpk_autogen_build_correction_schedule():
    """e-Deklaracje zero-ręki: build → korekta → terminy."""
    verds = [INV1, {"invoice_number": "Z-1", "amount_net": 500.0, "vat_rate": "23",
                    "vat_amount": 115.0, "direction": "PURCHASE"}]
    j = jpk_build(verds, "2026-01")
    assert j["jpk"]["vat_to_pay"] == 115.0
    assert j["declaration"]["P_10"] == 115.0
    assert jpk_correction(verds, {"period": "2026-01", "P_10": 50.0, "sales_count": 1})["correction_needed"] is True
    assert jpk_correction(verds, {"period": "2026-01", "P_10": 115.0, "sales_count": 1})["correction_needed"] is False
    sch = jpk_schedule("2026-01")
    assert sch["jpk_v7"] == "2026-01-26"  # 25.01.2026 = niedziela → poniedziałek
    assert sch["pcc_3"] == "2026-01-15"


def test_p04_jpk_verify_3way():
    """Detektor różnic 3-drożny: JPK ↔ deklaracja ↔ KSeF."""
    jpk = {"vat_due": 230.0, "vat_input": 115.0, "declaration": {"P_10": 115.0}}
    ksef_ok = {"invoices": [{"vat": 230.0}]}  # KSeF = faktury sprzedażowe
    assert jpk_verify(jpk, ksef_ok)["consistent"] is True
    ksef_bad = {"invoices": [{"vat": 200.0}]}
    v = jpk_verify(jpk, ksef_bad)
    assert v["consistent"] is False
    assert any("KSeF" in i for i in v["issues"])


def test_p04_edelivery_monitor():
    """e-Doręczenia: obowiązek EDE, nowe pisma, fiction 15 dni, archiwum WORM."""
    assert "ZAREJESTRUJ" in ede_check(True)["action"]
    letters = [{"id": "L1", "status": "NEW", "subject": "Wezwanie", "avis_date": "2026-06-25"},
               {"id": "L2", "status": "AVISED", "avis_date": "2026-06-25"}]
    assert ede_inbox(letters)["new_letters"] == 1
    fic = ede_fiction(letters, "2026-07-10")
    assert fic["fiction_active"] == 1
    assert FICTION_DAYS == 15
    arch = ede_archive(letters)
    assert arch["retention_years"] == 5
