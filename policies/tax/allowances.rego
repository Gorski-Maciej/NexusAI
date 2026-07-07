# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Tax Allowances (P80-P89)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły ulg podatkowych:
#   - Ulga B+R (100%/200% dla CBR)
#   - Ulga na prototyp (30%)
#   - IP Box (5%)
#   - Ulga na robotyzację (50%)
#   - Ulga na ekspansję
#   - Ulga termomodernizacyjna
#   - Ulga internetowa
#   - Ulga rehabilitacyjna
#   - Ulga abolicyjna
#   - Ulga dla pracujących seniorów
#
# package: tax.allowances
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.allowances

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.allowances.no_match",
    "package": "tax.allowances",
    "priority": 99
}

# ═══════════════════════════════════════════════════════════════════════════════
# P80: relief_rd (Priority 80)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P80: relief_rd ────────────────────────────────────────────────────────────
# Cel biznesowy: Ulga B+R — 100% kosztów (200% dla Centrum Badawczo-Rozwojowego)
# Przesłanki: has_rd_status == true
# Podstawa prawna: Art. 26e PIT, Art. 18d CIT
# Priorytet: 80
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.allowances.relief_rd",
    "package": "tax.allowances",
    "priority": 80,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "R_AND_D",
    "relief_percent": rd_relief_percent,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26e PIT, Art. 18d CIT"
} {
    input.company.has_rd_status == true
    rd_relief_percent := object.get(input.thresholds.bounds, "relief_rd_centrum", 200)
    input.company.rd_is_centrum == true
}

else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_rd_base",
    "package": "tax.allowances",
    "priority": 80,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "R_AND_D",
    "relief_percent": object.get(input.thresholds.bounds, "relief_rd_base", 100),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26e PIT, Art. 18d CIT"
} {
    input.company.has_rd_status == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P81: relief_prototype (Priority 81)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P81: relief_prototype ─────────────────────────────────────────────────────
# Cel biznesowy: Ulga na prototyp — 30% kosztów produkcji próbnej
# Podstawa prawna: Art. 26eb PIT, Art. 18db CIT
# Priorytet: 81
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_prototype",
    "package": "tax.allowances",
    "priority": 81,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "PROTOTYPE",
    "relief_percent": object.get(input.thresholds.bounds, "relief_prototype_percent", 30),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26eb PIT, Art. 18db CIT"
} {
    input.invoice.expense_type == "PROTOTYPE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P82: relief_ip_box (Priority 82)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P82: relief_ip_box ────────────────────────────────────────────────────────
# Cel biznesowy: IP Box — 5% stawka od dochodów z własności intelektualnej
# Przesłanki: tax_form == PIT_SCALE lub LINEAR lub CIT_STANDARD + IP income
# Podstawa prawna: Art. 30ca PIT, Art. 24d CIT
# Priorytet: 82
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_ip_box",
    "package": "tax.allowances",
    "priority": 82,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "IP_BOX",
    "pit_rate": helpers.get_rate("pit_ip_box", "0.05"),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 30ca PIT, Art. 24d CIT",
    "_warnings": ["IP Box — stawka 5% od kwalifikowanego dochodu z własności intelektualnej"]
} {
    input.invoice.expense_type == "IP_INCOME"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P83: relief_robotization (Priority 83)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P83: relief_robotization ──────────────────────────────────────────────────
# Cel biznesowy: Ulga na robotyzację — 50% kosztów
# Podstawa prawna: Art. 26gb PIT, Art. 38eb CIT
# Priorytet: 83
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_robotization",
    "package": "tax.allowances",
    "priority": 83,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "ROBOTIZATION",
    "relief_percent": object.get(input.thresholds.bounds, "relief_robotization_percent", 50),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26gb PIT, Art. 38eb CIT"
} {
    input.invoice.expense_type == "ROBOTIZATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P84: relief_expansion (Priority 84)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P84: relief_expansion ─────────────────────────────────────────────────────
# Cel biznesowy: Ulga na ekspansję — koszty targów i reklamy za granicą
# Podstawa prawna: Art. 26ec PIT, Art. 18dc CIT
# Priorytet: 84
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_expansion",
    "package": "tax.allowances",
    "priority": 84,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "EXPANSION",
    "relief_max": object.get(input.thresholds.bounds, "relief_expansion_max", 1000000),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26ec PIT, Art. 18dc CIT"
} {
    input.invoice.expense_type == "EXPANSION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P85: relief_thermomodernization (Priority 85)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P85: relief_thermomodernization ───────────────────────────────────────────
# Cel biznesowy: Ulga termomodernizacyjna — max 53 000 PLN
# Podstawa prawna: Art. 26h PIT
# Priorytet: 85
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_thermo",
    "package": "tax.allowances",
    "priority": 85,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "THERMOMODERNIZATION",
    "relief_max": object.get(input.thresholds.bounds, "relief_thermo_max", 53000),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26h ustawy o PIT"
} {
    input.invoice.expense_type == "THERMOMODERNIZATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P86: relief_internet (Priority 86)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P86: relief_internet ──────────────────────────────────────────────────────
# Cel biznesowy: Ulga internetowa — 760 PLN rocznie przez 2 lata
# Podstawa prawna: Art. 26 PIT
# Priorytet: 86
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_internet",
    "package": "tax.allowances",
    "priority": 86,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "INTERNET",
    "relief_max": object.get(input.thresholds.bounds, "relief_internet_max", 760),
    "internet_years_remaining": object.get(input.thresholds.bounds, "relief_internet_years", 2) - input.company.internet_years_used,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26 ustawy o PIT"
} {
    input.invoice.expense_type == "INTERNET"
    input.company.internet_years_used < object.get(input.thresholds.bounds, "relief_internet_years", 2)
}

# ═══════════════════════════════════════════════════════════════════════════════
# P87: relief_rehabilitation (Priority 87)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P87: relief_rehabilitation ────────────────────────────────────────────────
# Cel biznesowy: Ulga rehabilitacyjna
# Podstawa prawna: Art. 26 PIT
# Priorytet: 87
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_rehabilitation",
    "package": "tax.allowances",
    "priority": 87,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "REHABILITATION",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 26 ustawy o PIT"
} {
    input.invoice.expense_type == "REHABILITATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P88: relief_abolition (Priority 88)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P88: relief_abolition ─────────────────────────────────────────────────────
# Cel biznesowy: Ulga abolicyjna — zwolnienie z podatku od dochodów zagranicznych
# Podstawa prawna: Art. 27g PIT
# Priorytet: 88
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_abolition",
    "package": "tax.allowances",
    "priority": 88,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "ABOLITION",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 27g ustawy o PIT"
} {
    input.invoice.is_foreign_income == true
    input.company.tax_form == "PIT_SCALE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P89: relief_working_senior (Priority 89)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P89: relief_working_senior ────────────────────────────────────────────────
# Cel biznesowy: Ulga dla pracujących seniorów — zwolnienie dla pracujących po osiągnięciu wieku emerytalnego
# Przesłanki: is_working_senior
# Podstawa prawna: Art. 21 ust. 1 pkt 154 PIT
# Priorytet: 89
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.allowances.relief_working_senior",
    "package": "tax.allowances",
    "priority": 89,
    "vat_rate": "",
    "rounding_level": "",
    "relief_type": "WORKING_SENIOR",
    "pit_rate": "0.00",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 21 ust. 1 pkt 154 PIT",
    "_warnings": ["Ulga dla pracujących seniorów — całkowite zwolnienie z PIT"]
} {
    input.company.is_working_senior == true
}
