# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: RODO Sankcje i Przegląd (P1654-P1655 → 7 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.rodo_sankcje

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.rodo_sankcje.no_match",
    "package": "jdg.micro.rodo_sankcje", "priority": 999999
}

# P1654: UODO sanctions — tier 1 (2%)
decide := {
    "matched": true, "rule_id": "jdg.micro.rodo_sankcje.r1",
    "package": "jdg.micro.rodo_sankcje", "priority": 84401,
    "micro_rule_active": true,
    "sanction_type": "UODO", "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO sankcja TIER 1: %s — do 10M EUR / 2%% obrotu!", [violation]),
    "_legal_basis": "Art. 83 ust. 4 RODO",
    "_warnings": [sprintf("[MICRO] RODO SANKCJA TIER 1: %s. Max: 10M EUR lub 2%% rocznego obrotu. Działania naprawcze → redukcja kary o 50%% (współpraca z UODO).", [violation])]
} {
    violation := object.get(input.jdg_entrepreneur, "rodo_violation_type", "")
    violation in {"NO_DPO", "NO_RECORDS", "NO_DPIA", "NO_BREACH_REGISTER"}
}

# P1654b: UODO sanctions — tier 2 (4%)
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_sankcje.r2",
    "package": "jdg.micro.rodo_sankcje", "priority": 84402,
    "micro_rule_active": true,
    "sanction_type": "UODO", "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO sankcja TIER 2 (4%%!): %s", [violation]),
    "_legal_basis": "Art. 83 ust. 5 RODO",
    "_warnings": [sprintf("[MICRO] RODO SANKCJA TIER 2: %s. Max: 20M EUR lub 4%% obrotu! Natychmiastowe działania naprawcze + zgłoszenie do UODO. Współpraca = redukcja kary.", [violation])]
} {
    violation := object.get(input.jdg_entrepreneur, "rodo_violation_type", "")
    violation in {"NO_CONSENT", "DATA_BREACH_UNREPORTED", "ILLEGAL_TRANSFER", "NO_ERASURE", "VIOLATION_DATA_PRINCIPLES"}
}

# P1654c: mitigation guidance
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_sankcje.r3",
    "package": "jdg.micro.rodo_sankcje", "priority": 84403,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "RODO — wytyczne łagodzenia kar UODO.",
    "_legal_basis": "Art. 83 ust. 2 RODO (kryteria nakładania kar)",
    "_warnings": ["[MICRO] RODO MITIGACJA: kryteria UODO przy wymiarze kary: (a) charakter/waga naruszenia, (b) umyślność/nieumyślność, (c) działania minimalizujące szkodę, (d) stopień współpracy z UODO, (e) kategorie danych, (f) wcześniejsze naruszenia."]
} {
    object.get(input.jdg_entrepreneur, "rodo_violation_detected", false) == true
}

# P1655: annual compliance review
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_sankcje.r4",
    "package": "jdg.micro.rodo_sankcje", "priority": 84404,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO przegląd roczny — score: %.0f%%. Obszary: %s", [score, gaps]),
    "_legal_basis": "Art. 24 ust. 1 RODO (accountability), Art. 32 ust. 1 lit. d",
    "_warnings": [sprintf("[MICRO] RODO PRZEGLĄD ROCZNY: wynik %.0f%%. Do poprawy: %s. Przeprowadź przegląd + udokumentuj wnioski (Art.5(2) accountability).", [score, gaps])]
} {
    object.get(input.calendar, "month", 12) == 12
    score := object.get(input.jdg_entrepreneur, "rodo_compliance_score_pct", 50)
    gaps := object.get(input.jdg_entrepreneur, "rodo_gap_areas", "zgody, retencja, zabezpieczenia")
    score < 90
}

# P1655b: compliance OK
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_sankcje.r5",
    "package": "jdg.micro.rodo_sankcje", "priority": 84405,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 24 RODO",
    "_warnings": [sprintf("[MICRO] RODO COMPLIANCE: wynik %.0f%% — POWYŻEJ 90%%. Zgodność RODO na wysokim poziomie. Utrzymuj standard.", [score])]
} {
    object.get(input.calendar, "month", 12) == 12
    score := object.get(input.jdg_entrepreneur, "rodo_compliance_score_pct", 95)
    score >= 90
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_sankcje.fallback",
    "package": "jdg.micro.rodo_sankcje", "priority": 84499,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "RODO 2016/679",
    "_warnings": ["[MICRO] RODO sankcje — brak naruszeń, compliance score OK."]
} { true }
