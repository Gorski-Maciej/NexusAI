# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_15 — KSeF / JPK / e-DEKLARACJE / GTU / WIS — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R15-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r14_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r15_ksef_jpk_edeklaracje_innovations

import future.keywords.if

# ── R15-INN-01: KSEF FIREWALL MONITOR ────────────────────────────────────────

test_inn01_block_bad_nip if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "ksef_check": {"nip_valid": false, "xsd_valid": true, "upo_received": true},
    }
    decide.rule_id == "jdg.r15_ksef_jpk_edeklaracje_innovations.ksef_firewall_monitor"
    decide.kf_blocked == true
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn01_triage_incomplete_chain if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "ksef_check": {"nip_valid": true, "xsd_valid": true, "upo_received": false},
    }
    decide.kf_blocked == false
    decide._routing == "TRIAGE_QUEUE"
}

test_inn01_ok_complete_chain if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "ksef_check": {"nip_valid": true, "xsd_valid": true, "upo_received": true},
    }
    decide._routing == ""
}

# ── R15-INN-02: JPK RECONCILIATION CHECKER ───────────────────────────────────

test_inn02_mismatch_triage if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "jpk_reconciliation": {"vat7_pln": 1000, "jpk_v7m_pln": 1200, "ledger_pln": 1000},
    }
    decide.rule_id == "jdg.r15_ksef_jpk_edeklaracje_innovations.jpk_reconciliation_checker"
    decide.jr_mismatch == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn02_match_ok if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "jpk_reconciliation": {"vat7_pln": 1000, "jpk_v7m_pln": 1000, "ledger_pln": 1000},
    }
    decide.jr_mismatch == false
    decide._routing == ""
}

# ── R15-INN-03: GTU CODE CLASSIFIER ──────────────────────────────────────────

test_inn03_mismatch_alcohol if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "gtu_input": {"invoice_desc": "sprzedaż alkoholu", "assigned_code": "GTU_05"},
    }
    decide.rule_id == "jdg.r15_ksef_jpk_edeklaracje_innovations.gtu_code_classifier"
    decide.gt_expected_code == "GTU_01"
    decide.gt_mismatch == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn03_match_fuel if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "gtu_input": {"invoice_desc": "paliwo", "assigned_code": "GTU_02"},
    }
    decide.gt_expected_code == "GTU_02"
    decide.gt_mismatch == false
    decide._routing == ""
}

# ── R15-INN-04: KSEF OFFLINE DEADLINE MONITOR ────────────────────────────────

test_inn04_red_when_2_days if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "ksef_offline": {"items": [{"label": "Faktura", "days_left": 2, "filed": false}]},
    }
    decide.rule_id == "jdg.r15_ksef_jpk_edeklaracje_innovations.ksef_offline_deadline_monitor"
    decide.ko_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn04_amber_when_5_days if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "ksef_offline": {"items": [{"label": "Faktura", "days_left": 5, "filed": false}]},
    }
    decide._routing == "TRIAGE_QUEUE"
}

# ── R15-INN-05: WIS REQUEST MONITOR ──────────────────────────────────────────

test_inn05_incomplete_triage if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "wis_request": {"goods_desc": "", "fee_paid": false, "submitted": false},
    }
    decide.rule_id == "jdg.r15_ksef_jpk_edeklaracje_innovations.wis_request_monitor"
    decide.wr_incomplete == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_complete_ok if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
        "wis_request": {"goods_desc": "drukarka 3D", "fee_paid": true, "submitted": true},
    }
    decide.wr_incomplete == false
    decide._routing == ""
}

# ── no_match ─────────────────────────────────────────────────────────────────

test_inn_no_input_no_match if {
    decide := jdg.r15_ksef_jpk_edeklaracje_innovations.decide with input as {
        "jdg_entrepreneur": {"r15_ksef_jpk_check": true},
    }
    decide.rule_id == "jdg.r15_ksef_jpk_edeklaracje_innovations.no_match"
}
