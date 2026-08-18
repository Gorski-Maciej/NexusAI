# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.5: Conviction Registry Auto-Checker
# v7.0 — BP-5: KRK API integration + expungement monitor + PZP safeguard
# Package: jdg.enterprise.conviction_checker
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.conviction_checker

import future.keywords.in
import data.jdg.helpers

fee_for_request(request_type) = fee {
    fees := {"INDIVIDUAL": 20, "COMPANY": 30}
    fee := object.get(fees, request_type, 0)
}

period_years_for_offense(offense_type) = years {
    periods := {"MISDEMEANOR": 2, "FISCAL_CRIME": 5}
    years := object.get(periods, offense_type, 2)
}

expungement_action(is_expunged, days_until_expungement) = action {
    is_expunged
    action := "WNIOSEK O ZATARCIE SKAZANIA — upłynął okres"
}

expungement_action(is_expunged, days_until_expungement) = action {
    not is_expunged
    action := sprintf("Pozostało %d dni do zatarcia", [days_until_expungement])
}

pzp_exclusion(has_conviction, is_expunged) = excluded {
    has_conviction
    not is_expunged
    excluded := true
}

pzp_exclusion(has_conviction, is_expunged) = excluded {
    not has_conviction
    excluded := false
}

pzp_exclusion(has_conviction, is_expunged) = excluded {
    has_conviction
    is_expunged
    excluded := false
}

pzp_decision_action(pzp_excluded, is_expunged) = action {
    pzp_excluded
    action := "NIE SKŁADAJ OFERTY — wykluczenie z PZP (Art. 108 ust. 1 pkt 2 PZP)"
}

pzp_decision_action(pzp_excluded, is_expunged) = action {
    not pzp_excluded
    is_expunged
    action := "Możesz składać oferty — skazanie zatarte"
}

pzp_decision_action(pzp_excluded, is_expunged) = action {
    not pzp_excluded
    not is_expunged
    action := "Brak ograniczeń PZP"
}

impact_severity(total_blocks) = "CRITICAL" {
    total_blocks >= 4
}

impact_severity(total_blocks) = "HIGH" {
    total_blocks == 3
}

impact_severity(total_blocks) = "MEDIUM" {
    total_blocks >= 1
    total_blocks <= 2
}

impact_severity(total_blocks) = "NONE" {
    total_blocks == 0
}

expungement_warning(is_expunged, days_left, block_count, severity) = warnings {
    is_expunged
    warnings := [
        "🔍 CONVICTION REGISTRY AUTO-CHECKER",
        "   ✅ SKAZANIE ZATARTE — pełnia praw przywrócona!",
    ]
}

expungement_warning(is_expunged, days_left, block_count, severity) = warnings {
    not is_expunged
    warnings := [
        "🔍 CONVICTION REGISTRY AUTO-CHECKER",
        sprintf("   ⏳ Do zatarcia: %d dni (Art. 19 KKS)", [days_left]),
        sprintf("   🚫 Aktywne blokady: %d — %s", [block_count, severity]),
    ]
}

# ─────────────────────────────────────────────────────────────────────────────
# CRC-3200: KRK check wrapper (online certificate request)
# ─────────────────────────────────────────────────────────────────────────────
crc_request_krk_check(input) = krk {
    nip := object.get(input, "nip", "")
    request_type := object.get(input, "request_type", "INDIVIDUAL")
    purpose := object.get(input, "purpose", "SELF_CHECK")

    fee_pln := fee_for_request(request_type)

    krk := {
        "nip": nip,
        "request_type": request_type,
        "purpose": purpose,
        "mode": "ONLINE",
        "endpoint": "https://ekrk.ms.gov.pl",
        "fee_pln": fee_pln,
        "legal_basis": "Art. 7 ust. 1 ustawy o KRK",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CRC-3210: Expungement monitor (Art. 19 KKS — zatarcie skazania)
# v7.0 FIX (LUKA-K19-1): Unified on Art. 19 KKS
# ─────────────────────────────────────────────────────────────────────────────
crc_expungement_monitor(input) = monitor {
    conviction_date := object.get(input, "kks_conviction_date_days_ago", 0)
    offense_type := object.get(input, "offense_type", "MISDEMEANOR")

    # Art. 19 § 1 KKS: fiscal misdemeanor = 2 years
    # Art. 19 § 2 KKS: fiscal crime = 5 years
    expungement_period_years := period_years_for_offense(offense_type)
    expungement_days := expungement_period_years * 365

    days_until_expungement := max([expungement_days - conviction_date, 0])
    is_expunged := days_until_expungement <= 0

    exp_action := expungement_action(is_expunged, days_until_expungement)

    monitor := {
        "offense_type": offense_type,
        "conviction_days_ago": conviction_date,
        "expungement_period_years": expungement_period_years,
        "days_until_expungement": days_until_expungement,
        "is_expunged": is_expunged,
        "rights_restored": is_expunged,
        "legal_basis": "Art. 19 § 1-2 KKS",
        "action": exp_action,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CRC-3220: Public procurement (PZP Art. 108) tender safeguard
# ─────────────────────────────────────────────────────────────────────────────
crc_pzp_tender_check(input) = pzp {
    has_conviction := object.get(input, "kks_convicted", false)
    is_expunged := object.get(input, "expunged", false)
    tender_value := object.get(input, "tender_value_pln", 0)

    pzp_excluded := pzp_exclusion(has_conviction, is_expunged)
    eu_threshold := tender_value > 130000  # ~130k PLN dla dostaw/usług

    pzp_action := pzp_decision_action(pzp_excluded, is_expunged)

    pzp := {
        "has_conviction": has_conviction,
        "is_expunged": is_expunged,
        "pzp_excluded": pzp_excluded,
        "eu_threshold_exceeded": eu_threshold,
        "action": pzp_action,
        "legal_basis": "Art. 108 ust. 1 pkt 2 ustawy PZP",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CRC-3230: Business impact aggregator
# ─────────────────────────────────────────────────────────────────────────────
crc_business_impact(conviction_data) = impact {
    blocks := {
        "professional_license": object.get(conviction_data, "blocks_professional", false),
        "banking": object.get(conviction_data, "blocks_banking", false),
        "pzp_tenders": object.get(conviction_data, "blocks_pzp", false),
        "eu_funds": object.get(conviction_data, "blocks_eu_funds", false),
        "vat_solidarity": object.get(conviction_data, "vat_solidarity_art105a", false),
    }

    active_blocks := [k | blocks[k] == true]
    total_blocks := count(active_blocks)

    severity := impact_severity(total_blocks)

    impact := {
        "blocks": blocks,
        "active_block_count": total_blocks,
        "severity": severity,
        "expungement_benefit": "Po zatarciu: odblokowanie PZP, funduszy UE, licencji zawodowych",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CRC-3240: Build CRC warnings
# ─────────────────────────────────────────────────────────────────────────────
build_crc_warnings(krk, expungement, pzp, impact) = warnings {
    is_expunged := object.get(expungement, "is_expunged", false)
    days_left := object.get(expungement, "days_until_expungement", 0)
    severity := object.get(impact, "severity", "NONE")
    block_count := object.get(impact, "active_block_count", 0)

    base := ["🔍 CONVICTION REGISTRY AUTO-CHECKER"]

    warnings := expungement_warning(is_expunged, days_left, block_count, severity)
}
