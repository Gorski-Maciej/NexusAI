# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P38 BUNDLE DEPLOY (jdg.v3_p38_bundle_deploy)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (canary diff 0 / próbka 100, MTTR 5 min, WORM 0, shadow 24h, changelog 7 dni).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p38_bundle_deploy_enterprise.rego \
#       JDG/rules/v3_p38_bundle_deploy_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p38

import future.keywords.in

import data.jdg.v3_p38_bundle_deploy

_base := {"jdg_entrepreneur": {"v3_p38_check": true}}

_cases := {
    # I01: deterministic build + attestation
    "db_no_attestation": {"analysis": "deterministic_build",
                          "deterministic_build": {"builds_without_attestation": 1,
                                                   "nondeterministic_builds": 0,
                                                   "builds_total": 10}},
    "db_nondeterministic": {"analysis": "deterministic_build",
                            "deterministic_build": {"builds_without_attestation": 0,
                                                     "nondeterministic_builds": 2,
                                                     "builds_total": 10}},
    "db_ok": {"analysis": "deterministic_build",
              "deterministic_build": {"builds_without_attestation": 0,
                                       "nondeterministic_builds": 0,
                                       "builds_total": 10}},

    # I02: canary z decision diff
    "cn_diff": {"analysis": "canary_decision_diff",
                "canary_decision_diff": {"decision_diffs": 1, "sample_size": 500}},
    "cn_small_sample": {"analysis": "canary_decision_diff",
                        "canary_decision_diff": {"decision_diffs": 0, "sample_size": 50}},
    "cn_ok": {"analysis": "canary_decision_diff",
              "canary_decision_diff": {"decision_diffs": 0, "sample_size": 500}},

    # I03: auto-rollback z powodem
    "ar_no_reason": {"analysis": "auto_rollback",
                     "auto_rollback": {"rollbacks_without_reason": 1,
                                        "rollback_mttr_min": 3}},
    "ar_slow": {"analysis": "auto_rollback",
                "auto_rollback": {"rollbacks_without_reason": 0,
                                   "rollback_mttr_min": 9}},
    "ar_ok": {"analysis": "auto_rollback",
              "auto_rollback": {"rollbacks_without_reason": 0,
                                 "rollback_mttr_min": 4}},

    # I04: blue-green
    "bg_closed_early": {"analysis": "blue_green",
                        "blue_green": {"old_version_closed_before_month_end": 1}},
    "bg_unavailable": {"analysis": "blue_green",
                       "blue_green_unavailable": true,
                       "blue_green": {"old_version_closed_before_month_end": 0}},
    "bg_ok": {"analysis": "blue_green",
              "blue_green": {"old_version_closed_before_month_end": 0}},

    # I05: WORM archive
    "wa_missing": {"analysis": "worm_archive",
                   "worm_archive": {"versions_without_worm": 2, "versions_total": 10}},
    "wa_ok": {"analysis": "worm_archive",
              "worm_archive": {"versions_without_worm": 0, "versions_total": 10}},

    # I06: deployment window
    "dw_blocked": {"analysis": "deployment_window",
                   "deployment_window": {"deploys_in_blocked_window": 1,
                                          "windows_total": 12}},
    "dw_no_calendar": {"analysis": "deployment_window",
                       "window_calendar_unlinked": true,
                       "deployment_window": {"deploys_in_blocked_window": 0,
                                              "windows_total": 0}},
    "dw_ok": {"analysis": "deployment_window",
              "deployment_window": {"deploys_in_blocked_window": 0,
                                     "windows_total": 12}},

    # I07: signature verification
    "sv_unsigned": {"analysis": "signature_verification",
                    "signature_verification": {"unsigned_bundles_loaded": 1,
                                                "bundles_verified": 9}},
    "sv_disabled": {"analysis": "signature_verification",
                    "signature_verification_disabled": true,
                    "signature_verification": {"unsigned_bundles_loaded": 0,
                                                "bundles_verified": 0}},
    "sv_ok": {"analysis": "signature_verification",
              "signature_verification": {"unsigned_bundles_loaded": 0,
                                          "bundles_verified": 9}},

    # I08: overlay versioning
    "ov_collision": {"analysis": "overlay_versioning",
                     "overlay_versioning": {"base_collisions": 1,
                                             "overlays_expired": 0,
                                             "overlays_total": 3}},
    "ov_expired": {"analysis": "overlay_versioning",
                   "overlay_versioning": {"base_collisions": 0,
                                           "overlays_expired": 2,
                                           "overlays_total": 3}},
    "ov_ok": {"analysis": "overlay_versioning",
              "overlay_versioning": {"base_collisions": 0,
                                      "overlays_expired": 0,
                                      "overlays_total": 3}},

    # I09: post-deploy certification
    "pc_missing": {"analysis": "post_deploy_certification",
                   "post_deploy_certification": {"deploys_without_certificate": 1,
                                                  "post_deploy_golden_failures": 0,
                                                  "deploys_total": 5}},
    "pc_golden_fail": {"analysis": "post_deploy_certification",
                       "post_deploy_certification": {"deploys_without_certificate": 0,
                                                      "post_deploy_golden_failures": 1,
                                                      "deploys_total": 5}},
    "pc_ok": {"analysis": "post_deploy_certification",
              "post_deploy_certification": {"deploys_without_certificate": 0,
                                             "post_deploy_golden_failures": 0,
                                             "deploys_total": 5}},

    # I10: infrastructure as legal record
    "lr_unsigned": {"analysis": "legal_record",
                    "legal_record": {"records_without_signature": 1,
                                      "records_incomplete": 0,
                                      "records_total": 24}},
    "lr_incomplete": {"analysis": "legal_record",
                      "legal_record": {"records_without_signature": 0,
                                        "records_incomplete": 3,
                                        "records_total": 24}},
    "lr_ok": {"analysis": "legal_record",
              "legal_record": {"records_without_signature": 0,
                                "records_incomplete": 0,
                                "records_total": 24}},

    # I11: shadow traffic
    "st_regression": {"analysis": "shadow_traffic",
                      "shadow_traffic": {"shadow_hours": 30, "shadow_regressions": 1}},
    "st_short": {"analysis": "shadow_traffic",
                 "shadow_traffic": {"shadow_hours": 10, "shadow_regressions": 0}},
    "st_ok": {"analysis": "shadow_traffic",
              "shadow_traffic": {"shadow_hours": 30, "shadow_regressions": 0}},

    # I12: release notes
    "rn_missing": {"analysis": "release_notes",
                   "release_notes": {"deploys_without_changelog": 1,
                                      "changelog_max_age_days": 2}},
    "rn_stale": {"analysis": "release_notes",
                 "release_notes": {"deploys_without_changelog": 0,
                                    "changelog_max_age_days": 9}},
    "rn_ok": {"analysis": "release_notes",
              "release_notes": {"deploys_without_changelog": 0,
                                 "changelog_max_age_days": 2}},
}

_decide(case) = d {
    d := v3_p38_bundle_deploy.decide with input as object.union(_base, {"v3_p38": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "db_no_attestation": "BLOCK_AND_ALERT", "db_nondeterministic": "BLOCK_AND_ALERT", "db_ok": "SUGGEST",
    "cn_diff": "BLOCK_AND_ALERT", "cn_small_sample": "TRIAGE_QUEUE", "cn_ok": "SUGGEST",
    "ar_no_reason": "BLOCK_AND_ALERT", "ar_slow": "TRIAGE_QUEUE", "ar_ok": "SUGGEST",
    "bg_closed_early": "BLOCK_AND_ALERT", "bg_unavailable": "TRIAGE_QUEUE", "bg_ok": "SUGGEST",
    "wa_missing": "BLOCK_AND_ALERT", "wa_ok": "SUGGEST",
    "dw_blocked": "BLOCK_AND_ALERT", "dw_no_calendar": "TRIAGE_QUEUE", "dw_ok": "SUGGEST",
    "sv_unsigned": "BLOCK_AND_ALERT", "sv_disabled": "BLOCK_AND_ALERT", "sv_ok": "SUGGEST",
    "ov_collision": "BLOCK_AND_ALERT", "ov_expired": "TRIAGE_QUEUE", "ov_ok": "SUGGEST",
    "pc_missing": "BLOCK_AND_ALERT", "pc_golden_fail": "BLOCK_AND_ALERT", "pc_ok": "SUGGEST",
    "lr_unsigned": "BLOCK_AND_ALERT", "lr_incomplete": "TRIAGE_QUEUE", "lr_ok": "SUGGEST",
    "st_regression": "BLOCK_AND_ALERT", "st_short": "TRIAGE_QUEUE", "st_ok": "SUGGEST",
    "rn_missing": "BLOCK_AND_ALERT", "rn_stale": "TRIAGE_QUEUE", "rn_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p38_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: build bez attestation = BLOCK; niedeterministyczny = BLOCK ───────────
test_p38_i01_no_attestation_block {
    d := _decide("db_no_attestation")
    d.builds_without_attestation == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i01_nondeterministic_block {
    d := _decide("db_nondeterministic")
    d.nondeterministic_builds == 2
    d._routing == "BLOCK_AND_ALERT"
}

# ── I02: rozjazd canary > 0 = BLOCK; próbka < 100 = TRIAGE ────────────────────
test_p38_i02_diff_block {
    d := _decide("cn_diff")
    d.decision_diffs == 1
    d.canary_diff_max == 0
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i02_small_sample_triage {
    d := _decide("cn_small_sample")
    d.sample_size == 50
    d.canary_sample_min == 100
    d._routing == "TRIAGE_QUEUE"
}

# ── I03: rollback bez powodu = BLOCK; MTTR > SLA = TRIAGE ─────────────────────
test_p38_i03_no_reason_block {
    d := _decide("ar_no_reason")
    d.rollbacks_without_reason == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i03_slow_mttr_triage {
    d := _decide("ar_slow")
    d.rollback_mttr_min == 9
    d.rollback_mttr_max_min == 5
    d._routing == "TRIAGE_QUEUE"
}

# ── I04: stara wersja zamknięta przed close month = BLOCK ─────────────────────
test_p38_i04_closed_early_block {
    d := _decide("bg_closed_early")
    d.old_version_closed_before_month_end == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i04_unavailable_triage {
    d := _decide("bg_unavailable")
    d.blue_green_unavailable == true
    d._routing == "TRIAGE_QUEUE"
}

# ── I05: wersja bez WORM > 0 = BLOCK ──────────────────────────────────────────
test_p38_i05_missing_worm_block {
    d := _decide("wa_missing")
    d.versions_without_worm == 2
    d.worm_missing_max == 0
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: deploy w zablokowanym oknie = BLOCK; brak kalendarza = TRIAGE ────────
test_p38_i06_blocked_window_block {
    d := _decide("dw_blocked")
    d.deploys_in_blocked_window == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i06_no_calendar_triage {
    d := _decide("dw_no_calendar")
    d.window_calendar_unlinked == true
    d._routing == "TRIAGE_QUEUE"
}

# ── I07: unsigned load = BLOCK; weryfikacja wyłączona = BLOCK ─────────────────
test_p38_i07_unsigned_block {
    d := _decide("sv_unsigned")
    d.unsigned_bundles_loaded == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i07_disabled_block {
    d := _decide("sv_disabled")
    d.signature_verification_disabled == true
    d._routing == "BLOCK_AND_ALERT"
}

# ── I08: kolizja overlay = BLOCK; wygasły = TRIAGE ────────────────────────────
test_p38_i08_collision_block {
    d := _decide("ov_collision")
    d.base_collisions == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i08_expired_triage {
    d := _decide("ov_expired")
    d.overlays_expired == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I09: deploy bez certyfikatu = BLOCK; golden fail po deploy = BLOCK ────────
test_p38_i09_missing_cert_block {
    d := _decide("pc_missing")
    d.deploys_without_certificate == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i09_golden_fail_block {
    d := _decide("pc_golden_fail")
    d.post_deploy_golden_failures == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I10: wpis bez podpisu = BLOCK; niekompletny = TRIAGE ──────────────────────
test_p38_i10_unsigned_record_block {
    d := _decide("lr_unsigned")
    d.records_without_signature == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i10_incomplete_triage {
    d := _decide("lr_incomplete")
    d.records_incomplete == 3
    d._routing == "TRIAGE_QUEUE"
}

# ── I11: regresja w shadow = BLOCK; shadow < 24h = TRIAGE ─────────────────────
test_p38_i11_regression_block {
    d := _decide("st_regression")
    d.shadow_regressions == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i11_short_triage {
    d := _decide("st_short")
    d.shadow_hours == 10
    d.shadow_hours_min == 24
    d._routing == "TRIAGE_QUEUE"
}

# ── I12: deploy bez changelogu = BLOCK; nieświeży > 7 dni = TRIAGE ────────────
test_p38_i12_missing_changelog_block {
    d := _decide("rn_missing")
    d.deploys_without_changelog == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p38_i12_stale_triage {
    d := _decide("rn_stale")
    d.changelog_max_age_days == 9
    d.changelog_age_limit == 7
    d._routing == "TRIAGE_QUEUE"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p38_certificate_fields {
    d := _decide("db_ok")
    d.matched == true
    d["package"] == "jdg.v3_p38_bundle_deploy"
    d.priority == 438001
    d.threshold_version == "bundle-deploy-v3p38-2026.09"
    d.legal_basis_version == "bundle-deploy-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match ──────────────────────────────────────────────────
test_p38_no_match_without_flag {
    d := v3_p38_bundle_deploy.decide with input as {"v3_p38": _cases["db_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p38_bundle_deploy.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p38_fail_closed_no_snapshot {
    d := v3_p38_bundle_deploy.decide with input as object.union(_base, {"v3_p38": _cases["db_ok"]}) with data.jdg.thresholds.v3_p38 as {}
    d.rule_id == "jdg.v3_p38_bundle_deploy.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) ─────────────────────────────────────────────
test_p38_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p38
    s.v3_p38_canary_diff_max == 0
    s.v3_p38_canary_sample_min == 100
    s.v3_p38_rollback_mttr_max_min == 5
    s.v3_p38_worm_missing_max == 0
    s.v3_p38_shadow_hours_min == 24
    s.v3_p38_changelog_max_age_days == 7
    s.v3_p38_threshold_version == "bundle-deploy-v3p38-2026.09"
    s.valid_from == "2026-01-01"
}

# ── Audytowalność: reason i legal_basis w każdej decyzji; priorytety unikalne ─
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p38_routing_reasons_present {
    count(_reason_violations) == 0
}

_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p38_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 438001
    d.priority != 438002
    d.priority != 438003
    d.priority != 438004
    d.priority != 438005
    d.priority != 438006
    d.priority != 438007
    d.priority != 438008
    d.priority != 438009
    d.priority != 438010
    d.priority != 438011
    d.priority != 438012
}

test_p38_unique_priorities {
    count(_priority_violations) == 0
}
