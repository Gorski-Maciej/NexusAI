# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: Zmiana formy opodatkowania (P590-P599)
# ═══════════════════════════════════════════════════════════════════════════════
#
#
# METADATA
# title: JDG Package — pit.transitions
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.pit.transitions
# deprecated: false
#
# First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.6 + Doc 33 (Art. 9a PIT)
#
# package: jdg.pit.transitions
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.transitions

import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.pit.transitions.no_match",
    "package": "jdg.pit.transitions", "priority": 609
}

# ═══════════════════════════════════════════════════════════════════════════════
# P593: mid_year_change_restriction — Blokada zmiany formy w trakcie roku
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.transitions.mid_year_block",
    "package": "jdg.pit.transitions", "priority": 593,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zmiana formy opodatkowania NIEDOZWOLONA w trakcie roku",
    "_legal_basis": "Art. 9a ust. 5 PIT",
    "_warnings": ["Zmiana formy opodatkowania możliwa TYLKO od nowego roku podatkowego!"]
} {
    change_date := object.get(input.jdg_entrepreneur, "tax_form_change_date", "")
    change_date != ""
    change_date > input.jdg_entrepreneur.fiscal_year_start
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P594: tax_consequences_form_change — Dwa zeznania roczne przy zmianie
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.transitions.dual_return",
    "package": "jdg.pit.transitions", "priority": 594,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "",
    "pit_annual_return_type": "DUAL", "pit_dual_return_required": true,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 1b PIT",
    "_warnings": ["Zmiana formy — DWA zeznania roczne: PIT-36 + PIT-36L lub PIT-28"]
} {
    input.jdg_entrepreneur.tax_form_changed_from != ""
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P596: zus_health_recalculation_change — Przeliczenie składki zdrowotnej
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.transitions.health_recalc",
    "package": "jdg.pit.transitions", "priority": 596,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": new_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_health_recalculation_required": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 81 ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": ["Zmiana formy — WYMAGANE przeliczenie składki zdrowotnej (nowa stawka od następnego miesiąca)"]
} {
    old_form := object.get(input.jdg_entrepreneur, "tax_form_changed_from", "")
    new_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    old_form != new_form
    old_form != ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# P590: change_scale_to_linear — Zmiana ze skali na liniowy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.transitions.scale_to_linear",
    "package": "jdg.pit.transitions", "priority": 590,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_linear]), "pit_bracket": "",
    "pit_annual_return_type": "PIT-36L",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9a ust. 2, Art. 30c PIT",
    "_warnings": ["Zmiana: Skala → Liniowy. Brak kwoty wolnej. Nowa składka zdrowotna 4.9%."]
} {
    input.jdg_entrepreneur.tax_form_changed_from == "PIT_SCALE"
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P592: change_lump_sum_to_scale — Utrata ryczałtu → automatyczna skala
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.transitions.lump_sum_loss_to_scale",
    "package": "jdg.pit.transitions", "priority": 592,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "Automatyczna zmiana ryczałt → skala",
    "_legal_basis": "Art. 20 ustawy o ryczałcie",
    "_warnings": ["Utrata prawa do ryczałtu — AUTOMATYCZNA zmiana na skalę podatkową!"]
} {
    input.jdg_entrepreneur.tax_form_changed_from == "LUMP_SUM"
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}
