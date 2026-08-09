# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — DAC8 REPORT AUTO-GENERATOR (P13 Priority 3)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.dac8_report_generator
# Report:      RAPORT_P13 Section 7 — Priority 3
# Purpose:     Auto-generate DAC8 reports for 5 platform categories
#              Thresholds: 2000 EUR or 30 transactions
#              Deadline: 31 January; Penalty: up to 5M PLN
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.dac8_report_generator

import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.dac8_report_generator.no_match",
    "package": "jdg.dac8_report_generator",
    "priority": 999999
}

# ── Shared deterministic helpers ─────────────────────────────────────────────

threshold_reached_for(tx_count, revenue_eur) = true if {
    tx_count >= 30
} else = true if {
    revenue_eur >= 2000
} else = false if {
    true
}

compute_dac8_applies(tx_count, revenue_eur, cross_border) = true if {
    threshold_reached_for(tx_count, revenue_eur) == true
    cross_border == true
} else = false if {
    true
}

platform_category_mapping := {
    "RIDE_SHARING": {"dac8_category": "RIDE_SHARING", "data_points": ["driver_name", "driver_tax_id", "total_fares_eur", "number_of_rides", "platform_fees_eur"]},
    "ACCOMMODATION": {"dac8_category": "ACCOMMODATION", "data_points": ["host_name", "host_tax_id", "property_address", "total_rental_eur", "number_of_bookings", "platform_fees_eur"]},
    "PERSONAL_SERVICES": {"dac8_category": "PERSONAL_SERVICES", "data_points": ["seller_name", "seller_tax_id", "total_earnings_eur", "number_of_gigs", "platform_fees_eur"]},
    "GOODS": {"dac8_category": "GOODS_SALE", "data_points": ["seller_name", "seller_tax_id", "total_sales_eur", "number_of_transactions", "platform_fees_eur"]},
    "DIGITAL": {"dac8_category": "DIGITAL_CONTENT", "data_points": ["creator_name", "creator_tax_id", "total_revenue_eur", "number_of_sales", "platform_fees_eur"]}
}

category_info_for(platform_type) = category_info if {
    category_info := object.get(platform_category_mapping, platform_type, platform_category_mapping["GOODS"])
}

progress_for(applies, submitted) = 100 if {
    submitted == true
} else = 75 if {
    applies == true
} else = 0 if {
    true
}

routing_for(applies, submitted) = "BLOCK_AND_ALERT" if {
    applies == true
    submitted == false
} else = "TRIAGE_QUEUE" if {
    applies == true
} else = "" if {
    true
}

status_for(progress, applies) = "SUBMITTED" if {
    progress == 100
} else = "REQUIRED" if {
    applies == true
    progress < 100
} else = "BELOW_THRESHOLD" if {
    true
}

report_requirement_label(applies) = "MUST REPORT!" if {
    applies == true
} else = "below threshold" if {
    true
}

category_reportable(tx_count, revenue_eur) = true if {
    threshold_reached_for(tx_count, revenue_eur) == true
} else = false if {
    true
}

tracker_applies(tx_count, revenue_eur) = threshold if {
    threshold := threshold_reached_for(tx_count, revenue_eur)
}

tracker_status(submitted, days, applies) = "SUBMITTED" if {
    submitted == true
} else = sprintf("%d days to deadline — PREPARE NOW!", [days]) if {
    applies == true
    submitted == false
    days > 60
} else = sprintf("⚠️ %d days — URGENT!", [days]) if {
    applies == true
    submitted == false
    days <= 60
    days > 30
} else = sprintf("🚨 %d days — CRITICAL!", [days]) if {
    applies == true
    submitted == false
    days <= 30
    days > 0
} else = "❌ OVERDUE! Penalty up to 5M PLN!" if {
    applies == true
    submitted == false
    days <= 0
} else = "N/A — below reporting threshold" if {
    true
}

tracker_routing(submitted, days, applies) = "BLOCK_AND_ALERT" if {
    applies == true
    submitted == false
    days <= 30
} else = "TRIAGE_QUEUE" if {
    applies == true
    submitted == false
    days <= 60
} else = "WARNING" if {
    applies == true
    submitted == false
} else = "" if {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# DRG-001: DAC8 REPORT AUTO-GENERATOR — 5 platform categories
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    profile := object.get(input, "jdg_entrepreneur", {})
    object.get(profile, "platform_operator", false) == true

    platform_type := object.get(profile, "platform_type", "GOODS")
    platform_tx_count := object.get(profile, "platform_annual_tx_count", 0)
    platform_revenue_eur := object.get(profile, "platform_annual_revenue_eur", 0)
    platform_cross_border := object.get(profile, "platform_cross_border", false)
    reporting_period := object.get(profile, "tax_year", "2026")
    dac8_applies := compute_dac8_applies(platform_tx_count, platform_revenue_eur, platform_cross_border)
    category_info := category_info_for(platform_type)
    dac8_submitted := object.get(profile, "dac8_submitted", false)
    progress_pct := progress_for(dac8_applies, dac8_submitted)
    routing := routing_for(dac8_applies, dac8_submitted)
    drg_status := status_for(progress_pct, dac8_applies)
    requirement := report_requirement_label(dac8_applies)

    dac8_template := {
        "report_type": "DAC8",
        "reporting_year": reporting_period,
        "platform_type": category_info.dac8_category,
        "platform_operator_name": object.get(profile, "company_name", "N/A"),
        "platform_operator_tax_id": object.get(profile, "nip", "N/A"),
        "total_sellers_reported": platform_tx_count,
        "total_revenue_reported_eur": platform_revenue_eur,
        "threshold_tx": 30,
        "threshold_eur": 2000,
        "required_data_points": category_info.data_points,
        "deadline": "31 stycznia następnego roku",
        "submit_to": "Szef Krajowej Administracji Skarbowej (przez e-US)",
        "legal_basis_report": "DAC8 (EU 2021/514); Art. 45aa OrdPU"
    }

    verdict := {
        "matched": true,
        "rule_id": "jdg.dac8_report_generator.template",
        "package": "jdg.dac8_report_generator",
        "priority": 18501,
        "drg_dac8_applies": dac8_applies,
        "drg_platform_type": platform_type,
        "drg_platform_tx_count": platform_tx_count,
        "drg_platform_revenue_eur": platform_revenue_eur,
        "drg_dac8_template": dac8_template,
        "drg_dac8_deadline": "31 stycznia następnego roku",
        "drg_dac8_penalty_pln": 5000000,
        "drg_progress_pct": progress_pct,
        "drg_status": drg_status,
        "_routing": routing,
        "_routing_reason": sprintf("DAC8: %s platform — %d sellers / %.0f EUR — %s. Deadline: %s. Penalty: %.0fM PLN", [platform_type, platform_tx_count, platform_revenue_eur, requirement, "31 stycznia następnego roku", 5]),
        "_legal_basis": "DAC8 (EU 2021/514); Art. 45aa OrdPU",
        "_description": "DRG-001: DAC8 Report Auto-Generator — template for 5 platform categories with threshold validation"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DRG-002: DAC8 MULTI-CATEGORY AGGREGATOR
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    profile := object.get(input, "jdg_entrepreneur", {})
    object.get(profile, "platform_operator", false) == true
    object.get(profile, "platform_multi_category", false) == true

    categories := object.get(profile, "platform_categories_active", [])
    tx_per_category := object.get(profile, "platform_tx_per_category", {})
    revenue_per_category := object.get(profile, "platform_revenue_per_category", {})
    total_tx := sum([v | tx_per_category[k] = v])
    total_revenue := sum([v | revenue_per_category[k] = v])

    category_reports := [
        {
            "category": cat,
            "tx_count": object.get(tx_per_category, cat, 0),
            "revenue_eur": object.get(revenue_per_category, cat, 0),
            "reportable": category_reportable(object.get(tx_per_category, cat, 0), object.get(revenue_per_category, cat, 0))
        }
        | cat := categories[_]
    ]
    reportable_count := count([r | r := category_reports[_]; r.reportable == true])

    verdict := {
        "matched": true,
        "rule_id": "jdg.dac8_report_generator.multi_category",
        "package": "jdg.dac8_report_generator",
        "priority": 18502,
        "drg_multi_categories": categories,
        "drg_total_tx": total_tx,
        "drg_total_revenue_eur": total_revenue,
        "drg_category_reports": category_reports,
        "drg_reportable_categories": reportable_count,
        "drg_dac8_deadline": "31 stycznia następnego roku",
        "_routing": "",
        "_routing_reason": sprintf("DAC8 Multi-Category: %d categories, %d reportable, %.0f tx / %.0f EUR total", [count(categories), reportable_count, total_tx, total_revenue]),
        "_legal_basis": "DAC8 (EU 2021/514)",
        "_description": "DRG-002: DAC8 Multi-Category Aggregator"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DRG-003: DAC8 DEADLINE TRACKER WITH REMINDERS
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    profile := object.get(input, "jdg_entrepreneur", {})
    object.get(profile, "platform_operator", false) == true
    platform_tx_count := object.get(profile, "platform_annual_tx_count", 0)
    platform_revenue_eur := object.get(profile, "platform_annual_revenue_eur", 0)
    applies := tracker_applies(platform_tx_count, platform_revenue_eur)
    dac8_submitted := object.get(profile, "dac8_submitted", false)
    days_to_deadline := object.get(profile, "days_to_dac8_deadline", 365)
    dac8_status := tracker_status(dac8_submitted, days_to_deadline, applies)
    routing := tracker_routing(dac8_submitted, days_to_deadline, applies)

    verdict := {
        "matched": true,
        "rule_id": "jdg.dac8_report_generator.deadline_tracker",
        "package": "jdg.dac8_report_generator",
        "priority": 18503,
        "drg_dac8_status": dac8_status,
        "drg_dac8_submitted": dac8_submitted,
        "drg_days_to_deadline": days_to_deadline,
        "drg_deadline": "31 stycznia",
        "_routing": routing,
        "_routing_reason": sprintf("DAC8 Deadline: %s", [dac8_status]),
        "_legal_basis": "DAC8 (EU 2021/514); Art. 45aa OrdPU",
        "_description": "DRG-003: DAC8 Deadline Tracker with escalation reminders"
    }
}
