# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: Zwolnienia PIT (młodzi, powrót, 4+, senior) P580-P588
# ═══════════════════════════════════════════════════════════════════════════════
#
#
# METADATA
# title: JDG Package — pit.exemptions
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.pit.exemptions
# deprecated: false
#
# First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.6 + Doc 33 (Art. 21 PIT)
#
# package: jdg.pit.exemptions
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.exemptions

import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.pit.exemptions.no_match",
    "package": "jdg.pit.exemptions", "priority": 598
}

# ═══════════════════════════════════════════════════════════════════════════════
# P508: pit_revenue_exclusions — Wyłączenia z przychodów JDG
# Doc 26 §III: Identyfikacja wpływów NIEstanowiących przychodu z działalności
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.exemptions.revenue_exclusions",
    "package": "jdg.pit.exemptions", "priority": 508,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "pit_revenue_included": revenue_included,
    "revenue_classification": revenue_class,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 3 PIT",
    "_warnings": [warning_msg]
} {
    input.invoice.direction == "INCOME"
    income_source := object.get(input.invoice, "income_source", "")
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # VAT refund — NIE jest przychodem
    revenue_included = false { income_source == "VAT_REFUND" }
    revenue_class = "VAT_REFUND_NOT_REVENUE" { income_source == "VAT_REFUND" }
    warning_msg = "Zwrot VAT — NIE stanowi przychodu z działalności" { income_source == "VAT_REFUND" }

    # ZUS overpayment refund — NIE jest przychodem (jeśli składki nie były KUP)
    revenue_included = false { income_source == "ZUS_OVERPAYMENT_REFUND" }
    revenue_class = "ZUS_REFUND_NOT_REVENUE" { income_source == "ZUS_OVERPAYMENT_REFUND" }
    warning_msg = "Zwrot nadpłaty ZUS — NIE stanowi przychodu (jeśli składki nie były KUP)" { income_source == "ZUS_OVERPAYMENT_REFUND" }

    # Insurance compensation for lost revenue — JEST przychodem
    revenue_included = true { income_source == "INSURANCE_COMPENSATION" }
    revenue_class = "INSURANCE_IS_REVENUE" { income_source == "INSURANCE_COMPENSATION" }
    warning_msg = "Odszkodowanie za utracone przychody — STANOWI przychód z działalności" { income_source == "INSURANCE_COMPENSATION" }

    # Damages for assets — NIE jest przychodem
    revenue_included = false { income_source == "DAMAGES_FOR_ASSET" }
    revenue_class = "DAMAGES_NOT_REVENUE" { income_source == "DAMAGES_FOR_ASSET" }
    warning_msg = "Odszkodowanie za składniki majątku — NIE stanowi przychodu" { income_source == "DAMAGES_FOR_ASSET" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P580: pit_exemption_young — Ulga dla młodych (<26 lat) do 85 528 PLN
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.young",
    "package": "jdg.pit.exemptions", "priority": 580,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.00", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "YOUNG", "exemption_limit": thresholds.pit.pit_relief_shared_limit,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
    "_warnings": [sprintf("Ulga dla młodych — zwolnienie z PIT do %.0f PLN rocznie", [thresholds.pit.pit_relief_shared_limit])]
} {
    age := object.get(input.jdg_entrepreneur, "age", 99)
    age <= 26
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum <= thresholds.pit.pit_relief_shared_limit
    # Guard źródła dochodu: ulga dla młodych dotyczy TYLKO pracy/działalności/zlecenia, NIE najmu prywatnego
    income_source := object.get(input.jdg_entrepreneur, "income_source_type", "EMPLOYMENT")
    income_source in {"EMPLOYMENT", "JDG", "ZLECENIE"}
}

# ── P581: pit_exemption_young_revoked — Ulga dla młodych ANULOWANA (przekroczenie limitu) ──
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.young_revoked",
    "package": "jdg.pit.exemptions", "priority": 581,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.12", "pit_bracket": "LOW",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "YOUNG_REVOKED",
    "exemption_revoked_reason": "LIMIT_EXCEEDED",
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Ulga dla młodych ANULOWANA — przekroczony limit 85 528 PLN (dochód: %.2f PLN)", [cum]),
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
    "_warnings": [sprintf("ULGA DLA MŁODYCH ANULOWANA! Dochód %.2f PLN przekroczył limit 85 528 PLN. Od nadwyżki zapłacisz PIT 12%%. Dopłać zaległy podatek w najbliższym terminie płatności.", [cum])]
} {
    age := object.get(input.jdg_entrepreneur, "age", 99)
    age <= 26
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum > thresholds.pit.pit_relief_shared_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P582: pit_exemption_return — Ulga na powrót (art. 21 ust. 1 pkt 152 PIT)
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.return",
    "package": "jdg.pit.exemptions", "priority": 582,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.00", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "RETURN", "exemption_limit": thresholds.pit.pit_relief_shared_limit, "exemption_years_remaining": 4 - used_years,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 152 PIT",
    "_warnings": ["Ulga na powrót — 4 lata zwolnienia"]
} {
    input.jdg_entrepreneur.return_from_emigration == true
    used_years := object.get(input.jdg_entrepreneur, "return_years_used", 0)
    used_years < 4
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum <= thresholds.pit.pit_relief_shared_limit
    income_source := object.get(input.jdg_entrepreneur, "income_source_type", "EMPLOYMENT")
    income_source in {"EMPLOYMENT", "JDG", "ZLECENIE"}
}

# ── P583: pit_exemption_return_revoked — Ulga na powrót ANULOWANA (limit) ──
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.return_revoked",
    "package": "jdg.pit.exemptions", "priority": 583,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.12", "pit_bracket": "LOW",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "RETURN_REVOKED",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Ulga na powrót ANULOWANA — limit przekroczony",
    "_legal_basis": "Art. 21 ust. 1 pkt 152 PIT",
    "_warnings": ["Ulga na powrót — przekroczono limit 85 528 PLN. Dopłać zaległy PIT."]
} {
    input.jdg_entrepreneur.return_from_emigration == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum > thresholds.pit.pit_relief_shared_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P584: pit_exemption_family_4plus — Ulga 4+ dzieci
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.family_4plus",
    "package": "jdg.pit.exemptions", "priority": 584,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.00", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "FAMILY_4PLUS", "exemption_limit": thresholds.pit.pit_relief_shared_limit,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT",
    "_warnings": ["Ulga 4+ — zwolnienie z PIT"]
} {
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    children >= 4
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum <= thresholds.pit.pit_relief_shared_limit
    income_source := object.get(input.jdg_entrepreneur, "income_source_type", "EMPLOYMENT")
    income_source in {"EMPLOYMENT", "JDG", "ZLECENIE"}
}

# ── P585: pit_exemption_family_4plus_revoked — Ulga 4+ ANULOWANA ──
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.family_4plus_revoked",
    "package": "jdg.pit.exemptions", "priority": 585,
    "pit_form": pit_form, "pit_rate": "0.12", "pit_bracket": "LOW",
    "exemption": "FAMILY_4PLUS_REVOKED",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Ulga 4+ ANULOWANA — limit przekroczony",
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT",
    "_warnings": ["Ulga 4+ — przekroczono limit 85 528 PLN. Dopłać PIT od nadwyżki."]
} {
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    children >= 4
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum > thresholds.pit.pit_relief_shared_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P586: pit_exemption_working_senior — Ulga dla pracujących emerytów
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.working_senior",
    "package": "jdg.pit.exemptions", "priority": 586,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.00", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "WORKING_SENIOR", "exemption_limit": thresholds.pit.pit_relief_shared_limit,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 154 PIT",
    "_warnings": ["Ulga dla pracujących emerytów"]
} {
    input.jdg_entrepreneur.is_working_senior == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P588: pit_exemption_interactions — Wspólny limit 85 528 PLN
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.shared_limit",
    "package": "jdg.pit.exemptions", "priority": 588,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption_shared_limit": thresholds.pit.pit_relief_shared_limit,
    "exemption_warning": sprintf("Wspólny limit %.0f PLN dla ulg PIT-0 (młodzi, powrót, 4+, senior)", [thresholds.pit.pit_relief_shared_limit]),
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT",
    "_warnings": [sprintf("UWAGA: Ulgi PIT-0 mają WSPÓLNY limit %.0f PLN rocznie!", [thresholds.pit.pit_relief_shared_limit])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR", "LUMP_SUM"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P589: pit_exemption_shared_limit_monitor — Monitor wspólnego limitu PIT-0
# RAPORT_GLM52_P05 (INN-05). Trigger: input.pit_exemption_monitor_check == true.
# Art. 21 ust. 1 pkt 148-154 PIT: łączny limit 85 528 zł dla ulg PIT-0
# (młodzi/powrót/4+/senior). Alert TRIAGE_QUEUE przy ≥ 95% limitu,
# BLOCK_AND_ALERT przy przekroczeniu — agregacja użycia w roku.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.shared_limit_monitor",
    "package": "jdg.pit.exemptions", "priority": 589,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption_shared_usage": total_used,
    "exemption_shared_limit": limit,
    "exemption_usage_pct": usage_pct,
    "exemption_remaining": remaining,
    "exemption_usage_detail": {
        "young_used": young_used,
        "return_used": return_used,
        "family_4plus_used": family_4plus_used,
        "senior_used": senior_used
    },
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing_action,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT",
    "_warnings": [sprintf("Monitor limitu PIT-0: użyto %.2f z %.0f zł (%.1f%%). Pozostało: %.2f zł.", [total_used, limit, usage_pct, remaining])]
} {
    input.pit_exemption_monitor_check == true
    em := object.get(input, "pit_exemption_monitor", {})
    ent := object.get(input, "jdg_entrepreneur", {})
    pit_form := object.get(ent, "tax_form", "PIT_SCALE")
    young_used := object.get(em, "young_used", 0)
    return_used := object.get(em, "return_used", 0)
    family_4plus_used := object.get(em, "family_4plus_used", 0)
    senior_used := object.get(em, "senior_used", 0)
    limit := object.get(thresholds.pit, "pit_relief_shared_limit", 85528)
    alert_pct := object.get(thresholds.pit, "exemption_shared_limit_alert_pct", 0.95)

    total_used := round((young_used + return_used + family_4plus_used + senior_used) * 100) / 100
    usage_pct := round(total_used / limit * 1000) / 10  # % z 1 miejscem po przecinku
    remaining := round((limit - total_used) * 100) / 100
    alert_threshold := limit * alert_pct

    routing_action = "BLOCK_AND_ALERT" { total_used > limit }
    routing_action = "TRIAGE_QUEUE" { total_used <= limit; total_used >= alert_threshold }
    routing_action = "" { total_used < alert_threshold }
    routing_reason = sprintf("PRZEKROCZONO wspólny limit PIT-0: %.2f / %.0f zł — nadwyżka opodatkowana", [total_used, limit]) { total_used > limit }
    routing_reason = sprintf("Alert: użycie limitu PIT-0 osiągnęło %.1f%% (prog 95%%) — planuj pozostałe zwolnienia", [usage_pct]) { total_used <= limit; total_used >= alert_threshold }
    routing_reason = "Limit PIT-0 w normie" { total_used < alert_threshold }
}