# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — UK Post-Brexit Edge Cases (P170-P172)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: UK Post-Brexit Package — Import towarów, eksport usług, rejestracja VAT UK
# description: |
#   Reguły dla transakcji z Wielką Brytanią po Brexicie (od 2021 UK = kraj trzeci).
#   P170: Import towarów z UK — VAT + cło
#   P171: Eksport usług B2B do UK — reverse charge (NP w PL)
#   P172: Sprzedaż B2C do UK — próg rejestracji VAT UK 90 000 GBP
# architecture: Multi-Pass PAS 3 (ADR-001)
# legal_basis: Art. 17 ust. 1 pkt 1 VAT, Art. 28b VAT, UK VAT Act 1994
# edge_cases:
#   - P170 specjalizuje P45 (import_non_eu) — UK wymaga dodatkowej kontroli cła
#   - P171: usługi B2B do UK = NP (reverse charge w UK), nie WDT (UK nie jest UE)
#   - P172: Distance Selling UK — próg 90k GBP dla B2C
# package: jdg.crossborder.post_brexit
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.crossborder.post_brexit

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.crossborder.post_brexit.no_match",
    "package": "jdg.crossborder.post_brexit", "priority": 199
}

# ══════ P170: uk_post_brexit_goods_import — Import towarów z UK ══════
decide := {
    "matched": true, "rule_id": "jdg.crossborder.post_brexit.uk_goods_import",
    "package": "jdg.crossborder.post_brexit", "priority": 170,
    "vat_rate": "0.23", "rounding_level": "position", "gtu_code": "",
    "procedure": "IMPORT_NON_EU_UK", "vat_exemption": "",
    "customs_duty_possible": true, "uk_origin": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Import towarów z UK — VAT od importu + możliwe cło",
    "_legal_basis": "Art. 17 ust. 1 pkt 1 VAT, ustawa o ceł, TCA UK-EU",
    "_warnings": [
        "IMPORT Z UK — UK jest krajem trzecim (non-EU) od 2021. VAT należny w imporcie wg stawki krajowej. Sprawdź TCA (Trade and Cooperation Agreement) — możliwa preferencyjna stawka celna 0% przy świadectwie pochodzenia."
    ]
} {
    input.invoice.procedure == "IMPORT"
    input.vendor.country == "GB"
}

# ══════ P171: uk_post_brexit_services_export_b2b — Eksport usług B2B do UK ══════
else := {
    "matched": true, "rule_id": "jdg.crossborder.post_brexit.uk_services_export_b2b",
    "package": "jdg.crossborder.post_brexit", "priority": 171,
    "vat_rate": "0.00", "rounding_level": "total", "gtu_code": "",
    "procedure": "EXPORT_SERVICES_UK_B2B", "vat_exemption": "",
    "place_of_supply": "GB", "reverse_charge": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "Usługi B2B do UK — VAT rozlicza nabywca w UK (reverse charge)",
    "_legal_basis": "Art. 28b VAT (miejsce świadczenia = siedziba nabywcy)",
    "_warnings": [
        "USŁUGI B2B DO UK — miejsce świadczenia = UK (siedziba nabywcy). Polski JDG NIE nalicza VAT. Nabywca rozlicza reverse charge w UK. Faktura z adnotacją 'reverse charge'."
    ]
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "GB"
    input.vendor.is_b2b_buyer == true
    input.invoice.type == "SERVICE"
}

# ══════ P172: uk_post_brexit_vat_registration_threshold — Próg VAT UK dla B2C ══════
else := {
    "matched": true, "rule_id": "jdg.crossborder.post_brexit.uk_vat_registration_b2c",
    "package": "jdg.crossborder.post_brexit", "priority": 172,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "uk_vat_registration_required": threshold_exceeded,
    "uk_b2c_annual_turnover_gbp": uk_turnover,
    "uk_vat_threshold_gbp": 90000,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": warning_level,
    "_routing_reason": reason,
    "_legal_basis": "UK VAT Act 1994, Distance Selling Regulations",
    "_warnings": warnings_list
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "GB"
    input.vendor.is_b2c == true
    uk_turnover := object.get(input.jdg_entrepreneur, "uk_b2c_annual_turnover_gbp", 0)
    uk_turnover > 0
    threshold_exceeded := uk_turnover > 90000
    warning_level = "BLOCK_AND_ALERT" { threshold_exceeded == true }
    warning_level = "" { threshold_exceeded == false }
    reason = "Sprzedaż B2C do UK > 90 000 GBP — obowiązek rejestracji VAT w UK!" { threshold_exceeded == true }
    reason = "Sprzedaż B2C do UK poniżej progu 90k GBP" { threshold_exceeded == false }
    warnings_list = [sprintf("SPRZEDAŻ B2C DO UK — %.0f GBP rocznie. Próg rejestracji VAT UK: 90 000 GBP. %s", [uk_turnover, action])]
    action = "OBOWIĄZEK rejestracji VAT w UK (HMRC)! Złóż wniosek VAT1." { threshold_exceeded == true }
    action = "Poniżej progu — brak obowiązku rejestracji VAT UK." { threshold_exceeded == false }
}
