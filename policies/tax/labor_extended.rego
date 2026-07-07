# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Labor Extended (P328)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły prawa pracy rozszerzające istniejące P192-P194, P285-P287:
#   - P328: Badania BHP i medycyna pracy jako KUP — Art. 229 KP
#
# package: tax.labor_extended
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.labor_extended

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.labor_extended.no_match",
    "package": "tax.labor_extended",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P328: labor_ohs_medical_exams_kup (Priority 328)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Prawidłowa kwalifikacja kosztów badań BHP i medycyny pracy
#   jako KUP (100%). Obowiązkowe z mocy prawa, więc nie ma wątpliwości
#   co do związku z przychodem.
# Przesłanki: Faktura za badania lekarskie/medycynę pracy dla pracownika
# Podstawa prawna: Art. 229 KP w zw. z Art. 15 CIT, Art. 22 PIT

# ── P328: labor_ohs_medical_exams_kup ─────────────────────────────────────────
# Cel biznesowy: Badania BHP/medycyna pracy — 100% KUP jako koszt obowiązkowy
# Przesłanki: category == MEDICAL_EXAMS_OHS + beneficiary_type == employee
# Podstawa prawna: Art. 229 KP, Art. 15 CIT
# Priorytet: 328
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.labor_extended.ohs_medical_exams",
    "package": "tax.labor_extended",
    "priority": 328,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 229 KP, Art. 15 CIT",
    "_warnings": ["Badania BHP/medycyna pracy — 100% KUP jako koszt obowiązkowy"]
} {
    input.invoice.category_code == "MEDICAL_EXAMS_OHS"
    input.invoice.beneficiary_type == "employee"
}
