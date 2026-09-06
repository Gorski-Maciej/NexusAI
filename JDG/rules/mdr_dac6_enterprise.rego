# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE MDR DAC6 REPORTING ENGINE (Strategic Initiative S16b)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Documentation metadata (kept as ordinary comments; not parsed by OPA)
# title: JDG Enterprise MDR DAC6 — Mandatory Disclosure Rules
# description: |
#   ENTERPRISE v7.0 — Kompleksowy silnik raportowania MDR (DAC6).
#   Wypełnia lukę: rozbicie S16 (Exit Tax + MDR) na osobne moduły
#   dla pełnego pokrycia MDR (Art. 86a-86o OrdPU).
#
#   KLUCZOWE FUNKCJONALNOŚCI:
#   - Detekcja schematów podatkowych podlegających MDR (hallmarks A-E)
#   - Cross-border trigger detection (minimum 2 kraje EU lub EU+3rd)
#   - Automatyczna klasyfikacja hallmark (A1-A3, B1-B3, C1-C4, D1-D2, E1-E3)
#   - Kalkulator terminów raportowania MDR-1/MDR-2/MDR-3
#   - Weryfikacja progu korzyści podatkowej (50 000 PLN / 10 000 000 PLN)
#   - Generowanie metadanych dla formularza MDR-1
#   - Ostrzeżenia o karach za brak raportowania (do 21 000 000 PLN!)
#
#   UWAGA: MDR DOTYCZY TAKŻE JDG! Nie tylko duże korporacje.
#   Każdy doradca podatkowy, księgowy i przedsiębiorca ma obowiązek
#   raportowania schematów transgranicznych spełniających hallmark.
#
# architecture: Enterprise v7.0 MDR Engine
# legal_basis: Art. 86a-86o OrdPU; Dyrektywa 2018/822/EU (DAC6)
# package: jdg.mdr_dac6
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.mdr_dac6

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.mdr_dac6.no_match",
    "package": "jdg.mdr_dac6", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# MDR-100: HALLMARK DETECTION — Wykrywanie cech rozpoznawczych (hallmarks)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.mdr_dac6.hallmark_detection",
    "package": "jdg.mdr_dac6",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "mdr_reportable": is_reportable,
    "mdr_hallmarks_detected": detected_hallmarks,
    "mdr_hallmark_category": hallmark_category,
    "mdr_main_benefit_test": main_benefit_test_result,
    "mdr_cross_border_elements": cross_border_countries,
    "mdr_tax_advantage_pln": tax_advantage,
    "mdr_deadline_days": deadline_days,
    "mdr_form_required": "MDR-1",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": mdr_routing,
    "_routing_reason": mdr_reason,
    "_legal_basis": "Art. 86a-86o OrdPU; Dyrektywa 2018/822/EU (DAC6); Rozporzadzenie MF MDR",
    "_warnings": build_mdr_warnings(
        is_reportable, detected_hallmarks, hallmark_category,
        main_benefit_test_result, cross_border_countries,
        tax_advantage, deadline_days
    )
} {
    input.mdr_dac6_check == true
    pit_form := object.get(object.get(input, "jdg_entrepreneur", {}), "tax_form", "PIT_SCALE")
    
    # Transaction data
    transaction_type := object.get(input, "mdr_transaction_type", "")
    involves_countries := object.get(input, "mdr_involves_countries", [])
    tax_advantage := object.get(input, "mdr_tax_advantage_pln", 0)
    uses_hybrid_structure := object.get(input, "mdr_hybrid_mismatch", false)
    involves_tax_haven := object.get(input, "mdr_involves_tax_haven", false)
    uses_ip_transfer := object.get(input, "mdr_ip_transfer", false)
    uses_circular_flow := object.get(input, "mdr_circular_cash_flow", false)
    uses_double_deduction := object.get(input, "mdr_double_deduction", false)
    standardized_documentation := object.get(input, "mdr_standardized_docs", false)
    confidentiality_clause := object.get(input, "mdr_confidentiality_clause", false)
    success_fee := object.get(input, "mdr_success_fee", false)
    acquires_loss_company := object.get(input, "mdr_acquires_loss_company", false)
    converts_income_type := object.get(input, "mdr_converts_income", false)
    
    # === Macierz hallmark (etykieta, warunek) — kanoniczna taksonomia MDR A1-E1 ===
    all_pairs := [
        ["A1", _or2(confidentiality_clause, success_fee)],
        ["A2", standardized_documentation],
        ["A3", acquires_loss_company],
        ["B1", _and2(acquires_loss_company, count(involves_countries) > 1)],
        ["B2", _and2(converts_income_type, tax_advantage > 50000)],
        ["B3", uses_circular_flow],
        ["C1", double_deduction_check(input)],
        ["C2", _and2(double_deduction_check(input), count(involves_countries) > 1)],
        ["C3", false],
        ["C4", _and2(uses_ip_transfer, count(involves_countries) > 1)],
        ["D1", uses_hybrid_structure],
        ["D2", involves_tax_haven],
        ["E1", _and2(uses_ip_transfer, tax_advantage > 10000000)],
    ]
    detected_hallmarks := [p[0] | p := all_pairs[_]; p[1] == true]

    count_hallmarks := count(detected_hallmarks)
    is_reportable := _and2(count_hallmarks > 0, count(involves_countries) >= 1)
    main_benefit_test_result := count_hallmarks > 0
    cross_border_countries := involves_countries

    # Kategoria hallmark — pierwsza dopasowana A->E (bez cyklicznej referencji)
    has_hallmark_a := _has_cat("A", detected_hallmarks)
    has_hallmark_b := _has_cat("B", detected_hallmarks)
    has_hallmark_c := _has_cat("C", detected_hallmarks)
    has_hallmark_d := _has_cat("D", detected_hallmarks)
    has_hallmark_e := _has_cat("E", detected_hallmarks)
    hallmark_category := _hallmark_category(has_hallmark_a, has_hallmark_b, has_hallmark_c, has_hallmark_d, has_hallmark_e)

    # Termin (Art. 86f OrdPU) — najsurowszy kwalifikujacy termin wygrywa;
    # default 30 dni = sciezka "brak schematu" (decyzja zawsze zdefiniowana)
    deadline_days := _deadline_days(count_hallmarks, tax_advantage)

    mdr_routing := _mdr_routing(is_reportable, deadline_days)
    mdr_reason := _mdr_reason(is_reportable, deadline_days)
}

# ═══════════════════════════════════════════════════════════════════════════════
# MDR-200: TAX ADVANTAGE THRESHOLD ANALYZER
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr_dac6.tax_advantage_analyzer",
    "package": "jdg.mdr_dac6",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "mdr_tax_advantage_exceeds_threshold": exceeds_threshold,
    "mdr_threshold_small_pln": 50000,
    "mdr_threshold_large_pln": 10000000,
    "mdr_jdg_exemption_possible": jdg_exempt,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": ta_routing,
    "_routing_reason": ta_reason,
    "_legal_basis": "Art. 86a ust. 1 pkt 2 OrdPU; Art. 86e OrdPU",
    "_warnings": [
        sprintf("📊 ANALIZA PROGU KORZYSCI PODATKOWEJ MDR", []),
        sprintf("   Korzysc: %.0f PLN", [tax_advantage]),
        sprintf("   Prog maly: 50 000 PLN — %s", [_przek(exceeds_threshold)]),
        "   Prog duzy: 10 000 000 PLN",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ UWAGA: Dla hallmark D i E (automatyczna wymiana) NIE ma progu!",
        "   Kazda korzysc podlega raportowaniu (Art. 86a ust. 2 OrdPU).",
        "💡 JDG: zwolnienie dla mikroprzedsiebiorcow (Art. 86a ust. 1a OrdPU)",
        "   — dotyczy schematow krajowych, NIE transgranicznych!"
    ]
} {
    input.mdr_dac6_threshold_check == true
    pit_form := object.get(object.get(input, "jdg_entrepreneur", {}), "tax_form", "PIT_SCALE")
    tax_advantage := object.get(input, "mdr_tax_advantage_pln", 0)
    is_jdg := object.get(object.get(input, "jdg_entrepreneur", {}), "business_type", "") != "SP_ZOO"
    
    exceeds_threshold := tax_advantage > 50000
    jdg_exempt := _and2(is_jdg, tax_advantage <= 50000)
    
    ta_routing := _ta_route(exceeds_threshold)
    ta_reason := _ta_reason(tax_advantage, exceeds_threshold)
}

# ═══════════════════════════════════════════════════════════════════════════════
# MDR-300: REPORTING TIMELINE CALCULATOR
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr_dac6.timeline_calculator",
    "package": "jdg.mdr_dac6",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "mdr_reporter_type": reporter_type,
    "mdr_form_to_file": form_to_file,
    "mdr_deadline_calendar_days": cal_days,
    "mdr_annual_report_required": annual_report_needed,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": tl_routing,
    "_routing_reason": tl_reason,
    "_legal_basis": "Art. 86f-86h OrdPU; Art. 86j OrdPU; Rozporzadzenie MF MDR",
    "_warnings": [
        sprintf("📅 KALENDARZ MDR", []),
        sprintf("   Raportujacy: %s", [reporter_type]),
        sprintf("   Formularz: %s", [form_to_file]),
        sprintf("   Termin: %d dni od udostepnienia schematu", [cal_days]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 HARMONOGRAM RAPORTOWANIA:",
        "   • MDR-1: 30 dni od udostepnienia schematu (promotor/doradca)",
        "   • MDR-1: 30 dni od gotowosci do wdrozenia (korzystajacy)",
        "   • MDR-2: informacja zwrotna do Szefa KAS",
        "   • MDR-3: raport kwartalny (promotorzy — do 30 dnia po kwartale)",
        "   • NIP schematu (NSP): nadawany przez Szefa KAS po MDR-1"
    ]
} {
    input.mdr_dac6_timeline == true
    
    is_promoter := object.get(input, "mdr_is_promoter", false)
    is_user := object.get(input, "mdr_is_user", false)
    is_reportable := _or2(is_promoter, is_user)
    
    reporter_type := _reporter_type(is_promoter, is_user)
    
    form_to_file := _form_to_file(is_promoter, is_user)
    
    cal_days := 30
    annual_report_needed := is_promoter
    
    tl_routing := _tl_route(is_reportable)
    tl_reason := _tl_reason(is_reportable)
}

# ── Funkcje pomocnicze (poza łańcuchem else — naprawa łańcucha decyzyjnego) ──

double_deduction_check(doc) = true {
    object.get(doc, "mdr_double_deduction", false) == true
} else = false { true }

# ── Helpery MDR (Rego-safe: else-chainy zamiast warunkow w tresci reguly) ──

_and2(a, b) = true {
    a == true
    b == true
} else = false { true }

_or2(a, b) = true {
    a == true
} else = true {
    b == true
} else = false { true }

_has_cat(letter, hs) = true {
    h := hs[_]
    startswith(h, letter)
} else = false { true }

_hallmark_category(ha, hb, hc, hd, he) = "A" { ha == true }
else = "B" { hb == true }
else = "C" { hc == true }
else = "D" { hd == true }
else = "E" { he == true }
else = "-" { true }

_deadline_days(n, adv) = 7 { n >= 3 }
else = 7 { adv > 10000000 }
else = 14 { n > 1 }
else = 14 { adv > 50000 }
else = 30 { true }

_mdr_routing(rep, dl) = "BLOCK_AND_ALERT" { rep == true; dl <= 7 }
else = "TRIAGE_QUEUE" { rep == true }
else = "" { true }

_mdr_reason(rep, dl) = sprintf("MDR — schemat wykryty! Zglos MDR-1 w ciagu %d dni. Kary do 21 000 000 PLN!", [dl]) { rep == true }
else = "" { true }

_przek(c) = "PRZEKROCZONY" { c == true }
else = "OK" { true }

_ta_route(exceeds) = "TRIAGE_QUEUE" { exceeds == true }
else = "" { true }

_ta_reason(adv, exceeds) = sprintf("Korzysc %.0f PLN > 50k PLN — MDR wymagane", [adv]) { exceeds == true }
else = "" { true }

_reporter_type(prom, user) = "PROMOTOR/DORADCA — MDR-1 w 30 dni" { prom == true }
else = "KORZYSTAJACY — MDR-1 w 30 dni od gotowosci do wdrozenia" { user == true }
else = "NIEOKRESLONY" { true }

_form_to_file(prom, user) = "MDR-1 + MDR-3 (kwartalny)" { prom == true }
else = "MDR-1" { user == true }
else = "-" { true }

_tl_route(rep) = "TRIAGE_QUEUE" { rep == true }
else = "" { true }

_tl_reason(rep) = "Zloz MDR-1 w terminie — kary za opoznienie!" { rep == true }
else = "" { true }

build_mdr_warnings(reportable, hallmarks, cat, mbt, countries, tax_adv, deadline) = warnings {
    reportable == false
    warnings := ["✅ MDR DAC6 — brak schematu podlegajacego raportowaniu."]
}

build_mdr_warnings(reportable, hallmarks, cat, mbt, countries, tax_adv, deadline) = warnings {
    reportable == true
    hallmark_str := concat(", ", hallmarks)
    countries_str := concat(", ", countries)
    
    warnings := [
        sprintf("🚨 MDR DAC6 — SCHEMAT PODATKOWY WYKRYTY! ZGLOS MDR-1!", []),
        sprintf("   Hallmark(i): %s (Kategoria %s)", [hallmark_str, cat]),
        sprintf("   Panstwa: %s", [countries_str]),
        sprintf("   Korzysc podatkowa: %.0f PLN", [tax_adv]),
        sprintf("   TERMIN: %d dni od dnia nastepujacego po udostepnieniu schematu!", [deadline]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ KARY za brak raportowania MDR:",
        "   • KKS: do 720 stawek dziennych (Art. 80f KKS)",
        "   • Kara pieniezna: do 21 000 000 PLN!",
        "   • Odpowiedzialnosc solidarna doradcy i korzystajacego",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 FORMULARZ MDR-1 — wymagane dane:",
        "   • Identyfikacja schematu (nazwa, opis, podstawa prawna)",
        "   • Wskazanie hallmark",
        "   • Wartosc korzysci podatkowej",
        "   • Panstwa czlonkowskie, ktorych dotyczy",
        "   • Dane korzystajacego i doradcy",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 Zloz MDR-1 przez ePUAP do Szefa KAS w terminie!",
        "   • MDR-1: raportowanie przez doradce/promotora",
        "   • MDR-2: raportowanie przez korzystajacego (gdy brak doradcy)",
        "   • MDR-3: raportowanie kwartalne dla promotorow"
    ]
}
