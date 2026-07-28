# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Routing: Field confidence per forma (P10-P19)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Routing Package — OCR Field Confidence & Forma-Dependent Triage
# description: |
#   PAS 1 Multi-Pass. First-Match-Wins else-chain. Sprawdza pewność OCR per forma
#   opodatkowania: skala (P10), liniowy (P14), ryczałt (P15). Niska pewność NIP
#   kontrahenta (P12) → BLOCK_AND_ALERT. Ogólny próg (P19) → TRIAGE_QUEUE przy <70%.
# architecture: Multi-Pass PAS 1 (ADR-001), używa helpers.build_jdg_routing_reason()
# legal_basis: Art. 22 UoR (rzetelność ksiąg), Art. 96b VAT (Biała Lista)
# edge_cases:
#   - fc_vat_rate < 0.95 na skali → BLOCK (P10), na ryczałcie tylko TRIAGE (P15)
#   - fc_vendor_nip < 0.80 → BLOCK niezależnie od formy
# package: jdg.routing
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.routing

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.routing.no_match",
    "package": "jdg.routing", "priority": 29
}

# Pobiera próg routingu z thresholds (z fallbackiem do wartości domyślnych)
get_routing_threshold(key, fallback) = val {
    val := object.get(data.jdg.thresholds.routing_confidence, key, fallback)
}

# ═══════════════════════════════════════════════════════════════════════════════
# P10: fc_vat_rate_low_scale — Niska pewność stawki VAT (skala)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.routing.fc_vat_rate_low_scale",
    "package": "jdg.routing", "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": helpers.build_jdg_routing_reason("SCALE", "vat_rate", fc_vat, 0.95),
    "_legal_basis": "Art. 22 UoR (rzetelność ksiąg)",
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    fc_vat := object.get(input.confidence, "fc_vat_rate", 1.0)
    fc_vat < get_routing_threshold("vat_rate_block", 0.95)
    fc_vat > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P12: fc_vendor_nip_low — Niska pewność NIP kontrahenta
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.routing.fc_vendor_nip_low",
    "package": "jdg.routing", "priority": 12,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Niska pewność OCR NIP — ryzyko błędnej weryfikacji Białej Listy",
    "_legal_basis": "Art. 96b VAT, Art. 22 UoR",
    "_warnings": []
} {
    fc_nip := object.get(input.confidence, "fc_vendor_nip", 1.0)
    fc_nip < get_routing_threshold("nip_block", 0.80)
    fc_nip > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P14: fc_linear_minimum — Niska ogólna pewność (liniowy)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.routing.fc_linear_minimum",
    "package": "jdg.routing", "priority": 14,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": helpers.build_jdg_routing_reason("LINEAR", "fc_minimum", fc_min, 0.85),
    "_legal_basis": "Art. 22 UoR",
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    fc_min := object.get(input.confidence, "fc_minimum", 1.0)
    fc_min < get_routing_threshold("linear_min_block", 0.85)
    fc_min > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P15: fc_lump_sum_vat_rate — Niska pewność VAT (ryczałt)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.routing.fc_lump_sum_vat_rate",
    "package": "jdg.routing", "priority": 15,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": helpers.build_jdg_routing_reason("LUMP_SUM", "vat_rate", fc_vat, 0.95),
    "_legal_basis": "Art. 22 UoR",
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    fc_vat := object.get(input.confidence, "fc_vat_rate", 1.0)
    fc_vat < get_routing_threshold("vat_rate_block", 0.95)
    fc_vat > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P19: fc_global_minimum_low — Ogólna pewność poniżej minimum
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.routing.fc_global_minimum_low",
    "package": "jdg.routing", "priority": 19,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Ogólna pewność OCR poniżej globalnego minimum",
    "_legal_basis": "Art. 22 UoR",
    "_warnings": []
} {
    fc_min := object.get(input.confidence, "fc_minimum", 1.0)
    fc_min < get_routing_threshold("minimum_triage", 0.70)
    fc_min > 0
}
