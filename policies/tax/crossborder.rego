# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Cross-Border Rules (P40-P49)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły transakcji transgranicznych: EU reverse charge, import spoza UE,
# eksport towarów. Priorytet po compliance, przed merytorycznymi VAT.
#
# Wzorzec: FINOS OpenEAGO — Jurisdiction-Aware Tax Rules.
#
# package: tax.crossborder
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.crossborder

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.crossborder.no_match",
    "package": "tax.crossborder",
    "priority": 49
}

# ═══════════════════════════════════════════════════════════════════════════════
# P40: eu_reverse_charge (Priority 40)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Wewnątrzwspólnotowe nabycie towarów — reverse charge
# Przesłanki: vendor.country == EU, vendor.vat_status == active
# Podstawa prawna: Art. 17 ust. 1 pkt 3 VAT

# ── P40: eu_reverse_charge ────────────────────────────────────────────────────
# Cel biznesowy: Nabycie towarów z UE → reverse charge (0% VAT na fakturze,
#   podatek rozlicza nabywca w JPK_V7)
# Przesłanki: vendor.country == EU AND vendor.vat_status == active
# Podstawa prawna: Art. 17 ust. 1 pkt 3 VAT
# Priorytet: 40
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.crossborder.eu_reverse_charge",
    "package": "tax.crossborder",
    "priority": 40,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "GTU_12",
    "procedure": "VAT_REVERSE_CHARGE",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 17 ust. 1 pkt 3 VAT",
    "_warnings": ["Reverse charge — podatek rozlicza nabywca"]
} {
    input.vendor.country == "EU"
    input.vendor.vat_status == "active"
    input.invoice.transaction_date >= "2024-01-01"
}

else := {
    "matched": true,
    "rule_id": "tax.crossborder.eu_reverse_charge_wdt",
    "package": "tax.crossborder",
    "priority": 42,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "WDT",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 42 VAT",
    "_warnings": ["WDT — dostawa wewnątrzwspólnotowa (0% VAT)"]
} {
    input.invoice.procedure == "WDT"
    input.vendor.country == "EU"
    input.vendor.vat_status == "active"
    input.invoice.transaction_date >= "2024-01-01"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P45: import_non_eu (Priority 45)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Import towarów spoza UE — standardowa stawka VAT + procedura IMPORT
# Przesłanki: vendor.country == NON_EU (i nie jest to EXPORT)
# Podstawa prawna: Art. 17 ust. 1 pkt 1 VAT

# ── P45: import_non_eu ────────────────────────────────────────────────────────
# Cel biznesowy: Import towarów spoza UE → 23% VAT + procedura IMPORT
# Przesłanki: vendor.country == NON_EU AND procedure != EXPORT
# Podstawa prawna: Art. 17 ust. 1 pkt 1 VAT
# Priorytet: 45
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.crossborder.import_non_eu",
    "package": "tax.crossborder",
    "priority": 45,
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "rounding_level": "position",
    "gtu_code": "GTU_13",
    "procedure": "IMPORT",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 17 ust. 1 pkt 1 VAT",
    "_warnings": ["Import spoza UE — procedura celna wymagana"]
} {
    input.vendor.country == "NON_EU"
    input.invoice.procedure != "EXPORT"
    input.invoice.transaction_date >= "2024-01-01"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P48: export_goods (Priority 48)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Eksport towarów poza UE — stawka 0% VAT
# Przesłanki: vendor.country == NON_EU AND procedure == EXPORT
# Podstawa prawna: Art. 41 ust. 4-11 VAT

# ── P48: export_goods ─────────────────────────────────────────────────────────
# Cel biznesowy: Eksport towarów poza UE → 0% VAT
# Przesłanki: vendor.country == NON_EU AND procedure == EXPORT
# Podstawa prawna: Art. 41 ust. 4-11 ustawy o VAT
# Priorytet: 48
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.crossborder.export_goods",
    "package": "tax.crossborder",
    "priority": 48,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "EXPORT",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 4-11 ustawy o VAT",
    "_warnings": ["Eksport towarów — wymagane potwierdzenie wywozu (IE-599)"]
} {
    input.vendor.country == "NON_EU"
    input.invoice.procedure == "EXPORT"
    input.invoice.transaction_date >= "2024-01-01"
}
