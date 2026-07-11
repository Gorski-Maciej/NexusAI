# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — VAT: Odliczenia, korekty, auta, złe długi (P183-P192)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Deductions — Blocked Categories, Bad Debt, Vehicles, Pre-Proportion
# description: |
#   PAS 4b Multi-Pass. First-Match-Wins else-chain. Odliczenia VAT:
#   kategorie zablokowane (P183), OBOWIĄZEK korekty dłużnika 90 dni (P184),
#   pre-proporcja (P185), auto 50%/100% (P186/P186b), korekta roczna (P187),
#   termin 3m (P188), ulga wierzyciela 150 dni (P189), import (P191),
#   zwroty 60/25 dni (P192).
# architecture: Multi-Pass PAS 4b (ADR-001)
# legal_basis: Art. 86-91, 89a-89b VAT
# edge_cases:
#   - P184: sankcja 30% za brak korekty dłużnika (BLOCK_AND_ALERT)
#   - P185: de minimis <2% → 0% odliczenia
#   - P188: months_since_issue > 3 → termin bezpowrotnie minął
# package: jdg.vat.deductions
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# Architektura: First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.5 + Doc 33 (Art. 86-89b VAT)
#
# package: jdg.vat.deductions
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.deductions

import data.jdg.helpers

# ── Default ────────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.deductions.no_match",
    "package": "jdg.vat.deductions",
    "priority": 202
}

# ═══════════════════════════════════════════════════════════════════════════════
# P183: vat_blocked_categories — Kategorie wyłączone z odliczenia VAT
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.deductions.blocked_categories",
    "package": "jdg.vat.deductions", "priority": 183,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_BLOCKED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "VAT blocked category",
    "_legal_basis": "Art. 88 ust. 1 VAT",
    "_warnings": [sprintf("Kategoria %s — VAT NIE podlega odliczeniu", [input.invoice.category_code])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {
        "HOTEL", "RESTAURANT_MEALS", "ENTERTAINMENT",
        "REPRESENTATION", "ALCOHOL", "PERSONAL_EXPENSE"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P184: bad_debt_debtor_correction_mandatory — OBOWIĄZEK dłużnika korekty VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_debtor_mandatory",
    "package": "jdg.vat.deductions", "priority": 184,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_DEBTOR_CORRECTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "OBOWIĄZEK korekty VAT in minus po 90 dniach niezapłacenia",
    "_legal_basis": "Art. 89b VAT",
    "_warnings": ["OBOWIĄZEK dłużnika: korekta VAT in minus po 90 dniach. Sankcja 30% za brak korekty!"],
    "_future_events": [{
        "event_id":"bad_debt_debtor_vat_correction",
        "event_type":"TAX_OBLIGATION",
        "description":"Korekta VAT in minus po 90 dniach — OBOWIĄZEK w deklaracji JPK_V7",
        "due_date_horizon":"+7d",
        "action":"FILE_VAT_CORRECTION_JPK_V7",
        "priority":"CRITICAL"
    }]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.is_paid == false
    input.invoice.is_vat_deducted == true
    input.invoice.days_overdue >= 90
}

# ═══════════════════════════════════════════════════════════════════════════════
# P185: vat_pre_proportion_mixed — Pre-proporcja VAT dla wydatków mieszanych
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.pre_proportion_mixed",
    "package": "jdg.vat.deductions", "priority": 185,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "PRE_PROPORTION", "vat_exemption": "",
    "vat_deduction_percent": vat_deduction_percent, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2a-2h VAT",
    "_warnings": []
} {
    input.invoice.direction == "PURCHASE"
    input.jdg_entrepreneur.vat_proportion < 1.0
    vat_proportion := object.get(input.jdg_entrepreneur, "vat_proportion", 1.0)
    vat_deduction_percent := floor(vat_proportion * 100)

    # De minimis: < 2% → 0%
    vat_proportion >= 0.02
} else := {
    "matched": true, "rule_id": "jdg.vat.deductions.pre_proportion_de_minimis",
    "package": "jdg.vat.deductions", "priority": 185,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "PRE_PROPORTION_DE_MINIMIS", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "Proporcja < 2% — brak odliczenia VAT",
    "_legal_basis": "Art. 86 ust. 2g VAT",
    "_warnings": ["Proporcja VAT < 2% — brak prawa do odliczenia"]
} {
    vat_proportion := object.get(input.jdg_entrepreneur, "vat_proportion", 1.0)
    vat_proportion < 0.02
    vat_proportion > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P186: vehicle_50_vat_deduction — Auto mieszane → 50% VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.vehicle_50pct",
    "package": "jdg.vat.deductions", "priority": 186,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VEHICLE_50PCT", "vat_exemption": "",
    "vat_deduction_percent": 50, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86a VAT",
    "_warnings": ["Samochód mieszany — odliczenie 50% VAT"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code == "CAR"
    input.invoice.private_use_percent > 0
    input.invoice.has_mileage_log == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P186b: vehicle_100_vat_deduction — Auto z ewidencją → 100% VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.vehicle_100pct",
    "package": "jdg.vat.deductions", "priority": 186,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VEHICLE_100PCT", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86a VAT",
    "_warnings": ["Samochód z ewidencją przebiegu — odliczenie 100% VAT"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code == "CAR"
    input.invoice.has_mileage_log == true
    input.invoice.private_use_percent == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P187: annual_vat_correction_assets — Roczna korekta VAT dla środków trwałych
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.annual_correction_assets",
    "package": "jdg.vat.deductions", "priority": 187,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "ANNUAL_CORRECTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 91 VAT",
    "_warnings": ["Roczna korekta VAT dla środków trwałych — 1/5 przez 5 lat (ruchomości) lub 1/10 przez 10 lat (nieruchomości)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "FIXED_ASSET"
    input.jdg_entrepreneur.tax_year_end != null
}

# ═══════════════════════════════════════════════════════════════════════════════
# P188: vat_deduction_deadline_3m — Termin odliczenia VAT: 3 miesiące
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.deadline_3m_expired",
    "package": "jdg.vat.deductions", "priority": 188,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "DEADLINE_EXPIRED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczony 3-miesięczny termin odliczenia VAT",
    "_legal_basis": "Art. 86 ust. 11 VAT",
    "_warnings": ["Przekroczony termin odliczenia VAT (3 miesiące) — odliczenie NIEMOŻLIWE"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.months_since_issue > 3
    input.invoice.is_vat_deducted == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P189: bad_debt_relief_creditor — Ulga złe długi VAT (wierzyciel)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_creditor",
    "package": "jdg.vat.deductions", "priority": 189,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_CREDITOR", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a VAT",
    "_warnings": ["Ulga na złe długi — wierzyciel może skorygować VAT po 150 dniach + zawiadomieniu dłużnika"]
} {
    input.invoice.direction == "SALE"
    input.invoice.is_paid == false
    input.invoice.days_overdue >= 150
    input.invoice.debtor_notified == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P191: import_vat_deduction_timing — Odliczenie VAT od importu wg dokumentu celnego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.import_timing",
    "package": "jdg.vat.deductions", "priority": 191,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "IMPORT_DEDUCTION", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 2 VAT",
    "_warnings": ["Import — odliczenie VAT na podstawie dokumentu celnego SAD"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure == "IMPORT"
    input.invoice.has_customs_document == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P192: vat_refund_timing — Zwrot VAT: terminy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.refund_standard_60d",
    "package": "jdg.vat.deductions", "priority": 192,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_REFUND", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 87 VAT",
    "_warnings": []
} {
    input.invoice.procedure == "VAT_REFUND"
    input.jdg_entrepreneur.is_vat_payer == true
    # Standard return: 60 days
    input.invoice.vat_refund_type == "STANDARD"
} else := {
    "matched": true, "rule_id": "jdg.vat.deductions.refund_accelerated_25d",
    "package": "jdg.vat.deductions", "priority": 192,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_REFUND_ACCELERATED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 87 ust. 6 VAT",
    "_warnings": ["Zwrot VAT przyśpieszony — 25 dni"]
} {
    input.invoice.procedure == "VAT_REFUND"
    input.invoice.vat_refund_type == "ACCELERATED"
}
