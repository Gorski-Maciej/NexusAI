# NexusAI JDG Policies — Gig Economy & Freelancer Edge Cases (P595b-P599b)
# Legacy metadata retained as ordinary comments; invalid YAML annotation removed.
# P595b rideshare VAT; P596b food delivery VAT; P597b platform commissions;
# P598b 8.5% transport lump sum; P599b mileage-log limitations.

package jdg.business.gig_economy

import data.jdg.helpers

# Parser-compatible helpers. Their outputs preserve the original branch values.
gig_rideshare_pkd(pkd) = true {
    {"49.32.Z", "49.39.Z"}[pkd]
} else = false
gig_gastronomy_pkd(pkd) = true {
    {"56.21.Z", "56.10.A", "56.29.Z", "56.30.Z"}[pkd]
} else = false
gig_platform_allowed(platform) = true {
    {"UBER", "BOLT", "GLOVO", "WOLT", "UBER_EATS", "DELIVEROO", "JUST_EAT", "PYSD"}[platform]
} else = false
gig_vehicle_pkd(pkd) = true {
    {"49.32.Z", "53.20.Z", "49.39.Z", "49.41.Z"}[pkd]
} else = false
gig_rideshare_vat_rate(is_payer) = "0.08" {
    is_payer == true
} else = "0.00"
gig_rideshare_exemption(is_payer) = "SUBJECT" {
    is_payer == false
} else = ""
gig_rideshare_warning(is_payer) = warning {
    is_payer == true
    warning := ["RIDESHARE (taxi/Uber/Bolt) — 8% VAT. Transport pasażerski krajowy."]
} else = ["RIDESHARE (taxi/Uber/Bolt) — zwolniony z VAT podmiotowo (obrót < 200k PLN). Po przekroczeniu limitu: 8% VAT + obowiązek kasy fiskalnej."]
gig_food_rate(is_gastronomy) = "0.08" {
    is_gastronomy == true
} else = "0.23"
gig_food_classification(is_gastronomy) = "GASTRONOMY_8PCT" {
    is_gastronomy == true
} else = "COURIER_23PCT"
gig_food_warning(is_gastronomy) = warning {
    is_gastronomy == true
    warning := ["FOOD DELIVERY — usługa gastronomiczna (8% VAT). Dostawa posiłków przygotowanych przez Ciebie = usługa gastronomiczna."]
} else = ["FOOD DELIVERY — usługa kurierska (23% VAT). Jeśli tylko dostarczasz jedzenie (nie przygotowujesz) = usługa kurierska."]
gig_platform_name(platform) = object.get({
    "UBER": "Uber",
    "BOLT": "Bolt",
    "GLOVO": "Glovo",
    "WOLT": "Wolt",
    "UBER_EATS": "Uber Eats",
    "DELIVEROO": "Deliveroo",
    "JUST_EAT": "Just Eat",
    "PYSD": "Pyszne.pl"
}, platform, "Platforma gig economy")
gig_transport_section(pkwiu) = section {
    section := to_number(substring(pkwiu, 0, 2))
}
gig_transport_pkwiu(pkwiu) = true {
    section := gig_transport_section(pkwiu)
    section >= 49
    section <= 53
} else = false

default decide := {
    "matched": false,
    "rule_id": "jdg.business.gig_economy.no_match",
    "package": "jdg.business.gig_economy",
    "priority": 599
}

# P595b: rideshare VAT classification
decide := {
    "matched": true, "rule_id": "jdg.business.gig_economy.rideshare_vat",
    "package": "jdg.business.gig_economy", "priority": 595,
    "vat_rate": vat_rate, "rounding_level": "position", "gtu_code": "",
    "procedure": "", "vat_exemption": vat_exemption,
    "transport_passenger": true, "rideshare_detected": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "", "business_status": "",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2, Art. 113 VAT", "_warnings": warnings
} {
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main", "")
    gig_rideshare_pkd(pkd_main)
    input.invoice.category_code == "RIDESHARE_SERVICE"
    is_vat_payer := object.get(input.jdg_entrepreneur, "is_vat_payer", false)
    vat_rate := gig_rideshare_vat_rate(is_vat_payer)
    vat_exemption := gig_rideshare_exemption(is_vat_payer)
    warnings := gig_rideshare_warning(is_vat_payer)
}

# P596b: food delivery VAT
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.food_delivery_vat",
    "package": "jdg.business.gig_economy", "priority": 596,
    "vat_rate": vat_rate, "rounding_level": "position", "gtu_code": "",
    "procedure": "", "vat_exemption": "", "food_delivery_detected": true,
    "delivery_classification": classification,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "", "business_status": "",
    "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 41 ust. 2 VAT",
    "_warnings": warnings
} {
    input.invoice.category_code == "FOOD_DELIVERY"
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main", "")
    is_gastronomy := gig_gastronomy_pkd(pkd_main)
    vat_rate := gig_food_rate(is_gastronomy)
    classification := gig_food_classification(is_gastronomy)
    warnings := gig_food_warning(is_gastronomy)
}

# P597b: platform commission import / reverse charge
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.platform_commission_import",
    "package": "jdg.business.gig_economy", "priority": 597,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "IMPORT_SERVICES_REVERSE_CHARGE", "vat_exemption": "",
    "platform_commission_import": true, "platform_name": platform_name,
    "platform_fee_pln": platform_fee, "reverse_charge_vat_due": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "kus_note": "prowizja platformy = KUP jako koszt uzyskania przychodu",
    "zus_social_base_type": "", "zus_health_rate": "", "business_status": "",
    "_routing": "", "_routing_reason": "Prowizja platformy gig — import usług (reverse charge VAT)",
    "_legal_basis": "Art. 28b, Art. 17 ust. 1 pkt 4 VAT", "_warnings": warnings
} {
    input.vendor.is_gig_platform == true
    platform_fee := object.get(input.invoice, "platform_fee_deducted", 0)
    platform_fee > 0
    platform_country := object.get(input.vendor, "country", "NL")
    platform_country != "PL"
    platform := object.get(input.invoice, "vendor_platform", "")
    gig_platform_allowed(platform)
    platform_name := gig_platform_name(platform)
    vat_amount := platform_fee * 0.23
    warnings := [sprintf("%s — prowizja %.2f PLN = import usług spoza PL. JDG rozlicza VAT w PL (reverse charge): VAT należny = VAT naliczony = %.2f PLN. Prowizja jest KUP!", [platform_name, platform_fee, vat_amount])]
}

# P598b: 8.5% lump sum for transport
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.lump_sum_transport",
    "package": "jdg.business.gig_economy", "priority": 598,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "", "vat_exemption": "",
    "pit_form": "LUMP_SUM", "pit_rate": "0.085", "pit_bracket": "", "pit_annual_return_type": "PIT-28",
    "lump_sum_rate_category": "8.5%_TRANSPORT_SERVICES",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "",
    "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 12 ust. 1 pkt 5 lit. a ustawy o ryczałcie",
    "_warnings": [sprintf("RYCZAŁT 8.5%% — usługi transportowe (PKWiU %s). Uwaga: ryczałt = podatek od przychodu (nie od dochodu). Brak możliwości odliczenia KUP!", [pkwiu_code])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    pkwiu_code := object.get(input.invoice, "pkwiu_code", "")
    gig_transport_pkwiu(pkwiu_code)
}

# P599b: missing mileage log
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.mileage_tracking",
    "package": "jdg.business.gig_economy", "priority": 599,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "partial", "kus_percent": 75, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "",
    "mileage_log_missing": true, "vat_deduction_percent": 50,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Brak ewidencji przebiegu pojazdu — ograniczenie KUP 75% i VAT 50%",
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT",
    "_warnings": ["BRAK EWIDENCJI PRZEBIEGU — pojazd używany w gig economy bez kilometrówki. KUP ograniczone do 75%, VAT do 50%. Prowadź ewidencję: data, trasa, cel, liczba km, podpis. Przy pełnej ewidencji: 100% KUP + 100% VAT."]
} {
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main", "")
    gig_vehicle_pkd(pkd_main)
    input.invoice.category_code == "CAR"
    object.get(input.jdg_entrepreneur, "has_mileage_log", true) == false
}
