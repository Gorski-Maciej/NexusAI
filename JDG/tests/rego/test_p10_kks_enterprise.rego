# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P10 KKS — Kodeks Karny Skarbowy Enterprise — testy rego
# (RAPORT P10 v8.0 + v9.1 INN-13..16)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p10_kks

import future.keywords.in

# ── 17. SYMULATOR "CO JEŚLI" (INN-13) ─────────────────────────────────────────
test_penalty_what_if_correction_cheaper {
    result := data.jdg.p10_kks_innovations.penalty_what_if_simulator with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "tax_arrears": 10000},
            "offense": {"daily_rates": 10}}
    result.matched == true
    result.correction_cost == round(10000 * 0.15 * 100) / 100
    result.penalty_estimate == round(160.0 * 10 * 100) / 100
    result.correction_cheaper == true
    result.recommendation == "KOREKTA_DEKLARACJI"
}

test_penalty_what_if_penalty_cheaper {
    result := data.jdg.p10_kks_innovations.penalty_what_if_simulator with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "tax_arrears": 500000},
            "offense": {"daily_rates": 10}}
    result.correction_cheaper == false
    result.recommendation == "DORADCA_PODATKOWY"
}

# ── 18. GOTOWOŚĆ NA KONTROLĘ SKARBOWĄ (INN-14) ────────────────────────────────
test_tax_audit_readiness_ready {
    result := data.jdg.p10_kks_innovations.tax_audit_readiness with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}}
    result.readiness_score == 100
    result.audit_ready == true
    result._routing == ""
}

test_tax_audit_readiness_gaps {
    result := data.jdg.p10_kks_innovations.tax_audit_readiness with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "documents_incomplete": true, "jpk_not_ready": true}}
    result.readiness_score == 60
    result.audit_ready == false
    result._routing == "TRIAGE_QUEUE"
}

# ── 19. ODPOWIEDZIALNOŚĆ POWIĄZANA (INN-15) ───────────────────────────────────
test_related_liability_audit_succession {
    result := data.jdg.p10_kks_innovations.related_liability_audit with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "succession_active": true}}
    result.succession_active == true
    result._routing == "TRIAGE_QUEUE"
}

# ── 20. PRZEWIDYWACZ WYROKÓW (INN-16) ─────────────────────────────────────────
test_judgment_trend_predictor_favorable {
    result := data.jdg.p10_kks_innovations.judgment_trend_predictor with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "favorable_jurisprudence_trend": true},
            "offense": {"type": "art54"}}
    result.prediction == "WYSOKIE_SZANSE_OBRONY"
}

test_judgment_trend_predictor_neutral {
    result := data.jdg.p10_kks_innovations.judgment_trend_predictor with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}, "offense": {"type": "art54"}}
    result.prediction == "NEUTRALNE"
}

# ── 21. Główny decide (P10) — nowe sekcje agregowane ───────────────────────────
test_p10_main_decide_new_sections {
    result := data.jdg.p10_kks_innovations.decide with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}}
    result.matched == true
    result.what_if.recommendation == "KOREKTA_DEKLARACJI"
    result.audit_readiness.audit_ready == true
    result.judgment_trend.prediction == "NEUTRALNE"
}

# ── 1. Mapa pokrycia artykułów KKS ────────────────────────────────────────────
test_kks_coverage_report {
    result := data.jdg.p10_kks_innovations.kks_coverage_report with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}} with
        data.jdg.kks_audit as {"articles": {
            "a16": {"status": "COMPLETE"}, "a54": {"status": "COMPLETE"},
            "a56": {"status": "COMPLETE"}, "a62": {"status": "COMPLETE"},
            "a77": {"status": "COMPLETE"}, "a44": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 18
    result.summary.complete == 6
}

# ── 2. AUDYT GRADACJI KAR (PRIORYTET) ─────────────────────────────────────────
test_penalty_gradation_audit {
    result := data.jdg.p10_kks_innovations.penalty_gradation_audit with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}}
    result.daily_rate_min == round(4800.0 / 30 * 100) / 100
    result.daily_rate_max == 4800.0 * 400
    result.crime_threshold == 4800.0 * 200
    result.max_rates_crime == 720
    result.max_rates_misdemeanor == 240
    result.offense_matrix.art54.name == "Uchylanie się od opodatkowania"
}

# ── 3. KALKULATOR KARY (INN-01) ───────────────────────────────────────────────
test_penalty_calculator {
    result := data.jdg.p10_kks_innovations.penalty_calculator with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}, "offense": {"type": "art56", "amount": 150000, "daily_rates": 10}}
    result.daily_rates == 10
    result.is_crime == false
    result.fine_min == round(round(4800.0 / 30 * 100) / 100 * 10 * 100) / 100
    result.offense_info.name == "Nierzetelne księgi/PKPiR"
}

# ── 4. SILNIK MINIMALIZACJI KARY — 4-ścieżkowy decision tree (INN-02) ─────────
test_penalty_minimization_engine {
    result := data.jdg.p10_kks_innovations.penalty_minimization_engine with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "tax_arrears": 150000, "disclosure_before_detection": true}}
    result.paths.path_1_czynny_zal.eligible == true
    result.recommendation == "czynny_zal"
}

# ── 5. SYMULATOR RYZYKA KARNO-SKARBOWEGO (INN-03) ─────────────────────────────
test_risk_score_simulator {
    result := data.jdg.p10_kks_innovations.risk_score_simulator with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "empty_invoices": true, "recidivism": true}}
    result.risk_score == 65
    result.risk_level == "CRITICAL"
}

test_risk_score_simulator_low {
    result := data.jdg.p10_kks_innovations.risk_score_simulator with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}}
    result.risk_score == 0
    result.risk_level == "LOW"
}

# ── 6. CZYNNY ŻAL I DOBROWOLNE PODDANIE SIĘ (Sekcja 3) ────────────────────────
test_voluntary_disclosure_assistant {
    result := data.jdg.p10_kks_innovations.voluntary_disclosure_assistant with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "disclosure_before_detection": true, "control_started": false}}
    result.worth_filing == true
    result.effect == "brak odpowiedzialności karnej (art. 16 §1)"
}

test_voluntary_disclosure_assistant_control_started {
    result := data.jdg.p10_kks_innovations.voluntary_disclosure_assistant with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "disclosure_before_detection": true, "control_started": true}}
    result.worth_filing == false
}

# ── 7. PRZEDAWNIENIE I ZATARCIE (Sekcja 4) ────────────────────────────────────
test_limitation_calendar {
    result := data.jdg.p10_kks_innovations.limitation_calendar with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}}
    result.crime_years == 5
    result.misdemeanor_years == 3
}

test_conviction_expungement_tracker {
    result := data.jdg.p10_kks_innovations.conviction_expungement_tracker with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "penalty_type": "grzywna"}}
    result.expungement_period_years == 1
}

# ── 8. Duplikaty i spójność micro ↔ macro (Sekcja 5) ──────────────────────────
test_kks_duplicate_report {
    result := data.jdg.p10_kks_innovations.kks_duplicate_report with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}} with
        data.jdg.kks_audit as {"total_rule_ids": 474, "unique_count": 470, "duplicate_count": 2, "stub_count": 1}
    result.total_rule_ids == 474
    result.unique_count == 470
    result.duplicate_count == 2
    result.stub_count == 1
}

# ── 9. Pipeline auto-aktualizacji sankcji (Sekcja 6) ──────────────────────────
test_kks_pipeline_snapshot {
    result := data.jdg.p10_kks_innovations.kks_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.kks (ADR-002) — min. wynagrodzenie, mnożniki"
    result.pipeline.step_4_emit == "hot-reload pakietów jdg.kks / jdg.kks.innovations"
}

# ── 10. Genius ideas (Sekcja 7) ───────────────────────────────────────────────
test_small_value_assessor {
    result := data.jdg.p10_kks_innovations.small_value_assessor with
        input as {"jdg_entrepreneur": {"p10_kks_check": true}, "offense": {"amount": 100000}}
    result.is_small_value == true
    result.small_value_threshold == 2400000.0
}

test_recidivism_detector {
    result := data.jdg.p10_kks_innovations.recidivism_detector with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "prior_convictions": 1}}
    result.recidivism == true
    result.penalty_multiplier == 2
}

# ── 11. Główny decide (P10) + no_match ────────────────────────────────────────
test_p10_main_decide {
    result := data.jdg.p10_kks_innovations.decide with
        input as {"jdg_entrepreneur": {"p10_kks_check": true, "tax_arrears": 150000}}
    result.matched == true
    result.rule_id == "jdg.p10_kks_innovations.report"
    result._routing == "REPORT"
    result.penalty_gradation.max_rates_crime == 720
}

test_p10_default_no_match {
    result := data.jdg.p10_kks_innovations.decide with input as {"jdg_entrepreneur": {"tax_arrears": 1000}}
    result.matched == false
    result.rule_id == "jdg.p10_kks_innovations.no_match"
}
