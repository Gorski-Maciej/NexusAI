# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22b WNiP (wartości niematerialne
# i prawne) — RAPORT_GLM52_P06 (uzupełnienie mapy art. 22a-22o)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.amort_a22b
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22b

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22b.no_match",
    "package": "jdg.micro.amort_a22b",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22b — Art. 22b WNiP: definicja, okres, rozpoczęcie, limity           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22b.r1: wnip_definition — definicja WNiP (art. 22b ust. 1)
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22b.r1",
    "package": "jdg.micro.amort_a22b", "priority": 81401,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "wnip_qualified": true,
    "wnip_type": wnip_type,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22b ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22b PIT: WNiP = %s — nabyte prawa majątkowe, licencje, autorskie prawa majątkowe, know-how, programy komputerowe. Amortyzacja od NASTĘPNEGO miesiąca po przyjęciu.", [wnip_type])]
} {
    input.invoice.category_code == "INTANGIBLE_ASSET"
    wnip_type = "licencja" { object.get(input.invoice, "wnip_kind", "") == "LICENSE" }
    wnip_type = "autorskie prawa majątkowe" { object.get(input.invoice, "wnip_kind", "") == "COPYRIGHT" }
    wnip_type = "know-how" { object.get(input.invoice, "wnip_kind", "") == "KNOW_HOW" }
    wnip_type = "program komputerowy" { object.get(input.invoice, "wnip_kind", "") == "SOFTWARE" }
    wnip_type = "wartość niematerialna" { true }
    initial_value := object.get(input.invoice, "asset_initial_value", 0)
    initial_value > 0
}

# jdg.micro.amort_a22b.r2: wnip_period_5y — okres używania >1 rok, ≤5 lat (art. 22b ust. 1)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22b.r2",
    "package": "jdg.micro.amort_a22b", "priority": 81402,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "wnip_amortization_years": years,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22b ust. 1 PIT (okres używania 1-5 lat)",
    "_warnings": [sprintf("[MICRO] Art.22b PIT: WNiP amortyzowana przez %d lat (okres używania > 1 rok, nie dłużej niż 5 lat).", [years])]
} {
    object.get(input.invoice, "is_wnip", false) == true
    expected_life := object.get(input.invoice, "expected_useful_life_years", 3)
    expected_life > 1
    years := min([expected_life, 5])
}

# jdg.micro.amort_a22b.r3: wnip_start_next_month — rozpoczęcie od następnego miesiąca
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22b.r3",
    "package": "jdg.micro.amort_a22b", "priority": 81403,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "wnip_first_depreciation_month": first_month,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 1 pkt 1 PIT w zw. z art. 22b PIT",
    "_warnings": [sprintf("[MICRO] Art.22b/22h PIT: WNiP przyjęta %s — pierwszy odpis w %s (następny miesiąc).", [acceptance_date, first_month])]
} {
    object.get(input.invoice, "is_wnip", false) == true
    acceptance_date := object.get(input.invoice, "asset_acceptance_date", "2026-01-01")
    first_month := object.get(input.invoice, "first_depreciation_month", "")
    acceptance_date != ""
}

# jdg.micro.amort_a22b.r4: blocked_wnip_not_in_business — WNiP nieużywana w działalności = NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22b.r4",
    "package": "jdg.micro.amort_a22b", "priority": 81404,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WNiP nie jest wykorzystywana w działalności — amortyzacja NIEDOZWOLONA (NKUP)",
    "_legal_basis": "Art. 22b ust. 1 PIT (warunek: wykorzystanie w działalności)",
    "_warnings": ["[MICRO] Art.22b PIT: BLOCK — WNiP musi być wykorzystywana w działalności gospodarczej. W przeciwnym razie odpisy = NKUP."]
} {
    object.get(input.invoice, "is_wnip", false) == true
    object.get(input.invoice, "wnip_used_in_business", false) == false
}

# jdg.micro.amort_a22b.r5: wnip_low_value_10k — niskocenna WNiP ≤ 10 000 zł (jednorazowo)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22b.r5",
    "package": "jdg.micro.amort_a22b", "priority": 81405,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "wnip_one_time_kup": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22f ust. 3 PIT (niskocenne WNiP — jednorazowo w KUP)",
    "_warnings": [sprintf("[MICRO] Art.22f PIT: Niskocenna WNiP %.2f PLN < %.0f PLN — jednorazowo w KUP w miesiącu oddania do używania.", [value, low_value_limit])]
} {
    object.get(input.invoice, "is_wnip", false) == true
    value := object.get(input.invoice, "asset_initial_value", 0)
    low_value_limit := object.get(data.thresholds.jdg.depreciation, "one_off_low_value_limit", 10000)
    value > 0
    value < low_value_limit
}

# jdg.micro.amort_a22b.r6: wnip_blocked_software_license_rent — licencja w formie opłat = koszt bieżący
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22b.r6",
    "package": "jdg.micro.amort_a22b", "priority": 81406,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "wnip_treatment": "CURRENT_COST",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22b ust. 1 PIT, Art. 23 ust. 1 pkt 44 PIT (opłaty licencyjne = koszt bieżący)",
    "_warnings": ["[MICRO] Art.22b PIT: Licencja rozliczana w formie okresowych opłat = KOSZT BIEŻĄCY (nie amortyzacja). Amortyzacji podlega tylko nabyta WNiP."]
} {
    object.get(input.invoice, "is_wnip", false) == true
    object.get(input.invoice, "wnip_acquired", false) == false
    object.get(input.invoice, "license_fee_periodic", false) == true
}

# ── Bez fallbacka catch-all (konwencja micro warstwy: brak dopasowania → default no_match).
