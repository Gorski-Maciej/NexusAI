# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Fallback: Domyślna stawka 23% + NO_MATCH (P1000-P1099)
# ═══════════════════════════════════════════════════════════════════════════════
# METADATA
# title: JDG Package — fallback
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.fallback
# deprecated: false
#
package jdg.fallback

default decide := {"matched":false,"rule_id":"jdg.fallback.no_match","package":"jdg.fallback","priority":1099}

# ══════ P1000: domestic_fallback_jdg — Domyślna stawka 23% VAT PL ══════
# v7.0 FIX: matched:false — domyślna stawka 23% wymaga ręcznej weryfikacji
# (transakcja zwolniona z VAT nie powinna być automatycznie objęta 23%)
decide := {
    "matched":false,"rule_id":"jdg.fallback.domestic_23pct",
    "package":"jdg.fallback","priority":1000,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"",
    "vat_exemption":"","procedure":"",
    "pit_form":"SCALE","pit_rate":"0.12","pit_bracket":"LOW",
    "pit_annual_return_type":"PIT-36",
    "kus_qualification":"full","kus_percent":100,
    "zus_social_base_type":"STANDARD","zus_health_rate":"0.09",
    "business_status":"ACTIVE",
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"Domyślna stawka VAT 23% PL — wymaga ręcznej weryfikacji (transakcja może być zwolniona)",
    "_legal_basis":"Art. 41 ust. 1 VAT, Art. 27 ust. 1 PIT (domyślnie skala)",
    "_warnings":["Domyślne założenia: VAT 23%, PIT skala 12%, ZUS standard, pełny KUP"]
} {
    input.vendor.country == "PL"
}

# ══════ P1099: no_match_jdg — Ostateczny fallback ══════
else := {
    "matched":false,"rule_id":"jdg.fallback.no_match_jdg",
    "package":"jdg.fallback","priority":1099,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"",
    "vat_exemption":"","procedure":"",
    "pit_form":"SCALE","pit_rate":"0.12","pit_bracket":"LOW",
    "pit_annual_return_type":"PIT-36",
    "kus_qualification":"full","kus_percent":100,
    "zus_social_base_type":"STANDARD","zus_health_rate":"0.09",
    "business_status":"ACTIVE",
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"NO_MATCHING_RULE — żadna reguła JDG nie dopasowana",
    "_legal_basis":"Fallback — domyślne założenia systemowe",
    "_warnings":["NO_MATCHING_RULE — brak dopasowania żadnej reguły JDG. Przyjęto domyślne założenia."]
} {
    true
}
