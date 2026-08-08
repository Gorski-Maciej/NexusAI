# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P06 PIT MACRO ENTERPRISE v9.0
# Sekcje 7-9: optymalizacja formy + audyt ulg + 14 innowacji
# Format: complete rules (test_foo { ... }) — poprawna składnia OPA v0.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p06_pit_macro_enterprise_test

import future.keywords.in

# ── SEKCJA 7: FORM OPTIMIZER ──────────────────────────────────────────────────

test_form_optimizer_scale_vs_linear {
    result := data.jdg.p06_pit_macro_enterprise.form_optimizer with input as {
        "jdg_entrepreneur": {"p06_form_optimizer_check": true, "former_employer_services": false},
        "pit_projection": {"revenue": 300000, "costs": 100000, "lump_sum_eligible": false}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "scale_low_rate": 0.12, "scale_high_rate": 0.32,
            "linear_rate": 0.19}
    }
    result.matched == true
    result.optimizer.scale == 40000
    result.optimizer.linear == 38000
    result.optimizer.recommended_form == "LINEAR"
    result._routing == "REPORT"
}

test_form_optimizer_former_employer_block {
    result := data.jdg.p06_pit_macro_enterprise.form_optimizer with input as {
        "jdg_entrepreneur": {"p06_form_optimizer_check": true,
            "former_employer_services": true, "former_employer_same_services": true},
        "pit_projection": {"revenue": 300000, "costs": 100000, "lump_sum_eligible": false}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "scale_low_rate": 0.12, "scale_high_rate": 0.32,
            "linear_rate": 0.19}
    }
    result.optimizer.former_employer_block == true
    result.optimizer.linear == 0
    result.optimizer.recommended_form == "SCALE"
}

test_form_optimizer_scale_tax_reducing_low {
    # Dochód 100k → kwota zmniejszająca 3 600: 12%×100k = 12 000 − 3 600 = 8 400
    result := data.jdg.p06_pit_macro_enterprise.form_optimizer with input as {
        "jdg_entrepreneur": {"p06_form_optimizer_check": true, "former_employer_services": false},
        "pit_projection": {"revenue": 100000, "costs": 0, "lump_sum_eligible": false}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "scale_low_rate": 0.12, "scale_high_rate": 0.32,
            "linear_rate": 0.19}
    }
    result.matched == true
    result.optimizer.scale == 8400
    result.optimizer.linear == 19000
    result.optimizer.recommended_form == "SCALE"
}

test_form_optimizer_scale_tax_reducing_mid {
    # Dochód 150k → kwota zmniejszająca fazowana: 3 600 − 0.06×30k = 1 800
    # 12%×120k + 32%×30k − 1 800 = 14 400 + 9 600 − 1 800 = 22 200
    result := data.jdg.p06_pit_macro_enterprise.form_optimizer with input as {
        "jdg_entrepreneur": {"p06_form_optimizer_check": true, "former_employer_services": false},
        "pit_projection": {"revenue": 150000, "costs": 0, "lump_sum_eligible": false}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "scale_low_rate": 0.12, "scale_high_rate": 0.32,
            "linear_rate": 0.19}
    }
    result.matched == true
    result.optimizer.scale == 22200
    result.optimizer.linear == 28500
    result.optimizer.recommended_form == "SCALE"
}

# ── SEKCJA 7: LOSS-OF-LINEAR DETECTOR (Art. 30c ust. 2) ───────────────────────

test_loss_of_linear_detector {
    result := data.jdg.p06_pit_macro_enterprise.loss_of_linear_detector with input as {
        "jdg_entrepreneur": {"p06_linear_loss_check": true,
            "former_employer_services": true, "former_employer_same_services": true}
    }
    result.matched == true
    result.detector.former_employer_block == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── SEKCJA 8: B+R DEFINITION CHECKER (Art. 26e — 4 kryteria) ─────────────────

test_br_definition_all_criteria {
    result := data.jdg.p06_pit_macro_enterprise.br_definition_checker with input as {
        "jdg_entrepreneur": {"p06_br_check": true},
        "br_relief": {"creative_activity": true, "systematic_activity": true,
            "knowledge_increase": true, "uncertain_result": true, "qualified_costs": 100000}
    }
    result.matched == true
    result.br.definition_ok == true
    result.br.deduction_100pct == 100000
}

test_br_definition_missing_criterion {
    result := data.jdg.p06_pit_macro_enterprise.br_definition_checker with input as {
        "jdg_entrepreneur": {"p06_br_check": true},
        "br_relief": {"creative_activity": true, "systematic_activity": true,
            "knowledge_increase": true, "uncertain_result": false, "qualified_costs": 100000}
    }
    result.br.definition_ok == false
}

# ── SEKCJA 8: RELIEF RECOMMENDER ──────────────────────────────────────────────

test_relief_recommender_br {
    result := data.jdg.p06_pit_macro_enterprise.relief_recommender with input as {
        "jdg_entrepreneur": {"p06_relief_check": true},
        "br_relief": {"creative_activity": true, "systematic_activity": true,
            "knowledge_increase": true, "uncertain_result": true, "qualified_costs": 50000},
        "prototype_relief": {"qualified_costs": 0, "production_started": false},
        "ip_box": {"qualified_ip_income": 0}
    } with data.jdg.thresholds as {
        "pit": {"prototype_relief_rate": 0.30, "robotization_relief_rate": 0.50,
            "expansion_relief_max_costs": 1000000, "thermo_relief_limit": 53000,
            "shared_relief_limit": 85528, "ip_box_rate": 0.05}
    }
    result.matched == true
    result.reliefs.br_relief == 50000
    result.reliefs.recommended == "B+R (Art. 26e)"
}

test_relief_recommender_prototype {
    result := data.jdg.p06_pit_macro_enterprise.relief_recommender with input as {
        "jdg_entrepreneur": {"p06_relief_check": true},
        "prototype_relief": {"qualified_costs": 100000, "production_started": true},
        "ip_box": {"qualified_ip_income": 0}
    } with data.jdg.thresholds as {
        "pit": {"prototype_relief_rate": 0.30, "robotization_relief_rate": 0.50,
            "expansion_relief_max_costs": 1000000, "thermo_relief_limit": 53000,
            "shared_relief_limit": 85528, "ip_box_rate": 0.05}
    }
    result.reliefs.prototype_relief == 30000
    result.reliefs.recommended == "PROTOTYP (Art. 26eb)"
}

# ── SEKCJA 8: SHARED LIMIT GUARD (85 528 zł) ──────────────────────────────────

test_shared_limit_within {
    result := data.jdg.p06_pit_macro_enterprise.relief_recommender with input as {
        "jdg_entrepreneur": {"p06_relief_check": true},
        "br_relief": {"creative_activity": true, "systematic_activity": true,
            "knowledge_increase": true, "uncertain_result": true, "qualified_costs": 40000},
        "ip_box": {"qualified_ip_income": 200000}
    } with data.jdg.thresholds as {
        "pit": {"prototype_relief_rate": 0.30, "robotization_relief_rate": 0.50,
            "expansion_relief_max_costs": 1000000, "thermo_relief_limit": 53000,
            "shared_relief_limit": 85528, "ip_box_rate": 0.05}
    }
    result.reliefs.shared_limit_guard == true
    result.reliefs.br_relief == 40000
    result.reliefs.ip_box == 10000
}

# ── SEKCJA 8: TERMO CALCULATOR (limit 53 000 zł) ──────────────────────────────

test_termo_calculator_cap {
    result := data.jdg.p06_pit_macro_enterprise.termo_calculator with input as {
        "jdg_entrepreneur": {"p06_termo_check": true},
        "thermo_relief": {"qualified_costs": 80000, "building_owned": true,
            "completed_within_3_years": true, "completion_years": 2}
    } with data.jdg.thresholds as {
        "pit": {"thermo_relief_limit": 53000}
    }
    result.matched == true
    result.termo.deduction == 53000
    result.termo.deadline_ok == true
}

# ── SEKCJA 8: KUP AUDITOR ─────────────────────────────────────────────────────

test_kup_auditor_car {
    result := data.jdg.p06_pit_macro_enterprise.kup_auditor with input as {
        "jdg_entrepreneur": {"p06_kup_check": true},
        "kup_audit": {"car_operating_pct": 75, "car_value": 120000,
            "car_is_electric": false, "representation_costs": false, "cost_paid_this_year": true}
    }
    result.matched == true
    result.kup.car_operating_75pct == true
    result.kup.car_value_limit_150k == true
    result.kup.electric_car_225k == false
}

# ── SEKCJA 8: REKONCYLACJA PIT↔VAT↔ZUS↔PKPiR ─────────────────────────────────

test_pit_reconciliation_consistent {
    result := data.jdg.p06_pit_macro_enterprise.pit_reconciliation with input as {
        "jdg_entrepreneur": {"p06_recon_check": true},
        "pit_recon": {"revenue_pkpir": 100000, "revenue_vat": 100000,
            "kup": 50000, "vat_purchases": 50000, "zus_base": 20000, "income": 50000,
            "tolerance": 100}
    }
    result.matched == true
    result.recon.consistent == true
    result._routing == "TRIAGE_QUEUE"
}

test_pit_reconciliation_mismatch {
    result := data.jdg.p06_pit_macro_enterprise.pit_reconciliation with input as {
        "jdg_entrepreneur": {"p06_recon_check": true},
        "pit_recon": {"revenue_pkpir": 100000, "revenue_vat": 150000,
            "kup": 50000, "vat_purchases": 50000, "zus_base": 20000, "income": 50000,
            "tolerance": 100}
    }
    result.recon.consistent == false
}

# ── SEKCJA 9: GŁÓWNY RAPORT P06 ───────────────────────────────────────────────

test_p06_main_report {
    result := data.jdg.p06_pit_macro_enterprise.decide with input as {
        "jdg_entrepreneur": {"p06_pit_macro_check": true}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "scale_low_rate": 0.12, "scale_high_rate": 0.32,
            "linear_rate": 0.19, "ip_box_rate": 0.05, "prototype_relief_rate": 0.30,
            "robotization_relief_rate": 0.50, "expansion_relief_max_costs": 1000000,
            "thermo_relief_limit": 53000, "shared_relief_limit": 85528}
    }
    result.matched == true
    result.rule_id == "jdg.p06_pit_macro_enterprise.report"
    result._routing == "REPORT"
    count(result.p06_pit_macro.section9_genius) == 14
    result.p06_pit_macro.dependencies.P09_PKPiR == "KUP/koszty"
}

test_p06_no_match_default {
    result := data.jdg.p06_pit_macro_enterprise.decide with input as {
        "jdg_entrepreneur": {"p06_pit_macro_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.p06_pit_macro_enterprise.no_match"
}
