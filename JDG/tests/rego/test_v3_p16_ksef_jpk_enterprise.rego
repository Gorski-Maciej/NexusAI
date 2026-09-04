# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P16 KSeF/JPK ENTERPRISE (jdg.v3_p16_ksef_jpk)
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p16_ksef_jpk_enterprise.rego \
#       rules/v3_p16_ksef_jpk_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p16

import future.keywords.in

import data.jdg.v3_p16_ksef_jpk

_base := {"jdg_entrepreneur": {"v3_p16_check": true}}

_cases := {
    "session_orchestrator": {"analysis": "session_orchestrator", "pending_invoices": 5,
                             "session_mode": "ONLINE", "ksef_available": false,
                             "retries_used": 3, "invoice_issued_after": "2026-03-01",
                             "ksef_number_present": false},
    "zero_loss_queue": {"analysis": "zero_loss_queue", "offline_pending_invoices": 3,
                        "wal_enabled": false, "idempotency_keys_ok": true,
                        "invoice_in_queue": true},
    "upo_sentinel": {"analysis": "upo_sentinel", "sent_invoices": 10, "upo_received": 9,
                     "oldest_waiting_hours": 60},
    "pre_send_firewall": {"analysis": "pre_send_firewall", "fields_present": ["P_1", "P_2"],
                          "gtu_code": "GTU_99", "mpp_required": true, "mpp_marked": false,
                          "amount_net": 20000},
    "deadline_constitution": {"analysis": "deadline_constitution",
                              "filing": {"type": "VAT-7", "due_date": "2026-09-25",
                                         "shifted_to": "2026-09-25", "today": "2026-09-30",
                                         "filed": false}},
    "jpk_field_contract": {"analysis": "jpk_field_contract",
                           "rows": [{"gtu": "GTU_01", "amount_net": 1000, "mpp_required": false},
                                    {"gtu": "BAD_99", "amount_net": 20000, "mpp_required": true,
                                     "mpp_marked": false}]},
    "idempotent_corrections": {"analysis": "idempotent_corrections", "correction_event_id": "KOR-1",
                               "already_applied": true, "is_retry": false},
    "sandbox_ci_rig": {"analysis": "sandbox_ci_rig", "days_since_last_test": 12,
                       "failure_trend_pct": 3.0},
    "chaos_ksef_drill": {"analysis": "chaos_ksef_drill", "ksef_outage_hours": 72,
                         "drill_completed": false, "measured_rpo_hours": 2,
                         "measured_rto_hours": 6, "lost_invoices": 1},
    "edelivery_chain": {"analysis": "edelivery_chain", "sent_count": 5, "status_received": 5,
                        "upo_received": 3, "archived": 3, "oldest_waiting_hours": 30},
    "penalty_exposure": {"analysis": "penalty_exposure", "late_invoices": 3,
                         "vat_amount_late_pln": 500000, "regime": "FULL"},
    "golden_set": {"analysis": "golden_set", "invoice_number": "F/2026/1", "in_golden_set": true,
                   "schema_valid": false, "golden_fields_match": true},
}

_decide(case) = d {
    d := v3_p16_ksef_jpk.decide with input as object.union(_base, {"v3_p16": _cases[case]})
}

# ── I01: session orchestrator — retry wyczerpane → BLOCK_AND_ALERT ──
test_p16_i01_retry_exhausted_block {
    d := _decide("session_orchestrator")
    d.rule_id == "jdg.v3_p16_ksef_jpk.ksef_session_orchestrator"
    d._routing == "BLOCK_AND_ALERT"
    d.retry_exhausted == true
}

# ── I02: zero-loss queue — WAL wyłączony → BLOCK_AND_ALERT (RPO>0) ──
test_p16_i02_wal_off_block {
    d := _decide("zero_loss_queue")
    d.rule_id == "jdg.v3_p16_ksef_jpk.zero_loss_offline_queue"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I03: UPO sentinel — eskalacja → BLOCK_AND_ALERT ──
test_p16_i03_upo_escalation_block {
    d := _decide("upo_sentinel")
    d.rule_id == "jdg.v3_p16_ksef_jpk.upo_sentinel"
    d._routing == "BLOCK_AND_ALERT"
    d.missing_upo == 1
}

# ── I04: pre-send firewall — GTU nieznany → BLOCK_AND_ALERT ──
test_p16_i04_firewall_block {
    d := _decide("pre_send_firewall")
    d.rule_id == "jdg.v3_p16_ksef_jpk.pre_send_firewall"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I05: deadline constitution — termin minął → BLOCK_AND_ALERT ──
test_p16_i05_deadline_overdue_block {
    d := _decide("deadline_constitution")
    d.rule_id == "jdg.v3_p16_ksef_jpk.deadline_constitution"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: JPK field contract — złe GTU → BLOCK_AND_ALERT ──
test_p16_i06_field_contract_block {
    d := _decide("jpk_field_contract")
    d.rule_id == "jdg.v3_p16_ksef_jpk.jpk_field_contract"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I07: idempotent corrections — duplikat → BLOCK_AND_ALERT ──
test_p16_i07_duplicate_block {
    d := _decide("idempotent_corrections")
    d.rule_id == "jdg.v3_p16_ksef_jpk.idempotent_corrections"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I08: sandbox CI — test poza cyklem → TRIAGE_QUEUE ──
test_p16_i08_sandbox_overdue_triage {
    d := _decide("sandbox_ci_rig")
    d.rule_id == "jdg.v3_p16_ksef_jpk.sandbox_ci_rig"
    d._routing == "TRIAGE_QUEUE"
}

# ── I09: chaos drill — utrata faktur → BLOCK_AND_ALERT ──
test_p16_i09_chaos_loss_block {
    d := _decide("chaos_ksef_drill")
    d.rule_id == "jdg.v3_p16_ksef_jpk.chaos_ksef_drill"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I10: e-delivery chain — brak UPO → BLOCK_AND_ALERT ──
test_p16_i10_chain_broken_block {
    d := _decide("edelivery_chain")
    d.rule_id == "jdg.v3_p16_ksef_jpk.edelivery_chain"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I11: penalty exposure — wysoka ekspozycja → BLOCK_AND_ALERT ──
test_p16_i11_high_exposure_block {
    d := _decide("penalty_exposure")
    d.rule_id == "jdg.v3_p16_ksef_jpk.penalty_exposure_monitor"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I12: golden set — rozjazd z oracle → BLOCK_AND_ALERT ──
test_p16_i12_golden_violation_block {
    d := _decide("golden_set")
    d.rule_id == "jdg.v3_p16_ksef_jpk.ksef_jpk_golden_set"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Brak aktywacji (v3_p16_check=false) → no_match ──
test_p16_not_activated_no_match {
    d := v3_p16_ksef_jpk.decide with input as {"jdg_entrepreneur": {"v3_p16_check": false}}
    d.matched == false
    d.rule_id == "jdg.v3_p16_ksef_jpk.no_match"
}

# ── Ścieżka pozytywna: upo kompletne → SUGGEST ──
test_p16_i03_upo_complete_suggest {
    case := object.union(_cases["upo_sentinel"], {"sent_invoices": 10, "upo_received": 10,
                                                  "oldest_waiting_hours": 0})
    d := v3_p16_ksef_jpk.decide with input as object.union(_base, {"v3_p16": case})
    d.rule_id == "jdg.v3_p16_ksef_jpk.upo_sentinel"
    d._routing == "SUGGEST"
}

# ── Ścieżka pozytywna: korekta retry idempotentna → SUGGEST ──
test_p16_i07_retry_safe_suggest {
    case := object.union(_cases["idempotent_corrections"], {"is_retry": true})
    d := v3_p16_ksef_jpk.decide with input as object.union(_base, {"v3_p16": case})
    d.rule_id == "jdg.v3_p16_ksef_jpk.idempotent_corrections"
    d._routing == "SUGGEST"
}

# ── Ścieżka pozytywna: firewall czysty → SUGGEST ──
test_p16_i04_firewall_clean_suggest {
    case := {"analysis": "pre_send_firewall",
             "fields_present": ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"],
             "gtu_code": "GTU_01", "mpp_required": false, "mpp_marked": true, "amount_net": 1000}
    d := v3_p16_ksef_jpk.decide with input as object.union(_base, {"v3_p16": case})
    d.rule_id == "jdg.v3_p16_ksef_jpk.pre_send_firewall"
    d._routing == "SUGGEST"
}

# ── Ścieżka pozytywna: golden zgodny → SUGGEST ──
test_p16_i12_golden_ok_suggest {
    case := {"analysis": "golden_set", "invoice_number": "F/2026/1", "in_golden_set": true,
             "schema_valid": true, "golden_fields_match": true}
    d := v3_p16_ksef_jpk.decide with input as object.union(_base, {"v3_p16": case})
    d.rule_id == "jdg.v3_p16_ksef_jpk.ksef_jpk_golden_set"
    d._routing == "SUGGEST"
}

# ── Ścieżka pozytywna: deadline złożony → SUGGEST ──
test_p16_i05_deadline_filed_suggest {
    filing := object.union(object.get(_cases["deadline_constitution"], "filing", {}),
                           {"filed": true, "today": "2026-09-20"})
    case := {"analysis": "deadline_constitution", "filing": filing}
    d := v3_p16_ksef_jpk.decide with input as object.union(_base, {"v3_p16": case})
    d.rule_id == "jdg.v3_p16_ksef_jpk.deadline_constitution"
    d._routing == "SUGGEST"
}
