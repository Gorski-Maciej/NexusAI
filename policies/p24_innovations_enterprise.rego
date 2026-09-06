# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — P24 Innovations Enterprise Layer v7.0
# Mikro-Moduły Branżowe: CEIDG, Ryczałt, Sukcesja, Budownictwo, Transport, PP
# 12 Innowacyjnych Usprawnień Wyprzedzających Profesjonalistów (I1-I12)
# Generated: 2026-08-01 | Legal basis: stan prawny 01.08.2026
# Package: jdg.p24_innovations
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p24_innovations

import data.jdg.helpers

# ═══ Rego v0: helpery totalne (fix kompilacji — lokalne definicje warunkowe,
# infix and/or w termach oraz ternary są w Rego v0 niepoprawne) ═══
_or2(a, b) = true {
    a == true
} else = true {
    b == true
} else = false {
    true
}

_and2(a, b) = true {
    a == true
    b == true
} else = false {
    true
}

_and3(a, b, c) = true {
    a == true
    b == true
    c == true
} else = false {
    true
}

_not(x) = true {
    x == false
} else = false {
    true
}

# Selektory N-kierunkowe (Rego v0: zmienne są single-assignment — żadnych
# ponownych przypisań lokalnych; warunki muszą być związanymi boolami)
_score(cond, if_true, if_false) = if_true {
    cond == true
} else = if_false {
    true
}

_pick3(c1, v1, c2, v2, v3) = v1 {
    c1 == true
} else = v2 {
    c2 == true
} else = v3 {
    true
}

_pick4(c1, v1, c2, v2, c3, v3, v4) = v1 {
    c1 == true
} else = v2 {
    c2 == true
} else = v3 {
    c3 == true
} else = v4 {
    true
}

_pick5(c1, v1, c2, v2, c3, v3, c4, v4, v5) = v1 {
    c1 == true
} else = v2 {
    c2 == true
} else = v3 {
    c3 == true
} else = v4 {
    c4 == true
} else = v5 {
    true
}

# _cond: wartość lub 0 (dla liczb); _scond: wartość lub "" (dla stringów);
# _cond_list: lista lub [] — warunek ok musi być związanym boolem
_cond(value, ok) = value {
    ok == true
} else = 0 {
    true
}

_scond(value, ok) = value {
    ok == true
} else = "" {
    true
}

_cond_list(value, ok) = value {
    ok == true
} else = [] {
    true
}

_match_any(haystack, needles) = true {
    some i
    contains(haystack, needles[i])
} else = false {
    true
}

# ADR-002: snapshot bounds dla gałęzi i8/L-PP-2 (płaca minimalna — jedno źródło
# prawdy z data.jdg.thresholds.bounds). Wzorzec repo: reguła pakietowa z default
# — precyzyjna zależność od data.jdg.thresholds.bounds (bez recursji, którą
# wywołuje object.get(data.jdg, ...) przy odgałęzieniu do całego drzewa jdg),
# odporna na izolowany zbiór danych bez thresholds (fallback 4800).
default _bounds_snapshot = {}

_bounds_snapshot = bounds {
    bounds := data.jdg.thresholds.bounds
}

_vehicle_category(dmc, vehicle_type, seats, is_electric, is_hybrid) = "Zwolniony (elektryczny/hybrydowy)" {
    _or2(is_electric, is_hybrid)
} else = "Brak podatku (DMC <= 3.5t)" {
    dmc <= 3500
    vehicle_type != "BUS"
} else = "Ciężarowy 3.5-12t" {
    dmc > 3500
    dmc <= 12000
    vehicle_type == "TRUCK"
} else = "Ciężarowy >12t" {
    dmc > 12000
    vehicle_type == "TRUCK"
} else = "Ciągnik siodłowy" {
    vehicle_type == "TRACTOR"
} else = "Przyczepa/naczepa >7t" {
    vehicle_type == "TRAILER"
    dmc > 7000
} else = "Autobus >9 miejsc" {
    vehicle_type == "BUS"
    seats > 9
} else = "Brak podatku (DMC <= 3.5t)" {
    true
}

_vehicle_rate_cat(category) = "MAX_MF" {
    category == "Ciężarowy >12t"
} else = "MID_MF" {
    category == "Ciężarowy 3.5-12t"
} else = "TRACTOR_MF" {
    category == "Ciągnik siodłowy"
} else = "TRAILER_MF" {
    category == "Przyczepa/naczepa >7t"
} else = "BUS_MF" {
    category == "Autobus >9 miejsc"
} else = "EXEMPT" {
    category == "Zwolniony (elektryczny/hybrydowy)"
} else = "NONE" {
    true
}

_vehicle_tax(rate_cat) = 0 {
    rate_cat == "NONE"
} else = 0 {
    rate_cat == "EXEMPT"
} else = 2800 {
    rate_cat == "MID_MF"
} else = 3500 {
    rate_cat == "MAX_MF"
} else = 3200 {
    rate_cat == "TRACTOR_MF"
} else = 1800 {
    rate_cat == "TRAILER_MF"
} else = 2200 {
    rate_cat == "BUS_MF"
} else = 0 {
    true
}

_pkd_class(desc) = {"pkd": "62.01.Z", "desc": "Działalność związana z oprogramowaniem", "conf": "HIGH"} {
    _match_any(desc, ["programow", "software", "aplikacj"])
} else = {"pkd": "43.99.Z", "desc": "Pozostałe specjalistyczne roboty budowlane", "conf": "MEDIUM"} {
    _match_any(desc, ["budow", "remont", "wykończeni"])
} else = {"pkd": "49.41.Z", "desc": "Transport drogowy towarów", "conf": "HIGH"} {
    _match_any(desc, ["transport", "przewóz"])
} else = {"pkd": "69.20.Z", "desc": "Działalność rachunkowo-księgowa; doradztwo podatkowe", "conf": "HIGH"} {
    _match_any(desc, ["księgow", "rachunkow"])
} else = {"pkd": "70.22.Z", "desc": "Pozostałe doradztwo w zakresie prowadzenia działalności gospodarczej i zarządzania", "conf": "MEDIUM"} {
    _match_any(desc, ["doradz", "konsult"])
} else = {"pkd": "70.22.Z", "desc": "Pozostałe doradztwo w zakresie prowadzenia działalności...", "conf": "LOW"} {
    true
}

_tax_scale(income) = 0 {
    income <= 30000
} else = s {
    income <= 120000
    s := (income - 30000) * 0.12
} else = s {
    s := 10800 + (income - 120000) * 0.32
}

_tax_linear(income) = s {
    income > 30000
    s := (income - 30000) * 0.19
} else = 0 {
    true
}

_lump_rate(pkwiu) = 0.03 {
    contains(pkwiu, "62.0")
} else = 0.055 {
    _match_any(pkwiu, ["41.", "43."])
} else = 0.15 {
    contains(pkwiu, "49.")
} else = 0.125 {
    contains(pkwiu, "69.")
} else = 0.20 {
    contains(pkwiu, "86.")
} else = 0.085 {
    true
}

_tax_est(reinvests, income) = 0 {
    reinvests == true
} else = s {
    s := income * 0.10
}

_best_form(scale, linear, lump_label, lump, card, est) = "Skala podatkowa" {
    scale == min([scale, linear, lump, card, est])
} else = "Liniowy 19%" {
    linear == min([scale, linear, lump, card, est])
} else = lump_label {
    lump == min([scale, linear, lump, card, est])
} else = "Karta podatkowa" {
    card == min([scale, linear, lump, card, est])
} else = "Estoński CIT" {
    true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.p24_innovations.no_match",
    "package": "jdg.p24_innovations",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I1. CEIDG AUTO-FILE + CHANGE DETECTOR (P24 I1)                            ║
# ║  Automatic detection of data changes requiring CEIDG update within 7 days   ║
# ║  Legal basis: Art. 14 ust. 1 ustawy o CEIDG                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i1.r1: ceidg_change_detector_address
decide := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i1.ceidg_change_detector_address",
    "package": "jdg.p24_innovations",
    "priority": 24001,
    "innovation_id": "I1",
    "innovation_name": "CEIDG Auto-File + Change Detector",
    "detector_type": "ADDRESS_CHANGE",
    "days_to_file": 7,
    "auto_file_enabled": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "I1: Wykryto zmianę adresu — wymagana aktualizacja CEIDG w 7 dni",
    "_legal_basis": "Art. 14 ust. 1 ustawy o CEIDG (Dz.U. 2018 poz. 647)",
    "_warnings": ["[I1 CEIDG Detector] Zmiana adresu siedziby/adresu prowadzenia działalności wykryta. Masz 7 dni na zgłoszenie zmiany w CEIDG. Przekroczenie = kara 700-1400 zł."]
} {
    object.get(input.jdg_entrepreneur, "address_changed", false) == true
    object.get(input.jdg_entrepreneur, "ceidg_address_updated", false) == false
    object.get(input.jdg_entrepreneur, "ceidg_registered", false) == true
}

# jdg.p24_innovations.i1.r2: ceidg_change_detector_pkd
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i1.ceidg_change_detector_pkd",
    "package": "jdg.p24_innovations",
    "priority": 24002,
    "innovation_id": "I1",
    "innovation_name": "CEIDG Auto-File + Change Detector",
    "detector_type": "PKD_CHANGE",
    "days_to_file": 7,
    "auto_file_enabled": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "I1: Wykryto zmianę kodów PKD — wymagana aktualizacja CEIDG",
    "_legal_basis": "Art. 14 ust. 1 ustawy o CEIDG",
    "_warnings": ["[I1 CEIDG Detector] Zmiana głównego kodu PKD lub dodanie/usunięcie kodów. Aktualizacja CEIDG wymagana w 7 dni."]
} {
    object.get(input.jdg_entrepreneur, "pkd_codes_changed", false) == true
    object.get(input.jdg_entrepreneur, "ceidg_pkd_updated", false) == false
}

# jdg.p24_innovations.i1.r3: ceidg_change_detector_name
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i1.ceidg_change_detector_name",
    "package": "jdg.p24_innovations",
    "priority": 24003,
    "innovation_id": "I1",
    "innovation_name": "CEIDG Auto-File + Change Detector",
    "detector_type": "NAME_CHANGE",
    "days_to_file": 7,
    "auto_file_enabled": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "I1: Wykryto zmianę nazwy firmy — wymagana aktualizacja CEIDG",
    "_legal_basis": "Art. 14 ust. 1 ustawy o CEIDG",
    "_warnings": ["[I1 CEIDG Detector] Zmiana nazwy firmy wykryta. Aktualizacja CEIDG w 7 dni. Uwaga: zmiana nazwy może wymagać aktualizacji wszystkich faktur i umów."]
} {
    object.get(input.jdg_entrepreneur, "business_name_changed", false) == true
    object.get(input.jdg_entrepreneur, "ceidg_name_updated", false) == false
}

# jdg.p24_innovations.i1.r4: ceidg_change_detector_tax_form
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i1.ceidg_change_detector_tax_form",
    "package": "jdg.p24_innovations",
    "priority": 24004,
    "innovation_id": "I1",
    "innovation_name": "CEIDG Auto-File + Change Detector",
    "detector_type": "TAX_FORM_CHANGE",
    "days_to_file": 20,
    "auto_file_enabled": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "I1: Zmiana formy opodatkowania — termin 20 dni od początku roku/miesiąca",
    "_legal_basis": "Art. 9a ust. 2 PIT, Art. 25 ust. 5 ustawy o ryczałcie",
    "_warnings": ["[I1 CEIDG Detector] Zmiana formy opodatkowania wykryta. Masz 20 dni od początku miesiąca na zgłoszenie zmiany. CEIDG-1 aktualizacja + zawiadomienie US."]
} {
    object.get(input.jdg_entrepreneur, "tax_form_changed", false) == true
    object.get(input.jdg_entrepreneur, "tax_form_change_reported", false) == false
}

# jdg.p24_innovations.i1.r5: ceidg_auto_file_deadline_tracker
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i1.ceidg_deadline_tracker",
    "package": "jdg.p24_innovations",
    "priority": 24005,
    "innovation_id": "I1",
    "innovation_name": "CEIDG Auto-File + Change Detector",
    "detector_type": "DEADLINE_TRACKER",
    "days_remaining": days_remaining,
    "deadline_passed": deadline_passed,
    "estimated_penalty_pln": estimated_penalty,
    "_routing": route,
    "_routing_reason": reason,
    "_legal_basis": "Art. 14 ust. 1, Art. 48-49 ustawy o CEIDG",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_deadline_check", false) == true
    change_date := object.get(input.jdg_entrepreneur, "last_change_date", "")
    days_elapsed := object.get(input.jdg_entrepreneur, "ceidg_change_days_elapsed", 0)
    violation_count := object.get(input.jdg_entrepreneur, "ceidg_deadline_violation_count", 0)
    days_remaining := 7 - days_elapsed
    deadline_passed := days_elapsed > 7
    # Rego v0: selektory zamiast ponownych przypisań — fix kompilacji
    pen_low := violation_count <= 1
    estimated_penalty := _score(pen_low, 700, 1400)
    near_d := days_remaining <= 2
    pos_d := days_remaining > 0
    near_window := _and2(near_d, pos_d)
    route := _pick3(deadline_passed, "BLOCK_AND_ALERT", near_window, "TRIAGE_QUEUE", "")
    reason := _score(deadline_passed,
        sprintf("Termin CEIDG minął %d dni temu — kara %d zł", [days_elapsed - 7, estimated_penalty]),
        sprintf("Zostało %d dni na zgłoszenie zmiany w CEIDG", [days_remaining]))
    warnings := [sprintf("I1 Deadline Tracker: %s. Zmiana z dnia %s.", [reason, change_date])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I2. LUMP SUM RATE SEMANTIC MATCHER (P24 I2)                               ║
# ║  AI-based semantic mapping of business descriptions to flat-rate tax %      ║
# ║  Legal basis: Art. 12 ustawy o ryczałcie — stawki per PKWiU                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i2.r1: semantic_matcher_it_services
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i2.semantic_matcher_it",
    "package": "jdg.p24_innovations",
    "priority": 24006,
    "innovation_id": "I2",
    "innovation_name": "Lump Sum Rate Semantic Matcher",
    "matched_rate": "3.0%",
    "matched_pkwiu": "62.01.1 / 62.02 / 62.03",
    "confidence": "HIGH",
    "matcher_method": "SEMANTIC_KEYWORD",
    "_routing": "",
    "_routing_reason": "I2 Semantic: dopasowano stawkę ryczałtu 3% dla usług IT/programistycznych",
    "_legal_basis": "Art. 12 ust. 1 pkt 2 lit. g ustawy o ryczałcie",
    "_warnings": ["[I2 Semantic Matcher] Usługi IT — ryczałt 3%. Wyłączenia: doradztwo IT, zarządzanie projektami IT (8,5%), sprzęt komputerowy (5,5%). Zweryfikuj dominujący charakter usługi."]
} {
    object.get(input.invoice, "service_description", "") != ""
    desc := lower(object.get(input.invoice, "service_description", ""))
    _match_any(desc, ["programowanie", "software", "aplikacj", "kodowanie", "web development", "devops", "programist"])
}

# jdg.p24_innovations.i2.r2: semantic_matcher_construction
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i2.semantic_matcher_construction",
    "package": "jdg.p24_innovations",
    "priority": 24007,
    "innovation_id": "I2",
    "innovation_name": "Lump Sum Rate Semantic Matcher",
    "matched_rate": "5.5%",
    "matched_pkwiu": "41.00 / 42.00 / 43.00",
    "confidence": "HIGH",
    "matcher_method": "SEMANTIC_KEYWORD",
    "_routing": "",
    "_routing_reason": "I2 Semantic: dopasowano stawkę ryczałtu 5,5% dla usług budowlanych",
    "_legal_basis": "Art. 12 ust. 1 pkt 4 lit. a ustawy o ryczałcie",
    "_warnings": ["[I2 Semantic Matcher] Usługi budowlane — ryczałt 5,5%. UWAGA: budownictwo mieszkaniowe ma VAT 8% (Art. 41 ust. 12 VAT) — osobna analiza I10."]
} {
    # Wyzwalacz naturalny: klucz przychodu jawny w wejściu (gałąź samograniczna
    # przez keywords — bez nadmiarowego opty-in, spójnie z r1 IT)
    desc := lower(object.get(input.invoice, "service_description", ""))
    _match_any(desc, ["budow", "remont", "montaż", "instalacj", "wykończeni", "konstrukcj"])
}

# jdg.p24_innovations.i2.r3: semantic_matcher_services_85
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i2.semantic_matcher_services_85",
    "package": "jdg.p24_innovations",
    "priority": 24008,
    "innovation_id": "I2",
    "innovation_name": "Lump Sum Rate Semantic Matcher",
    "matched_rate": "8.5%",
    "matched_pkwiu": "działy 68-82 PKWiU",
    "confidence": "MEDIUM",
    "matcher_method": "SEMANTIC_KEYWORD",
    "_routing": "",
    "_routing_reason": "I2 Semantic: dopasowano stawkę ryczałtu 8,5% dla usług ogólnych",
    "_legal_basis": "Art. 12 ust. 1 pkt 5 lit. a ustawy o ryczałcie",
    "_warnings": ["[I2 Semantic Matcher] Usługi — ryczałt 8,5%. Dla najmu: 8,5% do 100 000 zł rocznie, powyżej 12,5%. Zweryfikuj, czy nie jest to wolny zawód (12,5%) lub usługi IT (3%)."]
} {
    # Wyzwalacz naturalny: klucz przychodu jawny w wejściu (gałąź samograniczna
    # przez keywords — bez nadmiarowego opty-in, spójnie z r1 IT)
    desc := lower(object.get(input.invoice, "service_description", ""))
    _match_any(desc, ["usługa", "konsult", "doradz", "szkoleni", "projekt"])
    _not(_match_any(desc, ["programowanie", "budow", "transport"]))
}

# jdg.p24_innovations.i2.r4: semantic_matcher_transport
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i2.semantic_matcher_transport",
    "package": "jdg.p24_innovations",
    "priority": 24009,
    "innovation_id": "I2",
    "innovation_name": "Lump Sum Rate Semantic Matcher",
    "matched_rate": "15.0%",
    "matched_pkwiu": "49.00 / 50.00 / 51.00",
    "confidence": "HIGH",
    "matcher_method": "SEMANTIC_KEYWORD",
    "_routing": "",
    "_routing_reason": "I2 Semantic: dopasowano stawkę ryczałtu 15% dla usług transportowych",
    "_legal_basis": "Art. 12 ust. 1 pkt 1 ustawy o ryczałcie",
    "_warnings": ["[I2 Semantic Matcher] Transport — ryczałt 15%. Dodatkowo: podatek od środków transportowych (DMC > 3,5t) — patrz I5 Transport Tax Fleet Optimizer."]
} {
    # Wyzwalacz naturalny: klucz przychodu jawny w wejściu (gałąź samograniczna
    # przez keywords — bez nadmiarowego opty-in, spójnie z r1 IT)
    desc := lower(object.get(input.invoice, "service_description", ""))
    _match_any(desc, ["transport", "przewóz", "spedycj", "kurier", "logistyk"])
}

# jdg.p24_innovations.i2.r5: semantic_matcher_professions_125
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i2.semantic_matcher_professions_125",
    "package": "jdg.p24_innovations",
    "priority": 24010,
    "innovation_id": "I2",
    "innovation_name": "Lump Sum Rate Semantic Matcher",
    "matched_rate": "12.5%",
    "matched_pkwiu": "działy 69, 70.2 PKWiU",
    "confidence": "MEDIUM",
    "matcher_method": "SEMANTIC_KEYWORD",
    "_routing": "",
    "_routing_reason": "I2 Semantic: dopasowano stawkę 12,5% dla wolnych zawodów",
    "_legal_basis": "Art. 12 ust. 1 pkt 2 lit. a ustawy o ryczałcie",
    "_warnings": ["[I2 Semantic Matcher] Wolne zawody — ryczałt 12,5%. Dotyczy: doradcy podatkowi, księgowi, radcy prawni, architekci, tłumacze. Nie dotyczy lekarzy (20%) ani stomatologów (17%)."]
} {
    # Wyzwalacz naturalny: klucz przychodu jawny w wejściu (gałąź samograniczna
    # przez keywords — bez nadmiarowego opty-in, spójnie z r1 IT)
    desc := lower(object.get(input.invoice, "service_description", ""))
    _match_any(desc, ["doradca podatkowy", "księgow", "radca prawny", "architekt", "tłumacz", "biegły"])
}

# jdg.p24_innovations.i2.r6: semantic_matcher_health_20
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i2.semantic_matcher_health_20",
    "package": "jdg.p24_innovations",
    "priority": 24011,
    "innovation_id": "I2",
    "innovation_name": "Lump Sum Rate Semantic Matcher",
    "matched_rate": "20.0%",
    "matched_pkwiu": "86.10 / 86.21 / 86.22 / 86.23",
    "confidence": "HIGH",
    "matcher_method": "SEMANTIC_KEYWORD",
    "_routing": "",
    "_routing_reason": "I2 Semantic: dopasowano stawkę 20% dla wolnych zawodów medycznych",
    "_legal_basis": "Art. 12 ust. 1 pkt 2 lit. b ustawy o ryczałcie",
    "_warnings": ["[I2 Semantic Matcher] Wolne zawody medyczne — ryczałt 20%. Dotyczy: lekarze, dentyści, weterynarze. Nie dotyczy pielęgniarek i fizjoterapeutów (17%)."]
} {
    # Wyzwalacz naturalny: klucz przychodu jawny w wejściu (gałąź samograniczna
    # przez keywords — bez nadmiarowego opty-in, spójnie z r1 IT)
    desc := lower(object.get(input.invoice, "service_description", ""))
    _match_any(desc, ["lekarz", "dentysta", "stomatolog", "weterynarz", "chirurg"])
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I3. SUCCESSION READINESS SCORECARD (P24 I3)                               ║
# ║  0-100 scoring for JDG succession readiness                                ║
# ║  Legal basis: Ustawa o zarządzie sukcesyjnym (Dz.U. 2018 poz. 1629)        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i3.r1: succession_scorecard
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i3.succession_scorecard",
    "package": "jdg.p24_innovations",
    "priority": 24012,
    "innovation_id": "I3",
    "innovation_name": "Succession Readiness Scorecard",
    "scorecard_total": total_score,
    "scorecard_max": 100,
    "scorecard_level": level,
    "scorecard_factors": factors,
    "scorecard_recommendations": recommendations,
    "_routing": route,
    "_routing_reason": sprintf("I3 Scorecard: gotowość sukcesyjna %d/100 — %s", [total_score, level]),
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym (Dz.U. 2018 poz. 1629)",
    "_warnings": warnings
} {
    # Opty-in: analiza raportowana tylko na żądanie (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_succession_check", false) == true
    # Factor weights (max 100 points)
    has_will := object.get(input.jdg_entrepreneur, "has_testament", false)
    has_manager := object.get(input.jdg_entrepreneur, "has_succession_manager_designated", false)
    has_agreement := object.get(input.jdg_entrepreneur, "has_succession_agreement", false)
    has_insurance := object.get(input.jdg_entrepreneur, "has_key_person_insurance", false)
    has_documentation := object.get(input.jdg_entrepreneur, "has_succession_documentation", false)
    has_training := object.get(input.jdg_entrepreneur, "has_successor_training", false)
    has_valuation := object.get(input.jdg_entrepreneur, "has_business_valuation", false)
    has_legal_review := object.get(input.jdg_entrepreneur, "has_legal_review_done", false)
    has_ceidg_plan := object.get(input.jdg_entrepreneur, "has_ceidg_succession_plan", false)
    has_zus_plan := object.get(input.jdg_entrepreneur, "has_zus_succession_plan", false)

    # Scoring
    # Rego v0: scoring przez selektory — fix kompilacji
    will_score := _score(has_will, 15, 0)
    manager_score := _pick3(has_manager, 15, _and2(has_agreement, _not(has_manager)), 5, 0)
    insurance_score := _score(has_insurance, 10, 0)
    documentation_score := _score(has_documentation, 10, 0)
    training_score := _score(has_training, 10, 0)
    valuation_score := _score(has_valuation, 10, 0)
    legal_score := _score(has_legal_review, 10, 0)
    ceidg_score := _score(has_ceidg_plan, 10, 0)
    zus_score := _score(has_zus_plan, 10, 0)

    total_score := will_score + manager_score + insurance_score + documentation_score +
                   training_score + valuation_score + legal_score + ceidg_score + zus_score

    factors := [
        {"factor": "testament", "score": will_score, "max": 15},
        {"factor": "zarządca_sukcesyjny", "score": manager_score, "max": 15},
        {"factor": "ubezpieczenie_kluczowej_osoby", "score": insurance_score, "max": 10},
        {"factor": "dokumentacja_sukcesyjna", "score": documentation_score, "max": 10},
        {"factor": "szkolenie_sukcesora", "score": training_score, "max": 10},
        {"factor": "wycena_przedsiebiorstwa", "score": valuation_score, "max": 10},
        {"factor": "przeglad_prawny", "score": legal_score, "max": 10},
        {"factor": "plan_ceidg", "score": ceidg_score, "max": 10},
        {"factor": "plan_zus", "score": zus_score, "max": 10}
    ]

    # Rego v0: poziomy/rekomendacje/routing przez helpery — fix kompilacji
    s_lt30 := total_score < 30
    s_ge30 := total_score >= 30
    s_lt50 := total_score < 50
    s_ge50 := total_score >= 50
    s_lt70 := total_score < 70
    s_ge70 := total_score >= 70
    s_lt90 := total_score < 90
    s_ge90 := total_score >= 90
    level := _pick5(s_lt30, "KRYTYCZNY — natychmiastowe działania wymagane",
        _and2(s_ge30, s_lt50), "NISKI — wymaga pilnej poprawy",
        _and2(s_ge50, s_lt70), "ŚREDNI — częściowa gotowość",
        _and2(s_ge70, s_lt90), "DOBRY — większość elementów przygotowana",
        "BARDZO DOBRY — kompleksowe przygotowanie")
    recommendations := _pick3(s_lt30,
        ["Sporządź testament", "Wskaż zarządcę sukcesyjnego", "Wykup ubezpieczenie kluczowej osoby"],
        _and2(s_ge30, s_lt70), ["Dokończ dokumentację sukcesyjną", "Przeprowadź wycenę firmy"],
        ["Aktualizuj plan sukcesyjny rocznie"])
    route := _pick3(s_lt30, "BLOCK_AND_ALERT", _and2(s_ge30, s_lt70), "TRIAGE_QUEUE", "")

    warnings := [sprintf("[I3 Scorecard] Gotowość sukcesyjna: %d/100 (%s). %s",
        [total_score, level, concat(", ", recommendations)])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I4. CONSTRUCTION TAX AUTO-CALCULATOR (P24 I4)                             ║
# ║  Calculator for 8% vs 23% construction VAT, reverse charge, PCC, KSeF      ║
# ║  Legal basis: Art. 41 ust. 12 VAT, Art. 17 ust. 1 pkt 8 VAT               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i4.r1: construction_tax_calculator
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i4.construction_tax_calculator",
    "package": "jdg.p24_innovations",
    "priority": 24013,
    "innovation_id": "I4",
    "innovation_name": "Construction Tax Auto-Calculator",
    "vat_rate_recommended": vat_rate_rec,
    "vat_amount_calculated": vat_amount,
    "reverse_charge_applies": rc_applies,
    "total_tax_burden": total_tax,
    "net_amount": net,
    "_routing": "",
    "_routing_reason": sprintf("I4 Construction Calc: VAT %s, RC: %v, Podatek łączny: %.2f PLN",
        [vat_rate_rec, rc_applies, total_tax]),
    "_legal_basis": "Art. 41 ust. 12 VAT, Art. 17 ust. 1 pkt 8 VAT",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.invoice, "construction_analysis_requested", false) == true
    net := object.get(input.invoice, "net_amount_pln", 0)
    is_residential := object.get(input.invoice, "is_residential_construction", false)
    floor_area := object.get(input.invoice, "building_floor_area_m2", 0)
    is_b2b := object.get(input.counterparty, "is_vat_payer", false)
    jdg_is_vat := input.jdg_entrepreneur.is_vat_payer
    includes_materials := object.get(input.invoice, "includes_materials", false)

    # VAT rate determination (Rego v0: helpery — fix kompilacji)
    rc_applies := _and2(is_b2b, jdg_is_vat)
    not_res := _not(is_residential)
    big_area := floor_area > 300
    small_area := floor_area <= 300
    not_rc := _not(rc_applies)
    vat_rate_rec := _pick4(rc_applies, "RC",
        _and2(not_rc, not_res), "23%",
        _and3(not_rc, is_residential, big_area), "23%",
        "8%")
    r23 := vat_rate_rec == "23%"
    r8 := vat_rate_rec == "8%"
    vat_rate_decimal := _pick3(r23, 0.23, r8, 0.08, 0.00)

    vat_amount := net * vat_rate_decimal
    total_tax := vat_amount

    rc_label := _score(rc_applies, "Reverse charge: nabywca rozlicza VAT", "Standardowe rozliczenie VAT")
    warnings := [sprintf("[I4 Construction Calc] Stawka VAT: %s. Kwota VAT: %.2f PLN. %s",
        [vat_rate_rec, vat_amount, rc_label])]
}

# jdg.p24_innovations.i4.r2: construction_materials_calculator
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i4.construction_materials_calculator",
    "package": "jdg.p24_innovations",
    "priority": 24014,
    "innovation_id": "I4",
    "innovation_name": "Construction Tax Auto-Calculator",
    "materials_relief_available": false,
    "materials_relief_note": "Ulga na materiały budowlane ZNIESIONA od 01.01.2014 — brak możliwości odliczenia",
    "_routing": "",
    "_routing_reason": "I4: Ulga na materiały budowlane — zniesiona (L-BUD-3 info)",
    "_legal_basis": "Ustawa z dnia 29.08.2005 o zwrocie osobom fizycznym niektórych wydatków... (wygasła 01.01.2014)",
    "_warnings": ["[I4 L-BUD-3] UWAGA: Ulga na materiały budowlane NIE istnieje od 01.01.2014! Limit 1 500 zł został zniesiony. Nie ma możliwości odliczenia VAT od materiałów budowlanych."]
} {
    object.get(input.invoice, "construction_materials_relief_requested", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I5. TRANSPORT TAX FLEET OPTIMIZER (P24 I5)                                ║
# ║  Fleet tax optimization (>3.5t, buses), DMC thresholds, pro rata sales     ║
# ║  Legal basis: Art. 8-13 ustawy o podatkach i opłatach lokalnych            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i5.r1: transport_tax_fleet_optimizer
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i5.transport_tax_fleet_optimizer",
    "package": "jdg.p24_innovations",
    "priority": 24015,
    "innovation_id": "I5",
    "innovation_name": "Transport Tax Fleet Optimizer",
    "vehicle_category": category,
    "dmc_kg": dmc,
    "tax_rate_category": rate_cat,
    "tax_per_vehicle_pln": tax_per_vehicle,
    "total_fleet_tax_pln": total_fleet_tax,
    "fleet_size": fleet_size,
    "_routing": "",
    "_routing_reason": sprintf("I5 Transport Tax: flota %d pojazdów, podatek łączny %.2f PLN", [fleet_size, total_fleet_tax]),
    "_legal_basis": "Art. 8-13 ustawy o podatkach i opłatach lokalnych",
    "_warnings": warnings
} {
    # Opty-in: analiza raportowana tylko na żądanie (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_transport_check", false) == true
    dmc := object.get(input.jdg_entrepreneur, "vehicle_dmc_kg", 0)
    vehicle_type := object.get(input.jdg_entrepreneur, "transport_vehicle_type", "")
    seats := object.get(input.jdg_entrepreneur, "vehicle_seats", 0)
    is_electric := object.get(input.jdg_entrepreneur, "vehicle_is_electric", false)
    is_hybrid := object.get(input.jdg_entrepreneur, "vehicle_is_hybrid", false)
    fleet_size := object.get(input.jdg_entrepreneur, "transport_fleet_size", 1)

    # Category / rate / tax — Rego v0: totalne funkcje pomocnicze (fix kompilacji)
    category := _vehicle_category(dmc, vehicle_type, seats, is_electric, is_hybrid)
    rate_cat := _vehicle_rate_cat(category)
    tax_per_vehicle := _vehicle_tax(rate_cat)

    total_fleet_tax := tax_per_vehicle * fleet_size

    warnings := [sprintf("[I5 Transport Tax] Kategoria: %s, DMC: %d kg, Stawka: ~%d PLN/rok (max MF), Flota: %d poj., Podatek łączny: ~%.2f PLN/rok. Stawki uchwala rada gminy — sprawdź lokalną uchwałę.",
        [category, dmc, tax_per_vehicle, fleet_size, total_fleet_tax])]
}

# jdg.p24_innovations.i5.r2: transport_tax_pro_rata_calculator
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i5.transport_tax_pro_rata",
    "package": "jdg.p24_innovations",
    "priority": 24016,
    "innovation_id": "I5",
    "innovation_name": "Transport Tax Fleet Optimizer",
    "pro_rata_applies": true,
    "months_owned": months_owned,
    "annual_tax_pln": annual_tax,
    "pro_rata_tax_pln": pro_rata_tax,
    "tax_until_month": tax_until,
    "_routing": "",
    "_routing_reason": sprintf("I5 Pro Rata: podatek za %d miesięcy = %.2f PLN", [months_owned, pro_rata_tax]),
    "_legal_basis": "Art. 9 ust. 5 ustawy o podatkach i opłatach lokalnych",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_prorata_check", false) == true
    purchase_month := object.get(input.jdg_entrepreneur, "vehicle_purchase_month", 0)
    sale_month := object.get(input.jdg_entrepreneur, "vehicle_sale_month", 0)
    current_month := object.get(input.jdg_entrepreneur, "current_tax_month", 0)
    annual_tax := object.get(input.jdg_entrepreneur, "estimated_annual_transport_tax_pln", 0)

    # Sale during year: tax until end of sale month (Rego v0: helpery — fix kompilacji)
    sale_pos := sale_month > 0
    purch_pos := purchase_month > 0
    sm1 := sale_month - 1
    pm_term := 12 - purchase_month + 1
    months_owned := _pick3(sale_pos, sm1, _and2(purch_pos, _not(sale_pos)), pm_term, 12)
    pro_rata_tax := (annual_tax / 12) * months_owned
    tax_until := _score(sale_pos, sale_month, 12)
    until_label := _score(sale_pos, sprintf("sprzedaży (miesiąc %d)", [tax_until]), "roku")

    warnings := [sprintf("[I5 Pro Rata] Zakup/sprzedaż w trakcie roku: podatek proporcjonalny za %d miesięcy = %.2f PLN (%d PLN rocznie). Podatek do końca %s.",
        [months_owned, pro_rata_tax, annual_tax, until_label])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I6. BUSINESS ACTIVITY CLASSIFIER (P24 I6)                                 ║
# ║  Automatic PKD classification from activity descriptions                   ║
# ║  Legal basis: Rozporządzenie RM ws. PKD (Dz.U. 2007 nr 251 poz. 1885)     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i6.r1: business_activity_classifier
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i6.activity_classifier",
    "package": "jdg.p24_innovations",
    "priority": 24017,
    "innovation_id": "I6",
    "innovation_name": "Business Activity Classifier (PKD Auto-Matcher)",
    "suggested_pkd_main": pkd,
    "suggested_pkd_description": pkd_desc,
    "confidence": conf,
    "_routing": "",
    "_routing_reason": sprintf("I6 PKD Classifier: %s — %s (confidence: %s)", [pkd, pkd_desc, conf]),
    "_legal_basis": "Rozporządzenie RM z 24.12.2007 ws. Polskiej Klasyfikacji Działalności",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_pkd_check", false) == true
    desc := lower(object.get(input.jdg_entrepreneur, "business_activity_description", ""))
    # Rego v0: klasyfikator jako totalna funkcja _pkd_class (fix kompilacji)
    pkd_cls := _pkd_class(desc)
    pkd := pkd_cls.pkd
    pkd_desc := pkd_cls.desc
    conf := pkd_cls.conf

    warnings := [sprintf("[I6 PKD Classifier] Sugerowany PKD: %s — %s (pewność: %s). Zweryfikuj w CEIDG przed rejestracją.",
        [pkd, pkd_desc, conf])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I7. LUMP SUM vs SCALE DECISION ENGINE (P24 I7)                            ║
# ║  Burden comparison: ryczałt vs skala vs liniowy vs karta vs estoński CIT   ║
# ║  Legal basis: Ustawa o PIT + Ustawa o ryczałcie + Ustawa o CIT (28c-28t)  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i7.r1: decision_engine_compare
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i7.decision_engine",
    "package": "jdg.p24_innovations",
    "priority": 24018,
    "innovation_id": "I7",
    "innovation_name": "Lump Sum vs Scale Decision Engine",
    "recommended_form": best_form,
    "annual_revenue_pln": revenue,
    "annual_costs_pln": costs,
    "comparison": comparison,
    "tax_savings_vs_worst_pln": savings,
    "_routing": "",
    "_routing_reason": sprintf("I7 Decision Engine: %s — oszczędność %.2f PLN rocznie", [best_form, savings]),
    "_legal_basis": "Ustawa o PIT (Art. 27), Ustawa o ryczałcie (Art. 12), Ustawa o CIT (Art. 28c-28t)",
    "_warnings": warnings
} {
    # Opty-in: analiza raportowana tylko na żądanie (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_formopt_check", false) == true
    revenue := object.get(input.jdg_entrepreneur, "estimated_annual_revenue_pln", 0)
    costs := object.get(input.jdg_entrepreneur, "estimated_annual_costs_pln", 0)
    pkwiu := object.get(input.jdg_entrepreneur, "primary_pkwiu", "")
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    reinvests := object.get(input.jdg_entrepreneur, "plans_reinvestment", false)

    income := revenue - costs

    # Tax calculations for each form (Rego v0: totalne funkcje — fix kompilacji)
    tax_scale := _tax_scale(income)
    tax_linear := _tax_linear(income)
    # Ryczałt rate based on PKWiU
    lump_rate := _lump_rate(pkwiu)
    tax_lump := revenue * lump_rate
    # Card tax (simplified)
    tax_card := 4800  # estimated annual
    # Estoński CIT (simplified)
    tax_est := _tax_est(reinvests, income)

    comparison := [
        {"form": "Skala podatkowa (12%/32%)", "tax_pln": tax_scale, "pros": "kwota wolna 30k, ulgi", "cons": "wysoki próg 32%"},
        {"form": "Liniowy 19%", "tax_pln": tax_linear, "pros": "stała stawka, bez progów", "cons": "brak kwoty wolnej, bez ulg na dzieci"},
        {"form": sprintf("Ryczałt %.1f%%", [lump_rate * 100]), "tax_pln": tax_lump, "pros": "uproszczona ewidencja", "cons": "limit 2M EUR, bez kosztów"},
        {"form": "Karta podatkowa", "tax_pln": tax_card, "pros": "brak ewidencji", "cons": "ograniczony zakres działalności"},
        {"form": "Estoński CIT", "tax_pln": tax_est, "pros": "0% przy reinwestycji", "cons": "min 3 pracowników, przychód <100M EUR"}
    ]

    # Find best (lowest tax) / max / min — Rego v0: funkcje totalne (fix kompilacji)
    lump_label := sprintf("Ryczałt %.1f%%", [lump_rate * 100])
    best_form := _best_form(tax_scale, tax_linear, lump_label, tax_lump, tax_card, tax_est)
    max_tax := max([tax_scale, tax_linear, tax_lump, tax_card, tax_est])
    min_tax := min([tax_scale, tax_linear, tax_lump, tax_card, tax_est])
    savings := max_tax - min_tax

    warnings := [sprintf("[I7 Decision Engine] Przy przychodzie %.2f PLN i kosztach %.2f PLN (dochód %.2f PLN): najlepsza forma = %s. Roczne oszczędności vs najgorsza forma: %.2f PLN. Porównanie: Skala=%.0f, Liniowy=%.0f, Ryczałt=%.0f, Karta=%.0f, Estoński=%.0f PLN.",
        [revenue, costs, income, best_form, savings, tax_scale, tax_linear, tax_lump, tax_card, tax_est])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I8. UNREGISTERED ACTIVITY DETECTOR (P24 I8)                               ║
# ║  Detection of unregistered activity against 75% min wage limit             ║
# ║  Legal basis: Art. 5 ustawy Prawo przedsiębiorców (Dz.U. 2018 poz. 646)   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i8.r1: unregistered_activity_limit_checker
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i8.unregistered_activity_checker",
    "package": "jdg.p24_innovations",
    "priority": 24019,
    "innovation_id": "I8",
    "innovation_name": "Unregistered Activity Detector",
    "min_wage_monthly_pln": min_wage,
    "limit_75pct_pln": limit_75pct,
    "current_monthly_revenue_pln": monthly_revenue,
    "limit_exceeded": limit_exceeded,
    "ceidg_registration_required": limit_exceeded,
    "year": 2026,
    "auto_indexation_note": "Limit = 75% minimalnego wynagrodzenia — aktualizowany automatycznie przy każdej zmianie płacy minimalnej (I8 dynamic indexation)",
    "_routing": route,
    "_routing_reason": reason,
    "_legal_basis": "Art. 5 ustawy Prawo przedsiębiorców (Dz.U. 2018 poz. 646)",
    "_warnings": warnings
} {
    # Wyzwalacz naturalny: klucz przychodu MUSI być jawny w wejściu (fix AP10 —
    # object.get z domyślnym 0 połykał każdy input jdg_entrepreneur i zasłaniał
    # i12/L-PP-2/no_match_final)
    object.get(input.jdg_entrepreneur, "monthly_revenue_unregistered_pln", null) != null
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_unregistered_pln", 0)
    # ADR-002: płaca minimalna z bounds (jedno źródło prawdy z L-PP-2), fallback 4800
    bounds := _bounds_snapshot
    min_wage := object.get(bounds, "minimum_wage_gross", 4800)
    limit_75pct := min_wage * 0.75
    limit_exceeded := monthly_revenue > limit_75pct

    near_limit := monthly_revenue > limit_75pct * 0.9
    route := _pick3(limit_exceeded, "BLOCK_AND_ALERT", near_limit, "TRIAGE_QUEUE", "")

    reason := _pick3(limit_exceeded,
        sprintf("PRZEKROCZONY limit działalności nieewidencjonowanej! Przychód %.2f PLN > %.2f PLN (75%% płacy min. %d PLN). Wymagana rejestracja CEIDG!",
            [monthly_revenue, limit_75pct, min_wage]),
        near_limit,
        sprintf("UWAGA: blisko limitu działalności nieewidencjonowanej (%.2f PLN / %.2f PLN)", [monthly_revenue, limit_75pct]),
        "Poniżej limitu działalności nieewidencjonowanej")

    warnings := [sprintf("[I8 Unregistered Activity Detector] %s. Limit 2026: %.2f PLN (75%% z %d PLN). Pamiętaj: przy zmianie płacy minimalnej limit zmienia się automatycznie.",
        [reason, limit_75pct, min_wage])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I9. SUCCESSION TAX LIABILITY ESTIMATOR (P24 I9)                           ║
# ║  Post-death liability and amortization continuity (Art. 22g ust. 12 PIT)   ║
# ║  Legal basis: Art. 22g ust. 12-15 PIT, ustawa o zarządzie sukcesyjnym     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i9.r1: succession_amortization_continuity
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i9.amortization_continuity",
    "package": "jdg.p24_innovations",
    "priority": 24020,
    "innovation_id": "I9",
    "innovation_name": "Succession Tax Liability Estimator",
    "amortization_continuity_applies": true,
    "assets_original_value_pln": original_value,
    "assets_current_book_value_pln": book_value,
    "annual_amortization_pln": annual_amort,
    "remaining_years": remaining_years,
    "successor_can_continue": true,
    "total_amortization_available_pln": total_available,
    "_routing": "",
    "_routing_reason": sprintf("I9 Amortyzacja: %.2f PLN rocznie odpisów dla sukcesora (pozostało %d lat)",
        [annual_amort, remaining_years]),
    "_legal_basis": "Art. 22g ust. 12 PIT — kontynuacja amortyzacji przez sukcesora",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    original_value := object.get(input.jdg_entrepreneur, "fixed_assets_original_value_pln", 0)
    book_value := object.get(input.jdg_entrepreneur, "fixed_assets_book_value_pln", 0)
    amort_rate := object.get(input.jdg_entrepreneur, "amortization_rate_pct", 20)
    years_amortized := object.get(input.jdg_entrepreneur, "years_amortized", 0)
    total_years := 100 / amort_rate
    remaining_years := round(total_years - years_amortized)

    annual_amort := original_value * amort_rate / 100
    total_available := book_value

    warnings := [sprintf("[I9 L-SUK-2] Sukcesor KONTYNUUJE amortyzację! Wartość początkowa: %.2f PLN, wartość bilansowa: %.2f PLN, stawka: %.0f%%, roczny odpis: %.2f PLN, pozostało ~%d lat. Art. 22g ust. 12 PIT: sukcesja = kontynuacja odpisów, NIE nowa amortyzacja.",
        [original_value, book_value, amort_rate, annual_amort, remaining_years])]
}

# jdg.p24_innovations.i9.r2: succession_zus_registration
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i9.zus_succession_registration",
    "package": "jdg.p24_innovations",
    "priority": 24021,
    "innovation_id": "I9",
    "innovation_name": "Succession Tax Liability Estimator",
    "zus_registration_deadline_days": 7,
    "zus_zua_required": true,
    "management_period_years": period,
    "management_period_extension_possible": period_ext,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("I9 ZUS: zarządca musi zgłosić się do ZUS w 7 dni. Okres zarządu: %d lat", [period]),
    "_legal_basis": "Art. 12 ust. 1 ustawy o zarządzie sukcesyjnym (ZUS), Art. 19 (okres zarządu)",
    "_warnings": warnings
} {
    # Opty-in: analiza raportowana tylko na żądanie (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_succession_active_check", false) == true
    is_succession := object.get(input.jdg_entrepreneur, "succession_active", false)
    days_since_death := object.get(input.jdg_entrepreneur, "days_since_death", 0)
    manager_registered_zus := object.get(input.jdg_entrepreneur, "succession_manager_zus_registered", false)
    court_extension := object.get(input.jdg_entrepreneur, "succession_court_extension", false)

    period := _score(court_extension, 5, 2)
    period_ext := _not(court_extension)

    deadline_passed := days_since_death > 7
    # Rego v0: etykieta statusu przez helpery (ternary-expression jest niepoprawne)
    over_deadline := _and2(deadline_passed, _not(manager_registered_zus))
    mgr_label := _pick3(over_deadline, "TERMIN PRZEKROCZONY!",
        manager_registered_zus, "Zgłoszono",
        sprintf("Zostało %d dni", [7 - days_since_death]))

    warnings := [sprintf("[I9 L-SUK-3] Zarządca sukcesyjny: zgłoszenie do ZUS (ZUS ZUA) w 7 dni od śmierci przedsiębiorcy. Minęło %d dni. %s",
        [days_since_death, mgr_label])]
}

# jdg.p24_innovations.i9.r3: succession_ksef_continuity
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i9.ksef_continuity",
    "package": "jdg.p24_innovations",
    "priority": 24022,
    "innovation_id": "I9",
    "innovation_name": "Succession Tax Liability Estimator",
    "ksef_obligation_continues": true,
    "vat_obligations_transferred": true,
    "nip_continues": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "I9 KSeF: sukcesor przejmuje obowiązki VAT i KSeF przedsiębiorstwa",
    "_legal_basis": "Art. 14 ustawy o zarządzie sukcesyjnym, Art. 96-106 VAT (rejestracja VAT)",
    "_warnings": ["[I9 L-SUK-4] Sukcesor PRZEJMUJE obowiązki VAT przedsiębiorstwa! NIP pozostaje ten sam. Faktury KSeF wystawiane w imieniu przedsiębiorstwa w spadku. JPK_V7 składane bez przerwy. Wyrejestrowanie VAT dopiero po zakończeniu zarządu sukcesyjnego."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I10. CONSTRUCTION VAT RATE AUTO-CLASSIFIER (P24 I10)                      ║
# ║  8% vs 23% VAT rate classification per construction service type           ║
# ║  Legal basis: Art. 41 ust. 12-12c VAT                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i10.r1: construction_vat_classifier
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i10.vat_classifier",
    "package": "jdg.p24_innovations",
    "priority": 24023,
    "innovation_id": "I10",
    "innovation_name": "Construction VAT Rate Auto-Classifier",
    "classification_result": result,
    "vat_rate_applied": vat_rate,
    "conditions_checked": conditions,
    "_routing": "",
    "_routing_reason": sprintf("I10 VAT Classifier: %s", [result]),
    "_legal_basis": "Art. 41 ust. 12-12c VAT",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.invoice, "construction_analysis_requested", false) == true
    is_residential := object.get(input.invoice, "is_residential_construction", false)
    floor_area := object.get(input.invoice, "building_floor_area_m2", 0)
    is_single_family := object.get(input.invoice, "is_single_family_house", false)
    is_multi_family := object.get(input.invoice, "is_multi_family_building", false)
    is_renovation := object.get(input.invoice, "is_renovation_service", false)
    is_new_construction := object.get(input.invoice, "is_new_construction", false)
    includes_materials := object.get(input.invoice, "includes_materials", false)

    # Classification logic (Rego v0: helpery — fix kompilacji)
    not_res := _not(is_residential)
    big_area := floor_area > 300
    small_area := floor_area <= 300
    vat_rate := _score(_and2(is_residential, small_area), 0.08, 0.23)
    result := _pick3(not_res, "VAT 23% — budynek niemieszkalny lub powierzchnia > 300 m2",
        _and2(is_residential, big_area), "VAT 23% — powierzchnia przekracza limit 300 m2",
        "VAT 8% — budownictwo mieszkaniowe (Art. 41 ust. 12 VAT)")

    conditions := [
        {"condition": "Budynek mieszkalny", "met": is_residential},
        {"condition": "Powierzchnia <= 300 m2", "met": floor_area <= 300, "actual": floor_area},
        {"condition": "Dom jednorodzinny", "met": is_single_family},
        {"condition": "Budynek wielorodzinny", "met": is_multi_family},
        {"condition": "Remont/modernizacja", "met": is_renovation},
        {"condition": "Nowa budowa", "met": is_new_construction},
        {"condition": "Materiały w cenie usługi", "met": includes_materials}
    ]

    # Rego v0: etykieta materiałów przez helper (ternary-expression niepoprawne)
    mat_label := _score(_and2(includes_materials, vat_rate == 0.08), "Materiały w cenie usługi = całość 8%", "")
    warnings := [sprintf("[I10 VAT Classifier L-BUD-2] %s. Pow. użytkowa: %.0f m2. %s",
        [result, floor_area,
         mat_label])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I11. MULTI-BRANCH TRANSPORT TAX MANAGER (P24 I11)                         ║
# ║  Fleet and multi-branch tax management per municipality                    ║
# ║  Legal basis: Art. 8-13 ustawy o podatkach i opłatach lokalnych            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i11.r1: multi_branch_transport_manager
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i11.multi_branch_manager",
    "package": "jdg.p24_innovations",
    "priority": 24024,
    "innovation_id": "I11",
    "innovation_name": "Multi-Branch Transport Tax Manager",
    "branches_count": branch_count,
    "total_fleet_vehicles": total_vehicles,
    "per_municipality_breakdown": municipality_tax,
    "total_annual_tax_all_branches_pln": total_tax,
    "_routing": "",
    "_routing_reason": sprintf("I11 Multi-Branch: %d oddziałów, %d pojazdów, podatek łączny ~%.2f PLN",
        [branch_count, total_vehicles, total_tax]),
    "_legal_basis": "Art. 8-13 ustawy o podatkach i opłatach lokalnych",
    "_warnings": warnings
} {
    # Opty-in: analiza raportowana tylko na żądanie (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_multibranch_check", false) == true
    branches := object.get(input.jdg_entrepreneur, "transport_branches", [])
    branch_count := count(branches)
    # Simplified: each branch has vehicles array
    # (Rego v0: zmienne single-assignment — jedno wiązanie bez wstępnych zer)
    vehicles := object.get(input.jdg_entrepreneur, "transport_fleet_vehicles", [])
    total_vehicles := count(vehicles)
    total_tax := total_vehicles * 2800  # estimated average
    municipality_tax := [{"municipality": "Główna siedziba", "vehicles": total_vehicles, "estimated_tax_pln": total_tax}]

    warnings := [sprintf("[I11 Multi-Branch] Zarządzanie flotą w %d oddziałach. Łącznie %d pojazdów. Szacunkowy podatek roczny: ~%.2f PLN (stawki wg uchwał poszczególnych gmin). Pamiętaj: każda gmina ustala własne stawki — złóż DT-1 dla każdej lokalizacji.",
        [branch_count, total_vehicles, total_tax])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  I12. MICRO-MODULE COVERAGE COMPLETENESS MATRIX (P24 I12)                  ║
# ║  Automated gap reporting per module in CI                                  ║
# ║  Legal basis: meta — narzędzie monitorowania pokrycia                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.i12.r1: coverage_matrix_reporter
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.i12.coverage_matrix",
    "package": "jdg.p24_innovations",
    "priority": 24025,
    "innovation_id": "I12",
    "innovation_name": "Micro-Module Coverage Completeness Matrix",
    "modules_analyzed": 6,
    "total_rules_available": 795,
    "coverage_summary": coverage,
    "gaps_remaining": gaps,
    "ci_readiness_pct": readiness,
    "_routing": "",
    "_routing_reason": sprintf("I12 Coverage Matrix: gotowość CI %.0f%% (%d luk pozostało)",
        [readiness, count(gaps)]),
    "_legal_basis": "Meta-narzędzie monitorowania pokrycia reguł OPA",
    "_warnings": warnings
} {
    # Opty-in: raport pokrycia tylko na żądanie (bez tego gałąź
    # połyka każdy unmatched input i unieważnia no_match_final — fix AP10)
    object.get(input.jdg_entrepreneur, "p24_coverage_check", false) == true
    # Static coverage data (would be dynamic in CI)
    coverage := [
        {"module": "CEIDG", "rules": 35, "coverage_pct": 80, "gaps": ["L-CEIDG-3 (ZUS/US interakcja)"]},
        {"module": "Ryczałt", "rules": 148, "coverage_pct": 92, "gaps": ["L-RYC-2 (PKWiU matcher)", "L-RYC-3 (karta podatkowa 14 dni)"]},
        {"module": "Sukcesja", "rules": 123, "coverage_pct": 95, "gaps": ["L-SUK-4 (KSeF interakcja)"]},
        {"module": "Budownictwo", "rules": 51, "coverage_pct": 95, "gaps": ["L-BUD-3 (brak ulgi info)"]},
        {"module": "Transport", "rules": 45, "coverage_pct": 72, "gaps": ["L-TR-1 (progi DMC szczegółowe)"]},
        {"module": "PP", "rules": 143, "coverage_pct": 90, "gaps": ["L-PP-2 (auto-indexacja limitu)"]}
    ]

    gaps := [gap | coverage_entry := coverage[_]; gap := coverage_entry.gaps[_]]
    total_gaps := count(gaps)
    avg_coverage := 87.33  # (80+92+95+95+72+90)/6

    # Rego v0: arytmetyka bool→number przez helper (bool × number = type error)
    readiness := (avg_coverage + _score(count(gaps) == 0, 5, 0)) / 100 * 100

    warnings := [sprintf("[I12 Coverage Matrix] 6 modułów P24, 795 reguł, średnie pokrycie %.0f%%. Pozostałe luki: %d. Najsłabszy moduł: Transport (72%%). CI readiness: %.0f%%. Rekomendacja: domknąć L-TR-1 i wdrożyć walidator 3P przed release.",
        [avg_coverage, total_gaps, readiness])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  L-RYC-2: PKWiU SEMANTIC MATCHER ENHANCED (embedded in I2)                 ║
# ║  L-RYC-3: TAX CARD 14-DAY REGISTRATION (P24 gap closure)                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.l_ryc3.r1: tax_card_registration_deadline
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.l_ryc3.tax_card_deadline",
    "package": "jdg.p24_innovations",
    "priority": 24026,
    "innovation_id": "L-RYC-3",
    "innovation_name": "Tax Card 14-Day Registration Deadline",
    "tax_card_application_deadline_days": 14,
    "days_remaining": days_rem,
    "deadline_passed": passed,
    "_routing": route,
    "_routing_reason": reason,
    "_legal_basis": "Art. 29 ust. 1 ustawy o ryczałcie (zgłoszenie karty podatkowej 14 dni przed rozpoczęciem)",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.jdg_entrepreneur, "tax_card_selected", false) == true
    tax_card_selected := object.get(input.jdg_entrepreneur, "tax_card_selected", false)
    business_start_date := object.get(input.jdg_entrepreneur, "business_start_date", "")
    tax_card_filed := object.get(input.jdg_entrepreneur, "tax_card_filed", false)
    days_before_start := object.get(input.jdg_entrepreneur, "days_before_business_start", 0)

    # Rego v0: helpery — fix kompilacji
    lt14 := days_before_start < 14
    ge14 := days_before_start >= 14
    d14 := 14 - days_before_start
    days_rem := _score(lt14, d14, 0)
    over14 := days_before_start > 14
    passed := _and2(over14, _not(tax_card_filed))
    near3 := days_rem <= 3
    not_filed := _not(tax_card_filed)
    route := _pick3(passed, "BLOCK_AND_ALERT", _and3(_not(passed), near3, not_filed), "TRIAGE_QUEUE", "")
    reason := _pick3(passed,
        "TERMIN MINĄŁ! Karta podatkowa wymaga zgłoszenia 14 dni przed rozpoczęciem działalności",
        _and2(_not(passed), not_filed),
        sprintf("Zostało %d dni na zgłoszenie karty podatkowej", [days_rem]),
        "Karta podatkowa zgłoszona")

    warnings := [sprintf("[L-RYC-3] Karta podatkowa (Art. 21-30 ustawy o ryczałcie): %s. Dotyczy: handel detaliczny, gastronomia, usługi transportowe — bez prawa zatrudnienia >2 pracowników. Formularz PIT-16 do US.",
        [reason])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  L-PP-2: AUTO-INDEXATION FOR UNREGISTERED ACTIVITY LIMIT (P24 gap closure) ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.l_pp2.r1: auto_indexation_unregistered_limit
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.l_pp2.auto_indexation",
    "package": "jdg.p24_innovations",
    "priority": 24027,
    "innovation_id": "L-PP-2",
    "innovation_name": "Unregistered Activity Limit Auto-Indexation",
    "min_wage_current_pln": min_wage_val,
    "limit_75pct_current_pln": limit_val,
    "min_wage_historical": historical,
    "limit_changed_this_year": changed,
    "next_expected_change_date": "2027-01-01",
    "_routing": "",
    "_routing_reason": sprintf("L-PP-2: Limit indeksowany — %.2f PLN (75%% z %d PLN)", [limit_val, min_wage_val]),
    "_legal_basis": "Art. 5 ustawy Prawo przedsiębiorców — 75% minimalnego wynagrodzenia",
    "_warnings": warnings
} {
    # Opty-in: indeksacja limitu raportowana tylko na żądanie (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_autoindex_check", false) == true
    # Dynamic min wage lookup
    # ADR-002: płaca minimalna z bounds (jedno źródło prawdy z i8), fallback 4800
    bounds_pp2 := _bounds_snapshot
    min_wage_val := object.get(bounds_pp2, "minimum_wage_gross", 4800)
    limit_val := min_wage_val * 0.75

    historical := [
        {"year": 2023, "min_wage": 3490, "limit": 2617.50},
        {"year": "2024_h1", "min_wage": 4242, "limit": 3181.50},
        {"year": "2024_h2", "min_wage": 4300, "limit": 3225},
        {"year": 2025, "min_wage": 4666, "limit": 3499.50},
        {"year": 2026, "min_wage": 4800, "limit": 3600.00}
    ]

    # Rego v0: proste związanie boola (fix kompilacji)
    changed := min_wage_val != 4800  # true gdy płaca minimalna odbiega od 2026

    warnings := [sprintf("[L-PP-2 Auto-Indexation] Limit działalności nieewidencjonowanej: %.2f PLN miesięcznie (75%% z %d PLN płacy minimalnej 2026). Limit zmienia się automatycznie przy każdej zmianie płacy minimalnej. Historycznie: 2023=%.2f, 2024=%.2f, 2025=%.2f, 2026=%.2f PLN.",
        [limit_val, min_wage_val, 2617.50, 3225.00, 3499.50, 3600.00])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  L-CEIDG-3: CEIDG ↔ ZUS ↔ US INTERACTION (P24 gap closure)                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.l_ceidg3.r1: ceidg_zus_us_interaction
else := {
    "matched": true,
    "rule_id": "jdg.p24_innovations.l_ceidg3.interaction",
    "package": "jdg.p24_innovations",
    "priority": 24028,
    "innovation_id": "L-CEIDG-3",
    "innovation_name": "CEIDG ↔ ZUS ↔ US Interaction Tracker",
    "ceidg_registration_date": ceidg_date,
    "zus_zua_auto_sent": zus_auto,
    "zus_zua_deadline_days": 7,
    "us_tax_office_notified": us_notified,
    "nip_auto_assigned": nip_auto,
    "interaction_flow_complete": flow_complete,
    "_routing": route,
    "_routing_reason": reason,
    "_legal_basis": "Art. 7a ustawy o CEIDG (integracja CEIDG-ZUS-US), Art. 8 (NIP automatyczny)",
    "_warnings": warnings
} {
    # Opty-in / wyzwalacz wejściowy (fix AP10)
    object.get(input.jdg_entrepreneur, "p24_interaction_check", false) == true
    ceidg_filed := object.get(input.jdg_entrepreneur, "ceidg_application_filed", false)
    days_since_filing := object.get(input.jdg_entrepreneur, "days_since_ceidg_filing", 0)
    zus_auto := object.get(input.jdg_entrepreneur, "zus_zua_auto_from_ceidg", false)
    us_notified := object.get(input.jdg_entrepreneur, "tax_office_notified", false)
    nip_auto := object.get(input.jdg_entrepreneur, "nip_assigned_auto", false)
    is_new_jdg := object.get(input.jdg_entrepreneur, "is_new_jdg_registration", false)

    # Rego v0: helpery — fix kompilacji
    flow_complete := _and3(zus_auto, us_notified, nip_auto)
    ceidg_date := object.get(input.jdg_entrepreneur, "ceidg_filing_date", "")
    late := days_since_filing > 7
    on_time := days_since_filing <= 7
    route := _pick3(_and3(is_new_jdg, _not(flow_complete), late), "BLOCK_AND_ALERT",
        _and3(is_new_jdg, _not(flow_complete), _not(late)), "TRIAGE_QUEUE", "")
    reason := _pick3(flow_complete,
        "Kompletny flow CEIDG→ZUS→US: ZUS ZUA automatycznie, NIP nadany, US powiadomiony",
        _and2(_not(flow_complete), on_time),
        sprintf("Oczekiwanie na integrację CEIDG→ZUS→US (dzień %d/7)...", [days_since_filing]),
        "UWAGA: Flow CEIDG→ZUS→US niekompletny po 7 dniach — sprawdź status!")
    zua_label := _score(zus_auto, "automatycznie", "oczekuje")
    nip_label := _score(nip_auto, "nadany automatycznie", "oczekuje")
    us_label := _score(us_notified, "powiadomiony", "oczekuje")
    warnings := [sprintf("[L-CEIDG-3] Flow integracyjny CEIDG→ZUS→US: %s. ZUS ZUA: %s. NIP: %s. US: %s. CEIDG automatycznie przekazuje dane do ZUS i US — nie musisz składać osobnych formularzy.",
        [reason, zua_label, nip_label, us_label])]
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  FINAL FALLBACK                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.p24_innovations.fallback
else := {
    "matched": false,
    "rule_id": "jdg.p24_innovations.no_match_final",
    "package": "jdg.p24_innovations",
    "priority": 24999,
    "_routing": "",
    "_routing_reason": "P24 Innovations: no matching rule — all checks passed or not applicable",
    "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": []
} {
    true
}
