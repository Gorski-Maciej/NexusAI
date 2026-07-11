# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — VAT: Procedures (Marża, OSS, VAT-RR, Tax Point, Metoda kasowa)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Procedures — Margin, OSS/IOSS, Tax Point, Cash Accounting, RR
# description: |
#   PAS 4c Multi-Pass. First-Match-Wins else-chain. Procedury VAT:
#   tax point usług ciągłych (P230), zaliczki (P231), VAT-UE kwartalnie (P232),
#   VAT-Z deregistration (P233), termin płatności 25. dnia (P234),
#   metoda kasowa (P235), VAT RR rolnik (P152), marża używane (P66),
#   OSS B2C (P67), IOSS import ≤150 EUR (P68).
# architecture: Multi-Pass PAS 4c (ADR-001)
# legal_basis: Art. 19a-21, 100, 103, 115-118, 120 VAT
# edge_cases:
#   - P235: small_taxpayer + vat_cash_accounting → tax_point = PAYMENT_DATE
#   - P152: VAT RR wymaga przelewu w 14 dni
#   - P68: IOSS tylko dla importu NON_EU ≤ 150 EUR
# package: jdg.vat.procedures
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# Architektura: First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.5 + Doc 33 (Art. 19a-21, 120 VAT)
#
# package: jdg.vat.procedures
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.procedures

import data.jdg.helpers

# ── Default ────────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.procedures.no_match",
    "package": "jdg.vat.procedures",
    "priority": 245
}

# ═══════════════════════════════════════════════════════════════════════════════
# P230: vat_tax_point_continuous_service — Usługi ciągłe: koniec okresu
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.procedures.tax_point_continuous",
    "package": "jdg.vat.procedures", "priority": 230,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "tax_point": "END_OF_PERIOD",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19a ust. 3 VAT",
    "_warnings": ["Usługa ciągła — obowiązek podatkowy na koniec okresu rozliczeniowego"]
} {
    input.invoice.is_continuous_service == true
    input.invoice.is_paid == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P231: vat_tax_point_advance_invoice — Zaliczka: data otrzymania
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.tax_point_advance",
    "package": "jdg.vat.procedures", "priority": 231,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "tax_point": "PAYMENT_DATE",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19a ust. 8 VAT",
    "_warnings": ["Faktura zaliczkowa — obowiązek podatkowy w dacie otrzymania zaliczki"]
} {
    input.invoice.invoice_type == "ADVANCE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P232: vat_ue_quarterly_summary — VAT-UE kwartalna informacja
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.vat_ue_quarterly",
    "package": "jdg.vat.procedures", "priority": 232,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_ue_summary_required": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 100 ust. 1 pkt 2-3 VAT",
    "_warnings": ["Transakcje UE — obowiązek informacji podsumowującej VAT-UE kwartalnie"]
} {
    input.invoice.procedure in {"WDT", "WNT", "TRIANGULAR"}
    input.jdg_entrepreneur.is_vat_eu_registered == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P233: vat_z_deregistration — Obowiązek VAT-Z przy zaprzestaniu działalności
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.vat_z_deregistration",
    "package": "jdg.vat.procedures", "priority": 233,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_z_required": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 96 ust. 6 VAT",
    "_warnings": ["Zaprzestanie działalności VAT — obowiązek złożenia VAT-Z w 30 dni"]
} {
    input.jdg_entrepreneur.business_status in {"CLOSED", "IN_SUCCESSIO"}
    input.jdg_entrepreneur.is_vat_payer == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P234: vat_payment_deadline — Termin płatności VAT: 25. dzień miesiąca
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.payment_deadline",
    "package": "jdg.vat.procedures", "priority": 234,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_payment_due_day": 25,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 103 ust. 1 VAT",
    "_warnings": []
} {
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.direction == "SALE"
    input.jdg_entrepreneur.vat_period == "MONTHLY"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P235: vat_cash_accounting_jdg — Metoda kasowa VAT dla małych podatników
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.cash_accounting_jdg",
    "package": "jdg.vat.procedures", "priority": 235,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_cash_accounting": true,
    "vat_tax_point": "PAYMENT_DATE",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["Metoda kasowa VAT — obowiązek podatkowy w dacie zapłaty"]
} {
    input.jdg_entrepreneur.is_small_taxpayer == true
    input.jdg_entrepreneur.is_vat_payer == true
    input.jdg_entrepreneur.vat_cash_accounting == true
    input.invoice.direction == "SALE"
} else := {
    "matched": true, "rule_id": "jdg.vat.procedures.cash_accounting_purchase",
    "package": "jdg.vat.procedures", "priority": 235,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_cash_accounting": true,
    "vat_deduction_timing": "PAYMENT_DATE",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 VAT",
    "_warnings": ["Metoda kasowa VAT — odliczenie w dacie zapłaty faktury zakupowej"]
} {
    input.jdg_entrepreneur.is_small_taxpayer == true
    input.jdg_entrepreneur.vat_cash_accounting == true
    input.invoice.direction == "PURCHASE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P152: vat_farmer_rr_purchase — VAT RR — zakup od rolnika ryczałtowego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.farmer_rr",
    "package": "jdg.vat.procedures", "priority": 152,
    "vat_rate": "0.07", "rounding_level": "position", "gtu_code": "", "procedure": "VAT_RR",
    "vat_exemption": "", "vat_rr_payment_condition": "PRZELEW_W_CIAGU_14_DNI",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 115-118 VAT",
    "_warnings": ["VAT RR — zakup od rolnika ryczałtowego. Odliczenie tylko przy przelewie w 14 dni!"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.is_agricultural_produce == true
    input.vendor.is_flat_rate_farmer == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P66: VAT-marża — towary używane, dzieła sztuki, antyki
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.margin_used_goods",
    "package": "jdg.vat.procedures", "priority": 66,
    "vat_rate": "0.23", "rounding_level": "total", "gtu_code": "", "procedure": "MARGIN_USED_GOODS",
    "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 120 ust. 4 VAT",
    "_warnings": ["Procedura marży — towary używane"]
} {
    input.invoice.category_code in {"USED_GOODS", "ANTIQUES", "COLLECTORS_ITEMS", "ARTWORKS"}
    input.invoice.procedure == "MARGIN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P67: OSS — VAT wg kraju konsumenta B2C
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.oss_b2c",
    "package": "jdg.vat.procedures", "priority": 67,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "OSS",
    "vat_exemption": "", "vat_oss_applicable": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28c VAT + rozp. 2019/2026",
    "_warnings": ["OSS — VAT według stawki kraju konsumenta (B2C)"]
} {
    input.invoice.direction == "SALE"
    input.vendor.is_b2c == true
    input.vendor.country in eu_countries
}

# ═══════════════════════════════════════════════════════════════════════════════
# P68: WSTO / IOSS — Import małych przesyłek ≤ 150 EUR
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.ioss_import",
    "package": "jdg.vat.procedures", "priority": 68,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "IOSS",
    "vat_exemption": "", "vat_ioss_applicable": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 33a VAT",
    "_warnings": ["IOSS — import małych przesyłek ≤ 150 EUR"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure == "IMPORT"
    input.vendor.country == "NON_EU"
    helpers.jdg_amount_eur <= 150
}

# ── EU countries list ──────────────────────────────────────────────────────────
eu_countries := {
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
}
