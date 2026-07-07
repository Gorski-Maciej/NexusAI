# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — GTU Code Mapping (P65)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Automatyczne mapowanie kategorii wydatku na kod GTU dla JPK_V7.
# Wykorzystuje współdzielone helpers z data.tax.helpers.
#
# Podstawa prawna: § 10 rozporządzenia w sprawie JPK_VAT
#
# package: tax.vat.gtu
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.vat.gtu

import data.tax.helpers

# ── Default: no GTU code ─────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.vat.gtu.no_match",
    "package": "tax.vat.gtu",
    "priority": 69
}

# ═══════════════════════════════════════════════════════════════════════════════
# P65: gtu_mapping_by_category (Priority 65)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Automatyczne przypisanie kodu GTU na podstawie kategorii
# Przesłanki: category_code ma zdefiniowane mapowanie w helpers
# Podstawa prawna: § 10 rozporządzenia w sprawie JPK_VAT

# ── P65: gtu_mapping_by_category ──────────────────────────────────────────────
# Cel biznesowy: Przypisz kod GTU na podstawie mapowania kategorii
# Przesłanki: helpers.category_to_gtu(code) zwraca niepusty string
# Podstawa prawna: § 10 rozporządzenia JPK_VAT
# Priorytet: 65
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.vat.gtu.mapping",
    "package": "tax.vat.gtu",
    "priority": 65,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": gtu,
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "§ 10 rozporządzenia w sprawie JPK_VAT"
} {
    gtu := helpers.category_to_gtu(input.invoice.category_code)
    gtu != ""
    input.vendor.country == "PL"
}
