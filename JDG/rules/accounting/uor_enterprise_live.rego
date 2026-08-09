# NexusAI JDG — UoR Enterprise Live compatibility adapter
# Public package retained for main_jdg compatibility.

package jdg.uor_live

import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.uor_live.no_match",
    "package": "jdg.uor_live",
    "priority": 99999
}

uor_threshold_eur := 2000000
uor_early_warning_threshold_eur := 1500000

base_verdict := {
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false
}

bool_not(value) := false if { value == true } else := true if { value == false }

any_true(a, b) := true if { a == true } else := true if { b == true } else := false if { a == false; b == false }

any_true4(a, b, c, d) := true if { a == true } else := true if { b == true } else := true if { c == true } else := true if { d == true } else := false if { a == false; b == false; c == false; d == false }

all_true(a, b, c) := true if { a == true; b == true; c == true } else := false if { true }

early_warning_active(value) := true if { value >= uor_early_warning_threshold_eur; value < uor_threshold_eur } else := false if { true }

route_for_count(value) := "" if { value == 0 } else := "TRIAGE_QUEUE" if { value == 1 } else := "BLOCK_AND_ALERT" if { value >= 2 }

document_route(value) := "" if { value == 15 } else := "BLOCK_AND_ALERT" if { value / 15 * 100 < 50 } else := "TRIAGE_QUEUE" if { value < 15 }

balance_route(value) := "" if { value < 0.01 } else := "TRIAGE_QUEUE" if { value <= 1000 } else := "BLOCK_AND_ALERT" if { value > 1000 }

uor_route(required, compliant, early_warning) := "BLOCK_AND_ALERT" if { required; not compliant } else := "WARNING" if { not required; early_warning } else := "" if { true }

inventory_route(complete) := "" if { complete } else := "BLOCK_AND_ALERT" if { not complete }

asset_route(impaired, market) := "TRIAGE_QUEUE" if { impaired; market > 0 } else := "" if { not impaired } else := "" if { market <= 0 }

rmk_route(needs, booked) := "TRIAGE_QUEUE" if { needs; not booked } else := "" if { not needs } else := "" if { needs; booked }

fs_route(filed) := "" if { filed } else := "BLOCK_AND_ALERT" if { not filed }

# Explicit discriminant prevents overlapping public decide rules.
decision_kind := "obligation" if {
    object.get(input.jdg_entrepreneur, "uor_check_requested", false) == true
} else := "document" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    any_true(object.get(input, "uor_document_check", false), object.get(input.jdg_entrepreneur, "uor_document_check", false))
} else := "double_entry" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
    object.get(input.jdg_entrepreneur, "uor_debit_total", null) != null
    object.get(input.jdg_entrepreneur, "uor_credit_total", null) != null
} else := "inventory" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    any_true4(object.get(input, "uor_inventory_check", false), object.get(input.jdg_entrepreneur, "uor_inventory_check", false), object.get(input.jdg_entrepreneur, "uor_physical_count_done", false), object.get(input.jdg_entrepreneur, "uor_balance_confirmation_done", false))
} else := "asset" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "expense_type", "") == "FIXED_ASSET"
} else := "rmk" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false)
    any_true(object.get(input.jdg_entrepreneur, "uor_has_prepaid_expenses", false), object.get(input.jdg_entrepreneur, "uor_has_accrued_expenses", false))
} else := "financial_statement" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false)
    object.get(input.jdg_entrepreneur, "uor_financial_statement_filed", null) != null
} else := "retention" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input, "uor_retention_check", false)
} else := "sof" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    any_true4(object.get(input.invoice, "expense_type", "") == "LEASE", object.get(input.invoice, "has_repurchase_obligation", false), object.get(input.invoice, "expense_type", "") == "FACTORING", object.get(input.invoice, "contract_type", "") == "UMOWA_O_DZIELO")
} else := "principles" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    any_true4(object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false), object.get(input.jdg_entrepreneur, "uor_cost_revenue_mismatch", false), object.get(input.jdg_entrepreneur, "uor_assets_overstated", false), object.get(input.jdg_entrepreneur, "business_status", "ACTIVE") != "ACTIVE")
} else := "status" if {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
} else := "none" if { true }

# UOR-001 — Art. 2.
decide := object.union(base_verdict, {
    "matched": true, "rule_id": "jdg.uor_live.full_accounting_obligation_check", "package": "jdg.uor_live", "priority": 9201,
    "pit_form": pit_form, "uor_full_accounting_required": required, "uor_threshold_eur": uor_threshold_eur,
    "uor_annual_revenue_eur": annual_eur, "uor_annual_revenue_pln": revenue_pln, "uor_cumulative_revenue_eur": cumulative_eur,
    "uor_threshold_pct": floor(cumulative_eur / uor_threshold_eur * 100), "uor_early_warning_active": early_warning,
    "uor_early_warning_threshold_eur": uor_early_warning_threshold_eur, "uor_current_quarter": quarter,
    "uor_quarters_remaining": quarters_remaining, "uor_pkpir_sufficient": bool_not(required), "_routing": route,
    "_routing_reason": sprintf("UoR Art.2: %.0f EUR; próg %.0f EUR.", [annual_eur, uor_threshold_eur]),
    "_legal_basis": "Art. 2 Ustawy o rachunkowości", "_warnings": [sprintf("UoR Art.2: %.0f PLN / %.0f EUR.", [revenue_pln, annual_eur])]
}) if {
    decision_kind == "obligation"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    annual_eur := revenue_pln / 4.5
    required := annual_eur >= uor_threshold_eur
    compliant := object.get(input.jdg_entrepreneur, "uor_compliant", false)
    q1 := object.get(input.jdg_entrepreneur, "revenue_q1", 0); q2 := object.get(input.jdg_entrepreneur, "revenue_q2", 0); q3 := object.get(input.jdg_entrepreneur, "revenue_q3", 0); q4 := object.get(input.jdg_entrepreneur, "revenue_q4", 0)
    cumulative_eur := (q1 + q2 + q3 + q4) / 4.5
    early_warning := early_warning_active(cumulative_eur)
    quarter := object.get(input.jdg_entrepreneur, "current_quarter", 1)
    quarters_remaining := 4 - quarter
    route := uor_route(required, compliant, early_warning)
}

# UOR-020 — Art. 20-21.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.accounting_document_validation", "package": "jdg.uor_live", "priority": 9203, "uor_doc_completeness_pct": floor(present / 15 * 10000) / 100, "uor_doc_elements_present": present, "uor_doc_elements_total": 15, "uor_doc_is_complete": present == 15, "_routing": document_route(present), "_routing_reason": sprintf("UoR Art.20-21: %d/15 elementów dokumentu.", [present]), "_legal_basis": "Art. 20-21 UoR", "_warnings": ["UoR: walidacja kompletności dowodu księgowego"]}) if {
    decision_kind == "document"
    values := [object.get(input.vendor, "name", "") != "", object.get(input.vendor, "address", "") != "", object.get(input.invoice, "issue_date", "") != "", object.get(input.invoice, "transaction_date", "") != "", object.get(input.invoice, "description", "") != "", object.get(input.invoice, "issuer_name", "") != "", object.get(input.invoice, "receiver_name", "") != "", object.get(input.invoice, "amount_net", 0) > 0, object.get(input.invoice, "vat_rate", "") != "", object.get(input.invoice, "amount_vat", -1) >= 0, object.get(input.vendor, "nip", "") != "", object.get(input.invoice, "invoice_number", "") != "", object.get(input.invoice, "payment_method", "") != "", object.get(input.invoice, "payment_due_date", "") != "", object.get(input.invoice, "currency", "PLN") != ""]
    present := count({x | x := values[_]; x == true})
}

# UOR-022 — Art. 22.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.double_entry_validation", "package": "jdg.uor_live", "priority": 9204, "uor_double_entry_balanced": difference < 0.01, "uor_debit_total": debit, "uor_credit_total": credit, "uor_balance_discrepancy": difference, "_routing": balance_route(difference), "_routing_reason": sprintf("UoR Art.22: Wn=%.2f, Ma=%.2f, delta=%.2f", [debit, credit, difference]), "_legal_basis": "Art. 22 UoR", "_warnings": ["UoR: walidacja podwójnego zapisu"]}) if {
    decision_kind == "double_entry"
    debit := object.get(input.jdg_entrepreneur, "uor_debit_total", 0)
    credit := object.get(input.jdg_entrepreneur, "uor_credit_total", 0)
    difference := abs(debit - credit)
}

# UOR-026 — Art. 26-27.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.inventory_obligation_check", "package": "jdg.uor_live", "priority": 9205, "uor_inventory_required": true, "uor_inventory_complete": complete, "uor_inventory_overdue": bool_not(complete),    "_routing": route, "_routing_reason": "UoR Art.26-27: inwentaryzacja roczna", "_legal_basis": "Art. 26-27 UoR", "_warnings": ["UoR: inwentaryzacja roczna"]}) if {
    decision_kind == "inventory"
    complete := all_true(object.get(input.jdg_entrepreneur, "uor_physical_count_done", false), object.get(input.jdg_entrepreneur, "uor_balance_confirmation_done", false), object.get(input.jdg_entrepreneur, "uor_document_verification_done", false))
    route := inventory_route(complete)
}

# UOR-028 — Art. 28-34.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.asset_valuation_check", "package": "jdg.uor_live", "priority": 9206, "uor_valuation_amount": amount, "uor_valuation_market_value": market, "uor_valuation_impairment_required": impaired,    "_routing": route, "_routing_reason": "UoR Art.28-34: wycena aktywów i pasywów", "_legal_basis": "Art. 28-34 UoR", "_warnings": ["UoR: wycena aktywów i pasywów"]}) if {
    decision_kind == "asset"
    amount := object.get(input.invoice, "amount_net", 0)
    market := object.get(input.invoice, "asset_market_value", amount)
    impaired := market < amount * 0.50
    route := asset_route(impaired, market)
}

# UOR-039 — Art. 39.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.accruals_deferrals_check", "package": "jdg.uor_live", "priority": 9207, "uor_rmk_prepaid_detected": prepaid, "uor_rmk_accrued_detected": accrued, "uor_rmk_properly_booked": properly_booked,    "_routing": route, "_routing_reason": "UoR Art.39: rozliczenia międzyokresowe kosztów", "_legal_basis": "Art. 39 UoR", "_warnings": ["UoR: rozliczenia międzyokresowe kosztów"]}) if {
    decision_kind == "rmk"
    prepaid := object.get(input.jdg_entrepreneur, "uor_has_prepaid_expenses", false)
    accrued := object.get(input.jdg_entrepreneur, "uor_has_accrued_expenses", false)
    needs_rmk := any_true(prepaid, accrued)
    properly_booked := object.get(input.jdg_entrepreneur, "uor_rmk_properly_booked", true)
    route := rmk_route(needs_rmk, properly_booked)
}

# UOR-045 — Art. 45-52.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.financial_statement_obligation", "package": "jdg.uor_live", "priority": 9208, "uor_financial_statement_required": true, "uor_fs_filed": filed, "uor_fs_components": ["Bilans", "RZiS", "Informacja dodatkowa"],    "_routing": route, "_routing_reason": "UoR Art.45-52: sprawozdanie finansowe", "_legal_basis": "Art. 45-52 UoR", "_warnings": ["UoR: sprawozdanie finansowe"]}) if {
    decision_kind == "financial_statement"
    filed := object.get(input.jdg_entrepreneur, "uor_financial_statement_filed", false)
    route := fs_route(filed)
}

# UOR-074 — Art. 74.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.document_retention_check", "package": "jdg.uor_live", "priority": 9209, "uor_retention_years": 5, "uor_retention_oldest_year_to_keep": sprintf("%d", [oldest_year]), "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 74 UoR", "_warnings": [sprintf("UoR Art.74: przechowuj dokumenty przez 5 lat; najstarszy rok: %d.", [oldest_year])]}) if {
    decision_kind == "retention"
    oldest_year := object.get(input, "current_year", 2026) - 5
}

# UOR-004-SOF.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.substance_over_form_check", "package": "jdg.uor_live", "priority": 9202, "uor_sof_ok": false, "uor_sof_violations_count": 1, "uor_sof_violations": ["substance_over_form"], "_routing": "TRIAGE_QUEUE", "_routing_reason": "UoR Art.4 pkt 6: substance over form", "_legal_basis": "Art. 4 ust. 1 pkt 6 UoR", "_warnings": ["UoR: przewaga treści ekonomicznej nad formą"]}) if {
    decision_kind == "sof"
}

# UOR-004 — Art. 4 principles.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.accounting_principles_check", "package": "jdg.uor_live", "priority": 9202, "uor_accrual_principle_ok": bool_not(cash_method), "uor_matching_principle_ok": bool_not(mismatch), "uor_prudence_principle_ok": bool_not(overstated), "uor_going_concern_ok": going_concern, "uor_principles_violations": violations, "_routing": route_for_count(violations), "_routing_reason": sprintf("UoR Art.4: %d zasad(y) naruszone.", [violations]), "_legal_basis": "Art. 4 UoR", "_warnings": ["UoR: zasady rachunkowości"]}) if {
    decision_kind == "principles"
    cash_method := object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false)
    mismatch := object.get(input.jdg_entrepreneur, "uor_cost_revenue_mismatch", false)
    overstated := object.get(input.jdg_entrepreneur, "uor_assets_overstated", false)
    going_concern := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE") == "ACTIVE"
    going_concern_violation := bool_not(going_concern)
    violations := count({x | x := [cash_method, mismatch, overstated, going_concern_violation][_]; x == true})
}

# Neutral status for a UoR entity with no requested specialized check.
decide := object.union(base_verdict, {"matched": true, "rule_id": "jdg.uor_live.uor_status_check", "package": "jdg.uor_live", "priority": 9299, "_routing": "", "_routing_reason": "UoR: brak wyspecjalizowanego zdarzenia.", "_legal_basis": "Ustawa o rachunkowości", "_warnings": ["UoR: brak wyspecjalizowanego zdarzenia do walidacji."]}) if {
    decision_kind == "status"
}
