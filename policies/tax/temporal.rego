# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Temporal Threshold Selection (ScTemporalSandbox)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Mechanizm automatycznego doboru zestawu thresholds na podstawie daty transakcji.
# Każdy zestaw thresholds ma valid_from i valid_to.
# Dla dat granicznych stosuje regułę transition.
#
# Ulepszenie #1 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# package: tax.temporal
# rule:     select_thresholds, effective_thresholds
# ═══════════════════════════════════════════════════════════════════════════════

package tax.temporal

import data.tax.helpers

# ── Temporal Threshold Selection ──────────────────────────────────────────────
# Wybiera aktywny zestaw thresholds na podstawie daty transakcji.
# Jeśli istnieje wiele pasujących okresów, wybiera ten z najpóźniejszym valid_from.

# Domyślny — brak dopasowania okresu
default effective_thresholds := input.thresholds

# Dopasowanie pojedynczego okresu
effective_thresholds := period.thresholds {
    period := input.thresholds._temporal_periods[_]
    input.invoice.transaction_date >= period.valid_from
    not period.valid_to
}

effective_thresholds := period.thresholds {
    period := input.thresholds._temporal_periods[_]
    input.invoice.transaction_date >= period.valid_from
    input.invoice.transaction_date <= period.valid_to
}

# ── Active Period Detection ───────────────────────────────────────────────────
# Zwraca ID aktywnego okresu (dla audytu)

active_period_id := period.id {
    period := input.thresholds._temporal_periods[_]
    input.invoice.transaction_date >= period.valid_from
    not period.valid_to
}

active_period_id := period.id {
    period := input.thresholds._temporal_periods[_]
    input.invoice.transaction_date >= period.valid_from
    input.invoice.transaction_date <= period.valid_to
}

# ── Transition Detection ──────────────────────────────────────────────────────
# Wykrywa czy transakcja jest w okresie przejściowym (między okresami)

is_transition_period {
    count({pid |
        pid := active_period_id
    }) > 1
}

is_transition_period {
    input.invoice.transaction_date >= object.get(input.thresholds, "_transition_from", "2099-12-31")
    input.invoice.transaction_date <= object.get(input.thresholds, "_transition_to", "2000-01-01")
}

# ── Threshold Resolution ──────────────────────────────────────────────────────
# Bezpieczny odczyt wartości z effective_thresholds z fallbackiem do input.thresholds

resolve_limit(key, fallback) := val {
    val := object.get(effective_thresholds.limits, key, object.get(input.thresholds.limits, key, fallback))
}

resolve_rate(key, fallback) := val {
    val := object.get(effective_thresholds.rates, key, object.get(input.thresholds.rates, key, fallback))
}

# ── Temporal Audit Trail ──────────────────────────────────────────────────────
# Buduje wpis audytowy dla temporalnej decyzji

temporal_audit := audit {
    audit := {
        "effective_period_id": active_period_id,
        "transaction_date": input.invoice.transaction_date,
        "is_transition": is_transition_period,
        "thresholds_source": "TEMPORAL_SANDBOX",
        "resolved_at": time.now_ns()
    }
}

# ── Future Date Detection ─────────────────────────────────────────────────────
# Wykrywa transakcje z datą przyszłą względem wszystkich zdefiniowanych okresów

future_period_detected {
    input.invoice.transaction_date > max_valid_from_str
}

# String comparison works for ISO dates in YYYY-MM-DD format
max_valid_from_str := max_date {
    dates := [p.valid_from | p := input.thresholds._temporal_periods[_]]
    max_date := sort(dates)[count(dates) - 1]
}

# ── Temporal Warning Generator ────────────────────────────────────────────────
# Generuje ostrzeżenie gdy transakcja jest blisko granicy okresu
# UWAGA: dates w thresholds muszą być w formacie RFC3339 (np. "2026-06-30T23:59:59Z")
# lub być konwertowane przez concat z "T00:00:00Z"

near_period_boundary(days) {
    some period in input.thresholds._temporal_periods
    period.valid_to
    period_end_ns := time.parse_ns(concat("", [period.valid_to, "T23:59:59Z"]))
    transaction_ns := time.parse_ns(concat("", [input.invoice.transaction_date, "T00:00:00Z"]))
    days_to_boundary_ns := (period_end_ns - transaction_ns) / 86400000000000
    days_to_boundary_ns <= days
    days_to_boundary_ns > 0
}

temporal_warnings := warnings {
    warnings := array.concat(
        [msg | is_transition_period; msg := "TRANSITION_PERIOD: Transakcja w okresie przejściowym między zestawami thresholds"],
        [msg | future_period_detected; msg := "FUTURE_PERIOD: Brak zdefiniowanych thresholds dla daty transakcji"],
        [msg | near_period_boundary(30); msg := "PERIOD_BOUNDARY_NEAR: Transakcja w ciągu 30 dni od zmiany okresu thresholds"]
    )
}

# ── Decision Rule ─────────────────────────────────────────────────────────────
# Zawsze zwraca metadane temporalne

default decide := {
    "matched": false,
    "rule_id": "tax.temporal.no_match",
    "package": "tax.temporal",
    "priority": 5
}

decide := {
    "matched": true,
    "rule_id": "tax.temporal.period_active",
    "package": "tax.temporal",
    "priority": 5,
    "effective_period": active_period_id,
    "thresholds_resolved": true,
    "_audit_temporal": temporal_audit,
    "_warnings": temporal_warnings,
    "_routing": routing_from_warnings
}

routing_from_warnings := "WARN" {
    count(temporal_warnings) > 0
}

routing_from_warnings := "OK" {
    count(temporal_warnings) == 0
}
