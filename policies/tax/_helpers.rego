# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Common Helpers
# ═══════════════════════════════════════════════════════════════════════════════
#
# Wspólne funkcje pomocnicze używane przez wszystkie pakiety reguł.
# Wzorzec: Policy-as-Code z separacją logiki od danych.
#
# package: tax.helpers
# ═══════════════════════════════════════════════════════════════════════════════

package tax.helpers

# ── GTU Code Mapping ──────────────────────────────────────────────────────────
# Mapuje kod kategorii na kod GTU dla JPK_V7.
# Podstawa prawna: § 10 rozporządzenia w sprawie JPK_VAT

category_to_gtu(code) = "GTU_04" {
    code == "FUEL"
} else = "GTU_01" {
    gtu_01_category(code)
} else = "GTU_07" {
    code == "FOOD"
} else = "GTU_08" {
    code == "CONSTRUCTION"
} else = "GTU_06" {
    code == "TRANSPORT"
} else = "GTU_05" {
    code == "SCRAP"
} else = "GTU_02" {
    code == "ALCOHOL"
} else = "GTU_03" {
    code == "TOBACCO"
} else = "GTU_09" {
    code == "PHARMA"
} else = "GTU_10" {
    code == "REAL_ESTATE"
} else = "GTU_11" {
    code == "GAS_ENERGY"
} else = "GTU_12" {
    code == "EU_SERVICES"
} else = "GTU_13" {
    code == "NON_EU_GOODS"
} else = "" {
    true
}

# Pomocnicze reguły kategorii (zamiast array in — kompatybilność z OPA < v0.34)
gtu_01_category(code) { code == "IT_OFFICE" }
gtu_01_category(code) { code == "ELECTRONICS" }

# ── Threshold Comparison Helpers ───────────────────────────────────────────────

# Sprawdza czy wartość >= próg z input.thresholds.limits
gte_limit(value, key) {
    value >= object.get(input.thresholds.limits, key, 999999999)
}

# Sprawdza czy wartość <= próg z input.thresholds.limits
lte_limit(value, key) {
    value <= object.get(input.thresholds.limits, key, 0)
}

# Bezpieczny odczyt stawki z input.thresholds.rates z fallbackiem
get_rate(key, fallback) = rate {
    rate := object.get(input.thresholds.rates, key, fallback)
}

# ── Field Confidence Helpers ───────────────────────────────────────────────────

# Sprawdza czy confidence pola jest poniżej progu
fc_below_threshold(fc_field, threshold_key) {
    object.get(input.confidence, fc_field, 1.0) < object.get(input.thresholds.fc_thresholds, threshold_key, 0.0)
    object.get(input.confidence, fc_field, 1.0) > 0
}

# ── Temporal Validation ────────────────────────────────────────────────────────

# Sprawdza czy data transakcji mieści się w okresie obowiązywania
is_valid_period(date) {
    date >= object.get(input.thresholds, "valid_from", "2000-01-01")
    not object.get(input.thresholds, "valid_to", null)
}

is_valid_period(date) {
    date >= object.get(input.thresholds, "valid_from", "2000-01-01")
    date <= object.get(input.thresholds, "valid_to", "2099-12-31")
}

# ── Routing Helpers ───────────────────────────────────────────────────────────

# Buduje czytelny reason dla routingu
build_routing_reason(tax_form, field_name, confidence, threshold) = reason {
    reason := concat("", [
        tax_form, ": ", field_name, " confidence ",
        sprintf("%.2f", [confidence]),
        " below threshold ",
        sprintf("%.2f", [threshold])
    ])
}

# ── Amount Converters ─────────────────────────────────────────────────────────

# Konwertuje kwotę brutto na EUR używając kursu z thresholds (z fallbackiem 4.5)
amount_eur = eur {
    eur := input.invoice.amount_gross / object.get(input.thresholds.rates, "eur_pln", 4.5)
}

# ── MPP / Split Payment Helpers ────────────────────────────────────────────────

# Lista kategorii wrażliwych wymagających MPP (załącznik nr 15 do ustawy o VAT)
# Używamy incremental rules zamiast set literal dla kompatybilności z OPA < v0.34
is_mpp_sensitive("FUEL")
is_mpp_sensitive("STEEL")
is_mpp_sensitive("ELECTRONICS")
is_mpp_sensitive("CONSTRUCTION")
is_mpp_sensitive("SCRAP")
is_mpp_sensitive("ALCOHOL")
