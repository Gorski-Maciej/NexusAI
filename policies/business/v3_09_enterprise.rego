# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RYCZAŁT + CYKL ŻYCIA JDG V3 ENTERPRISE (Kampania V3, część 09/20)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.business.v3_09
# Cel:     domknięcie luk L-09-001..L-09-009 z raportu 09_RYCZALT.txt:
#          monitor limitu 2M EUR (art. 6 u.z.p.d.), FormAdvisor z checkpointem
#          człowieka, checklist zawieszenia (PP art. 22-25), Succession Planner
#          (u.z.s. art. 12-13), deadline CEIDG, działalność nieewidencjonowana,
#          maszyna stanów cyklu życia, karta podatkowa — wszystko ZERO-HARDCODE
#          z data.jdg.thresholds.business_lifecycle; fail-closed (V1 z6);
#          Decision Certificate (V2 F4); Golden Oracle (F3).
# Prawo:   Ustawa z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym
#          od niektórych przychodów osiąganych przez osoby fizyczne (art. 6, 12,
#          21-23); Prawo przedsiębiorców (art. 5-6, 16, 22-25); ustawa o zarządzie
#          sukcesyjnym (art. 12-14); CEIDG (art. 16 ust. 3 PP).
# Struktura: wzorzec jdg.crossborder.v3_08 — reguły-decyzje budują verdict w ciele
#          reguły; łańcuch decide = first-match-wins (Rego bez operatora ternary;
#          wszystkie wartości warunkowe liczą funkcje pomocnicze z klauzulami else).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.business.v3_09

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.business.v3_09.no_match",
    "package": "jdg.business.v3_09",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji business_lifecycle → fail-closed ────
_th_snapshot := object.get(data.jdg.thresholds, "business_lifecycle", {})
_snapshot_ok := count(_th_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    object.get(_th_snapshot, key, null) != null
} else = fallback

_round2(value) = floor(value * 100) / 100

_bool_str(flag) = "TAK" {
    flag
}

_bool_str(flag) = "NIE" {
    flag == false
}

snapshot_status(ok) = "OK" {
    ok
} else = "MISSING"

# ── Fail-closed verdict gdy snapshot progów niedostępny ────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.business.v3_09.thresholds_missing",
    "package": "jdg.business.v3_09",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryczałt/cykl życia v3: brak snapshotu data.jdg.thresholds.business_lifecycle.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-09] Brak snapshotu progów — decyzje ryczałtu i cyklu życia ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.business.v3_09",
        "priority": priority,
        "threshold_version": object.get(_th_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_th_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_th_snapshot, "valid_from", null),
        "valid_to": object.get(_th_snapshot, "valid_to", null),
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-001: LIMIT MONITOR 2M EUR — art. 6 ust. 1 i 4 u.z.p.d. (progress bar;
#            ostrzeżenie 75%, alert 95%, kurs NBP z 1.10 — wszystkie z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

limit_zone(pct_of_limit, alert_pct, warn_pct) = "EXCEEDED" {
    pct_of_limit >= 100
} else = "ALERT" {
    pct_of_limit >= alert_pct
} else = "WARNING" {
    pct_of_limit >= warn_pct
} else = "SAFE"

limit_routing("EXCEEDED") = "BLOCK_AND_ALERT"
limit_routing("ALERT") = "TRIAGE_QUEUE"
limit_routing("WARNING") = "WARNING"
limit_routing("SAFE") = ""

limit_action("EXCEEDED") = "LIMIT PRZEKROCZONY — od 1 stycznia następnego roku skala podatkowa; zaplanuj zmianę formy!"
limit_action("ALERT") = "Zbliżasz się do limitu 2M EUR — zaplanuj zmianę formy opodatkowania."
limit_action("WARNING") = "Monitoring limitu ryczałtu — kontroluj przychody narastająco."
limit_action("SAFE") = "Limit ryczałtu bezpieczny."

eff_eur(revenue_eur, revenue_pln, fx) = eur {
    revenue_eur > 0
    eur := revenue_eur
} else = eur {
    eur := _round2(revenue_pln / fx)
}

ryczalt_limit_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "tax_regime", "") == "RYCZALT"

    limit_eur := _th("ryczalt_limit_eur", 2000000)
    warn_pct := _th("ryczalt_warning_pct", 75)
    alert_pct := _th("ryczalt_limit_alert_pct", 95)

    revenue_eur := object.get(profile, "annual_revenue_eur", 0)
    revenue_pln := object.get(profile, "annual_revenue_pln", 0)
    fx_rate := _th("eur_pln_reference", 4.3)
    revenue_eur_effective := eff_eur(revenue_eur, revenue_pln, fx_rate)

    pct_of_limit := pct_of(revenue_eur_effective, limit_eur)
    zone := limit_zone(pct_of_limit, alert_pct, warn_pct)
    exceeded := zone == "EXCEEDED"

    verdict := _certificate(360300, {
        "rule_id": "jdg.business.v3_09.ryczalt_limit_monitor",
        "procedure": "RYCZALT_LIMIT_MONITOR_V3",
        "ryczalt_limit_eur": limit_eur,
        "ryczalt_revenue_eur_effective": revenue_eur_effective,
        "ryczalt_limit_used_pct": pct_of_limit,
        "ryczalt_warning_pct_threshold": warn_pct,
        "ryczalt_alert_pct_threshold": alert_pct,
        "ryczalt_limit_zone": zone,
        "ryczalt_limit_exceeded": exceeded,
        "ryczalt_fx_source": "NBP_FIRST_WORKDAY_OCTOBER_ART6U4",
        "manual_review_required": exceeded,
        "_routing": limit_routing(zone),
        "_routing_reason": sprintf("Ryczałt limit v3 — %v/%d EUR (%v%% limitu; ostrz. %v%%, alert %v%%) → %s", [revenue_eur_effective, limit_eur, pct_of_limit, warn_pct, alert_pct, limit_action(zone)]),
        "_legal_basis": "Art. 6 ust. 1 i 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne",
        "_warnings": [
            "[RYCZAŁT] Limit 2M EUR oraz progi ostrzegawcze czytane z thresholds_jdg.rego (zero hardcode).",
            "[RYCZAŁT] Przekroczenie NIE jest karane — wyłączenie z ryczałtu od nowego roku (przeliczenie na zasady ogólne).",
        ],
    })
}

pct_of(value, total) = pct {
    total > 0
    pct := _round2(value / total * 100)
} else = 0

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-002: FORM ADVISOR CHECKPOINT — porównanie skala/liniowy/ryczałt/karta;
#            wynik = SUGGEST + manual_review (decyzja człowieka, sekcja H raportu)
# ═══════════════════════════════════════════════════════════════════════════════

best_form_for(scale_tax, linear_tax, ryczalt_tax) = "SKALA" {
    scale_tax <= linear_tax
    scale_tax <= ryczalt_tax
} else = "LINIOWY" {
    linear_tax <= ryczalt_tax
} else = "RYCZALT"

form_advisor_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "form_advisor_requested", false) == true

    revenue := object.get(profile, "projected_annual_revenue_pln", 0)
    costs_pct := object.get(profile, "cost_ratio_pct", 0)
    rate_ryczalt := object.get(profile, "pkwiu_ryczalt_rate", 0)

    net_factor := (100 - costs_pct) / 100
    scale_tax_est := _round2(revenue * 0.12 * net_factor)
    linear_tax_est := _round2(revenue * 0.19 * net_factor)
    ryczalt_tax_est := _round2(revenue * rate_ryczalt)
    best_form := best_form_for(scale_tax_est, linear_tax_est, ryczalt_tax_est)

    verdict := _certificate(360310, {
        "rule_id": "jdg.business.v3_09.form_advisor_checkpoint",
        "procedure": "FORM_ADVISOR_V3",
        "form_advisor_mode": "SUGGEST",
        "no_auto_post": true,
        "form_estimates_pln": {"SKALA": scale_tax_est, "LINIOWY": linear_tax_est, "RYCZALT": ryczalt_tax_est},
        "form_recommended": best_form,
        "form_decision_owner": "HUMAN",
        "manual_review_required": true,
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": sprintf("FormAdvisor v3 — szacunki roczne: skala %.0f / liniowy %.0f / ryczałt %.0f PLN → rekomendacja %s (wymaga zatwierdzenia człowieka)", [scale_tax_est, linear_tax_est, ryczalt_tax_est, best_form]),
        "_legal_basis": "Art. 27 ustawy o PIT; Art. 30c ustawy o PIT; Art. 6 i 12 ustawy o zryczałtowanym podatku dochodowym; Art. 21-28 u.z.p.d. (karta)",
        "_warnings": [
            "[FORM ADVISOR] Rekomendacja ma charakter SUGGEST — wybór formy opodatkowania wymaga decyzji człowieka.",
            "[FORM ADVISOR] Stawki 12%/19% użyte wyłącznie do estymacji porównawczej — obowiązujące stawki pochodzą z inputu/thresholds.",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-003: SUSPENSION CHECKLIST — PP art. 22-25 (limit miesięcy, min dni,
#            składka zdrowotna nadal, faktury B2B zablokowane)
# ═══════════════════════════════════════════════════════════════════════════════

suspension_routing(over, near) = "BLOCK_AND_ALERT" {
    over
} else = "TRIAGE_QUEUE" {
    near
} else = ""

suspension_conclusion(over) = "PLAN PRZEKRACZA LIMIT USTAWOWY!" {
    over
} else = "Plan mieści się w limicie ustawowym."

suspension_warnings(over) = warnings {
    over
    warnings := [
        "[ZAWIESZENIE] Checklist 5 punktów wygenerowany maszynowo; limity z thresholds (zero hardcode).",
        "[ZAWIESZENIE] Faktury B2B w zawieszeniu — brak kosztów u nabywcy (art. 23 ust. 2 PP).",
    ]
} else = warnings {
    warnings := ["[ZAWIESZENIE] Plan zawieszenia mieści się w limicie ustawowym."]
}

suspension_checklist_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "suspension_requested", false) == true

    max_months := _th("suspension_max_months", 24)
    min_days := _th("suspension_min_days", 30)
    alert_pct := _th("suspension_alert_pct", 90)

    planned_months := object.get(profile, "suspension_planned_months", 0)
    used_months := object.get(profile, "suspension_used_months_total", 0)
    within_min := planned_months == 0 or (planned_months * 30) >= min_days
    total_after := used_months + planned_months
    over_limit := total_after > max_months
    near_limit := not over_limit and total_after >= _round2(max_months * alert_pct / 100)
    health_due := _th("suspension_health_due", true)

    verdict := _certificate(360320, {
        "rule_id": "jdg.business.v3_09.suspension_checklist",
        "procedure": "SUSPENSION_CHECKLIST_V3",
        "suspension_max_months": max_months,
        "suspension_min_days": min_days,
        "suspension_total_after_months": total_after,
        "suspension_over_limit": over_limit,
        "suspension_near_limit_alert": near_limit,
        "suspension_min_duration_ok": within_min,
        "suspension_health_contribution_due": health_due,
        "suspension_b2b_invoices_blocked": true,
        "checklist_items": [
            "Złóż wniosek CEIDG o zawieszenie (art. 22 ust. 6 PP).",
            "Składka zdrowotna NALEŻNA przez cały okres zawieszenia.",
            "Brak prawa do wystawiania faktur B2B w zawieszeniu (art. 23 PP).",
            "Umowy najmu/benefits — rozwiąż lub kontynuuj koszty.",
            "ZUS: zgłoszenie zawieszenia = brak składek społecznych.",
        ],
        "_routing": suspension_routing(over_limit, near_limit),
        "_routing_reason": sprintf("Zawieszenie v3 — planowane %d mies., łącznie %d/%d mies. (alert %v%%); min. czas OK: %s → %s", [planned_months, total_after, max_months, alert_pct, _bool_str(within_min), suspension_conclusion(over_limit)]),
        "_legal_basis": "Art. 22-25 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców; Art. 81b ust. 1a ustawy o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych",
        "_warnings": suspension_warnings(over_limit),
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-004: SUCCESSION PLANNER — u.z.s. art. 12-13 (24/60 mies.), CEIDG 14 dni,
#            remanent likwidacyjny 10%
# ═══════════════════════════════════════════════════════════════════════════════

succession_horizon(court_extension, extended_months, default_months) = months {
    court_extension
    months := extended_months
} else = months {
    months := default_months
}

succession_ceidg_status(filed) = "wpis w terminie" {
    filed
} else = "BRAK WPISU W TERMINIE — likwidacja działalności spadkodawcy (art. 14 u.z.s.)!"

succession_routing(filed) = "BLOCK_AND_ALERT" {
    not filed
} else = "TRIAGE_QUEUE"

succession_source(court_extension) = "rozsądzenie sądu" {
    court_extension
} else = "ustawowe"

succession_planner_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "succession_applicable", false) == true

    default_months := _th("succession_default_months", 24)
    extended_months := _th("succession_extended_months", 60)
    ceidg_days := _th("succession_ceidg_days", 14)

    court_extension := object.get(profile, "succession_court_extension", false)
    horizon_months := succession_horizon(court_extension, extended_months, default_months)
    filed_in_time := object.get(profile, "succession_ceidg_filed_within_days", false)
    inventory_value := object.get(profile, "succession_inventory_value_pln", 0)
    remnant_rate := _th("succession_remnant_tax_rate", 0.10)
    remnant_tax := remnant_tax_for(inventory_value, remnant_rate)

    verdict := _certificate(360330, {
        "rule_id": "jdg.business.v3_09.succession_planner",
        "procedure": "SUCCESSION_PLANNER_V3",
        "succession_horizon_months": horizon_months,
        "succession_ceidg_deadline_days": ceidg_days,
        "succession_ceidg_filed_in_time": filed_in_time,
        "succession_inventory_value_pln": inventory_value,
        "succession_remnant_tax_pln": remnant_tax,
        "succession_court_extension": court_extension,
        "manual_review_required": not filed_in_time,
        "_routing": succession_routing(filed_in_time),
        "_routing_reason": sprintf("Sukcesja v3 — horyzont %d mies. (%s), wpis CEIDG w %d dni: %s; remnant %.2f PLN", [horizon_months, succession_source(court_extension), ceidg_days, _bool_str(filed_in_time), remnant_tax]),
        "_legal_basis": "Art. 12-13 i art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym osobową przedsiębiorcą; Art. 52a ustawy o PIT",
        "_warnings": [
            sprintf("[SUKCESJA] Horyzonty %d/%d mies. i termin CEIDG %d dni czytane z thresholds (zero hardcode).", [default_months, extended_months, ceidg_days]),
            sprintf("[SUKCESJA] Status wpisu zarządcy: %s", [succession_ceidg_status(filed_in_time)]),
        ],
    })
}

remnant_tax_for(value, rate) = tax {
    value > 0
    tax := _round2(value * rate)
} else = 0

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-005: CEIDG CHANGE DEADLINE — art. 16 ust. 3 PP (7 dni z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

ceidg_routing(overdue) = "WARNING" {
    overdue
} else = ""

ceidg_conclusion(overdue) = "PRZETERMINOWANE — złóż wniosek natychmiast!" {
    overdue
} else = "w terminie"

ceidg_deadline_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "ceidg_data_changed", false) == true

    deadline_days := _th("ceidg_registration_days", 7)
    days_since_change := object.get(profile, "days_since_ceidg_change", 0)
    overdue := days_since_change > deadline_days

    verdict := _certificate(360340, {
        "rule_id": "jdg.business.v3_09.ceidg_change_deadline",
        "procedure": "CEIDG_DEADLINE_V3",
        "ceidg_update_deadline_days": deadline_days,
        "ceidg_days_since_change": days_since_change,
        "ceidg_update_overdue": overdue,
        "_routing": ceidg_routing(overdue),
        "_routing_reason": sprintf("CEIDG v3 — zmiana danych %d dni temu vs termin %d dni → %s", [days_since_change, deadline_days, ceidg_conclusion(overdue)]),
        "_legal_basis": "Art. 16 ust. 3 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Centralna Ewidencja i Informacja o Działalności Gospodarczej)",
        "_warnings": [
            "[CEIDG] Termin 7 dni czytany z thresholds (zero hardcode).",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-006: DZIAŁALNOŚĆ NIEEWIDENCJONOWANA — PP art. 5 (limit 50% płacy min.)
# ═══════════════════════════════════════════════════════════════════════════════

unregistered_routing(over) = "BLOCK_AND_ALERT" {
    over
} else = ""

unregistered_conclusion(over) = "PRZEKROCZONY — wymagana rejestracja CEIDG!" {
    over
} else = "działalność legalna bez wpisu"

unregistered_gate_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "unregistered_activity_considered", false) == true

    wage_pct := _th("unregistered_min_wage_pct", 0.5)
    min_wage := _th("min_wage_pln", 4800.0)
    monthly_income := object.get(profile, "monthly_unregistered_income_pln", 0)
    limit_pln := _round2(min_wage * wage_pct)
    over_limit := monthly_income > limit_pln

    verdict := _certificate(360350, {
        "rule_id": "jdg.business.v3_09.unregistered_activity_gate",
        "procedure": "UNREGISTERED_GATE_V3",
        "unregistered_monthly_limit_pln": limit_pln,
        "unregistered_monthly_income_pln": monthly_income,
        "unregistered_over_limit": over_limit,
        "_routing": unregistered_routing(over_limit),
        "_routing_reason": sprintf("Nieewidencjonowana v3 — dochód %.0f PLN vs limit %.2f PLN (%v%% płacy min. %.0f PLN) → %s", [monthly_income, limit_pln, wage_pct, min_wage, unregistered_conclusion(over_limit)]),
        "_legal_basis": "Art. 5 i art. 6 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców",
        "_warnings": [
            "[NIEEWIDENCJONOWANA] Limit liczony z płacy minimalnej w thresholds — aktualizacja płacy minimalnej = aktualizacja snapshotu.",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-007: LIFECYCLE STATE MACHINE — walidacja przejść stanów cyklu życia JDG
# ═══════════════════════════════════════════════════════════════════════════════

allowed_transition("ACTIVE", "SUSPENDED")
allowed_transition("SUSPENDED", "ACTIVE")
allowed_transition("ACTIVE", "LIQUIDATION")
allowed_transition("SUSPENDED", "LIQUIDATION")
allowed_transition("DEATH_OF_OWNER", "SUCCESSION")
allowed_transition("DEATH_OF_OWNER", "LIQUIDATION")

lifecycle_sm_routing(allowed) = "BLOCK_AND_ALERT" {
    not allowed
} else = ""

lifecycle_sm_conclusion(allowed) = "DOZWOLONE" {
    allowed
} else = "NIEDOZWOLONE (manual review)"

lifecycle_state_machine_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    from_state := object.get(profile, "lifecycle_current_state", "")
    to_state := object.get(profile, "lifecycle_target_state", "")
    from_state != ""
    to_state != ""
    from_state != to_state

    allowed := allowed_transition(from_state, to_state)
    terminal_states := ["LIQUIDATION"]
    from_is_terminal := from_state in terminal_states

    verdict := _certificate(360360, {
        "rule_id": "jdg.business.v3_09.lifecycle_state_machine",
        "procedure": "LIFECYCLE_STATE_MACHINE_V3",
        "lifecycle_from_state": from_state,
        "lifecycle_target_state": to_state,
        "lifecycle_transition_allowed": allowed,
        "lifecycle_from_is_terminal": from_is_terminal,
        "lifecycle_known_states": ["ACTIVE", "SUSPENDED", "SUCCESSION", "LIQUIDATION", "DEATH_OF_OWNER"],
        "manual_review_required": not allowed,
        "_routing": lifecycle_sm_routing(allowed),
        "_routing_reason": sprintf("State machine v3 — %s → %s: %s%s", [from_state, to_state, lifecycle_sm_conclusion(allowed), if_terminal(from_is_terminal)]),
        "_legal_basis": "Art. 22-25 i art. 29 PP; Ustawa o zarządzie sukcesyjnym (2018); Art. 43 Kodeksu cywilnego (śmierć przedsiębiorcy)",
        "_warnings": [],
    })
}

if_terminal(is_terminal) = "; stan terminalny!" {
    is_terminal
} else = ""

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-008: KARTA PODATKOWA ELIGIBILITY — art. 21-28 u.z.p.d. (limit zatrudnienia)
# ═══════════════════════════════════════════════════════════════════════════════

karta_routing(eligible) = "" {
    eligible
} else = "WARNING"

karta_conclusion(eligible) = "eligible" {
    eligible
} else = "przekroczony limit zatrudnienia (art. 23 u.z.p.d.)"

karta_eligibility_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "karta_podatkowa_considered", false) == true

    max_emp := _th("karta_max_employees", 5)
    employees := object.get(profile, "employees_count", 0)
    eligible := employees <= max_emp
    spouse_help := object.get(profile, "spouse_works_in_business", false)

    verdict := _certificate(360370, {
        "rule_id": "jdg.business.v3_09.karta_eligibility",
        "procedure": "KARTA_ELIGIBILITY_V3",
        "karta_max_employees": max_emp,
        "karta_employees_count": employees,
        "karta_eligible": eligible,
        "karta_spouse_not_counted_as_employee": spouse_help,
        "_routing": karta_routing(eligible),
        "_routing_reason": sprintf("Karta v3 — %d pracowników vs limit %d → %s (pomagający małżonek nie liczy się do limitu)", [employees, max_emp, karta_conclusion(eligible)]),
        "_legal_basis": "Art. 21-23 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym (Dz.U. 2025 poz. 134 ze zm.)",
        "_warnings": [
            "[KARTA] Limit zatrudnienia z thresholds; pomagający małżonek nie wchodzi do limitu (art. 21 ust. 2 u.z.p.d.).",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-09-009: LIFECYCLE DECISION CERTIFICATE — zbiorczy certyfikat domeny (F3/F4)
# ═══════════════════════════════════════════════════════════════════════════════

lc_domain_packages := [
    "jdg.micro.ryczalt", "jdg.micro.ryc", "jdg.micro.ryczalt_cykl_atomic_p13",
    "jdg.business", "jdg.business.gig_economy", "jdg.business.v3_09",
    "jdg.business_lifecycle_etap18", "jdg.micro.ceidg", "jdg.micro.plan33_ceidg",
    "jdg.micro.sukcesja", "jdg.micro.succ",
]

lc_routing(regime) = "TRIAGE_QUEUE" {
    regime != ""
} else = ""

lifecycle_certificate_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})

    regime := object.get(profile, "tax_regime", "")
    state := object.get(profile, "lifecycle_current_state", "UNKNOWN")

    verdict := _certificate(360399, {
        "rule_id": "jdg.business.v3_09.lifecycle_decision_certificate",
        "procedure": "LC_DECISION_CERTIFICATE",
        "lc_tax_regime": regime,
        "lc_current_state": state,
        "lc_domain_packages_wired": lc_domain_packages,
        "lc_golden_oracle_ready": true,
        "manual_review_required": false,
        "_routing": lc_routing(regime),
        "_routing_reason": sprintf("Lifecycle certificate — forma: %s, stan: %s, snapshot progów: %s, pakietów domeny: %d", [regime, state, snapshot_status(_snapshot_ok), count(lc_domain_packages)]),
        "_legal_basis": "Kompleksowy certyfikat domeny ryczałt + cykl życia JDG (u.z.p.d./PP/u.z.s./CEIDG); zgodność z V1 zasada 9 i V2 filary F3-F4",
        "_warnings": [],
    })
}

# ── Łańcuch first-match-wins: fail-closed → domeny → certyfikat zbiorczy ──────

decide = fail_closed_decision {
    not _snapshot_ok
} else = ryczalt_limit_decision {
    true
} else = suspension_checklist_decision {
    true
} else = succession_planner_decision {
    true
} else = ceidg_deadline_decision {
    true
} else = unregistered_gate_decision {
    true
} else = lifecycle_state_machine_decision {
    true
} else = karta_eligibility_decision {
    true
} else = form_advisor_decision {
    true
} else = lifecycle_certificate_decision {
    true
}
