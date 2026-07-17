# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO — Transport i Transgraniczne (P1912-P1914 → 10 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.bdo_transport
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.bdo_transport

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.bdo_transport.no_match",
    "package": "jdg.micro.bdo_transport",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  BDO Transport/Cross-border — Zezwolenia, granice (10 reguł)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.bdo_transport.r1: transport_permit_check — sprawdzenie zezwolenia
decide := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.r1",
    "package": "jdg.micro.bdo_transport", "priority": 82301,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Transport odpadów bez zezwolenia — wymagany wpis w BDO!",
    "_legal_basis": "Art. 232-234 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO TRANSPORT: %s. Wpis w BDO jako transportujący + zezwolenie starosty. Numer rejestracyjny pojazdu w KPO.", [transport_kind])]
} {
    input.business.transports_waste == true
    object.get(input.business, "bdo_transport_permit_valid", false) == false
    is_hazardous := object.get(input.business, "transports_hazardous_waste", false)
    transport_kind = "Odpady inne niż niebezpieczne — wpis w BDO + zezwolenie" { is_hazardous == false }
    transport_kind = "NIENIEBEZPIECZNE — zezwolenie + ADR + OC przewoźnika!" { is_hazardous == true }
}

# jdg.micro.bdo_transport.r2: transport_adr_required — ADR dla niebezpiecznych
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.r2",
    "package": "jdg.micro.bdo_transport", "priority": 82302,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ADR WYMAGANE — transport odpadów niebezpiecznych!",
    "_legal_basis": "Umowa ADR, Ustawa o przewozie towarów niebezpiecznych",
    "_warnings": [sprintf("[MICRO] BDO TRANSPORT ADR: odpady niebezpieczne EWC %s. Wymagane: certyfikat ADR kierowcy, oznakowanie pojazdu, dokument przewozowy, wyposażenie awaryjne. Kara za brak: do 10 000 PLN.", [ewc])]
} {
    input.business.transports_waste == true
    input.business.transports_hazardous_waste == true
    ewc := object.get(input.invoice, "bdo_ewc_code", "")
}

# jdg.micro.bdo_transport.r3: transport_rules_ok — transport zgodny
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.r3",
    "package": "jdg.micro.bdo_transport", "priority": 82303,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 233 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO TRANSPORT: zezwolenie ważne do %s. %d pojazdów zarejestrowanych w BDO.", [expiry, vehicles])]
} {
    input.business.transports_waste == true
    object.get(input.business, "bdo_transport_permit_valid", false) == true
    expiry := object.get(input.business, "bdo_transport_permit_expiry", "2026-12-31")
    vehicles := object.get(input.business, "bdo_registered_vehicles", 0)
}

# jdg.micro.bdo_transport.r4: cross_border_notification — notyfikacja transgraniczna
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.r4",
    "package": "jdg.micro.bdo_transport", "priority": 82304,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Transgraniczne przemieszczanie: PL → %s. Notyfikacja GIOŚ WYMAGANA!", [country]),
    "_legal_basis": "Rozp. WE 1013/2006, Ustawa o międzynarodowym przemieszczaniu odpadów",
    "_warnings": [sprintf("[MICRO] BDO TRANSGRANICZNY: EWC %s → %s. Wymagane: zgoda GIOŚ, krajowe punkty kontaktowe, gwarancja finansowa, zgoda kraju odbioru. Procedura trwa 30-60 dni!", [ewc, country])]
} {
    country := object.get(input.invoice, "waste_destination_country", "")
    country != ""; country != "PL"
    ewc := object.get(input.invoice, "bdo_ewc_code", "")
    is_green := object.get(input.invoice, "waste_green_list", false)
    not is_green
}

# jdg.micro.bdo_transport.r5: cross_border_green_list — zielona lista (uproszczona)
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.r5",
    "package": "jdg.micro.bdo_transport", "priority": 82305,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Rozp. WE 1013/2006, Załącznik VII (zielona lista)",
    "_warnings": [sprintf("[MICRO] BDO TRANSGRANICZNY ZIELONA LISTA: EWC %s → %s. Procedura uproszczona — załącznik VII + umowa między stronami. Bez notyfikacji GIOŚ.", [ewc, country])]
} {
    country := object.get(input.invoice, "waste_destination_country", "")
    country != ""; country != "PL"
    object.get(input.invoice, "waste_green_list", false) == true
    ewc := object.get(input.invoice, "bdo_ewc_code", "")
}

# jdg.micro.bdo_transport.r6: storage_limit_check — limit magazynowania
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.r6",
    "package": "jdg.micro.bdo_transport", "priority": 82306,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Odpady magazynowane %d lat — limit 3 lat przekroczony!", [years]),
    "_legal_basis": "Art. 25 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO MAGAZYNOWANIE: EWC %s — %d lat (max 3 lata). Przekaż do unieszkodliwienia/odzysku NATYCHMIAST! Kara: 5 000 – 100 000 PLN.", [ewc, years])]
} {
    years := object.get(input.business, "waste_storage_years", 0)
    years >= 3
    ewc := object.get(input.invoice, "bdo_ewc_code", "nieznany")
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_transport.fallback",
    "package": "jdg.micro.bdo_transport", "priority": 82399,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa o odpadach",
    "_warnings": ["[MICRO] BDO transport — brak przesłanek transportowych dla tej transakcji."]
} { true }
