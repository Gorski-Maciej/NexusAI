# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Accounting Rules (P90-P94)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły rachunkowe:
#   - Amortyzacja liniowa
#   - Amortyzacja degresywna (wsp. 2.0)
#   - RMK — rozliczenia międzyokresowe kosztów
#   - Rewaluacja walutowa (FX)
#   - Wycena zapasów FIFO
#
# package: tax.accounting
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.accounting

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.accounting.no_match",
    "package": "tax.accounting",
    "priority": 99
}

# ═══════════════════════════════════════════════════════════════════════════════
# P90: acc_depreciation_linear (Priority 90)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P90: acc_depreciation_linear ──────────────────────────────────────────────
# Cel biznesowy: Amortyzacja liniowa środków trwałych
# Przesłanki: expense_type == FIXED_ASSET
# Podstawa prawna: Art. 32 ust. 1 UoR, KŚT
# Priorytet: 90
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.accounting.depreciation_linear",
    "package": "tax.accounting",
    "priority": 90,
    "vat_rate": "",
    "rounding_level": "",
    "depreciation_method": "LINEAR",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 32 ust. 1 UoR, KŚT"
} {
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.depreciation_method != "DEGRESSIVE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P91: acc_depreciation_degressive (Priority 91)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P91: acc_depreciation_degressive ──────────────────────────────────────────
# Cel biznesowy: Amortyzacja degresywna — wyższe odpisy w pierwszych latach
# Przesłanki: FIXED_ASSET + metoda degresywna + grupa KŚT 3-6
# Podstawa prawna: Art. 32 ust. 2 UoR
# Priorytet: 91
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.accounting.depreciation_degressive",
    "package": "tax.accounting",
    "priority": 91,
    "vat_rate": "",
    "rounding_level": "",
    "depreciation_method": "DEGRESSIVE",
    "depreciation_coefficient": 2.0,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 32 ust. 2 UoR"
} {
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.depreciation_method == "DEGRESSIVE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P92: acc_rmk_deferral (Priority 92)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P92: acc_rmk_deferral ─────────────────────────────────────────────────────
# Cel biznesowy: RMK — rozliczenia międzyokresowe kosztów (czynsze, ubezpieczenia)
# Przesłanki: is_prepaid + period_months > 1
# Podstawa prawna: Art. 39 UoR
# Priorytet: 92
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.accounting.rmk_deferral",
    "package": "tax.accounting",
    "priority": 92,
    "vat_rate": "",
    "rounding_level": "",
    "rmk_required": true,
    "rmk_months": input.invoice.period_months,
    "rmk_monthly_amount": input.invoice.amount_net / input.invoice.period_months,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 39 UoR"
} {
    input.invoice.is_prepaid == true
    input.invoice.period_months > 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# P93: acc_fx_revaluation (Priority 93)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P93: acc_fx_revaluation ───────────────────────────────────────────────────
# Cel biznesowy: Rewaluacja walutowa na dzień bilansowy
# Przesłanki: currency != PLN
# Podstawa prawna: Art. 30 UoR, IAS 21
# Priorytet: 93
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.accounting.fx_revaluation",
    "package": "tax.accounting",
    "priority": 93,
    "vat_rate": "",
    "rounding_level": "",
    "fx_revaluation_required": true,
    "fx_currency": input.invoice.currency,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 30 UoR, IAS 21"
} {
    input.invoice.currency != "PLN"
    input.invoice.is_paid == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P94: acc_fifo_inventory (Priority 94)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P94: acc_fifo_inventory ───────────────────────────────────────────────────
# Cel biznesowy: Wycena zapasów metodą FIFO
# Przesłanki: expense_type == INVENTORY
# Podstawa prawna: Art. 28 ust. 1 UoR, IAS 2
# Priorytet: 94
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.accounting.fifo_inventory",
    "package": "tax.accounting",
    "priority": 94,
    "vat_rate": "",
    "rounding_level": "",
    "inventory_method": "FIFO",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 28 ust. 1 UoR, IAS 2"
} {
    input.invoice.expense_type == "INVENTORY"
}
