# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Statistical Anomaly Detection (ScAnomalyGuard — Faza 1 MVP)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Proste reguły statystyczne do wykrywania anomalii w fakturach.
# Faza 1 MVP: reguły oparte na statystykach (bez ML).
# Faza 2: integracja z zewnętrznym modelem ML.
#
# Pomysł #2 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# package: tax.anomaly
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.anomaly

# ── Default ───────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.anomaly.no_anomaly",
    "package": "tax.anomaly",
    "priority": 8,
    "anomaly_detected": false,
    "anomaly_score": 0.0
}

# ── ANO-1: Amount Z-Score Anomaly ─────────────────────────────────────────────
# Cel: Wykrycie kwoty odstającej >3σ od średniej kategorii
decide := {
    "matched": true,
    "rule_id": "tax.anomaly.amount_zscore",
    "package": "tax.anomaly",
    "priority": 8,
    "anomaly_detected": true,
    "anomaly_type": "AMOUNT_ZSCORE",
    "anomaly_score": anomaly_score,
    "z_score": z,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Kwota %.2f PLN przekracza 3σ (μ=%.2f, σ=%.2f, z=%.2f)", [
        input.invoice.amount_net,
        input.invoice.category_avg_amount,
        input.invoice.category_stddev_amount,
        z
    ]),
    "_warnings": ["ANOMALIA: Kwota faktury znacząco odbiega od średniej kategorii"]
} {
    input.invoice.category_avg_amount
    input.invoice.category_stddev_amount
    z := (input.invoice.amount_net - input.invoice.category_avg_amount) / input.invoice.category_stddev_amount
    z > 3.0
    anomaly_score := min([z / 6.0, 1.0])
}

# ── ANO-2: Vendor Anomaly — First Large Transaction ───────────────────────────
# Cel: Nowy kontrahent + wysoka kwota = anomaly
else := {
    "matched": true,
    "rule_id": "tax.anomaly.vendor_first_large",
    "package": "tax.anomaly",
    "priority": 8,
    "anomaly_detected": true,
    "anomaly_type": "VENDOR_FIRST_LARGE",
    "anomaly_score": 0.7,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Nowy kontrahent z wysoką pierwszą fakturą",
    "_warnings": ["ANOMALIA: Pierwsza faktura od nowego kontrahenta przekracza próg bezpieczeństwa"]
} {
    input.vendor.is_new == true
    input.vendor.transaction_count_with_partner < 3
    input.invoice.amount_net > object.get(input.thresholds.limits, "first_transaction_alert", 50000)
}

# ── ANO-3: Partner Cost Ratio Anomaly ─────────────────────────────────────────
# Cel: Wykrycie wspólnika generującego nieproporcjonalnie dużo kosztów
else := {
    "matched": true,
    "rule_id": "tax.anomaly.partner_cost_ratio",
    "package": "tax.anomaly",
    "priority": 8,
    "anomaly_detected": true,
    "anomaly_type": "PARTNER_COST_RATIO",
    "anomaly_score": anomaly_score,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Wspólnik %s generuje %.0f%% kosztów przy %.0f%% udziale", [
        anomalous_partner.id,
        anomalous_partner.cost_ratio * 100,
        anomalous_partner.share_percent
    ]),
    "_warnings": ["ANOMALIA: Dysproporcja między udziałem wspólnika a generowanymi kosztami"]
} {
    partners := input.partners
    count(partners) >= 2
    anomalous_partner := partners[_]
    anomalous_partner.monthly_costs > 0
    total_costs := sum([p.monthly_costs | p := partners[_]])
    anomalous_partner.cost_ratio := anomalous_partner.monthly_costs / total_costs
    anomalous_partner.cost_ratio > (anomalous_partner.share_percent / 100) * object.get(input.thresholds.limits, "partner_cost_disparity_factor", 2.0)
    anomaly_score := min([(anomalous_partner.cost_ratio / (anomalous_partner.share_percent / 100) - 1) / 2, 1.0])
}

# ── ANO-4: Seasonal Anomaly — December Spike ──────────────────────────────────
# Cel: Wykrycie nienaturalnego wzrostu faktur w grudniu (sztuczne generowanie kosztów)
else := {
    "matched": true,
    "rule_id": "tax.anomaly.seasonal_december_spike",
    "package": "tax.anomaly",
    "priority": 8,
    "anomaly_detected": true,
    "anomaly_type": "SEASONAL_DECEMBER_SPIKE",
    "anomaly_score": anomaly_score,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Grudzień: %.0f faktur vs średnia miesięczna %.0f (wzrost o %.0f%%)", [
        december_count,
        monthly_avg,
        spike_pct
    ]),
    "_warnings": ["ANOMALIA: Nietypowy wzrost liczby faktur w grudniu — potencjalne sztuczne generowanie kosztów"]
} {
    month := substring(input.invoice.transaction_date, 5, 2)
    month == "12"
    input.partnership.monthly_invoice_counts
    # Klucze używają numerów miesięcy ("01"-"12") dla spójności
    december_count := object.get(input.partnership.monthly_invoice_counts, "12", 0)
    monthly_avg := sum([v | v := object.values(input.partnership.monthly_invoice_counts)]) / count(object.values(input.partnership.monthly_invoice_counts))
    monthly_avg > 0
    december_count > monthly_avg * object.get(input.thresholds.limits, "seasonal_spike_factor", 3.0)
    spike_pct := ((december_count - monthly_avg) / monthly_avg) * 100
    anomaly_score := min([spike_pct / 300, 1.0])
}

# ── ANO-5: ML Anomaly Score Integration ───────────────────────────────────────
# Cel: Odbiera anomaly_score z zewnętrznego modelu ML (Faza 2)
# Przesłanki: input._ml_anomaly.combined_anomaly_risk == "HIGH"
else := {
    "matched": true,
    "rule_id": "tax.anomaly.ml_model_high_risk",
    "package": "tax.anomaly",
    "priority": 8,
    "anomaly_detected": true,
    "anomaly_type": "ML_MODEL",
    "anomaly_score": input._ml_anomaly.combined_score,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Model ML wykrył anomalię — wymagana weryfikacja manualna",
    "_ml_details": {
        "amount_score": object.get(input._ml_anomaly, "amount_anomaly_score", 0),
        "vendor_score": object.get(input._ml_anomaly, "vendor_anomaly_score", 0),
        "seasonal_score": object.get(input._ml_anomaly, "seasonal_anomaly_score", 0)
    },
    "_warnings": ["ANOMALIA ML: Zewnętrzny model wykrył wzorzec anomalny"]
} {
    object.get(input, "_ml_anomaly", {})
    input._ml_anomaly.combined_anomaly_risk == "HIGH"
    input.invoice.amount_net > object.get(input.thresholds.limits, "ml_anomaly_min_amount", 10000)
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Oblicza sumę elementów tablicy
sum(arr) := result {
    result := _sum(arr, 0.0)
}

_sum([], acc) := acc

_sum([h | t], acc) := _sum(t, acc + h)
