# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CBAM FULL COMPLIANCE (P13 Priority 4)
# Package: jdg.cbam_full
# Legal basis: CBAM Regulation (EU) 2023/956; Implementing Regulation (EU) 2023/1773
# Public rule IDs: sector_classification, quarterly_reporting, certificate_tracker.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cbam_full

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.cbam_full.no_match",
    "package": "jdg.cbam_full",
    "priority": 999999
}

cbam_catalog := {
    "cement": {"cn_codes": ["2523"], "default_emission_factor_tonne_co2": 0.74, "name": "Cement"},
    "iron_steel": {"cn_codes": ["7201", "7202", "7203", "7204", "7205", "7206", "7207", "7208", "7209", "7210"], "default_emission_factor_tonne_co2": 1.90, "name": "Iron & Steel"},
    "aluminum": {"cn_codes": ["7601", "7603", "7604", "7605", "7606", "7607", "7608"], "default_emission_factor_tonne_co2": 8.60, "name": "Aluminum"},
    "fertilizers": {"cn_codes": ["2808", "2814", "2834", "3102", "3105"], "default_emission_factor_tonne_co2": 1.60, "name": "Fertilizers"},
    "electricity": {"cn_codes": ["2716"], "default_emission_factor_tonne_co2": 0.50, "name": "Electricity"},
    "hydrogen": {"cn_codes": ["2804"], "default_emission_factor_tonne_co2": 9.00, "name": "Hydrogen"}
}

sector_info(goods_type) = object.get(cbam_catalog, goods_type, {})

emission_factor(info) = object.get(info, "default_emission_factor_tonne_co2", 0) {
    count(info) > 0
} else = 1.0

net_liability(gross, offset) = floor((gross - offset) * 100) / 100 {
    gross > offset
} else = 0

report_obligations := {
    "frequency": "QUARTERLY",
    "content": "embedded emissions report, no certificate purchase needed",
    "deadline": "30 days after quarter end"
}

sector_routing(net, transitional) = "TRIAGE_QUEUE" {
    net > 0
    not transitional
} else = "WARNING" {
    net > 0
    transitional
} else = ""

report_status(submitted) = "SUBMITTED" {
    submitted
} else = "PENDING"

report_action(submitted) = "SUBMITTED" {
    submitted
} else = "MUST SUBMIT!"

quarterly_routing(submitted) = "WARNING" {
    not submitted
} else = ""

certificate_status(deficit, has_deficit) = sprintf("DEFICIT: %.0f certificates needed (%.0f EUR)", [deficit, deficit * 80]) {
    has_deficit
} else = "FULLY_COMPLIANT"

certificate_routing(has_deficit, held) = "BLOCK_AND_ALERT" {
    has_deficit
    held == 0
} else = "TRIAGE_QUEUE" {
    has_deficit
} else = ""

# CBF-001: CBAM sector classification and emissions calculator.
sector_decision := verdict {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    goods_type := object.get(invoice, "cbam_goods_type", "N/A")
    goods_weight_kg := object.get(invoice, "cbam_goods_weight_kg", 0)
    goods_weight_tonnes := goods_weight_kg / 1000
    country := object.get(vendor, "country", "N/A")
    carbon_price_paid := object.get(invoice, "cbam_carbon_price_paid", 0)
    info := sector_info(goods_type)
    known_sector := count(info) > 0
    factor := emission_factor(info)
    embedded := object.get(invoice, "cbam_embedded_emissions_tonnes", goods_weight_tonnes * factor)
    carbon_price := 80
    gross := floor(embedded * carbon_price * 100) / 100
    net := net_liability(gross, carbon_price_paid)
    transitional := true
    obligations := report_obligations
    routing := sector_routing(net, transitional)
    verdict := {
        "matched": true,
        "rule_id": "jdg.cbam_full.sector_classification",
        "package": "jdg.cbam_full",
        "priority": 18601,
        "cbf_goods_type": goods_type,
        "cbf_sector_name": object.get(info, "name", "UNKNOWN"),
        "cbf_is_known_sector": known_sector,
        "cbf_goods_weight_kg": goods_weight_kg,
        "cbf_goods_weight_tonnes": goods_weight_tonnes,
        "cbf_default_emission_factor": factor,
        "cbf_embedded_emissions_tonnes": embedded,
        "cbf_eu_carbon_price_eur": carbon_price,
        "cbf_cbam_gross_liability_eur": gross,
        "cbf_carbon_price_paid_origin": carbon_price_paid,
        "cbf_cbam_net_liability_eur": net,
        "cbf_cbam_phase": "TRANSITIONAL",
        "cbf_reporting_obligations": obligations,
        "cbf_vendor_country": country,
        "_routing": routing,
        "_routing_reason": sprintf("CBAM: %s (%.0f tonnes, %.0f kg) from %s — %.2f tCO2 → %.0f EUR net liability. Phase: %s", [object.get(info, "name", "Unknown"), goods_weight_tonnes, goods_weight_kg, country, embedded, net, "TRANSITIONAL"]),
        "_legal_basis": "CBAM Regulation (EU 2023/956); Implementing Regulation (EU 2023/1773)",
        "_description": "CBF-001: CBAM Sector Classification + Emissions Calculator for 6 sectors"
    }
    invoice.cbam_relevant == true
}

# CBF-002: CBAM quarterly reporting in the transitional phase.
quarterly_decision := verdict {
    invoice := object.get(input, "invoice", {})
    entrepreneur := object.get(input, "jdg_entrepreneur", {})
    current_quarter := object.get(entrepreneur, "cbam_current_quarter", "Q1")
    submitted := object.get(entrepreneur, "cbam_quarterly_report_submitted", false)
    deadline := "30 dni po zakończeniu kwartału"
    template := {
        "quarter": current_quarter,
        "goods_type": object.get(invoice, "cbam_goods_type", "N/A"),
        "goods_weight_tonnes": object.get(invoice, "cbam_goods_weight_kg", 0) / 1000,
        "embedded_emissions_tonnes": object.get(invoice, "cbam_embedded_emissions_tonnes", 0),
        "country_of_origin": object.get(object.get(input, "vendor", {}), "country", "N/A"),
        "carbon_price_paid_origin_eur": object.get(invoice, "cbam_carbon_price_paid", 0),
        "submitted": submitted,
        "deadline": deadline
    }
    verdict := {
        "matched": true,
        "rule_id": "jdg.cbam_full.quarterly_reporting",
        "package": "jdg.cbam_full",
        "priority": 18602,
        "cbf_quarter": current_quarter,
        "cbf_quarterly_deadline": deadline,
        "cbf_report_submitted": submitted,
        "cbf_cbam_template": template,
        "cbf_reporting_status": report_status(submitted),
        "_routing": quarterly_routing(submitted),
        "_routing_reason": sprintf("CBAM Quarterly: %s — %s. Deadline: %s", [current_quarter, report_action(submitted), deadline]),
        "_legal_basis": "CBAM Regulation (EU 2023/956); Implementing Regulation (EU 2023/1773)",
        "_description": "CBF-002: CBAM Quarterly Reporting — transitional phase obligations"
    }
    invoice.cbam_relevant == true
}

# CBF-003: CBAM certificate pricing and compliance tracker.
certificate_decision := verdict {
    entrepreneur := object.get(input, "jdg_entrepreneur", {})
    held := object.get(entrepreneur, "cbam_certificates_held", 0)
    needed := object.get(entrepreneur, "cbam_certificates_needed_annual", 0)
    price := 80
    total_cost := floor(needed * price * 100) / 100
    deficit := needed - held
    has_deficit := deficit > 0
    deficit_cost := floor(deficit * price * 100) / 100
    status := certificate_status(deficit, has_deficit)
    verdict := {
        "matched": true,
        "rule_id": "jdg.cbam_full.certificate_tracker",
        "package": "jdg.cbam_full",
        "priority": 18603,
        "cbf_certificates_held": held,
        "cbf_certificates_needed": needed,
        "cbf_certificate_deficit": deficit,
        "cbf_eu_ets_carbon_price_eur": price,
        "cbf_deficit_cost_eur": deficit_cost,
        "cbf_total_certificate_cost_eur": total_cost,
        "cbf_compliance_status": status,
        "cbf_cbam_registry_url": "https://cbam.ec.europa.eu/cbam-registry",
        "cbf_authorised_declarant_required": true,
        "_routing": certificate_routing(has_deficit, held),
        "_routing_reason": sprintf("CBAM Certificates: Held %d / Needed %d — Deficit: %d (%.0f EUR). Status: %s", [held, needed, deficit, deficit_cost, status]),
        "_legal_basis": "CBAM Regulation (EU 2023/956); Art. 20-24 (certificates)",
        "_description": "CBF-003: CBAM Certificate Pricing + Compliance Tracker"
    }
    entrepreneur.cbam_importer == true
}

decide := sector_decision {
    object.get(object.get(input, "invoice", {}), "cbam_relevant", false) == true
} else := quarterly_decision {
    object.get(object.get(input, "invoice", {}), "cbam_relevant", false) == true
} else := certificate_decision {
    object.get(object.get(input, "jdg_entrepreneur", {}), "cbam_importer", false) == true
}
