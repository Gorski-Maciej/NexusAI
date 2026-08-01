# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE DECISION COMPOSITION ORCHESTRATOR (LUKA-A1, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Decision Composition — Multi-Package Routing Aggregator
# description: |
#   ENTERPRISE v7.0 — Reguła kompozycji decyzji dla architektury Multi-Pass.
#   Wypełnia lukę A1 z raportu P18: gdy wiele pakietów zwraca różne routingu
#   (np. BLOCK z jdg.ksef_jpk i TRIAGE z jdg.jpk_v7_autogen), reguła ta
#   określa priorytet agregacji.
#
#   REGUŁY AGREGACJI:
#   1. BLOCK_AND_ALERT > wszystkie inne (jeśli jakikolwiek pakiet blokuje → blokada)
#   2. TRIAGE_QUEUE > WARNING > FALLBACK_ACTIVE > pusty
#   3. Routing pusty (\"\") = najniższy priorytet
#   4. Warningi łączone ze wszystkich pasujących pakietów
#   5. Podstawy prawne agregowane unikalnie
#
# architecture: Enterprise v7.0 Decision Aggregator (Multi-Pass ADR-001)
# package: jdg.decision_composer
# deprecated: false
# priority_range: 2250-2269
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.decision_composer

default decide := {
    "matched": false, "rule_id": "jdg.decision_composer.no_match",
    "package": "jdg.decision_composer", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# DCC-2250: ROUTING AGGREGATOR — Agregacja routingów z wielu pakietów
# ═══════════════════════════════════════════════════════════════════════════════

# Kolejność priorytetów routingu (od najwyższego):
# BLOCK_AND_ALERT > TRIAGE_QUEUE > WARNING > FALLBACK_ACTIVE > ""
routing_priority := {
    "BLOCK_AND_ALERT": 5,
    "TRIAGE_QUEUE": 4,
    "WARNING": 3,
    "FALLBACK_ACTIVE": 2,
    "": 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.decision_composer.routing_aggregator",
    "package": "jdg.decision_composer",
    "priority": 2250,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "composer_aggregated_routing": final_routing,
    "composer_source_packages": source_packages,
    "composer_block_count": block_count,
    "composer_triage_count": triage_count,
    "composer_warning_count": warning_count,
    "composer_fallback_count": fallback_count,
    "composer_total_decisions": total_decisions,
    "_routing": final_routing,
    "_routing_reason": composer_reason,
    "_legal_basis": "ADR-001 (Multi-Pass Architecture); Kompozycja decyzji wielopakietowej",
    "_warnings": build_composer_warnings(final_routing, block_count, triage_count, warning_count, fallback_count, total_decisions, source_packages)
} {
    input.decision_composition_active == true

    # Wejściowe decyzje z poszczególnych pakietów (dostarczane przez orchestrator)
    package_decisions := object.get(input, "package_decisions", [])
    total_decisions := count(package_decisions)

    # Zlicz routingi z poszczególnych pakietów
    block_count := count({x | x := package_decisions[_]; object.get(x, "_routing", "") == "BLOCK_AND_ALERT"})
    triage_count := count({x | x := package_decisions[_]; object.get(x, "_routing", "") == "TRIAGE_QUEUE"})
    warning_count := count({x | x := package_decisions[_]; object.get(x, "_routing", "") == "WARNING"})
    fallback_count := count({x | x := package_decisions[_]; object.get(x, "_routing", "") == "FALLBACK_ACTIVE"})

    # Określ dominujący routing: najwyższy priorytet wygrywa
    routings_found := {r | r := object.get(package_decisions[_], "_routing", "")}
    routing_priorities := [object.get(routing_priority, r, 0) | r := routings_found[_]]
    highest_priority := max(routing_priorities)
    final_routing := [r | r := routings_found[_]; object.get(routing_priority, r, 0) == highest_priority][0] { highest_priority > 0 }

    # Zbierz źródłowe pakiety
    source_packages := {p | p := object.get(package_decisions[_], "package", "")}

    composer_reason := sprintf("KOMPOZYCJA DECYZJI: %d pakietów → routing '%s'. BLOCK: %d, TRIAGE: %d, WARN: %d, FALLBACK: %d.", [total_decisions, final_routing, block_count, triage_count, warning_count, fallback_count])
}

build_composer_warnings(routing, block, triage, warn, fallback, total, packages) = warnings {
    package_list := concat(", ", [p | p := packages[_]])
    warnings := [
        "═══════════════════════════════════════════",
        sprintf("🔗 DECISION COMPOSER — AGREGUJĘ %d PAKIETÓW", [total]),
        sprintf("   Pakiety: %s", [package_list]),
        sprintf("   BLOCK: %d | TRIAGE: %d | WARN: %d | FALLBACK: %d", [block, triage, warn, fallback]),
        sprintf("   ➡️ DOMINUJĄCY ROUTING: %s", [routing]),
        "═══════════════════════════════════════════",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# DCC-2255: CONFLICT DETECTOR — Wykrywanie konfliktów między pakietami
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.decision_composer.conflict_detector",
    "package": "jdg.decision_composer",
    "priority": 2255,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "composer_has_conflicts": has_conflicts,
    "composer_conflicting_packages": conflicting,
    "composer_conflict_description": conflict_desc,
    "_routing": conflict_routing,
    "_routing_reason": conflict_reason,
    "_legal_basis": "ADR-001; Reguły rozstrzygania konfliktów między pakietami",
    "_warnings": build_conflict_warnings(has_conflicts, conflicting, conflict_desc)
} {
    input.decision_composition_conflict_check == true

    package_decisions := object.get(input, "package_decisions", [])
    blocks := [x | x := package_decisions[_]; object.get(x, "_routing", "") == "BLOCK_AND_ALERT"]
    triages := [x | x := package_decisions[_]; object.get(x, "_routing", "") == "TRIAGE_QUEUE"]

    # Konflikt: BLOCK + TRIAGE w różnych pakietach
    has_conflicts := count(blocks) > 0; count(triages) > 0

    conflicting := {}
    conflicting := array.concat(conflicting, [object.get(blocks[_], "package", "")]) { count(blocks) > 0 }
    conflicting := array.concat(conflicting, [object.get(triages[_], "package", "")]) { count(triages) > 0 }

    conflict_desc := sprintf("KONFLIKT: %d pakietów BLOCK vs %d pakietów TRIAGE. BLOCK dominuje (wyższy priorytet).", [count(blocks), count(triages)]) { has_conflicts }
    conflict_desc := "Brak konfliktów między pakietami." { not has_conflicts }

    conflict_routing := "BLOCK_AND_ALERT" { has_conflicts }
    conflict_routing := "" { true }
    conflict_reason := conflict_desc { has_conflicts }
    conflict_reason := "" { true }
}

build_conflict_warnings(has, conf, desc) = warnings {
    has
    conf_list := concat(", ", [c | c := conf[_]])
    warnings := [
        sprintf("⚠️ KONFLIKT DECYZJI: %s", [desc]),
        sprintf("   Konfliktujące pakiety: %s", [conf_list]),
        "   📋 ROZSTRZYGNIĘCIE: BLOCK_AND_ALERT dominuje nad TRIAGE_QUEUE.",
        "   Sprawdź czy blokada jest uzasadniona — może wymagać eskalacji."
    ]
} else = ["✅ DECISION COMPOSER: brak konfliktów między pakietami."]
