# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.6: Tax Calendar Smart Notifier
# v7.0 — BP-6: Multi-channel notifications + cash-flow planning + US deadlines
# Package: jdg.enterprise.calendar_notifier
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.calendar_notifier

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# CIN-3250: Multi-channel notification engine
# ─────────────────────────────────────────────────────────────────────────────
cin_notification_router(event) = routing {
    event_type := object.get(event, "type", "DEADLINE")
    days_remaining := object.get(event, "days_remaining", 30)
    amount_involved := object.get(event, "amount_pln", 0)

    # Channels as flags, NOT cumulative redeclaration
    push_flag := 1
    email_flag := 1 { days_remaining <= 7 }
    email_flag := 0 { days_remaining > 7 }
    ede_flag := 1 { days_remaining <= 3 }
    ede_flag := 0 { days_remaining > 3 }
    sms_flag := 1 { amount_involved > 10000; days_remaining <= 3 }
    sms_flag := 0 { true }

    channels := ["PUSH"]
    channels := array.concat(channels, ["EMAIL"]) { email_flag == 1 }
    channels := array.concat(channels, ["EDE"]) { ede_flag == 1 }
    channels := array.concat(channels, ["SMS"]) { sms_flag == 1 }

    # Mutual exclusive escalation_level guards
    escalation_level := "OVERDUE" { days_remaining <= 0 }
    escalation_level := "URGENT" { days_remaining <= 3; days_remaining > 0 }
    escalation_level := "WARNING" { days_remaining <= 7; days_remaining > 3 }
    escalation_level := "NORMAL" { days_remaining > 7 }

    routing := {
        "event_type": event_type,
        "days_remaining": days_remaining,
        "channels": channels,
        "escalation_level": escalation_level,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CIN-3260: Weekly/monthly cash-flow aggregation
# ─────────────────────────────────────────────────────────────────────────────
cin_cashflow_planner(upcoming_deadlines, balance) = plan {
    next_7_days := [d | d := upcoming_deadlines[_]; object.get(d, "days_remaining", 999) <= 7]
    next_30_days := [d | d := upcoming_deadlines[_]; object.get(d, "days_remaining", 999) <= 30]

    recommendation := "Zarezerwuj środki na nadchodzące płatności" { count(next_7_days) > 0 }
    recommendation := "Brak pilnych płatności" { true }

    plan := {
        "current_balance_pln": balance,
        "next_7_days_count": count(next_7_days),
        "next_30_days_count": count(next_30_days),
        "recommendation": recommendation,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CIN-3270: US decision deadline importer
# ─────────────────────────────────────────────────────────────────────────────
cin_us_deadline_importer(us_decisions) = imported {
    decisions_with_deadlines := [d | d := us_decisions[_]; object.get(d, "appeal_deadline_days", 0) > 0]
    upcoming := [d | d := decisions_with_deadlines[_]; object.get(d, "appeal_deadline_days", 999) <= 14]

    imported_action := "Masz nadchodzące terminy odwołań od decyzji US!" { count(upcoming) > 0 }
    imported_action := "" { true }

    imported := {
        "total_decisions": count(us_decisions),
        "with_deadlines": count(decisions_with_deadlines),
        "urgent_count": count(upcoming),
        "action": imported_action,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CIN-3280: Legislative calendar integration (vacatio legis)
# ─────────────────────────────────────────────────────────────────────────────
cin_legislative_calendar(upcoming_laws) = calendar {
    effective_30d := [l | l := upcoming_laws[_]; object.get(l, "days_until_effective", 999) <= 30]
    effective_90d := [l | l := upcoming_laws[_]; object.get(l, "days_until_effective", 999) <= 90]

    calendar := {
        "upcoming_changes": count(upcoming_laws),
        "effective_within_30d": count(effective_30d),
        "effective_within_90d": count(effective_90d),
        "next_change": object.get(upcoming_laws[0], "law_name", "") { count(upcoming_laws) > 0 },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CIN-3290: Build CIN warnings
# ─────────────────────────────────────────────────────────────────────────────
build_cin_warnings(routing, cashflow, us_deadlines, legislative) = warnings {
    channels := object.get(routing, "channels", ["PUSH"])
    escalation := object.get(routing, "escalation_level", "NORMAL")
    week_count := object.get(cashflow, "next_7_days_count", 0)
    urgent_us := object.get(us_deadlines, "urgent_count", 0)

    base := ["📅 TAX CALENDAR SMART NOTIFIER"]

    warn := array.concat(base, [
        sprintf("   🔔 Powiadomienie: %s (kanały: %s)", [escalation, concat(",", channels)]),
    ]) { escalation != "NORMAL" }

    warn := array.concat(base, ["   ✅ Kalendarz bez alertów"]) { escalation == "NORMAL" }

    base2 := warn

    cash_warn := array.concat(base2, [
        sprintf("   💰 Płatności w ciągu 7 dni: %d", [week_count]),
    ]) { week_count > 0 }

    us_warn := array.concat(cash_warn, [
        sprintf("   ⚖️ Terminy US/odwołań: %d w ciągu 14 dni!", [urgent_us]),
    ]) { urgent_us > 0 }

    us_warn := cash_warn { urgent_us == 0 }

    warnings := us_warn
}
