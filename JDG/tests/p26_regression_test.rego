# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P26 Regression Tests (Raport P26 R10)
# Testy Rego dla: neural_mesh, audit, retention, international, ppk_pfron
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tests.p26

# ── Retention Tests ───────────────────────────────────────────────────────────

test_retention_tax_documents_5yr {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "TAX", "statute_triggered": false}
    }
    result.matched == true
    result.rule_id == "jdg.retention.tax_documents_5yr"
}

test_retention_vat_invoices_extended {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "VAT_INVOICE", "related_to_real_estate": false}
    }
    result.matched == true
    result.rule_id == "jdg.retention.vat_invoices_extended"
}

test_retention_vat_real_estate_10yr {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "VAT_INVOICE", "related_to_real_estate": true}
    }
    result.matched == true
    result.rule_id == "jdg.retention.vat_invoices_real_estate_10yr"
}

test_retention_zus_10yr {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "ZUS"}
    }
    result.matched == true
    result.rule_id == "jdg.retention.zus_documents_10yr"
    result.retention_period_years == 10
}

test_retention_zus_archival_50yr {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "ZUS", "pre_1999_records": true}
    }
    result.matched == true
    result.rule_id == "jdg.retention.zus_archival_50yr_pre1999"
}

test_retention_uor_5yr {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "UOR_ACCOUNTING", "is_annual_report": false}
    }
    result.matched == true
    result.rule_id == "jdg.retention.uor_accounting_5yr"
}

test_retention_uor_annual_permanent {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "UOR_ACCOUNTING", "is_annual_report": true}
    }
    result.matched == true
    result.rule_id == "jdg.retention.uor_annual_reports_permanent"
}

test_retention_contracts_6yr {
    result := data.jdg.retention.decide with input as {
        "retention": {"document_category": "CONTRACTS"}
    }
    result.matched == true
    result.rule_id == "jdg.retention.contracts_6yr"
}

# ── International Tests ────────────────────────────────────────────────────────

test_international_wht_obligation {
    result := data.jdg.international.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "ROYALTIES"},
        "vendor": {"country": "DE"},
        "jdg_entrepreneur": {}
    }
    result.matched == true
    result.wht_required == true
}

test_international_tp_documentation {
    result := data.jdg.international.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "SERVICES", "amount_net": 150000},
        "vendor": {"country": "DE", "is_related_party": true},
        "jdg_entrepreneur": {}
    }
    result.matched == true
    result.tp_documentation_required == true
}

test_international_pe_risk {
    result := data.jdg.international.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "SERVICES", "amount_net": 10000},
        "vendor": {"country": "DE", "is_related_party": false},
        "jdg_entrepreneur": {"days_abroad": 200}
    }
    result.matched == true
    result.pe_risk == true
}

test_international_upo_treaty_lookup {
    result := data.jdg.international.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "SERVICES", "amount_net": 10000},
        "vendor": {"country": "DE", "is_related_party": false, "has_treaty": true},
        "jdg_entrepreneur": {"days_abroad": 30}
    }
    result.matched == true
    result.upo_country == "DE"
    result.upo_dividend_rate_pct == 5
}

test_international_ift2r {
    result := data.jdg.international.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "SERVICES", "amount_net": 10000, "wht_obligation": true, "amount_gross": 12000},
        "vendor": {"country": "DE", "is_related_party": false, "has_treaty": true},
        "jdg_entrepreneur": {"days_abroad": 30}
    }
    result.matched == true
    result.ift2r_required == true
}

test_international_pe_fixed_base {
    result := data.jdg.international.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "SERVICES", "amount_net": 10000},
        "vendor": {"country": "DE", "is_related_party": false},
        "jdg_entrepreneur": {"days_abroad": 30, "abroad_country": "DE", "days_abroad_in_country": 120, "has_fixed_office_abroad": true}
    }
    result.matched == true
    result.pe_fixed_base_risk == true
}

# ── PPK/PFRON Tests ───────────────────────────────────────────────────────────

test_ppk_pfron_obligation {
    result := data.jdg.ppk_pfron.decide with input as {
        "employment": {"has_employees": true, "employee_count": 3},
        "jdg_entrepreneur": {}
    }
    result.matched == true
}

# ── Neural Mesh Tests ─────────────────────────────────────────────────────────

test_neural_mesh_global_health {
    result := data.jdg.neural_mesh.decide with input as {
        "neural_mesh_analysis": true,
        "invoice": {"vat_rate_change_detected": false},
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "zus_status": "STANDARD",
            "vat_status": "ACTIVE",
            "jpk_filed_on_time": true,
            "ksef_registered": false,
            "vat_corrections_12mo": 0,
            "pit_advances_paid_on_time": true,
            "pit_annual_filed": true,
            "has_unresolved_losses": false,
            "zus_health_paid_current": true,
            "zus_social_paid_current": true,
            "zus_dra_filed": true,
            "whitelist_verified": true,
            "has_tax_interpretations_pending": false,
            "tax_deadlines_missed_12mo": 0,
            "kks_risk_flags_active": 0,
            "kks_convicted": false,
            "kks_voluntary_disclosure_filed": false,
            "kks_realtime_score_avg_30d": 0,
            "has_crossborder_transactions": false,
            "pkpir_maintained": true,
            "inventory_done_annual": false,
            "ceidg_valid": true,
            "business_suspended": false,
            "prokura_registered": false,
            "pcc_transactions_12mo": 0,
            "pcc3_filed_on_time": true,
            "has_business_real_estate": false,
            "dn1_filed": true,
            "has_taxable_vehicles": false,
            "dt1_filed": true,
            "in_succession": false,
            "rodo_policy_in_place": true,
            "rodo_register_maintained": true,
            "rodo_breach_12mo": false,
            "aml_obligated": false,
            "bdo_registered": false,
            "sanctions_hits_active": 0,
            "has_fatf_country_exposure": false,
            "aml_compliance_score": 100,
            "tax_year_as_int": 2026
        }
    }
    result.matched == true
    result.neural_mesh_global_health_score >= 0
    result.neural_mesh_global_health_score <= 100
}

# ── MPiPS Tests ───────────────────────────────────────────────────────────────

test_mpips_zfss_50fte {
    # ZFŚS — próg 50 FTE (P26 R6)
    result := data.jdg.mpips.decide with input as {
        "employment": {"has_employees": true, "employee_count": 45},
        "invoice": {},
        "jdg_entrepreneur": {},
        "data": {"thresholds": {"jdg": {"bounds": {"avg_monthly_wage": 7000}}}}
    }
    # 45 pracowników < 50 FTE — ZFŚS NIE powinien być matched
    result.rule_id != "jdg.mpips.zfss_social_fund"
}

test_mpips_zfss_50fte_triggered {
    # ZFŚS — próg 50 FTE — triggered
    result := data.jdg.mpips.decide with input as {
        "employment": {"has_employees": true, "employee_count": 55},
        "invoice": {},
        "jdg_entrepreneur": {},
        "data": {"thresholds": {"jdg": {"bounds": {"avg_monthly_wage": 7000}}}}
    }
    result.matched == true
}
