# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P13 Ryczałt + Cykl Życia JDG Enterprise — testy rego
# (RAPORT P13 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p13_ryczalt_cykl_zycia

import future.keywords.in

# ── 1. Mapa pokrycia artykułów ryczałtu ───────────────────────────────────────
test_ryczalt_coverage_report {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_coverage_report with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}} with
        data.jdg.p13_audit as {"articles": {
            "a4": {"status": "COMPLETE"}, "a6": {"status": "COMPLETE"},
            "a8": {"status": "COMPLETE"}, "a12": {"status": "COMPLETE"},
            "a15": {"status": "COMPLETE"}, "a21": {"status": "COMPLETE"},
            "a27": {"status": "COMPLETE"}, "a29": {"status": "COMPLETE"},
            "a30": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 9
    result.summary.complete == 9
}

# ── 2. AUDYT STAWEK RYCZAŁTU WG PKWiU (PRIORYTET — art. 12 ust. 1) ───────────
test_ryczalt_rates_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_rates_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.limit_eur == 2000000
    result.limit_pln == 9000000.0
    result.rates_pkwiu["3"] == "handel hurtowy i detaliczny (sekcja G)"
    result.rates_pkwiu["17"] == "wolne zawody (adwokaci, lekarze, księgowi, architekci — art. 12 ust. 1 pkt 5)"
    result.declaration == "PIT-28 — roczne rozliczenie ryczałtu (art. 21 ust. 2)"
}

# ── 3. Auto-kalkulator stawki z kodu PKWiU (INN-01) ───────────────────────────
test_ryczalt_rate_calculator_handel {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_rate_calculator with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true},
                  "activity": {"pkwiu_code": "4711"}}
    result.rate == "3%"
    result.pkwiu_section == "G (handel)"
}

test_ryczalt_rate_calculator_it {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_rate_calculator with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true},
                  "activity": {"pkwiu_code": "6201"}}
    result.rate == "12%"
    result.pkwiu_section == "J (IT)"
}

test_ryczalt_rate_calculator_transport {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_rate_calculator with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true},
                  "activity": {"pkwiu_code": "4941"}}
    result.rate == "12,5%"
    result.pkwiu_section == "H (transport)"
}

# ── 4. Tracker limitu 2 mln EUR (INN-02 — art. 6) ─────────────────────────────
test_ryczalt_limit_tracker {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_limit_tracker with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "revenue_ytd": 9500000}}
    result.exceeds_limit == true
    result.usage_pct == 105.56
    result.note == "przekroczenie limitu 2 mln EUR → utrata ryczałtu od następnego dnia (art. 6 ust. 4)"
}

test_ryczalt_limit_tracker_at_limit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_limit_tracker with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "revenue_ytd": 9000000}}
    result.exceeds_limit == false
    result.usage_pct == 100.0
}

test_ryczalt_limit_tracker_warning {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_limit_tracker with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "revenue_ytd": 6750000}}
    result.warning_at_75pct == true
    result.exceeds_limit == false
}

# ── 5. Wykrywacz błędnych stawek (INN-10) ─────────────────────────────────────
test_wrong_rate_detector {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.wrong_rate_detector with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true},
                  "activity": {"pkwiu_code": "4711", "declared_rate": "8,5%"}}
    result.rate_mismatch == true
    result.correct_rate == "3%"
}

# ── 6. AUDYT KARTY PODATKOWEJ (Sekcja 2) ──────────────────────────────────────
test_karta_podatkowa_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.karta_podatkowa_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.limit_zatrudnienia == 5
    count(result.zasady) > 0
    "wniosek do US" in result.zgłoszenie
}

# ── 7. AUDYT CYKLU ŻYCIA JDG (PRIORYTET — Sekcja 3) ───────────────────────────
test_lifecycle_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.lifecycle_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.phases.STARTUP_RELIEF == "ulga na start 0 zł ZUS społeczne (0-6 mies., art. 18a SUS)"
    result.phases.SUCCESSION == "zarządca sukcesyjny — 2 lata + przedłużenie do 5 lat (art. 3-15 z.s.)"
    count(result.integrated_packages) == 4
}

test_lifecycle_assistant_startup {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.lifecycle_assistant with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "months_active": 3}}
    result.current_phase == "STARTUP_RELIEF"
    result.next_phase == "STARTUP_PREFERENTIAL (po 6 mies. — preferencyjny ZUS 30%)"
    count(result.obligations_calendar) == 5
}

test_lifecycle_assistant_maturity {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.lifecycle_assistant with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "months_active": 70}}
    result.current_phase == "MATURITY"
    result.next_phase == "SUSPENDED / SUCCESSION (exit lub sukcesja)"
}

# ── 8. Symulator form opodatkowania (INN-09) ──────────────────────────────────
test_pit_form_comparator_ryczalt {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.pit_form_comparator with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "annual_revenue": 300000, "ryczalt_rate_pct": 8.5}}
    result.ryczalt_tax == 25500.0
    result.skala_tax == 36000.0
    result.liniowy_tax == 57000.0
    result.best_form == "ryczałt"
}

# ── 9. AUDYT SUKCESJI (Sekcja 4) ──────────────────────────────────────────────
test_succession_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.succession_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.zarzadca.wpis_ceidg_days == 14
    result.terms.standard_months == 24
    result.terms.extended_months == 60
    count(result.termination) == 5
}

test_succession_tracker {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.succession_tracker with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "succession_months_elapsed": 10}}
    count(result.steps) == 6
    result.months_remaining == 14
    result.extended_available == false
}

test_succession_tracker_extended {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.succession_tracker with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "succession_months_elapsed": 30}}
    result.months_remaining == -6
    result.extended_available == true
}

# ── 10. AUDYT ZAWIESZEŃ (Sekcja 5 — art. 22-25 PP) ────────────────────────────
test_suspension_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.suspension_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.art22_25.max_months == 24
    result.art22_25.min_days == 30
    result.resumption == "wznowienie — zgłoszenie CEIDG (art. 25 PP)"
}

# ── 11. Działalność nieewidencjonowana (INN-05 — art. 6 PP) ───────────────────
test_unregistered_business_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.unregistered_business_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "monthly_revenue": 2000}}
    result.limit_monthly == 2400.0
    result.within_limit == true
    result.min_wage_2026 == 4800
}

test_unregistered_business_audit_over {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.unregistered_business_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "monthly_revenue": 5000}}
    result.within_limit == false
}

# ── 12. Gig economy + prokura + CEIDG (INN-06/07/11) ──────────────────────────
test_gig_economy_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.gig_economy_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    "DAC7" in result.reporting
    result.integrated == "jdg.business.gig_economy"
}

test_prokura_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.prokura_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    count(result.types) == 3
    result.integrated == "jdg.representation (plan26_prokura)"
}

test_ceidg_audit {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ceidg_audit with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.wpis_days == 7
    result.integrated == "jdg.micro.ceidg (43 reguły micro)"
}

# ── 13. Pipeline + hook + panel (Sekcja 6-7) ──────────────────────────────────
test_ryczalt_pipeline_snapshot {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.ryczalt (ADR-002) — stawki PKWiU, limit 2M EUR, płaca minimalna"
    result.auto_update == "zmiany stawek ryczałtu i płacy minimalnej (coroczne obwieszczenia) → auto-aktualizacja thresholdów"
}

test_ryczalt_compliance_panel {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_compliance_panel with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    count(result.checks) == 7
    result.compliance_score == 100
}

# ── 14. Główny decide (P13) + no_match ────────────────────────────────────────
test_p13_main_decide {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.decide with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.matched == true
    result.rule_id == "jdg.p13_ryczalt_cykl_zycia_innovations.report"
    result._routing == "REPORT"
    result.lifecycle.phases.GROWTH == "limit VAT 200k → VAT-R, KSeF od 2026, pierwszy pracownik (art. 113 VAT)"
    result.succession.terms.standard_months == 24
}

# ── 9b. NOWE INNOWACJE v9.1 (INN-13..INN-17) ────────────────────────────────
test_company_setup_assistant_complete {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.company_setup_assistant with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "setup_ceidg_done": true,
                                       "setup_zus_done": true}}
    result.setup_complete == true
    result.steps_completed == 2
    result.onboarding_pct == 100.0
    result._routing == ""
}

test_company_setup_assistant_incomplete {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.company_setup_assistant with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "setup_ceidg_done": true}}
    result.setup_complete == false
    result._routing == "TRIAGE_QUEUE"
    count(result.steps) == 6
}

test_ryczalt_loss_detector {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_loss_detector with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "revenue_ytd": 5000000,
                                       "projected_annual_revenue": 10000000}}
    result.limit_pln == 9000000.0
    result.projected_loss_risk == true
    result.loss_triggered == false
    result._routing == "TRIAGE_QUEUE"
}

test_suspend_or_close_simulator {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.suspend_or_close_simulator with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "planned_suspension_months": 6,
                                       "will_resume": true}}
    result.recommendation == "ZAWIESZENIE"
    result._routing == "TRIAGE_QUEUE"
}

test_suspend_or_close_simulator_liquidation {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.suspend_or_close_simulator with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "planned_suspension_months": 36,
                                       "will_resume": true}}
    result.recommendation == "LIKWIDACJA"
    result.within_max_suspension == false
}

test_succession_step_guide {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.succession_step_guide with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true, "succession_months_elapsed": 30}}
    result.extension_needed == true
    result.standard_months == 24
    result.extended_months == 60
    count(result.checklist) == 6
    count(result.forms) == 3
    result._routing == "TRIAGE_QUEUE"
}

test_pkwiu_rate_recommender {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.pkwiu_rate_recommender with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true},
                  "activity": {"description": "sprzedaż w sklepie internetowym"}}
    result.recommended_rate == "3%"
    count(result.matched_keywords) >= 1
}

test_pkwiu_rate_recommender_it {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.pkwiu_rate_recommender with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true},
                  "activity": {"description": "programowanie aplikacji mobilnych"}}
    result.recommended_rate == "12%"
}

test_p13_main_decide_new_sections {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.decide with
        input as {"jdg_entrepreneur": {"p13_ryczalt_check": true}}
    result.loss_detector.rule_id == "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_loss_detector"
    result.setup.setup_complete == false
    result.exit_simulator.recommendation == "ZAWIESZENIE"
    result.succession_guide.months_remaining == 24
    result.rate_recommender.recommended_rate == "8,5%"
}

test_p13_default_no_match {
    result := data.jdg.p13_ryczalt_cykl_zycia_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p13_ryczalt_cykl_zycia_innovations.no_match"
}
