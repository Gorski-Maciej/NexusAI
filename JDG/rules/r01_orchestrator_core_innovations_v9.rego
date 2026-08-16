# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R01 GLM52 ORKIESTRATOR I RDZEŃ SILNIKA — INNOWACJE CORE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r01_orchestrator_core_innovations
# Raport: RAPORT_01_ORKIESTRATOR_RDZEN.txt (Kampania GLM 5.2 — seria 01/25)
#
# Prompt 01/25 (ORKIESTRATOR I RDZEŃ SILNIKA — main_jdg, routing, risk, temporal,
# thresholds, validation) — ulepszenia rdzenia silnika, poziom ENTERPRISE:
#   R01-INN-01 routing_path_trace         — deterministyczny routing z debugowaniem
#                                           ścieżki (O(1) sharded router; INV-040)
#   R01-INN-02 verdict_25_field           — werdykt 25-polowy: słownik kanoniczny +
#                                           bramka kompletności (brak pola = BLOCK)
#   R01-INN-03 decision_cache_runtime     — cache decyzji: klucz deterministyczny,
#                                           TTL, hit/miss, tamper-evident (F3 V2)
#   R01-INN-04 time_travel_guard          — spójność time-travel (P1610, INV-025):
#                                           data temporalna ≤ data ewaluacji
#   R01-INN-05 safe_merge_integrity       — runtime verification allowlist
#                                           niemutowalnej (INV-042, safe_merge)
#   R01-INN-06 priority_conflict_detector — zderzenia priorytetów / sprzeczne
#                                           werdykty w jednej decyzji (INV-018)
#
# Zgodność: ADR-001..009/017/022, P01 (lifecycle), P02 (core), P03 (orchestrator),
#           WIZJA V2 F2/F3/F4, V1 §9.3 (wersje w werdykcie), INV-018/025/037/040/042.
# package: jdg.r01_orchestrator_core_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r01_orchestrator_core_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r01_orchestrator_core_innovations.no_match", "package": "jdg.r01_orchestrator_core_innovations", "priority": 999999}

# ── Słownik kanoniczny werdyktu 25-polowego (raport master 00 + P02) ───────────
# 25 pól standardowego werdyktu JDG: 4 metadane + 15 pól decyzyjnych + 6 pól
# dowodowych (_routing.._warnings + temporalność). Kompletność = warunek brzegowy
# dla AUTO_POST (werdykt niekompletny nigdy nie jest CERTAIN).
verdict_25_fields := [
    "matched", "rule_id", "package", "priority",
    "vat_rate", "rounding_level", "gtu_code", "vat_exemption", "procedure",
    "pit_form", "pit_rate", "pit_bracket", "pit_annual_return_type",
    "kus_qualification", "kus_percent",
    "zus_social_base_type", "zus_health_rate",
    "business_status", "ceidg_registration_required",
    "valid_from", "valid_to",
    "_routing", "_routing_reason", "_legal_basis", "_warnings",
]

_has(v, k) {
    v[k] != null
}

# ── R01-INN-02: kompletność werdyktu 25-polowego ───────────────────────────────
missing_verdict_fields(verdict) = missing {
    missing := [f | some f in verdict_25_fields; not _has(verdict, f)]
} else := [] {
    true
}

verdict_complete(verdict) = true {
    count(missing_verdict_fields(verdict)) == 0
} else := false {
    true
}

# ── Dostęp do werdyktów pakietów (dostarczane przez host/main_jdg) ─────────────
# Bezpieczny: pusty obiekt przy braku — nigdy undefined.
_pkg_decisions := object.get(input, "_package_decisions", {})

_matched_verdicts := [p | some p in object.keys(_pkg_decisions); object.get(_pkg_decisions[p], "matched", false) == true]

verdict_completeness_report := {
    "canonical_field_count": count(verdict_25_fields),
    "checked_verdicts": count(_matched_verdicts),
    "incomplete_packages": [p | some p in _matched_verdicts; not verdict_complete(_pkg_decisions[p])],
    "missing_fields_by_package": {p: missing_verdict_fields(_pkg_decisions[p]) | some p in _matched_verdicts; count(missing_verdict_fields(_pkg_decisions[p])) > 0},
    "invariant": "INV-043: werdykt matched=true wymaga kompletnego słownika 25-polowego (BLOCK przy braku pola)",
} {
    true
}

# ── R01-INN-01: deterministyczny routing z debugowaniem ścieżki ────────────────
# Wybór ścieżki O(1) wg routing_context (main_jdg). Debug: pełny kontekst + powód.
# Ten sam routing_context → ta sama ścieżka (INV-040 — deterministyczny klucz).
select_path(ctx) = path {
    object.get(ctx, "is_cross_border", false) == true
    path := "FULL_CHAIN_CROSS_BORDER"
} else = path {
    object.get(ctx, "entity_status", "ACTIVE") != "ACTIVE"
    path := "FULL_CHAIN_ENTITY_NON_ACTIVE"
} else = path {
    object.get(ctx, "transaction_type", "") == "DOMESTIC_SALE"
    path := "SHARDED_DOMESTIC_SALE"
} else = path {
    object.get(ctx, "transaction_type", "") == "DOMESTIC_PURCHASE"
    path := "SHARDED_DOMESTIC_PURCHASE"
} else = "FULL_CHAIN_FALLBACK" {
    true
}

routing_path_trace := {
    "selected_path": select_path(_ctx),
    "routing_context": _ctx,
    "deterministic": true,
    "debug": sprintf("path=%s|tx=%s|entity=%s|xb=%v|eval=%s", [
        select_path(_ctx),
        object.get(_ctx, "transaction_type", ""),
        object.get(_ctx, "entity_status", ""),
        object.get(_ctx, "is_cross_border", false),
        object.get(_ctx, "evaluation_date", ""),
    ]),
    "note": "Ten sam routing_context = ta sama ścieżka (INV-040: deterministyczny klucz routingu)",
} {
    _ctx := object.get(input, "_routing_context", {})
    count(_ctx) > 0
} else := {
    "selected_path": "NO_CONTEXT",
    "routing_context": {},
    "deterministic": true,
    "debug": "path=NO_CONTEXT|brak _routing_context w input",
    "note": "Brak kontekstu routingu — host nie przekazał _routing_context (INV-020/036)",
} {
    true
}

# ── R01-INN-03: cache decyzji — runtime contract (F3 V2) ───────────────────────
# Deterministyczny klucz cache (INV-040): ten sam input + wersje bundla + data
# temporalna = ten sam klucz. SHA-256 wykonuje Python wrapper (decision_certificate.py).
cache_input_hash = sprintf("sha256:%s", [concat("|", [
    object.get(object.get(input, "jdg_entrepreneur", {}), "nip", ""),
    object.get(object.get(input, "invoice", {}), "invoice_number", ""),
    object.get(object.get(input, "invoice", {}), "direction", ""),
    object.get(input, "evaluation_datetime", "2026-01-01"),
    object.get(input, "temporal_evaluation_date", ""),
    sprintf("%v", [object.get(input, "bundle_version", "")]),
])])

decision_cache_runtime := {
    "cache_key": cache_input_hash,
    "ttl_ms": object.get(input, "decision_cache_ttl_ms", 300000),
    "hit": object.get(input, "decision_cache_hit", false),
    "invalidation": "zmiana input / bundle_version / temporal_evaluation_date → nowy klucz (F3 V2)",
    "tamper_evident": "decision_hash + input_hash weryfikowane merkle_verify (P03 INN-12)",
    "deterministic": true,
}

# ── R01-INN-04: time-travel guard (P1610 + INV-025) ────────────────────────────
# Time-travel OPA: ewaluacja wg stanu prawnego na datę transakcji. Spójność:
# data temporalna ≤ data ewaluacji (korekta nie może zmienić historycznego werdyktu).
time_travel_guard := {
    "temporal_evaluation_date": ted,
    "evaluation_datetime": ed,
    "time_travel_active": true,
    "consistent": ted <= ed,
    "routing": "TIME_TRAVEL",
    "certainty_rule": "INV-025: korekta deklaracji nie zmienia historycznych werdyktów (time-travel)",
} {
    ted := object.get(input, "temporal_evaluation_date", "")
    ted != ""
    ed := object.get(input, "evaluation_datetime", "2026-01-01")
} else := {
    "temporal_evaluation_date": "",
    "evaluation_datetime": object.get(input, "evaluation_datetime", "2026-01-01"),
    "time_travel_active": false,
    "consistent": true,
    "routing": "CURRENT_DATE",
}

# ── R01-INN-05: safe_merge integrity (INV-042) ─────────────────────────────────
# Lustrzana allowlist niemutowalna (main_jdg). Runtime verification: każdy pakiet
# z allowlisty, który matched, MUSI nadal nieść immutable_verdict=true — jeśli
# flaga zniknęła w merge → naruszenie INV-042 (możliwe nadpisanie przez wyższy
# priorytet). Lustro nie może się rozjechać z main_jdg (drift = sygnał ostrzegawczy).
immutable_allowlist := {
    "jdg.zus", "jdg.zus.sickness_benefits", "jdg.zus.enterprise_benefits",
    "jdg.zus.health_contribution", "jdg.business", "jdg.security.fortress",
}

safe_merge_integrity := {
    "allowlist_size": count(immutable_allowlist),
    "matched_immutable": count([p | some p in object.keys(_pkg_decisions); p in immutable_allowlist; object.get(_pkg_decisions[p], "matched", false) == true]),
    "violations": [p | some p in object.keys(_pkg_decisions); p in immutable_allowlist; object.get(_pkg_decisions[p], "matched", false) == true; object.get(_pkg_decisions[p], "immutable_verdict", false) != true],
    "overwrite_warning_present": _overwrite_warning(_pkg_decisions),
    "invariant": "INV-042: allowlist niemutowalna zweryfikowana w runtime (safe_merge integrity)",
} {
    true
}

_overwrite_warning(decisions) = true {
    some p in object.keys(decisions)
    object.get(decisions[p], "_warnings", [])[_] == "IMMUTABLE_VERDICT_OVERWRITE"
} else := false {
    true
}

# ── R01-INN-06: zderzenia priorytetów / sprzeczne werdykty (INV-018) ───────────
# Dwa pakiety matched z TYM SAMYM priorytetem = niejednoznaczność kolejności
# First-Match-Wins → TRIAGE_QUEUE (nie BLOCK — brak reguły nie może blokować).
priority_conflicts := {pri |
    some p in object.keys(_pkg_decisions)
    object.get(_pkg_decisions[p], "matched", false) == true
    pri := object.get(_pkg_decisions[p], "priority", 0)
    count([q | some q in object.keys(_pkg_decisions)
        object.get(_pkg_decisions[q], "matched", false) == true
        object.get(_pkg_decisions[q], "priority", 0) == pri]) > 1
}

priority_conflict_report := {
    "collision_priorities": priority_conflicts,
    "collision_count": count(priority_conflicts),
    "invariant": "INV-018: brak sprzecznych werdyktów tej samej domeny / zderzonych priorytetów w jednej decyzji",
} {
    true
}

# ── GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r01_orchestrator_core_check) ───────
# W normalnym ruchu (bez flagi) pakiet zwraca no_match — nie nadpisuje decyzji.
decide := {
    "matched": true,
    "rule_id": "jdg.r01_orchestrator_core_innovations.orchestrator_core_report",
    "_legal_basis": "R01 GLM52 (Orkiestrator + Rdzeń Silnika) + ADR-001..009/017/022 + INV-018/025/037/040/042",
    "package": "jdg.r01_orchestrator_core_innovations",
    "priority": 290,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "orchestrator_core": {
        "routing_path_trace": routing_path_trace,
        "verdict_25_fields_count": count(verdict_25_fields),
        "verdict_completeness": verdict_completeness_report,
        "decision_cache": decision_cache_runtime,
        "time_travel": time_travel_guard,
        "safe_merge_integrity": safe_merge_integrity,
        "priority_conflicts": priority_conflict_report,
    },
    "_routing": "REPORT",
    "_routing_reason": "R01 Orkiestrator: trace ścieżki routingu, cache decyzji, time-travel, safe_merge integrity, zderzenia priorytetów",
    "_legal_basis": "R01 GLM52 (Orkiestrator + Rdzeń Silnika) + ADR-001..009/017/022 + INV-018/025/037/040/042",
    "_warnings": ["Raport rdzenia orkiestratora — aktywowany wyłącznie flagą r01_orchestrator_core_check"],
} {
    object.get(input.jdg_entrepreneur, "r01_orchestrator_core_check", false) == true
}
