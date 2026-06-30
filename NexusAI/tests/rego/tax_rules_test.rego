# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Rules — OPA Tests
# ═══════════════════════════════════════════════════════════════════════════════
# Uruchom: opa test tests/rego/ --verbose
# ═══════════════════════════════════════════════════════════════════════════════

package tax.rules.test

import data.tax.rules.decide

# ═══════════════════════════════════════════════════════════════════════════════
# SUBSTANTIVE RULES
# ═══════════════════════════════════════════════════════════════════════════════

# FUEL in PL → 23% VAT, GTU_04
test_fuel_pl_matches_23_vat {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.23"
    result.gtu_code == "GTU_04"
}

# FUEL in PL → priority 10 (not FC, not fallback)
test_fuel_pl_priority_10 {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    # Jeśli matched, nie ma _routing (to nie jest FC rule)
    # Sprawdź że vat_rate pochodzi z reguły merytorycznej
    result.vat_rate == "0.23"
    result.gtu_code == "GTU_04"
}

# FOOD in PL → 8% VAT
test_food_pl_matches_8_vat {
    result := decide with input as {
        "category_code": "FOOD",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.08"
    result.gtu_code == "GTU_07"
}

# BOOKS in PL → 5% VAT
test_books_pl_matches_5_vat {
    result := decide with input as {
        "category_code": "BOOKS",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.05"
}

# EDUCATION in PL → 0% VAT (exempt)
test_education_pl_matches_0_vat {
    result := decide with input as {
        "category_code": "EDUCATION",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.00"
}

# HEALTHCARE in PL → 0% VAT (exempt)
test_healthcare_pl_matches_0_vat {
    result := decide with input as {
        "category_code": "HEALTHCARE",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.00"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CROSS-BORDER RULES
# ═══════════════════════════════════════════════════════════════════════════════

# EU reverse charge (active VAT status) → 0% VAT
test_eu_reverse_charge_0_vat {
    result := decide with input as {
        "category_code": "IT_OFFICE",
        "vendor_country": "EU",
        "vendor_vat_status": "active",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.00"
    result.procedure == "VAT_REVERSE_CHARGE"
}

# EU but NOT active VAT status → fallback to domestic 23%
test_eu_not_active_falls_to_domestic {
    result := decide with input as {
        "category_code": "IT_OFFICE",
        "vendor_country": "EU",
        "vendor_vat_status": "unknown",
        "transaction_date": "2025-06-01"
    }
    # Nie matchuje EU reverse charge → spada do fallback
    # Ale nie ma vendor_country == "PL", więc nie matchuje fallback
    result.matched == false
    result.error == "NO_MATCHING_RULE"
}

# Non-EU import → 23% VAT with IMPORT procedure
test_non_eu_import_23_vat {
    result := decide with input as {
        "category_code": "IT_OFFICE",
        "vendor_country": "NON_EU",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.23"
    result.procedure == "IMPORT"
    result.gtu_code == "GTU_13"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DOMESTIC FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════

# Unknown category in PL → fallback to 23%
test_unknown_pl_falls_to_fallback {
    result := decide with input as {
        "category_code": "UNKNOWN",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    result.matched == true
    result.vat_rate == "0.23"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NO MATCH (fallback)
# ═══════════════════════════════════════════════════════════════════════════════

# Unknown category in non-PL, non-EU, non-NON_EU country → NO_MATCH
test_unknown_country_no_match {
    result := decide with input as {
        "category_code": "UNKNOWN",
        "vendor_country": "XX",
        "transaction_date": "2025-06-01"
    }
    result.matched == false
    result.error == "NO_MATCHING_RULE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# FIRST-MATCH-WINS VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

# FUEL should match substantive rule before fallback
test_fuel_before_fallback {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    # FUEL rule returns GTU_04, fallback doesn't
    result.gtu_code == "GTU_04"
}

# FC rule with low vat_rate should match BEFORE substantive rule
test_fc_before_substantive {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_vat_rate": 0.70,
        "fc_minimum": 0.90,
        "transaction_date": "2025-06-01"
    }
    # FC rule at priority 8 should match before FUEL at priority 10
    result._routing == "BLOCK_AND_ALERT"
}

# High confidence → no routing → falls to substantive rule
test_high_confidence_no_routing {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_vat_rate": 0.99,
        "fc_total_net": 0.99,
        "fc_minimum": 0.99,
        "transaction_date": "2025-06-01"
    }
    # All FC thresholds met → no routing → fuel rule matches
    result.matched == true
    result.vat_rate == "0.23"
    result.gtu_code == "GTU_04"
    # Verify no _routing field (should be absent)
    not result._routing
    not result._routing_reason
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEMPORALITY VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

# Transaction before 2024-01-01 → NO_MATCH (all rules valid_from >= 2024)
test_before_2024_no_match {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "transaction_date": "2023-06-01"
    }
    # All rules have valid_from >= "2024-01-01"
    result.matched == false
    result.error == "NO_MATCHING_RULE"
}

# Transaction exactly on 2024-01-01 → matches
test_on_2024_01_01_matches {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "transaction_date": "2024-01-01"
    }
    result.matched == true
    result.vat_rate == "0.23"
}

# ═══════════════════════════════════════════════════════════════════════════════
# FIELD CONFIDENCE — DETAILED TESTS
# ═══════════════════════════════════════════════════════════════════════════════

# CIT_STANDARD + low vat_rate → BLOCK_AND_ALERT
test_cit_standard_low_vat_rate {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_vat_rate": 0.70,
        "fc_minimum": 0.90,
        "transaction_date": "2025-06-01"
    }
    result._routing == "BLOCK_AND_ALERT"
}

# CIT_STANDARD + low total_net → BLOCK_AND_ALERT
test_cit_standard_low_total_net {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_total_net": 0.80,
        "fc_vat_rate": 0.99,
        "fc_minimum": 0.90,
        "transaction_date": "2025-06-01"
    }
    result._routing == "BLOCK_AND_ALERT"
}

# LUMP_SUM + low vat_rate → TRIAGE_QUEUE
test_lump_sum_low_vat_rate {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "LUMP_SUM",
        "fc_vat_rate": 0.80,
        "fc_minimum": 0.99,
        "transaction_date": "2025-06-01"
    }
    result._routing == "TRIAGE_QUEUE"
}

# Low NIP confidence → BLOCK_AND_ALERT (universal)
test_low_nip_confidence {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_vat_rate": 0.99,
        "fc_vendor_nip": 0.50,
        "fc_minimum": 0.90,
        "transaction_date": "2025-06-01"
    }
    result._routing == "BLOCK_AND_ALERT"
}

# Low category confidence → TRIAGE_QUEUE (universal)
test_low_category_confidence {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_vat_rate": 0.99,
        "fc_category_code": 0.50,
        "fc_minimum": 0.90,
        "transaction_date": "2025-06-01"
    }
    result._routing == "TRIAGE_QUEUE"
}

# Very low minimum (< 0.70) → TRIAGE_QUEUE (lowest threshold)
test_very_low_minimum {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "company_tax_form": "CIT_STANDARD",
        "fc_vat_rate": 0.99,
        "fc_minimum": 0.60,
        "transaction_date": "2025-06-01"
    }
    # All individual FC thresholds met, but fc_minimum < 0.70
    result._routing == "TRIAGE_QUEUE"
}

# No field confidence in input → no routing
test_no_fc_in_input {
    result := decide with input as {
        "category_code": "FUEL",
        "vendor_country": "PL",
        "transaction_date": "2025-06-01"
    }
    # No fc_* keys in input → FC rules don't match → fuel rule
    result.matched == true
    result.vat_rate == "0.23"
    not result._routing
}
