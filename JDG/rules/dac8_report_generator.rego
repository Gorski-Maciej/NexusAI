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
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.dac8_report_generator.no_match",
    "package": "jdg.dac8_report_generator",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# DRG-001: DAC8 REPORT AUTO-GENERATOR — 5 platform categories
# Automatycznie generuje strukturę raportu DAC8 dla platform cyfrowych
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "platform_operator", false) == true

    platform_type := object.get(input.jdg_entrepreneur, "platform_type", "GOODS")
    platform_tx_count := object.get(input.jdg_entrepreneur, "platform_annual_tx_count", 0)
    platform_revenue_eur := object.get(input.jdg_entrepreneur, "platform_annual_revenue_eur", 0)
    platform_cross_border := object.get(input.jdg_entrepreneur, "platform_cross_border", false)
    reporting_period := object.get(input.jdg_entrepreneur, "tax_year", "2026")

    threshold_tx := 30
    threshold_eur := 2000
    dac8_applies := (platform_tx_count >= threshold_tx or platform_revenue_eur >= threshold_eur) and platform_cross_border

    platform_category_mapping := {
        "RIDE_SHARING": {"dac8_category": "RIDE_SHARING", "data_points": ["driver_name", "driver_tax_id", "total_fares_eur", "number_of_rides", "platform_fees_eur"]},
        "ACCOMMODATION": {"dac8_category": "ACCOMMODATION", "data_points": ["host_name", "host_tax_id", "property_address", "total_rental_eur", "number_of_bookings", "platform_fees_eur"]},
        "PERSONAL_SERVICES": {"dac8_category": "PERSONAL_SERVICES", "data_points": ["seller_name", "seller_tax_id", "total_earnings_eur", "number_of_gigs", "platform_fees_eur"]},
        "GOODS": {"dac8_category": "GOODS_SALE", "data_points": ["seller_name", "seller_tax_id", "total_sales_eur", "number_of_transactions", "platform_fees_eur"]},
        "DIGITAL": {"dac8_category": "DIGITAL_CONTENT", "data_points": ["creator_name", "creator_tax_id", "total_revenue_eur", "number_of_sales", "platform_fees_eur"]}
    }

    category_info := object.get(platform_category_mapping, platform_type, platform_category_mapping["GOODS"])

    dac8_template := {
        "report_type": "DAC8",
        "reporting_year": reporting_period,
        "platform_type": category_info.dac8_category,
        "platform_operator_name": object.get(input.jdg_entrepreneur, "company_name", "N/A"),
        "platform_operator_tax_id": object.get(input.jdg_entrepreneur, "nip", "N/A"),
        "total_sellers_reported": platform_tx_count,
        "total_revenue_reported_eur": platform_revenue_eur,
        "threshold_tx": threshold_tx,
        "threshold_eur": threshold_eur,
        "required_data_points": category_info.data_points,
        "deadline": "31 stycznia następnego roku",
        "submit_to": "Szef Krajowej Administracji Skarbowej (przez e-US)",
        "legal_basis_report": "DAC8 (EU 2021/514); Art. 45aa OrdPU"
    }

    dac8_deadline := "31 stycznia następnego roku"
    dac8_penalty := 5000000

    progress_pct := 100 { object.get(input.jdg_entrepreneur, "dac8_submitted", false) }
    progress_pct := 75 { dac8_applies; not object.get(input.jdg_entrepreneur, "dac8_submitted", false) }
    progress_pct := 0 { not dac8_applies }

    routing := "BLOCK_AND_ALERT" { dac8_applies and not object.get(input.jdg_entrepreneur, "dac8_submitted", false) }
    routing := "TRIAGE_QUEUE" { dac8_applies }
    routing := "" { true }

    drg_status := "SUBMITTED" { progress_pct == 100 }
    drg_status := "REQUIRED" { dac8_applies; progress_pct < 100 }
    drg_status := "BELOW_THRESHOLD" { not dac8_applies }

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
        "drg_dac8_deadline": dac8_deadline,
        "drg_dac8_penalty_pln": dac8_penalty,
        "drg_progress_pct": progress_pct,
        "drg_status": drg_status,
        "_routing": routing,
        "_routing_reason": sprintf("DAC8: %s platform — %d sellers / %.0f EUR — %s. Deadline: %s. Penalty: %.0fM PLN", [platform_type, platform_tx_count, platform_revenue_eur, "MUST REPORT!" { dac8_applies } else "below threshold", dac8_deadline, dac8_penalty / 1000000]),
        "_legal_basis": "DAC8 (EU 2021/514); Art. 45aa OrdPU",
        "_description": "DRG-001: DAC8 Report Auto-Generator — template for 5 platform categories with threshold validation"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DRG-002: DAC8 MULTI-CATEGORY AGGREGATOR
# Agregacja danych z wielu kategorii platform
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "platform_operator", false) == true
    object.get(input.jdg_entrepreneur, "platform_multi_category", false) == true

    categories := object.get(input.jdg_entrepreneur, "platform_categories_active", [])
    tx_per_category := object.get(input.jdg_entrepreneur, "platform_tx_per_category", {})
    revenue_per_category := object.get(input.jdg_entrepreneur, "platform_revenue_per_category", {})

    total_tx := sum([v | tx_per_category[k] = v])
    total_revenue := sum([v | revenue_per_category[k] = v])

    category_reports := [
        {
            "category": cat,
            "tx_count": object.get(tx_per_category, cat, 0),
            "revenue_eur": object.get(revenue_per_category, cat, 0),
            "reportable": object.get(tx_per_category, cat, 0) >= 30 or object.get(revenue_per_category, cat, 0) >= 2000
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
# Monitorowanie terminu DAC8 z alertami
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "platform_operator", false) == true
    platform_tx_count := object.get(input.jdg_entrepreneur, "platform_annual_tx_count", 0)
    platform_revenue_eur := object.get(input.jdg_entrepreneur, "platform_annual_revenue_eur", 0)
    dac8_applies := platform_tx_count >= 30 or platform_revenue_eur >= 2000

    dac8_deadline := "31 stycznia"
    dac8_submitted := object.get(input.jdg_entrepreneur, "dac8_submitted", false)
    days_to_deadline := object.get(input.jdg_entrepreneur, "days_to_dac8_deadline", 365)

    dac8_status := "SUBMITTED" { dac8_submitted }
    dac8_status := sprintf("%d days to deadline — PREPARE NOW!", [days_to_deadline]) { dac8_applies; not dac8_submitted; days_to_deadline > 60 }
    dac8_status := sprintf("⚠️ %d days — URGENT!", [days_to_deadline]) { dac8_applies; not dac8_submitted; days_to_deadline <= 60; days_to_deadline > 30 }
    dac8_status := sprintf("🚨 %d days — CRITICAL!", [days_to_deadline]) { dac8_applies; not dac8_submitted; days_to_deadline <= 30; days_to_deadline > 0 }
    dac8_status := sprintf("❌ OVERDUE! Penalty up to 5M PLN!") { dac8_applies; not dac8_submitted; days_to_deadline <= 0 }
    dac8_status := "N/A — below reporting threshold" { not dac8_applies }

    routing := "BLOCK_AND_ALERT" { dac8_applies; not dac8_submitted; days_to_deadline <= 0 }
    routing := "BLOCK_AND_ALERT" { dac8_applies; not dac8_submitted; days_to_deadline <= 30 }
    routing := "TRIAGE_QUEUE" { dac8_applies; not dac8_submitted; days_to_deadline <= 60 }
    routing := "WARNING" { dac8_applies; not dac8_submitted }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.dac8_report_generator.deadline_tracker",
        "package": "jdg.dac8_report_generator",
        "priority": 18503,
        "drg_dac8_status": dac8_status,
        "drg_dac8_submitted": dac8_submitted,
        "drg_days_to_deadline": days_to_deadline,
        "drg_deadline": dac8_deadline,
        "_routing": routing,
        "_routing_reason": sprintf("DAC8 Deadline: %s", [dac8_status]),
        "_legal_basis": "DAC8 (EU 2021/514); Art. 45aa OrdPU",
        "_description": "DRG-003: DAC8 Deadline Tracker with escalation reminders"
    }
}
