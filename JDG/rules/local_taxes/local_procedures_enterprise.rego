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

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-PCC-04: PCC Contract Withdrawal / Wadium (Deposit)
# Art. 1 ust. 1 — wadium/kaucja zwrotna NIE podlega PCC
# Art. 3 ust. 1 pkt 4 — rezygnacja z umowy: zwrot PCC jeśli w ciągu 14 dni
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.transaction_type in {"PCC_CONTRACT_WITHDRAWAL", "PCC_WADIUM_DEPOSIT"}
    tx_type := object.get(input.invoice, "transaction_type", "PCC_CONTRACT_WITHDRAWAL")

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    wadium_amount := object.get(input.invoice, "amount_gross", 0)
    withdrawal_days := object.get(input.invoice, "pcc_withdrawal_days_since_contract", 0)
    is_refundable := object.get(input.invoice, "pcc_wadium_is_refundable", false)
    refund_applied := object.get(input.invoice, "pcc_withdrawal_refund_applied", false)

    # Wadium is NOT subject to PCC (refundable deposit)
    is_wadium := tx_type == "PCC_WADIUM_DEPOSIT"
    is_withdrawal := tx_type == "PCC_CONTRACT_WITHDRAWAL"

    # Withdrawal within 14 days = full PCC refund
    within_deadline := withdrawal_days <= 14
    withdrawal_possible := is_withdrawal and within_deadline

    # PCC to refund
    pcc_already_paid := object.get(input.invoice, "pcc_already_paid_pln", 0)
    refund_amount := pcc_already_paid { withdrawal_possible; not refund_applied }
    refund_amount := 0 { not withdrawal_possible }
    refund_amount := 0 { refund_applied }

    proc_routing := "TRIAGE_QUEUE" { withdrawal_possible; not refund_applied; refund_amount > 0 }
    proc_routing := "BLOCK_AND_ALERT" { is_withdrawal; withdrawal_days > 14; pcc_already_paid > 0 }
    proc_routing := "" { is_wadium }
    proc_routing := "" { refund_applied }
    proc_routing := "" { refund_amount == 0 }

    proc_routing_reason := sprintf("Rezygnacja z umowy w %d dniu — zwrot PCC %.2f PLN!", [withdrawal_days, refund_amount]) { withdrawal_possible; not refund_applied; refund_amount > 0 }
    proc_routing_reason := sprintf("Przekroczony termin 14 dni (%d) — brak zwrotu PCC", [withdrawal_days]) { is_withdrawal; withdrawal_days > 14 }
    proc_routing_reason := "Wadium/kaucja zwrotna — NIE podlega PCC" { is_wadium; is_refundable }
    proc_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.pcc_contract_withdrawal_wadium",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1504,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "PCC", "pcc_withdrawal_type": tx_type,
        "pcc_is_wadium": is_wadium, "pcc_wadium_not_taxable": is_wadium and is_refundable,
        "pcc_withdrawal_days": withdrawal_days, "pcc_withdrawal_within_deadline": within_deadline,
        "pcc_withdrawal_refund_pln": refund_amount,
        "pcc_refund_applied": refund_applied,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 1 ust. 1, Art. 3 ust. 1 pkt 4 Ustawy o PCC; Art. 395 KC",
        "_warnings": [sprintf("📋 PCC REZYGNACJA/WADIUM: %s. %s %s",
            [type_note, status_note, action_note])]
    }

    type_note := "WADIUM — depozyt zwrotny" { is_wadium }
    type_note := sprintf("REZYGNACJA z umowy — %d dni od zawarcia", [withdrawal_days]) { is_withdrawal }

    status_note := sprintf("NIE podlega PCC — %.2f PLN depozytu zwrotnego", [wadium_amount]) { is_wadium; is_refundable }
    status_note := sprintf("Zwrot PCC możliwy — %.2f PLN do odzyskania (≤14 dni)", [refund_amount]) { withdrawal_possible; not refund_applied }
    status_note := sprintf("PRZEKROCZONY termin 14 dni (%d) — PCC przepada", [withdrawal_days]) { is_withdrawal; not within_deadline }
    status_note := "OK — wniosek o zwrot złożony" { refund_applied }

    action_note := "Złóż wniosek o zwrot PCC + korekta PCC-3!" { withdrawal_possible; not refund_applied }
    action_note := "Brak możliwości zwrotu — termin minął" { is_withdrawal; not within_deadline }
    action_note := "Dokumentuj jako depozyt (nie przychód)" { is_wadium }
    action_note := "" { refund_applied }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-EXC-01: Agricultural Diesel Refund — Limit 100 L/ha
# Art. 5 ustawy o zwrocie akcyzy rolnikom: max 100 litrów ON na hektar
# Zwrot: 1.20 PLN/L (część akcyzy)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "MOTOR_FUEL"
    input.invoice.fuel_type == "DIESEL"
    object.get(input.invoice, "diesel_for_agriculture", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    hectares := object.get(input.jdg_entrepreneur, "agricultural_hectares", 10)
    diesel_claimed_liters := object.get(input.invoice, "diesel_agriculture_liters_claimed", 0)
    refund_per_liter := 1.20
    limit_per_ha := 100

    max_liters := hectares * limit_per_ha
    eligible_liters := diesel_claimed_liters { diesel_claimed_liters <= max_liters }
    eligible_liters := max_liters { diesel_claimed_liters > max_liters }
    over_limit := diesel_claimed_liters - max_liters { diesel_claimed_liters > max_liters }
    over_limit := 0 { diesel_claimed_liters <= max_liters }

    refund_amount := floor(eligible_liters * refund_per_liter * 100) / 100
    over_limit_warning := over_limit > 0

    has_documentation := object.get(input.invoice, "diesel_agriculture_documented", false)

    proc_routing := "BLOCK_AND_ALERT" { over_limit_warning; not has_documentation }
    proc_routing := "TRIAGE_QUEUE" { over_limit_warning; has_documentation }
    proc_routing := "TRIAGE_QUEUE" { not over_limit_warning; not has_documentation; refund_amount > 0 }
    proc_routing := "" { not over_limit_warning; has_documentation }
    proc_routing := "" { refund_amount == 0 }

    proc_routing_reason := sprintf("Zwrot ON rolniczy — limit %.0f L/ha × %.1f ha = %.0f L max", [limit_per_ha, hectares, max_liters]) { over_limit_warning }
    proc_routing_reason := sprintf("Zwrot ON rolniczy: %.0f L × %.2f PLN/L = %.2f PLN", [eligible_liters, refund_per_liter, refund_amount]) { not over_limit_warning; refund_amount > 0 }
    proc_routing_reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.agricultural_diesel_limit",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1541,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "AGRICULTURE_DIESEL",
        "excise_diesel_agriculture_hectares": hectares,
        "excise_diesel_limit_per_ha_liters": limit_per_ha,
        "excise_diesel_max_liters": max_liters,
        "excise_diesel_claimed_liters": diesel_claimed_liters,
        "excise_diesel_eligible_liters": eligible_liters,
        "excise_diesel_over_limit_liters": over_limit,
        "excise_diesel_refund_per_liter_pln": refund_per_liter,
        "excise_diesel_refund_total_pln": refund_amount,
        "excise_diesel_over_limit": over_limit_warning,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 5 ustawy o zwrocie podatku akcyzowego rolnikom (Dz.U. 2025 poz. 567)",
        "_warnings": [sprintf("🚜 AKCYZA ON ROLNICZY: %.1f ha × %.0f L/ha = max %.0f L. Zgłoszono: %.0f L (limit %.0f L). %s Zwrot: %.2f PLN. %s. Wniosek do wójta/burmistrza 2× w roku (do 1.03 i 1.09).",
            [hectares, limit_per_ha, max_liters, diesel_claimed_liters, max_liters, limit_note, refund_amount, doc_note])]
    }

    limit_note := "⚠️ PRZEKROCZENIE limitu!" { over_limit_warning }
    limit_note := "✅ W limicie" { not over_limit_warning }

    doc_note := "⚠️ BRAK dokumentacji — faktury VAT za ON" { not has_documentation }
    doc_note := "✅ Dokumentacja OK" { has_documentation }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-EXC-02: Lab/Medical Alcohol Exemption
# Art. 30 ust. 7 pkt 2 — alkohol etylowy do celów medycznych/laboratoryjnych ZWOLNIONY
# Stawka 0% zamiast 8700 PLN/hl 100%
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "ALCOHOL"
    alcohol_type := object.get(input.invoice, "alcohol_type", "")
    alcohol_use := object.get(input.invoice, "alcohol_intended_use", "")
    alcohol_use in {"MEDICAL", "LABORATORY", "PHARMACEUTICAL", "SCIENTIFIC"}

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    volume_hl_100pct := object.get(input.invoice, "quantity_hl_100pct_alcohol", 0)
    volume_hl_100pct > 0

    normal_rate := 8700  # PLN/hl 100% (standard spirits rate)
    exempt_rate := 0     # PLN/hl 100% (lab/medical exemption)
    normal_excise := floor(volume_hl_100pct * normal_rate * 100) / 100
    savings := normal_excise

    has_certificate := object.get(input.invoice, "alcohol_lab_certificate", false)
    is_denatured := object.get(input.invoice, "alcohol_is_denatured", false)

    exempt_valid := has_certificate or is_denatured

    proc_routing := "BLOCK_AND_ALERT" { not exempt_valid }
    proc_routing := "" { exempt_valid }
    proc_routing_reason := sprintf("Alkohol %s — wymagane świadectwo/denaturat!", [alcohol_use]) { not exempt_valid }
    proc_routing_reason := sprintf("Alkohol %s — ZWOLNIONY z akcyzy (oszczędność: %.2f PLN)", [alcohol_use, savings]) { exempt_valid }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.lab_alcohol_exemption",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1542,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "ALCOHOL_EXEMPT",
        "excise_alcohol_use": alcohol_use,
        "excise_alcohol_volume_hl_100pct": volume_hl_100pct,
        "excise_alcohol_normal_rate_per_hl": normal_rate,
        "excise_alcohol_exempt_rate": exempt_rate,
        "excise_alcohol_excise_normal_pln": normal_excise,
        "excise_alcohol_excise_exempt_pln": 0,
        "excise_alcohol_savings_pln": savings,
        "excise_alcohol_exemption_valid": exempt_valid,
        "excise_alcohol_has_certificate": has_certificate,
        "excise_alcohol_is_denatured": is_denatured,
        "_routing": proc_routing, "_routing_reason": proc_routing_reason,
        "_legal_basis": "Art. 30 ust. 7 pkt 2 Ustawy o podatku akcyzowym; Rozp. MF ws. zwolnień",
        "_warnings": [sprintf("🧪 AKCYZA ALKOHOL LAB./MED.: %s — %.4f hl 100%%. Stawka normalna: %.0f PLN/hl = %.2f PLN. Stawka ZWOLNIONA: 0 PLN. Oszczędność: %.2f PLN! %s. Wymagane: świadectwo odbioru lub denaturat.",
            [alcohol_use, volume_hl_100pct, normal_rate, normal_excise, savings, cert_note])]
    }

    cert_note := "⚠️ BRAK świadectwa — akcyza NALICZONA!" { not exempt_valid }
    cert_note := "✅ Świadectwo OK — ZWOLNIONE" { exempt_valid }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-EXC-03: Tobacco 2027 Roadmap Alert
# Mapa drogowa akcyzy tytoniowej 2025-2027:
# 2026: 32% + 105 PLN/1000szt → 2027: 40% + 140 PLN/1000szt
# Alert o nadchodzącej podwyżce
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.invoice.excise_category == "TOBACCO"
    tobacco_type := object.get(input.invoice, "tobacco_type", "CIGARETTES")
    tobacco_type == "CIGARETTES"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    quantity_1000s := object.get(input.invoice, "quantity_per_1000", 0)
    retail_price_per_1000 := object.get(input.invoice, "retail_price_per_1000_pln", 0)

    # 2026 rates
    rate_2026_ad_valorem := 32
    rate_2026_specific := 105.00
    # 2027 rates
    rate_2027_ad_valorem := 40
    rate_2027_specific := 140.00

    # 2026 tax
    excise_2026_ad := retail_price_per_1000 * rate_2026_ad_valorem / 100
    excise_2026_total := floor(quantity_1000s * (excise_2026_ad + rate_2026_specific) * 100) / 100

    # 2027 projected tax
    excise_2027_ad := retail_price_per_1000 * rate_2027_ad_valorem / 100
    excise_2027_total := floor(quantity_1000s * (excise_2027_ad + rate_2027_specific) * 100) / 100

    increase_pln := floor((excise_2027_total - excise_2026_total) * 100) / 100
    increase_pct := floor((rate_2027_ad_valorem - rate_2026_ad_valorem) * 100) / 100

    roadmap_routing := "TRIAGE_QUEUE" { increase_pln > 500 }
    roadmap_routing := "" { increase_pln <= 500 }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.tobacco_2027_roadmap_alert",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1543,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "", "kus_percent": 0,
        "local_tax_type": "EXCISE", "excise_category": "TOBACCO_ROADMAP",
        "excise_tobacco_2026_rate": sprintf("%d%% + %.2f PLN/1000szt", [rate_2026_ad_valorem, rate_2026_specific]),
        "excise_tobacco_2027_rate": sprintf("%d%% + %.2f PLN/1000szt", [rate_2027_ad_valorem, rate_2027_specific]),
        "excise_tobacco_2026_total_pln": excise_2026_total,
        "excise_tobacco_2027_total_pln": excise_2027_total,
        "excise_tobacco_increase_pln": increase_pln,
        "excise_tobacco_increase_pct_points": increase_pct,
        "excise_tobacco_roadmap_effective": "2027-01-01",
        "_routing": roadmap_routing,
        "_routing_reason": sprintf("Mapa drogowa tytoniu 2027: wzrost o %.0f p.p. +35 PLN/1000szt → +%.2f PLN", [increase_pct, increase_pln]),
        "_legal_basis": "Mapa drogowa akcyzy tytoniowej 2025-2027 (Dz.U. 2025 poz. 420); Art. 99-99a u.p.a.",
        "_warnings": [sprintf("🚬 MAPA DROGOWA TYTONIU 2027: Akcyza rośnie od 2027-01-01! Obecnie (2026): %d%% + %.2f PLN = %.2f PLN. 2027: %d%% + %.2f PLN = %.2f PLN. WZROST: +%.2f PLN (%.0f p.p. ad valorem + 35 PLN/1000szt). ZAplanuj wyższe ceny i marże!",
            [rate_2026_ad_valorem, rate_2026_specific, excise_2026_total, rate_2027_ad_valorem, rate_2027_specific, excise_2027_total, increase_pln, increase_pct])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROC-DN1-AUTO: DN-1 Auto-Generator
# Automatyczne generowanie deklaracji DN-1 na podstawie danych nieruchomości
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.has_business_property == true
    object.get(input.jdg_entrepreneur, "dn1_auto_generate", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_area := object.get(input.jdg_entrepreneur, "property_area_m2", 50)
    is_business := object.get(input.jdg_entrepreneur, "property_is_business", true)
    is_mixed := object.get(input.jdg_entrepreneur, "property_is_mixed_use", false)
    business_area := object.get(input.jdg_entrepreneur, "property_business_area_m2", total_area)

    # Rates
    building_business_rate := 33.10
    building_residential_rate := 1.15
    land_business_rate := 1.43

    # Auto-calculate
    biz_area := business_area { is_mixed }
    biz_area := total_area { not is_mixed; is_business }
    priv_area := total_area - biz_area { is_mixed }
    priv_area := 0 { not is_mixed; is_business }

    biz_tax := floor(biz_area * building_business_rate * 100) / 100
    priv_tax := floor(priv_area * building_residential_rate * 100) / 100
    annual_tax := biz_tax + priv_tax
    installment := floor(annual_tax / 4 * 100) / 100

    dn1_filed := object.get(input.jdg_entrepreneur, "dn1_filed", false)

    dn1_fields := {
        "form": "DN-1",
        "tax_year": 2026,
        "taxpayer_nip": object.get(input.jdg_entrepreneur, "nip", ""),
        "property_address": object.get(input.jdg_entrepreneur, "property_address", ""),
        "total_area_m2": total_area,
        "business_area_m2": biz_area,
        "private_area_m2": priv_area,
        "building_business_tax_pln": biz_tax,
        "building_residential_tax_pln": priv_tax,
        "total_annual_tax_pln": annual_tax,
        "installment_pln": installment,
        "payment_schedule": ["15 marca", "15 maja", "15 września", "15 listopada"],
        "municipality_code": object.get(input.jdg_entrepreneur, "property_municipality_code", ""),
        "auto_generated": true
    }

    dn1_routing := "BLOCK_AND_ALERT" { not dn1_filed }
    dn1_routing := "" { dn1_filed }

    verdict := {
        "matched": true, "rule_id": "jdg.local_taxes.procedures.dn1_auto_generator",
        "package": "jdg.local_taxes.procedures_enterprise", "priority": 1551,
        "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": pit_form,
        "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
        "local_tax_type": "REAL_ESTATE", "property_tax_dn1_auto_generated": true,
        "property_dn1_form_data": dn1_fields,
        "property_dn1_annual_tax_pln": annual_tax,
        "property_dn1_installment_pln": installment,
        "property_dn1_filed": dn1_filed,
        "_routing": dn1_routing,
        "_routing_reason": sprintf("DN-1 AutoGen: %.2f PLN/rok (4×%.2f PLN) | %s",
            [annual_tax, installment, dn1_status]),
        "_legal_basis": "Art. 6 ust. 6-9 Ustawy o podatkach i opłatach lokalnych",
        "_warnings": [sprintf("📋 DN-1 AUTO-GENERATOR: Wygenerowano deklarację DN-1. Powierzchnia: %.0f m² (biz: %.0f, priv: %.0f). Podatek roczny: %.2f PLN. Raty: 4×%.2f PLN (15.03, 15.05, 15.09, 15.11). %s",
            [total_area, biz_area, priv_area, annual_tax, installment, filing_note])]
    }

    dn1_status := "NIEZŁOŻONA — złóż w gminie!" { not dn1_filed }
    dn1_status := "✅ ZŁOŻONA" { dn1_filed }
    filing_note := "⚠️ ZŁÓŻ DN-1 w urzędzie gminy w ciągu 14 dni!" { not dn1_filed }
    filing_note := "✅ Deklaracja złożona" { dn1_filed }
}
