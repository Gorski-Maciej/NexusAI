# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Common Helpers
# ═══════════════════════════════════════════════════════════════════════════════
#
# Common helpers for all JDG packages.
# Provides: threshold helpers, tax form detection, field confidence,
# routing reason builders, currency/date helpers, MPP detection,
# warning builders, temporal gating (is_active / is_active_now).
# Architecture: B2 Decoupled Thresholds.
# Package: jdg.helpers
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.helpers

import data.jdg.metadata

# ── Threshold Helpers ─────────────────────────────────────────────────────────

# Bezpieczny odczyt progu z data.jdg.thresholds.limits
get_jdg_limit(key, fallback) = value  if {
    value := object.get(data.jdg.thresholds.limits, key, fallback)
}

# Bezpieczny odczyt stawki z data.jdg.thresholds.rates
get_jdg_rate(key, fallback) = rate  if {
    rate := object.get(data.jdg.thresholds.rates, key, fallback)
}

# ── Tax Form Detection ────────────────────────────────────────────────────────

# Zwraca formę opodatkowania JDG (PIT_SCALE / LINEAR / LUMP_SUM / TAX_CARD)
jdg_tax_form = form  if {
    form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# Czy JDG jest na skali podatkowej?
is_scale = true if {
    jdg_tax_form == "PIT_SCALE"
}

# Czy JDG jest na podatku liniowym?
is_linear = true if {
    jdg_tax_form == "LINEAR"
}

# Czy JDG jest na ryczałcie?
is_lump_sum = true if {
    jdg_tax_form == "LUMP_SUM"
}

# Czy JDG jest na karcie podatkowej?
is_tax_card = true if {
    jdg_tax_form == "TAX_CARD"
}

# ── Field Confidence Helpers ───────────────────────────────────────────────────

# Sprawdza czy confidence pola jest poniżej progu JDG
jdg_fc_below_threshold(fc_field, threshold_key)  if {
    object.get(input.confidence, fc_field, 1.0) < object.get(data.jdg.thresholds.fc_thresholds, threshold_key, 0.0)
    object.get(input.confidence, fc_field, 1.0) > 0
}

# ── Building Routing Reason ────────────────────────────────────────────────────

build_jdg_routing_reason(tax_form, field_name, confidence, threshold) = reason  if {
    reason := concat("", [
        "[JDG] ", tax_form, ": ", field_name, " confidence ",
        sprintf("%.2f", [confidence]),
        " below threshold ",
        sprintf("%.2f", [threshold])
    ])
}

# ── Amount / Currency Helpers ──────────────────────────────────────────────────

# Konwertuje kwotę brutto na EUR używając kursu z thresholds
jdg_amount_eur = eur  if {
    eur := input.invoice.amount_gross / object.get(data.jdg.thresholds.bounds, "eur_pln", 4.5)
}

# ── Date Helpers ───────────────────────────────────────────────────────────────

# Oblicza liczbę dni między dwiema datami ISO (date2 - date1)
# Używa time.parse_ns do konwersji na nanosekundy, potem dzieli na dni
# Przykład: days_between("2026-01-01", "2026-01-15") → 14
days_between(date1, date2) = days  if {
    t1 := time.parse_ns("2006-01-02", date1)
    t2 := time.parse_ns("2006-01-02", date2)
    days := (t2 - t1) / 86400000000000
}

# Sprawdza czy data transakcji mieści się w okresie obowiązywania reguły JDG
jdg_is_valid_period(date_str)  if {
    date_str >= object.get(data.jdg.thresholds, "valid_from", "2000-01-01")
    not object.get(data.jdg.thresholds, "valid_to", null)
}

jdg_is_valid_period(date_str)  if {
    date_str >= object.get(data.jdg.thresholds, "valid_from", "2000-01-01")
    date_str <= object.get(data.jdg.thresholds, "valid_to", "2099-12-31")
}

# ── Per-Rule Temporal Validity (Doc 34 §0.1 Temporalność) ──────────────────
# Wykorzystuje temporal_validity z data.jdg.metadata.
# Semantyka (wariant A — bezpieczny dla wstecznej kompatybilności):
#   - Reguła BEZ wpisu w temporal_validity = ALWAYS ACTIVE
#   - Reguła Z wpisem = aktywna wtw valid_from ≤ date_str ≤ valid_to
#   - valid_to == null = obowiązuje do odwołania
# 3 rozłączne branche (defensywne disjointness guards):
#   - Branch 1: not metadata.is_temporal_rule(rule_id)            → ALWAYS ACTIVE
#   - Branch 2: valid_to == null                                    → bez ograniczenia górnego
#   - Branch 3: valid_to != null                                    → w przedziale [valid_from, valid_to]
# Daty ISO YYYY-MM-DD porównywane leksykograficznie (string sort order === chronological).
#
# Typowe użycie w innym pakiecie Rego:
#   import data.jdg.helpers
#   ...
#   decide := { ... }  if {
#     is_active("jdg.zus.health_scale", "2026-03-15")   # TRUE (Polski Ład nadal obowiązuje)
#     is_active("jdg.zus.health_scale", "2021-12-31")  # FALSE (przed Polskim Ładem)
#     is_active("jdg.business.ceidg_registration_check", "2026-03-15")  # TRUE (brak wpisu)
#   }
is_active(rule_id, date_str)  if {
    not metadata.is_temporal_rule(rule_id)
}

is_active(rule_id, date_str)  if {
    validity := metadata.get_rule_validity(rule_id)
    valid_from := object.get(validity, "valid_from", "0000-01-01")
    valid_to := validity.valid_to
    valid_to == null
    date_str >= valid_from
}

is_active(rule_id, date_str)  if {
    validity := metadata.get_rule_validity(rule_id)
    valid_from := object.get(validity, "valid_from", "0000-01-01")
    valid_to := validity.valid_to
    valid_to != null              # ⬅ explicit disjointness guard vs Branch 2
    date_str >= valid_from
    date_str <= valid_to
}

# Wygodny wrapper — czy reguła jest aktywna TERAZ (używa daty z input)
# Szuka daty w kolejności: input.evaluation_date → input.invoice.transaction_date
# → input.invoice.issue_date → input.jdg_entrepreneur.tax_period_start
is_active_now(rule_id)  if {
    eval_date := object.get(input, "evaluation_date", "")
    eval_date != ""
    is_active(rule_id, eval_date)
}

is_active_now(rule_id)  if {
    not object.get(input, "evaluation_date", "")
    inv_date := object.get(input.invoice, "transaction_date", "")
    inv_date != ""
    is_active(rule_id, inv_date)
}

is_active_now(rule_id)  if {
    not object.get(input, "evaluation_date", "")
    not object.get(input.invoice, "transaction_date", "")
    inv_date := object.get(input.invoice, "issue_date", "")
    inv_date != ""
    is_active(rule_id, inv_date)
}

# Bezpieczny fail: jeśli ŻADNA z dat nie jest dostępna w input
# → is_active_now nie matchuje żadnego branch → reguły temporalne
# traktowane jako NIEAKTYWNE (a nie aktywne od "2099-12-31").

# ── MPP / Split Payment Helpers ────────────────────────────────────────────────

# Lista kategorii wrażliwych wymagających MPP (załącznik nr 15 do VAT)
# v7.0 FIX: Rozszerzona z 6 do 47+ kategorii pokrywających pełny Załącznik 15
# Incremental rules dla kompatybilności z OPA < v0.34

# Grupa 1: Paliwa i energia (CN 2701-2716)
jdg_is_mpp_sensitive("FUEL")
jdg_is_mpp_sensitive("FUEL_HEATING")
jdg_is_mpp_sensitive("FUEL_DIESEL")
jdg_is_mpp_sensitive("FUEL_GASOLINE")
jdg_is_mpp_sensitive("FUEL_LPG")
jdg_is_mpp_sensitive("COAL")
jdg_is_mpp_sensitive("COAL_BROWN")
jdg_is_mpp_sensitive("COKE")
jdg_is_mpp_sensitive("CRUDE_OIL")
jdg_is_mpp_sensitive("OIL_LUBRICANTS")
jdg_is_mpp_sensitive("GAS_NATURAL")

# Grupa 2: Stal i metale (CN 7206-7229, 7601-7607)
jdg_is_mpp_sensitive("STEEL")
jdg_is_mpp_sensitive("STEEL_SEMI")
jdg_is_mpp_sensitive("STEEL_PIPE")
jdg_is_mpp_sensitive("IRON")
jdg_is_mpp_sensitive("ALUMINUM")
jdg_is_mpp_sensitive("ALUMINUM_RAW")
jdg_is_mpp_sensitive("COPPER")
jdg_is_mpp_sensitive("LEAD")
jdg_is_mpp_sensitive("ZINC")
jdg_is_mpp_sensitive("TIN")
jdg_is_mpp_sensitive("PRECIOUS_METALS")
jdg_is_mpp_sensitive("GOLD_RAW")
jdg_is_mpp_sensitive("SILVER_RAW")
jdg_is_mpp_sensitive("PLATINUM_RAW")

# Grupa 3: Elektronika (CN 8471, 8517)
jdg_is_mpp_sensitive("ELECTRONICS")
jdg_is_mpp_sensitive("COMPUTERS")
jdg_is_mpp_sensitive("LAPTOPS")
jdg_is_mpp_sensitive("TABLETS")
jdg_is_mpp_sensitive("SMARTPHONES")
jdg_is_mpp_sensitive("ELECTRONICS_CONSUMER")

# Grupa 4: Budownictwo (PKWiU 41-43)
jdg_is_mpp_sensitive("CONSTRUCTION")
jdg_is_mpp_sensitive("CONSTRUCTION_RESIDENTIAL")
jdg_is_mpp_sensitive("CONSTRUCTION_SERVICES")
jdg_is_mpp_sensitive("CONSTRUCTION_MATERIALS")
jdg_is_mpp_sensitive("CONSTRUCTION_SUBCONTRACTING")

# Grupa 5: Odpady i surowce wtórne (CN 3915, 4707, 7001)
jdg_is_mpp_sensitive("SCRAP")
jdg_is_mpp_sensitive("SCRAP_METAL")
jdg_is_mpp_sensitive("WASTE")
jdg_is_mpp_sensitive("WASTE_GLASS")
jdg_is_mpp_sensitive("WASTE_PAPER")
jdg_is_mpp_sensitive("WASTE_PLASTIC")
jdg_is_mpp_sensitive("RECYCLABLES")

# Grupa 6: Alkohol i wyroby akcyzowe
jdg_is_mpp_sensitive("ALCOHOL")
jdg_is_mpp_sensitive("BEVERAGES_ALCOHOLIC")
jdg_is_mpp_sensitive("TOBACCO")

# Grupa 7: Pojazdy i części (CN 8708)
jdg_is_mpp_sensitive("VEHICLES")
jdg_is_mpp_sensitive("CAR_PARTS")
jdg_is_mpp_sensitive("CAR_NEW")

# Grupa 8: Produkty rolne (CN 1001-1008, 1201-1207, 1701, 1801-1806)
jdg_is_mpp_sensitive("GRAIN")
jdg_is_mpp_sensitive("CEREALS")
jdg_is_mpp_sensitive("SUGAR")
jdg_is_mpp_sensitive("COCOA")
jdg_is_mpp_sensitive("CHOCOLATE")
jdg_is_mpp_sensitive("OILSEEDS")

# Grupa 9: Tekstylia i odzież (CN 5007-5113, 6101-6117, 6401-6405)
jdg_is_mpp_sensitive("TEXTILES")
jdg_is_mpp_sensitive("CLOTHING")
jdg_is_mpp_sensitive("FOOTWEAR")

# Grupa 10: Usługi niematerialne i certyfikaty
jdg_is_mpp_sensitive("CO2_CERTIFICATES")
jdg_is_mpp_sensitive("GREEN_CERTIFICATES")
jdg_is_mpp_sensitive("EMISSION_CERTIFICATES")

# ── CN Code Mapping for MPP (v7.0 NEW: bridge z Python MPPAnnex15Engine) ─────
# Full Załącznik 15 — 47 pozycji kodów CN
# Używane przez P100/P102/P103 w substantive.rego i compliance.rego P25
# CN code → category mapping
jdg_mpp_cn_to_category := {
    "2701": "COAL", "2702": "COAL", "2704": "COAL",
    "2710": "FUEL", "2711": "FUEL", "2713": "FUEL_HEATING",
    "7106": "PRECIOUS_METALS", "7108": "PRECIOUS_METALS",
    "7207": "STEEL", "7208": "STEEL", "7214": "STEEL",
    "7225": "STEEL", "7402": "COPPER", "7404": "SCRAP",
    "7601": "ALUMINUM", "7602": "SCRAP",
    "7801": "NON_FERROUS", "7901": "NON_FERROUS", "8001": "NON_FERROUS",
    "8471": "ELECTRONICS", "8517": "ELECTRONICS", "8528": "ELECTRONICS",
    "3915": "WASTE", "4004": "WASTE", "4707": "WASTE", "7001": "WASTE",
    "7204": "SCRAP", "8708": "AUTO_PARTS",
    "1001": "GRAIN", "1201": "GRAIN",
    "1507": "OILS", "1701": "FOOD", "1801": "FOOD",
    "6101": "TEXTILES", "6201": "TEXTILES", "6401": "TEXTILES",
    "5007": "TEXTILES", "5208": "TEXTILES", "5407": "TEXTILES",
    "8501": "MACHINERY", "9401": "FURNITURE"
}

# CN code → is_mpp_sensitive (bridge integration)
jdg_is_mpp_sensitive_by_cn(cn_code) {
    category := jdg_mpp_cn_to_category[substring(cn_code, 0, 4)]
    category != ""
}

# ── Warning Builders ───────────────────────────────────────────────────────────

# Buduje array ostrzeżeń z opcjonalnym warningiem
build_warnings(info_msg, warning_msg, condition) = warnings  if {
    condition
    warnings := [info_msg, warning_msg]
} else = [info_msg]  if {
    warnings := [info_msg]
}

# ═══════════════════════════════════════════════════════════════════════════════
# SELF-HEALING ROUTER — Health Monitor (Innowacja 9.1)
#
# Warstwa monitorowania zdrowia pakietów. Wstrzykiwana z Python health monitora
# (rolling window 100 ewaluacji). Pakiet z >20% błędów jest automatycznie
# wykluczany na TTL 5 min i zastępowany fallback.decide.
#
# Użycie:
#   import data.jdg.helpers
#   is_healthy("jdg.kks")  # true jeśli pakiet działa poprawnie
# ═══════════════════════════════════════════════════════════════════════════════

# Sprawdza czy pakiet jest zdrowy (health status z Python bridge)
# Używa defensywnego dostępu do data.jdg.health (może nie istnieć w testach)
is_package_healthy(package_name) = true {
    health_data := object.get(object.get(data, "jdg", {}), "health", {})
    not health_data[package_name]
} else = true {
    health_data := object.get(object.get(data, "jdg", {}), "health", {})
    health := health_data[package_name]
    object.get(health, "error_rate", 0) < object.get(health, "max_error_rate", 0.20)
} else = false {
    true
}

# Zwraca pakiet lub fallback jeśli niezdrowy (Innowacja 9.1)
healthy_or_fallback(package_name, package_result, fallback_result) = result {
    is_package_healthy(package_name)
    result := package_result
} else = result {
    result := fallback_result
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADAPTIVE PRIORITY ENGINE — Dynamiczne priorytety (Innowacja 9.7)
#
# Efektywny priorytet = bazowy + waga ryzyka + waga historyczna + waga temporalna.
# Wagi wstrzykiwane z Python pre-processora jako data.jdg.priority_weights.
# Reguła czyta swoją wagę z danych (fallback 0).
# ═══════════════════════════════════════════════════════════════════════════════

# Oblicza efektywny priorytet dynamiczny dla reguły
get_adaptive_priority(rule_id, base_priority) = effective {
    weights := object.get(object.get(data, "jdg", {}), "priority_weights", {})
    risk_weight := object.get(weights, sprintf("%s.risk", [rule_id]), 0)
    history_weight := object.get(weights, sprintf("%s.history", [rule_id]), 0)
    temporal_weight := object.get(weights, sprintf("%s.temporal", [rule_id]), 0)
    effective := base_priority + risk_weight + history_weight + temporal_weight
} else = base_priority {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEMPORAL SNAPSHOT ENGINE — Routing epok prawnych (Innowacja 9.4)
#
# Zamiast rejestru per-reguła, wybiera bundle OPA dla epoki prawnej.
# Epoki: pre-2019, 2019-2021, 2022-H1, 2022-H2, 2023-2025, 2026+.
# Router wybiera snapshot wg evaluation_date.
# ═══════════════════════════════════════════════════════════════════════════════

# Wybiera snapshot epoki prawnej dla daty ewaluacji
get_temporal_snapshot(eval_date) = snapshot {
    eval_date >= "2026-01-01"
    snapshot := "2026_PLUS"
} else = snapshot {
    eval_date >= "2023-01-01"
    snapshot := "2023_2025"
} else = snapshot {
    eval_date >= "2022-07-01"
    snapshot := "2022_H2"
} else = snapshot {
    eval_date >= "2022-01-01"
    snapshot := "2022_H1"
} else = snapshot {
    eval_date >= "2019-01-01"
    snapshot := "2019_2021"
} else = "PRE_2019" {
    true
}

# Zwraca nazwę bundle OPA dla danej epoki temporalnej
get_temporal_bundle(eval_date) = bundle {
    snapshot := get_temporal_snapshot(eval_date)
    bundle := concat("", ["jdg.snapshot.", snapshot])
}

# ── Cumulative Sum Helper (P31 FAZA 3.13) ─────────────────────────────────────
# Sumuje pierwsze N elementów tablicy (narastający przychód/dochód od stycznia)
cumulative_sum(arr, n) = sum_val {
    count(arr) > 0
    n > 0
    sum_val := sum([arr[i] | i := numbers.range(0, min([n, count(arr)]) - 1)])
} else = 0 {
    true
}

# Minimum of two numbers
min_num(a, b) = a { a < b } else = b
