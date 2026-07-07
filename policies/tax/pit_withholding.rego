# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — PIT Withholding (P331)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły poboru PIT przez płatnika:
#   - P331: Małe umowy zlecenia/o dzieło ≤200 PLN — ryczałt 12% — Art. 30 PIT
#
# package: tax.pit_withholding
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.pit_withholding

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.pit_withholding.no_match",
    "package": "tax.pit_withholding",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P331: pit_small_mandate_flat_rate (Priority 331)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Pobór zryczałtowanego podatku 12% dla drobnych umów zleceń
#   /o dzieło ≤200 PLN. Nie stosuje się KUP wykonawcy (20%/50%),
#   podatek płatny przez zleceniodawcę.
# Przesłanki: Umowa zlecenia/dzieło ≤200 PLN z osobą niebędącą pracownikiem
# Podstawa prawna: Art. 30 ust. 1 pkt 5a PIT

# ── P331: pit_small_mandate_flat_rate ─────────────────────────────────────────
# Cel biznesowy: Mała umowa zlecenia ≤200 PLN — ryczałt 12%, bez KUP wykonawcy
# Przesłanki: contract_of_mandate + amount ≤ small_mandate_limit + !employee
# Podstawa prawna: Art. 30 ust. 1 pkt 5a PIT
# Priorytet: 331
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.pit_withholding.small_mandate",
    "package": "tax.pit_withholding",
    "priority": 331,
    "vat_rate": "",
    "rounding_level": "",
    "pit_rate": "0.12",
    "pit_withholding_type": "LUMP_SUM",
    "apply_contractor_kup": false,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 30 ust. 1 pkt 5a PIT",
    "_warnings": ["Mała umowa zlecenia ≤200 PLN — ryczałt 12%, bez KUP wykonawcy"]
} {
    input.document.type == "contract_of_mandate"
    input.invoice.amount_gross <= object.get(input.thresholds.limits, "small_mandate_limit", 200)
    input.invoice.contractor_is_employee == false
}
