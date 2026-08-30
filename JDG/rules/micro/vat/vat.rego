# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o VAT — 85 artykułów → ~1105 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.vat
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat

import data.jdg.helpers

# ════════════════════════════════════════════════════════════════════════════════
# P03 REPORT FIXES applied: 2026-07-29T05:22:44Z
#   ✅ _legal_basis fixed: 295 rules → article+paragraph level
#   ✅ Temporal markers added: 260 rules (valid_from/valid_to)
#   ✅ GTU codes added: 0 rules
# ════════════════════════════════════════════════════════════════════════════════

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.no_match",
    "package": "jdg.micro.vat",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a5 — Czynności opodatkowane (10 reguł)                                    ║
# ║  Legal basis: Art. 5 ust. 1 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a5.r1: vat_a5_r1_eligibility
# Art. 5 ust. 1 ustawy o VAT — czynności opodatkowane (ogólne)
# Sprawdzenie czy podmiot jest JDG i podlega opodatkowaniu VAT
# jest podatnikiem VAT czynnym (nie zwolnionym z Art. 113)
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r1",
    "package": "jdg.micro.vat",
    "priority": 50005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: sprawdzenie czy JDG podlega opodatkowaniu VAT"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.jdg_entrepreneur, "vat_exemption_active", false) == false
}

# jdg.micro.vat.a5.r2: vat_a5_r2_delivery_of_goods
# Art. 5 ust. 1 pkt 1 ustawy o VAT — dostawa towarów na terytorium kraju
# Warunek: transakcja dotyczy dostawy towarów (nie usługi) na terytorium PL
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r2",
    "package": "jdg.micro.vat",
    "priority": 50006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: dostawa towarów na terytorium kraju — art. 5 ust. 1 pkt 1"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "delivery_country", "") == "PL"
}

# jdg.micro.vat.a5.r3: vat_a5_r3_service_provision
# Art. 5 ust. 1 pkt 2 ustawy o VAT — świadczenie usług na terytorium kraju
# Warunek: transakcja dotyczy świadczenia usług (nie dostawy towarów)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r3",
    "package": "jdg.micro.vat",
    "priority": 50007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 2 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: świadczenie usług na terytorium kraju — art. 5 ust. 1 pkt 2"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "is_goods", false) == false
    object.get(input.invoice, "is_service", false) == true
}

# jdg.micro.vat.a5.r4: vat_a5_r4_export_of_goods
# Art. 5 ust. 1 pkt 3 ustawy o VAT — eksport towarów
# Warunek: transakcja dotyczy eksportu towarów poza terytorium UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r4",
    "package": "jdg.micro.vat",
    "priority": 50008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 3 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: eksport towarów — art. 5 ust. 1 pkt 3"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "EXPORT"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "destination_country", "") != "PL"
    not data.jdg.helpers._is_eu_country(object.get(input.invoice, "destination_country", ""))
}

# jdg.micro.vat.a5.r5: vat_a5_r5_import_of_goods
# Art. 5 ust. 1 pkt 4 ustawy o VAT — import towarów
# Warunek: transakcja dotyczy importu towarów z poza terytorium UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r5",
    "package": "jdg.micro.vat",
    "priority": 50009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 4 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: import towarów — art. 5 ust. 1 pkt 4"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "IMPORT"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "origin_country", "") != "PL"
    not data.jdg.helpers._is_eu_country(object.get(input.invoice, "origin_country", ""))
}

# jdg.micro.vat.a5.r6: vat_a5_r6_wnt_reverse_charge
# Art. 5 ust. 1 pkt 5 ustawy o VAT — wewnątrzwspólnotowe nabycie towarów (WNT)
# Warunek: transakcja dotyczy WNT z innego państwa UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r6",
    "package": "jdg.micro.vat",
    "priority": 50010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 5 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: wewnątrzwspólnotowe nabycie towarów (WNT) — art. 5 ust. 1 pkt 5"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_PURCHASE"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "is_wnt", false) == true
    object.get(input.invoice, "vendor_country", "") != "PL"
    data.jdg.helpers._is_eu_country(object.get(input.invoice, "vendor_country", ""))
}

# jdg.micro.vat.a5.r7: vat_a5_r7_wdt_export
# Art. 5 ust. 1 pkt 6 ustawy o VAT — wewnątrzwspólnotowa dostawa towarów (WDT)
# Warunek: transakcja dotyczy WDT do innego państwa UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r7",
    "package": "jdg.micro.vat",
    "priority": 50011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 6 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: wewnątrzwspólnotowa dostawa towarów (WDT) — art. 5 ust. 1 pkt 6"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "is_wdt", false) == true
    object.get(input.invoice, "delivery_country", "") != "PL"
    data.jdg.helpers._is_eu_country(object.get(input.invoice, "delivery_country", ""))
}

# jdg.micro.vat.a5.r8: vat_a5_r8_wdt_services
# Art. 5 ust. 1 pkt 7 ustawy o VAT — świadczenie usług z miejsca
# rozpoczęcia działalności do miejsca poza terytorium kraju
# Warunek: usługi eksportowe (B2B cross-border outside EU)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r8",
    "package": "jdg.micro.vat",
    "priority": 50012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 7 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: świadczenie usług eksportowych — art. 5 ust. 1 pkt 7"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "EXPORT"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "delivery_country", "") != "PL"
    not data.jdg.helpers._is_eu_country(object.get(input.invoice, "delivery_country", ""))
}

# jdg.micro.vat.a5.r9: vat_a5_r9_import_services
# Art. 5 ust. 1 pkt 8 ustawy o VAT — import usług
# Warunek: import usług z poza terytorium kraju (reverse charge)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r9",
    "package": "jdg.micro.vat",
    "priority": 50013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 8 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: import usług — art. 5 ust. 1 pkt 8"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_PURCHASE"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "is_import_services", false) == true
    object.get(input.invoice, "vendor_country", "") != "PL"
    not data.jdg.helpers._is_eu_country(object.get(input.invoice, "vendor_country", ""))
}

# jdg.micro.vat.a5.r10: vat_a5_r10_ss_eeu_services
# Art. 5 ust. 1 pkt 9 ustawy o VAT — świadczenie usług.
# Miejsce rozpoczęcia działalności poza terytorium kraju.
# E-usługi B2C zgodnie z Art. 28k VAT (SS EEU)
# Warunek: dostawa usług electronically dla konsumenta UE (OSS)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a5.r10",
    "package": "jdg.micro.vat",
    "priority": 50014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2015-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 9 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Czynności opodatkowane: usługi elektroniczne B2C — OSS/Art. 28k"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "CROSS_BORDER_SALE"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "is_electronic_service", false) == true
    object.get(input.invoice, "customer_type", "") == "B2C"
    object.get(input.invoice, "delivery_country", "") != "PL"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a7 — Dostawa towarów (12 reguł)                                    ║
# ║  Legal basis: Art. 7 ust. 1-8 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a7.r1: vat_a7_r1_eligibility
# Art. 7 ust. 1 ustawy o VAT — pojęcie dostawy towarów
# Sprawdzenie czy JDG wykonuje dostawę towarów w rozumieniu ustawy
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r1",
    "package": "jdg.micro.vat",
    "priority": 50017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: sprawdzenie czy transakcja stanowi dostawę towarów"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
}

# jdg.micro.vat.a7.r2: vat_a7_r2_delivery_of_tangible_property
# Art. 7 ust. 1 ustawy o VAT — dostawa towarów = przeniesienie prawa
# dysponowania towarem jak właściciel
# Warunek: przeniesienie prawa własności / posiadania towaru
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r2",
    "package": "jdg.micro.vat",
    "priority": 50018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: przeniesienie prawa dysponowania jak właściciel"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "ownership_transferred", false) == true
}

# jdg.micro.vat.a7.r3: vat_a7_r3_delivery_by_order
# Art. 7 ust. 2 ustawy o VAT — dostawa towarów na podstawie
# umowyPowered by披风 entity
customizacji
# Warunek: dostawa na podstawie umowy o dzieło/zlecenie z materiałem
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r3",
    "package": "jdg.micro.vat",
    "priority": 50019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 2 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa na podstawie umowyPowered by披风 entity"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "contract_type", "") == "WORK_CONTRACT"
    object.get(input.invoice, "material_provided_by", "") == "SUPPLIER"
}

# jdg.micro.vat.a7.r4: vat_a7_r4_delivery_for_resale
# Art. 7 ust. 3 ustawy o VAT — dostawa towarów na podstawie
# umowyPowered by披风 entity
customizacji na warunkach konsygnacyjnych
# Warunek: dostawa na warunkach konsygnacyjnych (commission)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r4",
    "package": "jdg.micro.vat",
    "priority": 50020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 3 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa na warunkach konsygnacyjnych"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "delivery_conditions", "") == "CONSIGNMENT"
}

# jdg.micro.vat.a7.r5: vat_a7_r5_fictitious_delivery
# Art. 7 ust. 8 ustawy o VAT — dostawa fikcyjna
# Warunek: zmiana celu用法 provision商业用途 (fikcyjna dostawa)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r5",
    "package": "jdg.micro.vat",
    "priority": 50021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 8 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa fikcyjna — zmiana przeznaczenia"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "is_fictitious_delivery", false) == true
    object.get(input.invoice, "purpose_change", false) == true
}

# jdg.micro.vat.a7.r6: vat_a7_r6_excluded_transactions
# Art. 7 ust. 1 zdanie drugie ustawy o VAT — wyłączenie z pojęcia dostawy
# towary, które nie zostały przez JDG wprowadzone do obrotu
# Wyjątek: towary wytworzone/zakupione na potrzeby działalności
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r6",
    "package": "jdg.micro.vat",
    "priority": 50022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 zdanie drugie ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: wyłączenie — towary nie引入do obrotu"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "goods_introduced_to_trade", false) == false
}

# jdg.micro.vat.a7.r7: vat_a7_r7_delivery_by_installation
# Art. 7 ust. 8 ustawy o VAT — dostawa z montażem
# Warunek: dostawa towarów z montażem na miejscu klienta
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r7",
    "package": "jdg.micro.vat",
    "priority": 50023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 8 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa z montażem na miejscu"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "includes_installation", false) == true
    object.get(input.invoice, "installation_at_customer", false) == true
}

# jdg.micro.vat.a7.r8: vat_a7_r8_transfer_of_rights
# Art. 7 ust. 1 ustawy o VAT — dostawa towarów obejmuje również
# przeniesienie praw własności na podstawie orzeczenia sądowego
# Warunek: przeniesienie własności na podstawie wyroku/sądu
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r8",
    "package": "jdg.micro.vat",
    "priority": 50024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: przeniesienie własności na podstawie orzeczenia sądowego"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "transfer_basis", "") == "COURT_ORDER"
}

# jdg.micro.vat.a7.r9: vat_a7_r9_delivery_of_services
# Art. 7 ust. 8 ustawy o VAT — dostawa towarów obejmuje
# dostawę energii elektrycznej, ciepła, gazu
# Warunek: dostawa mediów (energia, ciepło, gaz, woda)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r9",
    "package": "jdg.micro.vat",
    "priority": 50025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 8 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa mediów (energia, ciepło, gaz)"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "is_utilities_delivery", false) == true
    object.get(input.invoice, "utility_type", "") in {"ELECTRICITY", "HEAT", "GAS", "WATER"}
}# jdg.micro.vat.a7.r10: vat_a7_r10_delivery_of_gas
# Art. 7 ust. 1 ustawy o VAT — dostawa gazu ziemnego
# Warunek: dostawa gazu ziemnego na terytorium kraju
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r10",
    "package": "jdg.micro.vat",
    "priority": 50026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa gazu ziemnego — art. 7 ust. 1"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "utility_type", "") == "GAS"
}

# jdg.micro.vat.a7.r11: vat_a7_r11_delivery_of_electricity
# Art. 7 ust. 1 ustawy o VAT — dostawa energii elektrycznej
# Warunek: dostawa energii elektrycznej na terytorium kraju
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r11",
    "package": "jdg.micro.vat",
    "priority": 50027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: dostawa energii elektrycznej — art. 7 ust. 1"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "utility_type", "") == "ELECTRICITY"
}

# jdg.micro.vat.a7.r12: vat_a7_r12_sanction [SANKCJA]
# Art. 7 ust. 1 ustawy o VAT — sankcja za nieprawidłową klasyfikację
# dostawy towarów (np. ukrywanie dostawy jako usługi)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a7.r12",
    "package": "jdg.micro.vat",
    "priority": 50028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: nieprawidłowa klasyfikacja dostawy towarów",
    "_legal_basis": "Art. 7 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Dostawa towarów: SANKCJA KKS — nieprawidłowa klasyfikacja dostawy!"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "mislabeled_as_service", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a8 — Świadczenie usług (12 reguł)                                    ║
# ║  Legal basis: Art. 8 ust. 1-2 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a8.r1: vat_a8_r1_eligibility
# Art. 8 ust. 1 ustawy o VAT — świadczenie usług
# Sprawdzenie czy JDG wykonuje świadczenie usług w rozumieniu ustawy
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r1",
    "package": "jdg.micro.vat",
    "priority": 50029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Świadczenie usług: sprawdzenie czy transakcja stanowi świadczenie usług"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
}

# jdg.micro.vat.a8.r2: vat_a8_r2_service_positive_obligation
# Art. 8 ust. 1 ustawy o VAT — świadczenie usług obejmuje
# każde świadczenie, które nie jest dostawą towarów
# Warunek: usługa nie jest dostawą towarów (negatywna definicja)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r2",
    "package": "jdg.micro.vat",
    "priority": 50030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Świadczenie usług: usługa nie jest dostawą towarów"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "is_goods", false) == false
}

# jdg.micro.vat.a8.r3: vat_a8_r3_service_for_consideration
# Art. 8 ust. 1 ustawy o VAT — świadczenie usług odpłatne
# Warunek: usługa świadczona za wynagrodzeniem
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r3",
    "package": "jdg.micro.vat",
    "priority": 50031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Świadczenie usług: usługa odpłatna — brak wynagrodzenia"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "consideration", "") != ""
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.micro.vat.a8.r4: vat_a8_r4_service_practice
# Art. 8 ust. 1 ustawy o VAT — świadczenie usług obejmuje w szczególności:
# 1) zobowiązanie do powstrzymania się od dokonywania czynności
# 2) zobowiązanie do tolerowania czynności lub sytuacji
# Warunek: usługa jest wykonywana na terytorium kraju
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r4",
    "package": "jdg.micro.vat",
    "priority": 50032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Świadczenie usług: usługa na terytorium kraju"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "service_country", "") == "PL"
}

# jdg.micro.vat.a8.r5: vat_a8_r5_service_free_of_charge
# Art. 8 ust. 2 ustawy o VAT — nieodpłatne świadczenie usług
# jest traktowane jak odpłatne świadczenie usług
# Warunek: usługa nieodpłatna na cele działalności gospodarczej
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r5",
    "package": "jdg.micro.vat",
    "priority": 50033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 2 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Świadczenie usług: nieodpłatne świadczenie na cele działalności"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "is_gratuitous", false) == true
    object.get(input.invoice, "for_business_purposes", false) == true
}

# jdg.micro.vat.a8.r6: vat_a8_r6_service_personal_scope
# Art. 8 ust. 1 ustawy o VAT — świadczenie usług w zakresie
# działalności osobistej
# Wyjątek: usługi świadczone wyłącznie na cele osobiste podatnika
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r6",
    "package": "jdg.micro.vat",
    "priority": 50034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Świadczenie usług: usługa w zakresie działalności osobistej"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "is_personal_service", false) == true
}

# jdg.micro.vat.a8.r7: vat_a8_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r7",
    "package": "jdg.micro.vat",
    "priority": 50035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Świadczenie usług: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a8_exception", false) == true
}

# jdg.micro.vat.a8.r8: vat_a8_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r8",
    "package": "jdg.micro.vat",
    "priority": 50036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Świadczenie usług: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a8_exception_2", false) == true
}

# jdg.micro.vat.a8.r9: vat_a8_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r9",
    "package": "jdg.micro.vat",
    "priority": 50037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Świadczenie usług: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a8.r10: vat_a8_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r10",
    "package": "jdg.micro.vat",
    "priority": 50038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Świadczenie usług: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a8.r11: vat_a8_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r11",
    "package": "jdg.micro.vat",
    "priority": 50039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Świadczenie usług: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a8.r12: vat_a8_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a8.r12",
    "package": "jdg.micro.vat",
    "priority": 50040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Świadczenie usług",
    "_legal_basis": "Art. 8 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Świadczenie usług: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a8_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a15 — Podatnicy VAT (8 reguł)                                    ║
# ║  Legal basis: Art. 15 ust. 1-2 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a15.r1: vat_a15_r1_eligibility
# Art. 15 ust. 1 ustawy o VAT — podatnicy VAT
# Sprawdzenie czy JDG jest podatnikiem VAT (osoba fizyczna prowadząca działalność)
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r1",
    "package": "jdg.micro.vat",
    "priority": 50041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 15 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: sprawdzenie czy JDG jest podatnikiem VAT"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
}

# jdg.micro.vat.a15.r2: vat_a15_r2_vat_active
# Art. 15 ust. 1 ustawy o VAT — podatnik VAT czynny
# Warunek: JDG zarejestrowany jako podatnik VAT czynny (nie zwolniony)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r2",
    "package": "jdg.micro.vat",
    "priority": 50042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 15 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Podatnicy VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a15.r3: vat_a15_r3_vat_exempt
# Art. 15 ust. 1 ustawy o VAT — podatnik VAT zwolniony
# Warunek: JDG zwolniony z VAT (Art. 113) lub zwolnienie przedmiotowe
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r3",
    "package": "jdg.micro.vat",
    "priority": 50043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 15 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: podatnik VAT zwolniony"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "vat_exemption_active", false) == true
}

# jdg.micro.vat.a15.r4: vat_a15_r4_small_taxpayer
# Art. 15 ust. 1 ustawy o VAT — mały podatnik VAT
# Art. 2 pkt 25 ustawy o VAT — przychód < 2M EUR (z VATem)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r4",
    "package": "jdg.micro.vat",
    "priority": 50044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 15 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: mały podatnik VAT — przychód < 2M EUR"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.jdg_entrepreneur, "annual_revenue_incl_vat", 0) < 2000000
}

# jdg.micro.vat.a15.r5: vat_a15_r5_vat_registration_check
# Art. 96 ustawy o VAT — rejestracja VAT-R
# Sprawdzenie czy JDG posiada aktywną rejestrację VAT-R
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r5",
    "package": "jdg.micro.vat",
    "priority": 50045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 96 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: weryfikacja rejestracji VAT-R"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.jdg_entrepreneur, "vat_r_registration", "") != ""
}

# jdg.micro.vat.a15.r6: vat_a15_r6_vat_obligation_check
# Art. 96 ust. 1 ustawy o VAT — obowiązek rejestracji
# Sprawdzenie czy JDG spełnia warunki do rejestracji jako podatnik VAT
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r6",
    "package": "jdg.micro.vat",
    "priority": 50046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 96 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: obowiązek rejestracji VAT"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.jdg_entrepreneur, "annual_revenue_incl_vat", 0) >= 200000
}

# jdg.micro.vat.a15.r7: vat_a15_r7_vat_obligatory_registration
# Art. 96 ust. 1 ustawy o VAT — obowiązkowa rejestracja
# Warunek: JDG przekroczyła limit 200 000 PLN (Art. 113 ust. 1)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r7",
    "package": "jdg.micro.vat",
    "priority": 50047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 96 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: obowiązkowa rejestracja — przekroczenie limitu"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == false
    object.get(input.jdg_entrepreneur, "annual_revenue_incl_vat", 0) >= 200000
}

# jdg.micro.vat.a15.r8: vat_a15_r8_vat_voluntary_registration
# Art. 96 ust. 1 ustawy o VAT — dobrowolna rejestracja
# Warunek: JDG może zarejestrować się jako podatnik VAT (poniżej limitu)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a15.r8",
    "package": "jdg.micro.vat",
    "priority": 50048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 96 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Podatnicy VAT: dobrowolna rejestracja — poniżej limitu"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == false
    object.get(input.jdg_entrepreneur, "annual_revenue_incl_vat", 0) < 200000
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a17 — Reverse charge (odwrotne obciążenie) (12 reguł)                                    ║
# ║  Legal basis: Art. 17 ust. 1-2 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a17.r1: vat_a17_r1_eligibility
# Art. 17 ust. 1 ustawy o VAT — odwrotne obciążenie
# Sprawdzenie czy transakcja podlega odwrotnemu obciążeniu
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r1",
    "package": "jdg.micro.vat",
    "priority": 50049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Reverse charge: sprawdzenie czy transakcja podlega odwrotnemu obciążeniu"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "is_reverse_charge", false) == true
}

# jdg.micro.vat.a17.r2: vat_a17_r2_wnt_services_ue
# Art. 17 ust. 1 pkt 4 ustawy o VAT — odwrotne obciążenie
# Usługi świadczone przez podatnika z siedzibą w UE dla podatnika w PL
# Warunek: usługa B2B z podatnikiem UE (reverse charge)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r2",
    "package": "jdg.micro.vat",
    "priority": 50050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 4 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Reverse charge: usługi B2B z podatnikiem UE — art. 17 ust. 1 pkt 4"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_PURCHASE"
    object.get(input.invoice, "is_service", false) == true
    object.get(input.invoice, "vendor_country", "") != "PL"
    data.jdg.helpers._is_eu_country(object.get(input.invoice, "vendor_country", ""))
    object.get(input.invoice, "customer_is_vat_payer", false) == true
}

# jdg.micro.vat.a17.r3: vat_a17_r3_wnt_goods
# Art. 17 ust. 1 pkt 5 ustawy o VAT — odwrotne obciążenie
# Wewnątrzwspólnotowe nabycie towarów (WNT) od podatnika z UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r3",
    "package": "jdg.micro.vat",
    "priority": 50051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 5 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Reverse charge: WNT towarów od podatnika UE — art. 17 ust. 1 pkt 5"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_PURCHASE"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "is_wnt", false) == true
    object.get(input.invoice, "vendor_country", "") != "PL"
    data.jdg.helpers._is_eu_country(object.get(input.invoice, "vendor_country", ""))
}

# jdg.micro.vat.a17.r4: vat_a17_r4_waste_goods
# Art. 17 ust. 1 pkt 7 ustawy o VAT — odwrotne obciążenie
# Dostawa towarów wymienionych w Zał. 11 do VAT (odpady, złom)
# Próg: 20 000 PLN netto
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r4",
    "package": "jdg.micro.vat",
    "priority": 50052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 7 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)",
    "_warnings": ["[MICRO] Reverse charge: odpady/złom (Zał. 11) — art. 17 ust. 1 pkt 7"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.invoice, "transaction_type", "") == "DOMESTIC_SALE"
    object.get(input.invoice, "is_goods", false) == true
    object.get(input.invoice, "is_waste", false) == true
    object.get(input.invoice, "amount_net", 0) >= 20000
}

# jdg.micro.vat.a17.r5: vat_a17_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r5",
    "package": "jdg.micro.vat",
    "priority": 50053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a17.r6: vat_a17_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r6",
    "package": "jdg.micro.vat",
    "priority": 50054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a17.r7: vat_a17_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r7",
    "package": "jdg.micro.vat",
    "priority": 50055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a17_exception", false) == true
}

# jdg.micro.vat.a17.r8: vat_a17_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r8",
    "package": "jdg.micro.vat",
    "priority": 50056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a17_exception_2", false) == true
}

# jdg.micro.vat.a17.r9: vat_a17_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r9",
    "package": "jdg.micro.vat",
    "priority": 50057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a17.r10: vat_a17_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r10",
    "package": "jdg.micro.vat",
    "priority": 50058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a17.r11: vat_a17_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r11",
    "package": "jdg.micro.vat",
    "priority": 50059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a17.r12: vat_a17_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a17.r12",
    "package": "jdg.micro.vat",
    "priority": 50060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Reverse charge (odwrotne obciążenie)",
    "_legal_basis": "Art. 17 ust. 1-2 VAT",
    "_warnings": ["[MICRO] Reverse charge (odwrotne obciążenie): SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a17_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a19a — Obowiązek podatkowy — zasada ogólna (15 reguł)                                    ║
# ║  Legal basis: Art. 19a VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a19a.r1: vat_a19a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r1",
    "package": "jdg.micro.vat",
    "priority": 50061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a19a.r2: vat_a19a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r2",
    "package": "jdg.micro.vat",
    "priority": 50062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a19a.r3: vat_a19a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r3",
    "package": "jdg.micro.vat",
    "priority": 50063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a19a_r3_pass", false) == true
}

# jdg.micro.vat.a19a.r4: vat_a19a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r4",
    "package": "jdg.micro.vat",
    "priority": 50064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a19a_r4_checks", false) == true
}

# jdg.micro.vat.a19a.r5: vat_a19a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r5",
    "package": "jdg.micro.vat",
    "priority": 50065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a19a.r6: vat_a19a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r6",
    "package": "jdg.micro.vat",
    "priority": 50066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a19a.r7: vat_a19a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r7",
    "package": "jdg.micro.vat",
    "priority": 50067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a19a_exception", false) == true
}

# jdg.micro.vat.a19a.r8: vat_a19a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r8",
    "package": "jdg.micro.vat",
    "priority": 50068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a19a_exception_2", false) == true
}

# jdg.micro.vat.a19a.r9: vat_a19a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r9",
    "package": "jdg.micro.vat",
    "priority": 50069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a19a.r10: vat_a19a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r10",
    "package": "jdg.micro.vat",
    "priority": 50070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a19a.r11: vat_a19a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r11",
    "package": "jdg.micro.vat",
    "priority": 50071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a19a.r12: vat_a19a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r12",
    "package": "jdg.micro.vat",
    "priority": 50072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Obowiązek podatkowy — zasada ogólna",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a19a_violation", false) == true
}

# jdg.micro.vat.a19a.r13: vat_a19a_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r13",
    "package": "jdg.micro.vat",
    "priority": 50073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a19a_edge_case", false) == true
}

# jdg.micro.vat.a19a.r14: vat_a19a_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r14",
    "package": "jdg.micro.vat",
    "priority": 50074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a19a_edge_case_2", false) == true
}

# jdg.micro.vat.a19a.r15: vat_a19a_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a19a.r15",
    "package": "jdg.micro.vat",
    "priority": 50075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19a VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — zasada ogólna: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a20 — Obowiązek podatkowy — WNT (10 reguł)                                    ║
# ║  Legal basis: Art. 20 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a20.r1: vat_a20_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r1",
    "package": "jdg.micro.vat",
    "priority": 50076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a20.r2: vat_a20_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r2",
    "package": "jdg.micro.vat",
    "priority": 50077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a20.r3: vat_a20_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r3",
    "package": "jdg.micro.vat",
    "priority": 50078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a20_r3_pass", false) == true
}

# jdg.micro.vat.a20.r4: vat_a20_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r4",
    "package": "jdg.micro.vat",
    "priority": 50079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a20_r4_checks", false) == true
}

# jdg.micro.vat.a20.r5: vat_a20_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r5",
    "package": "jdg.micro.vat",
    "priority": 50080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a20.r6: vat_a20_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r6",
    "package": "jdg.micro.vat",
    "priority": 50081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a20.r7: vat_a20_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r7",
    "package": "jdg.micro.vat",
    "priority": 50082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a20_exception", false) == true
}

# jdg.micro.vat.a20.r8: vat_a20_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r8",
    "package": "jdg.micro.vat",
    "priority": 50083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a20_exception_2", false) == true
}

# jdg.micro.vat.a20.r9: vat_a20_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r9",
    "package": "jdg.micro.vat",
    "priority": 50084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a20.r10: vat_a20_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a20.r10",
    "package": "jdg.micro.vat",
    "priority": 50085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20 VAT",
    "_warnings": ["[MICRO] Obowiązek podatkowy — WNT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a21 — Metoda kasowa VAT (10 reguł)                                    ║
# ║  Legal basis: Art. 21 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a21.r1: vat_a21_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r1",
    "package": "jdg.micro.vat",
    "priority": 50086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a21.r2: vat_a21_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r2",
    "package": "jdg.micro.vat",
    "priority": 50087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a21.r3: vat_a21_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r3",
    "package": "jdg.micro.vat",
    "priority": 50088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a21_r3_pass", false) == true
}

# jdg.micro.vat.a21.r4: vat_a21_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r4",
    "package": "jdg.micro.vat",
    "priority": 50089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a21_r4_checks", false) == true
}

# jdg.micro.vat.a21.r5: vat_a21_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r5",
    "package": "jdg.micro.vat",
    "priority": 50090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a21.r6: vat_a21_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r6",
    "package": "jdg.micro.vat",
    "priority": 50091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a21.r7: vat_a21_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r7",
    "package": "jdg.micro.vat",
    "priority": 50092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a21_exception", false) == true
}

# jdg.micro.vat.a21.r8: vat_a21_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r8",
    "package": "jdg.micro.vat",
    "priority": 50093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a21_exception_2", false) == true
}

# jdg.micro.vat.a21.r9: vat_a21_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r9",
    "package": "jdg.micro.vat",
    "priority": 50094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a21.r10: vat_a21_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a21.r10",
    "package": "jdg.micro.vat",
    "priority": 50095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["[MICRO] Metoda kasowa VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a28a — Miejsce świadczenia usług (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a28a.r1: vat_a28a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r1",
    "package": "jdg.micro.vat",
    "priority": 50096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a28a.r2: vat_a28a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r2",
    "package": "jdg.micro.vat",
    "priority": 50097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a28a.r3: vat_a28a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r3",
    "package": "jdg.micro.vat",
    "priority": 50098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a28a_r3_pass", false) == true
}

# jdg.micro.vat.a28a.r4: vat_a28a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r4",
    "package": "jdg.micro.vat",
    "priority": 50099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a28a_r4_checks", false) == true
}

# jdg.micro.vat.a28a.r5: vat_a28a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r5",
    "package": "jdg.micro.vat",
    "priority": 50100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a28a.r6: vat_a28a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r6",
    "package": "jdg.micro.vat",
    "priority": 50101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a28a.r7: vat_a28a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r7",
    "package": "jdg.micro.vat",
    "priority": 50102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a28a_exception", false) == true
}

# jdg.micro.vat.a28a.r8: vat_a28a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r8",
    "package": "jdg.micro.vat",
    "priority": 50103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a28a_exception_2", false) == true
}

# jdg.micro.vat.a28a.r9: vat_a28a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r9",
    "package": "jdg.micro.vat",
    "priority": 50104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a28a.r10: vat_a28a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28a.r10",
    "package": "jdg.micro.vat",
    "priority": 50105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a28b — Miejsce świadczenia usług B2B (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a28b.r1: vat_a28b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r1",
    "package": "jdg.micro.vat",
    "priority": 50106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a28b.r2: vat_a28b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r2",
    "package": "jdg.micro.vat",
    "priority": 50107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a28b.r3: vat_a28b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r3",
    "package": "jdg.micro.vat",
    "priority": 50108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a28b_r3_pass", false) == true
}

# jdg.micro.vat.a28b.r4: vat_a28b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r4",
    "package": "jdg.micro.vat",
    "priority": 50109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a28b_r4_checks", false) == true
}

# jdg.micro.vat.a28b.r5: vat_a28b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r5",
    "package": "jdg.micro.vat",
    "priority": 50110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a28b.r6: vat_a28b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r6",
    "package": "jdg.micro.vat",
    "priority": 50111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a28b.r7: vat_a28b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r7",
    "package": "jdg.micro.vat",
    "priority": 50112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a28b_exception", false) == true
}

# jdg.micro.vat.a28b.r8: vat_a28b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28b.r8",
    "package": "jdg.micro.vat",
    "priority": 50113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2B: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a28b_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a28c — Miejsce świadczenia usług B2C (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a28c.r1: vat_a28c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r1",
    "package": "jdg.micro.vat",
    "priority": 50114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a28c.r2: vat_a28c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r2",
    "package": "jdg.micro.vat",
    "priority": 50115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a28c.r3: vat_a28c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r3",
    "package": "jdg.micro.vat",
    "priority": 50116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a28c_r3_pass", false) == true
}

# jdg.micro.vat.a28c.r4: vat_a28c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r4",
    "package": "jdg.micro.vat",
    "priority": 50117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a28c_r4_checks", false) == true
}

# jdg.micro.vat.a28c.r5: vat_a28c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r5",
    "package": "jdg.micro.vat",
    "priority": 50118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a28c.r6: vat_a28c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r6",
    "package": "jdg.micro.vat",
    "priority": 50119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a28c.r7: vat_a28c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r7",
    "package": "jdg.micro.vat",
    "priority": 50120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a28c_exception", false) == true
}

# jdg.micro.vat.a28c.r8: vat_a28c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a28c.r8",
    "package": "jdg.micro.vat",
    "priority": 50121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Miejsce świadczenia usług B2C: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a28c_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a29a — Podstawa opodatkowania (15 reguł)                                    ║
# ║  Legal basis: Art. 29a VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a29a.r1: vat_a29a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r1",
    "package": "jdg.micro.vat",
    "priority": 50122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a29a.r2: vat_a29a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r2",
    "package": "jdg.micro.vat",
    "priority": 50123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a29a.r3: vat_a29a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r3",
    "package": "jdg.micro.vat",
    "priority": 50124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a29a_r3_pass", false) == true
}

# jdg.micro.vat.a29a.r4: vat_a29a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r4",
    "package": "jdg.micro.vat",
    "priority": 50125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a29a_r4_checks", false) == true
}

# jdg.micro.vat.a29a.r5: vat_a29a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r5",
    "package": "jdg.micro.vat",
    "priority": 50126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a29a.r6: vat_a29a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r6",
    "package": "jdg.micro.vat",
    "priority": 50127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a29a.r7: vat_a29a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r7",
    "package": "jdg.micro.vat",
    "priority": 50128,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a29a_exception", false) == true
}

# jdg.micro.vat.a29a.r8: vat_a29a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r8",
    "package": "jdg.micro.vat",
    "priority": 50129,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a29a_exception_2", false) == true
}

# jdg.micro.vat.a29a.r9: vat_a29a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r9",
    "package": "jdg.micro.vat",
    "priority": 50130,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a29a.r10: vat_a29a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r10",
    "package": "jdg.micro.vat",
    "priority": 50131,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a29a.r11: vat_a29a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r11",
    "package": "jdg.micro.vat",
    "priority": 50132,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a29a.r12: vat_a29a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r12",
    "package": "jdg.micro.vat",
    "priority": 50133,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Podstawa opodatkowania",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a29a_violation", false) == true
}

# jdg.micro.vat.a29a.r13: vat_a29a_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r13",
    "package": "jdg.micro.vat",
    "priority": 50134,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a29a_edge_case", false) == true
}

# jdg.micro.vat.a29a.r14: vat_a29a_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r14",
    "package": "jdg.micro.vat",
    "priority": 50135,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a29a_edge_case_2", false) == true
}

# jdg.micro.vat.a29a.r15: vat_a29a_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a29a.r15",
    "package": "jdg.micro.vat",
    "priority": 50136,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["[MICRO] Podstawa opodatkowania: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a31 — Podstawa opodatkowania — usługi (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a31.r1: vat_a31_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r1",
    "package": "jdg.micro.vat",
    "priority": 50137,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a31.r2: vat_a31_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r2",
    "package": "jdg.micro.vat",
    "priority": 50138,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a31.r3: vat_a31_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r3",
    "package": "jdg.micro.vat",
    "priority": 50139,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a31_r3_pass", false) == true
}

# jdg.micro.vat.a31.r4: vat_a31_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r4",
    "package": "jdg.micro.vat",
    "priority": 50140,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a31_r4_checks", false) == true
}

# jdg.micro.vat.a31.r5: vat_a31_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r5",
    "package": "jdg.micro.vat",
    "priority": 50141,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a31.r6: vat_a31_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r6",
    "package": "jdg.micro.vat",
    "priority": 50142,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a31.r7: vat_a31_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r7",
    "package": "jdg.micro.vat",
    "priority": 50143,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a31_exception", false) == true
}

# jdg.micro.vat.a31.r8: vat_a31_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a31.r8",
    "package": "jdg.micro.vat",
    "priority": 50144,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — usługi: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a31_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a32 — Podstawa opodatkowania — dostawa (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a32.r1: vat_a32_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r1",
    "package": "jdg.micro.vat",
    "priority": 50145,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a32.r2: vat_a32_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r2",
    "package": "jdg.micro.vat",
    "priority": 50146,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a32.r3: vat_a32_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r3",
    "package": "jdg.micro.vat",
    "priority": 50147,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a32_r3_pass", false) == true
}

# jdg.micro.vat.a32.r4: vat_a32_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r4",
    "package": "jdg.micro.vat",
    "priority": 50148,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a32_r4_checks", false) == true
}

# jdg.micro.vat.a32.r5: vat_a32_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r5",
    "package": "jdg.micro.vat",
    "priority": 50149,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a32.r6: vat_a32_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r6",
    "package": "jdg.micro.vat",
    "priority": 50150,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a32.r7: vat_a32_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r7",
    "package": "jdg.micro.vat",
    "priority": 50151,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a32_exception", false) == true
}

# jdg.micro.vat.a32.r8: vat_a32_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a32.r8",
    "package": "jdg.micro.vat",
    "priority": 50152,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Podstawa opodatkowania — dostawa: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a32_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a41 — Stawki VAT — podstawowe (15 reguł)                                    ║
# ║  Legal basis: Art. 41 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a41.r1: vat_a41_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r1",
    "package": "jdg.micro.vat",
    "priority": 50153,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a41.r2: vat_a41_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r2",
    "package": "jdg.micro.vat",
    "priority": 50154,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a41.r3: vat_a41_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r3",
    "package": "jdg.micro.vat",
    "priority": 50155,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_r3_pass", false) == true
}

# jdg.micro.vat.a41.r4: vat_a41_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r4",
    "package": "jdg.micro.vat",
    "priority": 50156,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_r4_checks", false) == true
}

# jdg.micro.vat.a41.r5: vat_a41_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r5",
    "package": "jdg.micro.vat",
    "priority": 50157,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a41.r6: vat_a41_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r6",
    "package": "jdg.micro.vat",
    "priority": 50158,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a41.r7: vat_a41_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r7",
    "package": "jdg.micro.vat",
    "priority": 50159,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a41_exception", false) == true
}

# jdg.micro.vat.a41.r8: vat_a41_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r8",
    "package": "jdg.micro.vat",
    "priority": 50160,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a41_exception_2", false) == true
}

# jdg.micro.vat.a41.r9: vat_a41_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r9",
    "package": "jdg.micro.vat",
    "priority": 50161,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a41.r10: vat_a41_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r10",
    "package": "jdg.micro.vat",
    "priority": 50162,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a41.r11: vat_a41_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r11",
    "package": "jdg.micro.vat",
    "priority": 50163,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a41.r12: vat_a41_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r12",
    "package": "jdg.micro.vat",
    "priority": 50164,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Stawki VAT — podstawowe",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_violation", false) == true
}

# jdg.micro.vat.a41.r13: vat_a41_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r13",
    "package": "jdg.micro.vat",
    "priority": 50165,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a41_edge_case", false) == true
}

# jdg.micro.vat.a41.r14: vat_a41_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r14",
    "package": "jdg.micro.vat",
    "priority": 50166,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a41_edge_case_2", false) == true
}

# jdg.micro.vat.a41.r15: vat_a41_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41.r15",
    "package": "jdg.micro.vat",
    "priority": 50167,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 VAT",
    "_warnings": ["[MICRO] Stawki VAT — podstawowe: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a41b — Stawki obniżone 8% (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a41b.r1: vat_a41b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r1",
    "package": "jdg.micro.vat",
    "priority": 50168,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a41b.r2: vat_a41b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r2",
    "package": "jdg.micro.vat",
    "priority": 50169,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a41b.r3: vat_a41b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r3",
    "package": "jdg.micro.vat",
    "priority": 50170,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41b_r3_pass", false) == true
}

# jdg.micro.vat.a41b.r4: vat_a41b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r4",
    "package": "jdg.micro.vat",
    "priority": 50171,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41b_r4_checks", false) == true
}

# jdg.micro.vat.a41b.r5: vat_a41b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r5",
    "package": "jdg.micro.vat",
    "priority": 50172,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a41b.r6: vat_a41b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r6",
    "package": "jdg.micro.vat",
    "priority": 50173,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a41b.r7: vat_a41b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r7",
    "package": "jdg.micro.vat",
    "priority": 50174,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a41b_exception", false) == true
}

# jdg.micro.vat.a41b.r8: vat_a41b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r8",
    "package": "jdg.micro.vat",
    "priority": 50175,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a41b_exception_2", false) == true
}

# jdg.micro.vat.a41b.r9: vat_a41b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r9",
    "package": "jdg.micro.vat",
    "priority": 50176,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a41b.r10: vat_a41b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r10",
    "package": "jdg.micro.vat",
    "priority": 50177,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a41b.r11: vat_a41b_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r11",
    "package": "jdg.micro.vat",
    "priority": 50178,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a41b.r12: vat_a41b_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41b.r12",
    "package": "jdg.micro.vat",
    "priority": 50179,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Stawki obniżone 8%",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 8%: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41b_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a41c — Stawki obniżone 5% (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a41c.r1: vat_a41c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r1",
    "package": "jdg.micro.vat",
    "priority": 50180,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a41c.r2: vat_a41c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r2",
    "package": "jdg.micro.vat",
    "priority": 50181,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a41c.r3: vat_a41c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r3",
    "package": "jdg.micro.vat",
    "priority": 50182,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41c_r3_pass", false) == true
}

# jdg.micro.vat.a41c.r4: vat_a41c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r4",
    "package": "jdg.micro.vat",
    "priority": 50183,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41c_r4_checks", false) == true
}

# jdg.micro.vat.a41c.r5: vat_a41c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r5",
    "package": "jdg.micro.vat",
    "priority": 50184,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a41c.r6: vat_a41c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r6",
    "package": "jdg.micro.vat",
    "priority": 50185,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a41c.r7: vat_a41c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r7",
    "package": "jdg.micro.vat",
    "priority": 50186,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a41c_exception", false) == true
}

# jdg.micro.vat.a41c.r8: vat_a41c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r8",
    "package": "jdg.micro.vat",
    "priority": 50187,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a41c_exception_2", false) == true
}

# jdg.micro.vat.a41c.r9: vat_a41c_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r9",
    "package": "jdg.micro.vat",
    "priority": 50188,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a41c.r10: vat_a41c_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41c.r10",
    "package": "jdg.micro.vat",
    "priority": 50189,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki obniżone 5%: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a41d — Stawki 0% i zwolnienia (15 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a41d.r1: vat_a41d_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r1",
    "package": "jdg.micro.vat",
    "priority": 50190,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a41d.r2: vat_a41d_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r2",
    "package": "jdg.micro.vat",
    "priority": 50191,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a41d.r3: vat_a41d_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r3",
    "package": "jdg.micro.vat",
    "priority": 50192,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41d_r3_pass", false) == true
}

# jdg.micro.vat.a41d.r4: vat_a41d_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r4",
    "package": "jdg.micro.vat",
    "priority": 50193,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41d_r4_checks", false) == true
}

# jdg.micro.vat.a41d.r5: vat_a41d_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r5",
    "package": "jdg.micro.vat",
    "priority": 50194,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a41d.r6: vat_a41d_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r6",
    "package": "jdg.micro.vat",
    "priority": 50195,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a41d.r7: vat_a41d_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r7",
    "package": "jdg.micro.vat",
    "priority": 50196,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a41d_exception", false) == true
}

# jdg.micro.vat.a41d.r8: vat_a41d_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r8",
    "package": "jdg.micro.vat",
    "priority": 50197,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a41d_exception_2", false) == true
}

# jdg.micro.vat.a41d.r9: vat_a41d_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r9",
    "package": "jdg.micro.vat",
    "priority": 50198,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a41d.r10: vat_a41d_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r10",
    "package": "jdg.micro.vat",
    "priority": 50199,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a41d.r11: vat_a41d_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r11",
    "package": "jdg.micro.vat",
    "priority": 50200,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a41d.r12: vat_a41d_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r12",
    "package": "jdg.micro.vat",
    "priority": 50201,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Stawki 0% i zwolnienia",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a41d_violation", false) == true
}

# jdg.micro.vat.a41d.r13: vat_a41d_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r13",
    "package": "jdg.micro.vat",
    "priority": 50202,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a41d_edge_case", false) == true
}

# jdg.micro.vat.a41d.r14: vat_a41d_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r14",
    "package": "jdg.micro.vat",
    "priority": 50203,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a41d_edge_case_2", false) == true
}

# jdg.micro.vat.a41d.r15: vat_a41d_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a41d.r15",
    "package": "jdg.micro.vat",
    "priority": 50204,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawki 0% i zwolnienia: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a42 — Stawka 0% — WDT (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a42.r1: vat_a42_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r1",
    "package": "jdg.micro.vat",
    "priority": 50205,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a42.r2: vat_a42_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r2",
    "package": "jdg.micro.vat",
    "priority": 50206,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a42.r3: vat_a42_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r3",
    "package": "jdg.micro.vat",
    "priority": 50207,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_r3_pass", false) == true
}

# jdg.micro.vat.a42.r4: vat_a42_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r4",
    "package": "jdg.micro.vat",
    "priority": 50208,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_r4_checks", false) == true
}

# jdg.micro.vat.a42.r5: vat_a42_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r5",
    "package": "jdg.micro.vat",
    "priority": 50209,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a42.r6: vat_a42_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r6",
    "package": "jdg.micro.vat",
    "priority": 50210,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a42.r7: vat_a42_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r7",
    "package": "jdg.micro.vat",
    "priority": 50211,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a42_exception", false) == true
}

# jdg.micro.vat.a42.r8: vat_a42_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r8",
    "package": "jdg.micro.vat",
    "priority": 50212,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a42_exception_2", false) == true
}

# jdg.micro.vat.a42.r9: vat_a42_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r9",
    "package": "jdg.micro.vat",
    "priority": 50213,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a42.r10: vat_a42_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r10",
    "package": "jdg.micro.vat",
    "priority": 50214,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a42.r11: vat_a42_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r11",
    "package": "jdg.micro.vat",
    "priority": 50215,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a42.r12: vat_a42_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a42.r12",
    "package": "jdg.micro.vat",
    "priority": 50216,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Stawka 0% — WDT",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Stawka 0% — WDT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a43 — Zwolnienia przedmiotowe (40 reguł)                                    ║
# ║  Legal basis: Art. 43 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a43.r1: vat_a43_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r1",
    "package": "jdg.micro.vat",
    "priority": 50217,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a43.r2: vat_a43_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r2",
    "package": "jdg.micro.vat",
    "priority": 50218,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a43.r3: vat_a43_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r3",
    "package": "jdg.micro.vat",
    "priority": 50219,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_r3_pass", false) == true
}

# jdg.micro.vat.a43.r4: vat_a43_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r4",
    "package": "jdg.micro.vat",
    "priority": 50220,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_r4_checks", false) == true
}

# jdg.micro.vat.a43.r5: vat_a43_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r5",
    "package": "jdg.micro.vat",
    "priority": 50221,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a43.r6: vat_a43_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r6",
    "package": "jdg.micro.vat",
    "priority": 50222,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a43.r7: vat_a43_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r7",
    "package": "jdg.micro.vat",
    "priority": 50223,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a43_exception", false) == true
}

# jdg.micro.vat.a43.r8: vat_a43_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r8",
    "package": "jdg.micro.vat",
    "priority": 50224,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a43_exception_2", false) == true
}

# jdg.micro.vat.a43.r9: vat_a43_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r9",
    "package": "jdg.micro.vat",
    "priority": 50225,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a43.r10: vat_a43_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r10",
    "package": "jdg.micro.vat",
    "priority": 50226,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a43.r11: vat_a43_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r11",
    "package": "jdg.micro.vat",
    "priority": 50227,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a43.r12: vat_a43_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r12",
    "package": "jdg.micro.vat",
    "priority": 50228,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zwolnienia przedmiotowe",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_violation", false) == true
}

# jdg.micro.vat.a43.r13: vat_a43_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r13",
    "package": "jdg.micro.vat",
    "priority": 50229,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a43_edge_case", false) == true
}

# jdg.micro.vat.a43.r14: vat_a43_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r14",
    "package": "jdg.micro.vat",
    "priority": 50230,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a43_edge_case_2", false) == true
}

# jdg.micro.vat.a43.r15: vat_a43_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r15",
    "package": "jdg.micro.vat",
    "priority": 50231,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# jdg.micro.vat.a43.r16: vat_a43_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r16",
    "package": "jdg.micro.vat",
    "priority": 50232,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a43.r17: vat_a43_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r17",
    "package": "jdg.micro.vat",
    "priority": 50233,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a43.r18: vat_a43_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r18",
    "package": "jdg.micro.vat",
    "priority": 50234,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_r18_pass", false) == true
}

# jdg.micro.vat.a43.r19: vat_a43_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r19",
    "package": "jdg.micro.vat",
    "priority": 50235,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_r19_checks", false) == true
}

# jdg.micro.vat.a43.r20: vat_a43_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r20",
    "package": "jdg.micro.vat",
    "priority": 50236,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a43.r21: vat_a43_r21_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r21",
    "package": "jdg.micro.vat",
    "priority": 50237,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a43.r22: vat_a43_r22_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r22",
    "package": "jdg.micro.vat",
    "priority": 50238,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a43_exception", false) == true
}

# jdg.micro.vat.a43.r23: vat_a43_r23_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r23",
    "package": "jdg.micro.vat",
    "priority": 50239,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a43_exception_2", false) == true
}

# jdg.micro.vat.a43.r24: vat_a43_r24_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r24",
    "package": "jdg.micro.vat",
    "priority": 50240,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a43.r25: vat_a43_r25_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r25",
    "package": "jdg.micro.vat",
    "priority": 50241,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a43.r26: vat_a43_r26_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r26",
    "package": "jdg.micro.vat",
    "priority": 50242,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a43.r27: vat_a43_r27_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r27",
    "package": "jdg.micro.vat",
    "priority": 50243,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 50000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zwolnienia przedmiotowe",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_violation", false) == true
}

# jdg.micro.vat.a43.r28: vat_a43_r28_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r28",
    "package": "jdg.micro.vat",
    "priority": 50244,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a43_edge_case", false) == true
}

# jdg.micro.vat.a43.r29: vat_a43_r29_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r29",
    "package": "jdg.micro.vat",
    "priority": 50245,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a43_edge_case_2", false) == true
}

# jdg.micro.vat.a43.r30: vat_a43_r30_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r30",
    "package": "jdg.micro.vat",
    "priority": 50246,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# jdg.micro.vat.a43.r31: vat_a43_r31_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r31",
    "package": "jdg.micro.vat",
    "priority": 50247,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a43.r32: vat_a43_r32_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r32",
    "package": "jdg.micro.vat",
    "priority": 50248,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a43.r33: vat_a43_r33_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r33",
    "package": "jdg.micro.vat",
    "priority": 50249,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_r33_pass", false) == true
}

# jdg.micro.vat.a43.r34: vat_a43_r34_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r34",
    "package": "jdg.micro.vat",
    "priority": 50250,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_r34_checks", false) == true
}

# jdg.micro.vat.a43.r35: vat_a43_r35_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r35",
    "package": "jdg.micro.vat",
    "priority": 50251,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a43.r36: vat_a43_r36_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r36",
    "package": "jdg.micro.vat",
    "priority": 50252,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a43.r37: vat_a43_r37_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r37",
    "package": "jdg.micro.vat",
    "priority": 50253,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a43_exception", false) == true
}

# jdg.micro.vat.a43.r38: vat_a43_r38_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r38",
    "package": "jdg.micro.vat",
    "priority": 50254,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a43_exception_2", false) == true
}

# jdg.micro.vat.a43.r39: vat_a43_r39_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r39",
    "package": "jdg.micro.vat",
    "priority": 50255,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a43.r40: vat_a43_r40_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a43.r40",
    "package": "jdg.micro.vat",
    "priority": 50256,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 VAT",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a86 — Prawo do odliczenia VAT (20 reguł)                                    ║
# ║  Legal basis: Art. 86 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a86.r1: vat_a86_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r1",
    "package": "jdg.micro.vat",
    "priority": 50257,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a86.r2: vat_a86_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r2",
    "package": "jdg.micro.vat",
    "priority": 50258,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a86.r3: vat_a86_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r3",
    "package": "jdg.micro.vat",
    "priority": 50259,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86_r3_pass", false) == true
}

# jdg.micro.vat.a86.r4: vat_a86_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r4",
    "package": "jdg.micro.vat",
    "priority": 50260,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86_r4_checks", false) == true
}

# jdg.micro.vat.a86.r5: vat_a86_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r5",
    "package": "jdg.micro.vat",
    "priority": 50261,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a86.r6: vat_a86_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r6",
    "package": "jdg.micro.vat",
    "priority": 50262,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a86.r7: vat_a86_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r7",
    "package": "jdg.micro.vat",
    "priority": 50263,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a86_exception", false) == true
}

# jdg.micro.vat.a86.r8: vat_a86_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r8",
    "package": "jdg.micro.vat",
    "priority": 50264,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a86_exception_2", false) == true
}

# jdg.micro.vat.a86.r9: vat_a86_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r9",
    "package": "jdg.micro.vat",
    "priority": 50265,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a86.r10: vat_a86_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r10",
    "package": "jdg.micro.vat",
    "priority": 50266,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a86.r11: vat_a86_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r11",
    "package": "jdg.micro.vat",
    "priority": 50267,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a86.r12: vat_a86_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r12",
    "package": "jdg.micro.vat",
    "priority": 50268,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Prawo do odliczenia VAT",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86_violation", false) == true
}

# jdg.micro.vat.a86.r13: vat_a86_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r13",
    "package": "jdg.micro.vat",
    "priority": 50269,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a86_edge_case", false) == true
}

# jdg.micro.vat.a86.r14: vat_a86_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r14",
    "package": "jdg.micro.vat",
    "priority": 50270,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a86_edge_case_2", false) == true
}

# jdg.micro.vat.a86.r15: vat_a86_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r15",
    "package": "jdg.micro.vat",
    "priority": 50271,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# jdg.micro.vat.a86.r16: vat_a86_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r16",
    "package": "jdg.micro.vat",
    "priority": 50272,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a86.r17: vat_a86_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r17",
    "package": "jdg.micro.vat",
    "priority": 50273,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a86.r18: vat_a86_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r18",
    "package": "jdg.micro.vat",
    "priority": 50274,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86_r18_pass", false) == true
}

# jdg.micro.vat.a86.r19: vat_a86_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r19",
    "package": "jdg.micro.vat",
    "priority": 50275,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86_r19_checks", false) == true
}

# jdg.micro.vat.a86.r20: vat_a86_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86.r20",
    "package": "jdg.micro.vat",
    "priority": 50276,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86 VAT",
    "_warnings": ["[MICRO] Prawo do odliczenia VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a86a — VAT od samochodów (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a86a.r1: vat_a86a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r1",
    "package": "jdg.micro.vat",
    "priority": 50277,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a86a.r2: vat_a86a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r2",
    "package": "jdg.micro.vat",
    "priority": 50278,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a86a.r3: vat_a86a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r3",
    "package": "jdg.micro.vat",
    "priority": 50279,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86a_r3_pass", false) == true
}

# jdg.micro.vat.a86a.r4: vat_a86a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r4",
    "package": "jdg.micro.vat",
    "priority": 50280,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86a_r4_checks", false) == true
}

# jdg.micro.vat.a86a.r5: vat_a86a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r5",
    "package": "jdg.micro.vat",
    "priority": 50281,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a86a.r6: vat_a86a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r6",
    "package": "jdg.micro.vat",
    "priority": 50282,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a86a.r7: vat_a86a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r7",
    "package": "jdg.micro.vat",
    "priority": 50283,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a86a_exception", false) == true
}

# jdg.micro.vat.a86a.r8: vat_a86a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r8",
    "package": "jdg.micro.vat",
    "priority": 50284,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a86a_exception_2", false) == true
}

# jdg.micro.vat.a86a.r9: vat_a86a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r9",
    "package": "jdg.micro.vat",
    "priority": 50285,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a86a.r10: vat_a86a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r10",
    "package": "jdg.micro.vat",
    "priority": 50286,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a86a.r11: vat_a86a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r11",
    "package": "jdg.micro.vat",
    "priority": 50287,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a86a.r12: vat_a86a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a86a.r12",
    "package": "jdg.micro.vat",
    "priority": 50288,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_05",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie VAT od samochodów",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT od samochodów: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a86a_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a87 — Terminy zwrotu VAT (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a87.r1: vat_a87_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r1",
    "package": "jdg.micro.vat",
    "priority": 50289,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a87.r2: vat_a87_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r2",
    "package": "jdg.micro.vat",
    "priority": 50290,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a87.r3: vat_a87_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r3",
    "package": "jdg.micro.vat",
    "priority": 50291,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a87_r3_pass", false) == true
}

# jdg.micro.vat.a87.r4: vat_a87_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r4",
    "package": "jdg.micro.vat",
    "priority": 50292,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a87_r4_checks", false) == true
}

# jdg.micro.vat.a87.r5: vat_a87_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r5",
    "package": "jdg.micro.vat",
    "priority": 50293,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a87.r6: vat_a87_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r6",
    "package": "jdg.micro.vat",
    "priority": 50294,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a87.r7: vat_a87_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r7",
    "package": "jdg.micro.vat",
    "priority": 50295,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a87_exception", false) == true
}

# jdg.micro.vat.a87.r8: vat_a87_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r8",
    "package": "jdg.micro.vat",
    "priority": 50296,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a87_exception_2", false) == true
}

# jdg.micro.vat.a87.r9: vat_a87_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r9",
    "package": "jdg.micro.vat",
    "priority": 50297,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a87.r10: vat_a87_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r10",
    "package": "jdg.micro.vat",
    "priority": 50298,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a87.r11: vat_a87_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r11",
    "package": "jdg.micro.vat",
    "priority": 50299,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a87.r12: vat_a87_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a87.r12",
    "package": "jdg.micro.vat",
    "priority": 50300,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Terminy zwrotu VAT",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy zwrotu VAT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a87_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a88 — Wyłączenia z odliczenia (15 reguł)                                    ║
# ║  Legal basis: Art. 88 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a88.r1: vat_a88_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r1",
    "package": "jdg.micro.vat",
    "priority": 50301,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a88.r2: vat_a88_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r2",
    "package": "jdg.micro.vat",
    "priority": 50302,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a88.r3: vat_a88_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r3",
    "package": "jdg.micro.vat",
    "priority": 50303,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a88_r3_pass", false) == true
}

# jdg.micro.vat.a88.r4: vat_a88_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r4",
    "package": "jdg.micro.vat",
    "priority": 50304,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a88_r4_checks", false) == true
}

# jdg.micro.vat.a88.r5: vat_a88_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r5",
    "package": "jdg.micro.vat",
    "priority": 50305,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a88.r6: vat_a88_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r6",
    "package": "jdg.micro.vat",
    "priority": 50306,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a88.r7: vat_a88_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r7",
    "package": "jdg.micro.vat",
    "priority": 50307,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a88_exception", false) == true
}

# jdg.micro.vat.a88.r8: vat_a88_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r8",
    "package": "jdg.micro.vat",
    "priority": 50308,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a88_exception_2", false) == true
}

# jdg.micro.vat.a88.r9: vat_a88_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r9",
    "package": "jdg.micro.vat",
    "priority": 50309,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a88.r10: vat_a88_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r10",
    "package": "jdg.micro.vat",
    "priority": 50310,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a88.r11: vat_a88_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r11",
    "package": "jdg.micro.vat",
    "priority": 50311,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a88.r12: vat_a88_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r12",
    "package": "jdg.micro.vat",
    "priority": 50312,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Wyłączenia z odliczenia",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a88_violation", false) == true
}

# jdg.micro.vat.a88.r13: vat_a88_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r13",
    "package": "jdg.micro.vat",
    "priority": 50313,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a88_edge_case", false) == true
}

# jdg.micro.vat.a88.r14: vat_a88_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r14",
    "package": "jdg.micro.vat",
    "priority": 50314,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a88_edge_case_2", false) == true
}

# jdg.micro.vat.a88.r15: vat_a88_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a88.r15",
    "package": "jdg.micro.vat",
    "priority": 50315,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 88 VAT",
    "_warnings": ["[MICRO] Wyłączenia z odliczenia: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a89a — Złe długi — wierzyciel (12 reguł)                                    ║
# ║  Legal basis: Art. 89a-89b VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a89a.r1: vat_a89a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r1",
    "package": "jdg.micro.vat",
    "priority": 50316,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a89a.r2: vat_a89a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r2",
    "package": "jdg.micro.vat",
    "priority": 50317,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a89a.r3: vat_a89a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r3",
    "package": "jdg.micro.vat",
    "priority": 50318,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a89a_r3_pass", false) == true
}

# jdg.micro.vat.a89a.r4: vat_a89a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r4",
    "package": "jdg.micro.vat",
    "priority": 50319,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a89a_r4_checks", false) == true
}

# jdg.micro.vat.a89a.r5: vat_a89a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r5",
    "package": "jdg.micro.vat",
    "priority": 50320,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a89a.r6: vat_a89a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r6",
    "package": "jdg.micro.vat",
    "priority": 50321,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a89a.r7: vat_a89a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r7",
    "package": "jdg.micro.vat",
    "priority": 50322,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a89a_exception", false) == true
}

# jdg.micro.vat.a89a.r8: vat_a89a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r8",
    "package": "jdg.micro.vat",
    "priority": 50323,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a89a_exception_2", false) == true
}

# jdg.micro.vat.a89a.r9: vat_a89a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r9",
    "package": "jdg.micro.vat",
    "priority": 50324,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a89a.r10: vat_a89a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r10",
    "package": "jdg.micro.vat",
    "priority": 50325,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a89a.r11: vat_a89a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r11",
    "package": "jdg.micro.vat",
    "priority": 50326,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a89a.r12: vat_a89a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89a.r12",
    "package": "jdg.micro.vat",
    "priority": 50327,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2013-01-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Złe długi — wierzyciel",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["[MICRO] Złe długi — wierzyciel: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a89a_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a89b — Złe długi — dłużnik (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a89b.r1: vat_a89b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r1",
    "package": "jdg.micro.vat",
    "priority": 50328,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a89b.r2: vat_a89b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r2",
    "package": "jdg.micro.vat",
    "priority": 50329,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a89b.r3: vat_a89b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r3",
    "package": "jdg.micro.vat",
    "priority": 50330,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a89b_r3_pass", false) == true
}

# jdg.micro.vat.a89b.r4: vat_a89b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r4",
    "package": "jdg.micro.vat",
    "priority": 50331,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a89b_r4_checks", false) == true
}

# jdg.micro.vat.a89b.r5: vat_a89b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r5",
    "package": "jdg.micro.vat",
    "priority": 50332,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a89b.r6: vat_a89b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r6",
    "package": "jdg.micro.vat",
    "priority": 50333,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a89b.r7: vat_a89b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r7",
    "package": "jdg.micro.vat",
    "priority": 50334,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a89b_exception", false) == true
}

# jdg.micro.vat.a89b.r8: vat_a89b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r8",
    "package": "jdg.micro.vat",
    "priority": 50335,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a89b_exception_2", false) == true
}

# jdg.micro.vat.a89b.r9: vat_a89b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r9",
    "package": "jdg.micro.vat",
    "priority": 50336,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a89b.r10: vat_a89b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r10",
    "package": "jdg.micro.vat",
    "priority": 50337,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a89b.r11: vat_a89b_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r11",
    "package": "jdg.micro.vat",
    "priority": 50338,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a89b.r12: vat_a89b_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a89b.r12",
    "package": "jdg.micro.vat",
    "priority": 50339,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Złe długi — dłużnik",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Złe długi — dłużnik: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a89b_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a96 — Rejestracja VAT-R (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a96.r1: vat_a96_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r1",
    "package": "jdg.micro.vat",
    "priority": 50340,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a96.r2: vat_a96_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r2",
    "package": "jdg.micro.vat",
    "priority": 50341,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a96.r3: vat_a96_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r3",
    "package": "jdg.micro.vat",
    "priority": 50342,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a96_r3_pass", false) == true
}

# jdg.micro.vat.a96.r4: vat_a96_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r4",
    "package": "jdg.micro.vat",
    "priority": 50343,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a96_r4_checks", false) == true
}

# jdg.micro.vat.a96.r5: vat_a96_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r5",
    "package": "jdg.micro.vat",
    "priority": 50344,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a96.r6: vat_a96_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r6",
    "package": "jdg.micro.vat",
    "priority": 50345,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a96.r7: vat_a96_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r7",
    "package": "jdg.micro.vat",
    "priority": 50346,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a96_exception", false) == true
}

# jdg.micro.vat.a96.r8: vat_a96_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r8",
    "package": "jdg.micro.vat",
    "priority": 50347,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a96_exception_2", false) == true
}

# jdg.micro.vat.a96.r9: vat_a96_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r9",
    "package": "jdg.micro.vat",
    "priority": 50348,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a96.r10: vat_a96_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r10",
    "package": "jdg.micro.vat",
    "priority": 50349,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a96.r11: vat_a96_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r11",
    "package": "jdg.micro.vat",
    "priority": 50350,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a96.r12: vat_a96_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96.r12",
    "package": "jdg.micro.vat",
    "priority": 50351,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Rejestracja VAT-R",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Rejestracja VAT-R: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a96_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a96b — Biała Lista VAT (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a96b.r1: vat_a96b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r1",
    "package": "jdg.micro.vat",
    "priority": 50352,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a96b.r2: vat_a96b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r2",
    "package": "jdg.micro.vat",
    "priority": 50353,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a96b.r3: vat_a96b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r3",
    "package": "jdg.micro.vat",
    "priority": 50354,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a96b_r3_pass", false) == true
}

# jdg.micro.vat.a96b.r4: vat_a96b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r4",
    "package": "jdg.micro.vat",
    "priority": 50355,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a96b_r4_checks", false) == true
}

# jdg.micro.vat.a96b.r5: vat_a96b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r5",
    "package": "jdg.micro.vat",
    "priority": 50356,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a96b.r6: vat_a96b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r6",
    "package": "jdg.micro.vat",
    "priority": 50357,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a96b.r7: vat_a96b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r7",
    "package": "jdg.micro.vat",
    "priority": 50358,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a96b_exception", false) == true
}

# jdg.micro.vat.a96b.r8: vat_a96b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r8",
    "package": "jdg.micro.vat",
    "priority": 50359,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a96b_exception_2", false) == true
}

# jdg.micro.vat.a96b.r9: vat_a96b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r9",
    "package": "jdg.micro.vat",
    "priority": 50360,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a96b.r10: vat_a96b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a96b.r10",
    "package": "jdg.micro.vat",
    "priority": 50361,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Biała Lista VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a97 — VAT-UE rejestracja (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a97.r1: vat_a97_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r1",
    "package": "jdg.micro.vat",
    "priority": 50362,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a97.r2: vat_a97_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r2",
    "package": "jdg.micro.vat",
    "priority": 50363,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a97.r3: vat_a97_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r3",
    "package": "jdg.micro.vat",
    "priority": 50364,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a97_r3_pass", false) == true
}

# jdg.micro.vat.a97.r4: vat_a97_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r4",
    "package": "jdg.micro.vat",
    "priority": 50365,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a97_r4_checks", false) == true
}

# jdg.micro.vat.a97.r5: vat_a97_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r5",
    "package": "jdg.micro.vat",
    "priority": 50366,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a97.r6: vat_a97_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r6",
    "package": "jdg.micro.vat",
    "priority": 50367,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a97.r7: vat_a97_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r7",
    "package": "jdg.micro.vat",
    "priority": 50368,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a97_exception", false) == true
}

# jdg.micro.vat.a97.r8: vat_a97_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r8",
    "package": "jdg.micro.vat",
    "priority": 50369,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a97_exception_2", false) == true
}

# jdg.micro.vat.a97.r9: vat_a97_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r9",
    "package": "jdg.micro.vat",
    "priority": 50370,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a97.r10: vat_a97_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a97.r10",
    "package": "jdg.micro.vat",
    "priority": 50371,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE rejestracja: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a99 — Deklaracje VAT (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a99.r1: vat_a99_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r1",
    "package": "jdg.micro.vat",
    "priority": 50372,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a99.r2: vat_a99_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r2",
    "package": "jdg.micro.vat",
    "priority": 50373,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a99.r3: vat_a99_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r3",
    "package": "jdg.micro.vat",
    "priority": 50374,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a99_r3_pass", false) == true
}

# jdg.micro.vat.a99.r4: vat_a99_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r4",
    "package": "jdg.micro.vat",
    "priority": 50375,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a99_r4_checks", false) == true
}

# jdg.micro.vat.a99.r5: vat_a99_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r5",
    "package": "jdg.micro.vat",
    "priority": 50376,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a99.r6: vat_a99_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r6",
    "package": "jdg.micro.vat",
    "priority": 50377,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a99.r7: vat_a99_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r7",
    "package": "jdg.micro.vat",
    "priority": 50378,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a99_exception", false) == true
}

# jdg.micro.vat.a99.r8: vat_a99_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r8",
    "package": "jdg.micro.vat",
    "priority": 50379,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a99_exception_2", false) == true
}

# jdg.micro.vat.a99.r9: vat_a99_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r9",
    "package": "jdg.micro.vat",
    "priority": 50380,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a99.r10: vat_a99_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r10",
    "package": "jdg.micro.vat",
    "priority": 50381,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a99.r11: vat_a99_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r11",
    "package": "jdg.micro.vat",
    "priority": 50382,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a99.r12: vat_a99_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a99.r12",
    "package": "jdg.micro.vat",
    "priority": 50383,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Deklaracje VAT",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Deklaracje VAT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a99_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a100 — VAT-UE informacje podsumowujące (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a100.r1: vat_a100_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r1",
    "package": "jdg.micro.vat",
    "priority": 50384,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a100.r2: vat_a100_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r2",
    "package": "jdg.micro.vat",
    "priority": 50385,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a100.r3: vat_a100_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r3",
    "package": "jdg.micro.vat",
    "priority": 50386,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a100_r3_pass", false) == true
}

# jdg.micro.vat.a100.r4: vat_a100_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r4",
    "package": "jdg.micro.vat",
    "priority": 50387,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a100_r4_checks", false) == true
}

# jdg.micro.vat.a100.r5: vat_a100_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r5",
    "package": "jdg.micro.vat",
    "priority": 50388,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a100.r6: vat_a100_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r6",
    "package": "jdg.micro.vat",
    "priority": 50389,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a100.r7: vat_a100_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r7",
    "package": "jdg.micro.vat",
    "priority": 50390,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a100_exception", false) == true
}

# jdg.micro.vat.a100.r8: vat_a100_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a100.r8",
    "package": "jdg.micro.vat",
    "priority": 50391,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] VAT-UE informacje podsumowujące: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a100_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a103 — Terminy płatności VAT (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a103.r1: vat_a103_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r1",
    "package": "jdg.micro.vat",
    "priority": 50392,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a103.r2: vat_a103_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r2",
    "package": "jdg.micro.vat",
    "priority": 50393,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a103.r3: vat_a103_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r3",
    "package": "jdg.micro.vat",
    "priority": 50394,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a103_r3_pass", false) == true
}

# jdg.micro.vat.a103.r4: vat_a103_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r4",
    "package": "jdg.micro.vat",
    "priority": 50395,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a103_r4_checks", false) == true
}

# jdg.micro.vat.a103.r5: vat_a103_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r5",
    "package": "jdg.micro.vat",
    "priority": 50396,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a103.r6: vat_a103_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r6",
    "package": "jdg.micro.vat",
    "priority": 50397,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a103.r7: vat_a103_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r7",
    "package": "jdg.micro.vat",
    "priority": 50398,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a103_exception", false) == true
}

# jdg.micro.vat.a103.r8: vat_a103_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a103.r8",
    "package": "jdg.micro.vat",
    "priority": 50399,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Terminy płatności VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a103_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a106a — Faktury — wymogi formalne (15 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a106a.r1: vat_a106a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r1",
    "package": "jdg.micro.vat",
    "priority": 50400,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a106a.r2: vat_a106a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r2",
    "package": "jdg.micro.vat",
    "priority": 50401,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a106a.r3: vat_a106a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r3",
    "package": "jdg.micro.vat",
    "priority": 50402,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106a_r3_pass", false) == true
}

# jdg.micro.vat.a106a.r4: vat_a106a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r4",
    "package": "jdg.micro.vat",
    "priority": 50403,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106a_r4_checks", false) == true
}

# jdg.micro.vat.a106a.r5: vat_a106a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r5",
    "package": "jdg.micro.vat",
    "priority": 50404,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a106a.r6: vat_a106a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r6",
    "package": "jdg.micro.vat",
    "priority": 50405,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a106a.r7: vat_a106a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r7",
    "package": "jdg.micro.vat",
    "priority": 50406,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a106a_exception", false) == true
}

# jdg.micro.vat.a106a.r8: vat_a106a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r8",
    "package": "jdg.micro.vat",
    "priority": 50407,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a106a_exception_2", false) == true
}

# jdg.micro.vat.a106a.r9: vat_a106a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r9",
    "package": "jdg.micro.vat",
    "priority": 50408,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a106a.r10: vat_a106a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r10",
    "package": "jdg.micro.vat",
    "priority": 50409,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a106a.r11: vat_a106a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r11",
    "package": "jdg.micro.vat",
    "priority": 50410,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a106a.r12: vat_a106a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r12",
    "package": "jdg.micro.vat",
    "priority": 50411,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Faktury — wymogi formalne",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106a_violation", false) == true
}

# jdg.micro.vat.a106a.r13: vat_a106a_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r13",
    "package": "jdg.micro.vat",
    "priority": 50412,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a106a_edge_case", false) == true
}

# jdg.micro.vat.a106a.r14: vat_a106a_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r14",
    "package": "jdg.micro.vat",
    "priority": 50413,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a106a_edge_case_2", false) == true
}

# jdg.micro.vat.a106a.r15: vat_a106a_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106a.r15",
    "package": "jdg.micro.vat",
    "priority": 50414,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury — wymogi formalne: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a106f — Faktury korygujące (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a106f.r1: vat_a106f_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r1",
    "package": "jdg.micro.vat",
    "priority": 50415,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a106f.r2: vat_a106f_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r2",
    "package": "jdg.micro.vat",
    "priority": 50416,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a106f.r3: vat_a106f_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r3",
    "package": "jdg.micro.vat",
    "priority": 50417,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106f_r3_pass", false) == true
}

# jdg.micro.vat.a106f.r4: vat_a106f_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r4",
    "package": "jdg.micro.vat",
    "priority": 50418,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106f_r4_checks", false) == true
}

# jdg.micro.vat.a106f.r5: vat_a106f_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r5",
    "package": "jdg.micro.vat",
    "priority": 50419,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a106f.r6: vat_a106f_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r6",
    "package": "jdg.micro.vat",
    "priority": 50420,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a106f.r7: vat_a106f_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r7",
    "package": "jdg.micro.vat",
    "priority": 50421,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a106f_exception", false) == true
}

# jdg.micro.vat.a106f.r8: vat_a106f_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r8",
    "package": "jdg.micro.vat",
    "priority": 50422,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a106f_exception_2", false) == true
}

# jdg.micro.vat.a106f.r9: vat_a106f_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r9",
    "package": "jdg.micro.vat",
    "priority": 50423,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a106f.r10: vat_a106f_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r10",
    "package": "jdg.micro.vat",
    "priority": 50424,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a106f.r11: vat_a106f_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r11",
    "package": "jdg.micro.vat",
    "priority": 50425,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a106f.r12: vat_a106f_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106f.r12",
    "package": "jdg.micro.vat",
    "priority": 50426,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Faktury korygujące",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Faktury korygujące: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106f_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a106na — KSeF — obowiązek (12 reguł)                                    ║
# ║  Legal basis: Art. 106na VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a106na.r1: vat_a106na_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r1",
    "package": "jdg.micro.vat",
    "priority": 50427,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a106na.r2: vat_a106na_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r2",
    "package": "jdg.micro.vat",
    "priority": 50428,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a106na.r3: vat_a106na_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r3",
    "package": "jdg.micro.vat",
    "priority": 50429,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106na_r3_pass", false) == true
}

# jdg.micro.vat.a106na.r4: vat_a106na_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r4",
    "package": "jdg.micro.vat",
    "priority": 50430,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106na_r4_checks", false) == true
}

# jdg.micro.vat.a106na.r5: vat_a106na_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r5",
    "package": "jdg.micro.vat",
    "priority": 50431,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a106na.r6: vat_a106na_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r6",
    "package": "jdg.micro.vat",
    "priority": 50432,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a106na.r7: vat_a106na_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r7",
    "package": "jdg.micro.vat",
    "priority": 50433,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a106na_exception", false) == true
}

# jdg.micro.vat.a106na.r8: vat_a106na_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r8",
    "package": "jdg.micro.vat",
    "priority": 50434,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a106na_exception_2", false) == true
}

# jdg.micro.vat.a106na.r9: vat_a106na_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r9",
    "package": "jdg.micro.vat",
    "priority": 50435,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a106na.r10: vat_a106na_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r10",
    "package": "jdg.micro.vat",
    "priority": 50436,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a106na.r11: vat_a106na_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r11",
    "package": "jdg.micro.vat",
    "priority": 50437,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a106na.r12: vat_a106na_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106na.r12",
    "package": "jdg.micro.vat",
    "priority": 50438,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie KSeF — obowiązek",
    "_legal_basis": "Art. 106na VAT",
    "_warnings": ["[MICRO] KSeF — obowiązek: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106na_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a106ne — KSeF — tryb awaryjny (8 reguł)                                    ║
# ║  Legal basis: Art. 106ne VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a106ne.r1: vat_a106ne_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r1",
    "package": "jdg.micro.vat",
    "priority": 50439,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a106ne.r2: vat_a106ne_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r2",
    "package": "jdg.micro.vat",
    "priority": 50440,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a106ne.r3: vat_a106ne_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r3",
    "package": "jdg.micro.vat",
    "priority": 50441,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106ne_r3_pass", false) == true
}

# jdg.micro.vat.a106ne.r4: vat_a106ne_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r4",
    "package": "jdg.micro.vat",
    "priority": 50442,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106ne_r4_checks", false) == true
}

# jdg.micro.vat.a106ne.r5: vat_a106ne_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r5",
    "package": "jdg.micro.vat",
    "priority": 50443,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a106ne.r6: vat_a106ne_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r6",
    "package": "jdg.micro.vat",
    "priority": 50444,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a106ne.r7: vat_a106ne_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r7",
    "package": "jdg.micro.vat",
    "priority": 50445,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a106ne_exception", false) == true
}

# jdg.micro.vat.a106ne.r8: vat_a106ne_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106ne.r8",
    "package": "jdg.micro.vat",
    "priority": 50446,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106ne VAT",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a106ne_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a106nq — KSeF — sankcje (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a106nq.r1: vat_a106nq_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r1",
    "package": "jdg.micro.vat",
    "priority": 50447,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a106nq.r2: vat_a106nq_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r2",
    "package": "jdg.micro.vat",
    "priority": 50448,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a106nq.r3: vat_a106nq_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r3",
    "package": "jdg.micro.vat",
    "priority": 50449,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106nq_r3_pass", false) == true
}

# jdg.micro.vat.a106nq.r4: vat_a106nq_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r4",
    "package": "jdg.micro.vat",
    "priority": 50450,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a106nq_r4_checks", false) == true
}

# jdg.micro.vat.a106nq.r5: vat_a106nq_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r5",
    "package": "jdg.micro.vat",
    "priority": 50451,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a106nq.r6: vat_a106nq_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r6",
    "package": "jdg.micro.vat",
    "priority": 50452,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a106nq.r7: vat_a106nq_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r7",
    "package": "jdg.micro.vat",
    "priority": 50453,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a106nq_exception", false) == true
}

# jdg.micro.vat.a106nq.r8: vat_a106nq_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a106nq.r8",
    "package": "jdg.micro.vat",
    "priority": 50454,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] KSeF — sankcje: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a106nq_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a108 — Split payment (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a108.r1: vat_a108_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r1",
    "package": "jdg.micro.vat",
    "priority": 50455,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a108.r2: vat_a108_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r2",
    "package": "jdg.micro.vat",
    "priority": 50456,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a108.r3: vat_a108_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r3",
    "package": "jdg.micro.vat",
    "priority": 50457,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a108_r3_pass", false) == true
}

# jdg.micro.vat.a108.r4: vat_a108_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r4",
    "package": "jdg.micro.vat",
    "priority": 50458,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a108_r4_checks", false) == true
}

# jdg.micro.vat.a108.r5: vat_a108_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r5",
    "package": "jdg.micro.vat",
    "priority": 50459,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a108.r6: vat_a108_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r6",
    "package": "jdg.micro.vat",
    "priority": 50460,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a108.r7: vat_a108_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r7",
    "package": "jdg.micro.vat",
    "priority": 50461,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a108_exception", false) == true
}

# jdg.micro.vat.a108.r8: vat_a108_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r8",
    "package": "jdg.micro.vat",
    "priority": 50462,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a108_exception_2", false) == true
}

# jdg.micro.vat.a108.r9: vat_a108_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r9",
    "package": "jdg.micro.vat",
    "priority": 50463,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a108.r10: vat_a108_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r10",
    "package": "jdg.micro.vat",
    "priority": 50464,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a108.r11: vat_a108_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r11",
    "package": "jdg.micro.vat",
    "priority": 50465,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a108.r12: vat_a108_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108.r12",
    "package": "jdg.micro.vat",
    "priority": 50466,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Split payment",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Split payment: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a108_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a108a — MPP — sankcje (8 reguł)                                    ║
# ║  Legal basis: Art. 108a-108f VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a108a.r1: vat_a108a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r1",
    "package": "jdg.micro.vat",
    "priority": 50467,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a108a.r2: vat_a108a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r2",
    "package": "jdg.micro.vat",
    "priority": 50468,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a108a.r3: vat_a108a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r3",
    "package": "jdg.micro.vat",
    "priority": 50469,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a108a_r3_pass", false) == true
}

# jdg.micro.vat.a108a.r4: vat_a108a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r4",
    "package": "jdg.micro.vat",
    "priority": 50470,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a108a_r4_checks", false) == true
}

# jdg.micro.vat.a108a.r5: vat_a108a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r5",
    "package": "jdg.micro.vat",
    "priority": 50471,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a108a.r6: vat_a108a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r6",
    "package": "jdg.micro.vat",
    "priority": 50472,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a108a.r7: vat_a108a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r7",
    "package": "jdg.micro.vat",
    "priority": 50473,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a108a_exception", false) == true
}

# jdg.micro.vat.a108a.r8: vat_a108a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a108a.r8",
    "package": "jdg.micro.vat",
    "priority": 50474,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2019-11-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a-108f VAT",
    "_warnings": ["[MICRO] MPP — sankcje: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a108a_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a109 — Ewidencja VAT (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a109.r1: vat_a109_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r1",
    "package": "jdg.micro.vat",
    "priority": 50475,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a109.r2: vat_a109_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r2",
    "package": "jdg.micro.vat",
    "priority": 50476,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a109.r3: vat_a109_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r3",
    "package": "jdg.micro.vat",
    "priority": 50477,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a109_r3_pass", false) == true
}

# jdg.micro.vat.a109.r4: vat_a109_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r4",
    "package": "jdg.micro.vat",
    "priority": 50478,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a109_r4_checks", false) == true
}

# jdg.micro.vat.a109.r5: vat_a109_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r5",
    "package": "jdg.micro.vat",
    "priority": 50479,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a109.r6: vat_a109_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r6",
    "package": "jdg.micro.vat",
    "priority": 50480,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a109.r7: vat_a109_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r7",
    "package": "jdg.micro.vat",
    "priority": 50481,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a109_exception", false) == true
}

# jdg.micro.vat.a109.r8: vat_a109_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r8",
    "package": "jdg.micro.vat",
    "priority": 50482,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a109_exception_2", false) == true
}

# jdg.micro.vat.a109.r9: vat_a109_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r9",
    "package": "jdg.micro.vat",
    "priority": 50483,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a109.r10: vat_a109_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a109.r10",
    "package": "jdg.micro.vat",
    "priority": 50484,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ustawy o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) — ewidencja VAT (rejestry sprzedaży i zakupów)",
    "_warnings": ["[MICRO] Ewidencja VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a113 — Zwolnienie podmiotowe 200k (18 reguł)                                    ║
# ║  Legal basis: Art. 113 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a113.r1: vat_a113_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r1",
    "package": "jdg.micro.vat",
    "priority": 50485,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a113.r2: vat_a113_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r2",
    "package": "jdg.micro.vat",
    "priority": 50486,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a113.r3: vat_a113_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r3",
    "package": "jdg.micro.vat",
    "priority": 50487,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a113_r3_pass", false) == true
}

# jdg.micro.vat.a113.r4: vat_a113_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r4",
    "package": "jdg.micro.vat",
    "priority": 50488,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a113_r4_checks", false) == true
}

# jdg.micro.vat.a113.r5: vat_a113_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r5",
    "package": "jdg.micro.vat",
    "priority": 50489,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a113.r6: vat_a113_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r6",
    "package": "jdg.micro.vat",
    "priority": 50490,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a113.r7: vat_a113_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r7",
    "package": "jdg.micro.vat",
    "priority": 50491,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a113_exception", false) == true
}

# jdg.micro.vat.a113.r8: vat_a113_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r8",
    "package": "jdg.micro.vat",
    "priority": 50492,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a113_exception_2", false) == true
}

# jdg.micro.vat.a113.r9: vat_a113_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r9",
    "package": "jdg.micro.vat",
    "priority": 50493,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a113.r10: vat_a113_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r10",
    "package": "jdg.micro.vat",
    "priority": 50494,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a113.r11: vat_a113_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r11",
    "package": "jdg.micro.vat",
    "priority": 50495,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a113.r12: vat_a113_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r12",
    "package": "jdg.micro.vat",
    "priority": 50496,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zwolnienie podmiotowe 200k",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a113_violation", false) == true
}

# jdg.micro.vat.a113.r13: vat_a113_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r13",
    "package": "jdg.micro.vat",
    "priority": 50497,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a113_edge_case", false) == true
}

# jdg.micro.vat.a113.r14: vat_a113_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r14",
    "package": "jdg.micro.vat",
    "priority": 50498,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a113_edge_case_2", false) == true
}

# jdg.micro.vat.a113.r15: vat_a113_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r15",
    "package": "jdg.micro.vat",
    "priority": 50499,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# jdg.micro.vat.a113.r16: vat_a113_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r16",
    "package": "jdg.micro.vat",
    "priority": 50500,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a113.r17: vat_a113_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r17",
    "package": "jdg.micro.vat",
    "priority": 50501,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a113.r18: vat_a113_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a113.r18",
    "package": "jdg.micro.vat",
    "priority": 50502,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 113 VAT",
    "_warnings": ["[MICRO] Zwolnienie podmiotowe 200k: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a113_r18_pass", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a119 — Faktury zaliczkowe (8 reguł)                                    ║
# ║  Legal basis: Art. 119 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a119.r1: vat_a119_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r1",
    "package": "jdg.micro.vat",
    "priority": 50503,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a119.r2: vat_a119_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r2",
    "package": "jdg.micro.vat",
    "priority": 50504,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a119.r3: vat_a119_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r3",
    "package": "jdg.micro.vat",
    "priority": 50505,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a119_r3_pass", false) == true
}

# jdg.micro.vat.a119.r4: vat_a119_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r4",
    "package": "jdg.micro.vat",
    "priority": 50506,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a119_r4_checks", false) == true
}

# jdg.micro.vat.a119.r5: vat_a119_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r5",
    "package": "jdg.micro.vat",
    "priority": 50507,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a119.r6: vat_a119_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r6",
    "package": "jdg.micro.vat",
    "priority": 50508,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a119.r7: vat_a119_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r7",
    "package": "jdg.micro.vat",
    "priority": 50509,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a119_exception", false) == true
}

# jdg.micro.vat.a119.r8: vat_a119_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a119.r8",
    "package": "jdg.micro.vat",
    "priority": 50510,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT",
    "_warnings": ["[MICRO] Faktury zaliczkowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a119_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a120 — Procedura marży (15 reguł)                                    ║
# ║  Legal basis: Art. 120 VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a120.r1: vat_a120_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r1",
    "package": "jdg.micro.vat",
    "priority": 50511,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a120.r2: vat_a120_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r2",
    "package": "jdg.micro.vat",
    "priority": 50512,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a120.r3: vat_a120_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r3",
    "package": "jdg.micro.vat",
    "priority": 50513,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a120_r3_pass", false) == true
}

# jdg.micro.vat.a120.r4: vat_a120_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r4",
    "package": "jdg.micro.vat",
    "priority": 50514,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a120_r4_checks", false) == true
}

# jdg.micro.vat.a120.r5: vat_a120_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r5",
    "package": "jdg.micro.vat",
    "priority": 50515,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a120.r6: vat_a120_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r6",
    "package": "jdg.micro.vat",
    "priority": 50516,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a120.r7: vat_a120_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r7",
    "package": "jdg.micro.vat",
    "priority": 50517,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a120_exception", false) == true
}

# jdg.micro.vat.a120.r8: vat_a120_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r8",
    "package": "jdg.micro.vat",
    "priority": 50518,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a120_exception_2", false) == true
}

# jdg.micro.vat.a120.r9: vat_a120_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r9",
    "package": "jdg.micro.vat",
    "priority": 50519,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a120.r10: vat_a120_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r10",
    "package": "jdg.micro.vat",
    "priority": 50520,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a120.r11: vat_a120_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r11",
    "package": "jdg.micro.vat",
    "priority": 50521,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a120.r12: vat_a120_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r12",
    "package": "jdg.micro.vat",
    "priority": 50522,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Procedura marży",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a120_violation", false) == true
}

# jdg.micro.vat.a120.r13: vat_a120_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r13",
    "package": "jdg.micro.vat",
    "priority": 50523,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "vat_a120_edge_case", false) == true
}

# jdg.micro.vat.a120.r14: vat_a120_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r14",
    "package": "jdg.micro.vat",
    "priority": 50524,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "vat_a120_edge_case_2", false) == true
}

# jdg.micro.vat.a120.r15: vat_a120_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a120.r15",
    "package": "jdg.micro.vat",
    "priority": 50525,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["[MICRO] Procedura marży: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "vat_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a129 — Transakcje UE — WDT (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a129.r1: vat_a129_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r1",
    "package": "jdg.micro.vat",
    "priority": 50526,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a129.r2: vat_a129_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r2",
    "package": "jdg.micro.vat",
    "priority": 50527,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a129.r3: vat_a129_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r3",
    "package": "jdg.micro.vat",
    "priority": 50528,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a129_r3_pass", false) == true
}

# jdg.micro.vat.a129.r4: vat_a129_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r4",
    "package": "jdg.micro.vat",
    "priority": 50529,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a129_r4_checks", false) == true
}

# jdg.micro.vat.a129.r5: vat_a129_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r5",
    "package": "jdg.micro.vat",
    "priority": 50530,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a129.r6: vat_a129_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r6",
    "package": "jdg.micro.vat",
    "priority": 50531,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a129.r7: vat_a129_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r7",
    "package": "jdg.micro.vat",
    "priority": 50532,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a129_exception", false) == true
}

# jdg.micro.vat.a129.r8: vat_a129_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r8",
    "package": "jdg.micro.vat",
    "priority": 50533,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a129_exception_2", false) == true
}

# jdg.micro.vat.a129.r9: vat_a129_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r9",
    "package": "jdg.micro.vat",
    "priority": 50534,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a129.r10: vat_a129_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r10",
    "package": "jdg.micro.vat",
    "priority": 50535,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a129.r11: vat_a129_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r11",
    "package": "jdg.micro.vat",
    "priority": 50536,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a129.r12: vat_a129_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a129.r12",
    "package": "jdg.micro.vat",
    "priority": 50537,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Transakcje UE — WDT",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WDT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a129_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a135 — Transakcje UE — WNT (12 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a135.r1: vat_a135_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r1",
    "package": "jdg.micro.vat",
    "priority": 50538,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a135.r2: vat_a135_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r2",
    "package": "jdg.micro.vat",
    "priority": 50539,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a135.r3: vat_a135_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r3",
    "package": "jdg.micro.vat",
    "priority": 50540,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_r3_pass", false) == true
}

# jdg.micro.vat.a135.r4: vat_a135_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r4",
    "package": "jdg.micro.vat",
    "priority": 50541,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_r4_checks", false) == true
}

# jdg.micro.vat.a135.r5: vat_a135_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r5",
    "package": "jdg.micro.vat",
    "priority": 50542,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a135.r6: vat_a135_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r6",
    "package": "jdg.micro.vat",
    "priority": 50543,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a135.r7: vat_a135_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r7",
    "package": "jdg.micro.vat",
    "priority": 50544,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a135_exception", false) == true
}

# jdg.micro.vat.a135.r8: vat_a135_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r8",
    "package": "jdg.micro.vat",
    "priority": 50545,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a135_exception_2", false) == true
}

# jdg.micro.vat.a135.r9: vat_a135_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r9",
    "package": "jdg.micro.vat",
    "priority": 50546,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a135.r10: vat_a135_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r10",
    "package": "jdg.micro.vat",
    "priority": 50547,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# jdg.micro.vat.a135.r11: vat_a135_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r11",
    "package": "jdg.micro.vat",
    "priority": 50548,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "vat_deadline_required", false) == true
}

# jdg.micro.vat.a135.r12: vat_a135_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a135.r12",
    "package": "jdg.micro.vat",
    "priority": 50549,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Transakcje UE — WNT",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje UE — WNT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a130 — OSS — One Stop Shop (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a130.r1: vat_a130_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r1",
    "package": "jdg.micro.vat",
    "priority": 50550,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a130.r2: vat_a130_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r2",
    "package": "jdg.micro.vat",
    "priority": 50551,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a130.r3: vat_a130_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r3",
    "package": "jdg.micro.vat",
    "priority": 50552,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a130_r3_pass", false) == true
}

# jdg.micro.vat.a130.r4: vat_a130_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r4",
    "package": "jdg.micro.vat",
    "priority": 50553,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a130_r4_checks", false) == true
}

# jdg.micro.vat.a130.r5: vat_a130_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r5",
    "package": "jdg.micro.vat",
    "priority": 50554,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a130.r6: vat_a130_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r6",
    "package": "jdg.micro.vat",
    "priority": 50555,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a130.r7: vat_a130_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r7",
    "package": "jdg.micro.vat",
    "priority": 50556,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a130_exception", false) == true
}

# jdg.micro.vat.a130.r8: vat_a130_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r8",
    "package": "jdg.micro.vat",
    "priority": 50557,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a130_exception_2", false) == true
}

# jdg.micro.vat.a130.r9: vat_a130_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r9",
    "package": "jdg.micro.vat",
    "priority": 50558,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a130.r10: vat_a130_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a130.r10",
    "package": "jdg.micro.vat",
    "priority": 50559,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] OSS — One Stop Shop: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a131 — IOSS — Import OSS (8 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a131.r1: vat_a131_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r1",
    "package": "jdg.micro.vat",
    "priority": 50560,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a131.r2: vat_a131_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r2",
    "package": "jdg.micro.vat",
    "priority": 50561,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a131.r3: vat_a131_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r3",
    "package": "jdg.micro.vat",
    "priority": 50562,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a131_r3_pass", false) == true
}

# jdg.micro.vat.a131.r4: vat_a131_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r4",
    "package": "jdg.micro.vat",
    "priority": 50563,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a131_r4_checks", false) == true
}

# jdg.micro.vat.a131.r5: vat_a131_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r5",
    "package": "jdg.micro.vat",
    "priority": 50564,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a131.r6: vat_a131_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r6",
    "package": "jdg.micro.vat",
    "priority": 50565,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a131.r7: vat_a131_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r7",
    "package": "jdg.micro.vat",
    "priority": 50566,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a131_exception", false) == true
}

# jdg.micro.vat.a131.r8: vat_a131_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a131.r8",
    "package": "jdg.micro.vat",
    "priority": 50567,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] IOSS — Import OSS: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a131_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  vat.a138 — Transakcje trójstronne (10 reguł)                                    ║
# ║  Legal basis: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.vat.a138.r1: vat_a138_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r1",
    "package": "jdg.micro.vat",
    "priority": 50568,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.vat.a138.r2: vat_a138_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r2",
    "package": "jdg.micro.vat",
    "priority": 50569,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "vat_condition_met", false) == true
}

# jdg.micro.vat.a138.r3: vat_a138_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r3",
    "package": "jdg.micro.vat",
    "priority": 50570,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "vat_a138_r3_pass", false) == true
}

# jdg.micro.vat.a138.r4: vat_a138_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r4",
    "package": "jdg.micro.vat",
    "priority": 50571,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "vat_a138_r4_checks", false) == true
}

# jdg.micro.vat.a138.r5: vat_a138_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r5",
    "package": "jdg.micro.vat",
    "priority": 50572,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "vat_exclusion_applies", false) == false
}

# jdg.micro.vat.a138.r6: vat_a138_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r6",
    "package": "jdg.micro.vat",
    "priority": 50573,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "vat_exclusion_2", false) == false
}

# jdg.micro.vat.a138.r7: vat_a138_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r7",
    "package": "jdg.micro.vat",
    "priority": 50574,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "vat_a138_exception", false) == true
}

# jdg.micro.vat.a138.r8: vat_a138_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r8",
    "package": "jdg.micro.vat",
    "priority": 50575,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "vat_a138_exception_2", false) == true
}

# jdg.micro.vat.a138.r9: vat_a138_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r9",
    "package": "jdg.micro.vat",
    "priority": 50576,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_vat", false) == true
}

# jdg.micro.vat.a138.r10: vat_a138_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.a138.r10",
    "package": "jdg.micro.vat",
    "priority": 50577,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Transakcje trójstronne: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_vat", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (678 reguł)       ║
# ║  Priorytety: 50000-50677                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.final.a100.u1.p1 — `final_a100_u1_p1`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a100.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50000,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a100_u1_p1_check", false) == true
}
# jdg.final.a101.u2.p2 — `final_a101_u2_p2`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a101.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a101_u2_p2_check", false) == true
}
# jdg.final.a101.u3.p3 — `final_a101_u3_p3`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a101.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a101_u3_p3_check", false) == true
}
# jdg.final.a101.u4.p4 — `final_a101_u4_p4`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a101.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a101_u4_p4_check", false) == true
}
# jdg.final.a102.u1.p2 — `final_a102_u1_p2`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a102.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a102_u1_p2_check", false) == true
}
# jdg.final.a102.u2.p3 — `final_a102_u2_p3`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a102.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a102_u2_p3_check", false) == true
}
# jdg.final.a102.u5.p1 — `final_a102_u5_p1`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a102.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a102_u5_p1_check", false) == true
}
# jdg.final.a103.u3.p4 — `final_a103_u3_p4`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a103.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a103_u3_p4_check", false) == true
}
# jdg.final.a103.u4.p1 — `final_a103_u4_p1`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a103.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a103_u4_p1_check", false) == true
}
# jdg.final.a103.u5.p2 — `final_a103_u5_p2`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a103.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a103_u5_p2_check", false) == true
}
# jdg.final.a104.u1.p3 — `final_a104_u1_p3`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a104.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a104_u1_p3_check", false) == true
}
# jdg.final.a104.u2.p4 — `final_a104_u2_p4`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a104.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a104_u2_p4_check", false) == true
}
# jdg.final.a104.u3.p1 — `final_a104_u3_p1`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a104.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a104_u3_p1_check", false) == true
}
# jdg.final.a105.u1.p4 — `final_a105_u1_p4`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a105.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a105_u1_p4_check", false) == true
}
# jdg.final.a105.u4.p2 — `final_a105_u4_p2`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a105.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a105_u4_p2_check", false) == true
}
# jdg.final.a105.u5.p3 — `final_a105_u5_p3`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a105.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a105_u5_p3_check", false) == true
}
# jdg.final.a106.u2.p1 — `final_a106_u2_p1`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a106.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a106_u2_p1_check", false) == true
}
# jdg.final.a106.u3.p2 — `final_a106_u3_p2`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a106.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a106_u3_p2_check", false) == true
}
# jdg.final.a106.u4.p3 — `final_a106_u4_p3`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a106.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a106_u4_p3_check", false) == true
}
# jdg.final.a107.u1.p1 — `final_a107_u1_p1`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a107.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a107_u1_p1_check", false) == true
}
# jdg.final.a107.u2.p2 — `final_a107_u2_p2`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a107.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a107_u2_p2_check", false) == true
}
# jdg.final.a107.u5.p4 — `final_a107_u5_p4`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a107.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a107_u5_p4_check", false) == true
}
# jdg.final.a108.u3.p3 — `final_a108_u3_p3`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a108.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a108_u3_p3_check", false) == true
}
# jdg.final.a108.u4.p4 — `final_a108_u4_p4`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a108.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a108_u4_p4_check", false) == true
}
# jdg.final.a108.u5.p1 — `final_a108_u5_p1`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a108.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a108_u5_p1_check", false) == true
}
# jdg.final.a109.u1.p2 — `final_a109_u1_p2`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a109.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 109 ustawy o VAT (ewidencja VAT) — patrz jdg.micro.vat.a109.*",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a109_u1_p2_check", false) == true
}
# jdg.final.a109.u2.p3 — `final_a109_u2_p3`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a109.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 109 ustawy o VAT (ewidencja VAT) — patrz jdg.micro.vat.a109.*",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a109_u2_p3_check", false) == true
}
# jdg.final.a109.u3.p4 — `final_a109_u3_p4`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a109.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 109 ustawy o VAT (ewidencja VAT) — patrz jdg.micro.vat.a109.*",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a109_u3_p4_check", false) == true
}
# jdg.final.a110.u1.p3 — `final_a110_u1_p3`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a110.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a110_u1_p3_check", false) == true
}
# jdg.final.a110.u4.p1 — `final_a110_u4_p1`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a110.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a110_u4_p1_check", false) == true
}
# jdg.final.a110.u5.p2 — `final_a110_u5_p2`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a110.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a110_u5_p2_check", false) == true
}
# jdg.final.a111.u2.p4 — `final_a111_u2_p4`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a111.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a111_u2_p4_check", false) == true
}
# jdg.final.a111.u3.p1 — `final_a111_u3_p1`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a111.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a111_u3_p1_check", false) == true
}
# jdg.final.a111.u4.p2 — `final_a111_u4_p2`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a111.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a111_u4_p2_check", false) == true
}
# jdg.final.a112.u1.p4 — `final_a112_u1_p4`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a112.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a112_u1_p4_check", false) == true
}
# jdg.final.a112.u2.p1 — `final_a112_u2_p1`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a112.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a112_u2_p1_check", false) == true
}
# jdg.final.a112.u5.p3 — `final_a112_u5_p3`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a112.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a112_u5_p3_check", false) == true
}
# jdg.final.a113.u3.p2 — `final_a113_u3_p2`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a113.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a113_u3_p2_check", false) == true
}
# jdg.final.a113.u4.p3 — `final_a113_u4_p3`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a113.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a113_u4_p3_check", false) == true
}
# jdg.final.a113.u5.p4 — `final_a113_u5_p4`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a113.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a113_u5_p4_check", false) == true
}
# jdg.final.a114.u1.p1 — `final_a114_u1_p1`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a114.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a114_u1_p1_check", false) == true
}
# jdg.final.a114.u2.p2 — `final_a114_u2_p2`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a114.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a114_u2_p2_check", false) == true
}
# jdg.final.a114.u3.p3 — `final_a114_u3_p3`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a114.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a114_u3_p3_check", false) == true
}
# jdg.final.a115.u1.p2 — `final_a115_u1_p2`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a115.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a115_u1_p2_check", false) == true
}
# jdg.final.a115.u4.p4 — `final_a115_u4_p4`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a115.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a115_u4_p4_check", false) == true
}
# jdg.final.a115.u5.p1 — `final_a115_u5_p1`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a115.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a115_u5_p1_check", false) == true
}
# jdg.final.a116.u2.p3 — `final_a116_u2_p3`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a116.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a116_u2_p3_check", false) == true
}
# jdg.final.a116.u3.p4 — `final_a116_u3_p4`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a116.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a116_u3_p4_check", false) == true
}
# jdg.final.a116.u4.p1 — `final_a116_u4_p1`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a116.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a116_u4_p1_check", false) == true
}
# jdg.final.a117.u1.p3 — `final_a117_u1_p3`: Art. 117 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a117.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 117 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 117: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a117_u1_p3_check", false) == true
}
# jdg.final.a117.u5.p2 — `final_a117_u5_p2`: Art. 117 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.final.a117.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 117 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT — przepisy końcowe",
    "_warnings": ["[MICRO] Art. 117: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "final_a117_u5_p2_check", false) == true
}
# jdg.gaar.r1 — `gaar_r1`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.gaar.r1",
    "package": "jdg.micro.general",
    "priority": 50051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.gaar.r1 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Przepisy prawa polskiego",
    "_warnings": ["[MICRO] jdg.gaar.r1: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "gaar_r1_check", false) == true
}
# jdg.vat.a103.r3 — `vat_a103_r3`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a103.r3",
    "package": "jdg.micro.vat",
    "priority": 50052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a103_r3_check", false) == true
}
# jdg.vat.a11.u1.p1 — `vat_a11_u1_p1`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a11.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a11_u1_p1_check", false) == true
}
# jdg.vat.a11.u2.p2 — `vat_a11_u2_p2`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a11.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a11_u2_p2_check", false) == true
}
# jdg.vat.a11.u3.p3 — `vat_a11_u3_p3`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a11.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a11_u3_p3_check", false) == true
}
# jdg.vat.a11.u4.p4 — `vat_a11_u4_p4`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a11.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a11_u4_p4_check", false) == true
}
# jdg.vat.a12.u1.p2 — `vat_a12_u1_p2`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a12.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a12_u1_p2_check", false) == true
}
# jdg.vat.a12.u2.p3 — `vat_a12_u2_p3`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a12.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a12_u2_p3_check", false) == true
}
# jdg.vat.a12.u3.p4 — `vat_a12_u3_p4`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a12.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a12_u3_p4_check", false) == true
}
# jdg.vat.a12.u5.p1 — `vat_a12_u5_p1`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a12.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a12_u5_p1_check", false) == true
}
# jdg.vat.a13.u1.p3 — `vat_a13_u1_p3`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a13.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a13_u1_p3_check", false) == true
}
# jdg.vat.a13.u2.p4 — `vat_a13_u2_p4`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a13.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a13_u2_p4_check", false) == true
}
# jdg.vat.a13.u4.p1 — `vat_a13_u4_p1`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a13.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a13_u4_p1_check", false) == true
}
# jdg.vat.a13.u5.p2 — `vat_a13_u5_p2`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a13.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a13_u5_p2_check", false) == true
}
# jdg.vat.a130.u1.p1 — `vat_a130_u1_p1`: Art. 130 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a130.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 130 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 130: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a130_u1_p1_check", false) == true
}
# jdg.vat.a130.u2.p2 — `vat_a130_u2_p2`: Art. 130 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a130.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 130 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 130: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a130_u2_p2_check", false) == true
}
# jdg.vat.a130.u3.p3 — `vat_a130_u3_p3`: Art. 130 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a130.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 130 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 130: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a130_u3_p3_check", false) == true
}
# jdg.vat.a130.u4.p4 — `vat_a130_u4_p4`: Art. 130 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a130.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 130 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 130: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a130_u4_p4_check", false) == true
}
# jdg.vat.a131.u1.p2 — `vat_a131_u1_p2`: Art. 131 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a131.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 131 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 131: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a131_u1_p2_check", false) == true
}
# jdg.vat.a131.u2.p3 — `vat_a131_u2_p3`: Art. 131 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a131.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 131 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 131: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a131_u2_p3_check", false) == true
}
# jdg.vat.a131.u3.p4 — `vat_a131_u3_p4`: Art. 131 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a131.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 131 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 131: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a131_u3_p4_check", false) == true
}
# jdg.vat.a131.u5.p1 — `vat_a131_u5_p1`: Art. 131 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a131.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 131 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 131: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a131_u5_p1_check", false) == true
}
# jdg.vat.a132.u1.p3 — `vat_a132_u1_p3`: Art. 132 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a132.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 132 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 132: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a132_u1_p3_check", false) == true
}
# jdg.vat.a132.u2.p4 — `vat_a132_u2_p4`: Art. 132 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a132.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 132 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 132: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a132_u2_p4_check", false) == true
}
# jdg.vat.a132.u4.p1 — `vat_a132_u4_p1`: Art. 132 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a132.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 132 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 132: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a132_u4_p1_check", false) == true
}
# jdg.vat.a132.u5.p2 — `vat_a132_u5_p2`: Art. 132 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a132.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 132 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 132: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a132_u5_p2_check", false) == true
}
# jdg.vat.a133.u1.p4 — `vat_a133_u1_p4`: Art. 133 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a133.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 133 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 133: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a133_u1_p4_check", false) == true
}
# jdg.vat.a133.u3.p1 — `vat_a133_u3_p1`: Art. 133 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a133.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 133 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 133: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a133_u3_p1_check", false) == true
}
# jdg.vat.a133.u4.p2 — `vat_a133_u4_p2`: Art. 133 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a133.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 133 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 133: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a133_u4_p2_check", false) == true
}
# jdg.vat.a133.u5.p3 — `vat_a133_u5_p3`: Art. 133 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a133.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 133 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 133: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a133_u5_p3_check", false) == true
}
# jdg.vat.a134.u2.p1 — `vat_a134_u2_p1`: Art. 134 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a134.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 134 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 134: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a134_u2_p1_check", false) == true
}
# jdg.vat.a134.u3.p2 — `vat_a134_u3_p2`: Art. 134 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a134.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 134 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 134: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a134_u3_p2_check", false) == true
}
# jdg.vat.a134.u4.p3 — `vat_a134_u4_p3`: Art. 134 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a134.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 134 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 134: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a134_u4_p3_check", false) == true
}
# jdg.vat.a134.u5.p4 — `vat_a134_u5_p4`: Art. 134 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a134.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 134 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 134: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a134_u5_p4_check", false) == true
}
# jdg.vat.a135.u1.p1 — `vat_a135_u1_p1`: Art. 135 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a135.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 135 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 135: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_u1_p1_check", false) == true
}
# jdg.vat.a135.u2.p2 — `vat_a135_u2_p2`: Art. 135 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a135.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 135 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 135: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_u2_p2_check", false) == true
}
# jdg.vat.a135.u3.p3 — `vat_a135_u3_p3`: Art. 135 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a135.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 135 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 135: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_u3_p3_check", false) == true
}
# jdg.vat.a135.u4.p4 — `vat_a135_u4_p4`: Art. 135 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a135.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 135 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 135: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a135_u4_p4_check", false) == true
}
# jdg.vat.a136.u1.p2 — `vat_a136_u1_p2`: Art. 136 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a136.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 136 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 136: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a136_u1_p2_check", false) == true
}
# jdg.vat.a136.u2.p3 — `vat_a136_u2_p3`: Art. 136 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a136.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 136 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 136: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a136_u2_p3_check", false) == true
}
# jdg.vat.a136.u3.p4 — `vat_a136_u3_p4`: Art. 136 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a136.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 136 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 136: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a136_u3_p4_check", false) == true
}
# jdg.vat.a136.u5.p1 — `vat_a136_u5_p1`: Art. 136 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a136.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 136 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 136: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a136_u5_p1_check", false) == true
}
# jdg.vat.a137.u1.p3 — `vat_a137_u1_p3`: Art. 137 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a137.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 137 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 137: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a137_u1_p3_check", false) == true
}
# jdg.vat.a137.u2.p4 — `vat_a137_u2_p4`: Art. 137 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a137.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 137 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 137: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a137_u2_p4_check", false) == true
}
# jdg.vat.a137.u4.p1 — `vat_a137_u4_p1`: Art. 137 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a137.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 137 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 137: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a137_u4_p1_check", false) == true
}
# jdg.vat.a137.u5.p2 — `vat_a137_u5_p2`: Art. 137 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a137.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 137 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 137: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a137_u5_p2_check", false) == true
}
# jdg.vat.a138.u1.p4 — `vat_a138_u1_p4`: Art. 138 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a138.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 138 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 138: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a138_u1_p4_check", false) == true
}
# jdg.vat.a138.u3.p1 — `vat_a138_u3_p1`: Art. 138 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a138.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 138 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 138: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a138_u3_p1_check", false) == true
}
# jdg.vat.a138.u4.p2 — `vat_a138_u4_p2`: Art. 138 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a138.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 138 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 138: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a138_u4_p2_check", false) == true
}
# jdg.vat.a138.u5.p3 — `vat_a138_u5_p3`: Art. 138 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a138.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 138 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 138: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a138_u5_p3_check", false) == true
}
# jdg.vat.a139.u2.p1 — `vat_a139_u2_p1`: Art. 139 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a139.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 139 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 139: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a139_u2_p1_check", false) == true
}
# jdg.vat.a139.u3.p2 — `vat_a139_u3_p2`: Art. 139 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a139.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 139 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 139: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a139_u3_p2_check", false) == true
}
# jdg.vat.a139.u4.p3 — `vat_a139_u4_p3`: Art. 139 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a139.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 139 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 139: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a139_u4_p3_check", false) == true
}
# jdg.vat.a139.u5.p4 — `vat_a139_u5_p4`: Art. 139 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a139.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 139 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 139: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a139_u5_p4_check", false) == true
}
# jdg.vat.a14.u1.p4 — `vat_a14_u1_p4`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a14.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a14_u1_p4_check", false) == true
}
# jdg.vat.a14.u3.p1 — `vat_a14_u3_p1`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a14.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a14_u3_p1_check", false) == true
}
# jdg.vat.a14.u4.p2 — `vat_a14_u4_p2`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a14.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a14_u4_p2_check", false) == true
}
# jdg.vat.a14.u5.p3 — `vat_a14_u5_p3`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a14.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a14_u5_p3_check", false) == true
}
# jdg.vat.a140.u1.p1 — `vat_a140_u1_p1`: Art. 140 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a140.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 140 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 140: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a140_u1_p1_check", false) == true
}
# jdg.vat.a140.u2.p2 — `vat_a140_u2_p2`: Art. 140 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a140.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 140 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 140: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a140_u2_p2_check", false) == true
}
# jdg.vat.a140.u3.p3 — `vat_a140_u3_p3`: Art. 140 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a140.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 140 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 140: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a140_u3_p3_check", false) == true
}
# jdg.vat.a140.u4.p4 — `vat_a140_u4_p4`: Art. 140 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a140.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 140 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 140: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a140_u4_p4_check", false) == true
}
# jdg.vat.a141.u1.p2 — `vat_a141_u1_p2`: Art. 141 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a141.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 141 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 141: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a141_u1_p2_check", false) == true
}
# jdg.vat.a141.u2.p3 — `vat_a141_u2_p3`: Art. 141 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a141.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 141 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 141: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a141_u2_p3_check", false) == true
}
# jdg.vat.a141.u3.p4 — `vat_a141_u3_p4`: Art. 141 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a141.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 141 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 141: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a141_u3_p4_check", false) == true
}
# jdg.vat.a141.u5.p1 — `vat_a141_u5_p1`: Art. 141 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a141.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 141 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 141: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a141_u5_p1_check", false) == true
}
# jdg.vat.a142.u1.p3 — `vat_a142_u1_p3`: Art. 142 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a142.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 142 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 142: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a142_u1_p3_check", false) == true
}
# jdg.vat.a142.u2.p4 — `vat_a142_u2_p4`: Art. 142 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a142.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 142 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 142: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a142_u2_p4_check", false) == true
}
# jdg.vat.a142.u4.p1 — `vat_a142_u4_p1`: Art. 142 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a142.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 142 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 142: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a142_u4_p1_check", false) == true
}
# jdg.vat.a142.u5.p2 — `vat_a142_u5_p2`: Art. 142 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a142.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 142 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 142: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a142_u5_p2_check", false) == true
}
# jdg.vat.a143.u1.p4 — `vat_a143_u1_p4`: Art. 143 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a143.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 143 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 143: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a143_u1_p4_check", false) == true
}
# jdg.vat.a143.u3.p1 — `vat_a143_u3_p1`: Art. 143 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a143.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 143 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 143: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a143_u3_p1_check", false) == true
}
# jdg.vat.a143.u4.p2 — `vat_a143_u4_p2`: Art. 143 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a143.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 143 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 143: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a143_u4_p2_check", false) == true
}
# jdg.vat.a143.u5.p3 — `vat_a143_u5_p3`: Art. 143 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a143.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 143 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 143: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a143_u5_p3_check", false) == true
}
# jdg.vat.a144.u2.p1 — `vat_a144_u2_p1`: Art. 144 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a144.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 144 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 144: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a144_u2_p1_check", false) == true
}
# jdg.vat.a144.u3.p2 — `vat_a144_u3_p2`: Art. 144 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a144.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 144 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 144: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a144_u3_p2_check", false) == true
}
# jdg.vat.a144.u4.p3 — `vat_a144_u4_p3`: Art. 144 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a144.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 144 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 144: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a144_u4_p3_check", false) == true
}
# jdg.vat.a144.u5.p4 — `vat_a144_u5_p4`: Art. 144 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a144.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50128,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 144 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 144: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a144_u5_p4_check", false) == true
}
# jdg.vat.a145.u1.p1 — `vat_a145_u1_p1`: Art. 145 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a145.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50129,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 145 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 145: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a145_u1_p1_check", false) == true
}
# jdg.vat.a145.u2.p2 — `vat_a145_u2_p2`: Art. 145 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a145.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50130,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 145 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 145: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a145_u2_p2_check", false) == true
}
# jdg.vat.a145.u3.p3 — `vat_a145_u3_p3`: Art. 145 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a145.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50131,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 145 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 145: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a145_u3_p3_check", false) == true
}
# jdg.vat.a145.u4.p4 — `vat_a145_u4_p4`: Art. 145 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a145.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50132,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 145 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 145: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a145_u4_p4_check", false) == true
}
# jdg.vat.a146.u1.p2 — `vat_a146_u1_p2`: Art. 146 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a146.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50133,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 146 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 146: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a146_u1_p2_check", false) == true
}
# jdg.vat.a146.u2.p3 — `vat_a146_u2_p3`: Art. 146 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a146.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50134,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 146 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 146: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a146_u2_p3_check", false) == true
}
# jdg.vat.a146.u3.p4 — `vat_a146_u3_p4`: Art. 146 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a146.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50135,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 146 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 146: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a146_u3_p4_check", false) == true
}
# jdg.vat.a146.u5.p1 — `vat_a146_u5_p1`: Art. 146 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a146.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50136,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 146 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 146: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a146_u5_p1_check", false) == true
}
# jdg.vat.a147.u1.p3 — `vat_a147_u1_p3`: Art. 147 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a147.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50137,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 147 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 147: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a147_u1_p3_check", false) == true
}
# jdg.vat.a147.u2.p4 — `vat_a147_u2_p4`: Art. 147 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a147.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50138,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 147 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 147: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a147_u2_p4_check", false) == true
}
# jdg.vat.a147.u4.p1 — `vat_a147_u4_p1`: Art. 147 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a147.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50139,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 147 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 147: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a147_u4_p1_check", false) == true
}
# jdg.vat.a147.u5.p2 — `vat_a147_u5_p2`: Art. 147 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a147.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50140,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 147 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 147: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a147_u5_p2_check", false) == true
}
# jdg.vat.a148.u1.p4 — `vat_a148_u1_p4`: Art. 148 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a148.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50141,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 148 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 148: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a148_u1_p4_check", false) == true
}
# jdg.vat.a148.u3.p1 — `vat_a148_u3_p1`: Art. 148 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a148.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50142,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 148 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 148: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a148_u3_p1_check", false) == true
}
# jdg.vat.a148.u4.p2 — `vat_a148_u4_p2`: Art. 148 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a148.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50143,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 148 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 148: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a148_u4_p2_check", false) == true
}
# jdg.vat.a148.u5.p3 — `vat_a148_u5_p3`: Art. 148 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a148.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50144,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 148 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 148: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a148_u5_p3_check", false) == true
}
# jdg.vat.a149.u2.p1 — `vat_a149_u2_p1`: Art. 149 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a149.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50145,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 149 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 149: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a149_u2_p1_check", false) == true
}
# jdg.vat.a149.u3.p2 — `vat_a149_u3_p2`: Art. 149 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a149.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50146,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 149 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 149: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a149_u3_p2_check", false) == true
}
# jdg.vat.a149.u4.p3 — `vat_a149_u4_p3`: Art. 149 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a149.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50147,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 149 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 149: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a149_u4_p3_check", false) == true
}
# jdg.vat.a149.u5.p4 — `vat_a149_u5_p4`: Art. 149 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a149.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50148,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 149 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 149: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a149_u5_p4_check", false) == true
}
# jdg.vat.a15.u2.p1 — `vat_a15_u2_p1`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a15.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50149,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a15_u2_p1_check", false) == true
}
# jdg.vat.a15.u3.p2 — `vat_a15_u3_p2`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a15.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50150,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a15_u3_p2_check", false) == true
}
# jdg.vat.a15.u4.p3 — `vat_a15_u4_p3`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a15.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50151,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a15_u4_p3_check", false) == true
}
# jdg.vat.a15.u5.p4 — `vat_a15_u5_p4`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a15.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50152,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a15_u5_p4_check", false) == true
}
# jdg.vat.a150.u1.p1 — `vat_a150_u1_p1`: Art. 150 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a150.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50153,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 150 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 150: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a150_u1_p1_check", false) == true
}
# jdg.vat.a150.u2.p2 — `vat_a150_u2_p2`: Art. 150 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a150.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50154,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 150 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 150: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a150_u2_p2_check", false) == true
}
# jdg.vat.a150.u3.p3 — `vat_a150_u3_p3`: Art. 150 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a150.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50155,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 150 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 150: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a150_u3_p3_check", false) == true
}
# jdg.vat.a150.u4.p4 — `vat_a150_u4_p4`: Art. 150 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a150.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50156,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 150 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 150: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a150_u4_p4_check", false) == true
}
# jdg.vat.a151.u1.p2 — `vat_a151_u1_p2`: Art. 151 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a151.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50157,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 151 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 151: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a151_u1_p2_check", false) == true
}
# jdg.vat.a151.u2.p3 — `vat_a151_u2_p3`: Art. 151 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a151.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50158,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 151 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 151: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a151_u2_p3_check", false) == true
}
# jdg.vat.a151.u3.p4 — `vat_a151_u3_p4`: Art. 151 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a151.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50159,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 151 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 151: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a151_u3_p4_check", false) == true
}
# jdg.vat.a151.u5.p1 — `vat_a151_u5_p1`: Art. 151 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a151.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50160,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 151 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 151: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a151_u5_p1_check", false) == true
}
# jdg.vat.a152.u1.p3 — `vat_a152_u1_p3`: Art. 152 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a152.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50161,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 152 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 152: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a152_u1_p3_check", false) == true
}
# jdg.vat.a152.u2.p4 — `vat_a152_u2_p4`: Art. 152 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a152.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50162,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 152 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 152: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a152_u2_p4_check", false) == true
}
# jdg.vat.a152.u4.p1 — `vat_a152_u4_p1`: Art. 152 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a152.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50163,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 152 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 152: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a152_u4_p1_check", false) == true
}
# jdg.vat.a152.u5.p2 — `vat_a152_u5_p2`: Art. 152 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a152.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50164,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 152 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 152: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a152_u5_p2_check", false) == true
}
# jdg.vat.a153.u1.p4 — `vat_a153_u1_p4`: Art. 153 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a153.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50165,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 153 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 153: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a153_u1_p4_check", false) == true
}
# jdg.vat.a153.u3.p1 — `vat_a153_u3_p1`: Art. 153 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a153.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50166,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 153 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 153: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a153_u3_p1_check", false) == true
}
# jdg.vat.a153.u4.p2 — `vat_a153_u4_p2`: Art. 153 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a153.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50167,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 153 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 153: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a153_u4_p2_check", false) == true
}
# jdg.vat.a153.u5.p3 — `vat_a153_u5_p3`: Art. 153 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a153.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50168,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 153 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 153: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a153_u5_p3_check", false) == true
}
# jdg.vat.a154.u2.p1 — `vat_a154_u2_p1`: Art. 154 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a154.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50169,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 154 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 154: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a154_u2_p1_check", false) == true
}
# jdg.vat.a154.u3.p2 — `vat_a154_u3_p2`: Art. 154 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a154.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50170,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 154 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 154: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a154_u3_p2_check", false) == true
}
# jdg.vat.a154.u4.p3 — `vat_a154_u4_p3`: Art. 154 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a154.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50171,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 154 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 154: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a154_u4_p3_check", false) == true
}
# jdg.vat.a154.u5.p4 — `vat_a154_u5_p4`: Art. 154 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a154.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50172,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 154 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 154: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a154_u5_p4_check", false) == true
}
# jdg.vat.a155.u1.p1 — `vat_a155_u1_p1`: Art. 155 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a155.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50173,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 155 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 155: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a155_u1_p1_check", false) == true
}
# jdg.vat.a155.u2.p2 — `vat_a155_u2_p2`: Art. 155 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a155.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50174,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 155 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 155: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a155_u2_p2_check", false) == true
}
# jdg.vat.a155.u3.p3 — `vat_a155_u3_p3`: Art. 155 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a155.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50175,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 155 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 155: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a155_u3_p3_check", false) == true
}
# jdg.vat.a155.u4.p4 — `vat_a155_u4_p4`: Art. 155 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a155.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50176,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 155 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 155: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a155_u4_p4_check", false) == true
}
# jdg.vat.a156.u1.p2 — `vat_a156_u1_p2`: Art. 156 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a156.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50177,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 156 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 156: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a156_u1_p2_check", false) == true
}
# jdg.vat.a156.u2.p3 — `vat_a156_u2_p3`: Art. 156 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a156.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50178,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 156 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 156: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a156_u2_p3_check", false) == true
}
# jdg.vat.a156.u3.p4 — `vat_a156_u3_p4`: Art. 156 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a156.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50179,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 156 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 156: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a156_u3_p4_check", false) == true
}
# jdg.vat.a156.u5.p1 — `vat_a156_u5_p1`: Art. 156 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a156.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50180,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 156 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 156: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a156_u5_p1_check", false) == true
}
# jdg.vat.a157.u1.p3 — `vat_a157_u1_p3`: Art. 157 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a157.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50181,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 157 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 157: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a157_u1_p3_check", false) == true
}
# jdg.vat.a157.u2.p4 — `vat_a157_u2_p4`: Art. 157 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a157.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50182,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 157 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 157: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a157_u2_p4_check", false) == true
}
# jdg.vat.a157.u4.p1 — `vat_a157_u4_p1`: Art. 157 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a157.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50183,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 157 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 157: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a157_u4_p1_check", false) == true
}
# jdg.vat.a157.u5.p2 — `vat_a157_u5_p2`: Art. 157 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a157.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50184,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 157 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 157: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a157_u5_p2_check", false) == true
}
# jdg.vat.a158.u1.p4 — `vat_a158_u1_p4`: Art. 158 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a158.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50185,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 158 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 158: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a158_u1_p4_check", false) == true
}
# jdg.vat.a158.u3.p1 — `vat_a158_u3_p1`: Art. 158 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a158.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50186,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 158 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 158: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a158_u3_p1_check", false) == true
}
# jdg.vat.a158.u4.p2 — `vat_a158_u4_p2`: Art. 158 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a158.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50187,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 158 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 158: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a158_u4_p2_check", false) == true
}
# jdg.vat.a158.u5.p3 — `vat_a158_u5_p3`: Art. 158 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a158.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50188,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 158 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 158: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a158_u5_p3_check", false) == true
}
# jdg.vat.a159.u2.p1 — `vat_a159_u2_p1`: Art. 159 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a159.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50189,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 159 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 159: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a159_u2_p1_check", false) == true
}
# jdg.vat.a159.u3.p2 — `vat_a159_u3_p2`: Art. 159 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a159.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50190,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 159 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 159: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a159_u3_p2_check", false) == true
}
# jdg.vat.a159.u4.p3 — `vat_a159_u4_p3`: Art. 159 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a159.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50191,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 159 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 159: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a159_u4_p3_check", false) == true
}
# jdg.vat.a159.u5.p4 — `vat_a159_u5_p4`: Art. 159 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a159.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50192,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 159 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 159: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a159_u5_p4_check", false) == true
}
# jdg.vat.a16.u1.p1 — `vat_a16_u1_p1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a16.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50193,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a16_u1_p1_check", false) == true
}
# jdg.vat.a16.u2.p2 — `vat_a16_u2_p2`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a16.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50194,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a16_u2_p2_check", false) == true
}
# jdg.vat.a16.u3.p3 — `vat_a16_u3_p3`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a16.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50195,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a16_u3_p3_check", false) == true
}
# jdg.vat.a16.u4.p4 — `vat_a16_u4_p4`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a16.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50196,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a16_u4_p4_check", false) == true
}
# jdg.vat.a160.u1.p1 — `vat_a160_u1_p1`: Art. 160 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a160.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50197,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 160 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 160: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a160_u1_p1_check", false) == true
}
# jdg.vat.a160.u2.p2 — `vat_a160_u2_p2`: Art. 160 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a160.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50198,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 160 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 160: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a160_u2_p2_check", false) == true
}
# jdg.vat.a160.u3.p3 — `vat_a160_u3_p3`: Art. 160 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a160.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50199,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 160 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 160: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a160_u3_p3_check", false) == true
}
# jdg.vat.a160.u4.p4 — `vat_a160_u4_p4`: Art. 160 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a160.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50200,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 160 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 160: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a160_u4_p4_check", false) == true
}
# jdg.vat.a161.u1.p2 — `vat_a161_u1_p2`: Art. 161 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a161.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50201,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 161 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 161: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a161_u1_p2_check", false) == true
}
# jdg.vat.a161.u2.p3 — `vat_a161_u2_p3`: Art. 161 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a161.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50202,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 161 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 161: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a161_u2_p3_check", false) == true
}
# jdg.vat.a161.u3.p4 — `vat_a161_u3_p4`: Art. 161 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a161.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50203,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 161 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 161: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a161_u3_p4_check", false) == true
}
# jdg.vat.a161.u5.p1 — `vat_a161_u5_p1`: Art. 161 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a161.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50204,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 161 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 161: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a161_u5_p1_check", false) == true
}
# jdg.vat.a162.u1.p3 — `vat_a162_u1_p3`: Art. 162 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a162.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50205,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 162 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 162: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a162_u1_p3_check", false) == true
}
# jdg.vat.a162.u2.p4 — `vat_a162_u2_p4`: Art. 162 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a162.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50206,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 162 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 162: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a162_u2_p4_check", false) == true
}
# jdg.vat.a162.u4.p1 — `vat_a162_u4_p1`: Art. 162 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a162.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50207,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 162 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 162: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a162_u4_p1_check", false) == true
}
# jdg.vat.a162.u5.p2 — `vat_a162_u5_p2`: Art. 162 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a162.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50208,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 162 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 162: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a162_u5_p2_check", false) == true
}
# jdg.vat.a163.u1.p4 — `vat_a163_u1_p4`: Art. 163 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a163.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50209,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 163 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 163: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a163_u1_p4_check", false) == true
}
# jdg.vat.a163.u3.p1 — `vat_a163_u3_p1`: Art. 163 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a163.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50210,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 163 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 163: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a163_u3_p1_check", false) == true
}
# jdg.vat.a163.u4.p2 — `vat_a163_u4_p2`: Art. 163 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a163.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50211,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 163 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 163: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a163_u4_p2_check", false) == true
}
# jdg.vat.a163.u5.p3 — `vat_a163_u5_p3`: Art. 163 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a163.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50212,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 163 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 163: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a163_u5_p3_check", false) == true
}
# jdg.vat.a164.u2.p1 — `vat_a164_u2_p1`: Art. 164 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a164.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50213,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 164 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 164: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a164_u2_p1_check", false) == true
}
# jdg.vat.a164.u3.p2 — `vat_a164_u3_p2`: Art. 164 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a164.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50214,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 164 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 164: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a164_u3_p2_check", false) == true
}
# jdg.vat.a164.u4.p3 — `vat_a164_u4_p3`: Art. 164 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a164.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50215,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 164 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 164: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a164_u4_p3_check", false) == true
}
# jdg.vat.a164.u5.p4 — `vat_a164_u5_p4`: Art. 164 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a164.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50216,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 164 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 164: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a164_u5_p4_check", false) == true
}
# jdg.vat.a165.u1.p1 — `vat_a165_u1_p1`: Art. 165 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a165.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50217,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 165 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 165: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a165_u1_p1_check", false) == true
}
# jdg.vat.a165.u2.p2 — `vat_a165_u2_p2`: Art. 165 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a165.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50218,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 165 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 165: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a165_u2_p2_check", false) == true
}
# jdg.vat.a165.u3.p3 — `vat_a165_u3_p3`: Art. 165 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a165.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50219,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 165 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 165: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a165_u3_p3_check", false) == true
}
# jdg.vat.a165.u4.p4 — `vat_a165_u4_p4`: Art. 165 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a165.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50220,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 165 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 165: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a165_u4_p4_check", false) == true
}
# jdg.vat.a166.u1.p2 — `vat_a166_u1_p2`: Art. 166 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a166.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50221,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 166 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 166: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a166_u1_p2_check", false) == true
}
# jdg.vat.a166.u2.p3 — `vat_a166_u2_p3`: Art. 166 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a166.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50222,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 166 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 166: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a166_u2_p3_check", false) == true
}
# jdg.vat.a166.u3.p4 — `vat_a166_u3_p4`: Art. 166 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a166.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50223,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 166 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 166: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a166_u3_p4_check", false) == true
}
# jdg.vat.a166.u5.p1 — `vat_a166_u5_p1`: Art. 166 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a166.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50224,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 166 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 166: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a166_u5_p1_check", false) == true
}
# jdg.vat.a167.u1.p3 — `vat_a167_u1_p3`: Art. 167 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a167.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50225,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 167 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 167: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a167_u1_p3_check", false) == true
}
# jdg.vat.a167.u2.p4 — `vat_a167_u2_p4`: Art. 167 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a167.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50226,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 167 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 167: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a167_u2_p4_check", false) == true
}
# jdg.vat.a167.u4.p1 — `vat_a167_u4_p1`: Art. 167 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a167.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50227,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 167 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 167: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a167_u4_p1_check", false) == true
}
# jdg.vat.a167.u5.p2 — `vat_a167_u5_p2`: Art. 167 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a167.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50228,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 167 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 167: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a167_u5_p2_check", false) == true
}
# jdg.vat.a168.u1.p4 — `vat_a168_u1_p4`: Art. 168 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a168.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50229,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 168 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 168: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a168_u1_p4_check", false) == true
}
# jdg.vat.a168.u3.p1 — `vat_a168_u3_p1`: Art. 168 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a168.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50230,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 168 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 168: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a168_u3_p1_check", false) == true
}
# jdg.vat.a168.u4.p2 — `vat_a168_u4_p2`: Art. 168 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a168.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50231,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 168 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 168: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a168_u4_p2_check", false) == true
}
# jdg.vat.a168.u5.p3 — `vat_a168_u5_p3`: Art. 168 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a168.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50232,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 168 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 168: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a168_u5_p3_check", false) == true
}
# jdg.vat.a169.u2.p1 — `vat_a169_u2_p1`: Art. 169 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a169.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50233,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 169 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 169: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a169_u2_p1_check", false) == true
}
# jdg.vat.a169.u3.p2 — `vat_a169_u3_p2`: Art. 169 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a169.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50234,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 169 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 169: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a169_u3_p2_check", false) == true
}
# jdg.vat.a169.u4.p3 — `vat_a169_u4_p3`: Art. 169 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a169.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50235,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 169 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 169: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a169_u4_p3_check", false) == true
}
# jdg.vat.a169.u5.p4 — `vat_a169_u5_p4`: Art. 169 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a169.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50236,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 169 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 169: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a169_u5_p4_check", false) == true
}
# jdg.vat.a17.u1.p2 — `vat_a17_u1_p2`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a17.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50237,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a17_u1_p2_check", false) == true
}
# jdg.vat.a17.u2.p3 — `vat_a17_u2_p3`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a17.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50238,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a17_u2_p3_check", false) == true
}
# jdg.vat.a17.u3.p4 — `vat_a17_u3_p4`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a17.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50239,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a17_u3_p4_check", false) == true
}
# jdg.vat.a17.u5.p1 — `vat_a17_u5_p1`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a17.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50240,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a17_u5_p1_check", false) == true
}
# jdg.vat.a170.u1.p1 — `vat_a170_u1_p1`: Art. 170 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a170.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50241,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 170 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 170: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a170_u1_p1_check", false) == true
}
# jdg.vat.a170.u2.p2 — `vat_a170_u2_p2`: Art. 170 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a170.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50242,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 170 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 170: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a170_u2_p2_check", false) == true
}
# jdg.vat.a170.u3.p3 — `vat_a170_u3_p3`: Art. 170 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a170.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50243,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 170 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 170: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a170_u3_p3_check", false) == true
}
# jdg.vat.a170.u4.p4 — `vat_a170_u4_p4`: Art. 170 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a170.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50244,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 170 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 170: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a170_u4_p4_check", false) == true
}
# jdg.vat.a171.u1.p2 — `vat_a171_u1_p2`: Art. 171 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a171.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50245,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 171 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 171: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a171_u1_p2_check", false) == true
}
# jdg.vat.a171.u2.p3 — `vat_a171_u2_p3`: Art. 171 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a171.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50246,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 171 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 171: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a171_u2_p3_check", false) == true
}
# jdg.vat.a171.u3.p4 — `vat_a171_u3_p4`: Art. 171 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a171.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50247,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 171 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 171: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a171_u3_p4_check", false) == true
}
# jdg.vat.a171.u5.p1 — `vat_a171_u5_p1`: Art. 171 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a171.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50248,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 171 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 171: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a171_u5_p1_check", false) == true
}
# jdg.vat.a172.u4.p1 — `vat_a172_u4_p1`: Art. 172 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a172.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50249,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 172 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 172: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a172_u4_p1_check", false) == true
}
# jdg.vat.a18.u1.p3 — `vat_a18_u1_p3`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a18.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50250,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a18_u1_p3_check", false) == true
}
# jdg.vat.a18.u2.p4 — `vat_a18_u2_p4`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a18.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50251,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a18_u2_p4_check", false) == true
}
# jdg.vat.a18.u4.p1 — `vat_a18_u4_p1`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a18.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50252,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a18_u4_p1_check", false) == true
}
# jdg.vat.a18.u5.p2 — `vat_a18_u5_p2`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a18.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50253,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a18_u5_p2_check", false) == true
}
# jdg.vat.a19.u1.p4 — `vat_a19_u1_p4`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a19.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50254,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a19_u1_p4_check", false) == true
}
# jdg.vat.a19.u3.p1 — `vat_a19_u3_p1`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a19.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50255,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a19_u3_p1_check", false) == true
}
# jdg.vat.a19.u4.p2 — `vat_a19_u4_p2`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a19.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50256,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a19_u4_p2_check", false) == true
}
# jdg.vat.a19.u5.p3 — `vat_a19_u5_p3`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a19.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50257,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a19_u5_p3_check", false) == true
}
# jdg.vat.a20.u2.p1 — `vat_a20_u2_p1`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a20.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50258,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a20_u2_p1_check", false) == true
}
# jdg.vat.a20.u3.p2 — `vat_a20_u3_p2`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a20.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50259,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a20_u3_p2_check", false) == true
}
# jdg.vat.a20.u4.p3 — `vat_a20_u4_p3`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a20.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50260,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a20_u4_p3_check", false) == true
}
# jdg.vat.a20.u5.p4 — `vat_a20_u5_p4`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a20.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50261,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a20_u5_p4_check", false) == true
}
# jdg.vat.a21.u1.p1 — `vat_a21_u1_p1`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a21.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50262,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a21_u1_p1_check", false) == true
}
# jdg.vat.a21.u2.p2 — `vat_a21_u2_p2`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a21.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50263,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a21_u2_p2_check", false) == true
}
# jdg.vat.a21.u3.p3 — `vat_a21_u3_p3`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a21.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50264,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a21_u3_p3_check", false) == true
}
# jdg.vat.a21.u4.p4 — `vat_a21_u4_p4`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a21.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50265,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a21_u4_p4_check", false) == true
}
# jdg.vat.a22.u1.p2 — `vat_a22_u1_p2`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a22.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50266,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a22_u1_p2_check", false) == true
}
# jdg.vat.a22.u2.p3 — `vat_a22_u2_p3`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a22.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50267,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a22_u2_p3_check", false) == true
}
# jdg.vat.a22.u3.p4 — `vat_a22_u3_p4`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a22.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50268,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a22_u3_p4_check", false) == true
}
# jdg.vat.a22.u5.p1 — `vat_a22_u5_p1`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a22.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50269,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a22_u5_p1_check", false) == true
}
# jdg.vat.a23.u1.p3 — `vat_a23_u1_p3`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a23.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50270,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a23_u1_p3_check", false) == true
}
# jdg.vat.a23.u2.p4 — `vat_a23_u2_p4`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a23.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50271,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a23_u2_p4_check", false) == true
}
# jdg.vat.a23.u4.p1 — `vat_a23_u4_p1`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a23.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50272,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a23_u4_p1_check", false) == true
}
# jdg.vat.a23.u5.p2 — `vat_a23_u5_p2`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a23.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50273,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a23_u5_p2_check", false) == true
}
# jdg.vat.a24.u1.p4 — `vat_a24_u1_p4`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a24.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50274,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a24_u1_p4_check", false) == true
}
# jdg.vat.a24.u3.p1 — `vat_a24_u3_p1`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a24.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50275,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a24_u3_p1_check", false) == true
}
# jdg.vat.a24.u4.p2 — `vat_a24_u4_p2`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a24.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50276,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a24_u4_p2_check", false) == true
}
# jdg.vat.a24.u5.p3 — `vat_a24_u5_p3`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a24.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50277,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a24_u5_p3_check", false) == true
}
# jdg.vat.a25.u2.p1 — `vat_a25_u2_p1`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a25.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50278,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a25_u2_p1_check", false) == true
}
# jdg.vat.a25.u3.p2 — `vat_a25_u3_p2`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a25.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50279,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a25_u3_p2_check", false) == true
}
# jdg.vat.a25.u4.p3 — `vat_a25_u4_p3`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a25.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50280,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a25_u4_p3_check", false) == true
}
# jdg.vat.a25.u5.p4 — `vat_a25_u5_p4`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a25.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50281,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a25_u5_p4_check", false) == true
}
# jdg.vat.a26.u1.p1 — `vat_a26_u1_p1`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a26.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50282,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a26_u1_p1_check", false) == true
}
# jdg.vat.a26.u2.p2 — `vat_a26_u2_p2`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a26.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50283,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a26_u2_p2_check", false) == true
}
# jdg.vat.a26.u3.p3 — `vat_a26_u3_p3`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a26.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50284,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a26_u3_p3_check", false) == true
}
# jdg.vat.a26.u4.p4 — `vat_a26_u4_p4`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a26.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50285,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a26_u4_p4_check", false) == true
}
# jdg.vat.a27.u1.p2 — `vat_a27_u1_p2`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a27.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50286,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a27_u1_p2_check", false) == true
}
# jdg.vat.a27.u2.p3 — `vat_a27_u2_p3`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a27.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50287,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a27_u2_p3_check", false) == true
}
# jdg.vat.a27.u3.p4 — `vat_a27_u3_p4`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a27.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50288,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a27_u3_p4_check", false) == true
}
# jdg.vat.a27.u5.p1 — `vat_a27_u5_p1`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a27.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50289,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a27_u5_p1_check", false) == true
}
# jdg.vat.a28.u1.p3 — `vat_a28_u1_p3`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a28.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50290,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a28_u1_p3_check", false) == true
}
# jdg.vat.a28.u2.p4 — `vat_a28_u2_p4`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a28.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50291,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a28_u2_p4_check", false) == true
}
# jdg.vat.a28.u4.p1 — `vat_a28_u4_p1`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a28.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50292,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a28_u4_p1_check", false) == true
}
# jdg.vat.a28.u5.p2 — `vat_a28_u5_p2`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a28.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50293,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a28_u5_p2_check", false) == true
}
# jdg.vat.a29.u1.p4 — `vat_a29_u1_p4`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a29.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50294,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a29_u1_p4_check", false) == true
}
# jdg.vat.a29.u3.p1 — `vat_a29_u3_p1`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a29.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50295,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a29_u3_p1_check", false) == true
}
# jdg.vat.a29.u4.p2 — `vat_a29_u4_p2`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a29.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50296,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a29_u4_p2_check", false) == true
}
# jdg.vat.a29.u5.p3 — `vat_a29_u5_p3`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a29.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50297,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a29_u5_p3_check", false) == true
}
# jdg.vat.a30.u2.p1 — `vat_a30_u2_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a30.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50298,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a30_u2_p1_check", false) == true
}
# jdg.vat.a30.u3.p2 — `vat_a30_u3_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a30.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50299,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a30_u3_p2_check", false) == true
}
# jdg.vat.a30.u4.p3 — `vat_a30_u4_p3`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a30.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50300,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a30_u4_p3_check", false) == true
}
# jdg.vat.a30.u5.p4 — `vat_a30_u5_p4`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a30.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50301,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a30_u5_p4_check", false) == true
}
# jdg.vat.a31.u1.p1 — `vat_a31_u1_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a31.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50302,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a31_u1_p1_check", false) == true
}
# jdg.vat.a31.u2.p2 — `vat_a31_u2_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a31.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50303,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a31_u2_p2_check", false) == true
}
# jdg.vat.a31.u3.p3 — `vat_a31_u3_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a31.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50304,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a31_u3_p3_check", false) == true
}
# jdg.vat.a31.u4.p4 — `vat_a31_u4_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a31.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50305,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a31_u4_p4_check", false) == true
}
# jdg.vat.a32.u1.p2 — `vat_a32_u1_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a32.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50306,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a32_u1_p2_check", false) == true
}
# jdg.vat.a32.u2.p3 — `vat_a32_u2_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a32.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50307,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a32_u2_p3_check", false) == true
}
# jdg.vat.a32.u3.p4 — `vat_a32_u3_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a32.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50308,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a32_u3_p4_check", false) == true
}
# jdg.vat.a32.u5.p1 — `vat_a32_u5_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a32.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50309,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a32_u5_p1_check", false) == true
}
# jdg.vat.a33.u1.p3 — `vat_a33_u1_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a33.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50310,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a33_u1_p3_check", false) == true
}
# jdg.vat.a33.u2.p4 — `vat_a33_u2_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a33.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50311,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a33_u2_p4_check", false) == true
}
# jdg.vat.a33.u4.p1 — `vat_a33_u4_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a33.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50312,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a33_u4_p1_check", false) == true
}
# jdg.vat.a33.u5.p2 — `vat_a33_u5_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a33.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50313,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a33_u5_p2_check", false) == true
}
# jdg.vat.a34.u1.p4 — `vat_a34_u1_p4`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a34.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50314,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a34_u1_p4_check", false) == true
}
# jdg.vat.a34.u3.p1 — `vat_a34_u3_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a34.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50315,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a34_u3_p1_check", false) == true
}
# jdg.vat.a34.u4.p2 — `vat_a34_u4_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a34.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50316,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a34_u4_p2_check", false) == true
}
# jdg.vat.a34.u5.p3 — `vat_a34_u5_p3`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a34.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50317,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a34_u5_p3_check", false) == true
}
# jdg.vat.a35.u2.p1 — `vat_a35_u2_p1`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a35.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50318,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a35_u2_p1_check", false) == true
}
# jdg.vat.a35.u3.p2 — `vat_a35_u3_p2`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a35.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50319,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a35_u3_p2_check", false) == true
}
# jdg.vat.a35.u4.p3 — `vat_a35_u4_p3`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a35.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50320,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a35_u4_p3_check", false) == true
}
# jdg.vat.a35.u5.p4 — `vat_a35_u5_p4`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a35.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50321,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a35_u5_p4_check", false) == true
}
# jdg.vat.a36.u1.p1 — `vat_a36_u1_p1`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a36.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50322,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a36_u1_p1_check", false) == true
}
# jdg.vat.a36.u2.p2 — `vat_a36_u2_p2`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a36.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50323,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a36_u2_p2_check", false) == true
}
# jdg.vat.a36.u3.p3 — `vat_a36_u3_p3`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a36.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50324,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a36_u3_p3_check", false) == true
}
# jdg.vat.a36.u4.p4 — `vat_a36_u4_p4`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a36.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50325,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a36_u4_p4_check", false) == true
}
# jdg.vat.a37.u1.p2 — `vat_a37_u1_p2`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a37.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50326,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a37_u1_p2_check", false) == true
}
# jdg.vat.a37.u2.p3 — `vat_a37_u2_p3`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a37.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50327,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a37_u2_p3_check", false) == true
}
# jdg.vat.a37.u3.p4 — `vat_a37_u3_p4`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a37.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50328,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a37_u3_p4_check", false) == true
}
# jdg.vat.a37.u5.p1 — `vat_a37_u5_p1`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a37.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50329,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a37_u5_p1_check", false) == true
}
# jdg.vat.a38.u1.p3 — `vat_a38_u1_p3`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a38.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50330,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a38_u1_p3_check", false) == true
}
# jdg.vat.a38.u2.p4 — `vat_a38_u2_p4`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a38.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50331,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a38_u2_p4_check", false) == true
}
# jdg.vat.a38.u4.p1 — `vat_a38_u4_p1`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a38.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50332,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a38_u4_p1_check", false) == true
}
# jdg.vat.a38.u5.p2 — `vat_a38_u5_p2`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a38.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50333,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a38_u5_p2_check", false) == true
}
# jdg.vat.a39.u1.p4 — `vat_a39_u1_p4`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a39.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50334,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a39_u1_p4_check", false) == true
}
# jdg.vat.a39.u3.p1 — `vat_a39_u3_p1`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a39.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50335,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a39_u3_p1_check", false) == true
}
# jdg.vat.a39.u4.p2 — `vat_a39_u4_p2`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a39.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50336,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a39_u4_p2_check", false) == true
}
# jdg.vat.a39.u5.p3 — `vat_a39_u5_p3`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a39.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50337,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a39_u5_p3_check", false) == true
}
# jdg.vat.a40.u2.p1 — `vat_a40_u2_p1`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a40.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50338,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a40_u2_p1_check", false) == true
}
# jdg.vat.a40.u3.p2 — `vat_a40_u3_p2`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a40.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50339,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a40_u3_p2_check", false) == true
}
# jdg.vat.a40.u4.p3 — `vat_a40_u4_p3`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a40.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50340,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a40_u4_p3_check", false) == true
}
# jdg.vat.a40.u5.p4 — `vat_a40_u5_p4`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a40.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50341,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a40_u5_p4_check", false) == true
}
# jdg.vat.a41.u1.p1 — `vat_a41_u1_p1`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a41.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50342,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_u1_p1_check", false) == true
}
# jdg.vat.a41.u2.p2 — `vat_a41_u2_p2`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a41.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50343,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_u2_p2_check", false) == true
}
# jdg.vat.a41.u3.p3 — `vat_a41_u3_p3`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a41.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50344,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_u3_p3_check", false) == true
}
# jdg.vat.a41.u4.p4 — `vat_a41_u4_p4`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a41.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50345,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a41_u4_p4_check", false) == true
}
# jdg.vat.a42.u1.p2 — `vat_a42_u1_p2`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a42.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50346,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_u1_p2_check", false) == true
}
# jdg.vat.a42.u2.p3 — `vat_a42_u2_p3`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a42.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50347,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_u2_p3_check", false) == true
}
# jdg.vat.a42.u3.p4 — `vat_a42_u3_p4`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a42.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50348,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_u3_p4_check", false) == true
}
# jdg.vat.a42.u5.p1 — `vat_a42_u5_p1`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a42.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50349,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a42_u5_p1_check", false) == true
}
# jdg.vat.a43.u1.p3 — `vat_a43_u1_p3`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a43.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50350,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_u1_p3_check", false) == true
}
# jdg.vat.a43.u2.p4 — `vat_a43_u2_p4`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a43.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50351,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_u2_p4_check", false) == true
}
# jdg.vat.a43.u4.p1 — `vat_a43_u4_p1`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a43.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50352,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_u4_p1_check", false) == true
}
# jdg.vat.a43.u5.p2 — `vat_a43_u5_p2`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a43.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50353,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a43_u5_p2_check", false) == true
}
# jdg.vat.a44.u1.p4 — `vat_a44_u1_p4`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a44.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50354,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a44_u1_p4_check", false) == true
}
# jdg.vat.a44.u3.p1 — `vat_a44_u3_p1`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a44.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50355,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a44_u3_p1_check", false) == true
}
# jdg.vat.a44.u4.p2 — `vat_a44_u4_p2`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a44.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50356,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a44_u4_p2_check", false) == true
}
# jdg.vat.a44.u5.p3 — `vat_a44_u5_p3`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a44.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50357,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a44_u5_p3_check", false) == true
}
# jdg.vat.a45.u2.p1 — `vat_a45_u2_p1`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a45.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50358,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a45_u2_p1_check", false) == true
}
# jdg.vat.a45.u3.p2 — `vat_a45_u3_p2`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a45.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50359,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a45_u3_p2_check", false) == true
}
# jdg.vat.a45.u4.p3 — `vat_a45_u4_p3`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a45.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50360,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a45_u4_p3_check", false) == true
}
# jdg.vat.a45.u5.p4 — `vat_a45_u5_p4`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a45.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50361,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a45_u5_p4_check", false) == true
}
# jdg.vat.a46.u1.p1 — `vat_a46_u1_p1`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a46.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50362,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a46_u1_p1_check", false) == true
}
# jdg.vat.a46.u2.p2 — `vat_a46_u2_p2`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a46.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50363,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a46_u2_p2_check", false) == true
}
# jdg.vat.a46.u3.p3 — `vat_a46_u3_p3`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a46.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50364,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a46_u3_p3_check", false) == true
}
# jdg.vat.a46.u4.p4 — `vat_a46_u4_p4`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a46.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50365,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a46_u4_p4_check", false) == true
}
# jdg.vat.a47.u1.p2 — `vat_a47_u1_p2`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a47.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50366,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a47_u1_p2_check", false) == true
}
# jdg.vat.a47.u2.p3 — `vat_a47_u2_p3`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a47.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50367,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a47_u2_p3_check", false) == true
}
# jdg.vat.a47.u3.p4 — `vat_a47_u3_p4`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a47.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50368,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a47_u3_p4_check", false) == true
}
# jdg.vat.a47.u5.p1 — `vat_a47_u5_p1`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a47.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50369,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a47_u5_p1_check", false) == true
}
# jdg.vat.a48.u1.p3 — `vat_a48_u1_p3`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a48.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50370,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a48_u1_p3_check", false) == true
}
# jdg.vat.a48.u2.p4 — `vat_a48_u2_p4`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a48.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50371,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a48_u2_p4_check", false) == true
}
# jdg.vat.a48.u4.p1 — `vat_a48_u4_p1`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a48.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50372,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a48_u4_p1_check", false) == true
}
# jdg.vat.a48.u5.p2 — `vat_a48_u5_p2`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a48.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50373,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a48_u5_p2_check", false) == true
}
# jdg.vat.a49.u1.p4 — `vat_a49_u1_p4`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a49.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50374,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a49_u1_p4_check", false) == true
}
# jdg.vat.a49.u3.p1 — `vat_a49_u3_p1`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a49.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50375,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a49_u3_p1_check", false) == true
}
# jdg.vat.a49.u4.p2 — `vat_a49_u4_p2`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a49.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50376,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a49_u4_p2_check", false) == true
}
# jdg.vat.a49.u5.p3 — `vat_a49_u5_p3`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a49.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50377,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a49_u5_p3_check", false) == true
}
# jdg.vat.a50.u2.p1 — `vat_a50_u2_p1`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a50.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50378,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a50_u2_p1_check", false) == true
}
# jdg.vat.a50.u3.p2 — `vat_a50_u3_p2`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a50.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50379,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a50_u3_p2_check", false) == true
}
# jdg.vat.a50.u4.p3 — `vat_a50_u4_p3`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a50.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50380,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a50_u4_p3_check", false) == true
}
# jdg.vat.a50.u5.p4 — `vat_a50_u5_p4`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a50.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50381,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a50_u5_p4_check", false) == true
}
# jdg.vat.a51.u1.p1 — `vat_a51_u1_p1`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a51.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50382,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a51_u1_p1_check", false) == true
}
# jdg.vat.a51.u2.p2 — `vat_a51_u2_p2`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a51.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50383,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a51_u2_p2_check", false) == true
}
# jdg.vat.a51.u3.p3 — `vat_a51_u3_p3`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a51.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50384,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a51_u3_p3_check", false) == true
}
# jdg.vat.a51.u4.p4 — `vat_a51_u4_p4`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a51.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50385,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a51_u4_p4_check", false) == true
}
# jdg.vat.a52.u1.p2 — `vat_a52_u1_p2`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a52.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50386,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a52_u1_p2_check", false) == true
}
# jdg.vat.a52.u2.p3 — `vat_a52_u2_p3`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a52.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50387,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a52_u2_p3_check", false) == true
}
# jdg.vat.a52.u3.p4 — `vat_a52_u3_p4`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a52.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50388,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a52_u3_p4_check", false) == true
}
# jdg.vat.a52.u5.p1 — `vat_a52_u5_p1`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a52.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50389,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a52_u5_p1_check", false) == true
}
# jdg.vat.a53.u1.p3 — `vat_a53_u1_p3`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a53.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50390,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a53_u1_p3_check", false) == true
}
# jdg.vat.a53.u2.p4 — `vat_a53_u2_p4`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a53.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50391,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a53_u2_p4_check", false) == true
}
# jdg.vat.a53.u4.p1 — `vat_a53_u4_p1`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a53.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50392,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a53_u4_p1_check", false) == true
}
# jdg.vat.a53.u5.p2 — `vat_a53_u5_p2`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a53.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50393,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a53_u5_p2_check", false) == true
}
# jdg.vat.a54.u1.p4 — `vat_a54_u1_p4`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a54.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50394,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a54_u1_p4_check", false) == true
}
# jdg.vat.a54.u3.p1 — `vat_a54_u3_p1`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a54.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50395,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a54_u3_p1_check", false) == true
}
# jdg.vat.a54.u4.p2 — `vat_a54_u4_p2`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a54.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50396,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a54_u4_p2_check", false) == true
}
# jdg.vat.a54.u5.p3 — `vat_a54_u5_p3`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a54.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50397,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a54_u5_p3_check", false) == true
}
# jdg.vat.a55.u2.p1 — `vat_a55_u2_p1`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a55.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50398,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a55_u2_p1_check", false) == true
}
# jdg.vat.a55.u3.p2 — `vat_a55_u3_p2`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a55.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50399,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a55_u3_p2_check", false) == true
}
# jdg.vat.a55.u4.p3 — `vat_a55_u4_p3`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a55.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50400,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a55_u4_p3_check", false) == true
}
# jdg.vat.a55.u5.p4 — `vat_a55_u5_p4`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a55.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50401,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a55_u5_p4_check", false) == true
}
# jdg.vat.a56.u1.p1 — `vat_a56_u1_p1`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a56.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50402,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a56_u1_p1_check", false) == true
}
# jdg.vat.a56.u2.p2 — `vat_a56_u2_p2`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a56.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50403,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a56_u2_p2_check", false) == true
}
# jdg.vat.a56.u3.p3 — `vat_a56_u3_p3`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a56.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50404,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a56_u3_p3_check", false) == true
}
# jdg.vat.a56.u4.p4 — `vat_a56_u4_p4`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a56.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50405,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a56_u4_p4_check", false) == true
}
# jdg.vat.a57.u1.p2 — `vat_a57_u1_p2`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a57.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50406,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a57_u1_p2_check", false) == true
}
# jdg.vat.a57.u2.p3 — `vat_a57_u2_p3`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a57.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50407,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a57_u2_p3_check", false) == true
}
# jdg.vat.a57.u3.p4 — `vat_a57_u3_p4`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a57.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50408,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a57_u3_p4_check", false) == true
}
# jdg.vat.a57.u5.p1 — `vat_a57_u5_p1`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a57.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50409,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a57_u5_p1_check", false) == true
}
# jdg.vat.a58.u1.p3 — `vat_a58_u1_p3`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a58.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50410,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a58_u1_p3_check", false) == true
}
# jdg.vat.a58.u2.p4 — `vat_a58_u2_p4`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a58.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50411,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a58_u2_p4_check", false) == true
}
# jdg.vat.a58.u4.p1 — `vat_a58_u4_p1`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a58.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50412,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a58_u4_p1_check", false) == true
}
# jdg.vat.a58.u5.p2 — `vat_a58_u5_p2`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a58.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50413,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a58_u5_p2_check", false) == true
}
# jdg.vat.a59.u1.p4 — `vat_a59_u1_p4`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a59.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50414,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a59_u1_p4_check", false) == true
}
# jdg.vat.a59.u3.p1 — `vat_a59_u3_p1`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a59.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50415,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a59_u3_p1_check", false) == true
}
# jdg.vat.a59.u4.p2 — `vat_a59_u4_p2`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a59.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50416,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a59_u4_p2_check", false) == true
}
# jdg.vat.a59.u5.p3 — `vat_a59_u5_p3`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a59.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50417,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a59_u5_p3_check", false) == true
}
# jdg.vat.a60.u2.p1 — `vat_a60_u2_p1`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a60.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50418,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a60_u2_p1_check", false) == true
}
# jdg.vat.a60.u3.p2 — `vat_a60_u3_p2`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a60.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50419,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a60_u3_p2_check", false) == true
}
# jdg.vat.a60.u4.p3 — `vat_a60_u4_p3`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a60.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50420,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a60_u4_p3_check", false) == true
}
# jdg.vat.a60.u5.p4 — `vat_a60_u5_p4`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a60.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50421,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a60_u5_p4_check", false) == true
}
# jdg.vat.a61.u1.p1 — `vat_a61_u1_p1`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a61.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50422,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a61_u1_p1_check", false) == true
}
# jdg.vat.a61.u2.p2 — `vat_a61_u2_p2`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a61.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50423,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a61_u2_p2_check", false) == true
}
# jdg.vat.a61.u3.p3 — `vat_a61_u3_p3`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a61.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50424,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a61_u3_p3_check", false) == true
}
# jdg.vat.a61.u4.p4 — `vat_a61_u4_p4`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a61.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50425,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a61_u4_p4_check", false) == true
}
# jdg.vat.a62.u1.p2 — `vat_a62_u1_p2`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a62.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50426,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a62_u1_p2_check", false) == true
}
# jdg.vat.a62.u2.p3 — `vat_a62_u2_p3`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a62.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50427,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a62_u2_p3_check", false) == true
}
# jdg.vat.a62.u3.p4 — `vat_a62_u3_p4`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a62.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50428,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a62_u3_p4_check", false) == true
}
# jdg.vat.a62.u5.p1 — `vat_a62_u5_p1`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a62.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50429,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a62_u5_p1_check", false) == true
}
# jdg.vat.a63.u1.p3 — `vat_a63_u1_p3`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a63.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50430,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a63_u1_p3_check", false) == true
}
# jdg.vat.a63.u2.p4 — `vat_a63_u2_p4`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a63.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50431,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a63_u2_p4_check", false) == true
}
# jdg.vat.a63.u4.p1 — `vat_a63_u4_p1`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a63.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50432,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a63_u4_p1_check", false) == true
}
# jdg.vat.a63.u5.p2 — `vat_a63_u5_p2`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a63.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50433,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a63_u5_p2_check", false) == true
}
# jdg.vat.a64.u1.p4 — `vat_a64_u1_p4`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a64.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50434,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a64_u1_p4_check", false) == true
}
# jdg.vat.a64.u3.p1 — `vat_a64_u3_p1`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a64.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50435,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a64_u3_p1_check", false) == true
}
# jdg.vat.a64.u4.p2 — `vat_a64_u4_p2`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a64.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50436,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a64_u4_p2_check", false) == true
}
# jdg.vat.a64.u5.p3 — `vat_a64_u5_p3`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a64.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50437,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a64_u5_p3_check", false) == true
}
# jdg.vat.a65.u2.p1 — `vat_a65_u2_p1`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a65.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50438,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a65_u2_p1_check", false) == true
}
# jdg.vat.a65.u3.p2 — `vat_a65_u3_p2`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a65.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50439,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a65_u3_p2_check", false) == true
}
# jdg.vat.a65.u4.p3 — `vat_a65_u4_p3`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a65.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50440,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a65_u4_p3_check", false) == true
}
# jdg.vat.a65.u5.p4 — `vat_a65_u5_p4`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a65.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50441,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a65_u5_p4_check", false) == true
}
# jdg.vat.a66.u1.p1 — `vat_a66_u1_p1`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a66.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50442,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a66_u1_p1_check", false) == true
}
# jdg.vat.a66.u2.p2 — `vat_a66_u2_p2`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a66.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50443,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a66_u2_p2_check", false) == true
}
# jdg.vat.a66.u3.p3 — `vat_a66_u3_p3`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a66.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50444,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a66_u3_p3_check", false) == true
}
# jdg.vat.a66.u4.p4 — `vat_a66_u4_p4`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a66.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50445,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a66_u4_p4_check", false) == true
}
# jdg.vat.a67.u1.p2 — `vat_a67_u1_p2`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a67.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50446,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a67_u1_p2_check", false) == true
}
# jdg.vat.a67.u2.p3 — `vat_a67_u2_p3`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a67.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50447,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a67_u2_p3_check", false) == true
}
# jdg.vat.a67.u3.p4 — `vat_a67_u3_p4`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a67.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50448,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a67_u3_p4_check", false) == true
}
# jdg.vat.a67.u5.p1 — `vat_a67_u5_p1`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a67.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50449,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a67_u5_p1_check", false) == true
}
# jdg.vat.a68.u1.p3 — `vat_a68_u1_p3`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a68.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50450,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a68_u1_p3_check", false) == true
}
# jdg.vat.a68.u2.p4 — `vat_a68_u2_p4`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a68.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50451,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a68_u2_p4_check", false) == true
}
# jdg.vat.a68.u4.p1 — `vat_a68_u4_p1`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a68.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50452,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a68_u4_p1_check", false) == true
}
# jdg.vat.a68.u5.p2 — `vat_a68_u5_p2`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a68.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50453,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a68_u5_p2_check", false) == true
}
# jdg.vat.a69.u1.p4 — `vat_a69_u1_p4`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a69.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50454,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a69_u1_p4_check", false) == true
}
# jdg.vat.a69.u3.p1 — `vat_a69_u3_p1`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a69.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50455,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a69_u3_p1_check", false) == true
}
# jdg.vat.a69.u4.p2 — `vat_a69_u4_p2`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a69.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50456,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a69_u4_p2_check", false) == true
}
# jdg.vat.a69.u5.p3 — `vat_a69_u5_p3`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a69.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50457,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a69_u5_p3_check", false) == true
}
# jdg.vat.a70.u2.p1 — `vat_a70_u2_p1`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a70.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50458,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a70_u2_p1_check", false) == true
}
# jdg.vat.a70.u3.p2 — `vat_a70_u3_p2`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a70.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50459,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a70_u3_p2_check", false) == true
}
# jdg.vat.a70.u4.p3 — `vat_a70_u4_p3`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a70.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50460,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a70_u4_p3_check", false) == true
}
# jdg.vat.a70.u5.p4 — `vat_a70_u5_p4`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a70.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50461,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a70_u5_p4_check", false) == true
}
# jdg.vat.a71.u1.p1 — `vat_a71_u1_p1`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a71.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50462,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a71_u1_p1_check", false) == true
}
# jdg.vat.a71.u2.p2 — `vat_a71_u2_p2`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a71.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50463,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a71_u2_p2_check", false) == true
}
# jdg.vat.a71.u3.p3 — `vat_a71_u3_p3`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a71.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50464,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a71_u3_p3_check", false) == true
}
# jdg.vat.a71.u4.p4 — `vat_a71_u4_p4`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a71.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50465,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a71_u4_p4_check", false) == true
}
# jdg.vat.a72.u1.p2 — `vat_a72_u1_p2`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a72.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50466,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a72_u1_p2_check", false) == true
}
# jdg.vat.a72.u2.p3 — `vat_a72_u2_p3`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a72.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50467,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a72_u2_p3_check", false) == true
}
# jdg.vat.a72.u3.p4 — `vat_a72_u3_p4`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a72.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50468,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a72_u3_p4_check", false) == true
}
# jdg.vat.a72.u5.p1 — `vat_a72_u5_p1`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a72.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50469,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a72_u5_p1_check", false) == true
}
# jdg.vat.a73.u1.p3 — `vat_a73_u1_p3`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a73.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50470,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a73_u1_p3_check", false) == true
}
# jdg.vat.a73.u2.p4 — `vat_a73_u2_p4`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a73.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50471,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a73_u2_p4_check", false) == true
}
# jdg.vat.a73.u4.p1 — `vat_a73_u4_p1`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a73.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50472,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a73_u4_p1_check", false) == true
}
# jdg.vat.a73.u5.p2 — `vat_a73_u5_p2`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a73.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50473,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a73_u5_p2_check", false) == true
}
# jdg.vat.a74.u1.p4 — `vat_a74_u1_p4`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a74.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50474,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a74_u1_p4_check", false) == true
}
# jdg.vat.a74.u3.p1 — `vat_a74_u3_p1`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a74.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50475,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a74_u3_p1_check", false) == true
}
# jdg.vat.a74.u4.p2 — `vat_a74_u4_p2`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a74.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50476,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a74_u4_p2_check", false) == true
}
# jdg.vat.a74.u5.p3 — `vat_a74_u5_p3`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a74.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50477,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a74_u5_p3_check", false) == true
}
# jdg.vat.a75.u2.p1 — `vat_a75_u2_p1`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a75.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50478,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a75_u2_p1_check", false) == true
}
# jdg.vat.a75.u3.p2 — `vat_a75_u3_p2`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a75.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50479,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a75_u3_p2_check", false) == true
}
# jdg.vat.a75.u4.p3 — `vat_a75_u4_p3`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a75.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50480,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a75_u4_p3_check", false) == true
}
# jdg.vat.a75.u5.p4 — `vat_a75_u5_p4`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a75.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50481,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a75_u5_p4_check", false) == true
}
# jdg.vat.a76.u1.p1 — `vat_a76_u1_p1`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a76.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50482,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a76_u1_p1_check", false) == true
}
# jdg.vat.a76.u2.p2 — `vat_a76_u2_p2`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a76.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50483,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a76_u2_p2_check", false) == true
}
# jdg.vat.a76.u3.p3 — `vat_a76_u3_p3`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a76.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50484,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a76_u3_p3_check", false) == true
}
# jdg.vat.a76.u4.p4 — `vat_a76_u4_p4`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a76.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50485,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a76_u4_p4_check", false) == true
}
# jdg.vat.a77.u1.p2 — `vat_a77_u1_p2`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a77.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50486,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a77_u1_p2_check", false) == true
}
# jdg.vat.a77.u2.p3 — `vat_a77_u2_p3`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a77.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50487,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a77_u2_p3_check", false) == true
}
# jdg.vat.a77.u3.p4 — `vat_a77_u3_p4`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a77.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50488,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a77_u3_p4_check", false) == true
}
# jdg.vat.a77.u5.p1 — `vat_a77_u5_p1`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a77.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50489,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a77_u5_p1_check", false) == true
}
# jdg.vat.a78.u1.p3 — `vat_a78_u1_p3`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a78.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50490,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a78_u1_p3_check", false) == true
}
# jdg.vat.a78.u2.p4 — `vat_a78_u2_p4`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a78.u2.p4",
    "package": "jdg.micro.vat",
    "priority": 50491,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a78_u2_p4_check", false) == true
}
# jdg.vat.a78.u4.p1 — `vat_a78_u4_p1`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a78.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50492,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a78_u4_p1_check", false) == true
}
# jdg.vat.a78.u5.p2 — `vat_a78_u5_p2`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a78.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50493,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a78_u5_p2_check", false) == true
}
# jdg.vat.a79.u1.p4 — `vat_a79_u1_p4`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a79.u1.p4",
    "package": "jdg.micro.vat",
    "priority": 50494,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a79_u1_p4_check", false) == true
}
# jdg.vat.a79.u3.p1 — `vat_a79_u3_p1`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a79.u3.p1",
    "package": "jdg.micro.vat",
    "priority": 50495,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a79_u3_p1_check", false) == true
}
# jdg.vat.a79.u4.p2 — `vat_a79_u4_p2`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a79.u4.p2",
    "package": "jdg.micro.vat",
    "priority": 50496,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a79_u4_p2_check", false) == true
}
# jdg.vat.a79.u5.p3 — `vat_a79_u5_p3`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a79.u5.p3",
    "package": "jdg.micro.vat",
    "priority": 50497,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a79_u5_p3_check", false) == true
}
# jdg.vat.a80.u2.p1 — `vat_a80_u2_p1`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a80.u2.p1",
    "package": "jdg.micro.vat",
    "priority": 50498,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a80_u2_p1_check", false) == true
}
# jdg.vat.a80.u3.p2 — `vat_a80_u3_p2`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a80.u3.p2",
    "package": "jdg.micro.vat",
    "priority": 50499,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a80_u3_p2_check", false) == true
}
# jdg.vat.a80.u4.p3 — `vat_a80_u4_p3`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a80.u4.p3",
    "package": "jdg.micro.vat",
    "priority": 50500,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a80_u4_p3_check", false) == true
}
# jdg.vat.a80.u5.p4 — `vat_a80_u5_p4`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a80.u5.p4",
    "package": "jdg.micro.vat",
    "priority": 50501,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a80_u5_p4_check", false) == true
}
# jdg.vat.a81.u1.p1 — `vat_a81_u1_p1`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a81.u1.p1",
    "package": "jdg.micro.vat",
    "priority": 50502,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a81_u1_p1_check", false) == true
}
# jdg.vat.a81.u2.p2 — `vat_a81_u2_p2`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a81.u2.p2",
    "package": "jdg.micro.vat",
    "priority": 50503,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a81_u2_p2_check", false) == true
}
# jdg.vat.a81.u3.p3 — `vat_a81_u3_p3`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a81.u3.p3",
    "package": "jdg.micro.vat",
    "priority": 50504,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a81_u3_p3_check", false) == true
}
# jdg.vat.a81.u4.p4 — `vat_a81_u4_p4`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a81.u4.p4",
    "package": "jdg.micro.vat",
    "priority": 50505,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a81_u4_p4_check", false) == true
}
# jdg.vat.a82.u1.p2 — `vat_a82_u1_p2`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a82.u1.p2",
    "package": "jdg.micro.vat",
    "priority": 50506,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a82_u1_p2_check", false) == true
}
# jdg.vat.a82.u2.p3 — `vat_a82_u2_p3`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a82.u2.p3",
    "package": "jdg.micro.vat",
    "priority": 50507,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a82_u2_p3_check", false) == true
}
# jdg.vat.a82.u3.p4 — `vat_a82_u3_p4`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a82.u3.p4",
    "package": "jdg.micro.vat",
    "priority": 50508,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a82_u3_p4_check", false) == true
}
# jdg.vat.a82.u5.p1 — `vat_a82_u5_p1`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a82.u5.p1",
    "package": "jdg.micro.vat",
    "priority": 50509,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a82_u5_p1_check", false) == true
}
# jdg.vat.a83.u1.p3 — `vat_a83_u1_p3`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a83.u1.p3",
    "package": "jdg.micro.vat",
    "priority": 50510,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a83_u1_p3_check", false) == true
}
# jdg.vat.a83.u4.p1 — `vat_a83_u4_p1`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a83.u4.p1",
    "package": "jdg.micro.vat",
    "priority": 50511,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a83_u4_p1_check", false) == true
}
# jdg.vat.a83.u5.p2 — `vat_a83_u5_p2`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a83.u5.p2",
    "package": "jdg.micro.vat",
    "priority": 50512,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a83_u5_p2_check", false) == true
}
# jdg.vat.a96.r20 — `vat_a96_r20`: Art. 96 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.a96.r20",
    "package": "jdg.micro.vat",
    "priority": 50513,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 96 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] Art. 96: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_a96_r20_check", false) == true
}
# jdg.vat.ksef.r1 — `vat_ksef_r1`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.ksef.r1",
    "package": "jdg.micro.vat",
    "priority": 50514,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.vat.ksef.r1 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] jdg.vat.ksef.r1: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_ksef_r1_check", false) == true
}
# jdg.vat.marz.r1 — `vat_marz_r1`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.marz.r1",
    "package": "jdg.micro.vat",
    "priority": 50515,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.vat.marz.r1 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] jdg.vat.marz.r1: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_marz_r1_check", false) == true
}
# jdg.vat.marz.r10 — `vat_marz_r10`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.marz.r10",
    "package": "jdg.micro.vat",
    "priority": 50516,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.vat.marz.r10 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] jdg.vat.marz.r10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_marz_r10_check", false) == true
}
# jdg.vat.mpp.r1 — `vat_mpp_r1`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.mpp.r1",
    "package": "jdg.micro.vat",
    "priority": 50517,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.vat.mpp.r1 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] jdg.vat.mpp.r1: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_mpp_r1_check", false) == true
}
# jdg.vat.rr.r15 — `vat_rr_r15`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vat.rr.r15",
    "package": "jdg.micro.vat",
    "priority": 50518,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.vat.rr.r15 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "_warnings": ["[MICRO] jdg.vat.rr.r15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vat_rr_r15_check", false) == true
}
# jdg.vida.v1.r1 — `vida_*_r1`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.vida.v1.r1",
    "package": "jdg.micro.general",
    "priority": 50519,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_12",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
            "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.vida.v1.r1 — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Przepisy prawa polskiego",
    "_warnings": ["[MICRO] jdg.vida.v1.r1: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "vida_*_r1_check", false) == true
}
