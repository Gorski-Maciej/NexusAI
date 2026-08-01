# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Prawo budowlane — 6 artykułów → ~50 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-14
# Package: jdg.micro.budownictwo
# Legal basis: Prawo budowlane (Dz.U. 1994 nr 89 poz. 414), KC art. 647-658, VAT reverse charge
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.budownictwo

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.budownictwo.no_match",
    "package": "jdg.micro.budownictwo",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a1 — Pozwolenie na budowę / zgłoszenie (8 reguł)              ║
# ║  Legal basis: Art. 28-35 Prawa budowlanego                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a1.r1: budownictwo_a1_r1_permit_required
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak pozwolenia na budowę — inwestycja wymaga pozwolenia",
    "_legal_basis": "Art. 28 Prawa budowlanego",
    "_warnings": ["[MICRO] Pozwolenie na budowę: sprawdzenie czy inwestycja wymaga pozwolenia"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "REQUIRES_PERMIT"
    object.get(input.jdg_entrepreneur, "building_permit_obtained", false) == false
}

# jdg.micro.budownictwo.a1.r2: budownictwo_a1_r2_notification_sufficient
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Zgłoszenie budowlane wystarczające dla tej kategorii",
    "_legal_basis": "Art. 29-30 Prawa budowlanego",
    "_warnings": ["[MICRO] Pozwolenie na budowę: inwestycja kwalifikuje się do zgłoszenia, nie wymaga pozwolenia"]
} {
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "NOTIFICATION_ONLY"
    object.get(input.jdg_entrepreneur, "building_notification_filed", false) == true
}

# jdg.micro.budownictwo.a1.r3: budownictwo_a1_r3_permit_obtained_valid
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Pozwolenie na budowę uzyskane — inwestycja zgodna z prawem",
    "_legal_basis": "Art. 28 Prawa budowlanego",
    "_warnings": ["[MICRO] Pozwolenie na budowę: dokumentacja kompletna, pozwolenie ważne"]
} {
    object.get(input.jdg_entrepreneur, "building_permit_obtained", false) == true
    object.get(input.jdg_entrepreneur, "building_permit_valid_until", "") != ""
}

# jdg.micro.budownictwo.a1.r4: budownictwo_a1_r4_permit_expired
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Pozwolenie na budowę wygasło — wymagane nowe pozwolenie",
    "_legal_basis": "Art. 37 Prawa budowlanego",
    "_warnings": ["[MICRO] Pozwolenie na budowę WYGASŁO! Rozpoczęcie robót bez ważnego pozwolenia grozi wstrzymaniem budowy i karą"]
} {
    object.get(input.jdg_entrepreneur, "building_permit_valid_until", "1970-01-01") < input.current_date
}

# jdg.micro.budownictwo.a1.r5: budownictwo_a1_r5_construction_log_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Dziennik budowy — obowiązek prowadzenia dla inwestycji z pozwoleniem",
    "_legal_basis": "Art. 45 Prawa budowlanego",
    "_warnings": ["[MICRO] Dziennik budowy: obowiązek prowadzenia dla tej inwestycji — brak dziennika = wykroczenie"]
} {
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "REQUIRES_PERMIT"
    object.get(input.jdg_entrepreneur, "construction_log_maintained", false) == false
}

# jdg.micro.budownictwo.a1.r6: budownictwo_a1_r6_construction_manager_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kierownik budowy wymagany — brak ustanowienia kierownika",
    "_legal_basis": "Art. 42 Prawa budowlanego",
    "_warnings": ["[MICRO] Kierownik budowy: OBOWIĄZKOWY dla tej kategorii inwestycji — ustanów kierownika przed rozpoczęciem robót"]
} {
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "REQUIRES_PERMIT"
    object.get(input.jdg_entrepreneur, "construction_manager_appointed", false) == false
}

# jdg.micro.budownictwo.a1.r7: budownictwo_a1_r7_occupancy_permit_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Pozwolenie na użytkowanie — obowiązek uzyskania przed oddaniem obiektu",
    "_legal_basis": "Art. 55-59 Prawa budowlanego",
    "_warnings": ["[MICRO] Pozwolenie na użytkowanie: wymagane przed rozpoczęciem użytkowania obiektu"]
} {
    object.get(input.jdg_entrepreneur, "construction_status", "") == "COMPLETED"
    object.get(input.jdg_entrepreneur, "occupancy_permit_obtained", false) == false
    object.get(input.jdg_entrepreneur, "occupancy_permit_not_required", false) == false
}

# jdg.micro.budownictwo.a1.r8: budownictwo_a1_r8_illegal_construction_penalty
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a1.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Samowola budowlana — konsekwencje prawne i finansowe",
    "_legal_basis": "Art. 48-50 Prawa budowlanego",
    "_warnings": ["[MICRO] SAMOWOLA BUDOWLANA! Grozi nakaz rozbiórki, kara do 1 000 000 PLN, odpowiedzialność karna"]
} {
    object.get(input.jdg_entrepreneur, "construction_without_permit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a2 — Reverse charge VAT dla usług budowlanych (8 reguł)       ║
# ║  Legal basis: Art. 17 ust. 1 pkt 8 VAT, Załącznik nr 14 do ustawy o VAT   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a2.r1: budownictwo_a2_r1_reverse_charge_applies
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250009,
    "vat_rate": "0.00",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge VAT — usługa budowlana objęta odwrotnym obciążeniem",
    "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT, Załącznik nr 14",
    "_warnings": ["[MICRO] Reverse charge: usługa budowlana między czynnymi podatnikami VAT — nabywca rozlicza VAT"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "pkwiu_code", "") in {"41.00", "42.00", "43.00", "43.11", "43.12", "43.13", "43.2", "43.3", "43.9"}
    object.get(input.counterparty, "is_vat_payer", false) == true
    input.jdg_entrepreneur.is_vat_payer == true
}

# jdg.micro.budownictwo.a2.r2: budownictwo_a2_r2_reverse_charge_not_applies_b2c
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250010,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge NIE ma zastosowania — klient nie jest podatnikiem VAT (B2C)",
    "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT",
    "_warnings": ["[MICRO] Reverse charge: odbiorca usługi budowlanej nie jest podatnikiem VAT — standardowe rozliczenie VAT"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.counterparty, "is_vat_payer", false) == false
}

# jdg.micro.budownictwo.a2.r3: budownictwo_a2_r3_reverse_charge_invoice_marking
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Reverse charge — faktura musi zawierać adnotację 'odwrotne obciążenie'",
    "_legal_basis": "Art. 106e ust. 1 pkt 18 VAT",
    "_warnings": ["[MICRO] Reverse charge: FAKTURA MUSI zawierać adnotację 'odwrotne obciążenie' — brak = wada formalna faktury"]
} {
    object.get(input.invoice, "reverse_charge_applies", false) == true
    object.get(input.invoice, "reverse_charge_annotation_present", false) == false
}

# jdg.micro.budownictwo.a2.r4: budownictwo_a2_r4_reverse_charge_subcontractor
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge — podwykonawca rozlicza reverse charge na generalnego wykonawcę",
    "_legal_basis": "Art. 17 ust. 1h VAT",
    "_warnings": ["[MICRO] Reverse charge podwykonawca: JDG jako podwykonawca wystawia fakturę z adnotacją 'odwrotne obciążenie'"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") == "SUBCONTRACTOR"
    object.get(input.counterparty, "construction_role", "") == "GENERAL_CONTRACTOR"
    object.get(input.counterparty, "is_vat_payer", false) == true
}

# jdg.micro.budownictwo.a2.r5: budownictwo_a2_r5_reverse_charge_general_contractor
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge — generalny wykonawca rozlicza VAT od podwykonawcy",
    "_legal_basis": "Art. 17 ust. 1 pkt 8 w zw. z ust. 1h VAT",
    "_warnings": ["[MICRO] Reverse charge generalny wykonawca: obowiązek rozliczenia VAT należnego i naliczonego od faktury podwykonawcy"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") == "GENERAL_CONTRACTOR"
    object.get(input.counterparty, "construction_role", "") == "SUBCONTRACTOR"
}

# jdg.micro.budownictwo.a2.r6: budownictwo_a2_r6_reverse_charge_jpk_marking
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge — obowiązek wykazania w JPK_V7 z oznaczeniem SW",
    "_legal_basis": "Art. 109 ust. 3b VAT, Rozporządzenie MF ws. JPK_V7",
    "_warnings": ["[MICRO] Reverse charge JPK: oznacz transakcję kodem SW w JPK_V7 — brak oznaczenia = błąd w deklaracji"]
} {
    object.get(input.invoice, "reverse_charge_applies", false) == true
    object.get(input.invoice, "jpk_sw_marked", false) == false
}

# jdg.micro.budownictwo.a2.r7: budownictwo_a2_r7_reverse_charge_materials_with_service
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge — materiały z montażem = całość objęta odwrotnym obciążeniem",
    "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT, interpretacja ogólna MF",
    "_warnings": ["[MICRO] Reverse charge materiały+usługa: gdy dominuje usługa budowlana, całość (materiały + robocizna) objęta odwrotnym obciążeniem"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION_WITH_MATERIALS"
    object.get(input.invoice, "materials_only_separate_invoice", false) == false
}

# jdg.micro.budownictwo.a2.r8: budownictwo_a2_r8_reverse_charge_not_employee
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a2.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Reverse charge NIE dotyczy — usługi świadczone przez pracowników (umowa o pracę)",
    "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT — dotyczy tylko usług od podatników VAT",
    "_warnings": ["[MICRO] Reverse charge: usługi budowlane świadczone przez pracowników na umowie o pracę NIE są objęte odwrotnym obciążeniem — to nie jest podwykonawstwo"]
} {
    object.get(input.counterparty, "employment_type", "") == "EMPLOYMENT_CONTRACT"
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a3 — Umowa o roboty budowlane (KC art. 647-658) (8 reguł)    ║
# ║  Legal basis: Kodeks Cywilny art. 647-658                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a3.r1: budownictwo_a3_r1_contract_form_written
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Umowa o roboty budowlane — wymagana forma pisemna dla celów dowodowych",
    "_legal_basis": "Art. 648 § 1 KC",
    "_warnings": ["[MICRO] Umowa budowlana: wymagana forma pisemna — brak pisemnej umowy = ryzyko sporu, trudności dowodowe"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") in {"GENERAL_CONTRACTOR", "SUBCONTRACTOR"}
    object.get(input.contract, "is_written_form", false) == false
    object.get(input.contract, "value_pln", 0) > 50000
}

# jdg.micro.budownictwo.a3.r2: budownictwo_a3_r2_contract_scope_defined
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Umowa budowlana — obowiązek określenia zakresu robót i dokumentacji projektowej",
    "_legal_basis": "Art. 647 KC",
    "_warnings": ["[MICRO] Umowa budowlana: zakres robót i dokumentacja projektowa muszą być określone w umowie"]
} {
    object.get(input.contract, "scope_of_work_defined", false) == true
    object.get(input.contract, "project_documentation_provided", false) == true
}

# jdg.micro.budownictwo.a3.r3: budownictwo_a3_r3_subcontractor_consent_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Podwykonawca — wymagana zgoda inwestora na zawarcie umowy z podwykonawcą",
    "_legal_basis": "Art. 647¹ § 2 KC",
    "_warnings": ["[MICRO] Podwykonawca: wymagana ZGODA INWESTORA na piśmie — bez zgody inwestor nie odpowiada solidarnie za zapłatę"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") == "SUBCONTRACTOR"
    object.get(input.contract, "investor_consent_obtained", false) == false
}

# jdg.micro.budownictwo.a3.r4: budownictwo_a3_r4_investor_solidary_liability
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Solidarna odpowiedzialność inwestora za zapłatę podwykonawcy",
    "_legal_basis": "Art. 647¹ § 5 KC",
    "_warnings": ["[MICRO] Solidarna odpowiedzialność: inwestor odpowiada solidarnie z generalnym wykonawcą za zapłatę wynagrodzenia podwykonawcy"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") == "SUBCONTRACTOR"
    object.get(input.contract, "investor_consent_obtained", false) == true
    object.get(input.contract, "payment_overdue", false) == true
}

# jdg.micro.budownictwo.a3.r5: budownictwo_a3_r5_contract_remuneration_fixed
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Wynagrodzenie ryczałtowe — zasady dla umów o roboty budowlane",
    "_legal_basis": "Art. 632 KC w zw. z art. 656 KC",
    "_warnings": ["[MICRO] Wynagrodzenie ryczałtowe: wykonawca nie może żądać podwyższenia wynagrodzenia, chyba że zmiana zakresu robót"]
} {
    object.get(input.contract, "remuneration_type", "") == "FIXED_LUMP_SUM"
    object.get(input.contract, "scope_change_requested", false) == false
}

# jdg.micro.budownictwo.a3.r6: budownictwo_a3_r6_contract_retention_guarantee
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Kaucja gwarancyjna / zabezpieczenie należytego wykonania — KUP w momencie potrącenia",
    "_legal_basis": "Art. 22 ust. 1 PIT, Art. 19a VAT",
    "_warnings": ["[MICRO] Kaucja gwarancyjna: kwota zatrzymana jako zabezpieczenie = przychód podatkowy dopiero po zwolnieniu kaucji"]
} {
    object.get(input.contract, "retention_percent", 0) > 0
    object.get(input.contract, "retention_released", false) == false
}

# jdg.micro.budownictwo.a3.r7: budownictwo_a3_r7_contract_penalty_kup
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Kary umowne w budownictwie — KUP/NKUP rozróżnienie",
    "_legal_basis": "Art. 23 ust. 1 pkt 19 PIT (kary umowne z tytułu wad towarów/usług = NKUP)",
    "_warnings": ["[MICRO] Kary umowne budowlane: kara za opóźnienie ≠ kara za wady — tylko kara za wady = NKUP"]
} {
    object.get(input.contract, "contractual_penalty_type", "") == "DEFECTS"
    object.get(input.contract, "contractual_penalty_paid", false) == true
}

# jdg.micro.budownictwo.a3.r8: budownictwo_a3_r8_contract_acceptance_protocol
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a3.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Protokół odbioru robót — moment powstania przychodu i obowiązku VAT",
    "_legal_basis": "Art. 647 KC, Art. 19a ust. 1 VAT (data wykonania usługi), Art. 14 PIT",
    "_warnings": ["[MICRO] Protokół odbioru: data podpisania protokołu = data wykonania usługi dla celów VAT i PIT"]
} {
    object.get(input.contract, "acceptance_protocol_signed", false) == true
    object.get(input.invoice, "tax_point_date", "") == ""
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a4 — BHP na budowie (8 reguł)                                 ║
# ║  Legal basis: Rozporządzenie MBHiP w sprawie BHP na budowie                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a4.r1: budownictwo_a4_r1_bhp_plan_required
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Plan BIOZ wymagany — brak planu bezpieczeństwa i ochrony zdrowia",
    "_legal_basis": "Art. 21a Prawa budowlanego, Rozporządzenie MI",
    "_warnings": ["[MICRO] Plan BIOZ: OBOWIĄZKOWY przy budowach powyżej 30 dni i 20 pracowników — brak = wykroczenie"]
} {
    object.get(input.jdg_entrepreneur, "construction_duration_days", 0) > 30
    object.get(input.jdg_entrepreneur, "construction_workers_count", 0) >= 20
    object.get(input.jdg_entrepreneur, "bioz_plan_prepared", false) == false
}

# jdg.micro.budownictwo.a4.r2: budownictwo_a4_r2_bhp_training_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Szkolenie BHP — obowiązek dla wszystkich pracowników na budowie",
    "_legal_basis": "Art. 237³ Kodeksu Pracy, Rozporządzenie MGiP ws. szkoleń BHP",
    "_warnings": ["[MICRO] Szkolenie BHP: każdy pracownik na budowie musi posiadać aktualne szkolenie BHP — brak = kara do 30 000 PLN"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") in {"GENERAL_CONTRACTOR", "SUBCONTRACTOR"}
    object.get(input.jdg_entrepreneur, "workers_bhp_trained", false) == false
}

# jdg.micro.budownictwo.a4.r3: budownictwo_a4_r3_ppe_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Środki ochrony indywidualnej — obowiązek zapewnienia pracownikom",
    "_legal_basis": "Art. 237⁶ KP, Rozporządzenie ws. ogólnych przepisów BHP",
    "_warnings": ["[MICRO] ŚOI: kaski, kamizelki, obuwie ochronne — OBOWIĄZKOWE na budowie. Koszt = KUP pracodawcy"]
} {
    object.get(input.jdg_entrepreneur, "construction_workers_count", 0) > 0
    object.get(input.jdg_entrepreneur, "ppe_provided", false) == false
}

# jdg.micro.budownictwo.a4.r4: budownictwo_a4_r4_scaffolding_inspection
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Rusztowania — obowiązek przeglądu przed oddaniem do użytku i okresowo",
    "_legal_basis": "Rozporządzenie ws. BHP przy pracach na wysokości",
    "_warnings": ["[MICRO] Rusztowania: przegląd rusztowania co 30 dni — brak przeglądu = zagrożenie katastrofą budowlaną"]
} {
    object.get(input.jdg_entrepreneur, "scaffolding_in_use", false) == true
    object.get(input.jdg_entrepreneur, "scaffolding_last_inspection_days", 365) > 30
}

# jdg.micro.budownictwo.a4.r5: budownictwo_a4_r5_construction_fence_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Ogrodzenie placu budowy — obowiązek zabezpieczenia terenu",
    "_legal_basis": "Rozporządzenie ws. BHP na budowie § 9-15",
    "_warnings": ["[MICRO] Ogrodzenie budowy: teren budowy musi być ogrodzony i oznakowany — koszt ogrodzenia = KUP"]
} {
    object.get(input.jdg_entrepreneur, "construction_site_fenced", false) == false
    object.get(input.jdg_entrepreneur, "construction_in_public_area", false) == true
}

# jdg.micro.budownictwo.a4.r6: budownictwo_a4_r6_construction_site_signage
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Tablica informacyjna budowy — obowiązek wywieszenia",
    "_legal_basis": "Art. 42 ust. 2 pkt 2 Prawa budowlanego",
    "_warnings": ["[MICRO] Tablica informacyjna: OBOWIĄZKOWA na każdej budowie z pozwoleniem — zawiera dane inwestora, projektanta, kierownika"]
} {
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "REQUIRES_PERMIT"
    object.get(input.jdg_entrepreneur, "construction_signage_installed", false) == false
}

# jdg.micro.budownictwo.a4.r7: budownictwo_a4_r7_excavation_protection
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Wykopy — obowiązek zabezpieczenia przed osunięciem",
    "_legal_basis": "Rozporządzenie ws. BHP przy robotach ziemnych",
    "_warnings": ["[MICRO] Wykopy: wykopy powyżej 1m głębokości muszą być zabezpieczone przed osunięciem — skarpowanie lub szalunki"]
} {
    object.get(input.jdg_entrepreneur, "excavation_depth_m", 0) > 1.0
    object.get(input.jdg_entrepreneur, "excavation_protected", false) == false
}

# jdg.micro.budownictwo.a4.r8: budownictwo_a4_r8_electrical_safety
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a4.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Instalacje elektryczne na budowie — wymagane uprawnienia SEP",
    "_legal_basis": "Rozporządzenie ws. BHP przy urządzeniach elektroenergetycznych",
    "_warnings": ["[MICRO] Instalacje elektryczne: prace przy instalacjach elektrycznych tylko przez osoby z uprawnieniami SEP — koszt uprawnień = KUP"]
} {
    object.get(input.jdg_entrepreneur, "electrical_work_performed", false) == true
    object.get(input.jdg_entrepreneur, "workers_sep_certified", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a5 — Odpowiedzialność za wady / gwarancja (10 reguł)         ║
# ║  Legal basis: KC art. 556-576, art. 637-638 (rękojmia za wady)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a5.r1: budownictwo_a5_r1_warranty_period_5_years
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Rękojmia za wady obiektu budowlanego — okres 5 lat",
    "_legal_basis": "Art. 568 § 1 KC w zw. z art. 638 KC (5 lat dla wad nieruchomości)",
    "_warnings": ["[MICRO] Rękojmia budowlana: okres rękojmi za wady obiektu budowlanego = 5 LAT od wydania obiektu"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") in {"GENERAL_CONTRACTOR", "SUBCONTRACTOR"}
    object.get(input.contract, "construction_completion_date", "") != ""
    object.get(input.contract, "defect_claim_date", "") != ""
}

# jdg.micro.budownictwo.a5.r2: budownictwo_a5_r2_defect_notification_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Zgłoszenie wady — obowiązek zgłoszenia w ciągu miesiąca od wykrycia",
    "_legal_basis": "Art. 563 § 1 KC",
    "_warnings": ["[MICRO] Zgłoszenie wady: wadę należy zgłosić w ciągu 1 MIESIĄCA od jej wykrycia — po terminie utrata uprawnień"]
} {
    object.get(input.jdg_entrepreneur, "defect_detected", false) == true
    object.get(input.jdg_entrepreneur, "defect_reported_within_month", false) == false
}

# jdg.micro.budownictwo.a5.r3: budownictwo_a5_r3_warranty_reserve_kup
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Rezerwa na naprawy gwarancyjne — KUP dopiero przy faktycznym wykonaniu",
    "_legal_basis": "Art. 22 ust. 1 PIT (koszt w momencie poniesienia), Art. 39 UoR (rezerwy)",
    "_warnings": ["[MICRO] Rezerwa gwarancyjna: rezerwa na przyszłe naprawy gwarancyjne NIE jest KUP — KUP dopiero przy faktycznym poniesieniu kosztu naprawy"]
} {
    object.get(input.jdg_entrepreneur, "warranty_reserve_created", false) == true
}

# jdg.micro.budownictwo.a5.r4: budownictwo_a5_r4_defect_repair_cost_kup
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Koszty napraw gwarancyjnych / rękojmi — KUP w momencie poniesienia",
    "_legal_basis": "Art. 22 ust. 1 PIT",
    "_warnings": ["[MICRO] Naprawy gwarancyjne: faktycznie poniesione koszty napraw = KUP. VAT od faktury za materiały do naprawy = odliczalny"]
} {
    object.get(input.invoice, "expense_category", "") == "WARRANTY_REPAIR"
    object.get(input.invoice, "defect_repair_actual_cost_incurred", false) == true
}

# jdg.micro.budownictwo.a5.r5: budownictwo_a5_r5_defect_rectification_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Termin usunięcia wady — 14 dni od zgłoszenia (standard rynkowy)",
    "_legal_basis": "Art. 561 § 1 KC (żądanie usunięcia wady w rozsądnym terminie)",
    "_warnings": ["[MICRO] Usunięcie wady: standardowy termin na usunięcie wady = 14 dni od zgłoszenia — po terminie inwestor może zlecić zastępczo na koszt wykonawcy"]
} {
    object.get(input.contract, "defect_reported_date", "") != ""
    object.get(input.contract, "defect_rectification_days", 0) > 14
    object.get(input.contract, "defect_rectified", false) == false
}

# jdg.micro.budownictwo.a5.r6: budownictwo_a5_r6_replacement_performance_cost
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Wykonawstwo zastępcze — koszty obciążają niewykonawczego wykonawcę",
    "_legal_basis": "Art. 480 KC (wykonawstwo zastępcze), Art. 636 KC",
    "_warnings": ["[MICRO] Wykonawstwo zastępcze: koszty wykonawstwa zastępczego + różnica w cenie = obciążenie dla pierwotnego wykonawcy. VAT naliczony od faktury zastępczej = odliczalny"]
} {
    object.get(input.contract, "replacement_contractor_engaged", false) == true
    object.get(input.jdg_entrepreneur, "is_original_contractor", false) == true
}

# jdg.micro.budownictwo.a5.r7: budownictwo_a5_r7_construction_insurance_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Ubezpieczenie budowy — OC wykonawcy + ubezpieczenie od ryzyk budowlanych",
    "_legal_basis": "Art. 648 § 1 KC (obowiązek umowny), Praktyka rynkowa",
    "_warnings": ["[MICRO] Ubezpieczenie budowy: OC wykonawcy i ubezpieczenie CAR = KUP. Składka = koszt uzyskania przychodu"]
} {
    object.get(input.jdg_entrepreneur, "construction_role", "") in {"GENERAL_CONTRACTOR"}
    object.get(input.jdg_entrepreneur, "construction_insurance_active", false) == false
}

# jdg.micro.budownictwo.a5.r8: budownictwo_a5_r8_defect_claim_documentation
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Dokumentacja reklamacyjna — protokół wad, zdjęcia, ekspertyza",
    "_legal_basis": "Art. 6 KC (ciężar dowodu), Art. 22 UoR (dowody księgowe)",
    "_warnings": ["[MICRO] Dokumentacja wad: protokół wad, dokumentacja fotograficzna, ekspertyza techniczna — niezbędne dla celów dowodowych i księgowych"]
} {
    object.get(input.contract, "defect_claim_filed", false) == true
    object.get(input.contract, "defect_documentation_complete", false) == false
}

# jdg.micro.budownictwo.a5.r9: budownictwo_a5_r9_construction_waste_kup
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r9",
    "package": "jdg.micro.budownictwo",
    "priority": 250041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Utylizacja odpadów budowlanych — obowiązek BDO i KUP",
    "_legal_basis": "Art. 66 Ustawy o odpadach, Art. 22 ust. 1 PIT (KUP)",
    "_warnings": ["[MICRO] Odpady budowlane: koszt utylizacji odpadów = KUP. Obowiązek wpisu w BDO i karty przekazania odpadów"]
} {
    object.get(input.jdg_entrepreneur, "construction_waste_generated", false) == true
    object.get(input.jdg_entrepreneur, "bdo_registered", false) == false
}

# jdg.micro.budownictwo.a5.r10: budownictwo_a5_r10_construction_guarantee_insurance
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a5.r10",
    "package": "jdg.micro.budownictwo",
    "priority": 250042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Gwarancja ubezpieczeniowa — alternatywa dla kaucji gwarancyjnej, koszt = KUP",
    "_legal_basis": "Art. 22 ust. 1 PIT, Art. 86 VAT (odliczenie VAT od składki)",
    "_warnings": ["[MICRO] Gwarancja ubezpieczeniowa: koszt gwarancji = KUP, VAT od składki = odliczalny (zw. ze sprzedażą opodatkowaną)"]
} {
    object.get(input.contract, "guarantee_insurance_obtained", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a6 — Katastrofa budowlana i odpowiedzialność karna (8 reguł) ║
# ║  Legal basis: Art. 90-98 Prawa budowlanego, KK/KW                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a6.r1: budownictwo_a6_r1_catastrophe_notification
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Katastrofa budowlana — obowiązek natychmiastowego zgłoszenia",
    "_legal_basis": "Art. 75 Prawa budowlanego",
    "_warnings": ["[MICRO] KATASTROFA BUDOWLANA! Natychmiast zgłoś do: PINB, Policja, Prokuratura. Niezgłoszenie = przestępstwo"]
} {
    object.get(input.jdg_entrepreneur, "construction_catastrophe_occurred", false) == true
    object.get(input.jdg_entrepreneur, "catastrophe_reported_to_authorities", false) == false
}

# jdg.micro.budownictwo.a6.r2: budownictwo_a6_r2_catastrophe_cause_investigation
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Postępowanie wyjaśniające przyczyny katastrofy — koszty ekspertyz = KUP",
    "_legal_basis": "Art. 76 Prawa budowlanego",
    "_warnings": ["[MICRO] Katastrofa budowlana: koszty ekspertyz technicznych i opinii rzeczoznawców = KUP (zabezpieczenie źródła przychodów)"]
} {
    object.get(input.jdg_entrepreneur, "catastrophe_investigation_ordered", false) == true
}

# jdg.micro.budownictwo.a6.r3: budownictwo_a6_r3_construction_log_violation
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Nieprowadzenie dziennika budowy — wykroczenie",
    "_legal_basis": "Art. 93 pkt 3 Prawa budowlanego",
    "_warnings": ["[MICRO] Dziennik budowy: nieprowadzenie dziennika = kara grzywny do 5 000 PLN (wykroczenie)"]
} {
    object.get(input.jdg_entrepreneur, "construction_log_required", false) == true
    object.get(input.jdg_entrepreneur, "construction_log_maintained", false) == false
}

# jdg.micro.budownictwo.a6.r4: budownictwo_a6_r4_unauthorized_deviation_from_project
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Istotne odstąpienie od projektu bez zgody — samowola budowlana",
    "_legal_basis": "Art. 36a Prawa budowlanego, Art. 50",
    "_warnings": ["[MICRO] Odstąpienie od projektu: istotne zmiany bez zgody projektanta i PINB = samowola budowlana — nakaz rozbiórki!"]
} {
    object.get(input.jdg_entrepreneur, "project_deviation_significant", false) == true
    object.get(input.jdg_entrepreneur, "project_deviation_approved", false) == false
}

# jdg.micro.budownictwo.a6.r5: budownictwo_a6_r5_construction_without_manager
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak kierownika budowy przy robotach wymagających pozwolenia — przestępstwo",
    "_legal_basis": "Art. 90 Prawa budowlanego",
    "_warnings": ["[MICRO] Brak kierownika budowy: prowadzenie robót bez kierownika = kara ograniczenia wolności albo pozbawienia wolności do lat 2!"]
} {
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "REQUIRES_PERMIT"
    object.get(input.jdg_entrepreneur, "construction_manager_appointed", false) == false
    object.get(input.jdg_entrepreneur, "construction_in_progress", false) == true
}

# jdg.micro.budownictwo.a6.r6: budownictwo_a6_r6_construction_noise_violation
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Hałas budowlany poza dozwolonymi godzinami — wykroczenie",
    "_legal_basis": "Art. 51 KW, Uchwały rad gmin o ciszy nocnej",
    "_warnings": ["[MICRO] Hałas budowlany: prace budowlane poza godzinami 6:00-22:00 (lub wg uchwały gminy) = mandat do 500 PLN"]
} {
    object.get(input.jdg_entrepreneur, "construction_noise_complaint", false) == true
}

# jdg.micro.budownictwo.a6.r7: budownictwo_a6_r7_construction_signage_penalty
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Brak tablicy informacyjnej — kara administracyjna",
    "_legal_basis": "Art. 93 pkt 7 Prawa budowlanego",
    "_warnings": ["[MICRO] Tablica informacyjna: brak tablicy = kara grzywny. Koszt tablicy = KUP"]
} {
    object.get(input.jdg_entrepreneur, "construction_project_type", "") == "REQUIRES_PERMIT"
    object.get(input.jdg_entrepreneur, "construction_signage_installed", false) == false
}

# jdg.micro.budownictwo.a6.r8: budownictwo_a6_r8_construction_documentation_archive
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a6.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Archiwizacja dokumentacji budowlanej — obowiązek przechowywania",
    "_legal_basis": "Art. 86 Ordynacji podatkowej (5 lat), Art. 74 UoR",
    "_warnings": ["[MICRO] Archiwizacja budowlana: dziennik budowy, dokumentacja powykonawcza, protokoły odbiorów = przechowuj min. 5 lat od końca roku podatkowego"]
} {
    object.get(input.jdg_entrepreneur, "construction_completed", false) == true
    object.get(input.jdg_entrepreneur, "construction_docs_archived", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  budownictwo.a7 — VAT 8% na budownictwo mieszkaniowe (12 reguł) P24 L-BUD-1 ║
# ║  Legal basis: Art. 41 ust. 12-12c VAT; limit 300 m2 pow. użytkowej          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.budownictwo.a7.r1: budownictwo_a7_r1_vat8_residential_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r1",
    "package": "jdg.micro.budownictwo",
    "priority": 250051,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% — usługa budowlana dla budownictwa mieszkaniowego (Art. 41 ust. 12 VAT)",
    "_legal_basis": "Art. 41 ust. 12 ustawy o VAT",
    "_warnings": ["[MICRO] VAT 8%: stawka obniżona dla budownictwa mieszkaniowego — budynek mieszkalny, powierzchnia użytkowa <= 300 m2"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "usable_area_m2", 999999) <= 300
    object.get(input.invoice, "service_scope", "") in {"CONSTRUCTION", "RENOVATION", "MODERNIZATION", "THERMOMODERNIZATION"}
}

# jdg.micro.budownictwo.a7.r2: budownictwo_a7_r2_vat23_non_residential
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r2",
    "package": "jdg.micro.budownictwo",
    "priority": 250052,
    "vat_rate": "0.23",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 23% — budynek niemieszkalny (nie spełnia warunków Art. 41 ust. 12 VAT)",
    "_legal_basis": "Art. 41 ust. 1 w zw. z art. 41 ust. 12 VAT",
    "_warnings": ["[MICRO] VAT 23%: budynek niemieszkalny — stawka podstawowa. Sprawdź, czy usługa nie kwalifikuje się do 8%"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "building_type", "") != "RESIDENTIAL"
}

# jdg.micro.budownictwo.a7.r3: budownictwo_a7_r3_vat23_area_exceeded
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r3",
    "package": "jdg.micro.budownictwo",
    "priority": 250053,
    "vat_rate": "0.23",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 23% — powierzchnia użytkowa > 300 m2 (limit Art. 41 ust. 12b VAT przekroczony)",
    "_legal_basis": "Art. 41 ust. 12b VAT — limit 300 m2",
    "_warnings": ["[MICRO] VAT 23%: powierzchnia użytkowa przekracza 300 m2 — stawka 8% NIE ma zastosowania. Całość usługi opodatkowana 23%"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "usable_area_m2", 0) > 300
}

# jdg.micro.budownictwo.a7.r4: budownictwo_a7_r4_vat8_b2c_direct
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r4",
    "package": "jdg.micro.budownictwo",
    "priority": 250054,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% B2C — usługa budowlana dla klienta indywidualnego (budynek mieszkalny <= 300 m2)",
    "_legal_basis": "Art. 41 ust. 12 VAT (B2C)",
    "_warnings": ["[MICRO] VAT 8% B2C: klient niepodatnik — faktura ze stawką 8%, brak reverse charge"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "usable_area_m2", 999999) <= 300
    object.get(input.counterparty, "is_vat_payer", false) == false
}

# jdg.micro.budownictwo.a7.r5: budownictwo_a7_r5_vat8_with_materials
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r5",
    "package": "jdg.micro.budownictwo",
    "priority": 250055,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% — usługa kompleksowa (materiały + robocizna) dla budownictwa mieszkaniowego",
    "_legal_basis": "Art. 41 ust. 12 VAT — usługa kompleksowa",
    "_warnings": ["[MICRO] VAT 8% kompleksowa: materiały w cenie usługi budowlanej — całość opodatkowana 8% (nie rozdzielaj materiałów na osobną fakturę)"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION_WITH_MATERIALS"
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "usable_area_m2", 999999) <= 300
}

# jdg.micro.budownictwo.a7.r6: budownictwo_a7_r6_vat8_social_housing
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r6",
    "package": "jdg.micro.budownictwo",
    "priority": 250056,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% — budownictwo społeczne (Art. 41 ust. 12a VAT: lokale do 150 m2, domy do 300 m2)",
    "_legal_basis": "Art. 41 ust. 12a VAT — budownictwo społeczne",
    "_warnings": ["[MICRO] VAT 8% społeczne: program budownictwa społecznego — stawka obniżona dla lokali mieszkalnych w ramach polityki mieszkaniowej"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "housing_program_type", "") == "SOCIAL_HOUSING"
}

# jdg.micro.budownictwo.a7.r7: budownictwo_a7_r7_vat8_renovation_only
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r7",
    "package": "jdg.micro.budownictwo",
    "priority": 250057,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% — remont budynku mieszkalnego (tylko robocizna, bez materiałów)",
    "_legal_basis": "Art. 41 ust. 12 VAT — remont",
    "_warnings": ["[MICRO] VAT 8% remont: sama robocizna remontowa w budynku mieszkalnym — 8%. Jeśli dokładasz materiały, sprawdź regułę a7.r5"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "service_scope", "") == "RENOVATION"
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "usable_area_m2", 999999) <= 300
}

# jdg.micro.budownictwo.a7.r8: budownictwo_a7_r8_vat8_infrastructure_residential
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r8",
    "package": "jdg.micro.budownictwo",
    "priority": 250058,
    "vat_rate": "0.08",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% — infrastruktura towarzysząca budownictwu mieszkaniowemu (Art. 41 ust. 12c VAT)",
    "_legal_basis": "Art. 41 ust. 12c VAT — infrastruktura towarzysząca",
    "_warnings": ["[MICRO] VAT 8% infrastruktura: przyłącza, garaże, chodniki, place zabaw jako część inwestycji mieszkaniowej — też 8%"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "infrastructure_type", "") in {"PARKING", "GARAGE", "UTILITY_CONNECTION", "PLAYGROUND", "SIDEWALK"}
    object.get(input.invoice, "related_residential_building", false) == true
}

# jdg.micro.budownictwo.a7.r9: budownictwo_a7_r9_vat8_jpk_gtu_marking
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r9",
    "package": "jdg.micro.budownictwo",
    "priority": 250059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_01",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% — obowiązek oznaczenia GTU_01 w JPK_V7 dla usług budowlanych",
    "_legal_basis": "Rozporządzenie MF ws. JPK_V7 — GTU_01",
    "_warnings": ["[MICRO] VAT 8% JPK: oznacz fakturę kodem GTU_01 w JPK_V7 (dostawa towarów i świadczenie usług objętych odwrotnym obciążeniem lub stawką obniżoną)"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "vat_rate_applied", 0) == 0.08
    object.get(input.invoice, "jpk_gtu_marked", false) == false
}

# jdg.micro.budownictwo.a7.r10: budownictwo_a7_r10_vat8_invoice_annotation
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r10",
    "package": "jdg.micro.budownictwo",
    "priority": 250060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "VAT 8% — faktura musi zawierać podstawę prawną stawki obniżonej (Art. 41 ust. 12 VAT)",
    "_legal_basis": "Art. 106e ust. 1 pkt 14 VAT — podstawa prawna stawki obniżonej",
    "_warnings": ["[MICRO] VAT 8% adnotacja: na fakturze ze stawką 8% należy wskazać podstawę prawną: 'Art. 41 ust. 12 ustawy o VAT' — brak adnotacji = wada formalna"]
} {
    object.get(input.invoice, "vat_rate_applied", 0) == 0.08
    object.get(input.invoice, "vat_reduced_rate_annotation", false) == false
}

# jdg.micro.budownictwo.a7.r11: budownictwo_a7_r11_vat8_ksef_invoice
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r11",
    "package": "jdg.micro.budownictwo",
    "priority": 250061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "VAT 8% KSeF — faktura ustrukturyzowana z kodem GTU_01 i stawką 8% wysyłana przez KSeF",
    "_legal_basis": "Art. 106ga VAT — KSeF, Rozporządzenie MF",
    "_warnings": ["[MICRO] VAT 8% KSeF: faktura budowlana ze stawką 8% podlega obowiązkowi KSeF — wyślij przez platformę w ciągu 24h"]
} {
    object.get(input.invoice, "vat_rate_applied", 0) == 0.08
    object.get(input.invoice, "ksef_sent", false) == false
    input.jdg_entrepreneur.is_vat_payer == true
}

# jdg.micro.budownictwo.a7.r12: budownictwo_a7_r12_vat8_material_separate_warning
else := {
    "matched": true,
    "rule_id": "jdg.micro.budownictwo.a7.r12",
    "package": "jdg.micro.budownictwo",
    "priority": 250062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "OSTRZEŻENIE: materiały na osobnej fakturze 23% przy usłudze 8% — ryzyko obejścia prawa (sztuczny podział)",
    "_legal_basis": "Art. 5 ust. 2 VAT (świadczenie złożone), Art. 41 ust. 12 VAT",
    "_warnings": ["[MICRO] UWAGA! Rozdzielasz materiały (23%) od usługi (8%) w tej samej inwestycji mieszkaniowej. Przy usłudze kompleksowej (materiały + robocizna) całość powinna być 8%. Sztuczny podział może być zakwestionowany przez US jako obejście prawa!"]
} {
    object.get(input.invoice, "service_category", "") == "CONSTRUCTION"
    object.get(input.invoice, "materials_only_separate_invoice", false) == true
    object.get(input.invoice, "building_type", "") == "RESIDENTIAL"
    object.get(input.invoice, "usable_area_m2", 999999) <= 300
}
