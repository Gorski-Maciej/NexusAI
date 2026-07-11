# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Corrections: Korekty faktur, deklaracji, JPK (P1100-P1120)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.corrections
#
# METADATA
# title: JDG Package — corrections
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.corrections
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.corrections.no_match","package":"jdg.corrections","priority":1130}

# ══════ P1100: correction_invoice_in_minus — Korekta faktury in minus ══════
decide := {
    "matched":true,"rule_id":"jdg.corrections.invoice_in_minus",
    "package":"jdg.corrections","priority":1100,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "correction_type":"IN_MINUS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 29a ust. 13, Art. 106j VAT",
    "_warnings":["Korekta in minus — wymagane potwierdzenie odbioru przez nabywcę"]
} {
    input.invoice.correction_type == "IN_MINUS"
    input.invoice.has_buyer_agreement == true
}

# ══════ P1102: correction_invoice_in_plus — Korekta faktury in plus ══════
else := {
    "matched":true,"rule_id":"jdg.corrections.invoice_in_plus",
    "package":"jdg.corrections","priority":1102,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "correction_type":"IN_PLUS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 29a ust. 13 VAT",
    "_warnings":["Korekta in plus — VAT należny w dacie zdarzenia korygującego"]
} {
    input.invoice.correction_type == "IN_PLUS"
}

# ══════ P1104: vat_declaration_correction — Korekta JPK_V7 ══════
else := {
    "matched":true,"rule_id":"jdg.corrections.vat_declaration_correction",
    "package":"jdg.corrections","priority":1104,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "correction_type":"JPK_V7_CORRECTION",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 81 Ordynacji podatkowej",
    "_warnings":["Korekta JPK_V7 — termin 5 lat od końca roku podatkowego"]
} {
    input.invoice.modifies_closed_vat_period == true
}

# ══════ P1106: pit_advance_correction — Korekta zaliczki PIT ══════
else := {
    "matched":true,"rule_id":"jdg.corrections.pit_advance_correction",
    "package":"jdg.corrections","priority":1106,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "correction_type":"PIT_ADVANCE_CORRECTION",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 44 PIT, Art. 81 OP",
    "_warnings":["Korekta zaliczki PIT — możliwa w kolejnym okresie rozliczeniowym"]
} {
    input.invoice.is_correction == true
    input.tax_type == "PIT_ADVANCE"
}

# ══════ P1110: correction_deadline_restrictions — Ograniczenia terminowe ══════
else := {
    "matched":true,"rule_id":"jdg.corrections.deadline_restrictions",
    "package":"jdg.corrections","priority":1110,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "correction_deadline_expired":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Przekroczony termin korekty — 5 lat od końca roku",
    "_legal_basis":"Art. 70 § 1, Art. 81 OP",
    "_warnings":["Korekta NIEMOŻLIWA — upłynął 5-letni termin przedawnienia!"]
} {
    input.invoice.is_correction == true
    days_since := object.get(input.invoice,"days_since_issue",0)
    days_since > 1825  # 5 years * 365 days
}

# ══════ P1112: statute_barred_correction_block — Blokada korekty po przedawnieniu ══════
else := {
    "matched":true,"rule_id":"jdg.corrections.statute_barred_block",
    "package":"jdg.corrections","priority":1112,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Zobowiązanie przedawnione — korekta niedozwolona",
    "_legal_basis":"Art. 70 Ordynacji podatkowej",
    "_warnings":["Zobowiązanie podatkowe przedawnione — KOREKTA NIEDOZWOLONA!"]
} {
    input.invoice.is_correction == true
    input.invoice.tax_obligation_statute_barred == true
}
