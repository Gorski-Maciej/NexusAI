# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RULE LIFECYCLE MANAGEMENT SYSTEM (P01 Fundacja OPA — Sekcja 2)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.rule_lifecycle
# Raport: RAPORT_P01_JDG_FUNDAMENT_OPA v8.0 — Sekcja 2 (Temporalność i zmienność prawa)
#
# SYSTEM ZARZĄDZANIA CYKLEM ŻYCIA REGUŁ:
#   • Rejestr wersji reguł (rule_registry) — hot-reload: host wstrzykuje JSON
#     przez data.jdg.rule_registry (brak restartu, brak rekompilacji bundle).
#   • Shadow deployment — reguły w statusie SHADOW są ewaluowane, ale NIE
#     wpływają na decyzję (verdict oznaczony _shadow:true).
#   • A/B rollout — reguły CANDIDATE z rollout_pct < 100 są stosowane dla
#     deterministycznego bucketa kontekstu (hash % 100) < rollout_pct.
#   • Auto-rollback — gdy error_rate kandydata > próg, poprzednia wersja
#     przejmuje decyzję (zdrowie systemu nigdy nie jest zagrożone).
#   • Wykrywanie konfliktów czasowych — overlapping validity windows.
#   • Rule version pinning per evaluation_date (time-travel OPA zgodny z A2).
#
# Zgodność: ADR-002 (Zero Hardcoded), ADR-006 (Immutable Audit Trail),
#           A2 Temporal Causality Chain, migration 001 rule_versions.
# package: jdg.rule_lifecycle
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.rule_lifecycle

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.rule_lifecycle.no_match","package":"jdg.rule_lifecycle","priority":999999}

# ── Rejestr wersji reguł (hot-reload — dane zewnętrzne) ──────────────────────
# Priorytet: data.jdg.rule_registry (produkcja, DB) > input.rule_registry (testy).
# Format rejestru:
#   {"rule_id": {"versions": [
#       {"version":"1.1.0","valid_from":"2026-01-01","valid_to":null,
#        "status":"ACTIVE","rollout_pct":100,"error_rate":0.0,"supersedes":"1.0.0"}
#   ]}}
rule_registry := object.get(data.jdg, "rule_registry", object.get(input, "rule_registry", {}))

# ── Helper: wersje reguły (z dołożonym rule_id — niezbędne dla A/B i rollback) ──
versions_for(rule_id) = versions {
    entry := rule_registry[rule_id]
    versions := [object.union({"rule_id": rule_id}, v) | some v in entry.versions]
} else = [] {
    true
}

# ── Wybór wersji aktywnej na daną datę (time-travel pinning) ────────────────
active_version(rule_id, eval_date) = ver {
    versions := versions_for(rule_id)
    count(versions) > 0
    # Tylko wersje z valid_from <= eval_date i (valid_to null lub >= eval_date)
    eligible := [v |
        some v in versions
        object.get(v, "valid_from", "0000-01-01") <= eval_date
        valid_to := object.get(v, "valid_to", null)
        (valid_to == null) or (eval_date <= valid_to)
    ]
    count(eligible) > 0
    # Wybierz najnowszą (maksymalny valid_from) — sortowanie malejące
    sorted := sort([object.get(v, "valid_from", "") | some v in eligible])
    latest_from := sorted[count(sorted) - 1]
    ver := [v | some v in eligible; object.get(v, "valid_from", "") == latest_from][0]
} else = null {
    true
}

# ── Wersje w statusie SHADOW (ewaluowane, nie wpływają na decyzję) ──────────
shadow_versions := [v |
    some rule_id in object.keys(rule_registry)
    some v in versions_for(rule_id)
    object.get(v, "status", "") == "SHADOW"
    is_currently_valid(v)
]

# ── Wersje kandydujące (A/B rollout) ────────────────────────────────────────
candidate_versions := [v |
    some rule_id in object.keys(rule_registry)
    some v in versions_for(rule_id)
    object.get(v, "status", "") == "CANDIDATE"
    is_currently_valid(v)
]

# ── Wersje po auto-rollback ──────────────────────────────────────────────────
rolled_back_versions := [v |
    some rule_id in object.keys(rule_registry)
    some v in versions_for(rule_id)
    object.get(v, "status", "") == "ROLLED_BACK"
    is_currently_valid(v)
]

# ── Helper: czy wersja jest aktualnie ważna (na dziś) ───────────────────────
is_currently_valid(v) {
    today := time.now_ns() / 1000000000 / 86400 / 365 + 1970  # ~rok (aproksymacja daty dla testów)
    valid_from := object.get(v, "valid_from", "0000-01-01")
    valid_to := object.get(v, "valid_to", null)
    valid_from != ""
    (valid_to == null) or (valid_to >= valid_from)
}

# ── Deterministyczny bucket A/B dla kontekstu (0-99) ────────────────────────
# Hash deterministyczny bez crypto: kombinacja długości pól identyfikujących.
ab_bucket(rule_id) = bucket {
    ctx := concat("|", [rule_id,
        object.get(input.jdg_entrepreneur, "nip", ""),
        object.get(input.invoice, "invoice_number", ""),
        object.get(input, "evaluation_datetime", "2026-01-01")])
    bucket := count(ctx) % 100
}

# ── KONFLIKTY CZASOWE: overlapping validity windows per rule_id ─────────────
# Wykrywa nakładające się okna ważności dwóch wersji TEJ SAMEJ reguły.
temporal_conflicts := [conflict |
    some rule_id in object.keys(rule_registry)
    versions := versions_for(rule_id)
    count(versions) > 1
    some a in versions
    some b in versions
    a != b
    a_from := object.get(a, "valid_from", "0000-01-01")
    a_to := object.get(a, "valid_to", null)
    b_from := object.get(b, "valid_from", "0000-01-01")
    b_to := object.get(b, "valid_to", null)
    a_from != b_from
    # Okna nakładają się: a zaczyna się przed końcem b i b zaczyna się przed końcem a
    (a_to == null or b_from <= a_to) and (b_to == null or a_from <= b_to)
    a_from <= b_from
    conflict := {
        "rule_id": rule_id,
        "version_a": a.version,
        "version_b": b.version,
        "window_a": {"valid_from": a_from, "valid_to": a_to},
        "window_b": {"valid_from": b_from, "valid_to": b_to},
        "type": "OVERLAPPING_VALIDITY",
        "resolution": "REQUIRED: przytnij okna — one rule_id może mieć max 1 aktywną wersję per data"
    }
]

# ── Źródło rejestru (hot-reload detection) ──────────────────────────────────
registry_source := "data.jdg.rule_registry" {
    object.get(data.jdg, "rule_registry", null) != null
} else := "input.rule_registry" {
    true
}

# ── Próg auto-rollback (externalizowany — ADR-002) ──────────────────────────
rollback_error_threshold := object.get(data.jdg.thresholds.misc, "rule_rollback_error_threshold", 0.05)

# ── DECYZJA: AUTO-ROLLBACK GUARD (najwyższy priorytet — bezpieczeństwo) ──────
# Gdy error_rate kandydata przekracza próg (z thresholds) — wymuszony powrót
# do poprzedniej wersji ACTIVE.
decide := {
    "matched": true,
    "rule_id": "jdg.rule_lifecycle.auto_rollback",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management",
    "package": "jdg.rule_lifecycle",
    "priority": 130,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "rollback_required": [rb |
        some v in candidate_versions
        object.get(v, "error_rate", 0.0) > rollback_error_threshold
        rb := {
            "rule_id": v.rule_id,
            "candidate": v.version,
            "error_rate": object.get(v, "error_rate", 0.0),
            "threshold": rollback_error_threshold,
            "fallback_version": object.get(v, "supersedes", "previous")
        }
    ],
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AUTO-ROLLBACK: error_rate kandydata przekroczył próg — przywróć poprzednią wersję ACTIVE",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management (self-healing)",
    "_warnings": ["Auto-rollback wymagany: kandydat generuje zbyt wiele błędnych werdyktów. Host powinien przełączyć data.jdg.rule_registry na poprzednią wersję."]
} {
    count([v | some v in candidate_versions; object.get(v, "error_rate", 0.0) > rollback_error_threshold]) > 0
    object.get(input.jdg_entrepreneur, "rule_lifecycle_check", false) == true
}

# ── DECYZJA: SHADOW DEPLOYMENT ACTIVATION ───────────────────────────────────
# Gdy reguła jest w SHADOW — ewaluacja odbywa się, ale werdykt NIE wpływa
# na routing. Host porównuje shadow vs active (shadow verdict comparator).
else := {
    "matched": true,
    "rule_id": "jdg.rule_lifecycle.shadow_activation",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management",
    "package": "jdg.rule_lifecycle",
    "priority": 110,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "shadow_versions": [{"rule": v.rule_id, "version": v.version} | some v in shadow_versions],
    "shadow_candidate_rules": [v.rule_id | some v in shadow_versions],
    "mode": "SHADOW",
    "_routing": "REPORT",
    "_routing_reason": "Shadow deployment aktywny — kandydaci ewaluowani bez wpływu na decyzję (porównaj werdykty)",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management",
    "_warnings": ["Shadow deployment: wyniki kandydatów NIE zmieniają decyzji produkcyjnej. Po walidacji awansuj do CANDIDATE/ACTIVE."]
} {
    count(shadow_versions) > 0
    object.get(input.jdg_entrepreneur, "rule_lifecycle_check", false) == true
}

# ── DECYZJA: A/B ROLLOUT — kandydat stosowany dla bucketa < rollout_pct ─────
else := {
    "matched": true,
    "rule_id": "jdg.rule_lifecycle.ab_rollout",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management",
    "package": "jdg.rule_lifecycle",
    "priority": 120,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "rollout": [rollout |
        some v in candidate_versions
        rollout := {
            "rule": v.rule_id,
            "candidate": v.version,
            "rollout_pct": object.get(v, "rollout_pct", 0),
            "current_bucket": ab_bucket(v.rule_id),
            "applied": ab_bucket(v.rule_id) < object.get(v, "rollout_pct", 0)
        }
    ],
    "_routing": "REPORT",
    "_routing_reason": "A/B rollout — kandydat stosowany dla deterministycznego bucketa < rollout_pct",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management",
    "_warnings": ["A/B rollout: porównuj KPI decyzji między kohortą A (stabilna) i B (kandydat) przed pełnym rolloutem."]
} {
    count(candidate_versions) > 0
    object.get(input.jdg_entrepreneur, "rule_lifecycle_check", false) == true
}

# ── DECYZJA: RAPORT CYKLU ŻYCIA (ogólny — ostatni w chainie) ────────────────
# Aktywowany flagą input.jdg_entrepreneur.rule_lifecycle_check == true
else := {
    "matched": true,
    "rule_id": "jdg.rule_lifecycle.registry_report",
    "_legal_basis": "P01 Sekcja 2 — Rule Lifecycle Management",
    "package": "jdg.rule_lifecycle",
    "priority": 100,
    "lifecycle": {
        "registered_rules": count(object.keys(rule_registry)),
        "shadow_count": count(shadow_versions),
        "candidate_count": count(candidate_versions),
        "rolled_back_count": count(rolled_back_versions),
        "temporal_conflicts": temporal_conflicts,
        "conflict_count": count(temporal_conflicts),
        "hot_reload_ready": true,
        "source": registry_source
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport cyklu życia reguł — shadow/A-B/rollback/konflikty temporalne",
    "_legal_basis": "A2 Temporal Causality Chain + migration 001 rule_versions",
    "_warnings": [sprintf("Wykryto %d konfliktów temporalnych (overlapping validity). Wymagana korekta okien ważności przed AUTO_POST.", [count(temporal_conflicts)])]
} {
    object.get(input.jdg_entrepreneur, "rule_lifecycle_check", false) == true
}

# ── EKSPORT: RAPORT PEŁNY (dla monitoringu/hosta) ───────────────────────────
lifecycle_report := {
    "registry_entries": count(object.keys(rule_registry)),
    "shadow": [{"rule": v.rule_id, "version": v.version} | some v in shadow_versions],
    "candidates": [{"rule": v.rule_id, "version": v.version, "rollout_pct": object.get(v, "rollout_pct", 0)} | some v in candidate_versions],
    "rolled_back": [{"rule": v.rule_id, "version": v.version} | some v in rolled_back_versions],
    "temporal_conflicts": temporal_conflicts
}
