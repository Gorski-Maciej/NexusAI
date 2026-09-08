# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P31 ETAPY AUDYTÓW 12–28 — DOMKNIĘCIE CYKLU KAMPANII ETAPOWEJ
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa audytów etapowych ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Unified Audit Schema (wspólny JSON-schema wyników etapów:
#       pass/fail/partial z dowodami; umożliwia automatyczną syntezę; AN01-AN03),
#   I02 Cross-Etap Conflict Detector (porównanie deklaracji etapów ze stanem
#       aktualnym; sprzeczność = konflikt Cxx; najnowszy dowód wygrywa),
#   I03 Red Team Pack (zestaw ataków regułowych: mutacje input, brakujące pola,
#       skrajne daty — wielokrotnego użytku per domena; AN03),
#   I04 Risk-of-Fortress Score (skalarne ryzyko z syntezy etapów+gate'ów+bramek;
#       monitorowane w P37, donoszone do certyfikatu decyzji; AN04),
#   I05 Etapy jako Dane (definicje audytów etapowych w data.thresholds — zmiana
#       audytu bez zmiany kodu; P06 parametry-as-data),
#   I06 Auto-Rerun po Nowelizacji (Law Radar P08 wyzwala rerun dotkniętych
#       etapów po nowelizacji; AN04),
#   I07 WORM Audit Trail (każdy run etapu zapisywany WORM z checksumą stanu
#       repo; AN04),
#   I08 Frontier Matrix (macierz etap×domena z datami ostatniego dowodu;
#       etap „wygasły” = brak dowodu >90 dni; AN01-AN03),
#   I09 Conflict Resolution Procedure (najnowszy dowód wygrywa; stara deklaracja
#       wchodzi do rejestru mediacji z reason; AN04),
#   I10 Certification Pack Generator (automatyczny pakiet dla P44: synteza +
#       dowody + luki P0/P1; AN04),
#   I11 Stage Closure Campaign (plan naprawy etapów bez dowodów; priorytet:
#       ZUS core/micro, UoR, KSeF; AN01-AN03),
#   I12 P30 Feed (wyniki etapów jako wejście do rejestru wdrożeń P30 — jedna
#       historia, dwie perspektywy; AN04).
#
# Integracje (kontrakty między-częściowe):
#   * P29 (bramki jakości) — wspólny raport JSON (schema) i identyfikatory,
#   * P30 (rejestr wdrożeń) — I12 feed: wyniki etapów jako wejście,
#   * P08 (Law Radar) — I06 auto-rerun po nowelizacji,
#   * P37 (obserwowalność) — I04 risk-of-fortress score,
#   * P43 (WORM) — I07 ślad audytowy uruchomień,
#   * P44 (certyfikacja) — I10 certification pack, I04 ryzyko jako tło decyzji.
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p31 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak snapshotu / nieznany etap / deklaracja
#     bez dowodu = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy cichy AUTO_POST
#     (anty-wzorzec AP07); ścieżki bez spełnionego warunku zwracają jawną
#     NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p31_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p31_audit_stages.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p31_audit_stages
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p31_audit_stages

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p31_check", false) == true
_ctx := object.get(input, "v3_p31", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p31_snapshot := data.jdg.thresholds.v3_p31

_snapshot_ok = true {
    count(_p31_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p31_snapshot) > 0
    value := object.get(_p31_snapshot, key, null)
    value != null
} else = fallback

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p31_audit_stages.thresholds_missing",
    "package": "jdg.v3_p31_audit_stages",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ETAPY AUDYTÓW V3-P31: brak snapshotu data.jdg.thresholds.v3_p31.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P31] Brak snapshotu progów audytów etapowych — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p31_audit_stages",
        "priority": priority,
        "threshold_version": object.get(_p31_snapshot, "v3_p31_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p31_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p31_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ── Katalog etapów 12–28 (jako dane; I05) ─────────────────────────────────────
_expected_stages := ["etap12", "etap13", "etap14", "etap15", "etap16", "etap17",
                     "etap18", "etap19", "etap20", "etap21", "etap22", "etap23",
                     "etap24", "etap25", "etap26", "etap27", "etap28"]

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I01: UNIFIED AUDIT SCHEMA — wspólny schemat wyników etapów (AN01-AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_stage_results := object.get(_ctx, "stage_results", {})
_stage_reported := [k | some k, _v in _stage_results]
_stage_missing := [s |
    s := _expected_stages[_]
    not s in _stage_reported
]
_stage_failed := [s |
    s := _stage_reported[_]
    object.get(_stage_results[s], "status", "") == "fail"
]
_stage_partial := [s |
    s := _stage_reported[_]
    object.get(_stage_results[s], "status", "") == "partial"
]
_stage_no_evidence := [s |
    s := _stage_reported[_]
    object.get(_stage_results[s], "evidence", {}) == {}
]

routing_us01 = "BLOCK_AND_ALERT" {
    count(_stage_missing) > 0
} else = "BLOCK_AND_ALERT" {
    count(_stage_failed) > 0
} else = "TRIAGE_QUEUE" {
    count(_stage_no_evidence) > 0
} else = "TRIAGE_QUEUE" {
    count(_stage_partial) > 0
} else = "SUGGEST" {
    true
}

reason_us01 = sprintf("Unified audit schema: brak wyników etapów %v — BLOCK (synteza wymaga pełnego pokrycia 12-28).", [_stage_missing]) {
    count(_stage_missing) > 0
} else = sprintf("Etap(y) FAIL: %v — BLOCK (synteza ryzyka nie może być wygenerowana).", [_stage_failed]) {
    count(_stage_failed) > 0
} else = sprintf("Etap(y) bez dowodów: %v — TRIAGE (deklaracja bez dowodu = twierdzenie, nie fakt; kanon P00).", [_stage_no_evidence]) {
    count(_stage_no_evidence) > 0
} else = sprintf("Etap(y) PARTIAL: %v — TRIAGE (wyniki częściowe wymagają domknięcia).", [_stage_partial]) {
    count(_stage_partial) > 0
} else = sprintf("Unified audit schema OK: %v/17 etapów PASS z dowodami.", [count(_stage_reported)]) {
    true
}

unified_audit_schema_decision := _certificate(431001, {
    "rule_id": "jdg.v3_p31_audit_stages.unified_audit_schema",
    "analysis": "unified_audit_schema",
    "stages_expected": count(_expected_stages),
    "stages_reported": count(_stage_reported),
    "stages_missing": _stage_missing,
    "stages_failed": _stage_failed,
    "stages_partial": _stage_partial,
    "stages_no_evidence": count(_stage_no_evidence),
    "_routing": routing_us01,
    "_routing_reason": reason_us01,
    "_legal_basis": "V3_P31 §5.1-5.3/AN01-AN03; kanon P00 (dowód = kod/test/artefakt); kontrakt P29 (wspólny JSON)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "unified_audit_schema"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I02: CROSS-ETAP CONFLICT DETECTOR — sprzeczności między etapami (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_conflicts := object.get(_ctx, "stage_conflicts", [])
_unresolved := [c |
    c := _conflicts[_]
    object.get(c, "resolved", false) == false
]

routing_cc02 = "BLOCK_AND_ALERT" {
    count(_unresolved) > 0
} else = "TRIAGE_QUEUE" {
    count(_conflicts) > 0
} else = "SUGGEST" {
    true
}

reason_cc02 = sprintf("Nierozstrzygnięte konflikty między etapami: %v — BLOCK (procedura I09: najnowszy dowód wygrywa + rejestr mediacji).", [_unresolved]) {
    count(_unresolved) > 0
} else = sprintf("Konflikty rozstrzygnięte (w rejestrze mediacji): %v — TRIAGE (monitorować).", [_conflicts]) {
    count(_conflicts) > 0
} else = "Brak sprzeczności między etapami — spójność deklaracji potwierdzona." {
    true
}

cross_etap_conflict_detector_decision := _certificate(431002, {
    "rule_id": "jdg.v3_p31_audit_stages.cross_etap_conflict_detector",
    "analysis": "cross_etap_conflict_detector",
    "conflicts_total": count(_conflicts),
    "conflicts_unresolved": count(_unresolved),
    "_routing": routing_cc02,
    "_routing_reason": reason_cc02,
    "_legal_basis": "V3_P31 §5.4/AN04; konwencja rozstrzygania (najnowszy dowód wygrywa)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cross_etap_conflict_detector"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I03: RED TEAM PACK — ataki regułowe wielokrotnego użytku (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rt_attacks := object.get(_ctx, "red_team_attacks", [])
_rt_failed := [a |
    a := _rt_attacks[_]
    object.get(a, "fail_closed_ok", false) == false
]
_rt_min := _th("v3_p31_min_red_team_attacks", 10)

routing_rt03 = "BLOCK_AND_ALERT" {
    count(_rt_failed) > 0
} else = "TRIAGE_QUEUE" {
    count(_rt_attacks) < _rt_min
} else = "SUGGEST" {
    true
}

reason_rt03 = sprintf("Ataki red team bez asercji fail-closed: %v — BLOCK (mutacja input MUSI dawać NEEDS_ADVICE/BLOCK, nigdy cichy AUTO_POST).", [_rt_failed]) {
    count(_rt_failed) > 0
} else = sprintf("Red team pack za mały: %v < %v — TRIAGE (mutacje input, brakujące pola, skrajne daty per domena).", [count(_rt_attacks), _rt_min]) {
    count(_rt_attacks) < _rt_min
} else = sprintf("Red team pack OK: %v ataków, wszystkie z asercją fail-closed.", [count(_rt_attacks)]) {
    true
}

red_team_pack_decision := _certificate(431003, {
    "rule_id": "jdg.v3_p31_audit_stages.red_team_pack",
    "analysis": "red_team_pack",
    "attacks_total": count(_rt_attacks),
    "attacks_failed": count(_rt_failed),
    "min_attacks": _rt_min,
    "_routing": routing_rt03,
    "_routing_reason": reason_rt03,
    "_legal_basis": "V3_P31 §5.3/AN03; chaos-testy prawne (K10); kontrakt P04/P43",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "red_team_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I04: RISK-OF-FORTRESS SCORE — skalarne ryzyko syntezy (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_rof := object.get(_ctx, "risk_of_fortress", {})
_rof_score := object.get(_rof, "score", 100)
_rof_max := _th("v3_p31_max_risk_of_fortress", 30)

routing_rf04 = "BLOCK_AND_ALERT" {
    _rof_score > _rof_max
} else = "TRIAGE_QUEUE" {
    _rof_score > _rof_max * 0.6
} else = "SUGGEST" {
    true
}

reason_rf04 = sprintf("Risk-of-fortress score %v > limitu %v — BLOCK (ryzyko fortecy ponad tolerancję; tło certyfikatu P44).", [_rof_score, _rof_max]) {
    _rof_score > _rof_max
} else = sprintf("Risk-of-fortress score %v w strefie ostrzegawczej (> %v) — TRIAGE (P37).", [_rof_score, _rof_max * 0.6]) {
    _rof_score > _rof_max * 0.6
} else = sprintf("Risk-of-fortress score %v OK (limit %v) — monitorowane w P37.", [_rof_score, _rof_max]) {
    true
}

risk_of_fortress_score_decision := _certificate(431004, {
    "rule_id": "jdg.v3_p31_audit_stages.risk_of_fortress_score",
    "analysis": "risk_of_fortress_score",
    "score": _rof_score,
    "max_score": _rof_max,
    "_routing": routing_rf04,
    "_routing_reason": reason_rf04,
    "_legal_basis": "V3_P31 §5.4/AN04; metryka → P37; tło ryzyka certyfikatu P44",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "risk_of_fortress_score"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I05: ETAPY JAKO DANE — definicje audytów w thresholds (AN01-AN03/P06)
# ═══════════════════════════════════════════════════════════════════════════════
_stage_registry := object.get(_p31_snapshot, "v3_p31_stage_registry", {})
_registry_entries := [k | some k, _v in _stage_registry]
_registry_missing := [s |
    s := _expected_stages[_]
    not s in _registry_entries
]
_hardcoded_audits := _has_flag("audit_hardcode_detected")

routing_ed05 = "BLOCK_AND_ALERT" {
    count(_registry_missing) > 0
} else = "BLOCK_AND_ALERT" {
    _hardcoded_audits
} else = "SUGGEST" {
    true
}

reason_ed05 = sprintf("Rejestr etapów niekompletny: brak %v — BLOCK (definicje audytów jako dane, zmiana bez deployu kodu; P06).", [_registry_missing]) {
    count(_registry_missing) > 0
} else = "Wykryto hardcode definicji audytów w kodzie — BLOCK (ADR-002)." {
    _hardcoded_audits
} else = sprintf("Rejestr etapów kompletny: %v etapów jako dane (kontrole, zakres, progi).", [count(_registry_entries)]) {
    true
}

stages_as_data_decision := _certificate(431005, {
    "rule_id": "jdg.v3_p31_audit_stages.stages_as_data",
    "analysis": "stages_as_data",
    "registry_entries": count(_registry_entries),
    "registry_missing": _registry_missing,
    "hardcode_detected": _hardcoded_audits,
    "_routing": routing_ed05,
    "_routing_reason": reason_ed05,
    "_legal_basis": "V3_P31 §5.1-5.3; ADR-002 (P06 parametry-as-data)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "stages_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I06: AUTO-RERUN PO NOWELIZACJI — Law Radar wyzwala rerun (AN04/P08)
# ═══════════════════════════════════════════════════════════════════════════════
_amendments := object.get(_ctx, "amendments", [])
_stale_after_amendment := [a |
    a := _amendments[_]
    object.get(a, "affected_stages_rerun", false) == false
]

routing_ar06 = "TRIAGE_QUEUE" {
    count(_stale_after_amendment) > 0
} else = "SUGGEST" {
    true
}

reason_ar06 = sprintf("Nowelizacje bez reruna dotkniętych etapów: %v — TRIAGE (Law Radar P08 musi wyzwalać rerun; wyniki etapów wygasają).", [_stale_after_amendment]) {
    count(_stale_after_amendment) > 0
} else = sprintf("Auto-rerun OK: %v nowelizacji, wszystkie z rerunem dotkniętych etapów.", [count(_amendments)]) {
    true
}

auto_rerun_after_amendment_decision := _certificate(431006, {
    "rule_id": "jdg.v3_p31_audit_stages.auto_rerun_after_amendment",
    "analysis": "auto_rerun_after_amendment",
    "amendments_total": count(_amendments),
    "amendments_without_rerun": count(_stale_after_amendment),
    "_routing": routing_ar06,
    "_routing_reason": reason_ar06,
    "_legal_basis": "V3_P31 §5.4/AN04; kontrakt P08 (Law Radar); P05 temporalność",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "auto_rerun_after_amendment"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I07: WORM AUDIT TRAIL — każdy run z checksumą repo (AN04/P43)
# ═══════════════════════════════════════════════════════════════════════════════
_runs := object.get(_ctx, "stage_runs", [])
_runs_without_worm := [r |
    r := _runs[_]
    object.get(r, "worm_archived", false) == false
]

routing_wt07 = "TRIAGE_QUEUE" {
    count(_runs_without_worm) > 0
} else = "SUGGEST" {
    true
}

reason_wt07 = sprintf("Uruchomienia etapów bez WORM + checksumy repo: %v — TRIAGE (ślad audytowy wymagany; P43).", [_runs_without_worm]) {
    count(_runs_without_worm) > 0
} else = sprintf("WORM audit trail OK: %v uruchomień zarchiwizowanych z checksumą.", [count(_runs)]) {
    true
}

worm_audit_trail_decision := _certificate(431007, {
    "rule_id": "jdg.v3_p31_audit_stages.worm_audit_trail",
    "analysis": "worm_audit_trail",
    "runs_total": count(_runs),
    "runs_without_worm": count(_runs_without_worm),
    "_routing": routing_wt07,
    "_routing_reason": reason_wt07,
    "_legal_basis": "V3_P31 §5.4/AN04; kontrakt P43 (WORM); UoR art. 5 archiwum [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "worm_audit_trail"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I08: FRONTIER MATRIX — etap×domena z datami dowodów (AN01-AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_frontier := object.get(_ctx, "frontier_matrix", [])
_frontier_stale := [f |
    f := _frontier[_]
    days := object.get(f, "days_since_evidence", 0)
    days > _th("v3_p31_evidence_stale_days", 90)
]

routing_fm08 = "TRIAGE_QUEUE" {
    count(_frontier_stale) > 0
} else = "SUGGEST" {
    true
}

reason_fm08 = sprintf("Etap(y) z dowodami starszymi niż %v dni: %v — TRIAGE (etap wygasły; wymaga reruna).", [_th("v3_p31_evidence_stale_days", 90), _frontier_stale]) {
    count(_frontier_stale) > 0
} else = sprintf("Frontier matrix OK: %v komórek, wszystkie z dowodami aktualnymi.", [count(_frontier)]) {
    true
}

frontier_matrix_decision := _certificate(431008, {
    "rule_id": "jdg.v3_p31_audit_stages.frontier_matrix",
    "analysis": "frontier_matrix",
    "cells_total": count(_frontier),
    "cells_stale": count(_frontier_stale),
    "stale_days": _th("v3_p31_evidence_stale_days", 90),
    "_routing": routing_fm08,
    "_routing_reason": reason_fm08,
    "_legal_basis": "V3_P31 §5.1-5.3/AN01-AN03; P05 temporalność dowodów",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "frontier_matrix"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I09: CONFLICT RESOLUTION PROCEDURE — najnowszy dowód wygrywa (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_mediations := object.get(_ctx, "mediation_register", [])
_mediations_missing_reason := [m |
    m := _mediations[_]
    object.get(m, "reason", "") == ""
]

routing_cr09 = "TRIAGE_QUEUE" {
    count(_mediations_missing_reason) > 0
} else = "SUGGEST" {
    true
}

reason_cr09 = sprintf("Wpisy rejestru mediacji bez reason: %v — TRIAGE (każda stara deklaracja musi mieć uzasadnienie rozstrzygnięcia).", [_mediations_missing_reason]) {
    count(_mediations_missing_reason) > 0
} else = sprintf("Rejestr mediacji OK: %v wpisów z reason (najnowszy dowód wygrywa).", [count(_mediations)]) {
    true
}

conflict_resolution_decision := _certificate(431009, {
    "rule_id": "jdg.v3_p31_audit_stages.conflict_resolution",
    "analysis": "conflict_resolution",
    "mediations_total": count(_mediations),
    "mediations_missing_reason": count(_mediations_missing_reason),
    "_routing": routing_cr09,
    "_routing_reason": reason_cr09,
    "_legal_basis": "V3_P31 §5.4/AN04; konwencja wiąże P40/P41/P44",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "conflict_resolution"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I10: CERTIFICATION PACK GENERATOR — pakiet dla P44 (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_certpack := object.get(_ctx, "certification_pack", {})
_certpack_ready := object.get(_certpack, "ready", false) == true
_certpack_has_synthesis := object.get(_certpack, "synthesis_present", false) == true
_certpack_has_p0p1 := object.get(_certpack, "p0p1_gaps_present", false) == true

routing_cp10 = "TRIAGE_QUEUE" {
    not _certpack_ready
} else = "TRIAGE_QUEUE" {
    not _certpack_has_synthesis
} else = "TRIAGE_QUEUE" {
    not _certpack_has_p0p1
} else = "SUGGEST" {
    true
}

reason_cp10 = sprintf("Certification pack niegotowy — TRIAGE (P44 wymaga: synteza + dowody + luki P0/P1).", []) {
    not _certpack_ready
} else = "Certification pack bez syntezy ryzyka — TRIAGE." {
    not _certpack_has_synthesis
} else = "Certification pack bez luk P0/P1 — TRIAGE." {
    not _certpack_has_p0p1
} else = "Certification pack kompletny: synteza + dowody + luki P0/P1 (wejście P44)." {
    true
}

certification_pack_generator_decision := _certificate(431010, {
    "rule_id": "jdg.v3_p31_audit_stages.certification_pack_generator",
    "analysis": "certification_pack_generator",
    "ready": _certpack_ready,
    "synthesis_present": _certpack_has_synthesis,
    "p0p1_gaps_present": _certpack_has_p0p1,
    "_routing": routing_cp10,
    "_routing_reason": reason_cp10,
    "_legal_basis": "V3_P31 §5.4/AN04; kontrakt P44 (certyfikacja finalna)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "certification_pack_generator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I11: STAGE CLOSURE CAMPAIGN — plan naprawy etapów bez dowodów (AN01-AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_closure := object.get(_ctx, "closure_plan", {})
_closure_targets := object.get(_closure, "stages_without_evidence", [])
_closure_max := _th("v3_p31_max_stages_without_evidence", 0)

routing_sc11 = "BLOCK_AND_ALERT" {
    count(_closure_targets) > _closure_max
} else = "TRIAGE_QUEUE" {
    count(_closure_targets) > 0
} else = "SUGGEST" {
    true
}

reason_sc11 = sprintf("Etap(y) bez dowodów: %v > limitu %v — BLOCK (kampania domknięcia: priorytet ZUS core/micro, UoR, KSeF).", [_closure_targets, _closure_max]) {
    count(_closure_targets) > _closure_max
} else = sprintf("Etap(y) bez dowodów: %v — TRIAGE (plan naprawy wymagany).", [_closure_targets]) {
    count(_closure_targets) > 0
} else = "Wszystkie etapy 12-28 mają dowody — kampania domknięcia zakończona." {
    true
}

stage_closure_campaign_decision := _certificate(431011, {
    "rule_id": "jdg.v3_p31_audit_stages.stage_closure_campaign",
    "analysis": "stage_closure_campaign",
    "stages_without_evidence": count(_closure_targets),
    "max_allowed": _closure_max,
    "_routing": routing_sc11,
    "_routing_reason": reason_sc11,
    "_legal_basis": "V3_P31 §5.1-5.3/AN01-AN03; kanon P00",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "stage_closure_campaign"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P31-I12: P30 FEED — wyniki etapów do rejestru wdrożeń (AN04/P30)
# ═══════════════════════════════════════════════════════════════════════════════
_feed := object.get(_ctx, "p30_feed", {})
_feed_entries := object.get(_feed, "entries", 0)
_feed_synced := object.get(_feed, "registry_synced", false) == true

routing_pf12 = "TRIAGE_QUEUE" {
    _feed_entries == 0
} else = "TRIAGE_QUEUE" {
    not _feed_synced
} else = "SUGGEST" {
    true
}

reason_pf12 = sprintf("Feed do P30 pusty: %v wpisów — TRIAGE (wyniki etapów muszą zasilać rejestr wdrożeń P30).", [_feed_entries]) {
    _feed_entries == 0
} else = "Feed do P30 niesynchronizowany z rejestrem wdrożeń — TRIAGE." {
    not _feed_synced
} else = sprintf("Feed do P30 OK: %v wpisów, zsynchronizowany z rejestrem wdrożeń (jedna historia, dwie perspektywy).", [_feed_entries]) {
    true
}

p30_feed_decision := _certificate(431012, {
    "rule_id": "jdg.v3_p31_audit_stages.p30_feed",
    "analysis": "p30_feed",
    "feed_entries": _feed_entries,
    "registry_synced": _feed_synced,
    "_routing": routing_pf12,
    "_routing_reason": reason_pf12,
    "_legal_basis": "V3_P31 §5.4/AN04; kontrakt P30 (rejestr wdrożeń)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "p30_feed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := unified_audit_schema_decision {
    unified_audit_schema_decision.rule_id != ""
} else := cross_etap_conflict_detector_decision {
    cross_etap_conflict_detector_decision.rule_id != ""
} else := red_team_pack_decision {
    red_team_pack_decision.rule_id != ""
} else := risk_of_fortress_score_decision {
    risk_of_fortress_score_decision.rule_id != ""
} else := stages_as_data_decision {
    stages_as_data_decision.rule_id != ""
} else := auto_rerun_after_amendment_decision {
    auto_rerun_after_amendment_decision.rule_id != ""
} else := worm_audit_trail_decision {
    worm_audit_trail_decision.rule_id != ""
} else := frontier_matrix_decision {
    frontier_matrix_decision.rule_id != ""
} else := conflict_resolution_decision {
    conflict_resolution_decision.rule_id != ""
} else := certification_pack_generator_decision {
    certification_pack_generator_decision.rule_id != ""
} else := stage_closure_campaign_decision {
    stage_closure_campaign_decision.rule_id != ""
} else := p30_feed_decision {
    p30_feed_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p31_audit_stages.no_match",
    "package": "jdg.v3_p31_audit_stages",
    "priority": 999999,
}
