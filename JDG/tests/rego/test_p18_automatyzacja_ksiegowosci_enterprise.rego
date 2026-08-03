# NexusAI JDG — testy rego P18 (Automatyzacja Księgowości)
# Package: jdg.tests.p18_automatyzacja_ksiegowosci
package jdg.tests.p18_automatyzacja_ksiegowosci

import future.keywords.in

test_p18_coverage_report {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.automatyzacja_coverage_report with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.automatyzacja_coverage_report"
    result.matched == true
    count(result.modules) == 7
}

test_banking_audit {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.banking_audit with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.banking_audit"
    result.psd2.sca_exempt_threshold_pln == 100
    result.elixir.cutoff == "14:30"
}

test_bank_statement_auto_booking {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.bank_statement_auto_booking with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"statement_transactions": 10, "auto_booked_count": 8}}
    result.matched == true
    result.transactions == 10
    result.auto_booked == 8
    result.unmatched == 2
}

test_payment_auto_tagging {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.payment_auto_tagging with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"payment_purpose": "ZUS marzec 2026"}}
    result.assigned_category == "ZUS"
}

test_psd2_monitor {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.psd2_monitor with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"payment_amount_pln": 250, "tx_count_since_auth": 6}}
    result.matched == true
    result.sca_decision == "SCA WYMAGANE — kwota > 100 zł (RTS 2018/389)"
    result._routing == "OK"
}

test_transfer_to_declaration_settlement_ok {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.transfer_to_declaration_settlement with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"tax_transfers": 4, "settled_transfers": 4}}
    result.consistent == true
    result._routing == ""
}

test_transfer_to_declaration_settlement_gap {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.transfer_to_declaration_settlement with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"tax_transfers": 4, "settled_transfers": 3}}
    result.consistent == false
    result._routing == "TRIAGE_QUEUE"
}

test_edelivery_esig_audit {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.edelivery_esig_audit with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.edelivery_esig_audit"
    result.jedno_klikniecie.urzady[0] == "US (VAT-7, PIT, PCC-3)"
}

test_one_click_letter_flow_incomplete {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.one_click_letter_flow with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true, "edelivery_address_set": true, "edelivery_mailbox_active": false}}
    result.fully_automated == false
    count(result.flow_steps) == 5
}

test_forms_declarations_audit {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.forms_declarations_audit with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.formularze["PIT-36"] == "auto-generacja z rejestrów PKPiR/UoR (do 30 kwietnia)"
}

test_form_autofill_engine_complete {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.form_autofill_engine with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "forms": {"form_type": "VAT-7", "required_fields": ["P_1", "P_2", "P_3"], "filled_fields": ["P_1", "P_2", "P_3"]}}
    result.ready_to_send == true
    result._routing == ""
}

test_form_autofill_engine_incomplete {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.form_autofill_engine with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "forms": {"form_type": "PIT-36", "required_fields": ["P_1", "P_2", "P_3", "P_4", "P_5"], "filled_fields": ["P_1", "P_2"]}}
    result.ready_to_send == false
    result._routing == "TRIAGE_QUEUE"
}

test_calendar_deadlines_audit {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.calendar_deadlines_audit with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.terminy["ZUS DRA"] == "do 10. dnia miesiąca (art. 47 u.ZUS)"
    result.terminy["VAT-7"] == "do 25. dnia miesiąca (art. 99 VAT)"
}

test_immortal_tax_calendar_after_deadline {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.immortal_tax_calendar with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "calendar": {"day_of_month": 26}}
    result.vat7 == "PO TERMINIE — naliczane odsetki!"
    result.zus_dra == "PO TERMINIE — naliczane odsetki!"
}

test_deadline_alert_tracker_critical {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.deadline_alert_tracker with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "calendar": {"today_deadlines": ["ZUS DRA"], "urgent_count": 3}}
    result.alert_level == "KRYTYCZNE — 1 terminów DZIŚ"
    result._routing == "URGENT"
}

test_correspondence_cashflow_audit {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.correspondence_cashflow_audit with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.correspondence_cashflow_audit"
    count(result.integrated_packages) == 6
}

test_bank_reconciliation_engine_gap {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.bank_reconciliation_engine with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"bank_balance_pln": 12500.50, "register_balance_pln": 12400.00}}
    result.gap_pln == 100.5
    result._routing == "TRIAGE_QUEUE"
}

test_cashflow_forecaster_negative {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.cashflow_forecaster with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "cashflow": {"inflows_pln": 20000, "outflows_pln": 15000, "tax_liabilities_pln": 8000}}
    result.projected_balance_pln == -3000
    result._routing == "TRIAGE_QUEUE"
}

test_overpayment_auto_claimer {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.overpayment_auto_claimer with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "overpayment": {"overpayment_pln": 1234.56, "days_after_declaration": 45}}
    result.auto_claim == true
    result._routing == "TRIAGE_QUEUE"
}

test_correspondence_auto_generator {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.correspondence_auto_generator with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "correspondence": {"document_type": "ZAŻALENIE"}}
    result.auto_generated == true
    result.document_type == "ZAŻALENIE"
}

test_api_adaptation_pipeline {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.api_adaptation_pipeline with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "api": {"api_version": "PolishAPI 3.0", "supported_versions": ["PolishAPI 1.0", "PolishAPI 2.0"]}}
    result.hot_reload == true
    result.api_adaptation.status == "WYMAGA ADAPTACJI — API PolishAPI 3.0 poza wsparciem"
}

test_tax_deadline_priority {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.tax_deadline_priority with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "calendar": {"today_deadlines": ["VAT-7"], "urgent_count": 2}}
    result.priority == "KRYTYCZNE — 1 terminów DZIŚ"
    result._routing == "URGENT"
}

test_virtual_bookkeeper_assistant {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.virtual_bookkeeper_assistant with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.assistant.terminy == "nieśmiertelny kalendarz (INN-07) + priorytetyzacja (INN-13)"
    result.assistant.deklaracje == "auto-fill formularzy (INN-06) + rozliczanie przelewów (INN-04)"
}

test_split_payment_adviser_over {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.split_payment_adviser with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"invoice_amount_pln": 20000}}
    result.recommendation == "MPP ZALECANE — mechanizm podzielonej płatności (≥15 000 zł)"
}

test_split_payment_adviser_below {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.split_payment_adviser with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}, "banking": {"invoice_amount_pln": 5000}}
    result.recommendation == "MPP FAKULTATYWNE — poniżej progu 15 000 zł"
}

test_p18_main_decide {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.decide with input as {"jdg_entrepreneur": {"p18_automatyzacja_check": true}}
    result.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.report"
    result.banking.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.banking_audit"
    result.calendar.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.calendar_deadlines_audit"
}

test_p18_default_no_match {
    result := data.jdg.p18_automatyzacja_ksiegowosci_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.rule_id == "jdg.p18_automatyzacja_ksiegowosci_innovations.no_match"
}
