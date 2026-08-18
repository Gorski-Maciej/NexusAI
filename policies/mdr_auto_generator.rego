# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — MDR AUTO-GENERATOR (P13 Priority 1)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.mdr_auto_generator
# Report:      RAPORT_P13 Section 7 — Priority 1
# Purpose:     Auto-generate MDR-1/MDR-3 forms with deadline tracking
#              Sankcja: do 21 000 000 PLN za brak raportowania
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.mdr_auto_generator

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.mdr_auto_generator.no_match",
    "package": "jdg.mdr_auto_generator",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# MG-001: MDR-1 AUTO-GENERATOR (Promotor)
# Generuje szablon formularza MDR-1 z automatycznie wykrytymi hallmarkami
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.mdr, "role", "") == "PROMOTER"
    object.get(input.document, "mdr_scheme_detected", false) == true

    hallmarks := []
    hallmarks := array.concat(hallmarks, ["A1_confidentiality"]) { object.get(input.invoice, "confidentiality_clause", false) }
    hallmarks := array.concat(hallmarks, ["A2_success_fee"]) { object.get(input.invoice, "success_fee_structure", false) }
    hallmarks := array.concat(hallmarks, ["A3_standardized"]) { object.get(input.invoice, "standardized_documentation", false) }
    hallmarks := array.concat(hallmarks, ["A4_loss_buying"]) { object.get(input.invoice, "loss_buying_scheme", false) }
    hallmarks := array.concat(hallmarks, ["A5_conversion"]) { object.get(input.invoice, "tax_benefit_type", "") == "CONVERSION" }
    hallmarks := array.concat(hallmarks, ["A6_circular"]) { object.get(input.invoice, "circular_flow", false) }
    hallmarks := array.concat(hallmarks, ["A7_double_deduction"]) { object.get(input.invoice, "double_deduction_detected", false) }
    hallmarks := array.concat(hallmarks, ["B1_loss_group"]) { object.get(input.invoice, "loss_utilization_group", false) }
    hallmarks := array.concat(hallmarks, ["B4_tax_haven"]) { object.get(input.invoice, "tax_haven_involved", false) }
    hallmarks := array.concat(hallmarks, ["C1_C4_cross_border"]) { object.get(input.invoice, "cross_border_deduction_related", false) }
    hallmarks := array.concat(hallmarks, ["C5_tp_gap"]) { object.get(input.invoice, "tp_methodology_gap", false) }
    hallmarks := array.concat(hallmarks, ["D1_ip_transfer"]) { object.get(input.invoice, "ip_transfer_no_remuneration", false) }
    hallmarks := array.concat(hallmarks, ["E1_crs_bypass"]) { object.get(input.invoice, "crs_bypass_detected", false) }
    hallmarks := array.concat(hallmarks, ["MBT_required"]) { object.get(input.invoice, "mbt_required", false) }

    hallmarks_count := count(hallmarks)
    deadline_days := 30

    mdr1_template := {
        "form": "MDR-1",
        "submitter": "PROMOTER",
        "hallmarks_detected": hallmarks,
        "hallmarks_count": hallmarks_count,
        "deadline_days": deadline_days,
        "deadline_date_format": sprintf("%d dni od udostępnienia schematu", [deadline_days]),
        "submit_to": "Szef Krajowej Administracji Skarbowej (przez e-US)",
        "legal_basis": "Art. 86f § 1 OrdPU",
        "penalty_non_submission_pln": 21000000,
        "quarterly_update": "MDR-4 — do końca miesiąca po kwartale",
        "retention_period": "6 lat"
    }

    verdict := {
        "matched": true,
        "rule_id": "jdg.mdr_auto_generator.mdr1_promoter",
        "package": "jdg.mdr_auto_generator",
        "priority": 18001,
        "mg_mdr1_ready": true,
        "mg_mdr1_template": mdr1_template,
        "mg_days_remaining": deadline_days,
        "mg_warning": "MDR-1 MUST be submitted within 30 days! Penalty: 21M PLN!",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": sprintf("MDR-1: %d hallmarks detected — deadline %d days. Penalty up to 21M PLN!", [hallmarks_count, deadline_days]),
        "_legal_basis": "Art. 86a-86o OrdPU; DAC6 (EU 2018/822)",
        "_description": "MG-001: MDR-1 Auto-Generator for promoter — template with all detected hallmarks"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MG-002: MDR-3 AUTO-GENERATOR (Korzystający)
# Generuje szablon formularza MDR-3
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.mdr, "role", "") == "USER"
    object.get(input.document, "mdr_scheme_detected", false) == true

    first_implementation_date := object.get(input.mdr, "first_implementation_date", "unknown")
    scheme_id := object.get(input.mdr, "scheme_id", "unknown")
    scheme_description := object.get(input.invoice, "mdr_scheme_description", "scheme")
    tax_advantage_pln := object.get(input.invoice, "tax_benefit_amount", 0)
    has_cross_border := object.get(input.invoice, "cross_border_element", false)

    mdr3_template := {
        "form": "MDR-3",
        "submitter": "USER (Korzystający)",
        "scheme_id": scheme_id,
        "scheme_description": scheme_description,
        "first_implementation_date": first_implementation_date,
        "tax_advantage_pln": tax_advantage_pln,
        "has_cross_border_element": has_cross_border,
        "deadline": "30 dni od pierwszej czynności wykonawczej",
        "submit_to": "Szef Krajowej Administracji Skarbowej (przez e-US)",
        "legal_basis": "Art. 86f § 1 OrdPU",
        "penalty_non_submission_pln": 21000000
    }

    verdict := {
        "matched": true,
        "rule_id": "jdg.mdr_auto_generator.mdr3_user",
        "package": "jdg.mdr_auto_generator",
        "priority": 18002,
        "mg_mdr3_ready": true,
        "mg_mdr3_template": mdr3_template,
        "mg_tax_advantage": tax_advantage_pln,
        "mg_warning": "MDR-3 MUST be submitted within 30 days of first implementation! 21M PLN penalty!",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": sprintf("MDR-3: scheme '%s' — submit within 30 days of first implementation. Penalty up to 21M PLN!", [scheme_id]),
        "_legal_basis": "Art. 86a-86o OrdPU; DAC6",
        "_description": "MG-002: MDR-3 Auto-Generator for user — template with scheme details"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MG-003: MDR DEADLINE TRACKER
# Monitoruje terminy i generuje alerty eskalacji
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.document, "mdr_scheme_detected", false) == true

    scheme_available_date := object.get(input.mdr, "scheme_available_date", 0)
    first_impl_date := object.get(input.mdr, "first_implementation_date", 0)
    mdr3_submitted := object.get(input.mdr, "mdr3_submitted", false)
    mdr_overdue := object.get(input.document, "mdr_overdue", false)
    role := object.get(input.mdr, "role", "UNKNOWN")

    days_since_scheme := 0 { scheme_available_date == 0 }
    days_since_impl := 0 { first_impl_date == 0 }

    days_remaining_scheme := 30 - days_since_scheme { days_since_scheme > 0 }
    days_remaining_impl := 30 - days_since_impl { days_since_impl > 0 }

    escalation_level := "OK" { mdr3_submitted }
    escalation_level := "GREEN" { not mdr3_submitted; days_remaining_scheme > 14 }
    escalation_level := "YELLOW" { not mdr3_submitted; days_remaining_scheme <= 14; days_remaining_scheme > 7 }
    escalation_level := "ORANGE" { not mdr3_submitted; days_remaining_scheme <= 7; days_remaining_scheme > 0 }
    escalation_level := "RED" { not mdr3_submitted; days_remaining_scheme <= 0 or mdr_overdue }
    escalation_level := "RED_CRITICAL" { mdr_overdue; not mdr3_submitted }

    routing := ""
    routing := "BLOCK_AND_ALERT" { escalation_level == "RED_CRITICAL" or escalation_level == "RED" }
    routing := "TRIAGE_QUEUE" { escalation_level == "ORANGE" }
    routing := "WARNING" { escalation_level == "YELLOW" }

    mg_next_action := "SUBMIT NOW!" { escalation_level in {"RED", "RED_CRITICAL"} }
    mg_next_action := "PREPARE submission" { escalation_level == "ORANGE" }
    mg_next_action := "Monitor deadline" { escalation_level == "YELLOW" }
    mg_next_action := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.mdr_auto_generator.deadline_tracker",
        "package": "jdg.mdr_auto_generator",
        "priority": 18003,
        "mg_role": role,
        "mg_escalation": escalation_level,
        "mg_mdr3_submitted": mdr3_submitted,
        "mg_days_remaining_estimate": days_remaining_scheme,
        "mg_overdue": mdr_overdue,
        "mg_next_action": mg_next_action,
        "_routing": routing,
        "_routing_reason": sprintf("MDR Deadline: %s — %d days remaining. Status: %s", [role, days_remaining_scheme, escalation_level]),
        "_legal_basis": "Art. 86f, 86o OrdPU",
        "_description": "MG-003: MDR Deadline Tracker with escalation levels (GREEN→YELLOW→ORANGE→RED→RED_CRITICAL)"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MG-004: MDR QUARTERLY MDR-4 REMINDER
# Przypomnienie o kwartalnej aktualizacji MDR-4
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "mdr4_due", false) == true

    mdr4_deadlines := {
        "Q1": "30 kwietnia",
        "Q2": "31 lipca",
        "Q3": "31 października",
        "Q4": "31 stycznia (następnego roku)"
    }

    current_quarter := object.get(input.mdr, "current_quarter", "Q1")
    deadline := object.get(mdr4_deadlines, current_quarter, "unknown")

    verdict := {
        "matched": true,
        "rule_id": "jdg.mdr_auto_generator.mdr4_reminder",
        "package": "jdg.mdr_auto_generator",
        "priority": 18004,
        "mg_mdr4_due": true,
        "mg_mdr4_quarter": current_quarter,
        "mg_mdr4_deadline": deadline,
        "mg_mdr4_form": "MDR-4",
        "_routing": "WARNING",
        "_routing_reason": sprintf("MDR-4: Quarterly update for %s due by %s", [current_quarter, deadline]),
        "_legal_basis": "Art. 86k OrdPU",
        "_description": "MG-004: MDR-4 Quarterly reminder — submit by end of month after quarter"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MG-005: MDR SANCTION CALCULATOR
# Kalkulator potencjalnej kary za brak zgłoszenia MDR
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "mdr3_submitted", false) == false

    tax_advantage := object.get(input.invoice, "tax_benefit_amount", 0)
    hallmarks_detected := 0

    # Count applicable hallmarks from input fields
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "confidentiality_clause", false) }
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "success_fee_structure", false) }
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "cross_border_element", false) }
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "tax_haven_involved", false) }
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "double_deduction_detected", false) }
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "crs_bypass_detected", false) }
    hallmarks_detected := hallmarks_detected + 1 { object.get(input.invoice, "hybrid_mismatch_detected", false) }

    max_admin_penalty := 21000000
    penalty_factor := 0.1 { hallmarks_detected <= 2 }
    penalty_factor := 0.3 { hallmarks_detected >= 3; hallmarks_detected <= 4 }
    penalty_factor := 0.5 { hallmarks_detected >= 5; hallmarks_detected <= 6 }
    penalty_factor := 0.8 { hallmarks_detected >= 7 }
    else := 0.2 { true }

    estimated_penalty := floor(max_admin_penalty * penalty_factor * 100) / 100
    kks_daily_rates := 720
    kks_daily_rate_pln := floor(object.get(input.jdg_entrepreneur, "daily_rate_pln", 116.33) * 100) / 100
    kks_max_penalty := floor(kks_daily_rates * kks_daily_rate_pln * 100) / 100

    total_exposure := estimated_penalty + kks_max_penalty

    verdict := {
        "matched": true,
        "rule_id": "jdg.mdr_auto_generator.sanction_calculator",
        "package": "jdg.mdr_auto_generator",
        "priority": 18005,
        "mg_hallmarks_detected": hallmarks_detected,
        "mg_tax_advantage": tax_advantage,
        "mg_max_admin_penalty": max_admin_penalty,
        "mg_penalty_factor": penalty_factor,
        "mg_estimated_admin_penalty": estimated_penalty,
        "mg_kks_max_penalty": kks_max_penalty,
        "mg_total_penalty_exposure": total_exposure,
        "mg_kks_daily_rates": kks_daily_rates,
        "_routing": "WARNING",
        "_routing_reason": sprintf("MDR Sanction: %d hallmarks → est. %.0f PLN admin + %.0f PLN KKS = %.0f PLN total exposure", [hallmarks_detected, estimated_penalty, kks_max_penalty, total_exposure]),
        "_legal_basis": "Art. 86o OrdPU; Art. 54-56 KKS",
        "_description": "MG-005: MDR Sanction Calculator — estimate admin penalty + KKS exposure based on hallmarks"
    }
}
