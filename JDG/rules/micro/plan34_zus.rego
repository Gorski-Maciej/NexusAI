# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: plan34_zus.rego (PROMPT 07 — ZUS MICRO)
# Package: jdg.micro.zus
# Pokrycie: Art. 5, 8, 14, 24, 30 SUS (Dz.U. 2025 poz. 345 ze zm.)
# Zero hardcode: wszystkie wartości przez data.jdg.thresholds.zus
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zus

import future.keywords.if
import future.keywords.in
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zus.plan34.no_match",
    "package": "jdg.micro.zus",
    "priority": 999999
}

_ths := object.get(data.jdg.thresholds, "zus", {})

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sus.a5 — Definicje (art. 5 SUS)                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zus.a5.przedsiebiorca — definicja przedsiębiorcy w rozumieniu SUS
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a5.przedsiebiorca",
    "package": "jdg.micro.zus",
    "priority": 90501,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "ACTIVE", "ceidg_registration_required": true,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Definicja przedsiębiorcy wg art. 5 pkt 21 SUS — JDG to osoba fizyczna prowadząca działalność",
    "_legal_basis": "Art. 5 pkt 21 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P34] Przedsiębiorca w rozumieniu SUS podlega obowiązkowym ubezpieczeniom społecznym"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sus.a8 — Zgłoszenie do ubezpieczeń (art. 8 SUS)                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zus.a8.zgloszenie — obowiązek zgłoszenia ZUS ZUA w ciągu 7 dni
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a8.zgloszenie",
    "package": "jdg.micro.zus",
    "priority": 90801,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": true,
    "micro_rule_active": true,
    "zus_registration_form": "ZUS_ZUA",
    "zus_registration_deadline_days": 7,
    "_routing": "",
    "_routing_reason": "Zgłoszenie do ZUS w ciągu 7 dni od rozpoczęcia działalności",
    "_legal_basis": "Art. 8 ust. 1 w zw. z art. 36 ust. 4 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P34] Zgłoś się do ZUS (formularz ZUS ZUA) w ciągu 7 dni od rozpoczęcia JDG"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_registration_required", false) == true
    days_since := object.get(input.jdg_entrepreneur, "days_since_business_start", 0)
    days_since <= 7
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sus.a14 — Ustanie ubezpieczeń (art. 14 SUS)                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zus.a14.ustanie_obowiazkowe — ustanie obowiązkowych ubezpieczeń
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a14.ustanie_obowiazkowe",
    "package": "jdg.micro.zus",
    "priority": 91401,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "CLOSED",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_insurance_ended": true,
    "zus_closure_form": "ZUS_ZCNA",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Ustanie ubezpieczeń — zamknięcie JDG",
    "_legal_basis": "Art. 14 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P34] Zamknięcie JDG — złóż ZUS ZCNA w ciągu 7 dni od zaprzestania działalności"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"
}

# jdg.micro.zus.a14.ustanie_dobrowolne — ustanie dobrowolnego chorobowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a14.ustanie_dobrowolne",
    "package": "jdg.micro.zus",
    "priority": 91402,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_sickness_ended": true,
    "zus_sickness_grace_days": 30,
    "_routing": "WARNING",
    "_routing_reason": "Dobrowolne chorobowe — brak składki > 30 dni = ustanie",
    "_legal_basis": "Art. 14 ust. 1-2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P34] Dobrowolne ubezpieczenie chorobowe wygasło po 30 dniach bez opłacenia składki"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true
    object.get(input.jdg_entrepreneur, "zus_sickness_unpaid_days", 0) > 30
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sus.a24 — Składki nienależne i odsetki (art. 24 SUS)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zus.a24.nadplata — nadpłata składek — zwrot lub zaliczenie
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a24.nadplata",
    "package": "jdg.micro.zus",
    "priority": 92401,
    "vat_rate": "", "rounding_level": "GROSZE", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_overpayment_pln": overpayment,
    "zus_overpayment_action": "WNIOSEK_O_ZWROT_LUB_ZALICZENIE",
    "_routing": "SUGGEST",
    "_routing_reason": "Nadpłata składek ZUS — złóż wniosek o zwrot lub zaliczenie na przyszłe składki",
    "_legal_basis": "Art. 24 ust. 6a-8 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": [sprintf("[MICRO P34] Nadpłata %.2f PLN — możesz wnioskować o zwrot (5 lat) lub zaliczenie na przyszłe składki", [overpayment])]
} {
    paid := object.get(input.jdg_entrepreneur, "zus_total_paid_pln", 0)
    due := object.get(input.jdg_entrepreneur, "zus_total_due_pln", 0)
    overpayment := paid - due
    overpayment > 0.01
}

# jdg.micro.zus.a24.zaleglosc — zaległość składek — odsetki
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a24.zaleglosc",
    "package": "jdg.micro.zus",
    "priority": 92402,
    "vat_rate": "", "rounding_level": "GROSZE", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_underpayment_pln": underpayment,
    "zus_interest_days": days_late,
    "zus_interest_rate_annual": interest_rate,
    "zus_interest_pln": floor(underpayment * interest_rate * days_late / 36500 * 100) / 100,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zaległość składek ZUS — naliczane odsetki ustawowe",
    "_legal_basis": "Art. 24 ust. 4-5 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": [sprintf("[MICRO P34] ZALEGŁOŚĆ %.2f PLN przez %d dni. Odsetki ≈ %.2f PLN. Ryzyko egzekucji administracyjnej!", [underpayment, days_late, floor(underpayment * interest_rate * days_late / 36500 * 100) / 100])]
} {
    paid := object.get(input.jdg_entrepreneur, "zus_total_paid_pln", 0)
    due := object.get(input.jdg_entrepreneur, "zus_total_due_pln", 0)
    underpayment := due - paid
    underpayment > 0.01
    days_late := object.get(input.jdg_entrepreneur, "zus_days_late", 0)
    interest_rate := object.get(_ths, "zus_interest_rate", 0.145)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sus.a30 — Ograniczenie umorzenia (art. 30 SUS)                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zus.a30.umorzenie_wylaczenie — ograniczenie umorzenia dla
# ubezpieczonych niebędących płatnikami
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a30.umorzenie_wylaczenie",
    "package": "jdg.micro.zus",
    "priority": 93001,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_remission_on_request": false,
    "zus_remission_ex_officio": true,
    "_routing": "SUGGEST",
    "_routing_reason": "Art. 30 SUS — jako płatnik (JDG) nie podlegasz ograniczeniu umorzenia",
    "_legal_basis": "Art. 30 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P34] Jako JDG-płatnik składek własnych możesz ubiegać się o umorzenie na wniosek (art. 28 SUS). Wyjątek art. 28 ust. 3 pkt 4c: umorzenie z urzędu przy całkowitej nieściągalności."]
} {
    object.get(input.jdg_entrepreneur, "zus_remission_eligible", false) == true
}

# jdg.micro.zus.a40.obowiazek_oplacania — obowiązek opłacania składek
# (art. 40 SUS — termin i forma opłacania)
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a40.obowiazek_oplacania",
    "package": "jdg.micro.zus",
    "priority": 94001,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_payment_method": "PRZELEW_LUB_PRZEKAZ_POCZTOWY",
    "zus_payment_account": "NUMER_RACHUNKU_SKLADKOWEGO_ZUS",
    "_routing": "",
    "_routing_reason": "Obowiązek opłacania składek ZUS przelewem na indywidualny NRS",
    "_legal_basis": "Art. 40 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P34] Składki ZUS opłać przelewem na swój indywidualny numer rachunku składkowego (NRS) — sprawdź na PUE ZUS"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_payment_required", false) == true
}