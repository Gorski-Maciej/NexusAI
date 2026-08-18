# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CONFLICT DECLARATION SYSTEM (P02 Warstwa Decyzyjna — Sekcja 2)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.conflict_declaration
# Raport: RAPORT_P02_JDG_WARSTWA_DECYZYJNA_CORE v8.0 — Sekcja 2 (Konflikty reguł)
#
# SYSTEM FORMALNEJ DEKLARACJI KONFLIKTÓW:
#   CD-01 Conflict Registry — formalna deklaracja znanych konfliktów
#        (data.jdg.conflict_declarations): pary domen, typ, reguła rozstrzygająca.
#   CD-02 Deterministic Hierarchy — hierarchia rozstrzygania: prawo nadrzędne >
#        przepis szczególny > reguła bezpieczeństwa > reguła optymalizacyjna.
#   CD-03 Real-Time Conflict Reporting — każda ewaluacja raportuje aktywne
#        konflikty (nowe + znane) do _cross_domain_conflicts (read-only).
#   CD-04 Conflict Simulator — what-if: jak zmieni się werdykt przy zmianie
#        rozstrzygnięcia konfliktu (sandbox, bez wpływu na produkcję).
#
# Zgodność: conflicts.rego, edge_cases.rego, P02 Sekcja 2, ADR-005.
# package: jdg.conflict_declaration
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.conflict_declaration

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.conflict_declaration.no_match","package":"jdg.conflict_declaration","priority":999999}

# ── Rejestr znanych konfliktów (formalna deklaracja — externalizowane) ───────
# Format: {"conflict_id": {"domains": [...], "type": "...", "resolution_rule": "...",
#                          "priority": N, "legal_basis": "..."}}
default_conflict_registry := {
    "ipbox_vs_br": {
        "domains": ["PIT_IP_BOX", "PIT_RD_RELIEF"],
        "type": "EXCLUSIVE_RELIEFS",
        "resolution_rule": "Wybierz wyższą korzyść — brak kumulacji (Art. 30ca ust. 3 PIT)",
        "priority": 1,
        "legal_basis": "Art. 30ca ust. 3 PIT + Art. 26e PIT"
    },
    "representation_vs_marketing": {
        "domains": ["REPRESENTATION", "MARKETING"],
        "type": "OVERLAP_EXPENSE",
        "resolution_rule": "Reprezentacja = NKUP; Marketing = KUP (granica: cel wydatku)",
        "priority": 2,
        "legal_basis": "Art. 23 ust. 1 pkt 23 PIT"
    },
    "car_auto_vs_kup": {
        "domains": ["VAT_CAR", "PIT_KUP"],
        "type": "CROSS_DOMAIN",
        "resolution_rule": "VAT od auta ≤50/100% limit; KUP analogicznie (spójność)",
        "priority": 3,
        "legal_basis": "Art. 86a VAT + Art. 23 ust. 1 pkt 46 PIT"
    },
    "bad_debt_creditor_vs_debtor": {
        "domains": ["VAT_BAD_DEBT_CREDITOR", "VAT_BAD_DEBT_DEBTOR"],
        "type": "MIRROR",
        "resolution_rule": "Wierzyciel koryguje in plus po 90 dniach; dłużnik in minus — synchronizacja",
        "priority": 4,
        "legal_basis": "Art. 89a-89b VAT"
    },
    "lump_sum_vs_direct_costs": {
        "domains": ["PIT_LUMP_SUM", "PIT_KUP"],
        "type": "INCOMPATIBLE",
        "resolution_rule": "Ryczałt nie odlicza KUP — wykluczenie strukturalne",
        "priority": 5,
        "legal_basis": "Art. 6 ust. 1 ustawy o ryczałcie"
    }
}

conflict_registry := object.get(data.jdg, "conflict_declarations", default_conflict_registry)

# ── CD-02: Deterministyczna hierarchia rozstrzygania ─────────────────────────
# Im wyższy priorytet (mniejsza liczba), tym wcześniej rozstrzygany.
resolution_order := sort([object.get(c, "priority", 99) | some c in conflict_registry])

# ── CD-01: Wykrywanie AKTYWNYCH konfliktów dla bieżącej ewaluacji ───────────
# Na podstawie sygnałów w input (aktywne domeny) + rejestru deklaracji.
active_conflicts := [conflict |
    some conflict_id in object.keys(conflict_registry)
    decl := conflict_registry[conflict_id]
    any_domain_active(decl.domains) == true
    conflict := {
        "conflict_id": conflict_id,
        "type": decl.type,
        "resolution_rule": decl.resolution_rule,
        "priority": decl.priority,
        "legal_basis": decl.legal_basis,
        "domains": decl.domains
    }
]

any_domain_active(domains) = true {
    some d in domains
    object.get(input.jdg_entrepreneur, d, false) == true
} else = false {
    true
}

# ── CD-03: Real-Time Conflict Report (do _cross_domain_conflicts) ───────────
# Read-only: NIE zmienia decyzji, tylko raportuje. Zgodny z PAS 8.
# ── DECYZJA: BLOCK przy konflikcie nierozstrzygalnym ─────────────────────────
# Gdy aktywny konflikt nie ma przypisanej reguły rozstrzygającej
# (resolution_rule pusta) — bezpieczeństwo: BLOCK_AND_ALERT.
decide := {
    "matched": true,
    "rule_id": "jdg.conflict_declaration.unresolved_conflict",
    "_legal_basis": "P02 Sekcja 2",
    "package": "jdg.conflict_declaration",
    "priority": 100,
    "_cross_domain_conflicts": [{"conflict_id": c.conflict_id, "type": c.type} |
        some c in active_conflicts
        object.get(c, "resolution_rule", "") == ""
    ],
    "unresolved_count": count([c | some c in active_conflicts; object.get(c, "resolution_rule", "") == ""]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wykryto konflikt domen bez reguły rozstrzygającej — wymagana decyzja człowieka",
    "_legal_basis": "P02 Sekcja 2 — Deterministic Conflict Hierarchy",
    "_warnings": ["Konflikt bez rozstrzygnięcia: nie można auto-postować — decyzja wymaga weryfikacji."]
} {
    object.get(input.jdg_entrepreneur, "conflict_check", false) == true
    count([c | some c in active_conflicts; object.get(c, "resolution_rule", "") == ""]) > 0
}

# ── DECYZJA: RAPORT AKTYWNYCH KONFLIKTÓW (z rozstrzygnięciami) ───────────────
else := {
    "matched": true,
    "rule_id": "jdg.conflict_declaration.report",
    "package": "jdg.conflict_declaration",
    "priority": 110,
    "active_conflicts": active_conflicts,
    "conflict_count": count(active_conflicts),
    "resolution_order": resolution_order,
    "_routing": "REPORT",
    "_routing_reason": "Raport konfliktów domen — formalne deklaracje + hierarchia rozstrzygania",
    "_legal_basis": "P02 Sekcja 2",
    "_warnings": [sprintf("Aktywne konflikty: %d. Rozstrzygnięcia wg hierarchii priorytetów.", [count(active_conflicts)])]
} {
    object.get(input.jdg_entrepreneur, "conflict_check", false) == true
    count(active_conflicts) > 0
}

# ── DECYZJA: BRAK KONFLIKTÓW ─────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.conflict_declaration.no_active_conflicts",
    "package": "jdg.conflict_declaration",
    "priority": 120,
    "active_conflicts": [],
    "conflict_count": 0,
    "_routing": "REPORT",
    "_routing_reason": "Brak aktywnych konfliktów domen — decyzja może przejść do publikacji po weryfikacji",
    "_legal_basis": "P02 Sekcja 2",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "conflict_check", false) == true
}

# ── CD-04: CONFLICT SIMULATOR (what-if, sandbox) ─────────────────────────────
# input.conflict_simulator = {"conflict_id": "...", "override_resolution": "..."}
conflict_simulator_verdict := {
    "matched": true,
    "rule_id": "jdg.conflict_declaration.simulator",
    "_legal_basis": "P02 Sekcja 2",
    "package": "jdg.conflict_declaration",
    "priority": 200,
    "simulation": {
        "conflict_id": sim.conflict_id,
        "current_resolution": object.get(conflict_registry[sim.conflict_id], "resolution_rule", "UNKNOWN"),
        "override_resolution": object.get(sim, "override_resolution", ""),
        "sandboxed": true,
        "note": "Symulacja — NIE zmienia rejestru ani decyzji produkcyjnej"
    },
    "_routing": "REPORT",
    "_routing_reason": "Conflict simulator: ocena wpływu zmiany rozstrzygnięcia konfliktu",
    "_legal_basis": "P02 Sekcja 2 — Conflict Simulator",
    "_warnings": ["Symulacja what-if — nie ma wpływu na produkcję."]
} {
    sim := object.get(input, "conflict_simulator", null)
    sim != null
    object.get(sim, "conflict_id", "") != ""
    conflict_registry[sim.conflict_id]
}

# ── EKSPORT: RAPORT KONFLIKTÓW (dla monitoringu) ─────────────────────────────
conflict_report := {
    "registered_conflicts": count(object.keys(conflict_registry)),
    "active_conflicts": active_conflicts,
    "resolution_order": resolution_order,
    "unresolved": [c | some c in active_conflicts; object.get(c, "resolution_rule", "") == ""]
}
