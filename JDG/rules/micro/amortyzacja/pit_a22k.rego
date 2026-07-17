# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22k Jednorazowa amortyzacja (10 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.amort_a22k
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22k

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22k.no_match",
    "package": "jdg.micro.amort_a22k",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22k — Art. 22k Jednorazowa amortyzacja de minimis (10 reguł)        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22k.r1: one_time_small_taxpayer — mały podatnik
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.r1",
    "package": "jdg.micro.amort_a22k", "priority": 81201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22k ust. 7 PIT",
    "_warnings": [sprintf("[MICRO] Art.22k PIT: Jednorazowa amortyzacja — mały podatnik. Limit 100 000 PLN łącznie w roku. ŚT grupy 3-8 KŚT.", [])]
} {
    object.get(input.jdg_entrepreneur, "is_small_taxpayer", false) == true
    input.invoice.one_time_depreciation == true
}

# jdg.micro.amort_a22k.r2: one_time_first_year — pierwszy rok działalności
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.r2",
    "package": "jdg.micro.amort_a22k", "priority": 81202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22k ust. 11 PIT",
    "_warnings": [sprintf("[MICRO] Art.22k PIT: Jednorazowa amortyzacja — pierwszy rok JDG. Limit 100k PLN. Tylko ŚT z grup 3-8 KŚT.", [])]
} {
    object.get(input.jdg_entrepreneur, "is_first_year", false) == true
    input.invoice.one_time_depreciation == true
}

# jdg.micro.amort_a22k.r3: one_time_100k_limit — limit 100 000 PLN
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.r3",
    "package": "jdg.micro.amort_a22k", "priority": 81203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22k ust. 7-12 PIT",
    "_warnings": [sprintf("[MICRO] Art.22k PIT: Jednorazowo %.2f PLN z limitu %.0f. Wykorzystano łącznie %.2f PLN/%.0f.", [one_time, de_minimis_limit, used_total, de_minimis_limit])]
} {
    de_minimis_limit := object.get(data.thresholds.jdg.depreciation, "one_off_de_minimis_limit", 100000)
    one_time := min([object.get(input.invoice, "amount_net", 0), de_minimis_limit])
    used_total := object.get(input.jdg_entrepreneur, "one_time_depreciation_used_ytd", 0)
    one_time > 0
}

# jdg.micro.amort_a22k.r4: one_time_exclusion_cars — wyłączenie samochodów
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.r4",
    "package": "jdg.micro.amort_a22k", "priority": 81204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Samochód osobowy WYKLUCZONY z jednorazowej amortyzacji! Amortyzuj liniowo.",
    "_legal_basis": "Art. 22k ust. 7 PIT (wyłączenie samochodów osobowych)",
    "_warnings": [sprintf("[MICRO] Art.22k PIT: BLOCK — samochód osobowy NIE podlega jednorazowej amortyzacji de minimis! Limit 150k (225k EV) + amortyzacja liniowa 20%%/rok.", [])]
} {
    input.invoice.category_code in {"VEHICLE", "CAR"}
    input.invoice.one_time_depreciation == true
    object.get(input.invoice, "is_passenger_car", true) == true
}

# jdg.micro.amort_a22k.r5: one_time_low_value_10k — niskocenne do 10k PLN
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.r5",
    "package": "jdg.micro.amort_a22k", "priority": 81205,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22d ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22d PIT: Niskocenny ŚT %.2f PLN < %.0f — jednorazowo w KUP w miesiącu oddania. Nie wpisuj do ewidencji ŚT!", [value, low_value_limit])]
} {
    value := object.get(input.invoice, "amount_net", 0)
    low_value_limit := object.get(data.thresholds.jdg.depreciation, "one_off_low_value_limit", 10000)
    value > 0
    value < low_value_limit
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT"}
}

# jdg.micro.amort_a22k.r6: blocked_exceeded_100k — blokada: przekroczony limit
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.r6",
    "package": "jdg.micro.amort_a22k", "priority": 81206,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Limit %.0f PLN jednorazowej amortyzacji przekroczony! Wykorzystano %.0f PLN.", [de_minimis_limit, used_total]),
    "_legal_basis": "Art. 22k ust. 7 PIT",
    "_warnings": [sprintf("[MICRO] Art.22k PIT: BLOCK — limit %.0f PLN wykorzystany (%.0f PLN). Nadwyżka %.0f PLN — amortyzuj liniowo/degresywnie!", [de_minimis_limit, used_total, excess])]
} {
    de_minimis_limit := object.get(data.thresholds.jdg.depreciation, "one_off_de_minimis_limit", 100000)
    used_total := object.get(input.jdg_entrepreneur, "one_time_depreciation_used_ytd", 0)
    used_total >= de_minimis_limit
    excess := used_total - de_minimis_limit
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22k.fallback",
    "package": "jdg.micro.amort_a22k", "priority": 81299,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22k PIT",
    "_warnings": ["[MICRO] Art.22k PIT — amortyzacja standardowa (liniowa/degresywna)"]
} { true }
