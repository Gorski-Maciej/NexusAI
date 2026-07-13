# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — RMK, Time-Travel OPA, przedawnienia (P1600-P1612)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.temporal
#
# METADATA
# title: JDG Package — temporal
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.temporal
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.temporal.no_match","package":"jdg.temporal","priority":1622}

# ══ P1600: tax_statute_limitations_5y — 5-letnie przedawnienie zobowiązań ══
decide := {
    "matched":true,"rule_id":"jdg.temporal.statute_limitations_5yr",
    "package":"jdg.temporal","priority":1600,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","statute_expired":true,"statute_limit_yr":5,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Zobowiązanie przedawnione — brak podstawy do egzekucji",
    "_legal_basis":"Art. 70 § 1 Ordynacja podatkowa",
    "_warnings":["Przedawnienie zobowiązania podatkowego po 5 latach od końca roku, w którym upłynął termin płatności. Bieg terminu przerywa zastosowanie środka egzekucyjnego."]
} {
    input.temporal.transaction_year <= time.now_ns() / 1000000000 / 86400 / 365 - 5 + 1970
    not input.temporal.statute_suspended
}

# ══ P1602: tax_statute_limitations_10y — 10-letnie przedawnienie (przestępstwo skarbowe) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.statute_limitations_10yr",
    "package":"jdg.temporal","priority":1602,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","statute_expired":true,"statute_limit_yr":10,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Przedawnienie 10-letnie — związek z przestępstwem skarbowym",
    "_legal_basis":"Art. 70 § 2 Ordynacja podatkowa (w zw. z art. 44 KKS)",
    "_warnings":["Przedawnienie 10-letnie! Zobowiązanie związane z przestępstwem skarbowym. Bieg terminu od końca roku popełnienia czynu."]
} {
    input.temporal.fiscal_crime_flag == true
    input.temporal.transaction_year >= time.now_ns() / 1000000000 / 86400 / 365 - 10 + 1970
}

# ══ P1603: tax_statute_suspended — Zawieszenie biegu przedawnienia ══
else := {
    "matched":true,"rule_id":"jdg.temporal.statute_suspended",
    "package":"jdg.temporal","priority":1603,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","statute_suspended":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Bieg przedawnienia zawieszony — postępowanie w toku",
    "_legal_basis":"Art. 70 § 6-7 Ordynacja podatkowa",
    "_warnings":["Bieg przedawnienia zawieszony! Przyczyny: wszczęcie postępowania karnego skarbowego, doręczenie zarzutów, kontrola celno-skarbowa. Nie stosować reguł przedawnienia."]
} {
    input.temporal.statute_suspended == true
}

# ══ P1604: rmk_vat_rate_2026 — RMK — stawka VAT obowiązująca w 2026 ══
else := {
    "matched":true,"rule_id":"jdg.temporal.vat_rate_effective_2026",
    "package":"jdg.temporal","priority":1604,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_vat_rate":"0.23","effective_year":2026,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"RMK — mechanizm odwróconego monitorowania krajowego dla VAT",
    "_warnings":["RMK 2026: podstawowa stawka VAT 23%. RMK monitoruje warunki dla powrotu stawek obniżonych 8% / 5% / 0%."]
} {
    input.temporal.effective_date_year == 2026
    input.temporal.vat_rate_lookup == true
}

# ══ P1605: rmk_vat_rate_8pct_condition — RMK — warunek powrotu 8% VAT ══
else := {
    "matched":true,"rule_id":"jdg.temporal.vat_rate_8pct_rmk_condition",
    "package":"jdg.temporal","priority":1605,
    "vat_rate":"0.08","rounding_level":"position","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_vat_rate":"0.08","effective_year":0,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"RMK — Art. 146ef VAT (klauzula powrotna)",
    "_warnings":["RMK: 8% VAT na wybrane towary/usługi (żywność, leki, gastronomia). Warunek: deficyt sektora GG <3% PKB i dług publiczny <60% PKB."]
} {
    input.temporal.vat_rate_lookup == true
    input.goods.category == "food_medicine"
    input.temporal.rmk_condition_met == true
}

# ══ P1606: historical_pit_rate_2019 — Historyczna stawka PIT (2019 — 17%/32%) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.historical_pit_rate_2019",
    "package":"jdg.temporal","priority":1606,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"0.17","pit_bracket":"0.32","pit_annual_return_type":"","pit_threshold_pln":85528,
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_year":2019,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27 PIT (stan prawny na 2019 r.)",
    "_warnings":["Historyczna stawka PIT 2019: 17% + 32% powyżej 85 528 PLN. Stawki zmienione od 2022 do 12%/32% (Polski Ład)."]
} {
    input.temporal.effective_date_year == 2019
    input.temporal.pit_rate_lookup == true
}

# ══ P1608: historical_pit_rate_2025 — Historyczna stawka PIT (2025 — 12%/32%) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.historical_pit_rate_2025",
    "package":"jdg.temporal","priority":1608,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"0.12","pit_bracket":"0.32","pit_annual_return_type":"","pit_threshold_pln":120000,
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_year":2025,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27 PIT (stan prawny od 1 lipca 2022)",
    "_warnings":["Historyczna stawka PIT 2025: 12% + 32% powyżej 120 000 PLN. Ulga dla klasy średniej zniesiona od 2025 (lub utrzymana — sprawdź aktualny stan prawny)."]
} {
    input.temporal.effective_date_year == 2025
    input.temporal.pit_rate_lookup == true
}

# ══ P1610: time_travel_rule_selection — Time-Travel OPA — wybór reguł wg daty ══
else := {
    "matched":true,"rule_id":"jdg.temporal.time_travel_rule_selection",
    "package":"jdg.temporal","priority":1610,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_rule_set":"TIME_TRAVEL","temporal_query_date":"",
    "_routing":"TIME_TRAVEL","_routing_reason":"Time-Travel OPA — ewaluacja reguł na datę historyczną zamiast current time",
    "_legal_basis":"Art. 3 Ordynacja podatkowa (prawo obowiązujące w dacie zdarzenia)",
    "_warnings":["Time-Travel OPA aktywne. Reguły ewaluowane według stanu prawnego na datę transakcji, NIE na dzień dzisiejszy. Konieczność utrzymywania historycznych zestawów reguł!"]
} {
    input.temporal.evaluation_date > 0
    input.temporal.evaluation_date != time.now_ns() / 1000000000
}

# ══ P1612: document_retention_reminder — Przypomnienie o upływie okresu przechowywania ══
else := {
    "matched":true,"rule_id":"jdg.temporal.document_retention_expiry",
    "package":"jdg.temporal","priority":1612,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","document_retention_expiring":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 86 § 1 Ordynacja podatkowa + Art. 112 VAT",
    "_warnings":["Okres przechowywania dokumentów upływa. Standardowo 5 lat od końca roku. Faktury VAT — do upływu przedawnienia zobowiązania. Dokumenty pracownicze — 50 lat (lub 10 lat od 2019 dla ZUS)."]
} {
    input.temporal.retention_expiry_year <= time.now_ns() / 1000000000 / 86400 / 365 + 1970
}
