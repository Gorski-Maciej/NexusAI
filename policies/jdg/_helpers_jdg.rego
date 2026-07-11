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
#   warning builders.
# architecture: B2 Decoupled Thresholds — używa data.thresholds (nie input.thresholds)
#   dla lepszego cache'owania OPA i mniejszych payloadów API.
# priority: N/A (helper library, nie reguła decyzyjna)
# package: jdg.helpers
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.helpers

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

# ── MPP / Split Payment Helpers ────────────────────────────────────────────────

# Lista kategorii wrażliwych wymagających MPP (załącznik nr 15 do VAT)
# Incremental rules dla kompatybilności z OPA < v0.34
jdg_is_mpp_sensitive("FUEL")
jdg_is_mpp_sensitive("STEEL")
jdg_is_mpp_sensitive("ELECTRONICS")
jdg_is_mpp_sensitive("CONSTRUCTION")
jdg_is_mpp_sensitive("SCRAP")
jdg_is_mpp_sensitive("ALCOHOL")

# ── Warning Builders ───────────────────────────────────────────────────────────

# Buduje array ostrzeżeń z opcjonalnym warningiem
build_warnings(info_msg, warning_msg, condition) = warnings {
    condition
    warnings := [info_msg, warning_msg]
} else = [info_msg] {
    warnings := [info_msg]
}
