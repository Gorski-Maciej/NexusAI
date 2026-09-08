# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P35 AUDYTORY DOMENOWE (jdg.v3_p35_audyutory_domenowe)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (trust floor/drop, golden replay age, feedback age, SLA, law freshness).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p35_audyutory_domenowe_enterprise.rego \
#       JDG/rules/v3_p35_audyutory_domenowe_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p35

import future.keywords.in

import data.jdg.v3_p35_audyutory_domenowe

_base := {"jdg_entrepreneur": {"v3_p35_check": true}}

_cases := {
    # I01: domain trust score
    "ts_big_drop": {"analysis": "domain_trust_score",
                    "domain_trust_score": {"domains_below_floor": [],
                                           "domains_with_big_drop": ["vat"]}},
    "ts_below_floor": {"analysis": "domain_trust_score",
                       "domain_trust_score": {"domains_below_floor": ["pit"],
                                              "domains_with_big_drop": []}},
    "ts_ok": {"analysis": "domain_trust_score",
              "domain_trust_score": {"domains_below_floor": [],
                                     "domains_with_big_drop": []}},

    # I02: auditor as data
    "ad_no_controls": {"analysis": "auditor_as_data",
                       "auditor_as_data": {"domains_without_definition": 0,
                                           "definitions_missing_controls": ["vat"]}},
    "ad_undefined": {"analysis": "auditor_as_data",
                     "auditor_as_data": {"domains_without_definition": 2,
                                         "definitions_missing_controls": []}},
    "ad_ok": {"analysis": "auditor_as_data",
              "auditor_as_data": {"domains_without_definition": 0,
                                  "definitions_missing_controls": []}},

    # I03: golden case registry
    "gr_forged": {"analysis": "golden_case_registry",
                  "golden_cases_forged": true,
                  "golden_case_registry": {"domains_without_cases": 0,
                                           "cases_not_replayed_days": 0}},
    "gr_undefined": {"analysis": "golden_case_registry",
                     "golden_case_registry": {"domains_without_cases": 1,
                                              "cases_not_replayed_days": 0}},
    "gr_stale": {"analysis": "golden_case_registry",
                 "golden_case_registry": {"domains_without_cases": 0,
                                          "cases_not_replayed_days": 45}},
    "gr_ok": {"analysis": "golden_case_registry",
              "golden_case_registry": {"domains_without_cases": 0,
                                       "cases_not_replayed_days": 5}},

    # I04: unified audit report
    "ur_off_schema": {"analysis": "unified_audit_report",
                      "unified_audit_report": {"reports_off_schema": 2}},
    "ur_ok": {"analysis": "unified_audit_report",
              "unified_audit_report": {"reports_off_schema": 0}},

    # I05: drill-down do dowodu
    "dd_broken": {"analysis": "drill_down_evidence",
                  "drill_down_evidence": {"metrics_without_full_trace": 1, "metrics_total": 10}},
    "dd_ok": {"analysis": "drill_down_evidence",
              "drill_down_evidence": {"metrics_without_full_trace": 0, "metrics_total": 10}},

    # I06: skew detection
    "sk_critical": {"analysis": "skew_detection",
                    "skew_detection": {"critical_skews": 1, "mild_skews": 0}},
    "sk_mild": {"analysis": "skew_detection",
                "skew_detection": {"critical_skews": 0, "mild_skews": 2}},
    "sk_ok": {"analysis": "skew_detection",
              "skew_detection": {"critical_skews": 0, "mild_skews": 0}},

    # I07: dashboardy jako dane
    "ds_hardcoded": {"analysis": "dashboards_as_data",
                     "dashboards_as_data": {"domains_without_dashboard": 0,
                                            "hardcoded_views": 1}},
    "ds_undefined": {"analysis": "dashboards_as_data",
                     "dashboards_as_data": {"domains_without_dashboard": 1,
                                            "hardcoded_views": 0}},
    "ds_ok": {"analysis": "dashboards_as_data",
              "dashboards_as_data": {"domains_without_dashboard": 0,
                                     "hardcoded_views": 0}},

    # I08: audyt ciągły vs per-PR
    "cu_pr_skipped": {"analysis": "continuous_vs_per_pr",
                      "continuous_vs_per_pr": {"nightly_missed_days": 0, "per_pr_skipped": 1}},
    "cu_night_missed": {"analysis": "continuous_vs_per_pr",
                        "continuous_vs_per_pr": {"nightly_missed_days": 3, "per_pr_skipped": 0}},
    "cu_ok": {"analysis": "continuous_vs_per_pr",
              "continuous_vs_per_pr": {"nightly_missed_days": 0, "per_pr_skipped": 0}},

    # I09: ocena operatora
    "of_stalled": {"analysis": "operator_feedback",
                   "operator_feedback": {"decisions_without_operator_review": 0,
                                         "reviews_missing_days": 20}},
    "of_unevaluated": {"analysis": "operator_feedback",
                       "operator_feedback": {"decisions_without_operator_review": 3,
                                             "reviews_missing_days": 2}},
    "of_ok": {"analysis": "operator_feedback",
              "operator_feedback": {"decisions_without_operator_review": 0,
                                    "reviews_missing_days": 0}},

    # I10: alert routing
    "ar_unrouted": {"analysis": "alert_routing",
                    "alert_routing": {"alerts_without_owner": 1, "sla_breached_alerts": 0}},
    "ar_sla_breach": {"analysis": "alert_routing",
                      "alert_routing": {"alerts_without_owner": 0, "sla_breached_alerts": 2}},
    "ar_ok": {"analysis": "alert_routing",
              "alert_routing": {"alerts_without_owner": 0, "sla_breached_alerts": 0}},

    # I11: legal freshness stamp
    "fs_stale": {"analysis": "legal_freshness_stamp",
                 "legal_freshness_stamp": {"domains_with_stale_law": 2}},
    "fs_ok": {"analysis": "legal_freshness_stamp",
              "legal_freshness_stamp": {"domains_with_stale_law": 0}},

    # I12: audyt inverse
    "iv_leak": {"analysis": "inverse_audit",
                "inverse_audit": {"domains_without_inverse_cases": 0,
                                  "unsafe_auto_post_leaks": 1}},
    "iv_missing": {"analysis": "inverse_audit",
                   "inverse_audit": {"domains_without_inverse_cases": 1,
                                     "unsafe_auto_post_leaks": 0}},
    "iv_ok": {"analysis": "inverse_audit",
              "inverse_audit": {"domains_without_inverse_cases": 0,
                                "unsafe_auto_post_leaks": 0}},
}

_decide(case) = d {
    d := v3_p35_audyutory_domenowe.decide with input as object.union(_base, {"v3_p35": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "ts_big_drop": "BLOCK_AND_ALERT", "ts_below_floor": "TRIAGE_QUEUE", "ts_ok": "SUGGEST",
    "ad_no_controls": "BLOCK_AND_ALERT", "ad_undefined": "TRIAGE_QUEUE", "ad_ok": "SUGGEST",
    "gr_forged": "BLOCK_AND_ALERT", "gr_undefined": "TRIAGE_QUEUE",
    "gr_stale": "TRIAGE_QUEUE", "gr_ok": "SUGGEST",
    "ur_off_schema": "BLOCK_AND_ALERT", "ur_ok": "SUGGEST",
    "dd_broken": "BLOCK_AND_ALERT", "dd_ok": "SUGGEST",
    "sk_critical": "BLOCK_AND_ALERT", "sk_mild": "TRIAGE_QUEUE", "sk_ok": "SUGGEST",
    "ds_hardcoded": "BLOCK_AND_ALERT", "ds_undefined": "TRIAGE_QUEUE", "ds_ok": "SUGGEST",
    "cu_pr_skipped": "BLOCK_AND_ALERT", "cu_night_missed": "TRIAGE_QUEUE", "cu_ok": "SUGGEST",
    "of_stalled": "BLOCK_AND_ALERT", "of_unevaluated": "TRIAGE_QUEUE", "of_ok": "SUGGEST",
    "ar_unrouted": "BLOCK_AND_ALERT", "ar_sla_breach": "TRIAGE_QUEUE", "ar_ok": "SUGGEST",
    "fs_stale": "BLOCK_AND_ALERT", "fs_ok": "SUGGEST",
    "iv_leak": "BLOCK_AND_ALERT", "iv_missing": "TRIAGE_QUEUE", "iv_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p35_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: trust score — duży spadek = BLOCK; podłoga = TRIAGE (telemetria) ─────
test_p35_i01_big_drop_block {
    d := _decide("ts_big_drop")
    d.rule_id == "jdg.v3_p35_audyutory_domenowe.domain_trust_score"
    d.domains_with_big_drop == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p35_i01_below_floor_triage {
    d := _decide("ts_below_floor")
    d.trust_score_floor == 70
    d._routing == "TRIAGE_QUEUE"
}

# ── I02: definicje bez kontroli ponad limit = BLOCK (audyt bez kontroli = fasada)
test_p35_i02_no_controls_block {
    d := _decide("ad_no_controls")
    d.definitions_missing_controls == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I03: sfabrykowane golden cases = BLOCK; granica wieku replay 30 dni ───────
test_p35_i03_forged_block {
    d := _decide("gr_forged")
    d._routing == "BLOCK_AND_ALERT"
}

test_p35_i03_stale_boundary {
    d := _decide("gr_stale")
    d.cases_not_replayed_days == 45
    d._routing == "TRIAGE_QUEUE"
}

# ── I04: raport spoza unified schema = BLOCK ──────────────────────────────────
test_p35_i04_off_schema_block {
    d := _decide("ur_off_schema")
    d.reports_off_schema == 2
    d._routing == "BLOCK_AND_ALERT"
}

# ── I05: metryka bez pełnego śladu = BLOCK ────────────────────────────────────
test_p35_i05_broken_trace_block {
    d := _decide("dd_broken")
    d.metrics_without_full_trace == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: skew — krytyczny = BLOCK, łagodny = TRIAGE ───────────────────────────
test_p35_i06_critical_block {
    d := _decide("sk_critical")
    d._routing == "BLOCK_AND_ALERT"
}

test_p35_i06_mild_triage {
    d := _decide("sk_mild")
    d._routing == "TRIAGE_QUEUE"
}

# ── I07: hardcode widoków = BLOCK (ADR-002) ───────────────────────────────────
test_p35_i07_hardcoded_block {
    d := _decide("ds_hardcoded")
    d.hardcoded_views == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I08: PR pominięty = BLOCK; nocny ponad limit = TRIAGE ─────────────────────
test_p35_i08_pr_skipped_block {
    d := _decide("cu_pr_skipped")
    d.per_pr_skipped == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p35_i08_nightly_boundary {
    d := _decide("cu_night_missed")
    d.nightly_missed_days == 3
    d.nightly_missed_max == 1
    d._routing == "TRIAGE_QUEUE"
}

# ── I09: feedback wstrzymany > 14 dni = BLOCK ─────────────────────────────────
test_p35_i09_stalled_block {
    d := _decide("of_stalled")
    d.reviews_missing_days == 20
    d.feedback_max_age_days == 14
    d._routing == "BLOCK_AND_ALERT"
}

# ── I10: alarm bez właściciela = BLOCK; SLA naruszone = TRIAGE ────────────────
test_p35_i10_unrouted_block {
    d := _decide("ar_unrouted")
    d.alerts_without_owner == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p35_i10_sla_breach_triage {
    d := _decide("ar_sla_breach")
    d.sla_hours == 4
    d._routing == "TRIAGE_QUEUE"
}

# ── I11: nieświeży dowód prawa = BLOCK ────────────────────────────────────────
test_p35_i11_stale_law_block {
    d := _decide("fs_stale")
    d.domains_with_stale_law == 2
    d.freshness_max_days == 7
    d._routing == "BLOCK_AND_ALERT"
}

# ── I12: wyciek AUTO_POST w negatywnej przestrzeni = BLOCK ────────────────────
test_p35_i12_leak_block {
    d := _decide("iv_leak")
    d.unsafe_auto_post_leaks == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p35_i12_missing_triage {
    d := _decide("iv_missing")
    d._routing == "TRIAGE_QUEUE"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p35_certificate_fields {
    d := _decide("ts_ok")
    d.matched == true
    d["package"] == "jdg.v3_p35_audyutory_domenowe"
    d.priority == 435001
    d.threshold_version == "audytory-v3p35-2026.09"
    d.legal_basis_version == "audytory-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match ──────────────────────────────────────────────────
test_p35_no_match_without_flag {
    d := v3_p35_audyutory_domenowe.decide with input as {"v3_p35": _cases["ts_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p35_audyutory_domenowe.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p35_fail_closed_no_snapshot {
    d := v3_p35_audyutory_domenowe.decide with input as object.union(_base, {"v3_p35": _cases["ts_ok"]}) with data.jdg.thresholds.v3_p35 as {}
    d.rule_id == "jdg.v3_p35_audyutory_domenowe.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) ─────────────────────────────────────────────
test_p35_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p35
    s.v3_p35_trust_score_floor == 70
    s.v3_p35_trust_drop_triage == 10
    s.v3_p35_missing_controls_max == 0
    s.v3_p35_golden_cases_min_per_domain == 3
    s.v3_p35_golden_replay_max_age_days == 30
    s.v3_p35_nightly_missed_max_days == 1
    s.v3_p35_feedback_max_age_days == 14
    s.v3_p35_alert_sla_hours == 4
    s.v3_p35_law_freshness_max_days == 7
    s.v3_p35_inverse_cases_min == 3
    s.v3_p35_threshold_version == "audytory-v3p35-2026.09"
    s.valid_from == "2026-01-01"
}

# ── Audytowalność: reason i legal_basis w każdej decyzji; priorytety unikalne ─
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p35_routing_reasons_present {
    count(_reason_violations) == 0
}

_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p35_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 435001
    d.priority != 435002
    d.priority != 435003
    d.priority != 435004
    d.priority != 435005
    d.priority != 435006
    d.priority != 435007
    d.priority != 435008
    d.priority != 435009
    d.priority != 435010
    d.priority != 435011
    d.priority != 435012
}

test_p35_unique_priorities {
    count(_priority_violations) == 0
}
