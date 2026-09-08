# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P36 GENERATORY MIGRATORY — TRANSFORMACJE JAKO TRANSAKCJE
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa generatorów i migracji ENTERPRISE — 12 analiz (I01–I12; minimum
# z promptu):
#   I01 Transform Transaction (dry-run diff → apply z dziennikiem →
#       auto-walidacja → auto-rollback; zero stanów pośrednich),
#   I02 Idempotency Certificate (każde narzędzie ma test idempotencji: drugi
#       run = zero diff; wymuszony w bramce P29; drugi run z diffem = BLOCK),
#   I03 Plan-to-Rules Pipeline (plan → walidacja planu (crossref, duplikaty)
#       → generacja reguł+testów jednocześnie; reguła bez testu = BLOCK),
#   I04 Migration Ledger (globalny dziennik migracji z checksumami — pełna
#       odtwarzalność historii; wpis bez checksumy = BLOCK),
#   I05 Guard Rails Generatora (generatory odmawiają produkcji reguł bez:
#       legal basis, rule_id, okna temporalnego, testu — fail-fast;
#       wyprodukowana reguła bez wymaganych pól = BLOCK),
#   I06 Golden Replay po Migracji (automatyczny replay P10 po masowej zmianie;
#       regresja = auto-rollback; dryf > 0 = TRIAGE),
#   I07 Mirror-Aware Apply (canonical i mirror w jednej transakcji — sync
#       guarantee z P39/P48; dryf mirror = TRIAGE),
#   I08 Generator Testów Granicznych (z tabeli aktów: progi, daty, stawki →
#       przypadki brzegowe groszowe i day-0/day+1; hardcode granic = BLOCK),
#   I09 Dry-Run Report (raport przed zmianą: ile plików, jakie reguły, jakie
#       ryzyka — do 4-eyes dla zmian krytycznych; zmiana bez raportu = BLOCK),
#   I10 Naming Convention Enforcer (walidator konwencji rule_id/pakietów/plików
#       jako wymóg generatorów; naruszenie konwencji = BLOCK),
#   I11 Migracja jako Dane (definicja migracji: mapowania, wyjątki w danych;
#       migracja bez definicji = BLOCK),
#   I12 Zero-Orphan Guarantee (po transformacji: żadna reguła bez testu,
#       żaden test bez reguły, żaden manifest bez pliku; orphan = BLOCK).
#
# Integracje (kontrakty między-częściowe):
#   * P03 (kontrakt werdyktu) — każda analiza emituje zgodny werdykt,
#   * P04 (invarianty) — transformacje nigdy nie omijają warstwy
#     konstytucyjnej; auto-rollback przy naruszeniu,
#   * P07 (lifecycle) — wygenerowane reguły wchodzą przez SHADOW/CANDIDATE,
#   * P10 (Golden Oracle) — replay po migracji (I06),
#   * P29 (kampanie jakości) — idempotencja wymuszona w bramkach (I02),
#   * P32 (automatyzacja) — granice groszowe jako dane testowe (I08 spójny
#     z P32-I06),
#   * P33 (warstwa AI) — propozycje AI przechodzą ten sam pipeline (I03/I05),
#   * P34 (walidacja) — DAG L1-L5 jako auto-walidacja transformacji (I01),
#   * P39 (CI) — sync guarantee mirror (I07),
#   * P48 (mirror sync) — mirror-aware apply (I07).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p36 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak raportu, orphan, brak checksumy,
#     naruszenie konwencji = BLOCK — nigdy cichy AUTO_POST.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p36_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p36_generatory_migratory.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p36_generatory_migratory
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p36_generatory_migratory

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p36_check", false) == true
_ctx := object.get(input, "v3_p36", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p36_snapshot := data.jdg.thresholds.v3_p36

_snapshot_ok = true {
    count(_p36_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p36_snapshot) > 0
    value := object.get(_p36_snapshot, key, null)
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
    "rule_id": "jdg.v3_p36_generatory_migratory.thresholds_missing",
    "package": "jdg.v3_p36_generatory_migratory",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "GENERATORY MIGRATORY V3-P36: brak snapshotu data.jdg.thresholds.v3_p36.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P36] Brak snapshotu progów generatorów — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p36_generatory_migratory",
        "priority": priority,
        "threshold_version": object.get(_p36_snapshot, "v3_p36_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p36_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p36_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I01: TRANSFORM TRANSACTION — dry-run → apply → walidacja → rollback (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_tt := object.get(_ctx, "transform_transaction", {})
_tt_partial := object.get(_tt, "partial_states", 0)
_tt_no_rollback := object.get(_tt, "applies_without_rollback_path", 0)

routing_tt01 = "BLOCK_AND_ALERT" {
    _tt_no_rollback > 0
} else = "BLOCK_AND_ALERT" {
    _tt_partial > 0
} else = "SUGGEST" {
    true
}

reason_tt01 = sprintf("Aplikacje transformacji bez ścieżki rollback: %v — BLOCK (zero stanów pośrednich; dry-run → apply → walidacja → rollback).", [_tt_no_rollback]) {
    _tt_no_rollback > 0
} else = sprintf("Stany pośrednie po transformacji: %v — BLOCK (transakcja: wszystko albo nic; auto-walidacja i auto-rollback).", [_tt_partial]) {
    _tt_partial > 0
} else = sprintf("Transform transaction OK: dry-run diff → apply z dziennikiem → auto-walidacja → auto-rollback gotowe; zero stanów pośrednich.", []) {
    true
}

transform_transaction_decision := _certificate(436001, {
    "rule_id": "jdg.v3_p36_generatory_migratory.transform_transaction",
    "analysis": "transform_transaction",
    "partial_states": _tt_partial,
    "applies_without_rollback_path": _tt_no_rollback,
    "_routing": routing_tt01,
    "_routing_reason": reason_tt01,
    "_legal_basis": "V3_P36 §10/I01; V1 zasada 6 (fail-closed); UoR art. 4 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "transform_transaction"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I02: IDEMPOTENCY CERTIFICATE — drugi run = zero diff (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_idm := object.get(_ctx, "idempotency_certificate", {})
_idm_failed := object.get(_idm, "tools_without_idempotency_test", [])
_idm_diffs := object.get(_idm, "second_run_diffs", 0)

routing_ic02 = "BLOCK_AND_ALERT" {
    _idm_diffs > 0
} else = "TRIAGE_QUEUE" {
    count(_idm_failed) > 0
} else = "SUGGEST" {
    true
}

reason_ic02 = sprintf("Drugi run narzędzi z diffem: %v — BLOCK (idempotencja złamana; bramka P29 wymusza test).", [_idm_diffs]) {
    _idm_diffs > 0
} else = sprintf("Narzędzia bez testu idempotencji: %v — TRIAGE (każde narzędzie z certyfikatem idempotencji).", [_idm_failed]) {
    count(_idm_failed) > 0
} else = sprintf("Idempotency certificate OK: wszystkie narzędzia z testem (drugi run = zero diff).", []) {
    true
}

idempotency_certificate_decision := _certificate(436002, {
    "rule_id": "jdg.v3_p36_generatory_migratory.idempotency_certificate",
    "analysis": "idempotency_certificate",
    "tools_without_idempotency_test": count(_idm_failed),
    "second_run_diffs": _idm_diffs,
    "_routing": routing_ic02,
    "_routing_reason": reason_ic02,
    "_legal_basis": "V3_P36 §10/I02; kontrakt P29 (bramki); UoR art. 4 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "idempotency_certificate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I03: PLAN-TO-RULES PIPELINE — reguły+testy jednocześnie (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_ptr := object.get(_ctx, "plan_to_rules", {})
_ptr_no_test := object.get(_ptr, "rules_without_test", 0)
_ptr_invalid := object.get(_ptr, "invalid_plans", 0)

routing_pr03 = "BLOCK_AND_ALERT" {
    _ptr_no_test > 0
} else = "TRIAGE_QUEUE" {
    _ptr_invalid > 0
} else = "SUGGEST" {
    true
}

reason_pr03 = sprintf("Reguły wygenerowane bez testu: %v — BLOCK (generacja reguł+testów jednocześnie; zakaz reguły bez testu).", [_ptr_no_test]) {
    _ptr_no_test > 0
} else = sprintf("Plany niewalidowane (crossref, duplikaty): %v — TRIAGE (walidacja planu przed generacją).", [_ptr_invalid]) {
    _ptr_invalid > 0
} else = sprintf("Plan-to-rules pipeline OK: %v reguł z testami wygenerowanych z planów.", [object.get(_ptr, "rules_generated", 0)]) {
    true
}

plan_to_rules_decision := _certificate(436003, {
    "rule_id": "jdg.v3_p36_generatory_migratory.plan_to_rules",
    "analysis": "plan_to_rules",
    "rules_without_test": _ptr_no_test,
    "invalid_plans": _ptr_invalid,
    "_routing": routing_pr03,
    "_routing_reason": reason_pr03,
    "_legal_basis": "V3_P36 §10/I03; zakaz duplikacji (P00); kontrakt P33 (propozycje AI tym samym pipeline)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "plan_to_rules"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I04: MIGRATION LEDGER — dziennik z checksumami (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_ml := object.get(_ctx, "migration_ledger", {})
_ml_no_checksum := object.get(_ml, "entries_without_checksum", 0)
_ml_missing := object.get(_ml, "migrations_without_entry", 0)

routing_ml04 = "BLOCK_AND_ALERT" {
    _ml_no_checksum > 0
} else = "BLOCK_AND_ALERT" {
    _ml_missing > 0
} else = "SUGGEST" {
    true
}

reason_ml04 = sprintf("Wpisy dziennika migracji bez checksumy: %v — BLOCK (pełna odtwarzalność historii wymaga checksum).", [_ml_no_checksum]) {
    _ml_no_checksum > 0
} else = sprintf("Migracje bez wpisu w dzienniku: %v — BLOCK (każda migracja: które narzędzie, kiedy, jakie pliki).", [_ml_missing]) {
    _ml_missing > 0
} else = sprintf("Migration ledger OK: %v wpisów z checksumami — historia odtwarzalna.", [object.get(_ml, "entries_total", 0)]) {
    true
}

migration_ledger_decision := _certificate(436004, {
    "rule_id": "jdg.v3_p36_generatory_migratory.migration_ledger",
    "analysis": "migration_ledger",
    "entries_without_checksum": _ml_no_checksum,
    "migrations_without_entry": _ml_missing,
    "_routing": routing_ml04,
    "_routing_reason": reason_ml04,
    "_legal_basis": "V3_P36 §10/I04; UoR art. 74-75 (archiwum) [NIEZWERYFIKOWANE]; kontrakt P43 (WORM)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "migration_ledger"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I05: GUARD RAILS GENERATORA — fail-fast bez legal basis/rule_id/okna/testu (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_gr := object.get(_ctx, "guard_rails", {})
_gr_violations := object.get(_gr, "rules_missing_required_fields", 0)
_gr_bypassed := object.get(_gr, "guard_rails_bypassed", 0)

routing_gi05 = "BLOCK_AND_ALERT" {
    _gr_bypassed > 0
} else = "BLOCK_AND_ALERT" {
    _gr_violations > 0
} else = "SUGGEST" {
    true
}

reason_gi05 = sprintf("Guard rails ominięte: %v — BLOCK (generatory odmawiają produkcji reguł bez legal basis, rule_id, okna temporalnego i testu — fail-fast).", [_gr_bypassed]) {
    _gr_bypassed > 0
} else = sprintf("Reguły bez wymaganych pól (legal basis/rule_id/okno/test): %v — BLOCK (fail-fast z komunikatem).", [_gr_violations]) {
    _gr_violations > 0
} else = "Guard rails OK: żaden generator nie wyprodukuje reguły bez pełnego pakietu wymaganych pól." {
    true
}

guard_rails_decision := _certificate(436005, {
    "rule_id": "jdg.v3_p36_generatory_migratory.guard_rails",
    "analysis": "guard_rails",
    "rules_missing_required_fields": _gr_violations,
    "guard_rails_bypassed": _gr_bypassed,
    "_routing": routing_gi05,
    "_routing_reason": reason_gi05,
    "_legal_basis": "V3_P36 §10/I05; ADR-002 (okna temporalne); zasada źródeł (legal basis); kontrakt P07",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "guard_rails"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I06: GOLDEN REPLAY PO MIGRACJI — regresja = auto-rollback (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_grp := object.get(_ctx, "golden_replay_post_migration", {})
_grp_drift := object.get(_grp, "drifted_decisions", 0)
_grp_skipped := object.get(_grp, "migrations_without_replay", 0)
_grp_drift_max := _th("v3_p36_replay_drift_max", 0)

routing_gm06 = "BLOCK_AND_ALERT" {
    _grp_drift > _grp_drift_max * 10
} else = "TRIAGE_QUEUE" {
    _grp_drift > _grp_drift_max
} else = "TRIAGE_QUEUE" {
    _grp_skipped > 0
} else = "SUGGEST" {
    true
}

reason_gm06 = sprintf("Replay po migracji: dryf %v > %v — BLOCK (regresja = auto-rollback transformacji; P10).", [_grp_drift, _grp_drift_max * 10]) {
    _grp_drift > _grp_drift_max * 10
} else = sprintf("Replay po migracji: dryf %v > %v — TRIAGE (przejrzeć zmiany werdyktów).", [_grp_drift, _grp_drift_max]) {
    _grp_drift > _grp_drift_max
} else = sprintf("Migracje bez golden replay: %v — TRIAGE (replay automatyczny po każdej masowej zmianie).", [_grp_skipped]) {
    _grp_skipped > 0
} else = sprintf("Golden replay po migracji OK: dryf %v ≤ %v, wszystkie migracje z replay (P10).", [_grp_drift, _grp_drift_max]) {
    true
}

golden_replay_post_migration_decision := _certificate(436006, {
    "rule_id": "jdg.v3_p36_generatory_migratory.golden_replay_post_migration",
    "analysis": "golden_replay_post_migration",
    "drifted_decisions": _grp_drift,
    "migrations_without_replay": _grp_skipped,
    "drift_max": _grp_drift_max,
    "_routing": routing_gm06,
    "_routing_reason": reason_gm06,
    "_legal_basis": "V3_P36 §10/I06; kontrakt P10 (Golden Oracle); kontrakt P32-I07 (replay sezonowy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_replay_post_migration"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I07: MIRROR-AWARE APPLY — canonical i mirror w jednej transakcji (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_ma := object.get(_ctx, "mirror_aware_apply", {})
_ma_divergent := object.get(_ma, "mirror_divergent_after_apply", 0)
_ma_canonical_only := object.get(_ma, "applies_canonical_only", 0)

routing_mi07 = "BLOCK_AND_ALERT" {
    _ma_canonical_only > 0
} else = "TRIAGE_QUEUE" {
    _ma_divergent > 0
} else = "SUGGEST" {
    true
}

reason_mi07 = sprintf("Aplikacje tylko na canonical bez mirror: %v — BLOCK (mirror-aware apply: canonical i mirror w jednej transakcji; sync guarantee P39/P48).", [_ma_canonical_only]) {
    _ma_canonical_only > 0
} else = sprintf("Rozbieżności mirror po aplikacji: %v — TRIAGE (zweryfikować sync; P48).", [_ma_divergent]) {
    _ma_divergent > 0
} else = "Mirror-aware apply OK: canonical i mirror aktualizowane w jednej transakcji." {
    true
}

mirror_aware_apply_decision := _certificate(436007, {
    "rule_id": "jdg.v3_p36_generatory_migratory.mirror_aware_apply",
    "analysis": "mirror_aware_apply",
    "mirror_divergent_after_apply": _ma_divergent,
    "applies_canonical_only": _ma_canonical_only,
    "_routing": routing_mi07,
    "_routing_reason": reason_mi07,
    "_legal_basis": "V3_P36 §10/I07; kontrakt P48 (mirror sync); AP11",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mirror_aware_apply"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I08: GENERATOR TESTÓW GRANICZNYCH — grosze i day-0/day+1 z aktów (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_gb := object.get(_ctx, "boundary_test_generator", {})
_gb_hardcode := _has_flag("boundary_values_hardcoded")
_gb_partial := object.get(_gb, "rules_without_boundary_tests", 0)
_gb_min := _th("v3_p36_boundary_rules_min_covered", 100)

routing_bg08 = "BLOCK_AND_ALERT" {
    _gb_hardcode
} else = "TRIAGE_QUEUE" {
    _gb_partial > 0
} else = "SUGGEST" {
    true
}

reason_bg08 = sprintf("Granice testowe wkodowane na stałe — BLOCK (progi/daty/stawki z tabeli aktów jako dane; ADR-002; P32-I06).", []) {
    _gb_hardcode
} else = sprintf("Reguły wyliczania bez testów granicznych (0,00/0,01/max, day-0/day+1): %v — TRIAGE (generator z tabeli aktów).", [_gb_partial]) {
    _gb_partial > 0
} else = sprintf("Generator testów granicznych OK: pokrycie reguł wyliczania ≥ %v%%.", [_gb_min]) {
    true
}

boundary_test_generator_decision := _certificate(436008, {
    "rule_id": "jdg.v3_p36_generatory_migratory.boundary_test_generator",
    "analysis": "boundary_test_generator",
    "rules_without_boundary_tests": _gb_partial,
    "boundary_values_hardcoded": _gb_hardcode,
    "_routing": routing_bg08,
    "_routing_reason": reason_bg08,
    "_legal_basis": "V3_P36 §10/I08; ADR-002; kontrakt P32-I06 (granice groszowe); P36-generator (P32)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "boundary_test_generator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I09: DRY-RUN REPORT — raport przed zmianą, 4-eyes dla krytycznych (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_dr := object.get(_ctx, "dry_run_report", {})
_dr_missing := object.get(_dr, "changes_without_report", 0)
_dr_critical_unapproved := object.get(_dr, "critical_unapproved", 0)

routing_drr09 = "BLOCK_AND_ALERT" {
    _dr_critical_unapproved > 0
} else = "BLOCK_AND_ALERT" {
    _dr_missing > 0
} else = "SUGGEST" {
    true
}

reason_drr09 = sprintf("Zmiany krytyczne bez zatwierdzenia 4-eyes: %v — BLOCK (dry-run report do przeglądu człowieka).", [_dr_critical_unapproved]) {
    _dr_critical_unapproved > 0
} else = sprintf("Zmiany bez raportu dry-run (ile plików, jakie reguły, jakie ryzyka): %v — BLOCK (raport przed zmianą obowiązkowy).", [_dr_missing]) {
    _dr_missing > 0
} else = sprintf("Dry-run report OK: wszystkie zmiany z raportem, krytyczne z 4-eyes.", []) {
    true
}

dry_run_report_decision := _certificate(436009, {
    "rule_id": "jdg.v3_p36_generatory_migratory.dry_run_report",
    "analysis": "dry_run_report",
    "changes_without_report": _dr_missing,
    "critical_unapproved": _dr_critical_unapproved,
    "_routing": routing_drr09,
    "_routing_reason": reason_drr09,
    "_legal_basis": "V3_P36 §10/I09; kontrakt P07 (4-eyes); KKS (człowiek zatwierdza) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dry_run_report"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I10: NAMING CONVENTION ENFORCER — rule_id/pakiety/pliki (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_nce := object.get(_ctx, "naming_convention_enforcer", {})
_nce_violations := object.get(_nce, "naming_violations", 0)

routing_nc10 = "BLOCK_AND_ALERT" {
    _nce_violations > 0
} else = "SUGGEST" {
    true
}

reason_nc10 = sprintf("Naruszenia konwencji nazewniczych (rule_id, pakiety, pliki): %v — BLOCK (standardy P00/P11.5 wiążące generatory).", [_nce_violations]) {
    _nce_violations > 0
} else = sprintf("Naming convention OK: %v artefaktów zgodnych z konwencją.", [object.get(_nce, "artifacts_checked", 0)]) {
    true
}

naming_convention_enforcer_decision := _certificate(436010, {
    "rule_id": "jdg.v3_p36_generatory_migratory.naming_convention_enforcer",
    "analysis": "naming_convention_enforcer",
    "naming_violations": _nce_violations,
    "artifacts_checked": object.get(_nce, "artifacts_checked", 0),
    "_routing": routing_nc10,
    "_routing_reason": reason_nc10,
    "_legal_basis": "V3_P36 §10/I10; standardy nazewnicze P00 (11.5)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "naming_convention_enforcer"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I11: MIGRACJA JAKO DANE — mapowania i wyjątki w danych (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_mad := object.get(_ctx, "migration_as_data", {})
_mad_undefined := object.get(_mad, "migrations_without_definition", 0)
_mad_hardcoded := _has_flag("mappings_hardcoded")

routing_md11 = "BLOCK_AND_ALERT" {
    _mad_hardcoded
} else = "BLOCK_AND_ALERT" {
    _mad_undefined > 0
} else = "SUGGEST" {
    true
}

reason_md11 = sprintf("Mapowania migracji wkodowane w kod — BLOCK (migracja jako dane: mapowania i wyjątki w definicji; przegląd bez kodu; ADR-002).", []) {
    _mad_hardcoded
} else = sprintf("Migracje bez definicji w danych: %v — BLOCK (narzędzie jest silnikiem, definicja jest daną).", [_mad_undefined]) {
    _mad_undefined > 0
} else = "Migracja jako dane OK: wszystkie migracje z definicją (mapowania, wyjątki) w danych." {
    true
}

migration_as_data_decision := _certificate(436011, {
    "rule_id": "jdg.v3_p36_generatory_migratory.migration_as_data",
    "analysis": "migration_as_data",
    "migrations_without_definition": _mad_undefined,
    "mappings_hardcoded": _mad_hardcoded,
    "_routing": routing_md11,
    "_routing_reason": reason_md11,
    "_legal_basis": "V3_P36 §10/I11; ADR-002 (params-as-data)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "migration_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36-I12: ZERO-ORPHAN GUARANTEE — reguła bez testu, test bez reguły, manifest bez pliku (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_zo := object.get(_ctx, "zero_orphan_guarantee", {})
_zo_rules_wo_test := object.get(_zo, "rules_without_test", 0)
_zo_tests_wo_rule := object.get(_zo, "tests_without_rule", 0)
_zo_manifests_wo_file := object.get(_zo, "manifests_without_file", 0)

routing_zo12 = "BLOCK_AND_ALERT" {
    (_zo_rules_wo_test + _zo_tests_wo_rule + _zo_manifests_wo_file) > _th("v3_p36_orphans_max", 0)
} else = "SUGGEST" {
    true
}

reason_zo12 = sprintf("Orphans po transformacji: reguły bez testu = %v, testy bez reguły = %v, manifesty bez pliku = %v (limit %v) — BLOCK (zero-orphan guarantee).", [_zo_rules_wo_test, _zo_tests_wo_rule, _zo_manifests_wo_file, _th("v3_p36_orphans_max", 0)]) {
    (_zo_rules_wo_test + _zo_tests_wo_rule + _zo_manifests_wo_file) > _th("v3_p36_orphans_max", 0)
} else = "Zero-orphan guarantee OK: każda reguła z testem, każdy test z regułą, każdy manifest z plikiem." {
    true
}

zero_orphan_guarantee_decision := _certificate(436012, {
    "rule_id": "jdg.v3_p36_generatory_migratory.zero_orphan_guarantee",
    "analysis": "zero_orphan_guarantee",
    "rules_without_test": _zo_rules_wo_test,
    "tests_without_rule": _zo_tests_wo_rule,
    "manifests_without_file": _zo_manifests_wo_file,
    "orphans_max": _th("v3_p36_orphans_max", 0),
    "_routing": routing_zo12,
    "_routing_reason": reason_zo12,
    "_legal_basis": "V3_P36 §10/I12; V1 (spójność artefaktów); kanon P00",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "zero_orphan_guarantee"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := transform_transaction_decision {
    transform_transaction_decision.rule_id != ""
} else := idempotency_certificate_decision {
    idempotency_certificate_decision.rule_id != ""
} else := plan_to_rules_decision {
    plan_to_rules_decision.rule_id != ""
} else := migration_ledger_decision {
    migration_ledger_decision.rule_id != ""
} else := guard_rails_decision {
    guard_rails_decision.rule_id != ""
} else := golden_replay_post_migration_decision {
    golden_replay_post_migration_decision.rule_id != ""
} else := mirror_aware_apply_decision {
    mirror_aware_apply_decision.rule_id != ""
} else := boundary_test_generator_decision {
    boundary_test_generator_decision.rule_id != ""
} else := dry_run_report_decision {
    dry_run_report_decision.rule_id != ""
} else := naming_convention_enforcer_decision {
    naming_convention_enforcer_decision.rule_id != ""
} else := migration_as_data_decision {
    migration_as_data_decision.rule_id != ""
} else := zero_orphan_guarantee_decision {
    zero_orphan_guarantee_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p36_generatory_migratory.no_match",
    "package": "jdg.v3_p36_generatory_migratory",
    "priority": 999999,
}
