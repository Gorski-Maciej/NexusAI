# ------------------------------------------------------------------------------
# NexusAI JDG — PKPiR ENTERPRISE LIVE (Strategic Initiative S17)
# ------------------------------------------------------------------------------
# ENTERPRISE v6.0 — Active Column Validation Layer for PKPiR
# Full validation of 17 PKPiR columns with REAL trigger conditions
# Every purchase/sale invoice = trigger. Uses input.invoice, jdg_entrepreneur, vendor.
# Legal basis: Rozp. MF z 15.11.2025 r. w sprawie PKPiR (§9-29)
# Architecture: Enterprise Live Layer, First-Match-Wins else-chain
# ------------------------------------------------------------------------------

package jdg.pkpir_live

import future.keywords.in
import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.pkpir_live.no_match",
    "package": "jdg.pkpir_live", "priority": 99999
}

# ------------------------------------------------------------------------------
# L-COL1: Kolumna 1 — Liczba porządkowa (LP) — ACTIVE dla każdej transakcji
# ------------------------------------------------------------------------------

decide := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_lp := object.get(input.invoice, "pkpir_lp", 0)
    expected_lp := object.get(input.jdg_entrepreneur, "pkpir_last_lp", 0) + 1

    # Gap detection — OPA 0.68 opts pattern (and→array comparison)
    gap_detected_opts := [
        {"c": [current_lp > 0, current_lp != expected_lp] == [true, true], "v": true},
        {"c": current_lp <= 0, "v": true},
        {"c": true, "v": false}
    ]
    gap_detected := [x.v | some x in gap_detected_opts; x.c][0]

    # Sequential gap size
    gap_size_opts := [
        {"c": current_lp > expected_lp + 1, "v": current_lp - expected_lp - 1},
        {"c": [current_lp > 0, current_lp != expected_lp, current_lp <= expected_lp + 1] == [true, true, true], "v": 1},
        {"c": current_lp == expected_lp, "v": 0}
    ]
    gap_size := [x.v | some x in gap_size_opts; x.c][0]

    # Validation result
    pkpir_validation_opts := [
        {"c": [current_lp > 0, current_lp == expected_lp] == [true, true], "v": "OK"},
        {"c": [current_lp > 0, current_lp != expected_lp] == [true, true], "v": "GAP_DETECTED"},
        {"c": current_lp <= 0, "v": "MISSING_LP"}
    ]
    pkpir_validation := [x.v | some x in pkpir_validation_opts; x.c][0]

    # Routing
    lp_routing_opts := [
        {"c": gap_detected == true, "v": "BLOCK_AND_ALERT"},
        {"c": true, "v": ""}
    ]
    lp_routing := [x.v | some x in lp_routing_opts; x.c][0]

    # Routing reason — conditional: only set when gap detected
    lp_routing_reason_opts := [
        {"c": gap_detected == true, "v": sprintf("Kol.1 PKPiR: LP=%d, oczekiwano=%d — luka w numeracji!", [current_lp, expected_lp])},
        {"c": true, "v": ""}
    ]
    lp_routing_reason := [x.v | some x in lp_routing_reason_opts; x.c][0]

    # Warnings
    lp_warnings_opts := [
        {"c": gap_size > 1, "v": [sprintf("PKPiR Kol.1: LP=%d, oczekiwano=%d. Luka %d numerów!", [current_lp, expected_lp, gap_size])]},
        {"c": current_lp <= 0, "v": [sprintf("PKPiR Kol.1: LP=%d — BRAK LP!", [current_lp])]},
        {"c": [gap_detected == true, gap_size == 1, current_lp > 0] == [true, true, true], "v": [sprintf("PKPiR Kol.1: LP=%d, oczekiwano=%d — poprawiono.", [current_lp, expected_lp])]},
        {"c": true, "v": []}
    ]
    lp_warnings := [x.v | some x in lp_warnings_opts; x.c][0]

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
        "_legal_basis": "§10 ust. 1 pkt 1 rozporządzenia MF w sprawie PKPiR",
        "_warnings": lp_warnings
    }
}

# ------------------------------------------------------------------------------
# L-COL2-3: Kolumna 2-3 — Data zdarzenia i data wpisu do PKPiR
# ------------------------------------------------------------------------------

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    event_date := object.get(input.invoice, "transaction_date", "")
    entry_date := object.get(input.invoice, "pkpir_entry_date", event_date)
    last_date := object.get(input.jdg_entrepreneur, "pkpir_last_entry_date", "2000-01-01")

    # Chronological check — OPA 0.68 opts pattern (and→array comparison)
    is_chronological_opts := [
        {"c": [entry_date != "", last_date != "", entry_date >= last_date] == [true, true, true], "v": true},
        {"c": entry_date == "", "v": true},
        {"c": true, "v": false}
    ]
    is_chronological := [x.v | some x in is_chronological_opts; x.c][0]

    is_chronology_broken := is_chronological == false

    # Deferred date — entry must be >= event. Split OR into separate option entries.
    entry_after_event_opts := [
        {"c": [entry_date != "", event_date != "", entry_date >= event_date] == [true, true, true], "v": true},
        {"c": entry_date == "", "v": true},
        {"c": event_date == "", "v": true},
        {"c": true, "v": false}
    ]
    entry_after_event := [x.v | some x in entry_after_event_opts; x.c][0]

    # Routing
    date_routing_opts := [
        {"c": is_chronology_broken == true, "v": "BLOCK_AND_ALERT"},
        {"c": [entry_after_event == false, is_chronology_broken == false] == [true, true], "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    date_routing := [x.v | some x in date_routing_opts; x.c][0]

    date_routing_reason_opts := [
        {"c": is_chronology_broken == true, "v": sprintf("Kol.2-3 PKPiR: data wpisu %s < ostatni zapis %s — NARUSZENIE chronologii!", [entry_date, last_date])},
        {"c": [entry_after_event == false, is_chronology_broken == false] == [true, true], "v": sprintf("Kol.2-3 PKPiR: data wpisu %s < data zdarzenia %s!", [entry_date, event_date])},
        {"c": true, "v": ""}
    ]
    date_routing_reason := [x.v | some x in date_routing_reason_opts; x.c][0]

    # Warnings
    chrono_label_opts := [
        {"c": is_chronological == true, "v": "OK"},
        {"c": true, "v": "NARUSZONA!"}
    ]
    chrono_label := [x.v | some x in chrono_label_opts; x.c][0]

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
        "_legal_basis": "§10 ust. 1 pkt 2-3 rozporządzenia MF w sprawie PKPiR; §9 ust. 1 (chronologia)",
        "_warnings": date_warnings
    }
}

# ------------------------------------------------------------------------------
# L-COL4-5: Kolumna 4-5 — Nr dokumentu i dane kontrahenta
# ------------------------------------------------------------------------------

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

    # vendor_missing: split OR into separate entries (and→array comparison)
    vendor_missing_opts := [
        {"c": [is_b2b == true, vendor_name == ""] == [true, true], "v": true},
        {"c": [is_b2b == true, vendor_nip == ""] == [true, true], "v": true},
        {"c": true, "v": false}
    ]
    vendor_missing := [x.v | some x in vendor_missing_opts; x.c][0]

    doc_status_opts := [
        {"c": [doc_missing == false, vendor_missing == false] == [true, true], "v": "OK"},
        {"c": doc_missing == true, "v": "MISSING_DOC"},
        {"c": [vendor_missing == true, doc_missing == false] == [true, true], "v": "MISSING_VENDOR"}
    ]
    doc_status := [x.v | some x in doc_status_opts; x.c][0]

    # Routing
    doc_routing_opts := [
        {"c": doc_missing == true, "v": "BLOCK_AND_ALERT"},
        {"c": [vendor_missing == true, doc_missing == false] == [true, true], "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    doc_routing := [x.v | some x in doc_routing_opts; x.c][0]

    doc_routing_reason_opts := [
        {"c": doc_missing == true, "v": "Kol.4 PKPiR: BRAK numeru dokumentu!"},
        {"c": [vendor_missing == true, doc_missing == false] == [true, true], "v": sprintf("Kol.5 PKPiR: Brak danych kontrahenta B2B (NIP: %s)", [vendor_nip])},
        {"c": true, "v": ""}
    ]
    doc_routing_reason := [x.v | some x in doc_routing_reason_opts; x.c][0]

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
        "_legal_basis": "§10 ust. 1 pkt 4-5 rozporządzenia MF w sprawie PKPiR",
        "_warnings": doc_warnings
    }
}

# ------------------------------------------------------------------------------
# L-COL6-9: Kolumny 6-9 — Przychody (SPRZEDAŻ)
# ------------------------------------------------------------------------------

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

    # PKPiR revenue: netto for VAT active, brutto for exempt
    pkpir_revenue_opts := [
        {"c": is_vat_payer == true, "v": revenue_net},
        {"c": true, "v": revenue_gross}
    ]
    pkpir_revenue := [x.v | some x in pkpir_revenue_opts; x.c][0]

    # Kol.7: main revenue
    is_main_revenue := rev_category in {"GOODS", "SERVICES", "MERCHANDISE", "IT_SERVICES"}
    col7_amount_opts := [
        {"c": is_main_revenue == true, "v": pkpir_revenue},
        {"c": true, "v": 0}
    ]
    col7_amount := [x.v | some x in col7_amount_opts; x.c][0]

    # Kol.8: other revenue
    is_other_revenue := is_main_revenue == false
    col8_amount_opts := [
        {"c": is_other_revenue == true, "v": pkpir_revenue},
        {"c": true, "v": 0}
    ]
    col8_amount := [x.v | some x in col8_amount_opts; x.c][0]

    # Kol.9: notes
    col9_notes := sprintf("Sprzedaż [%s]: %s", [rev_category, object.get(input.invoice, "description", "")])

    vat_status_opts := [
        {"c": is_vat_payer == true, "v": "NETTO"},
        {"c": true, "v": "BRUTTO"}
    ]
    vat_status := [x.v | some x in vat_status_opts; x.c][0]

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
        "_legal_basis": "§11 rozporządzenia MF w sprawie PKPiR; §13-14 (przychody)",
        "_warnings": rev_warnings
    }
}

# ------------------------------------------------------------------------------
# L-COL10-14: Kolumny 10-14 — Koszty (ZAKUP)
# ------------------------------------------------------------------------------

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.direction == "PURCHASE"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "OTHER_EXPENSES")
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_gross := object.get(input.invoice, "amount_gross", 0)

    # Ekspresowa klasyfikacja KUP vs NKUP — OPA 0.68 opts pattern (and→array)
    is_nkup_opts := [
        {"c": expense_type in {"REPRESENTATION", "ALCOHOL", "LUXURY", "ENTERTAINMENT", "PERSONAL_EXPENSE"}, "v": true},
        {"c": [input.invoice.is_cash_payment == true, amount_gross >= 15000] == [true, true], "v": true},
        {"c": object.get(input.vendor, "relation_to_entrepreneur", "") in {"SPOUSE", "CHILD"}, "v": true},
        {"c": true, "v": false}
    ]
    is_nkup := [x.v | some x in is_nkup_opts; x.c][0]

    kus_result_opts := [
        {"c": is_nkup == true, "v": "NKUP"},
        {"c": true, "v": "KUP"}
    ]
    kus_result := [x.v | some x in kus_result_opts; x.c][0]

    kus_pct_opts := [
        {"c": is_nkup == true, "v": 0},
        {"c": true, "v": 100}
    ]
    kus_pct := [x.v | some x in kus_pct_opts; x.c][0]

    # Mapowanie na konkretną kolumnę PKPiR (§12 Rozp. MF)
    target_col_opts := [
        {"c": expense_type in {"GOODS", "RAW_MATERIALS", "MERCHANDISE", "MATERIALS"}, "v": 10},
        {"c": expense_type in {"TRANSPORT_COST", "INSURANCE_COST", "CUSTOMS_DUTY", "PACKAGING", "ANCILLARY_COSTS"}, "v": 11},
        {"c": expense_type in {"SALARY", "WAGES", "BONUS", "SALARY_GROSS"}, "v": 12},
        {"c": expense_type in {"RENT", "UTILITIES", "TELECOM", "OFFICE", "IT_SERVICES", "ACCOUNTING", "LEGAL", "MARKETING", "CONSULTING", "TRAINING", "SOFTWARE", "OFFICE_SUPPLIES", "SECURITY", "MAINTENANCE", "TRANSPORT_GOODS", "OTHER_EXPENSES"}, "v": 13},
        {"c": is_nkup == true, "v": 14},
        {"c": true, "v": 13}
    ]
    target_col := [x.v | some x in target_col_opts; x.c][0]

    cost_pln := amount_net

    # Routing: NKUP above 1000 PLN → triage
    cost_routing_opts := [
        {"c": [is_nkup == true, amount_net > 1000] == [true, true], "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    cost_routing := [x.v | some x in cost_routing_opts; x.c][0]

    cost_routing_reason_opts := [
        {"c": [is_nkup == true, amount_net > 1000] == [true, true], "v": sprintf("Kol.%d PKPiR: NKUP %.2f PLN (%s)", [target_col, cost_pln, expense_type])},
        {"c": true, "v": ""}
    ]
    cost_routing_reason := [x.v | some x in cost_routing_reason_opts; x.c][0]

    kup_label_opts := [
        {"c": is_nkup == true, "v": "NKUP"},
        {"c": true, "v": "KUP"}
    ]
    kup_label := [x.v | some x in kup_label_opts; x.c][0]

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
        "_legal_basis": "§12, 15-21 rozporządzenia MF w sprawie PKPiR",
        "_warnings": cost_warnings
    }
}

# ------------------------------------------------------------------------------
# L-COL15-16: Kolumna 15 (amortyzacja+VAT) + Kolumna 16 (NKUP własne)
# ------------------------------------------------------------------------------

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Kol.15: Amortyzacja miesięczna + VAT niepodlegający odliczeniu
    depr_monthly := object.get(input.jdg_entrepreneur, "pkpir_col15_depreciation", 0)
    vat_not_deductible := object.get(input.jdg_entrepreneur, "pkpir_col15_vat_nondeductible", 0)

    # Kol.16: NKUP — składki ZUS przedsiębiorcy
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
        "_legal_basis": "§12 ust. 4-6 rozporządzenia MF w sprawie PKPiR; §21 (NKUP)",
        "_warnings": nkup_warnings
    }
}

# ------------------------------------------------------------------------------
# L-COL17: Kolumna 17 — Ewidencja Środków Trwałych + odpisy amortyzacyjne
# ------------------------------------------------------------------------------

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

    # Amortyzacja miesięczna — OPA 0.68 opts pattern (and→array comparison)
    monthly_depr_opts := [
        {"c": [depr_method == "LINEAR", asset_value > 10000] == [true, true], "v": asset_value * depr_rate / 12},
        {"c": [depr_method == "ONE_OFF", asset_value <= 10000] == [true, true], "v": asset_value},
        {"c": [depr_method == "ONE_OFF", asset_value > 10000, is_small_taxpayer == true] == [true, true, true], "v": asset_value / 12},
        {"c": asset_value == 0, "v": 0},
        {"c": depr_method == "NONE", "v": 0}
    ]
    monthly_depr := [x.v | some x in monthly_depr_opts; x.c][0]

    # Routing
    depr_routing_opts := [
        {"c": [depr_method == "NONE", asset_value > 10000] == [true, true], "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    depr_routing := [x.v | some x in depr_routing_opts; x.c][0]

    depr_routing_reason_opts := [
        {"c": [depr_method == "NONE", asset_value > 10000] == [true, true], "v": sprintf("ŚT %.0f PLN bez metody amortyzacji", [asset_value])},
        {"c": true, "v": ""}
    ]
    depr_routing_reason := [x.v | some x in depr_routing_reason_opts; x.c][0]

    depr_warnings_opts := [
        {"c": asset_value > 0, "v": [sprintf("PKPiR Kol.17: ŚT '%s'=%.0f PLN, KŚT %d/%d, metoda=%s, stawka=%.1f%%, miesięczny odpis=%.2f PLN", [asset_name, asset_value, kst_group, kst_subgroup, depr_method, depr_rate * 100, monthly_depr])]},
        {"c": true, "v": []}
    ]
    depr_warnings := [x.v | some x in depr_warnings_opts; x.c][0]

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

# ------------------------------------------------------------------------------
# L-REMANENT: Remanent — ciągłość roczna + wycena
# ------------------------------------------------------------------------------

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    remnant_start_val := object.get(input.jdg_entrepreneur, "remnant_start_of_year", 0)
    remnant_end_val := object.get(input.jdg_entrepreneur, "remnant_end_of_period", 0)
    remnant_previous_end := object.get(input.jdg_entrepreneur, "remnant_previous_year_end", 0)

    # Continuity: opening = previous closing — OPA 0.68 opts pattern (and→array)
    continuity_ok_opts := [
        {"c": remnant_previous_end == 0, "v": true},
        {"c": [remnant_previous_end > 0, remnant_start_val > 0, remnant_start_val == remnant_previous_end] == [true, true, true], "v": true},
        {"c": true, "v": false}
    ]
    continuity_ok := [x.v | some x in continuity_ok_opts; x.c][0]

    # Impact on income
    remnant_delta_opts := [
        {"c": [remnant_end_val > 0, remnant_start_val > 0] == [true, true], "v": remnant_end_val - remnant_start_val},
        {"c": remnant_end_val == 0, "v": 0},
        {"c": [remnant_start_val == 0, remnant_end_val > 0] == [true, true], "v": remnant_end_val}
    ]
    remnant_delta := [x.v | some x in remnant_delta_opts; x.c][0]

    income_impact := remnant_delta

    # Routing
    remnant_routing_opts := [
        {"c": continuity_ok == false, "v": "BLOCK_AND_ALERT"},
        {"c": [continuity_ok == true, abs(remnant_delta) > 50000] == [true, true], "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    remnant_routing := [x.v | some x in remnant_routing_opts; x.c][0]

    remnant_routing_reason_opts := [
        {"c": continuity_ok == false, "v": sprintf("Remanent: pocz.=%.2f ≠ końc. poprz.=%.2f — BRAK CIĄGŁOŚCI!", [remnant_start_val, remnant_previous_end])},
        {"c": [continuity_ok == true, abs(remnant_delta) > 50000] == [true, true], "v": sprintf("Remanent: duża zmiana %.2f PLN", [remnant_delta])},
        {"c": true, "v": ""}
    ]
    remnant_routing_reason := [x.v | some x in remnant_routing_reason_opts; x.c][0]

    cont_label_opts := [
        {"c": continuity_ok == true, "v": "OK"},
        {"c": true, "v": "NARUSZONA! Korekta wymagana!"}
    ]
    cont_label := [x.v | some x in cont_label_opts; x.c][0]

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
        "_legal_basis": "§27-29 rozporządzenia MF w sprawie PKPiR; Art. 24 ust. 2 PIT",
        "_warnings": remnant_warnings
    }
}

# ------------------------------------------------------------------------------
# L-CROSS-CHECK: Spójność międzykolumnowa — przychody vs koszty + remanent
# ------------------------------------------------------------------------------

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

    # Tolerance 100 PLN — OPA 0.68 opts pattern (and→array)
    has_discrepancy_opts := [
        {"c": reported_income == 0, "v": false},
        {"c": [reported_income > 0, income_diff > 100] == [true, true], "v": true},
        {"c": true, "v": false}
    ]
    has_discrepancy := [x.v | some x in has_discrepancy_opts; x.c][0]

    cross_routing_opts := [
        {"c": [has_discrepancy == true, income_diff > 5000] == [true, true], "v": "BLOCK_AND_ALERT"},
        {"c": [has_discrepancy == true, income_diff > 100, income_diff <= 5000] == [true, true, true], "v": "TRIAGE_QUEUE"},
        {"c": true, "v": ""}
    ]
    cross_routing := [x.v | some x in cross_routing_opts; x.c][0]

    cross_routing_reason_opts := [
        {"c": [has_discrepancy == true, reported_income > 0] == [true, true], "v": sprintf("PKPiR niespójność: dochód wyliczony %.2f ≠ raportowany %.2f (Δ=%.2f PLN)", [calculated_income, reported_income, income_diff])},
        {"c": true, "v": ""}
    ]
    cross_routing_reason := [x.v | some x in cross_routing_reason_opts; x.c][0]

    concord_label_opts := [
        {"c": has_discrepancy == false, "v": "✅ ZGODNE"},
        {"c": true, "v": "⚠️ NIESPÓJNOŚĆ!"}
    ]
    concord_label := [x.v | some x in concord_label_opts; x.c][0]

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
        "_legal_basis": "§10-29 rozporządzenia MF w sprawie PKPiR; Art. 24 PIT",
        "_warnings": cross_warnings
    }
}

# ------------------------------------------------------------------------------
# L-PERIOD-SUMMARY: Podsumowanie okresu PKPiR — wszystkie kolumny
# ------------------------------------------------------------------------------

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.is_period_end == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    entry_count := object.get(input.jdg_entrepreneur, "pkpir_entry_count", 0)
    issue_count := object.get(input.jdg_entrepreneur, "pkpir_issue_flags", 0)

    # OPA 0.68: clean_score as opts pattern (fixes unconditional shadow bug)
    clean_score_opts := [
        {"c": issue_count > 20, "v": 0},
        {"c": true, "v": 100 - issue_count * 5}
    ]
    clean_score := [x.v | some x in clean_score_opts; x.c][0]

    summary := sprintf("Okres PKPiR: %d wpisów, %d flag/ostrzeżeń, czystość=%.0f%%", [entry_count, issue_count, clean_score])

    summary_routing_opts := [
        {"c": clean_score >= 90, "v": ""},
        {"c": clean_score >= 50, "v": "TRIAGE_QUEUE"},
        {"c": true, "v": "BLOCK_AND_ALERT"}
    ]
    summary_routing := [x.v | some x in summary_routing_opts; x.c][0]

    summary_routing_reason_opts := [
        {"c": clean_score < 90, "v": sprintf("PKPiR: czystość %.0f%%, %d flag", [clean_score, issue_count])},
        {"c": true, "v": ""}
    ]
    summary_routing_reason := [x.v | some x in summary_routing_reason_opts; x.c][0]

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
        "_legal_basis": "§9-29 rozporządzenia MF w sprawie PKPiR (podsumowanie okresu)",
        "_warnings": summary_warnings
    }
}

# ------------------------------------------------------------------------------
# L-CASH-TRAP: Pułapka gotówkowa >15k PLN → automatycznie NKUP
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# L-WHITELIST-TRAP: Brak weryfikacji Białej Listy >15k → ryzyko
# ------------------------------------------------------------------------------

else := verdict {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    input.invoice.direction == "PURCHASE"

    transfer_amount := object.get(input.invoice, "amount_gross", 0)
    transfer_amount >= 15000

    is_verified := object.get(input.vendor, "on_whitelist", true)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    wl_routing_opts := [
        {"c": is_verified == false, "v": "BLOCK_AND_ALERT"},
        {"c": true, "v": ""}
    ]
    wl_routing := [x.v | some x in wl_routing_opts; x.c][0]

    wl_routing_reason_opts := [
        {"c": is_verified == false, "v": sprintf("Biała Lista: kontrahent NIEZWERYFIKOWANY dla przelewu %.2f PLN!", [transfer_amount])},
        {"c": true, "v": ""}
    ]
    wl_routing_reason := [x.v | some x in wl_routing_reason_opts; x.c][0]

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
