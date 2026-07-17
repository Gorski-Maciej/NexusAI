# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO — Zezwolenia DGO/BAT/Sankcje (P1915-P1917→8r)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.bdo_zezwolenia
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.bdo_zezwolenia

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.bdo_zezwolenia.no_match",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 999999
}

# jdg.micro.bdo_zezwolenia.r1: dgo_permit_check — sprawdzenie DGO
decide := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.r1",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82401,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Brak DGO — %s bez zezwolenia!", [activity]),
    "_legal_basis": "Art. 41-42 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO DGO: BRAK zezwolenia na %s (%s). Wystąp do starosty/marszałka. Kara bez DGO: do 100 000 PLN + wstrzymanie działalności!", [activity, ewc])]
} {
    input.business.processes_waste == true
    object.get(input.business, "dgo_permit_valid", false) == false
    activity := object.get(input.business, "waste_activity_type", "zbieranie")
    ewc := object.get(input.business, "primary_ewc_code", "brak")
}

# jdg.micro.bdo_zezwolenia.r2: dgo_permit_ok — DGO ważne
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.r2",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82402,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 42 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO DGO: zezwolenie ważne do %s. Organ: %s. Pamiętaj o przeglądzie co 10 lat.", [expiry, authority])]
} {
    input.business.processes_waste == true
    object.get(input.business, "dgo_permit_valid", false) == true
    expiry := object.get(input.business, "dgo_permit_expiry", "2036-12-31")
    authority := object.get(input.business, "dgo_authority", "Marszałek Województwa")
}

# jdg.micro.bdo_zezwolenia.r3: bat_conclusions_check — konkluzje BAT
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.r3",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82403,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Konkluzje BAT %s — dostosowanie do %d", [sector, deadline]),
    "_legal_basis": "Dyrektywa IED 2010/75/UE",
    "_warnings": [sprintf("[MICRO] BDO BAT: %s — dostosuj instalację do %d. Przegląd pozwolenia zintegrowanego + monitoring emisji. Niedostosowanie = kara do 1 000 000 PLN!", [sector, deadline])]
} {
    input.business.ippc_installation == true
    sector := object.get(input.business, "bat_sector", "odpady")
    bat_year := object.get(input.business, "bat_published_year", 2022)
    deadline := bat_year + 4
    deadline > object.get(input.calendar, "year", 2026)
}

# jdg.micro.bdo_zezwolenia.r4: sanction_no_registration — kara: brak rejestracji
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.r4",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82404,
    "micro_rule_active": true,
    "sanction_type": "ADMINISTRACYJNA", "sanction_amount_pln": 5000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja BDO: brak rejestracji — 5000 PLN.",
    "_legal_basis": "Art. 194 Ustawy o odpadach",
    "_warnings": ["[MICRO] BDO SANKCJA: brak rejestracji = 5000 PLN. Zarejestruj się w BDO i ureguluj opłatę. Odwołanie do SKO w ciągu 14 dni."]
} { object.get(input.business, "bdo_violation_code", "") == "NO_REGISTRATION" }

# jdg.micro.bdo_zezwolenia.r5: sanction_no_ledger — kara: brak ewidencji
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.r5",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82405,
    "micro_rule_active": true,
    "sanction_type": "ADMINISTRACYJNA", "sanction_amount_pln": 10000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja BDO: brak ewidencji — 10 000 PLN.",
    "_legal_basis": "Art. 195 Ustawy o odpadach",
    "_warnings": ["[MICRO] BDO SANKCJA: brak ewidencji odpadów = 10 000 PLN. Uzupełnij ewidencję kwartalną w systemie BDO natychmiast!"]
} { object.get(input.business, "bdo_violation_code", "") == "NO_LEDGER" }

# jdg.micro.bdo_zezwolenia.r6: sanction_illegal_storage — kara: nielegalne magazynowanie
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.r6",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82406,
    "micro_rule_active": true,
    "sanction_type": "ADMINISTRACYJNA", "sanction_amount_pln": 100000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja BDO: nielegalne magazynowanie — 100 000 PLN!",
    "_legal_basis": "Art. 197 Ustawy o odpadach",
    "_warnings": ["[MICRO] BDO SANKCJA: nielegalne magazynowanie odpadów = 100 000 PLN! Przekaż odpady do uprawnionego odbiorcy w ciągu 14 dni."]
} { object.get(input.business, "bdo_violation_code", "") == "ILLEGAL_STORAGE" }

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_zezwolenia.fallback",
    "package": "jdg.micro.bdo_zezwolenia", "priority": 82499,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa o odpadach",
    "_warnings": ["[MICRO] BDO zezwolenia — brak naruszeń. DGO/BAT prawidłowe."]
} { true }
