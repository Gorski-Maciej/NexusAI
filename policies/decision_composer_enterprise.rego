# NexusAI JDG — Enterprise decision composition orchestrator.
# Aggregates package routings using BLOCK > TRIAGE > WARNING > FALLBACK > empty.
# Legal basis: ADR-001 Multi-Pass Architecture.

package jdg.decision_composer

import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.decision_composer.no_match",
    "package": "jdg.decision_composer",
    "priority": 9999
}

routing_priority := {
    "BLOCK_AND_ALERT": 5,
    "TRIAGE_QUEUE": 4,
    "WARNING": 3,
    "FALLBACK_ACTIVE": 2,
    "": 0
}

base_fields := {
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false
}

package_decisions := object.get(input, "package_decisions", [])
total_decisions := count(package_decisions)

block_decisions := [x | x := package_decisions[_]; object.get(x, "_routing", "") == "BLOCK_AND_ALERT"]
triage_decisions := [x | x := package_decisions[_]; object.get(x, "_routing", "") == "TRIAGE_QUEUE"]
warning_decisions := [x | x := package_decisions[_]; object.get(x, "_routing", "") == "WARNING"]
fallback_decisions := [x | x := package_decisions[_]; object.get(x, "_routing", "") == "FALLBACK_ACTIVE"]

block_count := count(block_decisions)
triage_count := count(triage_decisions)
warning_count := count(warning_decisions)
fallback_count := count(fallback_decisions)

routings_found := {routing |
    decision := package_decisions[_]
    routing := object.get(decision, "_routing", "")
}
routing_priorities := [object.get(routing_priority, routing, 0) | routing := routings_found[_]]
highest_priority := max(array.concat([0], routing_priorities))

final_routing_for(priority, routings) = routing if {
    priority > 0
    routing := [candidate |
        candidate := routings[_]
        object.get(routing_priority, candidate, 0) == priority
    ][0]
} else = "" if {
    true
}

final_routing := final_routing_for(highest_priority, routings_found)
source_packages := {package_name |
    decision := package_decisions[_]
    package_name := object.get(decision, "package", "")
}

composer_reason := sprintf("KOMPOZYCJA DECYZJI: %d pakietów → routing '%s'. BLOCK: %d, TRIAGE: %d, WARN: %d, FALLBACK: %d.", [total_decisions, final_routing, block_count, triage_count, warning_count, fallback_count])

build_composer_warnings(routing, block, triage, warn, fallback, total, packages) = warnings if {
    package_list := concat(", ", [package_name | package_name := packages[_]])
    warnings := [
        "═══════════════════════════════════════════",
        sprintf("🔗 DECISION COMPOSER — AGREGUJĘ %d PAKIETÓW", [total]),
        sprintf("   Pakiety: %s", [package_list]),
        sprintf("   BLOCK: %d | TRIAGE: %d | WARN: %d | FALLBACK: %d", [block, triage, warn, fallback]),
        sprintf("   ➡️ DOMINUJĄCY ROUTING: %s", [routing]),
        "═══════════════════════════════════════════"
    ]
}

# DCC-2250: routing aggregator.
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.decision_composer.routing_aggregator",
    "package": "jdg.decision_composer",
    "priority": 2250,
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
}) if {
    object.get(input, "decision_composition_active", false) == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.decision_composer.conflict_detector",
    "package": "jdg.decision_composer",
    "priority": 2255,
    "composer_has_conflicts": has_conflicts,
    "composer_conflicting_packages": conflicting_packages,
    "composer_conflict_description": conflict_description,
    "_routing": conflict_routing,
    "_routing_reason": conflict_reason,
    "_legal_basis": "ADR-001; Reguły rozstrzygania konfliktów między pakietami",
    "_warnings": build_conflict_warnings(has_conflicts, conflicting_packages, conflict_description)
}) if {
    object.get(input, "decision_composition_conflict_check", false) == true
}

# DCC-2255: conflict detector.
has_conflicts = true if {
    count(block_decisions) > 0
    count(triage_decisions) > 0
} else = false if {
    true
}

conflicting_packages := array.concat(
    [object.get(decision, "package", "") | decision := block_decisions[_]],
    [object.get(decision, "package", "") | decision := triage_decisions[_]]
)

conflict_description = sprintf("KONFLIKT: %d pakietów BLOCK vs %d pakietów TRIAGE. BLOCK dominuje (wyższy priorytet).", [block_count, triage_count]) if {
    has_conflicts == true
} else = "Brak konfliktów między pakietami." if {
    true
}

conflict_routing = "BLOCK_AND_ALERT" if {
    has_conflicts == true
} else = "" if {
    true
}

conflict_reason = conflict_description if {
    has_conflicts == true
} else = "" if {
    true
}

build_conflict_warnings(has, packages, description) = warnings if {
    has == true
    package_list := concat(", ", [package_name | package_name := packages[_]])
    warnings := [
        sprintf("⚠️ KONFLIKT DECYZJI: %s", [description]),
        sprintf("   Konfliktujące pakiety: %s", [package_list]),
        "   📋 ROZSTRZYGNIĘCIE: BLOCK_AND_ALERT dominuje nad TRIAGE_QUEUE.",
        "   Sprawdź czy blokada jest uzasadniona — może wymagać eskalacji."
    ]
} else = ["✅ DECISION COMPOSER: brak konfliktów między pakietami."] if {
    true
}
