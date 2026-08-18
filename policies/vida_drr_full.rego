# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ViDA DRR FULL IMPLEMENTATION (P13 Priority 3)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.vida_drr_full
# Report:      RAPORT_P13 Section 7 — Priority 3
# Purpose:     Full ViDA DRR + e-invoicing + platform liability compliance
#              ViDA regulation phased 2027-2028
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vida_drr_full

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.vida_drr_full.no_match",
    "package": "jdg.vida_drr_full",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# VDF-001: ViDA DIGITAL REPORTING REQUIREMENTS (DRR)
# Pełna implementacja wymogów raportowania cyfrowego ViDA
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "has_cross_border_activity", false) == true
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"

    vida_phases := {
        "PHASE_1": {"effective": "2028-01-01", "requirement": "DRR — real-time reporting B2B cross-border", "status": "FUTURE"},
        "PHASE_2": {"effective": "2027-01-01", "requirement": "Platform liability — platform operator = deemed supplier", "status": "UPCOMING"},
        "PHASE_3": {"effective": "2028-01-01", "requirement": "Single VAT Registration (SVR) expansion", "status": "FUTURE"},
        "PHASE_4": {"effective": "2028-07-01", "requirement": "Mandatory EU e-invoicing B2B", "status": "FUTURE"}
    }

    current_phase := "PHASE_2"  # platform liability is closest

    # DRR requirements
    drr_transaction_data := {
        "invoice_number": object.get(input.invoice, "document_number", "N/A"),
        "buyer_vat": object.get(input.vendor, "nip_eu", "N/A"),
        "seller_vat": object.get(input.jdg_entrepreneur, "nip_eu", "N/A"),
        "amount_net": object.get(input.invoice, "amount_net", 0),
        "vat_rate": object.get(input.invoice, "vat_rate", 0.23),
        "transaction_date": object.get(input.invoice, "date", "N/A"),
        "goods_or_service": object.get(input.invoice, "goods_or_service", "GOODS"),
        "cross_border": true
    }

    drr_reporting_frequency := "REAL_TIME"  # ViDA requires real-time
    drr_reporting_deadline_seconds := 0  # immediate
    drr_format := "EN 16931 compliant e-invoice"

    # Check if e-invoicing ready
    is_einvoice_ready := object.get(input.jdg_entrepreneur, "uses_einvoicing", false)
    is_en16931_compliant := object.get(input.jdg_entrepreneur, "en16931_compliant", false)
    vida_readiness := is_einvoice_ready and is_en16931_compliant

    readiness_score := 0
    readiness_score := readiness_score + 30 { is_einvoice_ready }
    readiness_score := readiness_score + 30 { is_en16931_compliant }
    readiness_score := readiness_score + 20 { is_vat_payer }
    readiness_score := readiness_score + 20 { object.get(input.jdg_entrepreneur, "has_ksef", false) }

    routing := "WARNING" { not vida_readiness }
    routing := "" { vida_readiness }

    verdict := {
        "matched": true,
        "rule_id": "jdg.vida_drr_full.drr_implementation",
        "_legal_basis": "ViDA (EU 2022/890); Art. 130a-130d VAT",
        "package": "jdg.vida_drr_full",
        "priority": 18401,
        "vdf_vida_phases": vida_phases,
        "vdf_current_phase": current_phase,
        "vdf_drr_required": true,
        "vdf_drr_frequency": drr_reporting_frequency,
        "vdf_drr_format": drr_format,
        "vdf_drr_data_sample": drr_transaction_data,
        "vdf_einvoice_ready": is_einvoice_ready,
        "vdf_en16931_compliant": is_en16931_compliant,
        "vdf_vida_readiness_score": readiness_score,
        "vdf_vida_ready": vida_readiness,
        "vdf_next_step": "Enable EN 16931 e-invoicing before 2028" { not vida_readiness },
        "vdf_next_step": "Monitor ViDA phase transitions" { vida_readiness },
        "_routing": routing,
        "_routing_reason": sprintf("ViDA DRR: Readiness %d/100 — %s. Phase: %s. Frequency: %s", [readiness_score, "READY" { vida_readiness } else "NOT READY"], current_phase, drr_reporting_frequency]),
        "_legal_basis": "ViDA (EU 2022/890); EN 16931; Art. 130a-130d VAT",
        "_description": "VDF-001: ViDA DRR Full — 4-phase compliance roadmap with readiness scoring"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# VDF-002: PLATFORM LIABILITY TRACKER (Phase 2 — effective 2027)
# Platformy cyfrowe = deemed supplier od 2027
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "platform_operator", false) == true

    platform_type := object.get(input.jdg_entrepreneur, "platform_type", "GOODS")
    platform_cross_border := object.get(input.jdg_entrepreneur, "platform_cross_border", false)
    platform_tx_count := object.get(input.jdg_entrepreneur, "platform_annual_tx_count", 0)
    platform_revenue := object.get(input.jdg_entrepreneur, "platform_annual_revenue_eur", 0)

    platform_liability_effective := "2027-01-01"
    platform_becomes_supplier := platform_cross_border and platform_tx_count > 0

    # Platform liability: platform = deemed supplier for VAT
    vat_collection_duty := platform_becomes_supplier
    vat_remit_to := "One-Stop Shop (OSS) / Import One-Stop Shop (IOSS)"

    platform_liability_types := {
        "RIDE_SHARING": "Platform collects + remits VAT (Art. 130a VAT)",
        "ACCOMMODATION": "Platform collects + remits VAT for short-term rentals (Art. 130b VAT)",
        "PERSONAL_SERVICES": "Platform collects + remits VAT (Art. 130c VAT)",
        "GOODS": "Platform = deemed supplier for B2C ≤150 EUR (Art. 130d VAT)",
        "DIGITAL": "Platform = full VAT liability"
    }

    platform_liability := object.get(platform_liability_types, platform_type, "Check specific rules")

    routing := "TRIAGE_QUEUE" { platform_becomes_supplier }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.vida_drr_full.platform_liability",
        "_legal_basis": "ViDA (EU 2022/890); Art. 130a-130d VAT",
        "package": "jdg.vida_drr_full",
        "priority": 18402,
        "vdf_platform_type": platform_type,
        "vdf_platform_liability_effective": platform_liability_effective,
        "vdf_platform_becomes_supplier": platform_becomes_supplier,
        "vdf_platform_vat_collection_duty": vat_collection_duty,
        "vdf_platform_vat_remit": vat_remit_to,
        "vdf_platform_liability_rule": platform_liability,
        "vdf_days_until_effective": "~180 days (estimate)" { platform_liability_effective > "2026-07-01" },
        "_routing": routing,
        "_routing_reason": sprintf("Platform Liability: %s — %s. Effective: %s", [platform_type, "DEEMED SUPPLIER" { platform_becomes_supplier } else "N/A", platform_liability_effective]),
        "_legal_basis": "ViDA (EU 2022/890); Art. 130a-130d VAT",
        "_description": "VDF-002: Platform Liability Tracker — platform = deemed supplier from 2027"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# VDF-003: SINGLE VAT REGISTRATION (SVR) READINESS
# Ocena gotowości na Single VAT Registration
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "has_cross_border_activity", false) == true

    registered_in_eu_countries := object.get(input.jdg_entrepreneur, "vat_registered_countries", [])
    uses_oss := object.get(input.jdg_entrepreneur, "uses_oss_scheme", false)
    uses_ioss := object.get(input.jdg_entrepreneur, "uses_ioss_scheme", false)

    multiple_registrations := count(registered_in_eu_countries) > 1
    svr_benefit := multiple_registrations  # SVR eliminates need for multiple VAT registrations

    oss_ioss_ready := uses_oss or uses_ioss
    svr_readiness := oss_ioss_ready

    svr_effective := "2028-01-01"
    svr_phases := ["OSS/IOSS expansion (current)", "SVR for B2C (2028)", "SVR for B2B (2028+)", "Full SVR (2029+)"]

    verdict := {
        "matched": true,
        "rule_id": "jdg.vida_drr_full.svr_readiness",
        "_legal_basis": "ViDA (EU 2022/890); Art. 130a-130d VAT",
        "package": "jdg.vida_drr_full",
        "priority": 18403,
        "vdf_svr_effective": svr_effective,
        "vdf_current_registrations": registered_in_eu_countries,
        "vdf_multiple_registrations": multiple_registrations,
        "vdf_uses_oss": uses_oss,
        "vdf_uses_ioss": uses_ioss,
        "vdf_svr_ready": svr_readiness,
        "vdf_svr_benefit": "Eliminates multiple VAT registrations → single point of compliance" { svr_benefit },
        "vdf_svr_phases": svr_phases,
        "_routing": "",
        "_routing_reason": sprintf("SVR Readiness: %d EU registrations — OSS/IOSS: %s. SVR benefit: %s", [count(registered_in_eu_countries), oss_ioss_ready, "YES — consolidate!" { multiple_registrations } else "limited"]),
        "_legal_basis": "ViDA (EU 2022/890); Art. 130a-130d VAT",
        "_description": "VDF-003: Single VAT Registration Readiness Assessment"
    }
}
