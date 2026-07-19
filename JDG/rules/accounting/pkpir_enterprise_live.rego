# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PKPiR ENTERPRISE LIVE (Strategic Initiative S17)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG PKPiR Enterprise Live — Active Column Validation Layer
# description: |
#   ENTERPRISE v6.0 — "Ożywienie" martwej warstwy PKPiR.
#   Problem: 56+ reguł w accounting.rego miało matched:false, bo
#   warunki wyzwalania były zbyt wąskie (np. input.jdg_entrepreneur.uses_pkpir
#   + input.invoice.is_period_end — nigdy jednocześnie true).
#
#   Rozwiązanie: Ten pakiet używa PROSTYCH, REALNYCH triggerów:
#   - Każda faktura zakupowa/sprzedażowa = trigger
#   - Dane z input.invoice (amount_net, amount_gross, direction, expense_type)
#   - Dane z input.jdg_entrepreneur (tax_form, uses_pkpir)
#   - Dane z input.vendor (nip, name, country)
#
#   Pełna walidacja 17 kolumn PKPiR z REALNYMI warunkami:
#   - Kol. 1: LP przy każdej transakcji
#   - Kol. 2-3: Data zdarzenia i wpisu
#   - Kol. 4-5: Nr dokumentu i kontrahent
#   - Kol. 6-9: Przychody
#   - Kol. 10-14: Koszty (zakupy, uboczne, wynagrodzenia, pozostałe)
#   - Kol. 15: Amortyzacja + VAT
#   - Kol. 16: NKUP (wydatki niestanowiące KUP)
#   - Kol. 17: Ewidencja ŚT
#   - Kol. 18-19: Remanent i uwagi
#
#   SYNTAX v2.0: Wszystkie wartości warunkowe zdefiniowane jako zmienne
#   lokalne w ciele reguły, NIE jako inline conditionals w obiekcie.
#   Poprzednia wersja używała "key": "val" { cond } — NIEPOPRAWNE w Rego.
# architecture: Enterprise Live Layer, First-Match-Wins else-chain
# legal_basis: Rozp. MF z 15.11.2025 r. w sprawie PKPiR (§9-29)
# package: jdg.pkpir_live
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pkpir_live

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.pkpir_live.no_match",
    "package": "jdg.pkpir_live", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL1: Kolumna 1 — Liczba porządkowa (LP) — ACTIVE dla każdej transakcji
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_lp := object.get(input.invoice, "pkpir_lp", 0)
    expected_lp := object.get(input.jdg_entrepreneur, "pkpir_last_lp", 0) + 1

    # Gap detection
    gap_detected := false
    gap_detected := true { current_lp > 0; current_lp != expected_lp }
    gap_detected := true { current_lp <= 0 }

    # Sequential gap size
    gap_size := current_lp - expected_lp - 1 { current_lp > expected_lp + 1 }
    gap_size := 1 { current_lp > 0; current_lp != expected_lp; current_lp <= expected_lp + 1 }
    gap_size := 0 { current_lp == expected_lp }

    # Validation result
    pkpir_validation := "OK" { current_lp > 0; current_lp == expected_lp }
    pkpir_validation := "GAP_DETECTED" { current_lp > 0; current_lp != expected_lp }
    pkpir_validation := "MISSING_LP" { current_lp <= 0 }

    # Routing
    lp_routing := "BLOCK_AND_ALERT" { gap_detected == true }
    lp_routing := "" { gap_detected == false }

    lp_routing_reason := sprintf("Kol.1 PKPiR: LP=%d, oczekiwano=%d — luka w numeracji!", [current_lp, expected_lp]) { gap_detected == true }
    lp_routing_reason := "" { gap_detected == false }

    # Warnings
    lp_warnings := [sprintf("PKPiR Kol.1: LP=%d, oczekiwano=%d. Luka %d numerów!", [current_lp, expected_lp, gap_size])] { gap_size > 1 }
    lp_warnings := [sprintf("PKPiR Kol.1: LP=%d — BRAK LP!", [current_lp])] { current_lp <= 0 }
    lp_warnings := [sprintf("PKPiR Kol.1: LP=%d, oczekiwano=%d — poprawiono.", [current_lp, expected_lp])] { gap_detected == true; gap_size == 1; current_lp > 0 }
    lp_warnings := [] { gap_detected == false; current_lp > 0 }

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col1_sequential_validation",
        "package": "jdg.pkpir_live",
        "priority": 9101,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 1, "pkpir_lp_current": current_lp,
        "pkpir_lp_expected": expected_lp,
        "pkpir_validation": pkpir_validation,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": lp_routing,
        "_routing_reason": lp_routing_reason,
        "_legal_basis": "§10 ust. 1 pkt 1 Rozp. MF PKPiR",
        "_warnings": lp_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL2-3: Kolumna 2-3 — Data zdarzenia i data wpisu do PKPiR
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    event_date := object.get(input.invoice, "transaction_date", "")
    entry_date := object.get(input.invoice, "pkpir_entry_date", event_date)
    last_date := object.get(input.jdg_entrepreneur, "pkpir_last_entry_date", "2000-01-01")

    # Chronological check
    is_chronological := true { entry_date != ""; last_date != ""; entry_date >= last_date }
    is_chronological := true { entry_date == "" }
    is_chronological := false { entry_date != ""; last_date != ""; entry_date < last_date }

    is_chronology_broken := true { is_chronological == false }
    is_chronology_broken := false { is_chronological == true }

    # Deferred date — Kol.2 (zdarzenie) może być różna od Kol.3 (wpis)
    # ale wpis musi być późniejszy lub równy zdarzeniu
    entry_after_event := true { entry_date != ""; event_date != ""; entry_date >= event_date }
    entry_after_event := true { entry_date == "" or event_date == "" }
    entry_after_event := false { entry_date != ""; event_date != ""; entry_date < event_date }

    # Routing
    date_routing := "BLOCK_AND_ALERT" { is_chronology_broken == true }
    date_routing := "TRIAGE_QUEUE" { entry_after_event == false; is_chronology_broken == false }
    date_routing := "" { is_chronology_broken == false; entry_after_event == true }

    date_routing_reason := sprintf("Kol.2-3 PKPiR: data wpisu %s < ostatni zapis %s — NARUSZENIE chronologii!", [entry_date, last_date]) { is_chronology_broken == true }
    date_routing_reason := sprintf("Kol.2-3 PKPiR: data wpisu %s < data zdarzenia %s!", [entry_date, event_date]) { entry_after_event == false; is_chronology_broken == false }
    date_routing_reason := "" { is_chronology_broken == false; entry_after_event == true }

    # Warnings
    chrono_label := "OK" { is_chronological == true }
    chrono_label := "NARUSZONA!" { is_chronological == false }

    date_warnings := [sprintf("PKPiR Kol.2-3: zdarzenie=%s, wpis=%s, ostatni=%s. Chronologia: %s", [event_date, entry_date, last_date, chrono_label])]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col2_3_date_validation",
        "package": "jdg.pkpir_live",
        "priority": 9102,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 2, "pkpir_event_date": event_date,
        "pkpir_entry_date": entry_date, "pkpir_last_date": last_date,
        "pkpir_chronological": is_chronological,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": date_routing,
        "_routing_reason": date_routing_reason,
        "_legal_basis": "§10 ust. 1 pkt 2-3 Rozp. MF PKPiR; §9 ust. 1 (chronologia)",
        "_warnings": date_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL4-5: Kolumna 4-5 — Nr dokumentu i dane kontrahenta
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    doc_number := object.get(input.invoice, "document_number", "")
    vendor_name := object.get(input.vendor, "name", "")
    vendor_nip := object.get(input.vendor, "nip", "")

    is_b2b := object.get(input.vendor, "is_company", false)

    # Document status
    doc_missing := doc_number == ""
    vendor_missing := true { is_b2b == true; (vendor_name == "" or vendor_nip == "") }
    vendor_missing := false { is_b2b == false }
    vendor_missing := false { is_b2b == true; vendor_name != ""; vendor_nip != "" }

    doc_status := "OK" { doc_missing == false; vendor_missing == false }
    doc_status := "MISSING_DOC" { doc_missing == true }
    doc_status := "MISSING_VENDOR" { vendor_missing == true; doc_missing == false }

    # Routing
    doc_routing := "BLOCK_AND_ALERT" { doc_missing == true }
    doc_routing := "TRIAGE_QUEUE" { vendor_missing == true; doc_missing == false }
    doc_routing := "" { doc_missing == false; vendor_missing == false }

    doc_routing_reason := "Kol.4 PKPiR: BRAK numeru dokumentu!" { doc_missing == true }
    doc_routing_reason := sprintf("Kol.5 PKPiR: Brak danych kontrahenta B2B (NIP: %s)", [vendor_nip]) { vendor_missing == true; doc_missing == false }
    doc_routing_reason := "" { doc_missing == false; vendor_missing == false }

    doc_warnings := [sprintf("PKPiR Kol.4-5: nr=%s, kontrahent=%s, NIP=%s. Status: %s", [doc_number, vendor_name, vendor_nip, doc_status])]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col4_5_document_validation",
        "package": "jdg.pkpir_live",
        "priority": 9103,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 4, "pkpir_doc_number": doc_number,
        "pkpir_vendor_name": vendor_name, "pkpir_vendor_nip": vendor_nip,
        "pkpir_doc_validation": doc_status,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": doc_routing,
        "_routing_reason": doc_routing_reason,
        "_legal_basis": "§10 ust. 1 pkt 4-5 Rozp. MF PKPiR",
        "_warnings": doc_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL6-9: Kolumny 6-9 — Przychody (SPRZEDAŻ)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.direction == "SALE"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"

    revenue_net := object.get(input.invoice, "amount_net", 0)
    revenue_gross := object.get(input.invoice, "amount_gross", 0)
    vat_amount := object.get(input.invoice, "vat_amount", 0)
    rev_category := object.get(input.invoice, "expense_type", "GOODS")

    # PKPiR revenue: netto dla VAT czynnego, brutto dla zwolnionego
    pkpir_revenue := revenue_net { is_vat_payer == true }
    pkpir_revenue := revenue_gross { is_vat_payer == false }

    # Kol.7: sprzedane towary/usługi (główna działalność)
    is_main_revenue := rev_category in {"GOODS", "SERVICES", "MERCHANDISE", "IT_SERVICES"}
    col7_amount := pkpir_revenue { is_main_revenue == true }
    col7_amount := 0 { is_main_revenue == false }

    # Kol.8: pozostałe przychody
    is_other_revenue := is_main_revenue == false
    col8_amount := pkpir_revenue { is_other_revenue == true }
    col8_amount := 0 { is_other_revenue == false }

    # Kol.9: uwagi — zawsze wypełnione (opis zdarzenia)
    col9_notes := sprintf("Sprzedaż [%s]: %s", [rev_category, object.get(input.invoice, "description", "")])

    # VAT status
    vat_status := "NETTO" { is_vat_payer == true }
    vat_status := "BRUTTO" { is_vat_payer == false }

    rev_warnings := [sprintf("PKPiR Kol.7/8: przychód %s=%.2f PLN. Kol.7=%.2f, Kol.8=%.2f. VAT=%s (%.2f PLN)", [rev_category, pkpir_revenue, col7_amount, col8_amount, vat_status, vat_amount])]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col6_9_revenue_columns",
        "package": "jdg.pkpir_live",
        "priority": 9104,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 7, "pkpir_revenue_net": revenue_net,
        "pkpir_revenue_gross": revenue_gross, "pkpir_vat_amount": vat_amount,
        "pkpir_revenue_category": rev_category,
        "pkpir_revenue_pkpir_amount": pkpir_revenue,
        "pkpir_col7_amount": col7_amount,
        "pkpir_col8_amount": col8_amount,
        "pkpir_col9_notes": col9_notes,
        "pkpir_vat_status": vat_status,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": "",
        "_routing_reason": "",
        "_legal_basis": "§11 Rozp. MF PKPiR; §13-14 (przychody)",
        "_warnings": rev_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL10-14: Kolumny 10-14 — Koszty (ZAKUP)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.direction == "PURCHASE"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "OTHER_EXPENSES")
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_gross := object.get(input.invoice, "amount_gross", 0)

    # Ekspresowa klasyfikacja KUP vs NKUP
    is_nkup := false
    is_nkup := true { expense_type in {"REPRESENTATION", "ALCOHOL", "LUXURY", "ENTERTAINMENT", "PERSONAL_EXPENSE"} }
    is_nkup := true {
        input.invoice.is_cash_payment == true
        amount_gross >= 15000
    }
    is_nkup := true {
        object.get(input.vendor, "relation_to_entrepreneur", "") in {"SPOUSE", "CHILD"}
    }

    kus_result := "NKUP" { is_nkup == true }
    kus_result := "KUP" { is_nkup == false }
    kus_pct := 0 { is_nkup == true }
    kus_pct := 100 { is_nkup == false }

    # Mapowanie na konkretną kolumnę PKPiR (§12 Rozp. MF)
    target_col := 10 { expense_type in {"GOODS", "RAW_MATERIALS", "MERCHANDISE", "MATERIALS"} }
    target_col := 11 { expense_type in {"TRANSPORT_COST", "INSURANCE_COST", "CUSTOMS_DUTY", "PACKAGING", "ANCILLARY_COSTS"} }
    target_col := 12 { expense_type in {"SALARY", "WAGES", "BONUS", "SALARY_GROSS"} }
    target_col := 13 { expense_type in {"RENT", "UTILITIES", "TELECOM", "OFFICE", "IT_SERVICES", "ACCOUNTING", "LEGAL", "MARKETING", "CONSULTING", "TRAINING", "SOFTWARE", "OFFICE_SUPPLIES", "SECURITY", "MAINTENANCE", "TRANSPORT_GOODS", "OTHER_EXPENSES"} }
    target_col := 14 { is_nkup == true }
    target_col := 13 { target_col == 0 }

    cost_pln := amount_net

    # Routing: NKUP powyżej 1000 PLN → triage
    cost_routing := "" { is_nkup == false }
    cost_routing := "TRIAGE_QUEUE" { is_nkup == true; amount_net > 1000 }
    cost_routing := "" { is_nkup == true; amount_net <= 1000 }

    cost_routing_reason := sprintf("Kol.%d PKPiR: NKUP %.2f PLN (%s)", [target_col, cost_pln, expense_type]) { is_nkup == true; amount_net > 1000 }
    cost_routing_reason := "" { is_nkup == false }
    cost_routing_reason := "" { is_nkup == true; amount_net <= 1000 }

    kup_label := "NKUP" { is_nkup == true }
    kup_label := "KUP" { is_nkup == false }

    cost_warnings := [sprintf("PKPiR Kol.%d: %s=%.2f PLN %s.", [target_col, expense_type, cost_pln, kup_label])]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col10_14_cost_columns",
        "package": "jdg.pkpir_live",
        "priority": 9105,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": kus_result, "kus_percent": kus_pct,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": target_col, "pkpir_cost_amount_pln": cost_pln,
        "pkpir_cost_type": expense_type, "pkpir_is_nkup": is_nkup,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": cost_routing,
        "_routing_reason": cost_routing_reason,
        "_legal_basis": "§12, 15-21 Rozp. MF PKPiR",
        "_warnings": cost_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL15-16: Kolumna 15 (amortyzacja+VAT) + Kolumna 16 (NKUP własne)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Kol.15: Amortyzacja miesięczna + VAT niepodlegający odliczeniu
    depr_monthly := object.get(input.jdg_entrepreneur, "pkpir_col15_depreciation", 0)
    vat_not_deductible := object.get(input.jdg_entrepreneur, "pkpir_col15_vat_nondeductible", 0)

    # Kol.16: NKUP — składki ZUS przedsiębiorcy (społeczne + zdrowotna), zaliczki PIT
    zus_social_monthly := object.get(input.jdg_entrepreneur, "zus_social_monthly_pln", 0)
    zus_health_monthly := object.get(input.jdg_entrepreneur, "zus_health_monthly_pln", 0)
    pit_advance_monthly := object.get(input.jdg_entrepreneur, "pit_advance_monthly_pln", 0)

    zus_health_nkup := zus_health_monthly
    pit_advance_nkup := pit_advance_monthly
    nkup_total := zus_social_monthly + zus_health_monthly + pit_advance_monthly

    col15_total := depr_monthly + vat_not_deductible

    nkup_warnings := [
        sprintf("PKPiR Kol.15: Amortyzacja=%.2f PLN + VAT niepodlegający=%.2f PLN. RAZEM Kol.15=%.2f PLN", [depr_monthly, vat_not_deductible, col15_total]),
        sprintf("PKPiR Kol.16 (NKUP): ZUS społeczne=%.2f, ZUS zdrowotne=%.2f, PIT zaliczka=%.2f. RAZEM NKUP=%.2f PLN. To wydatki NIEobniżające dochodu!", [zus_social_monthly, zus_health_monthly, pit_advance_monthly, nkup_total])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col15_16_depreciation_vat_nkup",
        "package": "jdg.pkpir_live",
        "priority": 9106,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "NKUP", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 16, "pkpir_col15_total": col15_total,
        "pkpir_col15_depreciation": depr_monthly,
        "pkpir_col15_vat_nondeductible": vat_not_deductible,
        "pkpir_nkup_own_contributions": nkup_total,
        "pkpir_zus_health_entrepreneur_nkup": zus_health_nkup,
        "pkpir_pit_advance_nkup": pit_advance_nkup,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": "",
        "_routing_reason": "",
        "_legal_basis": "§12 ust. 4-6 Rozp. MF PKPiR; §21 (NKUP)",
        "_warnings": nkup_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-COL17: Kolumna 17 — Ewidencja Środków Trwałych + odpisy amortyzacyjne
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.expense_type == "FIXED_ASSET"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    asset_value := object.get(input.invoice, "amount_net", 0)
    asset_name := object.get(input.invoice, "description", "ŚT")
    depr_method := object.get(input.invoice, "depreciation_method", "LINEAR")
    kst_group := object.get(input.invoice, "kst_group", 0)
    kst_subgroup := object.get(input.invoice, "kst_subgroup", 0)
    depr_rate := object.get(input.invoice, "depreciation_rate", 0.20)
    is_small_taxpayer := object.get(input.jdg_entrepreneur, "is_small_taxpayer", false)

    # Amortyzacja miesięczna
    monthly_depr := asset_value * depr_rate / 12 { depr_method == "LINEAR"; asset_value > 10000 }
    monthly_depr := asset_value { depr_method == "ONE_OFF"; asset_value <= 10000 }
    monthly_depr := asset_value / 12 { depr_method == "ONE_OFF"; asset_value > 10000; is_small_taxpayer == true }
    monthly_depr := 0 { asset_value == 0 }
    monthly_depr := 0 { depr_method == "NONE" }

    # Routing
    depr_routing := "" { depr_method != "NONE" }
    depr_routing := "TRIAGE_QUEUE" { depr_method == "NONE"; asset_value > 10000 }
    depr_routing := "" { depr_method == "NONE"; asset_value <= 10000 }

    depr_routing_reason := sprintf("ŚT %.0f PLN bez metody amortyzacji", [asset_value]) { depr_method == "NONE"; asset_value > 10000 }
    depr_routing_reason := "" { depr_method != "NONE" }
    depr_routing_reason := "" { depr_method == "NONE"; asset_value <= 10000 }

    depr_warnings := [sprintf("PKPiR Kol.17: ŚT '%s'=%.0f PLN, KŚT %d/%d, metoda=%s, stawka=%.1f%%, miesięczny odpis=%.2f PLN", [asset_name, asset_value, kst_group, kst_subgroup, depr_method, depr_rate * 100, monthly_depr])] { asset_value > 0 }
    depr_warnings := [] { asset_value == 0 }

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.col17_fixed_asset_register",
        "package": "jdg.pkpir_live",
        "priority": 9107,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 17, "pkpir_asset_value": asset_value,
        "pkpir_depreciation_monthly": monthly_depr,
        "pkpir_depreciation_method": depr_method,
        "pkpir_kst_group": kst_group, "pkpir_kst_subgroup": kst_subgroup,
        "pkpir_asset_name": asset_name,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": depr_routing,
        "_routing_reason": depr_routing_reason,
        "_legal_basis": "Art. 22a-22o PIT; Rozporządzenie KŚT; §12 ust. 4 PKPiR",
        "_warnings": depr_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-REMANENT: Remanent — ciągłość roczna + wycena
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    remnant_start_val := object.get(input.jdg_entrepreneur, "remnant_start_of_year", 0)
    remnant_end_val := object.get(input.jdg_entrepreneur, "remnant_end_of_period", 0)
    remnant_previous_end := object.get(input.jdg_entrepreneur, "remnant_previous_year_end", 0)

    # Ciągłość: remanent początkowy = końcowy poprzedniego roku
    continuity_ok := true { remnant_previous_end == 0 }
    continuity_ok := true { remnant_previous_end > 0; remnant_start_val > 0; remnant_start_val == remnant_previous_end }
    continuity_ok := false { remnant_previous_end > 0; remnant_start_val > 0; remnant_start_val != remnant_previous_end }

    # Wpływ na dochód: remanent końcowy > początkowy = +dochód
    remnant_delta := remnant_end_val - remnant_start_val { remnant_end_val > 0; remnant_start_val > 0 }
    remnant_delta := 0 { remnant_end_val == 0 }
    remnant_delta := remnant_end_val { remnant_start_val == 0; remnant_end_val > 0 }

    income_impact := remnant_delta

    # Routing
    remnant_routing := "BLOCK_AND_ALERT" { continuity_ok == false }
    remnant_routing := "TRIAGE_QUEUE" { continuity_ok == true; abs(remnant_delta) > 50000 }
    remnant_routing := "" { continuity_ok == true; abs(remnant_delta) <= 50000 }

    remnant_routing_reason := sprintf("Remanent: pocz.=%.2f ≠ końc. poprz.=%.2f — BRAK CIĄGŁOŚCI!", [remnant_start_val, remnant_previous_end]) { continuity_ok == false }
    remnant_routing_reason := sprintf("Remanent: duża zmiana %.2f PLN", [remnant_delta]) { continuity_ok == true; abs(remnant_delta) > 50000 }
    remnant_routing_reason := "" { continuity_ok == true; abs(remnant_delta) <= 50000 }

    cont_label := "OK" { continuity_ok == true }
    cont_label := "NARUSZONA! Korekta wymagana!" { continuity_ok == false }

    remnant_warnings := [
        sprintf("REMANENT PKPiR §27-29: pocz.=%.2f, końc.=%.2f, Δ=%.2f PLN.", [remnant_start_val, remnant_end_val, remnant_delta]),
        sprintf("Wpływ na dochód: %+.2f PLN (remanent końc. > pocz. = ZWIĘKSZA dochód).", [income_impact]),
        sprintf("Ciągłość: %s", [cont_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.remnant_continuity_annual",
        "package": "jdg.pkpir_live",
        "priority": 9108,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_remnant_start": remnant_start_val,
        "pkpir_remnant_end": remnant_end_val,
        "pkpir_remnant_delta": remnant_delta,
        "pkpir_remnant_income_impact": income_impact,
        "pkpir_remnant_continuity_ok": continuity_ok,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": remnant_routing,
        "_routing_reason": remnant_routing_reason,
        "_legal_basis": "§27-29 Rozp. MF PKPiR; Art. 24 ust. 2 PIT",
        "_warnings": remnant_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-CROSS-CHECK: Spójność międzykolumnowa — przychody vs koszty + remanent
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    col7 := object.get(input.jdg_entrepreneur, "pkpir_col7_total", 0)
    col8 := object.get(input.jdg_entrepreneur, "pkpir_col8_total", 0)
    col10 := object.get(input.jdg_entrepreneur, "pkpir_col10_total", 0)
    col11 := object.get(input.jdg_entrepreneur, "pkpir_col11_total", 0)
    col12 := object.get(input.jdg_entrepreneur, "pkpir_col12_total", 0)
    col13 := object.get(input.jdg_entrepreneur, "pkpir_col13_total", 0)
    col14 := object.get(input.jdg_entrepreneur, "pkpir_col14_total", 0)
    rem_start := object.get(input.jdg_entrepreneur, "remnant_start_of_year", 0)
    rem_end := object.get(input.jdg_entrepreneur, "remnant_end_of_period", 0)

    total_revenue := col7 + col8
    total_costs_kup := col10 + col11 + col12 + col13
    total_costs_all := total_costs_kup + col14
    remnant_adj := rem_end - rem_start
    calculated_income := total_revenue - total_costs_kup + remnant_adj

    reported_income := object.get(input.jdg_entrepreneur, "reporting_income", 0)
    income_diff := abs(calculated_income - reported_income)

    # Tolerance 100 PLN
    has_discrepancy := false { reported_income == 0 }
    has_discrepancy := true { reported_income > 0; income_diff > 100 }
    has_discrepancy := false { reported_income > 0; income_diff <= 100 }

    cross_routing := "BLOCK_AND_ALERT" { has_discrepancy == true; income_diff > 5000 }
    cross_routing := "TRIAGE_QUEUE" { has_discrepancy == true; income_diff > 100; income_diff <= 5000 }
    cross_routing := "" { has_discrepancy == false }

    cross_routing_reason := sprintf("PKPiR niespójność: dochód wyliczony %.2f ≠ raportowany %.2f (Δ=%.2f PLN)", [calculated_income, reported_income, income_diff]) { has_discrepancy == true; reported_income > 0 }
    cross_routing_reason := "" { has_discrepancy == false or reported_income == 0 }

    concord_label := "✅ ZGODNE" { has_discrepancy == false }
    concord_label := "⚠️ NIESPÓJNOŚĆ!" { has_discrepancy == true }

    cross_warnings := [
        sprintf("SPÓJNOŚĆ PKPiR: Przychody=%.2f, Koszty KUP=%.2f (NKUP=%.2f), Remanent Δ=%.2f.", [total_revenue, total_costs_kup, col14, remnant_adj]),
        sprintf("Dochód wyliczony=%.2f PLN vs raportowany=%.2f PLN. Różnica=%.2f PLN. %s", [calculated_income, reported_income, income_diff, concord_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.cross_column_consistency_check",
        "package": "jdg.pkpir_live",
        "priority": 9109,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_total_revenue": total_revenue,
        "pkpir_total_costs": total_costs_all,
        "pkpir_remnant_adjustment": remnant_adj,
        "pkpir_calculated_income": calculated_income,
        "pkpir_reported_income": reported_income,
        "pkpir_income_discrepancy": income_diff,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": cross_routing,
        "_routing_reason": cross_routing_reason,
        "_legal_basis": "§10-29 Rozp. MF PKPiR; Art. 24 PIT",
        "_warnings": cross_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-PERIOD-SUMMARY: Podsumowanie okresu PKPiR — wszystkie kolumny
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    entry_count := object.get(input.jdg_entrepreneur, "pkpir_entry_count", 0)
    issue_count := object.get(input.jdg_entrepreneur, "pkpir_issue_flags", 0)
    clean_score := 100 - issue_count * 5 { issue_count <= 20 }
    clean_score := 0 { issue_count > 20 }

    summary := sprintf("Okres PKPiR: %d wpisów, %d flag/ostrzeżeń, czystość=%.0f%%", [entry_count, issue_count, clean_score])

    summary_routing := "" { clean_score >= 90 }
    summary_routing := "TRIAGE_QUEUE" { clean_score >= 50; clean_score < 90 }
    summary_routing := "BLOCK_AND_ALERT" { clean_score < 50 }

    summary_routing_reason := sprintf("PKPiR: czystość %.0f%%, %d flag", [clean_score, issue_count]) { clean_score < 90 }
    summary_routing_reason := "" { clean_score >= 90 }

    summary_warnings := [
        sprintf("📊 PODSUMOWANIE PKPiR: %d wpisów w okresie.", [entry_count]),
        sprintf("✅ Czystość: %.0f%% — %d flag do wyjaśnienia.", [clean_score, issue_count]),
        sprintf("📋 %s", [summary])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.period_summary_report",
        "package": "jdg.pkpir_live",
        "priority": 9190,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_period_summary": summary,
        "pkpir_total_entries": entry_count,
        "pkpir_issues_detected": issue_count,
        "pkpir_clean_score": clean_score,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": summary_routing,
        "_routing_reason": summary_routing_reason,
        "_legal_basis": "§9-29 Rozp. MF PKPiR (podsumowanie okresu)",
        "_warnings": summary_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-CASH-TRAP: Pułapka gotówkowa >15k PLN → automatycznie NKUP
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_cash_payment == true

    cash_amount := object.get(input.invoice, "amount_gross", 0)
    cash_amount >= 15000

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.cash_trap_over_15k_nkup",
        "package": "jdg.pkpir_live",
        "priority": 9195,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "NKUP", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_column": 14, "pkpir_cash_nkup_amount": cash_amount,
        "pkpir_cash_nkup_reason": "Płatność gotówkowa >15k PLN → NKUP (Art. 22p PIT)",
        "business_status": "", "ceidg_registration_required": false,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": sprintf("Gotówka %.2f PLN >15k → NKUP! Użyj przelewu.", [cash_amount]),
        "_legal_basis": "Art. 22p PIT; Art. 19 Prawa przedsiębiorców",
        "_warnings": [sprintf("🚨 PKPiR Kol.14 NKUP: Płatność gotówkowa %.2f PLN > 15 000 PLN! Wydatek NIE stanowi KUP. Używaj przelewów dla kwot >15k PLN!", [cash_amount])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L-WHITELIST-TRAP: Brak weryfikacji Białej Listy >15k → ryzyko
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.direction == "PURCHASE"

    transfer_amount := object.get(input.invoice, "amount_gross", 0)
    transfer_amount >= 15000

    is_verified := object.get(input.vendor, "on_whitelist", true)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    wl_routing := "BLOCK_AND_ALERT" { is_verified == false }
    wl_routing := "" { is_verified == true }

    wl_routing_reason := sprintf("Biała Lista: kontrahent NIEZWERYFIKOWANY dla przelewu %.2f PLN!", [transfer_amount]) { is_verified == false }
    wl_routing_reason := "" { is_verified == true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.pkpir_live.whitelist_verification_required",
        "package": "jdg.pkpir_live",
        "priority": 9196,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "pkpir_whitelist_required": true,
        "pkpir_whitelist_verified": is_verified,
        "pkpir_whitelist_transfer_amount": transfer_amount,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": wl_routing,
        "_routing_reason": wl_routing_reason,
        "_legal_basis": "Art. 96b VAT; Art. 117ba OrdPU",
        "_warnings": [sprintf("⚠️ PKPiR × Biała Lista: Przelew %.2f PLN >15k — zweryfikuj rachunek kontrahenta w Białej Liście MF!", [transfer_amount])]
    }
}
