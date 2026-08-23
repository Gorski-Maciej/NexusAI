# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22a Definicja ŚT (12 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.amort_a22a
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22a

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22a.no_match",
    "package": "jdg.micro.amort_a22a",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22a — Art. 22a Definicja środka trwałego (12 reguł)                 ║
# ║  Legal basis: Art. 22a PIT                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22a.r1: fa_definition — definicja ŚT
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r1",
    "package": "jdg.micro.amort_a22a", "priority": 81001,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: ŚT = składnik majątku o wartości ≥ %.0f PLN, przewidywany okres użytkowania > 1 rok, kompletny i zdatny do użytku.", [min_value])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "VEHICLE", "COMPUTER_EQUIPMENT", "OFFICE_EQUIPMENT", "REAL_ESTATE"}
    min_value := object.get(object.get(data.thresholds, "jdg", {}), "fixed_asset_min_value", 10000)
}

# jdg.micro.amort_a22a.r2: fa_ownership — wymóg własności
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r2",
    "package": "jdg.micro.amort_a22a", "priority": 81002,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: ŚT musi być własnością/współwłasnością podatnika. %s: %s.", [asset_name, ownership_status])]
} {
    is_owned := object.get(input.invoice, "is_owned_asset", false)
    is_co_owned := object.get(input.invoice, "is_co_owned_asset", false)
    is_owned or is_co_owned
    asset_name := object.get(input.invoice, "asset_name", "ŚT")
    ownership_status = "własność" { is_owned == true }
    ownership_status = "współwłasność" { is_co_owned == true }
}

# jdg.micro.amort_a22a.r3: fa_ready_for_use — kompletny i zdatny do użytku
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r3",
    "package": "jdg.micro.amort_a22a", "priority": 81003,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: ŚT musi być kompletny i zdatny do użytku w dniu %s. Amortyzacja od NASTĘPNEGO miesiąca!", [acceptance_date])]
} {
    object.get(input.invoice, "asset_ready_for_use", false) == true
    acceptance_date := object.get(input.invoice, "asset_acceptance_date", "")
}

# jdg.micro.amort_a22a.r4: fa_life_over_year — okres użytkowania >1 rok
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r4",
    "package": "jdg.micro.amort_a22a", "priority": 81004,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: Przewidywany okres użytkowania: %d lat. Powyżej 1 roku = ŚT.", [expected_life])]
} {
    expected_life := object.get(input.invoice, "expected_useful_life_years", 5)
    expected_life > 1
}

# jdg.micro.amort_a22a.r5: fa_initial_value — wartość początkowa
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r5",
    "package": "jdg.micro.amort_a22a", "priority": 81005,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22g PIT: Wartość początkowa ŚT: %.2f PLN (cena nabycia + koszty uboczne + cło + montaż)", [initial_value])]
} {
    initial_value := object.get(input.invoice, "asset_initial_value", 0)
    initial_value >= 10000
}

# jdg.micro.amort_a22a.r6: blocked_not_ready — blokada: ŚT niegotowy do użytku
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r6",
    "package": "jdg.micro.amort_a22a", "priority": 81006,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ŚT niegotowy do użytku — NIE rozpoczynaj amortyzacji!",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: BLOCK — ŚT %s nie jest kompletny/zdatny do użytku. Amortyzacja NIEDOZWOLONA do czasu zakończenia montażu/instalacji!", [asset_name])]
} {
    object.get(input.invoice, "asset_ready_for_use", false) == false
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY"}
    asset_name := object.get(input.invoice, "asset_name", "ŚT")
}

# jdg.micro.amort_a22a.r7: blocked_not_owned — blokada: brak własności
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r7",
    "package": "jdg.micro.amort_a22a", "priority": 81007,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak prawa własności — nie można amortyzować! (leasing operacyjny ≠ własność)",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: BLOCK — %s NIE jest własnością JDG. Leasing operacyjny = rata leasingowa w KUP, NIE amortyzacja!", [asset_name])]
} {
    object.get(input.invoice, "is_owned_asset", false) == false
    object.get(input.invoice, "is_co_owned_asset", false) == false
    input.invoice.category_code in {"FIXED_ASSET", "VEHICLE"}
    asset_name := object.get(input.invoice, "asset_name", "ŚT")
}

# jdg.micro.amort_a22a.r8: exception_building — wyjątek: budynki zawsze ŚT
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r8",
    "package": "jdg.micro.amort_a22a", "priority": 81008,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 pkt 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22a PIT: WYJĄTEK — budynki/budowle ZAWSZE są ŚT (niezależnie od wartości). %s, %.2f PLN.", [asset_name, value])]
} {
    input.invoice.category_code == "REAL_ESTATE"
    asset_name := object.get(input.invoice, "asset_name", "Nieruchomość")
    value := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.amort_a22a.r9: interaction_with_improvement — ulepszenie a ŚT
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22a.r9",
    "package": "jdg.micro.amort_a22a", "priority": 81009,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 17 PIT",
    "_warnings": [sprintf("[MICRO] Art.22g PIT: Ulepszenie ŚT %.2f PLN — %.0f PLN < %.0f = KUP jednorazowo. ≥ %.0f = zwiększa wartość początkową.", [improvement, threshold, threshold, threshold])]
} {
    improvement := object.get(input.invoice, "improvement_amount", 0)
    threshold := object.get(data.thresholds.jdg.depreciation, "improvement_threshold", 10000)
    improvement > 0
}

# ── Bez fallbacka catch-all (konwencja micro warstwy: brak dopasowania → default no_match).
# Składnik niespełniający definicji ŚT (art. 22a) nie produkuje werdyktu — makro KUP
# (kup.rego) obsługuje go jako wydatek; nie przejmujemy no_match (INV-018, wzorzec P03-P05).
