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

# ── MPP-sensitive categories (załącznik nr 15 do ustawy o VAT) ──────────────────
# Pomocnicze reguły dla P25: split_payment_mandatory
mpp_sensitive_category { input.category_code == "FUEL" }
mpp_sensitive_category { input.category_code == "STEEL" }
mpp_sensitive_category { input.category_code == "ELECTRONICS" }
mpp_sensitive_category { input.category_code == "CONSTRUCTION" }
mpp_sensitive_category { input.category_code == "SCRAP" }
mpp_sensitive_category { input.category_code == "ALCOHOL" }

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
# COMPLIANCE RULES (Priority 9)
# ═══════════════════════════════════════════════════════════════════════════════
# Reguły zgodności dokumentacyjnej i prawnej:
#   - Biała Lista MF (Art. 96b VAT, Art. 117ba Ordynacji podatkowej)
#   - Split Payment / MPP (Art. 108a VAT)
#   - Limit płatności gotówkowych (Art. 22p PIT, Art. 15d CIT)

# P20: Biała Lista — kontrahent nie figuruje na WL >15k PLN → BLOCK_AND_ALERT
# Podstawa prawna: Art. 96b VAT, Art. 117ba Ordynacji podatkowej
else = {
    "matched": true,
    "rule_id": "tax.compliance.whitelist_missing",
    "package": "tax.compliance",
    "priority": 9,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "income_tax_qualification": "deductible_full",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak kontrahenta na Białej Liście MF dla przelewu >15 000 PLN",
    "_legal_basis": "Art. 96b VAT, Art. 117ba Ordynacji podatkowej",
    "_warnings": ["Brak na Białej Liście — odpowiedzialność solidarna"]
} {
    input.amount_gross >= 15000
    input.on_whitelist == false
    input.transaction_date >= "2024-01-01"

# P21: Biała Lista — rachunek bankowy niezgodny z WL >15k PLN → BLOCK_AND_ALERT
# Podstawa prawna: Art. 117ba § 1 Ordynacji podatkowej
} else = {
    "matched": true,
    "rule_id": "tax.compliance.whitelist_account_mismatch",
    "package": "tax.compliance",
    "priority": 9,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "income_tax_qualification": "deductible_full",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Rachunek kontrahenta niezgodny z Białą Listą MF",
    "_legal_basis": "Art. 117ba § 1 Ordynacji podatkowej",
    "_warnings": ["Rachunek niezgodny z Białą Listą — odpowiedzialność solidarna"]
} {
    input.amount_gross >= 15000
    input.account_on_whitelist == false
    input.on_whitelist == true
    input.transaction_date >= "2024-01-01"

# P25: Split Payment / MPP obowiązkowy dla towarów wrażliwych >15k PLN
# Podstawa prawna: Art. 108a VAT (załącznik nr 15)
} else = {
    "matched": true,
    "rule_id": "tax.compliance.split_payment_mandatory",
    "package": "tax.compliance",
    "priority": 9,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "income_tax_qualification": "deductible_full",
    "mpp_required": true,
    "_legal_basis": "Art. 108a ustawy o VAT",
    "_warnings": ["Obowiązkowy mechanizm podzielonej płatności (MPP)"]
} {
    input.amount_gross >= 15000
    mpp_sensitive_category
    input.vendor_country == "PL"
    input.transaction_date >= "2024-01-01"

# P35: Płatność gotówkowa >15k PLN → brak KUP
# Podstawa prawna: Art. 22p PIT, Art. 15d CIT
} else = {
    "matched": true,
    "rule_id": "tax.compliance.cash_over_limit",
    "package": "tax.compliance",
    "priority": 9,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "income_tax_qualification": "non_deductible",
    "_legal_basis": "Art. 22p PIT, Art. 15d CIT",
    "_warnings": ["Płatność gotówkowa powyżej 15 000 PLN — brak KUP"]
} {
    input.is_cash_payment == true
    input.amount_gross >= 15000
    input.transaction_date >= "2024-01-01"
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
# Podstawa prawna: Art. 17 ust. 1 pkt 3 VAT
else = {
    "matched": true,
    "rule_id": "tax.crossborder.eu_reverse_charge",
    "package": "tax.crossborder",
    "priority": 50,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "GTU_12",
    "procedure": "VAT_REVERSE_CHARGE",
    "_legal_basis": "Art. 17 ust. 1 pkt 3 VAT"
} {
    input.vendor_country == "EU"
    input.vendor_vat_status == "active"
    input.transaction_date >= "2024-01-01"
}

# Non-EU import
else = {
    "matched": true,
    "rule_id": "tax.crossborder.import_non_eu",
    "package": "tax.crossborder",
    "priority": 50,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_13",
    "procedure": "IMPORT",
    "_legal_basis": "Art. 17 ust. 1 pkt 1 VAT"
} {
    input.vendor_country == "NON_EU"
    input.transaction_date >= "2024-01-01"
}

# Export goods (0% VAT) — eksport towarów poza UE
# Podstawa prawna: Art. 41 ust. 4-11 VAT
else = {
    "matched": true,
    "rule_id": "tax.crossborder.export_goods",
    "package": "tax.crossborder",
    "priority": 50,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "EXPORT",
    "_legal_basis": "Art. 41 ust. 4-11 ustawy o VAT"
} {
    input.vendor_country == "NON_EU"
    input.procedure == "EXPORT"
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
