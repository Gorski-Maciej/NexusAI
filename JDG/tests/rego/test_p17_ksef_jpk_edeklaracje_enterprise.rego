# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P17 KSeF + JPK + e-Deklaracje Enterprise — testy rego
# (RAPORT P17 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p17_ksef_jpk_edeklaracje

import future.keywords.in

# ── 1. Mapa pokrycia modułów KSeF + JPK + e-urząd ─────────────────────────────
test_p17_coverage_report {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_jpk_coverage_report with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}} with
        data.jdg.p17_audit as {"modules": {
            "ksef_core": {"status": "COMPLETE"}, "ksef_enterprise": {"status": "COMPLETE"},
            "jpk": {"status": "COMPLETE"}, "gtu": {"status": "COMPLETE"},
            "edelivery": {"status": "COMPLETE"}, "esig": {"status": "COMPLETE"},
            "wis": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 7
    result.summary.complete == 7
    result.summary.missing == 0
}

# ── 2. AUDYT KSeF (PRIORYTET — Sekcja 1) ──────────────────────────────────────
test_ksef_audit {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_audit with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true, "eval_date": "2026-08-01"}}
    "OBOWIĄZKOWY" in result.obowiazek.status
    result.obowiazek.od == "2026-02-01"
    result.offline.grace_days == 7
    result.sankcje.max_pln == 500000
    count(result.schemat.required_fields) == 8
}

# ── 3. Auto-generator JPK_V7 (INN-01 — Sekcja 2 PRIORYTET) ────────────────────
test_jpk_v7_auto_generator {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_v7_auto_generator with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "jpk": {"type": "JPK_V7M", "sales_register": 10000, "purchase_register": 6000,
                          "vat_sales": 1000, "vat_purchase": 700}}
    result.type == "JPK_V7M"
    result.vat_due == 300.0
    result.generated == true
    "25." in result.deadline
}

# ── 4. Tracker UPO (INN-02) ───────────────────────────────────────────────────
test_ksef_upo_tracker_missing {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_upo_tracker with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"invoice_count": 10, "upo_received_count": 8}}
    result.upo_missing == 2
    "BRAK UPO" in result.status
    result._routing == "TRIAGE_QUEUE"
}

test_ksef_upo_tracker_ok {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_upo_tracker with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"invoice_count": 10, "upo_received_count": 10}}
    result.upo_missing == 0
    result._routing == ""
}

# ── 5. Monitor sankcji KSeF (INN-03) ──────────────────────────────────────────
test_ksef_sanction_monitor_max {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sanction_monitor with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"invoices_outside_ksef": 6}}
    result.estimated_fine_pln == 500000
    result.sanction_level == "KRYTYCZNE — sankcja maksymalna!"
    result.max_sanction_pln == 500000
    result._routing == "BLOCK_AND_ALERT"
}

test_ksef_sanction_monitor_small {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sanction_monitor with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"invoices_outside_ksef": 2}}
    result.estimated_fine_pln == 2000.0
    result.sanction_level == "UMIARKOWANE"
}

# ── 6. System retry offline (INN-04) ──────────────────────────────────────────
test_ksef_offline_retry_within {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_offline_retry with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"offline_days": 3, "offline_invoices": 5}}
    result.grace_days == 7
    result.in_queue == 5
    "OK" in result.status
    result.auto_retry == true
    result._routing == ""
}

test_ksef_offline_retry_exceeded {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_offline_retry with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"offline_days": 10}}
    "PRZEKROCZONO" in result.status
    result._routing == "TRIAGE_QUEUE"
}

# ── 7. AUDYT JPK (PRIORYTET ★ — Sekcja 2) ─────────────────────────────────────
test_jpk_audit {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_audit with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    "25." in result.jpk_v7.obowiązek
    count(result.gtu.codes) == 13
    "GTU_01" in result.gtu.codes
    result.jpk_cit.obowiązek != ""
    count(result.integrated_packages) == 4
}

# ── 8. GTU auto-przypisanie (INN-05) ──────────────────────────────────────────
test_gtu_auto_assigner {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.gtu_auto_assigner with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "invoice": {"gtu_hint": "paliwa"}}
    result.assigned_gtu == "GTU_04"
    result.gtu_valid == true
}

test_gtu_auto_assigner_fallback {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.gtu_auto_assigner with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "invoice": {"gtu_hint": "inne towary"}}
    result.assigned_gtu == "GTU_01"
}

# ── 9. Walidator XSD (INN-06) ─────────────────────────────────────────────────
test_ksef_xsd_validator_ok {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_xsd_validator with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"schema_version": "FA(2)"}}
    result.xsd_valid == true
    count(result.invalid_fields) == 0
}

test_ksef_xsd_validator_missing {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_xsd_validator with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"schema_version": "FA(2)", "fields": {"P_1": true, "P_2": true}}}
    result.xsd_valid == false
    count(result.invalid_fields) == 6
}

# ── 10. Firewall KSeF (INN-07) ────────────────────────────────────────────────
test_ksef_firewall_guard_blocked {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_firewall_guard with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"anomaly_NIP invalid": true}}
    result.blocked == true
    count(result.anomalies) == 1
    result._routing == "BLOCK_AND_ALERT"
}

test_ksef_firewall_guard_clean {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_firewall_guard with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    result.blocked == false
    result._routing == ""
}

# ── 11. Walidacja krzyżowa JPK (INN-08) ───────────────────────────────────────
test_jpk_cross_validation_consistent {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_cross_validation with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "jpk": {"sales_register": 10000, "vat_7_sales": 10000,
                          "purchase_register": 6000, "vat_7_purchase": 6000}}
    result.consistent == true
    result._routing == ""
}

test_jpk_cross_validation_mismatch {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_cross_validation with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "jpk": {"sales_register": 10000, "vat_7_sales": 9999,
                          "purchase_register": 6000, "vat_7_purchase": 6000}}
    result.consistent == false
    result._routing == "TRIAGE_QUEUE"
}

# ── 12. AUDYT e-DORĘCZEŃ I e-PODPISU (Sekcja 3) ───────────────────────────────
test_edelivery_esig_audit {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.edelivery_esig_audit with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    "PODPIS KWALIFIKOWANY" in result.e_podpis.status
    result.e_podpis.kwalifikowany == true
    result.e_podpis.zaufany == true
    count(result.integrated_packages) == 4
}

# ── 13. Auto-aplikacja e-podpisu (INN-09) ─────────────────────────────────────
test_esig_auto_applier {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.esig_auto_applier with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true, "esig_type": "QUALIFIED", "esig_documents": 12}}
    result.signature_type == "QUALIFIED"
    result.documents_signed == 12
    result.auto_applied == true
}

# ── 14. Menedżer adresu do doręczeń (INN-10) ──────────────────────────────────
test_edelivery_address_manager_set {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.edelivery_address_manager with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true, "edelivery_address_set": true, "edelivery_mailbox_active": true}}
    "ADRES USTAWIONY" in result.status
    result._routing == ""
}

test_edelivery_address_manager_missing {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.edelivery_address_manager with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    "BRAK ADRESU" in result.status
    result._routing == "TRIAGE_QUEUE"
}

# ── 15. AUDYT ePUAP, WIS, ODPORNOŚCI (Sekcja 4) ───────────────────────────────
test_epuap_wis_resilience_audit {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.epuap_wis_resilience_audit with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    result.wis.response_days == 3
    result.sandbox.dostepny == true
    result.odporność.grace_days == 7
    count(result.integrated_packages) == 5
}

# ── 16. WIS auto-zapytania (INN-11) ───────────────────────────────────────────
test_wis_auto_requester {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.wis_auto_requester with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "wis": {"wis_requested": true, "wis_status": "PENDING"}}
    result.wis_requested == true
    result.wis_status == "PENDING"
    result.response_days == 3
}

# ── 17. Sandbox KSeF (INN-12) ─────────────────────────────────────────────────
test_ksef_sandbox_harness {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sandbox_harness with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"sandbox_test_invoices": 20}}
    result.sandbox_active == true
    result.test_invoices == 20
}

# ── 18. Kalkulator sankcji KSeF (INN-13) ──────────────────────────────────────
test_ksef_sanctions_calculator {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sanctions_calculator with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"invoices_outside_ksef": 6}}
    result.max_sanction_pln == 500000
    result.per_invoice_pln == 1000
    result.estimated_fine_pln == 500000
    result._routing == "BLOCK_AND_ALERT"
}

# ── 19. Kalendarz terminów JPK (INN-14) ───────────────────────────────────────
test_jpk_deadline_calendar {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_deadline_calendar with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    count(result.deadlines) == 5
    "25." in result.deadlines[0]
    "2026-02-01" in result.deadlines[4]
}

# ── 20. PIPELINE KSeF/XSD (Sekcja 5 + INN-15) ─────────────────────────────────
test_ksef_pipeline_snapshot {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.ksef_jpk_edeklaracje (ADR-002) — progi, terminy, schematy"
    result.hot_reload == true
    result.ksef_2_0.obowiązek != ""
}

test_ksef_schema_pipeline {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_schema_pipeline with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true},
                  "ksef": {"schema_version": "FA(2)"}}
    result.current_schema == "FA(2)"
    count(result.xsd_registry) == 3
    result.hot_reload == true
}

# ── 21. Główny decide (P17) + no_match ────────────────────────────────────────
test_p17_main_decide {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.decide with
        input as {"jdg_entrepreneur": {"p17_ksef_check": true}}
    result.matched == true
    result.rule_id == "jdg.p17_ksef_jpk_edeklaracje_innovations.report"
    result._routing == "REPORT"
    result.ksef.obowiazek.od == "2026-02-01"
    result.jpk.jpk_v7.obowiązek != ""
    result.edelivery_esig.e_podpis.status != ""
    result.pipeline.hot_reload == true
}

test_p17_default_no_match {
    result := data.jdg.p17_ksef_jpk_edeklaracje_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p17_ksef_jpk_edeklaracje_innovations.no_match"
}
