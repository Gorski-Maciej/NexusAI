# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CFC AUTO-CLASSIFIER (P13 Priority 2)
# Package: jdg.cfc_auto_classifier
# Legal basis: Art. 30f PIT; Art. 45 ust. 1aa PIT; EU List of Non-Cooperative Jurisdictions
# Public rule IDs: passive_classifier, de_minimis_check, jurisdiction_check.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cfc_auto_classifier

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.cfc_auto_classifier.no_match",
    "package": "jdg.cfc_auto_classifier",
    "priority": 999999
}

cfc_profile() = object.get(input, "jdg_entrepreneur", {})

passive_income_buckets(profile) = {
    "INTEREST": object.get(profile, "cfc_interest_income", 0),
    "ROYALTIES": object.get(profile, "cfc_royalties_income", 0),
    "DIVIDENDS": object.get(profile, "cfc_dividends_income", 0),
    "RENTAL": object.get(profile, "cfc_rental_income", 0),
    "CAPITAL_GAINS": object.get(profile, "cfc_capital_gains", 0),
    "FINANCIAL_ASSET_SALES": object.get(profile, "cfc_financial_asset_sales", 0),
    "INTANGIBLE_LICENSING": object.get(profile, "cfc_intangible_licensing", 0),
    "FRANCHISE_FEES": object.get(profile, "cfc_franchise_fees", 0),
    "LEASING": object.get(profile, "cfc_leasing_income", 0),
    "FACTORING": object.get(profile, "cfc_factoring_income", 0)
}

passive_types := {"INTEREST", "ROYALTIES", "DIVIDENDS", "RENTAL", "CAPITAL_GAINS", "FINANCIAL_ASSET_SALES", "INTANGIBLE_LICENSING", "FRANCHISE_FEES", "LEASING", "FACTORING"}

passive_income_for(buckets) = sum([value | buckets[key] = value; key in passive_types])

passive_pct_for(passive_income, total_income) = floor(passive_income / total_income * 10000) / 100 {
    total_income > 0
} else = 0

risk_level_for(score) = "LOW" {
    score < 30
} else = "MEDIUM" {
    score >= 30
    score < 60
} else = "HIGH" {
    score >= 60
    score < 80
} else = "CRITICAL"

risk_score_for(passive_exceeded, ownership_pct, country, buckets, total_income) = passive_points + ownership_points + country_points + royalty_points + licensing_points {
    passive_points := passive_score(passive_exceeded)
    ownership_points := ownership_score(ownership_pct)
    country_points := country_score(country)
    royalty_points := royalty_score(buckets, total_income)
    licensing_points := licensing_score(buckets)
}

passive_score(true) = 25
passive_score(false) = 0

ownership_score(ownership_pct) = 20 {
    ownership_pct > 0.75
} else = 0

country_score(country) = 15 {
    country in {"BM", "KY", "GG", "JE", "IM", "MH", "PA", "VG", "TC", "AE", "HK", "SG", "CH", "LI"}
} else = 0

royalty_score(buckets, total_income) = 10 {
    safe_ratio(object.get(buckets, "ROYALTIES", 0), total_income) > 0.50
} else = 0

licensing_score(buckets) = 10 {
    object.get(buckets, "INTANGIBLE_LICENSING", 0) > 0
} else = 0

safe_ratio(numerator, denominator) = numerator / denominator {
    denominator > 0
} else = 0

income_attributed(total_income, ownership_pct) = floor(total_income * ownership_pct * 100) / 100 {
    ownership_pct > 0.50
} else = 0

dominant_types(buckets) = [{"type": key, "amount": value} | buckets[key] = value; value > 0]

dominant_type_for(buckets) = [item.type | item := dominant_types(buckets)[_]; item.amount == max([x.amount | x := dominant_types(buckets)[_]])] {
    count(dominant_types(buckets)) > 0
} else = []

routing_for(risk_level, passive_exceeded) = "BLOCK_AND_ALERT" {
    risk_level == "CRITICAL"
    passive_exceeded
} else = "TRIAGE_QUEUE" {
    risk_level == "HIGH"
    passive_exceeded
} else = "WARNING" {
    passive_exceeded
} else = ""

# CAC-001: CFC passive income auto-classifier.
passive_decision := verdict {
    profile := cfc_profile()
    country := object.get(profile, "cfc_country", "N/A")
    total_income := object.get(profile, "cfc_total_income_pln", 0)
    ownership_pct := object.get(profile, "cfc_ownership_pct", 0)
    buckets := passive_income_buckets(profile)
    passive_income := passive_income_for(buckets)
    active_income := total_income - passive_income
    passive_pct := passive_pct_for(passive_income, total_income)
    threshold := 33.0
    passive_exceeded := passive_pct > threshold
    score := risk_score_for(passive_exceeded, ownership_pct, country, buckets, total_income)
    risk_level := risk_level_for(score)
    attributed := income_attributed(total_income, ownership_pct)
    tax_due := floor(attributed * 0.19 * 100) / 100
    dominant := dominant_type_for(buckets)
    verdict := {
        "matched": true,
        "rule_id": "jdg.cfc_auto_classifier.passive_classifier",
        "package": "jdg.cfc_auto_classifier",
        "priority": 18301,
        "cac_cfc_country": country,
        "cac_total_income": total_income,
        "cac_passive_income": passive_income,
        "cac_active_income": active_income,
        "cac_passive_pct": passive_pct,
        "cac_passive_threshold_exceeded": passive_exceeded,
        "cac_dominant_passive_type": dominant,
        "cac_income_buckets": buckets,
        "cac_ownership_pct": ownership_pct,
        "cac_cfc_income_attributed": attributed,
        "cac_cfc_tax_due": tax_due,
        "cac_risk_score": score,
        "cac_risk_level": risk_level,
        "cac_pit_cfc_due": "30 września następnego roku",
        "_routing": routing_for(risk_level, passive_exceeded),
        "_routing_reason": sprintf("CFC Classifier: %.1f%% passive (%s dominant) — Risk: %s (%d/100). Tax: %.0f PLN", [passive_pct, dominant, risk_level, score, tax_due]),
        "_legal_basis": "Art. 30f PIT — CFC; Art. 45 ust. 1aa PIT (PIT-CFC)",
        "_description": "CAC-001: CFC Passive Income Auto-Classifier with 10 income buckets and risk scoring"
    }
    profile.has_cfc == true
    object.get(profile, "cfc_de_minimis_requested", false) == false
    object.get(profile, "cfc_jurisdiction_requested", false) == false
}

# CAC-002: CFC de minimis check.
de_minimis_decision := verdict {
    profile := cfc_profile()
    ownership_pct := object.get(profile, "cfc_ownership_pct", 0)
    revenue := object.get(profile, "cfc_revenue_eur", 0)
    threshold := 250000
    scale := 4.5
    limit := threshold * scale / 100
    attributed := floor(revenue * ownership_pct * 100) / 100
    applies := attributed <= limit
    ownership_qualifies := ownership_pct > 0.50
    verdict := {
        "matched": true,
        "rule_id": "jdg.cfc_auto_classifier.de_minimis_check",
        "package": "jdg.cfc_auto_classifier",
        "priority": 18302,
        "cac_cfc_revenue_eur": revenue,
        "cac_attributed_revenue_eur": attributed,
        "cac_de_minimis_threshold_eur": threshold,
        "cac_de_minimis_limit_with_scale": limit,
        "cac_de_minimis_applies": applies,
        "cac_note": de_minimis_note(applies, ownership_qualifies),
        "_routing": "",
        "_routing_reason": sprintf("CFC De Minimis: %.0f EUR attributed vs %.0f EUR threshold — %s", [attributed, limit, de_minimis_action(applies, ownership_qualifies)]),
        "_legal_basis": "Art. 30f ust. 2 PIT",
        "_description": "CAC-002: CFC De Minimis check — 250k EUR threshold with ownership scaling"
    }
    profile.has_cfc == true
    profile.cfc_de_minimis_requested == true
}

de_minimis_note(applies, ownership_qualifies) = "De minimis exemption: CFC revenue < 250k EUR × ownership scale (4.5)" {
    applies
    ownership_qualifies
} else = "De minimis NOT applicable — CFC reporting required"

de_minimis_action(applies, ownership_qualifies) = "EXEMPT" {
    applies
    ownership_qualifies
} else = "NOT EXEMPT"

# CAC-003: CFC tax-haven / low-tax jurisdiction check.
jurisdiction_decision := verdict {
    profile := cfc_profile()
    country := object.get(profile, "cfc_country", "N/A")
    foreign_rate := object.get(profile, "cfc_foreign_tax_rate_pct", 20)
    tax_havens := {"AS", "BB", "BW", "BS", "BZ", "BM", "KY", "CK", "DM", "FJ", "GH", "GD", "GU", "HK", "JM", "JE", "KI", "LR", "MH", "MU", "MS", "NA", "NU", "PA", "WS", "SC", "SG", "LC", "VC", "TT", "TC", "AE", "VU", "VG", "ZW"}
    eu_blacklist := {"AS", "BS", "BZ", "FJ", "GU", "PW", "WS", "TT", "VU"}
    eu_greylist := {"BB", "BW", "CR", "CW", "HK", "JM", "MY", "MK", "QA", "SC", "TH", "TR", "AE", "VG"}
    tax_haven := country in tax_havens
    blacklisted := country in eu_blacklist
    greylisted := country in eu_greylist
    low_tax := foreign_rate < 14.25
    category := jurisdiction_category(tax_haven, blacklisted, greylisted, low_tax)
    verdict := {
        "matched": true,
        "rule_id": "jdg.cfc_auto_classifier.jurisdiction_check",
        "package": "jdg.cfc_auto_classifier",
        "priority": 18303,
        "cac_cfc_country": country,
        "cac_foreign_tax_rate": foreign_rate,
        "cac_is_tax_haven": tax_haven,
        "cac_is_eu_blacklisted": blacklisted,
        "cac_is_eu_greylisted": greylisted,
        "cac_is_low_tax_jurisdiction": low_tax,
        "cac_risk_category": category,
        "_routing": "",
        "_routing_reason": sprintf("CFC Jurisdiction: %s — Tax rate: %.1f%% — Category: %s %s", [country, foreign_rate, category, blacklist_suffix(blacklisted)]),
        "_legal_basis": "Art. 30f PIT; EU List of Non-Cooperative Jurisdictions",
        "_description": "CAC-003: CFC Tax Haven / Low-Tax Jurisdiction Check"
    }
    profile.has_cfc == true
    profile.cfc_jurisdiction_requested == true
}

jurisdiction_category(tax_haven, blacklisted, greylisted, low_tax) = "CRITICAL" {
    blacklisted
} else = "HIGH_RISK" {
    tax_haven
    not blacklisted
} else = "MONITOR" {
    greylisted
} else = "MONITOR" {
    low_tax
} else = "SAFE"

blacklist_suffix(true) = "(EU BLACKLIST!)"
blacklist_suffix(false) = ""

decide := passive_decision {
    object.get(cfc_profile(), "has_cfc", false) == true
    object.get(cfc_profile(), "cfc_de_minimis_requested", false) == false
    object.get(cfc_profile(), "cfc_jurisdiction_requested", false) == false
} else := de_minimis_decision {
    object.get(cfc_profile(), "has_cfc", false) == true
    object.get(cfc_profile(), "cfc_de_minimis_requested", false) == true
} else := jurisdiction_decision {
    object.get(cfc_profile(), "has_cfc", false) == true
    object.get(cfc_profile(), "cfc_jurisdiction_requested", false) == true
}
