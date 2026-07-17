# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: AML Transakcje/Monitoring (P1929-P1933 → 8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.aml_transakcje

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.aml_transakcje.no_match",
    "package": "jdg.micro.aml_transakcje", "priority": 999999
}

decide := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.r1",
    "package": "jdg.micro.aml_transakcje", "priority": 83101,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML structurization — %d transakcji od %s w 30 dni!", [tx, vendor]),
    "_legal_basis": "Art. 86 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML STRUKTURYZACJA: %d transakcji od %s poniżej progu w 30 dni = SMURFING. Zgłoś STR do GIIF!", [tx, vendor])]
} {
    tx := object.get(input.vendor, "similar_transactions_30d", 0); tx >= 5
    vendor := object.get(input.vendor, "name", "klient")
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.r2",
    "package": "jdg.micro.aml_transakcje", "priority": 83102,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Round-trip: %.2f PLN sale + %.2f PLN buy z %s!", [amt, back, vendor]),
    "_legal_basis": "Art. 299 KKS",
    "_warnings": [sprintf("[MICRO] AML ROUND-TRIP: %.2f/%.2f PLN z %s — podejrzenie prania! Wstrzymaj + STR!", [amt, back, vendor])]
} {
    amt := object.get(input.invoice, "amount_gross", 0)
    back := object.get(input.vendor, "round_trip_purchase_amount", 0)
    vendor := object.get(input.vendor, "name", "kontrahent")
    abs(amt - back) < amt * 0.05
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.r3",
    "package": "jdg.micro.aml_transakcje", "priority": 83103,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML unusual pattern: %s", [pattern]),
    "_legal_basis": "Art. 83-86 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML PATTERN: %s. Udokumentuj analizę. Podejrzenie → STR w 48h.", [pattern])]
} {
    object.get(input.invoice, "aml_unusual_pattern_flag", false) == true
    pattern := object.get(input.invoice, "aml_pattern_description", "nietypowa aktywność")
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.r4",
    "package": "jdg.micro.aml_transakcje", "priority": 83104,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 35 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML TRANS: %.2f PLN via %s. CDD wykonane — OK.", [amt, method])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    amt := object.get(input.invoice, "amount_gross", 0); amt >= 15000
    method := "przelew" { input.invoice.is_cash_payment == false }; method := "gotówka" { input.invoice.is_cash_payment == true }
    object.get(input.invoice, "is_suspicious_transaction", true) == false
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.r5",
    "package": "jdg.micro.aml_transakcje", "priority": 83105,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AML crypto Travel Rule — %.0f EUR. Przekaż dane!", [crypto_eur]),
    "_legal_basis": "Rozp. UE 2023/1113 (TFR)",
    "_warnings": [sprintf("[MICRO] AML TRAVEL RULE: %.0f EUR w krypto. Przekaż: nazwa, nr rachunku, adres, data urodzenia nadawcy/odbiorcy.", [crypto_eur])]
} {
    object.get(input.jdg_entrepreneur, "is_crypto_exchange", false) == true
    input.invoice.crypto_transfer == true
    crypto_eur := object.get(input.invoice, "crypto_amount_eur", 0); crypto_eur >= 1000
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.r6",
    "package": "jdg.micro.aml_transakcje", "priority": 83106,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("SANKCJE — %s (%.0f%%) na liście %s!", [vendor, score, list]),
    "_legal_basis": "Rozp. UE 269/2014",
    "_warnings": [sprintf("[MICRO] AML SANKCJE: %s na liście %s! Wstrzymaj transakcję + zgłoś do GIIF/KNF! Kara: do 20 mln PLN.", [vendor, list])]
} {
    object.get(input.vendor, "sanctions_list_match", false) == true
    vendor := object.get(input.vendor, "name", "Kontrahent")
    list := object.get(input.vendor, "sanctions_list_name", "UE/ONZ")
    score := object.get(input.vendor, "sanctions_match_confidence", 0)
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.aml_transakcje.fallback",
    "package": "jdg.micro.aml_transakcje", "priority": 83199,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa AML",
    "_warnings": ["[MICRO] AML transakcje — brak podejrzanych wzorców."]
} { true }
