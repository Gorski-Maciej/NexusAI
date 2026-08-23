# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22c Wyłączenia z amortyzacji
# — RAPORT_GLM52_P06 (uzupełnienie mapy art. 22a-22o)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.amort_a22c
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22c

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22c.no_match",
    "package": "jdg.micro.amort_a22c",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22c — Art. 22c Wyłączenia z amortyzacji (grunty, budynki mieszkalne, ║
# ║  dzieła sztuki, eksponaty, nieoddane do używania)                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22c.r1: blocked_land — grunty NIE amortyzowane (art. 22c pkt 1)
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22c.r1",
    "package": "jdg.micro.amort_a22c", "priority": 81501,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "amortization_excluded": true,
    "exclusion_reason": "Grunty i prawa wieczystego użytkowania gruntów nie podlegają amortyzacji",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Grunty NIE podlegają amortyzacji — wartość gruntu wyłącz z wartości początkowej budynku",
    "_legal_basis": "Art. 22c pkt 1 PIT",
    "_warnings": ["[MICRO] Art.22c PIT: BLOCK — grunty NIE są amortyzowane. Przy zakupie nieruchomości wyodrębnij wartość gruntu (art. 22g ust. 2 PIT)."]
} {
    input.invoice.category_code in {"LAND", "REAL_ESTATE"}
    object.get(input.invoice, "is_land", false) == true
}

# jdg.micro.amort_a22c.r2: blocked_residential_building — budynki mieszkalne z lokalami (art. 22c pkt 2)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22c.r2",
    "package": "jdg.micro.amort_a22c", "priority": 81502,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "amortization_excluded": true,
    "exclusion_reason": "Budynki mieszkalne wraz ze związanymi z nimi urządzeniami (wyjątek: działalność gospodarcza)",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Budynek mieszkalny NIE podlega amortyzacji (poza wynajmem w działalności gospodarczej)",
    "_legal_basis": "Art. 22c pkt 2 PIT",
    "_warnings": ["[MICRO] Art.22c PIT: BLOCK — budynki mieszkalne nie są amortyzowane, chyba że służą działalności gospodarczej (wynajem) — wtedy stawka 1,5%/rok (grupa 1 KŚT)."]
} {
    input.invoice.category_code == "REAL_ESTATE"
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "used_in_business", false) == false
}

# jdg.micro.amort_a22c.r3: blocked_art_works — dzieła sztuki i eksponaty muzealne (art. 22c pkt 3)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22c.r3",
    "package": "jdg.micro.amort_a22c", "priority": 81503,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "amortization_excluded": true,
    "exclusion_reason": "Dzieła sztuki i eksponaty muzealne nie podlegają amortyzacji",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Dzieła sztuki / eksponaty muzealne NIE podlegają amortyzacji",
    "_legal_basis": "Art. 22c pkt 3 PIT",
    "_warnings": ["[MICRO] Art.22c PIT: BLOCK — dzieła sztuki, eksponaty muzealne i kolekcje nie są amortyzowane."]
} {
    input.invoice.category_code in {"ART_WORK", "MUSEUM_EXHIBIT", "COLLECTION"}
}

# jdg.micro.amort_a22c.r4: blocked_not_put_to_use — ŚT nieoddany do używania (art. 22c pkt 4)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22c.r4",
    "package": "jdg.micro.amort_a22c", "priority": 81504,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "amortization_excluded": true,
    "exclusion_reason": "ŚT nieoddany do używania (w budowie / montaż) — amortyzacja od następnego miesiąca po przyjęciu",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ŚT nieoddany do używania — amortyzacja NIEDOZWOLONA przed przyjęciem",
    "_legal_basis": "Art. 22c pkt 4 PIT, Art. 22h ust. 1 pkt 1 PIT",
    "_warnings": ["[MICRO] Art.22c PIT: BLOCK — nie amortyzuje się środków trwałych przed oddaniem do używania (ŚT w budowie / montażu). Odpisy od następnego miesiąca po przyjęciu."]
} {
    object.get(input.invoice, "asset_ready_for_use", false) == false
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "REAL_ESTATE", "CONSTRUCTION_IN_PROGRESS"}
}

# jdg.micro.amort_a22c.r5: blocked_wnip_not_in_business — WNiP nieużywana w działalności
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22c.r5",
    "package": "jdg.micro.amort_a22c", "priority": 81505,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "amortization_excluded": true,
    "exclusion_reason": "WNiP nieużywana w działalności gospodarczej",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WNiP musi być wykorzystywana w działalności, aby podlegać amortyzacji",
    "_legal_basis": "Art. 22c pkt 4 PIT",
    "_warnings": ["[MICRO] Art.22c PIT: BLOCK — WNiP nieużywana w działalności gospodarczej nie podlega amortyzacji."]
} {
    object.get(input.invoice, "is_wnip", false) == true
    object.get(input.invoice, "wnip_used_in_business", false) == false
}

# jdg.micro.amort_a22c.r6: land_value_split — wyodrębnienie wartości gruntu (art. 22g ust. 2)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22c.r6",
    "package": "jdg.micro.amort_a22c", "priority": 81506,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "land_value": land_value,
    "building_depreciable_value": building_value,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 2 PIT (wyodrębnienie wartości gruntu)",
    "_warnings": [sprintf("[MICRO] Art.22g PIT: Wartość nieruchomości %.2f PLN = grunt %.2f PLN (NIE amortyzowany) + budynek %.2f PLN (amortyzowany).", [total, land_value, building_value])]
} {
    input.invoice.category_code == "REAL_ESTATE"
    total := object.get(input.invoice, "amount_net", 0)
    land_value := object.get(input.invoice, "land_value", 0)
    building_value := total - land_value
    land_value > 0
    building_value > 0
}

# ── Bez fallbacka catch-all (konwencja micro warstwy: brak dopasowania → default no_match).
