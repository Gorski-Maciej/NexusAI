# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise PCC & Local Taxes Complete (Doc 50: Class IX)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: PCC & Local Taxes Enterprise — Podatek od czynności cywilnoprawnych +
#        Podatek od nieruchomości + Podatek od środków transportu + Opłaty lokalne
# description: |
#   ENTERPRISE v5.0 — Wypełnia lukę 225 punktów prawnych Klasy IX (największa).
#   PCC to podatek od umów cywilnoprawnych (np. kupno auta od Kowalskiego).
#   Podatek od nieruchomości — kluczowy dla JDG z biurem/lokalem firmowym.
#   Implementuje:
#   - PCC od umów sprzedaży, pożyczek, darowizn, działu spadku
#   - PCC-3 deklaracja + terminy (14 dni od zawarcia umowy)
#   - Stawki PCC: 2% nieruchomości, 1% inne, 0.5% pożyczki od rodziny
#   - Podatek od nieruchomości: DN-1, stawki firmowe vs mieszkalne
#   - Podatek od środków transportu: DT-1, samochody >3.5t
#   - Opłata targowa, uzdrowiskowa, reklamowa, od posiadania psów
#   - Wyłączenia PCC przy transakcjach VAT
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Ustawa o PCC (Dz.U. 2025 poz. 789), Ustawa o podatkach lokalnych
#   (Dz.U. 2025 poz. 1234), Art. 2 pkt 4 PCC (wyłączenie VAT)
# package: jdg.local_taxes.pcc_enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.local_taxes.pcc_enterprise

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.local_taxes.pcc_enterprise.no_match",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 1599
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L1: L800-L809 — PCC — UMOWA SPRZEDAŻY (10 reguł)                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L800: pcc_sale_transaction_detection — Czy umowa podlega PCC? ──
decide := {
    "matched": true, "rule_id": "jdg.local_taxes.pcc.sale_detection",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 800,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pcc_applies": pcc_flag,
    "pcc_transaction_type": "SALE",
    "pcc_rate_pct": pcc_rate,
    "pcc_tax_due_pln": pcc_tax,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": pcc_routing,
    "_routing_reason": sprintf("PCC od umowy sprzedaży %.0f PLN — stawka %.1f%% = %.2f PLN [%s]", [market_value, pcc_rate, pcc_tax, pcc_reason]),
    "_legal_basis": "Art. 1 ust. 1 pkt 1, Art. 6-7 ustawy o PCC",
    "_warnings": [sprintf("PCC — UMOWA SPRZEDAŻY. Wartość rynkowa: %.2f PLN. %s. Stawka: %.1f%%. Podatek: %.2f PLN. Złóż PCC-3 w ciągu 14 dni od zawarcia umowy! UWAGA: Jeśli sprzedawca jest VAT-owcem i wystawia fakturę VAT → PCC NIE obowiązuje (Art. 2 pkt 4 PCC)!", [market_value, pcc_reason, pcc_rate, pcc_tax])],
    "valid_from": "2001-01-01", "valid_to": null,
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.transaction_type in {"CIVIL_LAW_SALE", "PRIVATE_SALE", "CAR_PURCHASE_PRIVATE"}
    market_value := object.get(input.invoice, "amount_gross", 0)
    is_vat_transaction := object.get(input.invoice, "is_vat_invoice", false)
    is_from_vat_payer := object.get(input.vendor, "is_vat_payer", false)
    # Wyłączenie: transakcja VAT
    pcc_flag = false { is_vat_transaction == true }
    pcc_flag = false { is_from_vat_payer == true }
    pcc_flag = true { is_vat_transaction == false; is_from_vat_payer == false }
    # Stawki PCC
    pcc_rate = 2.0 { input.invoice.category_code in {"REAL_ESTATE", "PROPERTY", "LAND"} }
    pcc_rate = 2.0 { input.invoice.category_code in {"CAR_PURCHASE_PRIVATE", "VEHICLE"} }
    pcc_rate = 1.0 { true }
    pcc_tax := floor(market_value * pcc_rate / 100 * 100) / 100
    pcc_reason = "PCC NIE dotyczy — faktura VAT" { pcc_flag == false }
    pcc_reason = "PCC OBOWIĄZUJE — umowa cywilnoprawna bez VAT" { pcc_flag == true }
    pcc_routing = "BLOCK_AND_ALERT" { pcc_flag == true and pcc_tax > 5000 }
    pcc_routing = "TRIAGE_QUEUE" { pcc_flag == true and pcc_tax <= 5000 }
    pcc_routing = "" { pcc_flag == false }
}

# ── L801: pcc_loan_borrow — PCC od pożyczki ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.pcc.loan_borrow",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 801,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pcc_applies": pcc_flag,
    "pcc_transaction_type": "LOAN",
    "pcc_rate_pct": pcc_rate,
    "pcc_tax_due_pln": pcc_tax,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": pcc_routing,
    "_routing_reason": sprintf("PCC od pożyczki %.0f PLN — %.1f%% = %.2f PLN", [loan_amount, pcc_rate, pcc_tax]),
    "_legal_basis": "Art. 1 ust. 1 pkt 2, Art. 7 ust. 1 pkt 4 ustawy o PCC",
    "_warnings": [sprintf("PCC — POŻYCZKA %.2f PLN. %s. Stawka: %.1f%% od nadwyżki ponad %.0f PLN. Podatek: %.2f PLN. Złóż PCC-3 w ciągu 14 dni. UWAGA: (1) Pożyczka od rodziny (I grupa podatkowa) powyżej %.0f PLN = ZWOLNIONA z PCC jeśli zgłosisz do US w 6 mies., (2) Pożyczka od wspólnika = PCC 0.5%%.", [loan_amount, pcc_note, pcc_rate, exemption_limit, pcc_tax, family_exemption_limit])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.transaction_type in {"LOAN", "BORROWING", "CREDIT_FROM_INDIVIDUAL"}
    loan_amount := object.get(input.invoice, "amount_gross", 0)
    is_family := object.get(input.invoice, "is_family_loan", false)
    is_bank := object.get(input.invoice, "is_bank_loan", false)
    exemption_limit := 1000
    family_exemption_limit := 36120
    # Wyłączenia
    pcc_flag = false { is_bank == true }  # Banki zwolnione z PCC
    pcc_flag = false { is_family == true; loan_amount <= family_exemption_limit }
    pcc_flag = true { true }
    pcc_rate = 0.5
    taxable_amount := max([0, loan_amount - exemption_limit])
    pcc_tax := floor(taxable_amount * pcc_rate / 100 * 100) / 100
    pcc_note = "ZWOLNIONE — pożyczka rodzinna" { is_family == true and loan_amount <= family_exemption_limit }
    pcc_note = "Do zgłoszenia w US (zwolnienie rodzinne powyżej limitu)" { is_family == true and loan_amount > family_exemption_limit }
    pcc_note = "PCC OBOWIĄZUJE" { is_family == false; is_bank == false }
    pcc_routing = "TRIAGE_QUEUE" { pcc_flag == true and pcc_tax > 0 }
    pcc_routing = "" { pcc_flag == false }
}

# ── L802: pcc_donation — PCC od darowizny ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.pcc.donation",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 802,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pcc_applies": false,
    "pcc_transaction_type": "DONATION",
    "pcc_note": "PCC nie dotyczy darowizn — podlega podatkowi od spadków i darowizn (SD-3)",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 ustawy o PCC (wyłączenie darowizn)",
    "_warnings": ["PCC — DAROWIZNA. Darowizny NIE podlegają PCC! Podlegają podatkowi od spadków i darowizn (SD-3). Zgłoś w ciągu 6 miesięcy. Stawki: 0%% (I grupa, do 36 120 PLN), 3-20%% (II-III grupa)."]
} {
    input.invoice.transaction_type == "DONATION"
}

# ── L803: pcc_declaration_pcc3_deadline — Termin PCC-3 14 dni ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.pcc.declaration_deadline_14d",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 803,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pcc_declaration_required": true,
    "pcc_declaration_form": "PCC-3",
    "pcc_declaration_deadline_days": 14,
    "pcc_days_since_transaction": days_since,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": deadline_routing,
    "_routing_reason": sprintf("PCC-3 — %d dni od transakcji (termin: 14 dni). %s", [days_since, deadline_status]),
    "_legal_basis": "Art. 10 ust. 1 ustawy o PCC",
    "_warnings": [sprintf("PCC-3 TERMIN — %d dni od zawarcia umowy (masz 14 dni!). %s. Opóźnienie = odsetki od zaległości podatkowych + potencjalna kara KKS. Złóż PCC-3 w US właściwym dla miejsca zamieszkania.", [days_since, deadline_action])]
} {
    input.invoice.transaction_type in {"CIVIL_LAW_SALE", "PRIVATE_SALE", "LOAN", "BORROWING"}
    # Only fire if PCC actually applies (not excluded by VAT)
    is_vat_transaction := object.get(input.invoice, "is_vat_invoice", false)
    not is_vat_transaction
    not object.get(input.vendor, "is_vat_payer", false)
    transaction_date := object.get(input.invoice, "transaction_date", "")
    transaction_date != ""
    pcc3_filed := object.get(input.invoice, "pcc3_filed", false)
    transaction_ns := time.parse_ns("2006-01-02", transaction_date)
    now_ns := time.now_ns()
    days_since := floor((now_ns - transaction_ns) / 86400000000000)
    deadline_status = "PRZEKROCZONY TERMIN!" { days_since > 14 }
    deadline_status = "Jeszcze masz czas" { days_since <= 14 }
    deadline_action = "NATYCHMIAST złóż PCC-3 z czynnym żalem!" { days_since > 14 and not pcc3_filed }
    deadline_action = "Złóż PCC-3 do końca terminu" { days_since <= 14 and not pcc3_filed }
    deadline_action = "OK — złożono" { pcc3_filed == true }
    deadline_routing = "BLOCK_AND_ALERT" { days_since > 14 and not pcc3_filed }
    deadline_routing = "" { pcc3_filed == true or days_since <= 14 }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L2: L810-L819 — PODATEK OD NIERUCHOMOŚCI (DN-1)                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L810: real_estate_tax_business_vs_residential — Stawka firmowa vs mieszkalna ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.property.business_vs_residential",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 810,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "property_tax_applies": true,
    "property_type": prop_type,
    "property_tax_rate_per_sqm": tax_rate,
    "property_tax_annual_pln": annual_tax,
    "property_declaration_form": "DN-1",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Podatek od nieruchomości: %s — %.2f PLN/m² × %.0f m² = %.2f PLN/rok", [prop_type, tax_rate, area, annual_tax]),
    "_legal_basis": "Art. 2-7 ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("PODATEK OD NIERUCHOMOŚCI — %s. Powierzchnia: %.0f m². Stawka: %.2f PLN/m²/rok. Roczny podatek: %.2f PLN. (1) Złóż DN-1 do 14 dni od nabycia/zmiany, (2) Płatność w ratach: do 15 marca, maja, września, listopada, (3) Stawka FIRMOWA (~33 PLN/m²) vs MIESZKALNA (~1.15 PLN/m²) — ogromna różnica!", [prop_type, area, tax_rate, annual_tax])]
} {
    input.jdg_entrepreneur.has_business_property == true
    area := object.get(input.jdg_entrepreneur, "property_area_m2", 50)
    is_residential := object.get(input.jdg_entrepreneur, "property_is_residential", false)
    is_business := object.get(input.jdg_entrepreneur, "property_is_business", false)
    tax_rate = 1.15 { is_residential == true; is_business == false }
    tax_rate = 33.00 { is_business == true }
    tax_rate = 1.15 { is_business == false; is_residential == false }
    prop_type = "MIESZKALNY (budynek mieszkalny)" { is_residential == true; is_business == false }
    prop_type = "FIRMOWY (związany z działalnością)" { is_business == true }
    prop_type = "GRUNT POD DZIAŁALNOŚĆ" { is_business == false; is_residential == false }
    annual_tax := floor(area * tax_rate * 100) / 100
}

# ── L811: real_estate_tax_declaration_dn1 — Obowiązek złożenia DN-1 ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.property.dn1_declaration",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 811,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "property_dn1_required": true,
    "property_dn1_deadline_days": 14,
    "property_dn1_filed": dn1_filed,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": dn1_routing,
    "_routing_reason": sprintf("DN-1 — deklaracja na podatek od nieruchomości. %s", [dn1_status]),
    "_legal_basis": "Art. 6 ust. 9 ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("DN-1 — %s. Termin: 14 dni od nabycia/zmiany nieruchomości. Złóż w urzędzie gminy właściwym dla położenia nieruchomości. Opłata w 4 ratach rocznych.", [dn1_status])]
} {
    input.jdg_entrepreneur.has_business_property == true
    dn1_filed := object.get(input.jdg_entrepreneur, "dn1_filed", false)
    dn1_status = "ZŁOŻONA" { dn1_filed == true }
    dn1_status = "NIEZŁOŻONA — złóż natychmiast!" { dn1_filed == false }
    dn1_routing = "BLOCK_AND_ALERT" { not dn1_filed }
    dn1_routing = "" { dn1_filed }
}

# ── L812: real_estate_tax_payment_schedule — Harmonogram płatności ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.property.payment_schedule",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 812,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "property_payment_installments": ["MARCH_15", "MAY_15", "SEPTEMBER_15", "NOVEMBER_15"],
    "property_installment_amount_pln": installment,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 11-13 ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("PODATEK OD NIERUCHOMOŚCI — Płatność w 4 ratach po %.2f PLN: (1) do 15 marca, (2) do 15 maja, (3) do 15 września, (4) do 15 listopada. Przy kwocie do 100 PLN — jednorazowo do 15 marca.", [installment])]
} {
    input.jdg_entrepreneur.has_business_property == true
    annual_tax := object.get(input.jdg_entrepreneur, "property_tax_annual", 400)
    installment := floor(annual_tax / 4 * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L3: L820-L829 — PODATEK OD ŚRODKÓW TRANSPORTU (DT-1)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L820: transport_tax_truck_over_3_5t — Podatek od ciężarówek >3.5t ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.transport.truck_over_3_5t",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 820,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "transport_tax_applies": true,
    "transport_tax_dmv_kg": dmv,
    "transport_tax_annual_pln": annual_tax,
    "transport_declaration_form": "DT-1",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Podatek od środków transportu: DMC %.0f kg — %.2f PLN/rok", [dmv, annual_tax]),
    "_legal_basis": "Art. 8-14 ustawy o podatkach i opłatach lokalnych",
    "_warnings": [sprintf("PODATEK OD ŚRODKÓW TRANSPORTU — Samochód ciężarowy DMC %.0f kg. Podatek roczny: %.2f PLN. Złóż DT-1 do 15 lutego. Płatność w 2 ratach: do 15 lutego i 15 września.", [dmv, annual_tax])],
    "valid_from": "2002-01-01", "valid_to": null,
} {
    input.jdg_entrepreneur.has_heavy_vehicle == true
    dmv := object.get(input.jdg_entrepreneur, "vehicle_dmv_kg", 3500)
    dmv > 3500
    annual_tax = 800 { dmv <= 5500 }
    annual_tax = 1200 { dmv > 5500; dmv <= 9000 }
    annual_tax = 1800 { dmv > 9000; dmv <= 16000 }
    annual_tax = 2500 { dmv > 16000 }
}

# ── L821: transport_tax_tractor_unit — Ciągnik siodłowy ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.transport.tractor_unit",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 821,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "transport_tax_type": "TRACTOR_UNIT",
    "transport_tax_annual_pln": 2300,
    "transport_declaration_form": "DT-1",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "Podatek od ciągnika siodłowego — 2 300 PLN/rok",
    "_legal_basis": "Art. 10 ustawy o podatkach i opłatach lokalnych",
    "_warnings": ["PODATEK OD CIĄGNIKA SIODŁOWEGO — 2 300 PLN/rok. Złóż DT-1 do 15 lutego. Płatność w 2 ratach."]
} {
    input.jdg_entrepreneur.vehicle_type == "TRACTOR_UNIT"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L4: L830-L839 — INNE PODATKI I OPŁATY LOKALNE                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L830: advertising_fee — Opłata reklamowa ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.advertising.fee",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 830,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "advertising_fee_applies": true,
    "advertising_board_area_m2": ad_area,
    "advertising_fee_daily_pln": daily_fee,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Opłata reklamowa: tablica %.1f m² — %.2f PLN/dzień", [ad_area, daily_fee]),
    "_legal_basis": "Art. 18a-18d ustawy o podatkach i opłatach lokalnych (opłata reklamowa)",
    "_warnings": [sprintf("OPŁATA REKLAMOWA — Tablica reklamowa %.1f m². %.2f PLN/dzień. Uchwała rady gminy określa stawki. Nie każda gmina pobiera!", [ad_area, daily_fee])]
} {
    input.jdg_entrepreneur.has_advertising_board == true
    ad_area := object.get(input.jdg_entrepreneur, "advertising_board_area_m2", 2.0)
    # Domyślna maksymalna stawka ustawowa
    daily_fee := floor(ad_area * 3.20 * 100) / 100
}

# ── L831: market_fee — Opłata targowa ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.market_fee",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 831,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "market_fee_applies": true,
    "market_fee_daily_pln": market_fee_daily,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Opłata targowa: %.2f PLN/dzień", [market_fee_daily]),
    "_legal_basis": "Art. 15-18 ustawy o podatkach i opłatach lokalnych (opłata targowa)",
    "_warnings": [sprintf("OPŁATA TARGOWA — Sprzedaż na targowisku: %.2f PLN/dzień. Pobiera gmina. Stawka zależy od rodzaju sprzedaży i powierzchni.", [market_fee_daily])]
} {
    input.invoice.is_market_sale == true
    market_fee_daily := 40
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L5: L840-L849 — AKCYZA DLA JDG (podstawy)                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L1b: L804-L809 — PCC ROZSZERZONE: Spółki, Zamiana, Hipoteka      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L804: pcc_company_formation — PCC od umowy spółki / zmiany umowy ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.pcc.company_formation",
    "package":"jdg.local_taxes.pcc_enterprise","priority":804,
    "pcc_transaction_type":"COMPANY_FORMATION",
    "pcc_rate_pct":0.5,"pcc_tax_due_pln":pcc_tax,
    "_routing":pcc_routing,"_routing_reason":sprintf("PCC od umowy spółki — 0.5%% od %.0f PLN = %.2f PLN",[capital,pcc_tax]),
    "_legal_basis":"Art. 1 ust. 1 pkt 1-2, Art. 7 ust. 1 pkt 9 ustawy o PCC",
    "_warnings":[sprintf("PCC — UMOWA SPÓŁKI / PODWYŻSZENIE KAPITAŁU. Wartość wkładu: %.2f PLN. PCC 0.5%% = %.2f PLN. Złóż PCC-3 w 14 dni! UWAGA: (1) Przekształcenie JDG w Sp. z o.o. = PCC 0.5%% od wartości wkładu, (2) Podwyższenie kapitału zakładowego = PCC od kwoty podwyższenia.",[capital,pcc_tax])]
} {
    input.invoice.transaction_type in {"COMPANY_FORMATION","SHARE_CAPITAL_INCREASE","JDG_TO_SPZOO"}
    capital:=object.get(input.invoice,"amount_net",0)
    is_eea:=object.get(input.invoice,"is_eea_company",false)
    pcc_rate=0.5
    taxable:=capital{capital<100000}
    taxable:=capital{capital>=100000}
    pcc_tax:=floor(taxable*pcc_rate/100*100)/100
    pcc_routing="TRIAGE_QUEUE"{pcc_tax>1000}
    pcc_routing=""{pcc_tax<=1000}
}

# ── L805: pcc_exchange_contract — PCC od umowy zamiany ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.pcc.exchange_contract",
    "package":"jdg.local_taxes.pcc_enterprise","priority":805,
    "pcc_transaction_type":"EXCHANGE","pcc_rate_pct":pcc_rate,"pcc_tax_due_pln":pcc_tax,
    "_routing":"TRIAGE_QUEUE","_routing_reason":sprintf("PCC od umowy zamiany — %.1f%% od wyższej wartości = %.2f PLN",[pcc_rate,pcc_tax]),
    "_legal_basis":"Art. 1 ust. 1 pkt 1, Art. 7 ust. 1 ustawy o PCC",
    "_warnings":[sprintf("PCC — UMOWA ZAMIANY. Wartość przedmiotu A: %.2f PLN, przedmiotu B: %.2f PLN. PCC płacisz od WYŻSZEJ wartości (%.2f PLN) wg stawki dla tego przedmiotu (%.1f%%). Podatek: %.2f PLN. Złóż PCC-3 w 14 dni!",[value_a,value_b,higher_value,pcc_rate,pcc_tax])]
} {
    input.invoice.transaction_type=="EXCHANGE"
    value_a:=object.get(input.invoice,"item_a_value",0)
    value_b:=object.get(input.invoice,"item_b_value",0)
    is_real_estate:=object.get(input.invoice,"is_real_estate_exchange",false)
    higher_value:=value_a{value_a>=value_b}
    higher_value:=value_b{value_b>value_a}
    pcc_rate=2.0{is_real_estate}
    pcc_rate=1.0{not is_real_estate}
    pcc_tax:=floor(higher_value*pcc_rate/100*100)/100
}

# ── L806: pcc_inheritance_division — PCC od działu spadku ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.pcc.inheritance_division",
    "package":"jdg.local_taxes.pcc_enterprise","priority":806,
    "pcc_transaction_type":"INHERITANCE_DIVISION","pcc_rate_pct":pcc_rate,"pcc_tax_due_pln":pcc_tax,
    "_routing":pcc_r,"_routing_reason":sprintf("PCC od działu spadku — %.1f%% = %.2f PLN",[pcc_rate,pcc_tax]),
    "_legal_basis":"Art. 1 ust. 1 pkt 5, Art. 7 ust. 1 pkt 6 ustawy o PCC",
    "_warnings":[sprintf("PCC — DZIAŁ SPADKU. Wartość udziału: %.2f PLN. %s Stawka: %.1f%%. Podatek: %.2f PLN (po potrąceniu długów i ciężarów). Złóż PCC-3 w 14 dni od uprawomocnienia się postanowienia sądu.",[inheritance_value,exemption_note,pcc_rate,pcc_tax])]
} {
    input.invoice.transaction_type=="INHERITANCE_DIVISION"
    inheritance_value:=object.get(input.invoice,"amount_net",0)
    is_close_family:=object.get(input.invoice,"is_close_family_inheritance",false)
    has_spouse:=object.get(input.invoice,"inheritance_has_spouse",false)
    pcc_rate=1.0{not is_close_family}
    pcc_rate=1.0{is_close_family;inheritance_value>200000}
    pcc_rate=0.5{is_close_family;inheritance_value<=200000}
    exemption_note="ZWOLNIENIE: najbliższa rodzina (grupa 0)"{inheritance_value<=36120;is_close_family}
    exemption_note="CZĘŚCIOWE: grupa I, małżonek"{has_spouse}
    exemption_note="OPODATKOWANE — brak zwolnień"{not is_close_family;not has_spouse}
    pcc_tax:=floor(inheritance_value*pcc_rate/100*100)/100
    pcc_r="TRIAGE_QUEUE"{pcc_tax>1000}
    pcc_r=""{pcc_tax<=1000}
}

# ── L807: pcc_mortgage_establishment — PCC od ustanowienia hipoteki ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.pcc.mortgage",
    "package":"jdg.local_taxes.pcc_enterprise","priority":807,
    "pcc_transaction_type":"MORTGAGE","pcc_rate_pct":0.1,"pcc_tax_due_pln":pcc_tax,
    "_routing":"","_routing_reason":sprintf("PCC od hipoteki — 0.1%% od %.0f PLN = %.2f PLN",[mortgage_amount,pcc_tax]),
    "_legal_basis":"Art. 1 ust. 1 pkt 1 lit. l, Art. 7 ust. 1 pkt 7 ustawy o PCC",
    "_warnings":[sprintf("PCC — HIPOTEKA. Kwota zabezpieczona: %.2f PLN. PCC 0.1%% = %.2f PLN. Złóż PCC-3 w 14 dni od ustanowienia hipoteki u notariusza.",[mortgage_amount,pcc_tax])]
} {
    input.invoice.transaction_type=="MORTGAGE_ESTABLISHMENT"
    mortgage_amount:=object.get(input.invoice,"amount_net",0)
    pcc_rate=0.1
    pcc_tax:=floor(mortgage_amount*pcc_rate/100*100)/100
}

# ── L808: pcc_surety_guarantee — PCC od poręczenia ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.pcc.surety",
    "package":"jdg.local_taxes.pcc_enterprise","priority":808,
    "pcc_transaction_type":"SURETY","pcc_rate_pct":0.5,"pcc_tax_due_pln":pcc_tax,
    "_routing":"","_routing_reason":sprintf("PCC od poręczenia — 0.5%% = %.2f PLN",[pcc_tax]),
    "_legal_basis":"Art. 1 ust. 1 pkt 1 lit. l, Art. 7 ust. 1 pkt 7 ustawy o PCC",
    "_warnings":[sprintf("PCC — PORĘCZENIE. Kwota poręczenia: %.2f PLN. PCC 0.5%% = %.2f PLN (jeśli nie jest elementem innej opodatkowanej umowy).",[surety_amount,pcc_tax])]
} {
    input.invoice.transaction_type=="SURETY"
    surety_amount:=object.get(input.invoice,"amount_net",0)
    is_part_of_loan:=object.get(input.invoice,"surety_part_of_loan",false)
    pcc_tax:=floor(surety_amount*0.5/100*100)/100{not is_part_of_loan}
    pcc_tax:=0{is_part_of_loan}
}

# ── L809: pcc_installment_sale — PCC od sprzedaży ratalnej ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.pcc.installment_sale",
    "package":"jdg.local_taxes.pcc_enterprise","priority":809,
    "pcc_transaction_type":"INSTALLMENT_SALE","pcc_rate_pct":2.0,"pcc_tax_due_pln":pcc_tax,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od sprzedaży ratalnej — 2% od całej wartości",
    "_legal_basis":"Art. 6 ust. 1 pkt 1 ustawy o PCC",
    "_warnings":[sprintf("PCC — SPRZEDAŻ RATALNA. Całkowita wartość: %.2f PLN. PCC 2%% = %.2f PLN (płacisz od CAŁEJ wartości z góry, nie od rat!). Złóż PCC-3 w 14 dni od zawarcia umowy.",[total_value,pcc_tax])],
    "valid_from":"2001-01-01","valid_to":null,
} {
    input.invoice.transaction_type in {"INSTALLMENT_SALE","LEASE_WITH_PURCHASE_OPTION"}
    total_value:=object.get(input.invoice,"amount_gross",0)
    pcc_tax:=floor(total_value*2.0/100*100)/100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L2b: L813-L819 — NIERUCHOMOŚĆ ROZSZERZONE: Mieszane, Rolny,      ║
# ║  Leśny, Garaże, Budowle, Tymczasowe, Amortyzacja                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L813: property_mixed_use — Nieruchomość częściowo firmowa ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.mixed_use",
    "package":"jdg.local_taxes.pcc_enterprise","priority":813,
    "kus_qualification":"KUP_DEDUCTIBLE_PROPORTIONAL","kus_percent":kup_pct,
    "property_business_pct":business_pct,"property_tax_annual_pln":annual_tax,
    "_routing":"","_routing_reason":sprintf("Nieruchomość mieszana: %.0f%% firmowa, %.0f%% prywatna",[business_pct,100-business_pct]),
    "_legal_basis":"Art. 1a ust. 5, Art. 4 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("NIERUCHOMOŚĆ MIESZANA — %.0f m² całkowitej, z czego %.0f m² (%.0f%%) do działalności. Podatek FIRMOWY od części biznesowej: %.2f PLN × %.0f m² = %.2f PLN. Podatek PRYWATNY od reszty: %.2f PLN × %.0f m² = %.2f PLN. ŁĄCZNIE: %.2f PLN/rok. KUP proporcjonalnie: %.0f%%.",[total_area,business_area,business_pct,biz_rate,business_area,biz_tax,priv_rate,priv_area,priv_tax,annual_tax,kup_pct])]
} {
    input.jdg_entrepreneur.has_business_property==true
    input.jdg_entrepreneur.property_is_mixed_use==true
    total_area:=object.get(input.jdg_entrepreneur,"property_area_m2",100)
    business_area:=object.get(input.jdg_entrepreneur,"property_business_area_m2",30)
    priv_area:=total_area-business_area
    business_pct:=floor(business_area/total_area*100)
    biz_rate:=33.10;priv_rate:=1.15
    biz_tax:=floor(business_area*biz_rate*100)/100
    priv_tax:=floor(priv_area*priv_rate*100)/100
    annual_tax:=biz_tax+priv_tax
    kup_pct:=floor(business_pct)
}

# ── L814: property_agricultural_tax — Podatek rolny zamiast od nieruchomości ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.agricultural",
    "package":"jdg.local_taxes.pcc_enterprise","priority":814,
    "property_agricultural_tax_applies":true,
    "agricultural_hectares":hectares,"ag_tax_annual_pln":ag_tax,
    "_routing":"","_routing_reason":sprintf("Podatek rolny: %.2f ha — %.2f PLN/rok",[hectares,ag_tax]),
    "_legal_basis":"Ustawa o podatku rolnym (Dz.U. 2025 poz. 345)",
    "_warnings":[sprintf("PODATEK ROLNY — %.2f ha przeliczeniowych. Stawka: %.2f q żyta × %.2f PLN/q = %.2f PLN/ha. Podatek roczny: %.2f PLN. UWAGA: Grunty rolne NIE podlegają podatkowi od nieruchomości (podatek rolny go zastępuje)! IR-1 do 15 stycznia.",[hectares,rye_quintals,rye_price,rate_per_ha,ag_tax])]
} {
    input.jdg_entrepreneur.has_agricultural_land==true
    hectares:=object.get(input.jdg_entrepreneur,"agricultural_hectares",1.0)
    rye_price:=object.get(object.get(data.jdg.thresholds,"local_taxes",{}),"rye_price_per_quintal",89.63)
    rye_quintals:=2.5;rate_per_ha:=floor(rye_quintals*rye_price*100)/100
    ag_tax:=floor(hectares*rate_per_ha*100)/100
}

# ── L815: property_forestry_tax — Podatek leśny ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.forestry",
    "package":"jdg.local_taxes.pcc_enterprise","priority":815,
    "property_forestry_tax_applies":true,
    "forest_hectares":hectares,"forest_tax_annual_pln":forest_tax,
    "_routing":"","_routing_reason":sprintf("Podatek leśny: %.2f ha — %.2f PLN/rok",[hectares,forest_tax]),
    "_legal_basis":"Ustawa o podatku leśnym (Dz.U. 2025 poz. 456)",
    "_warnings":[sprintf("PODATEK LEŚNY — %.4f ha. Stawka: %.2f m³ drewna × %.2f PLN/m³ = %.2f PLN/ha. Podatek roczny: %.2f PLN. Las NIE podlega podatkowi od nieruchomości. IL-1 do 15 stycznia.",[hectares,wood_m3,wood_price,rate_per_ha,forest_tax])]
} {
    input.jdg_entrepreneur.has_forest_land==true
    hectares:=object.get(input.jdg_entrepreneur,"forest_hectares",1.0)
    wood_price:=object.get(object.get(data.jdg.thresholds,"local_taxes",{}),"wood_price_per_m3",350.00)
    wood_m3:=0.22;rate_per_ha:=floor(wood_m3*wood_price*100)/100
    forest_tax:=floor(hectares*rate_per_ha*100)/100
}

# ── L816: property_garage_storage — Garaż i pomieszczenia gospodarcze ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.garage",
    "package":"jdg.local_taxes.pcc_enterprise","priority":816,
    "kus_qualification":"KUP_DEDUCTIBLE","kus_percent":100,
    "garage_business_use":is_biz,"garage_tax_annual_pln":garage_tax,
    "_routing":gg_routing,"_routing_reason":sprintf("Garaż firmowy: %.1f m² — %.2f PLN/rok",[garage_area,garage_tax]),
    "_legal_basis":"Art. 1a ust. 1 pkt 3 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("GARAŻ / BUDYNEK GOSPODARCZY — %.1f m². %s Stawka firmowa: %.2f PLN/m² = %.2f PLN/rok. UWAGA: Nawet garaż wolnostojący używany do celów firmowych = stawka firmowa!",[garage_area,usage_note,bldg_rate,garage_tax])]
} {
    input.jdg_entrepreneur.has_business_garage==true
    garage_area:=object.get(input.jdg_entrepreneur,"garage_area_m2",20)
    is_biz:=object.get(input.jdg_entrepreneur,"garage_used_for_business",false)
    bldg_rate:=33.10{is_biz};bldg_rate:=1.15{not is_biz}
    garage_tax:=floor(garage_area*bldg_rate*100)/100
    usage_note="FIRMOWY — do celów działalności"{is_biz}
    usage_note="PRYWATNY"{not is_biz}
    gg_routing="TRIAGE_QUEUE"{is_biz;garage_tax>500}
    gg_routing=""{true}
}

# ── L817: property_construction_tax — Podatek od budowli (2% wartości) ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.construction",
    "package":"jdg.local_taxes.pcc_enterprise","priority":817,
    "kus_qualification":"KUP_DEDUCTIBLE_AMORTIZATION","kus_percent":100,
    "construction_tax_rate_pct":2.0,"construction_tax_annual_pln":constr_tax,
    "_routing":"","_routing_reason":sprintf("Podatek od budowli firmowych — 2%% od %.0f PLN = %.2f PLN/rok",[constr_value,constr_tax]),
    "_legal_basis":"Art. 4 ust. 1 pkt 3 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("PODATEK OD BUDOWLI — Wartość budowli: %.2f PLN (podstawa amortyzacji). Podatek 2%% rocznie = %.2f PLN. DOTYCZY: parkingów, ogrodzeń, sieci, placów, silosów. NIE mylić z budynkami (te podlegają stawce za m²)!",[constr_value,constr_tax])]
} {
    input.jdg_entrepreneur.has_business_constructions==true
    constr_value:=object.get(input.jdg_entrepreneur,"construction_book_value",100000)
    constr_tax:=floor(constr_value*0.02*100)/100
}

# ── L818: property_temp_building — Budynek tymczasowy / kontener ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.temp_building",
    "package":"jdg.local_taxes.pcc_enterprise","priority":818,
    "temp_building_applies":true,"temp_area":tmp_area,
    "temp_tax_monthly_pln":tmp_tax,
    "_routing":"","_routing_reason":sprintf("Budynek tymczasowy %.0f m² — %.2f PLN/mies",[tmp_area,tmp_tax]),
    "_legal_basis":"Art. 6 ust. 2 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("BUDYNEK TYMCZASOWY / KONTENER — %.1f m², używany od %.0f miesięcy. Podatek naliczany proporcjonalnie za okres użytkowania. Przy >1 roku = pełny podatek od nieruchomości.",[tmp_area,months_used])]
} {
    input.jdg_entrepreneur.has_temporary_building==true
    tmp_area:=object.get(input.jdg_entrepreneur,"temp_building_area_m2",15)
    months_used:=object.get(input.jdg_entrepreneur,"temp_building_months",12)
    tmp_tax:=floor(tmp_area*33.10/12*months_used*100)/100{months_used<12}
    tmp_tax:=floor(tmp_area*33.10*100)/100{months_used>=12}
}

# ── L819: property_depreciation_kup — Podatek od nieruchomości jako KUP ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.property.as_kup",
    "package":"jdg.local_taxes.pcc_enterprise","priority":819,
    "kus_qualification":"KUP_DEDUCTIBLE","kus_percent":100,
    "property_tax_kup_note":"Podatek od nieruchomości firmowej stanowi KUP — odliczasz w dacie poniesienia",
    "_routing":"","_routing_reason":"Podatek od nieruchomości = KUP — pamiętaj o odliczeniu!",
    "_legal_basis":"Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 20 PIT",
    "_warnings":["PODATEK OD NIERUCHOMOŚCI = KUP! Każda rata podatku (15.03, 15.05, 15.09, 15.11) stanowi koszt uzyskania przychodu w dacie zapłaty. Pamiętaj o zaksięgowaniu w PKPiR (kolumna 13 — pozostałe wydatki)."]
} {
    input.jdg_entrepreneur.has_business_property==true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L3b: L822-L829 — TRANSPORT ROZSZERZONY: Autobusy, Specjalne,     ║
# ║  Przyczepy, Naczepy, Retro, Sezonowe, Zwolnienia, Terminy                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L822: transport_tax_bus — Autobus ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.bus",
    "package":"jdg.local_taxes.pcc_enterprise","priority":822,
    "kus_qualification":"KUP_DEDUCTIBLE","kus_percent":100,
    "transport_tax_type":"BUS","transport_tax_annual_pln":annual_tax,
    "_routing":"","_routing_reason":sprintf("Autobus %d miejsc — %.0f PLN/rok",[seats,annual_tax]),
    "_legal_basis":"Art. 12 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("AUTOBUS — %d miejsc (z kierowcą). Podatek: %.0f PLN/rok. DT-1 do 15 lutego. 2 raty: 15.02 i 15.09.",[seats,annual_tax])]
} {
    input.jdg_entrepreneur.vehicle_type=="BUS"
    seats:=object.get(input.jdg_entrepreneur,"vehicle_seats",20)
    annual_tax=1600{seats<22};annual_tax=2400{seats>=22;seats<40}
    annual_tax=3000{seats>=40}
}

# ── L823: transport_tax_special_vehicle — Pojazd specjalny ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.special",
    "package":"jdg.local_taxes.pcc_enterprise","priority":823,
    "transport_tax_type":"SPECIAL","transport_tax_annual_pln":annual_tax,
    "_routing":"","_routing_reason":sprintf("Pojazd specjalny — %.0f PLN/rok",[annual_tax]),
    "_legal_basis":"Art. 9-10 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("POJAZD SPECJALNY — %s. DMC: %.1f t. Podatek: %.0f PLN/rok. DT-1.",[spec_type,dmc,annual_tax])]
} {
    input.jdg_entrepreneur.vehicle_type in {"SPECIAL_VEHICLE","CRANE","CONCRETE_MIXER","GARBAGE_TRUCK"}
    dmc:=object.get(input.jdg_entrepreneur,"vehicle_dmv_kg",10000)/1000
    spec_type:=object.get(input.jdg_entrepreneur,"vehicle_type","SPECIAL")
    annual_tax=1200{dmc<=10};annual_tax=1800{dmc>10;dmc<=20};annual_tax=2400{dmc>20}
}

# ── L824: transport_tax_trailer — Przyczepy i naczepy ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.trailer",
    "package":"jdg.local_taxes.pcc_enterprise","priority":824,
    "transport_tax_type":"TRAILER","transport_tax_annual_pln":annual_tax,
    "_routing":"","_routing_reason":sprintf("Przyczepa/naczepa DMC %.1f t — %.0f PLN/rok",[dmc,annual_tax]),
    "_legal_basis":"Art. 10 ust. 1 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("PRZYCZEPA / NACZEPA — DMC %.1f t, %d osi(e). Podatek: %.0f PLN/rok (niezależnie od podatku od ciągnika!).",[dmc,axles,annual_tax])]
} {
    input.jdg_entrepreneur.vehicle_type in {"TRAILER","SEMI_TRAILER"}
    dmc:=object.get(input.jdg_entrepreneur,"vehicle_dmv_kg",8000)/1000
    axles:=object.get(input.jdg_entrepreneur,"vehicle_axles",2)
    annual_tax=800{dmc<=5};annual_tax=1200{dmc>5;dmc<=10}
    annual_tax=1800{dmc>10;dmc<=20};annual_tax=2400{dmc>20;axles==2}
    annual_tax=3200{dmc>20;axles>=3}
}

# ── L825: transport_tax_historic — Pojazd zabytkowy — zwolnienie ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.historic",
    "package":"jdg.local_taxes.pcc_enterprise","priority":825,
    "transport_tax_exempt":true,"transport_tax_annual_pln":0,
    "_routing":"","_routing_reason":"Pojazd zabytkowy — ZWOLNIONY z podatku",
    "_legal_basis":"Art. 12 ust. 1 pkt 2 ustawy o podatkach i opłatach lokalnych",
    "_warnings":["POJAZD ZABYTKOWY — caŁkowicie ZWOLNIONY z podatku od środków transportu. Wymagany wpis do rejestru zabytków lub wojewódzka ewidencja zabytków."]
} {
    input.jdg_entrepreneur.vehicle_is_historic==true
}

# ── L826: transport_tax_ev_hybrid — Pojazd elektryczny / hybrydowy — zwolnienie ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.ev",
    "package":"jdg.local_taxes.pcc_enterprise","priority":826,
    "transport_tax_exempt":true,"transport_tax_annual_pln":0,
    "_routing":"","_routing_reason":"Pojazd elektryczny — ZWOLNIONY z podatku",
    "_legal_basis":"Art. 12 ust. 1 pkt 1 i 2a ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("%s — ZWOLNIONY z podatku od środków transportu! %s",[vehicle_info,charge_info])]
} {
    input.jdg_entrepreneur.vehicle_is_electric==true
    is_hybrid:=object.get(input.jdg_entrepreneur,"vehicle_is_hybrid",false)
    vehicle_info="POJAZD ELEKTRYCZNY";charge_info="Oszczędność: nawet 2500 PLN/rok"{not is_hybrid}
    vehicle_info="HYBRYDA PLUG-IN";charge_info="Zwolnienie 50-100%% zależnie od emisji CO₂"{is_hybrid}
}

# ── L827: transport_tax_seasonal — Pojazd używany sezonowo — podatek proporcjonalny ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.seasonal",
    "package":"jdg.local_taxes.pcc_enterprise","priority":827,
    "transport_tax_seasonal":true,"transport_tax_annual_pln":proportional_tax,
    "_routing":"","_routing_reason":sprintf("Pojazd sezonowy — %.0f PLN (%.0f/12 × %.0f PLN)",[proportional_tax,months,full_tax]),
    "_legal_basis":"Art. 11a ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("POJAZD SEZONOWY — Używany tylko %d miesięcy w roku. Podatek proporcjonalny: %d/12 × %.0f PLN = %.0f PLN. Zgłoś sezonowe wyrejestrowanie w WK.",[months,months,full_tax,proportional_tax])]
} {
    input.jdg_entrepreneur.vehicle_is_seasonal==true
    months:=object.get(input.jdg_entrepreneur,"vehicle_active_months",6)
    dmc:=object.get(input.jdg_entrepreneur,"vehicle_dmv_kg",8000)
    full_tax=800{dmc<=5500};full_tax=1200{dmc>5500;dmc<=9000}
    full_tax=1800{dmc>9000;dmc<=16000};full_tax=2500{dmc>16000}
    proportional_tax:=floor(full_tax*months/12*100)/100
}

# ── L828: transport_tax_dt1_deadline — Termin DT-1 15 lutego ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.dt1_deadline",
    "package":"jdg.local_taxes.pcc_enterprise","priority":828,
    "dt1_required":true,"dt1_deadline":"FEBRUARY_15",
    "dt1_filed":dt1_ok,"dt1_late_days":late_days,
    "_routing":dt1_rt,"_routing_reason":sprintf("DT-1: %s",[dt1_stat]),
    "_legal_basis":"Art. 9 ust. 5 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("DT-1 — %s. Termin: 15 lutego. %s",[dt1_stat,dt1_action])]
} {
    input.jdg_entrepreneur.has_heavy_vehicle==true
    dt1_ok:=object.get(input.jdg_entrepreneur,"dt1_filed",false)
    dt1_stat="ZŁOŻONA"{dt1_ok};dt1_stat="NIEZŁOŻONA"{not dt1_ok}
    dt1_action="OK"{dt1_ok}
    dt1_action="ZŁÓŻ NATYCHMIAST! Opóźnienie = odsetki + kara KKS"{not dt1_ok}
    late_days:=0{dt1_ok};late_days:=99{not dt1_ok}
    dt1_rt="BLOCK_AND_ALERT"{not dt1_ok};dt1_rt=""{dt1_ok}
}

# ── L829: transport_tax_retirement — Wycofanie pojazdu — korekta podatku ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.transport.retirement",
    "package":"jdg.local_taxes.pcc_enterprise","priority":829,
    "transport_tax_refund_eligible":true,
    "transport_tax_refund_pln":refund_amount,
    "_routing":"","_routing_reason":sprintf("Wycofanie pojazdu — zwrot podatku %.2f PLN",[refund_amount]),
    "_legal_basis":"Art. 9 ust. 5-6 ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("WYCOFANIE POJAZDU — Sprzedaż/złomowanie w miesiącu %d. Należny zwrot nadpłaconego podatku za %d pozostałych miesięcy: %.2f PLN. Złóż korektę DT-1 z wnioskiem o zwrot.",[month,remaining,refund_amount])]
} {
    input.jdg_entrepreneur.vehicle_retired==true
    month:=object.get(input.jdg_entrepreneur,"vehicle_retirement_month",6)
    remaining:=12-month
    annual_tax:=object.get(input.jdg_entrepreneur,"transport_tax_annual",1800)
    refund_amount:=floor(annual_tax*remaining/12*100)/100{remaining>0}
    refund_amount:=0{remaining<=0}
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L4b: L832-L839 — OPŁATY LOKALNE ROZSZERZONE: Pies, Miejscowa,    ║
# ║  Uzdrowiskowa, Reklamowa (szczegóły), Kategorie                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L832: dog_ownership_fee — Opłata od posiadania psów ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.dog_fee",
    "package":"jdg.local_taxes.pcc_enterprise","priority":832,
    "dog_fee_applies":true,"dog_count":dog_count,"dog_fee_annual_pln":dog_fee_total,
    "_routing":"","_routing_reason":sprintf("Opłata za %d psa/psy — %.2f PLN/rok",[dog_count,dog_fee_total]),
    "_legal_basis":"Art. 18e-18f ustawy o podatkach i opłatach lokalnych (opłata od posiadania psów)",
    "_warnings":[sprintf("OPŁATA OD POSIADANIA PSÓW — %d pies/psy. %.2f PLN/szt/rok = %.2f PLN. Gmina MOŻE pobierać, nie musi (uchwała rady gminy). Zwolnienia: psy asystujące, gospodarstwa rolne (max 2 psy).",[dog_count,dog_fee_per,dog_fee_total])]
} {
    input.jdg_entrepreneur.has_dogs==true
    dog_count:=object.get(input.jdg_entrepreneur,"dog_count",1)
    dog_fee_per:=object.get(input.jdg_entrepreneur,"dog_fee_per_dog",120)
    dog_fee_total:=dog_count*dog_fee_per
}

# ── L833: resort_fee_category_a — Opłata miejscowa — kategoria A (korzystne warunki) ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.resort_fee_a",
    "package":"jdg.local_taxes.pcc_enterprise","priority":833,
    "resort_fee_category":"A","resort_fee_daily_pln":6.00,
    "_routing":"","_routing_reason":"Opłata miejscowa kat. A — 6.00 PLN/os/dzień",
    "_legal_basis":"Art. 17 ust. 2 ustawy o podatkach i opłatach lokalnych",
    "_warnings":["OPŁATA MIEJSCOWA kat. A — Strefa o szczególnie korzystnych warunkach klimatyczno-krajobrazowych. Maks. 6.00 PLN/os/dzień. Pobiera gmina od turystów przebywających >1 dobę."]
} {
    input.invoice.local_tax_type=="RESORT_FEE_A"
}

# ── L834: resort_fee_category_b — Opłata miejscowa — kategoria B ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.resort_fee_b",
    "package":"jdg.local_taxes.pcc_enterprise","priority":834,
    "resort_fee_category":"B","resort_fee_daily_pln":4.50,
    "_routing":"","_routing_reason":"Opłata miejscowa kat. B — 4.50 PLN/os/dzień",
    "_legal_basis":"Art. 17 ust. 2a ustawy o podatkach i opłatach lokalnych",
    "_warnings":["OPŁATA MIEJSCOWA kat. B — Pozostałe miejscowości turystyczne. Maks. 4.50 PLN/os/dzień."]
} {
    input.invoice.local_tax_type=="RESORT_FEE_B"
}

# ── L835: spa_fee_categories — Opłata uzdrowiskowa — kategorie ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.spa_fee_detailed",
    "package":"jdg.local_taxes.pcc_enterprise","priority":835,
    "spa_fee_daily_pln":spa_rate,"spa_fee_category":spa_cat,
    "_routing":"","_routing_reason":sprintf("Opłata uzdrowiskowa kat. %s — %.2f PLN/os/dzień",[spa_cat,spa_rate]),
    "_legal_basis":"Art. 17a ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("OPŁATA UZDROWISKOWA kat. %s — %.2f PLN/os/dzień. Pobierana w uzdrowiskach. Fundusz uzdrowiskowy finansuje infrastrukturę leczniczą.",[spa_cat,spa_rate])]
} {
    input.invoice.local_tax_type=="SPA_FEE"
    spa_class:=object.get(input.invoice,"spa_class","A")
    spa_rate=8.00{spa_class=="A"};spa_rate=6.00{spa_class=="B"}
    spa_rate=4.50{spa_class=="C"};spa_rate=3.00{spa_class=="D"}
    spa_cat=spa_class
}

# ── L836: advertising_fee_categories — Opłata reklamowa — kategorie ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.advertising.fee_categories",
    "package":"jdg.local_taxes.pcc_enterprise","priority":836,
    "kus_qualification":"KUP_DEDUCTIBLE","kus_percent":100,
    "advertising_fee_daily_pln":total_fee,"advertising_category":at,
    "_routing":"","_routing_reason":sprintf("Opłata reklamowa %s: %.1f m² = %.2f PLN/dzień",[at,area,total_fee]),
    "_legal_basis":"Art. 18a-18d ustawy o podatkach i opłatach lokalnych",
    "_warnings":[sprintf("OPŁATA REKLAMOWA — Typ: %s. Powierzchnia: %.1f m². Stawka: %.2f PLN/m²/dzień (max). %.2f PLN/dzień = ~%.2f PLN/rok. Rada gminy ustala stawki uchwałą.",[at,area,rate,total_fee,total_fee*365])]
} {
    input.jdg_entrepreneur.has_advertising_board==true
    area:=object.get(input.jdg_entrepreneur,"advertising_board_area_m2",3)
    at:=object.get(input.jdg_entrepreneur,"advertising_type","BILLBOARD")
    rate=3.20{at=="BILLBOARD"};rate=2.50{at=="BANNER"}
    rate=1.80{at=="POSTER"};rate=5.00{at=="LED_SCREEN"}
    rate=0.50{at=="SANDWICH_BOARD"}
    total_fee:=floor(area*rate*100)/100
}

# ── L837: advertising_fee_self_advertising_exemption — Zwolnienie dla własnej reklamy na budynku ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.advertising.self_adv_exempt",
    "package":"jdg.local_taxes.pcc_enterprise","priority":837,
    "advertising_fee_exempt":true,
    "_routing":"","_routing_reason":"Reklama własna na własnym budynku — ZWOLNIONA",
    "_legal_basis":"Art. 18b ust. 2 ustawy o podatkach i opłatach lokalnych (zwolnienie dla własnej reklamy)",
    "_warnings":["OPŁATA REKLAMOWA — ZWOLNIENIE! Tablica/szyld reklamujący WŁASNĄ działalność na WŁASNYM budynku NIE podlega opłacie reklamowej. Warunek: powierzchnia ≤ 3 m² i szyld informuje o prowadzonej działalności."]
} {
    input.jdg_entrepreneur.has_advertising_board==true
    input.jdg_entrepreneur.advertising_is_self_promotion==true
    object.get(input.jdg_entrepreneur,"advertising_board_area_m2",1)<=3
}

# ── L838: local_tax_deduction_reminder — Przypomnienie: podatki lokalne = KUP ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.all.kup_deduction",
    "package":"jdg.local_taxes.pcc_enterprise","priority":838,
    "kus_qualification":"KUP_DEDUCTIBLE","kus_percent":100,
    "_routing":"","_routing_reason":"WSZYSTKIE podatki lokalne stanowią KUP — zaksięguj!",
    "_legal_basis":"Art. 22 ust. 1 PIT (wszystkie podatki jako KUP)",
    "_warnings":["PODATKI LOKALNE = KUP! Podatek od nieruchomości, podatek od środków transportu, opłata targowa, opłata reklamowa — wszystkie stanowią koszt uzyskania przychodu. Księguj w PKPiR kolumna 13 (pozostałe wydatki) w dacie zapłaty."]
} {
    input.jdg_entrepreneur.has_local_taxes==true
}

# ── L839: local_tax_calendar — Kalendarz podatków lokalnych ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.calendar",
    "package":"jdg.local_taxes.pcc_enterprise","priority":839,
    "local_tax_calendar":["DN-1: 31 stycznia","DT-1: 15 lutego","IR-1 (rolny): 15 stycznia","IL-1 (leśny): 15 stycznia","PCC-3: 14 dni od umowy","Raty nieruchomość: 15.03, 15.05, 15.09, 15.11"],
    "_routing":"","_routing_reason":"Kalendarz podatków lokalnych — zapamiętaj terminy!",
    "_legal_basis":"Ustawa o podatkach lokalnych i opłatach + Ustawa o PCC",
    "_warnings":["KALENDARZ PODATKÓW LOKALNYCH: DN-1 → 31 stycznia | DT-1 → 15 lutego | IR-1 → 15 stycznia | IL-1 → 15 stycznia | PCC-3 → 14 dni od umowy | Raty PN → 15.03/15.05/15.09/15.11"]
} {
    input.jdg_entrepreneur.has_local_taxes==true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L5b: L841-L849 — AKCYZA ROZSZERZONA: Węgiel, Gaz, Energia,       ║
# ║  Skład Podatkowy, Procedura Zawieszona, Zwolnienia, Sankcje              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── L841: excise_coal_coke — Akcyza od węgla i koksu ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.coal",
    "package":"jdg.local_taxes.pcc_enterprise","priority":841,
    "excise_product_type":"COAL",
    "excise_rate_pln_per_unit":1.28,"excise_amount_pln":excise_amount,
    "_routing":"","_routing_reason":sprintf("Akcyza węglowa: %.1f ton × 1.28 PLN/GJ",[tonnes]),
    "_legal_basis":"Art. 89 ust. 1 pkt 1, Art. 89a ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA WĘGLOWA — %.1f ton węgla/koksu. Akcyza = %.2f PLN. UWAGA: zwolnienie dla gospodarstw domowych! Dla firm — pełna akcyza. e-DD przy przewozie >500 kg.",[tonnes,excise_amount])]
} {
    input.invoice.excise_category=="COAL"
    tonnes:=object.get(input.invoice,"quantity",1.0)
    gj_per_tonne:=25
    excise_amount:=tonnes*gj_per_tonne*1.28
}

# ── L842: excise_gas — Akcyza od gazu ziemnego ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.gas",
    "package":"jdg.local_taxes.pcc_enterprise","priority":842,
    "excise_product_type":"NATURAL_GAS",
    "excise_rate_pln_per_mwh":1.28,"excise_amount_pln":excise_amount,
    "_routing":"","_routing_reason":sprintf("Akcyza gazowa: %.0f MWh — %.2f PLN",[mwh,excise_amount]),
    "_legal_basis":"Art. 89 ust. 1a ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA GAZOWA — %.0f MWh gazu ziemnego. Akcyza: %.2f PLN. Stawka 1.28 PLN/MWh. Zwolnienie: CNG/LNG do napędu silników.",[mwh,excise_amount])]
} {
    input.invoice.excise_category=="NATURAL_GAS"
    mwh:=object.get(input.invoice,"quantity",10)
    excise_amount:=mwh*1.28
}

# ── L843: excise_electricity — Akcyza od energii elektrycznej ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.electricity",
    "package":"jdg.local_taxes.pcc_enterprise","priority":843,
    "excise_product_type":"ELECTRICITY",
    "excise_rate_pln_per_mwh":5.00,"excise_amount_pln":excise_amount,
    "_routing":"","_routing_reason":sprintf("Akcyza elektryczna: %.0f MWh — %.2f PLN",[mwh,excise_amount]),
    "_legal_basis":"Art. 89 ust. 3 ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA OD ENERGII ELEKTRYCZNEJ — %.0f MWh. Akcyza: %.2f PLN (5.00 PLN/MWh). Obowiązek podatkowy: wydanie energii odbiorcy. UWAGA: instalacje OZE do 1 MW = zwolnione z akcyzy!",[mwh,excise_amount])]
} {
    input.invoice.excise_category=="ELECTRICITY"
    mwh:=object.get(input.invoice,"quantity",100)
    is_renewable:=object.get(input.invoice,"is_renewable_energy",false)
    excise_amount:=0{is_renewable;mwh<=1000}
    excise_amount:=mwh*5.00{not is_renewable}
}

# ── L844: excise_energy_products — Akcyza od wyrobów energetycznych ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.energy_products",
    "package":"jdg.local_taxes.pcc_enterprise","priority":844,
    "excise_product_type":"ENERGY_PRODUCTS",
    "excise_rate_pln_per_unit":rate,"excise_amount_pln":excise_amount,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Akcyza od wyrobów energetycznych — obowiązek rejestracji AKC-R!",
    "_legal_basis":"Art. 86-92 ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA — WYRÓB ENERGETYCZNY: %s. Ilość: %.0f %s. Stawka: %.2f PLN/%s. Akcyza: %.2f PLN. Rejestracja AKC-R WYMAGANA!",[product,quantity,unit,rate,unit,excise_amount])]
} {
    input.invoice.excise_category=="ENERGY_PRODUCTS"
    product:=object.get(input.invoice,"energy_product_type","HEATING_OIL")
    quantity:=object.get(input.invoice,"quantity",1000)
    unit="litry"{product=="HEATING_OIL"};unit="kg"{product=="LUBRICANT"}
    rate=1.28{product=="HEATING_OIL"};rate=1.50{product=="LUBRICANT"}
    rate=0.00{product=="BIOFUEL"}
    excise_amount:=quantity*rate
}

# ── L845: excise_warehouse — Skład podatkowy — procedura zawieszona ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.warehouse",
    "package":"jdg.local_taxes.pcc_enterprise","priority":845,
    "excise_warehouse_required":true,"excise_warehouse_type":wh_type,
    "excise_suspension":suspension_active,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Skład podatkowy — wymagane zezwolenie + zabezpieczenie akcyzowe!",
    "_legal_basis":"Art. 48-66 ustawy o podatku akcyzowym",
    "_warnings":[sprintf("SKŁAD PODATKOWY — %s. Procedura zawieszona: %s. Warunki: (1) Zezwolenie naczelnika US, (2) Zabezpieczenie akcyzowe (gwarancja bankowa %s PLN), (3) EMCS — system elektroniczny, (4) Miesięczne AKC-4.",[wh_type,susp_note,guarantee])]
} {
    input.jdg_entrepreneur.has_excise_warehouse==true
    wh_type:=object.get(input.jdg_entrepreneur,"warehouse_type","TAX_WAREHOUSE")
    suspension_active:=object.get(input.jdg_entrepreneur,"excise_suspension_active",true)
    susp_note="AKTYWNA — akcyza odroczona do wyprowadzenia"{suspension_active}
    susp_note="NIEAKTYWNA — akcyza płatna od razu"{not suspension_active}
    guarantee:=50000
}

# ── L846: excise_registration_akcr — Obowiązek rejestracji AKC-R ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.akcr_registration",
    "valid_from":"2009-03-01","valid_to":null,
    "package":"jdg.local_taxes.pcc_enterprise","priority":846,
    "excise_registration_required":true,"excise_registration_form":"AKC-R",
    "excise_akcr_filed":akcr_ok,
    "_routing":akcr_rt,"_routing_reason":sprintf("AKC-R: %s",[akcr_stat]),
    "_legal_basis":"Art. 16-17 ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKC-R — %s. Obowiązek rejestracji PRZED pierwszą czynnością podlegającą akcyzie! Brak rejestracji = nielegalna produkcja/obrót = sankcja KKS + konfiskata towaru.",[akcr_stat])]
} {
    input.jdg_entrepreneur.is_excise_taxpayer==true
    akcr_ok:=object.get(input.jdg_entrepreneur,"akcr_filed",false)
    akcr_stat="ZAREJESTROWANY"{akcr_ok}
    akcr_stat="BRAK REJESTRACJI — ZŁÓŻ NATYCHMIAST!"{not akcr_ok}
    akcr_rt="BLOCK_AND_ALERT"{not akcr_ok};akcr_rt=""{akcr_ok}
}

# ── L847: excise_akc4_declaration — Deklaracja AKC-4 miesięczna ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.akc4_declaration",
    "package":"jdg.local_taxes.pcc_enterprise","priority":847,
    "excise_declaration_form":"AKC-4","excise_declaration_deadline":"25th of month",
    "excise_akc4_filed":akc4_ok,
    "_routing":akc4_rt,"_routing_reason":sprintf("AKC-4: %s",[akc4_stat]),
    "_legal_basis":"Art. 21-24 ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKC-4 — %s. Deklaracja miesięczna do 25. dnia następnego miesiąca. Obejmuje: ilość wyrobów, stawki, kwotę akcyzy, e-DD.",[akc4_stat])]
} {
    input.jdg_entrepreneur.is_excise_taxpayer==true
    akc4_ok:=object.get(input.jdg_entrepreneur,"akc4_filed_current_month",true)
    akc4_stat="ZŁOŻONA";akc4_rt=""{akc4_ok}
    akc4_stat="NIEZŁOŻONA — termin do 25."{not akc4_ok}
    akc4_rt="BLOCK_AND_ALERT"{not akc4_ok}
}

# ── L848: excise_exemption_small_producer — Zwolnienie dla małego producenta ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.small_producer_exemption",
    "package":"jdg.local_taxes.pcc_enterprise","priority":848,
    "excise_exempt":true,"excise_exemption_type":"SMALL_PRODUCER",
    "_routing":"","_routing_reason":"Mały producent — zwolniony z akcyzy wg limitów",
    "_legal_basis":"Art. 30 ust. 2 pkt 4, Art. 31b ustawy o podatku akcyzowym",
    "_warnings":[sprintf("AKCYZA — MAŁY PRODUCENT. %s. Limit: %.0f %s rocznie. Zwolnienie wymaga ewidencji uproszczonej (nie pełny skład podatkowy).",[product,annual_limit,unit])]
} {
    input.jdg_entrepreneur.is_excise_small_producer==true
    product:=object.get(input.jdg_entrepreneur,"excise_product_small","BEER")
    annual_limit=2000{product=="BEER"};unit="hl"{product=="BEER"}
    annual_limit=500{product=="WINE"};unit="hl"{product=="WINE"}
    annual_limit=100{product=="SPIRITS"};unit="l 100%%"{product=="SPIRITS"}
}

# ── L849: excise_sanction_illegal — Sankcja za nielegalny wyrób akcyzowy ──
else := {
    "matched":true,"rule_id":"jdg.local_taxes.excise.sanction_illegal",
    "package":"jdg.local_taxes.pcc_enterprise","priority":849,
    "excise_sanction_risk":"CRITICAL",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"RYZYKO NIELEGALNEJ AKCYZY — sankcja KKS + konfiskata!",
    "_legal_basis":"Art. 63-73 KKS; Art. 30-31 ustawy o podatku akcyzowym",
    "_warnings":["NIELEGALNY WYRÓB AKCYZOWY — (1) Kara KKS: grzywna do 720 stawek dziennych + kara pozbawienia wolności do 3 lat, (2) Przepadek wyrobów + urządzeń, (3) Szacunkowe określenie akcyzy (10-krotność stawki!), (4) Odpowiedzialność solidarna całego łańcucha dostaw."]
} {
    input.jdg_entrepreneur.excise_risk_illegal==true
}

# ── L840: excise_duty_alcohol_tobacco — Akcyza od alkoholu i tytoniu ──
else := {
    "matched": true, "rule_id": "jdg.local_taxes.excise.alcohol_tobacco",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 840,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "GTU_01",
    "procedure": "EXCISE",
    "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "excise_applies": true,
    "excise_product_type": excise_type,
    "excise_registration_required": true,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AKCYZA — %s. Wymagana rejestracja w systemie EMCS/PCC!", [excise_type]),
    "_legal_basis": "Ustawa o podatku akcyzowym (Dz.U. 2025 poz. 678)",
    "_warnings": [sprintf("AKCYZA — %s. Obowiązki: (1) Rejestracja AKC-R przed pierwszą czynnością, (2) Zabezpieczenie akcyzowe (dla składów podatkowych), (3) Deklaracja AKC-4 miesięcznie do 25. dnia, (4) e-DD — dokument dostawy przy przemieszczaniu.", [excise_type])]
} {
    input.invoice.category_code in {"ALCOHOL", "TOBACCO", "FUEL", "ENERGY_ELECTRIC"}
    input.invoice.direction in {"SALE", "PURCHASE"}
    input.jdg_entrepreneur.is_excise_taxpayer == true
    excise_type = "ALKOHOL" { input.invoice.category_code == "ALCOHOL" }
    excise_type = "TYTOŃ" { input.invoice.category_code == "TOBACCO" }
    excise_type = "PALIWA" { input.invoice.category_code == "FUEL" }
    excise_type = "ENERGIA ELEKTRYCZNA" { input.invoice.category_code == "ENERGY_ELECTRIC" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.local_taxes.pcc.fallback",
    "package": "jdg.local_taxes.pcc_enterprise", "priority": 899,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PCC / Ustawa o podatkach lokalnych",
    "_warnings": ["Transakcja nie podlega PCC ani podatkom lokalnym — OK"]
} {
    true
}
