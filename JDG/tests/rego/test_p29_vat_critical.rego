# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: VAT Critical Rules (P29)
# ═══════════════════════════════════════════════════════════════════════════════
# Testy natywne OPA dla plan26_critical.rego
# Uruchom: opa test JDG/tests/rego/test_p29_vat_critical.rego -v
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.plan26_critical_test

import data.jdg.vat.plan26_critical

# ── Test: MPP Threshold Precision ───────────────────────────────────────────

test_mpp_boundary_14999_99 if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "STEEL",
            "amount_gross": 14999.99,
            "amount_net": 13043.47
        }
    }
    # Kwota 14999.99 — poniżej progu, MPP NIE jest wymagany
    result.matched == true
}

test_mpp_boundary_15000_00 if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "STEEL",
            "amount_gross": 15000.00,
            "amount_net": 12195.12
        }
    }
    result.matched == true
    result.mpp_boundary_detected == true
}

test_mpp_boundary_15000_01 if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "STEEL",
            "amount_gross": 15000.01,
            "amount_net": 12195.13
        }
    }
    result.matched == true
    result.mpp_boundary_detected == true
}

test_mpp_not_sensitive_category if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "OFFICE_SUPPLIES",
            "amount_gross": 20000.00
        }
    }
    # NIE jest wrażliwa kategoria — MPP nie dotyczy
    result.mpp_boundary_detected == false { result.matched == true }
}

# ── Test: RO Construction 500k ───────────────────────────────────────────────

test_ro_construction_below_500k if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "CONSTRUCTION_SUBCONTRACTING",
            "amount_net": 490000,
            "reverse_charge_applies": false
        },
        "construction_subcontractor_total_net": 490000,
        "vendor": {"country": "PL"}
    }
    # Poniżej 500k — brak RO
    result.matched == true { result.procedure == "RO_CONSTRUCTION_500K_CHECK" }
}

test_ro_construction_above_500k if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "CONSTRUCTION_SUBCONTRACTING",
            "amount_net": 510000,
            "reverse_charge_applies": false
        },
        "construction_subcontractor_total_net": 510000,
        "vendor": {"country": "PL"}
    }
    result.ro_threshold_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

test_ro_construction_above_500k_with_ro_applied if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "CONSTRUCTION_SUBCONTRACTING",
            "amount_net": 520000,
            "reverse_charge_applies": true
        },
        "construction_subcontractor_total_net": 520000,
        "vendor": {"country": "PL"}
    }
    result.ro_threshold_exceeded == true
    result._routing == "TRIAGE_QUEUE"
}

# ── Test: Car VAT Deduction Limit ───────────────────────────────────────────

test_car_vat_limit_standard_exceeded if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "CAR_NEW",
            "amount_net": 200000,
            "is_electric_vehicle": false,
            "has_mileage_log": false
        }
    }
    result.car_net_value == 200000
    result.car_limit_applied == 150000
    result._routing == "TRIAGE_QUEUE"
}

test_car_vat_limit_ev_below if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "CAR_NEW",
            "amount_net": 200000,
            "is_electric_vehicle": true,
            "has_mileage_log": false
        }
    }
    result.car_limit_applied == 225000
    result._routing == ""
}

# ── Test: Subject Exemption Proportional ─────────────────────────────────────

test_subject_exemption_proportional_new_jdg if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 160000,
            "ceidg_entry_date": "2026-03-01"
        },
        "current_day_of_year": 300
    }
    # Limit proporcjonalny: 200k / 365 * 300 = 164 383 PLN
    # Przychód 160k < 164k — w limicie
    result.exemption_exceeded == false
}

test_subject_exemption_proportional_exceeded if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 170000,
            "ceidg_entry_date": "2026-03-01"
        },
        "current_day_of_year": 300
    }
    # Limit proporcjonalny: 200k / 365 * 300 = 164 383 PLN
    # Przychód 170k > 164k — przekroczony!
    result.exemption_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test: OSS/IOSS Compliance ────────────────────────────────────────────────

test_oss_below_threshold if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "category_code": "E_SERVICES"
        },
        "vendor": {"is_b2c": true},
        "jdg_entrepreneur": {
            "annual_e_services_eur": 5000
        }
    }
    result.oss_applicable == false
}

test_oss_above_threshold if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "category_code": "E_SERVICES"
        },
        "vendor": {"is_b2c": true},
        "jdg_entrepreneur": {
            "annual_e_services_eur": 12000
        }
    }
    result.oss_applicable == true
    result._routing == "TRIAGE_QUEUE"
}

# ── Test: VAT RR Farmer ──────────────────────────────────────────────────────

test_vat_rr_farmer if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "category_code": "AGRICULTURAL_PRODUCTS",
            "amount_net": 10000
        },
        "jdg_entrepreneur": {
            "is_flat_rate_farmer": true
        }
    }
    result.vat_rr_rate == 0.07
    result.vat_rr_compensation == 700
}

# ── Test: Bad Debt Auto-Tracker ──────────────────────────────────────────────

test_bad_debt_critical_90_days if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "is_paid": false,
            "direction": "SALE",
            "days_overdue": 95,
            "due_date": "2026-03-01",
            "invoice_number": "FV/2026/001"
        }
    }
    result.alert_level == "CRITICAL"
    result._routing == "TRIAGE_QUEUE"
}

test_bad_debt_warning_80_days if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "is_paid": false,
            "direction": "SALE",
            "days_overdue": 82,
            "due_date": "2026-03-15",
            "invoice_number": "FV/2026/002"
        }
    }
    result.alert_level == "WARNING"
}

test_bad_debt_info_60_days if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "is_paid": false,
            "direction": "SALE",
            "days_overdue": 65,
            "due_date": "2026-04-01",
            "invoice_number": "FV/2026/003"
        }
    }
    result.alert_level == "INFO"
}

# ── Test: WDT 70-Day Deadline ────────────────────────────────────────────────

test_wdt_no_docs_80_days if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "procedure": "WDT",
            "transaction_date": "2026-01-01",
            "has_transport_documents": false,
            "wdt_days_elapsed": 80
        }
    }
    result._routing == "BLOCK_AND_ALERT"
}

test_wdt_docs_received if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "procedure": "WDT",
            "has_transport_documents": true,
            "wdt_days_elapsed": 10
        }
    }
    result._routing == ""
}

# ── Test: Double Taxation Prevention ─────────────────────────────────────────

test_double_tax_risk if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "buyer_country": "DE",
            "place_of_supply": "PL"
        },
        "vendor": {"country": "PL"}
    }
    result.double_tax_risk_detected == true
}
