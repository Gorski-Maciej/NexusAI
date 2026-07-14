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

# ══ P1614: tax_free_amount_temporal — Kwota wolna od podatku temporalna (Doc 35) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.tax_free_amount_temporal",
    "package":"jdg.temporal","priority":1614,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","tax_free_amount":tax_free,"tax_year":tax_year,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27 ust. 1 PIT (zmieniany Polski Ład 2022)",
    "_warnings":[sprintf("Kwota wolna: %.0f PLN (rok %d). 2017: 6 600 PLN, 2018-2021: degresywna (1 440→0 PLN), od 2022: 30 000 PLN",[tax_free,tax_year])]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026);
    tax_free=6600{tax_year==2017};
    tax_free=8000{tax_year==2018};
    tax_free=8000{tax_year==2019};
    tax_free=8000{tax_year==2020};
    tax_free=8000{tax_year==2021};
    tax_free=30000{tax_year>=2022}
}

# ══ P1616: depreciation_one_off_limit_temporal — Limit amortyzacji jednorazowej temporalny (Doc 35) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.depreciation_one_off_limit",
    "package":"jdg.temporal","priority":1616,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","depreciation_limit":deplim,"tax_year":tax_year,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22d ust. 1 PIT (zmieniany wielokrotnie)",
    "_warnings":[sprintf("Limit jednorazowej amortyzacji: %.0f PLN (rok %d). Do 2018: 10 000 PLN. Od 2018: 100 000 PLN (de minimis).",[deplim,tax_year])]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026);
    deplim=10000{tax_year<2018};
    deplim=100000{tax_year>=2018}
}

# ══ P1613: temporal_polski_lad_transition — Okres przejściowy Polski Ład (Doc 36) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.polski_lad_transition",
    "package":"jdg.temporal","priority":1613,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"0.17","pit_bracket":"0.32","pit_annual_return_type":"","pit_threshold_pln":85528,
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","polski_lad_transition":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27 PIT (stan na 01.01.2022-30.06.2022)",
    "_warnings":["Polski Ład przejściowy (01-06.2022): PIT 17%/32%, próg 85 528 PLN, kwota wolna 30k PLN od 01.01.2022. Ulga dla klasy średniej aktywna."]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026)
    tax_year==2022
    object.get(input.temporal,"is_polish_lad_transition_period",false)==true
}

# ══ P1615: temporal_ksef_delayed_2026 — KSeF obowiązkowy od 01.02.2026 (Doc 36) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.ksef_delayed_2026",
    "package":"jdg.temporal","priority":1615,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_mandatory":true,"ksef_effective_date":"2026-02-01",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 106na-106nq VAT (KSeF obowiązkowy od 01.02.2026)",
    "_warnings":["KSeF obowiązkowy od 01.02.2026 — wszystkie faktury przez Krajowy System e-Faktur. Faktury poza KSeF = sankcja 100% VAT (max 500k PLN)."]
} {
    eval_date:=object.get(input.temporal,"evaluation_date","2026-07-14")
    eval_date>="2026-02-01"
    object.get(input.jdg_entrepreneur,"is_vat_payer",false)==true
}

# ══ P1618: temporal_nbp_fx_rate_date — Kurs NBP z dnia poprzedzającego (Doc 36) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.nbp_fx_rate_date",
    "package":"jdg.temporal","priority":1618,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","fx_rate_rule":fx_rule,"fx_rate_table":fx_table,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 14c PIT, Art. 30a-c VAT",
    "_warnings":[sprintf("Kurs walut: %s — tabela %s NBP z dnia poprzedzającego transakcję. Wyjątek: import/eksport celny → tabela C NBP.",[fx_rule,fx_table])]
} {
    input.invoice.currency!="PLN"
    is_customs:=object.get(input.invoice,"is_customs_transaction",false)
    fx_rule="Tabela A NBP z dnia poprzedzającego" { is_customs==false }
    fx_rule="Tabela C NBP (celna) z dnia poprzedzającego" { is_customs==true }
    fx_table="A" { is_customs==false }
    fx_table="C" { is_customs==true }
}

# ══ P1617: temporal_covid_legacy — Przedłużone terminy COVID (Doc 36) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.covid_legacy",
    "package":"jdg.temporal","priority":1617,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","covid_legacy":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozp. COVID (archiwalne 2020-2021)",
    "_warnings":["COVID-19 legacy: przedłużone terminy ZUS (tarcza antykryzysowa), VAT (zwolnienie z odsetek), PIT (przedłużone zeznania roczne). Okres 03.2020-12.2021 — historyczne."]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026)
    tax_year>=2020
    tax_year<=2021
    object.get(input.temporal,"covid_legacy_applies",false)==true
}
