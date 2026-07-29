# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: 4 formy opodatkowania (P500-P539)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: PIT Forms — 4 Tax Regimes: Scale, Linear, Lump Sum, Tax Card
# description: |
#   PAS 5a Multi-Pass. First-Match-Wins else-chain. 4 formy opodatkowania JDG:
#   skala 12/32% (P500), wspólne rozliczenie (P502), liniowy 19% (P510),
#   blokada byłego pracodawcy → skala (P512), ryczałt (P520),
#   limit 2M EUR → skala (P523), karta podatkowa (P530).
# architecture: Multi-Pass PAS 5a (ADR-001), używa data.thresholds
# legal_basis: Art. 27, 30c PIT, ustawa o ryczałcie
# edge_cases:
#   - P512: former_employer_services → automatycznie SCALE zamiast LINEAR
#   - P523: helpers.jdg_amount_eur > 2M → BLOCK_AND_ALERT
#   - P530: karta podatkowa nie ma zeznania rocznego
# package: jdg.pit.forms
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.6 + Doc 33 (Art. 27, 30c PIT + ryczałt + karta)
#
# package: jdg.pit.forms
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.forms

import data.jdg.helpers
import data.jdg.thresholds

# ── Default ────────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.pit.forms.no_match",
    "package": "jdg.pit.forms",
    "priority": 549
}

# ═══════════════════════════════════════════════════════════════════════════════
# P500: pit_form_scale — Skala podatkowa 12%/32% (domyślna)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.forms.scale",
    "package": "jdg.pit.forms", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": pit_rate, "pit_bracket": pit_bracket,
    "pit_annual_return_type": "PIT-36",
    "pit_tax_free_amount": thresholds.limits.pit_tax_free_amount, "pit_tax_free_reduction": floor(thresholds.limits.pit_tax_free_amount * thresholds.rates.pit_scale_low),
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_joint_filing": false, "relief_type": "",
    "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 1 PIT",
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    accumulated := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    bracket_limit := object.get(object.get(data.thresholds, "jdg", {}), "bounds", {})
    threshold := object.get(bracket_limit, "pit_scale_threshold", 120000)

    pit_bracket = "LOW" { accumulated <= threshold }
    pit_rate = sprintf("%.2f", [thresholds.rates.pit_scale_low]) { accumulated <= threshold }
    pit_bracket = "HIGH" { accumulated > threshold }
    pit_rate = sprintf("%.2f", [thresholds.rates.pit_scale_high]) { accumulated > threshold }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P502: pit_scale_joint_filing — Wspólne rozliczenie małżonków
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.scale_joint_filing",
    "package": "jdg.pit.forms", "priority": 502,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "pit_tax_free_amount": thresholds.limits.pit_tax_free_amount, "pit_tax_free_reduction": floor(thresholds.limits.pit_tax_free_amount * thresholds.rates.pit_scale_low),
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_joint_filing": true,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 2 PIT",
    "_warnings": ["Wspólne rozliczenie małżonków — efektywny próg 240 000 PLN"]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.jdg_entrepreneur.joint_filing == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P510: pit_form_linear — Podatek liniowy 19%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.linear",
    "package": "jdg.pit.forms", "priority": 510,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_linear]), "pit_bracket": "",
    "pit_annual_return_type": "PIT-36L",
    "pit_tax_free_amount": 0, "pit_tax_free_reduction": 0,
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_deductible_from_income": true, "zus_health_annual_limit": thresholds.zus.health_linear_deduction_limit,
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30c PIT",
    "_warnings": ["Podatek liniowy 19% — BRAK kwoty wolnej, BRAK wspólnego rozliczenia"]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P512: linear_former_employer_restriction — Blokada liniowego dla byłego pracodawcy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.linear_former_employer_block",
    "package": "jdg.pit.forms", "priority": 512,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Usługi dla byłego pracodawcy — podatek liniowy NIEDOZWOLONY",
    "_legal_basis": "Art. 30c ust. 2 PIT",
    "_warnings": ["Usługi dla byłego pracodawcy — NIE możesz używać podatku liniowego! Automatycznie: skala 12%."]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.jdg_entrepreneur.former_employer_services == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P520: pit_form_lump_sum — Ryczałt ewidencjonowany
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum",
    "package": "jdg.pit.forms", "priority": 520,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": lump_sum_rate, "pit_bracket": "",
    "pit_annual_return_type": "PIT-28", "pit_annual_return_deadline": "02-28",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_limit_type": "LUMP_SUM_TIER",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 12 ustawy o ryczałcie ewidencjonowanym",
    "_warnings": ["Ryczałt ewidencjonowany — podatek od przychodu (NIE dochodu!). PIT-28 do 28 lutego!"]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    pkwiu := object.get(input.invoice, "pkwiu_code", "")
    lump_sum_rate := lump_sum_rate_by_pkwiu(pkwiu)
}

# ── Lump sum rate determination by PKWiU ──────────────────────────────────────
lump_sum_rate_by_pkwiu(pkwiu) = rate {
    rate := object.get(lump_sum_rates_map, pkwiu_2digit(pkwiu), "0.085")
}

pkwiu_2digit(pkwiu) = code {
    parts := split(pkwiu, ".")
    code := parts[0]
}

lump_sum_rates_map := {
    "01": "0.02", "02": "0.02", "03": "0.02",
    "41": "0.055", "42": "0.055", "43": "0.055",
    "64": "0.055", "65": "0.055", "66": "0.055",
    "62": "0.12", "63": "0.12",
    "58": "0.085", "59": "0.085", "60": "0.085", "61": "0.085",
    "68": "0.15", "69": "0.17", "70": "0.17", "71": "0.17",
    "72": "0.085", "73": "0.17", "74": "0.17", "75": "0.17",
    "77": "0.17", "78": "0.17", "79": "0.17", "80": "0.17", "81": "0.17", "82": "0.17",
    "10": "0.03", "11": "0.03", "12": "0.03", "13": "0.03", "14": "0.03", "15": "0.03",
    "16": "0.03", "17": "0.03", "18": "0.03", "19": "0.03", "20": "0.03", "21": "0.03",
    "22": "0.03", "23": "0.03", "24": "0.03", "25": "0.03", "26": "0.03", "27": "0.03",
    "28": "0.03", "29": "0.03", "30": "0.03", "31": "0.03", "32": "0.03", "33": "0.03",
    "56": "0.03"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P523: lump_sum_annual_limit — Limit 2M EUR dla ryczałtu
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum_limit_exceeded",
    "package": "jdg.pit.forms", "priority": 523,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczony limit ryczałtu — obowiązek przejścia na skalę",
    "_legal_basis": "Art. 6 ust. 4 ustawy o ryczałcie",
    "_warnings": ["Przekroczony limit 2M EUR dla ryczałtu — OBOWIĄZKOWA zmiana na skalę podatkową!"]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    helpers.jdg_amount_eur > 2000000
}

# ═══════════════════════════════════════════════════════════════════════════════
# P530: pit_form_tax_card — Karta podatkowa
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.tax_card",
    "package": "jdg.pit.forms", "priority": 530,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "TAX_CARD", "pit_rate": "", "pit_bracket": "",
    "pit_monthly_amount": monthly_rate,
    "pit_annual_return_type": "", "pit_advance_due_day": 7,
    "kus_qualification": "none", "kus_percent": 0,
    "requires_pkpir": false, "requires_lump_sum_evidence": false,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21-30 ustawy o ryczałcie (rozdział 3)",
    "_warnings": ["Karta podatkowa — stała kwota podatku z decyzji US. Brak zeznania rocznego!"]
} {
    input.jdg_entrepreneur.tax_form == "TAX_CARD"
    monthly_rate := object.get(input.jdg_entrepreneur, "tax_card_monthly_rate", 0)
}
