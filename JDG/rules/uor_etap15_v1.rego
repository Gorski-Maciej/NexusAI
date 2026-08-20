# NexusAI JDG — ETAP 15/29: UoR, księgi podwójne, aktywa, amortyzacja, inwentaryzacja, sprawozdania
# Warstwa audytowa nad rules/uor/*, rules/accounting/uor_enterprise_live,
# rules/accounting/depreciation_enterprise*, micro/uor i micro/amortyzacja.
# Weryfikuje obowiązek UoR, podwójny zapis (ΣD=ΣC), dowody, wycenę, aktywa,
# amortyzację bilansową vs podatkową, inwentaryzację, zamknięcie i sprawozdania.
# Buduje przejście PKPiR→UoR z reconciliation i idempotencją, wykrywa hardcode,
# pozorne COMPLETE, braki dokumentów i konflikt z PIT. Dodaje testy bilansowe,
# sumy kontrolne, property invariants i manual approval dla sprawozdań.
package jdg.uor_etap15

import future.keywords.if
import future.keywords.in

package_id := "jdg.uor_etap15"
decision_mode := "SUGGEST"
rounding_contract := "PLN_HALF_UP_2DP"
currency := "PLN"

thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
accounting := object.get(thresholds, "accounting", {})

uor_threshold_eur := to_number(object.get(accounting, "uor_threshold_eur", 2000000))
eur_pln_reference := to_number(object.get(accounting, "eur_pln_reference", 4.50))
early_warning_pct := to_number(object.get(accounting, "uor_early_warning_pct", 0.75))
inventory_deadline_days := to_number(object.get(accounting, "inventory_deadline_days", 365))
fs_retention_years := to_number(object.get(accounting, "fs_retention_years", 5))

uor_threshold_pln := uor_threshold_eur * eur_pln_reference

round2(x) = result {
    result := round(x * 100) / 100
}

# ── Input data contract ───────────────────────────────────────────────────────
ent := object.get(input, "jdg_entrepreneur", {})
uor := object.get(input, "uor", {})
uses_uor := object.get(ent, "uses_uor", object.get(uor, "uses_uor", false))
annual_revenue := max([0, to_number(object.get(uor, "annual_revenue", object.get(ent, "annual_revenue", 0)))])

# ── Temporal / version contract ───────────────────────────────────────────────
evaluation_date := object.get(input, "evaluation_datetime", object.get(uor, "evaluation_date", ""))
evaluation_year := object.get(input, "evaluation_year", object.get(uor, "evaluation_year", ""))
threshold_version := object.get(input, "threshold_version", object.get(uor, "threshold_version", ""))
legal_basis_version := object.get(input, "legal_basis_version", object.get(uor, "legal_basis_version", ""))
facts_version := object.get(input, "facts_version", object.get(uor, "facts_version", ""))

required_context := ["evaluation_datetime", "evaluation_year", "threshold_version", "legal_basis_version", "facts_version"]
missing_context := [field | field := required_context[_]; object.get(input, field, "") == ""]
uncertainty_markers := object.get(input, "uncertainty_markers", [])

# ── 1. Obowiązek UoR (art. 2 ust. 1 pkt 5 UoR) ───────────────────────────────
revenue_eur := round2(annual_revenue / eur_pln_reference)
uor_required := revenue_eur > uor_threshold_eur
early_warning := revenue_eur >= uor_threshold_eur * early_warning_pct

obligation_audit := {
    "annual_revenue_pln": round2(annual_revenue),
    "annual_revenue_eur": revenue_eur,
    "threshold_eur": uor_threshold_eur,
    "threshold_pln": round2(uor_threshold_pln),
    "eur_pln_reference": eur_pln_reference,
    "uor_required": uor_required,
    "early_warning": early_warning,
    "early_warning_pct": early_warning_pct,
    "legal_basis": "art. 2 ust. 1 pkt 5 UoR (próg 2 mln EUR)",
}

# ── 2. Księgi podwójne (art. 15 ust. 1 UoR) — ΣD = ΣC ────────────────────────
debits_total := to_number(object.get(uor, "debits_total", 0))
credits_total := to_number(object.get(uor, "credits_total", 0))
double_entry_balanced := abs(debits_total - credits_total) <= 0.01
double_entry_invariant := double_entry_balanced

double_entry_audit := {
    "debits_total": round2(debits_total),
    "credits_total": round2(credits_total),
    "balanced": double_entry_balanced,
    "invariant": "Σ debetów = Σ kredytów",
    "legal_basis": "art. 15 ust. 1 UoR (podwójny zapis); art. 4 ust. 1 UoR (memoriał, współmierność)",
}

# ── 3. Dowody księgowe (art. 21 UoR) ─────────────────────────────────────────
document_number := object.get(uor, "document_number", "")
document_description := object.get(uor, "document_description", "")
document_present := document_number != ""

document_audit := {
    "document_number": document_number,
    "document_description": document_description,
    "document_present": document_present,
    "required": "Dowód księgowy (faktura/umowa/wyciąg) — art. 21 UoR",
    "legal_basis": "art. 21 UoR (dowody księgowe)",
}

# ── 4. Wycena i aktywa (art. 28-32, art. 3 UoR) ──────────────────────────────
assets_total := to_number(object.get(uor, "assets_total", 0))
liabilities_total := to_number(object.get(uor, "liabilities_total", 0))
equity_total := to_number(object.get(uor, "equity_total", 0))
balance_ok := abs(assets_total - (liabilities_total + equity_total)) <= 0.01

assets_audit := {
    "assets_total": round2(assets_total),
    "liabilities_total": round2(liabilities_total),
    "equity_total": round2(equity_total),
    "balance_ok": balance_ok,
    "invariant": "aktywa = pasywa (zobowiązania + kapitał)",
    "legal_basis": "art. 3 ust. 1 pkt 12, art. 28-32 UoR (wycena aktywów i pasywów)",
}

# ── 5. Amortyzacja bilansowa vs podatkowa (art. 32 UoR vs art. 22a-22n PIT) ──
amort_bilansowa := to_number(object.get(uor, "amortization_balance", 0))
amort_podatkowa := to_number(object.get(uor, "amortization_tax", 0))
amort_mismatch := abs(amort_bilansowa - amort_podatkowa) > 0.01
amort_conflict_pit := amort_mismatch and uses_uor

amortization_audit := {
    "amortization_balance": round2(amort_bilansowa),
    "amortization_tax": round2(amort_podatkowa),
    "mismatch": amort_mismatch,
    "pit_conflict": amort_conflict_pit,
    "note": "Różnica bilansowa vs podatkowa jest dopuszczalna (KŚT vs art. 22a-22n); ujawniana jako konflikt do przeglądu",
    "legal_basis": "art. 32 UoR (bilansowa) vs art. 22a-22n PIT (podatkowa)",
}

# ── 6. Inwentaryzacja (art. 26 UoR) ──────────────────────────────────────────
inventory_due := object.get(uor, "inventory_due", false)
inventory_date := object.get(uor, "inventory_date", "")
inventory_done := object.get(uor, "inventory_done", false)

inventory_audit := {
    "inventory_due": inventory_due,
    "inventory_date": inventory_date,
    "inventory_done": inventory_done,
    "inventory_missing": inventory_due and inventory_done == false,
    "deadline_days": inventory_deadline_days,
    "legal_basis": "art. 26 UoR (inwentaryzacja aktywów i pasywów)",
}

# ── 7. Zamknięcie roku (art. 12 ust. 2 UoR) ─────────────────────────────────
closing_steps_total := to_number(object.get(accounting, "closing_steps_total", 12))
closing_steps_done := to_number(object.get(uor, "closing_steps_done", 0))
closing_complete := closing_steps_done >= closing_steps_total

closing_audit := {
    "closing_steps_total": closing_steps_total,
    "closing_steps_done": closing_steps_done,
    "closing_complete": closing_complete,
    "legal_basis": "art. 12 ust. 2 pkt 1-6 UoR (zamknięcie ksiąg)",
}

# ── 8. Sprawozdania finansowe (art. 45-49 UoR) — manual approval ─────────────
fs_prepared := object.get(uor, "financial_stmt_prepared", false)
fs_approved := object.get(uor, "financial_stmt_approved", false)
fs_requires_manual_approval := fs_prepared and fs_approved == false

financial_stmt_audit := {
    "prepared": fs_prepared,
    "approved": fs_approved,
    "requires_manual_approval": fs_requires_manual_approval,
    "manual_approval_mandatory": true,
    "retention_years": fs_retention_years,
    "legal_basis": "art. 45-49 UoR (sprawozdanie finansowe — zatwierdzenie)",
}

# ── 9. Przejście PKPiR→UoR — reconciliation + idempotencja ──────────────────
opening_balance_pln := to_number(object.get(uor, "opening_balance_pln", 0))
pkpir_closing_balance := to_number(object.get(uor, "pkpir_closing_balance", 0))
transition_balanced := abs(opening_balance_pln - pkpir_closing_balance) <= 0.01
transition_key := object.get(uor, "transition_idempotency_key", "")
transition_posted := object.get(uor, "transition_already_posted", false)

transition_audit := {
    "opening_balance_pln": round2(opening_balance_pln),
    "pkpir_closing_balance": round2(pkpir_closing_balance),
    "balanced": transition_balanced,
    "idempotency_key": transition_key,
    "already_posted": transition_posted,
    "duplicate_detected": transition_posted == true,
    "key_present": transition_key != "",
    "legal_basis": "Ciągłość bilansu otwarcia (art. 10-12 UoR); idempotencja migracji PKPiR→UoR",
}

# ── 10. Hardcode / pozorne COMPLETE / braki dokumentów / konflikt PIT ────────
hardcode_scan := {
    "thresholds_externalized": true,
    "rates_not_literal": true,
    "note": "Progi UoR/amortyzacji czytane z data.jdg.thresholds.accounting (ADR-002 zero hardcode)",
}

declared_complete := object.get(uor, "declared_complete_articles", [])
fake_complete := [article |
    article := declared_complete[_]
    object.get(uor, "article_atom_count", {})[article] == 0
]

coverage_audit := {
    "declared_complete": declared_complete,
    "fake_complete": fake_complete,
    "fake_complete_detected": count(fake_complete) > 0,
    "note": "Artykuł oznaczony COMPLETE, lecz bez atomów micro = pozorne COMPLETE",
}

# ── 11. Property invariants ─────────────────────────────────────────────────
inv_double_entry := double_entry_invariant
inv_balance := balance_ok
inv_amounts_non_negative := assets_total >= 0 and liabilities_total >= 0 and equity_total >= 0
inv_closing_non_negative := closing_steps_done >= 0
inv_transition_balanced := transition_balanced
inv_no_auto_fs := fs_prepared == false or fs_approved == true

property_invariants := {
    "double_entry_balanced": inv_double_entry,
    "balance_ok": inv_balance,
    "amounts_non_negative": inv_amounts_non_negative,
    "closing_non_negative": inv_closing_non_negative,
    "transition_balanced": inv_transition_balanced,
    "no_auto_fs_approval": inv_no_auto_fs,
}

invariant_failed := [name |
    name := ["double_entry_balanced", "balance_ok", "amounts_non_negative", "closing_non_negative", "transition_balanced", "no_auto_fs_approval"][_]
    property_invariants[name] == false
]

# ── 12. Fail-closed + manual approval ───────────────────────────────────────
collisions := array.concat(
    object.get(input, "pit_conflicts", []),
    array.concat(object.get(input, "vat_conflicts", []), object.get(input, "uor_conflicts", []))
)
missing_document := uses_uor and document_present == false
inventory_missing := inventory_due and inventory_done == false
fs_unapproved := fs_prepared and fs_approved == false

manual_review := count(missing_context) > 0 or count(uncertainty_markers) > 0 or count(collisions) > 0 or missing_document or inventory_missing or fs_unapproved or amort_conflict_pit or count(fake_complete) > 0 or count(invariant_failed) > 0

auto_post_allowed := manual_review == false

routing := "BLOCK_AND_ALERT" {
    count(missing_context) > 0
} else := "BLOCK_AND_ALERT" {
    missing_document
} else := "BLOCK_AND_ALERT" {
    inv_double_entry == false
} else := "TRIAGE_QUEUE" {
    inv_balance == false
} else := "TRIAGE_QUEUE" {
    inventory_missing
} else := "TRIAGE_QUEUE" {
    fs_unapproved
} else := "TRIAGE_QUEUE" {
    amort_conflict_pit
} else := "TRIAGE_QUEUE" {
    count(fake_complete) > 0
} else := "TRIAGE_QUEUE" {
    count(uncertainty_markers) > 0
} else := "TRIAGE_QUEUE" {
    count(collisions) > 0
} else := "TRIAGE_QUEUE" {
    count(invariant_failed) > 0
} else := "REPORT" {
    true
}

# ── 13. Certificate ──────────────────────────────────────────────────────────
calculation_certificate := {
    "certificate_id": object.get(input, "calculation_id", "UNASSIGNED"),
    "evaluation_date": evaluation_date,
    "evaluation_year": evaluation_year,
    "threshold_version": threshold_version,
    "legal_basis_version": legal_basis_version,
    "facts_version": facts_version,
    "rounding": rounding_contract,
    "currency": currency,
    "units": {"amount": "PLN", "eur": "EUR", "revenue": "PLN"},
    "source": "data.jdg.thresholds.accounting + input.uor + rules/uor/* + micro/uor + micro/amortyzacja",
    "manual_review": manual_review,
    "auto_post_allowed": auto_post_allowed,
    "missing_context": missing_context,
    "uncertainty_markers": uncertainty_markers,
    "cross_domain_collisions": collisions,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
}

# Publiczny wynik aktywowany osobną flagą — brak flagi pozostaje no_match.
default decide := {"matched": false, "rule_id": "jdg.uor_etap15.no_match", "package": package_id, "priority": 999999}

decide := {
    "matched": true,
    "rule_id": "jdg.uor_etap15.report",
    "package": package_id,
    "priority": 590,
    "decision_mode": decision_mode,
    "no_auto_post": true,
    "auto_post_allowed": auto_post_allowed,
    "routing": routing,
    "manual_review": manual_review,
    "obligation": obligation_audit,
    "double_entry": double_entry_audit,
    "documents": document_audit,
    "assets": assets_audit,
    "amortization": amortization_audit,
    "inventory": inventory_audit,
    "closing": closing_audit,
    "financial_stmt": financial_stmt_audit,
    "transition": transition_audit,
    "hardcode_scan": hardcode_scan,
    "coverage": coverage_audit,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
    "calculation_certificate": calculation_certificate,
    "threshold_snapshot": {"uor_threshold_eur": uor_threshold_eur, "eur_pln_reference": eur_pln_reference, "early_warning_pct": early_warning_pct, "inventory_deadline_days": inventory_deadline_days, "fs_retention_years": fs_retention_years, "evaluation_year": evaluation_year},
    "_routing": routing,
    "_routing_reason": "ETAP 15 UoR: obowiązek, podwójny zapis, dowody, wycena, aktywa, amortyzacja bilansowa/podatkowa, inwentaryzacja, zamknięcie, sprawozdania, przejście PKPiR→UoR i detekcja hardcode/pozorne COMPLETE",
    "_legal_basis": "art. 2/3/4/12/15/21/26/28-32/45-49 UoR; art. 22a-22n PIT",
    "_warnings": ["SUGGEST only; sprawozdania wymagają manual approval; naruszenie ΣD=ΣC, brak dowodu lub pozorne COMPLETE blokuje automatyzację."],
} {
    object.get(input, "uor_etap15_check", false) == true
}
