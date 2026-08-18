# NexusAI JDG — Hyper-Plan45 META orchestrator.
# Package: jdg.hyper_plan45_meta. Legacy metadata kept as ordinary comments.

package jdg.hyper_plan45_meta

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.meta.no_match",
    "package": "jdg.hyper_plan45_meta",
    "priority": 9999,
}

bool_text(value) := sprintf("%v", [value])
bool_not(value) := object.get({"true": false, "false": true}, bool_text(value), false)
both_true(a, b) := object.get({"true|true": true}, sprintf("%v|%v", [a, b]), false)

module_list(input_data) := [entry.name |
    some entry in [
        {"name": "S1_TaxOpt", "active": true},
        {"name": "S2_CrossDomain", "active": true},
        {"name": "S3_Judicial", "active": true},
        {"name": "S4_AuditDefense", "active": true},
        {"name": "S5_Strategic", "active": true},
        {"name": "S6_KSeF", "active": object.get(input_data.jdg_entrepreneur, "uses_ksef", false)},
        {"name": "S7_PPK_PFRON", "active": object.get(input_data.jdg_entrepreneur, "has_employees", false)},
        {"name": "S8_Cashflow", "active": true},
        {"name": "S9_FormTransition", "active": true},
        {"name": "S10_Banking", "active": object.get(input_data.jdg_entrepreneur, "banking_psd2_enabled", false)},
        {"name": "S11_AnnualDecl", "active": true},
        {"name": "S12_JPK_V7", "active": object.get(input_data.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"},
        {"name": "S13_Legislative", "active": true},
        {"name": "S14_NeuralMesh", "active": true},
        {"name": "S16_MDR_DAC6", "active": object.get(input_data.jdg_entrepreneur, "is_cross_border_active", false)},
        {"name": "S21_VAT_Complete", "active": object.get(input_data.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"},
        {"name": "S22_TaxAuthority", "active": true},
        {"name": "S23_Sanctions", "active": true},
        {"name": "S24_Lifecycle", "active": true},
    ]
    entry.active == true
]

meta_warnings(modules, score, conflicts) := [sprintf("✅ HYPER-PLAN45 META: %.0f/100 spójności (%d modułów)", [score, count(modules)])] if {
    score >= 90
} else := [
    sprintf("⚠️ HYPER-PLAN45 META: %.0f/100 spójności", [score]),
    sprintf("   Aktywne moduły: %d", [count(modules)]),
    sprintf("   Konflikty: %d", [count(conflicts)]),
    "Rozważ ponowną kalibrację reguł",
]

# META-100: cross-module consistency check.
decide := {
    "matched": true,
    "rule_id": "jdg.meta.consistency_check",
    "package": "jdg.hyper_plan45_meta",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "meta_active_modules": active_modules,
    "meta_consistency_score": consistency_score,
    "meta_conflicts_detected": conflicts,
    "meta_recommended_actions": recommendations,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": meta_routing,
    "_routing_reason": meta_reason,
    "_legal_basis": "Cross-module consistency — wszystkie moduły Hyper-Plan45",
    "_warnings": meta_warnings(active_modules, consistency_score, conflicts),
} if {
    input.meta_consistency_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    active_modules := module_list(input)
    has_ip_box := object.get(input.jdg_entrepreneur, "has_qualifying_ip", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)
    conflicts := [entry.message |
        some entry in [
            {"message": "IP Box + B+R conflict (S1-S5)", "active": has_ip_box},
            {"message": "Cross-border + brak MDR (S2-S16)", "active": is_cross_border},
        ]
        entry.active == true
    ]
    consistency_score := max([100 - count(conflicts) * 10, 0])
    recommendations := [entry.message |
        some entry in [
            {"message": "Włącz monitoring cross-domain S2", "active": consistency_score < 80},
            {"message": "Aktywuj MDR DAC6 dla transakcji transgranicznych", "active": is_cross_border},
        ]
        entry.active == true
    ]
    meta_routing := object.get({"true": "TRIAGE_QUEUE", "false": ""}, bool_text(consistency_score < 80), "")
    meta_reason := sprintf("Spójność: %d/100 — %d modułów aktywnych, %d konfliktów", [consistency_score, count(active_modules), count(conflicts)])
} else := {
    "matched": true,
    "rule_id": "jdg.meta.coverage_analyzer",
    "package": "jdg.hyper_plan45_meta",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "meta_total_rules_available": 455,
    "meta_active_rules": active_rules,
    "meta_coverage_pct": coverage_pct,
    "meta_uncovered_areas": uncovered,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": cov_reason,
    "_legal_basis": "Analiza pokrycia Hyper-Plan45",
    "_warnings": [sprintf("📊 POKRYCIE HYPER-PLAN45: %.0f%% (%d/455 reguł)", [coverage_pct, active_rules])],
} if {
    input.meta_coverage_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)
    active_rules := 72 + object.get({"true": 50, "false": 0}, bool_text(is_vat_payer), 0) + object.get({"true": 15, "false": 0}, bool_text(has_employees), 0) + object.get({"true": 30, "false": 0}, bool_text(is_cross_border), 0) + 200
    coverage_pct := min([floor(active_rules / 455 * 10000) / 100, 100])
    uncovered := [entry.label |
        some entry in [
            {"label": "Employer/PPK/PFRON", "active": bool_not(has_employees)},
            {"label": "Cross-Border VAT/MDR", "active": bool_not(is_cross_border)},
        ]
        entry.active == true
    ]
    cov_reason := sprintf("Pokrycie %.0f%% — %d obszarów nieaktywnych", [coverage_pct, count(uncovered)])
} else := {
    "matched": true,
    "rule_id": "jdg.meta.optimal_path_recommender",
    "package": "jdg.hyper_plan45_meta",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "meta_recommended_s1_to_s9": s1_to_s9,
    "meta_recommended_s4_to_s22": s4_to_s22,
    "meta_recommended_s8_to_s10": s8_to_s10,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Optymalizacja ścieżek cross-modułowych zalecana",
    "_legal_basis": "Strategia optymalizacji Hyper-Plan45",
    "_warnings": [
        "🎯 OPTYMALNE ŚCIEŻKI CROSS-MODUŁOWE:",
        sprintf("   S1→S9: %s", [s1_to_s9]),
        sprintf("   S4↔S22: %s", [s4_to_s22]),
        sprintf("   S8→S10: %s", [s8_to_s10]),
    ],
} if {
    input.meta_optimal_path == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    s1_to_s9 := "S1 TaxOpt → S9 FormTransition: zoptymalizuj formę + symuluj zmianę"
    s4_to_s22 := "S4 AuditDefense → S22 TaxAuthority: automatyczna generacja pism"
    s8_to_s10 := "S8 Cashflow → S10 Banking: automatyczne przelewy + prognoza"
}
