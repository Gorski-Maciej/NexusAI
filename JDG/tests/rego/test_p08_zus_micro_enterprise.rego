# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 ZUS/SUS Micro Enterprise — testy rego (RAPORT P08 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p08_zus_micro

import future.keywords.in

# ── 1. Mapa pokrycia artykułów ZUS micro ──────────────────────────────────────
test_zus_coverage_report {
    result := data.jdg.p08_zus_micro_innovations.zus_coverage_report with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true}} with
        data.jdg.zus_micro_audit as {"articles": {
            "sus_a6": {"status": "COMPLETE"}, "sus_a9": {"status": "COMPLETE"},
            "sus_a18": {"status": "COMPLETE"}, "sus_a22": {"status": "COMPLETE"},
            "h_a81": {"status": "COMPLETE"}, "h_a79": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 25
    result.summary.complete == 6
}

# ── 2. Audyt zdrowotnej mikro (PRIORYTET) ─────────────────────────────────────
test_health_micro_audit {
    result := data.jdg.p08_zus_micro_innovations.health_micro_audit with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "tax_form": "skala", "monthly_income": 10000, "annual_revenue": 100000, "annual_income": 120000, "health_advances_paid": 10000}}
    result.matched == true
    result.rates.skala_9pct == 0.09
    result.monthly.scale == 900.0
    result.monthly.linear == 490.0
    result.monthly.lump == 819.0
    result.minimum_monthly == 432.0
    result.annual_reconciliation.due_scale == 10800.0
    result.annual_reconciliation.difference == 800.0
}

# ── 3. Silnik progu ryczałtowego z auto-przeliczeniem (INN-01) ────────────────
test_lump_tier_auto_recalc {
    result := data.jdg.p08_zus_micro_innovations.lump_tier_auto_recalc with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "annual_revenue": 100000}}
    result.matched == true
    result.current_tier == 819.0
    result.tier_switch_needed == true
    result.annual_impact == round(819.00 * 12 * 100) / 100 - round(491.40 * 12 * 100) / 100
}

# ── 4. Składka od nadwyżki (INN-02) ───────────────────────────────────────────
test_health_excess_detector {
    result := data.jdg.p08_zus_micro_innovations.health_excess_detector with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "monthly_income": 10000}}
    result.minimum_health == 432.0
    result.scale_paid == 900.0
    result.excess_over_min == 468.0
}

# ── 5. Audyt zasiłków mikro ───────────────────────────────────────────────────
test_benefits_micro_audit {
    result := data.jdg.p08_zus_micro_innovations.benefits_micro_audit with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "benefit_base": 5204.40, "insured_months": 6}}
    result.waiting.eligible == true
    result.daily.sickness_80pct == round(round(5204.40 / 30 * 100) / 100 * 0.80 * 100) / 100
    result.limits.maternity_days_20wks == 140
    result.limits.sickness_annual_limit == 85528
}

test_waiting_period_calculator {
    result := data.jdg.p08_zus_micro_innovations.waiting_period_calculator with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "insured_months": 1}}
    result.eligible == false
    result.remaining_months == 2
}

# ── 6. Audyt duplikatów i stubów ──────────────────────────────────────────────
test_zus_stub_duplicate_report {
    result := data.jdg.p08_zus_micro_innovations.zus_stub_duplicate_report with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true}} with
        data.jdg.zus_micro_audit as {"total_rule_ids": 500, "unique_count": 480, "duplicate_count": 2, "stub_count": 1}
    result.total_rule_ids == 500
    result.unique_rule_ids == 480
    result.duplicate_count == 2
    result.stub_count == 1
}

# ── 7. Spójność micro ↔ macro (P07) ───────────────────────────────────────────
test_zus_micro_macro_report {
    result := data.jdg.p08_zus_micro_innovations.zus_micro_macro_report with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true}} with
        data.jdg.zus_micro_audit as {"articles": {
            "h_a79": {"status": "COMPLETE"}, "h_a81": {"status": "COMPLETE"},
            "h_a81b": {"status": "COMPLETE"}, "h_a81c": {"status": "COMPLETE"},
            "h_a81d": {"status": "COMPLETE"}, "h_a82": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.micro_coverage.health_articles == 6
    result.priority_consistency == "makro P720-P770 ⊃ mikro a6-a47 (decyzje macro mają atomowe wsparcie)"
}

# ── 8. Atomowy silnik zbiegów (a6/a9) (INN-04) ────────────────────────────────
test_atomic_concurrent_title_engine {
    result := data.jdg.p08_zus_micro_innovations.atomic_concurrent_title_engine with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "concurrent_title": "etat_jdg"}}
    result.obligation.social == false
    result.obligation.health == true
    result.legal_atom.a6 == "podleganie ubezpieczeniom (art. 6 ust. 1 pkt 1-2)"
}

# ── 9. Pipeline temporalny (Sekcja 6) ─────────────────────────────────────────
test_zus_micro_pipeline_snapshot {
    result := data.jdg.p08_zus_micro_innovations.zus_micro_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "tax_year": 2026}}
    result.year == 2026
    result.snapshot.minimum_wage_gross == 4800
    result.snapshot.health_lump_tier_2_amount == 819.00
    result.pipeline.step_1_ingest == "data.jdg.thresholds.zus (ADR-002)"
}

# ── 10. Symulator zdrowotnej per forma (INN-06) ───────────────────────────────
test_health_micro_simulator {
    result := data.jdg.p08_zus_micro_innovations.health_micro_simulator with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "monthly_income": 5000, "annual_revenue": 30000}}
    result.comparison.skala == 450.0
    result.comparison.liniowy == 245.0
    result.comparison.ryczałt == 491.40
    result.cheapest == "liniowy"
}

# ── 11. Detektor niekonsekwencji rule_id (INN-07) ─────────────────────────────
test_rule_id_inconsistency_detector {
    result := data.jdg.p08_zus_micro_innovations.rule_id_inconsistency_detector with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true}} with
        data.jdg.zus_micro_audit as {"plan33_rule_id_prefix": "jdg.zus"}
    result.consistent == false
    result._routing == "WARNING"
}

# ── 12. Główny decide (P08) + no_match ────────────────────────────────────────
test_p08_main_decide {
    result := data.jdg.p08_zus_micro_innovations.decide with
        input as {"jdg_entrepreneur": {"p08_zus_micro_check": true, "tax_form": "ryczałt", "monthly_income": 15000, "annual_revenue": 250000}}
    result.matched == true
    result.rule_id == "jdg.p08_zus_micro_innovations.report"
    result._routing == "REPORT"
    result.health_micro.form == "ryczałt"
}

test_p08_default_no_match {
    result := data.jdg.p08_zus_micro_innovations.decide with input as {"jdg_entrepreneur": {"monthly_income": 10000}}
    result.matched == false
    result.rule_id == "jdg.p08_zus_micro_innovations.no_match"
}
