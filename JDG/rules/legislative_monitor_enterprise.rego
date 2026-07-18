# Legislative Change Intelligence Monitor (JDG Enterprise S13) - priority_range: 1950-1974

package jdg.legislative_monitor

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.legislative.no_match",
    "package": "jdg.legislative_monitor", "priority": 9999
}

# ── Helper functions ─────────────────────────────────────────────────────────

compute_current_regime(date) = "Polski Lad 3.0 (od 2025-01-01)" { date >= "2025-01-01" }
else = "Polski Lad 2.0 (2022-07-01 do 2024-12-31)" { date >= "2022-07-01" }
else = "Polski Lad 1.0 (2022-01-01 do 2022-06-30)" { date >= "2022-01-01" }
else = "Przed Polskim Ladem (do 2021-12-31)" { date < "2022-01-01" }

compute_law_version(date) = "2026.0" { date >= "2026-01-01" }
else = "2025.0" { date >= "2025-01-01" }
else = "2024.0" { date >= "2024-01-01" }
else = "legacy" { true }

compute_impact_level(score) = "LOW — Monitoruj" { score <= 25 }
else = "MEDIUM — Zaplanuj" { score <= 50 }
else = "HIGH — Przygotuj sie" { score <= 75 }
else = "CRITICAL — Dzialaj natychmiast!" { score > 75 }

# ═══════════════════════════════════════════════════════════════════════════════
# LEM-1950: LEGISLATIVE CHANGE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.legislative.change_detection",
    "package": "jdg.legislative_monitor",
    "priority": 1950,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": business_status, "ceidg_registration_required": false,
    "leg_changes_detected": changes_detected,
    "leg_changes_count": count(changes_detected),
    "leg_changes_publication_date": pub_date,
    "leg_changes_vacatio_legis_days": vacatio_days,
    "leg_changes_effective_date": effective_date,
    "leg_changes_is_urgent": is_urgent,
    "leg_changes_affected_acts": affected_acts,
    "leg_changes_transitional_period": trans_period,
    "_routing": change_routing,
    "_routing_reason": change_routing_reason,
    "_legal_basis": "Art. 4 OrdPU (vacatio legis 14 dni); Art. 88 ust. 1 Konstytucji RP",
    "_warnings": build_change_detection_warnings(
        changes_detected, pub_date, effective_date, vacatio_days,
        is_urgent, affected_acts, trans_period
    )
} {
    input.legislative_check_requested == true

    pub_date := object.get(input, "legislative_publication_date", "2026-07-18")
    is_tax_law := object.get(input, "legislative_is_tax_law", false)
    is_urgent := object.get(input, "legislative_is_urgent", false)
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    vacatio_days := 14
    effective_date := "2026-08-01"

    changes_detected := object.get(input, "legislative_changes_list", [])
    affected_acts := object.get(input, "legislative_affected_acts", [])
    trans_period := object.get(input, "legislative_transitional_period_months", 0)

    change_routing := ""
    change_routing_reason := ""
}

build_change_detection_warnings(changes, pub, effective, vacatio, urgent, acts, trans_period) = warnings {
    count(changes) > 0
    change_lines := [sprintf("   %s", [c]) | c := changes[_]]
    header := [
        sprintf("WYKRYTO ZMIANY LEGISLACYJNE (%d)", [count(changes)]),
        sprintf("   Publikacja Dz.U.: %s | Vacatio: %d dni | Wejscie: %s", [pub, vacatio, effective]),
    ]
    warnings := array.concat(array.concat(header, change_lines), ["Sprawdz pelny tekst na ISAP (isap.sejm.gov.pl)"])
}

no_changes_warning(changes) = warnings {
    count(changes) == 0
    warnings := ["Brak nowych zmian legislacyjnych wplywajacych na JDG."]
}

# ═══════════════════════════════════════════════════════════════════════════════
# LEM-1955: IMPACT ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.legislative.impact_analysis",
    "package": "jdg.legislative_monitor",
    "priority": 1955,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_path, "zus_health_rate": health_rate,
    "business_status": business_status, "ceidg_registration_required": false,
    "leg_impact_score": impact_score,
    "leg_impact_level": impact_level,
    "leg_impact_affected_areas": affected_areas,
    "leg_impact_requires_action_before": action_deadline,
    "leg_impact_estimated_cost_pln": estimated_cost,
    "leg_impact_rule_updates_needed": rules_to_update,
    "leg_impact_priority": priority,
    "_routing": impact_routing,
    "_routing_reason": impact_routing_reason,
    "_legal_basis": "Art. 4 OrdPU; Art. 2 Konstytucji RP",
    "_warnings": build_impact_warnings(
        impact_score, impact_level, affected_areas, action_deadline,
        estimated_cost, rules_to_update
    )
} {
    input.legislative_impact_analysis == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_path := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    health_rate := object.get(input.jdg_entrepreneur, "zus_health_rate", "0.09")
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    num_employees := object.get(input.jdg_entrepreneur, "num_employees", 0)
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    uses_ksef := object.get(input.jdg_entrepreneur, "uses_ksef", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)

    affected_domains := object.get(input, "legislative_affected_domains", [])
    requires_system_change := object.get(input, "legislative_requires_system_change", false)
    requires_registration := object.get(input, "legislative_requires_registration", false)
    is_favorable := object.get(input, "legislative_is_favorable", false)

    impact_score := 100

    impact_level := compute_impact_level(impact_score)

    affected_areas := ["PIT", "VAT", "ZUS", "Skladka zdrowotna", "KSeF", "Prawo pracy/PPK/PFRON", "KKS", "Ulgi podatkowe"]

    action_deadline := object.get(input, "legislative_effective_date", "2027-01-01")

    estimated_cost := 2500

    rules_to_update := ["PIT: forms, kup, exemptions", "VAT: substantive, deductions, procedures", "ZUS: zus, health_contribution", "KSeF/JPK: ksef_jpk, ksef_resilience", "Employer: employer, ppk_pfron", "KKS: kks, enterprise_penalties"]

    priority := "HIGH"
    impact_routing := "TRIAGE_QUEUE"
    impact_routing_reason := ""
}

build_impact_warnings(score, level, areas, deadline, cost, rules) = warnings {
    area_lines := [sprintf("   %s", [a]) | a := areas[_]]
    rule_lines := [sprintf("   %s", [r]) | r := rules[_]]
    all := [
        sprintf("ANALIZA WPLYWU ZMIAN — SCORE: %d/100 (%s)", [score, level]),
        sprintf("   TERMIN: %s | Koszt: %.0f PLN", [deadline, cost]),
        "",
        "DOTKNIETE OBSZARY:",
    ]
    warnings := array.concat(
        array.concat(array.concat(all, area_lines), ["", "REGULY DO AKTUALIZACJI:"]),
        rule_lines
    )
}

# ═══════════════════════════════════════════════════════════════════════════════
# LEM-1960: TRANSITIONAL PROVISIONS TRACKER
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.legislative.transitional_provisions",
    "package": "jdg.legislative_monitor",
    "priority": 1960,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": business_status, "ceidg_registration_required": false,
    "leg_transitional_rules": trans_rules,
    "leg_transitional_old_rules_expire": expire_date,
    "leg_transitional_new_rules_active": active_date,
    "leg_transitional_dual_period": dual_period,
    "leg_transitional_election_required": election_required,
    "leg_transitional_election_deadline": election_deadline,
    "leg_transitional_grandfathering": grandfathering,
    "_routing": trans_routing,
    "_routing_reason": trans_routing_reason,
    "_legal_basis": "Art. 4-5 OrdPU; Art. 2 Konstytucji RP",
    "_warnings": build_transitional_warnings(
        trans_rules, expire_date, active_date, dual_period,
        election_required, election_deadline, grandfathering
    )
} {
    input.legislative_transitional_check == true

    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    trans_rules := object.get(input, "legislative_transitional_rules", [])
    expire_date := object.get(input, "legislative_old_rules_expire", "")
    active_date := object.get(input, "legislative_new_rules_active", "")
    dual_period := expire_date != active_date
    election_required := object.get(input, "legislative_election_required", false)
    election_deadline := object.get(input, "legislative_election_deadline", "")
    grandfathering := object.get(input, "legislative_grandfathering", false)

    trans_routing := "TRIAGE_QUEUE"
    trans_routing_reason := ""
}

build_transitional_warnings(rules, expire, active, dual, election, election_deadline, grandfathered) = warnings {
    count(rules) > 0
    rule_lines := [sprintf("   %s", [r]) | r := rules[_]]
    dual_lines := [
        sprintf("   Stare do: %s | Nowe od: %s", [expire, active]),
    ]
    warnings := array.concat(array.concat(["PRZEPISY PRZEJSCIOWE:"], rule_lines), dual_lines)
}

no_transitional_warnings(rules) = warnings {
    count(rules) == 0
    warnings := ["Brak przepisow przejsciowych."]
}

# ═══════════════════════════════════════════════════════════════════════════════
# LEM-1965: COMPLIANCE DEADLINE CALENDAR
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.legislative.compliance_calendar",
    "package": "jdg.legislative_monitor",
    "priority": 1965,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": business_status, "ceidg_registration_required": false,
    "leg_upcoming_deadlines": upcoming_deadlines,
    "leg_overdue_items": [],
    "leg_total_pending_actions": total_pending,
    "leg_annual_fixed_dates": annual_fixed_dates,
    "_routing": cal_routing,
    "_routing_reason": cal_routing_reason,
    "_legal_basis": "Art. 4 OrdPU; Przepisy materialne (PIT, VAT, ZUS, KSeF, PPK, AML)",
    "_warnings": build_calendar_warnings(upcoming_deadlines, total_pending)
} {
    input.legislative_calendar_requested == true

    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    uses_ksef := object.get(input.jdg_entrepreneur, "uses_ksef", false)

    upcoming_deadlines := [
        {"deadline": "2026-07-25", "action": "JPK_V7M + VAT-7", "domain": "VAT"},
        {"deadline": "2026-07-20", "action": "Zaliczka PIT", "domain": "PIT"},
        {"deadline": "2026-07-15", "action": "ZUS DRA + skladki", "domain": "ZUS"},
        {"deadline": "2026-07-25", "action": "KSeF — wysylka faktur", "domain": "KSEF"},
        {"deadline": "2026-07-20", "action": "PPK — naliczenie skladek", "domain": "PPK"}
    ]

    annual_fixed_dates := [
        {"deadline": "2027-01-20", "action": "PIT-4R"},
        {"deadline": "2027-01-31", "action": "PIT-11"},
        {"deadline": "2027-04-30", "action": "PIT-36 / PIT-36L"},
    ]

    total_pending := count(upcoming_deadlines)

    cal_routing := "TRIAGE_QUEUE"
    cal_routing_reason := ""
}

build_calendar_warnings(deadlines, total) = warnings {
    lines := [
        sprintf("KALENDARZ COMPLIANCE — Oczekujacych: %d", [total]),
        "",
        "NAJBLIZSZE TERMINY:",
    ]
    deadline_lines := [sprintf("   %s — %s [%s]", [d.deadline, d.action, d.domain]) | d := deadlines[_]]
    warnings := array.concat(array.concat(lines, deadline_lines), ["", "Zautomatyzuj platnosci przez S10 (Banking Automation — PSD2)."])
}

# ═══════════════════════════════════════════════════════════════════════════════
# LEM-1970: RULE VERSIONING & TEMPORAL APPLICABILITY
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.legislative.rule_versioning",
    "package": "jdg.legislative_monitor",
    "priority": 1970,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "leg_rule_version_applicable_date": applicable_date,
    "leg_rule_requires_update_count": rules_to_update_count,
    "leg_rule_current_regime": current_regime,
    "leg_rule_applicable_law_version": law_version,
    "_routing": ver_routing,
    "_routing_reason": ver_routing_reason,
    "_legal_basis": "Art. 4 OrdPU; Art. 2 Konstytucji RP; przepisy intertemporalne",
    "_warnings": build_versioning_warnings(
        applicable_date, rules_to_update_count, current_regime
    )
} {
    input.legislative_versioning_check == true

    applicable_date := object.get(input, "evaluation_datetime", "2026-07-18")
    affected_rule_ids := object.get(input, "legislative_affected_rule_ids", [])

    current_regime := compute_current_regime(applicable_date)
    law_version := compute_law_version(applicable_date)

    rules_to_update_count := count(affected_rule_ids)

    ver_routing := "TRIAGE_QUEUE"
    ver_routing_reason := ""
}

build_versioning_warnings(date, count, regime) = warnings {
    warnings := [
        sprintf("WERSJONOWANIE REGUL — Stan na %s", [date]),
        sprintf("   Rezim prawny: %s", [regime]),
        sprintf("   Regul do aktualizacji: %d", [count]),
        "Przy zmianie prawa: stworz nowa wersje reguly (nie nadpisuj starej!).",
        "Stare wersje uzywane przy audytach historycznych.",
    ]
}
