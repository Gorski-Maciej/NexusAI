# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22i Metody amortyzacji (12 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.amort_a22i
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22i

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22i.no_match",
    "package": "jdg.micro.amort_a22i",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22i — Art. 22i Metody amortyzacji (12 reguł)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22i.r1: linear_default — metoda liniowa = domyślna
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r1",
    "package": "jdg.micro.amort_a22i", "priority": 81101,
    "valid_from": "2025-01-01", "valid_to": null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22i PIT: Amortyzacja LINIOWA — stawka %.0f%% rocznie = %.2f PLN/rok (%d rat)", [rate, annual, months])]
} {
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "VEHICLE", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT"}
    initial_value := object.get(input.invoice, "asset_initial_value", 0)
    initial_value >= 10000
    rate := object.get(input.invoice, "depreciation_rate_pct", 20)
    annual := floor(initial_value * rate / 100 * 100) / 100
    months := 12
}

# jdg.micro.amort_a22i.r2: linear_start_next_month — rozpoczęcie od następnego miesiąca
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r2",
    "package": "jdg.micro.amort_a22i", "priority": 81102,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 1 pkt 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22h PIT: Amortyzacja od NASTĘPNEGO miesiąca po przyjęciu. Przyjęto: %s → pierwszy odpis: %s", [acceptance_date, first_depr_date])]
} {
    acceptance_date := object.get(input.invoice, "asset_acceptance_date", "2026-01-01")
    first_depr_date := object.get(input.invoice, "first_depreciation_date", "")
    acceptance_date != ""
}

# jdg.micro.amort_a22i.r3: linear_rates_kst — stawki z KŚT
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r3",
    "package": "jdg.micro.amort_a22i", "priority": 81103,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 1-2 PIT + Załącznik nr 1",
    "_warnings": [sprintf("[MICRO] Art.22i PIT: Stawka KŚT %s: %.0f%% rocznie. Grupa KŚT: %s", [asset_type, rate, kst_group])]
} {
    asset_type := object.get(input.invoice, "kst_asset_type", "Maszyny")
    kst_group := object.get(input.invoice, "kst_group", "4")
    rate := object.get(input.invoice, "depreciation_rate_pct", 20)
}

# jdg.micro.amort_a22i.r4: degressive_conditions — warunki metody degresywnej
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r4",
    "package": "jdg.micro.amort_a22i", "priority": 81104,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 2 PIT",
    "_warnings": [sprintf("[MICRO] Art.22i PIT: Metoda DEGRESYWNA — współczynnik %.1f × stawka %.0f%% = %.0f%% efektywna. Maszyny w grupie 3-6 i 8 KŚT + transport.", [coeff, base_rate, effective_rate])]
} {
    input.invoice.depreciation_method == "DEGRESSIVE"
    base_rate := object.get(input.invoice, "depreciation_base_rate", 20)
    coeff := object.get(input.invoice, "degressive_coefficient", 2.0)
    effective_rate := base_rate * coeff
}

# jdg.micro.amort_a22i.r5: degressive_switch_to_linear — przejście na liniową
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r5",
    "package": "jdg.micro.amort_a22i", "priority": 81105,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 5 PIT",
    "_warnings": [sprintf("[MICRO] Art.22i PIT: Degresywna → LINIOWA gdy roczny odpis ≤ odpis liniowy (%.2f PLN). Wartość netto: %.2f PLN.", [linear_annual, net_value])]
} {
    input.invoice.depreciation_method == "DEGRESSIVE"
    object.get(input.invoice, "switch_to_linear_triggered", false) == true
    net_value := object.get(input.invoice, "asset_net_value", 0)
    linear_annual := object.get(input.invoice, "linear_annual_depreciation", 0)
}

# jdg.micro.amort_a22i.r6: blocked_wrong_coefficient — blokada: zły współczynnik
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r6",
    "package": "jdg.micro.amort_a22i", "priority": 81106,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Niedozwolony współczynnik %.1f dla grupy KŚT %s. Max: 2.0 (maszyny) / 1.4 (inne).", [coeff, kst_group]),
    "_legal_basis": "Art. 22i ust. 2 PIT",
    "_warnings": [sprintf("[MICRO] Art.22i PIT: BLOCK — współczynnik degresywny %.1f > max %.1f dla grupy KŚT %s. Nadwyżka amortyzacji = NKUP!", [coeff, max_coeff, kst_group])]
} {
    coeff := object.get(input.invoice, "degressive_coefficient", 1.0)
    kst_group := object.get(input.invoice, "kst_group", "1")
    max_coeff = 2.0 { kst_group in {"3", "4", "5", "6", "8"} }
    max_coeff = 1.4 { true }
    coeff > max_coeff
}

# jdg.micro.amort_a22i.r7: building_rate — stawki budynków
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r7",
    "package": "jdg.micro.amort_a22i", "priority": 81107,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 1 PIT + Załącznik nr 1 (poz. 1-2)",
    "_warnings": [sprintf("[MICRO] Art.22i PIT: Budynek %s — stawka %.1f%% rocznie (%d lat amortyzacji)", [building_type, rate, years])]
} {
    input.invoice.category_code == "REAL_ESTATE"
    building_type = "mieszkalny" { input.invoice.subtype == "RESIDENTIAL" }
    building_type = "niemieszkalny" { input.invoice.subtype != "RESIDENTIAL" }
    rate = 1.5 { input.invoice.subtype == "RESIDENTIAL" }
    rate = 2.5 { input.invoice.subtype != "RESIDENTIAL" }
    years = 67 { input.invoice.subtype == "RESIDENTIAL" }
    years = 40 { input.invoice.subtype != "RESIDENTIAL" }
}

# jdg.micro.amort_a22i.r8: exception_used_asset — wyjątek: używany ŚT = szybsza
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.r8",
    "package": "jdg.micro.amort_a22i", "priority": 81108,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22j ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22j PIT: WYJĄTEK — używany ŚT, okres amortyzacji skrócony do %d mies. (min. 24 mies. dla maszyn, 36 mies. dla budynków)", [shortened_months])]
} {
    object.get(input.invoice, "is_used_asset", false) == true
    shortened_months := object.get(input.invoice, "shortened_depreciation_months", 60)
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22i.fallback",
    "package": "jdg.micro.amort_a22i", "priority": 81199,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i PIT",
    "_warnings": ["[MICRO] Art.22i PIT — amortyzacja liniowa ze stawką podstawową"]
} { true }
