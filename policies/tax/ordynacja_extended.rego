# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Ordynacja Podatkowa Extended (P325, P329)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły proceduralne Ordynacji Podatkowej:
#   - P325: Zabezpieczenie wykonania zobowiązania — Art. 33, 36 Ordynacji
#   - P329: Ulga w spłacie / odroczenie — Art. 54, 67a-69 Ordynacji
#
# package: tax.ordynacja_extended
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.ordynacja_extended

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.ordynacja_extended.no_match",
    "package": "tax.ordynacja_extended",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P325: ord_tax_securing_deadline (Priority 325)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Obsługa decyzji o zabezpieczeniu wykonania zobowiązania
#   przez US — wymagany natychmiastowy depozyt.
# Przesłanki: Decyzja US o zabezpieczeniu + odwołanie bez wstrzymania wykonania
# Podstawa prawna: Art. 33, Art. 36 Ordynacji Podatkowej

# ── P325: ord_tax_securing_deadline ───────────────────────────────────────────
# Cel biznesowy: Zabezpieczenie wykonania zobowiązania podatkowego
# Przesłanki: us_securing_decision + appealed_without_stay
# Podstawa prawna: Art. 33, Art. 36 Ordynacji podatkowej
# Priorytet: 325
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.ordynacja_extended.securing_deadline",
    "package": "tax.ordynacja_extended",
    "priority": 325,
    "vat_rate": "",
    "rounding_level": "",
    "tax_securing_required": true,
    "requires_immediate_deposit": true,
    "income_tax_qualification": "",
    "_legal_basis": "Art. 33, Art. 36 Ordynacji podatkowej",
    "_warnings": ["Decyzja o zabezpieczeniu — wymagany natychmiastowy depozyt"]
} {
    input.document.type == "us_securing_decision"
    input.document.is_appealed_without_stay == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P329: ord_payment_relief_deferral (Priority 329)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Automatyczne zastosowanie opłaty prolongacyjnej zamiast
#   odsetek za zwłokę przy odroczeniu/rozłożeniu na raty.
# Przesłanki: Aktywna decyzja o odroczeniu/ratach + dokument płatności
# Podstawa prawna: Art. 54, Art. 67a-69 Ordynacji Podatkowej

# ── P329: ord_payment_relief_deferral ─────────────────────────────────────────
# Cel biznesowy: Opłata prolongacyjna zamiast odsetek za zwłokę
# Przesłanki: has_active_deferral_decision + document.type == tax_payment
# Podstawa prawna: Art. 54, Art. 67a-69 Ordynacji podatkowej
# Priorytet: 329
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.ordynacja_extended.payment_relief",
    "package": "tax.ordynacja_extended",
    "priority": 329,
    "vat_rate": "",
    "rounding_level": "",
    "apply_prolongation_fee": true,
    "prolongation_rate": object.get(input.thresholds.rates, "prolongation_fee", "0.50"),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 54, Art. 67a-69 Ordynacji podatkowej"
} {
    input.company.has_active_deferral_decision == true
    input.document.type == "tax_payment"
}
