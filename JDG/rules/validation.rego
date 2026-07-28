# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Validation: NIP, REGON, Invoice Continuity (R0613-R0622)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Validation Package — Document & Identifier Validation
# description: |
#   First-Match-Wins else-chain walidacji dokumentów i identyfikatorów.
#   Reguły R0613-R0622 z Doc 28a — NIP/REGON checksum, ciągłość numeracji,
#   spójność dat i kwot, KSeF UPO.
# legal_basis: Art. 96 VAT (NIP), Art. 106e-106nq VAT (faktury), KSeF
# edge_cases:
#   - NIP checksum: algorytm modulo 11 z wagami [6,5,7,2,3,4,5,6,7]
#   - REGON 9-cyfrowy: wagi [8,9,2,3,4,5,6,7], modulo 11
#   - REGON 14-cyfrowy: wagi [2,4,8,5,0,9,7,3,6,1,2,4,8], modulo 11
# package: jdg.validation
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.validation

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.validation.no_match",
    "package": "jdg.validation", "priority": 999
}

# v7.0 ADR-002 FIX: Wagi NIP/REGON pobierane z data.jdg.thresholds.checksum_weights
# zamiast hardcoded wartości w kodzie. Aktualizacja wag = zmiana thresholds_jdg.rego.

# ══════ R0613: nip_checksum_validation — Suma kontrolna NIP (modulo 11) ══════
decide := {
    "matched": true, "rule_id": "jdg.validation.nip_checksum",
    "package": "jdg.validation", "priority": 613,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "NIP_CHECKSUM", "validation_passed": checksum_ok,
    "nip_digits": digits, "nip_checksum_calculated": checksum,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "NIP checksum invalid — błędny identyfikator podatkowy",
    "_legal_basis": "Art. 96 VAT (identyfikator podatkowy)",
    "_warnings": ["NIEOCZYWISTY NIP — suma kontrolna się nie zgadza. Sprawdź poprawność numeru! Błędny NIP = brak odliczenia VAT + NKUP"]
} {
    vendor_nip := object.get(input.vendor, "nip", "")
    count(vendor_nip) == 10

    # Ekstrakcja cyfr przez substring (Rego nie wspiera array comprehension z licznikiem)
    d0 := to_number(substring(vendor_nip, 0, 1))
    d1 := to_number(substring(vendor_nip, 1, 1))
    d2 := to_number(substring(vendor_nip, 2, 1))
    d3 := to_number(substring(vendor_nip, 3, 1))
    d4 := to_number(substring(vendor_nip, 4, 1))
    d5 := to_number(substring(vendor_nip, 5, 1))
    d6 := to_number(substring(vendor_nip, 6, 1))
    d7 := to_number(substring(vendor_nip, 7, 1))
    d8 := to_number(substring(vendor_nip, 8, 1))
    d9 := to_number(substring(vendor_nip, 9, 1))

    # Wagi NIP z thresholds (ADR-002: Zero Hardcoded)
    nip_weights := object.get(data.jdg.thresholds.checksum_weights, "nip", [6,5,7,2,3,4,5,6,7])
    weighted_sum := d0*nip_weights[0] + d1*nip_weights[1] + d2*nip_weights[2] + d3*nip_weights[3] + d4*nip_weights[4] + d5*nip_weights[5] + d6*nip_weights[6] + d7*nip_weights[7] + d8*nip_weights[8]
    checksum := weighted_sum % 11
    checksum_ok := checksum == d9
    checksum_ok == false
}

# ══════ R0614: regon_checksum_validation — Suma kontrolna REGON ══════
else := {
    "matched": true, "rule_id": "jdg.validation.regon_checksum",
    "package": "jdg.validation", "priority": 614,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "REGON_CHECKSUM", "validation_passed": checksum_ok,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "REGON checksum invalid",
    "_legal_basis": "Ustawa o statystyce publicznej (REGON)",
    "_warnings": [sprintf("REGON %d-cyfrowy — suma kontrolna nieprawidłowa. Sprawdź numer w CEIDG", [regon_len])]
} {
    regon := object.get(input.vendor, "regon", "")
    regon_len := count(regon)
    regon_len in {9, 14}

    # Ekstrakcja cyfr przez substring
    rd0 := to_number(substring(regon, 0, 1))
    rd1 := to_number(substring(regon, 1, 1))
    rd2 := to_number(substring(regon, 2, 1))
    rd3 := to_number(substring(regon, 3, 1))
    rd4 := to_number(substring(regon, 4, 1))
    rd5 := to_number(substring(regon, 5, 1))
    rd6 := to_number(substring(regon, 6, 1))
    rd7 := to_number(substring(regon, 7, 1))
    rd8 := to_number(substring(regon, 8, 1))

    # REGON 9-cyfrowy: wagi z thresholds (ADR-002)
    regon9_w := object.get(data.jdg.thresholds.checksum_weights, "regon9", [8,9,2,3,4,5,6,7])
    checksum_9 := (rd0*regon9_w[0] + rd1*regon9_w[1] + rd2*regon9_w[2] + rd3*regon9_w[3] + rd4*regon9_w[4] + rd5*regon9_w[5] + rd6*regon9_w[6] + rd7*regon9_w[7]) % 11
    checksum_ok_9 := checksum_9 == rd8

    # REGON 14-cyfrowy: wagi z thresholds (ADR-002)
    rd9 := to_number(substring(regon, 9, 1))
    rd10 := to_number(substring(regon, 10, 1))
    rd11 := to_number(substring(regon, 11, 1))
    rd12 := to_number(substring(regon, 12, 1))
    rd13 := to_number(substring(regon, 13, 1))

    regon14_w := object.get(data.jdg.thresholds.checksum_weights, "regon14", [2,4,8,5,0,9,7,3,6,1,2,4,8])
    checksum_14 := (rd0*regon14_w[0] + rd1*regon14_w[1] + rd2*regon14_w[2] + rd3*regon14_w[3] +
                    rd4*regon14_w[4] + rd5*regon14_w[5] + rd6*regon14_w[6] + rd7*regon14_w[7] +
                    rd8*regon14_w[8] + rd9*regon14_w[9] + rd10*regon14_w[10] + rd11*regon14_w[11] + rd12*regon14_w[12]) % 11
    checksum_ok_14 := checksum_14 == rd13

    checksum_ok = checksum_ok_9 { regon_len == 9 }
    checksum_ok = checksum_ok_14 { regon_len == 14 }
    checksum_ok == false
}

# ══════ R0615: invoice_number_continuity — Ciągłość numeracji faktur ══════
else := {
    "matched": true, "rule_id": "jdg.validation.invoice_number_continuity",
    "package": "jdg.validation", "priority": 615,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "INVOICE_NUMBER_GAP", "validation_passed": false,
    "invoice_number_gap": gap_detected, "gap_count": gap_count,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Luka w numeracji faktur — możliwe ukrycie przychodu",
    "_legal_basis": "Art. 106e VAT (faktura ustrukturyzowana)",
    "_warnings": [sprintf("LUKA W NUMERACJI FAKTUR — %d brakujących numerów między %s a %s. Sprawdź czy nie ukryto sprzedaży!", [gap_count, prev_num, current_num])]
} {
    prev_num := object.get(input.jdg_entrepreneur, "last_invoice_number", "")
    current_num := object.get(input.invoice, "invoice_number", "")
    prev_num != ""
    current_num != ""

    prev_int := to_number(prev_num)
    curr_int := to_number(current_num)
    gap_detected := curr_int - prev_int > 1
    gap_count := curr_int - prev_int - 1
    gap_detected == true
}

# ══════ R0616: invoice_date_future_check — Data faktury ≤ data bieżąca ══════
else := {
    "matched": true, "rule_id": "jdg.validation.invoice_date_future",
    "package": "jdg.validation", "priority": 616,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "FUTURE_INVOICE_DATE", "validation_passed": false,
    "invoice_date": inv_date, "days_in_future": days_ahead,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Data faktury w przyszłości — niemożliwa data",
    "_legal_basis": "Art. 106e ust. 1 pkt 1 VAT",
    "_warnings": [sprintf("DATA FAKTURY W PRZYSZŁOŚCI — %s to %d dni od dziś. Faktura nie może mieć daty późniejszej niż data wystawienia!", [inv_date, days_ahead])]
} {
    inv_date := object.get(input.invoice, "issue_date", "")
    inv_date != ""
    inv_ns := time.parse_ns("2006-01-02", inv_date)
    now_ns := time.now_ns()
    inv_ns > now_ns
    days_ahead := floor((inv_ns - now_ns) / (24 * 60 * 60 * 1000000000))
}

# ══════ R0617: sale_delivery_date_range — Data sprzedaży ≤ data faktury + 30 ══════
else := {
    "matched": true, "rule_id": "jdg.validation.sale_delivery_date_range",
    "package": "jdg.validation", "priority": 617,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "DELIVERY_DATE_RANGE", "validation_passed": false,
    "days_sale_to_invoice": days_diff,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Data sprzedaży zbyt odległa od daty faktury (>30 dni)",
    "_legal_basis": "Art. 106i ust. 1 VAT (termin wystawienia faktury)",
    "_warnings": [sprintf("DATA SPRZEDAŻY ODSTAJE — %d dni między datą sprzedaży (%s) a datą faktury (%s). Max dozwolone 30 dni (Art. 106i VAT)", [days_diff, sale_date, inv_date])]
} {
    sale_date := object.get(input.invoice, "sale_date", "")
    inv_date := object.get(input.invoice, "issue_date", "")
    sale_date != ""
    inv_date != ""

    sale_ns := time.parse_ns("2006-01-02", sale_date)
    inv_ns := time.parse_ns("2006-01-02", inv_date)
    days_diff := floor((inv_ns - sale_ns) / (24 * 60 * 60 * 1000000000))
    days_diff > 30
}

# ══════ R0618: invoice_amount_consistency — Kwota netto + VAT = brutto ══════
else := {
    "matched": true, "rule_id": "jdg.validation.invoice_amount_consistency",
    "package": "jdg.validation", "priority": 618,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "AMOUNT_CONSISTENCY", "validation_passed": false,
    "expected_gross": floor(expected_gross * 100) / 100, "actual_gross": amount_gross,
    "difference": floor(abs(amount_gross - expected_gross) * 100) / 100,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niezgodność kwot netto+VAT vs brutto — błąd na fakturze",
    "_legal_basis": "Art. 106e ust. 1 pkt 11-14 VAT",
    "_warnings": [sprintf("NIEZGODNOŚĆ KWOT — netto %.2f + VAT %.2f = %.2f, ale brutto = %.2f. Różnica: %.2f PLN. Faktura jest wadliwa!", [amount_net, vat_amount, expected_gross, amount_gross, abs(amount_gross - expected_gross)])]
} {
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_net > 0
    amount_gross > 0

    # VAT amount — preferowane pole vat_amount; jeśli brak, oblicz z netto * rate
    vat_rate_str := object.get(input.invoice, "vat_rate", "0.23")
    vat_amount := object.get(input.invoice, "vat_amount", 0)
    vat_amount > 0

    expected_gross := amount_net + vat_amount
    expected_gross != amount_gross
    abs(amount_gross - expected_gross) > 0.01
}

# ══════ R0619: nip_seller_buyer_distinct — NIP sprzedawcy ≠ NIP nabywcy ══════
else := {
    "matched": true, "rule_id": "jdg.validation.nip_seller_buyer_distinct",
    "package": "jdg.validation", "priority": 619,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "SELF_INVOICING", "validation_passed": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "NIP sprzedawcy = NIP nabywcy — samofakturowanie bez podstawy",
    "_legal_basis": "Art. 106e VAT (elementy faktury)",
    "_warnings": ["NIP SPRZEDAWCY = NIP NABYWCY — faktura wystawiona samemu sobie! Niedozwolone poza szczególnymi przypadkami (samofakturowanie tylko za zgodą nabywcy)"]
} {
    buyer_nip := object.get(input.invoice, "buyer_nip", "")
    vendor_nip := object.get(input.vendor, "nip", "")
    buyer_nip != ""
    vendor_nip != ""
    buyer_nip == vendor_nip
}

# ══════ R0620: ksef_upo_required — KSeF UPO wymagane dla e-faktury ══════
else := {
    "matched": true, "rule_id": "jdg.validation.ksef_upo_required",
    "package": "jdg.validation", "priority": 620,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "validation_type": "KSEF_UPO_MISSING", "validation_passed": false,
    "ksef_upo_required_since": "2026-02-01",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak UPO KSeF dla faktury elektronicznej B2B",
    "_legal_basis": "Art. 106na VAT (obowiązkowy KSeF od 1.02.2026)",
    "_warnings": ["BRAK UPO KSeF — faktura B2B po 1.02.2026 wymaga Urzędowego Poświadczenia Odbioru! Bez UPO faktura jest nieważna dla odliczenia VAT"]
} {
    input.invoice.ksef_faktura == true
    input.invoice.direction == "SALE"
    inv_date := object.get(input.invoice, "issue_date", "")
    inv_date >= "2026-02-01"
    input.invoice.ksef_upo_received == false
    input.vendor.is_company == true
}
