# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: RODO AI & Marketing (P1652-P1653 → 6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.rodo_ai_marketing

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.rodo_ai_marketing.no_match",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 999999
}

# P1652: AI profiling Art.22
decide := {
    "matched": true, "rule_id": "jdg.micro.rodo_ai_marketing.r1",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 84301,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("RODO Art.22 AI — %s bez zabezpieczeń!", [prof_type]),
    "_legal_basis": "Art. 22 RODO",
    "_warnings": [sprintf("[MICRO] RODO AI: %s wywołuje skutki prawne. Wymagane: (1) wyraźna zgoda/umowa, (2) prawo do interwencji ludzkiej, (3) DPIA obowiązkowe!", [prof_type])]
} {
    object.get(input.jdg_entrepreneur, "uses_ai_automated_decisions", false) == true
    object.get(input.jdg_entrepreneur, "rodo_art22_safeguards", false) == false
    prof_type := object.get(input.jdg_entrepreneur, "ai_profiling_type", "scoring")
}

# P1652b: AI profiling compliant
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_ai_marketing.r2",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 84302,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 RODO",
    "_warnings": [sprintf("[MICRO] RODO AI: %s — zabezpieczenia Art.22 wdrożone. DPIA + zgoda + prawo do interwencji ludzkiej — OK.", [prof_type])]
} {
    object.get(input.jdg_entrepreneur, "uses_ai_automated_decisions", false) == true
    object.get(input.jdg_entrepreneur, "rodo_art22_safeguards", false) == true
    prof_type := object.get(input.jdg_entrepreneur, "ai_profiling_type", "scoring")
}

# P1653: B2B vs B2C marketing wrong basis
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_ai_marketing.r3",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 84303,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "RODO B2B vs B2C — BŁĄD podstawy prawnej marketingu!",
    "_legal_basis": "Art. 6 RODO, Art. 172 PT",
    "_warnings": ["[MICRO] RODO MARKETING: BŁĄD — używasz podstawy B2B (prawnie uzasadniony interes) dla B2C! B2C wymaga ZGODY (opt-in). B2B może używać uzasadnionego interesu z opt-out."]
} {
    object.get(input.jdg_entrepreneur, "uses_b2b_basis_for_b2c", false) == true
}

# P1653b: marketing B2B
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_ai_marketing.r4",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 84304,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 1 lit. f RODO",
    "_warnings": ["[MICRO] RODO MARKETING B2B: podstawa — prawnie uzasadniony interes + opt-out. Pamiętaj o klauzuli informacyjnej i prawie do sprzeciwu."]
} {
    object.get(input.jdg_entrepreneur, "markets_to_b2b", false) == true
}

# P1653c: marketing B2C
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_ai_marketing.r5",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 84305,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 1 lit. a RODO + Art. 172 PT",
    "_warnings": ["[MICRO] RODO MARKETING B2C: podstawa — ZGODA (opt-in). Zgoda musi być: dobrowolna, konkretna, świadoma, jednoznaczna. Obowiązek wykazania!"]
} {
    object.get(input.jdg_entrepreneur, "markets_to_b2c", false) == true
}

# fallback
else := {
    "matched": true, "rule_id": "jdg.micro.rodo_ai_marketing.fallback",
    "package": "jdg.micro.rodo_ai_marketing", "priority": 84399,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "RODO 2016/679",
    "_warnings": ["[MICRO] RODO AI/marketing — brak profilowania AI, marketing prawidłowy."]
} { true }
