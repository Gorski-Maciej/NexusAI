# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — VAT Registration (P324)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły rejestracji VAT:
#   - P324: Obowiązkowa rejestracja VAT-R — Art. 15, Art. 96 VAT
#
# package: tax.vat_registration
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.vat_registration

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.vat_registration.no_match",
    "package": "tax.vat_registration",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P324: vat_registration_vat_r_mandatory (Priority 324)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Alert przy pierwszej sprzedaży przez podmiot niezarejestrowany
#   jako czynny podatnik VAT. P58 (zwolnienie podmiotowe) i P296 (VAT-UE)
#   nie pokrywają podstawowego obowiązku VAT-R.
# Przesłanki: Firma bez rejestracji VAT + faktura podlega VAT
# Podstawa prawna: Art. 15 i Art. 96 VAT

# ── P324: vat_registration_vat_r_mandatory ────────────────────────────────────
# Cel biznesowy: Blokada faktury dla podmiotu niezarejestrowanego jako VAT
# Przesłanki: vat_status == unregistered + vat_taxable == true
# Podstawa prawna: Art. 15, Art. 96 VAT
# Priorytet: 324
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.vat_registration.vat_r_mandatory",
    "package": "tax.vat_registration",
    "priority": 324,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Podmiot niezarejestrowany jako podatnik VAT — wymagany VAT-R",
    "_legal_basis": "Art. 15, Art. 96 VAT",
    "_warnings": ["Złóż VAT-R przed wystawieniem pierwszej faktury"]
} {
    input.company.vat_status == "unregistered"
    input.invoice.vat_taxable == true
}
