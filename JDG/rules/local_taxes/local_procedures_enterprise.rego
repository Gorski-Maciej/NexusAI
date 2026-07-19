# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Local Tax Procedures Enterprise (Class IX: Procedures)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Local Tax Procedures — Enforcement, Refunds, Cross-Tax Interactions
# description: |
#   ENTERPRISE v6.1 — Domknięcie proceduralnych luk w Klasie IX.
#   Pokrycie: PCC procedury (przedawnienie, zwrot nadpłaty, inspekcja),
#   podatek od nieruchomości (zwolnienia, nadpłaty, zmiany w trakcie roku),
#   transport (DT-1 korekta, sprzedaż pojazdu w trakcie roku),
#   interakcje między-podatkowe (PCC×VAT edge cases, property×amortyzacja).
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Ustawa o PCC, OrdPU, Ustawa o podatkach lokalnych
# package: jdg.local_taxes.procedures_enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.local_taxes.procedures_enterprise

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.local_taxes.procedures.no_match",
    "package": "jdg.local_taxes.procedures_enterprise", "priority": 1599
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-PCC-01: PCC Statute of Limitations — 5 lat przedawnienia
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    input.invoice.transaction_type in {"CIVIL_LAW_SALE", "PRIVATE_SALE", "LOAN", "BORROWING", "COMPANY_FORMATION"}
    is_vat_transaction := object.get(input.invoice, "is_vat_invoice", false)
    is_vat_transaction == false
    not object.get(input.vendor, "is_vat_payer", false)

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    transaction_year := object.get(input.invoice, "transaction_year", 2026)
    current_year := 2026
    years_since := current_year - transaction_year

    is_expired := years_since >= 5
    pcc_filed := object.get(input.invoice, "pcc3_filed", false)

    proc_routing := "" { is_expired == true }
    proc_routing := "BLOCK_AND_ALERT" { is_expired == false; pcc_filed == false }
    proc_routing := "" { is_expired == false; pcc_filed == true }

    proc_routing_reason := sprintf("PCC przedawnione — transakcja z %d (5 lat minęło)", [transaction_year]) { is_expired == true }
    proc_routing_reason := sprintf("PCC za %d NIEprzedawnione — złóż PCC-3!", [transaction_year]) { is_expired == false; pcc_filed == false }
    proc_routing_reason := "" { is_expired == false; pcc_filed == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.pcc_statute_of_limitations",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1501,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "PCC", "pcc_transaction_year": transaction_year,
        "pcc_years_elapsed": years_since, "pcc_is_expired": is_expired,
        "pcc_declaration_filed": pcc_filed,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 70 §1 OrdPU; Art. 10 ust. 1 Ustawy o PCC",
        "_warnings": [sprintf("⏰ PCC PRZEDAWNIENIE: Transakcja z %d r. — %d lat temu. %s. Termin przedawnienia PCC: 5 lat od końca roku, w którym powstał obowiązek podatkowy.", [transaction_year, years_since, status_note])]
    }

    status_note := "PRZEDAWNIONE — brak obowiązku" { is_expired == true }
    status_note := sprintf("AKTYWNE do końca %d — złóż PCC-3!", [transaction_year + 5]) { is_expired == false; pcc_filed == false }
    status_note := "OK — deklaracja złożona" { is_expired == false; pcc_filed == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-PCC-02: PCC Refund/Overpayment — Zwrot nadpłaty PCC
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.transaction_type == "PCC_OVERPAYMENT_REFUND"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    overpayment_pln := object.get(input.invoice, "pcc_overpayment_pln", 0)
    overpayment_pln > 0
    refund_applied := object.get(input.invoice, "pcc_refund_applied", false)
    refund_deadline_years := 5
    overpayment_year := object.get(input.invoice, "pcc_overpayment_year", 2024)

    is_within_deadline := 2026 - overpayment_year < refund_deadline_years

    proc_routing := "TRIAGE_QUEUE" { is_within_deadline == true; refund_applied == false }
    proc_routing := "" { refund_applied == true }
    proc_routing := "" { is_within_deadline == false }

    proc_routing_reason := sprintf("Nadpłata PCC %.2f PLN za %d — złóż wniosek o zwrot!", [overpayment_pln, overpayment_year]) { is_within_deadline == true; refund_applied == false }
    proc_routing_reason := sprintf("Nadpłata PCC za %d PRZEDAWNIONA", [overpayment_year]) { is_within_deadline == false }
    proc_routing_reason := "" { refund_applied == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.pcc_overpayment_refund",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1502,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "PCC", "pcc_overpayment_pln": overpayment_pln,
        "pcc_overpayment_year": overpayment_year,
        "pcc_refund_within_deadline": is_within_deadline,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 72-80 OrdPU (nadpłata podatku)",
        "_warnings": [sprintf("💰 PCC NADPŁATA: %.2f PLN za rok %d. %s Wniosek o zwrot do US (PCC-3 korekta + wniosek). Termin: 5 lat od dnia powstania nadpłaty.", [overpayment_pln, overpayment_year, refund_note])]
    }

    refund_note := "ZŁÓŻ WNIOSEK O ZWROT!" { is_within_deadline == true; refund_applied == false }
    refund_note := "PRZEDAWNIONE — brak zwrotu" { is_within_deadline == false }
    refund_note := "Wniosek złożony" { refund_applied == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-PCC-03: PCC × VAT Exclusion — Edge cases mieszanych transakcji
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.transaction_type in {"CIVIL_LAW_SALE", "PRIVATE_SALE"}
    is_mixed_transaction := object.get(input.invoice, "is_vat_and_nonvat_mix", false)
    is_mixed_transaction == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_value := object.get(input.invoice, "amount_gross", 0)
    vat_portion := object.get(input.invoice, "vat_portion_value", 0)
    nonvat_portion := total_value - vat_portion

    pcc_applies_to := nonvat_portion { nonvat_portion > 0 }
    pcc_applies_to := 0 { nonvat_portion <= 0 }
    pcc_amount := floor(pcc_applies_to * 0.02 * 100) / 100

    proc_routing := "TRIAGE_QUEUE" { pcc_amount > 0 }
    proc_routing := "" { pcc_amount == 0 }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.pcc_vat_mixed_transaction",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1503,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "PCC", "pcc_mixed_transaction": true,
        "pcc_vat_portion": vat_portion, "pcc_nonvat_portion": nonvat_portion,
        "pcc_amount_pln": pcc_amount,
        "_routing": proc_routing, "_routing_reason": sprintf("Transakcja mieszana VAT+PCC — PCC tylko od %.2f PLN", [nonvat_portion]),
        "_legal_basis": "Art. 2 pkt 4 Ustawy o PCC (wyłączenie VAT) — interpretacja mieszana",
        "_warnings": [sprintf("⚠️ PCC×VAT MIESZANA: Transakcja %.2f PLN (VAT: %.2f + non-VAT: %.2f). PCC 2%% tylko od części non-VAT: %.2f PLN. UWAGA: US może kwestionować podział!", [total_value, vat_portion, nonvat_portion, pcc_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-PROP-01: Property Tax Exemptions — Zwolnienia od podatku
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.has_business_property == true
    exemption_type := object.get(input.jdg_entrepreneur, "property_exemption_type", "NONE")
    exemption_type != "NONE"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    property_area := object.get(input.jdg_entrepreneur, "property_area_m2", 0)
    exemption_applied := object.get(input.jdg_entrepreneur, "property_exemption_dn1_filed", false)

    exemption_label := "Osoby niepełnosprawne (art. 7 ust. 2 pkt 5)" { exemption_type == "DISABLED" }
    exemption_label := "Weterani/ kombatanci (art. 7 ust. 2 pkt 6)" { exemption_type == "VETERAN" }
    exemption_label := "Zabytki wpisane do rejestru (art. 7 ust. 2 pkt 7)" { exemption_type == "MONUMENT" }
    exemption_label := "Szkoły i placówki oświatowe (art. 7 ust. 2 pkt 2)" { exemption_type == "EDUCATION" }
    exemption_label := sprintf("Inne: %s", [exemption_type]) { true }

    proc_routing := "TRIAGE_QUEUE" { exemption_applied == false }
    proc_routing := "" { exemption_applied == true }
    proc_routing_reason := sprintf("Zwolnienie z podatku od nieruchomości (%s) — złóż wniosek DN-1!", [exemption_label]) { exemption_applied == false }
    proc_routing_reason := "" { exemption_applied == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.property_exemption_check",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1511,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "REAL_ESTATE", "property_exemption_type": exemption_type,
        "property_exemption_applied": exemption_applied,
        "property_exemption_label": exemption_label,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 7 Ustawy o podatkach i opłatach lokalnych",
        "_warnings": [sprintf("🏠 ZWOLNIENIE Z PODATKU OD NIERUCHOMOŚCI: %s. %sZłóż wniosek w gminie (DN-1 + dokumentacja). Zwolnienie od następnego miesiąca po złożeniu wniosku.", [exemption_label, appl_note])]
    }

    appl_note := "⚠️ WNIOSEK NIEZŁOŻONY! " { exemption_applied == false }
    appl_note := "✅ Wniosek złożony. " { exemption_applied == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-PROP-02: Property Mid-Year Change — Zmiana powierzchni w trakcie roku
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.has_business_property == true
    area_changed := object.get(input.jdg_entrepreneur, "property_area_changed_mid_year", false)
    area_changed == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    old_area := object.get(input.jdg_entrepreneur, "property_area_old_m2", 0)
    new_area := object.get(input.jdg_entrepreneur, "property_area_m2", 0)
    change_month := object.get(input.jdg_entrepreneur, "property_change_month", 1)
    dn1_updated := object.get(input.jdg_entrepreneur, "dn1_updated_after_change", false)

    months_before := change_month - 1 { change_month > 1 }
    months_before := 0 { change_month <= 1 }
    months_after := 12 - months_before
    rate := 33.10

    tax_before := floor(old_area * rate / 12 * months_before * 100) / 100
    tax_after := floor(new_area * rate / 12 * months_after * 100) / 100
    new_total := tax_before + tax_after

    proc_routing := "TRIAGE_QUEUE" { dn1_updated == false }
    proc_routing := "" { dn1_updated == true }
    proc_routing_reason := sprintf("Zmiana powierzchni w miesiącu %d — aktualizuj DN-1!", [change_month]) { dn1_updated == false }
    proc_routing_reason := "" { dn1_updated == true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.property_mid_year_change",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1512,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "REAL_ESTATE", "property_area_changed": true,
        "property_old_area": old_area, "property_new_area": new_area,
        "property_tax_old_total": tax_before, "property_tax_new_total": tax_after,
        "property_annual_tax_recalculated": new_total,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 6 ust. 6-7 Ustawy o podatkach i opłatach lokalnych",
        "_warnings": [sprintf("📐 ZMIANA POWIERZCHNI: %.0f → %.0f m² od miesiąca %d. Podatek: %.2f (sty-%s) + %.2f (%s-gru) = %.2f PLN/rok. Aktualizuj DN-1 w 14 dni!", [old_area, new_area, change_month, tax_before, sprintf("%d", [change_month - 1]), tax_after, sprintf("%d", [change_month]), new_total])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-TRANS-01: Transport DT-1 Amendment — Sprzedaż pojazdu w trakcie roku
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.has_heavy_vehicle == true
    vehicle_sold := object.get(input.jdg_entrepreneur, "vehicle_sold_mid_year", false)
    vehicle_sold == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    sale_month := object.get(input.jdg_entrepreneur, "vehicle_sale_month", 6)
    annual_tax := object.get(input.jdg_entrepreneur, "transport_tax_annual", 1800)
    dt1_amended := object.get(input.jdg_entrepreneur, "dt1_amended_after_sale", false)

    months_owned := sale_month
    tax_proportional := floor(annual_tax / 12 * months_owned * 100) / 100
    refund_due := floor((annual_tax - tax_proportional) * 100) / 100 { annual_tax > tax_proportional }
    refund_due := 0 { annual_tax <= tax_proportional }

    proc_routing := "TRIAGE_QUEUE" { dt1_amended == false; refund_due > 0 }
    proc_routing := "" { dt1_amended == true }
    proc_routing := "" { refund_due == 0 }
    proc_routing_reason := sprintf("Sprzedaż pojazdu — zwrot %.2f PLN. Złóż korektę DT-1!", [refund_due]) { dt1_amended == false; refund_due > 0 }
    proc_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.transport_sale_mid_year",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1521,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "TRANSPORT", "transport_vehicle_sold": true,
        "transport_sale_month": sale_month, "transport_months_owned": months_owned,
        "transport_tax_proportional": tax_proportional, "transport_tax_refund_due": refund_due,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 9 ust. 5-6 Ustawy o podatkach i opłatach lokalnych",
        "_warnings": [sprintf("🚛 DT-1 KOREKTA: Sprzedaż pojazdu w miesiącu %d. Podatek za %d mies.: %.2f PLN. Nadpłata do zwrotu: %.2f PLN. Złóż korektę DT-1 z wnioskiem o zwrot!", [sale_month, months_owned, tax_proportional, refund_due])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-TRANS-02: Combined Transport Tax — Ciągnik + naczepa łącznie
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.vehicle_type == "TRACTOR_UNIT"
    has_trailer := object.get(input.jdg_entrepreneur, "has_trailer_too", false)
    has_trailer == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    tractor_tax := object.get(input.jdg_entrepreneur, "transport_tax_annual", 2300)
    trailer_dmc := object.get(input.jdg_entrepreneur, "trailer_dmc_kg", 8000)
    trailer_axles := object.get(input.jdg_entrepreneur, "trailer_axles", 2)

    trailer_tax := 800 { trailer_dmc / 1000 <= 5 }
    trailer_tax := 1200 { trailer_dmc / 1000 > 5; trailer_dmc / 1000 <= 10 }
    trailer_tax := 1800 { trailer_dmc / 1000 > 10; trailer_dmc / 1000 <= 20 }
    trailer_tax := 2400 { trailer_dmc / 1000 > 20; trailer_axles == 2 }
    trailer_tax := 3200 { trailer_dmc / 1000 > 20; trailer_axles >= 3 }
    combined_tax := tractor_tax + trailer_tax

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.transport_combined_tractor_trailer",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1522,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "TRANSPORT", "transport_combined": true,
        "transport_tractor_tax": tractor_tax, "transport_trailer_tax": trailer_tax,
        "transport_combined_annual_pln": combined_tax,
        "_routing": "", "_routing_reason": sprintf("Ciągnik+ naczepa — łączny podatek %.0f PLN/rok", [combined_tax]),
        "_legal_basis": "Art. 8-10 Ustawy o podatkach i opłatach lokalnych",
        "_warnings": [sprintf("🚛 ZESTAW: Ciągnik (%.0f PLN) + naczepa DMC %.1ft (%.0f PLN) = %.0f PLN/rok. Osobne pozycje w DT-1!", [tractor_tax, trailer_dmc / 1000, trailer_tax, combined_tax])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-CROSS-01: Property Tax × PIT Amortization — KUP interaction
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.has_business_property == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    property_tax_annual := object.get(input.jdg_entrepreneur, "property_tax_annual", 0)
    property_tax_booked_as_kup := object.get(input.jdg_entrepreneur, "property_tax_in_pkpir", false)

    proc_routing := "TRIAGE_QUEUE" { property_tax_booked_as_kup == false; property_tax_annual > 0 }
    proc_routing := "" { property_tax_booked_as_kup == true }
    proc_routing := "" { property_tax_annual == 0 }
    proc_routing_reason := sprintf("Podatek od nieruchomości %.2f PLN nieuwzględniony w KUP — utrata odliczenia!", [property_tax_annual]) { property_tax_booked_as_kup == false; property_tax_annual > 0 }
    proc_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.property_tax_kup_interaction",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1531,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "CROSS_TAX", "cross_tax_interaction": "PROPERTY_TAX_x_KUP",
        "property_tax_annual_pln": property_tax_annual,
        "property_tax_booked_as_kup": property_tax_booked_as_kup,
        "property_tax_kup_note": "Podatek od nieruchomości firmowej stanowi KUP w dacie zapłaty raty",
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 22 ust. 1 PIT; Art. 23 ust. 1 pkt 20 PIT",
        "_warnings": [sprintf("🔗 PODATEK OD NIER. × KUP: Podatek roczny %.2f PLN. %s Każda rata (15.03, 15.05, 15.09, 15.11) = KUP w dacie zapłaty. Księguj w PKPiR kolumna 13.", [property_tax_annual, kup_note])]
    }

    kup_note := "⚠️ NIE uwzględniony w KUP/PKPiR — utrata odliczenia!" { property_tax_booked_as_kup == false }
    kup_note := "✅ Uwzględniony w KUP." { property_tax_booked_as_kup == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-CROSS-02: Transport Tax × PKPiR — Koszty firmowe
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.has_heavy_vehicle == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    transport_tax_annual := object.get(input.jdg_entrepreneur, "transport_tax_annual", 0)
    transport_tax_booked := object.get(input.jdg_entrepreneur, "transport_tax_booked_as_kup", false)

    proc_routing := "TRIAGE_QUEUE" { transport_tax_booked == false; transport_tax_annual > 0 }
    proc_routing := "" { transport_tax_booked == true }
    proc_routing := "" { transport_tax_annual == 0 }
    proc_routing_reason := sprintf("Podatek od środków transportu %.0f PLN nie w KUP!", [transport_tax_annual]) { transport_tax_booked == false; transport_tax_annual > 0 }
    proc_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.transport_tax_kup_interaction",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1532,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "CROSS_TAX", "cross_tax_interaction": "TRANSPORT_TAX_x_KUP",
        "transport_tax_annual_pln": transport_tax_annual,
        "transport_tax_booked_as_kup": transport_tax_booked,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 22 ust. 1 PIT (KUP — wszystkie koszty poniesione w celu osiągnięcia przychodu)",
        "_warnings": [sprintf("🔗 PODATEK TRANSPORT. × KUP: %.0f PLN/rok. %s Raty (15.02 i 15.09) = KUP w dacie zapłaty. Księguj w PKPiR kolumna 13.", [transport_tax_annual, kup_note])]
    }

    kup_note := "⚠️ NIE zaksięgowany jako KUP!" { transport_tax_booked == false }
    kup_note := "✅ Zaksięgowany jako KUP." { transport_tax_booked == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-CROSS-03: PCC × Business Assets — Środek trwały od osoby prywatnej
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.direction == "PURCHASE"
    input.vendor.is_company == false
    input.invoice.vat_taxable == false
    input.invoice.is_asset_purchase == true
    input.invoice.expense_type == "FIXED_ASSET"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    asset_value := object.get(input.invoice, "amount_gross", 0)
    pcc_amount := floor(asset_value * 0.02 * 100) / 100
    pcc_added_to_initial_value := object.get(input.invoice, "pcc_added_to_asset_value", false)

    initial_value_without_pcc := asset_value
    initial_value_with_pcc := asset_value + pcc_amount { pcc_added_to_initial_value == false }
    initial_value_with_pcc := asset_value { pcc_added_to_initial_value == true }

    proc_routing := "TRIAGE_QUEUE" { pcc_added_to_initial_value == false; pcc_amount > 100 }
    proc_routing := "" { pcc_added_to_initial_value == true }
    proc_routing := "" { pcc_amount <= 100 }
    proc_routing_reason := sprintf("PCC %.2f PLN od ŚT — dodaj do wartości początkowej amortyzacji!", [pcc_amount]) { pcc_added_to_initial_value == false }
    proc_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.pcc_asset_amortization",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1533,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_VIA_AMORTIZATION", "kus_percent": 100,
        "local_tax_type": "CROSS_TAX", "cross_tax_interaction": "PCC_x_AMORTIZATION",
        "pcc_on_asset": pcc_amount, "pcc_added_to_initial_value": pcc_added_to_initial_value,
        "asset_initial_value": initial_value_with_pcc,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 22g ust. 3 PIT (PCC zwiększa wartość początkową ŚT)",
        "_warnings": [sprintf("🔗 PCC × AMORTYZACJA: Zakup ŚT od osoby prywatnej za %.2f PLN. PCC 2%% = %.2f PLN. %s Wartość początkowa ŚT = %.2f PLN (cena + PCC). Amortyzujesz od CAŁEJ kwoty!", [asset_value, pcc_amount, pcc_note, initial_value_with_pcc])]
    }

    pcc_note := "⚠️ PCC NIE doliczone do wartości początkowej — zaniżona amortyzacja!" { pcc_added_to_initial_value == false }
    pcc_note := "✅ PCC doliczone do wartości początkowej." { pcc_added_to_initial_value == true }
}
