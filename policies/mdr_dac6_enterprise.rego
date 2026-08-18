# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE MDR DAC6 REPORTING ENGINE (Strategic Initiative S16b)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
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
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    
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
    
    detected_hallmarks := []
    
    # === Category A: Generic Hallmarks (Main Benefit Test required) ===
    hallmark_a1 := confidentiality_clause or success_fee
    detected_hallmarks := array.concat(detected_hallmarks, ["A1"]) { hallmark_a1 }
    
    hallmark_a2 := standardized_documentation
    detected_hallmarks := array.concat(detected_hallmarks, ["A2"]) { hallmark_a2 }
    
    hallmark_a3 := acquires_loss_company
    detected_hallmarks := array.concat(detected_hallmarks, ["A3"]) { hallmark_a3 }
    
    # === Category B: Specific Hallmarks (Main Benefit Test required) ===
    hallmark_b1 := acquires_loss_company and count(involves_countries) > 1
    detected_hallmarks := array.concat(detected_hallmarks, ["B1"]) { hallmark_b1 }
    
    hallmark_b2 := converts_income_type and tax_advantage > 50000
    detected_hallmarks := array.concat(detected_hallmarks, ["B2"]) { hallmark_b2 }
    
    hallmark_b3 := uses_circular_flow
    detected_hallmarks := array.concat(detected_hallmarks, ["B3"]) { hallmark_b3 }
    
    # === Category C: Cross-border specific (Main Benefit Test) ===
    hallmark_c1 := double_deduction_check(input)
    detected_hallmarks := array.concat(detected_hallmarks, ["C1"]) { hallmark_c1 }
    
    hallmark_c2 := double_deduction_check(input) and count(involves_countries) > 1
    detected_hallmarks := array.concat(detected_hallmarks, ["C2"]) { hallmark_c2 }
    
    hallmark_c3 := false
    detected_hallmarks := array.concat(detected_hallmarks, ["C3"]) { hallmark_c3 }
    
    hallmark_c4 := uses_ip_transfer and count(involves_countries) > 1
    detected_hallmarks := array.concat(detected_hallmarks, ["C4"]) { hallmark_c4 }
    
    # === Category D: Specific Hallmarks re automatic exchange (NO MBT) ===
    hallmark_d1 := uses_hybrid_structure
    detected_hallmarks := array.concat(detected_hallmarks, ["D1"]) { hallmark_d1 }
    
    hallmark_d2 := involves_tax_haven
    detected_hallmarks := array.concat(detected_hallmarks, ["D2"]) { hallmark_d2 }
    
    # === Category E: Transfer pricing (NO MBT) ===
    hallmark_e1 := uses_ip_transfer and tax_advantage > 10000000
    detected_hallmarks := array.concat(detected_hallmarks, ["E1"]) { hallmark_e1 }
    
    count_hallmarks := count(detected_hallmarks)
    is_reportable := count_hallmarks > 0 and count(involves_countries) >= 1
    
    # Hallmark category detection — uses independent boolean flags
    # to avoid circular self-reference in Rego
    has_hallmark_a := count([h | h := [hallmark_a1, hallmark_a2, hallmark_a3]; h == true]) > 0
    has_hallmark_b := count([h | h := [hallmark_b1, hallmark_b2, hallmark_b3]; h == true]) > 0
    has_hallmark_c := count([h | h := [hallmark_c1, hallmark_c2, hallmark_c3, hallmark_c4]; h == true]) > 0
    has_hallmark_d := count([h | h := [hallmark_d1, hallmark_d2]; h == true]) > 0
    has_hallmark_e := hallmark_e1

    hallmark_category := "A" { has_hallmark_a }
    hallmark_category := "B" { not has_hallmark_a; has_hallmark_b }
    hallmark_category := "C" { not has_hallmark_a; not has_hallmark_b; has_hallmark_c }
    hallmark_category := "D" { not has_hallmark_a; not has_hallmark_b; not has_hallmark_c; has_hallmark_d }
    hallmark_category := "E" { not has_hallmark_a; not has_hallmark_b; not has_hallmark_c; not has_hallmark_d; has_hallmark_e }
    hallmark_category := "-" { not has_hallmark_a; not has_hallmark_b; not has_hallmark_c; not has_hallmark_d; not has_hallmark_e }
    main_benefit_test_result := count_hallmarks > 0
    
    cross_border_countries := involves_countries
    
    # Deadline calculation (Art. 86f OrdPU)
    deadline_days := 30 { count_hallmarks == 1 and tax_advantage <= 50000 }
    deadline_days := 14 { count_hallmarks > 1 or tax_advantage > 50000 }
    deadline_days := 7 { count_hallmarks >= 3 or tax_advantage > 10000000 }
    
    mdr_routing := "BLOCK_AND_ALERT" { is_reportable; deadline_days <= 7 }
    mdr_routing := "TRIAGE_QUEUE" { is_reportable; deadline_days > 7 }
    mdr_routing := "" { true }
    mdr_reason := sprintf("MDR — schemat wykryty! Zglos MDR-1 w ciagu %d dni. Kary do 21 000 000 PLN!", 
        [deadline_days]) { is_reportable }
    mdr_reason := "" { true }
}

double_deduction_check(input) = true {
    object.get(input, "mdr_double_deduction", false) == true
} else = false { true }

build_mdr_warnings(reportable, hallmarks, cat, mbt, countries, tax_adv, deadline) = warnings {
    reportable == false
    warnings := ["✅ MDR DAC6 — brak schematu podlegajacego raportowaniu."]
} else = {
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
        sprintf("   Prog maly: 50 000 PLN — %s", ["PRZEKROCZONY" { exceeds_threshold } else "OK"]),
        sprintf("   Prog duzy: 10 000 000 PLN"),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ UWAGA: Dla hallmark D i E (automatyczna wymiana) NIE ma progu!",
        "   Kazda korzysc podlega raportowaniu (Art. 86a ust. 2 OrdPU).",
        "💡 JDG: zwolnienie dla mikroprzedsiebiorcow (Art. 86a ust. 1a OrdPU)",
        "   — dotyczy schematow krajowych, NIE transgranicznych!"
    ]
} {
    input.mdr_dac6_threshold_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    tax_advantage := object.get(input, "mdr_tax_advantage_pln", 0)
    is_jdg := object.get(input.jdg_entrepreneur, "business_type", "") != "SP_ZOO"
    
    exceeds_threshold := tax_advantage > 50000
    jdg_exempt := is_jdg and tax_advantage <= 50000
    
    ta_routing := "TRIAGE_QUEUE" { exceeds_threshold }
    ta_routing := "" { true }
    ta_reason := sprintf("Korzysc %.0f PLN > 50k PLN — MDR wymagane", [tax_advantage]) { exceeds_threshold }
    ta_reason := "" { true }
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
    is_reportable := is_promoter or is_user
    
    reporter_type := "PROMOTOR/DORADCA — MDR-1 w 30 dni" { is_promoter }
    reporter_type := "KORZYSTAJACY — MDR-1 w 30 dni od gotowosci do wdrozenia" { is_user }
    reporter_type := "NIEOKRESLONY" { true }
    
    form_to_file := "MDR-1" { is_promoter or is_user }
    form_to_file := "MDR-3 (kwartalny)" { is_promoter }
    
    cal_days := 30
    annual_report_needed := is_promoter
    
    tl_routing := "TRIAGE_QUEUE" { is_reportable }
    tl_routing := "" { true }
    tl_reason := "Zloz MDR-1 w terminie — kary za opoznienie!" { is_reportable }
    tl_reason := "" { true }
}
