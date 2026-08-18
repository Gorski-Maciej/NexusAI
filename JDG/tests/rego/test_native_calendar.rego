# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: KALENDARZ PŁATNOŚCI / TERMINY (GLM52 P16)
# Testy pakietu jdg.deadline_monitor: kalendarz nadchodzących płatności
# (PIT/VAT/ZUS), routing BLOCK_AND_ALERT / TRIAGE_QUEUE oraz wpływ opóźnień
# (odsetki art. 56 OrdPU, ulga art. 67a OrdPU).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_calendar

import data.jdg.deadline_monitor

# ── Kalendarz płatności (deadline_calendar_check) ─────────────────────────────
test_calendar_upcoming_payments {
    r := deadline_monitor.decide with input as {
        "deadline_calendar_check": true,
        "dlm_upcoming_payments": [
            {"date": "2026-08-20", "days_left": 2, "amount": 4500.0, "type": "ZUS"},
            {"date": "2026-08-25", "days_left": 7, "amount": 8200.0, "type": "VAT"}
        ]
    }
    r.matched == true
    r.rule_id == "jdg.deadline_monitor.payment_calendar"
    r.dlm_total_upcoming_payments == 2
    r.dlm_total_amount_due == 12700.0
    r.dlm_next_deadline_days == 2
    r.dlm_next_deadline_type == "ZUS"
    r._routing == "TRIAGE_QUEUE"
}

test_calendar_urgent_payment_blocks {
    r := deadline_monitor.decide with input as {
        "deadline_calendar_check": true,
        "dlm_upcoming_payments": [
            {"date": "2026-08-19", "days_left": 1, "amount": 15000.0, "type": "PIT"}
        ]
    }
    r.matched == true
    r.rule_id == "jdg.deadline_monitor.payment_calendar"
    r._routing == "BLOCK_AND_ALERT"
}

test_calendar_no_payments {
    r := deadline_monitor.decide with input as {
        "deadline_calendar_check": true,
        "dlm_upcoming_payments": []
    }
    r.matched == true
    r.dlm_total_upcoming_payments == 0
    r._routing == ""
}

# ── Opóźnienie płatności (late_payment_impact) ────────────────────────────────
test_calendar_late_payment_impact {
    r := deadline_monitor.decide with input as {
        "dlm_late_amount": 10000.0,
        "dlm_late_days": 45
    }
    r.matched == true
    r.rule_id == "jdg.deadline_monitor.late_payment_impact"
    r.dlm_installment_eligible == true
    r._routing == "TRIAGE_QUEUE"
    "Art. 53-56 OrdPU (odsetki); Art. 67a OrdPU (ulgi w spłacie)" == r._legal_basis
}

test_calendar_late_payment_installment_not_eligible {
    r := deadline_monitor.decide with input as {
        "dlm_late_amount": 3000.0,
        "dlm_late_days": 10
    }
    r.matched == true
    r.rule_id == "jdg.deadline_monitor.late_payment_impact"
    r.dlm_installment_eligible == false
}

# ── Brak sekcji → no_match ─────────────────────────────────────────────────────
test_calendar_no_match {
    r := deadline_monitor.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.deadline_monitor.no_match"
}
