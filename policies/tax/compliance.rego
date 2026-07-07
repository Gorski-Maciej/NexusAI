# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Compliance Rules (P20-P39)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły zgodności dokumentacyjnej i prawnej:
#   - Biała Lista MF (Art. 96b VAT, Art. 117ba Ordynacji podatkowej)
#   - Split Payment / MPP (Art. 108a VAT)
#   - Limit płatności gotówkowych (Art. 22p PIT, Art. 15d CIT)
#
# Wzorzec: FINOS OpenEAGO — Jurisdiction-Aware Compliance Controls.
#
# package: tax.compliance
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.compliance

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.compliance.no_match",
    "package": "tax.compliance",
    "priority": 39
}

# ═══════════════════════════════════════════════════════════════════════════════
# P20: whitelist_missing_over_limit (Priority 20)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Weryfikacja Białej Listy MF — blokada gdy kontrahent nie figuruje
#   na WL dla przelewów >15 000 PLN.
# Przesłanki: amount_gross >= mpp_limit AND vendor.on_whitelist == false
# Podstawa prawna: Art. 96b VAT, Art. 117ba Ordynacji podatkowej

# ── P20: whitelist_missing_over_limit ─────────────────────────────────────────
# Cel biznesowy: Brak kontrahenta na Białej Liście MF >15k PLN → BLOCK_AND_ALERT
# Przesłanki: amount_gross >= mpp_limit AND !on_whitelist
# Podstawa prawna: Art. 96b VAT, Art. 117ba Ordynacji podatkowej
# Priorytet: 20
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.compliance.whitelist_missing",
    "package": "tax.compliance",
    "priority": 20,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "deductible_full",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak kontrahenta na Białej Liście MF dla przelewu >15 000 PLN",
    "_legal_basis": "Art. 96b VAT, Art. 117ba Ordynacji podatkowej",
    "_warnings": ["Brak na Białej Liście — odpowiedzialność solidarna"]
} {
    input.invoice.amount_gross >= object.get(input.thresholds.limits, "mpp_limit", 15000)
    input.vendor.on_whitelist == false
    input.invoice.transaction_date >= "2024-01-01"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P25: split_payment_mandatory (Priority 25)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Obowiązkowy MPP dla faktur >15k PLN brutto,
#   gdy towary/usługi z załącznika nr 15 do ustawy o VAT.
# Przesłanki: amount_gross >= mpp_limit AND category_code w MPP-sensitive
# Podstawa prawna: Art. 108a VAT

# ── P25: split_payment_mandatory ──────────────────────────────────────────────
# Cel biznesowy: Obowiązkowy MPP dla towarów wrażliwych >15k PLN
# Przesłanki: amount_gross >= mpp_limit AND category in MPP list
# Podstawa prawna: Art. 108a ustawy o VAT
# Priorytet: 25
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.compliance.split_payment_mandatory",
    "package": "tax.compliance",
    "priority": 25,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "deductible_full",
    "mpp_required": true,
    "_legal_basis": "Art. 108a ustawy o VAT",
    "_warnings": ["Obowiązkowy mechanizm podzielonej płatności (MPP) — załącznik nr 15"]
} {
    input.invoice.amount_gross >= object.get(input.thresholds.limits, "mpp_limit", 15000)
    helpers.is_mpp_sensitive(input.invoice.category_code)
    input.vendor.country == "PL"
    input.invoice.transaction_date >= "2024-01-01"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P35: cash_transaction_over_limit (Priority 35)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Płatność gotówkowa >15k PLN → brak możliwości zaliczenia do KUP
# Przesłanki: is_cash_payment == true AND amount_gross >= cash_transaction_limit
# Podstawa prawna: Art. 22p PIT, Art. 15d CIT

# ── P35: cash_transaction_over_limit ──────────────────────────────────────────
# Cel biznesowy: Płatność gotówkowa > limit → brak KUP
# Przesłanki: is_cash_payment == true AND amount_gross >= cash_limit
# Podstawa prawna: Art. 22p PIT, Art. 15d CIT
# Priorytet: 35
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.compliance.cash_over_limit",
    "package": "tax.compliance",
    "priority": 35,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "non_deductible",
    "_legal_basis": "Art. 22p PIT, Art. 15d CIT",
    "_warnings": ["Płatność gotówkowa powyżej limitu 15 000 PLN — brak KUP"]
} {
    input.invoice.is_cash_payment == true
    input.invoice.amount_gross >= object.get(input.thresholds.limits, "cash_transaction_limit", 15000)
    input.invoice.transaction_date >= "2024-01-01"
}
