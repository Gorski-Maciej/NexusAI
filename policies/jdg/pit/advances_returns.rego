# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: Zaliczki i zeznania roczne (P540-P559)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: PIT Advances & Returns — Monthly/Quarterly/Simplified, Annual Filings
# description: |
#   PAS 5c Multi-Pass. First-Match-Wins else-chain. Zaliczki: miesięczne (P540),
#   kwartalne dla małych podatników (P542), uproszczone 1/12 (P543),
#   odliczenie ZUS od zaliczki (P541). Zeznania roczne: PIT-36 skala (P550),
#   PIT-36L liniowy (P552), PIT-28 ryczałt (P554 — termin 28 lutego!),
#   przekroczenie terminu (P556).
# architecture: Multi-Pass PAS 5c (ADR-001)
# legal_basis: Art. 44-45 PIT, ustawa o ryczałcie
# edge_cases:
#   - P554: PIT-28 termin 28 lutego (nie 30 kwietnia!)
#   - P556: tax_return_filed_current = false → BLOCK_AND_ALERT
# package: jdg.pit.advances
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.6 + Doc 33 (Art. 44-45 PIT)
#
# package: jdg.pit.advances
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.advances

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.advances.no_match",
    "package": "jdg.pit.advances", "priority": 569
}

# ═══════════════════════════════════════════════════════════════════════════════
# P540: pit_advance_monthly — Zaliczka miesięczna (skala/liniowy)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.advances.monthly",
    "package": "jdg.pit.advances", "priority": 540,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "pit_advance_frequency": "MONTHLY", "pit_advance_due_day": 20,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 44 ust. 1 i 3 PIT",
    "_warnings": []
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}
    input.jdg_entrepreneur.uses_quarterly_advances == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P542: pit_advance_quarterly — Zaliczka kwartalna (mały podatnik)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.quarterly",
    "package": "jdg.pit.advances", "priority": 542,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "pit_advance_frequency": "QUARTERLY", "pit_advance_due_day": 20,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 44 ust. 3g PIT",
    "_warnings": ["Mały podatnik — zaliczki kwartalne"]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}
    input.jdg_entrepreneur.is_small_taxpayer == true
    input.jdg_entrepreneur.uses_quarterly_advances == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P543: pit_advance_simplified — Zaliczki uproszczone
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.simplified",
    "package": "jdg.pit.advances", "priority": 543,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "pit_advance_frequency": "SIMPLIFIED", "pit_advance_due_day": 20,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 44 ust. 6b PIT",
    "_warnings": ["Zaliczki uproszczone — 1/12 podatku z roku poprzedniego"]
} {
    input.jdg_entrepreneur.uses_simplified_advances == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P541: pit_advance_zus_social_deduction — Odliczenie ZUS od zaliczki PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.zus_social_deduction",
    "package": "jdg.pit.advances", "priority": 541,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 2 PIT",
    "_warnings": ["Składki ZUS społeczne odliczane od dochodu przy wyliczaniu zaliczki PIT"]
} {
    input.invoice.expense_type == "ZUS_SOCIAL_ENTREPRENEUR"
    input.invoice.is_paid == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P550: pit_annual_return_pit36 — Zeznanie PIT-36 (skala)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.annual_pit36",
    "package": "jdg.pit.advances", "priority": 550,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-36",
    "pit_annual_return_deadline": "04-30",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 1 PIT",
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P552: pit_annual_return_pit36l — Zeznanie PIT-36L (liniowy)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.annual_pit36l",
    "package": "jdg.pit.advances", "priority": 552,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-36L",
    "pit_annual_return_deadline": "04-30",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 1a PIT",
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P554: pit_annual_return_pit28 — Zeznanie PIT-28 (ryczałt) — termin 28 lutego!
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.annual_pit28",
    "package": "jdg.pit.advances", "priority": 554,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-28",
    "pit_annual_return_deadline": "02-28",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 ustawy o ryczałcie",
    "_warnings": ["UWAGA: PIT-28 do 28 lutego! (wcześniej niż PIT-36/PIT-36L do 30 kwietnia)"]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P556: pit_annual_return_overdue — Przekroczenie terminu zeznania rocznego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.advances.return_overdue",
    "package": "jdg.pit.advances", "priority": 556,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Niezłożone zeznanie roczne PIT",
    "_legal_basis": "Art. 45 PIT, Art. 56 KKS",
    "_warnings": ["Niezłożone zeznanie roczne PIT — ryzyko sankcji KKS!"],
    "_future_events": [{
        "event_id":"annual_return_overdue",
        "event_type":"COMPLIANCE_DEADLINE",
        "description":"Niezłożone zeznanie roczne — natychmiastowe działanie wymagane",
        "due_date_horizon":"IMMEDIATE",
        "action":"FILE_ANNUAL_TAX_RETURN",
        "priority":"CRITICAL"
    }]
} {
    input.jdg_entrepreneur.tax_return_filed_current == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}
