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
import data.jdg.thresholds

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
    "pit_exemption_limit_pln": thresholds.pit.pit_relief_shared_limit,
    "pit_exemption_used_pln": exemption_used,
    "pit_exemption_remaining_pln": exemption_remaining,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": exemption_routing,
    "_routing_reason": sprintf("Ulga dla młodych: %s — limit %.0f PLN, wykorzystano %.0f PLN", [status, thresholds.pit.pit_relief_shared_limit, exemption_used]),
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
    "_warnings": [sprintf("ULGA DLA MŁODYCH (do 26 lat) — %s. Limit: %.0f PLN rocznie. Obejmuje: przychody z umowy o pracę, zlecenia, praktyk. NIE obejmuje: działalności gospodarczej! JDG = brak ulgi dla młodych z DG.", [status_detail, thresholds.pit.pit_relief_shared_limit])]
} {
    input.jdg_entrepreneur.age_at_year_start <= 26
    input.jdg_entrepreneur.tax_year_as_int >= 2020  # Ulga od 1 sierpnia 2019, w pełni od 2020
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 0)
    exemption_used := min([annual_income, thresholds.pit.pit_relief_shared_limit])
    exemption_remaining := max([0, thresholds.pit.pit_relief_shared_limit - annual_income])
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
    "pit_exemption_limit_pln": thresholds.pit.pit_relief_shared_limit,
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
    status_detail = sprintf("Limit %.0f PLN/rok, pozostało %d lat", [thresholds.pit.pit_relief_shared_limit, years_remaining]) { is_eligible }
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
    "pit_exemption_limit_pln": thresholds.pit.pit_relief_shared_limit,
    "pit_exemption_children_count": children_count,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Ulga dla rodzin 4+: %s — %d dzieci. Limit %.0f PLN na rodzica.", [status, children_count, thresholds.pit.pit_relief_shared_limit]),
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT",
    "_warnings": [sprintf("ULGA DLA RODZIN 4+ — %s. (1) Limit 85 528 PLN rocznie OSOBNO na każdego rodzica, (2) Dotyczy przychodów z pracy, zleceń ORAZ DG (nawet na ryczałcie!), (3) Dzieci do 18 lat (lub do 25 lat jeśli się uczą), (4) NIE łączy się z ulgą dla młodych!", [status_detail])]
} {
    children_count := object.get(input.jdg_entrepreneur, "children_count", 0)
    children_count >= 4
    is_eligible := true
    status = "PRZYSŁUGUJE" { is_eligible == true }
    status_detail = sprintf("%d dzieci — zwolnienie %.0f PLN/rok na rodzica", [children_count, thresholds.pit.pit_relief_shared_limit])
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
    "pit_exemption_limit_pln": thresholds.pit.pit_relief_shared_limit,
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
# ║  E140-E149: ALIMENTY (Art. 21 ust. 1 pkt 127 PIT)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E140: alimony_child_exemption — Alimenty na dziecko zwolnione z PIT ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.alimony_child_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 140,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "ALIMONY_CHILD",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": amount,
    "pit_exemption_limit_pln": 700, "pit_exemption_limit_note": "miesięcznie na dziecko",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": alimony_rt,
    "_routing_reason": alimony_rs,
    "_legal_basis": "Art. 21 ust. 1 pkt 127 lit. a PIT",
    "_warnings": [sprintf("ALIMENTY NA DZIECKO — %s. %.2f PLN. Do 700 PLN/mies na dziecko = ZWOLNIONE z PIT. Nadwyżka ponad 700 PLN = opodatkowana skalą. Alimenty zasądzone przez sąd lub ugodę — NIE dobrowolne!", [alimony_status, amount])]
} {
    input.invoice.income_type == "ALIMONY"
    recipient_type := object.get(input.invoice, "alimony_recipient", "CHILD")
    recipient_type == "CHILD"
    amount := object.get(input.invoice, "amount_net", 0)
    is_court_ordered := object.get(input.invoice, "is_court_ordered", false)
    exempt_limit := 700
    is_exempt := amount <= exempt_limit and is_court_ordered
    alimony_status = "ZWOLNIONE (do 700 PLN/mies)" { is_exempt }
    alimony_status = sprintf("CZĘŚCIOWO OPODATKOWANE — nadwyżka %.2f PLN ponad 700 PLN", [amount - 700]) { amount > 700; is_court_ordered }
    alimony_status = "OPODATKOWANE — alimenty dobrowolne (bez wyroku sądu/ugody)" { not is_court_ordered }
    alimony_rt = "TRIAGE_QUEUE" { not is_exempt }
    alimony_rt = "" { is_exempt }
    alimony_rs = sprintf("Alimenty %.2f PLN — nadwyżka ponad 700 PLN", [amount - 700]) { amount > 700 }
    alimony_rs = "Alimenty dobrowolne — opodatkowane!" { not is_court_ordered }
    alimony_rs = "" { is_exempt }
}

# ── E141: alimony_spouse_exemption — Alimenty na byłego małżonka ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.alimony_spouse_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 141,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "ALIMONY_SPOUSE",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": amount,
    "pit_exemption_limit_pln": 700, "pit_exemption_limit_note": "miesięcznie na byłego małżonka",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 127 lit. b PIT",
    "_warnings": [sprintf("ALIMENTY NA BYŁEGO MAŁŻONKA — %s. %.2f PLN. Do 700 PLN/mies dla byłego małżonka = ZWOLNIONE. UWAGA: alimenty na inne osoby (rodzice, rodzeństwo) = NIE są zwolnione!", [sp_status, amount])]
} {
    input.invoice.income_type == "ALIMONY"
    recipient_type := object.get(input.invoice, "alimony_recipient", "CHILD")
    recipient_type == "SPOUSE"
    amount := object.get(input.invoice, "amount_net", 0)
    is_court_ordered := object.get(input.invoice, "is_court_ordered", false)
    is_exempt := amount <= 700 and is_court_ordered
    sp_status = "ZWOLNIONE (do 700 PLN/mies)" { is_exempt }
    sp_status = "OPODATKOWANE" { not is_exempt }
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
    not object.get(input.invoice, "is_workplace_accident", false)
    not object.get(input.invoice, "is_insurance_payout", false)
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

# ── E202: severance_pay_exemption — Odprawy zwolnione z PIT ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.severance_pay_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "SEVERANCE_PAY",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": severance_amount,
    "pit_exemption_limit_pln": severance_limit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Odprawa: %s — %.2f PLN", [sev_status, severance_amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 3 PIT",
    "_warnings": [sprintf("ODPRAWA — %s. %.2f PLN. Limity: (1) Odprawa z tytułu zwolnień grupowych — zwolniona do wysokości 15-krotności min. wynagrodzenia, (2) Odprawa emerytalna/rentowa — zwolniona do 3-krotności min. wynagrodzenia, (3) Odprawa z Kodeksu Pracy (1-3 miesięczne) — zwolniona. Nadwyżka = opodatkowana!", [sev_status, severance_amount])]
} {
    input.invoice.income_type == "SEVERANCE_PAY"
    severance_amount := object.get(input.invoice, "amount_net", 0)
    severance_type := object.get(input.invoice, "severance_type", "COLLECTIVE")
    severance_limit = 15 * 4800 { severance_type == "COLLECTIVE" }
    severance_limit = 3 * 4800 { severance_type == "RETIREMENT" }
    severance_limit = 3 * 4800 { severance_type == "LABOR_CODE" }
    severance_limit = 0 { true }
    is_exempt := severance_amount <= severance_limit and severance_limit > 0
    sev_status = "ZWOLNIONE" { is_exempt }
    sev_status = sprintf("CZĘŚCIOWO OPODATKOWANE — nadwyżka %.2f PLN", [severance_amount - severance_limit]) { not is_exempt; severance_limit > 0 }
    sev_status = "OPODATKOWANE" { severance_limit <= 0 }
}

# ── E203: workplace_accident_compensation — Odszkodowanie za wypadek przy pracy ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.workplace_accident",
    "package": "jdg.pit.art21_exemptions", "priority": 203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "ACCIDENT_COMPENSATION",
    "pit_exemption_applies": true,
    "pit_exemption_amount_pln": accident_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "Odszkodowanie powypadkowe — ZWOLNIONE z PIT",
    "_legal_basis": "Art. 21 ust. 1 pkt 3c PIT",
    "_warnings": [sprintf("ODSZKODOWANIE POWYPADKOWE — ZWOLNIONE z PIT. %.2f PLN. Odszkodowania z tytułu wypadku przy pracy i chorób zawodowych są CAŁKOWICIE zwolnione z PIT bez limitu kwotowego!", [accident_amount])]
} {
    input.invoice.income_type == "COMPENSATION"
    object.get(input.invoice, "is_workplace_accident", false) == true
    accident_amount := object.get(input.invoice, "amount_net", 0)
}

# ── E204: insurance_compensation_exemption — Odszkodowania ubezpieczeniowe ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.insurance_compensation",
    "package": "jdg.pit.art21_exemptions", "priority": 204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "INSURANCE_PAYOUT",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": ins_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Odszkodowanie ubezpieczeniowe: %s — %.2f PLN", [ins_status, ins_amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 4 PIT",
    "_warnings": [sprintf("ODSZKODOWANIE UBEZPIECZENIOWE — %s. %.2f PLN. (1) Odszkodowania z OC/AC komunikacyjnego = ZWOLNIONE (do wartości szkody), (2) Odszkodowania z ubezpieczenia na życie = ZWOLNIONE, (3) Odszkodowania z polisy inwestycyjnej = OPODATKOWANE (traktowane jak zyski kapitałowe).", [ins_status, ins_amount])]
} {
    input.invoice.income_type == "COMPENSATION"
    object.get(input.invoice, "is_insurance_payout", false) == true
    ins_amount := object.get(input.invoice, "amount_net", 0)
    is_investment_policy := object.get(input.invoice, "is_investment_policy", false)
    is_exempt := not is_investment_policy
    ins_status = "ZWOLNIONE (OC/AC/życie)" { is_exempt }
    ins_status = "OPODATKOWANE — polisa inwestycyjna = zysk kapitałowy 19%" { not is_exempt }
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
    not object.get(input.invoice, "is_doctoral", false)
    not object.get(input.invoice, "is_eu_funded", false)
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

# ── E211: doctoral_scholarship — Stypendium doktoranckie ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.doctoral_scholarship",
    "package": "jdg.pit.art21_exemptions", "priority": 211,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "DOCTORAL_SCHOLARSHIP",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_limit_pln": doc_limit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Stypendium doktoranckie: %s — %.2f PLN", [doc_status, amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 39, 40a PIT",
    "_warnings": [sprintf("STYPENDIUM DOKTORANCKIE — %s. %.2f PLN/mies. (1) Stypendium doktoranckie do 3 roku — zwolnione do limitu określonego w ustawie (ok. 5000 PLN/mies w 2026), (2) Stypendium w Szkole Doktorskiej — zwolnione w całości, (3) Nadwyżka ponad limit = opodatkowana.", [doc_status, amount])]
} {
    input.invoice.income_type == "SCHOLARSHIP"
    object.get(input.invoice, "is_doctoral", false) == true
    amount := object.get(input.invoice, "amount_net", 0)
    is_school := object.get(input.invoice, "is_doctoral_school", false)
    doc_limit = 999999999 { is_school }  # bez limitu
    doc_limit = 5000 { not is_school }
    is_exempt := amount <= doc_limit
    doc_status = "ZWOLNIONE" { is_exempt }
    doc_status = sprintf("CZĘŚCIOWO OPODATKOWANE — nadwyżka %.2f PLN ponad limit", [amount - doc_limit]) { not is_exempt }
}

# ── E212: training_internship_grant — Stypendium szkoleniowe/stażowe ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.training_grant",
    "package": "jdg.pit.art21_exemptions", "priority": 212,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "TRAINING_GRANT",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": training_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Stypendium stażowe/szkoleniowe: %s", [train_status]),
    "_legal_basis": "Art. 21 ust. 1 pkt 39, 40b PIT",
    "_warnings": [sprintf("STYPENDIUM STAŻOWE/SZKOLENIOWE — %s. %.2f PLN. (1) Stypendia z Funduszu Pracy — zwolnione, (2) Stypendia stażowe z PUP — zwolnione, (3) Stypendia z UE (EFS) — zwolnione, (4) Prywatne stypendia fundowane przez JDG dla pracowników = KUP dla JDG.", [train_status, training_amount])]
} {
    input.invoice.income_type in {"TRAINING_GRANT", "INTERNSHIP_STIPEND"}
    training_amount := object.get(input.invoice, "amount_net", 0)
    is_eu_funded := object.get(input.invoice, "is_eu_funded", false)
    is_pup := object.get(input.invoice, "is_labor_office_grant", false)
    is_exempt := is_eu_funded or is_pup
    train_status = "ZWOLNIONE (UE/PUP)" { is_exempt }
    train_status = "OPODATKOWANE — źródło prywatne" { not is_exempt }
}

# ── E213: eu_project_grant — Dotacje z funduszy UE ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.eu_grant_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 213,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_exemption_type": "EU_GRANT",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": grant_amount,
    "pit_exemption_source": grant_source,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": grant_rt,
    "_routing_reason": sprintf("Dotacja UE: %s — %.2f PLN", [grant_status, grant_amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 46, 47c, 129 PIT",
    "_warnings": [sprintf("DOTACJA ZE ŚRODKÓW UE — %s. %.2f PLN z %s. UWAGA dla JDG: (1) Dotacje UE na rozpoczęcie DG = ZWOLNIONE z PIT, (2) Dotacje na środki trwałe = zwolnione do wysokości amortyzacji, (3) Dotacje do wynagrodzeń = ZWOLNIONE. Dotacje UE NIE podlegają VAT (art. 29a VAT).", [grant_status, grant_amount, grant_source])]
} {
    input.invoice.income_type == "GRANT"
    object.get(input.invoice, "is_eu_funded", false) == true
    grant_amount := object.get(input.invoice, "amount_net", 0)
    grant_source := object.get(input.invoice, "grant_source", "EU")
    is_startup_grant := object.get(input.invoice, "is_startup_grant", false)
    is_asset_grant := object.get(input.invoice, "is_asset_grant", false)
    is_exempt := is_startup_grant or not is_asset_grant
    grant_status = "ZWOLNIONE" { is_exempt }
    grant_status = "ZWOLNIONE DO WYSOKOŚCI AMORTYZACJI" { is_asset_grant; not is_startup_grant }
    grant_rt = "TRIAGE_QUEUE" { is_asset_grant }
    grant_rt = "" { not is_asset_grant }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E220-E229: SPRZEDAŻ NIERUCHOMOŚCI (Art. 21 ust. 1 pkt 131 PIT)         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E220: real_estate_sale_5year_exemption — Sprzedaż nieruchomości po 5 latach ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.real_estate_5year_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 220,
    "pit_exemption_type": "REAL_ESTATE_5YEAR",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": sale_profit,
    "pit_exemption_ownership_years": ownership_years,
    "_routing": re_rt,
    "_routing_reason": sprintf("Sprzedaż nieruchomości: %s — %.0f lat własności", [re_status, ownership_years]),
    "_legal_basis": "Art. 21 ust. 1 pkt 131 PIT; Art. 10 ust. 1 pkt 8 PIT",
    "_warnings": [sprintf("SPRZEDAŻ NIERUCHOMOŚCI — %s. Zysk: %.2f PLN. Okres własności: %.0f lat. KLUCZOWE: (1) Sprzedaż PO 5 latach od końca roku nabycia = CAŁKOWICIE ZWOLNIONE z PIT!, (2) Sprzedaż PRZED 5 laty = 19%% PIT od zysku (pomniejszonego o koszty nabycia+remontu), (3) Liczy się DATA NABYCIA (akt notarialny), NIE data zasiedlenia. Dla JDG: nieruchomość w ŚT = inny reżim.", [re_status, sale_profit, ownership_years])]
} {
    input.invoice.income_type == "REAL_ESTATE_SALE"
    not object.get(input.invoice, "is_inherited", false)
    not object.get(input.invoice, "declares_housing_relief", false)
    sale_price := object.get(input.invoice, "sale_price", 0)
    purchase_price := object.get(input.invoice, "purchase_price", 0)
    renovation_cost := object.get(input.invoice, "renovation_cost", 0)
    acquisition_year := object.get(input.invoice, "acquisition_year", 2020)
    current_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
    is_jdg_asset := object.get(input.invoice, "is_jdg_fixed_asset", false)
    ownership_years := current_year - acquisition_year - 1
    sale_profit := max([0, sale_price - purchase_price - renovation_cost])
    is_exempt := ownership_years >= 5 and not is_jdg_asset
    re_status = "ZWOLNIONE — minęło 5 lat od nabycia" { is_exempt }
    re_status = sprintf("OPODATKOWANE 19%% — tylko %.0f lat (potrzeba 5)", [ownership_years]) { ownership_years < 5; not is_jdg_asset }
    re_status = "OPODATKOWANE — nieruchomość w ewidencji ŚT JDG" { is_jdg_asset }
    re_rt = "BLOCK_AND_ALERT" { not is_exempt }
    re_rt = "" { is_exempt }
}

# ── E221: real_estate_inheritance_timing — Dziedziczenie nieruchomości — bieg 5 lat ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.real_estate_inheritance",
    "package": "jdg.pit.art21_exemptions", "priority": 221,
    "pit_exemption_type": "REAL_ESTATE_INHERITANCE",
    "pit_exemption_applies": is_exempt,
    "_routing": "",
    "_routing_reason": sprintf("Dziedziczenie: %s — bieg 5 lat od nabycia przez spadkodawcę", [inh_status]),
    "_legal_basis": "Art. 10 ust. 5 PIT; Art. 21 ust. 1 pkt 131 PIT",
    "_warnings": [sprintf("DZIEDZICZENIE NIERUCHOMOŚCI — %s. Zysk: %.2f PLN. ZASADA: (1) 5-letni termin biegnie od daty nabycia przez SPADKODAWCĘ (nie od daty dziedziczenia!), (2) Jeśli spadkodawca miał >5 lat = sprzedaż ZWOLNIONA od razu, (3) Samo nabycie w drodze spadku = ZWOLNIONE z podatku od spadków (zgłoś SD-Z2 do US w ciągu 6 mies.!).", [inh_status, sale_profit])]
} {
    input.invoice.income_type == "REAL_ESTATE_SALE"
    object.get(input.invoice, "is_inherited", false) == true
    testator_acquisition_year := object.get(input.invoice, "testator_acquisition_year", 2010)
    current_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
    ownership_years := current_year - testator_acquisition_year - 1
    sale_profit := object.get(input.invoice, "sale_profit", 0)
    is_exempt := ownership_years >= 5
    inh_status = "ZWOLNIONE — spadkodawca miał >5 lat" { is_exempt }
    inh_status = sprintf("OPODATKOWANE 19%% — spadkodawca miał tylko %.0f lat", [ownership_years]) { not is_exempt }
}

# ── E222: housing_relief_own_purpose — Ulga mieszkaniowa (własne cele mieszkaniowe) ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.housing_relief",
    "package": "jdg.pit.art21_exemptions", "priority": 222,
    "pit_exemption_type": "HOUSING_RELIEF",
    "pit_exemption_applies": is_eligible,
    "pit_exemption_amount_pln": relief_amount,
    "pit_exemption_deadline_years": 3,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Ulga mieszkaniowa: %s — %.2f PLN do wydania w ciągu 3 lat", [housing_status, relief_amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 131 PIT (ulga mieszkaniowa)",
    "_warnings": [sprintf("ULGA MIESZKANIOWA — %s. Zysk ze sprzedaży: %.2f PLN. Wydaj na WŁASNE CELE MIESZKANIOWE w ciągu 3 LAT od końca roku sprzedaży: (1) Zakup domu/mieszkania w PL/UE/EOG, (2) Budowa/remont własnego lokalu, (3) Spłata kredytu hipotecznego, (4) Nabycie prawa własności/wieczystego użytkowania. NIE: zakup działki budowlanej bez budowy!", [housing_status, relief_amount])]
} {
    input.invoice.income_type == "REAL_ESTATE_SALE"
    sale_profit := object.get(input.invoice, "sale_profit", 0)
    ownership_years := object.get(input.invoice, "ownership_years", 0)
    ownership_years < 5
    wants_relief := object.get(input.invoice, "declares_housing_relief", false)
    is_eligible := wants_relief
    relief_amount = sale_profit { is_eligible }
    relief_amount = 0 { not is_eligible }
    housing_status = "PRZYSŁUGUJE — zadeklaruj wydatki mieszkaniowe" { is_eligible }
    housing_status = "Możesz skorzystać — złóż oświadczenie o uldze mieszkaniowej" { not is_eligible }
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
# ║  E310-E319: RYCZAŁTY SAMOCHODOWE (Art. 21 ust. 1 pkt 23b PIT)           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E310: car_mileage_allowance_employee — Ryczałt samochodowy dla pracownika ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.car_mileage_employee",
    "package": "jdg.pit.art21_exemptions", "priority": 310,
    "pit_exemption_type": "CAR_MILEAGE_EMPLOYEE",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_per_km_pln": mileage_rate,
    "pit_exemption_monthly_km_limit": km_limit,
    "_routing": "",
    "_routing_reason": sprintf("Kilometrówka pracownicza: %d km × %.2f PLN/km = %.2f PLN zwolnione", [km_used, mileage_rate, exempt_total]),
    "_legal_basis": "Art. 21 ust. 1 pkt 23b PIT; Rozp. MPiPS w/s należności za podróże służbowe",
    "_warnings": [sprintf("RYCZAŁT SAMOCHODOWY (PRACOWNIK) — %.0f km × %.2f PLN/km = %.2f PLN ZWOLNIONE. Limity 2026: (1) Samochód do 900 cm³ = 0.89 PLN/km, (2) Powyżej 900 cm³ = 1.15 PLN/km, (3) Miesięczny limit km = 300 km dla dojazdów, 500 km dla jazd lokalnych. Nadwyżka = opodatkowana!", [km_used, mileage_rate, exempt_total])]
} {
    input.employment.has_employees == true
    input.invoice.income_type == "CAR_MILEAGE_ALLOWANCE"
    km_used := object.get(input.invoice, "mileage_km", 0)
    engine_cc := object.get(input.invoice, "vehicle_engine_cc", 2000)
    mileage_rate = 0.89 { engine_cc <= 900 }
    mileage_rate = 1.15 { engine_cc > 900 }
    km_limit = 300 { object.get(input.invoice, "is_commute", false) }
    km_limit = 500 { not object.get(input.invoice, "is_commute", false) }
    exempt_km := min([km_used, km_limit])
    exempt_total := floor(exempt_km * mileage_rate * 100) / 100
    is_exempt := exempt_total > 0
}

# ── E311: jdg_car_mileage_kup — JDG rozlicza auto przez kilometrówkę/KUP ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.jdg_car_mileage_kup",
    "package": "jdg.pit.art21_exemptions", "priority": 311,
    "pit_exemption_type": "CAR_MILEAGE_JDG",
    "pit_exemption_applies": false,
    "pit_exemption_note": "JDG — rozliczaj FAKTYCZNE koszty lub kilometrówkę w PKPiR (KUP), nie diety",
    "_routing": "",
    "_routing_reason": "JDG — auto w KUP, nie w dietach",
    "_legal_basis": "Art. 23 ust. 1 pkt 36 PIT; Art. 22 PIT",
    "_warnings": [sprintf("AUTO W JDG — NIE ma diet/ryczałtu samochodowego zwolnionego z PIT! Zamiast tego: (1) Ewidencja przebiegu pojazdu (kilometrówka) × %.2f PLN/km = KUP, (2) FAKTYCZNE koszty (paliwo, serwis, ubezpieczenie) w 75%% (bez ewidencji) lub 100%% (z ewidencją), (3) Leasing operacyjny — rata w KUP.", [1.15])]
} {
    input.invoice.income_type == "CAR_MILEAGE_ALLOWANCE"
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

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  E410-E419: INNE ZWOLNIENIA DLA JDG (rolne, spadki, loterie, darowizny) ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── E410: agricultural_income_exemption — Dochody z działalności rolniczej ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.agricultural_exemption",
    "package": "jdg.pit.art21_exemptions", "priority": 410,
    "pit_exemption_type": "AGRICULTURAL_INCOME",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_note": agri_note,
    "_routing": agri_rt,
    "_routing_reason": sprintf("Dochód rolny: %s", [agri_status]),
    "_legal_basis": "Art. 2 ust. 1 pkt 1 PIT; Art. 21 ust. 1 pkt 49-50 PIT",
    "_warnings": [sprintf("DZIAŁALNOŚĆ ROLNICZA — %s. %.2f PLN. (1) Działy specjalne produkcji rolnej = opodatkowane PIT (normy szacunkowe), (2) Zwykła działalność rolnicza = NIE podlega PIT (tylko podatek rolny!), (3) Przetwórstwo produktów rolnych = JDG/PIT, (4) Agroturystyka do 5 pokoi = zwolniona z PIT.", [agri_status, agri_amount])]
} {
    input.invoice.income_type == "AGRICULTURAL"
    agri_amount := object.get(input.invoice, "amount_net", 0)
    is_special_sector := object.get(input.invoice, "is_special_agricultural_sector", false)
    is_processing := object.get(input.invoice, "is_agricultural_processing", false)
    is_agrotourism := object.get(input.invoice, "is_agrotourism", false)
    rooms := object.get(input.invoice, "agrotourism_rooms", 0)
    is_exempt := (not is_special_sector and not is_processing) or (is_agrotourism and rooms <= 5)
    agri_status = "ZWOLNIONE z PIT — podatek rolny" { is_exempt; not is_agrotourism }
    agri_status = "ZWOLNIONE — agroturystyka ≤5 pokoi" { is_agrotourism; rooms <= 5 }
    agri_status = "OPODATKOWANE PIT — działy specjalne" { is_special_sector }
    agri_status = "OPODATKOWANE PIT — przetwórstwo" { is_processing }
    agri_note = "Dochód rolny — odrębny reżim" { is_exempt }
    agri_note = "Wchodzi do JDG — opodatkowane PIT" { not is_exempt }
    agri_rt = "BLOCK_AND_ALERT" { not is_exempt }
    agri_rt = "" { is_exempt }
}

# ── E411: inheritance_donation_exemption — Spadki i darowizny zwolnione ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.inheritance_donation",
    "package": "jdg.pit.art21_exemptions", "priority": 411,
    "pit_exemption_type": "INHERITANCE_DONATION",
    "pit_exemption_applies": is_exempt,
    "_routing": "",
    "_routing_reason": sprintf("Spadek/darowizna: %s", [inh_status]),
    "_legal_basis": "Art. 21 ust. 1 pkt 49 PIT; Ustawa o podatku od spadków i darowizn",
    "_warnings": [sprintf("SPADEK/DAROWIZNA — %s. %.2f PLN. ZASADY: (1) Nabycie spadku = ZWOLNIONE z PIT (opodatkowane odrębnym podatkiem od spadków), (2) Darowizny od najbliższej rodziny (grupa 0 — małżonek, dzieci, rodzice) = ZWOLNIONE z podatku od spadków (zgłoś SD-Z2 w ciągu 6 mies.!), (3) Darowizny dla JDG od rodziny = przychód JDG (opodatkowany!), chyba że jako darowizna prywatna.", [inh_status, amount])]
} {
    input.invoice.income_type in {"INHERITANCE", "DONATION"}
    amount := object.get(input.invoice, "amount_net", 0)
    is_to_jdg := object.get(input.invoice, "is_to_jdg", false)
    is_close_family := object.get(input.invoice, "is_close_family", false)
    is_exempt := not is_to_jdg
    inh_status = "ZWOLNIONE z PIT — odrębny podatek od spadków" { not is_to_jdg; input.invoice.income_type == "INHERITANCE" }
    inh_status = "ZWOLNIONE — darowizna prywatna od rodziny" { not is_to_jdg; input.invoice.income_type == "DONATION"; is_close_family }
    inh_status = "OPODATKOWANE — darowizna dla JDG = przychód!" { is_to_jdg }
    inh_status = "OPODATKOWANE — darowizna spoza grupy 0" { not is_to_jdg; not is_close_family }
}

# ── E412: lottery_competition_exemption — Wygrane w konkursach i loteriach ──
else := {
    "matched": true, "rule_id": "jdg.pit.art21.lottery_winnings",
    "package": "jdg.pit.art21_exemptions", "priority": 412,
    "pit_exemption_type": "LOTTERY_WINNINGS",
    "pit_exemption_applies": is_exempt,
    "pit_exemption_amount_pln": win_amount,
    "pit_exemption_limit_pln": 2280,
    "_routing": "",
    "_routing_reason": sprintf("Wygrana: %s — %.2f PLN", [win_status, win_amount]),
    "_legal_basis": "Art. 21 ust. 1 pkt 6a, 68 PIT",
    "_warnings": [sprintf("WYGRANA — %s. %.2f PLN. Limity: (1) Konkursy z dziedziny nauki/kultury/sportu = ZWOLNIONE do 2 280 PLN, (2) Gry liczbowe/loterie Totalizatora Sportowego — opodatkowane 10%% ryczałtem (pobiera organizator), (3) Wygrane w konkursach branżowych dla JDG = PRZYCHÓD JDG (opodatkowane!)\n", [win_status, win_amount])]
} {
    input.invoice.income_type in {"LOTTERY_WIN", "COMPETITION_PRIZE"}
    win_amount := object.get(input.invoice, "amount_net", 0)
    is_scientific := object.get(input.invoice, "is_scientific_competition", false)
    is_lottery := object.get(input.invoice, "is_state_lottery", false)
    is_for_jdg := object.get(input.invoice, "is_for_jdg", false)
    is_exempt := is_scientific and win_amount <= 2280 and not is_for_jdg
    win_status = "ZWOLNIONE do 2 280 PLN" { is_exempt }
    win_status = "OPODATKOWANE 10%% ryczałt (pobiera płatnik)" { is_lottery; not is_for_jdg }
    win_status = "PRZYCHÓD JDG — opodatkowane wg formy JDG" { is_for_jdg }
    win_status = sprintf("OPODATKOWANE — nadwyżka %.2f PLN ponad 2 280 PLN", [win_amount - 2280]) { not is_exempt; not is_lottery; not is_for_jdg; win_amount > 2280 }
    win_status = "ZWOLNIONE" { not is_exempt; not is_lottery; not is_for_jdg; win_amount <= 2280 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NO-MATCH (R04 P1: stub { true } usunięty — nie generuje fałszywego matched:true)
# ═══════════════════════════════════════════════════════════════════════════════
