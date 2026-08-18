# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — E-Learning & Digital Education (P590b-P594b)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: E-Learning Package — Kursy online, webinary, platformy edukacyjne
# description: |
#   Reguły dla JDG prowadzących działalność e-learningową:
#   P590b: VAT dla kursów online — zwolnienie tylko przy finansowaniu publicznym
#   P591b: Ryczałt 8.5% dla edukacji (PKWiU 85.xx)
#   P592b: Kursy dla studentów UE B2C — OSS
#   P593b: Kursy dla studentów non-EU B2C — NP w PL
#   P594b: Sprzedaż przez platformy (Udemy, Coursera) — podział przychodu
# architecture: Multi-Pass PAS 5 (ADR-001)
# legal_basis: Art. 43 ust. 1 pkt 26-29 VAT, Art. 28c VAT, Art. 12 ryczałt
# edge_cases:
#   - Komercyjne kursy online → 23% VAT (nie są zwolnione)
#   - Platformy zagraniczne → prowizja = import usług (reverse charge)
# package: jdg.pit.elearning
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit.elearning

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.elearning.no_match",
    "package": "jdg.pit.elearning", "priority": 599
}

# ══════ P590b: elearning_vat_exemption_check — VAT dla e-learningu ══════
decide := {
    "matched": true, "rule_id": "jdg.pit.elearning.vat_exemption_check",
    "package": "jdg.pit.elearning", "priority": 590,
    "vat_rate": vat_rate, "rounding_level": "position", "gtu_code": "",
    "procedure": "", "vat_exemption": vat_exemption,
    "elearning_vat_classification": classification,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 26-29 VAT",
    "_warnings": warnings
} {
    input.invoice.category_code in {"ELEARNING", "ONLINE_COURSE", "WEBINAR", "DIGITAL_EDUCATION"}
    is_public := object.get(input.invoice, "is_publicly_funded", false)
    vat_rate = "0.23" { is_public == false }
    vat_rate = "0.00" { is_public == true }
    vat_exemption = "OBJECT" { is_public == true }
    vat_exemption = "" { is_public == false }
    classification = "COMMERCIAL" { is_public == false }
    classification = "PUBLICLY_FUNDED_EXEMPT" { is_public == true }
    warnings = [
        "E-LEARNING KOMERCYJNY — 23% VAT. Zwolnienie z VAT (Art. 43 ust. 1 pkt 29) tylko gdy kurs finansowany ze środków publicznych. Faktura z 23% VAT."
    ] { is_public == false }
    warnings = [
        "E-LEARNING — zwolniony z VAT (finansowanie publiczne). Wymagane potwierdzenie finansowania ze środków publicznych."
    ] { is_public == true }
}

# ══════ P591b: elearning_lump_sum_rate_8_5 — Ryczałt 8.5% dla edukacji ══════
else := {
    "matched": true, "rule_id": "jdg.pit.elearning.lump_sum_rate_85",
    "package": "jdg.pit.elearning", "priority": 591,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "", "vat_exemption": "",
    "pit_form": "LUMP_SUM", "pit_rate": "0.085", "pit_bracket": "",
    "pit_annual_return_type": "PIT-28",
    "lump_sum_rate_category": "8.5%_EDUCATION",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ust. 1 pkt 5 lit. a ustawy o ryczałcie",
    "_warnings": [
        sprintf("RYCZAŁT 8.5%% — usługi edukacyjne (PKWiU %s). Przypomnienie: ryczałt = podatek od przychodu, brak KUP.", [pkwiu_code])
    ]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    pkwiu_code := object.get(input.invoice, "pkwiu_code", "")
    pkwiu_code in {"85.59", "85.42", "85.41", "85.51", "85.52", "85.53", "85.60"}
}

# ══════ P592b: elearning_foreign_students_vat_exemption — Kursy dla UE B2C ══════
else := {
    "matched": true, "rule_id": "jdg.pit.elearning.foreign_students_eu_vat",
    "package": "jdg.pit.elearning", "priority": 592,
    "vat_rate": "0.00", "rounding_level": "total", "gtu_code": "",
    "procedure": "OSS_ELIGIBLE", "vat_exemption": "",
    "place_of_supply": vendor_country,
    "oss_registration_required": oss_needed,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "E-learning B2C UE — VAT rozlicza konsument (OSS)",
    "_legal_basis": "Art. 28c ust. 1 VAT (usługi elektroniczne B2C UE)",
    "_warnings": warnings
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"ELEARNING", "ONLINE_COURSE", "WEBINAR"}
    vendor_country := input.vendor.country
    vendor_country in {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PT","RO","SK","SI","ES","SE"}
    vendor_country != "PL"
    input.vendor.is_b2c == true
    eu_b2c_annual := object.get(input.jdg_entrepreneur, "b2c_eu_annual_eur", 0)
    oss_needed := eu_b2c_annual > 10000
    warnings = [
        sprintf("E-LEARNING B2C DO UE (%s) — VAT rozlicza konsument. %s", [vendor_country, oss_info])
    ]
    oss_info = sprintf("OSS wymagane! Sprzedaż B2C UE %.0f EUR > 10 000 EUR. Zarejestruj się w OSS by rozliczać VAT w PL.", [eu_b2c_annual]) { oss_needed == true }
    oss_info = sprintf("Poniżej progu OSS 10 000 EUR (%.0f EUR). VAT rozliczany w kraju konsumenta.", [eu_b2c_annual]) { oss_needed == false }
}

# ══════ P593b: elearning_non_eu_students_zero_vat — Kursy dla non-EU B2C ══════
else := {
    "matched": true, "rule_id": "jdg.pit.elearning.non_eu_students_vat",
    "package": "jdg.pit.elearning", "priority": 593,
    "vat_rate": "0.00", "rounding_level": "total", "gtu_code": "",
    "procedure": "NP_NON_EU_B2C", "vat_exemption": "",
    "place_of_supply": vendor_country,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "E-learning B2C non-EU — NP w PL (VAT rozlicza konsument w swoim kraju)",
    "_legal_basis": "Art. 28c ust. 2 VAT",
    "_warnings": [
        sprintf("E-LEARNING B2C NON-EU (%s) — miejsce świadczenia = kraj konsumenta. Polski JDG NIE nalicza VAT (NP). Konsument rozlicza VAT w swoim kraju.", [vendor_country])
    ]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"ELEARNING", "ONLINE_COURSE", "WEBINAR"}
    vendor_country := input.vendor.country
    vendor_country == "NON_EU"
    input.vendor.is_b2c == true
}

# ══════ P594b: elearning_platform_revenue_split — Podział przychodu z platform ══════
else := {
    "matched": true, "rule_id": "jdg.pit.elearning.platform_revenue_split",
    "package": "jdg.pit.elearning", "priority": 594,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "PLATFORM_SPLIT", "vat_exemption": "",
    "platform_sale_detected": true, "platform_name": platform_name,
    "revenue_jdg_net": jdg_net, "platform_fee_amount": platform_fee,
    "import_services_vat_required": import_vat_needed,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "kus_note": "koszty prowizji platformy = KUP",
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "_routing": "",
    "_routing_reason": "Sprzedaż przez platformę e-learning — prowizja = import usług",
    "_legal_basis": "Art. 28b, Art. 17 ust. 1 pkt 4 VAT",
    "_warnings": warnings
} {
    input.invoice.is_platform_sale == true
    platform_fee := object.get(input.invoice, "platform_fee_deducted", 0)
    platform_fee > 0
    platform := object.get(input.invoice, "distribution_platform", "")
    platform in {"UDEMY", "COURSERA", "SKILLSHARE", "TEACHABLE", "THINKIFIC", "PODIA"}
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    jdg_net := amount_gross - platform_fee
    platform_country := object.get(input.vendor, "platform_country", "US")
    import_vat_needed := platform_country != "PL"

    platform_name = "Udemy" { platform == "UDEMY" }
    platform_name = "Coursera" { platform == "COURSERA" }
    platform_name = "Skillshare" { platform == "SKILLSHARE" }
    platform_name = "Teachable" { platform == "TEACHABLE" }
    platform_name = "Thinkific" { platform == "THINKIFIC" }
    platform_name = "Podia" { platform == "PODIA" }
    platform_name = "Platforma e-learningowa"

    warnings = [
        sprintf("%s — prowizja %.2f PLN = import usług (reverse charge VAT). Przychód JDG: %.2f PLN netto (kwota brutto - prowizja). Prowizja jest KUP dla JDG.", [platform_name, platform_fee, jdg_net])
    ] { import_vat_needed == true }
    warnings = [
        sprintf("%s — prowizja %.2f PLN. Przychód JDG: %.2f PLN netto.", [platform_name, platform_fee, jdg_net])
    ] { import_vat_needed == false }
}
