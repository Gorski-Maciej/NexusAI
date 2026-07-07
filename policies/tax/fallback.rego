# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Fallback Rules (P100+)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły domyślne — stosowane gdy żadna konkretna reguła nie pasuje.
# Gwarantuje, że każda faktura otrzyma werdykt.
#
# package: tax.fallback
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.fallback

import data.tax.helpers

# ═══════════════════════════════════════════════════════════════════════════════
# P100: domestic_fallback (Priority 100)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Domyślna stawka VAT 23% dla Polski, gdy żadna konkretna
#   reguła nie określiła stawki
# Przesłanki: vendor.country == PL
# Podstawa prawna: Art. 41 ust. 1 VAT

# ── P100: domestic_fallback ───────────────────────────────────────────────────
# Cel biznesowy: Domestyczny fallback — 23% VAT dla Polski
# Przesłanki: vendor.country == PL
# Podstawa prawna: Art. 41 ust. 1 VAT
# Priorytet: 100
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.fallback.domestic_default",
    "package": "tax.fallback",
    "priority": 100,
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 1 VAT (stawka domyślna)"
} {
    input.vendor.country == "PL"
    input.invoice.transaction_date >= "2024-01-01"
}

# ── P200: no_match ────────────────────────────────────────────────────────────
# Cel biznesowy: Ostateczny fallback — gdy żadna reguła nie pasuje.
#   Zawsze na końcu łańcucha (najwyższy numer priorytetu).
# Priorytet: 200
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.fallback.no_match",
    "package": "tax.fallback",
    "priority": 200,
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 1 VAT (ostateczny fallback)",
    "_warnings": ["NO_MATCHING_RULE — zastosowano domyślną stawkę 23% VAT"]
} {
    true
}
