# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Direct CIT Rules (P70-P74)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły podatku dochodowego od osób prawnych (CIT):
#   - CIT estoński (20% efektywna, odroczenie)
#   - Mały podatnik (9%)
#   - Cienka kapitalizacja
#   - Standardowy CIT (19%)
#   - Rozliczenie strat
#
# package: tax.direct.cit
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.direct.cit

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.direct.cit.no_match",
    "package": "tax.direct.cit",
    "priority": 79
}

# ═══════════════════════════════════════════════════════════════════════════
# P72: cit_thin_capitalization (Priority 72 — FIRST in chain)
# ═══════════════════════════════════════════════════════════════════════════
# UWAGA: Reguła na pierwszym miejscu — thin cap dotyczy WSZYSTKICH form CIT
# (standard, small, estonian). Przed określeniem stawki!

# ── P72: cit_thin_capitalization ──────────────────────────────────────────────
# Cel biznesowy: Cienka kapitalizacja — wyłączenie z KUP nadmiernych odsetek
# Przesłanki: related_party + debt/equity > ratio + expense_type == INTEREST
# Podstawa prawna: Art. 15c CIT
# Priorytet: 72
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.direct.cit.thin_capitalization",
    "package": "tax.direct.cit",
    "priority": 72,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "non_deductible",
    "_warnings": ["Przekroczony limit cienkiej kapitalizacji (debt/equity > limit)"],
    "_legal_basis": "Art. 15c ustawy o CIT"
} {
    input.vendor.is_related_party == true
    input.vendor.debt_to_equity_ratio > object.get(input.thresholds.limits, "thin_cap_ratio", 3.0)
    input.invoice.expense_type == "INTEREST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P70: cit_estonian_effective (Priority 70)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P70: cit_estonian_effective ───────────────────────────────────────────────
# Cel biznesowy: Estoński CIT — efektywna 20% od wypłaconego zysku, odroczenie
# Przesłanki: tax_form == CIT_ESTONIAN
# Podstawa prawna: Rozdział 6b CIT (Art. 28c-28t)
# Priorytet: 70
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.cit.estonian",
    "package": "tax.direct.cit",
    "priority": 70,
    "vat_rate": "",
    "rounding_level": "",
    "cit_rate": helpers.get_rate("cit_estonian_effective", "0.20"),
    "tax_deferral": true,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Rozdział 6b ustawy o CIT (Art. 28c-28t)",
    "_warnings": ["Estoński CIT — podatek odroczony do momentu wypłaty zysku"]
} {
    input.company.tax_form == "CIT_ESTONIAN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P71: cit_small_taxpayer (Priority 71)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P71: cit_small_taxpayer ───────────────────────────────────────────────────
# Cel biznesowy: Mały podatnik CIT — stawka 9%
# Przesłanki: CIT_STANDARD + is_small_taxpayer
# Podstawa prawna: Art. 19 ust. 1a CIT
# Priorytet: 71
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.cit.small_taxpayer",
    "package": "tax.direct.cit",
    "priority": 71,
    "vat_rate": "",
    "rounding_level": "",
    "cit_rate": helpers.get_rate("cit_small", "0.09"),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 19 ust. 1a ustawy o CIT"
} {
    input.company.tax_form == "CIT_STANDARD"
    input.company.is_small_taxpayer == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P73: cit_standard_taxpayer (Priority 73)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P73: cit_standard_taxpayer ────────────────────────────────────────────────
# Cel biznesowy: Standardowy CIT — 19%
# Przesłanki: CIT_STANDARD + NOT small_taxpayer
# Podstawa prawna: Art. 19 ust. 1 CIT
# Priorytet: 73
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.cit.standard",
    "package": "tax.direct.cit",
    "priority": 73,
    "vat_rate": "",
    "rounding_level": "",
    "cit_rate": helpers.get_rate("cit_standard", "0.19"),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 19 ust. 1 ustawy o CIT"
} {
    input.company.tax_form == "CIT_STANDARD"
    input.company.is_small_taxpayer == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P74: cit_loss_carry_forward (Priority 74)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P74: cit_loss_carry_forward ───────────────────────────────────────────────
# Cel biznesowy: Rozliczenie straty podatkowej — max 50%/rok przez 5 lat
# Przesłanki: has_loss_carry_forward
# Podstawa prawna: Art. 7 ust. 5 CIT
# Priorytet: 74
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.cit.loss_carry_forward",
    "package": "tax.direct.cit",
    "priority": 74,
    "vat_rate": "",
    "rounding_level": "",
    "loss_carry_forward_available": true,
    "loss_carry_forward_limit_percent": 50,
    "max_years": 5,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 7 ust. 5 ustawy o CIT"
} {
    input.company.has_loss_carry_forward == true
}
