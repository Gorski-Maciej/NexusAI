# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P36 GENERATORY MIGRATORY (jdg.v3_p36_generatory_migratory)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (replay drift, orphans_max, hardcode granic i mapowań, 4-eyes).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p36_generatory_migratory_enterprise.rego \
#       JDG/rules/v3_p36_generatory_migratory_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p36

import future.keywords.in

import data.jdg.v3_p36_generatory_migratory

_base := {"jdg_entrepreneur": {"v3_p36_check": true}}

_cases := {
    # I01: transform transaction
    "tt_no_rollback": {"analysis": "transform_transaction",
                       "transform_transaction": {"partial_states": 0,
                                                 "applies_without_rollback_path": 1}},
    "tt_partial": {"analysis": "transform_transaction",
                   "transform_transaction": {"partial_states": 2,
                                             "applies_without_rollback_path": 0}},
    "tt_ok": {"analysis": "transform_transaction",
              "transform_transaction": {"partial_states": 0,
                                        "applies_without_rollback_path": 0}},

    # I02: idempotency certificate
    "ic_diffs": {"analysis": "idempotency_certificate",
                 "idempotency_certificate": {"tools_without_idempotency_test": [],
                                             "second_run_diffs": 1}},
    "ic_no_test": {"analysis": "idempotency_certificate",
                   "idempotency_certificate": {"tools_without_idempotency_test": ["fix_x"],
                                               "second_run_diffs": 0}},
    "ic_ok": {"analysis": "idempotency_certificate",
              "idempotency_certificate": {"tools_without_idempotency_test": [],
                                          "second_run_diffs": 0}},

    # I03: plan-to-rules pipeline
    "pr_no_test": {"analysis": "plan_to_rules",
                   "plan_to_rules": {"rules_without_test": 1, "invalid_plans": 0,
                                     "rules_generated": 5}},
    "pr_invalid": {"analysis": "plan_to_rules",
                   "plan_to_rules": {"rules_without_test": 0, "invalid_plans": 2,
                                     "rules_generated": 0}},
    "pr_ok": {"analysis": "plan_to_rules",
              "plan_to_rules": {"rules_without_test": 0, "invalid_plans": 0,
                                "rules_generated": 12}},

    # I04: migration ledger
    "ml_no_checksum": {"analysis": "migration_ledger",
                       "migration_ledger": {"entries_without_checksum": 1,
                                            "migrations_without_entry": 0,
                                            "entries_total": 10}},
    "ml_missing": {"analysis": "migration_ledger",
                   "migration_ledger": {"entries_without_checksum": 0,
                                        "migrations_without_entry": 1,
                                        "entries_total": 9}},
    "ml_ok": {"analysis": "migration_ledger",
              "migration_ledger": {"entries_without_checksum": 0,
                                   "migrations_without_entry": 0,
                                   "entries_total": 15}},

    # I05: guard rails generatora
    "gr_bypassed": {"analysis": "guard_rails",
                    "guard_rails": {"rules_missing_required_fields": 0,
                                    "guard_rails_bypassed": 1}},
    "gr_missing": {"analysis": "guard_rails",
                   "guard_rails": {"rules_missing_required_fields": 2,
                                   "guard_rails_bypassed": 0}},
    "gr_ok": {"analysis": "guard_rails",
              "guard_rails": {"rules_missing_required_fields": 0,
                              "guard_rails_bypassed": 0}},

    # I06: golden replay po migracji
    "gm_drift": {"analysis": "golden_replay_post_migration",
                 "golden_replay_post_migration": {"drifted_decisions": 1,
                                                  "migrations_without_replay": 0}},
    "gm_skipped": {"analysis": "golden_replay_post_migration",
                   "golden_replay_post_migration": {"drifted_decisions": 0,
                                                    "migrations_without_replay": 1}},
    "gm_ok": {"analysis": "golden_replay_post_migration",
              "golden_replay_post_migration": {"drifted_decisions": 0,
                                               "migrations_without_replay": 0}},

    # I07: mirror-aware apply
    "ma_canonical_only": {"analysis": "mirror_aware_apply",
                          "mirror_aware_apply": {"mirror_divergent_after_apply": 0,
                                                 "applies_canonical_only": 1}},
    "ma_divergent": {"analysis": "mirror_aware_apply",
                     "mirror_aware_apply": {"mirror_divergent_after_apply": 2,
                                            "applies_canonical_only": 0}},
    "ma_ok": {"analysis": "mirror_aware_apply",
              "mirror_aware_apply": {"mirror_divergent_after_apply": 0,
                                     "applies_canonical_only": 0}},

    # I08: generator testów granicznych (hardcode na poziomie ctx)
    "bg_hardcode": {"analysis": "boundary_test_generator",
                    "boundary_values_hardcoded": true,
                    "boundary_test_generator": {"rules_without_boundary_tests": 0}},
    "bg_partial": {"analysis": "boundary_test_generator",
                   "boundary_test_generator": {"rules_without_boundary_tests": 3}},
    "bg_ok": {"analysis": "boundary_test_generator",
              "boundary_test_generator": {"rules_without_boundary_tests": 0}},

    # I09: dry-run report
    "dr_unapproved": {"analysis": "dry_run_report",
                      "dry_run_report": {"changes_without_report": 0,
                                         "critical_unapproved": 1}},
    "dr_missing": {"analysis": "dry_run_report",
                   "dry_run_report": {"changes_without_report": 2,
                                      "critical_unapproved": 0}},
    "dr_ok": {"analysis": "dry_run_report",
              "dry_run_report": {"changes_without_report": 0,
                                 "critical_unapproved": 0}},

    # I10: naming convention enforcer
    "nc_violations": {"analysis": "naming_convention_enforcer",
                      "naming_convention_enforcer": {"naming_violations": 1,
                                                     "artifacts_checked": 100}},
    "nc_ok": {"analysis": "naming_convention_enforcer",
              "naming_convention_enforcer": {"naming_violations": 0,
                                             "artifacts_checked": 120}},

    # I11: migracja jako dane (hardcode na poziomie ctx)
    "md_hardcoded": {"analysis": "migration_as_data",
                     "mappings_hardcoded": true,
                     "migration_as_data": {"migrations_without_definition": 0}},
    "md_undefined": {"analysis": "migration_as_data",
                     "migration_as_data": {"migrations_without_definition": 2}},
    "md_ok": {"analysis": "migration_as_data",
              "migration_as_data": {"migrations_without_definition": 0}},

    # I12: zero-orphan guarantee
    "zo_orphans": {"analysis": "zero_orphan_guarantee",
                   "zero_orphan_guarantee": {"rules_without_test": 1,
                                             "tests_without_rule": 0,
                                             "manifests_without_file": 0}},
    "zo_ok": {"analysis": "zero_orphan_guarantee",
              "zero_orphan_guarantee": {"rules_without_test": 0,
                                        "tests_without_rule": 0,
                                        "manifests_without_file": 0}},
}

_decide(case) = d {
    d := v3_p36_generatory_migratory.decide with input as object.union(_base, {"v3_p36": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "tt_no_rollback": "BLOCK_AND_ALERT", "tt_partial": "BLOCK_AND_ALERT", "tt_ok": "SUGGEST",
    "ic_diffs": "BLOCK_AND_ALERT", "ic_no_test": "TRIAGE_QUEUE", "ic_ok": "SUGGEST",
    "pr_no_test": "BLOCK_AND_ALERT", "pr_invalid": "TRIAGE_QUEUE", "pr_ok": "SUGGEST",
    "ml_no_checksum": "BLOCK_AND_ALERT", "ml_missing": "BLOCK_AND_ALERT", "ml_ok": "SUGGEST",
    "gr_bypassed": "BLOCK_AND_ALERT", "gr_missing": "BLOCK_AND_ALERT", "gr_ok": "SUGGEST",
    "gm_drift": "BLOCK_AND_ALERT", "gm_skipped": "TRIAGE_QUEUE", "gm_ok": "SUGGEST",
    "ma_canonical_only": "BLOCK_AND_ALERT", "ma_divergent": "TRIAGE_QUEUE", "ma_ok": "SUGGEST",
    "bg_hardcode": "BLOCK_AND_ALERT", "bg_partial": "TRIAGE_QUEUE", "bg_ok": "SUGGEST",
    "dr_unapproved": "BLOCK_AND_ALERT", "dr_missing": "BLOCK_AND_ALERT", "dr_ok": "SUGGEST",
    "nc_violations": "BLOCK_AND_ALERT", "nc_ok": "SUGGEST",
    "md_hardcoded": "BLOCK_AND_ALERT", "md_undefined": "BLOCK_AND_ALERT", "md_ok": "SUGGEST",
    "zo_orphans": "BLOCK_AND_ALERT", "zo_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p36_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: rollback = BLOCK; stany pośrednie = BLOCK (zero stanów pośrednich) ───
test_p36_i01_no_rollback_block {
    d := _decide("tt_no_rollback")
    d.applies_without_rollback_path == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i01_partial_states_block {
    d := _decide("tt_partial")
    d.partial_states == 2
    d._routing == "BLOCK_AND_ALERT"
}

# ── I02: drugi run z diffem = BLOCK; brak testu = TRIAGE ──────────────────────
test_p36_i02_second_run_diff_block {
    d := _decide("ic_diffs")
    d.second_run_diffs == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i02_no_test_triage {
    d := _decide("ic_no_test")
    d.tools_without_idempotency_test == 1
    d._routing == "TRIAGE_QUEUE"
}

# ── I03: reguła bez testu = BLOCK; plan niewalidowany = TRIAGE ────────────────
test_p36_i03_rule_without_test_block {
    d := _decide("pr_no_test")
    d.rules_without_test == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i03_invalid_plan_triage {
    d := _decide("pr_invalid")
    d.invalid_plans == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I04: wpis bez checksumy = BLOCK; migracja bez wpisu = BLOCK ───────────────
test_p36_i04_no_checksum_block {
    d := _decide("ml_no_checksum")
    d.entries_without_checksum == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i04_migration_missing_block {
    d := _decide("ml_missing")
    d.migrations_without_entry == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I05: guard rails ominięte = BLOCK; brak pól = BLOCK ───────────────────────
test_p36_i05_bypassed_block {
    d := _decide("gr_bypassed")
    d.guard_rails_bypassed == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i05_missing_fields_block {
    d := _decide("gr_missing")
    d.rules_missing_required_fields == 2
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: dryf replay > 0 (limit 0) = BLOCK; migracja bez replay = TRIAGE ──────
test_p36_i06_drift_block {
    d := _decide("gm_drift")
    d.drifted_decisions == 1
    d.drift_max == 0
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i06_skipped_triage {
    d := _decide("gm_skipped")
    d.migrations_without_replay == 1
    d._routing == "TRIAGE_QUEUE"
}

# ── I07: canonical bez mirror = BLOCK; rozbieżność mirror = TRIAGE ────────────
test_p36_i07_canonical_only_block {
    d := _decide("ma_canonical_only")
    d.applies_canonical_only == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i07_divergent_triage {
    d := _decide("ma_divergent")
    d.mirror_divergent_after_apply == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I08: granice wkodowane = BLOCK; brak testów granicznych = TRIAGE ──────────
test_p36_i08_hardcode_block {
    d := _decide("bg_hardcode")
    d.boundary_values_hardcoded == true
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i08_partial_triage {
    d := _decide("bg_partial")
    d.rules_without_boundary_tests == 3
    d._routing == "TRIAGE_QUEUE"
}

# ── I09: krytyczne bez 4-eyes = BLOCK; zmiana bez raportu = BLOCK ─────────────
test_p36_i09_unapproved_block {
    d := _decide("dr_unapproved")
    d.critical_unapproved == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i09_missing_report_block {
    d := _decide("dr_missing")
    d.changes_without_report == 2
    d._routing == "BLOCK_AND_ALERT"
}

# ── I10: naruszenie konwencji nazewniczych = BLOCK ────────────────────────────
test_p36_i10_violation_block {
    d := _decide("nc_violations")
    d.naming_violations == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I11: mapowania wkodowane = BLOCK; migracja bez definicji = BLOCK ──────────
test_p36_i11_hardcoded_block {
    d := _decide("md_hardcoded")
    d.mappings_hardcoded == true
    d._routing == "BLOCK_AND_ALERT"
}

test_p36_i11_undefined_block {
    d := _decide("md_undefined")
    d.migrations_without_definition == 2
    d._routing == "BLOCK_AND_ALERT"
}

# ── I12: suma orphanów > 0 = BLOCK; orphans_max jako dane ─────────────────────
test_p36_i12_orphans_block {
    d := _decide("zo_orphans")
    d.rules_without_test == 1
    d.orphans_max == 0
    d._routing == "BLOCK_AND_ALERT"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p36_certificate_fields {
    d := _decide("tt_ok")
    d.matched == true
    d["package"] == "jdg.v3_p36_generatory_migratory"
    d.priority == 436001
    d.threshold_version == "generatory-v3p36-2026.09"
    d.legal_basis_version == "generatory-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match ──────────────────────────────────────────────────
test_p36_no_match_without_flag {
    d := v3_p36_generatory_migratory.decide with input as {"v3_p36": _cases["tt_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p36_generatory_migratory.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p36_fail_closed_no_snapshot {
    d := v3_p36_generatory_migratory.decide with input as object.union(_base, {"v3_p36": _cases["tt_ok"]}) with data.jdg.thresholds.v3_p36 as {}
    d.rule_id == "jdg.v3_p36_generatory_migratory.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) ─────────────────────────────────────────────
test_p36_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p36
    s.v3_p36_idempotency_required == true
    s.v3_p36_rule_without_test_max == 0
    s.v3_p36_generator_required_fields == ["_legal_basis", "rule_id", "valid_from", "test_id"]
    s.v3_p36_guard_rail_violations_max == 0
    s.v3_p36_replay_drift_max == 0
    s.v3_p36_mirror_divergence_max == 0
    s.v3_p36_boundary_rules_min_covered == 100
    s.v3_p36_orphans_max == 0
    s.v3_p36_threshold_version == "generatory-v3p36-2026.09"
    s.valid_from == "2026-01-01"
}

# ── Audytowalność: reason i legal_basis w każdej decyzji; priorytety unikalne ─
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p36_routing_reasons_present {
    count(_reason_violations) == 0
}

_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p36_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 436001
    d.priority != 436002
    d.priority != 436003
    d.priority != 436004
    d.priority != 436005
    d.priority != 436006
    d.priority != 436007
    d.priority != 436008
    d.priority != 436009
    d.priority != 436010
    d.priority != 436011
    d.priority != 436012
}

test_p36_unique_priorities {
    count(_priority_violations) == 0
}
