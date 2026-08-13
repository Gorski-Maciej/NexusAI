# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Local Taxes: Podatek od środków transportowych (P1320)
# Doc 26: Podatki lokalne — transport, pojazdy ciężarowe >3.5t
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Package — local_taxes/transport
# description: Podatek od środków transportowych dla JDG posiadających pojazdy >3.5t
# architecture: Multi-Pass (ADR-001)
# package: jdg.local_taxes.transport
# doc_source: Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md §VIII
#
package jdg.local_taxes.transport

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.local_taxes.transport.no_match",
    "package": "jdg.local_taxes.transport",
    "priority": 1329
}

# ══════ P1320: transport_tax_applicable — Podatek od środków transportowych ══════
# Cel biznesowy: JDG posiadające pojazdy ciężarowe >3.5t, ciągniki siodłowe,
# autobusy → obowiązek podatku od środków transportowych. Deklaracja DT-1.
decide := {
    "matched": true,
    "rule_id": "jdg.local_taxes.transport.tax_applicable",
    "package": "jdg.local_taxes.transport",
    "priority": 1320,
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
    "local_tax_type": "TRANSPORT",
    "transport_tax_applicable": true,
    "vehicle_type": vehicle_type,
    "vehicle_weight_kg": vehicle_weight,
    "max_payload_kg": max_payload,
    "transport_tax_declaration": "DT-1",
    "transport_tax_due_annually": true,
    "transport_tax_deadline": "do_15_lutego_za_dany_rok",
    "valid_from": "2002-01-01", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Pojazd ciężarowy >3.5t — obowiązek podatku od środków transportowych",
    "_legal_basis": "Ustawa o podatkach i opłatach lokalnych, Rozdział 3 (Art. 8-14)",
    "_warnings": [sprintf("PODATEK OD ŚRODKÓW TRANSPORTOWYCH — pojazd %s, DMC %.0f kg, ładowność %.0f kg. Obowiązek złożenia DT-1 do 15 lutego (za dany rok) lub w ciągu 14 dni od nabycia. Stawka zależy od DMC i rodzaju pojazdu — sprawdź uchwałę rady gminy.", [vehicle_type, vehicle_weight, max_payload])]
} {
    # Pojazd ciężarowy, autobus lub ciągnik siodłowy
    category := object.get(input.invoice, "category_code", "")

    is_heavy_vehicle = true {
        category in {"TRUCK", "BUS", "TRACTOR_UNIT", "VEHICLE"}
    }

    is_heavy_vehicle == true

    vehicle_weight := object.get(input.invoice, "vehicle_dmc", 0)

    # Próg DMC > 3.5t z thresholds
    transport_tax_min_weight := object.get(
        object.get(object.get(data.thresholds, "jdg", {}), "limits", {}),
        "transport_tax_min_weight_kg", 3500
    )
    vehicle_weight > transport_tax_min_weight

    max_payload := object.get(input.invoice, "vehicle_max_payload_kg", 0)

    vehicle_type = "CIĘŻAROWY" { category == "TRUCK" }
    vehicle_type = "AUTOBUS" { category == "BUS" }
    vehicle_type = "CIĄGNIK_SIODŁOWY" { category == "TRACTOR_UNIT" }
    vehicle_type = "POJAZD_CIEZAROWY" { category == "VEHICLE" }
}
