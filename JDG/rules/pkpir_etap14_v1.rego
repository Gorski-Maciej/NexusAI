# NexusAI JDG — ETAP 14/29: PKPiR columns, documents, revenue/cost, NKUP, remanent, korekty
# Warstwa audytowa nad accounting.rego, accounting/pkpir_enterprise_* oraz
# micro/pkpir/*. Buduje Accounting Evidence Pack (decyzja → wymagany dokument →
# reguła źródłowa), weryfikuje kolumny/numerację/chronologię, moment przychodu/
# kosztu, NKUP/pojazdy/leasing/wynagrodzenia, remanent/storno/korekty oraz
# trzystronne uzgodnienie PKPiR↔VAT↔bank. Idempotentne księgowanie i blokada
# AUTO_POST przy brakach danych (fail-closed — nigdy cichy domyślny wynik).
package jdg.pkpir_etap14

import future.keywords.if
import future.keywords.in

package_id := "jdg.pkpir_etap14"
decision_mode := "SUGGEST"
rounding_contract := "PLN_HALF_UP_2DP"
currency := "PLN"

thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
accounting := object.get(thresholds, "accounting", {})

pkpir_columns := to_number(object.get(accounting, "pkpir_columns", 17))
cash_basis_days := to_number(object.get(accounting, "pkpir_entry_deadline_days", 14))
car_limit_standard := to_number(object.get(accounting, "car_limit_standard", 150000))
car_limit_electric := to_number(object.get(accounting, "car_limit_electric", 225000))
remanent_threshold := to_number(object.get(accounting, "remanent_annual_check", 1))

round2(x) = result {
    result := round(x * 100) / 100
}

# ── Input data contract ───────────────────────────────────────────────────────
ent := object.get(input, "jdg_entrepreneur", {})
acc := object.get(input, "pkpir", {})
uses_pkpir := object.get(ent, "uses_pkpir", false)

# ── Temporal / version contract ───────────────────────────────────────────────
evaluation_date := object.get(input, "evaluation_datetime", object.get(acc, "evaluation_date", ""))
evaluation_year := object.get(input, "evaluation_year", object.get(acc, "evaluation_year", ""))
threshold_version := object.get(input, "threshold_version", object.get(acc, "threshold_version", ""))
legal_basis_version := object.get(input, "legal_basis_version", object.get(acc, "legal_basis_version", ""))
facts_version := object.get(input, "facts_version", object.get(acc, "facts_version", ""))

required_context := ["evaluation_datetime", "evaluation_year", "threshold_version", "legal_basis_version", "facts_version"]
missing_context := [field | field := required_context[_]; object.get(input, field, "") == ""]
uncertainty_markers := object.get(input, "uncertainty_markers", [])

# ── ACCOUNTING EVIDENCE PACK: decyzja → wymagany dokument → reguła źródłowa ──
evidence_pack := [
    {"decision": "Ewidencja przychodu", "required_document": "Faktura sprzedaży / paragon / rachunek", "source_rule": "§10 ust. 1 pkt 6-8 rozp. MF PKPiR; art. 14 ust. 1 PIT", "column": 7},
    {"decision": "Ewidencja kosztu", "required_document": "Faktura zakupu / dowód wewnętrzny", "source_rule": "§10 ust. 1 pkt 10-13 rozp. MF PKPiR; art. 22 ust. 1 PIT", "column": 13},
    {"decision": "Koszt NKUP (wyłączenie)", "required_document": "Dowód + wykaz NKUP", "source_rule": "art. 23 ust. 1 PIT", "column": 14},
    {"decision": "Pojazd w kosztach", "required_document": "Faktura + ewidencja przebiegu (VAT-26)", "source_rule": "art. 23 ust. 1 pkt 46 PIT; limit 150k/225k", "column": 13},
    {"decision": "Leasing operacyjny", "required_document": "Umowa leasingu + harmonogram rat", "source_rule": "art. 23b PIT (cała rata KUP)", "column": 13},
    {"decision": "Leasing finansowy", "required_document": "Umowa + część odsetkowa raty", "source_rule": "art. 23f PIT (tylko odsetki)", "column": 13},
    {"decision": "Wynagrodzenia", "required_document": "Lista płac + dowód wypłaty + ZUS DRA", "source_rule": "art. 22 ust. 1 PIT; kol. 12", "column": 12},
    {"decision": "Remanent", "required_document": "Spis z natury (remanent)", "source_rule": "§18-19 rozp. MF PKPiR; art. 24 ust. 2 PIT", "column": 0},
    {"decision": "Storno (odwrócenie)", "required_document": "Dowód korygujący (minus)", "source_rule": "§11-12 rozp. MF PKPiR", "column": 0},
    {"decision": "Korekta zapisu", "required_document": "Faktura korygująca / nota", "source_rule": "§11-12 rozp. MF PKPiR; art. 14 ust. 1m PIT", "column": 17},
    {"decision": "Uzgodnienie VAT", "required_document": "Rejestr VAT sprzedaży/zakupu", "source_rule": "art. 109 ust. 3 VAT", "column": 0},
    {"decision": "Uzgodnienie z bankiem", "required_document": "Wyciąg bankowy", "source_rule": "art. 24a PIT (dowody)", "column": 0},
    {"decision": "Raport JPK_PKPIR", "required_document": "Struktura JPK_PKPIR (16 kolumn)", "source_rule": "art. 193a OrdPU", "column": 0},
]
evidence_count := count(evidence_pack)

# ── Kolumny / numeracja / chronologia ────────────────────────────────────────
column_count := to_number(object.get(acc, "column_count", object.get(ent, "pkpir_column_count", pkpir_columns)))
columns_complete := column_count >= pkpir_columns

lp_current := to_number(object.get(acc, "entry_number", object.get(ent, "pkpir_lp", 0)))
lp_expected := to_number(object.get(acc, "expected_entry_number", 0))
lp_sequential := lp_current == lp_expected {
    lp_expected > 0
} else := true {
    lp_expected == 0
}

event_date := object.get(acc, "event_date", "")
entry_date := object.get(acc, "entry_date", "")
document_number := object.get(acc, "document_number", "")
counterparty := object.get(acc, "counterparty", "")
chronology_ok := entry_date >= event_date {
    event_date != ""
    entry_date != ""
} else := true {
    event_date == "" or entry_date == ""
}
document_present := document_number != ""

column_audit := {
    "columns_required": pkpir_columns,
    "columns_present": column_count,
    "columns_complete": columns_complete,
    "lp_current": lp_current,
    "lp_expected": lp_expected,
    "lp_sequential": lp_sequential,
    "event_date": event_date,
    "entry_date": entry_date,
    "chronology_ok": chronology_ok,
    "document_number": document_number,
    "counterparty": counterparty,
    "document_present": document_present,
    "legal_basis": "§10-12 rozp. MF z 15.11.2025 r. w sprawie PKPiR",
}

# ── Moment przychodu / kosztu (memoriał kasowy) ──────────────────────────────
direction := object.get(acc, "direction", "")
amount := max([0, to_number(object.get(acc, "amount", 0))])
vat_amount := to_number(object.get(acc, "vat_amount", 0))

revenue_moment := "CASH_RECEIPT" {
    direction == "SALE"
    object.get(acc, "cash_received", false) == true
} else := "ACCRUAL_PENDING" {
    direction == "SALE"
    object.get(acc, "cash_received", false) == false
} else := "" {
    true
}
cost_moment := "CASH_PAID" {
    direction == "PURCHASE"
    object.get(acc, "cash_paid", false) == true
} else := "ACCRUAL_PENDING" {
    direction == "PURCHASE"
    object.get(acc, "cash_paid", false) == false
} else := "" {
    true
}
moment_audit := {
    "direction": direction,
    "amount": round2(amount),
    "vat_amount": round2(vat_amount),
    "revenue_moment": revenue_moment,
    "cost_moment": cost_moment,
    "cash_basis_days": cash_basis_days,
    "legal_basis": "art. 14 ust. 1 PIT (kasowa); §9 ust. 1 rozp. MF PKPiR (14 dni)",
}

# ── NKUP / pojazdy / leasing / wynagrodzenia ─────────────────────────────────
nkup := object.get(acc, "nkup", false)
vehicle_value := to_number(object.get(acc, "vehicle_value", 0))
vehicle_electric := object.get(acc, "vehicle_electric", false)
vehicle_limit := car_limit_electric {
    vehicle_electric
} else := car_limit_standard {
    true
}
vehicle_over_limit := vehicle_value > vehicle_limit {
    vehicle_value > 0
}
leasing_type := object.get(acc, "leasing_type", "")
wages_amount := to_number(object.get(acc, "wages_amount", 0))

deduction_audit := {
    "nkup": nkup,
    "nkup_excluded_from_kup": nkup == true,
    "vehicle_value": vehicle_value,
    "vehicle_electric": vehicle_electric,
    "vehicle_limit": vehicle_limit,
    "vehicle_over_limit": vehicle_over_limit,
    "leasing_type": leasing_type,
    "leasing_operational_full_installment": leasing_type == "OPERATIONAL",
    "leasing_financial_interest_only": leasing_type == "FINANCIAL",
    "wages_amount": wages_amount,
    "legal_basis": "art. 23 ust. 1 PIT (NKUP); art. 23a pkt 47a PIT (limity aut); art. 23b/23f PIT (leasing); art. 22 ust. 1 PIT (wynagrodzenia)",
}

# ── Remanent / storno / korekty ─────────────────────────────────────────────
remanent_type := object.get(acc, "remanent_type", "")
remanent_value := to_number(object.get(acc, "remanent_value", 0))
storno := object.get(acc, "storno", false)
correction := object.get(acc, "correction", false)
correction_reason := object.get(acc, "correction_reason", "")

adjustment_audit := {
    "remanent_type": remanent_type,
    "remanent_value": remanent_value,
    "remanent_required": object.get(acc, "remanent_required", false),
    "storno": storno,
    "storno_negative": storno == false or amount < 0,
    "correction": correction,
    "correction_reason": correction_reason,
    "correction_reason_present": correction == false or correction_reason != "",
    "legal_basis": "§18-19 rozp. MF PKPiR (remanent); §11-12 (storno/korekty); art. 14 ust. 1m PIT",
}

# ── Trzystronne uzgodnienie PKPiR↔VAT↔bank ───────────────────────────────────
pkpir_revenue_total := to_number(object.get(acc, "revenue_total", 0))
pkpir_cost_total := to_number(object.get(acc, "cost_total", 0))
vat := object.get(input, "vat", {})
vat_sales_total := to_number(object.get(vat, "sales_total", 0))
vat_purchase_total := to_number(object.get(vat, "purchase_total", 0))
bank := object.get(input, "bank", {})
bank_inflows := to_number(object.get(bank, "inflows", 0))
bank_outflows := to_number(object.get(bank, "outflows", 0))

tolerance := to_number(object.get(accounting, "reconciliation_tolerance", 0.01))
rev_vat_match := abs(pkpir_revenue_total - vat_sales_total) <= tolerance
cost_vat_match := abs(pkpir_cost_total - vat_purchase_total) <= tolerance
rev_bank_match := abs(pkpir_revenue_total - bank_inflows) <= tolerance
cost_bank_match := abs(pkpir_cost_total - bank_outflows) <= tolerance

reconciliation := {
    "pkpir_revenue_total": round2(pkpir_revenue_total),
    "pkpir_cost_total": round2(pkpir_cost_total),
    "vat_sales_total": round2(vat_sales_total),
    "vat_purchase_total": round2(vat_purchase_total),
    "bank_inflows": round2(bank_inflows),
    "bank_outflows": round2(bank_outflows),
    "revenue_vs_vat": rev_vat_match,
    "cost_vs_vat": cost_vat_match,
    "revenue_vs_bank": rev_bank_match,
    "cost_vs_bank": cost_bank_match,
    "balanced": rev_vat_match and cost_vat_match and rev_bank_match and cost_bank_match,
    "tolerance": tolerance,
    "legal_basis": "art. 109 ust. 3 VAT (rejestr VAT); art. 24a PIT (dowody); JPK_PKPIR art. 193a OrdPU",
}

# ── Idempotentne księgowanie ─────────────────────────────────────────────────
idempotency_key := object.get(acc, "idempotency_key", "")
already_posted := object.get(acc, "already_posted", false)
duplicate_detected := already_posted == true
idempotency_audit := {
    "idempotency_key": idempotency_key,
    "already_posted": already_posted,
    "duplicate_detected": duplicate_detected,
    "key_present": idempotency_key != "",
    "legal_basis": "Idempotencja zapisu — ten sam dowód nie może być zaksięgowany dwukrotnie",
}

# ── Property invariants ──────────────────────────────────────────────────────
inv_amount_non_negative := amount >= 0
inv_wages_non_negative := wages_amount >= 0
inv_remanent_non_negative := remanent_value >= 0
inv_columns_positive := column_count >= 0
inv_storno_negative := storno == false or amount < 0
inv_correction_reason := correction == false or correction_reason != ""

property_invariants := {
    "amount_non_negative": inv_amount_non_negative,
    "wages_non_negative": inv_wages_non_negative,
    "remanent_non_negative": inv_remanent_non_negative,
    "columns_positive": inv_columns_positive,
    "storno_negative": inv_storno_negative,
    "correction_reason": inv_correction_reason,
}

invariant_failed := [name |
    name := ["amount_non_negative", "wages_non_negative", "remanent_non_negative", "columns_positive", "storno_negative", "correction_reason"][_]
    property_invariants[name] == false
]

# ── Fail-closed: AUTO_POST lock przy brakach ────────────────────────────────
collisions := array.concat(
    object.get(input, "pit_conflicts", []),
    array.concat(object.get(input, "vat_conflicts", []), object.get(input, "uor_conflicts", []))
)
missing_document := uses_pkpir and document_present == false
missing_chronology := uses_pkpir and chronology_ok == false
missing_columns := uses_pkpir and columns_complete == false
reconciliation_unbalanced := reconciliation.balanced == false and (pkpir_revenue_total > 0 or pkpir_cost_total > 0)

manual_review := count(missing_context) > 0 or count(uncertainty_markers) > 0 or count(collisions) > 0 or missing_document or missing_chronology or missing_columns or reconciliation_unbalanced or duplicate_detected or count(invariant_failed) > 0

auto_post_allowed := manual_review == false

routing := "BLOCK_AND_ALERT" {
    count(missing_context) > 0
} else := "BLOCK_AND_ALERT" {
    missing_columns
} else := "BLOCK_AND_ALERT" {
    missing_document
} else := "BLOCK_AND_ALERT" {
    duplicate_detected
} else := "TRIAGE_QUEUE" {
    missing_chronology
} else := "TRIAGE_QUEUE" {
    reconciliation_unbalanced
} else := "TRIAGE_QUEUE" {
    count(uncertainty_markers) > 0
} else := "TRIAGE_QUEUE" {
    count(collisions) > 0
} else := "TRIAGE_QUEUE" {
    count(invariant_failed) > 0
} else := "REPORT" {
    true
}

# ── Certificate ───────────────────────────────────────────────────────────────
calculation_certificate := {
    "certificate_id": object.get(input, "calculation_id", "UNASSIGNED"),
    "evaluation_date": evaluation_date,
    "evaluation_year": evaluation_year,
    "threshold_version": threshold_version,
    "legal_basis_version": legal_basis_version,
    "facts_version": facts_version,
    "rounding": rounding_contract,
    "currency": currency,
    "units": {"amount": "PLN", "remanent": "PLN", "wages": "PLN"},
    "source": "data.jdg.thresholds.accounting + input.pkpir + accounting.rego + micro/pkpir/*",
    "manual_review": manual_review,
    "auto_post_allowed": auto_post_allowed,
    "missing_context": missing_context,
    "uncertainty_markers": uncertainty_markers,
    "cross_domain_collisions": collisions,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
}

# Publiczny wynik aktywowany osobną flagą — brak flagi pozostaje no_match.
default decide := {"matched": false, "rule_id": "jdg.pkpir_etap14.no_match", "package": package_id, "priority": 999999}

decide := {
    "matched": true,
    "rule_id": "jdg.pkpir_etap14.report",
    "package": package_id,
    "priority": 580,
    "decision_mode": decision_mode,
    "no_auto_post": true,
    "auto_post_allowed": auto_post_allowed,
    "routing": routing,
    "manual_review": manual_review,
    "evidence_pack": {"entries": evidence_pack, "count": evidence_count},
    "columns": column_audit,
    "moment": moment_audit,
    "deductions": deduction_audit,
    "adjustments": adjustment_audit,
    "reconciliation": reconciliation,
    "idempotency": idempotency_audit,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
    "calculation_certificate": calculation_certificate,
    "threshold_snapshot": {"pkpir_columns": pkpir_columns, "cash_basis_days": cash_basis_days, "car_limit_standard": car_limit_standard, "car_limit_electric": car_limit_electric, "evaluation_year": evaluation_year},
    "_routing": routing,
    "_routing_reason": "ETAP 14 PKPiR: dowody, kolumny, chronologia, moment, NKUP/pojazdy/leasing/wynagrodzenia, remanent/storno/korekty, uzgodnienie 3-stronne, idempotencja i blokada AUTO_POST",
    "_legal_basis": "§10-12/§18-19 rozp. MF PKPiR; art. 14/22/23/23a/23b/23f/24 PIT; art. 109 ust. 3 VAT; JPK_PKPIR art. 193a OrdPU",
    "_warnings": ["SUGGEST only; brak dowodu, kolumn, chronologii lub niezgodność uzgodnienia blokuje automatyczne księgowanie (AUTO_POST)."],
} {
    object.get(input, "pkpir_etap14_check", false) == true
}
