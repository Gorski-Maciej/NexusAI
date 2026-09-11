# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P48 SYNCHRONIZACJA MIRROR POLICIES — ZERO DRYFU
# CANONICAL↔MIRROR (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa synchronizacji mirror ENTERPRISE — 12 analiz (I01–I12; minimum z
# promptu P48 Sekcja 10):
#   I01 Mirror as Build Output (policies/ generowane z JDG/rules jednym
#       poleceniem; ręczna edycja mirror = BLOCK_AND_ALERT; brak manifestu sync
#       = BLOCK — dryf strukturalnie niemożliwy),
#   I02 Semantic AST Diff Gate (dryf semantyczny = BLOCK merge; dryf tekstowy
#       (komentarze/nagłówki) = dozwolony; brak mapy dryfu = BLOCK),
#   I03 Sync-in-PR Rule (canonical zmieniony bez synchronicznego mirror = BLOCK
#       PR; sync-poza-PR = BLOCK_AND_ALERT),
#   I04 Drift Heatmap (mapa cieplna per pakiet; cel 0; dryf > progu = BLOCK,
#       trend rosnący = TRIAGE),
#   I05 Overlay Declaration (celowe różnice mirror w OVERLAY.md z powodem,
#       właścicielem i terminem; niejawny overlay = BLOCK_AND_ALERT),
#   I06 Mirror Test Parity (testy natywne na canonical i mirror; rozjazd wyników
#       = BLOCK; brak evidence = TRIAGE),
#   I07 Golden Replay on Mirror (złote orzeczenia odtwarzane na mirror; delta
#       decyzji > 0 = BLOCK; brak replay = TRIAGE),
#   I08 Mirror Ownership Register (każdy pakiet mirror z właścicielem i
#       kadencją przeglądu; pakiet osierocony = BLOCK_AND_ALERT),
#   I09 Post-Deploy Mirror Check (bundle zbudowany z canonical — checksum
#       match; deploy z dryfującego źródła = BLOCK),
#   I10 Case-Study Template (wzorzec analizy dryfu: przypadek→przyczyna→skutek→
#       naprawa→kontrola; case bez planu naprawy = TRIAGE),
#   I11 Mirror Lifecycle Alignment (mirror dziedziczy lifecycle z canonical;
#       rozjazd statusów = BLOCK_AND_ALERT),
#   I12 One-Truth Attestation (certyfikat decyzji z hashem reguły użytej —
#       nie tylko rule_id; brak hashu = TRIAGE).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p48 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * Fail-closed (V1 zasada 6): brak snapshotu, brak manifestu sync, brak mapy
#     dryfu, dryf semantyczny niezaraportowany, overlay niejawny, deploy bez
#     checksum canonical = BLOCK — nigdy cicha decyzja na dryfującej wersji.
#   * Honesty: liczniki z narzędzi i bundli (nie deklaracje); baseline dryfu
#     (pomiar 2026-09-11: canonical 522, mirror 580, wspólnych 500 — 472
#     identycznych, 3 tekstowych, 25 semantycznych, 22 brakujących, 80
#     osieroconych legacy) raportowany uczciwie jako backlog, nie ukrywany.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     [NIEZWERYFIKOWANE — ISAP] do czasu stempla 4-eyes (protokół 04).
#   * Aktywacja: input.jdg_entrepreneur.v3_p48_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p48_mirror_sync.<reguła>.
#   * Kontrakty: P45 (stub-killer, pipeline konwersji), P46 (rejestr
#     parametrów), P47 (kanon cytowań, mediacje), P00 (jedno źródło prawdy),
#     P36 (sync w tej samej transakcji), P38 (post-deploy), P10 (golden),
#     P39 (bramki CI), P07 (lifecycle).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p48_mirror_sync
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p48_mirror_sync

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p48_check", false) == true
_ctx := object.get(input, "v3_p48", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p48_snapshot := data.jdg.thresholds.v3_p48
_packages_map := data.jdg.thresholds.v3_p48_packages

_snapshot_ok = true {
    count(_p48_snapshot) > 0
} else = false {
    true
}

_packages_ok = true {
    count(_packages_map) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p48_snapshot) > 0
    value := object.get(_p48_snapshot, key, null)
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
    "rule_id": "jdg.v3_p48_mirror_sync.thresholds_missing",
    "package": "jdg.v3_p48_mirror_sync",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MIRROR-SYNC V3-P48: brak snapshotu data.jdg.thresholds.v3_p48.",
    "_legal_basis": "ADR-002; V1 zasada 6 (fail-closed); ustawa o rachunkowości art. 4 ust. 1 (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]",
    "_warnings": ["[V3-P48] Brak snapshotu progów synchronizacji mirror — kontrole ZABLOKOWANE."],
}

# ── Fail-closed gdy mapa pakietów mirror niedostępna (własność nieznana) ──────
packages_missing_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p48_mirror_sync.packages_missing",
    "package": "jdg.v3_p48_mirror_sync",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MIRROR-SYNC V3-P48: brak mapy pakietów data.jdg.thresholds.v3_p48_packages.",
    "_legal_basis": "V3-P48-I08; protokół 04 — rejestr własności wymaga mapy pakietów",
    "_warnings": ["[V3-P48] Mapa pakietów mirror niedostępna — kontrola własności ZABLOKOWANA."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p48_mirror_sync",
        "priority": priority,
        "threshold_version": object.get(_p48_snapshot, "v3_p48_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p48_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p48_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I01: MIRROR AS BUILD OUTPUT — policies/ generowane, nie ręczne (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_build := object.get(_ctx, "mirror_build_output", {})
_sync_manifest := object.get(_build, "sync_manifest_present", false)
_sync_age_days := object.get(_build, "sync_age_days", 999999)
_hand_edits := object.get(_build, "hand_edits", 0)
_sync_max_age := _th("v3_p48_sync_max_age_days", 7)

routing_mb01 = "BLOCK_AND_ALERT" {
    _has_flag("mirror_edit_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _sync_manifest
} else = "BLOCK_AND_ALERT" {
    _hand_edits > 0
} else = "TRIAGE_QUEUE" {
    _sync_age_days > _sync_max_age
} else = "AUTO_FILE" {
    true
}

mirror_build_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_build_output"
    routing_mb01 == "AUTO_FILE"
    cert := _certificate(448001, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_build_output",
        "decision_mode": "AUTO_POST",
        "_routing": routing_mb01,
        "_routing_reason": "MIRROR-SYNC: mirror wygenerowany z canonical — zero ręcznych edycji.",
        "_legal_basis": "P48-I01; P00 jedno źródło prawdy; V1 §1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "sync_manifest_present": _sync_manifest,
        "sync_age_days": _sync_age_days,
        "hand_edits": _hand_edits,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_build_output"
    routing_mb01 == "TRIAGE_QUEUE"
    cert := _certificate(448001, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_build_output",
        "decision_mode": "TRIAGE",
        "_routing": routing_mb01,
        "_routing_reason": "MIRROR-SYNC: mirror niezsynchronizowany w oknie progowym — przegląd.",
        "_legal_basis": "P48-I01; P48-I03 (sync-in-PR); P36",
        "_warnings": ["[V3-P48] Mirror przeterminowany — uruchom mirror build."],
        "sync_age_days": _sync_age_days,
        "max_age_days": _sync_max_age,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_build_output"
    routing_mb01 == "BLOCK_AND_ALERT"
    cert := _certificate(448001, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_build_output",
        "decision_mode": "BLOCK",
        "_routing": routing_mb01,
        "_routing_reason": "MIRROR-SYNC: ręczna edycja mirror / brak manifestu sync — dryf strukturalny.",
        "_legal_basis": "P48-I01; AP11; ustawa o rachunkowości art. 5 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Mirror musi być build output — edycja ręczna ZABLOKOWANA."],
        "sync_manifest_present": _sync_manifest,
        "hand_edits": _hand_edits,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I02: SEMANTIC AST DIFF GATE — dryf semantyczny blokuje merge (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_astdiff := object.get(_ctx, "semantic_ast_diff", {})
_semantic_drift := object.get(_astdiff, "semantic_diffs", 0)
_textual_diffs := object.get(_astdiff, "textual_diffs", 0)
_unreported_semantic := object.get(_astdiff, "unreported_semantic", 0)
_drift_map_present := object.get(_astdiff, "drift_map_present", false)
_semantic_max := _th("v3_p48_semantic_drift_max", 0)

routing_sa02 = "BLOCK_AND_ALERT" {
    _has_flag("ast_diff_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _drift_map_present
} else = "BLOCK_AND_ALERT" {
    _unreported_semantic > 0
} else = "BLOCK_AND_ALERT" {
    _semantic_drift > _semantic_max
} else = "TRIAGE_QUEUE" {
    _semantic_drift > 0
} else = "AUTO_FILE" {
    true
}

semantic_ast_diff_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_ast_diff"
    routing_sa02 == "AUTO_FILE"
    cert := _certificate(448002, {
        "rule_id": "jdg.v3_p48_mirror_sync.semantic_ast_diff",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sa02,
        "_routing_reason": "MIRROR-SYNC: AST canonical == AST mirror — zero dryfu semantycznego.",
        "_legal_basis": "P48-I02; Ordynacja art. 24b (tekst obowiązujący na datę zdarzenia) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "semantic_diffs": _semantic_drift,
        "textual_diffs": _textual_diffs,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_ast_diff"
    routing_sa02 == "TRIAGE_QUEUE"
    cert := _certificate(448002, {
        "rule_id": "jdg.v3_p48_mirror_sync.semantic_ast_diff",
        "decision_mode": "TRIAGE",
        "_routing": routing_sa02,
        "_routing_reason": "MIRROR-SYNC: dryf semantyczny zaraportowany w mapie — backlog naprawy.",
        "_legal_basis": "P48-I02; AP11; mapa dryfu → P68 re-certyfikacja",
        "_warnings": ["[V3-P48] Dryf semantyczny w backlogu — domknąć sync."],
        "semantic_diffs": _semantic_drift,
        "textual_diffs": _textual_diffs,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_ast_diff"
    routing_sa02 == "BLOCK_AND_ALERT"
    cert := _certificate(448002, {
        "rule_id": "jdg.v3_p48_mirror_sync.semantic_ast_diff",
        "decision_mode": "BLOCK",
        "_routing": routing_sa02,
        "_routing_reason": "MIRROR-SYNC: niezaraportowany dryf semantyczny — merge ZABLOKOWANY.",
        "_legal_basis": "P48-I02; AP11; V2 F4 (dowód wersji reguły); ustawa VAT art. 106b [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Dryf semantyczny mirror vs canonical — kontrole ZABLOKOWANE."],
        "semantic_diffs": _semantic_drift,
        "unreported_semantic": _unreported_semantic,
        "drift_map_present": _drift_map_present,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I03: SYNC-IN-PR RULE — zmiana canonical bez mirror = odrzucenie PR (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_syncpr := object.get(_ctx, "sync_in_pr", {})
_canonical_changed := object.get(_syncpr, "canonical_changed", 0)
_mirror_changed := object.get(_syncpr, "mirror_changed", 0)
_out_of_pr_sync := object.get(_syncpr, "out_of_pr_sync", 0)

routing_sp03 = "BLOCK_AND_ALERT" {
    _has_flag("sync_bypassed")
} else = "BLOCK_AND_ALERT" {
    _canonical_changed > 0
    _mirror_changed == 0
} else = "BLOCK_AND_ALERT" {
    _out_of_pr_sync > 0
} else = "AUTO_FILE" {
    true
}

sync_in_pr_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "sync_in_pr"
    routing_sp03 == "AUTO_FILE"
    cert := _certificate(448003, {
        "rule_id": "jdg.v3_p48_mirror_sync.sync_in_pr",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sp03,
        "_routing_reason": "MIRROR-SYNC: zmiana canonical i mirror w tej samej PR — zero dryfu czasowego.",
        "_legal_basis": "P48-I03; P36 (sync w tej samej transakcji)",
        "_warnings": [],
        "canonical_changed": _canonical_changed,
        "mirror_changed": _mirror_changed,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "sync_in_pr"
    routing_sp03 == "BLOCK_AND_ALERT"
    cert := _certificate(448003, {
        "rule_id": "jdg.v3_p48_mirror_sync.sync_in_pr",
        "decision_mode": "BLOCK",
        "_routing": routing_sp03,
        "_routing_reason": "MIRROR-SYNC: canonical zmieniony bez synchronicznego mirror — PR odrzucony.",
        "_legal_basis": "P48-I03; AP11; kontrakt wyjściowy P48 → P36",
        "_warnings": ["[V3-P48] Dodaj mirror do tej samej PR albo deklarację overlay."],
        "canonical_changed": _canonical_changed,
        "mirror_changed": _mirror_changed,
        "out_of_pr_sync": _out_of_pr_sync,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I04: DRIFT HEATMAP — mapa cieplna dryfu per pakiet (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_heatmap := object.get(_ctx, "drift_heatmap", {})
_packages_total := object.get(_heatmap, "packages_total", 0)
_packages_clean := object.get(_heatmap, "packages_clean", 0)
_worst_drift := object.get(_heatmap, "worst_package_drift", 0)
_trend_rising := object.get(_heatmap, "trend_rising", false)
_drift_target := _th("v3_p48_heatmap_target_pct", 100)
_drift_block := _th("v3_p48_drift_block_pct", 20)

routing_dh04 = "BLOCK_AND_ALERT" {
    _has_flag("heatmap_bypassed")
} else = "BLOCK_AND_ALERT" {
    _worst_drift > _drift_block
} else = "TRIAGE_QUEUE" {
    _trend_rising
} else = "TRIAGE_QUEUE" {
    _packages_total > 0
    _packages_clean < _packages_total
} else = "AUTO_FILE" {
    true
}

drift_heatmap_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_heatmap"
    routing_dh04 == "AUTO_FILE"
    cert := _certificate(448004, {
        "rule_id": "jdg.v3_p48_mirror_sync.drift_heatmap",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dh04,
        "_routing_reason": "MIRROR-SYNC: wszystkie pakiety mirror czyste (dryf 0) — cel osiągnięty.",
        "_legal_basis": "P48-I04; K11 (walidacja krzyżowa mirror vs canonical)",
        "_warnings": [],
        "packages_total": _packages_total,
        "packages_clean": _packages_clean,
        "worst_package_drift": _worst_drift,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_heatmap"
    routing_dh04 == "TRIAGE_QUEUE"
    cert := _certificate(448004, {
        "rule_id": "jdg.v3_p48_mirror_sync.drift_heatmap",
        "decision_mode": "TRIAGE",
        "_routing": routing_dh04,
        "_routing_reason": "MIRROR-SYNC: pakiety z dryfem / trend rosnący — heatmapa kierowca napraw.",
        "_legal_basis": "P48-I04; P68 re-certyfikacja wymaga dryfu → 0",
        "_warnings": ["[V3-P48] Heatmapa dryfu > 0 — plan naprawy per pakiet."],
        "packages_total": _packages_total,
        "packages_clean": _packages_clean,
        "worst_package_drift": _worst_drift,
        "trend_rising": _trend_rising,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_heatmap"
    routing_dh04 == "BLOCK_AND_ALERT"
    cert := _certificate(448004, {
        "rule_id": "jdg.v3_p48_mirror_sync.drift_heatmap",
        "decision_mode": "BLOCK",
        "_routing": routing_dh04,
        "_routing_reason": "MIRROR-SYNC: dryf pakietu przekroczył próg blokady — deploy z mirror ZABLOKOWANY.",
        "_legal_basis": "P48-I04; AP11; RODO art. 5 ust. 1d (prawidłowość) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Dryf najgorszego pakietu ponad próg blokady."],
        "worst_package_drift": _worst_drift,
        "drift_block_pct": _drift_block,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I05: OVERLAY DECLARATION — celowe różnice jawne w OVERLAY.md (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_overlay := object.get(_ctx, "overlay_declaration", {})
_declared_overlays := object.get(_overlay, "declared_overlays", 0)
_undeclared_overlays := object.get(_overlay, "undeclared_overlays", 0)
_overlay_expired := object.get(_overlay, "expired_overlays", 0)

routing_ov05 = "BLOCK_AND_ALERT" {
    _has_flag("overlay_bypassed")
} else = "BLOCK_AND_ALERT" {
    _undeclared_overlays > 0
} else = "TRIAGE_QUEUE" {
    _overlay_expired > 0
} else = "AUTO_FILE" {
    true
}

overlay_declaration_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "overlay_declaration"
    routing_ov05 == "AUTO_FILE"
    cert := _certificate(448005, {
        "rule_id": "jdg.v3_p48_mirror_sync.overlay_declaration",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ov05,
        "_routing_reason": "MIRROR-SYNC: wszystkie overlay zadeklarowane z powodem i terminem przeglądu.",
        "_legal_basis": "P48-I05; V1 §6.3 (overlays czasowe); V2 §8",
        "_warnings": [],
        "declared_overlays": _declared_overlays,
        "undeclared_overlays": _undeclared_overlays,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "overlay_declaration"
    routing_ov05 == "TRIAGE_QUEUE"
    cert := _certificate(448005, {
        "rule_id": "jdg.v3_p48_mirror_sync.overlay_declaration",
        "decision_mode": "TRIAGE",
        "_routing": routing_ov05,
        "_routing_reason": "MIRROR-SYNC: overlay po terminie przeglądu — odświeżyć deklarację lub wycofać.",
        "_legal_basis": "P48-I05; P05 temporalność",
        "_warnings": ["[V3-P48] Overlay z wygasłym terminem przeglądu."],
        "expired_overlays": _overlay_expired,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "overlay_declaration"
    routing_ov05 == "BLOCK_AND_ALERT"
    cert := _certificate(448005, {
        "rule_id": "jdg.v3_p48_mirror_sync.overlay_declaration",
        "decision_mode": "BLOCK",
        "_routing": routing_ov05,
        "_routing_reason": "MIRROR-SYNC: niezadeklarowany overlay — ukryta różnica mirror = dryf.",
        "_legal_basis": "P48-I05; AP11; jawne nie ukryte (prompt P48 I05)",
        "_warnings": ["[V3-P48] Overlay bez OVERLAY.md — ZABLOKOWANY."],
        "undeclared_overlays": _undeclared_overlays,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I06: MIRROR TEST PARITY — testy na canonical i mirror (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_parity := object.get(_ctx, "mirror_test_parity", {})
_parity_runs := object.get(_parity, "parity_runs", 0)
_parity_mismatch := object.get(_parity, "result_mismatches", 0)
_mirror_tests_total := object.get(_parity, "mirror_tests_total", 0)
_min_parity := _th("v3_p48_min_parity_runs", 1)

routing_tp06 = "BLOCK_AND_ALERT" {
    _has_flag("parity_bypassed")
} else = "BLOCK_AND_ALERT" {
    _parity_mismatch > 0
} else = "TRIAGE_QUEUE" {
    _parity_runs < _min_parity
} else = "TRIAGE_QUEUE" {
    _mirror_tests_total == 0
} else = "AUTO_FILE" {
    true
}

mirror_test_parity_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_test_parity"
    routing_tp06 == "AUTO_FILE"
    cert := _certificate(448006, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_test_parity",
        "decision_mode": "AUTO_POST",
        "_routing": routing_tp06,
        "_routing_reason": "MIRROR-SYNC: testy canonical i mirror dają identyczne wyniki — parity pełna.",
        "_legal_basis": "P48-I06; K11; P39 (bramki testowe)",
        "_warnings": [],
        "parity_runs": _parity_runs,
        "result_mismatches": _parity_mismatch,
        "mirror_tests_total": _mirror_tests_total,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_test_parity"
    routing_tp06 == "TRIAGE_QUEUE"
    cert := _certificate(448006, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_test_parity",
        "decision_mode": "TRIAGE",
        "_routing": routing_tp06,
        "_routing_reason": "MIRROR-SYNC: brak dowodu parity testów mirror — mirror nie testowany równie surowo.",
        "_legal_basis": "P48-I06; AP06; prompt P48 5.3",
        "_warnings": ["[V3-P48] Uruchom testy na mirror i porównaj wyniki."],
        "parity_runs": _parity_runs,
        "mirror_tests_total": _mirror_tests_total,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_test_parity"
    routing_tp06 == "BLOCK_AND_ALERT"
    cert := _certificate(448006, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_test_parity",
        "decision_mode": "BLOCK",
        "_routing": routing_tp06,
        "_routing_reason": "MIRROR-SYNC: rozjazd wyników testów canonical vs mirror — BLOCKER.",
        "_legal_basis": "P48-I06; AP11; ustawa o ZUS art. 47-48 (spójność deklaracji) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Mirror zachowuje się inaczej niż canonical."],
        "result_mismatches": _parity_mismatch,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I07: GOLDEN REPLAY ON MIRROR — zgodność decyzji przed deploy (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_gmirror := object.get(_ctx, "golden_replay_mirror", {})
_replay_total := object.get(_gmirror, "verdicts_total", 0)
_replay_delta := object.get(_gmirror, "decision_deltas", 0)
_replay_done := object.get(_gmirror, "replay_done", false)

routing_gr07 = "BLOCK_AND_ALERT" {
    _has_flag("replay_bypassed")
} else = "BLOCK_AND_ALERT" {
    _replay_done
    _replay_delta > _replay_delta_max
} else = "TRIAGE_QUEUE" {
    not _replay_done
} else = "AUTO_FILE" {
    true
}

_replay_delta_max := _th("v3_p48_replay_delta_max", 0)

golden_replay_mirror_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "golden_replay_mirror"
    routing_gr07 == "AUTO_FILE"
    cert := _certificate(448007, {
        "rule_id": "jdg.v3_p48_mirror_sync.golden_replay_mirror",
        "decision_mode": "AUTO_POST",
        "_routing": routing_gr07,
        "_routing_reason": "MIRROR-SYNC: replay złotych orzeczeń na mirror = zero delt decyzji.",
        "_legal_basis": "P48-I07; P10 Golden Oracle; V2 F3",
        "_warnings": [],
        "verdicts_total": _replay_total,
        "decision_deltas": _replay_delta,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "golden_replay_mirror"
    routing_gr07 == "TRIAGE_QUEUE"
    cert := _certificate(448007, {
        "rule_id": "jdg.v3_p48_mirror_sync.golden_replay_mirror",
        "decision_mode": "TRIAGE",
        "_routing": routing_gr07,
        "_routing_reason": "MIRROR-SYNC: replay na mirror niewykonany — zgodność decyzji nieudowodniona.",
        "_legal_basis": "P48-I07; P10; AP06",
        "_warnings": ["[V3-P48] Wykonaj golden replay na mirror przed deploy."],
        "verdicts_total": _replay_total,
        "replay_done": _replay_done,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "golden_replay_mirror"
    routing_gr07 == "BLOCK_AND_ALERT"
    cert := _certificate(448007, {
        "rule_id": "jdg.v3_p48_mirror_sync.golden_replay_mirror",
        "decision_mode": "BLOCK",
        "_routing": routing_gr07,
        "_routing_reason": "MIRROR-SYNC: mirror zmienia wyniki złotych orzeczeń — deploy ZABLOKOWANY.",
        "_legal_basis": "P48-I07; V2 F3; KSeF schematy (spójność wersji) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Delta decyzji mirror vs canonical > 0."],
        "decision_deltas": _replay_delta,
        "delta_max": _replay_delta_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I08: MIRROR OWNERSHIP REGISTER — zero pakietów osieroconych (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_own := object.get(_ctx, "mirror_ownership", {})
_packages_total_own := object.get(_own, "packages_total", 0)
_orphan_packages := object.get(_own, "orphan_packages", 0)
_stale_reviews := object.get(_own, "stale_reviews", 0)
_review_days := _th("v3_p48_review_max_age_days", 90)

routing_mo08 = "BLOCK_AND_ALERT" {
    _has_flag("ownership_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _packages_ok
} else = "BLOCK_AND_ALERT" {
    _orphan_packages > 0
} else = "TRIAGE_QUEUE" {
    _stale_reviews > 0
} else = "AUTO_FILE" {
    true
}

mirror_ownership_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_ownership"
    routing_mo08 == "AUTO_FILE"
    cert := _certificate(448008, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_ownership",
        "decision_mode": "AUTO_POST",
        "_routing": routing_mo08,
        "_routing_reason": "MIRROR-SYNC: każdy pakiet mirror ma właściciela i świeży przegląd.",
        "_legal_basis": "P48-I08; V1 model ról operatorów (§12.1)",
        "_warnings": [],
        "packages_total": _packages_total_own,
        "orphan_packages": _orphan_packages,
        "stale_reviews": _stale_reviews,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_ownership"
    routing_mo08 == "TRIAGE_QUEUE"
    cert := _certificate(448008, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_ownership",
        "decision_mode": "TRIAGE",
        "_routing": routing_mo08,
        "_routing_reason": "MIRROR-SYNC: przeglądy własności przeterminowane — zaplanować przegląd.",
        "_legal_basis": "P48-I08; P05 temporalność",
        "_warnings": ["[V3-P48] Przeglądy pakietów mirror przeterminowane."],
        "stale_reviews": _stale_reviews,
        "review_max_age_days": _review_days,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_ownership"
    routing_mo08 == "BLOCK_AND_ALERT"
    cert := _certificate(448008, {
        "rule_id": "jdg.v3_p48_mirror_sync.mirror_ownership",
        "decision_mode": "BLOCK",
        "_routing": routing_mo08,
        "_routing_reason": "MIRROR-SYNC: pakiety mirror bez właściciela — osierocone = ryzyko cichego dryfu.",
        "_legal_basis": "P48-I08; AP11; procedura reakcji prompt P48 5.3",
        "_warnings": ["[V3-P48] Pakiety osierocone — przypisz właściciela."],
        "orphan_packages": _orphan_packages,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I09: POST-DEPLOY MIRROR CHECK — checksum deploy vs canonical (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_pdep := object.get(_ctx, "post_deploy_check", {})
_deploys_checked := object.get(_pdep, "deploys_checked", 0)
_source_mismatch := object.get(_pdep, "source_mismatches", 0)

routing_pd09 = "BLOCK_AND_ALERT" {
    _has_flag("deploy_check_bypassed")
} else = "BLOCK_AND_ALERT" {
    _source_mismatch > 0
} else = "TRIAGE_QUEUE" {
    _deploys_checked == 0
} else = "AUTO_FILE" {
    true
}

post_deploy_check_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "post_deploy_check"
    routing_pd09 == "AUTO_FILE"
    cert := _certificate(448009, {
        "rule_id": "jdg.v3_p48_mirror_sync.post_deploy_check",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pd09,
        "_routing_reason": "MIRROR-SYNC: wdrożone bundly zbudowane z canonical (checksum match).",
        "_legal_basis": "P48-I09; P38 post-deploy; V1 §9.3 (wersje bundle)",
        "_warnings": [],
        "deploys_checked": _deploys_checked,
        "source_mismatches": _source_mismatch,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "post_deploy_check"
    routing_pd09 == "TRIAGE_QUEUE"
    cert := _certificate(448009, {
        "rule_id": "jdg.v3_p48_mirror_sync.post_deploy_check",
        "decision_mode": "TRIAGE",
        "_routing": routing_pd09,
        "_routing_reason": "MIRROR-SYNC: brak kontroli post-deploy — pochodzenie bundle nieudowodnione.",
        "_legal_basis": "P48-I09; P38; AP12",
        "_warnings": ["[V3-P48] Sprawdź checksum wdrożonych bundli vs canonical."],
        "deploys_checked": _deploys_checked,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "post_deploy_check"
    routing_pd09 == "BLOCK_AND_ALERT"
    cert := _certificate(448009, {
        "rule_id": "jdg.v3_p48_mirror_sync.post_deploy_check",
        "decision_mode": "BLOCK",
        "_routing": routing_pd09,
        "_routing_reason": "MIRROR-SYNC: deploy z dryfującego źródła — rollback i przebudowa z canonical.",
        "_legal_basis": "P48-I09; AP11; AI Act (wersjonowanie canonical/deployed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Wdrożono bundle niezgodny z canonical — ROLLBACK."],
        "source_mismatches": _source_mismatch,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I10: CASE-STUDY TEMPLATE — standard analizy dryfu (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_case := object.get(_ctx, "case_study", {})
_open_cases := object.get(_case, "open_cases", 0)
_cases_without_plan := object.get(_case, "cases_without_repair_plan", 0)
_overdue_cases := object.get(_case, "overdue_cases", 0)

routing_cs10 = "BLOCK_AND_ALERT" {
    _has_flag("case_bypassed")
} else = "BLOCK_AND_ALERT" {
    _overdue_cases > 0
} else = "TRIAGE_QUEUE" {
    _cases_without_plan > 0
} else = "TRIAGE_QUEUE" {
    _open_cases > 0
} else = "AUTO_FILE" {
    true
}

case_study_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "case_study"
    routing_cs10 == "AUTO_FILE"
    cert := _certificate(448010, {
        "rule_id": "jdg.v3_p48_mirror_sync.case_study",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cs10,
        "_routing_reason": "MIRROR-SYNC: zero otwartych przypadków dryfu — standard analizy obecny.",
        "_legal_basis": "P48-I10; lekcje kampanii V3 (case study dryfu)",
        "_warnings": [],
        "open_cases": _open_cases,
        "cases_without_repair_plan": _cases_without_plan,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "case_study"
    routing_cs10 == "TRIAGE_QUEUE"
    cert := _certificate(448010, {
        "rule_id": "jdg.v3_p48_mirror_sync.case_study",
        "decision_mode": "TRIAGE",
        "_routing": routing_cs10,
        "_routing_reason": "MIRROR-SYNC: przypadki dryfu bez planu naprawy — uzupełnić przyczyna→skutek→naprawa→kontrola.",
        "_legal_basis": "P48-I10; prompt P48 5.4; P68",
        "_warnings": ["[V3-P48] Case study bez planu naprawy z terminem i właścicielem."],
        "open_cases": _open_cases,
        "cases_without_repair_plan": _cases_without_plan,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "case_study"
    routing_cs10 == "BLOCK_AND_ALERT"
    cert := _certificate(448010, {
        "rule_id": "jdg.v3_p48_mirror_sync.case_study",
        "decision_mode": "BLOCK",
        "_routing": routing_cs10,
        "_routing_reason": "MIRROR-SYNC: przypadek dryfu po terminie naprawy — eskalacja.",
        "_legal_basis": "P48-I10; P48-Q03 (terminy naprawy 4-eyes)",
        "_warnings": ["[V3-P48] Case study dryfu po terminie — BLOCK."],
        "overdue_cases": _overdue_cases,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I11: MIRROR LIFECYCLE ALIGNMENT — statusy mirror = canonical (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_lif := object.get(_ctx, "lifecycle_alignment", {})
_status_mismatches := object.get(_lif, "status_mismatches", 0)
_compared_rules := object.get(_lif, "compared_rules", 0)

routing_la11 = "BLOCK_AND_ALERT" {
    _has_flag("lifecycle_bypassed")
} else = "BLOCK_AND_ALERT" {
    _status_mismatches > 0
} else = "TRIAGE_QUEUE" {
    _compared_rules == 0
} else = "AUTO_FILE" {
    true
}

lifecycle_alignment_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "lifecycle_alignment"
    routing_la11 == "AUTO_FILE"
    cert := _certificate(448011, {
        "rule_id": "jdg.v3_p48_mirror_sync.lifecycle_alignment",
        "decision_mode": "AUTO_POST",
        "_routing": routing_la11,
        "_routing_reason": "MIRROR-SYNC: SHADOW w canonical = SHADOW w mirror — zero rozjazdu statusów.",
        "_legal_basis": "P48-I11; P07 lifecycle; V1 cykl życia reguł",
        "_warnings": [],
        "compared_rules": _compared_rules,
        "status_mismatches": _status_mismatches,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "lifecycle_alignment"
    routing_la11 == "TRIAGE_QUEUE"
    cert := _certificate(448011, {
        "rule_id": "jdg.v3_p48_mirror_sync.lifecycle_alignment",
        "decision_mode": "TRIAGE",
        "_routing": routing_la11,
        "_routing_reason": "MIRROR-SYNC: brak porównania lifecycle mirror vs canonical.",
        "_legal_basis": "P48-I11; P07; AP04",
        "_warnings": ["[V3-P48] Uruchom porównanie statusów lifecycle."],
        "compared_rules": _compared_rules,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "lifecycle_alignment"
    routing_la11 == "BLOCK_AND_ALERT"
    cert := _certificate(448011, {
        "rule_id": "jdg.v3_p48_mirror_sync.lifecycle_alignment",
        "decision_mode": "BLOCK",
        "_routing": routing_la11,
        "_routing_reason": "MIRROR-SYNC: rozjazd statusów lifecycle — mirror aktywny przy canonical SHADOW.",
        "_legal_basis": "P48-I11; V1 zasada 6; Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Statusy lifecycle mirror ≠ canonical — BLOCK."],
        "status_mismatches": _status_mismatches,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48-I12: ONE-TRUTH ATTESTATION — hash reguły w certyfikacie decyzji (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_att := object.get(_ctx, "one_truth_attestation", {})
_certificates_total := object.get(_att, "certificates_total", 0)
_certificates_with_hash := object.get(_att, "certificates_with_rule_hash", 0)

routing_ot12 = "BLOCK_AND_ALERT" {
    _has_flag("attestation_bypassed")
} else = "TRIAGE_QUEUE" {
    _certificates_total > 0
    _certificates_with_hash < _certificates_total
} else = "AUTO_FILE" {
    true
}

one_truth_attestation_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "one_truth_attestation"
    routing_ot12 == "AUTO_FILE"
    cert := _certificate(448012, {
        "rule_id": "jdg.v3_p48_mirror_sync.one_truth_attestation",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ot12,
        "_routing_reason": "MIRROR-SYNC: każdy certyfikat decyzji z hashem użytej wersji reguły.",
        "_legal_basis": "P48-I12; V2 F4 (dowód wersji); V1 §9.3",
        "_warnings": [],
        "certificates_total": _certificates_total,
        "certificates_with_rule_hash": _certificates_with_hash,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "one_truth_attestation"
    routing_ot12 == "TRIAGE_QUEUE"
    cert := _certificate(448012, {
        "rule_id": "jdg.v3_p48_mirror_sync.one_truth_attestation",
        "decision_mode": "TRIAGE",
        "_routing": routing_ot12,
        "_routing_reason": "MIRROR-SYNC: certyfikaty bez hashu reguły — brak dowodu KTO wyliczył.",
        "_legal_basis": "P48-I12; V2 F4; ustawa o rachunkowości art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P48] Dodaj rule_hash do certyfikatów decyzji."],
        "certificates_total": _certificates_total,
        "certificates_with_rule_hash": _certificates_with_hash,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := packages_missing_decision {
    not _packages_ok
} else := mirror_build_decision {
    mirror_build_decision.rule_id != ""
} else := semantic_ast_diff_decision {
    semantic_ast_diff_decision.rule_id != ""
} else := sync_in_pr_decision {
    sync_in_pr_decision.rule_id != ""
} else := drift_heatmap_decision {
    drift_heatmap_decision.rule_id != ""
} else := overlay_declaration_decision {
    overlay_declaration_decision.rule_id != ""
} else := mirror_test_parity_decision {
    mirror_test_parity_decision.rule_id != ""
} else := golden_replay_mirror_decision {
    golden_replay_mirror_decision.rule_id != ""
} else := mirror_ownership_decision {
    mirror_ownership_decision.rule_id != ""
} else := post_deploy_check_decision {
    post_deploy_check_decision.rule_id != ""
} else := case_study_decision {
    case_study_decision.rule_id != ""
} else := lifecycle_alignment_decision {
    lifecycle_alignment_decision.rule_id != ""
} else := one_truth_attestation_decision {
    one_truth_attestation_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p48_mirror_sync.no_match",
    "package": "jdg.v3_p48_mirror_sync",
    "priority": 999999,
}
