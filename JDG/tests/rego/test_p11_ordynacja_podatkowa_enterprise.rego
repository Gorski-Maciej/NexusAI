# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 Ordynacja Podatkowa Enterprise — testy rego
# (RAPORT P11 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p11_ordynacja

import future.keywords.in

# ── 1. Mapa pokrycia artykułów OrdPU ──────────────────────────────────────────
test_ordpu_coverage_report {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.ordpu_coverage_report with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}} with
        data.jdg.ordpu_audit as {"articles": {
            "a70": {"status": "COMPLETE"}, "a81": {"status": "COMPLETE"},
            "a81b": {"status": "COMPLETE"}, "a119a": {"status": "COMPLETE"},
            "a138a": {"status": "COMPLETE"}, "a193a": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 20
    result.summary.complete == 6
}

# ── 2. AUDYT PRZEDAWNIEŃ (PRIORYTET — art. 70) ────────────────────────────────
test_limitation_engine {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.limitation_engine with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "tax_year": 2026}}
    result.limitation_years == 5
    result.deadline_year == 2031
    result.deadline == "31.12.2031"
    result.interruption.acts == "decyzja ustalająca/określająca, czynność egzekucyjna (art. 70 §4)"
    result.suspension.cases == "postępowanie karne (podejrzenie przestępstwa), zawieszenie postępowania (art. 70 §6)"
}

# ── 3. Kalendarz przedawnień z alertami (INN-01) ──────────────────────────────
test_limitation_calendar {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.limitation_calendar with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "current_year": 2026}, "liabilities": [
            {"tax_type": "VAT", "tax_year": 2021},
            {"tax_type": "PIT", "tax_year": 2024},
        ]}
    count(result.alerts) == 2
    result.alerts[0].deadline == "31.12.2026"
    count(result.urgent) == 1
}

# ── 4. Kalkulator odsetek (INN-02 — art. 56, 200% lombardu) ──────────────────
test_interest_calculator {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.interest_calculator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}, "liability": {"arrears": 10000, "days_overdue": 60}}
    result.annual_rate_pct == 200
    result.interest_due == round(10000 * (200.0 / 365) / 100 * 60 * 100) / 100
}

# ── 5. Silnik auto-korekty deklaracji (INN-03 — art. 81/81b) ─────────────────
test_auto_correction_engine {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.auto_correction_engine with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "current_year": 2026}, "correction": {"original_tax": 10000, "corrected_tax": 12000, "tax_year": 2023, "days_overdue": 60}}
    result.difference == 2000.0
    result.direction == "dopłata (zaległość)"
    result.within_5y == true
    result.interest_on_arrears == round(2000 * (200.0 / 365) / 100 * 60 * 100) / 100
}

# ── 6. Auto-korespondencja z urzędem (Sekcja 4) ───────────────────────────────
test_correspondence_audit {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.correspondence_audit with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}}
    count(result.integrated_packages) == 6
    count(result.proceeding_flow) == 5
    result.appeal_days == 14
    result.interpretation_days == 30
}

test_proceeding_tracker {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.proceeding_tracker with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}, "proceeding": {"stage": "wniosek"}}
    result.deadline_days == 30
    result.next_action == "monitoruj termin wydania interpretacji (30 dni)"
}

# ── 7. GAAR (art. 119a) ───────────────────────────────────────────────────────
test_gaar_audit {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.gaar_audit with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "artificiality_score": 70}}
    result.gaar_risk == "WYSOKIE"
    result.art119a.artificiality_threshold == 60
}

# ── 8. Biała Lista (art. 117ba — 30 dni, sankcja 20%) ─────────────────────────
test_white_list_monitor {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.white_list_monitor with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}, "payment": {"amount": 50000, "vendor_white_listed": true, "paid_to_listed_account": false, "notified_within_30d": false}}
    result.sanction_pct == 20
    result.sanction == 10000.0
}

# ── 9. Silnik ryzyka kontroli skarbowej (INN-07) ──────────────────────────────
test_inspection_risk_engine {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.inspection_risk_engine with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "declared_vs_reported_variance": 0.30}}
    result.risk_score == 30
    result.risk_level == "ŚREDNIE"
}

# ── 10. Generator wniosków o ulgi w spłacie (INN-08) ──────────────────────────
test_relief_application_generator {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.relief_application_generator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}}
    result.relief_types.art67a == "odroczenie terminu płatności / rozłożenie na raty"
    result.relief_types.art67c == "umorzenie zaległości podatkowej (ważny interes podatnika)"
}

# ── 11. Kalkulator korzyści GAAR (INN-13) ─────────────────────────────────────
test_gaar_benefit_calculator {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.gaar_benefit_calculator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}, "scheme": {"tax_benefit": 10000, "artificiality": 70}}
    result.risk == "GAAR_APPLIES"
}

# ── 12. Asystent czynnego żalu (INN-12) ───────────────────────────────────────
test_czynny_zal_assistant {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.czynny_zal_assistant with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "disclosure_before_detection": true, "control_started": false}}
    result.worth_filing == true
    result.effect == "brak odpowiedzialności karnej skarbowej (art. 16 §1)"
}

# ── 13. Pipeline auto-aktualizacji (Sekcja 6) ─────────────────────────────────
test_ordpu_pipeline_snapshot {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.ordpu_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.ordpu (ADR-002) — terminy, stawki"
    result.pipeline.step_4_emit == "hot-reload pakietów jdg.limitations / jdg.interest_calculator"
}

# ── 15. TRACKER MILCZĄCEGO ZAŁATWIENIA (INN-16) ──────────────────────────────
test_silent_settlement_tracker_positive {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.silent_settlement_tracker with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "proceeding_started": true, "proceeding_months_elapsed": 3, "proceeding_decision_issued": false}}
    result.silent_positive_settlement == true
    result._routing == "TRIAGE_QUEUE"
}

test_silent_settlement_tracker_no {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.silent_settlement_tracker with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "proceeding_started": false, "proceeding_months_elapsed": 1}}
    result.silent_positive_settlement == false
}

# ── 16. KALKULATOR OPŁACALNOŚCI KOREKTY (INN-17) ──────────────────────────────
test_correction_profitability_profitable {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.correction_profitability_calculator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "tax_difference": 10000, "inspection_risk_pct": 40}}
    result.correction_cost == round(10000 * 0.15 * 100) / 100
    result.correction_profitable == true
    result.recommendation == "ZŁÓŻ_KOREKTĘ"
}

test_correction_profitability_not_profitable {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.correction_profitability_calculator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "tax_difference": 500000, "inspection_risk_pct": 5}}
    result.correction_profitable == false
    result.recommendation == "ANALIZA_Z_DORADCA"
}

# ── 17. SYMULATOR ULG W SPŁACIE (INN-18) ──────────────────────────────────────
test_relief_simulator_umorzenie {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.relief_simulator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "tax_arrears": 50000, "important_taxpayer_interest": true}}
    result.relief_options.umorzenie.eligibility == true
    result.recommendation == "WNIOSEK_O_UMORZENIE"
}

test_relief_simulator_none {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.relief_simulator with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "tax_arrears": 50000}}
    result.recommendation == "BRAK_ULGI"
}

# ── 18. AUTO-WYKRYWANIE PRZEDAWNIENIA (INN-19) ────────────────────────────────
test_prescription_windup_guard_prescribed {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.prescription_windup_guard with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "liability_year": 2019, "current_year": 2026}}
    result.prescribed == true
    result._routing == "TRIAGE_QUEUE"
}

test_prescription_windup_guard_active {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.prescription_windup_guard with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "liability_year": 2024, "current_year": 2026}}
    result.prescribed == false
    result._routing == ""
}

# ── 14. Główny decide (P11) + no_match ────────────────────────────────────────
test_p11_main_decide {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.decide with
        input as {"jdg_entrepreneur": {"p11_ordynacja_check": true, "tax_year": 2026}}
    result.matched == true
    result.rule_id == "jdg.p11_ordynacja_podatkowa_innovations.report"
    result._routing == "REPORT"
    result.limitation_engine.deadline == "31.12.2031"
}

test_p11_default_no_match {
    result := data.jdg.p11_ordynacja_podatkowa_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p11_ordynacja_podatkowa_innovations.no_match"
}
