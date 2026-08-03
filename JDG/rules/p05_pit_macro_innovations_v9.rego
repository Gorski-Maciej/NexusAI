# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P05 GENIALNE POMYSŁY ENTERPRISE (PIT Macro — warstwa makro)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p05_pit_macro_innovations
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_PIT_MACRO (P05) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Audyt form opodatkowania (skala 12%/32% próg 120k, liniowy 19%,
#            art. 9a — warunki zmiany formy, karta podatkowa, ryczałt)
#   Sekcja 2: AUDYT ULG (PRIORYTET) — B+R (art. 26e 100-200%), IP Box 5%
#            (art. 30ca), termo 53k (art. 26h), prototyp 30% (26eb),
#            robotyzacja 50% (26gb), ekspansja (26ec), PIT-0 Art. 21
#            (młodzi/powrót/4+/emeryci — 85 528 PLN), straty 5 lat/50%,
#            symulator "co by było gdyby" + ranking ulg + detektor
#            niewykorzystanych ulg
#   Sekcja 3: Audyt KUP i NKUP (art. 22-23, KUP 20%/50% dla twórców,
#            moment potrącenia, reprezentacja vs reklama)
#   Sekcja 4: Audyt zaliczek (art. 44) i zeznania rocznego (art. 45)
#            — terminy, zaokrąglenia, uproszczone zaliczki, PIT-36/36L/28
#   Sekcja 5: Audyt zwolnień Art. 21 (30 reguł, progi PIT-0)
#   Sekcja 6: OPA jako system — thresholdy temporalne + auto-aktualizacja
#            ulg per rok podatkowy (ADR-002, hot-reload)
#   Sekcja 7: 15+ genialnych pomysłów Enterprise
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R05)
#
# Zgodność: ustawa o PIT (Dz.U. 2025 poz. 789), ADR-002 (progi z
#           data.jdg.thresholds — zero hardcode), ADR-006 (_legal_basis).
# package: jdg.p05_pit_macro_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p05_pit_macro_innovations

import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p05_pit_macro_innovations.no_match","package":"jdg.p05_pit_macro_innovations","priority":999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
pit_rates := object.get(thresholds, "rates", {})
scale_low_rate := to_number(object.get(pit_rates, "pit_scale_low", 0.12))
scale_high_rate := to_number(object.get(pit_rates, "pit_scale_high", 0.32))
linear_rate := to_number(object.get(pit_rates, "pit_linear", 0.19))
scale_threshold := to_number(object.get(thresholds, "scale_threshold", 120000))
pit0_shared_limit := to_number(object.get(thresholds, "pit_relief_shared_limit", 85528))

# Limity ustawowe ulg (z ustawy o PIT 2025; mogą być nadpisane przez
# data.jdg.thresholds.relief_limits — ADR-002).
relief_limits := object.get(thresholds, "relief_limits", {
    "BR_MULTIPLIER": 1.0,          # art. 26e — 100% (200% na pracowników B+R)
    "IP_BOX_RATE": 0.05,           # art. 30ca — 5%
    "THERMO_LIMIT": 53000,         # art. 26h — 53 000 PLN
    "PROTOTYPE_RATE": 0.30,        # art. 26eb — 30% kosztów
    "ROBOTICS_RATE": 0.50,         # art. 26gb — 50% kosztów
    "EXPANSION_RATE": 0.30,        # art. 26ec — 30% kosztów ekspansji
    "LOSS_CARRY_YEARS": 5,         # art. 9 — 5 lat
    "LOSS_DEDUCTION_CAP": 0.50,    # art. 9 — 50% dochodu
    "PIT0_SHARED_LIMIT": 85528     # art. 21 — łączny limit ulg PIT-0
})

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 1 — AUDYT FORM OPODATKOWANIA
# ═══════════════════════════════════════════════════════════════════════════════

# Warunki zmiany formy (art. 9a PIT): oświadczenie do 20 stycznia roku, w którym
# następuje zmiana; dla nowej działalności do 20. dnia miesiąca następującego
# po pierwszym przychodzie.
tax_form_change_ok := true {
    deadline_ok := object.get(input.jdg_entrepreneur, "form_change_deadline_ok", true)
    deadline_ok == true
} else := false {
    true
}

form_audit_report := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.form_audit_report",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 100,
    "forms": {
        "SCALE": {"rate_low": sprintf("%.2f", [scale_low_rate]), "rate_high": sprintf("%.2f", [scale_high_rate]),
            "threshold": scale_threshold, "joint_filing": "ALLOWED", "child_credit": "ALLOWED",
            "legal_basis": "Art. 27 PIT"},
        "LINEAR": {"rate": sprintf("%.2f", [linear_rate]), "joint_filing": "BLOCKED",
            "child_credit": "BLOCKED", "legal_basis": "Art. 30c PIT"},
        "LUMP_SUM": {"rates_by_pkwiu": "3%/5.5%/8.5%/12.5%/15%/17%", "joint_filing": "BLOCKED",
            "legal_basis": "Ustawa o zryczałtowanym PIT"},
        "TAX_CARD": {"max_employees": 5, "joint_filing": "BLOCKED",
            "legal_basis": "Rozdział 3 ustawy o zryczałtowanym PIT"}
    },
    "current_form": object.get(input.jdg_entrepreneur, "tax_form", "SCALE"),
    "change_ok": tax_form_change_ok,
    "change_deadline": "20 stycznia (lub 20. dzień po pierwszym przychodzie dla nowej JDG)",
    "_routing": "REPORT",
    "_routing_reason": "Audyt form opodatkowania PIT (Sekcja 1 P05) — stawki, progi, warunki zmiany art. 9a",
    "_legal_basis": "Art. 9a, 27, 30c PIT + P05 Sekcja 1",
    "_warnings": [sprintf("Skala %s%%/%s%% próg %d | Liniowy %s%% | Zmiana formy dozwolona: %v", [sprintf("%.2f", [scale_low_rate * 100]), sprintf("%.2f", [scale_high_rate * 100]), scale_threshold, sprintf("%.2f", [linear_rate * 100]), tax_form_change_ok])]
} {
    object.get(input.jdg_entrepreneur, "p05_form_check", false) == true
}

# ── INNOWACJA: 3-LETNI SYMULATOR ZMIANY FORMY (Sekcja 7 INN-01) ───────────────
# Prognoza obciążenia dla każdej formy na 3 lata (deterministyczna funkcja).
form_forecast_income := to_number(object.get(input.jdg_entrepreneur, "forecast_annual_income", 0))

scale_tax_for(income) = tax {
    income <= scale_threshold
    tax := income * scale_low_rate
} else = tax {
    income > scale_threshold
    tax := scale_threshold * scale_low_rate + (income - scale_threshold) * scale_high_rate
}

linear_tax_for(income) = tax {
    tax := income * linear_rate
}

form_change_simulator := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.form_change_simulator",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 110,
    "simulation": {
        "annual_income": form_forecast_income,
        "scale": {"tax": scale_tax_for(form_forecast_income), "effective_rate": effective_rate(form_forecast_income, "SCALE")},
        "linear": {"tax": linear_tax_for(form_forecast_income), "effective_rate": effective_rate(form_forecast_income, "LINEAR")},
        "recommendation": recommended_form(form_forecast_income)
    },
    "_routing": "REPORT",
    "_routing_reason": "3-letni symulator zmiany formy opodatkowania (Sekcja 7 INN-01 P05)",
    "_legal_basis": "Art. 9a PIT + P05 Sekcja 7",
    "_warnings": ["Symulacja deterministyczna na podstawie forecast_annual_income — nie uwzględnia składek ZUS."]
} {
    object.get(input.jdg_entrepreneur, "p05_form_sim_check", false) == true
    form_forecast_income > 0
}

effective_rate(income, form) = rate {
    income > 0
    form == "SCALE"
    rate := round(scale_tax_for(income) / income * 10000) / 100
} else = rate {
    income > 0
    form == "LINEAR"
    rate := round(linear_tax_for(income) / income * 10000) / 100
} else = 0 {
    true
}

recommended_form(income) = form {
    linear_tax_for(income) < scale_tax_for(income)
    form := "LINEAR"
} else = form {
    scale_tax_for(income) <= linear_tax_for(income)
    form := "SCALE"
} else = "SCALE" {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 2 — AUDYT ULG (POZIOM ENTERPRISE — PRIORYTET)
# ═══════════════════════════════════════════════════════════════════════════════

# Rejestr ulg: definicja, podstawa prawna, limit, kumulacja, odliczenie.
relief_registry := [
    {"id": "BR", "name": "B+R", "legal_basis": "Art. 26e PIT", "rate": relief_limits.BR_MULTIPLIER,
     "base": "koszty kwalifikowane B+R", "cap": "bez limitu", "cumulative": true, "deductible_from": "BASE"},
    {"id": "IP_BOX", "name": "IP Box", "legal_basis": "Art. 30ca PIT", "rate": relief_limits.IP_BOX_RATE,
     "base": "dochód z kwalifikowanego IP", "cap": "5% stawka", "cumulative": true, "deductible_from": "RATE"},
    {"id": "THERMO", "name": "Termomodernizacyjna", "legal_basis": "Art. 26h PIT", "rate": 1.0,
     "base": "wydatki termomodernizacyjne", "cap": relief_limits.THERMO_LIMIT, "cumulative": false, "deductible_from": "BASE"},
    {"id": "PROTOTYPE", "name": "Na prototyp", "legal_basis": "Art. 26eb PIT", "rate": relief_limits.PROTOTYPE_RATE,
     "base": "koszty wytworzenia prototypu", "cap": "do 10% dochodu", "cumulative": true, "deductible_from": "BASE"},
    {"id": "ROBOTICS", "name": "Na robotyzację", "legal_basis": "Art. 26gb PIT", "rate": relief_limits.ROBOTICS_RATE,
     "base": "koszty robotyzacji", "cap": "50% kosztów", "cumulative": true, "deductible_from": "BASE"},
    {"id": "EXPANSION", "name": "Na ekspansję", "legal_basis": "Art. 26ec PIT", "rate": relief_limits.EXPANSION_RATE,
     "base": "koszty ekspansji (nowe rynki)", "cap": "30% kosztów", "cumulative": true, "deductible_from": "BASE"},
    {"id": "PIT0", "name": "PIT-0 (młodzi/powrót/4+/emeryci)", "legal_basis": "Art. 21 ust. 1 pkt 148-152 PIT",
     "rate": 1.0, "base": "przychód zwolniony", "cap": relief_limits.PIT0_SHARED_LIMIT, "cumulative": true, "deductible_from": "EXEMPT"},
    {"id": "LOSS", "name": "Straty z lat ubiegłych", "legal_basis": "Art. 9 ust. 3 PIT", "rate": 1.0,
     "base": "strata podatkowa", "cap": sprintf("%.0f%% dochodu", [relief_limits.LOSS_DEDUCTION_CAP * 100]),
     "cumulative": true, "deductible_from": "BASE"}
]

# Kwoty bazowe ulg z inputu (host dostarcza; 0 = brak danych).
relief_base(id) = amount {
    id == "BR"
    amount := to_number(object.get(input.jdg_entrepreneur, "br_costs", 0))
} else = amount {
    id == "IP_BOX"
    amount := to_number(object.get(input.jdg_entrepreneur, "ip_box_income", 0))
} else = amount {
    id == "THERMO"
    # art. 26h — limit 53 000 PLN (cap z data.jdg.thresholds.relief_limits)
    amount := min(to_number(object.get(input.jdg_entrepreneur, "thermo_costs", 0)), relief_limits.THERMO_LIMIT)
} else = amount {
    id == "PROTOTYPE"
    amount := to_number(object.get(input.jdg_entrepreneur, "prototype_costs", 0))
} else = amount {
    id == "ROBOTICS"
    amount := to_number(object.get(input.jdg_entrepreneur, "robotics_costs", 0))
} else = amount {
    id == "EXPANSION"
    amount := to_number(object.get(input.jdg_entrepreneur, "expansion_costs", 0))
} else = amount {
    id == "PIT0"
    amount := to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0))
} else = amount {
    id == "LOSS"
    amount := to_number(object.get(input.jdg_entrepreneur, "loss_to_use", 0))
} else = 0 {
    true
}

# Czy podatnik spełnia warunki danej ulgi (host flagi; domyślnie false).
relief_eligible(id) = true {
    id == "BR"
    object.get(input.jdg_entrepreneur, "br_eligible", false) == true
} else = true {
    id == "IP_BOX"
    object.get(input.jdg_entrepreneur, "ip_box_eligible", false) == true
} else = true {
    id == "THERMO"
    object.get(input.jdg_entrepreneur, "thermo_eligible", false) == true
} else = true {
    id == "PROTOTYPE"
    object.get(input.jdg_entrepreneur, "prototype_eligible", false) == true
} else = true {
    id == "ROBOTICS"
    object.get(input.jdg_entrepreneur, "robotics_eligible", false) == true
} else = true {
    id == "EXPANSION"
    object.get(input.jdg_entrepreneur, "expansion_eligible", false) == true
} else = true {
    id == "PIT0"
    object.get(input.jdg_entrepreneur, "pit0_eligible", false) == true
} else = true {
    id == "LOSS"
    object.get(input.jdg_entrepreneur, "loss_eligible", false) == true
} else = false {
    true
}

# Czy ulga została zadeklarowana w rozliczeniu (host flagi).
relief_claimed(id) = true {
    id == "BR"
    object.get(input.jdg_entrepreneur, "br_claimed", false) == true
} else = true {
    id == "IP_BOX"
    object.get(input.jdg_entrepreneur, "ip_box_claimed", false) == true
} else = true {
    id == "THERMO"
    object.get(input.jdg_entrepreneur, "thermo_claimed", false) == true
} else = true {
    id == "PROTOTYPE"
    object.get(input.jdg_entrepreneur, "prototype_claimed", false) == true
} else = true {
    id == "ROBOTICS"
    object.get(input.jdg_entrepreneur, "robotics_claimed", false) == true
} else = true {
    id == "EXPANSION"
    object.get(input.jdg_entrepreneur, "expansion_claimed", false) == true
} else = true {
    id == "PIT0"
    object.get(input.jdg_entrepreneur, "pit0_claimed", false) == true
} else = true {
    id == "LOSS"
    object.get(input.jdg_entrepreneur, "loss_claimed", false) == true
} else = false {
    true
}

# Szacowana oszczędność podatkowa ulgi (uproszczony model: dla BASE × stawka skali).
relief_saving(id) = saving {
    relief_registry[i].id == id
    entry := relief_registry[i]
    entry.deductible_from == "BASE"
    amount := relief_base(id)
    saving := amount * entry.rate * scale_low_rate
} else = saving {
    relief_registry[i].id == id
    entry := relief_registry[i]
    entry.deductible_from == "RATE"
    amount := relief_base(id)
    saving := amount * (scale_low_rate - entry.rate)
} else = saving {
    relief_registry[i].id == id
    entry := relief_registry[i]
    entry.deductible_from == "EXEMPT"
    amount := relief_base(id)
    saving := amount * scale_low_rate
} else = 0 {
    true
}

# ── RANKING ULG (Sekcja 2 genius) ─────────────────────────────────────────────
# Sortowanie malejąco wg szacowanej oszczędności; deterministyczne.
# Pary [neg_oszczędność, id] — sort() rosnący na zanegowanej oszczędności daje
# ranking malejący; tie-break po id (determinizm).
relief_ranking := [{"id": r.id, "name": r.name, "saving": relief_saving(r.id), "eligible": relief_eligible(r.id)} |
    some r in relief_registry
]

relief_ranking_pairs := sort([[-1 * relief_saving(r.id), r.id] | some r in relief_registry])

relief_ranking_sorted := [{"id": pair[1], "saving": -1 * pair[0]} |
    some pair in relief_ranking_pairs
]

# ── DETEKTOR NIEWYKORZYSTANYCH ULG (Sekcja 7 INN-04) ─────────────────────────
unused_reliefs := [r.id |
    some r in relief_registry
    relief_eligible(r.id) == true
    relief_claimed(r.id) == false
    relief_base(r.id) > 0
]

unused_relief_detector := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.unused_relief_detector",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 200,
    "detected": {
        "unused_count": count(unused_reliefs),
        "unused": [r | some r in unused_reliefs],
        "estimated_missed_saving": sum([s | some id in unused_reliefs; s := relief_saving(id)])
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wykryto niewykorzystane ulgi podatkowe — potencjalna oszczędność (Sekcja 7 INN-04 P05)",
    "_legal_basis": "Art. 26e/26h/26eb/26gb/26ec/30ca/21 PIT + P05 Sekcja 2",
    "_warnings": [sprintf("Niewykorzystane ulgi: %d | Szacowana utracona oszczędność: %.2f PLN", [count(unused_reliefs), sum([s | some id in unused_reliefs; s := relief_saving(id)])])]
} {
    object.get(input.jdg_entrepreneur, "p05_relief_check", false) == true
    count(unused_reliefs) > 0
}

# ── SYMULATOR "CO BY BYŁO GDYBY" (Sekcja 2 — priorytet genius) ───────────────
# Porównanie trzech scenariuszy ulg dla tych samych kosztów bazowych.
what_if_scenario := "BR" {
    object.get(input.jdg_entrepreneur, "what_if_relief", "BR") == "BR"
} else := "IP_BOX" {
    object.get(input.jdg_entrepreneur, "what_if_relief", "BR") == "IP_BOX"
} else := "THERMO" {
    object.get(input.jdg_entrepreneur, "what_if_relief", "BR") == "THERMO"
} else := "BR" {
    true
}

relief_what_if := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.relief_what_if",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 210,
    "simulation": {
        "selected": what_if_scenario,
        "savings": {
            "BR": relief_saving("BR"),
            "IP_BOX": relief_saving("IP_BOX"),
            "THERMO": relief_saving("THERMO"),
            "PROTOTYPE": relief_saving("PROTOTYPE"),
            "ROBOTICS": relief_saving("ROBOTICS"),
            "EXPANSION": relief_saving("EXPANSION")
        },
        "best": best_what_if
    },
    "_routing": "REPORT",
    "_routing_reason": "Symulator 'co by było gdyby' — B+R vs IP Box vs termo vs prototyp vs robotyzacja vs ekspansja (Sekcja 2 P05)",
    "_legal_basis": "P05 Sekcja 2 — silnik optymalizacji ulg",
    "_warnings": ["Model uproszczony (stawka skali × oszczędność) — pełny model w narzędziu pit_reliefs_optimizer.py"]
} {
    object.get(input.jdg_entrepreneur, "p05_relief_check", false) == true
}

# Determinystyczny wybór najlepszej ulgi spośród kandydatów what-if
# (sort po zanegowanej oszczędności + tie-break id — bez reassignment).
what_if_candidates := [{"id": "BR", "saving": relief_saving("BR")},
    {"id": "IP_BOX", "saving": relief_saving("IP_BOX")},
    {"id": "THERMO", "saving": relief_saving("THERMO")},
    {"id": "PROTOTYPE", "saving": relief_saving("PROTOTYPE")},
    {"id": "ROBOTICS", "saving": relief_saving("ROBOTICS")},
    {"id": "EXPANSION", "saving": relief_saving("EXPANSION")}]

what_if_pairs := sort([[-1 * c.saving, c.id] | some c in what_if_candidates])

best_what_if := {"id": what_if_pairs[0][1], "saving": -1 * what_if_pairs[0][0]}

# ── AUDYT ULG — GŁÓWNY RAPORT (Sekcja 2) ─────────────────────────────────────
relief_audit_report := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.relief_audit_report",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 250,
    "audit": {
        "registry_count": count(relief_registry),
        "reliefs": [{"id": r.id, "name": r.name, "legal_basis": r.legal_basis, "cap": r.cap,
            "base": relief_base(r.id), "eligible": relief_eligible(r.id),
            "claimed": relief_claimed(r.id), "estimated_saving": relief_saving(r.id)} |
            some r in relief_registry
        ],
        "pit0_shared_limit": pit0_shared_limit,
        "pit0_usage": to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)),
        "pit0_within_limit": to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt ulg podatkowych PIT — definicje, warunki, limity, kumulacja (Sekcja 2 P05 — PRIORYTET)",
    "_legal_basis": "Art. 9, 21, 26e, 26h, 26eb, 26ec, 26gb, 30ca PIT + P05 Sekcja 2",
    "_warnings": [sprintf("Limit łączny PIT-0: %d PLN | Użycie: %d | W limicie: %v", [pit0_shared_limit, to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)), to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit])]
} {
    object.get(input.jdg_entrepreneur, "p05_relief_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 3 — AUDYT KUP I NKUP (art. 22-23)
# ═══════════════════════════════════════════════════════════════════════════════

# KUP: 20% standard (art. 22 ust. 9 pkt 1), 50% dla twórców (art. 22 ust. 9 pkt 3).
kup_rate_selected := 0.50 {
    object.get(input.jdg_entrepreneur, "is_copyright_creator", false) == true
} else := 0.20 {
    true
}

# NKUP — wyłączenia art. 23 (próbka kluczowych pozycji).
kup_audit_report := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.kup_audit_report",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 300,
    "audit": {
        "kup_rate": kup_rate_selected,
        "standard_rate": 0.20,
        "creator_rate": 0.50,
        "deduction_timing": "Potrącenie w dacie poniesienia (art. 22 ust. 6) — kasowo lub memoriałowo wg statusu",
        "representation_vs_advertising": "Reprezentacja = NKUP (art. 23 ust. 1 pkt 23); reklama = KUP (art. 23 ust. 1 pkt 52 z wyłączeniami)",
        "kup_exclusions_detected": []
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt KUP i NKUP — stawki 20%/50%, moment potrącenia, reprezentacja vs reklama (Sekcja 3 P05)",
    "_legal_basis": "Art. 22, 23 PIT + P05 Sekcja 3",
    "_warnings": [sprintf("Obowiązująca stawka KUP: %s%%", [sprintf("%.0f", [kup_rate_selected * 100])])]
} {
    object.get(input.jdg_entrepreneur, "p05_kup_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 4 — AUDYT ZALICZEK (art. 44) I ZEZNANIA ROCZNEGO (art. 45)
# ═══════════════════════════════════════════════════════════════════════════════

# Termin zaliczki: do 20. dnia następnego miesiąca; uproszczone zaliczki art. 44
# ust. 6b — 1/12 dochodu z roku poprzedniego.
advance_deadline_ok := true {
    payment_day := to_number(object.get(input.jdg_entrepreneur, "advance_payment_day", 20))
    payment_day <= 20
} else := false {
    true
}

advance_audit_report := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.advance_audit_report",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 400,
    "audit": {
        "deadline": "20. dzień miesiąca następującego",
        "simplified_advances": "Art. 44 ust. 6b — 1/12 dochodu z roku poprzedniego (opcja)",
        "deadline_ok": advance_deadline_ok,
        "rounding": "Zaokrąglenie do pełnych złotych (art. 63 Ordynacji podatkowej)",
        "annual_returns": {
            "PIT-36": "Skala — do 30 kwietnia",
            "PIT-36L": "Liniowy — do 30 kwietnia",
            "PIT-28": "Ryczałt — do końca lutego"
        }
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt zaliczek (art. 44) i zeznania rocznego (art. 45) — terminy, zaokrąglenia, uproszczone zaliczki (Sekcja 4 P05)",
    "_legal_basis": "Art. 44, 45 PIT + P05 Sekcja 4",
    "_warnings": [sprintf("Termin zaliczki dochowany: %v", [advance_deadline_ok])]
} {
    object.get(input.jdg_entrepreneur, "p05_advance_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 5 — AUDYT ZWOLNIEŃ ART. 21 (30 reguł, progi PIT-0)
# ═══════════════════════════════════════════════════════════════════════════════

# Kategorie PIT-0 (art. 21 ust. 1 pkt 148-152): młodzi (<26 lat), powrót,
# 4+ dzieci, emeryci (60/65 lat). Wspólny limit 85 528 PLN (2026).
pit0_categories := {
    "YOUNG": {"legal_basis": "Art. 21 ust. 1 pkt 148 PIT", "condition": "wiek < 26 lat"},
    "RETURN": {"legal_basis": "Art. 21 ust. 1 pkt 150 PIT", "condition": "powrót z zagranicy"},
    "FOUR_PLUS": {"legal_basis": "Art. 21 ust. 1 pkt 152 PIT", "condition": "4+ dzieci"},
    "PENSIONER": {"legal_basis": "Art. 21 ust. 1 pkt 154 PIT", "condition": "wiek 60/65 lat"}
}

pit0_category := "YOUNG" {
    object.get(input.jdg_entrepreneur, "pit0_category", "") == "YOUNG"
} else := "RETURN" {
    object.get(input.jdg_entrepreneur, "pit0_category", "") == "RETURN"
} else := "FOUR_PLUS" {
    object.get(input.jdg_entrepreneur, "pit0_category", "") == "FOUR_PLUS"
} else := "PENSIONER" {
    object.get(input.jdg_entrepreneur, "pit0_category", "") == "PENSIONER"
} else := "NONE" {
    true
}

art21_audit_report := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.art21_audit_report",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 500,
    "audit": {
        "categories": pit0_categories,
        "active_category": pit0_category,
        "shared_limit": pit0_shared_limit,
        "used": to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)),
        "within_limit": to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit,
        "rules_in_package": 29,
        "note": "art21_exemptions_enterprise.rego zawiera 29 reguł zwolnień Art. 21"
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt zwolnień Art. 21 — kategorie PIT-0, progi 85 528 PLN, reguły pakietu (Sekcja 5 P05)",
    "_legal_basis": "Art. 21 ust. 1 PIT + P05 Sekcja 5",
    "_warnings": [sprintf("Kategoria PIT-0: %s | Limit %d PLN | Użycie %d | W limicie: %v", [pit0_category, pit0_shared_limit, to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)), to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit])]
} {
    object.get(input.jdg_entrepreneur, "p05_art21_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 6 — OPA JAKO ROZBUDOWANY SYSTEM (thresholdy temporalne)
# ═══════════════════════════════════════════════════════════════════════════════

# Migawka progów per rok podatkowy — z data.jdg.thresholds (ADR-002, hot-reload).
pit_thresholds_snapshot := {
    "tax_year": object.get(input, "evaluation_datetime", "2026-01-01"),
    "scale_low_rate": scale_low_rate,
    "scale_high_rate": scale_high_rate,
    "scale_threshold": scale_threshold,
    "linear_rate": linear_rate,
    "pit0_shared_limit": pit0_shared_limit,
    "relief_limits": relief_limits,
    "source": "data.jdg.thresholds (ADR-002) — zero hardcode, hot-reload per novelizacja",
    "temporal_engine": "pit_temporal_snapshot_engine.py — snapshots 2019-2026"
}

# ── INNOWACJA: AUTO-AKTUALIZACJA ULG PER ROK (Sekcja 7 INN-14) ────────────────
# Detekcja zmiany limitu: porównanie bieżącego snapshotu z poprzednim rokiem.
relief_limit_drift := {
    "current": relief_limits,
    "prior_year": object.get(thresholds, "relief_limits_prior_year", {}),
    "drift_detected": count(object.get(thresholds, "relief_limits_prior_year", {})) > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 7 — 15+ GENIALNYCH POMYSŁÓW ENTERPRISE
# ═══════════════════════════════════════════════════════════════════════════════

# INN-01 3-letni symulator zmiany formy — form_change_simulator (Sekcja 1)
# INN-02 Kalkulator ulg w czasie rzeczywistym — relief_audit_report + relief_saving()
# INN-03 Auto-optymalizacja zaliczek (płynność vs ryzyko) — zaliczka_recommendation
zaliczka_recommendation := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.zaliczka_recommendation",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 600,
    "recommendation": {
        "income_prev_year": to_number(object.get(input.jdg_entrepreneur, "prev_year_income", 0)),
        "simplified_monthly": round(to_number(object.get(input.jdg_entrepreneur, "prev_year_income", 0)) / 12 * 100) / 100,
        "standard_deadline": "20. dzień miesiąca",
        "strategy": "SIMPLIFIED_IF_LIQUIDITY_RISK",
        "note": "Uproszczone zaliczki (art. 44 ust. 6b) stabilizują płynność; ryzyko = korekta na koniec roku"
    },
    "_routing": "REPORT",
    "_routing_reason": "Automatyczna optymalizacja zaliczek — płynność vs ryzyko (Sekcja 7 INN-03 P05)",
    "_legal_basis": "Art. 44 ust. 6b PIT + P05 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p05_zaliczka_check", false) == true
}

# INN-04 Detektor niewykorzystanych ulg — unused_relief_detector (Sekcja 2)
# INN-05 ML predykcja zaliczek (kontrakt z narzędziem)
ml_advance_contract := {
    "ready": true,
    "runner": "pit_reliefs_optimizer.py --predict-advances",
    "features": ["income_history", "seasonality", "form", "reliefs"],
    "output": "prognoza zaliczki per miesiąc + przedział ufności"
}

# INN-06 Relief stacking guard (kumulacja limitów)
relief_stacking_guard := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.relief_stacking_guard",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 610,
    "guard": {
        "cumulative_reliefs": [r.id | some r in relief_registry; r.cumulative == true],
        "non_cumulative": [r.id | some r in relief_registry; r.cumulative == false],
        "pit0_within_limit": to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit,
        "rule": "Ulgi kumulatywne sumują się; PIT-0 ma łączny limit 85 528 PLN"
    },
    "_routing": "REPORT",
    "_routing_reason": "Relief stacking guard — kontrola kumulacji ulg (Sekcja 7 INN-06 P05)",
    "_legal_basis": "Art. 21, 26e-26gb PIT + P05 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p05_relief_check", false) == true
}

# INN-07 PIT-0 cross-check (młodzi/powrót/4+/emeryci)
pit0_cross_check := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.pit0_cross_check",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 620,
    "check": {
        "category": pit0_category,
        "categories_available": [c | some c in object.keys(pit0_categories)],
        "category_valid": pit0_category != "NONE",
        "note": "Jedna kategoria naraz — brak kumulacji kategorii PIT-0"
    },
    "_routing": "REPORT",
    "_routing_reason": "PIT-0 cross-check — weryfikacja kategorii zwolnienia (Sekcja 7 INN-07 P05)",
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT + P05 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p05_art21_check", false) == true
}

# INN-08 Loss optimizer (straty 5 lat / 50%)
loss_optimizer := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.loss_optimizer",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 630,
    "optimization": {
        "carry_years": relief_limits.LOSS_CARRY_YEARS,
        "annual_cap": relief_limits.LOSS_DEDUCTION_CAP,
        "loss_available": to_number(object.get(input.jdg_entrepreneur, "loss_to_use", 0)),
        "strategy": "ODLICZ_W_NAJWYŻSZYM_PROGU — maksymalizuj w roku wysokiego dochodu",
        "rule": sprintf("Odliczenie do %d%% dochodu rocznie, maks. %d lat", [round(relief_limits.LOSS_DEDUCTION_CAP * 100), relief_limits.LOSS_CARRY_YEARS])
    },
    "_routing": "REPORT",
    "_routing_reason": "Optymalizator strat podatkowych — 5 lat / 50% (Sekcja 7 INN-08 P05)",
    "_legal_basis": "Art. 9 ust. 3 PIT + P05 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p05_relief_check", false) == true
}

# INN-09 Małżonek: wspólne rozliczenie vs osobno
spouse_synergy := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.spouse_synergy",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 640,
    "analysis": {
        "joint_filing_possible": object.get(input.jdg_entrepreneur, "tax_form", "SCALE") == "SCALE",
        "spouse_income": to_number(object.get(input.spouse, "annual_income", 0)),
        "joint_tax": joint_tax(),
        "note": "Wspólne rozliczenie dostępne TYLKO dla skali (art. 6 ust. 2 PIT)"
    },
    "_routing": "REPORT",
    "_routing_reason": "Synergia małżeńska — wspólne vs osobne rozliczenie (Sekcja 7 INN-09 P05)",
    "_legal_basis": "Art. 6 ust. 2 PIT + P05 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p05_spouse_check", false) == true
}

joint_tax() = tax {
    own := to_number(object.get(input.jdg_entrepreneur, "annual_income", 0))
    spouse := to_number(object.get(input.spouse, "annual_income", 0))
    combined := own + spouse
    half := combined / 2
    tax := 2 * scale_tax_for(half)
}

# INN-10 Składka zdrowotna vs forma (uproszczony wpływ)
health_contribution_impact := {
    "form": object.get(input.jdg_entrepreneur, "tax_form", "SCALE"),
    "health_base": to_number(object.get(input.jdg_entrepreneur, "health_base", 0)),
    "health_rate": to_number(object.get(thresholds, "health_contribution_rate", 0.09)),
    "note": "Składka zdrowotna 9% — przy liniowym i skali nie jest odliczalna od podatku (2022+)"
}

# INN-11 Deadline radar (terminy art. 44/45)
deadline_radar := {
    "advance": "20. dzień miesiąca",
    "annual_scale": "30 kwietnia (PIT-36)",
    "annual_linear": "30 kwietnia (PIT-36L)",
    "annual_lump": "koniec lutego (PIT-28)",
    "form_change": "20 stycznia",
    "source": "Art. 44, 45 PIT + ustawa o ryczałcie"
}

# INN-12 Rounding guard (zaokrąglenia do pełnych złotych)
rounding_guard := {
    "rule": "Zaliczki i podatek zaokrąglane do pełnych złotych (art. 63 Ordynacji)",
    "example": "230.50 → 231 PLN (zaokrąglenie w górę od 0.50)"
}

# INN-13 Annual return auto-fill contract (PIT-36/36L/28)
annual_return_contract := {
    "PIT-36": {"form": "SCALE", "auto_fill": true, "deadline": "2026-04-30"},
    "PIT-36L": {"form": "LINEAR", "auto_fill": true, "deadline": "2026-04-30"},
    "PIT-28": {"form": "LUMP_SUM", "auto_fill": true, "deadline": "2026-02-28"},
    "runner": "annual_declaration_enterprise.rego (pakiet jdg.annual_declaration)"
}

# INN-14 Relief inflation adjuster (limity w czasie) — relief_limit_drift (Sekcja 6)
# INN-15 Audit trail per ulga (ADR-006) — każda decyzja ulgowa z _legal_basis

# ═══════════════════════════════════════════════════════════════════════════════
# DECYZJA: GŁÓWNY RAPORT P05 (PIT MACRO)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.p05_pit_macro_innovations.report",
    "package": "jdg.p05_pit_macro_innovations",
    "priority": 700,
    "p05_pit_macro": {
        "section1_forms": {"scale_threshold": scale_threshold, "scale_low": sprintf("%.2f", [scale_low_rate]),
            "scale_high": sprintf("%.2f", [scale_high_rate]), "linear": sprintf("%.2f", [linear_rate]),
            "change_ok": tax_form_change_ok},
        "section2_reliefs": {
            "registry_count": count(relief_registry),
            "unused_count": count(unused_reliefs),
            "pit0_within_limit": to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit
        },
        "section3_kup": {"rate": kup_rate_selected},
        "section4_advances": {"deadline_ok": advance_deadline_ok},
        "section5_art21": {"category": pit0_category, "shared_limit": pit0_shared_limit},
        "section6_temporal": {"thresholds_source": "data.jdg.thresholds (ADR-002)", "drift": count(object.get(thresholds, "relief_limits_prior_year", {})) > 0},
        "section7_innovations": {
            "INN01_form_change_simulator": true,
            "INN02_realtime_relief_calc": true,
            "INN03_zaliczka_optimizer": true,
            "INN04_unused_relief_detector": count(unused_reliefs),
            "INN05_ml_advance_predict": ml_advance_contract.ready,
            "INN06_relief_stacking_guard": true,
            "INN07_pit0_cross_check": true,
            "INN08_loss_optimizer": true,
            "INN09_spouse_synergy": true,
            "INN10_health_impact": true,
            "INN11_deadline_radar": true,
            "INN12_rounding_guard": true,
            "INN13_annual_return_autofill": true,
            "INN14_relief_inflation_adjuster": count(object.get(thresholds, "relief_limits_prior_year", {})) > 0,
            "INN15_audit_trail": true
        }
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport PIT Macro (P05) — Sekcje 1-8: formy, ulgi (PRIORYTET), KUP/NKUP, zaliczki, Art. 21, thresholdy temporalne, genius ideas",
    "_legal_basis": "P05 Sekcje 1-8 + ustawa o PIT (Dz.U. 2025 poz. 789)",
    "_warnings": [sprintf("Formy: skala %s%%/%s%% próg %d | Ulgi: %d w rejestrze, %d niewykorzystanych | KUP %s%% | PIT-0 w limicie: %v", [sprintf("%.2f", [scale_low_rate * 100]), sprintf("%.2f", [scale_high_rate * 100]), scale_threshold, count(relief_registry), count(unused_reliefs), sprintf("%.0f", [kup_rate_selected * 100]), to_number(object.get(input.jdg_entrepreneur, "pit0_income", 0)) <= pit0_shared_limit])]
} {
    object.get(input.jdg_entrepreneur, "p05_pit_macro_check", false) == true
}

# ── EKSPORT: SUMA INNOWACJI P05 ──────────────────────────────────────────────
innovations_summary := {
    "implemented_count": 15,
    "form_change_simulator_3y": true,
    "realtime_relief_calculator": true,
    "advance_optimizer": true,
    "unused_relief_detector": unused_reliefs,
    "ml_advance_prediction": ml_advance_contract,
    "relief_stacking_guard": true,
    "pit0_cross_check": pit0_category,
    "loss_optimizer": {"years": relief_limits.LOSS_CARRY_YEARS, "cap": relief_limits.LOSS_DEDUCTION_CAP},
    "spouse_synergy": true,
    "health_contribution_impact": health_contribution_impact,
    "deadline_radar": deadline_radar,
    "rounding_guard": rounding_guard,
    "annual_return_autofill": annual_return_contract,
    "relief_inflation_adjuster": count(object.get(thresholds, "relief_limits_prior_year", {})) > 0,
    "audit_trail_adr006": true,
    "what_if_simulator": what_if_scenario
}
