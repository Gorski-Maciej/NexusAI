# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: RODO Erasure & Minimalizacja (P1640-P1643 → 8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.rodo_erasure

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.rodo_erasure.no_match",
    "package": "jdg.micro.rodo_erasure", "priority": 999999
}

# P1640: erasure request
decide := {
    "matched": true, "rule_id": "jdg.micro.rodo_erasure.r1",
    "package": "jdg.micro.rodo_erasure", "priority": 84001,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO Art.17 — usunięcie: %s. 30 dni.", [scope]),
    "_legal_basis": "Art. 17 RODO (prawo do bycia zapomnianym)",
    "_warnings": [sprintf("[MICRO] RODO ERASURE: żądanie usunięcia — %s. Usuń dane z: CRM, faktury, email, backup w 30 dni. Powiadom odbiorców (Art.19). Wyjątek: dane księgowe 5 lat (UoR).", [scope])]
} {
    object.get(input.jdg_entrepreneur, "rodo_erasure_requested", false) == true
    scope := object.get(input.jdg_entrepreneur, "rodo_erasure_scope", "wszystkie dane")
}

# P1641: erasure exception accounting
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_erasure.r2",
    "package": "jdg.micro.rodo_erasure", "priority": 84002,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO × UoR — dane księgowe do %d NIE podlegają usunięciu!", [end]),
    "_legal_basis": "Art. 17 ust. 3 lit. b RODO + Art. 74 UoR",
    "_warnings": [sprintf("[MICRO] RODO ERASURE WYJĄTEK: dokument księgowy z %d — retencja do %d (5 lat UoR). Odpowiedz: dane przetwarzane na podstawie obowiązku prawnego.", [doc_year, end])]
} {
    object.get(input.jdg_entrepreneur, "rodo_erasure_requested", false) == true
    object.get(input.invoice, "is_accounting_document", false) == true
    doc_year := object.get(input.invoice, "document_year", 2026); end := doc_year + 5
    object.get(input.calendar, "year", 2026) < end
}

# P1642: data minimization audit
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_erasure.r3",
    "package": "jdg.micro.rodo_erasure", "priority": 84003,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO minimalizacja — %d zbędnych pól (np. %s)", [n, ex]),
    "_legal_basis": "Art. 5 ust. 1 lit. c RODO (minimalizacja), Art. 25 RODO",
    "_warnings": [sprintf("[MICRO] RODO MINIMALIZACJA: %d zbędnych pól (np. %s). Privacy by Design — zbieraj TYLKO niezbędne dane! Usuń w 90 dni.", [n, ex])]
} {
    n := object.get(input.jdg_entrepreneur, "rodo_excessive_data_fields", 0); n > 0
    ex := object.get(input.jdg_entrepreneur, "rodo_excessive_field_example", "PESEL")
}

# P1643: encryption gap
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_erasure.r4",
    "package": "jdg.micro.rodo_erasure", "priority": 84004,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO Art.32 — szyfrowanie: %s, pseudonimizacja: %s", [enc, pseud]),
    "_legal_basis": "Art. 32 RODO",
    "_warnings": [sprintf("[MICRO] RODO SECURITY: szyfrowanie: %s, pseudonimizacja: %s. AES-256 at-rest, TLS 1.3 in-transit. Brak = kara UODO!", [enc, pseud])]
} {
    enc_ok := object.get(input.jdg_entrepreneur, "rodo_encryption_active", false)
    pseud_ok := object.get(input.jdg_entrepreneur, "rodo_pseudonymization_active", false)
    enc = "BRAK!" { not enc_ok }; enc = "OK" { enc_ok }
    pseud = "BRAK!" { not pseud_ok }; pseud = "OK" { pseud_ok }
    not enc_ok or not pseud_ok
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_erasure.fallback",
    "package": "jdg.micro.rodo_erasure", "priority": 84099,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "RODO 2016/679",
    "_warnings": ["[MICRO] RODO erasure — brak żądań usunięcia, dane zminimalizowane, zabezpieczenia OK."]
} { true }
