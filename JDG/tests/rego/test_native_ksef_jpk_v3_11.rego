# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE REGO TESTS: jdg.ksef_jpk.v3_11 (Kampania V3, część 11)
# Uruchamiane przez `opa test JDG/rules JDG/tests/rego` (bramka CI).
# Konwencja: `v := ...decide with input as {...}` — modyfikator `with` dotyczy
# dokładnie jednego wyrażenia, dlatego każdy test wiąże wynik do zmiennej `v`.
# ═══════════════════════════════════════════════════════════════════════════════
package tests.test_native_ksef_jpk_v3_11

import future.keywords.in

# T01: fail-closed — brak snapshotu ksef_jpk_edeklaracje blokuje domenę
test_v3_11_fail_closed_without_thresholds {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {"invoice": {}, "jdg_entrepreneur": {}}
         with data.jdg.thresholds as {}
    startswith(v.rule_id, "jdg.ksef_jpk.v3_11.thresholds_missing")
    v._routing == "BLOCK_AND_ALERT"
}

# T02: faktura B2B po 2026-02-01 bez KSeF → BLOCK_AND_ALERT + sankcja FULL tier
test_v3_11_ksef_mandatory_gate {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {"issue_date": "2026-03-01", "buyer_nip": "1234567890",
                    "vat_amount_pln": 100000, "ksef_submitted": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.ksef_mandatory_gate"
    v.sanction_exposure.tier == "FULL"
    v.sanction_exposure.exposure_pln == 500000
    v._routing == "BLOCK_AND_ALERT"
}

# T03: czynny żal złożony → sankcja APOLOGY_50 (50% VAT, cap 250k)
test_v3_11_sanction_apology_tier {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {"issue_date": "2026-03-01", "buyer_nip": "1234567890",
                    "vat_amount_pln": 400000, "ksef_submitted": false},
        "jdg_entrepreneur": {"active_apology_filed": true},
    }
    v.sanction_exposure.tier == "APOLOGY_50"
    v.sanction_exposure.exposure_pln == 200000
}

# T04: B2C bez NIP → SUGGEST/WARNING tryb B2C_NO_NIP (nie blokada)
test_v3_11_b2c_without_nip {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {"issue_date": "2026-03-01", "buyer_nip": "", "ksef_submitted": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.b2c_without_nip_handler"
    v.ksef_mode == "B2C_NO_NIP"
    v._routing == "WARNING"
}

# T05: kolejka offline w oknie (<120h) → MONITOR bez alertu
test_v3_11_offline_queue_in_window {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {"in_offline_queue": true, "queue_age_hours": 24},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.offline_queue_guard"
    v.window_exceeded == false
    v._routing == ""
}

# T06: kolejka offline po oknie (>168h) → BLOCK_AND_ALERT
test_v3_11_offline_queue_window_exceeded {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {"in_offline_queue": true, "queue_age_hours": 200},
        "jdg_entrepreneur": {},
    }
    v.window_exceeded == true
    v._routing == "BLOCK_AND_ALERT"
}

# T07: UPO w terminie (12h < okno 1 dnia) → WARNING
test_v3_11_upo_pending_in_window {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {"ksef_submitted": true, "upo_received": false,
                    "hours_since_submission": 12},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.upo_validation_guard"
    v._routing == "WARNING"
}

# T08: podmiot publiczny B2G bez adresu e-Doręczeń → BLOCK_AND_ALERT
test_v3_11_edelivery_address_missing {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "counterparty": {"is_public_entity_b2g": true,
                         "edelivery_address_verified": false},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.edelivery_address_guard"
    v._routing == "BLOCK_AND_ALERT"
}

# T09: rozbieżność JPK ↔ KSeF → TRIAGE_QUEUE
test_v3_11_reconcile_discrepancy {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {},
        "jpk_register": {"enabled": true, "invoice_count": 42},
        "ksef_summary": {"submitted_count": 40},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.jpk_ksef_reconcile"
    v._routing == "TRIAGE_QUEUE"
    v.jpk_invoice_count == 42
    v.ksef_submitted_count == 40
}

# T10: WIS wygasa krytycznie (<90 dni) → TRIAGE_QUEUE
test_v3_11_wis_expiry_critical {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "wis_certificate": {"held": true, "days_to_expiry": 60},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.wis_expiry_watcher"
    v.days_to_expiry == 60
    v.critical_days == 90
    v._routing == "TRIAGE_QUEUE"
}

# T11: WIS w oknie ostrzegawczym (120 dni) → WARNING
test_v3_11_wis_expiry_warning {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "wis_certificate": {"held": true, "days_to_expiry": 120},
        "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.wis_expiry_watcher"
    v._routing == "WARNING"
}

# T12: certyfikat zbiorczy domeny (catch-all)
test_v3_11_domain_certificate_catch_all {
    v := data.jdg.ksef_jpk.v3_11.decide with input as {
        "invoice": {}, "jdg_entrepreneur": {},
    }
    v.rule_id == "jdg.ksef_jpk.v3_11.domain_certificate"
    v.snapshot_status == "OK"
}
