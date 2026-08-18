# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Micro Layer — KSeF autoryzacja, odrzucenie, API fallback
# Generated: 2026-07-28
# Package: jdg.micro.vat.ksef
# Legal coverage: Art. 106na-106nh VAT (KSeF), Art. 106ne (tryb awaryjny)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat.ksef

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.ksef.no_match",
    "package": "jdg.micro.vat.ksef",
    "priority": 999999,
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KSeF Autoryzacja — 4 reguły                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# KSEF-M01: Autoryzacja — token KSeF ważny
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m01",
    "package": "jdg.micro.vat.ksef",
    "priority": 106001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "KSeF — token autoryzacyjny ważny",
    "_legal_basis": "Art. 106na ust. 1 VAT",
    "_warnings": ["[MICRO KSeF] Token KSeF OK — faktura może być wysłana"]
} {
    object.get(input.jdg_entrepreneur, "ksef_token_valid", false) == true
    object.get(input.invoice, "requires_ksef", false) == true
}

# KSEF-M02: Autoryzacja — token wygasł → odnowienie
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m02",
    "package": "jdg.micro.vat.ksef",
    "priority": 106002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF — token wygasł → wygeneruj nowy token",
    "_legal_basis": "Art. 106na ust. 2 VAT",
    "_warnings": ["[MICRO KSeF] TOKEN WYGASŁ — odnow token przed wysyłką faktury"]
} {
    object.get(input.jdg_entrepreneur, "ksef_token_valid", false) == false
    object.get(input.invoice, "requires_ksef", false) == true
}

# KSEF-M03: Kwalifikowany podpis elektroniczny — wymagany
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m03",
    "package": "jdg.micro.vat.ksef",
    "priority": 106003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "VERIFICATION_QUEUE",
    "_routing_reason": "KSeF — wymagany kwalifikowany podpis elektroniczny",
    "_legal_basis": "Art. 106na ust. 3 VAT",
    "_warnings": ["[MICRO KSeF] Wymagany podpis kwalifikowany lub pieczęć elektroniczna"]
} {
    object.get(input.invoice, "requires_ksef", false) == true
    object.get(input.invoice, "ksef_signature_valid", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KSeF Odrzucenie faktury — 3 reguły                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# KSEF-M04: Odrzucenie — błąd walidacji XSD
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m04",
    "package": "jdg.micro.vat.ksef",
    "priority": 106004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF — faktura odrzucona: błąd schematu XSD",
    "_legal_basis": "Art. 106nb ust. 1 VAT",
    "_warnings": ["[MICRO KSeF] ODRZUCONO — błąd walidacji XSD, popraw i wyślij ponownie"]
} {
    object.get(input.invoice, "ksef_status", "") == "REJECTED_XSD"
}

# KSEF-M05: Odrzucenie — błąd biznesowy (NIP, stawka)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m05",
    "package": "jdg.micro.vat.ksef",
    "priority": 106005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF — faktura odrzucona: błąd biznesowy",
    "_legal_basis": "Art. 106nb ust. 2 VAT",
    "_warnings": ["[MICRO KSeF] ODRZUCONO — błąd biznesowy (NIP, stawka, GTU)"]
} {
    object.get(input.invoice, "ksef_status", "") == "REJECTED_BUSINESS"
}

# KSEF-M06: Odrzucenie — timeout / brak odpowiedzi
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m06",
    "package": "jdg.micro.vat.ksef",
    "priority": 106006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "RETRY_QUEUE",
    "_routing_reason": "KSeF — timeout API → ponów za 5 min",
    "_legal_basis": "Art. 106ne VAT (tryb awaryjny)",
    "_warnings": ["[MICRO KSeF] TIMEOUT KSeF — ponów wysyłkę za 5 minut"]
} {
    object.get(input.invoice, "ksef_status", "") == "TIMEOUT"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KSeF Tryb awaryjny / offline — 4 reguły                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# KSEF-M07: Tryb offline — KSeF niedostępny
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m07",
    "package": "jdg.micro.vat.ksef",
    "priority": 106007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "FALLBACK_QUEUE",
    "_routing_reason": "KSeF offline → tryb awaryjny — wystaw PDF + wyślij później",
    "_legal_basis": "Art. 106ne ust. 1-3 VAT",
    "_warnings": ["[MICRO KSeF] TRYB AWARYJNY — wystaw PDF, wyślij do KSeF w ciągu 7 dni"]
} {
    object.get(input.invoice, "ksef_status", "") == "OFFLINE"
    object.get(input.invoice, "requires_ksef", false) == true
}

# KSEF-M08: Tryb offline — numeracja faktur /OFFLINE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m08",
    "package": "jdg.micro.vat.ksef",
    "priority": 106008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "KSeF offline — numeracja z sufiksem /OFFLINE",
    "_legal_basis": "Art. 106ne ust. 4 VAT",
    "_warnings": ["[MICRO KSeF] Numeracja offline — dodaj /OFFLINE do numeru faktury"]
} {
    object.get(input.invoice, "ksef_mode", "") == "OFFLINE"
    object.get(input.invoice, "invoice_number", "") != ""
    not contains(input.invoice.invoice_number, "/OFFLINE")
}

# KSEF-M09: Ponowna wysyłka po awarii — deadline 7 dni
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m09",
    "package": "jdg.micro.vat.ksef",
    "priority": 106009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF offline > 7 dni — PRZEKROCZONY TERMIN!",
    "_legal_basis": "Art. 106ne ust. 5 VAT",
    "_warnings": ["[MICRO KSeF] PRZEKROCZONY TERMIN 7 DNI — wyślij natychmiast do KSeF!"]
} {
    object.get(input.invoice, "ksef_mode", "") == "OFFLINE"
    object.get(input.invoice, "ksef_offline_days", 0) > 7
}

# KSEF-M10: API fallback — retry z backoffem
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.ksef.ksef_m10",
    "package": "jdg.micro.vat.ksef",
    "priority": 106010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2024-07-01",
    "valid_to": null,
    "_routing": "RETRY_QUEUE",
    "_routing_reason": "KSeF API error 5xx → retry z wykładniczym backoffem",
    "_legal_basis": "Art. 106ne VAT (tryb awaryjny)",
    "_warnings": ["[MICRO KSeF] API ERROR — ponów wysyłkę z wykładniczym backoffem (max 5 prób)"]
} {
    object.get(input.invoice, "ksef_status", "") == "API_ERROR"
    object.get(input.invoice, "ksef_retry_count", 0) < 5
}
