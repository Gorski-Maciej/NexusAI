# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — VAT: Miejsce świadczenia (Art. 28a-28o VAT)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Place of Supply — Art. 28a-28o Implementation (v7.0 R7)
# description: |
#   PAS 4d Multi-Pass. First-Match-Wins else-chain. Określa miejsce świadczenia
#   wg ustawy o VAT Art. 28a-28o:
#   - Art. 28b: B2B usługi → siedziba nabywcy
#   - Art. 28c: B2C usługi → siedziba usługodawcy (z wyjątkami)
#   - Art. 28e: Nieruchomości → miejsce położenia
#   - Art. 28l: E-usługi B2C → siedziba konsumenta
#   - Art. 28f-28g: Transport → miejsce odcinka
#   - Art. 28h-28i: Kultura/sport/edukacja → miejsce konsumpcji
#   - Art. 28l-28o: Pozostałe usługi szczególne
# architecture: Multi-Pass PAS 4d (ADR-001)
# legal_basis: Art. 28a-28o VAT, Rozp. 282/2011 UE
# package: jdg.vat.place_of_supply
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.place_of_supply

import data.jdg.helpers

# ── Default ──────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.place_of_supply.no_match",
    "package": "jdg.vat.place_of_supply",
    "priority": 400
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-1: Art. 28b — B2B usługi → miejsce = siedziba nabywcy (reverse charge)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.b2b_services_art28b",
    "package": "jdg.vat.place_of_supply", "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_B2B",
    "vat_exemption": "", "place_of_supply": buyer_country,
    "place_of_supply_rule": "Art. 28b VAT",
    "place_of_supply_determined": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_border_vat_implication": "IMPORT_OF_SERVICES_BY_BUYER",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28b VAT",
    "_warnings": [sprintf("B2B — miejsce świadczenia = siedziba nabywcy (%s). Nabywca rozlicza VAT (reverse charge). JPK_V7: K_43 (UE) / K_44 (poza UE).", [buyer_country])]
} {
    input.invoice.expense_type in {"SERVICE", "CONSULTING", "IT_SERVICES", "SOFTWARE_LICENSE", "SAAS"}
    input.vendor.is_vat_taxable_person == true
    input.vendor.country != "PL"
    buyer_country := input.vendor.country
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-2: Art. 28c — B2C usługi → miejsce = siedziba usługodawcy (PL)
# Wyjątki: e-usługi (28k), nieruchomości (28e), transport (28f)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.b2c_services_art28c",
    "package": "jdg.vat.place_of_supply", "priority": 2,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_B2C",
    "vat_exemption": "", "place_of_supply": "PL",
    "place_of_supply_rule": "Art. 28c VAT",
    "place_of_supply_determined": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_border_vat_implication": "POLISH_VAT_APPLIES",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28c VAT",
    "_warnings": ["B2C — miejsce świadczenia = siedziba usługodawcy (PL). Polski VAT należny."]
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "PL"
    input.vendor.is_b2c == true
    input.invoice.expense_type in {"SERVICE", "CONSULTING", "REPAIR", "RENTAL"}
    # Wykluczenia: e-usługi B2C (Art. 28k), nieruchomości (28e), transport (28f-28g)
    not input.invoice.category_code in {"E_SERVICES", "REAL_ESTATE", "TRANSPORT_PASSENGER", "TRANSPORT_FREIGHT"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-3: Art. 28e — Nieruchomości → miejsce = położenie nieruchomości
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.real_estate_art28e",
    "package": "jdg.vat.place_of_supply", "priority": 3,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_REAL_ESTATE",
    "vat_exemption": "", "place_of_supply": property_country,
    "place_of_supply_rule": "Art. 28e VAT",
    "place_of_supply_determined": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_border_vat_implication": "VAT_IN_PROPERTY_COUNTRY",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28e VAT",
    "_warnings": [sprintf("NIERUCHOMOŚĆ — miejsce świadczenia = kraj położenia (%s). VAT wg przepisów kraju położenia nieruchomości. Może wymagać rejestracji VAT za granicą!", [property_country])]
} {
    input.invoice.category_code in {"REAL_ESTATE", "BUILDING_SALE", "LAND_LEASE", "PROPERTY_MANAGEMENT", "CONSTRUCTION_RESIDENTIAL"}
    property_country := object.get(input.invoice, "property_country", "PL")
    property_country != "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-4: Art. 28l — E-usługi B2C → miejsce = siedziba konsumenta
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.e_services_b2c_art28l",
    "package": "jdg.vat.place_of_supply", "priority": 4,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_E_SERVICES_B2C",
    "vat_exemption": "", "place_of_supply": consumer_country,
    "place_of_supply_rule": "Art. 28l VAT",
    "place_of_supply_determined": true,
    "oss_ioss_applicable": oss_applicable,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_border_vat_implication": "OSS_OR_FOREIGN_VAT_REGISTRATION",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28l VAT (e-usługi B2C — miejsce konsumenta)",
    "_warnings": [sprintf("E-USŁUGI B2C — miejsce świadczenia = siedziba konsumenta (%s). Rozlicz przez OSS (unia) lub zarejestruj VAT w kraju konsumenta!", [consumer_country])]
} {
    input.invoice.category_code in {"E_SERVICES", "DIGITAL_CONTENT", "SOFTWARE_DOWNLOAD", "ONLINE_COURSE", "STREAMING"}
    input.vendor.is_b2c == true
    input.invoice.direction == "SALE"
    consumer_country := object.get(input.invoice, "consumer_country", "PL")
    consumer_country != "PL"
    oss_applicable = true { consumer_country in eu_countries }
    oss_applicable = false { not consumer_country in eu_countries }
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-5: Art. 28f-28g — Transport → miejsce = trasa (odcinek)
# Transport pasażerski: proporcjonalnie do odcinka trasy
# Transport towarów B2B: siedziba nabywcy (Art. 28b)
# Transport towarów B2C: miejsce rozpoczęcia transportu
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.transport_art28f_28g",
    "package": "jdg.vat.place_of_supply", "priority": 5,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_TRANSPORT",
    "vat_exemption": "", "place_of_supply": transport_pos,
    "place_of_supply_rule": transport_article,
    "place_of_supply_determined": true,
    "transport_route": transport_route,
    "transport_vat_proportion_pl": vat_proportion_pl,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_border_vat_implication": cross_border_note,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28f-28g VAT",
    "_warnings": [sprintf("TRANSPORT — %s. Trasa: %s. VAT PL proporcjonalnie do odcinka w PL: %.0f%%.", [transport_article, transport_route, vat_proportion_pl * 100])]
} {
    input.invoice.category_code in {"TRANSPORT_PASSENGER", "TRANSPORT_FREIGHT", "COURIER", "LOGISTICS"}
    input.invoice.direction == "SALE"
    route_start := object.get(input.invoice, "transport_route_from", "PL")
    route_end := object.get(input.invoice, "transport_route_to", "PL")
    route_in_pl := object.get(input.invoice, "transport_km_in_pl", 0)
    route_total := object.get(input.invoice, "transport_km_total", 0)

    transport_route := concat("", [route_start, " → ", route_end])

    # Określenie artykułu i miejsca świadczenia
    is_passenger := input.invoice.category_code == "TRANSPORT_PASSENGER"
    is_b2b := input.vendor.is_vat_taxable_person == true

    transport_article = "Art. 28f VAT (transport towarów)" { not is_passenger }
    transport_article = "Art. 28g VAT (transport osób)" { is_passenger }

    transport_pos = "PROPORTIONAL" { route_in_pl > 0; route_total > 0 }
    transport_pos = "PL" { route_start == "PL"; route_end == "PL" }
    transport_pos = route_start { route_in_pl == 0 }

    vat_proportion_pl = 1.0 { route_in_pl == 0 }
    vat_proportion_pl = route_in_pl / route_total { route_total > 0; route_in_pl > 0 }
    vat_proportion_pl = 1.0 { route_total == 0 }

    cross_border_note = "VAT PL od odcinka w PL — VAT w kraju docelowym od pozostałej części" { route_in_pl > 0; route_start != route_end }
    cross_border_note = "VAT PL w całości" { route_start == "PL"; route_end == "PL" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-6: Art. 28i — Kultura/sport/edukacja → miejsce = gdzie się odbywa
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.culture_event_art28i",
    "package": "jdg.vat.place_of_supply", "priority": 6,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_EVENT",
    "vat_exemption": "", "place_of_supply": event_country,
    "place_of_supply_rule": "Art. 28i VAT",
    "place_of_supply_determined": true,
    "event_location": event_location,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_border_vat_implication": "VAT_IN_EVENT_COUNTRY",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28i VAT",
    "_warnings": [sprintf("EVENT — miejsce świadczenia = miejsce odbywania się (%s). VAT wg przepisów kraju wydarzenia.", [event_country])]
} {
    input.invoice.category_code in {"CULTURE", "SPORT", "CONFERENCE", "EXHIBITION", "CONCERT", "TRAINING_EVENT"}
    event_country := object.get(input.invoice, "event_country", "PL")
    event_location := object.get(input.invoice, "event_city", "") 
    event_country != "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-7: Art. 28j — Usługi restauracyjne i cateringowe
# Miejsce = fizyczne miejsce świadczenia (nie siedziba)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.restaurant_catering_art28j",
    "package": "jdg.vat.place_of_supply", "priority": 7,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_RESTAURANT",
    "vat_exemption": "", "place_of_supply": service_country,
    "place_of_supply_rule": "Art. 28j VAT",
    "place_of_supply_determined": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28j VAT",
    "_warnings": [sprintf("RESTAURACJA/CATERING — miejsce świadczenia = miejsce fizycznego wykonania (%s). Wyjątek: na pokładach statków/pociągów = miejsce rozpoczęcia.\n", [service_country])]
} {
    input.invoice.category_code in {"RESTAURANT", "CATERING", "RESTAURANT_MEALS", "GASTRONOMY"}
    service_country := object.get(input.invoice, "service_location_country", "PL")
    service_country != "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-8: Art. 28k — Wynajem krótkoterminowy środków transportu
# Miejsce = miejsce wydania środka transportu
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.vehicle_rental_art28k",
    "package": "jdg.vat.place_of_supply", "priority": 8,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_VEHICLE_RENTAL",
    "vat_exemption": "", "place_of_supply": pickup_country,
    "place_of_supply_rule": "Art. 28k VAT",
    "place_of_supply_determined": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28k VAT",
    "_warnings": [sprintf("WYNAJEM POJAZDU — miejsce świadczenia = miejsce wydania (%s). Krótkoterminowy ≤ 30 dni (pojazdy) / ≤ 90 dni (łodzie).", [pickup_country])]
} {
    input.invoice.category_code in {"CAR_RENTAL", "VEHICLE_RENTAL", "BOAT_RENTAL"}
    input.invoice.is_short_term_rental == true
    pickup_country := object.get(input.invoice, "pickup_country", "PL")
    pickup_country != "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-9: WDT 0% — Wewnątrzwspólnotowa Dostawa Towarów
# Miejsce = kraj przeznaczenia w UE, stawka 0% w PL przy spełnieniu warunków
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.wdt_zero_rate_art13_41",
    "package": "jdg.vat.place_of_supply", "priority": 9,
    "vat_rate": "0.00", "rounding_level": "position", "gtu_code": "", "procedure": "WDT",
    "vat_exemption": "0PCT_WDT", "place_of_supply": buyer_country,
    "place_of_supply_rule": "Art. 13, 41 ust. 3-4 VAT",
    "place_of_supply_determined": true,
    "wdt_documentation_required": true,
    "vat_ue_summary_required": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 13 VAT, Art. 41 ust. 3-4 VAT",
    "_warnings": [sprintf("WDT 0%% — dostawa do %s. WYMAGANE: (1) VAT-UE nabywcy, (2) dokumenty potwierdzające wywóz (CMR, list przewozowy), (3) faktura z adnotacją 'odwrotne obciążenie'. VAT-UE w terminie 15. dnia następnego miesiąca.", [buyer_country])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"GOODS", "MERCHANDISE", "PRODUCTS", "RAW_MATERIALS"}
    buyer_country := object.get(input.invoice, "buyer_country", "")
    buyer_country in eu_countries
    buyer_country != "PL"
    input.jdg_entrepreneur.is_vat_eu_registered == true
    input.invoice.has_transport_documents == true
    input.invoice.buyer_vat_eu_number != ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-10: Export 0% — Eksport towarów poza UE
# Miejsce = kraj przeznaczenia poza UE, stawka 0% w PL przy udokumentowanym wywozie
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.export_zero_rate_art2pkt8_41",
    "package": "jdg.vat.place_of_supply", "priority": 10,
    "vat_rate": "0.00", "rounding_level": "position", "gtu_code": "", "procedure": "EXPORT",
    "vat_exemption": "0PCT_EXPORT", "place_of_supply": destination_country,
    "place_of_supply_rule": "Art. 2 pkt 8, Art. 41 ust. 4-11 VAT",
    "place_of_supply_determined": true,
    "export_customs_required": true,
    "export_ie599_required": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 8 VAT, Art. 41 ust. 4-11 VAT",
    "_warnings": [sprintf("EKSPORT 0%% — wywóz do %s. WYMAGANE: (1) dokument celny IE-599 / komunikat IE-529 potwierdzający wywóz poza UE, (2) termin na uzyskanie dokumentu: do upływu terminu złożenia deklaracji VAT. Bez dokumentu = stawka 23%%!", [destination_country])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"GOODS", "MERCHANDISE", "PRODUCTS"}
    destination_country := object.get(input.invoice, "buyer_country", "")
    not destination_country in eu_countries
    destination_country != "PL"
    input.invoice.has_customs_document == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# POS-11: Art. 28d — Usługi pośrednictwa B2C
# Miejsce świadczenia = miejsce dostawy towaru głównego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.place_of_supply.intermediation_b2c_art28d",
    "package": "jdg.vat.place_of_supply", "priority": 11,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PLACE_OF_SUPPLY_INTERMEDIATION",
    "vat_exemption": "", "place_of_supply": goods_delivery_country,
    "place_of_supply_rule": "Art. 28d VAT",
    "place_of_supply_determined": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28d VAT",
    "_warnings": [sprintf("POŚREDNICTWO B2C — miejsce = miejsce dostawy towaru głównego (%s).", [goods_delivery_country])]
} {
    input.invoice.category_code == "INTERMEDIATION"
    input.vendor.is_b2c == true
    goods_delivery_country := object.get(input.invoice, "goods_delivery_country", "PL")
    goods_delivery_country != "PL"
}

# ── EU countries list ──────────────────────────────────────────────────────────
eu_countries := {
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
}
