# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: AML STR/GIIF + Training + Audit (P1934-P1938,P1946 → 8r)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.aml_str_gif

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.aml_str_gif.no_match",
    "package": "jdg.micro.aml_str_gif", "priority": 999999
}

# STR filing obligation — 48h deadline
decide := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r1",
    "package": "jdg.micro.aml_str_gif", "priority": 83201,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AML STR WYMAGANE — %s. 48h deadline!", [reason]),
    "_legal_basis": "Art. 83-86 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML STR: %s — złóż STR przez e-PUAP GIIF w 48h. Wstrzymaj transakcję (max 96h). NIE informuj klienta (tipping-off Art.86)!", [reason])]
} {
    object.get(input.invoice, "is_suspicious_transaction", false) == true
    reason := object.get(input.invoice, "suspicious_transaction_reason", "podejrzenie prania pieniędzy")
}

# Missing STR penalty
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r2",
    "package": "jdg.micro.aml_str_gif", "priority": 83202,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AML — BRAK STR mimo podejrzanej transakcji!",
    "_legal_basis": "Art. 147-153 Ustawy AML, Art. 299 KKS",
    "_warnings": ["[MICRO] AML STR MISSING: transakcja podejrzana bez STR! Kara: do 5 mln PLN (KNF) + do 25 lat pozbawienia wolności (KKS). Złóż STR natychmiast!"]
} {
    object.get(input.jdg_entrepreneur, "aml_pending_suspicious_no_str", false) == true
}

# Tipping-off warning
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r3",
    "package": "jdg.micro.aml_str_gif", "priority": 83203,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AML TIPPING-OFF — ZAKAZ informowania klienta o STR!",
    "_legal_basis": "Art. 86 Ustawy AML",
    "_warnings": ["[MICRO] AML TIPPING-OFF: ZAKAZ informowania klienta lub osób trzecich o zgłoszeniu STR! Kara: do 1 mln PLN + odpowiedzialność karna!"]
} {
    object.get(input.jdg_entrepreneur, "aml_str_filed", false) == true
    object.get(input.invoice, "client_notified_of_str", false) == true
}

# Training obligation
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r4",
    "package": "jdg.micro.aml_str_gif", "priority": 83204,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML szkolenia — %d/%d przeszkolonych. Ostatnie: %s", [trained, total, last]),
    "_legal_basis": "Art. 50-52 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML SZKOLENIA: %d/%d pracowników. Ostatnie: %s. Częstotliwość: co 12 mies. Dokumentuj listę + test!", [trained, total, last])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    total := object.get(input.employment, "employee_count", 0); total > 0
    trained := object.get(input.employment, "aml_trained_employees", 0)
    last := object.get(input.jdg_entrepreneur, "aml_last_training_date", "nigdy")
}

# AML retention 5 years
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r5",
    "package": "jdg.micro.aml_str_gif", "priority": 83205,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML retencja 5 lat — braki: %d dokumentów", [missing]),
    "_legal_basis": "Art. 48 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML RETENCJA: 5 lat od końca relacji. Status: %s. Braki: %d dokumentów CDD/EDD.", [status, missing])]
} {
    missing := object.get(input.jdg_entrepreneur, "aml_documentation_missing_count", 0)
    status = "KOMPLETNA" { missing == 0 }; status = "BRAKI — uzupełnij!" { missing > 0 }
}

# Audit annual
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r6",
    "package": "jdg.micro.aml_str_gif", "priority": 83206,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML audyt roczny — ostatni: %s", [last]),
    "_legal_basis": "Art. 50 ust. 3 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML AUDYT: ostatni: %s. Wymagany co 12 mies. Zakres: procedura, CDD, STR, szkolenia, CBDD.", [last])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    last := object.get(input.jdg_entrepreneur, "aml_last_audit_date", "nigdy")
    last == "nigdy"
}

# Internal procedure gap
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.r7",
    "package": "jdg.micro.aml_str_gif", "priority": 83207,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML procedura — brak: %s", [gap]),
    "_legal_basis": "Art. 50-52 Ustawy AML",
    "_warnings": [sprintf("[MICRO] AML PROCEDURA: brakuje: %s. Kompletna procedura: (1) ocena ryzyka, (2) CDD/EDD, (3) STR, (4) szkolenia, (5) audyt, (6) retencja. Uzupełnij 30 dni!", [gap])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    object.get(input.jdg_entrepreneur, "aml_procedure_complete", true) == false
    gap := object.get(input.jdg_entrepreneur, "aml_procedure_missing_element", "nieokreślony")
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.aml_str_gif.fallback",
    "package": "jdg.micro.aml_str_gif", "priority": 83299,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa AML",
    "_warnings": ["[MICRO] AML STR/GIIF — brak przesłanek do raportowania."]
} { true }
