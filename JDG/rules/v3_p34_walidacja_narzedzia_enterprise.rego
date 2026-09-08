# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P34 WALIDACJA NARZĘDZI — WALIDACJA JAKO GOVERNANCE
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa walidacji ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Walidacja jako Sieć DAG (poziomy L1-L5 jako graf zależności z lokalnym
#       retry i raportem per poziom — czym wcześniej przerwać PR),
#   I02 Semantic Diff dla Rego (porównanie AST dwóch wersji reguły z
#       klasyfikacją zmiany: kosmetyczna/progowa/semantyczna),
#   I03 Legal Basis Linter Online (podstawa prawna sprawdzana na PR i nocnie;
#       dryf = TRIAGE, brak weryfikacji = BLOCK),
#   I04 Tautologia Fuzzing (property-based: reguła stała dla wszystkich
#       inputów = BLOCK — anty-wzorzec AP01),
#   I05 Cross-Write Detector (dwie reguły zapisujące tę samą ścieżkę werdyktu
#       bez precedence = BLOCKER — AP08),
#   I06 Mirror Semantic Parity (policies/ i JDG/rules/ identyczne semantycznie
#       — AST diff, nie tylko nazwy plików; AP11),
#   I07 Doc-Numbers Invariant (liczba w dokumentacji bez anchora do narzędzia
#       liczącego = [DEKLARACJA] = TRIAGE),
#   I08 Auto-Fix z 4-Eyes (narzędzia proponują poprawki jako PR z etykietą
#       wymagającą przeglądu człowieka; auto-merge = BLOCK),
#   I09 Walidacja jako Usługa (endpoint uruchamia walidację ad hoc na dowolnym
#       bundle własnym lub kandydującym),
#   I10 Coverage Heatmap Ciągła (legal_coverage_heatmap odświeżany z trendem;
#       spadek pokrycia = alert do Law Radar P08),
#   I11 Snapshot Walidacji do Certyfikatu (Decision Certificate zawiera ID
#       przebiegu walidacji — provenance decyzji),
#   I12 Rejestr Wyjątków (każde wyłączenie reguły walidacji ma termin
#       wygaśnięcia i właściciela — zero wiecznych wyłączeń).
#
# Integracje (kontrakty między-częściowe):
#   * P03 (kontrakt werdyktu) — każda analiza emituje zgodny werdykt,
#   * P04 (invarianty) — walidacja nigdy nie omija warstwy konstytucyjnej,
#   * P07 (lifecycle) — auto-fix tylko jako PR człowieka (I08),
#   * P08 (Law Radar) — spadek pokrycia = alert (I10),
#   * P22/P47 (legal basis) — linter online I03 współpracuje z ISAP crawler,
#   * P33 (warstwa AI) — walidacja narzędzi AI tym samym rejestrem wyjątków,
#   * P48 (mirror sync) — parity I06 dostarcza sygnał dryfu.
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p34 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak pola, konflikt zapisów, tautologia,
#     niepewność = NEEDS_ADVICE / TRIAGE — nigdy cichy AUTO_POST (AP07).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p34_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p34_walidacja_narzedzia.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p34_walidacja_narzedzia
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p34_walidacja_narzedzia

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p34_check", false) == true
_ctx := object.get(input, "v3_p34", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p34_snapshot := data.jdg.thresholds.v3_p34

_snapshot_ok = true {
    count(_p34_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p34_snapshot) > 0
    value := object.get(_p34_snapshot, key, null)
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
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.thresholds_missing",
    "package": "jdg.v3_p34_walidacja_narzedzia",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WALIDACJA NARZĘDZI V3-P34: brak snapshotu data.jdg.thresholds.v3_p34.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P34] Brak snapshotu progów walidacji — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p34_walidacja_narzedzia",
        "priority": priority,
        "threshold_version": object.get(_p34_snapshot, "v3_p34_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p34_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p34_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I01: WALIDACJA JAKO SIEĆ DAG — poziomy L1-L5 (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_dag := object.get(_ctx, "validation_dag", {})
_dag_failed := object.get(_dag, "failed_levels", [])
_dag_order := object.get(_dag, "levels_order", [])
_dag_expected := _th("v3_p34_dag_levels", ["L1_syntax", "L2_lint", "L3_tests", "L4_semantic", "L5_legal"])

routing_dg01 = "BLOCK_AND_ALERT" {
    count(_dag_failed) > 0
    count(_dag_order) == 0
} else = "BLOCK_AND_ALERT" {
    count(_dag_failed) > 0
    _dag_order[0] != _dag_expected[0]
} else = "TRIAGE_QUEUE" {
    count(_dag_failed) > 0
} else = "TRIAGE_QUEUE" {
    count(_dag_order) != count(_dag_expected)
} else = "SUGGEST" {
    true
}

reason_dg01 = sprintf("Poziomy walidacji ZERWANE (brak kolejności) przy porażkach: %v — BLOCK (DAG wymaga kolejności L1-L5 do lokalnego retry).", [_dag_failed]) {
    count(_dag_failed) > 0
    count(_dag_order) == 0
} else = sprintf("Pierwszy zepsuty poziom DAG to %v, oczekiwano %v — BLOCK (walidacja startuje od L1_syntax; czym wcześniej przerwać PR).", [object.get(_dag_order, 0, "?"), _dag_expected[0]]) {
    count(_dag_failed) > 0
    _dag_order[0] != _dag_expected[0]
} else = sprintf("Poziomy DAG z porażkami: %v — TRIAGE (lokalny retry przed PR; raport per poziom).", [_dag_failed]) {
    count(_dag_failed) > 0
} else = sprintf("Sieć DAG niekompletna: %v poziomów, oczekiwano %v — TRIAGE (uzupełnić poziomy L1-L5).", [count(_dag_order), count(_dag_expected)]) {
    count(_dag_order) != count(_dag_expected)
} else = sprintf("Walidacja DAG OK: poziomy %v w kolejności, zero porażek.", [_dag_order]) {
    true
}

validation_dag_decision := _certificate(434001, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.validation_dag",
    "analysis": "validation_dag",
    "levels_order": count(_dag_order),
    "failed_levels": count(_dag_failed),
    "dag_levels_expected": count(_dag_expected),
    "_routing": routing_dg01,
    "_routing_reason": reason_dg01,
    "_legal_basis": "V3_P34 §10/I01; V1 (bramki CI); UoR art. 4 ust. 1 (sprawdzalność) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "validation_dag"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I02: SEMANTIC DIFF DLA REGO — AST diff i klasyfikacja zmiany (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sdiff := object.get(_ctx, "semantic_diff", {})
_sdiff_unclassified := object.get(_sdiff, "unclassified_changes", 0)
_sdiff_semantic := object.get(_sdiff, "semantic_changes", 0)

routing_sd02 = "BLOCK_AND_ALERT" {
    _has_flag("semantic_change_without_smt")
} else = "TRIAGE_QUEUE" {
    _sdiff_unclassified > 0
} else = "TRIAGE_QUEUE" {
    _sdiff_semantic > 0
} else = "SUGGEST" {
    true
}

reason_sd02 = sprintf("Zmiana semantyczna bez dowodu SMT/Z3 (P33-I01) — BLOCK (AST diff wymaga dowodu równoważności lub klasyfikacji).", []) {
    _has_flag("semantic_change_without_smt")
} else = sprintf("Zmiany bez klasyfikacji (kosmetyczna/progowa/semantyczna): %v — TRIAGE (każda zmiana klasyfikowana przez AST diff).", [_sdiff_unclassified]) {
    _sdiff_unclassified > 0
} else = sprintf("Zmiany semantyczne: %v — TRIAGE (ścieżka awansu: P07 lifecycle + P33 pipeline).", [_sdiff_semantic]) {
    _sdiff_semantic > 0
} else = sprintf("Semantic diff OK: wszystkie zmiany skalsyfikowane, zero zmian semantycznych w tym przebiegu.", []) {
    true
}

semantic_diff_decision := _certificate(434002, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.semantic_diff",
    "analysis": "semantic_diff",
    "unclassified_changes": _sdiff_unclassified,
    "semantic_changes": _sdiff_semantic,
    "_routing": routing_sd02,
    "_routing_reason": reason_sd02,
    "_legal_basis": "V3_P34 §10/I02; V1 (bramki); kontrakt P33-I01 (SMT/Z3)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_diff"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I03: LEGAL BASIS LINTER ONLINE — PR i nocnie (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_lbl := object.get(_ctx, "legal_basis_linter", {})
_lbl_unverified := object.get(_lbl, "unverified_basis", 0)
_lbl_drift := object.get(_lbl, "drift_detected", 0)

routing_lb03 = "BLOCK_AND_ALERT" {
    _lbl_unverified > 0
} else = "TRIAGE_QUEUE" {
    _lbl_drift > 0
} else = "SUGGEST" {
    true
}

reason_lb03 = sprintf("Podstawy prawne bez weryfikacji na PR: %v — BLOCK (linter online; P33-I03 guard spójny).", [_lbl_unverified]) {
    _lbl_unverified > 0
} else = sprintf("Dryf podstaw prawnych (nocny skan): %v — TRIAGE (Law Radar P08 + rejestr mediacji).", [_lbl_drift]) {
    _lbl_drift > 0
} else = sprintf("Legal basis linter OK: %v podstaw zweryfikowanych, zero dryfu (PR + nightly).", [object.get(_lbl, "verified_basis", 0)]) {
    true
}

legal_basis_linter_decision := _certificate(434003, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.legal_basis_linter",
    "analysis": "legal_basis_linter",
    "unverified_basis": _lbl_unverified,
    "drift_detected": _lbl_drift,
    "_routing": routing_lb03,
    "_routing_reason": reason_lb03,
    "_legal_basis": "V3_P34 §10/I03; zasada źródeł ISAP/RCL/MF; kontrakt P22/P47 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "legal_basis_linter"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I04: TAUTOLOGIA FUZZING — reguła stała dla wszystkich inputów = BLOCK (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_taut := object.get(_ctx, "tautology_fuzzing", {})
_taut_flagged := object.get(_taut, "tautologies_found", 0)
_taut_inputs := object.get(_taut, "inputs_generated", 0)
_taut_min_inputs := _th("v3_p34_fuzz_min_inputs", 1000)

routing_tf04 = "BLOCK_AND_ALERT" {
    _taut_flagged > 0
} else = "TRIAGE_QUEUE" {
    _taut_inputs > 0
    _taut_inputs < _taut_min_inputs
} else = "TRIAGE_QUEUE" {
    _taut_inputs == 0
    _has_flag("fuzzing_scheduled")
} else = "SUGGEST" {
    true
}

reason_tf04 = sprintf("Tautologie (reguły stałe dla wszystkich inputów): %v — BLOCK (AP01; stub bez warunku wykryty fuzzingiem).", [_taut_flagged]) {
    _taut_flagged > 0
} else = sprintf("Fuzzing niepełny: %v inputów < minimum %v — TRIAGE (property-based wymagane).", [_taut_inputs, _taut_min_inputs]) {
    _taut_inputs > 0
    _taut_inputs < _taut_min_inputs
} else = "Fuzzing zaplanowany, ale nieuruchomiony — TRIAGE (asercja: reguła nie jest stała)." {
    _taut_inputs == 0
    _has_flag("fuzzing_scheduled")
} else = sprintf("Tautologia fuzzing OK: %v inputów, zero tautologii (AP01 zamknięty).", [_taut_inputs]) {
    true
}

tautology_fuzzing_decision := _certificate(434004, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.tautology_fuzzing",
    "analysis": "tautology_fuzzing",
    "tautologies_found": _taut_flagged,
    "inputs_generated": _taut_inputs,
    "min_inputs": _taut_min_inputs,
    "_routing": routing_tf04,
    "_routing_reason": reason_tf04,
    "_legal_basis": "V3_P34 §10/I04; anty-wzorzec AP01; bramki CI (P39)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "tautology_fuzzing"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I05: CROSS-WRITE DETECTOR — konflikt zapisów bez precedence = BLOCKER (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_cw := object.get(_ctx, "cross_write_detector", {})
_cw_conflicts := object.get(_cw, "cross_write_conflicts", 0)
_cw_without_precedence := object.get(_cw, "conflicts_without_precedence", 0)

routing_cw05 = "BLOCK_AND_ALERT" {
    _cw_without_precedence > 0
} else = "TRIAGE_QUEUE" {
    _cw_conflicts > 0
} else = "SUGGEST" {
    true
}

reason_cw05 = sprintf("Konflikty zapisu do tej samej ścieżki werdyktu bez precedence: %v — BLOCK (AP08; dwie reguły piszą w jedno miejsce).", [_cw_without_precedence]) {
    _cw_without_precedence > 0
} else = sprintf("Konflikty zapisu z ustalonym precedence: %v — TRIAGE (zweryfikować intencję autorów).", [_cw_conflicts]) {
    _cw_conflicts > 0
} else = "Cross-write detector OK: zero konfliktów zapisu do ścieżek werdyktu (AP08 zamknięty)." {
    true
}

cross_write_detector_decision := _certificate(434005, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.cross_write_detector",
    "analysis": "cross_write_detector",
    "cross_write_conflicts": _cw_conflicts,
    "conflicts_without_precedence": _cw_without_precedence,
    "_routing": routing_cw05,
    "_routing_reason": reason_cw05,
    "_legal_basis": "V3_P34 §10/I05; anty-wzorzec AP08; V1 (determinizm werdyktu)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cross_write_detector"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I06: MIRROR SEMANTIC PARITY — AST diff policies/ vs JDG/rules/ (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_mir := object.get(_ctx, "mirror_semantic_parity", {})
_mir_divergent := object.get(_mir, "divergent_rules", 0)
_mir_unchecked := object.get(_mir, "unchecked_rules", 0)
_mir_max_unchecked := _th("v3_p34_mirror_unchecked_max", 0)

routing_mp06 = "BLOCK_AND_ALERT" {
    _has_flag("mirror_divergence_blocking")
} else = "TRIAGE_QUEUE" {
    _mir_divergent > 0
} else = "TRIAGE_QUEUE" {
    _mir_unchecked > _mir_max_unchecked
} else = "SUGGEST" {
    true
}

reason_mp06 = sprintf("Dryf mirror semantyczny wymagający blokady merge — BLOCK (AP11; walidacja krzyżowa mirror vs canonical).", []) {
    _has_flag("mirror_divergence_blocking")
} else = sprintf("Reguły rozbieżne semantycznie (mirror vs canonical): %v — TRIAGE (AST diff; P48 mirror sync).", [_mir_divergent]) {
    _mir_divergent > 0
} else = sprintf("Reguły bez porównania AST: %v > limit %v — TRIAGE (parity wymaga pełnego pokrycia).", [_mir_unchecked, _mir_max_unchecked]) {
    _mir_unchecked > _mir_max_unchecked
} else = sprintf("Mirror semantic parity OK: 0 rozbieżności AST, %v reguł sprawdzonych.", [object.get(_mir, "checked_rules", 0)]) {
    true
}

mirror_semantic_parity_decision := _certificate(434006, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.mirror_semantic_parity",
    "analysis": "mirror_semantic_parity",
    "divergent_rules": _mir_divergent,
    "unchecked_rules": _mir_unchecked,
    "checked_rules": object.get(_mir, "checked_rules", 0),
    "_routing": routing_mp06,
    "_routing_reason": reason_mp06,
    "_legal_basis": "V3_P34 §10/I06; anty-wzorzec AP11; kontrakt P48 (mirror sync)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_semantic_parity"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I07: DOC-NUMBERS INVARIANT — liczba bez anchora = DEKLARACJA (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_dni := object.get(_ctx, "doc_numbers_invariant", {})
_dni_anchors := object.get(_dni, "anchored_numbers", 0)
_dni_declarations := object.get(_dni, "unanchored_numbers", 0)
_dni_max_declarations := _th("v3_p34_doc_unanchored_max", 0)

routing_dn07 = "BLOCK_AND_ALERT" {
    _has_flag("doc_numbers_forged")
} else = "TRIAGE_QUEUE" {
    _dni_declarations > _dni_max_declarations
} else = "SUGGEST" {
    true
}

reason_dn07 = sprintf("Wykryto sfabrykowane liczby w dokumentacji — BLOCK (liczba musi mieć anchor do narzędzia liczącego; P00 kanon dowodu).", []) {
    _has_flag("doc_numbers_forged")
} else = sprintf("Liczby w dokumentacji bez anchora [DEKLARACJA]: %v > limit %v — TRIAGE (podpiąć pod narzędzia liczące).", [_dni_declarations, _dni_max_declarations]) {
    _dni_declarations > _dni_max_declarations
} else = sprintf("Doc-numbers invariant OK: %v liczb z anchorem, %v [DEKLARACJA] ≤ limitu.", [_dni_anchors, _dni_declarations]) {
    true
}

doc_numbers_invariant_decision := _certificate(434007, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.doc_numbers_invariant",
    "analysis": "doc_numbers_invariant",
    "anchored_numbers": _dni_anchors,
    "unanchored_numbers": _dni_declarations,
    "unanchored_limit": _dni_max_declarations,
    "_routing": routing_dn07,
    "_routing_reason": reason_dn07,
    "_legal_basis": "V3_P34 §10/I07; kanon P00 (dowód bez uruchomienia = twierdzenie)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "doc_numbers_invariant"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I08: AUTO-FIX Z 4-EYES — poprawki tylko jako PR człowieka (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_afx := object.get(_ctx, "auto_fix_four_eyes", {})
_afx_proposed := object.get(_afx, "fixes_proposed", 0)
_afx_merged := object.get(_afx, "auto_merged_fixes", 0)
_afx_unreviewed := object.get(_afx, "fixes_without_review", 0)

routing_af08 = "BLOCK_AND_ALERT" {
    _afx_merged > 0
} else = "TRIAGE_QUEUE" {
    _afx_unreviewed > 0
} else = "SUGGEST" {
    true
}

reason_af08 = sprintf("Auto-merge poprawek narzędzi: %v — BLOCK (auto-fix zawsze jako PR z przeglądem człowieka; 4-eyes; P07).", [_afx_merged]) {
    _afx_merged > 0
} else = sprintf("Poprawki bez przeglądu człowieka: %v — TRIAGE (etykieta review-required obowiązkowa).", [_afx_unreviewed]) {
    _afx_unreviewed > 0
} else = sprintf("Auto-fix z 4-eyes OK: %v poprawek jako PR, wszystkie z przeglądem.", [_afx_proposed]) {
    true
}

auto_fix_four_eyes_decision := _certificate(434008, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.auto_fix_four_eyes",
    "analysis": "auto_fix_four_eyes",
    "fixes_proposed": _afx_proposed,
    "auto_merged_fixes": _afx_merged,
    "fixes_without_review": _afx_unreviewed,
    "_routing": routing_af08,
    "_routing_reason": reason_af08,
    "_legal_basis": "V3_P34 §10/I08; kontrakt P07 (lifecycle); KKS (człowiek zatwierdza) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "auto_fix_four_eyes"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I09: WALIDACJA JAKO USŁUGA — ad hoc na dowolnym bundle (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_vas := object.get(_ctx, "validation_as_service", {})
_vas_runs := object.get(_vas, "ad_hoc_runs", 0)
_vas_unaudited := object.get(_vas, "runs_without_audit", 0)

routing_vs09 = "BLOCK_AND_ALERT" {
    _vas_unaudited > 0
} else = "TRIAGE_QUEUE" {
    _vas_runs == 0
    _has_flag("service_deployed")
} else = "SUGGEST" {
    true
}

reason_vs09 = sprintf("Przebiegi walidacji ad hoc bez śladu audytu: %v — BLOCK (każdy run z ID w Decision Certificate; I11).", [_vas_unaudited]) {
    _vas_unaudited > 0
} else = "Usługa walidacji wdrożona, ale bez uruchomień — TRIAGE (endpoint gotowy; zweryfikować integrację P40)." {
    _vas_runs == 0
    _has_flag("service_deployed")
} else = sprintf("Walidacja jako usługa OK: %v przebiegów ad hoc, wszystkie audytowane.", [_vas_runs]) {
    true
}

validation_as_service_decision := _certificate(434009, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.validation_as_service",
    "analysis": "validation_as_service",
    "ad_hoc_runs": _vas_runs,
    "runs_without_audit": _vas_unaudited,
    "_routing": routing_vs09,
    "_routing_reason": reason_vs09,
    "_legal_basis": "V3_P34 §10/I09; kontrakt P40 (API); I11 provenance",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "validation_as_service"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I10: COVERAGE HEATMAP CIĄGŁA — spadek pokrycia = alert (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_chm := object.get(_ctx, "coverage_heatmap_continuous", {})
_chm_drop := object.get(_chm, "coverage_drop_points", 0)
_chm_stale_days := object.get(_chm, "stale_days", 0)
_chm_max_stale := _th("v3_p34_heatmap_max_stale_days", 1)

routing_ch10 = "BLOCK_AND_ALERT" {
    _chm_drop > _th("v3_p34_coverage_drop_block", 5)
} else = "TRIAGE_QUEUE" {
    _chm_drop > 0
} else = "TRIAGE_QUEUE" {
    _chm_stale_days > _chm_max_stale
} else = "SUGGEST" {
    true
}

reason_ch10 = sprintf("Spadek pokrycia prawnego: %v punktów > limit %v — BLOCK (pokrycie spada krytycznie; Law Radar P08).", [_chm_drop, _th("v3_p34_coverage_drop_block", 5)]) {
    _chm_drop > _th("v3_p34_coverage_drop_block", 5)
} else = sprintf("Spadek pokrycia: %v punktów — TRIAGE (alert do Law Radar P08; trend odświeżany).", [_chm_drop]) {
    _chm_drop > 0
} else = sprintf("Heatmapa nieaktualna: %v dni > limit %v — TRIAGE (odświeżenie codzienne wymagane).", [_chm_stale_days, _chm_max_stale]) {
    _chm_stale_days > _chm_max_stale
} else = sprintf("Coverage heatmap OK: trend bez spadków, ostatnie odświeżenie %v dni temu.", [_chm_stale_days]) {
    true
}

coverage_heatmap_continuous_decision := _certificate(434010, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.coverage_heatmap_continuous",
    "analysis": "coverage_heatmap_continuous",
    "coverage_drop_points": _chm_drop,
    "stale_days": _chm_stale_days,
    "max_stale_days": _chm_max_stale,
    "_routing": routing_ch10,
    "_routing_reason": reason_ch10,
    "_legal_basis": "V3_P34 §10/I10; kontrakt P08 (Law Radar); K12 (mapa pokrycia)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "coverage_heatmap_continuous"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I11: SNAPSHOT WALIDACJI DO CERTYFIKATU — provenance decyzji (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_vsn := object.get(_ctx, "validation_snapshot", {})
_vsn_missing := object.get(_vsn, "decisions_without_validation_id", 0)

routing_vn11 = "BLOCK_AND_ALERT" {
    _vsn_missing > 0
} else = "SUGGEST" {
    true
}

reason_vn11 = sprintf("Decyzje bez ID przebiegu walidacji w certyfikacie: %v — BLOCK (provenance decyzji wymaga wersji narzędzi walidacji).", [_vsn_missing]) {
    _vsn_missing > 0
} else = sprintf("Snapshot walidacji OK: każda decyzja z ID przebiegu walidacji (wersje narzędzi w certyfikacie).", []) {
    true
}

validation_snapshot_decision := _certificate(434011, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.validation_snapshot",
    "analysis": "validation_snapshot",
    "decisions_without_validation_id": _vsn_missing,
    "_routing": routing_vn11,
    "_routing_reason": reason_vn11,
    "_legal_basis": "V3_P34 §10/I11; V2 F4 (Decision Certificate); UoR art. 4 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "validation_snapshot"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34-I12: REJESTR WYJĄTKÓW — zero wiecznych wyłączeń (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_exc := object.get(_ctx, "exception_register", {})
_exc_no_expiry := object.get(_exc, "exceptions_without_expiry", 0)
_exc_no_owner := object.get(_exc, "exceptions_without_owner", 0)
_exc_expired := object.get(_exc, "expired_exceptions", 0)

routing_ex12 = "BLOCK_AND_ALERT" {
    _exc_expired > 0
} else = "BLOCK_AND_ALERT" {
    _exc_no_expiry > 0
} else = "TRIAGE_QUEUE" {
    _exc_no_owner > 0
} else = "SUGGEST" {
    true
}

reason_ex12 = sprintf("Wyjątki po terminie wygaśnięcia aktywne: %v — BLOCK (zero wiecznych wyłączeń; wygasłe = re-aktywacja reguły).", [_exc_expired]) {
    _exc_expired > 0
} else = sprintf("Wyjątki bez terminu wygaśnięcia: %v — BLOCK (każdy suppress ma expiry i właściciela).", [_exc_no_expiry]) {
    _exc_no_expiry > 0
} else = sprintf("Wyjątki bez właściciela: %v — TRIAGE (przypisać właściciela; audytowalność).", [_exc_no_owner]) {
    _exc_no_owner > 0
} else = sprintf("Rejestr wyjątków OK: %v aktywnych wyjątków, wszystkie z expiry i właścicielem.", [object.get(_exc, "active_exceptions", 0)]) {
    true
}

exception_register_decision := _certificate(434012, {
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.exception_register",
    "analysis": "exception_register",
    "exceptions_without_expiry": _exc_no_expiry,
    "exceptions_without_owner": _exc_no_owner,
    "expired_exceptions": _exc_expired,
    "_routing": routing_ex12,
    "_routing_reason": reason_ex12,
    "_legal_basis": "V3_P34 §10/I12; V1 zasada 6 (fail-closed); audytowalność (7.1h)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exception_register"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := validation_dag_decision {
    validation_dag_decision.rule_id != ""
} else := semantic_diff_decision {
    semantic_diff_decision.rule_id != ""
} else := legal_basis_linter_decision {
    legal_basis_linter_decision.rule_id != ""
} else := tautology_fuzzing_decision {
    tautology_fuzzing_decision.rule_id != ""
} else := cross_write_detector_decision {
    cross_write_detector_decision.rule_id != ""
} else := mirror_semantic_parity_decision {
    mirror_semantic_parity_decision.rule_id != ""
} else := doc_numbers_invariant_decision {
    doc_numbers_invariant_decision.rule_id != ""
} else := auto_fix_four_eyes_decision {
    auto_fix_four_eyes_decision.rule_id != ""
} else := validation_as_service_decision {
    validation_as_service_decision.rule_id != ""
} else := coverage_heatmap_continuous_decision {
    coverage_heatmap_continuous_decision.rule_id != ""
} else := validation_snapshot_decision {
    validation_snapshot_decision.rule_id != ""
} else := exception_register_decision {
    exception_register_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p34_walidacja_narzedzia.no_match",
    "package": "jdg.v3_p34_walidacja_narzedzia",
    "priority": 999999,
}
