# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22n Ewidencja ŚT (8 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.amort_a22n
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22n

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22n.no_match",
    "package": "jdg.micro.amort_a22n",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22n — Art. 22n Ewidencja ŚT (8 reguł)                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22n.r1: register_mandatory — ewidencja ŚT obowiązkowa
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22n.r1",
    "package": "jdg.micro.amort_a22n", "priority": 81301,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22n ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22n PIT: Ewidencja ŚT OBOWIĄZKOWA dla każdego amortyzowanego składnika. %d ŚT w ewidencji.", [count])]
} {
    object.get(input.jdg_entrepreneur, "has_fixed_assets", false) == true
    count := object.get(input.jdg_entrepreneur, "fixed_asset_count", 0)
}

# jdg.micro.amort_a22n.r2: register_elements — elementy ewidencji
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22n.r2",
    "package": "jdg.micro.amort_a22n", "priority": 81302,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22n ust. 2 PIT",
    "_warnings": [sprintf("[MICRO] Art.22n PIT: Ewidencja ŚT nr %s — %.2f PLN. Wymagane: nr, data przyjęcia, nazwa, wartość, stawka %%, odpisy roczne, data likwidacji, przyczyna.", [asset_id, value])]
} {
    asset_id := object.get(input.invoice, "asset_registry_number", "")
    asset_id != ""
    value := object.get(input.invoice, "asset_initial_value", 0)
}

# jdg.micro.amort_a22n.r3: register_update_improvement — aktualizacja przy ulepszeniu
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22n.r3",
    "package": "jdg.micro.amort_a22n", "priority": 81303,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22n ust. 3 PIT",
    "_warnings": [sprintf("[MICRO] Art.22n PIT: Ulepszenie ŚT %s — %.2f PLN. Zwiększ wartość początkową w ewidencji. Nowa wartość: %.2f PLN.", [asset_id, improvement, new_value])]
} {
    input.invoice.category_code == "ASSET_IMPROVEMENT"
    improvement := object.get(input.invoice, "amount_net", 0)
    improvement >= 10000
    asset_id := object.get(input.invoice, "asset_registry_number", "")
    new_value := object.get(input.invoice, "new_initial_value", 0)
}

# jdg.micro.amort_a22n.r4: register_liquidation — likwidacja ŚT
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22n.r4",
    "package": "jdg.micro.amort_a22n", "priority": 81304,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22n ust. 4 PIT",
    "_warnings": [sprintf("[MICRO] Art.22n PIT: Likwidacja ŚT %s — data: %s, przyczyna: %s. Wpis w ewidencji + protokół likwidacji.", [asset_id, liquidation_date, reason])]
} {
    input.invoice.direction == "LIQUIDATION"
    asset_id := object.get(input.invoice, "asset_registry_number", "")
    liquidation_date := object.get(input.invoice, "liquidation_date", "")
    reason := object.get(input.invoice, "liquidation_reason", "")
}

# jdg.micro.amort_a22n.r5: blocked_no_register — blokada: brak ewidencji
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22n.r5",
    "package": "jdg.micro.amort_a22n", "priority": 81305,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak ewidencji ŚT — amortyzacja NIEDOZWOLONA! Odpisy = NKUP!",
    "_legal_basis": "Art. 22n ust. 5 PIT",
    "_warnings": [sprintf("[MICRO] Art.22n PIT: BLOCK — brak ewidencji ŚT. Amortyzacja %.2f PLN NIE stanowi KUP! Załóż ewidencję natychmiast i skoryguj odpisy.", [depr_amount])]
} {
    object.get(input.jdg_entrepreneur, "asset_register_exists", false) == false
    object.get(input.jdg_entrepreneur, "has_fixed_assets", false) == true
    depr_amount := object.get(input.invoice, "depreciation_annual_pln", 0)
}

# jdg.micro.amort_a22n.r6: register_sale — sprzedaż ŚT w ewidencji
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22n.r6",
    "package": "jdg.micro.amort_a22n", "priority": 81306,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22n ust. 4 PIT, Art. 14 PIT",
    "_warnings": [sprintf("[MICRO] Art.22n PIT: Sprzedaż ŚT %s — %.2f PLN. Ewidencja: data sprzedaży + przyczyna. Przychód w kol.7/8 PKPiR, niezamortyzowana wartość w KUP.", [asset_id, sale_price])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"FIXED_ASSET_SALE", "VEHICLE_SALE"}
    asset_id := object.get(input.invoice, "asset_registry_number", "")
    sale_price := object.get(input.invoice, "amount_net", 0)
}

# ── Bez fallbacka catch-all (konwencja micro warstwy: brak dopasowania → default no_match).
