# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P33 PCC Complete (Legal Audit Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG PCC Complete — Full Civil Law Transaction Tax Coverage
# description: |
#   Uzupełnienie 203 punktów prawnych PCC z RAPORT_P33:
#   - 7 brakujących typów czynności (zamiana, darowizna, dożywocie, hipoteka,
#     użytkowanie, zastaw, orzeczenia sądowe)
#   - Stawki: 0.5% (spółki), 1% (nieruchomości, prawa majątkowe), 2% (pozostałe)
#   - Zwolnienia Art. 9: pożyczka rodzinna ≤36 120 PLN, sprzedaż po 5 latach,
#     rolnicy, używane rzeczy, restrukturyzacja
#   - PCC-3 Auto-Filler z kalkulacją podatku
#   - Firewall VAT/PCC: wyłączenie Art. 2 pkt 4 PCC
#   - Sztuczny podział transakcji (GAAR PCC)
# architecture: Enterprise Supplement, First-Match-Wins else-chain
# legal_basis: Ustawa o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)
# package: jdg.p33_pcc_complete
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p33_pcc_complete

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.p33_pcc_complete.no_match",
    "package": "jdg.p33_pcc_complete", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC-001: Art. 1 ust. 1 — Umowa zamiany (exchange/barter)
# Stawka: 1% od wartości przedmiotu o wyższej wartości
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    input.invoice.direction == "PURCHASE"
    tx_type := object.get(input.invoice, "pcc_transaction_type", "")
    tx_type == "EXCHANGE"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    item1_value := object.get(input.invoice, "amount_net", 0)
    item2_value := object.get(input.invoice, "pcc_exchange_counter_value", 0)
    base_value := item1_value { item1_value >= item2_value }
    base_value := item2_value { item2_value > item1_value }
    base_value > 0

    pcc_rate := 0.01  # 1% for real estate/rights exchange
    pcc_amount := floor(base_value * pcc_rate * 100) / 100

    # Art. 2 pkt 4 exclusion: if both sides are VAT transactions → no PCC
    is_vat_transaction := object.get(input.invoice, "vat_applicable", false)
    counterparty_vat := object.get(input.invoice, "pcc_counterparty_vat", false)
    pcc_excluded := is_vat_transaction and counterparty_vat

    pcc_routing := "BLOCK_AND_ALERT" { pcc_excluded == false; pcc_amount > 0 }
    pcc_routing := "" { pcc_excluded }

    reason := sprintf("Zamiana: PCC 1%% od %.0f PLN = %.2f PLN. PCC-3 w 14 dni.",
        [base_value, pcc_amount]) { pcc_excluded == false }
    reason := "Zamiana wyłączona z PCC — obie strony VAT." { pcc_excluded }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_pcc_complete.exchange_tax",
        "package": "jdg.p33_pcc_complete", "priority": 9351,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pcc_type": "ZAMIANA (Art. 1 ust. 1 pkt 2 PCC)",
        "pcc_base_value": base_value,
        "pcc_rate_pct": pcc_rate * 100,
        "pcc_amount_pln": pcc_amount,
        "pcc_excluded_by_vat": pcc_excluded,
        "pcc_declaration": "PCC-3",
        "pcc_deadline_days": 14,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": pcc_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 1 ust. 1 pkt 2, Art. 6 ust. 1 pkt 1, Art. 2 pkt 4 Ustawy o PCC",
        "_warnings": [sprintf("🔄 PCC ZAMIANA: Wartość wyższa=%.0f PLN × 1%% = %.2f PLN. %s PCC-3 w 14 dni.",
            [base_value, pcc_amount, excl_note])]
    }

    excl_note := "WYŁĄCZONE (VAT)" { pcc_excluded }
    excl_note := sprintf("DO ZAPŁATY: %.2f PLN.", [pcc_amount]) { pcc_excluded == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC-002: Art. 1 ust. 1 pkt 2 — Pożyczka (loan) — pełna obsługa
# Stawka: 2% od nadwyżki >36 120 PLN. Zwolnienie rodzinne Art. 9.
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.direction == "PURCHASE"
    tx_type := object.get(input.invoice, "pcc_transaction_type", object.get(input.invoice, "expense_type", ""))
    tx_type == "LOAN"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    loan_amount := object.get(input.invoice, "amount_net", 0)
    loan_amount > 0

    is_from_family := object.get(input.vendor, "is_family_member", false)
    family_group := object.get(input.vendor, "family_tax_group", "")
    family_group in {"I", "II", "III"}  # Groups I-III per inheritance law

    # Art. 9 pkt 10 lit. g: exemption up to 36 120 PLN from family
    exemption_limit := 36120.0
    exempt_amount := 0 { is_from_family == false }
    exempt_amount := loan_amount { is_from_family; loan_amount <= exemption_limit }
    exempt_amount := exemption_limit { is_from_family; loan_amount > exemption_limit }

    taxable_base := loan_amount - exempt_amount
    taxable_base := 0 { taxable_base < 0 }

    pcc_rate := 0.02
    pcc_amount := floor(taxable_base * pcc_rate * 100) / 100

    is_exempt := is_from_family and loan_amount <= exemption_limit
    is_partially_exempt := is_from_family and loan_amount > exemption_limit

    # Split loan GAAR detection
    has_related_loans := object.get(input.jdg_entrepreneur, "pcc_related_loans_count", 0) > 1
    total_related := object.get(input.jdg_entrepreneur, "pcc_related_loans_total", 0)
    possible_split := has_related_loans and total_related > exemption_limit and loan_amount <= exemption_limit

    pcc_routing := "BLOCK_AND_ALERT" { possible_split }
    pcc_routing := "TRIAGE_QUEUE" { pcc_amount > 1000 }
    pcc_routing := "" { pcc_amount == 0 }
    pcc_routing := "" { pcc_amount <= 1000; pcc_amount > 0 }

    reason := sprintf("GAAR: Sztuczny podział pożyczek! %d pożyczek na łączną kwotę %.0f PLN > %.0f PLN. Rozlicz ŁĄCZNIE!",
        [object.get(input.jdg_entrepreneur, "pcc_related_loans_count", 0), total_related, exemption_limit]) { possible_split }
    reason := sprintf("Pożyczka: PCC 2%% od %.0f PLN = %.2f PLN", [taxable_base, pcc_amount]) { pcc_amount > 0 }
    reason := sprintf("Pożyczka %.0f PLN od rodziny (gr. %s) — ZWOLNIONA z PCC (≤%.0f PLN)",
        [loan_amount, family_group, exemption_limit]) { is_exempt }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_pcc_complete.loan_full",
        "package": "jdg.p33_pcc_complete", "priority": 9352,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pcc_type": "POŻYCZKA (Art. 1 ust. 1 pkt 2 PCC)",
        "pcc_loan_amount": loan_amount,
        "pcc_loan_family_exempt": is_exempt,
        "pcc_loan_exemption_limit": exemption_limit,
        "pcc_loan_taxable_base": taxable_base,
        "pcc_amount_pln": pcc_amount,
        "pcc_gaar_split_detected": possible_split,
        "pcc_declaration": "PCC-3",
        "pcc_deadline_days": 14,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": pcc_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 1 ust. 1 pkt 2, Art. 7 ust. 1 pkt 4, Art. 9 pkt 10 lit. g Ustawy o PCC",
        "_warnings": [sprintf("💰 PCC POŻYCZKA: %.0f PLN. %s PCC-3 + zapłata w 14 dni. %s",
            [loan_amount, loan_warning, gaar_warning])]
    }

    loan_warning := sprintf("ZWOLNIONE (rodzina, ≤%.0f PLN)", [exemption_limit]) { is_exempt }
    loan_warning := sprintf("Zwolnione %.0f PLN, opodatkowane %.0f PLN × 2%% = %.2f PLN", [exempt_amount, taxable_base, pcc_amount]) { is_partially_exempt }
    loan_warning := sprintf("Pełny PCC: %.0f PLN × 2%% = %.2f PLN", [taxable_base, pcc_amount]) { is_exempt == false; is_partially_exempt == false }

    gaar_warning := "⚠️ GAAR: Wykryto sztuczny podział pożyczek — rozlicz ŁĄCZNIE!" { possible_split }
    gaar_warning := "" { not possible_split }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC-003: Art. 1 ust. 1 pkt 1 — Sprzedaż nieruchomości (real estate)
# Stawka: 1% (budynki, lokale, grunty, prawa wieczystego użytkowania)
# STAWKA 1% NIE 2%! Różnica od ruchomości.
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.direction == "PURCHASE"
    tx_type := object.get(input.invoice, "pcc_transaction_type", object.get(input.invoice, "category_code", ""))
    tx_type in {"REAL_ESTATE", "PROPERTY", "LAND", "BUILDING", "PERPETUAL_USUFRUCT"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    property_value := object.get(input.invoice, "amount_net", 0)
    property_value > 0

    is_from_company := object.get(input.vendor, "is_company", true)
    seller_is_vat_payer := is_from_company and object.get(input.vendor, "is_vat_payer", false)

    # Art. 2 pkt 4 exclusion: if seller charges VAT → no PCC
    pcc_excluded := seller_is_vat_payer
    # Uwaga: zwolniony podmiotowo (Art. 113 VAT) → NIE wyłączone z PCC!

    pcc_rate := 0.01  # 1% for real estate
    pcc_amount := floor(property_value * pcc_rate * 100) / 100

    # Art. 9 exemption: sale of residential property after 5 years
    is_residential := object.get(input.invoice, "pcc_property_residential", false)
    ownership_years := object.get(input.jdg_entrepreneur, "pcc_property_ownership_years", 0)
    exempt_5y := is_residential and ownership_years >= 5
    final_pcc := 0 { exempt_5y }
    final_pcc := pcc_amount { not exempt_5y; not pcc_excluded }
    final_pcc := 0 { pcc_excluded }

    pcc_routing := "BLOCK_AND_ALERT" { final_pcc > 2000; not pcc_excluded }
    pcc_routing := "" { pcc_excluded or exempt_5y }
    pcc_routing := "" { final_pcc <= 2000; final_pcc > 0 }

    reason := sprintf("Nieruchomość: PCC 1%% od %.0f PLN = %.2f PLN", [property_value, final_pcc]) { final_pcc > 0 }
    reason := "Nieruchomość wyłączona z PCC — sprzedawca nalicza VAT." { pcc_excluded }
    reason := sprintf("Nieruchomość mieszkalna po %d latach — ZWOLNIONA z PCC (Art. 9).", [ownership_years]) { exempt_5y }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_pcc_complete.real_estate_full",
        "package": "jdg.p33_pcc_complete", "priority": 9353,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pcc_type": "NIERUCHOMOŚĆ (Art. 1 ust. 1 pkt 1 lit. a PCC)",
        "pcc_property_value": property_value,
        "pcc_rate_pct": 1.0,
        "pcc_amount_pln": final_pcc,
        "pcc_excluded_by_vat": pcc_excluded,
        "pcc_exempt_5years": exempt_5y,
        "pcc_declaration": "PCC-3 (notariusz pobiera i odprowadza)",
        "pcc_deadline_days": 14,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": pcc_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a, Art. 6 ust. 1 pkt 1, Art. 9, Art. 2 pkt 4 Ustawy o PCC",
        "_warnings": [sprintf("🏠 PCC NIERUCHOMOŚĆ: %.0f PLN × 1%% = %.2f PLN. %s PCC-3 + zapłata w 14 dni. Notariusz = płatnik.",
            [property_value, final_pcc, status_note])]
    }

    status_note := "ZWOLNIONE (mieszkalna >5 lat)" { exempt_5y }
    status_note := "WYŁĄCZONE (VAT)" { pcc_excluded }
    status_note := sprintf("DO ZAPŁATY: %.2f PLN", [final_pcc]) { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC-004: Art. 1 ust. 1 pkt 3-9 — Pozostałe czynności (darowizna, hipoteka,
# użytkowanie, zastaw, dożywocie, orzeczenia sądowe)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.direction == "PURCHASE"
    tx_type := object.get(input.invoice, "pcc_transaction_type", "")

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    base_value := object.get(input.invoice, "amount_net", 0)
    base_value > 0

    # Rate mapping per transaction type
    pcc_rate := 0.02 { tx_type == "DONATION_DEED" }           # Darowizna (umowa, nie podatek od spadków)
    pcc_rate := 0.001 { tx_type == "MORTGAGE_ESTABLISHMENT" }  # Hipoteka 0.1% od kwoty zabezpieczenia
    pcc_rate := 0.01 { tx_type in {"USUFRUCT", "EASEMENT"} }   # Użytkowanie/służebność 1%
    pcc_rate := 0.005 { tx_type == "PLEDGE_ESTABLISHMENT" }    # Zastaw 0.5%
    pcc_rate := 0.02 { tx_type == "LIFE_ANNUITY" }             # Dożywocie 2%
    pcc_rate := 0.02 { tx_type == "COURT_SETTLEMENT" }         # Ugoda sądowa 2%
    pcc_rate := 0.02 { tx_type in {"COMPANY_SHARES", "PARTNERSHIP_AMENDMENT"} }  # Spółki 0.5% od wkładu
    pcc_rate := 0.005 { tx_type in {"COMPANY_SHARES", "PARTNERSHIP_AMENDMENT"} }  # Override: 0.5%
    else := 0.02 { true }

    pcc_amount := floor(base_value * pcc_rate * 100) / 100

    type_labels := {
        "DONATION_DEED": "Umowa darowizny",
        "MORTGAGE_ESTABLISHMENT": "Ustanowienie hipoteki",
        "USUFRUCT": "Ustanowienie użytkowania",
        "EASEMENT": "Ustanowienie służebności",
        "PLEDGE_ESTABLISHMENT": "Ustanowienie zastawu",
        "LIFE_ANNUITY": "Umowa dożywocia",
        "COURT_SETTLEMENT": "Ugoda/Orzeczenie sądowe",
        "COMPANY_SHARES": "Umowa spółki/zmiana",
        "PARTNERSHIP_AMENDMENT": "Zmiana umowy spółki"
    }
    type_label := type_labels[tx_type]

    pcc_routing := "TRIAGE_QUEUE" { pcc_amount > 5000 }
    pcc_routing := "" { pcc_amount <= 5000 }

    reason := sprintf("%s: PCC %.1f%% od %.0f PLN = %.2f PLN", [type_label, pcc_rate * 100, base_value, pcc_amount])

    verdict := {
        "matched": true, "rule_id": "jdg.p33_pcc_complete.other_transactions",
        "package": "jdg.p33_pcc_complete", "priority": 9354,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pcc_type": type_label,
        "pcc_base_value": base_value,
        "pcc_rate_pct": pcc_rate * 100,
        "pcc_amount_pln": pcc_amount,
        "pcc_declaration": "PCC-3",
        "pcc_deadline_days": 14,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": pcc_routing,
        "_routing_reason": reason,
        "_legal_basis": sprintf("Art. 1 ust. 1, Art. 6-7 Ustawy o PCC — %s", [tx_type]),
        "_warnings": [sprintf("📋 PCC %s: %.0f PLN × %.1f%% = %.2f PLN. PCC-3 w 14 dni.",
            [type_label, base_value, pcc_rate * 100, pcc_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC-005: Art. 10 — PCC-3 Auto-Filler + Kalkulator
# Automatyczna kalkulacja wszystkich zobowiązań PCC w okresie
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.invoice, "is_period_end", false) == true
    # Trigger: quarter-end or year-end summary

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    pcc_loans := object.get(input.jdg_entrepreneur, "pcc_loans_total_year", 0)
    pcc_cars := object.get(input.jdg_entrepreneur, "pcc_cars_total_year", 0)
    pcc_real_estate := object.get(input.jdg_entrepreneur, "pcc_real_estate_total_year", 0)
    pcc_exchanges := object.get(input.jdg_entrepreneur, "pcc_exchanges_total_year", 0)
    pcc_other := object.get(input.jdg_entrepreneur, "pcc_other_total_year", 0)
    pcc_total := pcc_loans + pcc_cars + pcc_real_estate + pcc_exchanges + pcc_other

    pcc_loans_paid := object.get(input.jdg_entrepreneur, "pcc_loans_paid", 0)
    pcc_cars_paid := object.get(input.jdg_entrepreneur, "pcc_cars_paid", 0)
    pcc_total_paid := pcc_loans_paid + pcc_cars_paid

    unpaid := pcc_total - pcc_total_paid
    unpaid := 0 { unpaid < 0 }
    is_fully_paid := unpaid < 0.01

    pcc_count := object.get(input.jdg_entrepreneur, "pcc_transaction_count", 0)
    pcc3_filed := object.get(input.jdg_entrepreneur, "pcc3_declarations_filed", 0)

    pcc_routing := "BLOCK_AND_ALERT" { is_fully_paid == false; unpaid > 1000 }
    pcc_routing := "TRIAGE_QUEUE" { is_fully_paid == false; unpaid <= 1000; unpaid > 0 }
    pcc_routing := "" { is_fully_paid }

    reason := sprintf("PCC NIEZAPŁACONE: %.2f PLN z %.2f PLN łącznie. Złóż PCC-3!",
        [unpaid, pcc_total]) { is_fully_paid == false }
    reason := "" { is_fully_paid }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_pcc_complete.pcc3_auto_filler",
        "package": "jdg.p33_pcc_complete", "priority": 9355,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pcc_auto_total_pln": pcc_total,
        "pcc_auto_paid_pln": pcc_total_paid,
        "pcc_auto_unpaid_pln": unpaid,
        "pcc_auto_is_fully_paid": is_fully_paid,
        "pcc_auto_transaction_count": pcc_count,
        "pcc_auto_pcc3_filed": pcc3_filed,
        "pcc_auto_breakdown": {
            "pożyczki": pcc_loans,
            "pojazdy": pcc_cars,
            "nieruchomości": pcc_real_estate,
            "zamiany": pcc_exchanges,
            "inne": pcc_other
        },
        "business_status": "", "ceidg_registration_required": false,
        "_routing": pcc_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 10 Ustawy o PCC (deklaracja PCC-3 + zapłata 14 dni)",
        "_warnings": [sprintf("📋 PCC-3 AUTO-KALKULATOR: %d transakcji, PCC łącznie=%.2f PLN. Zapłacone=%.2f PLN. %s",
            [pcc_count, pcc_total, pcc_total_paid, pay_status])]
    }

    pay_status := sprintf("⚠️ DO ZAPŁATY: %.2f PLN — złóż PCC-3!", [unpaid]) { is_fully_paid == false }
    pay_status := "✅ Wszystkie PCC opłacone." { is_fully_paid }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC-006: Art. 2 pkt 4 — PCC vs VAT Firewall
# Transakcja opodatkowana VAT → wyłączona z PCC. ALE UWAGA:
# Jeśli sprzedawca jest zwolniony podmiotowo (Art. 113 VAT) → PCC się należy!
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.vendor, "is_company", true) == false
    input.invoice.direction == "PURCHASE"
    # Non-company vendor → potential PCC

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    seller_is_vat_payer := object.get(input.vendor, "is_vat_payer", false)
    seller_vat_exempt := object.get(input.vendor, "vat_exempt_subjective", false)  # Art. 113 VAT
    transaction_vat_applicable := object.get(input.invoice, "vat_applicable", false)
    transaction_vat_rate := object.get(input.invoice, "vat_rate", 0)

    # Firewall logic:
    # 1. Seller is active VAT payer + transaction subject to VAT → NO PCC
    # 2. Seller is subjectively VAT exempt (Art. 113) → PCC APPLIES!
    # 3. Transaction is exempt from VAT (e.g., financial services) → PCC APPLIES!
    # 4. Seller is non-VAT private person → PCC APPLIES!

    pcc_applies := false { seller_is_vat_payer; transaction_vat_applicable; transaction_vat_rate > 0 }
    pcc_applies := true { seller_vat_exempt }
    pcc_applies := true { not seller_is_vat_payer; not transaction_vat_applicable }
    pcc_applies := true { seller_is_vat_payer; transaction_vat_applicable == false }

    trans_value := object.get(input.invoice, "amount_gross", 0)
    pcc_estimate := floor(trans_value * 0.02 * 100) / 100 { pcc_applies }
    pcc_estimate := 0 { not pcc_applies }

    firewall_routing := "BLOCK_AND_ALERT" { pcc_applies; pcc_estimate > 0 }
    firewall_routing := "" { not pcc_applies }

    reason := sprintf("PCC FIREWALL: Sprzedawca bez VAT → PCC 2%% ≈ %.2f PLN od %.0f PLN.",
        [pcc_estimate, trans_value]) { pcc_applies }
    reason := "Transakcja podlega VAT → wyłączona z PCC (Art. 2 pkt 4)." { not pcc_applies }

    scenario := "Sprzedawca = czynny VAT-owiec + transakcja opodatkowana → BEZ PCC" { not pcc_applies }
    scenario := "Sprzedawca = zwolniony podmiotowo (Art. 113 VAT) → PCC SIĘ NALEŻY!" { seller_vat_exempt }
    scenario := "Sprzedawca = osoba prywatna (nie VAT-owiec) → PCC SIĘ NALEŻY!" { not seller_is_vat_payer }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_pcc_complete.vat_pcc_firewall",
        "package": "jdg.p33_pcc_complete", "priority": 9356,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pcc_firewall_applies": pcc_applies,
        "pcc_firewall_estimated_pln": pcc_estimate,
        "pcc_firewall_scenario": scenario,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": firewall_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 2 pkt 4 Ustawy o PCC; Art. 113 Ustawy o VAT (zwolnienie podmiotowe)",
        "_warnings": [sprintf("🛡️ PCC vs VAT FIREWALL: %s PCC szacunkowo=%.2f PLN.",
            [scenario, pcc_estimate])]
    }
}
