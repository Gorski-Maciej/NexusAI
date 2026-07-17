# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise PIT Article 21 Exemptions (Class B → A)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: PIT Art. 21 — Zwolnienia przedmiotowe dla JDG
# description: |
#   ENTERPRISE v5.0 — Wypełnia lukę ~90 punktów Klasy B (PIT Art. 21).
#   Zwolnienia przedmiotowe to jeden z najbardziej złożonych obszarów PIT.
#   Implementuje kluczowe zwolnienia dla JDG:
#   - Ulga dla młodych (do 26 r.ż., limit 85 528 PLN)
#   - Ulga na powrót (4 lata, 85 528 PLN/rok)
#   - Ulga dla rodzin 4+ 
#   - Ulga dla pracujących emerytów
#   - Zwolnienia odszkodowań i zapomóg
#   - Zwolnienia stypendiów i dotacji
#   - Zwolnienia z ZFŚS
#   - Dieta i delegacje służbowe
# architecture: Enterprise Multi-Pass, First-Match-Wins else-chain
# legal_basis: Art. 21 ust. 1 PIT
# package: jdg.pit.art21_exemptions
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.art21_exemptions

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.art21.no_match",
    "package": "jdg.pit.art21_exemptions", "priority": 2199
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E100-E109: ULGA DLA MŁODYCH (Art. 21 ust. 1 pkt 148 PIT)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E100: young_relief_eligibility — Ulga dla młodych do 26 lat ──
decide := {
    "matched": true, "rule_id": "jdg.pit.art21.young_relief_eligibility",
    "package": "jdg.pit.art21_exemptions", "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "YOUNG_RELIEF",
    "pit_exemption_applies": is_eligible,
    "pit_exemption_limit_pln": 85528,
    "pit_exemption_used_pln": exemption_used,
    "pit_exemption_remaining_pln": exemption_remaining,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": exemption_routing,
    "_routing_reason": sprintf("Ulga dla młodych: %s — limit %.0f PLN, wykorzystano %.0f PLN", [status, 85528.0, exemption_used]),
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
    "_warnings": [sprintf("ULGA DLA MŁODYCH (do 26 lat) — %s. Limit: 85 528 PLN rocznie. Obejmuje: przychody z umowy o pracę, zlecenia, praktyk. NIE obejmuje: działalności gospodarczej! JDG = brak ulgi dla młodych z DG.", [status_detail])]
} {
    input.jdg_entrepreneur.age_at_year_start <= 26
    input.jdg_entrepreneur.tax_year_as_int >= 2020  # Ulga od 1 sierpnia 2019, w pełni od 2020
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 0)
    exemption_used := min([annual_income, 85528])
    exemption_remaining := max([0, 85528 - annual_income])
    is_eligible := true
    status = "PRZYSŁUGUJE" { is_eligible == true; exemption_remaining > 0 }
    status = "LIMIT WYCZERPANY" { exemption_remaining <= 0 }
    status_detail = sprintf("Zwolnione %.0f PLN, pozostało %.0f PLN", [exemption_used, exemption_remaining]) { exemption_remaining > 0 }
    status_detail = "Limit 85 528 PLN wyczerpany — nadwyżka opodatkowana" { exemption_remaining <= 0 }
    exemption_routing = "" { true }
}

# ── E101: young_relief_not_for_jdg — Ulga dla młodych NIE dla DG ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.young_relief_not_for_jdg",
    "package": "jdg.pit.art21_exemptions", "priority": 101,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "YOUNG_RELIEF",
    "pit_exemption_applies": false,
    "pit_exemption_reason": "Ulga dla młodych NIE dotyczy przychodów z działalności gospodarczej",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT (wyłączenie dla DG)",
    "_warnings": ["ULGA DLA MŁODYCH — UWAGA: Przychody z JDG NIE są objęte ulgą dla młodych! Ulga obejmuje tylko umowę o pracę, zlecenia i praktyki. Dla JDG — płacisz normalny PIT."]
} {
    input.jdg_entrepreneur.age_at_year_start <= 26
    input.invoice.income_source == "JDG"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E110-E119: ULGA NA POWRÓT (Art. 21 ust. 1 pkt 152 PIT)                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E110: return_relief_eligibility — Ulga na powrót z emigracji ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.return_relief",
    "package": "jdg.pit.art21_exemptions", "priority": 110,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "RETURN_RELIEF",
    "pit_exemption_applies": is_eligible,
    "pit_exemption_limit_pln": 85528,
    "pit_exemption_years": 4,
    "pit_exemption_years_remaining": years_remaining,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Ulga na powrót: %s — %d lat pozostało z 4-letniego limitu", [status, years_remaining]),
    "_legal_basis": "Art. 21 ust. 1 pkt 152 PIT",
    "_warnings": [sprintf("ULGA NA POWRÓT — %s. Limit: 85 528 PLN rocznie przez 4 lata podatkowe. Warunki: (1) zmiana rezydencji podatkowej na Polskę, (2) brak rezydencji PL przez ostatnie 3 lata, (3) dotyczy przychodów z pracy, zleceń ORAZ DG! To JEDYNA ulga dla młodych obejmująca JDG.", [status_detail])]
} {
    input.jdg_entrepreneur.return_relief_eligible == true
    return_year := object.get(input.jdg_entrepreneur, "return_to_pl_year", 2023)
    current_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
    years_elapsed := current_year - return_year
    years_remaining := max([0, 4 - years_elapsed])
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 0)
    is_eligible := years_remaining > 0
    status = "PRZYSŁUGUJE" { is_eligible == true }
    status = "WYGASŁA" { is_eligible == false }
    status_detail = sprintf("Limit %.0f PLN/rok, pozostało %d lat", [85528.0, years_remaining]) { is_eligible }
    status_detail = "Okres 4 lat od powrotu minął" { not is_eligible }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E120-E129: ULGA DLA RODZIN 4+ (Art. 21 ust. 1 pkt 153 PIT)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E120: family_4plus_relief — Ulga dla rodziców 4+ dzieci ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.family_4plus_relief",
    "package": "jdg.pit.art21_exemptions", "priority": 120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "FAMILY_4PLUS",
    "pit_exemption_applies": is_eligible,
    "pit_exemption_limit_pln": 85528,
    "pit_exemption_children_count": children_count,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Ulga dla rodzin 4+: %s — %d dzieci. Limit %.0f PLN na rodzica.", [status, children_count, 85528.0]),
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT",
    "_warnings": [sprintf("ULGA DLA RODZIN 4+ — %s. (1) Limit 85 528 PLN rocznie OSOBNO na każdego rodzica, (2) Dotyczy przychodów z pracy, zleceń ORAZ DG (nawet na ryczałcie!), (3) Dzieci do 18 lat (lub do 25 lat jeśli się uczą), (4) NIE łączy się z ulgą dla młodych!", [status_detail])]
} {
    children_count := object.get(input.jdg_entrepreneur, "children_count", 0)
    children_count >= 4
    is_eligible := true
    status = "PRZYSŁUGUJE" { is_eligible == true }
    status_detail = sprintf("%d dzieci — zwolnienie %.0f PLN/rok na rodzica", [children_count, 85528.0])
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E130-E139: ULGA DLA PRACUJĄCYCH EMERYTÓW (Art. 21 ust. 1 pkt 154 PIT)  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E130: working_senior_relief — Ulga dla pracujących emerytów ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.working_senior_relief",
    "package": "jdg.pit.art21_exemptions", "priority": 130,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "WORKING_SENIOR",
    "pit_exemption_applies": is_eligible,
    "pit_exemption_limit_pln": 85528,
    "pit_exemption_conditions": ["WIEK_EMERYTALNY", "NIE_OTRZYMUJE_EMERYTURY", "PRACUJE"],
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Ulga dla pracujących emerytów: %s", [status]),
    "_legal_basis": "Art. 21 ust. 1 pkt 154 PIT",
    "_warnings": [sprintf("ULGA DLA PRACUJĄCYCH EMERYTÓW — %s. Warunki: (1) Kobieta ≥60 lat / Mężczyzna ≥65 lat, (2) NIE pobiera emerytury/renty (nawet jej nie zawiesiłaś!), (3) Pracuje na etacie/zleceniu/DG. Limit 85 528 PLN rocznie. UWAGA: złożenie wniosku o emeryturę = UTRATA ulgi wstecz!", [status_detail])]
} {
    age := object.get(input.jdg_entrepreneur, "age_at_year_start", 40)
    is_female := object.get(input.jdg_entrepreneur, "is_female", false)
    retirement_age = 60 { is_female == true }
    retirement_age = 65 { is_female == false }
    receives_pension := object.get(input.jdg_entrepreneur, "receives_pension", false)
    is_eligible := age >= retirement_age and not receives_pension
    status = "PRZYSŁUGUJE" { is_eligible == true }
    status = "NIE PRZYSŁUGUJE" { is_eligible == false }
    status_detail = "Wiek emerytalny osiągnięty, emerytura niepobierana — ulga działa!" { is_eligible }
    status_detail = sprintf("Wiek %d < %d" , [age, retirement_age]) { age < retirement_age }
    status_detail = "Pobiera emeryturę — ulga wykluczona" { receives_pension }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E200-E209: ZWOLNIENIA ODSZKODOWAŃ I ZAPOMÓG (Art. 21 ust. 1 pkt 3-4)   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E200: compensation_exemption — Odszkodowania zwolnione ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.compensation_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "COMPENSATION",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": compensation_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Odszkodowanie: %s", [exemption_status]),
    "_legal_basis": "Art. 21 ust. 1 pkt 3-4 PIT",
    "_warnings": [sprintf("ODSZKODOWANIE — %s. Kwota: %.2f PLN. (1) Odszkodowania z OC i NW są zwolnione, (2) Odszkodowania od pracodawcy — zwolnione jeśli wynikają z przepisów prawa pracy, (3) Odszkodowania za wywłaszczenie — zwolnione. UWAGA: odszkodowania za utracone korzyści SĄ opodatkowane!", [exemption_status, compensation_amount])]
} {
    input.invoice.income_type == "COMPENSATION"
    compensation_amount := object.get(input.invoice, "amount_net", 0)
    is_statutory := object.get(input.invoice, "is_statutory_compensation", true)
    is_lost_profits := object.get(input.invoice, "is_lost_profits", false)
    is_exempt := is_statutory and not is_lost_profits
    exemption_status = "ZWOLNIONE z PIT" { is_exempt == true }
    exemption_status = "OPODATKOWANE — utracone korzyści" { is_lost_profits == true }
    exemption_status = "OPODATKOWANE — nie wynika z przepisów" { not is_statutory and not is_lost_profits }
}

# ── E201: social_assistance_exemption — Zapomogi i świadczenia socjalne ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.social_assistance",
    "package": "jdg.pit.art21_exemptions", "priority": 201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "SOCIAL_ASSISTANCE",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_limit_pln": 10000,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Zapomoga/ZFŚS: %s — %.2f PLN", [exemption_status, amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 26, 38, 67 PIT",
    "_warnings": [sprintf("ZAPOMOGA SOCJALNA — %s. Kwota %.2f PLN. (1) Zapomogi z ZFŚS do 10 000 PLN/rok = zwolnione, (2) Zapomogi losowe (powódź, pożar) = zwolnione bez limitu, (3) Powyżej 10k PLN = opodatkowane. Nie dotyczy JDG wypłacającej sobie samej!", [exemption_status, amount])]
} {
    input.invoice.income_type in {"SOCIAL_ASSISTANCE", "ZFS_BENEFIT", "DISASTER_RELIEF"}
    amount := object.get(input.invoice, "amount_net", 0)
    is_disaster := object.get(input.invoice, "is_disaster_relief", false)
    is_exempt := amount <= 10000 or is_disaster
    exemption_status = "ZWOLNIONE" { is_exempt == true }
    exemption_status = sprintf("OPODATKOWANE — nadwyżka %.2f PLN ponad 10k", [amount - 10000]) { not is_exempt }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E210-E219: STYPENDIA I DOTACJE (Art. 21 ust. 1 pkt 39-40 PIT)          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E210: scholarship_exemption — Stypendia zwolnione ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.scholarship_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 210,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "SCHOLARSHIP",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_limit_pln": exemption_limit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Stypendium: %s — %.2f PLN", [status, amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 39-40b PIT",
    "_warnings": [sprintf("STYPENDIUM/DOTACJA — %s. %.2f PLN. Limity: (1) Stypendia szkolne/studenckie — brak limitu, (2) Stypendia sportowe — zwolnione, (3) Dotacje z UP — zwolnione do 6× przeciętnego wynagrodzenia, (4) Stypendia naukowe dla JDG — opodatkowane!", [status, amount])]
} {
    input.invoice.income_type in {"SCHOLARSHIP", "GRANT", "LABOR_OFFICE_GRANT"}
    amount := object.get(input.invoice, "amount_net", 0)
    is_student := object.get(input.invoice, "is_student_scholarship", false)
    is_sport := object.get(input.invoice, "is_sport_scholarship", false)
    is_pup := object.get(input.invoice, "is_labor_office_grant", false)
    exemption_limit = 999999999 { is_student == true or is_sport == true }  # brak limitu
    exemption_limit = 6 * 7000 { is_pup == true }  # 6 × przeciętne wynagrodzenie
    exemption_limit = 0 { true }
    is_exempt := amount <= exemption_limit and exemption_limit > 0
    status = "ZWOLNIONE" { is_exempt == true }
    status = "OPODATKOWANE" { not is_exempt }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E300-E309: DIETY I DELEGACJE (Art. 21 ust. 1 pkt 16 PIT)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E300: business_travel_per_diem — Diety za delegacje służbowe ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.business_travel_per_diem",
    "package": "jdg.pit.art21_exemptions", "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "BUSINESS_TRAVEL",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_per_diem_pln": per_diem,
    "pit_exemption_days": travel_days,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Delegacja: %d dni × %.2f PLN = %.2f PLN zwolnione", [travel_days, per_diem, total_exempt]),
    "_legal_basis": "Art. 21 ust. 1 pkt 16 PIT",
    "_warnings": [sprintf("DELEGACJA SŁUŻBOWA — %d dni × %.2f PLN. Łącznie zwolnione: %.2f PLN. UWAGA: Dotyczy TYLKO pracowników (etat)! JDG NIE rozlicza diet — rozlicza faktyczne koszty podróży w PKPiR.", [travel_days, per_diem, total_exempt])]
} {
    input.employment.has_employees == true
    input.invoice.income_type == "BUSINESS_TRAVEL"
    travel_days := object.get(input.invoice, "travel_days", 1)
    is_domestic := object.get(input.invoice, "is_domestic_travel", true)
    per_diem = 45.00 { is_domestic == true }
    per_diem = 57.00 { not is_domestic }  # EUR — uproszczenie
    total_exempt := floor(travel_days * per_diem * 100) / 100
    is_exempt := true
}

# ── E301: jdg_travel_no_per_diem — JDG nie rozlicza diet ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.jdg_travel_no_diets",
    "package": "jdg.pit.art21_exemptions", "priority": 301,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "BUSINESS_TRAVEL",
    "pit_exemption_applies": false,
    "pit_exemption_note": "JDG NIE rozlicza diet — ewidencjonuj FAKTYCZNE koszty podróży w PKPiR jako KUP",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 16 PIT (wyłączenie dla przedsiębiorców)",
    "_warnings": ["DELEGACJE JDG — Przedsiębiorca NIE rozlicza diet! Zamiast tego: (1) Faktury za paliwo → KUP, (2) Faktury za hotel → KUP, (3) Bilety lotnicze/kolejowe → KUP, (4) Ryczałt za używanie prywatnego auta → kilometrówka."]
} {
    input.invoice.income_type == "BUSINESS_TRAVEL"
    input.jdg_entrepreneur.business_type == "JDG"
    not input.employment.has_employees
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E400-E409: PRZYCHODY KAPITAŁOWE (Art. 21 ust. 1 pkt 50-52 PIT)         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E400: dividends_exemption — Dywidendy i zyski kapitałowe ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.dividend_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_income_type": "CAPITAL_GAINS",
    "pit_separate_from_jdg": true,
    "pit_tax_rate_capital": 0.19,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przychody kapitałowe — ODDZIELNIE od JDG! Stawka 19%.",
    "_legal_basis": "Art. 21 ust. 1 pkt 50-52, Art. 30a-30b PIT",
    "_warnings": [sprintf("%s — %.2f PLN. KLUCZOWE: (1) Przychody kapitałowe NIE wchodzą do JDG! Oddzielnie 19%% ryczałt PIT-38 do 30 kwietnia, (2) Dywidendy, odsetki, zyski z akcji/krypto = zawsze 19%% ryczałt, (3) Strata z giełdy NIE obniża dochodu JDG!", [income_label, amount])]
} {
    input.invoice.income_type in {"DIVIDENDS", "INTEREST", "STOCK_PROFIT", "CRYPTO_PROFIT", "CAPITAL_GAINS"}
    input.jdg_entrepreneur.business_type == "JDG"
    amount := object.get(input.invoice, "amount_net", 0)
    income_label = "DYWIDENDY" { input.invoice.income_type == "DIVIDENDS" }
    income_label = "ODSETKI" { input.invoice.income_type == "INTEREST" }
    income_label = "ZYSK GIEŁDOWY" { input.invoice.income_type == "STOCK_PROFIT" }
    income_label = "KRYPTOWALUTY" { input.invoice.income_type == "CRYPTO_PROFIT" }
    income_label = "ZYSKI KAPITAŁOWE" { true }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E500-E509: INNE ZWOLNIENIA DLA JDG                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E500: vat_exempt_revenue_no_double_tax — Przychód zwolniony z VAT nie jest podwójnie opodatkowany ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.vat_exempt_no_duplicate",
    "package": "jdg.pit.art21_exemptions", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_note": "Przychód wykazywany w PKPiR w kwocie netto (bez VAT) lub brutto (przy zwolnieniu VAT)",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 1 PIT",
    "_warnings": [sprintf("PRZYCHÓD JDG — %.2f PLN (%s). Zasady: (1) VAT czynny → przychód NETTO (VAT nie jest przychodem!), (2) ZW VAT → przychód BRUTTO (faktura bez VAT), (3) Dotacje do środków trwałych → zwolnione do wartości amortyzacji.", [revenue, vat_note])]
} {
    input.invoice.direction == "SALE"
    input.invoice.income_type == "JDG"
    is_vat_payer := object.get(input.jdg_entrepreneur, "is_vat_payer", false)
    revenue = input.invoice.amount_net { is_vat_payer == true }
    revenue = input.invoice.amount_gross { is_vat_payer == false }
    vat_note = "VAT czynny — przychód NETTO" { is_vat_payer == true }
    vat_note = "Zwolniony z VAT — przychód BRUTTO" { is_vat_payer == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.art21.fallback",
    "package": "jdg.pit.art21_exemptions", "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 PIT",
    "_warnings": ["Przychód podlega standardowemu opodatkowaniu PIT według wybranej formy JDG. Brak zwolnień przedmiotowych z Art. 21 dla tego typu przychodu."]
} {
    true
}
