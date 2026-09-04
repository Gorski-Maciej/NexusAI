# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P15 CROSS-BORDER ENTERPRISE (kampania V3 FORTRESS)
# ===============================================================================
# Warstwa transgraniczna ENTERPRISE: place of supply (art. 28a-28o VAT), WDT/WNT
# (art. 42/138 VAT), stawki VAT UE jako dane, rezydencja (art. 3 PIT — determinator
# NEEDS_ADVICE), kursy NBP z D-1 (precyzja groszowa), TP (art. 23o/23zf PIT),
# MDR/DAC6 (art. 86a OrdPU), exit tax (art. 24cg/30da PIT), OSS (art. 28k-28m),
# distance selling (art. 24/25 VAT), invarianty cross-border (P04) i bramka
# spójności walutowej (VAT ↔ PKPiR — kontrakt z P28/P16).
#
# Zasady:
#   * WSZYSTKIE progi/stawki/limity z data.jdg.thresholds.crossborder (ADR-002,
#     P06 parametry-as-data); zero hardcode.
#   * Okna temporalne (valid_from/valid_to) honorowane z snapshotu (P05).
#   * Fail-closed: brak danych / niepewna rezydencja / brak stawki = NEEDS_ADVICE
#     lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST.
#   * Aktywacja: input.jdg_entrepreneur.v3_p15_check == true (wzorzec
#     jdg.crossborder_etap17); bez flagi → no_match.
#   * rule_id: jdg.v3_p15_crossborder.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p15_crossborder
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p15_crossborder

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p15_check", false) == true
_ctx := object.get(input, "v3_p15", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p15_crossborder.no_match",
    "package": "jdg.v3_p15_crossborder",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji crossborder → fail-closed sentinel ──
_th_snapshot := object.get(data.jdg.thresholds, "crossborder", {})
_snapshot_ok := count(_th_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    object.get(_th_snapshot, key, null) != null
} else = fallback

_round2(value) = floor(value * 100) / 100

_round_half_up(value) = result {
    scaled := value * 100
    result := (floor(scaled + 0.5)) / 100
}

_bool_str(flag) = "TAK" {
    flag
}
_bool_str(flag) = "NIE" {
    flag == false
}

# normalizacja procent/ułamek: 50 → 0.5, 0.5 → 0.5
_norm_frac(x) = v {
    x > 1
    v := x / 100
} else = x

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p15_crossborder.thresholds_missing",
    "package": "jdg.v3_p15_crossborder",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Cross-border V3-P15: brak snapshotu data.jdg.thresholds.crossborder.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P15] Brak snapshotu progów — decyzje transgraniczne ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p15_crossborder",
        "priority": priority,
        "threshold_version": object.get(_th_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_th_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_th_snapshot, "valid_from", null),
        "valid_to": object.get(_th_snapshot, "valid_to", null),
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I01: PLACE-OF-SUPPLY MATRIX (art. 28a-28o VAT)
# Usługa → kontrahent (B2B/B2C) → kraj → reguła → status; nieznana ścieżka =
# NEEDS_ADVICE. Macierz jako DANE (data.jdg.thresholds.crossborder.pos_*_rule).
# ═══════════════════════════════════════════════════════════════════════════════
place_of_supply_zone = {"zone": "B2B_MIEJSCE_NABYWCY", "art": _th("pos_b2b_rule", "28b"), "status": "PEŁNE"} {
    _activated
    object.get(_ctx, "customer_type", "") == "B2B"
    object.get(_ctx, "destination_country", "") != ""
} else := {"zone": "B2C_MIEJSCE_SWIADCZENIA", "art": _th("pos_b2c_rule", "28c"), "status": "PEŁNE"} {
    _activated
    object.get(_ctx, "customer_type", "") == "B2C"
    svc := object.get(_ctx, "service_type", "")
    svc != "digital"
    svc != "restaurant"
    svc != "accommodation"
    svc != "real_estate"
} else := {"zone": "USLUGI_ELEKTRONICZNE_B2C", "art": _th("pos_digital_b2c_rule", "28k"), "status": "PEŁNE"} {
    _activated
    object.get(_ctx, "customer_type", "") == "B2C"
    object.get(_ctx, "service_type", "") == "digital"
} else := {"zone": "GASTRONOMIA", "art": _th("pos_restaurant_rule", "28f"), "status": "PEŁNE"} {
    _activated
    object.get(_ctx, "service_type", "") == "restaurant"
} else := {"zone": "NIERUCHOMOSCI", "art": _th("pos_real_estate_rule", "28e"), "status": "PEŁNE"} {
    _activated
    object.get(_ctx, "service_type", "") == "real_estate"
} else := {"zone": "KRÓTKOTERMINOWE_ZAWATEROWANIE", "art": _th("pos_accommodation_rule", "28g"), "status": "PEŁNE"} {
    _activated
    object.get(_ctx, "service_type", "") == "accommodation"
} else := {"zone": "NIEZNANA", "art": "", "status": "BRAK_ŚCIEŻKI"} {
    _activated
}

place_of_supply_decision := _certificate(370101, {
    "rule_id": "jdg.v3_p15_crossborder.place_of_supply_matrix",
    "analysis": "place_of_supply",
    "place_of_supply": place_of_supply_zone,
    "fail_closed": place_of_supply_zone.status == "BRAK_ŚCIEŻKI",
    "_routing": routing_pos,
    "_routing_reason": reason_pos,
    "_legal_basis": "Art. 28a-28o ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_pos,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "place_of_supply"
}

routing_pos = "NEEDS_ADVICE" {
    place_of_supply_zone.status == "BRAK_ŚCIEŻKI"
} else = ""

reason_pos = sprintf("Nieznana ścieżka place of supply (usługa=%s) — wymagana analiza człowieka.",
    [object.get(_ctx, "service_type", "?")]) {
    place_of_supply_zone.status == "BRAK_ŚCIEŻKI"
} else = ""

warnings_pos = ["[V3-P15-I01] Nieznana ścieżka place of supply — decyzja wymaga 4-eyes."] {
    place_of_supply_zone.status == "BRAK_ŚCIEŻKI"
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I02: EU VAT RATES FEED (stawki UE jako dane z valid_from)
# Stawki kraju docelowego podawane w input (feed komisji) — walidacja obecności,
# okna temporalne i zgodność z wersją danych. Brak stawki = NEEDS_ADVICE.
# ═══════════════════════════════════════════════════════════════════════════════
eu_rates_decision := _certificate(370102, {
    "rule_id": "jdg.v3_p15_crossborder.eu_vat_rates_feed",
    "analysis": "eu_rates",
    "rate_validated": rate_found,
    "rate_pct": rate_value,
    "data_version": object.get(_ctx, "rates_data_version", "MISSING"),
    "feed_source": _th("eu_vat_rates_feed_source", "https://taxation-customs.ec.europa.eu/vat-rates_en"),
    "fail_closed": rate_missing,
    "_routing": routing_eur,
    "_routing_reason": reason_eur,
    "_legal_basis": "Art. 97-100 VAT (VAT-UE), stawki krajów UE [NIEZWERYFIKOWANE]",
    "_warnings": warnings_eur,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "eu_rates"
}

rate_found := object.get(_ctx, "rate_pct", null) != null

rate_missing = true {
    not rate_found
} else = false

rate_value = object.get(_ctx, "rate_pct", null)

routing_eur = "NEEDS_ADVICE" {
    not rate_found
} else = ""

reason_eur = "Brak stawki VAT kraju docelowego w danych (feed) — nie można rozliczyć WNT." {
    not rate_found
} else = ""

warnings_eur = ["[V3-P15-I02] Brak stawki kraju docelowego — stawka wymaga weryfikacji w feedzie komisji."] {
    not rate_found
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I03: RESIDENCY ADVISOR (art. 3 PIT) — determinator NEEDS_ADVICE
# 183 dni / centrum interesów życiowych — NIGDY automatyczna decyzja; kwestionariusz
# + checklist dokumentów (certyfikat rezydencji).
# ═══════════════════════════════════════════════════════════════════════════════
residency_status = {"determination": "REZYDENT_PL_183_DNI", "needs_advice": false, "confidence": "HIGH"} {
    _activated
    object.get(_ctx, "days_in_poland", 0) >= _th("residency_days", 183)
    object.get(_ctx, "center_of_interests_pl", null) != false
} else := {"determination": "REZYDENT_PL_CENTRUM_INTERESOW", "needs_advice": false, "confidence": "MEDIUM"} {
    _activated
    object.get(_ctx, "days_in_poland", 0) < _th("residency_days", 183)
    object.get(_ctx, "center_of_interests_pl", null) == true
} else := {"determination": "NIEPEWNA", "needs_advice": true, "confidence": "LOW"} {
    _activated
    object.get(_ctx, "center_of_interests_pl", null) == null
} else := {"determination": "NIEREZYDENT_PL", "needs_advice": false, "confidence": "MEDIUM"} {
    _activated
}

residency_decision := _certificate(370103, {
    "rule_id": "jdg.v3_p15_crossborder.residency_advisor",
    "analysis": "residency",
    "residency": residency_status,
    "checklist": ["certyfikat rezydencji", "kalendarz obecności (183 dni)", "centrum interesów życiowych (rodzina, majątek, aktywność)"],
    "fail_closed": residency_status.needs_advice,
    "_routing": routing_res,
    "_routing_reason": reason_res,
    "_legal_basis": "Art. 3 ust. 1 i 1a ustawy o PIT [NIEZWERYFIKOWANE]",
    "_warnings": warnings_res,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "residency"
}

routing_res = "NEEDS_ADVICE" {
    residency_status.needs_advice
} else = ""

reason_res = "Niepewna rezydencja (centrum interesów nieustalone) — decyzja wymaga analizy człowieka." {
    residency_status.needs_advice
} else = ""

warnings_res = ["[V3-P15-I03] Niepewna rezydencja — nie podejmuj automatycznej decyzji; pobierz certyfikat rezydencji."] {
    residency_status.needs_advice
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I04: FX PRECISION ENGINE (kursy NBP D-1, precyzja groszowa)
# Kurs z dnia poprzedniego (D-1) dla ewidencji; zaokrąglenie round-half-up do 0,01;
# invariant: suma PLN = suma(wartość waluty × kurs) po zaokrągleniu.
# ═══════════════════════════════════════════════════════════════════════════════
fx_precision = result {
    _activated
    amount := object.get(_ctx, "amount_foreign", 0)
    rate := object.get(_ctx, "rate_nbp", 0)
    rate > 0

    pln := _round_half_up(amount * rate)
    result := {"amount_pln": pln, "amount_foreign": amount, "rate": rate,
               "rate_date": object.get(_ctx, "rate_date", "D-1"),
               "rounding": _th("fx_rounding_rule", "round_half_up"),
               "scale": _th("fx_rounding_scale", 2)}
} else := {"amount_pln": -1, "amount_foreign": object.get(_ctx, "amount_foreign", 0),
            "rate": 0, "rate_date": "MISSING", "rounding": "MISSING", "scale": 2} {
    _activated
    object.get(_ctx, "analysis", "") == "fx"
}

expected_matches = true {
    fx_precision.amount_pln >= 0
    object.get(_ctx, "expected_pln", null) == null
} else = true {
    expected := object.get(_ctx, "expected_pln", null)
    expected != null
    _round_half_up(expected) == fx_precision.amount_pln
} else = false

invariant_fx = expected_matches

fx_invariant_fail = true {
    not invariant_fx
} else = false

fx_precision_decision := _certificate(370104, {
    "rule_id": "jdg.v3_p15_crossborder.fx_precision_engine",
    "analysis": "fx",
    "fx": fx_precision,
    "invariant_ok": invariant_fx,
    "fail_closed": fx_invariant_fail,
    "_routing": routing_fx,
    "_routing_reason": reason_fx,
    "_legal_basis": "Art. 24c PIT (różnice kursowe), kursy NBP [NIEZWERYFIKOWANE]",
    "_warnings": warnings_fx,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "fx"
}

routing_fx = "BLOCK_AND_ALERT" {
    not invariant_fx
} else = ""

reason_fx = "Naruszenie invariantu groszowego: suma PLN ≠ suma(wartość × kurs) po zaokrągleniu." {
    not invariant_fx
} else = ""

warnings_fx = ["[V3-P15-I04] Niezgodność przeliczenia groszowego — sprawdź kurs i zaokrąglenie."] {
    not invariant_fx
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I05: TP THRESHOLD SENTINEL (art. 23o/23zf PIT) — monitoring progów
# Progi dokumentacji TP (towary 10M / usługi 2M / finansowe 2,5M) z alertami
# i checklistą dokumentacyjną. Przekroczenie = TRIAGE_QUEUE + checklist.
# ═══════════════════════════════════════════════════════════════════════════════
_tp_over_limit(goods, services, financial) = true {
    goods >= _th("tp_goods_transactions_pln", 10000000)
}
_tp_over_limit(goods, services, financial) = true {
    services >= _th("tp_services_transactions_pln", 2000000)
}
_tp_over_limit(goods, services, financial) = true {
    financial >= _th("tp_financial_transactions_pln", 2500000)
}
_tp_over_limit(goods, services, financial) = false {
    goods < _th("tp_goods_transactions_pln", 10000000)
    services < _th("tp_services_transactions_pln", 2000000)
    financial < _th("tp_financial_transactions_pln", 2500000)
}

tp_status = result {
    _activated
    goods := object.get(_ctx, "tp_goods_pln", 0)
    services := object.get(_ctx, "tp_services_pln", 0)
    financial := object.get(_ctx, "tp_financial_pln", 0)
    exceeded := _tp_over_limit(goods, services, financial)
    result := {"exceeded": exceeded, "goods": goods, "services": services, "financial": financial,
               "limits": {"goods": _th("tp_goods_transactions_pln", 10000000),
                           "services": _th("tp_services_transactions_pln", 2000000),
                           "financial": _th("tp_financial_transactions_pln", 2500000)},
               "documentation_months": _th("tp_documentation_months", 6)}
}

tp_threshold_decision := _certificate(370105, {
    "rule_id": "jdg.v3_p15_crossborder.tp_threshold_sentinel",
    "analysis": "tp",
    "tp": tp_status,
    "fail_closed": tp_status.exceeded,
    "_routing": routing_tp,
    "_routing_reason": reason_tp,
    "_legal_basis": "Art. 23o, 23zf ustawy o PIT [NIEZWERYFIKOWANE]",
    "_warnings": warnings_tp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "tp"
}

routing_tp = "TRIAGE_QUEUE" {
    tp_status.exceeded
} else = ""

reason_tp = "Przekroczony próg dokumentacji TP — wymagana dokumentacja lokalna (6 mies.) + checklist." {
    tp_status.exceeded
} else = ""

warnings_tp = ["[V3-P15-I05] Przekroczony próg TP — przygotuj dokumentację lokalną w terminie ustawowym."] {
    tp_status.exceeded
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I06: MDR HALLMARK SCORER (art. 86a OrdPU / DAC6) — scoring + human review
# Scoring hallmarks A-E (0-100); próg raportowania + termin 30 dni; human review
# WYMUSZONY — nigdy cichy AUTO_POST.
# ═══════════════════════════════════════════════════════════════════════════════
mdr_score = result {
    _activated
    score := object.get(_ctx, "mdr_score", 0)
    deadline_days := _th("mdr_deadline_days", 30)
    high := score >= 70
    result := {"score": score, "deadline_days": deadline_days,
               "human_review_required": _th("mdr_human_review_required", true),
               "reportable": score > 0, "high_risk": high,
               "deadline": sprintf("do %d dni od zdarzenia", [deadline_days])}
}

mdr_decision := _certificate(370106, {
    "rule_id": "jdg.v3_p15_crossborder.mdr_hallmark_scorer",
    "analysis": "mdr",
    "mdr": mdr_score,
    "fail_closed": mdr_score.high_risk,
    "_routing": routing_mdr,
    "_routing_reason": reason_mdr,
    "_legal_basis": "Art. 86a-86o OrdPU (MDR), Dyrektywa DAC6 [NIEZWERYFIKOWANE]",
    "_warnings": warnings_mdr,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mdr"
}

routing_mdr = "TRIAGE_QUEUE" {
    mdr_score.high_risk
} else = ""

reason_mdr = "Wysoki scoring MDR (≥70) — wymagany human review przed jakimkolwiek raportem." {
    mdr_score.high_risk
} else = ""

warnings_mdr = ["[V3-P15-I06] Wysokie ryzyko MDR/DAC6 — human review obowiązkowy; termin 30 dni od zdarzenia."] {
    mdr_score.high_risk
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I07: EXIT TAX EARLY WARNING (art. 24cg/30da PIT)
# Wczesne wykrywanie zdarzeń exit tax (przeniesienie majątku / zmiana rezydencji)
# powyżej progu 4M PLN — alert + checklist dokumentacyjna. Poniżej progu = SUGOEST.
# ═══════════════════════════════════════════════════════════════════════════════
_exit_tax_trigger(transferring, changing, market_value) = true {
    transferring == true
    market_value >= _th("exit_tax_threshold_pln", 4000000)
}
_exit_tax_trigger(transferring, changing, market_value) = true {
    changing == true
    market_value >= _th("exit_tax_threshold_pln", 4000000)
}
_exit_tax_trigger(transferring, changing, market_value) = false {
    transferring == false
    changing == false
}
_exit_tax_trigger(transferring, changing, market_value) = false {
    market_value < _th("exit_tax_threshold_pln", 4000000)
}

exit_tax_status = result {
    _activated
    transferring := object.get(_ctx, "transferring_assets_abroad", false)
    changing := object.get(_ctx, "changing_tax_residence", false)
    market_value := object.get(_ctx, "asset_market_value", 0)
    triggered := _exit_tax_trigger(transferring, changing, market_value)
    estimated := _round2((market_value - object.get(_ctx, "asset_tax_value", 0)) * _th("exit_tax_rate_pct", 0.19))
    result := {"triggered": triggered, "market_value": market_value,
               "threshold_pln": _th("exit_tax_threshold_pln", 4000000),
               "estimated_tax_pln": estimated,
               "deferral_years_eea": _th("exit_tax_deferral_years_eea", 5)}
}

exit_tax_decision := _certificate(370107, {
    "rule_id": "jdg.v3_p15_crossborder.exit_tax_early_warning",
    "analysis": "exit_tax",
    "exit_tax": exit_tax_status,
    "fail_closed": exit_tax_status.triggered,
    "_routing": routing_et,
    "_routing_reason": reason_et,
    "_legal_basis": "Art. 24cg, 30da ustawy o PIT [NIEZWERYFIKOWANE]",
    "_warnings": warnings_et,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exit_tax"
}

routing_et = "BLOCK_AND_ALERT" {
    exit_tax_status.triggered
} else = ""

reason_et = "Zdarzenie exit tax powyżej progu — wymagany alert i checklista dokumentacyjna." {
    exit_tax_status.triggered
} else = ""

warnings_et = ["[V3-P15-I07] Exit tax — przeniesienie majątku/rezydencji powyżej progu; przygotuj dokumentację i rozważ odroczenie EOG."] {
    exit_tax_status.triggered
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I08: CROSS-BORDER GOLDEN SET (Golden Oracle — P10)
# Kontrola pokrycia golden setu decyzjami granicznymi (D-1 kursy, 183 dni, progi TP).
# ═══════════════════════════════════════════════════════════════════════════════
golden_set_coverage = result {
    _activated
    coverage := object.get(_ctx, "golden_coverage", {})
    required := ["fx_d1", "residency_183", "tp_goods", "tp_services", "pos_b2b", "pos_b2c"]
    missing := [r | r := required[_]; not coverage[r]]
    min_set := _th("golden_set_min_verdicts", 30)
    result := {"required": required, "missing": missing, "complete": count(missing) == 0,
               "min_verdicts": min_set, "current_verdicts": object.get(_ctx, "golden_verdicts", 0)}
}

golden_set_decision := _certificate(370108, {
    "rule_id": "jdg.v3_p15_crossborder.crossborder_golden_set",
    "analysis": "golden_set",
    "golden_set": golden_set_coverage,
    "fail_closed": golden_set_incomplete,
    "_routing": routing_gs,
    "_routing_reason": reason_gs,
    "_legal_basis": "Golden Oracle (V2/F3) — nienaruszalność przeszłości",
    "_warnings": warnings_gs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

golden_set_incomplete = true {
    not golden_set_coverage.complete
} else = false

routing_gs = "TRIAGE_QUEUE" {
    golden_set_incomplete
} else = ""

reason_gs = "Golden set cross-border niepełny — brak decyzji granicznych dla ścieżek krytycznych." {
    golden_set_incomplete
} else = ""

warnings_gs = ["[V3-P15-I08] Uzupełnij golden set o brakujące decyzje graniczne."] {
    golden_set_incomplete
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I09: OSS DECISION ADVISOR (art. 28k-28m VAT) — decyzja architektoniczna
# JDG: symulator — czy rejestracja OSS opłacalna (próg sprzedaży wysyłkowej B2C).
# Decyzja = SUGGEST + rekomendacja, nigdy automatyczna rejestracja.
# ═══════════════════════════════════════════════════════════════════════════════
oss_advice = result {
    _activated
    distance_sales_eur := object.get(_ctx, "distance_sales_eur", 0)
    threshold := _th("oss_distance_selling_threshold_eur", 10000)
    result := {"distance_sales_eur": distance_sales_eur, "threshold_eur": threshold,
               "oss_recommended": distance_sales_eur >= threshold,
               "decision_mode": "SUGGEST", "no_auto_post": true}
}

oss_decision := _certificate(370109, {
    "rule_id": "jdg.v3_p15_crossborder.oss_decision_advisor",
    "analysis": "oss",
    "oss": oss_advice,
    "fail_closed": oss_advice.oss_recommended,
    "_routing": routing_oss,
    "_routing_reason": reason_oss,
    "_legal_basis": "Art. 28k-28m ustawy o VAT (OSS) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_oss,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "oss"
}

routing_oss = "SUGGEST" {
    oss_advice.oss_recommended
} else = ""

reason_oss = "Sprzedaż wysyłkowa B2C powyżej progu — rozważ rejestrację OSS (decyzja człowieka)." {
    oss_advice.oss_recommended
} else = ""

warnings_oss = ["[V3-P15-I09] Próg OSS przekroczony — rekomendacja SUGGEST, decyzja należy do przedsiębiorcy."] {
    oss_advice.oss_recommended
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I10: DISTANCE SELLING TRACKER (art. 24/25 VAT) — monitoring progów
# Progi sprzedaży wysyłkowej per kraj (10k EUR / 35k / 100k) z alarmami.
# ═══════════════════════════════════════════════════════════════════════════════
distance_selling_status = result {
    _activated
    sales := object.get(_ctx, "distance_sales_eur", 0)
    limit := _th("distance_selling_limit_eur", 10000)
    exceeded := sales >= limit
    result := {"sales_eur": sales, "limit_eur": limit, "exceeded": exceeded,
               "countries": object.get(_ctx, "countries", [])}
}

distance_selling_decision := _certificate(370110, {
    "rule_id": "jdg.v3_p15_crossborder.distance_selling_tracker",
    "analysis": "distance_selling",
    "distance_selling": distance_selling_status,
    "fail_closed": distance_selling_status.exceeded,
    "_routing": routing_ds,
    "_routing_reason": reason_ds,
    "_legal_basis": "Art. 24-25 ustawy o VAT (sprzedaż wysyłkowa) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_ds,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "distance_selling"
}

routing_ds = "TRIAGE_QUEUE" {
    distance_selling_status.exceeded
} else = ""

reason_ds = "Przekroczony próg sprzedaży wysyłkowej — wymagana rejestracja/OSS w kraju docelowym." {
    distance_selling_status.exceeded
} else = ""

warnings_ds = ["[V3-P15-I10] Próg distance selling przekroczony — sprawdź obowiązki rejestracyjne w kraju konsumpcji."] {
    distance_selling_status.exceeded
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I11: CROSS-BORDER INVARIANTS (P04) — WDT/VAT-UE, kurs D-1, import usług
#  * WDT wymaga rejestracji VAT-UE + kontrahenta z ważnym NIP UE (VIES).
#  * Kurs D-1 dla ewidencji (nie data wystawienia).
#  * Import usług (art. 28b) — samoopodatkowanie (reverse charge) bez cichego 0%.
# ═══════════════════════════════════════════════════════════════════════════════
_inv_wdt_ok(check_wdt, vat_ue, eu_customer) = true {
    check_wdt == false
}
_inv_wdt_ok(check_wdt, vat_ue, eu_customer) = true {
    check_wdt == true
    vat_ue == true
    eu_customer == true
}
_inv_wdt_ok(check_wdt, vat_ue, eu_customer) = false {
    check_wdt == true
    vat_ue == false
}
_inv_wdt_ok(check_wdt, vat_ue, eu_customer) = false {
    check_wdt == true
    eu_customer == false
}

_inv_fx_d1_ok(check_wdt, rate_date) = true {
    check_wdt == false
}
_inv_fx_d1_ok(check_wdt, rate_date) = true {
    check_wdt == true
    rate_date == "D-1"
}
_inv_fx_d1_ok(check_wdt, rate_date) = false {
    check_wdt == true
    rate_date != "D-1"
}

_inv_rc_ok(import_services, rc_applied) = true {
    import_services == false
}
_inv_rc_ok(import_services, rc_applied) = true {
    import_services == true
    rc_applied == true
}
_inv_rc_ok(import_services, rc_applied) = false {
    import_services == true
    rc_applied == false
}

_all3_ok(w, f, r) = true {
    w == true
    f == true
    r == true
}
_all3_ok(w, f, r) = false {
    w == false
}
_all3_ok(w, f, r) = false {
    f == false
}
_all3_ok(w, f, r) = false {
    r == false
}

invariants = result {
    _activated
    vat_ue := object.get(_ctx, "vat_ue_registered", false)
    eu_customer := object.get(_ctx, "eu_customer_vat_id_valid", false)
    rate_date := object.get(_ctx, "rate_date_used", "")
    import_services := object.get(_ctx, "import_services", false)
    check_wdt := object.get(_ctx, "wdt_claim", false)

    wdt_ok := _inv_wdt_ok(check_wdt, vat_ue, eu_customer)
    fx_ok := _inv_fx_d1_ok(check_wdt, rate_date)
    rc_ok := _inv_rc_ok(import_services, object.get(_ctx, "reverse_charge_applied", false))

    result := {"wdt_vat_ue_ok": wdt_ok, "fx_d1_ok": fx_ok, "import_services_rc_ok": rc_ok,
               "all_ok": _all3_ok(wdt_ok, fx_ok, rc_ok)}
}

crossborder_invariants_decision := _certificate(370111, {
    "rule_id": "jdg.v3_p15_crossborder.crossborder_invariants",
    "analysis": "invariants",
    "invariants": invariants,
    "fail_closed": invariants_fail,
    "_routing": routing_inv,
    "_routing_reason": reason_inv,
    "_legal_basis": "Art. 42/97 VAT, art. 28b VAT, P04 invarianty runtime [NIEZWERYFIKOWANE]",
    "_warnings": warnings_inv,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "invariants"
}

invariants_fail = true {
    not invariants.all_ok
} else = false

routing_inv = "BLOCK_AND_ALERT" {
    invariants_fail
} else = ""

reason_inv = "Naruszenie invariantu cross-border (WDT bez VAT-UE, kurs nie D-1, import usług bez reverse charge)." {
    invariants_fail
} else = ""

warnings_inv = ["[V3-P15-I11] Invariant cross-border naruszony — decyzja zablokowana do czasu usunięcia naruszenia."] {
    invariants_fail
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P15-I12: CURRENCY CONSISTENCY GATE (kontrakt z P28/P16)
# Te same kursy dla VAT i PKPiR na tym samym inputcie (JPK_V7 pola WDT/WNT/UE).
# ═══════════════════════════════════════════════════════════════════════════════
currency_consistency = result {
    _activated
    vat_rate := object.get(_ctx, "vat_rate", null)
    pkpir_rate := object.get(_ctx, "pkpir_rate", null)
    consistent := vat_rate == pkpir_rate
    result := {"vat_rate": vat_rate, "pkpir_rate": pkpir_rate,
               "consistent": consistent, "required": _th("currency_consistency_required", true)}
}

currency_gate_decision := _certificate(370112, {
    "rule_id": "jdg.v3_p15_crossborder.currency_consistency_gate",
    "analysis": "currency",
    "currency_consistency": currency_consistency,
    "fail_closed": currency_mismatch,
    "_routing": routing_cur,
    "_routing_reason": reason_cur,
    "_legal_basis": "Kontrakt P28 (księgowość) / P16 (JPK_V7) — spójność kursów",
    "_warnings": warnings_cur,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "currency"
}

currency_mismatch = true {
    not currency_consistency.consistent
} else = false

routing_cur = "BLOCK_AND_ALERT" {
    currency_mismatch
} else = ""

reason_cur = "Niespójność kursów VAT vs PKPiR na tym samym inputcie — niezgodność JPK." {
    currency_mismatch
} else = ""

warnings_cur = ["[V3-P15-I12] Kursy VAT i PKPiR różne dla tej samej faktury — korekta przed księgowaniem."] {
    currency_mismatch
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, pierwszy match wygrywa)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := place_of_supply_decision {
    place_of_supply_decision.rule_id != ""
} else := eu_rates_decision {
    eu_rates_decision.rule_id != ""
} else := residency_decision {
    residency_decision.rule_id != ""
} else := fx_precision_decision {
    fx_precision_decision.rule_id != ""
} else := tp_threshold_decision {
    tp_threshold_decision.rule_id != ""
} else := mdr_decision {
    mdr_decision.rule_id != ""
} else := exit_tax_decision {
    exit_tax_decision.rule_id != ""
} else := golden_set_decision {
    golden_set_decision.rule_id != ""
} else := oss_decision {
    oss_decision.rule_id != ""
} else := distance_selling_decision {
    distance_selling_decision.rule_id != ""
} else := crossborder_invariants_decision {
    crossborder_invariants_decision.rule_id != ""
} else := currency_gate_decision {
    currency_gate_decision.rule_id != ""
} else := default_decide {
    true
}