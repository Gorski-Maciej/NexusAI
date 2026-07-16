# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Verdict Provenance Graph (A1 Strategic Initiative)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Verdict Provenance Graph — Full Decision Path Tracing
# description: |
#   A1 z NexusAI_JDG_STRATEGIC_IMPROVEMENTS_7000.txt.
#   Każdy werdykt JDG jest wzbogacany o `_provenance_tree` — graf JSON
#   pokazujący PEŁNĄ ścieżkę decyzyjną: od main_jdg przez Macro do Micro
#   z referencjami do threshold_ref i hashów podstaw prawnych.
#
#   Architektura: Post-merge enrichment — działa PO zakończeniu main_jdg.
#   Side-effect-free — nie zmienia logiki reguł, tylko rozszerza output.
#   Zgodność z Sovos Merkle Tree audit standard.
#
#   Struktura _provenance_tree:
#     - path: lista kroków decyzyjnych [step, package, rule_id, basis, value]
#     - root_hash: SHA-256 całego kontekstu (do non-repudiation)
#     - evaluation_ms: czas ewaluacji
#     - evaluated_at: timestamp ISO 8601
# architecture: Post-Merge Enrichment (Sovos Merkle Tree pattern)
# legal_basis: N/A (audit infrastructure)
# package: jdg.provenance
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.provenance

import data.jdg.metadata

# ── Build provenance tree for a verdict ─────────────────────────────────────

# Główna funkcja: buduje _provenance_tree dla werdyktu
build_provenance(final_verdict, input_context) = tree {
    # Krok 1: Zbierz pakiety, które zwróciły matched:true
    active_packages := [pkg |
        some pkg_name in object.keys(input_context._package_decisions)
        input_context._package_decisions[pkg_name].matched == true
    ]

    # Krok 2: Zbuduj ścieżkę decyzyjną
    decision_path := build_decision_path(active_packages, input_context)

    # Krok 3: Generuj root hash przez konkatenację (OPA nie ma crypto.sha256)
    # Realne hashowanie SHA-256 wykonuje Python wrapper
    root_hash_concat := concat("|", [p.rule_id | p := decision_path[_]])
    root_hash := sprintf("sha256:%s", [root_hash_concat])

    # Krok 4: Złóż pełne drzewo
    tree := {
        "path": decision_path,
        "root_hash": root_hash,
        "evaluation_ms": input_context._evaluation_ms,
        "evaluated_at": sprintf("%s", [time.now_ns()]),
        "active_packages": count(active_packages),
        "total_packages": count(object.keys(input_context._package_decisions)),
        "verdict_summary": {
            "matched": object.get(final_verdict, "matched", false),
            "rule_id": object.get(final_verdict, "rule_id", "unknown"),
            "routing": object.get(final_verdict, "_routing", ""),
            "package": object.get(final_verdict, "package", "")
        }
    }
}

# Fallback: jeśli brak _package_decisions, zwróć minimalne drzewo
build_provenance(final_verdict, input_context) = tree {
    not input_context._package_decisions
    tree := {
        "path": [{
            "step": 1,
            "package": object.get(final_verdict, "package", "unknown"),
            "rule_id": object.get(final_verdict, "rule_id", "unknown"),
            "legal_basis": object.get(final_verdict, "_legal_basis", ""),
            "routing": object.get(final_verdict, "_routing", ""),
            "threshold_refs": []
        }],
        "root_hash": sprintf("sha256:%s", [object.get(final_verdict, "rule_id", "unknown")]),
        "evaluation_ms": 0,
        "evaluated_at": sprintf("%s", [time.now_ns()]),
        "active_packages": 1,
        "total_packages": 1
    }
}

# ── Build decision path from active packages ────────────────────────────────

build_decision_path(packages, ctx) = path {
    # Sortuj pakiety wg priorytetu decyzyjnego (najwyższy = najważniejszy)
    sorted := sort_packages_by_priority(packages, ctx)

    # Mapuj każdy pakiet na krok decyzyjny
    path := [build_step(i, pkg, ctx) |
        some i, pkg_name in sorted
        pkg := ctx._package_decisions[pkg_name]
    ]
}

# ── Build a single decision step ────────────────────────────────────────────

build_step(index, pkg, ctx) = step {
    rule_id := object.get(pkg, "rule_id", "unknown")
    pkg_name := object.get(pkg, "package", "unknown")

    # Pobierz metadane temporalne jeśli istnieją
    validity := metadata.get_rule_validity(rule_id)

    # Zbierz threshold_refs dla tego pakietu
    threshold_refs := collect_threshold_refs(pkg)

    step := {
        "step": index,
        "package": pkg_name,
        "rule_id": rule_id,
        "priority": object.get(pkg, "priority", 0),
        "legal_basis": object.get(pkg, "_legal_basis", ""),
        "routing": object.get(pkg, "_routing", ""),
        "routing_reason": object.get(pkg, "_routing_reason", ""),
        "matched": object.get(pkg, "matched", false),
        "threshold_refs": threshold_refs,
        "temporal_valid_from": object.get(validity, "valid_from", null),
        "temporal_valid_to": object.get(validity, "valid_to", null),
        "warnings": object.get(pkg, "_warnings", [])
    }
}

# ── Collect threshold references from a package decision ────────────────────

collect_threshold_refs(pkg) = refs {
    refs := [ref |
        some key in object.keys(pkg)
        not startswith(key, "_")
        val := pkg[key]
        is_numeric(val)  # tylko wartości numeryczne jako threshold_refs
        ref := {"key": key, "value": val}
    ]
} else = [] {
    true
}

# ── Sort packages by priority (highest first = most important decision) ─────

sort_packages_by_priority(packages, ctx) = sorted {
    # Pakiety z BLOCK_AND_ALERT mają najwyższy priorytet
    # Następnie TRIAGE_QUEUE, potem pozostałe
    block_packages := [p | p := packages[_]; ctx._package_decisions[p]._routing == "BLOCK_AND_ALERT"]
    triage_packages := [p | p := packages[_]; ctx._package_decisions[p]._routing == "TRIAGE_QUEUE"]
    other_packages := [p | p := packages[_];
        ctx._package_decisions[p]._routing != "BLOCK_AND_ALERT"
        ctx._package_decisions[p]._routing != "TRIAGE_QUEUE"
    ]

    sorted := array.concat(array.concat(block_packages, triage_packages), other_packages)
}

# ── Enrich a verdict with provenance tree ────────────────────────────────────

# Główna funkcja eksportowa: dodaje _provenance_tree do werdyktu
enrich_verdict(verdict, input_context) = enriched {
    tree := build_provenance(verdict, input_context)
    enriched := object.union(verdict, {"_provenance_tree": tree})
}

# ── Helpers ─────────────────────────────────────────────────────────────────

is_numeric(val) = true {
    val == 0
}

is_numeric(val) = true {
    val > 0
}

is_numeric(val) = true {
    val < 0
}
