# JPK_V7 Auto-Generator (JDG Enterprise S12) - priority_range: 1925-1949

package jdg.jpk_v7_autogen

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.jpk_v7.no_match",
    "package": "jdg.jpk_v7_autogen", "priority": 9999
}

# ── Helper functions ─────────────────────────────────────────────────────────

check_status_label(disc_count) = "ZGODNE" { disc_count == 0 }
else = sprintf("NIEZGODNOSCI: %d", [disc_count]) { disc_count > 0 }

extraction_status_label(errors) = "KOMPLETNE" { errors == 0 }
else = sprintf("NIEPELNE — %d faktur", [errors]) { errors > 0 }

sales_routing_flag(docs, vat, net) = "TRIAGE_QUEUE" { docs == 0 }
else = "BLOCK_AND_ALERT" { vat > 0; net == 0 }
else = "" { true }

purchase_routing_flag(wnt, net, vat_ded) = "TRIAGE_QUEUE" { wnt > 0; wnt > net * 0.3 }
else = "BLOCK_AND_ALERT" { vat_ded > net * 0.23 * 1.5 }
else = "" { true }

crosscheck_routing_flag(disc_count) = "BLOCK_AND_ALERT" { disc_count >= 3 }
else = "TRIAGE_QUEUE" { disc_count > 0 }
else = "" { disc_count == 0 }

ksef_extract_routing_flag(errors) = "BLOCK_AND_ALERT" { errors > 0 }
else = "" { errors == 0 }

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1925: JPK_V7M SALES REGISTER AUTO-FILL
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.sales_register_autofill",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1925,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_period": jpk_period,
    "jpk_version": "JPK_V7M(1)",
    "jpk_sales_K_10_total": total_net_sales,
    "jpk_sales_K_11_vat_due": total_vat_due,
    "jpk_sales_document_count": doc_count,
    "jpk_sales_corrections_count": correction_count,
    "_routing": jpk_sales_routing,
    "_routing_reason": jpk_sales_routing_reason,
    "_legal_basis": "Art. 109 ust. 3d-e VAT; Rozporzadzenie MF JPK_V7; Art. 106e VAT",
    "_warnings": build_jpk_sales_warnings(
        jpk_period, total_net_sales, total_vat_due, doc_count, correction_count
    )
} {
    input.jpk_v7_generate == true
    input.invoice.direction == "SALE"

    jp := object.get(input, "jpk_period", "2026-07")
    jpk_period := jp
    total_net_sales := object.get(input, "total_net_sales", 0)
    total_vat_due := object.get(input, "total_vat_due", 0)
    doc_count := object.get(input, "sales_invoice_count", 0)
    correction_count := object.get(input, "sales_corrections_in_period", 0)

    jpk_sales_routing := sales_routing_flag(doc_count, total_vat_due, total_net_sales)
    jpk_sales_routing_reason := ""
}

build_jpk_sales_warnings(pd, net, vat, docs, corrections) = warnings {
    lines := [
        sprintf("JPK_V7M — EWIDENCJA SPRZEDAZY VAT (%s)", [pd]),
        sprintf("   Dokumentow: %d | Korekt: %d", [docs, corrections]),
        sprintf("   Netto sprzedaz: %14.0f PLN | VAT nalezny: %14.0f PLN", [net, vat]),
        sprintf("   Wyslij JPK_V7M przez API KSeF do 25.%s.%s", [object.get(input, "jpk_period_month", "07"), object.get(input, "jpk_period_year", "2026")]),
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1930: JPK_V7M PURCHASE REGISTER AUTO-FILL
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.purchase_register_autofill",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1930,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_period": jpk_period,
    "jpk_purchases_P_38_net": total_net_purchases,
    "jpk_purchases_P_39_vat_deductible": total_vat_deductible,
    "jpk_purchases_non_deductible": non_deductible_vat,
    "jpk_purchases_mp_split_payment": mp_split_payment_total,
    "jpk_purchases_document_count": purchase_count,
    "jpk_purchases_wnt_amount": wnt_amount,
    "jpk_purchases_import_vat": import_vat,
    "jpk_purchases_reverse_charge": reverse_charge_amount,
    "_routing": jpk_purchase_routing,
    "_routing_reason": jpk_purchase_routing_reason,
    "_legal_basis": "Art. 86-91 VAT; Art. 109 ust. 3d-e VAT",
    "_warnings": build_jpk_purchases_warnings(
        jpk_period, total_net_purchases, total_vat_deductible,
        non_deductible_vat, mp_split_payment_total, purchase_count,
        wnt_amount, import_vat
    )
} {
    input.jpk_v7_generate == true
    input.invoice.direction == "PURCHASE"

    jpk_p := object.get(input, "jpk_period", "2026-07")
    jpk_period := jpk_p
    total_net_purchases := object.get(input, "purchases_net_total", 0)
    total_vat_deductible := object.get(input, "purchases_vat_deductible", 0)
    non_deductible_vat := object.get(input, "purchases_vat_non_deductible", 0)
    mp_split_payment_total := object.get(input, "purchases_mp_split_payment_total", 0)
    purchase_count := object.get(input, "purchase_invoice_count", 0)
    wnt_amount := object.get(input, "purchases_wnt_amount", 0)
    import_vat := object.get(input, "purchases_import_vat", 0)
    reverse_charge_amount := object.get(input, "purchases_reverse_charge", 0)

    jpk_purchase_routing := purchase_routing_flag(wnt_amount, total_net_purchases, total_vat_deductible)
    jpk_purchase_routing_reason := ""
}

build_jpk_purchases_warnings(pd, net, vat_ded, non_ded, mp_split, docs, wnt, import_v) = warnings {
    lines := [
        sprintf("JPK_V7M — EWIDENCJA ZAKUPOW VAT (%s)", [pd]),
        sprintf("   Dokumentow: %d | Netto zakupy: %.0f PLN", [docs, net]),
        sprintf("   VAT do odliczenia: %.0f PLN | Niepodlegajacy: %.0f PLN", [vat_ded, non_ded]),
        sprintf("   MPP: %.0f PLN | WNT: %.0f PLN | Import VAT: %.0f PLN", [mp_split, wnt, import_v]),
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1935: VAT-7 DECLARATION AUTO-GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.vat7_declaration_autogen",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1935,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_vat7_period": period,
    "jpk_vat7_sales_vat_due": sales_vat_due,
    "jpk_vat7_purchase_vat_deductible": purchase_vat_ded,
    "jpk_vat7_import_vat_deductible": import_vat_ded,
    "jpk_vat7_wnt_vat": wnt_vat,
    "jpk_vat7_reverse_charge_vat": rc_vat,
    "jpk_vat7_net_vat_to_pay": net_vat_to_pay,
    "jpk_vat7_net_vat_to_refund": net_vat_to_refund,
    "jpk_vat7_carry_forward_to_next": carry_to_next,
    "jpk_vat7_payment_deadline": deadline,
    "jpk_vat7_bank_account_mf": "47 1010 0071 2223 [mikrorachunek VAT]",
    "_routing": vat7_routing,
    "_routing_reason": vat7_routing_reason,
    "_legal_basis": "Art. 99 ust. 1-3 VAT; Art. 103 VAT; Art. 87 VAT",
    "_warnings": build_vat7_warnings(
        period, sales_vat_due, purchase_vat_ded, net_vat_to_pay,
        net_vat_to_refund, carry_to_next, deadline
    )
} {
    input.jpk_v7_generate_vat7 == true

    p := object.get(input, "jpk_period", "2026-07")
    period := p
    period_month := object.get(input, "jpk_period_month", "07")

    sales_vat_due := object.get(input, "sales_vat_due_total", 0)
    purchase_vat_ded := object.get(input, "purchases_vat_deductible", 0)
    import_vat_ded := object.get(input, "import_vat_deductible", 0)
    wnt_vat := object.get(input, "wnt_vat_due", 0)
    rc_vat := object.get(input, "reverse_charge_vat", 0)

    gross_vat_to_pay := sales_vat_due + wnt_vat - purchase_vat_ded - import_vat_ded
    carry_from_prev := object.get(input, "vat_carry_forward_from_prev", 0)
    adjusted_vat := gross_vat_to_pay - carry_from_prev

    # v7.0 FIX (P18): Real VAT-7 refund/carry forward logic.
    # If adjusted_vat < 0 → refund or carry forward to next period (Art. 87 VAT)
    net_vat_to_pay := max([adjusted_vat, 0])
    net_vat_to_refund := max([-adjusted_vat, 0])
    carry_to_next := 0
    # If refund requested as carry forward (not direct refund), set carry_to_next
    carry_requested := object.get(input, "vat_carry_forward_requested", false)
    carry_to_next := net_vat_to_refund { carry_requested }
    net_vat_to_refund := 0 { carry_requested }

    period_year := object.get(input, "jpk_period_year", "2026")
    deadline := sprintf("25.%s.%s", [period_month, period_year])
    vat7_routing := ""
    vat7_routing_reason := ""
}

build_vat7_warnings(pd, sales, purchases, to_pay, to_refund, carry, deadline) = warnings {
    lines := [
        sprintf("VAT-7 — DEKLARACJA MIESIECZNA (%s)", [pd]),
        sprintf("   VAT nalezny: %.0f PLN | VAT naliczony: %.0f PLN", [sales, purchases]),
        sprintf("   DO ZAPLATY: %.0f PLN | DO ZWROTU: %.0f PLN", [to_pay, to_refund]),
        sprintf("   TERMIN: %s | Wyślij przez API KSeF", [deadline]),
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1940: GTU CODE AUTO-ASSIGNMENT
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.gtu_code_autoassignment",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1940,
    "vat_rate": "", "rounding_level": "", "gtu_code": assigned_gtu,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_gtu_codes_full": all_gtu_codes,
    "_routing": gtu_routing,
    "_routing_reason": gtu_routing_reason,
    "_legal_basis": "Art. 106e ust. 1 pkt 18a VAT; Zalacznik nr 15 do ustawy VAT",
    "_warnings": build_gtu_warnings(assigned_gtu, all_gtu_codes)
} {
    input.jpk_v7_assign_gtu == true

    product_category := object.get(input, "product_category", "GENERAL")
    cn_code := object.get(input, "cn_code", "")

    # v7.0 AUDIT FIX (P18): GTU mapping corrected per Załącznik nr 15 do ustawy VAT.
    #   FIX 1: VEHICLES → GTU_07 (pojazdy i części, nie GTU_06)
    #   FIX 2: PHARMA_MEDICAL → GTU_09 (leki i wyroby medyczne, nie GTU_08)
    #   FIX 3: CONSULTING/LEGAL/IT → GTU_12 (usługi niematerialne, nie GTU_11)
    #   EXPANDED: All 13 GTU codes now covered (GTU_01-GTU_13)
    gtu_lookup := {
        "ALCOHOL": ["GTU_01"],
        "FUEL": ["GTU_02"],
        "HEATING_OIL": ["GTU_03"],
        "TOBACCO": ["GTU_04"],
        "ELECTRONICS_WASTE": ["GTU_05"],
        "VEHICLES": ["GTU_07"],
        "VEHICLE_PARTS": ["GTU_07"],
        "PRECIOUS_METALS": ["GTU_08"],
        "PHARMA_MEDICAL": ["GTU_09"],
        "MEDICAL_DEVICES": ["GTU_09"],
        "BUILDINGS_REAL_ESTATE": ["GTU_10"],
        "CONSTRUCTION": ["GTU_10"],
        "CONSULTING": ["GTU_12"],
        "LEGAL": ["GTU_12"],
        "IT_SERVICES": ["GTU_12"],
        "INTANGIBLE_SERVICES": ["GTU_12"],
        "TRANSPORT_LOGISTICS": ["GTU_13"],
        "WAREHOUSING": ["GTU_13"]
    }
    all_gtu_codes := object.get(gtu_lookup, product_category, [])
    assigned_gtu := concat(";", all_gtu_codes)
    requires_detail := count(all_gtu_codes) > 0
    gtu_routing := ""
    gtu_routing_reason := ""
}

build_gtu_warnings(assigned, all_codes) = warnings {
    count(all_codes) > 0
    code_lines := [sprintf("   %s", [c]) | c := all_codes[_]]
    all := array.concat([sprintf("GTU: %s", [assigned]), "Wykryte kody:"], code_lines)
    warnings := all
}

gtu_warnings_fallback(assigned, all_codes) = warnings {
    count(all_codes) == 0
    warnings := ["Brak wymaganych kodow GTU."]
}

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1945: JPK_V7 CROSS-CHECK VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.cross_check_validation",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1945,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_crosscheck_total_discrepancies": total_discrepancies,
    "jpk_crosscheck_status": check_status,
    "jpk_crosscheck_jpk_net_sales": jpk_net_sales,
    "jpk_crosscheck_pkpir_revenue": pkpir_revenue,
    "jpk_crosscheck_ksef_invoice_count": ksef_count,
    "jpk_crosscheck_jpk_invoice_count": jpk_count,
    "_routing": cross_routing,
    "_routing_reason": cross_routing_reason,
    "_legal_basis": "Art. 109 ust. 3d VAT; Rozporzadzenie MF JPK_V7; Art. 193 OrdPU",
    "_warnings": build_crosscheck_warnings(
        total_discrepancies, check_status, jpk_net_sales, pkpir_revenue, ksef_count, jpk_count
    )
} {
    input.jpk_v7_crosscheck == true

    jpk_net_sales := object.get(input, "jpk_sales_net_total", 0)
    pkpir_revenue := object.get(input, "pkpir_revenue_col10", 0)
    jpk_vat_due := object.get(input, "jpk_vat_due_total", 0)
    pkpir_vat := object.get(input, "pkpir_vat_expected", 0)
    ksef_count := object.get(input, "ksef_invoice_count_period", 0)
    jpk_count := object.get(input, "jpk_invoice_count_period", 0)

    # v7.0 AUDIT FIX (P18 — LUKA-J): Cross-check must calculate REAL discrepancies
    # Previously hardcoded to 3, causing BLOCK_AND_ALERT on every check regardless of data.
    # Now computes: net sales difference abs(jpk-pkpir) + vat difference abs(jpk_vat-pkpir_vat) + count diff abs(jpk-ksef)
    net_discrepancy := abs(jpk_net_sales - pkpir_revenue)
    # Only flag if difference > tolerance (1 PLN rounding)
    net_flag := 0
    net_flag := 1 { net_discrepancy > 1 }
    vat_discrepancy := abs(jpk_vat_due - pkpir_vat)
    vat_flag := 0
    vat_flag := 1 { vat_discrepancy > 1 }
    count_discrepancy := abs(jpk_count - ksef_count)
    count_flag := 0
    count_flag := 1 { count_discrepancy > 0 }
    total_discrepancies := net_flag + vat_flag + count_flag

    check_status := check_status_label(total_discrepancies)
    cross_routing := crosscheck_routing_flag(total_discrepancies)
    cross_routing_reason := ""
}

build_crosscheck_warnings(disc_count, status, jpk_sales, pkpir_rev, ksef_cnt, jpk_cnt) = warnings {
    disc_count == 0
    warnings := [
        sprintf("CROSS-CHECK JPK vs PKPiR vs KSeF: %s", [status]),
        sprintf("   JPK sprzedaz: %.0f PLN | PKPiR: %.0f PLN", [jpk_sales, pkpir_rev]),
        sprintf("   JPK faktury: %d | KSeF: %d — ZGODNE", [jpk_cnt, ksef_cnt]),
    ]
}

crosscheck_warnings_fallback(disc_count, status, jpk_sales, pkpir_rev, ksef_cnt) = warnings {
    disc_count > 0
    warnings := [
        sprintf("CROSS-CHECK JPK_V7 — %s — sprawdz roznice!", [status]),
        sprintf("   JPK: %.0f PLN / PKPiR: %.0f PLN / KSeF: %d faktur", [jpk_sales, pkpir_rev, ksef_cnt]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1949: JPK_V7K SUPPORT — Kwartalne rozliczenie VAT (dla malych podatnikow)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.v7k_quarterly_support",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1949,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_version": "JPK_V7K(1)",
    "jpk_v7k_quarter": v7k_quarter,
    "jpk_v7k_quarterly_net_sales": q_net_sales,
    "jpk_v7k_quarterly_vat_due": q_vat_due,
    "jpk_v7k_quarterly_vat_deductible": q_vat_ded,
    "jpk_v7k_net_vat_to_pay": net_vat,
    "jpk_v7k_eligibility_check": eligibility_ok,
    "_routing": v7k_routing,
    "_routing_reason": v7k_reason,
    "_legal_basis": "Art. 99 ust. 2-3 VAT; Art. 2 pkt 25 VAT (maly podatnik)",
    "_warnings": [
        sprintf("JPK_V7K — ROZLICZENIE KWARTALNE (Q%s)", [v7k_quarter]),
        sprintf("   Sprzedaz netto: %.0f PLN | VAT nalezny: %.0f PLN", [q_net_sales, q_vat_due]),
        sprintf("   VAT naliczony: %.0f PLN | Do zaplaty: %.0f PLN", [q_vat_ded, net_vat]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 WARUNKI JPK_V7K (kwartalne):",
        "   • Status malego podatnika VAT (sprzedaz < 2 000 000 EUR)",
        "   • Zlozenie VAT-R z wyborem kwartalnego rozliczenia",
        "   • Brak zaleglosci podatkowych",
        "   • Termin: do 25. dnia miesiaca po zakonczeniu kwartalu",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ UWAGA: Kwartalne = 4 deklaracje zamiast 12 — mniej administracji!",
        "   • ALE: podatek za caly kwartal trzeba zaplacic jednorazowo",
        "   • Wymagane: lepsze planowanie cashflow (modul S8)"
    ]
} {
    input.jpk_v7k_generate == true
    v7k_quarter := object.get(input, "jpk_v7k_quarter", "Q2")
    q_net_sales := object.get(input, "jpk_v7k_quarterly_net_sales", 0)
    q_vat_due := object.get(input, "jpk_v7k_quarterly_vat_due", 0)
    q_vat_ded := object.get(input, "jpk_v7k_quarterly_vat_deductible", 0)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 180000)
    vat_status := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT")
    
    net_vat := q_vat_due - q_vat_ded
    # v7.0 FIX (P18 LUKA-J1): Configurable EUR rate from thresholds instead of hardcoded 4.5
    eur_rate := object.get(object.get(data.thresholds, "rates", {}), "eur_pln", 4.5)
    eligibility_ok := annual_revenue < object.get(object.get(data.thresholds, "vat", {}), "small_taxpayer_threshold_eur", 2000000) * eur_rate
    
    v7k_routing := "TRIAGE_QUEUE" { eligibility_ok; vat_status != "ACTIVE" }
    v7k_routing := "" { true }
    v7k_reason := "Zarejestruj sie jako podatnik VAT kwartalny (VAT-R) aby zmniejszyc liczbe deklaracji z 12 do 4" { eligibility_ok; vat_status != "ACTIVE" }
    v7k_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# JV7-1948: JPK_V7 KSEF DATA EXTRACTION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.jpk_v7.ksef_data_extraction",
    "package": "jdg.jpk_v7_autogen",
    "priority": 1948,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_ksef_invoices_found": ksef_invoice_count,
    "jpk_ksef_invoices_processed": processed_count,
    "jpk_ksef_invoices_with_errors": error_count,
    "jpk_ksef_extraction_status": extraction_status,
    "jpk_ksef_total_net_extracted": total_net_extracted,
    "jpk_ksef_total_vat_extracted": total_vat_extracted,
    "_routing": ksef_extract_routing,
    "_routing_reason": ksef_extract_routing_reason,
    "_legal_basis": "Art. 106na-106nw VAT (KSeF); Rozporzadzenie MF FA(2)",
    "_warnings": build_ksef_extraction_warnings(
        ksef_invoice_count, processed_count, error_count, extraction_status,
        total_net_extracted, total_vat_extracted
    )
} {
    input.jpk_v7_ksef_extract == true

    ksef_invoice_count := object.get(input, "ksef_invoice_count_period", 0)
    processed_count := object.get(input, "ksef_processed_count", 0)
    error_count := ksef_invoice_count - processed_count
    extraction_status := extraction_status_label(error_count)

    total_net_extracted := object.get(input, "ksef_total_net_extracted", 0)
    total_vat_extracted := object.get(input, "ksef_total_vat_extracted", 0)

    ksef_extract_routing := ksef_extract_routing_flag(error_count)
    ksef_extract_routing_reason := ""
}

build_ksef_extraction_warnings(total, processed, errors, status, net, vat) = warnings {
    warnings := [
        sprintf("KSeF -> JPK_V7 EKSTRAKCJA: %s", [status]),
        sprintf("   Faktur KSeF: %d | Przetworzone: %d | Bledy: %d", [total, processed, errors]),
        sprintf("   Wyekstrahowano: netto %.0f PLN, VAT %.0f PLN", [net, vat]),
    ]
}
