# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE AUDIT DEFENSE & TAX CONTROL ENGINE (S4)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Audit Defense — Kontrola Skarbowa, Czynny Żal, Odwołania
# description: |
#   ENTERPRISE v5.0 — Silnik obrony przed kontrolą skarbową.
#   Automatyczna detekcja ryzyka kontroli, przygotowanie dokumentacji,
#   strategia czynnego żalu, terminy odwołań, procedury sprostowania.
#   Symuluje przebieg kontroli i przygotowuje przedsiębiorcę.
#   Wypełnia krytyczną lukę: reprezentacja przed US (częściowa automatyzacja).
# architecture: Enterprise Defense Engine, First-Match-Wins else-chain
# legal_basis: Ordynacja Podatkowa (Art. 16, 70, 81, 281-292), KKS (Art. 16, 54-62)
# package: jdg.audit_defense
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.audit_defense

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.audit_defense.no_match",
    "package": "jdg.audit_defense", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S4-400: AUDIT RISK SCORING — Punktacja ryzyka kontroli skarbowej
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.audit_defense.risk_scoring",
    "package": "jdg.audit_defense",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_risk_score": risk_score,
    "audit_risk_factors": risk_factors,
    "audit_risk_level": risk_level,
    "audit_preventive_actions": preventive_actions,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": audit_routing,
    "_routing_reason": audit_reason,
    "_legal_basis": "Art. 281-292 OrdPU; Art. 54-62 KKS; Kryteria wyboru do kontroli MF",
    "_warnings": build_audit_warnings(risk_score, risk_level, risk_factors, preventive_actions)
} {
    input.audit_risk_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    
    # Risk factors (each adds to score)
    risk_score := 0
    risk_factors := []
    preventive_actions := []

    # Factor 1: High amount discrepancy (VAT correction > 30%)
    vat_correction_pct := object.get(input.jdg_entrepreneur, "vat_correction_pct_annual", 0)
    risk_score := risk_score + 25 { vat_correction_pct > 0.30 }
    risk_factors := array.concat(risk_factors, [sprintf("Korekty VAT >30%% (%.0f%%) — czerwona flaga dla US", [vat_correction_pct * 100])]) { vat_correction_pct > 0.30 }
    preventive_actions := array.concat(preventive_actions, ["Udokumentuj przyczyny korekt VAT (błędy, zwroty, storno). Przygotuj uzasadnienie dla każdej korekty >10k PLN."]) { vat_correction_pct > 0.30 }

    # Factor 2: Rapid revenue growth
    revenue_growth := object.get(input.jdg_entrepreneur, "revenue_growth_vs_previous_year", 0)
    risk_score := risk_score + 15 { revenue_growth > 2.0 }
    risk_factors := array.concat(risk_factors, [sprintf("Wzrost przychodów +%.0f%% rok do roku — może wzbudzić zainteresowanie US", [revenue_growth * 100])]) { revenue_growth > 2.0 }

    # Factor 3: Frequent contracting with new, unverified vendors
    new_vendor_pct := object.get(input.jdg_entrepreneur, "new_vendor_pct_quarterly", 0)
    risk_score := risk_score + 10 { new_vendor_pct > 0.50 }
    risk_factors := array.concat(risk_factors, [">50% kontrahentów to nowi, niezweryfikowani — ryzyko karuzeli VAT"]) { new_vendor_pct > 0.50 }
    preventive_actions := array.concat(preventive_actions, ["Weryfikuj każdego nowego kontrahenta w Białej Liście i CEIDG przed transakcją >15k PLN."]) { new_vendor_pct > 0.50 }

    # Factor 4: Repeated corrections to same fields
    repeat_correction_count := object.get(input.jdg_entrepreneur, "repeat_correction_count_12mo", 0)
    risk_score := risk_score + 20 { repeat_correction_count >= 5 }
    risk_factors := array.concat(risk_factors, [sprintf("%d powtarzających się korekt w ciągu 12 mies — wzorzec błędów", [repeat_correction_count])]) { repeat_correction_count >= 5 }
    preventive_actions := array.concat(preventive_actions, ["Zlokalizuj źródło powtarzających się błędów. Wprowadź automatyczną walidację przed księgowaniem."]) { repeat_correction_count >= 5 }

    # Factor 5: Late filings
    late_filing_count := object.get(input.jdg_entrepreneur, "late_filing_count_12mo", 0)
    risk_score := risk_score + 15 { late_filing_count >= 3 }
    risk_factors := array.concat(risk_factors, [sprintf("%d spóźnionych deklaracji w ciągu roku — czynny żal zalecany", [late_filing_count])]) { late_filing_count >= 3 }
    preventive_actions := array.concat(preventive_actions, ["Złóż CZYNNY ŻAL (Art. 16 KKS) dla każdej spóźnionej deklaracji. Unikniesz kary! Ustaw automatyczne przypomnienia."]) { late_filing_count >= 3 }

    # Factor 6: Cash transactions over limit
    cash_over_limit_count := object.get(input.jdg_entrepreneur, "cash_transactions_over_15k_pln", 0)
    risk_score := risk_score + 30 { cash_over_limit_count > 0 }
    risk_factors := array.concat(risk_factors, [sprintf("%d transakcji gotówkowych >15k PLN — NARUSZENIE limitu!", [cash_over_limit_count])]) { cash_over_limit_count > 0 }
    preventive_actions := array.concat(preventive_actions, ["NATYCHMIAST przestaw się na przelewy! Transakcje >15k PLN MUSZĄ być bezgotówkowe (Art. 19 Prawa przedsiębiorców)."]) { cash_over_limit_count > 0 }

    # Factor 7: Industry-specific risk
    industry := object.get(input.jdg_entrepreneur, "industry", "GENERAL")
    high_risk_industries := {"FUEL": 15, "SCRAP": 20, "ELECTRONICS": 15, "CONSTRUCTION": 10, "ALCOHOL": 15, "IT_SERVICES": 5}
    industry_risk := object.get(high_risk_industries, industry, 0)
    risk_score := risk_score + industry_risk { industry_risk > 0 }
    risk_factors := array.concat(risk_factors, [sprintf("Branża %s — podwyższone ryzyko kontroli (sektor wrażliwy VAT)", [industry])]) { industry_risk > 0 }

    # Determine risk level
    risk_level := "NISKIE" { risk_score < 20 }
    risk_level := "ŚREDNIE" { risk_score >= 20; risk_score < 50 }
    risk_level := "WYSOKIE" { risk_score >= 50; risk_score < 80 }
    risk_level := "KRYTYCZNE" { risk_score >= 80 }

    audit_routing := "" { risk_level == "NISKIE" }
    audit_routing := "TRIAGE_QUEUE" { risk_level == "ŚREDNIE" }
    audit_routing := "BLOCK_AND_ALERT" { risk_level == "WYSOKIE" }
    audit_routing := "BLOCK_AND_ALERT" { risk_level == "KRYTYCZNE" }

    audit_reason := sprintf("Ryzyko kontroli: %s (%d/100 pkt)", [risk_level, risk_score]) { risk_score > 0 }
    audit_reason := "" { risk_score <= 0 }
}

build_audit_warnings(score, level, factors, actions) = warnings {
    score > 0
    header := [sprintf("🔍 RYZYKO KONTROLI SKARBOWEJ: %s (%d/100 pkt)", [level, score])]
    factor_lines := [sprintf("  • %s", [f]) | f = factors[_]]
    action_lines := [sprintf("  🛡️ %s", [a]) | a = actions[_]]
    separator := [""]
    result := array.concat(header, separator)
    result := array.concat(result, ["CZYNNIKI RYZYKA:"])
    result := array.concat(result, factor_lines)
    result := array.concat(result, separator)
    result := array.concat(result, ["DZIAŁANIA ZAPOBIEGAWCZE:"])
    result := array.concat(result, action_lines)
    result
} else = ["✅ RYZYKO KONTROLI: NISKIE (0/100 pkt) — Brak czerwonych flag. Prowadź działalność dalej."] {
    warnings := [good_msg]
}

# ═══════════════════════════════════════════════════════════════════════════════
# S4-410: VOLUNTARY DISCLOSURE (CZYNNY ŻAL) — Automatyczna strategia
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.audit_defense.voluntary_disclosure_strategy",
    "package": "jdg.audit_defense",
    "priority": 410,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_voluntary_disclosure_recommended": needs_vd,
    "audit_vd_deadline_days_remaining": days_remaining,
    "audit_vd_procedure": vd_procedure,
    "audit_vd_expected_penalty_avoided": penalty_avoided,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": vd_routing,
    "_routing_reason": vd_reason,
    "_legal_basis": "Art. 16 § 1-5 KKS; Art. 16a KKS; Art. 56 § 1-3 KKS",
    "_warnings": build_vd_warnings(needs_vd, days_remaining, penalty_avoided)
} {
    input.audit_voluntary_disclosure_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    
    has_unreported_income := object.get(input.jdg_entrepreneur, "has_unreported_income", false)
    has_unpaid_tax := object.get(input.jdg_entrepreneur, "has_unpaid_tax", false)
    days_since_violation := object.get(input.jdg_entrepreneur, "days_since_tax_violation", 0)
    unreported_amount := object.get(input.jdg_entrepreneur, "unreported_tax_amount", 0)
    tax_authority_initiated := object.get(input.jdg_entrepreneur, "tax_authority_initiated_proceedings", false)
    
    # Voluntary disclosure logic
    needs_vd := false { not has_unreported_income; not has_unpaid_tax }
    needs_vd := true { has_unreported_income; not tax_authority_initiated }
    needs_vd := false { tax_authority_initiated }  # Za późno — US już wie
    
    # Deadline: before tax authority discovers
    days_remaining := 999 { not tax_authority_initiated }
    days_remaining := 0 { tax_authority_initiated }
    
    # Possible penalties avoided
    penalty_avoided := unreported_amount * 0.30 { unreported_amount > 0; needs_vd }
    penalty_avoided := 0 { true }
    
    vd_procedure := "ZŁÓŻ CZYNNY ŻAL NATYCHMIAST: 1) Pismo do US (właściwy NUS) z opisem czynu, 2) Zapłać zaległy podatek + odsetki, 3) Złóż korektę deklaracji. Skutek: brak kary KKS (Art. 16 § 1 KKS)." { needs_vd }
    
    vd_routing := "BLOCK_AND_ALERT" { needs_vd; unreported_amount > 5000 }
    vd_routing := "TRIAGE_QUEUE" { needs_vd; unreported_amount <= 5000 }
    vd_routing := "" { not needs_vd }
    
    vd_reason := sprintf("Czynny żal KONIECZNY — %d PLN niezaplaconych podatków", [unreported_amount]) { needs_vd; unreported_amount > 5000 }
    vd_reason := "Rozważ czynny żal dla małych zaległości" { needs_vd; unreported_amount <= 5000 }
    vd_reason := "" { not needs_vd }
}

build_vd_warnings(true, days, penalty) = [
    sprintf("🚨 CZYNNY ŻAL (Art. 16 KKS) — NATYCHMIASTOWA AKCJA!", []),
    sprintf("⚠️ Niezgłoszony dochód/podatek wykryty. Złóż czynny żal ZANIM US rozpocznie kontrolę.", []),
    sprintf("💰 Unikniesz kary: ~%.0f PLN (30%% zaległości) + odpowiedzialności karnej-skarbowej.", [penalty]),
    "📋 PROCEDURA: 1. Napisz pismo do NUS (opisz czyn + dowody). 2. Zapłać zaległość + odsetki. 3. Złóż korektę deklaracji.",
    "⏰ Termin: PRZED wszczęciem postępowania przez US. Po wszczęciu — czynny żal NIESKUTECZNY!",
    "🛡️ Efekt: BRAK kary KKS (Art. 16 § 1 KKS). Warunek: pełna wpłata w terminie wyznaczonym przez US."
]

build_vd_warnings(false, _, _) = ["✅ Brak potrzeby czynnego żalu."]

# ═══════════════════════════════════════════════════════════════════════════════
# S4-420: APPEAL PROCEDURE INTELLIGENCE — Strategia odwołań
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.audit_defense.appeal_procedure",
    "package": "jdg.audit_defense",
    "priority": 420,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_appeal_deadline_days": 14,
    "audit_appeal_to": "Dyrektor Izby Administracji Skarbowej",
    "audit_appeal_grounds_template": appeal_grounds,
    "audit_wsa_deadline_days": 30,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": appeal_routing,
    "_routing_reason": appeal_reason,
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
    
    appeal_routing := "TRIAGE_QUEUE" { decision_amount > 10000 }
    appeal_routing := "BLOCK_AND_ALERT" { decision_amount > 50000 }
    appeal_routing := "" { decision_amount <= 10000 }
    
    appeal_reason := sprintf("Decyzja na %.0f PLN — odwołanie zalecane w ciągu 14 dni", [decision_amount]) { decision_amount > 0 }
    appeal_reason := "" { decision_amount <= 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S4-430: STATUTE OF LIMITATIONS TRACKER — Przedawnienia podatkowe
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.audit_defense.statute_of_limitations",
    "package": "jdg.audit_defense",
    "priority": 430,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "audit_tax_year_expiring": expiring_years,
    "audit_statute_standard_years": 5,
    "audit_statute_suspension_events": suspension_events,
    "audit_document_retention_deadline": retention_deadline,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": statute_routing,
    "_routing_reason": statute_reason,
    "_legal_basis": "Art. 70-71 OrdPU; Art. 86 OrdPU (przechowywanie); Art. 74 UoR",
    "_warnings": build_statute_warnings(expiring_years)
} {
    input.audit_statute_check == true
    
    tax_years := object.get(input.jdg_entrepreneur, "tax_years_active", [])
    current_events := object.get(input.jdg_entrepreneur, "tax_events", [])
    
    # Find tax years approaching statute of limitations (5 years)
    expiring_years := [year |
        year := tax_years[_]
        year <= 2021  # 5 years back from 2026
    ]
    
    # Suspension events: audit, appeal, correction
    suspension_events := [event |
        event := current_events[_]
        event.type == "AUDIT_INITIATED" or
        event.type == "APPEAL_FILED" or
        event.type == "CORRECTION_SUBMITTED"
    ]
    
    retention_deadline := "5 lat od końca roku kalendarzowego, w którym upłynął termin płatności podatku."
    
    statute_routing := "TRIAGE_QUEUE" { count(expiring_years) > 0 }
    statute_routing := "" { true }
    
    statute_reason := sprintf("Lata %s zbliżają się do przedawnienia — sprawdź dokumentację", [concat(", ", expiring_years)]) { count(expiring_years) > 0 }
    statute_reason := "" { true }
}

build_statute_warnings(years) = [
    sprintf("⏰ PRZEDAWNIENIE: Lata podatkowe %s zbliżają się do 5-letniego okresu przedawnienia.", [concat(", ", years)]),
    "⚠️ Po upływie 5 lat US NIE może wszcząć kontroli za ten rok (Art. 70 § 1 OrdPU).",
    "📋 ALE uwaga: przedawnienie ulega ZAWIESZENIU w przypadku wszczęcia postępowania, odwołania, lub kontroli.",
    "🗂️ PRZECHOWUJ dokumenty przez 5 lat od końca roku, w którym upłynął termin płatności podatku."
] {
    count(years) > 0
} else = ["✅ Wszystkie lata podatkowe w okresie przedawnienia są bezpieczne."] {
    warnings := [safe_msg]
}
