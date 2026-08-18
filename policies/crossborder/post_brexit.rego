# NexusAI JDG Policies — UK Post-Brexit Edge Cases (P170-P172)
package jdg.crossborder.post_brexit

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.crossborder.post_brexit.no_match",
    "package": "jdg.crossborder.post_brexit",
    "priority": 199
}

uk_b2c_threshold_status(turnover) = true {
    turnover > 90000
}

uk_b2c_threshold_status(turnover) = false {
    turnover <= 90000
}

uk_b2c_routing(exceeded) = "BLOCK_AND_ALERT" {
    exceeded
}

uk_b2c_routing(exceeded) = "" {
    exceeded == false
}

uk_b2c_reason(exceeded) = "Sprzedaż B2C do UK > 90 000 GBP — obowiązek rejestracji VAT w UK!" {
    exceeded
}

uk_b2c_reason(exceeded) = "Sprzedaż B2C do UK poniżej progu 90k GBP" {
    exceeded == false
}

uk_b2c_action(exceeded) = "OBOWIĄZEK rejestracji VAT w UK (HMRC)! Złóż wniosek VAT1." {
    exceeded
}

uk_b2c_action(exceeded) = "Poniżej progu — brak obowiązku rejestracji VAT UK." {
    exceeded == false
}

# P170: import goods from UK
decide := {
    "matched": true,
    "rule_id": "jdg.crossborder.post_brexit.uk_goods_import",
    "package": "jdg.crossborder.post_brexit",
    "priority": 170,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "IMPORT_NON_EU_UK",
    "vat_exemption": "",
    "customs_duty_possible": true,
    "uk_origin": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Import towarów z UK — VAT od importu + możliwe cło",
    "_legal_basis": "Art. 17 ust. 1 pkt 1 VAT, ustawa o ceł, TCA UK-EU",
    "_warnings": ["IMPORT Z UK — UK jest krajem trzecim; sprawdź VAT, cło i pochodzenie preferencyjne."]
} {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    object.get(invoice, "procedure", "") == "IMPORT"
    object.get(vendor, "country", "") == "GB"
}

# P171: B2B services export to UK
else := {
    "matched": true,
    "rule_id": "jdg.crossborder.post_brexit.uk_services_export_b2b",
    "package": "jdg.crossborder.post_brexit",
    "priority": 171,
    "vat_rate": "0.00",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "EXPORT_SERVICES_UK_B2B",
    "vat_exemption": "",
    "place_of_supply": "GB",
    "reverse_charge": true,
    "_routing": "",
    "_routing_reason": "Usługi B2B do UK — reverse charge w UK",
    "_legal_basis": "Art. 28b VAT",
    "_warnings": ["USŁUGI B2B DO UK — miejsce świadczenia UK; faktura z adnotacją reverse charge."]
} {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    object.get(invoice, "direction", "") == "SALE"
    object.get(vendor, "country", "") == "GB"
    object.get(vendor, "is_b2b_buyer", false) == true
    object.get(invoice, "type", "") == "SERVICE"
}

# P172: B2C VAT registration threshold
else := {
    "matched": true,
    "rule_id": "jdg.crossborder.post_brexit.uk_vat_registration_b2c",
    "package": "jdg.crossborder.post_brexit",
    "priority": 172,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "procedure": "",
    "vat_exemption": "",
    "uk_vat_registration_required": exceeded,
    "uk_b2c_annual_turnover_gbp": turnover,
    "uk_vat_threshold_gbp": 90000,
    "_routing": uk_b2c_routing(exceeded),
    "_routing_reason": uk_b2c_reason(exceeded),
    "_legal_basis": "UK VAT Act 1994, Distance Selling Regulations",
    "_warnings": [sprintf("SPRZEDAŻ B2C DO UK — %.0f GBP rocznie. %s", [turnover, uk_b2c_action(exceeded)])]
} {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    profile := object.get(input, "jdg_entrepreneur", {})
    object.get(invoice, "direction", "") == "SALE"
    object.get(vendor, "country", "") == "GB"
    object.get(vendor, "is_b2c", false) == true
    turnover := object.get(profile, "uk_b2c_annual_turnover_gbp", 0)
    turnover > 0
    exceeded := uk_b2c_threshold_status(turnover)
}
