# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Direct PIT Rules (P74-P79)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły podatku dochodowego od osób fizycznych (PIT):
#   - Ryczałt wg PKWiU
#   - Skala podatkowa (12%/32%)
#   - Podatek liniowy (19%)
#   - Wspólne rozliczenie małżonków
#   - Ulga dla młodych (<26 lat)
#   - Ulga na powrót (4 lata)
#   - Ulga dla rodzin 4+ dzieci
#
# package: tax.direct.pit
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.direct.pit

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.direct.pit.no_match",
    "package": "tax.direct.pit",
    "priority": 89
}

# ═══════════════════════════════════════════════════════════════════════════════
# P74: pit_lump_sum_rate (Priority 74)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P74: pit_lump_sum_rate ────────────────────────────────────────────────────
# Cel biznesowy: Stawka ryczałtu wg PKWiU (2%-17%)
# Przesłanki: tax_form == LUMP_SUM
# Podstawa prawna: Art. 12 ustawy o ryczałcie
# Priorytet: 74
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.direct.pit.lump_sum",
    "package": "tax.direct.pit",
    "priority": 74,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": pit_lump_rate,
    "pit_regime": "LUMP_SUM",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 12 ustawy o ryczałcie ewidencjonowanym"
} {
    input.company.tax_form == "LUMP_SUM"
    pit_lump_rate := helpers.get_rate(lump_sum_key(input.invoice.pkwiu_code), "0.12")
}

# Pomocnicze: mapowanie PKWiU → stawka ryczałtu
lump_sum_key(pkwiu) = "lump_sum_pkwiu_08_5" {
    pkwiu_prefix_match(pkwiu, "62")
} else = "lump_sum_pkwiu_12" {
    pkwiu_prefix_match(pkwiu, "41")
} else = "lump_sum_default" {
    true
}

pkwiu_prefix_match(pkwiu, prefix) {
    startswith(pkwiu, prefix)
}

# ═══════════════════════════════════════════════════════════════════════════════
# P75: pit_tax_scale (Priority 75)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P75: pit_tax_scale ────────────────────────────────────────────────────────
# Cel biznesowy: Skala podatkowa 12%/32%
# Przesłanki: tax_form == PIT_SCALE
# Podstawa prawna: Art. 27 ust. 1 PIT
# Priorytet: 75
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.pit.tax_scale_low",
    "package": "tax.direct.pit",
    "priority": 75,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": helpers.get_rate("pit_scale_low", "0.12"),
    "pit_bracket_threshold": object.get(input.thresholds.bounds, "pit_scale_threshold", 120000),
    "pit_tax_free_amount": object.get(input.thresholds.bounds, "pit_tax_free_amount", 30000),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 27 ust. 1 PIT"
} {
    input.company.tax_form == "PIT_SCALE"
}

# ── P75b: pit_linear ──────────────────────────────────────────────────────────
# Cel biznesowy: Podatek liniowy 19% dla przedsiębiorców
# Przesłanki: tax_form == LINEAR
# Podstawa prawna: Art. 30c PIT
# Priorytet: 75
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.pit.linear",
    "package": "tax.direct.pit",
    "priority": 75,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": helpers.get_rate("pit_linear", "0.19"),
    "pit_regime": "LINEAR",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 30c ustawy o PIT"
} {
    input.company.tax_form == "LINEAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P76: pit_joint_filing (Priority 76)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P76: pit_joint_filing ─────────────────────────────────────────────────────
# Cel biznesowy: Wspólne rozliczenie małżonków → efektywny próg × 2
# Przesłanki: PIT_SCALE + joint_filing
# Podstawa prawna: Art. 6 ust. 2 PIT
# Priorytet: 76
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.pit.joint_filing",
    "package": "tax.direct.pit",
    "priority": 76,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": helpers.get_rate("pit_scale_low", "0.12"),
    "pit_bracket_threshold": object.get(input.thresholds.bounds, "pit_scale_threshold", 120000) * 2,
    "joint_filing_active": true,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 6 ust. 2 ustawy o PIT"
} {
    input.company.tax_form == "PIT_SCALE"
    input.company.joint_filing == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P77-P79: Ulgi osobiste (Priority 77-79)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P77: pit_young_exemption ──────────────────────────────────────────────────
# Cel biznesowy: Ulga dla młodych — zwolnienie z PIT do 26. roku życia
# Przesłanki: taxpayer_age <= 26 AND age > 0
# Podstawa prawna: Art. 21 ust. 1 pkt 148 PIT
# Priorytet: 77
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.pit.young_exemption",
    "package": "tax.direct.pit",
    "priority": 77,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": "0.00",
    "pit_exemption": "YOUNG",
    "pit_exemption_limit": object.get(input.thresholds.bounds, "pit_young_exemption_limit", 85528),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
    "_warnings": ["Ulga dla młodych — zwolnienie z PIT do 26 lat"]
} {
    input.company.taxpayer_age <= 26
    input.company.taxpayer_age > 0
}

# ── P78: pit_return_exemption ─────────────────────────────────────────────────
# Cel biznesowy: Ulga na powrót — 4 lata zwolnienia z PIT po emigracji
# Przesłanki: return_from_emigration AND return_years_used < 4
# Podstawa prawna: Art. 21 ust. 1 pkt 152 PIT
# Priorytet: 78
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.pit.return_exemption",
    "package": "tax.direct.pit",
    "priority": 78,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": "0.00",
    "pit_exemption": "RETURN",
    "pit_exemption_limit": object.get(input.thresholds.bounds, "pit_return_exemption_limit", 85528),
    "return_years_remaining": 4 - input.company.return_years_used,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 21 ust. 1 pkt 152 PIT",
    "_warnings": ["Ulga na powrót — zwolnienie z PIT po emigracji"]
} {
    input.company.return_from_emigration == true
    input.company.return_years_used < 4
}

# ── P79: pit_family_4plus ─────────────────────────────────────────────────────
# Cel biznesowy: Ulga dla rodzin 4+ dzieci — zwolnienie z PIT
# Przesłanki: children_count >= 4
# Podstawa prawna: Art. 21 ust. 1 pkt 153 PIT
# Priorytet: 79
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.direct.pit.family_4plus",
    "package": "tax.direct.pit",
    "priority": 79,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": "0.00",
    "pit_exemption": "FAMILY_4PLUS",
    "pit_exemption_limit": object.get(input.thresholds.bounds, "pit_family_4plus_limit", 85528),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT",
    "_warnings": ["Ulga dla rodzin 4+ dzieci — całkowite zwolnienie z PIT"]
} {
    input.company.children_count >= 4
}
