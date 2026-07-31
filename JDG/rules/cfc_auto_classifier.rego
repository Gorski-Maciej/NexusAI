# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CFC AUTO-CLASSIFIER (P13 Priority 2)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.cfc_auto_classifier
# Report:      RAPORT_P13 Section 7 — Priority 2
# Purpose:     Automatic classification of passive income types for CFC
#              Eliminates manual classification errors
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cfc_auto_classifier

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.cfc_auto_classifier.no_match",
    "package": "jdg.cfc_auto_classifier",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# CAC-001: CFC PASSIVE INCOME AUTO-CLASSIFIER
# Automatycznie klasyfikuje wszystkie źródła dochodów pasywnych CFC
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "has_cfc", false) == true

    cfc_country := object.get(input.jdg_entrepreneur, "cfc_country", "N/A")
    cfc_total_income := object.get(input.jdg_entrepreneur, "cfc_total_income_pln", 0)
    ownership_pct := object.get(input.jdg_entrepreneur, "cfc_ownership_pct", 0)

    # Auto-classify income sources from available data
    income_buckets := {
        "INTEREST": object.get(input.jdg_entrepreneur, "cfc_interest_income", 0),
        "ROYALTIES": object.get(input.jdg_entrepreneur, "cfc_royalties_income", 0),
        "DIVIDENDS": object.get(input.jdg_entrepreneur, "cfc_dividends_income", 0),
        "RENTAL": object.get(input.jdg_entrepreneur, "cfc_rental_income", 0),
        "CAPITAL_GAINS": object.get(input.jdg_entrepreneur, "cfc_capital_gains", 0),
        "FINANCIAL_ASSET_SALES": object.get(input.jdg_entrepreneur, "cfc_financial_asset_sales", 0),
        "INTANGIBLE_LICENSING": object.get(input.jdg_entrepreneur, "cfc_intangible_licensing", 0),
        "FRANCHISE_FEES": object.get(input.jdg_entrepreneur, "cfc_franchise_fees", 0),
        "LEASING": object.get(input.jdg_entrepreneur, "cfc_leasing_income", 0),
        "FACTORING": object.get(input.jdg_entrepreneur, "cfc_factoring_income", 0)
    }

    passive_types := {"INTEREST", "ROYALTIES", "DIVIDENDS", "RENTAL", "CAPITAL_GAINS", "FINANCIAL_ASSET_SALES", "INTANGIBLE_LICENSING", "FRANCHISE_FEES", "LEASING", "FACTORING"}

    passive_income := sum([v | income_buckets[k] = v; k in passive_types])
    active_income := cfc_total_income - passive_income
    passive_pct := floor(passive_income / cfc_total_income * 10000) / 100 { cfc_total_income > 0 }
    passive_pct := 0 { cfc_total_income <= 0 }

    passive_threshold_pct := 33.0
    passive_threshold_exceeded := passive_pct > passive_threshold_pct

    # Find dominant passive income type
    all_income := [{"type": k, "amount": v} | income_buckets[k] = v; v > 0]
    dominant_type := [item.type | item := all_income[_]; item.amount == max([x.amount | x := all_income[_]])]

    # Risk scoring
    risk_score := 0
    risk_score := risk_score + 25 { passive_threshold_exceeded }
    risk_score := risk_score + 20 { ownership_pct > 0.75 }
    risk_score := risk_score + 15 { cfc_country in {"BM","KY","GG","JE","IM","MH","PA","VG","TC","AE","HK","SG","CH","LI"} }
    risk_score := risk_score + 10 { object.get(income_buckets, "ROYALTIES", 0) / cfc_total_income > 0.50 }
    risk_score := risk_score + 10 { object.get(income_buckets, "INTANGIBLE_LICENSING", 0) > 0 }

    risk_level := "LOW" { risk_score < 30 }
    risk_level := "MEDIUM" { risk_score >= 30; risk_score < 60 }
    risk_level := "HIGH" { risk_score >= 60; risk_score < 80 }
    risk_level := "CRITICAL" { risk_score >= 80 }

    pit_cfc_due := "30 września następnego roku"
    tax_rate := 0.19
    cfc_income_attributed := floor(cfc_total_income * ownership_pct * 100) / 100 { ownership_pct > 0.50 }
    cfc_income_attributed := 0 { ownership_pct <= 0.50 }
    cfc_tax_due := floor(cfc_income_attributed * tax_rate * 100) / 100

    routing := "BLOCK_AND_ALERT" { risk_level == "CRITICAL" and passive_threshold_exceeded }
    routing := "TRIAGE_QUEUE" { risk_level == "HIGH" and passive_threshold_exceeded }
    routing := "WARNING" { passive_threshold_exceeded }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.cfc_auto_classifier.passive_classifier",
        "package": "jdg.cfc_auto_classifier",
        "priority": 18301,
        "cac_cfc_country": cfc_country,
        "cac_total_income": cfc_total_income,
        "cac_passive_income": passive_income,
        "cac_active_income": active_income,
        "cac_passive_pct": passive_pct,
        "cac_passive_threshold_exceeded": passive_threshold_exceeded,
        "cac_dominant_passive_type": dominant_type,
        "cac_income_buckets": income_buckets,
        "cac_ownership_pct": ownership_pct,
        "cac_cfc_income_attributed": cfc_income_attributed,
        "cac_cfc_tax_due": cfc_tax_due,
        "cac_risk_score": risk_score,
        "cac_risk_level": risk_level,
        "cac_pit_cfc_due": pit_cfc_due,
        "_routing": routing,
        "_routing_reason": sprintf("CFC Classifier: %.1f%% passive (%s dominant) — Risk: %s (%d/100). Tax: %.0f PLN", [passive_pct, dominant_type, risk_level, risk_score, cfc_tax_due]),
        "_legal_basis": "Art. 30f PIT — CFC; Art. 45 ust. 1aa PIT (PIT-CFC)",
        "_description": "CAC-001: CFC Passive Income Auto-Classifier with 10 income buckets and risk scoring"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CAC-002: CFC DE MINIMIS CHECK
# Sprawdza wyłączenie de minimis 250 000 EUR × 4.5 (art. 30f ust. 2 PIT)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "has_cfc", false) == true

    ownership_pct := object.get(input.jdg_entrepreneur, "cfc_ownership_pct", 0)
    cfc_revenue_eur := object.get(input.jdg_entrepreneur, "cfc_revenue_eur", 0)

    de_minimis_threshold_eur := 250000
    ownership_scale := 4.5  # multiplier for proportional ownership
    de_minimis_limit_eur := de_minimis_threshold_eur * ownership_scale / 100

    # Proportional revenue attributed to JDG
    attributed_revenue_eur := floor(cfc_revenue_eur * ownership_pct * 100) / 100

    de_minimis_applies := attributed_revenue_eur <= de_minimis_limit_eur and ownership_pct > 0.50

    cac_note := "De minimis exemption: CFC revenue < 250k EUR × ownership scale (4.5)" { de_minimis_applies }
    cac_note := "De minimis NOT applicable — CFC reporting required" { not de_minimis_applies }

    verdict := {
        "matched": true,
        "rule_id": "jdg.cfc_auto_classifier.de_minimis_check",
        "package": "jdg.cfc_auto_classifier",
        "priority": 18302,
        "cac_cfc_revenue_eur": cfc_revenue_eur,
        "cac_attributed_revenue_eur": attributed_revenue_eur,
        "cac_de_minimis_threshold_eur": de_minimis_threshold_eur,
        "cac_de_minimis_limit_with_scale": de_minimis_limit_eur,
        "cac_de_minimis_applies": de_minimis_applies,
        "cac_note": cac_note,
        "_routing": "",
        "_routing_reason": sprintf("CFC De Minimis: %.0f EUR attributed vs %.0f EUR threshold — %s", [attributed_revenue_eur, de_minimis_limit_eur, "EXEMPT" { de_minimis_applies } else "NOT EXEMPT"]),
        "_legal_basis": "Art. 30f ust. 2 PIT",
        "_description": "CAC-002: CFC De Minimis check — 250k EUR threshold with ownership scaling"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CAC-003: CFC TAX HAVEN / LOW-TAX JURISDICTION CHECK
# Sprawdza czy jurysdykcja CFC jest rajem podatkowym lub low-tax
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "has_cfc", false) == true

    cfc_country := object.get(input.jdg_entrepreneur, "cfc_country", "N/A")
    foreign_tax_rate := object.get(input.jdg_entrepreneur, "cfc_foreign_tax_rate_pct", 20)

    # EU list of non-cooperative jurisdictions + low-tax
    tax_havens := {"AS","BB","BW","BS","BZ","BM","KY","CK","DM","FJ","GH","GD","GU","HK","JM","JE","KI","LR","MH","MU","MS","NA","NU","PA","WS","SC","SG","LC","VC","TT","TC","AE","VU","VG","ZW"}
    
    eu_blacklist := {"AS","BS","BZ","FJ","GU","PW","WS","TT","VU"}
    eu_greylist := {"BB","BW","CR","CW","HK","JM","MY","MK","QA","SC","TH","TR","AE","VG"}
    
    is_tax_haven := cfc_country in tax_havens
    is_eu_blacklisted := cfc_country in eu_blacklist
    is_eu_greylisted := cfc_country in eu_greylist
    is_low_tax := foreign_tax_rate < 14.25  # 75% of Polish 19% rate

    risk_category := "SAFE" { not is_tax_haven; not is_low_tax }
    risk_category := "MONITOR" { is_eu_greylisted or is_low_tax }
    risk_category := "HIGH_RISK" { is_tax_haven; not is_eu_blacklisted }
    risk_category := "CRITICAL" { is_eu_blacklisted }

    verdict := {
        "matched": true,
        "rule_id": "jdg.cfc_auto_classifier.jurisdiction_check",
        "package": "jdg.cfc_auto_classifier",
        "priority": 18303,
        "cac_cfc_country": cfc_country,
        "cac_foreign_tax_rate": foreign_tax_rate,
        "cac_is_tax_haven": is_tax_haven,
        "cac_is_eu_blacklisted": is_eu_blacklisted,
        "cac_is_eu_greylisted": is_eu_greylisted,
        "cac_is_low_tax_jurisdiction": is_low_tax,
        "cac_risk_category": risk_category,
        "_routing": "",
        "_routing_reason": sprintf("CFC Jurisdiction: %s — Tax rate: %.1f%% — Category: %s %s", [cfc_country, foreign_tax_rate, risk_category, "(EU BLACKLIST!)" { is_eu_blacklisted } else ""]),
        "_legal_basis": "Art. 30f PIT; EU List of Non-Cooperative Jurisdictions",
        "_description": "CAC-003: CFC Tax Haven / Low-Tax Jurisdiction Check"
    }
}
