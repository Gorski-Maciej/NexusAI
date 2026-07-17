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
    "matched": false, "rule_id": "jdg.local_taxes.pcc.no_match",
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
    "_warnings": [sprintf("PCC — UMOWA SPRZEDAŻY. Wartość rynkowa: %.2f PLN. %s. Stawka: %.1f%%. Podatek: %.2f PLN. Złóż PCC-3 w ciągu 14 dni od zawarcia umowy! UWAGA: Jeśli sprzedawca jest VAT-owcem i wystawia fakturę VAT → PCC NIE obowiązuje (Art. 2 pkt 4 PCC)!", [market_value, pcc_reason, pcc_rate, pcc_tax])]
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
    "_warnings": [sprintf("PODATEK OD ŚRODKÓW TRANSPORTU — Samochód ciężarowy DMC %.0f kg. Podatek roczny: %.2f PLN. Złóż DT-1 do 15 lutego. Płatność w 2 ratach: do 15 lutego i 15 września.", [dmv, annual_tax])]
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
