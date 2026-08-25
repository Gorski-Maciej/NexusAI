# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE REGO TESTS: jdg.compliance.v3_12 (Kampania V3, część 12)
# Uruchamiane przez `opa test JDG/rules JDG/tests/rego` (bramka CI).
# Konwencja: `v := ...decide with input as {...}` — modyfikator `with` dotyczy
# dokładnie jednego wyrażenia, dlatego każdy test wiąże wynik do zmiennej `v`.
# ═══════════════════════════════════════════════════════════════════════════════
package tests.test_native_compliance_v3_12

import future.keywords.in

# T01: fail-closed — brak snapshotu rodo_aml_bdo_hr_etap21 blokuje domenę
test_v3_12_fail_closed_without_thresholds {
    v := data.jdg.compliance.v3_12.decide with input as {"rodo_incident": {}, "jdg_entrepreneur": {}}
         with data.jdg.thresholds as {}
    startswith(v.rule_id, "jdg.compliance.v3_12.thresholds_missing")
    v._routing == "BLOCK_AND_ALERT"
}

# T02: naruszenie RODO niezgłoszone po 72h → BLOCK_AND_ALERT (art. 33)
test_v3_12_rodo_breach_overdue {
    v := data.jdg.compliance.v3_12.decide with input as {
        "rodo_incident": {"breach_detected": true, "hours_since_detection": 80,
                          "reported_to_uodo": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.rodo_breach_guard"
    v.deadline_hours == 72
    v._routing == "BLOCK_AND_ALERT"
}

# T03: naruszenie RODO zgłoszone → brak alertu
test_v3_12_rodo_breach_reported {
    v := data.jdg.compliance.v3_12.decide with input as {
        "rodo_incident": {"breach_detected": true, "hours_since_detection": 80,
                          "reported_to_uodo": true},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.rodo_breach_guard"
    v._routing == ""
}

# T04: żądanie usunięcia danych po 30 dniach → BLOCK_AND_ALERT (art. 17)
test_v3_12_erasure_overdue {
    v := data.jdg.compliance.v3_12.decide with input as {
        "erasure_request": {"received": true, "days_pending": 45, "erased": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.erasure_engine_guard"
    v.erasure_deadline_days == 30
    v._routing == "BLOCK_AND_ALERT"
}

# T05: transakcja AML ≥ 15k EUR bez STR → BLOCK_AND_ALERT (art. 34 uAML)
test_v3_12_aml_transaction_no_str {
    v := data.jdg.compliance.v3_12.decide with input as {
        "aml_transaction": {"monitored": true, "value_eur": 20000, "str_filed": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.aml_transaction_monitor"
    v.transaction_threshold_eur == 15000
    v._routing == "BLOCK_AND_ALERT"
}

# T06: kontrahent wysokiego ryzyka bez CBDD → BLOCK_AND_ALERT
test_v3_12_cbdd_high_risk_incomplete {
    v := data.jdg.compliance.v3_12.decide with input as {
        "counterparty": {"risk_screened": true, "risk_level": "HIGH",
                         "cbdd_completed": false, "ubo_identified": true},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.aml_cbdd_guard"
    v.ubo_minimum_pct == 25
    v._routing == "BLOCK_AND_ALERT"
}

# T07: KPO niepotwierdzone >7 dni → TRIAGE_QUEUE
test_v3_12_bdo_kpo_unconfirmed {
    v := data.jdg.compliance.v3_12.decide with input as {
        "bdo_kpo": {"issued": true, "days_unconfirmed": 10,
                    "unconfirmed_over_year": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.bdo_kpo_guard"
    v.kpo_deadline_days == 7
    v._routing == "TRIAGE_QUEUE"
}

# T08: KPO niepotwierdzone ponad rok → BLOCK_AND_ALERT
test_v3_12_bdo_kpo_expired {
    v := data.jdg.compliance.v3_12.decide with input as {
        "bdo_kpo": {"issued": true, "days_unconfirmed": 400,
                    "unconfirmed_over_year": true},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.bdo_kpo_guard"
    v._routing == "BLOCK_AND_ALERT"
}

# T09: AI/profiling bez DPIA → TRIAGE_QUEUE (manual approval z thresholds)
test_v3_12_dpia_missing {
    v := data.jdg.compliance.v3_12.decide with input as {
        "data_processing": {"ai_profiling_large_scale": true, "dpia_completed": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.dpia_guard"
    v.dpia_required == true
    v.dpia_completed == false
}

# T10: transakcja poniżej progu AML → certyfikat domeny (brak zdarzenia)
test_v3_12_aml_below_threshold_catch_all {
    v := data.jdg.compliance.v3_12.decide with input as {
        "aml_transaction": {"monitored": true, "value_eur": 5000, "str_filed": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.domain_certificate"
    v.snapshot_status == "OK"
}

# T11: certyfikat domeny — klucze progowe dostępne w verdict
test_v3_12_certificate_threshold_values {
    v := data.jdg.compliance.v3_12.decide with input as {
        "rodo_incident": {}, "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.compliance.v3_12.domain_certificate"
    v.rodo_breach_deadline_hours == 72
    v.ubo_minimum_pct == 25
}

# T12: threshold_version w każdym Decision Certificate (Golden Oracle F3)
test_v3_12_certificate_version_present {
    v := data.jdg.compliance.v3_12.decide with input as {
        "rodo_incident": {"breach_detected": true, "hours_since_detection": 1,
                          "reported_to_uodo": false},
        "jdg_entrepreneur": {},
    }
    v.threshold_version == "rodo-aml-bdo-2026.08"
}
