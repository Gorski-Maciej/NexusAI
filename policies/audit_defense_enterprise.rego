# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE AUDIT DEFENSE & TAX CONTROL ENGINE (S4)
# ═══════════════════════════════════════════════════════════════════════════════
# Legacy metadata retained as ordinary comments; invalid YAML annotation removed.
# Public contract: data.jdg.audit_defense.decide (first-match-wins).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.audit_defense

# ── Audit risk helpers ────────────────────────────────────────────────────────
audit_risk_score(vat_correction_pct, revenue_growth, new_vendor_pct, repeat_correction_count, late_filing_count, cash_over_limit_count, industry_risk) = score {
    checks := [
        [vat_correction_pct > 0.30, 25],
        [revenue_growth > 2.0, 15],
        [new_vendor_pct > 0.50, 10],
        [repeat_correction_count >= 5, 20],
        [late_filing_count >= 3, 15],
        [cash_over_limit_count > 0, 30],
        [industry_risk > 0, industry_risk]
    ]
    score := sum([item[1] | item := checks[_]; item[0]])
}

audit_risk_factors(vat_correction_pct, revenue_growth, new_vendor_pct, repeat_correction_count, late_filing_count, cash_over_limit_count, industry, industry_risk) = factors {
    checks := [
        [vat_correction_pct > 0.30, sprintf("Korekty VAT >30%% (%.0f%%) — czerwona flaga dla US", [vat_correction_pct * 100])],
        [revenue_growth > 2.0, sprintf("Wzrost przychodów +%.0f%% rok do roku — może wzbudzić zainteresowanie US", [revenue_growth * 100])],
        [new_vendor_pct > 0.50, ">50% kontrahentów to nowi, niezweryfikowani — ryzyko karuzeli VAT"],
        [repeat_correction_count >= 5, sprintf("%d powtarzających się korekt w ciągu 12 mies — wzorzec błędów", [repeat_correction_count])],
        [late_filing_count >= 3, sprintf("%d spóźnionych deklaracji w ciągu roku — czynny żal zalecany", [late_filing_count])],
        [cash_over_limit_count > 0, sprintf("%d transakcji gotówkowych >15k PLN — NARUSZENIE limitu!", [cash_over_limit_count])],
        [industry_risk > 0, sprintf("Branża %s — podwyższone ryzyko kontroli (sektor wrażliwy VAT)", [industry])]
    ]
    factors := [item[1] | item := checks[_]; item[0]]
}

audit_preventive_actions(vat_correction_pct, new_vendor_pct, repeat_correction_count, late_filing_count, cash_over_limit_count) = actions {
    checks := [
        [vat_correction_pct > 0.30, "Udokumentuj przyczyny korekt VAT (błędy, zwroty, storno). Przygotuj uzasadnienie dla każdej korekty >10k PLN."],
        [new_vendor_pct > 0.50, "Weryfikuj każdego nowego kontrahenta w Białej Liście i CEIDG przed transakcją >15k PLN."],
        [repeat_correction_count >= 5, "Zlokalizuj źródło powtarzających się błędów. Wprowadź automatyczną walidację przed księgowaniem."],
        [late_filing_count >= 3, "Złóż CZYNNY ŻAL (Art. 16 KKS) dla każdej spóźnionej deklaracji. Unikniesz kary! Ustaw automatyczne przypomnienia."],
        [cash_over_limit_count > 0, "NATYCHMIAST przestaw się na przelewy! Transakcje >15k PLN MUSZĄ być bezgotówkowe (Art. 19 Prawa przedsiębiorców)."]
    ]
    actions := [item[1] | item := checks[_]; item[0]]
}

audit_risk_level(score) = "NISKIE" { score < 20 } else = "ŚREDNIE" { score >= 20; score < 50 } else = "WYSOKIE" { score >= 50; score < 80 } else = "KRYTYCZNE" { score >= 80 }
audit_routing_for(level) = "" { level == "NISKIE" } else = "TRIAGE_QUEUE" { level == "ŚREDNIE" } else = "BLOCK_AND_ALERT" { level == "WYSOKIE" } else = "BLOCK_AND_ALERT" { level == "KRYTYCZNE" }
audit_reason_for(score, level) = sprintf("Ryzyko kontroli: %s (%d/100 pkt)", [level, score]) { score > 0 } else = "" { score <= 0 }

build_audit_warnings(score, level, factors, actions) = warnings {
    score > 0
    header := sprintf("🔍 RYZYKO KONTROLI SKARBOWEJ: %s (%d/100 pkt)", [level, score])
    factor_lines := [sprintf("  • %s", [factor]) | factor := factors[_]]
    action_lines := [sprintf("  🛡️ %s", [action]) | action := actions[_]]
    warnings := array.concat([header, "", "CZYNNIKI RYZYKA:"], array.concat(factor_lines, array.concat(["", "DZIAŁANIA ZAPOBIEGAWCZE:"], action_lines)))
} else = ["✅ RYZYKO KONTROLI: NISKIE (0/100 pkt) — Brak czerwonych flag. Prowadź działalność dalej."]

# ── Voluntary disclosure helpers ──────────────────────────────────────────────
vd_needs(has_unreported, has_unpaid, authority_started) = false {
    not has_unreported
    not has_unpaid
} else = true {
    has_unreported
    not authority_started
} else = false {
    authority_started
}

vd_days_remaining(authority_started) = 999 { not authority_started } else = 0 { authority_started }
vd_penalty(amount, needs) = amount * 0.30 { amount > 0; needs } else = 0 { true }
vd_procedure_for(needs) = "ZŁÓŻ CZYNNY ŻAL NATYCHMIAST: 1) Pismo do US (właściwy NUS) z opisem czynu, 2) Zapłać zaległy podatek + odsetki, 3) Złóż korektę deklaracji. Skutek: brak kary KKS (Art. 16 § 1 KKS)." { needs } else = "" { not needs }
vd_routing_for(needs, amount) = "BLOCK_AND_ALERT" { needs; amount > 5000 } else = "TRIAGE_QUEUE" { needs; amount <= 5000 } else = "" { not needs }
vd_reason_for(needs, amount) = sprintf("Czynny żal KONIECZNY — %d PLN niezaplaconych podatków", [amount]) { needs; amount > 5000 } else = "Rozważ czynny żal dla małych zaległości" { needs; amount <= 5000 } else = "" { not needs }

build_vd_warnings(true, days, penalty) = [
    "🚨 CZYNNY ŻAL (Art. 16 KKS) — NATYCHMIASTOWA AKCJA!",
    "⚠️ Niezgłoszony dochód/podatek wykryty. Złóż czynny żal ZANIM US rozpocznie kontrolę.",
    sprintf("💰 Unikniesz kary: ~%.0f PLN (30%% zaległości) + odpowiedzialności karnej-skarbowej.", [penalty]),
    "📋 PROCEDURA: 1. Napisz pismo do NUS (opisz czyn + dowody). 2. Zapłać zaległość + odsetki. 3. Złóż korektę deklaracji.",
    "⏰ Termin: PRZED wszczęciem postępowania przez US. Po wszczęciu — czynny żal NIESKUTECZNY!",
    "🛡️ Efekt: BRAK kary KKS (Art. 16 § 1 KKS). Warunek: pełna wpłata w terminie wyznaczonym przez US."
]
build_vd_warnings(false, _, _) = ["✅ Brak potrzeby czynnego żalu."]

# ── Appeal and statute helpers ─────────────────────────────────────────────────
appeal_routing_for(amount) = "BLOCK_AND_ALERT" { amount > 50000 } else = "TRIAGE_QUEUE" { amount > 10000 } else = "" { amount <= 10000 }
appeal_reason_for(amount) = sprintf("Decyzja na %.0f PLN — odwolanie zalecane w ciagu 14 dni. Uzyj S22 (tax_authority_interaction) do auto-generacji pisma odwoławczego.", [amount]) { amount > 0 } else = "" { amount <= 0 }

statute_expiring_years(years) = expiring {
    expiring := [year | year := years[_]; year <= 2021]
}
statute_events(events) = suspension_events {
    suspension_events := [event | event := events[_]; {"AUDIT_INITIATED", "APPEAL_FILED", "CORRECTION_SUBMITTED"}[event.type]]
}
statute_routing_for(years) = "TRIAGE_QUEUE" { count(years) > 0 } else = "" { true }
statute_reason_for(years) = sprintf("Lata %s zbliżają się do przedawnienia — sprawdź dokumentację", [concat(", ", years)]) { count(years) > 0 } else = "" { true }
build_statute_warnings(years) = [
    sprintf("⏰ PRZEDAWNIENIE: Lata podatkowe %s zbliżają się do 5-letniego okresu przedawnienia.", [concat(", ", years)]),
    "⚠️ Po upływie 5 lat US NIE może wszcząć kontroli za ten rok (Art. 70 § 1 OrdPU).",
    "📋 ALE uwaga: przedawnienie ulega ZAWIESZENIU w przypadku wszczęcia postępowania, odwołania, lub kontroli.",
    "🗂️ PRZECHOWUJ dokumenty przez 5 lat od końca roku, w którym upłynął termin płatności podatku."
] { count(years) > 0 } else = ["✅ Wszystkie lata podatkowe w okresie przedawnienia są bezpieczne."]

# ── Public first-match-wins decision chain ────────────────────────────────────
default decide := {
    "matched": false, "rule_id": "jdg.audit_defense.no_match",
    "package": "jdg.audit_defense", "priority": 9999
}

decide := {
    "matched": true,
    "rule_id": "jdg.audit_defense.risk_scoring",
    "package": "jdg.audit_defense",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_risk_score": risk_score, "audit_risk_factors": risk_factors,
    "audit_risk_level": risk_level, "audit_preventive_actions": preventive_actions,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": audit_routing, "_routing_reason": audit_reason,
    "_legal_basis": "Art. 281-292 OrdPU; Art. 54-62 KKS; Kryteria wyboru do kontroli MF",
    "_warnings": build_audit_warnings(risk_score, risk_level, risk_factors, preventive_actions)
} {
    input.audit_risk_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    vat_correction_pct := object.get(input.jdg_entrepreneur, "vat_correction_pct_annual", 0)
    revenue_growth := object.get(input.jdg_entrepreneur, "revenue_growth_vs_previous_year", 0)
    new_vendor_pct := object.get(input.jdg_entrepreneur, "new_vendor_pct_quarterly", 0)
    repeat_correction_count := object.get(input.jdg_entrepreneur, "repeat_correction_count_12mo", 0)
    late_filing_count := object.get(input.jdg_entrepreneur, "late_filing_count_12mo", 0)
    cash_over_limit_count := object.get(input.jdg_entrepreneur, "cash_transactions_over_15k_pln", 0)
    industry := object.get(input.jdg_entrepreneur, "industry", "GENERAL")
    industry_risk := object.get({"FUEL": 15, "SCRAP": 20, "ELECTRONICS": 15, "CONSTRUCTION": 10, "ALCOHOL": 15, "IT_SERVICES": 5}, industry, 0)
    risk_score := audit_risk_score(vat_correction_pct, revenue_growth, new_vendor_pct, repeat_correction_count, late_filing_count, cash_over_limit_count, industry_risk)
    risk_factors := audit_risk_factors(vat_correction_pct, revenue_growth, new_vendor_pct, repeat_correction_count, late_filing_count, cash_over_limit_count, industry, industry_risk)
    preventive_actions := audit_preventive_actions(vat_correction_pct, new_vendor_pct, repeat_correction_count, late_filing_count, cash_over_limit_count)
    risk_level := audit_risk_level(risk_score)
    audit_routing := audit_routing_for(risk_level)
    audit_reason := audit_reason_for(risk_score, risk_level)
}

else := {
    "matched": true, "rule_id": "jdg.audit_defense.voluntary_disclosure_strategy",
    "package": "jdg.audit_defense", "priority": 410,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_voluntary_disclosure_recommended": needs_vd,
    "audit_vd_deadline_days_remaining": days_remaining,
    "audit_vd_procedure": vd_procedure,
    "audit_vd_expected_penalty_avoided": penalty_avoided,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": vd_routing, "_routing_reason": vd_reason,
    "_legal_basis": "Art. 16 § 1-5 KKS; Art. 16a KKS; Art. 56 § 1-3 KKS",
    "_warnings": build_vd_warnings(needs_vd, days_remaining, penalty_avoided)
} {
    input.audit_voluntary_disclosure_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_unreported_income := object.get(input.jdg_entrepreneur, "has_unreported_income", false)
    has_unpaid_tax := object.get(input.jdg_entrepreneur, "has_unpaid_tax", false)
    unreported_amount := object.get(input.jdg_entrepreneur, "unreported_tax_amount", 0)
    tax_authority_initiated := object.get(input.jdg_entrepreneur, "tax_authority_initiated_proceedings", false)
    needs_vd := vd_needs(has_unreported_income, has_unpaid_tax, tax_authority_initiated)
    days_remaining := vd_days_remaining(tax_authority_initiated)
    penalty_avoided := vd_penalty(unreported_amount, needs_vd)
    vd_procedure := vd_procedure_for(needs_vd)
    vd_routing := vd_routing_for(needs_vd, unreported_amount)
    vd_reason := vd_reason_for(needs_vd, unreported_amount)
}

else := {
    "matched": true, "rule_id": "jdg.audit_defense.appeal_procedure",
    "package": "jdg.audit_defense", "priority": 420,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_appeal_deadline_days": 14,
    "audit_appeal_to": "Dyrektor Izby Administracji Skarbowej",
    "audit_appeal_grounds_template": appeal_grounds,
    "audit_wsa_deadline_days": 30,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": appeal_routing, "_routing_reason": appeal_reason,
    "_legal_basis": "Art. 220-247 OrdPU (odwołania); Art. 52-54 PPSA (skarga do WSA); Art. 479 PPSA (kasacja do NSA)",
    "_warnings": [
        "⚖️ PROCEDURA ODWOŁAWCZA:",
        "📋 ETAP 1: Odwołanie do Dyrektora IAS — 14 dni od doręczenia decyzji (Art. 223 § 1 OrdPU).",
        "📋 ETAP 2: Skarga do WSA — 30 dni od doręczenia decyzji II instancji (Art. 53 § 1 PPSA).",
        "📋 ETAP 3: Skarga kasacyjna do NSA — 30 dni od doręczenia wyroku WSA z uzasadnieniem (Art. 479 PPSA).",
        "💡 WSKAZÓWKA: Odwołanie wnosi się PRZEZ organ I instancji. Zachowaj dowód nadania!",
        "💰 KOSZTY: Odwołanie — BEZPŁATNE. Skarga WSA — wpis 100-500 PLN. Kasacja NSA — wpis 100-1000 PLN.",
        "⏰ UWAGA: Złożenie odwołania WSTRZYMUJE wykonanie decyzji (z wyjątkiem decyzji rygoru natychmiastowej)."
    ]
} {
    input.audit_appeal_needed == true
    decision_type := object.get(input.jdg_entrepreneur, "tax_decision_type", "VAT_DETERMINATION")
    decision_amount := object.get(input.jdg_entrepreneur, "tax_decision_amount", 0)
    appeal_grounds := sprintf("Błędna interpretacja %s przez organ I instancji. Naruszenie Art. XX OrdPU.", [decision_type])
    appeal_routing := appeal_routing_for(decision_amount)
    appeal_reason := appeal_reason_for(decision_amount)
}

else := {
    "matched": true, "rule_id": "jdg.audit_defense.statute_of_limitations",
    "package": "jdg.audit_defense", "priority": 430,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_tax_year_expiring": expiring_years,
    "audit_statute_standard_years": 5,
    "audit_statute_suspension_events": suspension_events,
    "audit_document_retention_deadline": "5 lat od końca roku kalendarzowego, w którym upłynął termin płatności podatku.",
    "_routing": statute_routing, "_routing_reason": statute_reason,
    "_legal_basis": "Art. 70-71 OrdPU; Art. 86 OrdPU (przechowywanie); Art. 74 UoR",
    "_warnings": build_statute_warnings(expiring_years)
} {
    input.audit_statute_check == true
    tax_years := object.get(input.jdg_entrepreneur, "tax_years_active", [])
    current_events := object.get(input.jdg_entrepreneur, "tax_events", [])
    expiring_years := statute_expiring_years(tax_years)
    suspension_events := statute_events(current_events)
    statute_routing := statute_routing_for(expiring_years)
    statute_reason := statute_reason_for(expiring_years)
}
