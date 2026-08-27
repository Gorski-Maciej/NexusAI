# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: sus_a19.rego (PROMPT 07 — ZUS MICRO)
# Package: jdg.micro.sus
# Art. 19 SUS — Roczna podstawa wymiaru składek, 30-krotność przeciętnego
# (Dz.U. 2025 poz. 345 ze zm.)
# Zero hardcode: cap_multiplier i avg_wage z data.jdg.thresholds.zus
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.sus

import future.keywords.if
import future.keywords.in
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.sus.a19.no_match",
    "package": "jdg.micro.sus",
    "priority": 999999
}

# ── a19.r1: Roczny limit podstawy — eligibility ───────────────────────────────
# Art. 19 ust. 1 SUS: roczna podstawa wymiaru składek na ubezpieczenia emerytalne
# i rentowe w danym roku kalendarzowym nie może być wyższa od kwoty odpowiadającej
# 30-krotności prognozowanego przeciętnego wynagrodzenia miesięcznego.

decide := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a19.annual_cap_eligibility",
    "package": "jdg.micro.sus",
    "priority": 91901,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "ANNUAL_CAP",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Art. 19 ust. 1 SUS — weryfikacja rocznego limitu 30× przeciętne",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO A19] Roczna podstawa emerytalno-rentowa limitowana do 30× przeciętnego wynagrodzenia"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_annual_cap_check", false) == true
}

# ── a19.r2: Obliczenie limitu rocznego ────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a19.annual_cap_calculation",
    "package": "jdg.micro.sus",
    "priority": 91902,
    "vat_rate": "", "rounding_level": "GROSZE", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "ANNUAL_CAP_CALCULATED",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_annual_base_pln": annual_base,
    "zus_annual_cap_pln": cap,
    "zus_annual_excess_pln": excess,
    "zus_annual_cap_exceeded": true,
    "_routing": "SUGGEST",
    "_routing_reason": "Przekroczono roczny limit 30× — zaprzestań poboru składek emerytalno-rentowych od nadwyżki",
    "_legal_basis": "Art. 19 ust. 1, 3, 5 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": [sprintf("[MICRO A19] Roczna podstawa %.0f PLN > limit %.0f PLN (30× %.0f PLN). Nadwyżka %.0f PLN BEZ składek emerytalno-rentowych.", [annual_base, cap, avg_wage, excess])]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    annual_base := object.get(input.jdg_entrepreneur, "zus_annual_base_pln", 0)
    avg_wage := object.get(object.get(thresholds, "zus", {}), "avg_monthly_wage", 8190.00)
    multiplier := object.get(object.get(thresholds, "zus", {}), "annual_cap_multiplier", 30)
    cap := floor(avg_wage * multiplier)
    annual_base > cap
    excess := annual_base - cap
}

# ── a19.r3: Wielu płatników — obowiązek zawiadomienia ─────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a19.multi_payer_notification",
    "package": "jdg.micro.sus",
    "priority": 91903,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "zus_multi_payer_notification_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wielu płatników — obowiązek zawiadomienia o przekroczeniu limitu (art. 19 ust. 6)",
    "_legal_basis": "Art. 19 ust. 6 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO A19] Masz kilku płatników składek — zawiadom wszystkich o przekroczeniu rocznego limitu podstawy (art. 19 ust. 6 SUS)"]
} {
    object.get(input.jdg_entrepreneur, "zus_multi_payer", false) == true
    object.get(input.jdg_entrepreneur, "zus_annual_cap_exceeded", false) == true
}