# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: RODO Podprocesorzy i Naruszenia (P1644-P1647 → 8r)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.rodo_podprocesorzy

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.rodo_podprocesorzy.no_match",
    "package": "jdg.micro.rodo_podprocesorzy", "priority": 999999
}

# P1644: subprocessor chain audit
decide := {
    "matched": true, "rule_id": "jdg.micro.rodo_podprocesorzy.r1",
    "package": "jdg.micro.rodo_podprocesorzy", "priority": 84101,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO podprocesorzy: %d łącznie, %d BEZ UMOWY!", [total, no_agr]),
    "_legal_basis": "Art. 28 ust. 2-4 RODO",
    "_warnings": [sprintf("[MICRO] RODO PODPROCESORZY: %d łącznie, %d BEZ UMOWY POWIERZENIA! Każdy wymaga: zgody administratora + umowa Art.28 + takie same obowiązki.", [total, no_agr])]
} {
    total := object.get(input.jdg_entrepreneur, "subprocessor_count", 0); total > 0
    no_agr := object.get(input.jdg_entrepreneur, "subprocessor_no_agreement_count", 0)
}

# P1645: third country subprocessor
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_podprocesorzy.r2",
    "package": "jdg.micro.rodo_podprocesorzy", "priority": 84102,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO — podprocesor w %s bez SCC!", [country]),
    "_legal_basis": "Art. 44-49 RODO, Wyrok TSUE Schrems II",
    "_warnings": [sprintf("[MICRO] RODO TRANSFER: podprocesor w %s BEZ Standardowych Klauzul Umownych! SCC + DPIA + TIA WYMAGANE. Transfer NIELEGALNY — kara do 20 mln EUR!", [country])]
} {
    object.get(input.jdg_entrepreneur, "subprocessor_in_third_country", false) == true
    country := object.get(input.jdg_entrepreneur, "subprocessor_country", "USA")
    object.get(input.jdg_entrepreneur, "subprocessor_scc_signed", false) == false
}

# P1646: breach register
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_podprocesorzy.r3",
    "package": "jdg.micro.rodo_podprocesorzy", "priority": 84103,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("RODO rejestr naruszeń — %d incydentów.", [count]),
    "_legal_basis": "Art. 33 ust. 5 RODO",
    "_warnings": [sprintf("[MICRO] RODO REJESTR NARUSZEŃ: %d incydentów. Prowadź na bieżąco: data, opis, skutki, działania naprawcze, decyzja o zgłoszeniu do UODO.", [count])]
} {
    object.get(input.jdg_entrepreneur, "rodo_breach_register_not_maintained", false) == true
    count := object.get(input.jdg_entrepreneur, "rodo_breach_total_count", 0)
}

# P1647: processor liability
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_podprocesorzy.r4",
    "package": "jdg.micro.rodo_podprocesorzy", "priority": 84104,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO — naruszenie przez %s. Odpowiedzialność SOLIDARNA!", [name]),
    "_legal_basis": "Art. 82 RODO",
    "_warnings": [sprintf("[MICRO] RODO ODPOWIEDZIALNOŚĆ: naruszenie przez %s. Jako ADMINISTRATOR ponosisz odpowiedzialność solidarną! Żądaj: audytu, raportu, działań naprawczych.", [name])]
} {
    object.get(input.jdg_entrepreneur, "processor_data_breach", false) == true
    name := object.get(input.jdg_entrepreneur, "processor_name_breach", "procesor")
}

