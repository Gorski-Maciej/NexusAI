# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE HOLISTIC JDG LIFECYCLE MANAGER (Strategic Initiative S24)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Holistic Lifecycle Manager — Full JDG Lifecycle Intelligence
# description: |
#   ENTERPRISE v7.0 — Kompletny manager cyklu życia JDG.
#   Od rejestracji CEIDG, przez wszystkie etapy wzrostu, po zamknięcie/sukcesję.
#   
#   KLUCZOWA INNOWACJA: JDG to nie pojedyncze transakcje — to CAŁY CYKL ŻYCIA
#   firmy. Ten silnik modeluje każdy etap i zapewnia ciągłość compliance.
#
#   FAZY CYKLU ŻYCIA:
#   1. PRE-START: Planowanie formy, rejestracja CEIDG, VAT-R, ZUS ZZA/ZUA
#   2. STARTUP: Ulga na start (0-6 mies.), preferencyjny ZUS (7-30 mies.)
#   3. GROWTH: Mały ZUS+, pierwszy pracownik, limit VAT 200k, KSeF
#   4. MATURITY: Optymalizacja podatkowa, skala→liniowy, JDG→Sp. z o.o.
#   5. EXIT: Zamknięcie, likwidacja, sukcesja, remanent likwidacyjny
#
#   KLUCZOWE FUNKCJE:
#   - Timeline Compliance: deadline'y rejestracyjne, zmiany statusu
#   - Phase Transition Triggers: automatyczne wykrywanie zmiany fazy
#   - Multi-Year Strategy: optymalizacja w horyzoncie 5-letnim
#   - Health Monitoring: wskaźniki zdrowia JDG per faza
#   - Predictive Alerts: co się zmieni za 3/6/12 miesięcy
# architecture: Enterprise v7.0 Lifecycle Engine
# legal_basis: Prawo Przedsiębiorców, CEIDG, SUS, PIT, VAT, OrdPU, Sukcesja
# package: jdg.lifecycle_manager
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.lifecycle_manager

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.lifecycle.no_match",
    "package": "jdg.lifecycle_manager", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S24-100: FAZA CYKLU ŻYCIA JDG — Identyfikacja + predykcja następnej fazy
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.lifecycle.current_phase_detection",
    "package": "jdg.lifecycle_manager",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "lifecycle_current_phase": current_phase,
    "lifecycle_months_active": months_active,
    "lifecycle_next_phase": next_phase,
    "lifecycle_next_phase_trigger_date": next_phase_date,
    "lifecycle_phase_transition_actions": transition_actions,
    "lifecycle_remaining_months_in_phase": months_remaining,
    "business_status": business_status, "ceidg_registration_required": false,
    "_routing": lifecycle_routing,
    "_routing_reason": lifecycle_reason,
    "_legal_basis": "Prawo Przedsiębiorców; Art. 18a-18c SUS; Art. 113 VAT; Art. 9a PIT; Art. 14a OrdPU",
    "_warnings": array.concat(
        [
            sprintf("🔄 FAZA JDG: %s (miesiąc %d)", [current_phase, months_active]),
            sprintf("   Następna faza: %s", [next_phase]),
            sprintf("   Pozostało: %d mies. w obecnej fazie", [months_remaining]),
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            sprintf("📋 DZIAŁANIA (%d):", [count(transition_actions)])
        ],
        [sprintf("   %s", [a]) | a := transition_actions[_]]
    ),
} {
    input.lifecycle_phase_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    ceidg_entry := object.get(input.jdg_entrepreneur, "ceidg_entry_date", "2026-01-01")
    months_active := calculate_months_active(ceidg_entry)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 50000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    vat_status := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT")
    is_suspended := business_status == "SUSPENDED"
    in_closure := object.get(input.jdg_entrepreneur, "business_closure_in_progress", false)
    in_succession := object.get(input.jdg_entrepreneur, "in_succession", false)

    # Phase detection
    current_phase := "PRE_START" { months_active < 0 }
    current_phase := "STARTUP_START_RELIEF" { months_active >= 0; months_active < 6; zus_status == "START_RELIEF" }
    current_phase := "STARTUP_PREFERENTIAL" { months_active >= 6; months_active < 30; zus_status == "PREFERENTIAL" }
    current_phase := "EARLY_GROWTH" { months_active >= 6; annual_revenue < 200000; not has_employees }
    current_phase := "GROWTH_EMPLOYEES" { has_employees; employee_count <= 5 }
    current_phase := "GROWTH_VAT_ACTIVE" { vat_status == "ACTIVE"; annual_revenue >= 200000 }
    current_phase := "MATURITY" { months_active >= 30; annual_revenue >= 200000; has_employees }
    current_phase := "SUSPENDED" { is_suspended }
    current_phase := "SUCCESSION" { in_succession }
    current_phase := "CLOSURE" { in_closure }
    current_phase := "ESTABLISHED" { current_phase == "" }

    # Next phase prediction
    next_phase := "STARTUP_PREFERENTIAL" {
        current_phase == "STARTUP_START_RELIEF"; months_active >= 5
    }
    next_phase := "EARLY_GROWTH" {
        current_phase in {"STARTUP_PREFERENTIAL", "STARTUP_START_RELIEF"}
        annual_revenue > 100000
    }
    next_phase := "GROWTH_VAT_ACTIVE" {
        current_phase in {"EARLY_GROWTH", "STARTUP_PREFERENTIAL"}
        annual_revenue >= 180000
    }
    next_phase := "MATURITY" {
        months_active >= 24
        annual_revenue >= 150000
    }
    next_phase := "SUSPENDED" {
        object.get(input.jdg_entrepreneur, "planning_suspension", false)
    }
    next_phase := current_phase { next_phase == "" }

    # Next phase trigger date
    next_phase_date := calculate_next_phase_date(ceidg_entry, months_active, current_phase, next_phase)

    # Remaining months
    months_remaining := 6 - months_active { current_phase == "STARTUP_START_RELIEF"; months_active < 6 }
    months_remaining := 30 - months_active { current_phase == "STARTUP_PREFERENTIAL"; months_active < 30 }
    months_remaining := 36 - months_active { zus_status == "MALY_ZUS_PLUS"; months_active < 36 }
    months_remaining := 999 { months_remaining == 0 }

    # Transition actions
    transition_actions := generate_transition_actions(current_phase, next_phase, months_remaining, annual_revenue, vat_status, has_employees, months_active, pit_form)

    lifecycle_routing := "TRIAGE_QUEUE" { months_remaining <= 2; months_remaining > 0 }
    lifecycle_routing := "BLOCK_AND_ALERT" { months_remaining <= 0 }
    lifecycle_routing := "" { true }
    lifecycle_reason := sprintf("Faza: %s → %s. Zostało %d mies. %s",
        [current_phase, next_phase, months_remaining,
         "PRZYGOTUJ SIĘ NA ZMIANĘ!" { months_remaining <= 2 }
         else ""]) { months_remaining <= 6 }
    lifecycle_reason := "" { true }
}

# ── Helpers ─────────────────────────────────────────────────────────────────

calculate_months_active(entry_date) = months {
    entry_ns := time.parse_ns("2006-01-02", entry_date)
    today_ns := time.now_ns()
    months := floor((today_ns - entry_ns) / (30.44 * 24 * 60 * 60 * 1000000000))
} else = 0 { true }

calculate_next_phase_date(entry, months, current, next) = date {
    date := sprintf("2026-%02d-01", [calculate_month_number(months + 1)])
} else = "Unknown" { true }

calculate_month_number(total_months) = month {
    year_offset := floor(total_months / 12)
    month_rem := total_months % 12 + 1  # 1-indexed
    month := month_rem + year_offset * 12  # simplified
    month := month_rem { month_rem <= 12 }
}

generate_transition_actions(current, next, remaining, annual_revenue, vat_status, has_employees, months_active, pit_form) = actions {
    actions := []

    actions := array.concat(actions, [
        sprintf("⚠️ Za %d mies. KONIEC ulgi na start → preferencyjny ZUS (30%% podstawy, 24 mies.)", [remaining]),
        "📋 Przygotuj się na wzrost składek ZUS. Budżetuj +%.0f PLN/mies. Potrzebujesz ZUS ZUA (kod 05 10).",
        "💰 Rozważ rejestrację VAT przed końcem ulgi dla odliczeń od inwestycji startupowych."
    ]) { current == "STARTUP_START_RELIEF"; remaining <= 2 }

    actions := array.concat(actions, [
        sprintf("⚠️ Za %d mies. KONIEC preferencyjnego ZUS → STANDARDOWY (60%% podstawy).", [remaining]),
        "📋 Przygotuj się na ZNACZNY wzrost składek ZUS (+~80%%).",
        "💰 Jeśli nie masz jeszcze VAT — rozważ rejestrację dla kompensacji kosztów."
    ]) { current == "STARTUP_PREFERENTIAL"; remaining <= 3 }

    actions := array.concat(actions, [
        sprintf("⚠️ Zbliżasz się do limitu VAT 200k! %.0f PLN/200k PLN.", [annual_revenue]),
        "📋 Przygotuj VAT-R (zgłoszenie rejestracyjne). Masz 7 dni od przekroczenia limitu.",
        "💰 Po rejestracji: VAT od sprzedaży 23%%, ale odliczasz VAT od wszystkich zakupów firmowych!"
    ]) { annual_revenue >= 180000; vat_status == "EXEMPT" }

    actions := array.concat(actions, [
        "⚠️ Jesteś w fazie GROWTH — rozważ pierwszego pracownika.",
        "📋 Obowiązki: ZUS ZUA dla pracownika, PIT-4R, PIT-11, PPK?",
        "💰 Koszt pracownika: brutto + ~20%% ZUS pracodawcy. Min. płaca 2026: ~4 666 PLN brutto."
    ]) { next == "GROWTH_EMPLOYEES"; not has_employees; months_active > 12 }

    actions := array.concat(actions, [
        "🚀 Jesteś w fazie MATURITY — rozważ optymalizację.",
        sprintf("📋 Analiza: JDG PIT %s vs Sp. z o.o. CIT 19%%/9%% — oszczędność może być znacząca.", [pit_form]),
        "💰 CIT estoński: brak podatku przy reinwestycji + brak składek ZUS od zysku!"
    ]) { current == "MATURITY" }

    actions := ["✅ Jesteś w stabilnej fazie — kontynuuj działalność."] { count(actions) == 0 }
}


# ═══════════════════════════════════════════════════════════════════════════════
# S24-200: TIMELINE COMPLIANCE — Wszystkie deadline'y rejestracyjne
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.lifecycle.compliance_timeline",
    "package": "jdg.lifecycle_manager",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "lifecycle_milestones_completed": milestones_done,
    "lifecycle_milestones_pending": milestones_pending,
    "lifecycle_milestones_missed": milestones_missed,
    "lifecycle_next_registration_deadline": next_deadline,
    "lifecycle_next_deadline_description": next_desc,
    "business_status": business_status, "ceidg_registration_required": registration_needed,
    "_routing": timeline_routing,
    "_routing_reason": timeline_reason,
    "_legal_basis": "Prawo Przedsiębiorców; CEIDG; Art. 96 VAT; Art. 43 SUS; Art. 44 PIT",
    "_warnings": warnings,
} {
    input.lifecycle_timeline_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    months_active := calculate_months_active(object.get(input.jdg_entrepreneur, "ceidg_entry_date", "2026-01-01"))
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    vat_status := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    ceidg_valid := object.get(input.jdg_entrepreneur, "ceidg_valid", true)

    # All regulatory milestones
    all_milestones := [
        {"id": "CEIDG_REGISTRATION", "desc": "Rejestracja CEIDG-1", "deadline": "Przed rozpoczęciem działalności", "article": "Art. 5-6 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)"},
        {"id": "ZUS_ZUA_JDG", "desc": "Zgłoszenie ZUS ZUA (kod 05 10)", "deadline": "7 dni od wpisu CEIDG", "article": "Art. 43 SUS"},
        {"id": "VAT_R_REGISTRATION", "desc": "VAT-R (rejestracja VAT)", "deadline": "Przed pierwszą transakcją / 7 dni od przekroczenia 200k", "article": "Art. 96 VAT"},
        {"id": "TAX_FORM_CHOICE", "desc": "Wybór formy opodatkowania PIT", "deadline": "Do 20. dnia miesiąca po pierwszym przychodzie", "article": "Art. 9a PIT"},
        {"id": "FIRST_ZUS_PAYMENT", "desc": "Pierwsza składka ZUS", "deadline": "Do 10. dnia następnego miesiąca", "article": "Art. 47 SUS"},
        {"id": "FIRST_PIT_ADVANCE", "desc": "Pierwsza zaliczka PIT", "deadline": "Do 20. dnia następnego miesiąca", "article": "Art. 44 PIT"},
        {"id": "FIRST_JPK_V7", "desc": "Pierwszy JPK_V7M", "deadline": "Do 25. dnia następnego miesiąca", "article": "Art. 109 VAT"},
        {"id": "KSEF_REGISTRATION", "desc": "Rejestracja KSeF", "deadline": "Przed pierwszą fakturą B2B", "article": "Art. 106na VAT"},
        {"id": "FIRST_EMPLOYEE_ZUS", "desc": "Zgłoszenie pracownika ZUS ZUA", "deadline": "7 dni od zatrudnienia", "article": "Art. 43 SUS"},
    ]

    # Determine which are completed
    milestones_done := [m | m := all_milestones[_]; is_milestone_completed(m.id)]
    milestones_pending := [m | m := all_milestones[_]; not is_milestone_completed(m.id); not is_milestone_missed(m, months_active, annual_revenue)]
    milestones_missed := [m | m := all_milestones[_]; is_milestone_missed(m, months_active, annual_revenue)]

    next_deadline := object.get(milestones_pending[0], "deadline", "Brak") { count(milestones_pending) > 0 }
    next_deadline := "Wszystkie zrealizowane" { count(milestones_pending) == 0 }
    next_desc := object.get(milestones_pending[0], "desc", "") { count(milestones_pending) > 0 }

    registration_needed := count(milestones_pending) > 0

    timeline_routing := "BLOCK_AND_ALERT" { count(milestones_missed) > 0 }
    timeline_routing := "TRIAGE_QUEUE" { count(milestones_pending) > 0; count(milestones_missed) == 0 }
    timeline_routing := "" { true }
    timeline_reason := sprintf("%d brakujących rejestracji — %d po terminie!",
        [count(milestones_pending), count(milestones_missed)]) { count(milestones_missed) > 0 }
    timeline_reason := sprintf("%d rejestracji do wykonania", [count(milestones_pending)]) { count(milestones_pending) > 0; count(milestones_missed) == 0 }
    timeline_reason := "" { true }

    warnings := [
        sprintf("🚨 %d BRAKUJĄCYCH REJESTRACJI PO TERMINIE!", [count(milestones_missed)]),
        sprintf("   %s", [concat("; ", [m.desc | m := milestones_missed[_]])]),
        "   Konsekwencje: brak ZUS = brak ubezpieczenia zdrowotnego!",
        "   NATYCHMIAST złóż brakujące zgłoszenia!"
    ] { count(milestones_missed) > 0 }
    warnings := [
        sprintf("📋 %d REJESTRACJI DO WYKONANIA:", [count(milestones_pending)]),
        sprintf("   %s", [concat("; ", [sprintf("%s (termin: %s)", [m.desc, m.deadline]) | m := milestones_pending[_]])])
    ] { count(milestones_pending) > 0 }
    warnings := ["✅ Wszystkie rejestracje i zgłoszenia zrealizowane!"] { true }
}

is_milestone_completed(milestone_id) = true {
    milestone_id == "CEIDG_REGISTRATION"
    object.get(input.jdg_entrepreneur, "ceidg_valid", true)
} else = true {
    milestone_id == "ZUS_ZUA_JDG"
    object.get(input.jdg_entrepreneur, "zus_registered", true)
} else = true {
    milestone_id == "VAT_R_REGISTRATION"
    object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") != "EXEMPT"
} else = true {
    milestone_id == "TAX_FORM_CHOICE"
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
} else = false { true }

is_milestone_missed(milestone, months_active, annual_revenue) = true {
    not is_milestone_completed(milestone.id)
    milestone.id == "ZUS_ZUA_JDG"; months_active > 1
} else = true {
    not is_milestone_completed(milestone.id)
    milestone.id == "VAT_R_REGISTRATION"; annual_revenue > 200000
} else = false { true }

# ═══════════════════════════════════════════════════════════════════════════════
# S24-300: JDG HEALTH SCORECARD — Kompleksowy wskaźnik zdrowia
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.lifecycle.health_scorecard",
    "package": "jdg.lifecycle_manager",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "lifecycle_health_score": health_score,
    "lifecycle_health_grade": health_grade,
    "lifecycle_compliance_score": compliance_score,
    "lifecycle_financial_score": financial_score,
    "lifecycle_operational_score": operational_score,
    "lifecycle_risk_score": risk_score_inverted,
    "lifecycle_areas_needing_attention": attention_areas,
    "business_status": business_status, "ceidg_registration_required": false,
    "_routing": health_routing,
    "_routing_reason": health_reason,
    "_legal_basis": "Kompleksowa ocena stanu JDG",
    "_warnings": [
        sprintf("🏥 JDG HEALTH SCORECARD: %.0f/100 (Ocena: %s)", [health_score, health_grade]),
        sprintf("   Compliance: %.0f | Finanse: %.0f | Operacje: %.0f | Ryzyko: %.0f",
            [compliance_score, financial_score, operational_score, risk_score_inverted]),
        sprintf("   Obszary wymagające uwagi: %s",
            [concat(", ", attention_areas) { count(attention_areas) > 0 } else "BRAK"])
    ]
} {
    input.lifecycle_health_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    attention_areas := []

    # Compliance score (0-100)
    compliance_score := 100
    compliance_score := compliance_score - 20 { not object.get(input.jdg_entrepreneur, "ceidg_valid", true) }
    compliance_score := compliance_score - 20 { not object.get(input.jdg_entrepreneur, "zus_registered", true) }
    compliance_score := compliance_score - 10 { object.get(input.jdg_entrepreneur, "jpk_filed_on_time", true) == false }
    compliance_score := compliance_score - 15 { object.get(input.jdg_entrepreneur, "pit_annual_filed", true) == false }
    compliance_score := max([compliance_score, 0])
    attention_areas := array.concat(attention_areas, ["COMPLIANCE"]) { compliance_score < 70 }

    # Financial score (0-100)
    financial_score := 100
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 50000)
    financial_score := financial_score - 15 { annual_profit < 0 }
    financial_score := financial_score - 10 { annual_profit < 12000; annual_profit >= 0 }
    has_emergency_fund := object.get(input.jdg_entrepreneur, "emergency_fund_months", 0) >= 3
    financial_score := financial_score - 20 { not has_emergency_fund }
    financial_score := max([financial_score, 0])
    attention_areas := array.concat(attention_areas, ["FINANSE"]) { financial_score < 70 }

    # Operational score (0-100)
    operational_score := 100
    has_accounting_system := object.get(input.jdg_entrepreneur, "has_accounting_system", true)
    operational_score := operational_score - 30 { not has_accounting_system }
    operational_score := max([operational_score, 0])
    attention_areas := array.concat(attention_areas, ["OPERACJE"]) { operational_score < 70 }

    # Risk score (inverted — higher = better)
    risk_factors := object.get(input.jdg_entrepreneur, "active_risk_flags", 0)
    risk_score_inverted := 100 - risk_factors * 10
    risk_score_inverted := max([risk_score_inverted, 0])
    attention_areas := array.concat(attention_areas, ["RYZYKO"]) { risk_score_inverted < 70 }

    # Overall health
    health_score := floor((compliance_score * 0.35 + financial_score * 0.30 + 
                           operational_score * 0.15 + risk_score_inverted * 0.20) * 100) / 100

    health_grade := "A" { health_score >= 90 }
    health_grade := "B" { health_score >= 75; health_score < 90 }
    health_grade := "C" { health_score >= 60; health_score < 75 }
    health_grade := "D" { health_score >= 40; health_score < 60 }
    health_grade := "F" { health_score < 40 }

    health_routing := "BLOCK_AND_ALERT" { health_score < 40 }
    health_routing := "TRIAGE_QUEUE" { health_score >= 40; health_score < 60 }
    health_routing := "" { true }
    health_reason := sprintf("JDG Health: %.0f/100 (%s) — %s",
        [health_score, health_grade,
         "KRYTYCZNA sytuacja!" { health_score < 40 }
         else "Wymaga uwagi" { health_score < 70 }
         else "W normie"]) { health_score < 70 }
    health_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S24-400: EXIT STRATEGY — Zamknięcie JDG i sukcesja
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.lifecycle.exit_strategy",
    "package": "jdg.lifecycle_manager",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "lifecycle_exit_type": exit_type,
    "lifecycle_exit_checklist": exit_checklist,
    "lifecycle_exit_mandatory_deadlines": mandatory_deadlines,
    "lifecycle_exit_tax_consequences": tax_consequences,
    "business_status": "CLOSING", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Zamknięcie JDG — %s. %d kroków wymaganych.",
        [exit_type, count(exit_checklist)]),
    "_legal_basis": "Prawo Przedsiębiorców Art. 31-36; Art. 24 PIT; Art. 14 VAT; Ustawa o zarządzie sukcesyjnym",
    "_warnings": array.concat(
        array.concat(
            array.concat(
                array.concat(
                    [
                        sprintf("🚪 ZAMKNIĘCIE JDG — %s", [exit_type]),
                        sprintf("📋 CHECKLISTA (%d kroków):", [count(exit_checklist)])
                    ],
                    [sprintf("   %s", [s]) | s := exit_checklist[_]]
                ),
                ["━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", "⏰ KRYTYCZNE TERMINY:"]
            ),
            [sprintf("   • %s", [d]) | d := mandatory_deadlines[_]]
        ),
        ["━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", "💰 KONSEKWENCJE PODATKOWE:", tax_consequences]
    ),
} {
    input.lifecycle_exit_planned == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    exit_reason := object.get(input.jdg_entrepreneur, "exit_reason", "VOLUNTARY_CLOSURE")
    has_inventory := object.get(input.jdg_entrepreneur, "inventory_remnant_value", 0) > 0
    has_employees_left := object.get(input.jdg_entrepreneur, "employees_still_active", false)
    has_assets := object.get(input.jdg_entrepreneur, "fixed_assets_value", 0) > 0
    has_liabilities := object.get(input.jdg_entrepreneur, "outstanding_liabilities", 0) > 0
    is_succession := object.get(input.jdg_entrepreneur, "exit_via_succession", false)
    has_unpaid_taxes := object.get(input.jdg_entrepreneur, "has_unpaid_taxes", false)
    has_unresolved_losses := object.get(input.jdg_entrepreneur, "has_unresolved_losses", false)

    exit_type := "DOBROWOLNE_ZAMKNIECIE" { exit_reason == "VOLUNTARY_CLOSURE" }
    exit_type := "SUKCESJA" { is_succession }
    exit_type := "LIKWIDACJA_PRZYMUSOWA" { exit_reason == "FORCED_LIQUIDATION" }
    exit_type := "ZAWIESZENIE" { exit_reason == "SUSPENSION" }
    exit_type := "SPRZEDAZ_FIRMY" { exit_reason == "BUSINESS_SALE" }

    exit_checklist := []
    exit_checklist := array.concat(exit_checklist, 
        ["1. Wyrejestruj CEIDG (CEIDG-1 — wniosek o wykreślenie)"])
    exit_checklist := array.concat(exit_checklist,
        ["2. Spisz REMANENT LIKWIDACYJNY — wycena wg cen zakupu lub rynkowych (niższa) — Art. 24 ust. 3 PIT"])

    remnant_tax_rate := "10%" { pit_form in {"PIT_SCALE", "LINEAR"} }
    remnant_tax_rate := "wg stawki ryczałtu" { pit_form == "LUMP_SUM" }

    exit_checklist := array.concat(exit_checklist, [
        sprintf("3. Zapłać %s zryczałtowany podatek od remanentu (%.0f PLN remanent → %.0f PLN podatku)",
            [remnant_tax_rate, object.get(input.jdg_entrepreneur, "inventory_remnant_value", 0),
             object.get(input.jdg_entrepreneur, "inventory_remnant_value", 0) * 0.10])
    ]) { has_inventory }

    exit_checklist := array.concat(exit_checklist,
        ["4. Wyrejestruj VAT (VAT-Z) — VAT od remanentu 23% wartości rynkowej (Art. 14 VAT)"])
    exit_checklist := array.concat(exit_checklist,
        ["5. Złóż deklarację ZUS ZWUA (wyrejestrowanie z ubezpieczeń) w ciągu 7 dni"])

    exit_checklist := array.concat(exit_checklist, [
        sprintf("6. Spłać zaległe podatki: %.0f PLN", [object.get(input.jdg_entrepreneur, "unpaid_taxes_total", 0)])
    ]) { has_unpaid_taxes }

    exit_checklist := array.concat(exit_checklist,
        ["7. Złóż ZEZNANIE KOŃCOWE PIT do 30 kwietnia następnego roku — UWAGA: strata PRZEPADA (Art. 9 ust. 5 PIT)"])
    exit_checklist := array.concat(exit_checklist,
        ["8. Złóż ostatni JPK_V7M (do 25. dnia miesiąca po wyrejestrowaniu VAT)"])

    exit_checklist := array.concat(exit_checklist, [
        sprintf("9. Rozwiąż umowy z %d pracownikami — odprawy, świadectwa pracy, PIT-11", 
            [object.get(input.jdg_entrepreneur, "employee_count", 0)])
    ]) { has_employees_left }

    exit_checklist := array.concat(exit_checklist,
        ["10. Przechowuj dokumentację przez 5 lat od końca roku podatkowego (Art. 86 OrdPU)"])

    exit_checklist := array.concat(exit_checklist, [
        "SPECJALNE: Ustanów ZARZĄDCĘ SUKCESYJNEGO (akt notarialny) — Art. 7-9 ustawy o zarządzie sukcesyjnym",
        "SPECJALNE: Zgłoś zarządcę do CEIDG w ciągu 14 dni od śmierci (Art. 12 ust. 1)",
        "SPECJALNE: Zarządca działa max 2 lata od śmierci (Art. 49 ust. 1)"
    ]) { is_succession }

    mandatory_deadlines := [
        "CEIDG: natychmiast po zakończeniu likwidacji",
        "VAT-Z: przed zaprzestaniem czynności opodatkowanych",
        "ZUS ZWUA: 7 dni od zaprzestania działalności",
        "Zeznanie końcowe PIT: do 30 kwietnia następnego roku",
        "Przechowywanie dokumentów: 5 lat od końca roku"
    ]

    tax_consequences := concat("\n", [
        sprintf("• Podatek od remanentu: %.0f PLN (%s%% ryczałt)", 
            [object.get(input.jdg_entrepreneur, "inventory_remnant_value", 0) * 0.10, remnant_tax_rate]),
        "• VAT od remanentu: 23% wartości rynkowej towarów (Art. 14 VAT)",
        "• Nierozliczone straty PRZEPADAJĄ (Art. 9 ust. 5 PIT)",
        "• Ostatnia zaliczka PIT: od dochodu za okres od początku roku do dnia likwidacji",
        "• Sprzedaż środków trwałych: dochód ze sprzedaży opodatkowany na zasadach ogólnych"
    ])
}

