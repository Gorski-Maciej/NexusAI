# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Liability: Przedawnienia, odpowiedzialność, odsetki (P1150-P1174)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.liability
#
# METADATA
# title: JDG Package — liability
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.liability
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.liability.no_match","package":"jdg.liability","priority":1184}

# ══════ P1150: tax_statute_of_limitations_5y — Przedawnienie 5 lat ══════
decide := {
    "matched":true,"rule_id":"jdg.liability.statute_5_years",
    "package":"jdg.liability","priority":1150,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "statute_of_limitations_years":5,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 70 § 1 Ordynacji podatkowej",
    "_warnings":["Zobowiązanie podatkowe przedawnia się po 5 latach od końca roku kalendarzowego"]
} {
    days_since_fye := object.get(input.document,"months_since_fye",0)
    days_since_fye >= 60  # 5 years * 12 months
}

# ══════ P1158: entrepreneur_personal_liability — Pełna odpowiedzialność osobista ══════
else := {
    "matched":true,"rule_id":"jdg.liability.personal_liability",
    "package":"jdg.liability","priority":1158,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "liability_type":"UNLIMITED_PERSONAL",
    "liability_scope":"ALL_ASSETS_PERSONAL_AND_BUSINESS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 33 Ordynacji podatkowej, Art. 415 KC",
    "_warnings":["JDG — PEŁNA odpowiedzialność osobista całym majątkiem (osobistym i firmowym)!"]
} {
    input.jdg_entrepreneur.tax_form != ""  # is JDG
}

# ══════ P1164: late_payment_interest_calculation — Odsetki za zwłokę ══════
else := {
    "matched":true,"rule_id":"jdg.liability.late_payment_interest",
    "package":"jdg.liability","priority":1164,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "interest_rate_annual":"0.145","interest_calculation":"DAILY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 47-52 Ordynacji podatkowej",
    "_warnings":["Odsetki za zwłokę — stawka 14.5% w skali roku, naliczane dziennie"]
} {
    input.invoice.days_overdue > 0
    input.invoice.is_paid == false
}

# ══════ P1168: voluntary_disclosure_active — Czynny żal ══════
else := {
    "matched":true,"rule_id":"jdg.liability.voluntary_disclosure",
    "package":"jdg.liability","priority":1168,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "voluntary_disclosure_active":true,"kks_immunity":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 16-16b KKS",
    "_warnings":["Czynny żal — złożony przed wszczęciem kontroli. Brak kary KKS!"]
} {
    input.document.tax_status == "VOLUNTARY_DISCLOSURE"
}

# ══════ P1169: overpayment_detection — Nadpłata podatku ══════
else := {
    "matched":true,"rule_id":"jdg.liability.overpayment_detection",
    "package":"jdg.liability","priority":1169,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "overpayment_detected":true,"refund_deadline_days":45,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 72-80 Ordynacji podatkowej",
    "_warnings":["Nadpłata podatku — zwrot w terminie 45 dni"]
} {
    input.document.tax_status == "OVERPAYMENT"
}
