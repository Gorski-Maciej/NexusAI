# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: RODO Zatrudnienie & Cross-Domain (P1648-P1651 → 8r)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.rodo_zatrudnienie

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.rodo_zatrudnienie.no_match",
    "package": "jdg.micro.rodo_zatrudnienie", "priority": 999999
}

# P1648: email monitoring
decide := {
    "matched": true, "rule_id": "jdg.micro.rodo_zatrudnienie.r1",
    "package": "jdg.micro.rodo_zatrudnienie", "priority": 84201,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO monitoring poczty — %d prac. Polityka: %s", [emp, pol]),
    "_legal_basis": "Art. 223 KP, Art. 5/6/88 RODO",
    "_warnings": [sprintf("[MICRO] RODO EMAIL: monitoring %d pracowników. %s. Wymagane: polityka monitoringu, proporcjonalność, zakaz czytania prywatnej poczty!", [emp, pol])]
} {
    input.employment.has_employees == true; object.get(input.jdg_entrepreneur, "employee_email_monitoring_active", false) == true
    emp := object.get(input.employment, "employee_count", 0)
    has_pol := object.get(input.jdg_entrepreneur, "email_monitoring_policy_exists", false)
    pol = "BRAK POLITYKI!" { not has_pol }; pol = "OK" { has_pol }
}

# P1649: sobriety testing
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_zatrudnienie.r2",
    "package": "jdg.micro.rodo_zatrudnienie", "priority": 84202,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO badanie trzeźwości — %d prac. Dane wrażliwe!", [emp]),
    "_legal_basis": "Art. 22(1c) KP, Art. 9 RODO",
    "_warnings": [sprintf("[MICRO] RODO TRZEŹWOŚĆ: %d pracowników. To DANE WRAŻLIWE (Art.9)! Wymagane: regulamin kontroli + DPIA + ograniczony dostęp do wyników.", [emp])]
} {
    input.employment.has_employees == true; object.get(input.jdg_entrepreneur, "employee_sobriety_testing_active", false) == true
    emp := object.get(input.employment, "employee_count", 0)
}

# P1650: employee consent validity
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_zatrudnienie.r3",
    "package": "jdg.micro.rodo_zatrudnienie", "priority": 84203,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO nieważna zgoda pracownicza: %s", [issue]),
    "_legal_basis": "Art. 7 RODO, Wytyczne EROD 05/2020",
    "_warnings": [sprintf("[MICRO] RODO ZGODA: %s. Zgoda pracownika wobec pracodawcy jest domniemanie NIEWAŻNA! Użyj podstawy: obowiązek prawny (Art.6(1)(c)) lub uzasadniony interes (Art.6(1)(f)).", [issue])]
} {
    input.employment.has_employees == true; object.get(input.employment, "employee_consent_as_legal_basis", false) == true
    issue := object.get(input.employment, "consent_validity_issue", "nierównowaga stosunku pracy")
}

# P1651: cross-domain retention
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_zatrudnienie.r4",
    "package": "jdg.micro.rodo_zatrudnienie", "priority": 84204,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO × Cross-Domain retencja: %s", [domains]),
    "_legal_basis": "Art. 5 ust. 1 lit. e RODO + Art. 74 UoR + Art. 147a OrdPU",
    "_warnings": [sprintf("[MICRO] RODO CROSS-DOMAIN: konflikt retencji — %s. Zastosuj NAJDŁUŻSZY okres: 10 lat (ZUS dane płacowe) > 5 lat (PKPiR księgowe) > RODO minimum.", [domains])]
} {
    has_zus := object.get(input.jdg_entrepreneur, "has_zus_records", false)
    has_acc := object.get(input.jdg_entrepreneur, "processes_accounting_data", false)
    domains = "ZUS+PKPiR+RODO" { has_zus; has_acc }
    domains = "ZUS+RODO" { has_zus; not has_acc }
    domains = "PKPiR+RODO" { has_acc; not has_zus }
    has_zus or has_acc
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_zatrudnienie.fallback",
    "package": "jdg.micro.rodo_zatrudnienie", "priority": 84299,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "RODO 2016/679",
    "_warnings": ["[MICRO] RODO zatrudnienie — brak przesłanek monitoringu/trzeźwości/zgód."]
} { true }
