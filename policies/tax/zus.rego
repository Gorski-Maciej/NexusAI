# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — ZUS Contribution Rules (P95-P99)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły składek ZUS:
#   - Mały ZUS+ (30% min. wynagrodzenia, 36 miesięcy)
#   - Ulga na start (6 miesięcy bez składek społecznych)
#   - Preferencyjny ZUS (30% min. wynagrodzenia, 24 miesiące)
#   - Składka zdrowotna (9% skala / 4.9% liniowy/ryczałt)
#   - Standardowe stawki ZUS
#
# package: tax.zus
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.zus

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.zus.no_match",
    "package": "tax.zus",
    "priority": 99
}

# ═══════════════════════════════════════════════════════════════════════════════
# P96: zus_start_relief (Priority 96)
# ═══════════════════════════════════════════════════════════════════════════════
# UWAGA: Najbardziej preferencyjna — na pierwszym miejscu w chainie

# ── P96: zus_start_relief ─────────────────────────────────────────────────────
# Cel biznesowy: Ulga na start — 6 mies. bez składek społecznych (tylko zdrowotna)
# Przesłanki: zus_status == START_RELIEF + months_used < 6
# Podstawa prawna: Art. 18a SUS
# Priorytet: 96
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.zus.start_relief",
    "package": "tax.zus",
    "priority": 96,
    "vat_rate": "",
    "rounding_level": "",
    "zus_social": "0.00",
    "zus_health_only": true,
    "zus_months_remaining": object.get(input.thresholds.bounds, "zus_start_months", 6) - input.company.zus_months_used,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 18a ustawy o SUS"
} {
    input.company.zus_status == "START_RELIEF"
    input.company.zus_months_used < object.get(input.thresholds.bounds, "zus_start_months", 6)
}

# ═══════════════════════════════════════════════════════════════════════════════
# P95: zus_maly_plus (Priority 95)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P95: zus_maly_plus ────────────────────────────────────────────────────────
# Cel biznesowy: Mały ZUS+ — obniżona podstawa przez 36 miesięcy
# Przesłanki: zus_status == MALY_ZUS_PLUS + months_used < 36
# Podstawa prawna: Art. 18c SUS
# Priorytet: 95
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.zus.maly_plus",
    "package": "tax.zus",
    "priority": 95,
    "vat_rate": "",
    "rounding_level": "",
    "zus_base_percent": object.get(input.thresholds.bounds, "zus_maly_plus_min_wage_percent", 0.30),
    "zus_months_remaining": object.get(input.thresholds.bounds, "zus_maly_plus_months", 36) - input.company.zus_months_used,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 18c ustawy o SUS"
} {
    input.company.zus_status == "MALY_ZUS_PLUS"
    input.company.zus_months_used < object.get(input.thresholds.bounds, "zus_maly_plus_months", 36)
}

# ═══════════════════════════════════════════════════════════════════════════════
# P97: zus_preferential (Priority 97)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P97: zus_preferential ─────────────────────────────────────────────────────
# Cel biznesowy: Preferencyjny ZUS — 30% min. wynagrodzenia przez 24 miesiące
# Przesłanki: zus_status == PREFERENTIAL + months_used < 24
# Podstawa prawna: Art. 18a SUS
# Priorytet: 97
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.zus.preferential",
    "package": "tax.zus",
    "priority": 97,
    "vat_rate": "",
    "rounding_level": "",
    "zus_base_percent": 0.30,
    "zus_months_remaining": 24 - input.company.zus_months_used,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 18a ustawy o SUS"
} {
    input.company.zus_status == "PREFERENTIAL"
    input.company.zus_months_used < 24
}

# ═══════════════════════════════════════════════════════════════════════════
# P99: zus_standard (Priority 99)
# ═══════════════════════════════════════════════════════════════════════════

# ── P99: zus_standard ─────────────────────────────────────────────────────
# Cel biznesowy: Standardowe stawki składek ZUS
# Przesłanki: zus_status == STANDARD
# Podstawa prawna: Art. 22 SUS
# Priorytet: 99
# ────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.zus.standard",
    "package": "tax.zus",
    "priority": 99,
    "vat_rate": "",
    "rounding_level": "",
    "zus_pension_rate": helpers.get_rate("zus_pension", "0.1952"),
    "zus_disability_rate": helpers.get_rate("zus_disability", "0.08"),
    "zus_sickness_rate": helpers.get_rate("zus_sickness", "0.0245"),
    "zus_accident_rate": helpers.get_rate("zus_accident", "0.0167"),
    "zus_labour_fund_rate": helpers.get_rate("zus_labour_fund", "0.0245"),
    "zus_fgsp_rate": helpers.get_rate("zus_fgsp", "0.001"),
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 22 ustawy o SUS"
} {
    input.company.zus_status == "STANDARD"
}

# ═══════════════════════════════════════════════════════════════════════════
# P98: zus_health_contrib (Priority 98 — FALLBACK po standard)
# ═══════════════════════════════════════════════════════════════════════════

# ── P98: zus_health_contrib ───────────────────────────────────────────────
# Cel biznesowy: Składka zdrowotna — 9% (skala) / 4.9% (liniowy/ryczałt)
# UWAGA: Na końcu chaina — fallback dla nieznanych statusów
# Podstawa prawna: Art. 79-81 ustawy zdrowotnej
# Priorytet: 98
# ────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.zus.health_contrib",
    "package": "tax.zus",
    "priority": 98,
    "vat_rate": "",
    "rounding_level": "",
    "zus_health_rate": health_rate,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach zdrowotnych"
} {
    health_rate := health_rate_for(input.company.tax_form)
}

# ── Helpers: stawka zdrowotna zależna od formy opodatkowania ─────────────────
health_rate_for("PIT_SCALE") = object.get(input.thresholds.rates, "zus_health", "0.09")

health_rate_for("LINEAR") = object.get(input.thresholds.rates, "zus_health_lump", "0.049")

health_rate_for("LUMP_SUM") = object.get(input.thresholds.rates, "zus_health_lump", "0.049")

# Fallback dla pozostałych form (CIT_STANDARD, CIT_ESTONIAN)
health_rate_for(tax_form) = object.get(input.thresholds.rates, "zus_health", "0.09") {
    tax_form != "PIT_SCALE"
    tax_form != "LINEAR"
    tax_form != "LUMP_SUM"
}
