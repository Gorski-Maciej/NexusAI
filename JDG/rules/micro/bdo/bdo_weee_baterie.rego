# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO — WEEE/Baterie/SUP (P1918-P1921 → 8r)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.bdo_weee
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.bdo_weee

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.bdo_weee.no_match",
    "package": "jdg.micro.bdo_weee", "priority": 999999
}

# jdg.micro.bdo_weee.r1: weee_registration_check
decide := {
    "matched": true, "rule_id": "jdg.micro.bdo_weee.r1",
    "package": "jdg.micro.bdo_weee", "priority": 82501,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("WEEE — sprzedaż %.1f kg sprzętu elektrycznego. Rejestracja: %s", [kg, reg]),
    "_legal_basis": "Ustawa o ZSEiE (Dz.U. 2023 poz. 1322)",
    "_warnings": [sprintf("[MICRO] BDO WEEE: %s kg sprzętu. %s. Poziom zbiórki: %.0f%%. Rejestracja w oddzielnym rejestrze ZSEiE w BDO. Opłata produktowa przy nieosiągnięciu poziomu.", [kg, reg, coll_pct])]
} {
    input.business.sells_electronics == true
    kg := object.get(input.business, "weee_sold_kg", 0); kg > 0
    is_reg := object.get(input.business, "weee_registered_in_bdo", false)
    reg = "ZAREJESTROWANY — OK" { is_reg }; reg = "BRAK REJESTRACJI!" { not is_reg }
    coll_pct := object.get(input.business, "weee_collection_pct", 0)
}

# jdg.micro.bdo_weee.r2: weee_collection_target — cel zbiórki
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_weee.r2",
    "package": "jdg.micro.bdo_weee", "priority": 82502,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("WEEE — zbiórka %.0f%% (cel 65%%)", [coll_pct]),
    "_legal_basis": "Dyrektywa WEEE 2012/19/UE",
    "_warnings": [sprintf("[MICRO] BDO WEEE: poziom zbiórki %.0f%% (cel: 65%% od 2019). %s Opłata produktowa za brak: %.2f PLN/kg.", [coll_pct, status, penalty])]
} {
    input.business.sells_electronics == true
    coll_pct := object.get(input.business, "weee_collection_pct", 0)
    status = "CEL OSIĄGNIĘTY" { coll_pct >= 65 }
    status = "CEL NIEOSIĄGNIĘTY — opłata!" { coll_pct < 65 }
    penalty := object.get(object.get(data.thresholds, "jdg", {}), "weee_penalty_per_kg", 15.00)
}

# jdg.micro.bdo_weee.r3: battery_introduction_check
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_weee.r3",
    "package": "jdg.micro.bdo_weee", "priority": 82503,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Baterie — %.1f kg wprowadzonych. Cel zbiórki: %.0f%%", [kg, target]),
    "_legal_basis": "Ustawa o bateriach i akumulatorach, Rozp. UE 2023/1542",
    "_warnings": [sprintf("[MICRO] BDO BATERIE: %.1f kg. Cel zbiórki: %.0f%%. Sprawozdanie roczne do 15 marca. Opłata produktowa: %.2f PLN/kg poniżej celu.", [kg, target, penalty])]
} {
    input.business.introduces_batteries == true
    kg := object.get(input.business, "battery_mass_introduced_kg", 0); kg > 0
    target := object.get(object.get(data.thresholds, "jdg", {}), "battery_collection_target_pct", 45)
    penalty := object.get(object.get(data.thresholds, "jdg", {}), "battery_penalty_per_kg", 12.00)
}

# jdg.micro.bdo_weee.r4: sup_plastic_calculation
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_weee.r4",
    "package": "jdg.micro.bdo_weee", "priority": 82504,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("SUP EPR — %.0f kg plastiku = %.2f PLN opłaty", [kg, fee]),
    "_legal_basis": "Ustawa SUP (Dz.U. 2023 poz. 877), Dyrektywa SUP 2019/904",
    "_warnings": [sprintf("[MICRO] BDO SUP: %.0f kg plastiku jednorazowego. Opłata EPR: %.2f PLN. Od 2025 zakaz: patyczki higieniczne, słomki, sztućce, talerze, pojemniki styropianowe.", [kg, fee])]
} {
    input.business.introduces_sup_products == true
    kg := object.get(input.business, "sup_plastic_kg", 0); kg > 0
    rate := object.get(object.get(data.thresholds, "jdg", {}), "sup_epr_rate_per_kg", 0.80)
    fee := floor(kg * rate * 100) / 100
}

# jdg.micro.bdo_weee.r5: environmental_damage_remediation
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_weee.r5",
    "package": "jdg.micro.bdo_weee", "priority": 82505,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Szkoda w środowisku: %s. Remediacja WYMAGANA!", [dmg_type]),
    "_legal_basis": "Ustawa o zapobieganiu szkodom w środowisku i ich naprawie",
    "_warnings": [sprintf("[MICRO] BDO SZKODA: %s — natychmiastowe działania zapobiegawcze + zgłoszenie do RDOŚ w 30 dni. Szacunkowy koszt remediacji: %.0f PLN. Odpowiedzialność niezależnie od winy!", [dmg_type, cost])]
} {
    input.business.environmental_damage_detected == true
    dmg_type := object.get(input.business, "environmental_damage_type", "zanieczyszczenie gleby")
    cost := object.get(input.business, "remediation_estimated_cost_pln", 0)
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_weee.fallback",
    "package": "jdg.micro.bdo_weee", "priority": 82599,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa o odpadach",
    "_warnings": ["[MICRO] BDO WEEE/Baterie/SUP — JDG nie podlega tym obowiązkom."]
} { true }
