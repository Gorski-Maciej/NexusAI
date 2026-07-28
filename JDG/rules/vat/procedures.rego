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
# V.07: Art. 19a ust. 5 pkt 3 VAT — Obowiązek podatkowy przy fakturowaniu z dołu
# Jeśli faktura wystawiona w terminie do 60 dni od wykonania usługi, obowiązek
# podatkowy powstaje z chwilą wystawienia faktury (ale nie później niż 60 dnia).
# JDG często myli — wystawia FV z opóźnieniem → obowiązek za zły miesiąc.
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.procedures.tax_point_delayed_invoice_60d",
    "package": "jdg.vat.procedures", "priority": 227,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "tax_point": tax_point_result,
    "vat_tax_point_day": tax_point_day,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19a ust. 5 pkt 3 VAT",
    "_warnings": [sprintf("FAKTUROWANIE Z DOŁU — usługa wykonana %s, faktura %s (%d dni po). Obowiązek podatkowy: %s. Uwaga: max 60 dni od wykonania!", [service_date, invoice_date, days_diff, tax_point_result])]
} {
    input.invoice.is_service == true
    input.invoice.invoice_issued == true
    input.invoice.invoice_issue_date != ""
    input.invoice.service_completion_date != ""

    days_diff := helpers.days_between(input.invoice.service_completion_date, input.invoice.invoice_issue_date)
    days_diff <= 60
    days_diff > 0

    # Obowiązek w dacie faktury, ale max 60 dnia od wykonania
    tax_point_day = days_diff { days_diff <= 60 }
    tax_point_result = "INVOICE_DATE" { days_diff <= 60 }

    service_date := input.invoice.service_completion_date
    invoice_date := input.invoice.invoice_issue_date
}

# ═══════════════════════════════════════════════════════════════════════════════
# P230: vat_tax_point_continuous_service — Usługi ciągłe: koniec okresu
# ═══════════════════════════════════════════════════════════════════════════════
else := {
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
    input.invoice.category_code in {"USED_GOODS", "ANTIQUES", "COLLECTORS_ITEMS"}
    input.invoice.procedure == "MARGIN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P66a: VAT-marża — dzieła sztuki (8% stawka obniżona wg Art. 120 ust. 4-5)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.margin_art_objects",
    "package": "jdg.vat.procedures", "priority": 66,
    "vat_rate": "0.08", "rounding_level": "total", "gtu_code": "", "procedure": "MARGIN_ART_OBJECTS",
    "vat_exemption": "", "vat_margin_scheme": "ART_OBJECTS_8PCT",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 120 ust. 4-5 VAT (stawka obniżona 8% dla dzieł sztuki)",
    "_warnings": ["Procedura marży — dzieła sztuki (8% VAT). Wymagana dokumentacja: imię/nazwisko twórcy, data nabycia, cena zakupu."]
} {
    input.invoice.category_code == "ARTWORKS"
    input.invoice.procedure == "MARGIN"
    input.invoice.is_original_artwork == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P66b: VAT-marża — biuro podróży (Art. 119 VAT)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.margin_travel_agency",
    "package": "jdg.vat.procedures", "priority": 66,
    "vat_rate": "0.23", "rounding_level": "total", "gtu_code": "", "procedure": "MARGIN_TRAVEL_AGENCY",
    "vat_exemption": "", "vat_margin_scheme": "TRAVEL_AGENCY_ART119",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT (procedura marży dla usług turystycznych)",
    "_warnings": ["Procedura marży — biuro podróży. Podstawa opodatkowania = marża (cena - koszty podwykonawców). Faktura oznaczona 'procedura marży dla usług turystycznych'."]
} {
    input.invoice.category_code == "TRAVEL_SERVICES"
    input.invoice.procedure == "MARGIN"
    input.invoice.is_travel_package == true
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

# ═══════════════════════════════════════════════════════════════════════════════
# P236: vat_23_new_vehicle_registration — VAT-23 dla nowych środków transportu
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.vat_23_new_vehicle",
    "package": "jdg.vat.procedures", "priority": 236,
    "vat_rate": "0.23", "rounding_level": "position", "gtu_code": "GTU_09", "procedure": "VAT_23",
    "vat_exemption": "", "vat_23_required": true, "vat_23_deadline_days": 14,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 103 ust. 3-4 VAT",
    "_warnings": [sprintf("VAT-23 — nowy środek transportu z %s. Złóż deklarację VAT-23 w ciągu 14 dni od nabycia + opłać VAT przed rejestracją pojazdu", [object.get(input.vendor, "country", "UE")])]
} {
    input.invoice.category_code in {"CAR_NEW", "MOTORCYCLE_NEW", "BOAT_NEW", "AIRCRAFT_NEW"}
    input.invoice.direction == "PURCHASE"
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P237: vat_25_tax_payment_confirmation — VAT-25 potwierdzenie zapłaty
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.vat_25_payment",
    "package": "jdg.vat.procedures", "priority": 237,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "VAT_25",
    "vat_exemption": "", "vat_25_required_for_registration": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 103 ust. 5-6 VAT",
    "_warnings": ["VAT-25 — wymagane potwierdzenie zapłaty VAT przed rejestracją pojazdu. Wydział komunikacji wymaga VAT-25!"]
} {
    input.invoice.vat_23_paid == true
    input.invoice.vehicle_registration_pending == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P238: wis_binding_rate_info — WIS — Wiążąca Informacja Stawkowa
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.wis_binding_rate",
    "package": "jdg.vat.procedures", "priority": 238,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "WIS",
    "vat_exemption": "", "wis_binding_rate_info_applicable": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 42a-42d VAT (WIS)",
    "_warnings": [sprintf("WIS — wiążąca informacja stawkowa dla %s. Wniosek do Dyrektora KIS. Opłata 40 PLN. Chroni przed zmianą interpretacji przez 5 lat. WIS obowiązuje od dnia wydania!", [goods_desc])]
} {
    input.invoice.wis_required == true
    input.invoice.wis_obtained == false
    goods_desc := object.get(input.invoice, "commodity_description", "towar/usługa")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P239: slim_vat3_procedural — SLIM VAT 3 — zmiany proceduralne 2023+
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.slim_vat3_procedural",
    "package": "jdg.vat.procedures", "priority": 239,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "SLIM_VAT3",
    "vat_exemption": "", "slim_vat3_applies": true,
    "vat_bad_debt_days": 90, "vat_neutrality_extended": true,
    "vat_ksef_phase": vat_ksef_phase,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "SLIM VAT 3 (Dz.U. 2023 poz. 1050)",
    "_warnings": [sprintf("SLIM VAT 3 — ulga złe długi 90 dni, zwrot VAT 40→15 dni, neutralność rozliczeń. %s", [ksef_info])]
} {
    tx_date := object.get(input.invoice, "transaction_date", "")
    tx_date >= "2023-01-01"
    input.jdg_entrepreneur.is_vat_payer == true

    ksef_active := object.get(input.jdg_entrepreneur, "ksef_active", false)
    vat_ksef_phase = "KSeF OBOWIĄZKOWY — wszystkie faktury przez KSeF" { ksef_active == true }
    vat_ksef_phase = "KSeF DOBROWOLNY — możesz wystawiać przez KSeF" { ksef_active == false }
    ksef_info = "KSeF OBOWIĄZKOWY" { ksef_active == true }
    ksef_info = "KSeF dobrowolny" { ksef_active == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P240: vat_sanction_empty_invoice — Sankcja 30% VAT za pustą fakturę
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.empty_invoice_sanction",
    "package": "jdg.vat.procedures", "priority": 240,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "VAT_SANCTION",
    "vat_exemption": "", "vat_sanction_percent": 30,
    "vat_sanction_amount": floor(sanction_amount),
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Sankcja 30% VAT — pusta faktura / brak MPP",
    "_legal_basis": "Art. 108a ust. 5, Art. 109 ust. 5b VAT, Art. 62 KKS",
    "_warnings": [sprintf("SANKCJA 30%% VAT: %.2f PLN! Podstawa: %s. Natychmiast skoryguj deklarację + złóż czynny żal!", [sanction_amount, sanction_reason])]
} {
    is_empty_invoice := object.get(input.invoice, "is_empty_invoice", false)
    is_fake_invoice := object.get(input.invoice, "is_fake_invoice", false)
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross > 15000
    no_split_payment := input.invoice.split_payment_used == false

    # Priorytet przyczyna sankcji: pusta faktura > brak MPP
    qualifies := (is_empty_invoice == true) | (is_fake_invoice == true) | (no_split_payment == true; input.invoice.split_payment_mandatory == true)
    qualifies == true

    sanction_amount := amount_gross * 0.30

    sanction_reason = "Pusta/fikcyjna faktura" { is_empty_invoice == true }
    sanction_reason = "Pusta/fikcyjna faktura" { is_fake_invoice == true }
    else = "Brak split payment przy obowiązku" { no_split_payment == true; not (is_empty_invoice | is_fake_invoice) }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P241: vat_ue_correction — Korekta VAT-UE
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.vat_ue_correction",
    "package": "jdg.vat.procedures", "priority": 241,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "VAT_UE_CORRECTION",
    "vat_exemption": "", "vat_ue_correction_required": true,
    "vat_ue_correction_period": correction_period,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Korekta VAT-UE — wykryto rozbieżność w informacji podsumowującej",
    "_legal_basis": "Art. 100 ust. 4-5 VAT",
    "_warnings": [sprintf("KOREKTA VAT-UE — rozbieżność %.2f PLN za okres %s. Złóż korektę VAT-UE przed kontrolą transgraniczną!", [discrepancy, correction_period])]
} {
    input.jdg_entrepreneur.is_vat_eu_registered == true
    input.invoice.vat_ue_discrepancy_detected == true
    discrepancy := object.get(input.invoice, "vat_ue_discrepancy_amount", 0)
    discrepancy > 0
    correction_period := object.get(input.invoice, "vat_ue_correction_period", "")
}

# ── EU countries list ──────────────────────────────────────────────────────────
eu_countries := {
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
}
