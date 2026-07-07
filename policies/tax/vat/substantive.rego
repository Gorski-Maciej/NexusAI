# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Substantive VAT Rules (P50-P69)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Merytoryczne reguły VAT: stawki wg kategorii, zwolnienia przedmiotowe
# i podmiotowe, ulga na złe długi, procedura marży.
#
# Wzorzec: VAT rates jako look-up tables, kategorie → stawka.
#
# package: tax.vat.substantive
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.vat.substantive

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.vat.substantive.no_match",
    "package": "tax.vat.substantive",
    "priority": 69
}

# ═══════════════════════════════════════════════════════════════════════════════
# P50: vat_margin_scheme (Priority 50)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Procedura VAT-marża dla towarów używanych, dzieł sztuki, antyków
# Przesłanki: procedure == MARGIN
# Podstawa prawna: Art. 120 ustawy o VAT

# ── P50: vat_margin_scheme ────────────────────────────────────────────────────
# Cel biznesowy: Procedura marży → VAT naliczany od marży, nie od całości
# Przesłanki: procedure == MARGIN
# Podstawa prawna: Art. 120 VAT
# Priorytet: 50
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.vat.substantive.margin_scheme",
    "package": "tax.vat.substantive",
    "priority": 50,
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 120 VAT",
    "_warnings": ["Procedura VAT-marża — podstawa od marży, nie od całości"]
} {
    input.invoice.procedure == "MARGIN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P52-P54: VAT rates by category (PL only)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P52: fuel_pl ──────────────────────────────────────────────────────────────
# Cel biznesowy: Paliwo w PL → 23% VAT + GTU_04
# Podstawa prawna: Art. 41 ust. 1 VAT, § 10 rozp. JPK_VAT
# Priorytet: 52
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.fuel_pl",
    "package": "tax.vat.substantive",
    "priority": 52,
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "rounding_level": "position",
    "gtu_code": "GTU_04",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 1 VAT"
} {
    input.invoice.category_code == "FUEL"
    input.vendor.country == "PL"
}

# ── P53: food_pl ──────────────────────────────────────────────────────────────
# Cel biznesowy: Żywność w PL → 5% VAT (stawka obniżona)
# Podstawa prawna: Art. 41 ust. 2a VAT, rozp. MF
# Priorytet: 53
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.food_pl",
    "package": "tax.vat.substantive",
    "priority": 53,
    "vat_rate": helpers.get_rate("vat_reduced_5", "0.05"),
    "rounding_level": "position",
    "gtu_code": "GTU_07",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 2a VAT"
} {
    input.invoice.category_code == "FOOD"
    input.vendor.country == "PL"
}

# ── P54: books_pl ─────────────────────────────────────────────────────────────
# Cel biznesowy: Książki i publikacje → 5% VAT
# Podstawa prawna: Art. 41 ust. 2a VAT
# Priorytet: 54
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.books_pl",
    "package": "tax.vat.substantive",
    "priority": 54,
    "vat_rate": helpers.get_rate("vat_reduced_5", "0.05"),
    "rounding_level": "position",
    "gtu_code": "GTU_01",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 2a VAT"
} {
    input.invoice.category_code == "BOOKS"
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P55-P57: VAT exemptions (zwolnienia przedmiotowe)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P55: education_exempt ─────────────────────────────────────────────────────
# Cel biznesowy: Usługi edukacyjne → zwolnione z VAT
# Podstawa prawna: Art. 43 ust. 1 pkt 26-29 VAT
# Priorytet: 55
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.education_exempt",
    "package": "tax.vat.substantive",
    "priority": 55,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 43 ust. 1 pkt 26-29 VAT",
    "_warnings": ["Usługa edukacyjna zwolniona z VAT"]
} {
    input.invoice.category_code == "EDUCATION"
    input.vendor.country == "PL"
}

# ── P56: healthcare_exempt ────────────────────────────────────────────────────
# Cel biznesowy: Usługi medyczne → zwolnione z VAT
# Podstawa prawna: Art. 43 ust. 1 pkt 18-20 VAT
# Priorytet: 56
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.healthcare_exempt",
    "package": "tax.vat.substantive",
    "priority": 56,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 43 ust. 1 pkt 18-20 VAT",
    "_warnings": ["Usługa medyczna zwolniona z VAT"]
} {
    input.invoice.category_code == "HEALTHCARE"
    input.vendor.country == "PL"
}

# ── P57: finance_insurance_exempt ─────────────────────────────────────────────
# Cel biznesowy: Usługi finansowe i ubezpieczeniowe → zwolnione z VAT
# Podstawa prawna: Art. 43 ust. 1 pkt 7, 37-41 VAT
# Priorytet: 57
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.finance_exempt",
    "package": "tax.vat.substantive",
    "priority": 57,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 43 ust. 1 pkt 7, 37-41 VAT",
    "_warnings": ["Usługa finansowa/ubezpieczeniowa zwolniona z VAT"]
} {
    is_financial_category(input.invoice.category_code)
}

# ── P58: subject_exemption ────────────────────────────────────────────────────
# Cel biznesowy: Zwolnienie podmiotowe VAT (obrót < 200 000 PLN)
# Podstawa prawna: Art. 113 ust. 1 VAT
# Priorytet: 58
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.subject_exemption",
    "package": "tax.vat.substantive",
    "priority": 58,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "vat_exemption": "SUBJECT",
    "_legal_basis": "Art. 113 ust. 1 VAT",
    "_warnings": ["Zwolnienie podmiotowe VAT — limit 200 000 PLN"]
} {
    input.company.is_vat_payer == false
    input.vendor.country == "PL"
}

# ── P60: bad_debt_relief ──────────────────────────────────────────────────────
# Cel biznesowy: Ulga na złe długi — możliwość korekty VAT po 150 dniach
# Podstawa prawna: Art. 89a VAT
# Priorytet: 60
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.vat.substantive.bad_debt_relief",
    "package": "tax.vat.substantive",
    "priority": 60,
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "bad_debt_relief_eligible": true,
    "_legal_basis": "Art. 89a VAT",
    "_warnings": ["Faktura nieopłacona >150 dni — ulga na złe długi"]
} {
    input.invoice.is_paid == false
    input.invoice.days_overdue >= object.get(input.thresholds.limits, "bad_debt_days", 150)
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Category Helpers (zamiast array in — OPA < v0.34 compatibility)
# ═══════════════════════════════════════════════════════════════════════════════

is_financial_category("FINANCE")
is_financial_category("INSURANCE")
is_financial_category("BANKING")
