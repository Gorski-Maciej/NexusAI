# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Local Taxes: Podatek od nieruchomości (P1310-P1312)
# Doc 26: Podatki lokalne — nieruchomości firmowe, home office, DN-1
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Package — local_taxes/real_estate
# description: Podatek od nieruchomości firmowych — home office, DN-1
# architecture: Multi-Pass (ADR-001)
# package: jdg.local_taxes.real_estate
# doc_source: Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md §VIII
#
package jdg.local_taxes.real_estate

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.local_taxes.real_estate.no_match",
    "package": "jdg.local_taxes.real_estate",
    "priority": 1319
}

# ══════ P1310: real_estate_commercial_rate — Wyższa stawka za powierzchnię firmową ══════
# Cel biznesowy: Część domu/mieszkania wykorzystywana na JDG → wyższa stawka
# podatku od nieruchomości (~33,10 PLN/m² zamiast ~1,15 PLN/m² mieszkalnego).
# Obowiązek deklaracji DN-1 w ciągu 14 dni.
decide := {
    "matched": true,
    "rule_id": "jdg.local_taxes.real_estate.commercial_rate",
    "package": "jdg.local_taxes.real_estate",
    "priority": 1310,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "vat_exemption": "",
    "procedure": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "local_tax_type": "REAL_ESTATE",
    "local_tax_land_rate": 1.15,
    "local_tax_building_rate": 33.10,
    "real_estate_commercial_sqm": office_sqm,
    "real_estate_annual_tax": annual_tax,
    "dn1_filing_required": true,
    "dn1_filing_deadline_days": 14,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Powierzchnia firmowa — obowiązek DN-1 i wyższa stawka podatku",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234), Art. 2-7 + uchwała gminy",
    "_warnings": [sprintf("PODATEK OD NIERUCHOMOŚCI FIRMOWEJ — %.2f m² × %.2f PLN/m² = %.2f PLN/rok. Część mieszkalna: %.2f m² × %.2f PLN/m². Złóż DN-1 w ciągu 14 dni!", [office_sqm, commercial_rate, annual_tax, residential_sqm, 1.15])]
} {
    office_sqm := object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0)
    office_sqm > 0

    # Stawka komercyjna z thresholds (domyślnie 33.10 PLN/m²) lub z uchwały gminy
    commercial_rate := object.get(
        object.get(object.get(data.thresholds, "jdg", {}), "local_taxes", {}),
        "real_estate_commercial_rate", 33.10
    )

    total_sqm := object.get(input.jdg_entrepreneur, "total_property_sqm", 0)
    residential_sqm = total_sqm - office_sqm { total_sqm > office_sqm }
    residential_sqm = 0 { total_sqm <= office_sqm }

    annual_tax = office_sqm * commercial_rate + residential_sqm * 1.15

    # DN-1 wymagane jeśli nie złożono
    dn1_filed := object.get(input.jdg_entrepreneur, "dn1_filed", false)
    dn1_filed == false
}

# ══════ P1312: real_estate_tax_return_deadline — Termin DN-1 przekroczony ══════
# Cel biznesowy: DN-1 musi być złożone w ciągu 14 dni od rozpoczęcia
# wykorzystywania nieruchomości na cele firmowe. Alert po terminie.
else := {
    "matched": true,
    "rule_id": "jdg.local_taxes.real_estate.deadline_overdue",
    "package": "jdg.local_taxes.real_estate",
    "priority": 1312,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "vat_exemption": "",
    "procedure": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "local_tax_type": "REAL_ESTATE",
    "dn1_overdue": true,
    "dn1_days_overdue": days_overdue,
    "dn1_filing_required_immediately": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "DN-1 niezłożona w terminie 14 dni",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234), Art. 6 ust. 6-7",
    "_warnings": [sprintf("DN-1 NIEZŁOŻONA W TERMINIE — minęło %d dni od rozpoczęcia wykorzystywania %.2f m² na cele firmowe. Złóż DN-1 NATYCHMIAST! Konsekwencje: podatek od nieruchomości może być naliczony wstecz z odsetkami.", [days_overdue, office_sqm])]
} {
    office_sqm := object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0)
    office_sqm > 0

    dn1_filed := object.get(input.jdg_entrepreneur, "dn1_filed", false)
    dn1_filed == false

    firm_use_start_date := object.get(
        input.jdg_entrepreneur, "home_office_start_date", ""
    )
    firm_use_start_date != ""

    # Oblicz dni od rozpoczęcia użytkowania firmowego
    days_since_start := object.get(input.jdg_entrepreneur, "days_since_home_office_start", 0)
    days_since_start > 14
    days_overdue = days_since_start - 14
}
