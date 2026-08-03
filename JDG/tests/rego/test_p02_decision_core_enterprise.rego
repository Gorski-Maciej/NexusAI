# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for P02 Warstwa Decyzyjna Core v9.0
# Packages: jdg.adaptive_trust, jdg.conflict_declaration,
#           jdg.decision_core_completeness, jdg.p02_decision_core_innovations
# Source: P02_Warstwa_Deczyjna_Core.txt (prompts_glm52)
# Generated: 2026-08-02
# ═══════════════════════════════════════════════════════════════════════════════

package test_p02_decision_core

import future.keywords.in

# ═══ ADAPTIVE TRUST (Sekcja 1) ═══

# AUTO_POST gate — wysoki trust, brak fraud
test_adaptive_trust_auto_post {
    result := data.jdg.adaptive_trust.decide with input as {
        "jdg_entrepreneur": {"trust_check": true, "primary_package": "jdg.vat"},
        "confidence": {"fc_vat_rate": 0.99, "fc_vendor_nip": 0.99, "fc_date": 0.99, "fc_amount": 0.99},
        "vendor": {"on_whitelist": true},
        "invoice": {"amount_net": 1000, "amount_gross": 1230, "vat_amount": 230}
    }
    result.matched == true
    result.rule_id == "jdg.adaptive_trust.auto_post_gate"
    result._routing == "AUTO_POST"
    result.trust.final >= result.trust.threshold_auto_post
}

# SUGGEST gate — średni trust
test_adaptive_trust_suggest {
    result := data.jdg.adaptive_trust.decide with input as {
        "jdg_entrepreneur": {"trust_check": true, "primary_package": "jdg.vat"},
        "confidence": {"fc_vat_rate": 0.85, "fc_vendor_nip": 0.85, "fc_date": 0.85, "fc_amount": 0.85},
        "vendor": {"on_whitelist": true}
    }
    result.rule_id == "jdg.adaptive_trust.suggest_gate"
    result._routing == "SUGGEST"
}

# TRIAGE/BLOCK — fraud pattern (okrągła kwota 1000)
test_adaptive_trust_block_fraud {
    result := data.jdg.adaptive_trust.decide with input as {
        "jdg_entrepreneur": {"trust_check": true, "primary_package": "jdg.vat"},
        "confidence": {"fc_vat_rate": 0.99, "fc_vendor_nip": 0.99, "fc_date": 0.99, "fc_amount": 0.99},
        "invoice": {"amount_net": 1000}
    }
    result.rule_id == "jdg.adaptive_trust.triage_gate"
    result._routing == "BLOCK_AND_ALERT"
    count(result.trust.fraud_patterns) >= 1
}

# ═══ CONFLICT DECLARATION (Sekcja 2) ═══

# Raport konfliktów — aktywny konflikt ipbox_vs_br
test_conflict_declaration_report {
    result := data.jdg.conflict_declaration.decide with input as {
        "jdg_entrepreneur": {"conflict_check": true, "PIT_IP_BOX": true, "PIT_RD_RELIEF": true}
    }
    result.matched == true
    result.rule_id == "jdg.conflict_declaration.report"
    count(result.active_conflicts) >= 1
}

# Brak konfliktów
test_conflict_declaration_clear {
    result := data.jdg.conflict_declaration.decide with input as {
        "jdg_entrepreneur": {"conflict_check": true}
    }
    result.rule_id == "jdg.conflict_declaration.no_active_conflicts"
}

# ═══ DECISION CORE COMPLETENESS (Sekcje 3-5) ═══

# Limitations calendar — zobowiązanie przedawnione (2015 + 5 = 2020 < 2026)
test_limitations_alert {
    result := data.jdg.decision_core_completeness.decide with input as {
        "jdg_entrepreneur": {"limitations_check": true},
        "evaluation_datetime": "2026-01-01",
        "limitations_calendar": {"obligations": [
            {"type": "VAT", "tax_year": 2015}
        ]}
    }
    result.rule_id == "jdg.decision_core_completeness.limitations_alert"
    result._routing == "BLOCK_AND_ALERT"
}

# Retention non-compliant — dokumenty 2 lata < 5 lat
test_retention_non_compliant {
    result := data.jdg.decision_core_completeness.decide with input as {
        "jdg_entrepreneur": {"compliance_check": true},
        "compliance_probe": {"retention_docs_years": 2}
    }
    result.rule_id == "jdg.decision_core_completeness.retention_non_compliant"
    result._routing == "TRIAGE_QUEUE"
}

# Edge case gap — kombinacja bez pokrycia
test_edge_case_gap {
    result := data.jdg.decision_core_completeness.decide with input as {
        "jdg_entrepreneur": {"edge_case_check": true},
        "edge_case_probe": {"dimensions": ["ec_exotic_combo_xyz"]}
    }
    result.rule_id == "jdg.decision_core_completeness.edge_case_gap"
    result.gap_count >= 1
}

# ═══ P02 DECISION CORE INNOVATIONS (Sekcja 7) ═══

test_p02_innovations_report {
    result := data.jdg.p02_decision_core_innovations.decide with input as {
        "jdg_entrepreneur": {"p02_decision_core_check": true},
        "invoice": {"amount_net": 1000, "amount_gross": 1230, "vat_amount": 230, "issue_date": "2026-01-01"},
        "_package_decisions": {
            "jdg.risk": {"matched": true, "rule_id": "jdg.risk.x", "_routing": "ALLOW", "_routing_reason": "ok", "_legal_basis": "Art. 1", "_warnings": []}
        },
        "verdict": {"_provenance_tree": {"path": [{"step": 1}]}}
    }
    result.matched == true
    result.rule_id == "jdg.p02_decision_core_innovations.report"
    result.innovations.INN06_graceful_level == "AUTO_POST"
    result.innovations.INN01_correctness_proof.contract_ok == true
}

# INN-06 graceful downgrade — brak kwot → TRIAGE_QUEUE
test_p02_graceful_downgrade {
    result := data.jdg.p02_decision_core_innovations.decide with input as {
        "jdg_entrepreneur": {"p02_decision_core_check": true},
        "invoice": {"issue_date": "2026-01-01"}
    }
    result.innovations.INN06_graceful_level == "TRIAGE_QUEUE"
}
