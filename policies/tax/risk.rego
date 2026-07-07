# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Risk & Fraud Rules (P0-P9)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły wykrywania ryzyka i fraudu — najwyższy priorytet (first-match-wins).
# Każda reguła może zablokować dalsze przetwarzanie faktury.
#
# Wzorzec: FINOS OpenEAGO — Runtime Controls z hard-stop thresholds.
#
# package: tax.risk
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.risk

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.risk.no_match",
    "package": "tax.risk",
    "priority": 9
}

# ═══════════════════════════════════════════════════════════════════════════════
# P0: fraud_graph_match (Priority 0)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Natychmiastowa blokada faktury od kontrahenta w sieci fraudowej
# Przesłanki: vendor.fraud_flag == true
# Podstawa prawna: Art. 86 ust. 1 VAT, Art. 55 KKS

# ── P0: fraud_graph_match ─────────────────────────────────────────────────────
# Cel biznesowy: Blokada faktury od kontrahenta w sieci fraudowej VAT
# Przesłanki: vendor.fraud_flag == true
# Podstawa prawna: Art. 86 ust. 1 VAT, Art. 55 KKS
# Priorytet: 0
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.risk.fraud_graph_match",
    "package": "tax.risk",
    "priority": 0,
    "vat_rate": "",
    "rounding_level": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kontrahent zidentyfikowany w sieci fraudowej VAT",
    "_legal_basis": "Art. 86 ust. 1 VAT, Art. 55 KKS",
    "fraud_detected": true,
    "_warnings": ["Podejrzenie wyłudzenia VAT — natychmiastowa blokada"]
} {
    input.vendor.fraud_flag == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1: counterparty_trust_low (Priority 1)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Niski trust score kontrahenta → alert dla księgowego
# Przesłanki: trust_score < trust_auto_post (z thresholds)
# Podstawa prawna: Art. 22 UoR (zasada ostrożności), ADR-009

# ── P1: counterparty_trust_low ────────────────────────────────────────────────
# Cel biznesowy: Niski trust score kontrahenta → TRIAGE_QUEUE
# Przesłanki: trust_score < trust_auto_post AND trust_score > 0
# Podstawa prawna: Art. 22 UoR (zasada ostrożności), ADR-009
# Priorytet: 1
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.risk.counterparty_trust_low",
    "package": "tax.risk",
    "priority": 1,
    "vat_rate": "",
    "rounding_level": "",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": concat("", [
        "Niski trust score kontrahenta: ",
        sprintf("%.2f", [input.vendor.trust_score]),
        " < ", sprintf("%.2f", [input.thresholds.limits.trust_auto_post])
    ]),
    "_legal_basis": "Art. 22 UoR (zasada ostrożności), ADR-009",
    "vendor_trust_score": input.vendor.trust_score
} {
    input.vendor.trust_score < object.get(input.thresholds.limits, "trust_auto_post", 0.92)
    input.vendor.trust_score > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P2: anomaly_amount (Priority 2)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Wykrycie anomalii kwotowej >3σ od średniej kategorii
# Przesłanki: amount_net > (avg + 3*stddev)
# Podstawa prawna: Art. 22 UoR (zasada ostrożności)

# ── P2: anomaly_amount ────────────────────────────────────────────────────────
# Cel biznesowy: Wykrycie anomalii kwotowej >3σ
# Przesłanki: amount_net > (category_avg + 3 * category_stddev)
# Podstawa prawna: Art. 22 UoR (zasada ostrożności)
# Priorytet: 2
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.risk.anomaly_amount",
    "package": "tax.risk",
    "priority": 2,
    "vat_rate": "",
    "rounding_level": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kwota faktury przekracza 3σ od średniej dla kategorii",
    "_legal_basis": "Art. 22 UoR (zasada ostrożności)",
    "_anomaly_zscore": (input.invoice.amount_net - input.invoice.category_avg_amount) / input.invoice.category_stddev_amount
} {
    input.invoice.category_avg_amount
    input.invoice.category_stddev_amount
    input.invoice.amount_net > input.invoice.category_avg_amount + 3 * input.invoice.category_stddev_amount
}

# ═══════════════════════════════════════════════════════════════════════════════
# P3: new_counterparty_flag (Priority 3)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Nowy kontrahent (pierwsze faktury) → dodatkowa weryfikacja
# Przesłanki: vendor.is_new == true
# Podstawa prawna: Art. 22 UoR (rzetelność ksiąg), procedury AML

# ── P3: new_counterparty_flag ─────────────────────────────────────────────────
# Cel biznesowy: Nowy kontrahent → TRIAGE_QUEUE
# Przesłanki: vendor.is_new == true
# Podstawa prawna: Art. 22 UoR (rzetelność ksiąg), procedury AML
# Priorytet: 3
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.risk.new_counterparty_flag",
    "package": "tax.risk",
    "priority": 3,
    "vat_rate": "",
    "rounding_level": "",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Nowy kontrahent — wymagana dodatkowa weryfikacja przed księgowaniem",
    "_legal_basis": "Art. 22 UoR (rzetelność ksiąg), procedury AML"
} {
    input.vendor.is_new == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P5: semantic_guard_disallowed (Priority 5)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Wykrycie wydatków niezwiązanych z działalnością gospodarczą
# Przesłanki: category_code in [ALCOHOL, ENTERTAINMENT, LUXURY]
# Podstawa prawna: Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT

# ── P5: semantic_guard_disallowed ─────────────────────────────────────────────
# Cel biznesowy: Wydatki niezwiązane z działalnością → NKUP + BLOCK
# Przesłanki: category_code in [ALCOHOL, ENTERTAINMENT, LUXURY] AND expense_type != REPRESENTATION
# Podstawa prawna: Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT
# Priorytet: 5
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.risk.semantic_guard_disallowed",
    "package": "tax.risk",
    "priority": 5,
    "income_tax_qualification": "non_deductible",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wydatek niezwiązany z działalnością gospodarczą",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT",
    "_warnings": ["Wydatek nie stanowi kosztu uzyskania przychodu"]
} {
    disallowed_category(input.invoice.category_code)
    input.invoice.expense_type != "REPRESENTATION"
}

# Pomocnicze: kategorie wydatków niezwiązanych z działalnością
disallowed_category("ALCOHOL")
disallowed_category("ENTERTAINMENT")
disallowed_category("LUXURY")
