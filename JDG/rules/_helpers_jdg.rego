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

# Bezpieczny odczyt progu z data.thresholds.jdg.limits
get_jdg_limit(key, fallback) = value  if {
    value := object.get(data.thresholds.jdg.limits, key, fallback)
}

# Bezpieczny odczyt stawki z data.thresholds.jdg.rates
get_jdg_rate(key, fallback) = rate  if {
    rate := object.get(data.thresholds.jdg.rates, key, fallback)
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
    object.get(input.confidence, fc_field, 1.0) < object.get(data.thresholds.jdg.fc_thresholds, threshold_key, 0.0)
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
    eur := input.invoice.amount_gross / object.get(data.thresholds.jdg.rates, "eur_pln", 4.5)
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
    date_str >= object.get(data.thresholds.jdg, "valid_from", "2000-01-01")
    not object.get(data.thresholds.jdg, "valid_to", null)
}

jdg_is_valid_period(date_str)  if {
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
# Incremental rules dla kompatybilności z OPA < v0.34
jdg_is_mpp_sensitive("FUEL")
jdg_is_mpp_sensitive("STEEL")
jdg_is_mpp_sensitive("ELECTRONICS")
jdg_is_mpp_sensitive("CONSTRUCTION")
jdg_is_mpp_sensitive("SCRAP")
jdg_is_mpp_sensitive("ALCOHOL")

# ── Warning Builders ───────────────────────────────────────────────────────────

# Buduje array ostrzeżeń z opcjonalnym warningiem
build_warnings(info_msg, warning_msg, condition) = warnings  if {
    condition
    warnings := [info_msg, warning_msg]
} else = [info_msg]  if {
    warnings := [info_msg]
}
