# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Common Helpers
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Common Helpers — Reusable Utility Functions
# description: |
#   Wspólne funkcje pomocnicze dla wszystkich pakietów JDG.
#   Używane przez wszystkie pakiety poprzez `import data.jdg.helpers`.
#   Zawiera: threshold helpers, tax form detection, field confidence,
#   routing reason builders, currency/date helpers, MPP detection,
#   warning builders, **temporal gating** (is_active / is_active_now).
#   Łańcuch import: biznes → helpers → metadata (brak cyklu, metadata ma no imports).
# architecture: B2 Decoupled Thresholds — używa data.thresholds (nie input.thresholds)
#   dla lepszego cache'owania OPA i mniejszych payloadów API.
#   Temporal Validity Registry w metadata jest SSoT dla temporalności reguł.
# priority: N/A (helper library, nie reguła decyzyjna)
# package: jdg.helpers
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.helpers

import data.jdg.metadata

# ── Threshold Helpers ─────────────────────────────────────────────────────────

# Bezpieczny odczyt progu z data.thresholds.jdg.limits
get_jdg_limit(key, fallback) = value {
    value := object.get(data.thresholds.jdg.limits, key, fallback)
}

# Bezpieczny odczyt stawki z data.thresholds.jdg.rates
get_jdg_rate(key, fallback) = rate {
    rate := object.get(data.thresholds.jdg.rates, key, fallback)
}

# ── Tax Form Detection ────────────────────────────────────────────────────────

# Zwraca formę opodatkowania JDG (PIT_SCALE / LINEAR / LUMP_SUM / TAX_CARD)
jdg_tax_form = form {
    form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# Czy JDG jest na skali podatkowej?
is_scale {
    jdg_tax_form == "PIT_SCALE"
}

# Czy JDG jest na podatku liniowym?
is_linear {
    jdg_tax_form == "LINEAR"
}

# Czy JDG jest na ryczałcie?
is_lump_sum {
    jdg_tax_form == "LUMP_SUM"
}

# Czy JDG jest na karcie podatkowej?
is_tax_card {
    jdg_tax_form == "TAX_CARD"
}

# ── Field Confidence Helpers ───────────────────────────────────────────────────

# Sprawdza czy confidence pola jest poniżej progu JDG
jdg_fc_below_threshold(fc_field, threshold_key) {
    object.get(input.confidence, fc_field, 1.0) < object.get(data.thresholds.jdg.fc_thresholds, threshold_key, 0.0)
    object.get(input.confidence, fc_field, 1.0) > 0
}

# ── Building Routing Reason ────────────────────────────────────────────────────

build_jdg_routing_reason(tax_form, field_name, confidence, threshold) = reason {
    reason := concat("", [
        "[JDG] ", tax_form, ": ", field_name, " confidence ",
        sprintf("%.2f", [confidence]),
        " below threshold ",
        sprintf("%.2f", [threshold])
    ])
}

# ── Amount / Currency Helpers ──────────────────────────────────────────────────

# Konwertuje kwotę brutto na EUR używając kursu z thresholds
jdg_amount_eur = eur {
    eur := input.invoice.amount_gross / object.get(data.thresholds.jdg.rates, "eur_pln", 4.5)
}

# ── Date Helpers ───────────────────────────────────────────────────────────────

# Sprawdza czy data transakcji mieści się w okresie obowiązywania reguły JDG
jdg_is_valid_period(date_str) {
    date_str >= object.get(data.thresholds.jdg, "valid_from", "2000-01-01")
    not object.get(data.thresholds.jdg, "valid_to", null)
}

jdg_is_valid_period(date_str) {
    date_str >= object.get(data.thresholds.jdg, "valid_from", "2000-01-01")
    date_str <= object.get(data.thresholds.jdg, "valid_to", "2099-12-31")
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
#   decide := { ... } {
#     is_active("jdg.zus.health_scale", "2026-03-15")   # TRUE (Polski Ład nadal obowiązuje)
#     is_active("jdg.zus.health_scale", "2021-12-31")  # FALSE (przed Polskim Ładem)
#     is_active("jdg.business.ceidg_registration_check", "2026-03-15")  # TRUE (brak wpisu)
#   }
is_active(rule_id, date_str) {
    not metadata.is_temporal_rule(rule_id)
}

is_active(rule_id, date_str) {
    validity := metadata.get_rule_validity(rule_id)
    valid_from := object.get(validity, "valid_from", "0000-01-01")
    valid_to := validity.valid_to
    valid_to == null
    date_str >= valid_from
}

is_active(rule_id, date_str) {
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
is_active_now(rule_id) {
    eval_date := object.get(input, "evaluation_date", "")
    eval_date != ""
    is_active(rule_id, eval_date)
}

is_active_now(rule_id) {
    not object.get(input, "evaluation_date", "")
    inv_date := object.get(input.invoice, "transaction_date", "")
    inv_date != ""
    is_active(rule_id, inv_date)
}

is_active_now(rule_id) {
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

# ── Warning Builders ───────────────────────────────────────────────────────────

# Buduje array ostrzeżeń z opcjonalnym warningiem
build_warnings(info_msg, warning_msg, condition) = warnings {
    condition
    warnings := [info_msg, warning_msg]
} else = [info_msg] {
    warnings := [info_msg]
}
