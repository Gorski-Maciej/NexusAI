# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: AML Ryzyko/CDD/PEP (P1925-P1928 → 10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.aml_ryzyko

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.aml_ryzyko.no_match",
    "package": "jdg.micro.aml_ryzyko", "priority": 999999
}

# jdg.micro.aml_ryzyko.r1 — PKD check
decide := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r1",
    "package": "jdg.micro.aml_ryzyko", "priority": 83001,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML PKD check — %s: %s", [pkd, sector]),
    "_legal_basis": "Art. 2 ust. 1 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML PKD: %s → %s. Podmiot obowiązany AML. Wymagana procedura wewnętrzna + CDD + szkolenia.", [pkd, sector])]
} {
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
    aml_pkd := {"69.20.Z", "66.19.Z", "68.31.Z", "64.99.Z", "64.19.Z"}
    pkd in aml_pkd
    sector = "KSIĘGOWOŚĆ" { pkd == "69.20.Z" }
    sector = "NIERUCHOMOŚCI" { pkd == "68.31.Z" }
    sector = "KRYPTO" { pkd == "64.19.Z" }
    sector = "FINANSE" { pkd in aml_pkd }
}

# jdg.micro.aml_ryzyko.r2 — risk level HIGH
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r2",
    "package": "jdg.micro.aml_ryzyko", "priority": 83002,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AML HIGH RISK — %s!", [reason]),
    "_legal_basis": "Art. 33-43 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML HIGH RISK: %s. EDD OBOWIĄZKOWE! Zgoda kierownictwa + źródło majątku + monitoring ciągły.", [reason])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    is_pep := object.get(input.vendor, "is_pep", false)
    is_high_risk := object.get(input.vendor, "is_high_risk_jurisdiction", false)
    is_pep or is_high_risk
    reason = "PEP + kraj wysokiego ryzyka" { is_pep; is_high_risk }
    reason = "PEP" { is_pep; not is_high_risk }
    reason = "kraj wysokiego ryzyka" { not is_pep; is_high_risk }
}

# jdg.micro.aml_ryzyko.r3 — CDD basic
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r3",
    "package": "jdg.micro.aml_ryzyko", "priority": 83003,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 34 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML CDD: transakcja %.2f PLN. Identyfikacja klienta + weryfikacja dokumentu tożsamości + oświadczenie o źródle pochodzenia środków.", [amount])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    amount := object.get(input.invoice, "amount_gross", 0); amount >= 15000
}

# jdg.micro.aml_ryzyko.r4 — CDD cash
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r4",
    "package": "jdg.micro.aml_ryzyko", "priority": 83004,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — gotówka %.0f EUR > 10k. Rejestracja!", [eur]),
    "_legal_basis": "Art. 72 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML GOTÓWKA: %.0f EUR. Zarejestruj transakcję + pełna identyfikacja klienta. Powyżej 15k EUR → obowiązek STR do GIIF.", [eur])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.invoice.is_cash_payment == true
    eur_pln := object.get(object.get(data.thresholds.jdg, "bounds", {}), "eur_pln", 4.50)
    eur := floor(object.get(input.invoice, "amount_gross", 0) / eur_pln * 100) / 100
    eur >= 10000
}

# jdg.micro.aml_ryzyko.r5 — PEP screening
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r5",
    "package": "jdg.micro.aml_ryzyko", "priority": 83005,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("PEP: %s (%s). EDD WYMAGANE!", [name, role]),
    "_legal_basis": "Art. 43-46 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML PEP: %s (rola: %s). EDD obowiązkowe! Zgoda wyższego kierownictwa przed transakcją + źródło majątku + monitoring 12 mies. po zakończeniu funkcji publicznej.", [name, role])]
} {
    object.get(input.vendor, "is_pep", false) == true
    name := object.get(input.vendor, "name", "Kontrahent"); role := object.get(input.vendor, "pep_role", "funkcja")
}

# jdg.micro.aml_ryzyko.r6 — high risk country
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r6",
    "package": "jdg.micro.aml_ryzyko", "priority": 83006,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Kraj wysokiego ryzyka AML: %s!", [country]),
    "_legal_basis": "Art. 43 ust. 5 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML KRAJ RYZYKA: %s (kod: %s). EDD + zgoda zarządu + monitoring transakcji + STR do GIIF. FATF czarna/szara lista.", [country, code])]
} {
    object.get(input.vendor, "is_high_risk_jurisdiction", false) == true
    country := object.get(input.vendor, "country_name", "Nieznany"); code := object.get(input.vendor, "country", "XX")
}

# jdg.micro.aml_ryzyko.r7 — UBO verification
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.r7",
    "package": "jdg.micro.aml_ryzyko", "priority": 83007,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("UBO weryfikacja: %s — CBDD: %s", [vendor, cbdd]),
    "_legal_basis": "Art. 61-79 Ustawy o CBDD, Art. 35 AML",
    "_warnings": [sprintf("[MICRO] AML UBO: %s. CBDD: %s. %s Rozbieżność >25%% → STR do GIIF!", [vendor, cbdd, discrepancy_msg])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.invoice.amount_gross >= 15000
    vendor := object.get(input.vendor, "name", "kontrahent")
    cbdd_reg := object.get(input.vendor, "cbdd_registered", false)
    cbdd = "zarejestrowany" { cbdd_reg }; cbdd = "BRAK!" { not cbdd_reg }
    disc := object.get(input.vendor, "ubo_discrepancy", false)
    discrepancy_msg = "UBO zgodny" { not disc }; discrepancy_msg = "ROZBIEŻNOŚĆ — zgłoś!" { disc }
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.aml_ryzyko.fallback",
    "package": "jdg.micro.aml_ryzyko", "priority": 83099,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa AML",
    "_warnings": ["[MICRO] AML ryzyko — JDG nie jest podmiotem obowiązanym lub transakcja poniżej progu."]
} { true }
