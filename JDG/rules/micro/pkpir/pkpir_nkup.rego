# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — §21 Kolumna 14 NKUP
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir_nkup
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir_nkup

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir_nkup.no_match",
    "package": "jdg.micro.pkpir_nkup",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.p21 — §21 Kolumna 14 — NKUP (10 reguł)                             ║
# ║  Legal basis: §21 Rozp. MF z 15.11.2025 r., Art. 23 PIT                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir_nkup.p21.r1: nkup_definition — definicja NKUP
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r1",
    "package": "jdg.micro.pkpir_nkup", "priority": 80401,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§21 rozporządzenia MF z 15.11.2025 r.",
    "_warnings": ["[MICRO] §21 PKPiR: Kol.14 — wydatki niestanowiące kosztów uzyskania przychodu (NKUP). NIE wliczaj do dochodu PIT!"]
} { input.jdg_entrepreneur.uses_pkpir == true }

# jdg.micro.pkpir_nkup.p21.r2: exception_suspension — wyjątek: NKUP w zawieszeniu (MUSI być PRZED regułami kategorii!)
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r2",
    "package": "jdg.micro.pkpir_nkup", "priority": 80402,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "SUSPENDED", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22-25 Prawa przedsiębiorców",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: WYJĄTEK — zawieszenie JDG. Wydatek %s (%.2f PLN) w całości NKUP!", [category, amount])]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.invoice.category_code not in {"RENT", "UTILITIES", "SECURITY", "LEASE_EXISTING", "INSURANCE", "ACCOUNTING"}
    category := input.invoice.category_code
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_nkup.p21.r3: nkup_representation — reprezentacja → NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r3",
    "package": "jdg.micro.pkpir_nkup", "priority": 80403,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: Kol.14 NKUP — reprezentacja/wydatki osobiste %.2f PLN", [amount])]
} {
    input.invoice.category_code in {"ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE"}
    input.invoice.direction == "PURCHASE"
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_nkup.p21.r4: nkup_cash_over_limit — gotówka >15k → NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r4",
    "package": "jdg.micro.pkpir_nkup", "priority": 80404,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22p PIT",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: Kol.14 NKUP — płatność gotówkowa >15k: %.2f PLN. Cała kwota NKUP!", [amount])]
} {
    input.invoice.is_cash_payment == true
    amount := object.get(input.invoice, "amount_gross", 0)
    amount >= 15000
}

# jdg.micro.pkpir_nkup.p21.r5: nkup_car_75pct — samochód osobowy 75% NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r5",
    "package": "jdg.micro.pkpir_nkup", "priority": 80405,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 25,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: Kol.14 NKUP — auto bez kilometrówki: %.2f PLN (25%% NKUP). Załóż ewidencję = 0%% NKUP!", [nkup_portion])]
} {
    input.invoice.category_code == "CAR"
    object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false) == false
    expense := object.get(input.invoice, "amount_net", 0)
    nkup_portion := floor(expense * 0.25 * 100) / 100
}

# jdg.micro.pkpir_nkup.p21.r6: nkup_lease_excess — nadwyżka leasingu → NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r6",
    "package": "jdg.micro.pkpir_nkup", "priority": 80406,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: Kol.14 NKUP — leasing powyżej limitu: %.2f PLN NKUP (limit 150k/225k EV)", [excess])]
} {
    input.invoice.category_code == "CAR_LEASE"
    excess := object.get(input.invoice, "lease_excess_over_limit", 0)
    excess > 0
}

# jdg.micro.pkpir_nkup.p21.r7: nkup_not_business — wydatek niezwiązany → NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r7",
    "package": "jdg.micro.pkpir_nkup", "priority": 80407,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 PIT (związek z przychodem)",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: Kol.14 NKUP — brak związku z przychodem JDG: %.2f PLN", [amount])]
} {
    object.get(input.invoice, "is_business_related", true) == false
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_nkup.p21.r8: nkup_interest_tax_arrears — odsetki od zaległości → NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r8",
    "package": "jdg.micro.pkpir_nkup", "priority": 80408,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 18 PIT",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: Kol.14 NKUP — odsetki od zaległości podatkowych %.2f PLN — NIE są KUP!", [interest_amount])]
} {
    input.invoice.category_code == "TAX_INTEREST"
    interest_amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_nkup.p21.r9: interaction_vat_nkup — VAT nieodliczalny = NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r9",
    "package": "jdg.micro.pkpir_nkup", "priority": 80409,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 43 PIT",
    "_warnings": [sprintf("[MICRO] §21 PKPiR × VAT: VAT nieodliczalny %.2f PLN → kol.14 NKUP. VAT odliczalny → kol.16.", [vat_nondeductible])]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    vat_nondeductible := object.get(input.invoice, "vat_nondeductible_amount", 0)
    vat_nondeductible > 0
}

# jdg.micro.pkpir_nkup.p21.r10: sanction_nkup_as_kup — sankcja: NKUP zaksięgowane jako KUP
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.r10",
    "package": "jdg.micro.pkpir_nkup", "priority": 80410,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("NKUP %.2f PLN błędnie zaksięgowane w kol.10-13 zamiast kol.14! Ryzyko KKS Art.56!", [amount]),
    "_legal_basis": "Art. 56 KKS",
    "_warnings": [sprintf("[MICRO] §21 PKPiR: SANKCJA — NKUP %.2f PLN w kolumnie KUP! Skoryguj przez storno + wpis w kol.14.", [amount])]
} {
    object.get(input.jdg_entrepreneur, "nkup_misclassified_as_kup", false) == true
    amount := object.get(input.jdg_entrepreneur, "nkup_misclassified_amount", 0)
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_nkup.p21.fallback",
    "package": "jdg.micro.pkpir_nkup", "priority": 80499,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§21 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] PKPiR NKUP — wydatek stanowi KUP"]
} { true }
