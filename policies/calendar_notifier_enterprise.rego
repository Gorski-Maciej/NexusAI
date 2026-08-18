# NexusAI JDG Enterprise — Tax Calendar Smart Notifier
# Public functions: cin_notification_router, cin_cashflow_planner,
# cin_us_deadline_importer, cin_legislative_calendar, build_cin_warnings.

package jdg.enterprise.calendar_notifier

notification_email_flag(days) = 1 {
    days <= 7
} else = 0

notification_ede_flag(days) = 1 {
    days <= 3
} else = 0

notification_sms_flag(amount, days) = 1 {
    amount > 10000
    days <= 3
} else = 0

notification_channels(email_flag, ede_flag, sms_flag) = channels {
    base := ["PUSH"]
    with_email := notification_append(base, "EMAIL", email_flag)
    with_ede := notification_append(with_email, "EDE", ede_flag)
    channels := notification_append(with_ede, "SMS", sms_flag)
}

notification_append(base, channel, 1) = array.concat(base, [channel])
notification_append(base, _, 0) = base

notification_escalation(days) = "OVERDUE" {
    days <= 0
} else = "URGENT" {
    days > 0
    days <= 3
} else = "WARNING" {
    days > 3
    days <= 7
} else = "NORMAL"

cin_notification_router(event) = routing {
    event_type := object.get(event, "type", "DEADLINE")
    days_remaining := object.get(event, "days_remaining", 30)
    amount_involved := object.get(event, "amount_pln", 0)
    email_flag := notification_email_flag(days_remaining)
    ede_flag := notification_ede_flag(days_remaining)
    sms_flag := notification_sms_flag(amount_involved, days_remaining)
    channels := notification_channels(email_flag, ede_flag, sms_flag)
    escalation_level := notification_escalation(days_remaining)
    routing := {
        "event_type": event_type,
        "days_remaining": days_remaining,
        "channels": channels,
        "escalation_level": escalation_level
    }
}

cashflow_recommendation(next_7_days) = "Zarezerwuj środki na nadchodzące płatności" {
    count(next_7_days) > 0
} else = "Brak pilnych płatności"

cin_cashflow_planner(upcoming_deadlines, balance) = plan {
    next_7_days := [d | d := upcoming_deadlines[_]; object.get(d, "days_remaining", 999) <= 7]
    next_30_days := [d | d := upcoming_deadlines[_]; object.get(d, "days_remaining", 999) <= 30]
    recommendation := cashflow_recommendation(next_7_days)
    plan := {
        "current_balance_pln": balance,
        "next_7_days_count": count(next_7_days),
        "next_30_days_count": count(next_30_days),
        "recommendation": recommendation
    }
}

us_deadline_action(upcoming) = "Masz nadchodzące terminy odwołań od decyzji US!" {
    count(upcoming) > 0
} else = ""

cin_us_deadline_importer(us_decisions) = imported {
    decisions_with_deadlines := [d | d := us_decisions[_]; object.get(d, "appeal_deadline_days", 0) > 0]
    upcoming := [d | d := decisions_with_deadlines[_]; object.get(d, "appeal_deadline_days", 999) <= 14]
    imported := {
        "total_decisions": count(us_decisions),
        "with_deadlines": count(decisions_with_deadlines),
        "urgent_count": count(upcoming),
        "action": us_deadline_action(upcoming)
    }
}

next_law_name(laws) = object.get(laws[0], "law_name", "") {
    count(laws) > 0
} else = ""

cin_legislative_calendar(upcoming_laws) = calendar {
    effective_30d := [law | law := upcoming_laws[_]; object.get(law, "days_until_effective", 999) <= 30]
    effective_90d := [law | law := upcoming_laws[_]; object.get(law, "days_until_effective", 999) <= 90]
    calendar := {
        "upcoming_changes": count(upcoming_laws),
        "effective_within_30d": count(effective_30d),
        "effective_within_90d": count(effective_90d),
        "next_change": next_law_name(upcoming_laws)
    }
}

calendar_base_warnings(escalation, channels) = [
    "📅 TAX CALENDAR SMART NOTIFIER",
    sprintf("   🔔 Powiadomienie: %s (kanały: %s)", [escalation, concat(",", channels)])
] {
    escalation != "NORMAL"
} else = [
    "📅 TAX CALENDAR SMART NOTIFIER",
    "   ✅ Kalendarz bez alertów"
]

build_cin_warnings(routing, cashflow, us_deadlines, _) = warnings {
    channels := object.get(routing, "channels", ["PUSH"])
    escalation := object.get(routing, "escalation_level", "NORMAL")
    week_count := object.get(cashflow, "next_7_days_count", 0)
    urgent_us := object.get(us_deadlines, "urgent_count", 0)
    base := calendar_base_warnings(escalation, channels)
    with_cash := calendar_cash_warnings(base, week_count)
    warnings := calendar_us_warnings(with_cash, urgent_us)
}

calendar_cash_warnings(base, week_count) = array.concat(base, [sprintf("   💰 Płatności w ciągu 7 dni: %d", [week_count])]) {
    week_count > 0
} else = base

calendar_us_warnings(base, urgent_us) = array.concat(base, [sprintf("   ⚖️ Terminy US/odwołań: %d w ciągu 14 dni!", [urgent_us])]) {
    urgent_us > 0
} else = base
