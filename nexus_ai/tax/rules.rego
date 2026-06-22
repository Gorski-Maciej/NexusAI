# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Rules — OPA Rego Policy
# ═══════════════════════════════════════════════════════════════════════════════
#
# Generowane automatycznie przez OpaPolicyGenerator z DuckDB RuleStore.
# Reguły first-match-wins (else chain) z temporalnością i field confidence.
#
# Zgodne z aa3fvcx.txt:
#   - First-match-wins: pierwsza pasująca reguła wygrywa
#   - Temporalność: valid_from / valid_to jako klauzule
#   - Field confidence: routing (BLOCK_AND_ALERT / TRIAGE_QUEUE)
#   - Fallback: default decide = NO_MATCH
#
# package: tax.rules
# rule:     decide
# ═══════════════════════════════════════════════════════════════════════════════

package tax.rules

# ── Default: no matching rule ─────────────────────────────────────────────────
default decide = {
    "matched": false,
    "error": "NO_MATCHING_RULE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# FIELD CONFIDENCE RULES (Priority 8)
# ═══════════════════════════════════════════════════════════════════════════════
# Najwyższy priorytet — sprawdzane przed regułami merytorycznymi.
# Jeśli confidence danego pola jest poniżej progu, faktura jest kierowana
# do routingu (BLOCK_AND_ALERT lub TRIAGE_QUEUE) zamiast automatycznego
# księgowania.

# CIT_STANDARD: VAT rate confidence < 0.98 → BLOCK_AND_ALERT
decide = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CIT_STANDARD: VAT rate confidence below threshold 0.98"
} {
    input.company_tax_form == "CIT_STANDARD"
    input.fc_vat_rate < 0.98
    input.fc_vat_rate > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CIT_STANDARD: net amount confidence below threshold 0.95"
} {
    input.company_tax_form == "CIT_STANDARD"
    input.fc_total_net < 0.95
    input.fc_total_net > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CIT_STANDARD: minimum confidence below threshold 0.85"
} {
    input.company_tax_form == "CIT_STANDARD"
    input.fc_minimum < 0.85
    input.fc_minimum > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CIT_ESTONIAN: VAT rate confidence below threshold 0.95"
} {
    input.company_tax_form == "CIT_ESTONIAN"
    input.fc_vat_rate < 0.95
    input.fc_vat_rate > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "LINEAR: minimum confidence below threshold 0.85"
} {
    input.company_tax_form == "LINEAR"
    input.fc_minimum < 0.85
    input.fc_minimum > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "LUMP_SUM: VAT rate confidence below threshold 0.95"
} {
    input.company_tax_form == "LUMP_SUM"
    input.fc_vat_rate < 0.95
    input.fc_vat_rate > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "LUMP_SUM: net amount confidence below threshold 0.60"
} {
    input.company_tax_form == "LUMP_SUM"
    input.fc_total_net < 0.60
    input.fc_total_net > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MIXED_AUTO: minimum confidence below threshold 0.90"
} {
    input.category_code == "MIXED_AUTO"
    input.fc_minimum < 0.90
    input.fc_minimum > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "REPRESENTATION: minimum confidence below threshold 0.95"
} {
    input.category_code == "REPRESENTATION"
    input.fc_minimum < 0.95
    input.fc_minimum > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Unreliable NIP confidence"
} {
    input.fc_vendor_nip < 0.80
    input.fc_vendor_nip > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Low category confidence"
} {
    input.fc_category_code < 0.80
    input.fc_category_code > 0
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Multiple low-confidence fields detected"
} {
    input.fc_minimum < 0.70
    input.fc_minimum > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# SUBSTANTIVE TAX RULES (Priority 10)
# ═══════════════════════════════════════════════════════════════════════════════
# Konkretne reguły podatkowe dla różnych kategorii i krajów.

# FUEL in PL → 23% VAT, GTU_04
else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_04"
} {
    input.category_code == "FUEL"
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
} else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_01"
} {
    input.category_code == "IT_OFFICE"
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
} else = {
    "matched": true,
    "vat_rate": "0.08",
    "rounding_level": "position",
    "gtu_code": "GTU_07"
} {
    input.category_code == "FOOD"
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
} else = {
    "matched": true,
    "vat_rate": "0.05",
    "rounding_level": "position",
    "gtu_code": "GTU_01"
} {
    input.category_code == "BOOKS"
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
} else = {
    "matched": true,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": ""
} {
    lower(input.category_code) == "education"
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
} else = {
    "matched": true,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": ""
} {
    lower(input.category_code) == "healthcare"
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CROSS-BORDER RULES (Priority 50)
# ═══════════════════════════════════════════════════════════════════════════════

# EU reverse charge (active VAT status)
else = {
    "matched": true,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "GTU_12",
    "procedure": "VAT_REVERSE_CHARGE"
} {
    input.vendor_country == "EU"
    input.vendor_vat_status == "active"
    input.transaction_date >= "2024-01-01"
}

# Non-EU import
else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_13",
    "procedure": "IMPORT"
} {
    input.vendor_country == "NON_EU"
    input.transaction_date >= "2024-01-01"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DOMESTIC FALLBACK (Priority 100)
# ═══════════════════════════════════════════════════════════════════════════════
# Domyślna stawka dla Polski gdy żadna konkretna reguła nie pasuje.

else = {
    "matched": true,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": ""
} {
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"
}
