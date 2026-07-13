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

default decide := {
    "matched": false, "rule_id": "jdg.pit.exemptions.no_match",
    "package": "jdg.pit.exemptions", "priority": 598
}

# ═══════════════════════════════════════════════════════════════════════════════
# P580: pit_exemption_young — Ulga dla młodych (<26 lat) do 85 528 PLN
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.exemptions.young",
    "package": "jdg.pit.exemptions", "priority": 580,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.00", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "YOUNG", "exemption_limit": 85528,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
    "_warnings": ["Ulga dla młodych — zwolnienie z PIT do 85 528 PLN rocznie"]
} {
    age := object.get(input.jdg_entrepreneur, "age", 99)
    age <= 26
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cum := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    cum <= 85528
}

# ═══════════════════════════════════════════════════════════════════════════════
# P582: pit_exemption_return — Ulga na powrót (4 lata po emigracji)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.exemptions.return",
    "package": "jdg.pit.exemptions", "priority": 582,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.00", "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "exemption": "RETURN", "exemption_limit": 85528, "exemption_years_remaining": 4 - used_years,
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
    "exemption": "FAMILY_4PLUS", "exemption_limit": 85528,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT",
    "_warnings": ["Ulga 4+ — zwolnienie z PIT"]
} {
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    children >= 4
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
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
    "exemption": "WORKING_SENIOR", "exemption_limit": 85528,
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
    "exemption_shared_limit": 85528,
    "exemption_warning": "Wspólny limit 85 528 PLN dla ulg PIT-0 (młodzi, powrót, 4+, senior)",
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT",
    "_warnings": ["UWAGA: Ulgi PIT-0 mają WSPÓLNY limit 85 528 PLN rocznie!"]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR", "LUMP_SUM"}
}
