# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Micro Layer — Miejsce świadczenia usług (Art. 28d-28o VAT)
# Generated: 2026-07-28
# Package: jdg.micro.vat.place_of_supply
# Legal coverage: Art. 28d (B2C general), 28e (nieruchomości), 28f-g (transport),
#   28h-i (kultura/eventy), 28k (e-usługi), 28l (restauracje), 28m (wynajem),
#   28n (pośrednictwo), 28o (B2C szczególne)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat.place_of_supply

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.place_of_supply.no_match",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 999999,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28d — B2C usługi — zasada ogólna (siedziba usługodawcy)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M01: B2C general rule — miejsce siedziby usługodawcy
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m01",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "B2C — miejsce świadczenia = siedziba usługodawcy (PL)",
    "_legal_basis": "Art. 28d ust. 1 VAT",
    "_warnings": ["[MICRO POS] B2C ogólne — VAT PL jeśli usługodawca w PL"]
} {
    object.get(input.invoice, "customer_type", "") == "B2C"
    object.get(input.jdg_entrepreneur, "country", "") == "PL"
    object.get(input.invoice, "pos_special_rule", false) == false
}

# POS-M02: B2C — nabywca spoza UE → nie podlega VAT PL
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m02",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28002,
    "vat_rate": "NP",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "B2C spoza UE — NP (nie podlega VAT PL)",
    "_legal_basis": "Art. 28d ust. 2 VAT",
    "_warnings": ["[MICRO POS] B2C nabywca spoza UE — NP w PL, VAT w kraju nabywcy"]
} {
    object.get(input.invoice, "customer_type", "") == "B2C"
    object.get(input.invoice, "buyer_country", "PL") != "PL"
    not eu_country(input.invoice.buyer_country)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28e — Usługi związane z nieruchomościami                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M03: Nieruchomości — miejsce położenia nieruchomości
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m03",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28003,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_09",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Usługi na nieruchomości — VAT w kraju nieruchomości",
    "_legal_basis": "Art. 28e VAT",
    "_warnings": ["[MICRO POS] Nieruchomość — VAT wg miejsca położenia nieruchomości"]
} {
    object.get(input.invoice, "service_category", "") == "REAL_ESTATE"
    object.get(input.invoice, "property_country", "") != ""
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28f-28g — Transport                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M04: Transport towarów B2C — miejsce rozpoczęcia
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m04",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28004,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_10",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Transport towarów B2C — VAT w miejscu rozpoczęcia",
    "_legal_basis": "Art. 28f ust. 1 VAT",
    "_warnings": ["[MICRO POS] Transport B2C — VAT PL jeśli transport zaczyna się w PL"]
} {
    object.get(input.invoice, "service_category", "") == "TRANSPORT_GOODS"
    object.get(input.invoice, "customer_type", "") == "B2C"
    object.get(input.invoice, "transport_start_country", "") == "PL"
}

# POS-M05: Transport pasażerski B2C — proporcjonalnie do trasy
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m05",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28005,
    "vat_rate": "0.08",
    "rounding_level": "position",
    "gtu_code": "GTU_10",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Transport pasażerski — proporcjonalnie do trasy w PL",
    "_legal_basis": "Art. 28g VAT",
    "_warnings": ["[MICRO POS] Transport pasażerski — VAT proporcjonalnie do km w PL"]
} {
    object.get(input.invoice, "service_category", "") == "TRANSPORT_PASSENGER"
    object.get(input.invoice, "route_km_pl", 0) > 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28h-28i — Kultura, sport, eventy                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M06: Eventy kulturalne/sportowe — miejsce fizycznego wykonania
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m06",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28006,
    "vat_rate": "0.08",
    "rounding_level": "position",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Event kulturalny/sportowy — VAT w miejscu wydarzenia",
    "_legal_basis": "Art. 28h VAT",
    "_warnings": ["[MICRO POS] Event — VAT w kraju gdzie odbywa się wydarzenie"]
} {
    object.get(input.invoice, "service_category", "") == "CULTURAL_EVENT"
    object.get(input.invoice, "event_country", "") == "PL"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28k — E-usługi B2C (MOSS/OSS)                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M07: E-usługi B2C — miejsce konsumenta
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m07",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28007,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_12",
    "micro_rule_active": true,
    "valid_from": "2015-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "E-usługi B2C — VAT w kraju konsumenta (MOSS/OSS)",
    "_legal_basis": "Art. 28k VAT",
    "_warnings": ["[MICRO POS] E-usługi B2C — VAT kraju konsumenta, rozlicz przez OSS"]
} {
    object.get(input.invoice, "service_category", "") == "E_SERVICES"
    object.get(input.invoice, "customer_type", "") == "B2C"
    object.get(input.invoice, "buyer_country", "") != "PL"
    object.get(input.invoice, "oss_registered", false) == true
}

# POS-M08: E-usługi B2C PL — VAT PL
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m08",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28008,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_12",
    "micro_rule_active": true,
    "valid_from": "2015-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "E-usługi B2C PL — VAT PL",
    "_legal_basis": "Art. 28k VAT",
    "_warnings": ["[MICRO POS] E-usługi B2C — konsument w PL → VAT PL 23%"]
} {
    object.get(input.invoice, "service_category", "") == "E_SERVICES"
    object.get(input.invoice, "customer_type", "") == "B2C"
    object.get(input.invoice, "buyer_country", "") == "PL"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28l — Restauracje i catering                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M09: Restauracje — miejsce fizycznego świadczenia
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m09",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28009,
    "vat_rate": "0.08",
    "rounding_level": "position",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Restauracja/catering — VAT w miejscu świadczenia",
    "_legal_basis": "Art. 28l VAT",
    "_warnings": ["[MICRO POS] Gastronomia — VAT w kraju lokalu/wydarzenia"]
} {
    object.get(input.invoice, "service_category", "") == "RESTAURANT"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28m — Wynajem krótkoterminowy środków transportu                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M10: Wynajem pojazdów — miejsce wydania
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m10",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28010,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_05",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Wynajem krótkoterminowy — VAT w miejscu wydania pojazdu",
    "_legal_basis": "Art. 28m VAT",
    "_warnings": ["[MICRO POS] Wynajem pojazdu — VAT PL jeśli wydanie w PL"]
} {
    object.get(input.invoice, "service_category", "") == "VEHICLE_RENTAL"
    object.get(input.invoice, "pickup_country", "") == "PL"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 28n — Pośrednictwo B2C                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# POS-M11: Pośrednictwo B2C — miejsce transakcji głównej
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_m11",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28011,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Pośrednictwo B2C — VAT wg transakcji głównej",
    "_legal_basis": "Art. 28n VAT",
    "_warnings": ["[MICRO POS] Pośrednictwo — VAT w kraju transakcji głównej"]
} {
    object.get(input.invoice, "service_category", "") == "INTERMEDIATION"
    object.get(input.invoice, "customer_type", "") == "B2C"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  POS-DEF: Art. 28a VAT — definicje rozdziału o miejscu świadczenia        ║
# ║  (PROMPT_03: domknięcie luki pokrycia G01 — Art. 28a)                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Art. 28a pkt 1 VAT: „podatnik" na potrzeby rozdziału = podmioty wykonujące
#   samodzielnie działalność gospodarczą (art. 15 ust. 2 VAT) lub osoby prawne
#   niebędące podatnikami, zidentyfikowane/obowiązane do identyfikacji do celów
#   VAT lub VAT-UE.
# Art. 28a pkt 2 VAT: podatnik wykonujący czynności niepodlegające opodatkowaniu
#   (art. 5 ust. 1) pozostaje podatnikiem w odniesieniu do WSZYSTKICH usług
#   świadczonych na jego rzecz — usługa dla takiego podmiotu = B2B (miejsce
#   świadczenia wg art. 28b, nie 28c).
# Zgodność: Bbb (Ustawa z 11.03.2004 o VAT, Dz.U. 2025 poz. 456 ze zm.).

pos_definitions_28a := {
    "matched": true,
    "rule_id": "jdg.micro.vat.place_of_supply.pos_definitions_28a",
    "package": "jdg.micro.vat.place_of_supply",
    "priority": 28001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2010-01-01",
    "valid_to": null,
    "pos_definitions": {
        "taxpayer_for_pos": taxpayer,
        "reason": "Art. 28a VAT — kwalifikacja podmiotu jako podatnika dla miejsca świadczenia.",
    },
    "_routing": "AUTO_POST",
    "_routing_reason": "Art. 28a VAT — definicja podatnika dla rozdziału o miejscu świadczenia.",
    "_legal_basis": "Art. 28a pkt 1-2 VAT (Dz.U. 2025 poz. 456 ze zm.); art. 15 ust. 2, art. 5 ust. 1 VAT",
    "_warnings": [
        "[MICRO POS] Art. 28a: podmiot zidentyfikowany do celów VAT/VAT-UE jest podatnikiem dla miejsca świadczenia.",
        "[MICRO POS] Art. 28a pkt 2: usługi świadczone na rzecz podatnika wykonującego czynności nieopodatkowane pozostają B2B (art. 28b, nie 28c).",
    ],
} {
    object.get(input, "pos_definition_check", false) == true
    entity := object.get(input.invoice, "entity", {})
    taxpayer := object.get(entity, "identified_for_vat", false) or object.get(entity, "independent_economic_activity", false)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Helper: eu_country                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

eu_country(country) {
    eu := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"}
    eu[country]
}
