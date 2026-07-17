# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — §27-29 Remanent
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir_remnant
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir_remnant

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir_remnant.no_match",
    "package": "jdg.micro.pkpir_remnant",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.p27 — §27-29 Remanent (spis z natury) — 10 reguł                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir_remnant.p27.r1: remnant_annual_required — obowiązek remanentu
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r1",
    "package": "jdg.micro.pkpir_remnant", "priority": 80501,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§27 Rozp. MF z 15.11.2025 r.",
    "_warnings": [sprintf("[MICRO] §27 PKPiR: Remanent roczny na 31 grudnia %d. Obowiązkowy przy PKPiR!", [tax_year])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.jdg_entrepreneur.has_inventory == true
    input.calendar.month == 12
    tax_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
}

# jdg.micro.pkpir_remnant.p27.r2: remnant_valuation_lower_of — wycena niższa z cen
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r2",
    "package": "jdg.micro.pkpir_remnant", "priority": 80502,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§28 ust. 1 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] §28 PKPiR: Wycena remanentu — NIŻSZA z cen: zakupu (%.2f) lub rynkowej (%.2f) = %.2f PLN", [purchase, market, valued])]
} {
    input.jdg_entrepreneur.has_inventory == true
    purchase := object.get(input.invoice, "purchase_price", 0)
    market := object.get(input.invoice, "market_price", 0)
    valued := min([purchase, market])
    valued > 0
}

# jdg.micro.pkpir_remnant.p27.r3: remnant_damaged_goods — towary uszkodzone = 0
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r3",
    "package": "jdg.micro.pkpir_remnant", "priority": 80503,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§28 ust. 2 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] §28 PKPiR: Towary uszkodzone/przeterminowane — wycena ZEROWA. %d pozycji.", [count])]
} {
    count := object.get(input.jdg_entrepreneur, "damaged_goods_count", 0)
    count > 0
}

# jdg.micro.pkpir_remnant.p27.r4: remnant_transfer_next_year — przeniesienie
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r4",
    "package": "jdg.micro.pkpir_remnant", "priority": 80504,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§29 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] §29 PKPiR: Remanent końcowy %.2f PLN = remanent początkowy następnego roku", [remnant_value])]
} {
    remnant_value := object.get(input.jdg_entrepreneur, "remnant_value_pln", 0)
    remnant_value > 0
    input.calendar.month == 12
}

# jdg.micro.pkpir_remnant.p27.r5: remnant_liquidation_10pct — remanent likwidacyjny 10%
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r5",
    "package": "jdg.micro.pkpir_remnant", "priority": 80505,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Remanent likwidacyjny — 10%% podatku od nadwyżki %.2f PLN", [surplus]),
    "_legal_basis": "Art. 24 ust. 3 PIT",
    "_warnings": [sprintf("[MICRO] §27-29 PKPiR: LIKWIDACJA JDG — 10%% podatku od nadwyżki remanentu: %.2f PLN. Zapłać przed zamknięciem!", [tax_due])]
} {
    input.jdg_entrepreneur.business_closure_in_progress == true
    surplus := object.get(input.jdg_entrepreneur, "remnant_surplus_value", 0)
    surplus > 0
    tax_due := floor(surplus * 0.10 * 100) / 100
}

# jdg.micro.pkpir_remnant.p27.r6: remnant_form_change — remanent przy zmianie formy
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r6",
    "package": "jdg.micro.pkpir_remnant", "priority": 80506,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Remanent przy zmianie formy: %s → %s", [old_form, new_form]),
    "_legal_basis": "Art. 24 ust. 2 PIT, Art. 44 ust. 2 PIT",
    "_warnings": [sprintf("[MICRO] §27 PKPiR: Zmiana formy %s → %s — sporządź remanent na 1 stycznia. Wartość: %.2f PLN.", [old_form, new_form, remnant_value])]
} {
    old_form := object.get(input.jdg_entrepreneur, "previous_tax_form", "")
    new_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    old_form != new_form
    old_form != ""
    remnant_value := object.get(input.jdg_entrepreneur, "remnant_value_pln", 0)
}

# jdg.micro.pkpir_remnant.p27.r7: remnant_no_inventory_warning — brak remanentu
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r7",
    "package": "jdg.micro.pkpir_remnant", "priority": 80507,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Brak remanentu rocznego mimo posiadania zapasów — ryzyko KKS!",
    "_legal_basis": "§27 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] §27 PKPiR: BRAK REMANENTU za %d. Masz zapasy — remanent OBOWIĄZKOWY! Ryzyko KKS Art.56.", [tax_year])]
} {
    input.jdg_entrepreneur.has_inventory == true
    object.get(input.jdg_entrepreneur, "inventory_done_current_year", false) == false
    input.calendar.month == 1
    tax_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026) - 1
}

# jdg.micro.pkpir_remnant.p27.r8: remnant_documentation — dokumentacja remanentu
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.r8",
    "package": "jdg.micro.pkpir_remnant", "priority": 80508,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§28-29 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] §28 PKPiR: Dokumentacja remanentu — spis z natury + wycena + podpis. Przechowuj 5 lat od końca %d.", [retention_end])]
} {
    object.get(input.jdg_entrepreneur, "remnant_documentation_complete", true) == false
    retention_end := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026) + 5
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_remnant.p27.fallback",
    "package": "jdg.micro.pkpir_remnant", "priority": 80599,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§27-29 Rozp. MF PKPiR",
    "_warnings": ["[MICRO] PKPiR remanent — nie dotyczy (brak zapasów lub poza terminem)"]
} { true }
