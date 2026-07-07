# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — CIT Deductions (P323)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły odliczeń CIT wykraczające poza standardowe KUP:
#   - P323: Ulga na złe długi CIT (wierzyciel) — Art. 18f CIT
#
# package: tax.cit_deductions
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.cit_deductions

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.cit_deductions.no_match",
    "package": "tax.cit_deductions",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P323: cit_bad_debt_relief_creditor (Priority 323)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Pomniejszenie podstawy opodatkowania CIT o wartość
#   wierzytelności nieściągalnych z perspektywy wierzyciela.
#   Analog P60 (VAT bad debt — dłużnik).
# Przesłanki: Wierzytelność wykazana jako przychód + brak zapłaty >90 dni
# Podstawa prawna: Art. 18f CIT

# ── P323: cit_bad_debt_relief_creditor ────────────────────────────────────────
# Cel biznesowy: Ulga CIT na złe długi — pomniejszenie podstawy opodatkowania
# Przesłanki: days_overdue > 90 + is_paid == false + was_recognized_as_revenue
# Podstawa prawna: Art. 18f CIT
# Priorytet: 323
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.cit_deductions.bad_debt_creditor",
    "package": "tax.cit_deductions",
    "priority": 323,
    "vat_rate": "",
    "rounding_level": "",
    "cit_deduction_eligible": true,
    "cit_deduction_amount": input.invoice.amount_net,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 18f CIT",
    "_warnings": ["Ulga na złe długi CIT — pomniejszenie podstawy opodatkowania"]
} {
    input.invoice.days_overdue > 90
    input.invoice.is_paid == false
    input.invoice.was_recognized_as_revenue == true
    is_eligible_cit_form(input.company.tax_form)
}

# ── Helper: eligible tax forms for CIT bad debt relief ────────────────────────
is_eligible_cit_form("CIT_STANDARD")
is_eligible_cit_form("CIT_ESTONIAN")
