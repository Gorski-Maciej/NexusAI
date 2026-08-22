# ETAP 21 — native tests for RODO/AML/BDO/HR evidence contract.
package test_jdg_rodo_aml_bdo_hr_etap21

import future.keywords.if

base := {
    "jdg_entrepreneur": {"rodo_aml_bdo_hr_etap21_check": true},
    "rodo_aml_bdo_hr_etap21": {
        "domains": ["RODO", "AML", "BDO", "HR"],
        "evaluation_date": "2026-08-21",
        "facts_version": "facts-21-1",
        "threshold_version": "compliance-hr-etap21-2026.08",
        "legal_basis_version": "isap-uodo-aml-bdo-kp-2026.08",
        "source_refs": ["UODO-2026", "GIIF-2026", "BDO-2026", "KP-2026"],
        "legal_nodes": {"RODO": "RODO art. 5/17/30/33", "AML": "u.AML art. 28-34/74-80", "BDO": "UoO art. 66-70", "HR": "KP art. 85"},
        "owner_approval": true,
        "document": {"document_id": "COMP-21-1", "document_hash": "sha256:comp-21-1", "document_type": "COMPLIANCE_REVIEW"},
        "privacy": {
            "legal_basis": "Art. 6 ust. 1 lit. c RODO", "purpose": "realizacja obowiązku prawnego",
            "data_categories": ["DANE_KONTRAHENTA"], "consent_required": false,
            "data_minimized": true, "purpose_limitation": true, "pii_redacted_in_output": true,
            "retention_days": 1825, "retention_basis": "RODO art. 5(1)(e) + UoR", "retention_review_date": "2027-08-21",
            "breach_detected": false, "rights_request_open": false
        },
        "aml": {
            "ubo_verified": true, "ubo_ownership_pct": 50, "ubo_source_ref": "CRBR-21-1",
            "cdd_level": "STANDARD", "cdd_evidence_id": "CDD-21-1", "sanctions_screened": true,
            "screening_date": "2026-08-21", "screening_source_ref": "EU-SANCTIONS-21-1",
            "transaction_amount_eur": 1000, "suspicious_activity": false
        },
        "bdo": {
            "registration_required": true, "registered": true, "registration_id": "BDO-21-1",
            "kpo_required": true, "kpo_id": "KPO-21-1", "kpo_status": "CONFIRMED",
            "ewc_code": "15 01 01", "ewc_verified": true, "ewc_source_ref": "EWC-21-1",
            "transport_required": true, "transport_authorized": true, "carrier_evidence_id": "CARRIER-21-1",
            "waste_record_required": true, "waste_record_id": "WASTE-21-1", "waste_mass_unit": "KG"
        },
        "hr": {
            "employee_count": 10, "employment_document_id": "EMP-21-1", "employment_basis": "EMPLOYMENT",
            "payroll_period": "2026-08", "payroll_evidence_id": "PAY-21-1", "zus_pit_reconciled": true,
            "ppk_applicable": true, "ppk_status": "ENROLLED", "ppk_evidence_id": "PPK-21-1"
        }
    }
}

test_no_match_without_stage_flag if {
    result := data.jdg.rodo_aml_bdo_hr_etap21.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.rodo_aml_bdo_hr_etap21.no_match"
}

test_missing_evidence_blocks if {
    result := data.jdg.rodo_aml_bdo_hr_etap21.decide with input as {
        "jdg_entrepreneur": {"rodo_aml_bdo_hr_etap21_check": true},
        "rodo_aml_bdo_hr_etap21": {"domains": ["RODO"]}
    }
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_privacy_by_design_and_manual_gate if {
    result := data.jdg.rodo_aml_bdo_hr_etap21.decide with input as base
    result.rodo_certificate.basis_complete == true
    result.rodo_certificate.retention_complete == true
    result.privacy_by_design == true
    result.manual_review_required == true
    result.compliance_guidance_only == true
    result.tax_decision == false
}

test_aml_ubo_cddd_and_str if {
    result := data.jdg.rodo_aml_bdo_hr_etap21.decide with input as base
    result.aml_certificate.ubo_complete == true
    result.aml_certificate.cdd_complete == true
    result.aml_certificate.sanctions_screening_complete == true
    result.aml_certificate.str_required == false
    result.aml_certificate.str_complete == true
}

test_bdo_kpo_ewc_transport if {
    result := data.jdg.rodo_aml_bdo_hr_etap21.decide with input as base
    result.bdo_certificate.registration_complete == true
    result.bdo_certificate.kpo_complete == true
    result.bdo_certificate.ewc_complete == true
    result.bdo_certificate.waste_transport_complete == true
    result.bdo_certificate.waste_record_complete == true
}

test_hr_ppk_pfron if {
    result := data.jdg.rodo_aml_bdo_hr_etap21.decide with input as base
    result.hr_certificate.employment_complete == true
    result.hr_certificate.payroll_complete == true
    result.hr_certificate.ppk_complete == true
    result.hr_certificate.pfron_required == false
    result.hr_certificate.pfron_complete == true
}
