# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — HYPER-PLAN45 META ENTERPRISE ORCHESTRATOR (FAZA 3)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Hyper-Plan45 META — Cross-Rule Orchestration Engine
# description: |
#   ENTERPRISE v7.0 — Meta-warstwa orkiestrująca ~455 reguł z 14 modułów
#   Hyper-Plan45. Wprowadza "nadreguły" (meta-rules) analizujące wyniki
#   z wielu pakietów jednocześnie i generujące rekomendacje cross-modułowe.
#
#   Moduły Hyper-Plan45 objęte META:
#   - Tax Optimization (S1) — 6+4 reguł
#   - Cross-Domain (S2) — 4+10 reguł
#   - Judicial Rulings (S3) — 5 reguł
#   - Audit Defense (S4) — 4 reguły
#   - Strategic Advisor (S5) — 4+4 reguły
#   - KSeF Resilience (S6) — 3 reguły
#   - PPK/PFRON (S7) — 3 reguły
#   - Cashflow Predictor (S8) — 4 reguły
#   - Form Transition (S9) — 4 reguły
#   - Banking Automation (S10) — 8 reguł
#   - Annual Declaration (S11) — 4 reguły
#   - JPK_V7 AutoGen (S12) — 5 reguł
#   - Legislative Monitor (S13) — 4 reguły
#   - Neural Mesh (S14) — 5 reguł
#   - MDR DAC6 (S16b) — 3 reguły
#   = ~72 reguł Enterprise + ~383 reguł core = ~455 total
#
# architecture: Enterprise v7.0 META Orchestrator
# package: jdg.hyper_plan45_meta
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.hyper_plan45_meta

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.meta.no_match",
    "package": "jdg.hyper_plan45_meta", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# META-100: CROSS-MODULE CONSISTENCY CHECK — Spójność między modułami
# ═══════════════════════════════════════════════════════════════════════════════

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
    "_legal_basis": "Cross-module consistency — wszystkie moduly Hyper-Plan45",
    "_warnings": build_meta_warnings(active_modules, consistency_score, conflicts)
} {
    input.meta_consistency_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)
    uses_ksef := object.get(input.jdg_entrepreneur, "uses_ksef", false)
    uses_banking_api := object.get(input.jdg_entrepreneur, "banking_psd2_enabled", false)
    has_ip_box := object.get(input.jdg_entrepreneur, "has_qualifying_ip", false)

    active_modules := ["S1_TaxOpt", "S2_CrossDomain"]
    active_modules := array.concat(active_modules, ["S3_Judicial"]) { true }
    active_modules := array.concat(active_modules, ["S4_AuditDefense"]) { true }
    active_modules := array.concat(active_modules, ["S5_Strategic"]) { true }
    active_modules := array.concat(active_modules, ["S6_KSeF"]) { uses_ksef }
    active_modules := array.concat(active_modules, ["S7_PPK_PFRON"]) { has_employees }
    active_modules := array.concat(active_modules, ["S8_Cashflow"]) { true }
    active_modules := array.concat(active_modules, ["S9_FormTransition"]) { true }
    active_modules := array.concat(active_modules, ["S10_Banking"]) { uses_banking_api }
    active_modules := array.concat(active_modules, ["S11_AnnualDecl"]) { true }
    active_modules := array.concat(active_modules, ["S12_JPK_V7"]) { is_vat_payer }
    active_modules := array.concat(active_modules, ["S13_Legislative"]) { true }
    active_modules := array.concat(active_modules, ["S14_NeuralMesh"]) { true }
    active_modules := array.concat(active_modules, ["S16_MDR_DAC6"]) { is_cross_border }
    active_modules := array.concat(active_modules, ["S21_VAT_Complete"]) { is_vat_payer }
    active_modules := array.concat(active_modules, ["S22_TaxAuthority"]) { true }
    active_modules := array.concat(active_modules, ["S23_Sanctions"]) { true }
    active_modules := array.concat(active_modules, ["S24_Lifecycle"]) { true }

    module_count := count(active_modules)
    conflicts := []
    conflicts := array.concat(conflicts, ["IP Box + B+R conflict (S1-S5)"]) { has_ip_box }
    conflicts := array.concat(conflicts, ["Cross-border + brak MDR (S2-S16)"]) { is_cross_border }

    consistency_score := 100 - count(conflicts) * 10
    recommendations := []
    recommendations := array.concat(recommendations, ["Wlacz monitoring cross-domain S2"]) { consistency_score < 80 }
    recommendations := array.concat(recommendations, ["Aktywuj MDR DAC6 dla transakcji transgranicznych"]) { is_cross_border }

    meta_routing := "TRIAGE_QUEUE" { consistency_score < 80 }
    meta_routing := "" { true }
    meta_reason := sprintf("Spójność: %d/100 — %d modułów aktywnych, %d konfliktów", 
        [consistency_score, module_count, count(conflicts)]) { true }
}

build_meta_warnings(modules, score, conflicts) = warnings {
    score >= 90
    warnings := [sprintf("✅ HYPER-PLAN45 META: %.0f/100 spójności (%d modułów)", [score, count(modules)])]
} else = warnings {
    score < 90
    warnings := [
        sprintf("⚠️ HYPER-PLAN45 META: %.0f/100 spójności", [score]),
        sprintf("   Aktywne moduły: %d", [count(modules)]),
        sprintf("   Konflikty: %d", [count(conflicts)]),
        "   Rozwaz ponowna kalibracje regul"
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# META-200: MODULE COVERAGE ANALYZER — Analiza pokrycia modułów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
    "_routing": cov_routing,
    "_routing_reason": cov_reason,
    "_legal_basis": "Analiza pokrycia Hyper-Plan45",
    "_warnings": [sprintf("📊 POKRYCIE HYPER-PLAN45: %.0f%% (%d/455 reguł)", [coverage_pct, active_rules])]
} {
    input.meta_coverage_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)

    active_rules := 72
    active_rules := active_rules + 50 { is_vat_payer }
    active_rules := active_rules + 15 { has_employees }
    active_rules := active_rules + 30 { is_cross_border }
    active_rules := active_rules + 200
    # TODO: Replace hardcoded counts with dynamic module rule counting
    # using data.jdg.module_registry when available
    # module_registry maps package names to rule counts:
    #   S1_tax_opt: 10, S2_cross_domain: 15, S4_audit: 4, S5_strategic: 8,
    #   S8_cashflow: 4, S9_form_transition: 5, S10_banking: 12,
    #   S11_annual_decl: 4, S12_jpk_v7: 6, S13_legislative: 5,
    #   S14_neural_mesh: 5, S16_mdr_dac6: 3, S21_vat_complete: ~50,
    #   S22_tax_authority: 6, S23_sanctions: 4, S24_lifecycle: 5
    # = ~140 Enterprise rules + ~315 core rules = ~455 total

    coverage_pct := floor(active_rules / 455 * 10000) / 100
    coverage_pct := 100 { coverage_pct > 100 }

    uncovered := []
    uncovered := array.concat(uncovered, ["Employer/PPK/PFRON"]) { not has_employees }
    uncovered := array.concat(uncovered, ["Cross-Border VAT/MDR"]) { not is_cross_border }

    cov_routing := "" { true }
    cov_reason := sprintf("Pokrycie %.0f%% — %d obszarow nieaktywnych", [coverage_pct, count(uncovered)]) { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# META-300: OPTIMAL RULE PATH RECOMMENDER — Rekomendacja optymalnej ścieżki
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
    "_routing_reason": "Optymalizacja sciezek cross-modulowych zalecana",
    "_legal_basis": "Strategia optymalizacji Hyper-Plan45",
    "_warnings": [
        sprintf("🎯 OPTYMALNE SCIEZKI CROSS-MODULOWE:", []),
        sprintf("   S1→S9: %s", [s1_to_s9]),
        sprintf("   S4↔S22: %s", [s4_to_s22]),
        sprintf("   S8→S10: %s", [s8_to_s10])
    ]
} {
    input.meta_optimal_path == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 100000)

    s1_to_s9 := "S1 TaxOpt → S9 FormTransition: zoptymalizuj forme + symuluj zmiane"
    s4_to_s22 := "S4 AuditDefense → S22 TaxAuthority: automatyczna generacja pism"
    s8_to_s10 := "S8 Cashflow → S10 Banking: automatyczne przelewy + prognoza"
}
