# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — UoR Valuation Rules (P322, P330)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły wyceny wg Ustawy o Rachunkowości:
#   - P322: Rezerwy wg prawa polskiego — Art. 31 ust. 1 UoR
#   - P330: Koszt wytworzenia vs cena nabycia — Art. 28 ust. 1-3 UoR
#
# package: tax.uor_valuation
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.uor_valuation

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.uor_valuation.no_match",
    "package": "tax.uor_valuation",
    "priority": 399
}

# ═══════════════════════════════════════════════════════════════════════════════
# P322: uor_provisions_recognition (Priority 322)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Utworzenie rezerwy na pewne/prawdopodobne straty wg polskich
#   norm rachunkowości. Dotyczy firm NIE stosujących MSSF (IAS 37 → P121).
# Przesłanki: !uses_ifrs + has_certain_or_probable_loss
# Podstawa prawna: Art. 31 ust. 1 UoR

# ── P322: uor_provisions_recognition ──────────────────────────────────────────
# Cel biznesowy: Rezerwy wg polskiego GAAP (nie IAS 37)
# Przesłanki: !uses_ifrs + has_certain_or_probable_loss
# Podstawa prawna: Art. 31 ust. 1 UoR
# Priorytet: 322
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.uor_valuation.provisions_polish_gaap",
    "package": "tax.uor_valuation",
    "priority": 322,
    "vat_rate": "",
    "rounding_level": "",
    "provision_required": true,
    "provision_type": "UOR_ART_31",
    "income_tax_qualification": "deductible_partial",
    "_legal_basis": "Art. 31 ust. 1 UoR",
    "_warnings": ["Zawiąż rezerwę na straty wg Art. 31 UoR"]
} {
    input.company.uses_ifrs == false
    input.document.has_certain_or_probable_loss == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P330: uor_valuation_manufacturing_cost (Priority 330)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Ustalenie właściwej metody wyceny początkowej — koszt
#   wytworzenia (produkcja własna) vs cena nabycia (zakup).
#   Uzupełnienie P94 (FIFO) o metodę wyceny wejścia.
# Przesłanki: Środek trwały wyprodukowany wewnętrznie (nie zakupiony)
# Podstawa prawna: Art. 28 ust. 1, 2, 3 UoR

# ── P330: uor_valuation_manufacturing_cost ────────────────────────────────────
# Cel biznesowy: Wycena wg kosztu wytworzenia (produkcja własna)
# Przesłanki: produced_internally + purchase_cost == 0
# Podstawa prawna: Art. 28 ust. 1-3 UoR
# Priorytet: 330
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.uor_valuation.manufacturing_cost",
    "package": "tax.uor_valuation",
    "priority": 330,
    "vat_rate": "",
    "rounding_level": "",
    "valuation_base": "manufacturing_cost",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 28 ust. 1-3 UoR",
    "_warnings": ["Wycena wg kosztu wytworzenia — alokuj koszty pośrednie produkcji"]
} {
    input.asset.produced_internally == true
    input.asset.purchase_cost == 0
}
