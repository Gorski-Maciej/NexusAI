# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — RMK, Time-Travel OPA, przedawnienia (P1600-P1612)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.temporal
#
# DANE DOKUMENTACYJNE (komentarz zwykły — nie parsowany przez OPA):
#   title: JDG Package — temporal · architecture: Multi-Pass (ADR-001)
#   package: jdg.temporal · deprecated: false
#   description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
#
import data.jdg.helpers
import future.keywords.in
default decide := {"matched":false,"rule_id":"jdg.temporal.no_match","package":"jdg.temporal","priority":1622}

# ── ADR-002 (CZĘŚĆ 1): epoki czasowe externalizowane do data.thresholds.jdg.temporal_epochs ──
epoch_2018 := data.thresholds.jdg.temporal_epochs.e2018
epoch_2019 := data.thresholds.jdg.temporal_epochs.e2019
epoch_2020 := data.thresholds.jdg.temporal_epochs.e2020
epoch_2021 := data.thresholds.jdg.temporal_epochs.e2021
epoch_2022 := data.thresholds.jdg.temporal_epochs.e2022
epoch_2023 := data.thresholds.jdg.temporal_epochs.e2023
epoch_2025 := data.thresholds.jdg.temporal_epochs.e2025

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS TEMPORALNE (P03 GLM52 — naprawa składni P1614/P1616/P1618):
# wartości warunkowe jako FUNKCJE (deterministyczne, testowalne) zamiast
# nielegalnych inline-guards (x=1{cond} nie jest poprawnym Rego).
# ═══════════════════════════════════════════════════════════════════════════════

# Kwota wolna od podatku wg roku (Art. 27 ust. 1 PIT) — P1614
tax_free_amount(year) = object.get(data.thresholds.jdg.pit, "tax_free_2017", 6600) { year == 2017 }
tax_free_amount(year) = object.get(data.thresholds.jdg.pit, "tax_free_2018_2021", 8000) { year in {2018, 2019, 2020, 2021} }
tax_free_amount(year) = object.get(data.thresholds.jdg.pit, "tax_free_2022_plus", 30000) { year >= 2022 }

# Limit jednorazowej amortyzacji wg roku (Art. 22d ust. 1 PIT) — P1616
depreciation_one_off_limit(year) = object.get(data.thresholds.jdg.depreciation, "one_off_annual_limit_pre2018", 10000) { year < 2018 }
depreciation_one_off_limit(year) = object.get(data.thresholds.jdg.depreciation, "one_off_annual_limit", 100000) { year >= 2018 }

# Tabela kursów NBP wg transakcji (Art. 14c PIT, Art. 30a-c VAT) — P1618
fx_table_name(is_customs) = "Tabela C NBP (celna) z dnia poprzedzającego" { is_customs == true }
fx_table_name(is_customs) = "Tabela A NBP z dnia poprzedzającego" { is_customs == false }
fx_table_code(is_customs) = "C" { is_customs == true }
fx_table_code(is_customs) = "A" { is_customs == false }

# Predykaty nakładania/pokrycia (P03 GLM52 — poprawka: Rego nie ma operatora `or`;
# OR wyrażony przez WIELOKROTNE reguły funkcji).
_overlap_cond(a_to, b_from) { a_to == null }
_overlap_cond(a_to, b_from) { b_from <= a_to }

_in_window(vt, eval_date) { vt == null }
_in_window(vt, eval_date) { eval_date <= vt }

# Prawdziwa luka czasowa: następny valid_from jest WIĘCEJ niż 1 dzień po valid_to
# (valid_to włącznie — dzień graniczny należy do poprzedniej wersji).
# Zgodne z testami: 2025-12-31 → 2026-01-01 = ciągłość, 2024-12-31 → 2026-01-01 = luka.
_has_gap(end_prev, next_from) {
    end_ns := time.parse_rfc3339_ns(_to_ts(end_prev))
    next_ns := time.parse_rfc3339_ns(_to_ts(next_from))
    next_ns > end_ns + 86400000000000
}

# Normalizacja daty do pełnego RFC3339 (data-only → midnight UTC)
_to_ts(d) = concat("", [d, "T00:00:00Z"]) {
    not contains(d, "T")
} else = d {
    contains(d, "T")
}

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
    "pit_form":"","pit_rate":"0.17","pit_bracket":"0.32","pit_annual_return_type":"","pit_threshold_pln": data.thresholds.pit.pit_relief_shared_limit,
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_year":epoch_2019,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27 PIT (stan prawny na 2019 r.)",
    "_warnings":["Historyczna stawka PIT 2019: 17% + 32% powyżej 85 528 PLN. Stawki zmienione od 2022 do 12%/32% (Polski Ład)."]
} {
    input.temporal.effective_date_year == epoch_2019
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

# ═══════════════════════════════════════════════════════════════════════════════
# P03 GLM52 — PEŁNA TEMPORALNOŚĆ: ALGEBRA INTERWAŁÓW (ADR-003 + ADR-022)
# Rozbudowa o detektory P1627-P1632:
#   P1627: temporal_interval_algebra — algebra interwałów: ZERO LUK + ZERO
#          NAKŁADEK globalnie (dowód formalny na rule_versions/rule_registry),
#   P1628: temporal_threshold_version_pin — deterministyczny wybór wersji
#          progu wg daty ewaluacji (threshold_versions — time-travel progów),
#   P1629: temporal_law_change_lead — Law Radar (F5): lead days ≥ 30 dla
#          zbliżających się zmian prawa (bramka „tryb pilny" < 30 dni),
#   P1630: temporal_retroactive_change — wykrywanie zmian wstecznych
#          (valid_from w przeszłości = ryzyko korekty historycznej),
#   P1631: temporal_pinning_drift — dryft: wersja przypięta ≠ wersja aktywna,
#   P1632: temporal_version_proof — dowód deterministycznego wyboru wersji:
#          dla każdej reguły DOKŁADNIE jedna wersja aktywna na datę.
# ═══════════════════════════════════════════════════════════════════════════════

# ══ P1627: temporal_interval_algebra — ZERO LUK + ZERO NAKŁADEK (dowód) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.interval_algebra","package":"jdg.temporal","priority":1627,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","interval_proof":proof,"overlap_total":ov_count,"gap_total":gp_count,
    "_routing":"REPORT","_routing_reason":"Algebra interwałów: weryfikacja zero luk i zero nakładek w oknach ważności",
    "_legal_basis":"ADR-003 + ADR-022 (temporalność pełna) + P03 GLM52 §3",
    "_warnings":[sprintf("Interval algebra: %d nakładek, %d luk (cel: 0/0).",[ov_count,gp_count])]
} {
    registry := _version_registry
    ov := [o |
        some rid in object.keys(registry)
        some a in registry[rid]
        some b in registry[rid]
        a != b
        a_from := object.get(a,"valid_from","0000-01-01")
        b_from := object.get(b,"valid_from","0000-01-01")
        a_to := object.get(a,"valid_to",null)
        a_from <= b_from
        _overlap_cond(a_to, b_from)
        o := {"rule_id":rid,"type":"OVERLAP","a":object.get(a,"version","?"),"b":object.get(b,"version","?")}
    ]
    gp := [g |
        some rid in object.keys(registry)
        versions := registry[rid]
        count(versions) > 1
        sorted := sort([object.get(v,"valid_from","") | some v in versions])
        some i, _ in sorted
        i < count(sorted) - 1
        end_prev := object.get([v | some v in versions; object.get(v,"valid_from","") == sorted[i]][0],"valid_to",null)
        end_prev != null
        _has_gap(end_prev, sorted[i+1])
        g := {"rule_id":rid,"type":"GAP","from":end_prev,"to":sorted[i+1]}
    ]
    ov_count := count(ov)
    gp_count := count(gp)
    proof := {
        "zero_overlaps": ov_count == 0,
        "zero_gaps": gp_count == 0,
        "rules_checked": count(object.keys(registry)),
        "property": "INV-037",
    }
    object.get(input.temporal,"interval_algebra",false)==true
}

# ══ P1628: temporal_threshold_version_pin — wersja progu na datę ══
else := {
    "matched":true,"rule_id":"jdg.temporal.threshold_version_pin","package":"jdg.temporal","priority":1628,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","threshold_pinned":pins,"pinned_count":count(pins),
    "_routing":"TIME_TRAVEL","_routing_reason":"Time-travel progów: wersja progu wybrana deterministycznie dla daty ewaluacji",
    "_legal_basis":"ADR-002 (progi temporalne) + P03 GLM52 §3",
    "_warnings":["Progi przypięte do daty ewaluacji — wartości historyczne NIE są nadpisywane przez bieżące."]
} {
    eval_date := object.get(input.temporal,"evaluation_date","")
    eval_date != ""
    tvers := object.get(input,"threshold_versions",{})
    pins := [p |
        some key in object.keys(tvers)
        versions := tvers[key]
        count(versions) > 0
        eligible := [v |
            some v in versions
            object.get(v,"valid_from","0000-01-01") <= eval_date
            vt := object.get(v,"valid_to",null)
            _in_window(vt, eval_date)
        ]
        count(eligible) > 0
        latest := max([object.get(v,"valid_from","") | some v in eligible])
        ver := [v | some v in eligible; object.get(v,"valid_from","") == latest][0]
        p := {"threshold":key,"version":object.get(ver,"version","unknown"),"value":object.get(ver,"value",0),"valid_from":latest}
    ]
    count(pins) > 0
    object.get(input.temporal,"threshold_pin",false)==true
}

# ══ P1629: temporal_law_change_lead — Law Radar (F5): lead days ≥ 30 ══
else := {
    "matched":true,"rule_id":"jdg.temporal.law_change_lead","package":"jdg.temporal","priority":1629,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","urgent_changes":urgent,"lead_ok_count":ok_count,
    "_routing":"REPORT","_routing_reason":"Law Radar F5: zmiany prawa z lead < 30 dni = tryb pilny (bramka)",
    "_legal_basis":"WIZJA V2 F5 (Law Radar) + P03 GLM52 §3 + legal_change_calendar.py",
    "_warnings":[sprintf("Zmiany pilne (lead < 30 dni): %d — reguły muszą być gotowe przed wejściem prawa w życie.",[count(urgent)])]
} {
    changes := object.get(input,"law_change_log",[])
    urgent := [c |
        some c in changes
        lead := object.get(c,"lead_days",-1)
        lead >= 0
        lead < 30
    ]
    ok_count := count([c | some c in changes; object.get(c,"lead_days",-1) >= 30])
    count(changes) > 0
    object.get(input.temporal,"law_radar",false)==true
}

# ══ P1630: temporal_retroactive_change — zmiany wsteczne ══
else := {
    "matched":true,"rule_id":"jdg.temporal.retroactive_change","package":"jdg.temporal","priority":1630,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retroactive":retro_list,"retroactive_count":count(retro_list),
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Wykryto zmianę wsteczną (valid_from w przeszłości) — ryzyko korekty historycznej",
    "_legal_basis":"Art. 3 OrdPU (prawo w dacie zdarzenia) + ADR-003",
    "_warnings":["Zmiana wsteczna: nowa wersja reguły z valid_from przed bieżącym okresem. Zweryfikuj uprawnienie do korekty wstecznej."]
} {
    current := object.get(input.temporal,"current_period","9999-12-31")
    retro_list := [r |
        some rid in object.keys(_version_registry)
        some v in _version_registry[rid]
        vf := object.get(v,"valid_from","9999-12-31")
        vf < current
        object.get(v,"status","ACTIVE") in {"CANDIDATE","SHADOW","ACTIVE"}
        object.get(v,"is_retroactive",false)==true
        r := {"rule_id":rid,"version":object.get(v,"version",""),"valid_from":vf}
    ]
    count(retro_list) > 0
    object.get(input.temporal,"retroactive_check",false)==true
}

# ══ P1631: temporal_pinning_drift — wersja przypięta ≠ aktywna ══
else := {
    "matched":true,"rule_id":"jdg.temporal.pinning_drift","package":"jdg.temporal","priority":1631,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","drift_rules":drift_list,"drift_count":count(drift_list),
    "_routing":"REPORT","_routing_reason":"Dryft wersji: przypięta wersja różni się od aktywnej — możliwa niespójność time-travel",
    "_legal_basis":"A2 Temporal Causality Chain + ADR-003 + P03 GLM52 §3",
    "_warnings":["Dryft pinningu: werdykt użył wersji historycznej, ale bieżąca wersja ACTIVE zmieniła się — sprawdź spójność rejestru."]
} {
    eval_date := object.get(input.temporal,"evaluation_date","")
    eval_date != ""
    pinned := object.get(input.temporal,"pinned_versions",{})
    registry := _version_registry
    drift_list := [d |
        some rid in object.keys(pinned)
        pv := object.get(pinned,rid,"")
        pv != ""
        versions := object.get(registry,rid,[])
        count(versions) > 0
        eligible := [v |
            some v in versions
            object.get(v,"valid_from","0000-01-01") <= eval_date
            vt := object.get(v,"valid_to",null)
            _in_window(vt, eval_date)
        ]
        count(eligible) > 0
        latest := max([object.get(v,"valid_from","") | some v in eligible])
        active_ver := object.get([v | some v in eligible; object.get(v,"valid_from","") == latest][0],"version","")
        active_ver != pv
        d := {"rule_id":rid,"pinned":pv,"active":active_ver}
    ]
    count(drift_list) > 0
    object.get(input.temporal,"pinning_drift",false)==true
}

# ══ P1632: temporal_version_proof — dowód deterministycznego wyboru wersji ══
else := {
    "matched":true,"rule_id":"jdg.temporal.version_proof","package":"jdg.temporal","priority":1632,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","version_proof":vproof,"ambiguity_count":amb_count,
    "_routing":"REPORT","_routing_reason":"Dowód: dokładnie jedna wersja aktywna na datę dla każdej reguły (determinizm time-travel)",
    "_legal_basis":"ADR-003 + A2 (deterministyczny wybór wersji) + P03 GLM52 §3",
    "_warnings":[sprintf("Niejednoznacznych wyborów wersji: %d (cel: 0).",[amb_count])]
} {
    eval_date := object.get(input.temporal,"evaluation_date","2026-01-01")
    registry := _version_registry
    amb := [a |
        some rid in object.keys(registry)
        versions := registry[rid]
        eligible := [v |
            some v in versions
            object.get(v,"valid_from","0000-01-01") <= eval_date
            vt := object.get(v,"valid_to",null)
            _in_window(vt, eval_date)
        ]
        count(eligible) > 1
        a := {"rule_id":rid,"candidates":count(eligible),"date":eval_date}
    ]
    amb_count := count(amb)
    vproof := {
        "rules": count(object.keys(registry)),
        "date": eval_date,
        "ambiguous": amb,
        "deterministic": amb_count == 0,
        "selection": "max(valid_from) spośród eligible — sortowalne i deterministyczne",
    }
    object.get(input.temporal,"version_proof",false)==true
}


# ═══════════════════════════════════════════════════════════════════════════════
# P01 SEK. 2 — ROZBUDOWA TEMPORALNOŚCI: WYKRYWANIE KONFLIKTÓW CZASOWYCH
# I OVERLAPPING VALIDITY (A2+ / P01 Sekcja 2 — Rule Lifecycle Management)
# ═══════════════════════════════════════════════════════════════════════════════
# Nowe reguły P1619-P1624:
#   P1619: temporal_overlap_detector — nakładające się okna ważności reguł
#          (konflikt czasowy między dwoma wpisami temporal_validity dla
#          tej samej reguły lub reguł supersedujących się wzajemnie).
#   P1620: temporal_rule_version_pin — pinning wersji reguły na datę ewaluacji
#          (time-travel zgodny z rule_versions z migration 001).
#   P1621: temporal_law_change_calendar — kalendarz zmian prawa dla reguł
#          temporalnych (proaktywne alerty o zbliżających się zmianach).
#   P1622: temporal_shadow_window — reguła w oknie shadow (przed valid_from)
#          ewaluowana bez wpływu na decyzję.
#   P1623: temporal_rollback_window — reguła po auto-rollback (valid_to przedłużony).
#   P1624: temporal_gap_detector — luki czasowe między wersjami reguły.
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# P01 SEK. 2 — ROZBUDOWA TEMPORALNOŚCI: WYKRYWANIE KONFLIKTÓW CZASOWYCH
# I OVERLAPPING VALIDITY (A2+ / P01 Sekcja 2 — Rule Lifecycle Management)
# ═══════════════════════════════════════════════════════════════════════════════
# Nowe reguły P1619-P1624:
#   P1619: temporal_overlap_detector — nakładające się okna ważności reguł
#          (konflikt czasowy między dwoma wpisami temporal_validity dla
#          tej samej reguły lub reguł supersedujących się wzajemnie).
#   P1620: temporal_rule_version_pin — pinning wersji reguły na datę ewaluacji
#          (time-travel zgodny z rule_versions z migration 001).
#   P1621: temporal_law_change_calendar — kalendarz zmian prawa dla reguł
#          temporalnych (proaktywne alerty o zbliżających się zmianach).
#   P1622: temporal_shadow_window — reguła w oknie shadow (przed valid_from)
#          ewaluowana bez wpływu na decyzję.
#   P1623: temporal_rollback_window — reguła po auto-rollback (valid_to przedłużony).
#   P1624: temporal_gap_detector — luki czasowe między wersjami reguły.
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# P01 SEK. 2 — ROZBUDOWA TEMPORALNOŚCI: WYKRYWANIE KONFLIKTÓW CZASOWYCH
# I OVERLAPPING VALIDITY (A2+ / P01 Sekcja 2 — Rule Lifecycle Management)
# Nowe reguły P1619-P1624 (PRZENIESIONE PRZED P1610 wg P03 GLM52 — detektory
# specyficzne muszą odpalać się przed generycznym time-travel):
#   P1619: temporal_overlap_detector, P1620: temporal_rule_version_pin,
#   P1621: temporal_law_change_calendar, P1622: temporal_shadow_window,
#   P1623: temporal_rollback_window, P1624: temporal_gap_detector.
# ═══════════════════════════════════════════════════════════════════════════════

# ══ P1619: temporal_overlap_detector — Nakładające się okna ważności ══
else := {
    "matched":true,"rule_id":"jdg.temporal.overlap_detector","package":"jdg.temporal","priority":1619,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_overlaps":overlaps,"overlap_count":count(overlaps),
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Wykryto nakładające się okna ważności reguł — możliwy konflikt interpretacyjny",
    "_legal_basis":"A2 Temporal Causality Chain + P01 Sekcja 2 (Rule Lifecycle Management)",
    "_warnings":["Nakładające się okna ważności: dwie wersje reguły mogą obowiązywać jednocześnie. Wymagana korekta w rule_versions przed AUTO_POST."]
} {
    overlaps := [o |
        some rule_id in object.keys(input.temporal_validity_overrides)
        versions := input.temporal_validity_overrides[rule_id]
        count(versions) > 1
        some a in versions
        some b in versions
        a != b
        a_from := object.get(a,"valid_from","0000-01-01")
        b_from := object.get(b,"valid_from","0000-01-01")
        a_to := object.get(a,"valid_to",null)
        b_to := object.get(b,"valid_to",null)
        a_from <= b_from
        _overlap_cond(a_to, b_from)
        o := {"rule_id":rule_id,"version_a":object.get(a,"version","?"),"version_b":object.get(b,"version","?"),"type":"OVERLAPPING_VALIDITY"}
    ]
    count(overlaps) > 0
    object.get(input.temporal,"overlap_check",false)==true
}

# ══ P1620: temporal_rule_version_pin — Pinning wersji reguły na datę ══
else := {
    "matched":true,"rule_id":"jdg.temporal.rule_version_pin","package":"jdg.temporal","priority":1620,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","pinned_rule":rule_id,"pinned_version":version,"pinned_date":eval_date,
    "_routing":"TIME_TRAVEL","_routing_reason":"Time-Travel OPA: przypięto wersję reguły obowiązującą w dacie ewaluacji",
    "_legal_basis":"Art. 3 Ordynacja podatkowa + A2 Temporal Causality Chain",
    "_warnings":["Wersja reguły przypięta do daty historycznej. NIE używać wersji bieżącej dla tej ewaluacji."]
} {
    rule_id := object.get(input.temporal,"pin_rule_id","")
    rule_id != ""
    eval_date := object.get(input.temporal,"evaluation_date","")
    eval_date != ""
    versions := object.get(input.temporal_validity_overrides,rule_id,[])
    count(versions) > 0
    eligible := [v |
        some v in versions
        object.get(v,"valid_from","0000-01-01") <= eval_date
        vt := object.get(v,"valid_to",null)
        _in_window(vt, eval_date)
    ]
    count(eligible) > 0
    latest := max([object.get(v,"valid_from","") | some v in eligible])
    version := object.get([v | some v in eligible; object.get(v,"valid_from","") == latest][0],"version","unknown")
}

# ══ P1621: temporal_law_change_calendar — Kalendarz zmian prawa ══
else := {
    "matched":true,"rule_id":"jdg.temporal.law_change_calendar","package":"jdg.temporal","priority":1621,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","law_changes":changes,"upcoming_changes":count(changes),
    "_routing":"REPORT","_routing_reason":"Kalendarz zmian prawa — proaktywne alerty o zbliżających się zmianach progów/stawek",
    "_legal_basis":"P01 Sekcja 2 — Rule Lifecycle Management (law-change forecasting)",
    "_warnings":[sprintf("Zbliżających się zmian prawa: %d. Uwzględnij je w planowaniu okresów rozliczeniowych.",[count(changes)])]
} {
    changes := [c |
        some key in object.keys(input.threshold_change_log)
        versions := input.threshold_change_log[key]
        some v in versions
        vf := object.get(v,"valid_from","9999-12-31")
        vf > object.get(input.temporal,"current_period","0000-01-01")
        c := {"threshold":key,"valid_from":vf,"new_value":object.get(v,"value",0),"act":object.get(v,"act","")}
    ]
    count(changes) > 0
    object.get(input.temporal,"law_change_calendar",false)==true
}

# ══ P1622: temporal_shadow_window — Okno shadow przed wejściem w życie ══
else := {
    "matched":true,"rule_id":"jdg.temporal.shadow_window","package":"jdg.temporal","priority":1622,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","shadow_rules":shadow_list,"shadow_count":count(shadow_list),
    "_routing":"REPORT","_routing_reason":"Reguły w oknie shadow (przed valid_from) — ewaluacja testowa bez wpływu na decyzję",
    "_legal_basis":"P01 Sekcja 2 — Shadow Deployment (Rule Lifecycle Management)",
    "_warnings":["Shadow window: nowe wersje reguł ewaluowane testowo przed wejściem w życie (valid_from). Werdykty shadow nie są decyzyjne."]
} {
    shadow_list := [s |
        some rule_id in object.keys(input.temporal_validity_overrides)
        some v in input.temporal_validity_overrides[rule_id]
        object.get(v,"status","") == "SHADOW"
        s := {"rule_id":rule_id,"version":object.get(v,"version",""),"valid_from":object.get(v,"valid_from","")}
    ]
    count(shadow_list) > 0
    object.get(input.temporal,"shadow_window",false)==true
}

# ══ P1623: temporal_rollback_window — Okno po auto-rollback ══
else := {
    "matched":true,"rule_id":"jdg.temporal.rollback_window","package":"jdg.temporal","priority":1623,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","rolled_back":rb_list,"rollback_count":count(rb_list),
    "_routing":"REPORT","_routing_reason":"Wersje reguł po auto-rollback — przywrócono poprzednią wersję ACTIVE",
    "_legal_basis":"P01 Sekcja 2 — Auto-Rollback (Rule Lifecycle Management)",
    "_warnings":["Auto-rollback wykonany: kandydat generował zbyt wiele błędów. Działa wersja poprzednia."]
} {
    rb_list := [rb |
        some rule_id in object.keys(input.temporal_validity_overrides)
        some v in input.temporal_validity_overrides[rule_id]
        object.get(v,"status","") == "ROLLED_BACK"
        rb := {"rule_id":rule_id,"candidate":object.get(v,"version",""),"restored":object.get(v,"supersedes","")}
    ]
    count(rb_list) > 0
    object.get(input.temporal,"rollback_window",false)==true
}

# ══ P1624: temporal_gap_detector — Luki czasowe między wersjami ══
else := {
    "matched":true,"rule_id":"jdg.temporal.gap_detector","package":"jdg.temporal","priority":1624,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","temporal_gaps":gaps,"gap_count":count(gaps),
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Luki czasowe między wersjami reguły — okresy bez obowiązującej reguły",
    "_legal_basis":"A2 Temporal Causality Chain + P01 Sekcja 2",
    "_warnings":["Wykryto lukę czasową: istnieje okres, w którym żadna wersja reguły nie obowiązuje. Uzupełnij rule_versions."]
} {
    gaps := [g |
        some rule_id in object.keys(input.temporal_validity_overrides)
        versions := input.temporal_validity_overrides[rule_id]
        count(versions) > 1
        sorted := sort([object.get(v,"valid_from","") | some v in versions])
        some i, _ in sorted
        i < count(sorted) - 1
        end_prev := object.get([v | some v in versions; object.get(v,"valid_from","") == sorted[i]][0],"valid_to",null)
        end_prev != null
        _has_gap(end_prev, sorted[i+1])
        g := {"rule_id":rule_id,"gap_from":end_prev,"gap_to":sorted[i+1],"type":"TEMPORAL_GAP"}
    ]
    count(gaps) > 0
    object.get(input.temporal,"gap_check",false)==true
}

# ══ P1625: middle_class_relief_2026 — Ulga dla klasy średniej (R04 P1) ══
# Ulga dla klasy średniej (art. 26 ust. 1 pkt 2aa-2ab PIT) obowiązywała w 2022
# (Polski Ład). ZNIESIONA z dniem 01.01.2023. Dla 2026 → niedostępna.
# UMIESZCZONA PRZED P1614 — P1614 odpala się dla każdego effective_date_year
# i shadowowałaby tę regułę w else-chain.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched":true,"rule_id":"jdg.temporal.middle_class_relief_2026","package":"jdg.temporal","priority":1625,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","middle_class_relief_active":false,"middle_class_relief_year":tax_year,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 26 ust. 1 pkt 2aa-2ab PIT (uchylony z dniem 01.01.2023)",
    "_warnings":["Ulga dla klasy średniej ZNIESIONA od 01.01.2023 — NIE odliczaj jej w 2026! Obowiązywała tylko w 2022 (Polski Ład). Korekty za 2022: nadal możliwe do 5 lat."]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026)
    tax_year>=epoch_2023
    object.get(input.temporal,"middle_class_relief_check",false)==true
}

# ══ P1626: middle_class_relief_2022 — aktywna tylko w 2022 (R04 P1) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.middle_class_relief_2022","package":"jdg.temporal","priority":1626,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","middle_class_relief_active":true,"middle_class_relief_year":epoch_2022,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 26 ust. 1 pkt 2aa-2ab PIT (stan prawny 2022)",
    "_warnings":["Ulga dla klasy średniej AKTYWNA w 2022: dochody 30 000-120 000 zł (skala), wzór: (A*6.68%-380.50)/0.17 dla A≤100k, (A*7.24%-525.12)/0.17 dla A>100k. Od 2023 zniesiona."]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026)
    tax_year==epoch_2022
    object.get(input.temporal,"middle_class_relief_check",false)==true
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
    tax_year := object.get(input.temporal,"effective_date_year",2026)
    tax_free := tax_free_amount(tax_year)
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
    tax_year := object.get(input.temporal,"effective_date_year",2026)
    deplim := depreciation_one_off_limit(tax_year)
}

# ══ P1613: temporal_polski_lad_transition — Okres przejściowy Polski Ład (Doc 36) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.polski_lad_transition",
    "package":"jdg.temporal","priority":1613,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"0.17","pit_bracket":"0.32","pit_annual_return_type":"","pit_threshold_pln": data.thresholds.pit.pit_relief_shared_limit,
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","polski_lad_transition":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27 PIT (stan na 01.01.2022-30.06.2022)",
    "_warnings":["Polski Ład przejściowy (01-06.2022): PIT 17%/32%, próg 85 528 PLN, kwota wolna 30k PLN od 01.01.2022. Ulga dla klasy średniej aktywna."]
} {
    tax_year:=object.get(input.temporal,"effective_date_year",2026)
    tax_year==epoch_2022
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
    fx_rule := fx_table_name(is_customs)
    fx_table := fx_table_code(is_customs)
}

# ══ P1617: temporal_covid_legacy — Przedłużone terminy COVID (Doc 36) ══
else := {
    "matched":true,"rule_id":"jdg.temporal.covid_legacy","package":"jdg.temporal","priority":1617,
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
    tax_year>=epoch_2020
    tax_year<=epoch_2021
    object.get(input.temporal,"covid_legacy_applies",false)==true
}

# ── Helper: rejestr wersji (input.rule_registry > input.temporal_validity_overrides) ──
# UWAGA: NIE używa data.jdg — data.jdg zawiera decide (cykl rekurencyjny).
_version_registry = registry {
    registry := {rid: _versions_for(entry) | some rid, entry in object.get(input,"rule_registry",{})}
    count(registry) > 0
} else = registry {
    registry := {rid: [object.union(v,{"version":object.get(v,"version","v1")}) | some v in input.temporal_validity_overrides[rid]] |
        some rid in object.keys(input.temporal_validity_overrides)}
}

# Akceptuje zarówno tablicę wersji, jak i obiekt {versions: [...]} (schemat rejestru)
_versions_for(entry) = entry { is_array(entry) }
_versions_for(entry) = object.get(entry, "versions", []) { not is_array(entry) }
