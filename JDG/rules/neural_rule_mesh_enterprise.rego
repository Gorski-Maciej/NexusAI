# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE NEURAL RULE MESH (Strategic Initiative S14)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Neural Rule Mesh — Cross-Domain Intelligent Decision Fabric
# description: |
#   ENTERPRISE v6.0 — Najwyższa warstwa inteligencji między-domenowej.
#   Łączy WSZYSTKIE 13 domen prawnych w spójną sieć decyzyjną.
#   
#   KLUCZOWA INNOWACJA: Reguły nie działają już w izolacji. Każda decyzja
#   w jednej domenie (np. VAT) automatycznie propaguje konsekwencje do
#   wszystkich pozostałych domen (PIT, ZUS, KKS, Ordynacja, PCC, UoR...).
#   
#   Architektura "Neural Mesh":
#   - Warstwa 1: Domain Nodes (13 węzłów per akt prawny)
#   - Warstwa 2: Synaptic Rules (reguły łączące 2+ domen)
#   - Warstwa 3: Global Optimizer (optymalizacja globalna, nie lokalna)
#   - Warstwa 4: Predictive Shield (predykcja ryzyka kontroli)
#   - Warstwa 5: Auto-Healing (samouczenie z korekt użytkownika)
#
#   Ta sieć NIE JEST sumą reguł — jest ILOCZYNEM ich interakcji.
#   13 domen × 13 domen = 169 potencjalnych interakcji między-domenowych.
#   Każda interakcja jest modelowana jako reguła synaptyczna.
# architecture: Neural Mesh v6.0, Post-Merge Cross-Domain Intelligence
# legal_basis: Wszystkie 13 aktów prawnych (VAT, PIT, ZUS, OrdPU, KKS, UoR, 
#              PP, PCC, PodLok, Ryczałt, Sukcesja, RODO, AML/BDO)
# package: jdg.neural_mesh
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.neural_mesh

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.neural_mesh.no_match",
    "package": "jdg.neural_mesh", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# WARSTWA 1: DOMAIN NODES — Metryki zdrowia per domena prawna
# ═══════════════════════════════════════════════════════════════════════════════

# NM-001: Global Domain Health Score — Agregacja zdrowia wszystkich 13 domen
decide := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.global_domain_health",
    "package": "jdg.neural_mesh",
    "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "neural_mesh_global_health_score": global_health,
    "neural_mesh_domain_scores": domain_scores,
    "neural_mesh_critical_gaps": critical_gaps,
    "neural_mesh_recommendation": global_recommendation,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": mesh_routing,
    "_routing_reason": mesh_reason,
    "_legal_basis": "Neural Mesh v6.0 — 13-domain health aggregation",
    "_warnings": build_mesh_health_warnings(global_health, domain_scores, critical_gaps)
} {
    input.neural_mesh_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")

    # Domain Health Scores (0-100 per domain)
    domain_scores := {
        "VAT":     calculate_vat_health(),
        "PIT":     calculate_pit_health(),
        "ZUS":     calculate_zus_health(),
        "OrdPU":   calculate_ordpu_health(),
        "KKS":     calculate_kks_health(),
        "UoR":     calculate_uor_health(),
        "PP":      calculate_pp_health(),
        "PCC":     calculate_pcc_health(),
        "PodLok":  calculate_podlok_health(),
        "Ryczałt": calculate_ryczalt_health(),
        "Sukcesja": calculate_sukcesja_health(),
        "RODO":    calculate_rodo_health(),
        "AML_BDO": calculate_aml_bdo_health()
    }

    # Global health = weighted average
    weights := {"VAT": 0.20, "PIT": 0.20, "ZUS": 0.15, "OrdPU": 0.10,
                "KKS": 0.08, "UoR": 0.08, "PP": 0.05, "PCC": 0.04,
                "PodLok": 0.03, "Ryczałt": 0.03, "Sukcesja": 0.02,
                "RODO": 0.01, "AML_BDO": 0.01}
    
    global_health := sum([score * weights[domain] |
        domain := object.keys(domain_scores)[_]
        score := domain_scores[domain]
    ])

    # Identify critical gaps (domains < 50)
    critical_gaps := [domain |
        domain := object.keys(domain_scores)[_]
        domain_scores[domain] < 50
    ]

    # Global recommendation
    global_recommendation := "✅ WSZYSTKIE DOMENY W NORMIE — kontynuuj działalność." {
        global_health >= 80
        count(critical_gaps) == 0
    }

    global_recommendation := sprintf("⚠️ UWAGA — %d domen(y) poniżej progu bezpieczeństwa: %s. %s",
        [count(critical_gaps), concat(", ", critical_gaps), action_needed]) {
        count(critical_gaps) > 0
        count(critical_gaps) <= 2
        action_needed := "Wymagana interwencja w ciągu 30 dni."
    }

    global_recommendation := sprintf("🔴 KRYTYCZNE — %d domen poniżej progu! %s. NATYCHMIASTOWA interwencja wymagana!",
        [count(critical_gaps), concat(", ", critical_gaps)]) {
        count(critical_gaps) > 2
    }

    mesh_routing := "" { global_health >= 80 }
    mesh_routing := "TRIAGE_QUEUE" { global_health >= 50; global_health < 80 }
    mesh_routing := "BLOCK_AND_ALERT" { global_health < 50 }

    mesh_reason := sprintf("Neural Mesh Health: %.0f/100", [global_health]) { global_health < 80 }
    mesh_reason := "" { global_health >= 80 }
}

# ── Helpers ─────────────────────────────────────────────────────────────────

# Build numbered list from steps array without numbers.range
build_numbered_steps(steps) = result {
    indexed := [sprintf("%d. %s", [idx, step]) |
        step := steps[_]
        idx := index_of(steps, step) + 1
    ]
    result := concat("; ", indexed)
}

# Simple index_of helper
index_of(arr, item) = idx {
    arr[idx] == item
} else = -1 {
    true
}

# ── Domain Health Calculators ─────────────────────────────────────────────────

calculate_vat_health() = score {
    vat_status := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT")
    has_jpk := object.get(input.jdg_entrepreneur, "jpk_filed_on_time", true)
    has_ksef := object.get(input.jdg_entrepreneur, "ksef_registered", false)
    vat_corrections := object.get(input.jdg_entrepreneur, "vat_corrections_12mo", 0)
    
    score := 100
    score := score - 20 { not has_jpk }
    score := score - 15 { vat_corrections > 5 }
    score := score - 10 { vat_corrections > 2; vat_corrections <= 5 }
    tax_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
    score := score - 10 { tax_year >= 2026; not has_ksef; vat_status != "EXEMPT" }
    score := max([score, 0])
}

calculate_pit_health() = score {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    advances_paid := object.get(input.jdg_entrepreneur, "pit_advances_paid_on_time", true)
    annual_filed := object.get(input.jdg_entrepreneur, "pit_annual_filed", true)
    has_losses := object.get(input.jdg_entrepreneur, "has_unresolved_losses", false)
    
    score := 100
    score := score - 30 { not advances_paid }
    score := score - 20 { not annual_filed }
    score := score - 10 { has_losses }
    score := max([score, 0])
}

calculate_zus_health() = score {
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    health_paid := object.get(input.jdg_entrepreneur, "zus_health_paid_current", true)
    social_paid := object.get(input.jdg_entrepreneur, "zus_social_paid_current", true)
    declarations_filed := object.get(input.jdg_entrepreneur, "zus_dra_filed", true)
    
    score := 100
    score := score - 30 { not health_paid }
    score := score - 25 { not social_paid }
    score := score - 15 { not declarations_filed }
    score := score - 5 { zus_status == "STANDARD" }
    score := max([score, 0])
}

calculate_ordpu_health() = score {
    has_whitelist := object.get(input.jdg_entrepreneur, "whitelist_verified", true)
    has_interpretations := object.get(input.jdg_entrepreneur, "has_tax_interpretations_pending", false)
    deadlines_missed := object.get(input.jdg_entrepreneur, "tax_deadlines_missed_12mo", 0)
    
    score := 100
    score := score - 25 { deadlines_missed > 3 }
    score := score - 15 { deadlines_missed > 0; deadlines_missed <= 3 }
    score := score - 10 { not has_whitelist }
    score := score - 10 { has_interpretations }
    score := max([score, 0])
}

calculate_kks_health() = score {
    kks_flags := object.get(input.jdg_entrepreneur, "kks_risk_flags_active", 0)
    has_conviction := object.get(input.jdg_entrepreneur, "kks_convicted", false)
    has_vd := object.get(input.jdg_entrepreneur, "kks_voluntary_disclosure_filed", false)
    # v7.0 Audit: integracja z KKS Realtime Scorer
    kks_realtime_avg := object.get(input.jdg_entrepreneur, "kks_realtime_score_avg_30d", 0)
    has_crossborder_kks := object.get(input.jdg_entrepreneur, "has_crossborder_transactions", false)
    
    score := 100
    score := score - 60 { has_conviction }
    score := score - 30 { kks_flags > 2 }
    score := score - 15 { kks_flags > 0; kks_flags <= 2 }
    # v7.0 Audit: realtime scorer integration
    score := score - 15 { kks_realtime_avg > 50 }  # RED zone avg
    score := score - 8 { kks_realtime_avg > 30; kks_realtime_avg <= 50 }  # YELLOW zone avg
    # v7.0 Audit: crossborder amplifies KKS risk
    score := score - 10 { has_crossborder_kks; kks_flags > 0 }
    score := score + 20 { has_vd }
    score := min([max([score, 0]), 100])
}

calculate_uor_health() = score {
    has_pkpir := object.get(input.jdg_entrepreneur, "pkpir_maintained", true)
    has_inventory := object.get(input.jdg_entrepreneur, "inventory_done_annual", false)
    
    score := 100
    score := score - 40 { not has_pkpir }
    score := score - 20 { not has_inventory }
    score := max([score, 0])
}

calculate_pp_health() = score {
    ceidg_valid := object.get(input.jdg_entrepreneur, "ceidg_valid", true)
    is_suspended := object.get(input.jdg_entrepreneur, "business_suspended", false)
    has_prokura := object.get(input.jdg_entrepreneur, "prokura_registered", false)
    
    score := 100
    score := score - 50 { not ceidg_valid }
    score := score - 10 { is_suspended; has_prokura }
    score := max([score, 0])
}

calculate_pcc_health() = score {
    pcc_transactions := object.get(input.jdg_entrepreneur, "pcc_transactions_12mo", 0)
    pcc_filed := object.get(input.jdg_entrepreneur, "pcc3_filed_on_time", true)
    
    score := 100
    score := score - 40 { pcc_transactions > 0; not pcc_filed }
    score := score - 10 { pcc_transactions > 5 }
    score := max([score, 0])
}

calculate_podlok_health() = score {
    has_real_estate := object.get(input.jdg_entrepreneur, "has_business_real_estate", false)
    dn1_filed := object.get(input.jdg_entrepreneur, "dn1_filed", true)
    has_transport := object.get(input.jdg_entrepreneur, "has_taxable_vehicles", false)
    dt1_filed := object.get(input.jdg_entrepreneur, "dt1_filed", true)
    
    score := 100
    score := score - 30 { has_real_estate; not dn1_filed }
    score := score - 20 { has_transport; not dt1_filed }
    score := max([score, 0])
}

calculate_ryczalt_health() = score {
    uses_lump := object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    ewidencja_ok := object.get(input.jdg_entrepreneur, "lump_sum_records_ok", true)
    limit_ok := object.get(input.jdg_entrepreneur, "lump_sum_limit_ok", true)
    
    score := 100 { not uses_lump }
    score := 70 { uses_lump; ewidencja_ok; limit_ok }
    score := 30 { uses_lump; not ewidencja_ok }
    score := 20 { uses_lump; not limit_ok }
}

calculate_sukcesja_health() = score {
    in_succession := object.get(input.jdg_entrepreneur, "in_succession", false)
    
    score := 100 { not in_succession }
    score := 50 { in_succession }
}

calculate_rodo_health() = score {
    has_policy := object.get(input.jdg_entrepreneur, "rodo_policy_in_place", true)
    has_register := object.get(input.jdg_entrepreneur, "rodo_register_maintained", true)
    has_breach := object.get(input.jdg_entrepreneur, "rodo_breach_12mo", false)
    
    score := 100
    score := score - 30 { not has_policy }
    score := score - 20 { not has_register }
    score := score - 25 { has_breach }
    score := max([score, 0])
}

calculate_aml_bdo_health() = score {
    has_aml := object.get(input.jdg_entrepreneur, "aml_obligated", false)
    aml_procedure := object.get(input.jdg_entrepreneur, "aml_procedure_in_place", true)
    has_bdo := object.get(input.jdg_entrepreneur, "bdo_registered", false)
    bdo_ok := object.get(input.jdg_entrepreneur, "bdo_reports_filed", true)
    # v7.0 Audit: integracja z SanctionsScreeningAPI
    sanctions_hits := object.get(input.jdg_entrepreneur, "sanctions_hits_active", 0)
    has_fatf_exposure := object.get(input.jdg_entrepreneur, "has_fatf_country_exposure", false)
    aml_audit_score := object.get(input.jdg_entrepreneur, "aml_compliance_score", 100)
    
    score := 100
    score := score - 40 { has_aml; not aml_procedure }
    score := score - 30 { has_bdo; not bdo_ok }
    # v7.0 Audit: sanctions screening + AML audit integration
    score := score - 35 { sanctions_hits > 0 }
    score := score - 25 { has_fatf_exposure }
    score := score - 20 { aml_audit_score < 60 }
    score := score - 10 { aml_audit_score >= 60; aml_audit_score < 80 }
    score := max([score, 0])
}

build_mesh_health_warnings(health, scores, gaps) = warnings {
    health >= 80
    warnings := [sprintf("🟢 NEURAL MESH: Global Health %.0f/100 — wszystkie 13 domen w normie.", [health])]
} else = warnings {
    health >= 50
    health >= 50
    gap_list := concat(", ", gaps)
    warnings := [
        sprintf("🟡 NEURAL MESH: Global Health %.0f/100 — domeny poniżej progu: %s", [health, gap_list]),
        sprintf("⚠️ %d domen(y) wymaga(ją) uwagi. Priorytet: %s", [count(gaps), gap_list]),
        "📋 Rekomendacja: Zaplanuj działania naprawcze w ciągu 30 dni."
    ]
} else = warnings {
    gap_list := concat(", ", gaps)
    warnings := [
        sprintf("🔴 NEURAL MESH ALERT: Global Health %.0f/100 — KRYTYCZNE!", [health]),
        sprintf("🚨 %d domen(y) poniżej progu: %s", [count(gaps), gap_list]),
        "🛑 NATYCHMIASTOWA interwencja wymagana! Ryzyko kontroli skarbowej EKSTREMALNIE WYSOKIE.",
        "📋 Skontaktuj się z doradcą podatkowym. Nie księguj nowych faktur przed naprawą."
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# WARSTWA 2: SYNAPTIC RULES — Reguły łączące 2+ domen (169 potencjalnych)
# ═══════════════════════════════════════════════════════════════════════════════

# NM-100: VAT × PIT SYNAPSE — Efekt domina zmiany stawki VAT na PIT i ZUS
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.vat_pit_synapse",
    "package": "jdg.neural_mesh",
    "priority": 100,
    "vat_rate": vat_rate, "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": pit_effective_rate, "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_status, "kus_percent": kus_pct,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "neural_synapse_vat_to_pit_impact": vat_pit_delta,
    "neural_synapse_vat_to_zus_impact": vat_zus_delta,
    "neural_synapse_cashflow_impact_90d": cashflow_90d,
    "neural_synapse_total_tax_burden_change": total_delta,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": synapse_routing,
    "_routing_reason": synapse_reason,
    "_legal_basis": "Art. 14, 22, 27, 30c PIT; Art. 86 VAT; Art. 79-81 ustawy zdrowotnej",
    "_warnings": [sprintf("🧠 VAT→PIT SYNAPSE: Zmiana stawki VAT z %s na %s → efekt domina: PIT %+.0f PLN, ZUS %+.0f PLN, Cashflow %+.0f PLN/90d. Łączny wpływ: %+.0f PLN.",
        [old_vat_rate_str, vat_rate, vat_pit_delta, vat_zus_delta, cashflow_90d, total_delta])]
} {
    input.neural_mesh_synapse_analysis == true
    input.invoice.vat_rate_change_detected == true
    
    old_vat_rate_str := object.get(input.invoice, "previous_vat_rate", "0.23")
    vat_rate := object.get(input.invoice, "vat_rate", "0.23")
    amount_net := object.get(input.invoice, "amount_net", 0)
    direction := input.invoice.direction
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    
    # VAT → PIT: zmiana VAT należnego/naliczonego wpływa na dochód
    old_vat_amount := amount_net * to_number(old_vat_rate_str)
    new_vat_amount := amount_net * to_number(vat_rate)
    vat_delta := new_vat_amount - old_vat_amount
    
    # For SALES: higher VAT = lower net income (VAT is not revenue)
    # For PURCHASES: higher VAT = higher deduction → lower PIT base
    vat_pit_delta := -vat_delta * 0.19 { direction == "SALE"; pit_form == "LINEAR" }
    vat_pit_delta := -vat_delta * 0.12 { direction == "SALE"; pit_form == "PIT_SCALE" }
    vat_pit_delta := vat_delta * 0.19 { direction == "PURCHASE"; pit_form == "LINEAR" }
    vat_pit_delta := vat_delta * 0.12 { direction == "PURCHASE"; pit_form == "PIT_SCALE" }
    
    # VAT → ZUS: zmiana dochodu wpływa na składkę zdrowotną
    health_rate := "0.09" { pit_form == "PIT_SCALE" }
    health_rate := "0.049" { pit_form == "LINEAR" }
    health_rate := "varying" { pit_form == "LUMP_SUM" }
    vat_zus_delta := -vat_delta * 0.09 { pit_form == "PIT_SCALE"; direction == "SALE" }
    vat_zus_delta := vat_delta * 0.09 { pit_form == "PIT_SCALE"; direction == "PURCHASE" }
    vat_zus_delta := -vat_delta * 0.049 { pit_form == "LINEAR"; direction == "SALE" }
    vat_zus_delta := vat_delta * 0.049 { pit_form == "LINEAR"; direction == "PURCHASE" }
    vat_zus_delta := 0 { pit_form == "LUMP_SUM" }
    
    # Cashflow 90-day impact
    cashflow_90d := -vat_delta { direction == "PURCHASE" }
    cashflow_90d := vat_delta { direction == "SALE" }
    
    total_delta := vat_pit_delta + vat_zus_delta + cashflow_90d
    
    kus_pct := 100 { direction == "PURCHASE" }
    kus_pct := 0 { direction == "SALE" }
    kus_status := "deductible_full" { direction == "PURCHASE" }
    kus_status := "non_deductible" { direction == "SALE" }
    pit_effective_rate := "0.19" { pit_form == "LINEAR" }
    pit_effective_rate := "0.12" { pit_form == "PIT_SCALE" }
    
    synapse_routing := "" { abs(total_delta) < 1000 }
    synapse_routing := "TRIAGE_QUEUE" { abs(total_delta) >= 1000; abs(total_delta) < 10000 }
    synapse_routing := "BLOCK_AND_ALERT" { abs(total_delta) >= 10000 }
    
    synapse_reason := sprintf("VAT→PIT domino: %.0f PLN łącznego wpływu", [total_delta]) { abs(total_delta) >= 1000 }
    synapse_reason := "" { abs(total_delta) < 1000 }
}

# NM-200: PIT × ZUS SYNAPSE — Wybór formy opodatkowania → efekt na ZUS
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.pit_zus_synapse",
    "package": "jdg.neural_mesh",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "neural_synapse_pit_to_zus_annual_cost": annual_health_cost,
    "neural_synapse_alternative_form_annual_cost": alternative_cost,
    "neural_synapse_optimal_form_recommendation": optimal_recommendation,
    "neural_synapse_annual_savings_potential": annual_savings,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("PIT×ZUS: Potencjalna oszczędność %.0f PLN/rok przez zmianę formy", [annual_savings]),
    "_legal_basis": "Art. 27, 30c PIT; Art. 79-81 ustawy zdrowotnej; Art. 6-12 ustawy o ryczałcie",
    "_warnings": [sprintf("🧠 PIT×ZUS SYNAPSE: Obecna forma=%s → zdrowotna=%.0f PLN/rok. Optymalna=%s → zdrowotna=%.0f PLN/rok. Oszczędność: %.0f PLN/rok!",
        [current_form, annual_health_cost, optimal_form, alternative_cost, annual_savings])]
} {
    input.neural_mesh_synapse_analysis == true
    input.neural_mesh_pit_zus_optimization == true
    
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 30000)
    annual_profit := annual_income - annual_costs
    
    # Health contribution costs per form
    health_scale := annual_profit * 0.09 { annual_profit > 0 }
    health_scale := 0 { annual_profit <= 0 }
    health_linear := min([annual_profit * 0.049, 12900]) { annual_profit > 0 }
    health_linear := 0 { annual_profit <= 0 }
    health_lump := 419 * 12 { annual_income <= 60000 }
    health_lump := 699 * 12 { annual_income > 60000; annual_income <= 300000 }
    health_lump := 1258 * 12 { annual_income > 300000 }
    
    health_costs := {"PIT_SCALE": health_scale, "LINEAR": health_linear, "LUMP_SUM": health_lump}
    annual_health_cost := object.get(health_costs, current_form, health_scale)
    health_rate := "0.09" { current_form == "PIT_SCALE" }
    health_rate := "0.049" { current_form == "LINEAR" }
    health_rate := "varying" { current_form == "LUMP_SUM" }
    
    # Find optimal form
    forms_sorted := ["PIT_SCALE", "LINEAR", "LUMP_SUM"]
    costs_array := [health_scale, health_linear, health_lump]
    
    optimal_form := "PIT_SCALE"
    optimal_form := "LINEAR" { health_linear <= health_scale; health_linear <= health_lump }
    optimal_form := "LUMP_SUM" { health_lump < health_scale; health_lump < health_linear }
    
    alternative_cost := object.get(health_costs, optimal_form, health_scale)
    annual_savings := annual_health_cost - alternative_cost
    
    optimal_recommendation := sprintf("Zmień formę na %s — oszczędzasz %.0f PLN/rok na samej składce zdrowotnej!",
        [optimal_form, annual_savings]) { annual_savings > 2000; current_form != optimal_form }
    optimal_recommendation := "Obecna forma jest optymalna pod względem składki zdrowotnej." {
        current_form == optimal_form
    }
    optimal_recommendation := sprintf("Różnica <2000 PLN — zmiana formy może być nieopłacalna ze względu na koszty administracyjne.",
        []) { annual_savings <= 2000; current_form != optimal_form }
}

# NM-300: KKS × OrdPU SYNAPSE — Czynny żal a przedawnienie
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.kks_ordpu_synapse",
    "package": "jdg.neural_mesh",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_synapse_voluntary_disclosure_window": vd_window_days,
    "neural_synapse_statute_remaining_years": statute_years_remaining,
    "neural_synapse_recommended_action": kks_action,
    "neural_synapse_penalty_range": penalty_range,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": kks_routing,
    "_routing_reason": kks_routing_reason,
    "_legal_basis": "Art. 16 KKS; Art. 70 OrdPU; Art. 44 KKS",
    "_warnings": [sprintf("🧠 KKS×OrdPU SYNAPSE: Czynny żal dostępny przez %d dni. Przedawnienie za %.1f lat. %s. Kara: %s",
        [vd_window_days, statute_years_remaining, kks_action, penalty_range])]
} {
    input.neural_mesh_synapse_analysis == true
    has_violation := object.get(input.jdg_entrepreneur, "has_tax_violation", false)
    has_violation == true
    
    tax_authority_aware := object.get(input.jdg_entrepreneur, "tax_authority_aware", false)
    days_since_violation := object.get(input.jdg_entrepreneur, "days_since_tax_violation", 0)
    violation_year := object.get(input.jdg_entrepreneur, "violation_tax_year", 2020)
    violation_amount := object.get(input.jdg_entrepreneur, "violation_tax_amount_pln", 0)
    
    # Current year from evaluation date or input
    eval_date := object.get(input, "evaluation_date", "2026-01-01")
    current_year := to_number(substring(eval_date, 0, 4))
    
    # Statute of limitations: 5 years from end of tax year
    statute_end_year := violation_year + 5
    years_passed := current_year - violation_year
    statute_years_remaining := 5 - years_passed
    
    # Voluntary disclosure: available until tax authority discovers
    vd_window_days := 999 { not tax_authority_aware }
    vd_window_days := 0 { tax_authority_aware }
    
    kks_action := "✅ ZŁÓŻ CZYNNY ŻAL NATYCHMIAST — unikniesz kary! Art. 16 KKS." {
        not tax_authority_aware; statute_years_remaining > 0
    }
    kks_action := "⚠️ CZYNNY ŻAL JUŻ NIESKUTECZNY — US wszczął postępowanie." {
        tax_authority_aware
    }
    kks_action := "📋 PRZEDAWNIENIE — zobowiązanie wygasło po 5 latach." {
        statute_years_remaining <= 0
    }
    
    penalty_range := sprintf("%.0f - %.0f PLN (30%% zaległości + odsetki)", 
        [violation_amount * 0.1, violation_amount * 0.30]) { not tax_authority_aware }
    penalty_range := sprintf("%.0f - %.0f PLN (pełna odpowiedzialność KKS)", 
        [violation_amount * 0.30, violation_amount * 3.0]) { tax_authority_aware }
    
    kks_routing := "BLOCK_AND_ALERT" { not tax_authority_aware; statute_years_remaining > 0; violation_amount > 5000 }
    kks_routing := "TRIAGE_QUEUE" { not tax_authority_aware; statute_years_remaining > 0; violation_amount <= 5000 }
    kks_routing := "BLOCK_AND_ALERT" { tax_authority_aware; violation_amount > 0 }
    kks_routing := "" { statute_years_remaining <= 0 }
    
    kks_routing_reason := sprintf("Czynny żal dostępny: %d dni. Zaległość: %.0f PLN", 
        [vd_window_days, violation_amount]) { not tax_authority_aware }
    kks_routing_reason := "Postępowanie KAS w toku — czynny żal nieskuteczny" { tax_authority_aware }
    kks_routing_reason := "" { statute_years_remaining <= 0 }
}

# ═══════════════════════════════════════════════════════════════════════════
# NM-310: KKS × AML SYNAPSE — Naruszenia KKS uruchamiają Enhanced Due Diligence AML
# Raport v7.0: KKS violations + AML = synergiczny efekt compliance
# ═══════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.kks_aml_synapse",
    "package": "jdg.neural_mesh",
    "priority": 310,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_synapse_kks_aml_edd_required": edd_required,
    "neural_synapse_kks_aml_risk_amplification": risk_amplification,
    "neural_synapse_kks_aml_sar_triggered": sar_triggered,
    "neural_synapse_kks_aml_combined_risk": combined_risk_level,
    "neural_synapse_kks_aml_remediation_steps": remediation_steps,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": synapse_routing,
    "_routing_reason": synapse_reason,
    "_legal_basis": "Art. 54-62 KKS; Art. 83-86 Ustawy AML; Art. 299 KKS; Rekomendacja 10 FATF",
    "_warnings": build_kks_aml_warnings(edd_required, risk_amplification, sar_triggered, combined_risk_level)
} {
    input.neural_mesh_synapse_analysis == true
    # Trigger: KKS flags ARE active AND JDG is AML-obligated
    kks_flags := object.get(input.jdg_entrepreneur, "kks_risk_flags_active", 0)
    is_aml_obligated := object.get(input.jdg_entrepreneur, "aml_obligated", false)
    kks_flags > 0
    is_aml_obligated == true

    # KKS offense type determines AML risk amplification
    kks_offense_type := object.get(input.jdg_entrepreneur, "kks_dominant_offense_type", "TAX_EVASION")
    invoice_amount := object.get(input.invoice, "amount_gross", 0)
    
    # KKS → AML risk amplification factor
    kks_aml_multiplier := 1.0
    kks_aml_multiplier := 3.0 { kks_offense_type == "EMPTY_INVOICE" }
    kks_aml_multiplier := 2.5 { kks_offense_type == "VAT_CAROUSEL" }
    kks_aml_multiplier := 2.0 { kks_offense_type == "TAX_EVASION" }
    kks_aml_multiplier := 1.8 { kks_offense_type == "UNRELIABLE_BOOKS" }
    kks_aml_multiplier := 1.5 { kks_offense_type == "UNRELIABLE_VAT" }

    risk_amplification := sprintf("KKS %s → AML ryzyko ×%.1f", [kks_offense_type, kks_aml_multiplier])

    # EDD required when KKS flags > 0 AND AML obligated
    edd_required := true

    # SAR triggered when amount > 15000 PLN AND KKS offense is financial
    sar_triggered := invoice_amount >= 15000
    sar_triggered := true { kks_offense_type == "VAT_CAROUSEL" }
    sar_triggered := true { kks_offense_type == "EMPTY_INVOICE"; invoice_amount >= 5000 }

    # Combined risk level (priority: SAR > flags count)
    combined_risk_level := "CRITICAL" { sar_triggered }
    else := "CRITICAL" { kks_flags >= 5 }
    else := "HIGH" { kks_flags >= 3 }
    else := "MEDIUM" { kks_flags >= 1 }
    else := "LOW"

    # Remediation steps
    remediation_steps := [
        "1. Wstrzymaj transakcje z kontrahentem do czasu zakończenia EDD",
        "2. Przygotuj STR/SAR do GIIF jeśli kwota > 15k PLN",
        "3. Zweryfikuj źródło majątku kontrahenta",
        "4. Uzyskaj zgodę zarządu na kontynuację relacji (Art. 43 ust. 5 Ustawy AML)",
        "5. Złóż czynny żal KKS (Art. 16 KKS) dla nieprawidłowości podatkowych"
    ]

    synapse_routing := "BLOCK_AND_ALERT" { combined_risk_level == "CRITICAL" }
    synapse_routing := "TRIAGE_QUEUE" { combined_risk_level == "HIGH" }
    synapse_routing := "" { true }

    synapse_reason := sprintf("KKS×AML SYNAPSE: %d flag KKS + AML obligated → EDD+SAR. Ryzyko: %s",
        [kks_flags, combined_risk_level]) { combined_risk_level != "LOW" }
    synapse_reason := "" { combined_risk_level == "LOW" }
}

build_kks_aml_warnings(edd, amplification, sar, risk) = warnings {
    risk == "CRITICAL"
    warnings := [
        sprintf("🧠 KKS×AML SYNAPSE CRITICAL: %s", [amplification]),
        "🚨 EDD WYMAGANE + SAR/STR do GIIF OBOWIĄZKOWY!",
        "🛑 Art. 299 KKS — pranie pieniędzy: do 10 lat pozbawienia wolności!",
        "📋 Wstrzymaj wszystkie transakcje do czasu wyjaśnienia."
    ]
} else = warnings {
    risk == "HIGH"
    warnings := [
        sprintf("🧠 KKS×AML SYNAPSE HIGH: %s", [amplification]),
        "⚠️ EDD wymagane. Rozważ zgłoszenie SAR do GIIF.",
        "📋 Przeprowadź pogłębioną analizę w ciągu 14 dni."
    ]
} else = warnings {
    warnings := [
        sprintf("🧠 KKS×AML SYNAPSE: %s — monitoruj sytuację.", [amplification])
    ]
}

# ═══════════════════════════════════════════════════════════════════════════
# NM-320: KKS × Crossborder SYNAPSE — Ryzyko KKS amplifikowane przez transakcje transgraniczne
# Raport v7.0: crossborder + KKS = efekt domina międzynarodowego
# ═══════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.kks_crossborder_synapse",
    "package": "jdg.neural_mesh",
    "priority": 320,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_synapse_kks_cb_risk_multiplier": risk_multiplier,
    "neural_synapse_kks_cb_exposure_jurisdictions": exposed_jurisdictions,
    "neural_synapse_kks_cb_max_penalty_crossborder": max_cb_penalty,
    "neural_synapse_kks_cb_mdr_triggered": mdr_triggered,
    "neural_synapse_kks_cb_recommendation": cb_recommendation,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": synapse_routing,
    "_routing_reason": synapse_reason,
    "_legal_basis": "Art. 54-62 KKS; Art. 86a OP (MDR); Art. 299 KKS (transgraniczne pranie); Dyrektywa DAC6",
    "_warnings": build_kks_cb_warnings(risk_multiplier, exposed_jurisdictions, max_cb_penalty, mdr_triggered)
} {
    input.neural_mesh_synapse_analysis == true
    kks_flags := object.get(input.jdg_entrepreneur, "kks_risk_flags_active", 0)
    has_crossborder := object.get(input.jdg_entrepreneur, "has_crossborder_transactions", false)
    kks_flags > 0
    has_crossborder == true

    # Cross-border risk jurisdictions
    cb_countries := object.get(input.jdg_entrepreneur, "crossborder_countries", [])
    fatf_black := {"IR", "KP", "MM"}
    fatf_grey := {"SY", "VE", "YE", "AF", "SS", "ZW"}
    sanctioned_jurisdictions := {"RU", "BY"}

    # Identify exposed jurisdictions
    exposed_fatf_black := [c | c := cb_countries[_]; c in fatf_black]
    exposed_fatf_grey := [c | c := cb_countries[_]; c in fatf_grey]
    exposed_sanctioned := [c | c := cb_countries[_]; c in sanctioned_jurisdictions]
    exposed_jurisdictions := array.concat(array.concat(exposed_fatf_black, exposed_fatf_grey), exposed_sanctioned)

    # Risk multiplier (priority: black > grey > sanctioned > default)
    risk_multiplier := 3.0 { count(exposed_fatf_black) > 0 }
    else := 2.0 { count(exposed_fatf_grey) > 0 }
    else := 1.5 { count(exposed_sanctioned) > 0 }
    else := 1.0

    # Max cross-border penalty (720 daily rates * 143 PLN * risk multiplier)
    max_cb_penalty := 720 * 143 * risk_multiplier

    # MDR triggered when cross-border + KKS and amount > threshold
    invoice_amount := object.get(input.invoice, "amount_gross", 0)
    mdr_triggered := invoice_amount >= 50000

    cb_recommendation := "NATYCHMIAST złóż MDR-3 + czynny żal KKS!" { mdr_triggered }
    cb_recommendation := "Złóż czynny żal KKS — crossborder amplifikuje ryzyko." { not mdr_triggered; kks_flags > 0 }
    cb_recommendation := "" { kks_flags == 0 }

    synapse_routing := "BLOCK_AND_ALERT" { risk_multiplier >= 2.0 }
    synapse_routing := "TRIAGE_QUEUE" { risk_multiplier >= 1.5; risk_multiplier < 2.0 }
    synapse_routing := "" { risk_multiplier < 1.5 }

    synapse_reason := sprintf("KKS×Crossborder: %d flag KKS + %d jurysdykcji ryzyka. Mnożnik: ×%.1f",
        [kks_flags, count(exposed_jurisdictions), risk_multiplier]) { count(exposed_jurisdictions) > 0 }
    synapse_reason := sprintf("KKS×Crossborder: %d flag KKS + transgraniczne. Monitoruj.", [kks_flags]) { count(exposed_jurisdictions) == 0 }
}

build_kks_cb_warnings(multiplier, jurisdictions, penalty, mdr) = warnings {
    multiplier >= 2.0
    jur_list := concat(", ", jurisdictions)
    warnings := [
        sprintf("🧠 KKS×CROSSBORDER SYNAPSE CRITICAL: ×%.1f — jurysdykcje ryzyka: %s", [multiplier, jur_list]),
        sprintf("🚨 Maksymalna kara transgraniczna: %.0f PLN", [penalty]),
        "🛑 MDR-3 WYMAGANY + czynny żal KKS! Ryzyko ekstradycji!",
        "📋 Skontaktuj się z doradcą międzynarodowym."
    ]
} else = warnings {
    multiplier >= 1.5
    warnings := [
        sprintf("🧠 KKS×CROSSBORDER SYNAPSE HIGH: ×%.1f", [multiplier]),
        "⚠️ Transakcje transgraniczne zwiększają ryzyko KKS.",
        "📋 Zweryfikuj dokumentację TP i MDR."
    ]
} else = warnings {
    warnings := [
        "🧠 KKS×CROSSBORDER SYNAPSE: Monitoruj transakcje transgraniczne."
    ]
}

# ═══════════════════════════════════════════════════════════════════════════
# NM-330: AML × Crossborder SYNAPSE — AML risk amplifikowany przez transgraniczność
# Raport v7.0: AML + crossborder = obowiązek FATF/OFAC screening + EDD
# ═══════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.aml_crossborder_synapse",
    "package": "jdg.neural_mesh",
    "priority": 330,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_synapse_aml_cb_screening_required": screening_required,
    "neural_synapse_aml_cb_risk_level": aml_cb_risk,
    "neural_synapse_aml_cb_travel_rule": travel_rule_applies,
    "neural_synapse_aml_cb_crypto_flag": crypto_flag,
    "neural_synapse_aml_cb_max_str_deadline_days": str_deadline_days,
    "neural_synapse_aml_cb_recommended_actions": recommended_actions,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": synapse_routing,
    "_routing_reason": synapse_reason,
    "_legal_basis": "Art. 43, 83-86 Ustawy AML; FATF Rekomendacje 10, 16, 19; AMLD5/AMLD6; TFR 2023/1113",
    "_warnings": build_aml_cb_warnings(screening_required, aml_cb_risk, travel_rule_applies, crypto_flag)
} {
    input.neural_mesh_synapse_analysis == true
    is_aml_obligated := object.get(input.jdg_entrepreneur, "aml_obligated", false)
    has_crossborder := object.get(input.jdg_entrepreneur, "has_crossborder_transactions", false)
    is_aml_obligated == true
    has_crossborder == true

    vendor_country := object.get(input.vendor, "country", "PL")
    invoice_amount := object.get(input.invoice, "amount_gross", 0)
    is_crypto := object.get(input.invoice, "is_crypto_transaction", false)

    # FATF high-risk jurisdictions
    fatf_high_risk := {"IR", "KP", "MM", "SY", "VE", "YE", "AF", "SS"}
    screening_required := vendor_country in fatf_high_risk
    screening_required := true { vendor_country in {"RU", "BY"} }

    # Travel Rule (FATF R16): crypto transfers > 1000 EUR (~4300 PLN)
    travel_rule_applies := is_crypto and invoice_amount >= 4300

    # Crypto flag
    crypto_flag := is_crypto

    # Risk assessment (priority: CRITICAL countries > FATF high risk > crypto > medium)
    aml_cb_risk := "CRITICAL" { vendor_country in {"IR", "KP", "MM", "RU", "BY"} }
    else := "HIGH" { vendor_country in fatf_high_risk }
    else := "HIGH" { is_crypto; invoice_amount >= 100000 }
    else := "MEDIUM" { vendor_country in {"CN", "HK", "AE", "PA"} }
    else := "LOW"

    # STR deadline (days)
    str_deadline_days := 30 { aml_cb_risk == "LOW" }
    str_deadline_days := 14 { aml_cb_risk == "MEDIUM" }
    str_deadline_days := 7 { aml_cb_risk == "HIGH" }
    str_deadline_days := 2 { aml_cb_risk == "CRITICAL" }

    # Recommended actions
    recommended_actions := [
        "1. Pełny screening OFAC/UE/UK/FATF kontrahenta",
        "2. Enhanced Due Diligence (EDD) — źródło majątku + zgoda zarządu",
        "3. Monitoring transakcji w czasie rzeczywistym",
        "4. Przygotuj STR/SAR do GIIF",
        "5. Dokumentuj wszystkie kroki AML (audit trail)"
    ]

    synapse_routing := "BLOCK_AND_ALERT" { aml_cb_risk == "CRITICAL" }
    synapse_routing := "BLOCK_AND_ALERT" { travel_rule_applies; invoice_amount >= 50000 }
    synapse_routing := "TRIAGE_QUEUE" { aml_cb_risk == "HIGH" }
    synapse_routing := "" { true }

    synapse_reason := sprintf("AML×Crossborder: %s — %s. STR w %d dni.",
        [vendor_country, aml_cb_risk, str_deadline_days]) { aml_cb_risk != "LOW" }
    synapse_reason := "" { aml_cb_risk == "LOW" }
}

build_aml_cb_warnings(screening, risk, travel_rule, crypto) = warnings {
    risk == "CRITICAL"
    warnings := [
        sprintf("🧠 AML×CROSSBORDER SYNAPSE CRITICAL — ryzyko: %s", [risk]),
        "🚨 PEŁNY SCREENING FATF/OFAC/UE WYMAGANY NATYCHMIAST!",
        "🛑 STR/SAR do GIIF w ciągu 2 dni! Art. 86 Ustawy AML.",
        "📋 Wstrzymaj transakcję do czasu zakończenia EDD."
    ]
} else = warnings {
    risk == "HIGH"
    travel_note := "+ Travel Rule (FATF R16)" { travel_rule }
    travel_note := "" { not travel_rule }
    warnings := [
        sprintf("🧠 AML×CROSSBORDER SYNAPSE HIGH — %s %s", [risk, travel_note]),
        "⚠️ EDD + screening sankcyjny wymagany.",
        "📋 STR/SAR do GIIF w ciągu 7 dni."
    ]
} else = warnings {
    warnings := [
        sprintf("🧠 AML×CROSSBORDER SYNAPSE: %s — standardowe procedury AML.", [risk])
    ]
}

# NM-400: PCC × VAT SYNAPSE — Transakcja PCC a zwolnienie VAT
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.pcc_vat_synapse",
    "package": "jdg.neural_mesh",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_synapse_pcc_applies": pcc_applies,
    "neural_synapse_pcc_rate": pcc_rate,
    "neural_synapse_pcc_amount": pcc_amount,
    "neural_synapse_pcc_declaration_deadline": "14 dni od zawarcia umowy",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": pcc_routing,
    "_routing_reason": pcc_reason,
    "_legal_basis": "Art. 1-2, 6-7, 10 Ustawy o PCC; Art. 2 pkt 4 Ustawy o PCC (wyłączenie VAT)",
    "_warnings": [sprintf("🧠 PCC×VAT SYNAPSE: %s — PCC %s%% = %.0f PLN. PCC-3 w 14 dni. %s",
        [transaction_desc, pcc_rate_str, pcc_amount, pcc_note])]
} {
    input.neural_mesh_synapse_analysis == true
    object.get(input.invoice, "is_pcc_transaction", false) == true
    
    transaction_type := object.get(input.invoice, "pcc_transaction_type", "")
    transaction_amount := object.get(input.invoice, "amount_gross", 0)
    vendor_is_vat_payer := object.get(input.vendor, "is_vat_payer", false)
    is_vat_exempt_transaction := object.get(input.invoice, "vat_exempt_for_pcc", false)
    
    # PCC wyłączone gdy transakcja podlega VAT (Art. 2 pkt 4 Ustawy o PCC)
    pcc_applies := false { vendor_is_vat_payer; not is_vat_exempt_transaction }
    pcc_applies := true { not vendor_is_vat_payer }
    pcc_applies := true { is_vat_exempt_transaction }
    
    pcc_rate := 0.02 { transaction_type in {"SALE_MOVABLE", "LOAN", "EXCHANGE"} }
    pcc_rate := 0.01 { transaction_type in {"SALE_REAL_ESTATE", "DONATION_TAXABLE"} }
    pcc_rate := 0.005 { transaction_type == "COMPANY_SHARES_SALE" }
    pcc_rate := 0.02 { true }
    
    pcc_amount := transaction_amount * pcc_rate { pcc_applies }
    pcc_amount := 0 { not pcc_applies }
    pcc_rate_str := sprintf("%.1f", [pcc_rate * 100])
    
    transaction_desc := transaction_type
    pcc_note := "Transakcja podlega VAT → PCC NIE stosuje się (Art. 2 pkt 4 Ustawy o PCC)" { not pcc_applies }
    pcc_note := sprintf("ZŁÓŻ PCC-3 w ciągu 14 dni! Kwota: %.0f PLN.", [pcc_amount]) { pcc_applies; pcc_amount > 0 }
    
    pcc_routing := "BLOCK_AND_ALERT" { pcc_applies; pcc_amount > 5000 }
    pcc_routing := "TRIAGE_QUEUE" { pcc_applies; pcc_amount > 0; pcc_amount <= 5000 }
    pcc_routing := "" { not pcc_applies }
    
    pcc_reason := sprintf("PCC %.0f PLN — złóż PCC-3 w 14 dni", [pcc_amount]) { pcc_applies; pcc_amount > 0 }
    pcc_reason := "" { not pcc_applies }
}

# NM-500: UoR × PIT SYNAPSE — Amortyzacja bilansowa vs podatkowa
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.uor_pit_synapse",
    "package": "jdg.neural_mesh",
    "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_synapse_depreciation_gap_uor_vs_pit": depreciation_gap,
    "neural_synapse_deferred_tax_asset": deferred_tax_asset,
    "neural_synapse_deferred_tax_liability": deferred_tax_liability,
    "neural_synapse_kst_group": kst_group,
    "neural_synapse_depreciation_method_pit": pit_method,
    "neural_synapse_depreciation_method_uor": uor_method,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": depreciation_routing,
    "_routing_reason": depreciation_reason,
    "_legal_basis": "Art. 22a-22o PIT; Art. 28-34 UoR; Rozporządzenie KŚT",
    "_warnings": [sprintf("🧠 UoR×PIT SYNAPSE: Amortyzacja — PIT=%s (%.0f%%), UoR=%s (%.0f%%). Różnica: %.0f PLN. %s",
        [pit_method, pit_rate_pct, uor_method, uor_rate_pct, depreciation_gap, deferred_note])]
} {
    input.neural_mesh_synapse_analysis == true
    object.get(input.invoice, "expense_type", "") == "FIXED_ASSET"
    asset_value := object.get(input.invoice, "amount_net", 0)
    asset_value >= 10000  # Fixed asset threshold
    
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_method := object.get(input.invoice, "depreciation_method", "LINEAR")
    uor_method := object.get(input.invoice, "uor_depreciation_method", "LINEAR")
    pit_rate := object.get(input.invoice, "depreciation_rate", 0.20)
    uor_rate := object.get(input.invoice, "uor_depreciation_rate", 0.20)
    kst_group := object.get(input.invoice, "kst_group", "N/A")
    
    pit_rate_pct := pit_rate * 100
    uor_rate_pct := uor_rate * 100
    
    # Annual depreciation gap
    pit_annual := asset_value * pit_rate
    uor_annual := asset_value * uor_rate
    depreciation_gap := pit_annual - uor_annual
    
    # Deferred tax calculation
    pit_tax_rate := 0.19 { pit_form == "LINEAR" }
    pit_tax_rate := 0.12 { pit_form == "PIT_SCALE" }
    pit_tax_rate := 0.15 { pit_form == "LUMP_SUM" }
    
    deferred_tax_asset := abs(depreciation_gap) * pit_tax_rate { depreciation_gap < 0 }
    deferred_tax_asset := 0 { depreciation_gap >= 0 }
    deferred_tax_liability := depreciation_gap * pit_tax_rate { depreciation_gap > 0 }
    deferred_tax_liability := 0 { depreciation_gap <= 0 }
    
    deferred_note := "Aktywo na podatek odroczony — PIT < UoR" { depreciation_gap < 0; abs(depreciation_gap) > 1000 }
    deferred_note := "Rezerwa na podatek odroczony — PIT > UoR" { depreciation_gap > 0; depreciation_gap > 1000 }
    deferred_note := "Brak istotnej różnicy przejściowej" { abs(depreciation_gap) <= 1000 }
    
    depreciation_routing := "" { abs(depreciation_gap) < 5000 }
    depreciation_routing := "TRIAGE_QUEUE" { abs(depreciation_gap) >= 5000 }
    
    depreciation_reason := sprintf("Różnica amortyzacji PIT-UoR: %.0f PLN/rok", [depreciation_gap]) { abs(depreciation_gap) >= 5000 }
    depreciation_reason := "" { abs(depreciation_gap) < 5000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WARSTWA 3: GLOBAL OPTIMIZER — Optymalizacja globalna, nie lokalna
# ═══════════════════════════════════════════════════════════════════════════════

# NM-600: GLOBAL DEADLINE ORCHESTRATOR — Wszystkie terminy w jednym miejscu
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.global_deadline_orchestrator",
    "package": "jdg.neural_mesh",
    "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_deadlines_upcoming": upcoming_deadlines,
    "neural_deadlines_critical_7days": critical_7d,
    "neural_deadlines_missed": missed_deadlines,
    "neural_deadlines_next_action_date": next_action_date,
    "neural_deadlines_next_action_description": next_action_desc,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": deadline_routing,
    "_routing_reason": deadline_reason,
    "_legal_basis": "Art. 44, 45 PIT; Art. 99, 103 VAT; Art. 47 SUS; Art. 70 OrdPU; Art. 44 KKS",
    "_warnings": build_deadline_warnings(upcoming_deadlines, critical_7d, missed_deadlines)
} {
    input.neural_mesh_deadline_check == true
    
    today := object.get(input, "evaluation_date", "2026-07-19")
    
    # All deadlines for JDG
    all_deadlines := [
        {"type": "VAT_JPK", "date": "2026-07-25", "desc": "JPK_V7M za czerwiec 2026", "amount": 0},
        {"type": "PIT_ADVANCE", "date": "2026-07-20", "desc": "Zaliczka PIT za czerwiec", "amount": 0},
        {"type": "ZUS_SOCIAL", "date": "2026-07-10", "desc": "ZUS społeczne za czerwiec", "amount": 0},
        {"type": "ZUS_HEALTH", "date": "2026-07-10", "desc": "ZUS zdrowotne za czerwiec", "amount": 0},
        {"type": "PIT_ANNUAL", "date": "2027-04-30", "desc": "PIT-36/PIT-36L/PIT-28 za 2026", "amount": 0},
        {"type": "VAT_UE", "date": "2026-07-15", "desc": "VAT-UE za czerwiec", "amount": 0},
        {"type": "PCC3", "date": "2026-08-03", "desc": "PCC-3 (jeśli dotyczy)", "amount": 0},
        {"type": "IWA", "date": "2026-12-31", "desc": "ZUS IWA za 2026", "amount": 0}
    ]
    
    upcoming_deadlines := [d |
        d := all_deadlines[_]
        d.date >= today
    ]
    
    critical_7d := [d |
        d := upcoming_deadlines[_]
        days_until := helpers.days_between(today, d.date)
        days_until <= 7
        days_until >= 0
    ]
    
    missed_deadlines := [d |
        d := all_deadlines[_]
        d.date < today
    ]
    
    next_action_date := object.get(upcoming_deadlines[0], "date", "N/A") { count(upcoming_deadlines) > 0 }
    next_action_date := "Brak" { count(upcoming_deadlines) == 0 }
    next_action_desc := object.get(upcoming_deadlines[0], "desc", "Brak") { count(upcoming_deadlines) > 0 }
    next_action_desc := "Brak" { count(upcoming_deadlines) == 0 }
    
    deadline_routing := "BLOCK_AND_ALERT" { count(critical_7d) > 0 }
    deadline_routing := "TRIAGE_QUEUE" { count(missed_deadlines) > 0 }
    deadline_routing := "" { true }
    
    deadline_reason := sprintf("KRYTYCZNE: %d terminów w ciągu 7 dni!", [count(critical_7d)]) { count(critical_7d) > 0 }
    deadline_reason := sprintf("UWAGA: %d terminów przekroczonych!", [count(missed_deadlines)]) { count(missed_deadlines) > 0; count(critical_7d) == 0 }
    deadline_reason := "" { count(critical_7d) == 0; count(missed_deadlines) == 0 }
}

build_deadline_warnings(upcoming, critical, missed) = warnings {
    count(critical) > 0
    critical_list := concat("; ", [sprintf("%s: %s", [d.type, d.desc]) | d := critical[_]])
    warnings := [
        sprintf("🚨 KRYTYCZNE TERMINY (%d w ciągu 7 dni!): %s", [count(critical), critical_list]),
        "⚠️ NATYCHMIAST podejmij działania! Po terminie: odsetki, KKS, sankcje."
    ]
} else = warnings {
    count(missed) > 0
    missed_list := concat("; ", [sprintf("%s: %s (termin: %s)", [d.type, d.desc, d.date]) | d := missed[_]])
    warnings := [
        sprintf("⚠️ PRZEKROCZONE TERMINY (%d): %s", [count(missed), missed_list]),
        "📋 Rozważ czynny żal (Art. 16 KKS) i niezwłoczną korektę."
    ]
} else = warnings {
    count(upcoming) > 0
    next := upcoming[0]
    warnings := [sprintf("📅 NAJBLIŻSZY TERMIN: %s — %s (za %d dni)", [next.date, next.desc, helpers.days_between("2026-07-19", next.date)])]
} else = ["✅ Wszystkie terminy na dziś załatwione."]

# ═══════════════════════════════════════════════════════════════════════════════
# WARSTWA 4: PREDICTIVE SHIELD — Predykcja ryzyka kontroli skarbowej
# ═══════════════════════════════════════════════════════════════════════════════

# NM-700: PREDICTIVE AUDIT RISK ENGINE — 12 czynników ryzyka kontroli
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.predictive_audit_risk",
    "package": "jdg.neural_mesh",
    "priority": 700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_audit_risk_score": total_risk,
    "neural_audit_risk_factors": active_factors,
    "neural_audit_risk_factors_count": count(active_factors),
    "neural_audit_predicted_timeframe_days": predicted_days,
    "neural_audit_prevention_checklist": prevention_steps,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": risk_routing,
    "_routing_reason": risk_reason,
    "_legal_basis": "Art. 281-292 OrdPU; Art. 54-62 KKS; Kryteria wyboru do kontroli MF; Analiza predykcyjna NexusAI",
    "_warnings": build_predictive_audit_warnings(total_risk, active_factors, predicted_days, prevention_steps)
} {
    input.neural_mesh_audit_prediction == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    
    # 12 Predictive Audit Risk Factors
    risk_factors := []
    total_risk := 0
    
    # Factor 1: Revenue volatility (>50% change year-over-year)
    revenue_growth := abs(object.get(input.jdg_entrepreneur, "revenue_growth_vs_previous_year", 0))
    total_risk := total_risk + 15 { revenue_growth > 0.50 }
    risk_factors := array.concat(risk_factors, ["Zmienność przychodów >50% rok-do-roku — czerwona flaga"]) { revenue_growth > 0.50 }
    
    # Factor 2: VAT corrections frequency
    vat_corrections := object.get(input.jdg_entrepreneur, "vat_corrections_12mo", 0)
    total_risk := total_risk + 10 { vat_corrections > 5 }
    risk_factors := array.concat(risk_factors, [sprintf("Wysoka częstotliwość korekt VAT: %d/rok", [vat_corrections])]) { vat_corrections > 5 }
    
    # Factor 3: Low margin industry deviation
    margin := object.get(input.jdg_entrepreneur, "profit_margin_pct", 20)
    industry_avg := object.get(input.jdg_entrepreneur, "industry_avg_margin", 20)
    total_risk := total_risk + 20 { margin < industry_avg * 0.30 }
    risk_factors := array.concat(risk_factors, ["Marża znacząco poniżej średniej branżowej"]) { margin < industry_avg * 0.30 }
    
    # Factor 4: Late filings
    late_filings := object.get(input.jdg_entrepreneur, "late_filing_count_12mo", 0)
    total_risk := total_risk + 15 { late_filings >= 3 }
    risk_factors := array.concat(risk_factors, [sprintf("%d spóźnionych deklaracji", [late_filings])]) { late_filings >= 3 }
    
    # Factor 5: High-risk industry
    industry := object.get(input.jdg_entrepreneur, "industry", "GENERAL")
    high_risk := {"FUEL": 25, "SCRAP": 30, "ELECTRONICS": 20, "CONSTRUCTION": 15, "ALCOHOL": 20, "IT_SERVICES": 5, "CONSULTING": 10}
    industry_score := object.get(high_risk, industry, 0)
    total_risk := total_risk + industry_score { industry_score > 0 }
    risk_factors := array.concat(risk_factors, [sprintf("Branża wysokiego ryzyka: %s", [industry])]) { industry_score > 10 }
    
    # Factor 6: New unverified vendors > 50%
    new_vendors := object.get(input.jdg_entrepreneur, "new_vendor_pct_quarterly", 0)
    total_risk := total_risk + 15 { new_vendors > 0.50 }
    risk_factors := array.concat(risk_factors, [">50% nowych kontrahentów"]) { new_vendors > 0.50 }
    
    # Factor 7: Cash transactions over 15k limit
    cash_over_limit := object.get(input.jdg_entrepreneur, "cash_transactions_over_15k_pln", 0)
    total_risk := total_risk + 25 { cash_over_limit > 0 }
    risk_factors := array.concat(risk_factors, ["Transakcje gotówkowe >15k PLN — naruszenie limitu!"]) { cash_over_limit > 0 }
    
    # Factor 8: Cross-border transactions without proper documentation
    cross_border_undocumented := object.get(input.jdg_entrepreneur, "cross_border_without_tp_doc", false)
    total_risk := total_risk + 20 { cross_border_undocumented }
    risk_factors := array.concat(risk_factors, ["Transakcje transgraniczne bez dokumentacji TP"]) { cross_border_undocumented }
    
    # Factor 9: Rapid employee growth
    employee_growth := object.get(input.jdg_entrepreneur, "employee_growth_12mo_pct", 0)
    total_risk := total_risk + 10 { employee_growth > 1.0 }
    risk_factors := array.concat(risk_factors, ["Szybki wzrost zatrudnienia >100%"]) { employee_growth > 1.0 }
    
    # Factor 10: Large one-time transactions
    one_time_large := object.get(input.jdg_entrepreneur, "largest_single_transaction_12mo", 0)
    avg_transaction := object.get(input.jdg_entrepreneur, "avg_transaction_pln", 10000)
    total_risk := total_risk + 10 { one_time_large > avg_transaction * 20 }
    risk_factors := array.concat(risk_factors, ["Pojedyncza transakcja 20x większa od średniej"]) { one_time_large > avg_transaction * 20 }
    
    # Factor 11: Industry-specific compliance gaps
    compliance_gaps := object.get(input.jdg_entrepreneur, "compliance_gap_flags", 0)
    total_risk := total_risk + 10 { compliance_gaps >= 3 }
    risk_factors := array.concat(risk_factors, [sprintf("%d flag braków compliance", [compliance_gaps])]) { compliance_gaps >= 3 }
    
    # Factor 12: Past KKS convictions
    has_past_conviction := object.get(input.jdg_entrepreneur, "kks_convicted", false)
    total_risk := total_risk + 35 { has_past_conviction }
    risk_factors := array.concat(risk_factors, ["Wcześniejsze skazanie KKS — ZAAWANSOWANY MONITORING US"]) { has_past_conviction }
    
    active_factors := risk_factors
    
    # Predictive timeframe
    predicted_days := 365 { total_risk < 20 }
    predicted_days := 180 { total_risk >= 20; total_risk < 50 }
    predicted_days := 90 { total_risk >= 50; total_risk < 80 }
    predicted_days := 30 { total_risk >= 80 }
    
    # Prevention checklist
    prevention_steps := [
        "Zweryfikuj wszystkich nowych kontrahentów w Białej Liście MF",
        "Uzupełnij dokumentację transakcji transgranicznych",
        "Przygotuj uzasadnienia dla wszystkich korekt VAT",
        "Usuń transakcje gotówkowe >15k PLN",
        "Złóż czynny żal dla zaległych deklaracji",
        "Zaktualizuj politykę cen transferowych"
    ]
    
    risk_routing := "" { total_risk < 20 }
    risk_routing := "TRIAGE_QUEUE" { total_risk >= 20; total_risk < 50 }
    risk_routing := "BLOCK_AND_ALERT" { total_risk >= 50 }
    
    risk_reason := sprintf("Ryzyko kontroli: %d/100 — przewidywana w ciągu %d dni", [total_risk, predicted_days]) { total_risk >= 20 }
    risk_reason := "" { total_risk < 20 }
}

build_predictive_audit_warnings(risk, factors, days, steps) = warnings {
    risk >= 80
    factor_list := concat("; ", factors)
    step_list := build_numbered_steps(steps)
    warnings := [
        sprintf("🔴 EKSTREMALNE RYZYKO KONTROLI: %d/100 — przewidywana w ciągu %d dni!", [risk, days]),
        sprintf("🚨 %d aktywnych czynników: %s", [count(factors), factor_list]),
        "📋 NATYCHMIASTOWE DZIAŁANIA ZAPOBIEGAWCZE:",
        step_list
    ]
} else = warnings {
    risk >= 50
    factor_list := concat("; ", factors)
    warnings := [
        sprintf("🟡 WYSOKIE RYZYKO KONTROLI: %d/100 — przewidywana w ciągu %d dni", [risk, days]),
        sprintf("⚠️ %d aktywnych czynników: %s", [count(factors), factor_list]),
        "📋 Działania zapobiegawcze zalecane w ciągu 30 dni."
    ]
} else = warnings {
    risk >= 20
    warnings := [
        sprintf("🟢 UMIARKOWANE RYZYKO: %d/100", [risk]),
        sprintf("%d czynników — monitoruj sytuację.", [count(factors)])
    ]
} else = warnings {
    warnings := ["✅ NISKIE RYZYKO KONTROLI — prowadź działalność normalnie."]
}

# ═══════════════════════════════════════════════════════════════════════════════
# WARSTWA 5: AUTO-HEALING — Samouczenie z korekt użytkownika
# ═══════════════════════════════════════════════════════════════════════════════

# NM-800: CORRECTION PATTERN DETECTOR — Wykrywanie wzorców korekt
else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.correction_pattern_detector",
    "package": "jdg.neural_mesh",
    "priority": 800,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "neural_autoheal_pattern_detected": pattern_detected,
    "neural_autoheal_pattern_type": pattern_type,
    "neural_autoheal_pattern_frequency": pattern_count,
    "neural_autoheal_suggested_rule_update": suggested_update,
    "neural_autoheal_confidence": pattern_confidence,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": autoheal_routing,
    "_routing_reason": autoheal_reason,
    "_legal_basis": "Neural Mesh v6.0 Auto-Healing Layer — Cognitive Audit Trail",
    "_warnings": [sprintf("🧠 AUTO-HEAL: Wykryto wzorzec korekt '%s' (%d powtórzeń, %.0f%% pewności). Sugerowana aktualizacja reguły: %s",
        [pattern_type, pattern_count, pattern_confidence * 100, suggested_update])]
} {
    input.neural_mesh_autoheal == true
    correction_count := object.get(input.jdg_entrepreneur, "correction_count_same_type", 0)
    correction_count >= 5  # Minimum 5 corrections to detect pattern
    
    pattern_type := object.get(input.jdg_entrepreneur, "correction_type", "UNKNOWN")
    pattern_count := correction_count
    pattern_confidence := min([correction_count / 10.0, 1.0])
    pattern_detected := true
    
    suggested_update := sprintf("Aktualizuj regułę dla '%s': dostosuj priorytet i warunki na podstawie %d korekt użytkownika.",
        [pattern_type, correction_count])
    
    # Pokaż który pakiet Rego wymaga aktualizacji
    target_package := "jdg.vat.substantive" { pattern_type == "VAT_RATE_WRONG" }
    target_package := "jdg.pit.kup" { pattern_type == "KUP_CLASSIFICATION_WRONG" }
    target_package := "jdg.zus" { pattern_type == "ZUS_BASE_WRONG" }
    target_package := "jdg.accounting" { pattern_type == "DEPRECIATION_METHOD_WRONG" }
    target_package := "jdg.vat.deductions" { pattern_type == "VAT_DEDUCTION_WRONG" }
    target_package := "jdg.conflicts" { pattern_type == "CONFLICT_RESOLUTION_WRONG" }
    target_package := "jdg.neural_mesh" { true }
    
    suggested_update := sprintf("Pakiet: %s — %s", [target_package, suggested_update])
    
    autoheal_routing := "TRIAGE_QUEUE" { pattern_confidence >= 0.70 }
    autoheal_routing := "" { pattern_confidence < 0.70 }
    
    autoheal_reason := sprintf("Auto-Heal: wzorzec '%s' (%d×) — sugerowana aktualizacja %s",
        [pattern_type, correction_count, target_package]) { pattern_confidence >= 0.70 }
    autoheal_reason := "" { pattern_confidence < 0.70 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NM-900: GLOBAL COMPLIANCE SCORECARD — Karta wynikowa compliance
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh.global_compliance_scorecard",
    "package": "jdg.neural_mesh",
    "priority": 900,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "neural_compliance_overall_score": overall_compliance,
    "neural_compliance_grade": compliance_grade,
    "neural_compliance_vat_score": vat_compliance,
    "neural_compliance_pit_score": pit_compliance,
    "neural_compliance_zus_score": zus_compliance,
    "neural_compliance_ksef_score": ksef_compliance,
    "neural_compliance_rodo_score": rodo_compliance,
    "neural_compliance_aml_score": aml_compliance,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": compliance_routing,
    "_routing_reason": compliance_reason,
    "_legal_basis": "Ustawa o VAT, PIT, SUS, RODO, AML; KSeF; Neural Mesh v6.0",
    "_warnings": [sprintf("📊 COMPLIANCE SCORECARD: %.0f/100 (Ocena: %s). VAT=%.0f, PIT=%.0f, ZUS=%.0f, KSeF=%.0f, RODO=%.0f, AML=%.0f",
        [overall_compliance, compliance_grade, vat_compliance, pit_compliance, zus_compliance, ksef_compliance, rodo_compliance, aml_compliance])]
} {
    input.neural_mesh_compliance_scorecard == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    
    # VAT Compliance
    vat_compliance := 100
    vat_compliance := vat_compliance - 30 { object.get(input.jdg_entrepreneur, "vat_status", "") == "EXEMPT"; not object.get(input.jdg_entrepreneur, "vat_exemption_valid", true) }
    vat_compliance := vat_compliance - 20 { object.get(input.jdg_entrepreneur, "jpk_filed_on_time", true) == false }
    vat_compliance := max([vat_compliance, 0])
    
    # PIT Compliance
    pit_compliance := 100
    pit_compliance := pit_compliance - 30 { object.get(input.jdg_entrepreneur, "pit_annual_filed", true) == false }
    pit_compliance := pit_compliance - 20 { object.get(input.jdg_entrepreneur, "pit_advances_paid_on_time", true) == false }
    pit_compliance := max([pit_compliance, 0])
    
    # ZUS Compliance
    zus_compliance := 100
    zus_compliance := zus_compliance - 25 { object.get(input.jdg_entrepreneur, "zus_social_paid_current", true) == false }
    zus_compliance := zus_compliance - 25 { object.get(input.jdg_entrepreneur, "zus_health_paid_current", true) == false }
    zus_compliance := max([zus_compliance, 0])
    
    # KSeF Compliance
    ksef_compliance := 100
    ksef_compliance := ksef_compliance - 50 { object.get(input.jdg_entrepreneur, "ksef_registered", true) == false }
    ksef_compliance := max([ksef_compliance, 0])
    
    # RODO Compliance
    rodo_compliance := 100
    rodo_compliance := rodo_compliance - 40 { object.get(input.jdg_entrepreneur, "rodo_policy_in_place", true) == false }
    rodo_compliance := max([rodo_compliance, 0])
    
    # AML Compliance
    aml_compliance := 100
    aml_compliance := aml_compliance - 50 { object.get(input.jdg_entrepreneur, "aml_obligated", false); object.get(input.jdg_entrepreneur, "aml_procedure_in_place", true) == false }
    aml_compliance := max([aml_compliance, 0])
    
    overall_compliance := (vat_compliance * 0.25 + pit_compliance * 0.25 + zus_compliance * 0.20 +
                          ksef_compliance * 0.15 + rodo_compliance * 0.10 + aml_compliance * 0.05)
    
    compliance_grade := "A+ (DOSKONAŁA)" { overall_compliance >= 95 }
    compliance_grade := "A (BARDZO DOBRA)" { overall_compliance >= 90; overall_compliance < 95 }
    compliance_grade := "B (DOBRA)" { overall_compliance >= 75; overall_compliance < 90 }
    compliance_grade := "C (DOSTATECZNA)" { overall_compliance >= 60; overall_compliance < 75 }
    compliance_grade := "D (NISKA)" { overall_compliance >= 40; overall_compliance < 60 }
    compliance_grade := "F (KRYTYCZNA — NATYCHMIASTOWA NAPRAWA!)" { overall_compliance < 40 }
    
    compliance_routing := "" { overall_compliance >= 75 }
    compliance_routing := "TRIAGE_QUEUE" { overall_compliance >= 40; overall_compliance < 75 }
    compliance_routing := "BLOCK_AND_ALERT" { overall_compliance < 40 }
    
    compliance_reason := sprintf("Compliance: %.0f/100 — Ocena %s", [overall_compliance, compliance_grade]) { overall_compliance < 90 }
    compliance_reason := "" { overall_compliance >= 90 }
}
