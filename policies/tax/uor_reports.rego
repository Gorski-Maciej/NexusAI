# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — UoR Reports (P327)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły sprawozdawczości finansowej wg UoR:
#   - P327: Klasyfikacja bilansowa (długoterminowe vs krótkoterminowe)
#          — Art. 35-44 UoR + Załącznik nr 1
#
# package: tax.uor_reports
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.uor_reports

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.uor_reports.no_match",
    "package": "tax.uor_reports",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P327: uor_financial_statement_structure (Priority 327)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Automatyczna klasyfikacja aktywów do odpowiednich pozycji
#   bilansu (długoterminowe vs krótkoterminowe) wg załącznika nr 1 do UoR.
# Przesłanki: Aktywo o okresie użytkowania >12 mies. i nie jest przeznaczone do obrotu
# Podstawa prawna: Art. 35-44 UoR + Załącznik nr 1

# ── P327: uor_financial_statement_structure ───────────────────────────────────
# Cel biznesowy: Klasyfikacja bilansowa — aktywa trwałe vs obrotowe
# Przesłanki: expected_usage_months > 12 + !is_held_for_trading
# Podstawa prawna: Art. 35-44 UoR, Załącznik nr 1
# Priorytet: 327
# ────────────────────────────────────────────────────────────────────────────────

# Aktywa trwałe (non-current)
decide := {
    "matched": true,
    "rule_id": "tax.uor_reports.bs_classification",
    "package": "tax.uor_reports",
    "priority": 327,
    "vat_rate": "",
    "rounding_level": "",
    "bs_category": "non_current_assets",
    "income_tax_qualification": "",
    "_legal_basis": "Art. 35-44 UoR, Załącznik nr 1"
} {
    input.asset.expected_usage_months > 12
    input.asset.is_held_for_trading == false
}

# Aktywa obrotowe (current)
else := {
    "matched": true,
    "rule_id": "tax.uor_reports.bs_classification",
    "package": "tax.uor_reports",
    "priority": 327,
    "vat_rate": "",
    "rounding_level": "",
    "bs_category": "current_assets",
    "income_tax_qualification": "",
    "_legal_basis": "Art. 35-44 UoR, Załącznik nr 1"
} {
    input.asset.expected_usage_months <= 12
    input.asset.is_held_for_trading == false
}
