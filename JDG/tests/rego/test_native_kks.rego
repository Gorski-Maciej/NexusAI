# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: KKS (PROMPT 08)
# Package: jdg.kks
# Rules tested: voluntary_disclosure, empty_invoice, unreliable_vat,
# tax_evasion, statute_of_limitations, repeat_offense, penalty_calc,
# minor_significance, obstruction
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_kks
import data.jdg.kks

# ── Test 1: Czynny żal — eligible (brak postępowania) ────────────────────────
test_positive_voluntary_disclosure_eligible {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {
            "kks_voluntary_disclosure_filed": false,
            "kks_proceedings_started": false
        },
        "invoice": {
            "kks_flag": true
        }
    }
    result.rule_id == "jdg.kks.voluntary_disclosure_eligible"
    result.kks_immunity_possible == true
}

# ── Test 2: Czynny żal — NIEmożliwy (postępowanie wszczęte) ──────────────────
test_positive_voluntary_disclosure_deadline_breach {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {
            "kks_proceedings_started": true
        },
        "invoice": {"kks_flag": true}
    }
    result.rule_id == "jdg.kks.voluntary_disclosure_deadline_breach"
    result.kks_immunity_possible == false
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test 3: Pusta faktura — Art. 62 §2 ────────────────────────────────────────
test_positive_empty_invoice {
    result := data.jdg.kks.decide with input as {
        "invoice": {
            "is_empty_invoice": true,
            "amount_gross": 50000.0
        }
    }
    result.rule_id == "jdg.kks.empty_invoice_art62"
    result.kks_penalty_severity == "CRITICAL"
    result.kks_max_imprisonment_years == 25
}

# ── Test 4: Nierzetelna ewidencja VAT — Art. 57 ───────────────────────────────
test_positive_unreliable_vat {
    result := data.jdg.kks.decide with input as {
        "invoice": {"vat_records_unreliable": true}
    }
    result.rule_id == "jdg.kks.unreliable_vat_evidence_art57"
    result.kks_offense_type == "UNRELIABLE_VAT"
}

# ── Test 5: Niezłożenie deklaracji — Art. 77 ─────────────────────────────────
test_positive_declaration_missing {
    result := data.jdg.kks.decide with input as {
        "invoice": {"declaration_missing": true}
    }
    result.rule_id == "jdg.kks.tax_return_non_filing_art77"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test 6: Niezapłacenie podatku — Art. 79 (>500 PLN) ───────────────────────
test_positive_tax_unpaid {
    result := data.jdg.kks.decide with input as {
        "invoice": {"tax_arrears_pln": 15000.0}
    }
    result.rule_id == "jdg.kks.non_payment_of_tax_art79"
    result.kks_offense_type == "TAX_UNPAID"
}

# ── Test 7: Uchylanie od opodatkowania — Art. 54 ─────────────────────────────
test_positive_tax_evasion {
    result := data.jdg.kks.decide with input as {
        "invoice": {
            "tax_declaration_type": "VAT-7",
            "declaration_data_falsified": true,
            "tax_shortfall_pln": 50000.0
        }
    }
    result.rule_id == "jdg.kks.tax_evasion_false_declaration"
    result.kks_penalty_severity == "CRITICAL"
    result.kks_imprisonment_possible == true
}

# ── Test 8: Przedawnienie karalności — Art. 44 ───────────────────────────────
test_positive_statute_barred {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {"kks_time_barred": true}
    }
    result.rule_id == "jdg.kks.statute_of_limitations_art44"
    result.kks_crime_statute_years == 5
}

# ── Test 9: Recydywa — Art. 19 §3 ────────────────────────────────────────────
test_positive_repeat_offense {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {
            "kks_incidents_60m": 4
        }
    }
    result.rule_id == "jdg.kks.repeat_offense_aggravating"
    result.kks_recidivist == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test 10: Znikoma szkodliwość — Art. 18 ───────────────────────────────────
test_positive_minor_significance {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {
            "kks_voluntary_disclosure_filed": true
        },
        "invoice": {"kks_tax_shortfall": 2000.0}
    }
    result.rule_id == "jdg.kks.minor_significance"
    result.kks_minor_significance == true
}

# ── Test 11: Czynny żal — wpłata należności ──────────────────────────────────
test_positive_disclosure_payment {
    result := data.jdg.kks.decide with input as {
        "invoice": {"kks_tax_shortfall": 10000.0}
    }
    result.rule_id == "jdg.kks.voluntary_disclosure_payment"
    result.kks_amount_due == 10000.0
}

# ── Test 12: Nierzetelne PKPiR — Art. 56 ─────────────────────────────────────
test_positive_unreliable_books {
    result := data.jdg.kks.decide with input as {
        "invoice": {"books_entries_falsified": true}
    }
    result.rule_id == "jdg.kks.unreliable_pkpir_art56"
    result.kks_max_daily_rates == 240
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test 13: Wielu czynów — czynny żal ───────────────────────────────────────
test_positive_multiple_offenses_disclosure {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {
            "kks_offenses_count": 3,
            "kks_voluntary_disclosure_filed": true
        }
    }
    result.rule_id == "jdg.kks.voluntary_disclosure_multiple_offenses"
    result.kks_disclosed_count == 3
}

# ── Test 14: Nadzwyczajne złagodzenie — Art. 17 ──────────────────────────────
test_positive_extraordinary_mitigation {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {"kks_extraordinary_mitigation": true}
    }
    result.rule_id == "jdg.kks.extraordinary_mitigation"
    result.kks_extraordinary_mitigation_possible == true
}

# ── Test 15: Zawieszenie przedawnienia — Art. 44 §5 ───────────────────────────
test_positive_limitation_suspension {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {
            "kks_proceedings_started": true,
            "kks_proceedings_type": "CRIMINAL"
        }
    }
    result.rule_id == "jdg.kks.statute_limitation_suspension"
    result.kks_limitation_suspended == true
}

# ── Test 16: Kalkulacja kary — Art. 23 + 48 ──────────────────────────────────
test_positive_penalty_calculation {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {"kks_penalty_calculation_needed": true}
    }
    result.rule_id == "jdg.kks.fiscal_penalty_calculation"
}

# ── Test 17: Utrudnianie kontroli — Art. 69 ───────────────────────────────────
test_positive_obstruction_of_audit {
    result := data.jdg.kks.decide with input as {
        "jdg_entrepreneur": {"kks_obstruction_of_proceedings": true}
    }
    result.rule_id == "jdg.kks.obstruction_of_tax_audit_art69"
    result.kks_offense_type == "OBSTRUCTION"
}

# ── Test 18: no_match — pusty input ───────────────────────────────────────────
test_no_match_kks {
    result := data.jdg.kks.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.kks.no_match"
}