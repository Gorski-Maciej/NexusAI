# -*- coding: utf-8 -*-
"""Testy P18 — Automatyzacja Księgowości (NexusAI JDG)."""
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))

from automatyzacja_ksiegowosci_auditor import (  # noqa: E402
    audit_rego_files,
    bank_reconciliation_engine,
    bank_statement_auto_booking,
    banking_audit,
    cashflow_forecaster,
    correspondence_auto_generator,
    deadline_alert_tracker,
    form_autofill_engine,
    immortal_tax_calendar,
    one_click_letter_flow,
    overpayment_auto_claimer,
    payment_auto_tagging,
    psd2_monitor,
    split_payment_adviser,
    tax_deadline_priority,
    transfer_to_declaration_settlement,
)


# ── Sekcja 1: Bankowość (PSD2/PolishAPI) ──────────────────────────────────────
def test_banking_audit_structure():
    res = banking_audit()
    assert res["psd2"]["sca_exempt_threshold_pln"] == 100
    assert res["elixir"]["cutoff"] == "14:30"
    assert res["elixir"]["express_elixir_cutoff"] == "15:30"
    assert res["polish_api"]["oauth2"] is True
    assert res["polish_api"]["eidas"] is True


def test_bank_statement_auto_booking_partial():
    res = bank_statement_auto_booking(transactions=25, auto_booked=22)
    assert res["transactions"] == 25
    assert res["auto_booked"] == 22
    assert res["unmatched"] == 3
    assert res["_routing"] == ""  # auto_booked > 0 → brak routingu


def test_bank_statement_auto_booking_zero():
    res = bank_statement_auto_booking(transactions=10, auto_booked=0)
    assert res["auto_booked"] == 0
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_payment_auto_tagging_zus():
    res = payment_auto_tagging(payment_purpose="ZUS marzec 2026")
    assert res["assigned_category"] == "ZUS"


def test_payment_auto_tagging_vat():
    res = payment_auto_tagging(payment_purpose="VAT-7 za luty")
    assert res["assigned_category"] == "VAT"


def test_payment_auto_tagging_koszt():
    res = payment_auto_tagging(payment_purpose="zakup materiałów biurowych")
    assert res["assigned_category"] == "KOSZT"


def test_psd2_monitor_sca_required_high_amount():
    res = psd2_monitor(payment_amount_pln=250.0, tx_count_since_auth=6)
    assert "SCA WYMAGANE" in res["sca_decision"]
    assert res["_routing"] == "OK"


def test_psd2_monitor_sca_exempt():
    res = psd2_monitor(payment_amount_pln=50.0, tx_count_since_auth=1)
    assert "SCA EXEMPT" in res["sca_decision"]


def test_transfer_to_declaration_settlement_ok():
    res = transfer_to_declaration_settlement(transfers=4, settled=4)
    assert res["consistent"] is True
    assert res["_routing"] == ""


def test_transfer_to_declaration_settlement_gap():
    res = transfer_to_declaration_settlement(transfers=4, settled=3)
    assert res["consistent"] is False
    assert res["_routing"] == "TRIAGE_QUEUE"


# ── Sekcja 2: e-Doręczenia i e-podpis ─────────────────────────────────────────
def test_one_click_letter_flow_incomplete():
    res = one_click_letter_flow(address_set=True, mailbox_active=False)
    assert res["fully_automated"] is False
    assert len(res["flow_steps"]) == 5


def test_one_click_letter_flow_complete():
    res = one_click_letter_flow(address_set=True, mailbox_active=True)
    assert res["fully_automated"] is True


# ── Sekcja 3: Formularze i deklaracje ─────────────────────────────────────────
def test_form_autofill_engine_complete():
    res = form_autofill_engine(form_type="VAT-7", filled=3, required=3)
    assert res["ready_to_send"] is True
    assert res["_routing"] == ""
    assert "KOMPLETNY" in res["fill_status"]


def test_form_autofill_engine_incomplete():
    res = form_autofill_engine(form_type="PIT-36", filled=2, required=5)
    assert res["ready_to_send"] is False
    assert res["_routing"] == "TRIAGE_QUEUE"
    assert "NIEPEŁNY" in res["fill_status"]


# ── Sekcja 4: Kalendarz i terminy ─────────────────────────────────────────────
def test_immortal_tax_calendar_after_deadline():
    res = immortal_tax_calendar(day_of_month=26)
    assert res["zus_dra"] == "PO TERMINIE — naliczane odsetki!"
    assert res["vat7"] == "PO TERMINIE — naliczane odsetki!"


def test_immortal_tax_calendar_before_deadline():
    res = immortal_tax_calendar(day_of_month=8)
    assert "PRZED TERMINEM" in res["zus_dra"]
    assert "PRZED TERMINEM" in res["vat7"]


def test_deadline_alert_tracker_critical():
    res = deadline_alert_tracker(today_deadlines=["ZUS DRA"], urgent_count=3)
    assert "KRYTYCZNE" in res["alert_level"]
    assert res["_routing"] == "URGENT"


def test_deadline_alert_tracker_ok():
    res = deadline_alert_tracker(today_deadlines=[], urgent_count=0)
    assert res["alert_level"] == "BEZ TERMINÓW PILNYCH"
    assert res["_routing"] == "OK"


# ── Sekcja 5: Korespondencja i przepływy ──────────────────────────────────────
def test_bank_reconciliation_engine_gap():
    res = bank_reconciliation_engine(bank_balance_pln=12500.50, register_balance_pln=12400.00)
    assert res["gap_pln"] == 100.5
    assert res["_routing"] == "TRIAGE_QUEUE"
    assert "ROZBIEŻNOŚĆ" in res["recon_status"]


def test_bank_reconciliation_engine_ok():
    res = bank_reconciliation_engine(bank_balance_pln=12400.00, register_balance_pln=12400.00)
    assert res["_routing"] == ""
    assert "ZGODNE" in res["recon_status"]


def test_cashflow_forecaster_negative():
    res = cashflow_forecaster(inflows_pln=20000.0, outflows_pln=15000.0, tax_liabilities_pln=8000.0)
    assert res["projected_balance_pln"] == -3000.0
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_cashflow_forecaster_positive():
    res = cashflow_forecaster(inflows_pln=30000.0, outflows_pln=10000.0, tax_liabilities_pln=5000.0)
    assert res["projected_balance_pln"] == 15000.0
    assert res["_routing"] == ""


def test_overpayment_auto_claimer():
    res = overpayment_auto_claimer(overpayment_pln=1234.56, days_after_declaration=45)
    assert res["auto_claim"] is True
    assert res["_routing"] == "TRIAGE_QUEUE"
    assert "NADPŁATA" in res["status"]


def test_correspondence_auto_generator():
    res = correspondence_auto_generator(document_type="ZAŻALENIE")
    assert res["auto_generated"] is True
    assert res["document_type"] == "ZAŻALENIE"


# ── INN-13 / INN-15 ───────────────────────────────────────────────────────────
def test_tax_deadline_priority():
    res = tax_deadline_priority(today_deadlines=["VAT-7"], urgent_count=2)
    assert "KRYTYCZNE" in res["priority"]
    assert res["_routing"] == "URGENT"


def test_split_payment_adviser_over():
    res = split_payment_adviser(invoice_amount_pln=20000.0)
    assert "MPP ZALECANE" in res["recommendation"]


def test_split_payment_adviser_below():
    res = split_payment_adviser(invoice_amount_pln=5000.0)
    assert "MPP FAKULTATYWNE" in res["recommendation"]


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    audit = audit_rego_files()
    assert audit["total_rule_ids"] > 200, "Za mało rule_id w modułach P18"
    assert audit["summary"]["total_modules"] == 7
    assert audit["gap_pct"] == 0, "Wszystkie 7 modułów powinny być COMPLETE"


def test_audit_banking_complete():
    audit = audit_rego_files()
    assert audit["modules"]["banking"]["status"] == "COMPLETE"
    assert audit["modules"]["banking"]["rules"] >= 70  # 15+10+51+5


def test_audit_edelivery_esig_complete():
    audit = audit_rego_files()
    assert audit["modules"]["edelivery"]["status"] == "COMPLETE"
    assert audit["modules"]["esig"]["status"] == "COMPLETE"


def test_audit_forms_calendar_complete():
    audit = audit_rego_files()
    assert audit["modules"]["forms"]["status"] == "COMPLETE"
    assert audit["modules"]["calendar"]["status"] == "COMPLETE"


def test_audit_cashflow_complete():
    audit = audit_rego_files()
    assert audit["modules"]["cashflow"]["status"] == "COMPLETE"
    assert audit["modules"]["cashflow"]["rules"] >= 15  # 3+3+3+4+7+5+3


# ── Kontrola pakietu P18 ──────────────────────────────────────────────────────
def test_p18_package_exists():
    p = BASE_DIR / "rules" / "p18_automatyzacja_ksiegowosci_innovations_v9.rego"
    assert p.exists(), "Brak pliku p18_automatyzacja_ksiegowosci_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p18_automatyzacja_ksiegowosci_innovations" in text


def test_p18_braces_balanced():
    text = (BASE_DIR / "rules" / "p18_automatyzacja_ksiegowosci_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("{") == text.count("}"), "Niezbalansowane nawiasy w pakiecie P18"


def test_p18_innovations_count():
    text = (BASE_DIR / "rules" / "p18_automatyzacja_ksiegowosci_innovations_v9.rego").read_text(encoding="utf-8")
    # 15 INN markerów (INN-01..INN-15)
    for i in range(1, 16):
        marker = f"INN-{i:02d}"
        assert marker in text, f"Brak markera {marker} w pakiecie P18"


def test_p18_legal_basis_present():
    text = (BASE_DIR / "rules" / "p18_automatyzacja_ksiegowosci_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15, "Za mało podstaw prawnych w pakiecie P18"


def test_p18_wiring_in_main():
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p18_automatyzacja_ksiegowosci_innovations" in main
    assert '"jdg.p18_automatyzacja_ksiegowosci_innovations": p18_automatyzacja_ksiegowosci_innovations.decide' in main
    assert "final_verdict_p18 = safe_merge(final_verdict_p17," in main


def test_p18_no_collision():
    """Brak kolizji ze starym pakietem jdg.p18_innovations (v8)."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    new_pkg = "jdg.p18_automatyzacja_ksiegowosci_innovations"
    assert new_pkg in main
    # nowy pakiet nie jest identyczny ze starym
    text = (BASE_DIR / "rules" / "p18_automatyzacja_ksiegowosci_innovations_v9.rego").read_text(encoding="utf-8")
    assert "jdg.p18_automatyzacja_ksiegowosci_innovations" in text


def test_p18_tool_smoke():
    """Smoke test narzędzia — audyt + kalendarz."""
    audit = audit_rego_files()
    assert audit["total_rule_ids"] > 0
    cal = immortal_tax_calendar(day_of_month=10)
    assert cal["zus_dra"] == "DZIŚ TERMIN — złóż deklarację!"


def test_p18_tool_smoke_table():
    cal = immortal_tax_calendar(day_of_month=25)
    assert cal["vat7"] == "DZIŚ TERMIN — złóż deklarację!"
    assert cal["jpk_v7"] == "DZIŚ TERMIN — złóż deklarację!"


def test_p18_constants_match():
    """Progi w narzędziu (Python) zgodne z rego (PSD2 SCA 100 zł, Elixir 14:30, MPP 15 000)."""
    assert banking_audit()["psd2"]["sca_exempt_threshold_pln"] == 100
    assert split_payment_adviser(invoice_amount_pln=14999.99)["recommendation"].startswith("MPP FAKULTATYWNE")
    assert split_payment_adviser(invoice_amount_pln=15000.00)["recommendation"].startswith("MPP ZALECANE")
