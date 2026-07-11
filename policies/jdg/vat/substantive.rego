# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — VAT: Stawki, zwolnienia, GTU (P50-P65)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Substantive — Rates, Exemptions, GTU Codes
# description: |
#   PAS 4a Multi-Pass. First-Match-Wins else-chain. Stawki VAT wg kategorii:
#   23% standard (P52/P67), 8% obniżona (P64), 5% żywność/książki (P53/P54/P66),
#   0% zwolnienia przedmiotowe: edukacja (P55), medycyna (P56), finanse (P57),
#   podmiotowe 200k (P58/P59), kultura (P61), nieruchomości (P62), poczta (P63).
#   Mapowanie GTU 13 kodów (P65), ulga złe długi VAT (P60).
# architecture: Multi-Pass PAS 4a (ADR-001)
# legal_basis: Art. 41-43, 89a, 113, 120 VAT
# edge_cases:
#   - P58: zwolnienie podmiotowe tylko gdy !is_vat_payer AND turnover < 200k
#   - P60: bad_debt_creditor wymaga >150 dni + debtor_notified
#   - P67: standard 23% = catch-all dla PL
# package: jdg.vat.substantive
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# Architektura: First-Match-Wins else-chain
# Wzorzec mapowania: category_code → vat_rate + gtu_code
# Podstawa: Doc 34 Sec 4.5 + Doc 33 (dekompozycja art. 41-43 VAT)
#
# package: jdg.vat.substantive
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.substantive

import data.jdg.helpers

# ── Default: no matching VAT rate rule ──────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.substantive.no_match",
    "package": "jdg.vat.substantive",
    "priority": 75
}

# ═══════════════════════════════════════════════════════════════════════════════
# P50: vat_margin_scheme — Procedura VAT-marża
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.substantive.margin_scheme",
    "package": "jdg.vat.substantive", "priority": 50,
    "vat_rate": "0.23", "rounding_level": "total",
    "gtu_code": "", "procedure": "MARGIN",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 120 ustawy o VAT",
    "_warnings": ["Procedura VAT-marża — podstawa = marża, nie cała kwota"]
} {
    input.invoice.procedure == "MARGIN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P52: vat_rate_fuel_pl — Paliwo → 23% + GTU_04
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.fuel_pl",
    "package": "jdg.vat.substantive", "priority": 52,
    "vat_rate": "0.23", "rounding_level": "position",
    "gtu_code": "GTU_04", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 VAT",
    "_warnings": []
} {
    input.invoice.category_code == "FUEL"
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P53: vat_rate_food_pl — Żywność → 5% + GTU_07
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.food_pl",
    "package": "jdg.vat.substantive", "priority": 53,
    "vat_rate": "0.05", "rounding_level": "position",
    "gtu_code": "GTU_07", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2a VAT",
    "_warnings": []
} {
    input.invoice.category_code in {"FOOD", "GROCERIES", "FOOD_BASIC"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P54: vat_rate_books — Książki → 5%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.books_pl",
    "package": "jdg.vat.substantive", "priority": 54,
    "vat_rate": "0.05", "rounding_level": "position",
    "gtu_code": "GTU_01", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2a VAT",
    "_warnings": []
} {
    input.invoice.category_code in {"BOOKS", "EBOOKS", "AUDIOBOOKS"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P55: vat_exemption_education — Edukacja → zwolniona
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.education_exempt",
    "package": "jdg.vat.substantive", "priority": 55,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 26-29 VAT",
    "_warnings": ["Usługi edukacyjne zwolnione z VAT"]
} {
    input.invoice.category_code in {"EDUCATION", "TRAINING", "TUTORING"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P56: vat_exemption_healthcare — Medycyna → zwolniona
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.healthcare_exempt",
    "package": "jdg.vat.substantive", "priority": 56,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 18-20 VAT",
    "_warnings": ["Usługi medyczne zwolnione z VAT"]
} {
    input.invoice.category_code in {"HEALTHCARE", "MEDICAL", "DENTAL", "PHYSIOTHERAPY"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P57: vat_exemption_financial — Finanse/ubezpieczenia → zwolnione
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.financial_exempt",
    "package": "jdg.vat.substantive", "priority": 57,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 7, 37-38 VAT",
    "_warnings": ["Usługi finansowe/ubezpieczeniowe zwolnione z VAT"]
} {
    input.invoice.category_code in {"FINANCIAL", "INSURANCE", "BANKING", "LOAN"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P58: vat_exemption_subject_jdg — Zwolnienie podmiotowe JDG (200k limit)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.subject_exemption_jdg",
    "package": "jdg.vat.substantive", "priority": 58,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "SUBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 1 i 9 VAT",
    "_warnings": ["Zwolnienie podmiotowe VAT — limit 200 000 PLN rocznie"]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    input.jdg_entrepreneur.annual_turnover_net < 200000
}

# ═══════════════════════════════════════════════════════════════════════════════
# P59: subject_exemption_startup_proportion — Proporcja dla nowych JDG
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.startup_proportion",
    "package": "jdg.vat.substantive", "priority": 59,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "SUBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 9 VAT",
    "_warnings": ["Nowa JDG — limit zwolnienia proporcjonalny do okresu prowadzenia działalności"]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    input.jdg_entrepreneur.ceidg_entry_date != null
    input.jdg_entrepreneur.annual_turnover_net < 200000
}

# ═══════════════════════════════════════════════════════════════════════════════
# P60: vat_bad_debt_relief — Ulga na złe długi VAT (wierzyciel)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.bad_debt_relief_creditor",
    "package": "jdg.vat.substantive", "priority": 60,
    "vat_rate": "", "rounding_level": "",
    "gtu_code": "", "procedure": "BAD_DEBT_RELIEF_CREDITOR",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a VAT",
    "_warnings": ["Ulga na złe długi VAT — korekta po 150 dniach od terminu płatności"]
} {
    input.invoice.is_paid == false
    input.invoice.days_overdue >= 150
    input.invoice.direction == "SALE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P61: vat_exemption_culture — Kultura/sport → zwolnione
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.culture_exempt",
    "package": "jdg.vat.substantive", "priority": 61,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 32-33 VAT",
    "_warnings": ["Usługi kulturalne/sportowe zwolnione z VAT"]
} {
    input.invoice.category_code in {"CULTURE", "SPORT", "MUSEUM", "LIBRARY"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P62: vat_exemption_real_estate — Nieruchomości → zwolnione (po pierwszym zasiedleniu)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.real_estate_exempt",
    "package": "jdg.vat.substantive", "priority": 62,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 10 VAT",
    "_warnings": ["Dostawa nieruchomości po pierwszym zasiedleniu — zwolniona z VAT"]
} {
    input.invoice.category_code in {"REAL_ESTATE", "BUILDING_SALE"}
    input.invoice.is_first_occupancy == false
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P63: vat_exemption_postal — Usługi pocztowe → zwolnione
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.postal_exempt",
    "package": "jdg.vat.substantive", "priority": 63,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 17 VAT",
    "_warnings": []
} {
    input.invoice.category_code == "POSTAL"
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P64: vat_rate_8pct — Stawka obniżona 8% (budownictwo mieszkaniowe, hotele, transport)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.rate_8pct",
    "package": "jdg.vat.substantive", "priority": 64,
    "vat_rate": "0.08", "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2 VAT w zw. z załącznikiem nr 3",
    "_warnings": []
} {
    input.invoice.category_code in {
        "CONSTRUCTION_RESIDENTIAL", "HOTEL", "TRANSPORT_PASSENGER",
        "PHARMACEUTICALS", "MEDICAL_EQUIPMENT", "RESTAURANT_CATERING",
        "WATER_SUPPLY", "WASTE_COLLECTION"
    }
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P65: gtu_mapping_by_category — Mapowanie GTU (13 kodów)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.gtu_mapping",
    "package": "jdg.vat.substantive", "priority": 65,
    "vat_rate": "0.23", "rounding_level": "position",
    "gtu_code": gtu_code, "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT",
    "_warnings": []
} {
    input.vendor.country == "PL"
    gtu_code := gtu_map[input.invoice.category_code]
    gtu_code != ""
}

# ── GTU Map (13 kodów) ────────────────────────────────────────────────────────
gtu_map := {
    "ALCOHOL": "GTU_01",
    "BEVERAGES_ALCOHOLIC": "GTU_01",
    "TOBACCO": "GTU_02",
    "FUEL": "GTU_04",
    "FUEL_HEATING": "GTU_04",
    "OIL_LUBRICANTS": "GTU_05",
    "MEDICAL_PRODUCTS": "GTU_06",
    "WASTE": "GTU_07",
    "ELECTRONICS": "GTU_08",
    "VEHICLES": "GTU_09",
    "STEEL": "GTU_10",
    "PRECIOUS_METALS": "GTU_11",
    "CONSTRUCTION": "GTU_12",
    "TRANSPORT_SERVICES": "GTU_13"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P66: vat_rate_5pct_extended — Stawka 5% rozszerzona
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.rate_5pct_extended",
    "package": "jdg.vat.substantive", "priority": 66,
    "vat_rate": "0.05", "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2a VAT",
    "_warnings": []
} {
    input.invoice.category_code in {
        "BABY_PRODUCTS", "MEAT_FISH", "AGRICULTURAL_INPUTS",
        "DISPOSABLE_MEDICAL", "NEWSPAPERS", "FOOD_MEAT"
    }
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P67: vat_rate_23_standard — Stawka 23% (pozostałe kategorie PL)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.rate_23_standard_pl",
    "package": "jdg.vat.substantive", "priority": 67,
    "vat_rate": "0.23", "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 VAT",
    "_warnings": []
} {
    input.vendor.country == "PL"
    input.invoice.category_code in {
        "CONSULTING", "IT_SERVICES", "MARKETING", "ADVERTISING",
        "SOFTWARE", "HOSTING", "SAAS", "TELECOMMUNICATIONS",
        "RENTAL_COMMERCIAL", "CLEANING", "FURNITURE",
        "ELECTRONICS_CONSUMER", "JEWELRY", "OFFICE_SUPPLIES",
        "LEGAL_SERVICES", "ACCOUNTING_SERVICES", "TRANSPORT_GOODS",
        "CONSTRUCTION_MATERIALS", "MAINTENANCE", "SECURITY"
    }
}
