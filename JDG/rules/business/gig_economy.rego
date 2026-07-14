# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Gig Economy & Freelancer Edge Cases (P595b-P599b)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Gig Economy Package — Rideshare, food delivery, platform work
# description: |
#   Reguły dla JDG w gig economy (Uber/Bolt/Glovo/Wolt):
#   P595b: VAT dla rideshare — 8% transport pasażerski lub zwolnienie
#   P596b: VAT dla food delivery — 8% gastronomia lub 23% kurier
#   P597b: Prowizje platform gig — import usług (reverse charge)
#   P598b: Ryczałt 8.5% dla transportu (PKWiU 49-53)
#   P599b: Ewidencja przebiegu pojazdu — 75% KUP / 50% VAT bez kilometrówki
# architecture: Multi-Pass PAS 5/8 (ADR-001)
# legal_basis: Art. 41 ust. 2, Art. 113 VAT, Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT
# edge_cases:
#   - P595b: rideshare może być zwolniony podmiotowo jeśli obrót < 200k
#   - P599b: bez ewidencji przebiegu → ograniczenie KUP do 75% i VAT do 50%
# package: jdg.business.gig_economy
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.business.gig_economy

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.business.gig_economy.no_match",
    "package": "jdg.business.gig_economy", "priority": 599
}

# ══════ P595b: gig_economy_rideshare_vat_classification — VAT rideshare ══════
decide := {
    "matched": true, "rule_id": "jdg.business.gig_economy.rideshare_vat",
    "package": "jdg.business.gig_economy", "priority": 595,
    "vat_rate": vat_rate, "rounding_level": "position", "gtu_code": "",
    "procedure": "", "vat_exemption": vat_exemption,
    "transport_passenger": true, "rideshare_detected": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2, Art. 113 VAT",
    "_warnings": warnings
} {
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main", "")
    pkd_main in {"49.32.Z", "49.39.Z"}
    input.invoice.category_code == "RIDESHARE_SERVICE"

    is_vat_payer := object.get(input.jdg_entrepreneur, "is_vat_payer", false)
    vat_rate = "0.08" { is_vat_payer == true }
    vat_rate = "0.00" { is_vat_payer == false }
    vat_exemption = "SUBJECT" { is_vat_payer == false }
    vat_exemption = "" { is_vat_payer == true }

    warnings = [
        "RIDESHARE (taxi/Uber/Bolt) — 8% VAT. Transport pasażerski krajowy."
    ] { is_vat_payer == true }
    warnings = [
        "RIDESHARE (taxi/Uber/Bolt) — zwolniony z VAT podmiotowo (obrót < 200k PLN). Po przekroczeniu limitu: 8% VAT + obowiązek kasy fiskalnej."
    ] { is_vat_payer == false }
}

# ══════ P596b: gig_economy_food_delivery_vat — VAT food delivery ══════
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.food_delivery_vat",
    "package": "jdg.business.gig_economy", "priority": 596,
    "vat_rate": vat_rate, "rounding_level": "position", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "food_delivery_detected": true, "delivery_classification": classification,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2 VAT",
    "_warnings": warnings
} {
    input.invoice.category_code == "FOOD_DELIVERY"
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main", "")
    is_gastronomy := pkd_main in {"56.21.Z", "56.10.A", "56.29.Z", "56.30.Z"}

    vat_rate = "0.08" { is_gastronomy == true }
    vat_rate = "0.23" { is_gastronomy == false }
    classification = "GASTRONOMY_8PCT" { is_gastronomy == true }
    classification = "COURIER_23PCT" { is_gastronomy == false }

    warnings = [
        "FOOD DELIVERY — usługa gastronomiczna (8% VAT). Dostawa posiłków przygotowanych przez Ciebie = usługa gastronomiczna."
    ] { is_gastronomy == true }
    warnings = [
        "FOOD DELIVERY — usługa kurierska (23% VAT). Jeśli tylko dostarczasz jedzenie (nie przygotowujesz) = usługa kurierska."
    ] { is_gastronomy == false }
}

# ══════ P597b: gig_economy_platform_commission_import — Prowizje platform ══════
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
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "Prowizja platformy gig — import usług (reverse charge VAT)",
    "_legal_basis": "Art. 28b, Art. 17 ust. 1 pkt 4 VAT",
    "_warnings": [
        sprintf("%s — prowizja %.2f PLN = import usług spoza PL. JDG rozlicza VAT w PL (reverse charge): VAT należny = VAT naliczony = %.2f PLN. Prowizja jest KUP!", [platform_name, platform_fee, vat_amount])
    ]
} {
    input.vendor.is_gig_platform == true
    platform_fee := object.get(input.invoice, "platform_fee_deducted", 0)
    platform_fee > 0
    platform_country := object.get(input.vendor, "country", "NL")
    platform_country != "PL"

    platform := object.get(input.invoice, "vendor_platform", "")
    platform in {"UBER", "BOLT", "GLOVO", "WOLT", "UBER_EATS", "DELIVEROO", "JUST_EAT", "PYSD"}
    platform_name = "Uber" { platform == "UBER" }
    platform_name = "Bolt" { platform == "BOLT" }
    platform_name = "Glovo" { platform == "GLOVO" }
    platform_name = "Wolt" { platform == "WOLT" }
    platform_name = "Uber Eats" { platform == "UBER_EATS" }
    platform_name = "Deliveroo" { platform == "DELIVEROO" }
    platform_name = "Just Eat" { platform == "JUST_EAT" }
    platform_name = "Pyszne.pl" { platform == "PYSD" }
    platform_name = "Platforma gig economy"
    vat_amount := platform_fee * 0.23
}

# ══════ P598b: gig_economy_lump_sum_rate_8_5_transport — Ryczałt 8.5% transport ══════
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.lump_sum_transport",
    "package": "jdg.business.gig_economy", "priority": 598,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "LUMP_SUM", "pit_rate": "0.085", "pit_bracket": "",
    "pit_annual_return_type": "PIT-28",
    "lump_sum_rate_category": "8.5%_TRANSPORT_SERVICES",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ust. 1 pkt 5 lit. a ustawy o ryczałcie",
    "_warnings": [
        sprintf("RYCZAŁT 8.5%% — usługi transportowe (PKWiU %s). Uwaga: ryczałt = podatek od przychodu (nie od dochodu). Brak możliwości odliczenia KUP!", [pkwiu_code])
    ]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    pkwiu_code := object.get(input.invoice, "pkwiu_code", "")
    # PKWiU 49-53: transport i gospodarka magazynowa
    section_code := substring(pkwiu_code, 0, 2)
    to_number(section_code) >= 49
    to_number(section_code) <= 53
}

# ══════ P599b: gig_economy_mileage_tracking_obligation — Ewidencja km ══════
else := {
    "matched": true, "rule_id": "jdg.business.gig_economy.mileage_tracking",
    "package": "jdg.business.gig_economy", "priority": 599,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "partial", "kus_percent": 75,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "mileage_log_missing": true,
    "vat_deduction_percent": 50,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Brak ewidencji przebiegu pojazdu — ograniczenie KUP 75% i VAT 50%",
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT",
    "_warnings": [
        "BRAK EWIDENCJI PRZEBIEGU — pojazd używany w gig economy bez kilometrówki. KUP ograniczone do 75%, VAT do 50%. Prowadź ewidencję: data, trasa, cel, liczba km, podpis. Przy pełnej ewidencji: 100% KUP + 100% VAT."
    ]
} {
    pkd_main := object.get(input.jdg_entrepreneur, "pkd_main", "")
    pkd_main in {"49.32.Z", "53.20.Z", "49.39.Z", "49.41.Z"}
    input.invoice.category_code == "CAR"
    object.get(input.jdg_entrepreneur, "has_mileage_log", true) == false
}
