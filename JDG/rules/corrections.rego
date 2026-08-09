# NexusAI JDG Policies — Corrections: korekty faktur i deklaracji (R0420-R0435)
package jdg.corrections

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.corrections.no_match",
    "package": "jdg.corrections",
    "priority": 439
}

correction_change_percent(invoice) = change_percent {
    raw_percent := object.get(invoice, "correction_value_change_pct", 0)
    change_percent := max([raw_percent, 0 - raw_percent])
}

correction_is_red(invoice) {
    correction_change_percent(invoice) > 5
}

correction_is_red(invoice) {
    object.get(invoice, "correction_nip_changed", false) == true
}

correction_is_red(invoice) {
    object.get(invoice, "correction_date_changed", false) == true
}

correction_type(invoice) = "STORNO_RED" {
    correction_is_red(invoice)
}

correction_type(invoice) = "STORNO_BLACK" {
    not correction_is_red(invoice)
}

correction_method(correction) = "Anuluj pierwotną + wystaw nową" {
    correction == "STORNO_RED"
}

correction_method(correction) = "Nota korygująca do istniejącej" {
    correction == "STORNO_BLACK"
}

correction_info(correction) = "Duże zmiany/NIP/data → nowa faktura" {
    correction == "STORNO_RED"
}

correction_info(correction) = "Drobna korekta ilości/ceny" {
    correction == "STORNO_BLACK"
}

jpk_code_for_reason(reason) = code {
    codes := {
        "CALCULATION_ERROR": "1",
        "VAT_RATE_ERROR": "2",
        "CORRECTION_INVOICE_RECEIVED": "3",
        "BAD_DEBT_RELIEF": "4",
        "TAX_AUDIT_DECISION": "5"
    }
    code := object.get(codes, reason, "6")
}

jpk_description_for_reason(reason) = description {
    descriptions := {
        "CALCULATION_ERROR": "Błąd rachunkowy",
        "VAT_RATE_ERROR": "Błąd w stawce VAT",
        "CORRECTION_INVOICE_RECEIVED": "Otrzymanie faktury korygującej",
        "BAD_DEBT_RELIEF": "Ulga na złe długi",
        "TAX_AUDIT_DECISION": "Decyzja US / kontrola"
    }
    description := object.get(descriptions, reason, "Inna przyczyna")
}

correction_tax_year(invoice) = tax_year {
    tax_year := object.get(invoice, "tax_year", 0)
    tax_year != 0
}

correction_deadline(tax_year) = deadline {
    deadline := sprintf("%d-12-31", [to_number(tax_year) + 5])
}

correction_is_within_limits(deadline) {
    deadline >= "2026-12-31"
}

correction_routing(within_limits) = "" {
    within_limits
}

correction_routing(within_limits) = "BLOCK_AND_ALERT" {
    not within_limits
}

correction_routing_reason(within_limits) = "" {
    within_limits
}

correction_routing_reason(within_limits) = "Przedawnienie — korekta NIEDOPUSZCZALNA" {
    not within_limits
}

correction_limit_info(within_limits, deadline) = info {
    within_limits
    info := sprintf("W terminie (do %s)", [deadline])
}

correction_limit_info(within_limits, deadline) = "PO TERMINIE — przedawnione!" {
    not within_limits
}

fixed_asset_correction_years(asset_type) = 10 {
    asset_type == "REAL_ESTATE"
}

fixed_asset_correction_years(asset_type) = 5 {
    asset_type != "REAL_ESTATE"
}

# P1115a: correction_storno_red_vs_black
decide := {
    "matched": true,
    "rule_id": "jdg.corrections.storno_type",
    "package": "jdg.corrections",
    "priority": 415,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "correction_type": corr_type,
    "correction_method": correction_method(corr_type),
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a ust. 13-14 VAT, Art. 106j VAT",
    "_warnings": [sprintf("Korekta: typ=%s, metoda=%s. %s", [corr_type, correction_method(corr_type), correction_info(corr_type)])]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_correction", false) == true
    corr_type := correction_type(invoice)
}

# P1122: correction_jpk_v7_amendment_code
else := {
    "matched": true,
    "rule_id": "jdg.corrections.jpk_amendment_code",
    "package": "jdg.corrections",
    "priority": 422,
    "correction_jpk_code": jpk_code,
    "correction_jpk_code_desc": jpk_desc,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie JPK_VAT",
    "_warnings": [sprintf("Korekta JPK_V7 — kod przyczyny: %s (%s)", [jpk_code, jpk_desc])]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_declaration_correction", false) == true
    reason := object.get(invoice, "correction_reason", "6")
    jpk_code := jpk_code_for_reason(reason)
    jpk_desc := jpk_description_for_reason(reason)
}

# R0420: correction_invoice_in_minus
else := {
    "matched": true,
    "rule_id": "jdg.corrections.invoice_in_minus",
    "package": "jdg.corrections",
    "priority": 420,
    "correction_type": "IN_MINUS",
    "correction_period": "BUYER_RECEIPT_DATE",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106j VAT",
    "_warnings": ["KOREKTA IN MINUS — ujmij w okresie otrzymania potwierdzenia odbioru przez nabywcę."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "document_type", "") == "CORRECTION_INVOICE"
    object.get(invoice, "correction_direction", "") == "DECREASE"
}

# R0421: correction_invoice_in_plus
else := {
    "matched": true,
    "rule_id": "jdg.corrections.invoice_in_plus",
    "package": "jdg.corrections",
    "priority": 421,
    "correction_type": "IN_PLUS",
    "correction_period": "ORIGINAL_INVOICE_PERIOD",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106j VAT",
    "_warnings": ["KOREKTA IN PLUS — ujmij w okresie pierwotnej faktury, jeśli przyczyna istniała w dniu wystawienia."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "document_type", "") == "CORRECTION_INVOICE"
    object.get(invoice, "correction_direction", "") == "INCREASE"
}

# R0422: correction_vat_declaration_period
else := {
    "matched": true,
    "rule_id": "jdg.corrections.vat_declaration_period",
    "package": "jdg.corrections",
    "priority": 422,
    "correction_declaration": "VAT",
    "correction_file": "JPK_V7K",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 81 OrdPU",
    "_warnings": ["KOREKTA DEKLARACJI VAT — złóż JPK_V7K z korektą."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_declaration_correction", false) == true
    object.get(invoice, "tax_type", "") == "VAT"
}

# R0423: correction_jpk_v7_storno
else := {
    "matched": true,
    "rule_id": "jdg.corrections.jpk_v7_storno",
    "package": "jdg.corrections",
    "priority": 423,
    "correction_method": "STORNO",
    "jpk_field": "KOREKTA_PODSTAWY_OPODATKOWANIA",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 109 ust. 3b VAT",
    "_warnings": ["KOREKTA JPK_V7 — storno w polach podstawy opodatkowania."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_jpk_correction", false) == true
}

# R0424: correction_statute_limitations
else := {
    "matched": true,
    "rule_id": "jdg.corrections.statute_limitations",
    "package": "jdg.corrections",
    "priority": 424,
    "correction_deadline_years": 5,
    "correction_allowed": within_limits,
    "_routing": correction_routing(within_limits),
    "_routing_reason": correction_routing_reason(within_limits),
    "_legal_basis": "Art. 70, 81 OrdPU",
    "_warnings": [sprintf("PRZEDAWNIENIE KOREKTY — %s. Zobowiązanie z %v: termin korekty upływa %s.", [correction_limit_info(within_limits, deadline), tax_year, deadline])]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_correction", false) == true
    tax_year := correction_tax_year(invoice)
    deadline := correction_deadline(tax_year)
    within_limits := correction_is_within_limits(deadline)
}

# R0425: correction_interest_calculation
else := {
    "matched": true,
    "rule_id": "jdg.corrections.interest_calculation",
    "package": "jdg.corrections",
    "priority": 425,
    "correction_interest_due": true,
    "correction_interest_rate_pct": interest_pct,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta + odsetki — dopłata po terminie",
    "_legal_basis": "Art. 53-56 OrdPU",
    "_warnings": [sprintf("ODSETKI OD KOREKTY — %.2f PLN × %.1f%% × %d dni = %.2f PLN.", [amount, interest_pct, days_late, interest_amount])]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_correction_in_plus", false) == true
    object.get(invoice, "payment_overdue", false) == true
    days_late := object.get(invoice, "days_overdue", 0)
    days_late > 0
    amount := object.get(invoice, "amount_net", 0)
    interest_pct := object.get(object.get(object.get(object.get(data, "thresholds", {}), "jdg", {}), "bounds", {}), "tax_interest_rate", 14.5)
    interest_amount := floor(amount * interest_pct / 100 * days_late / 365 * 100) / 100
}

# R0426: correction_pit_advance
else := {
    "matched": true,
    "rule_id": "jdg.corrections.pit_advance",
    "package": "jdg.corrections",
    "priority": 426,
    "correction_type": "PIT_ADVANCE",
    "correction_method": "AMEND_PREVIOUS_MONTHS",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 44 PIT",
    "_warnings": ["KOREKTA ZALICZKI PIT — rozlicz korektę w zeznaniu rocznym."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "tax_type", "") == "PIT"
    object.get(invoice, "is_advance_correction", false) == true
}

# R0427: correction_zus_base
else := {
    "matched": true,
    "rule_id": "jdg.corrections.zus_base",
    "package": "jdg.corrections",
    "priority": 427,
    "correction_type": "ZUS_BASE",
    "correction_document": "DRA_KOREKTA",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta podstawy ZUS — złóż DRA korygującą",
    "_legal_basis": "Art. 47 SUS",
    "_warnings": ["KOREKTA ZUS — skoryguj deklarację DRA."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_zus_correction", false) == true
}

# R0428: correction_invoice_numbering
else := {
    "matched": true,
    "rule_id": "jdg.corrections.invoice_numbering",
    "package": "jdg.corrections",
    "priority": 428,
    "numbering_continuity": true,
    "expected_next": expected,
    "actual": actual,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Numeracja faktur — brak ciągłości",
    "_legal_basis": "Art. 106e ust. 1 pkt 2 VAT",
    "_warnings": [sprintf("CIĄGŁOŚĆ NUMERACJI — oczekiwano %s, otrzymano %s.", [expected, actual])]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "document_type", "") == "CORRECTION_INVOICE"
    expected := object.get(invoice, "expected_invoice_number", "")
    actual := object.get(invoice, "invoice_number", "")
    expected != ""
    expected != actual
}

# R0429: collective_correction
else := {
    "matched": true,
    "rule_id": "jdg.corrections.collective_correction",
    "package": "jdg.corrections",
    "priority": 429,
    "collective_correction": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 106j ust. 3 VAT",
    "_warnings": ["KOREKTA ZBIORCZA — podaj okres, łączną kwotę i przyczynę korekty."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_collective_correction", false) == true
}

# R0430: bad_debt_correction
else := {
    "matched": true,
    "rule_id": "jdg.corrections.bad_debt_correction",
    "package": "jdg.corrections",
    "priority": 430,
    "bad_debt_correction": true,
    "creditor_correction": "VAT_DECREASE",
    "debtor_correction": "VAT_INCREASE",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta złe długi — ulga + obowiązek",
    "_legal_basis": "Art. 89a-89b VAT",
    "_warnings": ["KOREKTA ZŁE DŁUGI — wierzyciel zmniejsza VAT, dłużnik zwiększa VAT po 90 dniach."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_bad_debt_correction", false) == true
}

# R0431: annual_correction
else := {
    "matched": true,
    "rule_id": "jdg.corrections.annual_correction",
    "package": "jdg.corrections",
    "priority": 431,
    "annual_vat_correction": true,
    "correction_type": "PROPORTION_UPDATE",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 91 VAT",
    "_warnings": ["KOREKTA ROCZNA VAT — zaktualizuj proporcję odliczeń w JPK_V7."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_annual_proportion_correction", false) == true
}

# R0432: fixed_asset_correction
else := {
    "matched": true,
    "rule_id": "jdg.corrections.fixed_asset_correction",
    "package": "jdg.corrections",
    "priority": 432,
    "fixed_asset_correction": true,
    "correction_period_years": correction_years,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 91 ust. 2 VAT",
    "_warnings": [sprintf("KOREKTA ŚRODKÓW TRWAŁYCH — %d-letni okres korekty.", [correction_years])]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_fixed_asset_correction", false) == true
    asset_type := object.get(invoice, "asset_type", "")
    correction_years := fixed_asset_correction_years(asset_type)
}

# R0433: cross_border_correction
else := {
    "matched": true,
    "rule_id": "jdg.corrections.cross_border_correction",
    "package": "jdg.corrections",
    "priority": 433,
    "cross_border_correction": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta VAT-UE / WNT/WDT",
    "_legal_basis": "Art. 103 VAT",
    "_warnings": ["KOREKTA TRANSGRANICZNA — skoryguj VAT-UE/WNT/WDT."]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_cross_border_correction", false) == true
}

# R0434: correction_overpayment
else := {
    "matched": true,
    "rule_id": "jdg.corrections.correction_overpayment",
    "package": "jdg.corrections",
    "priority": 434,
    "overpayment_detected": true,
    "overpayment_refund_days": 45,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 78 OrdPU",
    "_warnings": [sprintf("NADPŁATA — %.2f PLN. US zwraca w 45 dni.", [overpayment_amount])]
} {
    invoice := object.get(input, "invoice", {})
    overpayment_amount := object.get(invoice, "overpayment_amount", 0)
    overpayment_amount > 0
}

# R0435: correction_underpayment
else := {
    "matched": true,
    "rule_id": "jdg.corrections.correction_underpayment",
    "package": "jdg.corrections",
    "priority": 435,
    "underpayment_detected": true,
    "underpayment_interest": interest_due,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Niedopłata — ureguluj natychmiast!",
    "_legal_basis": "Art. 53 OrdPU",
    "_warnings": [sprintf("NIEDOPŁATA — %.2f PLN + odsetki %.2f PLN.", [underpayment_amount, interest_due])]
} {
    invoice := object.get(input, "invoice", {})
    underpayment_amount := object.get(invoice, "underpayment_amount", 0)
    underpayment_amount > 0
    days_late := object.get(invoice, "days_overdue", 0)
    interest_rate := object.get(object.get(object.get(object.get(data, "thresholds", {}), "jdg", {}), "bounds", {}), "tax_interest_rate", 14.5)
    interest_due := floor(underpayment_amount * interest_rate / 100 * days_late / 365 * 100) / 100
}

# P180: correction_lock_during_audit
else := {
    "matched": true,
    "rule_id": "jdg.corrections.lock_during_audit",
    "package": "jdg.corrections",
    "priority": 180,
    "correction_blocked": true,
    "block_reason": "TAX_AUDIT_IN_PROGRESS",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Korekta zablokowana — trwa kontrola podatkowa",
    "_legal_basis": "Art. 81b § 1 Ordynacji podatkowej",
    "_warnings": ["KOREKTA ZABLOKOWANA — trwa kontrola celno-skarbowa."]
} {
    profile := object.get(input, "jdg_entrepreneur", {})
    invoice := object.get(input, "invoice", {})
    object.get(profile, "tax_audit_in_progress", false) == true
    object.get(invoice, "is_correction", false) == true
}
