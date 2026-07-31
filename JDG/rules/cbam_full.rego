# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CBAM FULL COMPLIANCE (P13 Priority 4)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.cbam_full
# Report:      RAPORT_P13 Section 7 — Priority 4
# Purpose:     Full CBAM compliance — cement, steel, aluminum, fertilizers, electricity, hydrogen
#              CBAM Regulation (EU 2023/956) — entered into force 2023, transitional until 2026
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cbam_full

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.cbam_full.no_match",
    "package": "jdg.cbam_full",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# CBF-001: CBAM SECTOR CLASSIFICATION + EMISSIONS CALCULATOR
# Automatyczna klasyfikacja towarów CBAM i kalkulacja emisji
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.invoice, "cbam_relevant", false) == true

    cbam_goods_type := object.get(input.invoice, "cbam_goods_type", "N/A")
    goods_weight_kg := object.get(input.invoice, "cbam_goods_weight_kg", 0)
    goods_weight_tonnes := goods_weight_kg / 1000
    vendor_country := object.get(input.vendor, "country", "N/A")
    carbon_price_paid_origin := object.get(input.invoice, "cbam_carbon_price_paid", 0)

    cbam_sectors := {
        "cement": {"cn_codes": ["2523"], "default_emission_factor_tonne_co2": 0.74, "name": "Cement"},
        "iron_steel": {"cn_codes": ["7201","7202","7203","7204","7205","7206","7207","7208","7209","7210"], "default_emission_factor_tonne_co2": 1.90, "name": "Iron & Steel"},
        "aluminum": {"cn_codes": ["7601","7603","7604","7605","7606","7607","7608"], "default_emission_factor_tonne_co2": 8.60, "name": "Aluminum"},
        "fertilizers": {"cn_codes": ["2808","2814","2834","3102","3105"], "default_emission_factor_tonne_co2": 1.60, "name": "Fertilizers"},
        "electricity": {"cn_codes": ["2716"], "default_emission_factor_tonne_co2": 0.50, "name": "Electricity"},
        "hydrogen": {"cn_codes": ["2804"], "default_emission_factor_tonne_co2": 9.00, "name": "Hydrogen"}
    }

    sector_info := object.get(cbam_sectors, cbam_goods_type, {})
    is_known_sector := count(sector_info) > 0

    default_emission_factor := object.get(sector_info, "default_emission_factor_tonne_co2", 0) { is_known_sector }
    default_emission_factor := 1.0 { not is_known_sector }

    embedded_emissions := object.get(input.invoice, "cbam_embedded_emissions_tonnes", goods_weight_tonnes * default_emission_factor)

    eu_carbon_price_per_tonne := 80  # EU ETS approximate price ~80 EUR/tonne
    cbam_certificate_price := eu_carbon_price_per_tonne

    cbam_gross_liability_eur := floor(embedded_emissions * cbam_certificate_price * 100) / 100
    cbam_offset_eur := carbon_price_paid_origin
    cbam_net_liability_eur := floor((cbam_gross_liability_eur - cbam_offset_eur) * 100) / 100 { cbam_gross_liability_eur > cbam_offset_eur }
    cbam_net_liability_eur := 0 { cbam_gross_liability_eur <= cbam_offset_eur }

    is_transitional := true  # transitional period until 2026-12-31
    cbam_phase := "TRANSITIONAL" { is_transitional }
    cbam_phase := "DEFINITIVE" { not is_transitional }

    reporting_obligations := {
        "transitional": {"frequency": "QUARTERLY", "content": "embedded emissions report, no certificate purchase needed", "deadline": "30 days after quarter end"},
        "definitive": {"frequency": "ANNUAL", "content": "CBAM declaration + certificate surrender by 31 May", "deadline": "31 maja następnego roku"}
    }

    obligations := reporting_obligations.transitional { is_transitional }
    obligations := reporting_obligations.definitive { not is_transitional }

    routing := "TRIAGE_QUEUE" { cbam_net_liability_eur > 0 and not is_transitional }
    routing := "WARNING" { cbam_net_liability_eur > 0 and is_transitional }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.cbam_full.sector_classification",
        "package": "jdg.cbam_full",
        "priority": 18601,
        "cbf_goods_type": cbam_goods_type,
        "cbf_sector_name": object.get(sector_info, "name", "UNKNOWN"),
        "cbf_is_known_sector": is_known_sector,
        "cbf_goods_weight_kg": goods_weight_kg,
        "cbf_goods_weight_tonnes": goods_weight_tonnes,
        "cbf_default_emission_factor": default_emission_factor,
        "cbf_embedded_emissions_tonnes": embedded_emissions,
        "cbf_eu_carbon_price_eur": eu_carbon_price_per_tonne,
        "cbf_cbam_gross_liability_eur": cbam_gross_liability_eur,
        "cbf_carbon_price_paid_origin": carbon_price_paid_origin,
        "cbf_cbam_net_liability_eur": cbam_net_liability_eur,
        "cbf_cbam_phase": cbam_phase,
        "cbf_reporting_obligations": obligations,
        "cbf_vendor_country": vendor_country,
        "_routing": routing,
        "_routing_reason": sprintf("CBAM: %s (%.0f tonnes, %.0f kg) from %s — %.2f tCO2 → %.0f EUR net liability. Phase: %s", [object.get(sector_info, "name", "Unknown"), goods_weight_tonnes, goods_weight_kg, vendor_country, embedded_emissions, cbam_net_liability_eur, cbam_phase]),
        "_legal_basis": "CBAM Regulation (EU 2023/956); Implementing Regulation (EU 2023/1773)",
        "_description": "CBF-001: CBAM Sector Classification + Emissions Calculator for 6 sectors"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CBF-002: CBAM QUARTERLY REPORTING (Transitional Phase)
# Raportowanie kwartalne w fazie przejściowej CBAM
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.invoice, "cbam_relevant", false) == true

    current_quarter := object.get(input.jdg_entrepreneur, "cbam_current_quarter", "Q1")
    cbam_report_submitted := object.get(input.jdg_entrepreneur, "cbam_quarterly_report_submitted", false)
    is_transitional := true

    quarterly_deadline := "30 dni po zakończeniu kwartału"

    cbam_template := {
        "quarter": current_quarter,
        "goods_type": object.get(input.invoice, "cbam_goods_type", "N/A"),
        "goods_weight_tonnes": object.get(input.invoice, "cbam_goods_weight_kg", 0) / 1000,
        "embedded_emissions_tonnes": object.get(input.invoice, "cbam_embedded_emissions_tonnes", 0),
        "country_of_origin": object.get(input.vendor, "country", "N/A"),
        "carbon_price_paid_origin_eur": object.get(input.invoice, "cbam_carbon_price_paid", 0),
        "submitted": cbam_report_submitted,
        "deadline": quarterly_deadline
    }

    routing := "WARNING" { not cbam_report_submitted }

    cbf_reporting_status := "SUBMITTED" { cbam_report_submitted }
    cbf_reporting_status := "PENDING" { not cbam_report_submitted }

    verdict := {
        "matched": true,
        "rule_id": "jdg.cbam_full.quarterly_reporting",
        "package": "jdg.cbam_full",
        "priority": 18602,
        "cbf_quarter": current_quarter,
        "cbf_quarterly_deadline": quarterly_deadline,
        "cbf_report_submitted": cbam_report_submitted,
        "cbf_cbam_template": cbam_template,
        "cbf_reporting_status": cbf_reporting_status,
        "_routing": routing,
        "_routing_reason": sprintf("CBAM Quarterly: %s — %s. Deadline: %s", [current_quarter, "SUBMITTED" { cbam_report_submitted } else "MUST SUBMIT!"], quarterly_deadline),
        "_legal_basis": "CBAM Regulation (EU 2023/956); Implementing Regulation (EU 2023/1773)",
        "_description": "CBF-002: CBAM Quarterly Reporting — transitional phase obligations"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CBF-003: CBAM CERTIFICATE PRICING + COMPLIANCE TRACKER
# Monitorowanie cen certyfikatów CBAM i zgodności
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "cbam_importer", false) == true

    cbam_certificates_held := object.get(input.jdg_entrepreneur, "cbam_certificates_held", 0)
    cbam_certificates_needed := object.get(input.jdg_entrepreneur, "cbam_certificates_needed_annual", 0)
    eu_carbon_price := 80
    certificate_cost_eur := floor(cbam_certificates_needed * eu_carbon_price * 100) / 100

    deficit := cbam_certificates_needed - cbam_certificates_held
    has_deficit := deficit > 0
    deficit_cost_eur := floor(deficit * eu_carbon_price * 100) / 100

    cbam_registry_url := "https://cbam.ec.europa.eu/cbam-registry"
    cbam_authorised_declarant_required := true

    cbf_compliance_status := "FULLY_COMPLIANT" { not has_deficit }
    cbf_compliance_status := sprintf("DEFICIT: %.0f certificates needed (%.0f EUR)", [deficit, deficit_cost_eur]) { has_deficit }

    routing := "BLOCK_AND_ALERT" { has_deficit and cbam_certificates_held == 0 }
    routing := "TRIAGE_QUEUE" { has_deficit }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.cbam_full.certificate_tracker",
        "package": "jdg.cbam_full",
        "priority": 18603,
        "cbf_certificates_held": cbam_certificates_held,
        "cbf_certificates_needed": cbam_certificates_needed,
        "cbf_certificate_deficit": deficit,
        "cbf_eu_ets_carbon_price_eur": eu_carbon_price,
        "cbf_deficit_cost_eur": deficit_cost_eur,
        "cbf_total_certificate_cost_eur": certificate_cost_eur,
        "cbf_compliance_status": cbf_compliance_status,
        "cbf_cbam_registry_url": cbam_registry_url,
        "cbf_authorised_declarant_required": cbam_authorised_declarant_required,
        "_routing": routing,
        "_routing_reason": sprintf("CBAM Certificates: Held %d / Needed %d — Deficit: %d (%.0f EUR). Status: %s", [cbam_certificates_held, cbam_certificates_needed, deficit, deficit_cost_eur, compliance_status]),
        "_legal_basis": "CBAM Regulation (EU 2023/956); Art. 20-24 (certificates)",
        "_description": "CBF-003: CBAM Certificate Pricing + Compliance Tracker"
    }
}
