# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P37 OBSERWOWALNOŚĆ (jdg.v3_p37_obserwowalnosc)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (freshness SLA, spike ratio, latency 2×, golden drift 0, benchmark 10%).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p37_obserwowalnosc_enterprise.rego \
#       JDG/rules/v3_p37_obserwowalnosc_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p37

import future.keywords.in

import data.jdg.v3_p37_obserwowalnosc

_base := {"jdg_entrepreneur": {"v3_p37_check": true}}

_cases := {
    # I01: decision SLO contract
    "slo_invalid": {"analysis": "decision_slo",
                    "decision_slo": {"slos_without_threshold_or_action": 1,
                                     "slo_violations_open": 0, "slos_total": 6}},
    "slo_violations": {"analysis": "decision_slo",
                       "decision_slo": {"slos_without_threshold_or_action": 0,
                                        "slo_violations_open": 2, "slos_total": 6}},
    "slo_ok": {"analysis": "decision_slo",
               "decision_slo": {"slos_without_threshold_or_action": 0,
                                "slo_violations_open": 0, "slos_total": 6}},

    # I02: law freshness SLA
    "lf_unverified": {"analysis": "law_freshness_sla",
                      "law_freshness_sla": {"acts_unverified": 1, "acts_stale": 0}},
    "lf_stale": {"analysis": "law_freshness_sla",
                 "law_freshness_sla": {"acts_unverified": 0, "acts_stale": 3}},
    "lf_ok": {"analysis": "law_freshness_sla",
              "law_freshness_sla": {"acts_unverified": 0, "acts_stale": 0}},

    # I03: needs-advice radar
    "na_no_reason": {"analysis": "needs_advice_radar",
                     "needs_advice_radar": {"needs_advice_without_reason": 1,
                                            "spike_detected": false}},
    "na_spike": {"analysis": "needs_advice_radar",
                 "needs_advice_radar": {"needs_advice_without_reason": 0,
                                        "spike_detected": true}},
    "na_ok": {"analysis": "needs_advice_radar",
              "needs_advice_radar": {"needs_advice_without_reason": 0,
                                     "spike_detected": false}},

    # I04: latency budget
    "lb_over2x": {"analysis": "latency_budget",
                  "latency_budget": {"domains_over_budget": 1,
                                     "domains_over_2x_budget": 1}},
    "lb_over": {"analysis": "latency_budget",
                "latency_budget": {"domains_over_budget": 2,
                                   "domains_over_2x_budget": 0}},
    "lb_ok": {"analysis": "latency_budget",
              "latency_budget": {"domains_over_budget": 0,
                                 "domains_over_2x_budget": 0}},

    # I05: certificate telemetry
    "ct_missing": {"analysis": "certificate_telemetry",
                   "certificate_telemetry": {"decisions_without_certificate": 1,
                                             "certificates_incomplete": 0,
                                             "decisions_total": 100}},
    "ct_incomplete": {"analysis": "certificate_telemetry",
                      "certificate_telemetry": {"decisions_without_certificate": 0,
                                                "certificates_incomplete": 2,
                                                "decisions_total": 100}},
    "ct_ok": {"analysis": "certificate_telemetry",
              "certificate_telemetry": {"decisions_without_certificate": 0,
                                        "certificates_incomplete": 0,
                                        "decisions_total": 100}},

    # I06: error budget freeze
    "eb_deploy_freeze": {"analysis": "error_budget_freeze",
                         "error_budget_exhausted": true,
                         "error_budget_freeze": {"deploys_during_freeze": 1,
                                                 "budget_remaining_pct": 0}},
    "eb_exhausted": {"analysis": "error_budget_freeze",
                     "error_budget_exhausted": true,
                     "error_budget_freeze": {"deploys_during_freeze": 0,
                                             "budget_remaining_pct": 0}},
    "eb_ok": {"analysis": "error_budget_freeze",
              "error_budget_exhausted": false,
              "error_budget_freeze": {"deploys_during_freeze": 0,
                                      "budget_remaining_pct": 80}},

    # I07: anomaly detection
    "an_unaccounted": {"analysis": "anomaly_detection",
                       "anomaly_detection": {"false_alarms_no_seasonality": 0,
                                             "anomalies_unaccounted": 1,
                                             "anomalies_explained": 4}},
    "an_false": {"analysis": "anomaly_detection",
                 "anomaly_detection": {"false_alarms_no_seasonality": 2,
                                       "anomalies_unaccounted": 0,
                                       "anomalies_explained": 3}},
    "an_ok": {"analysis": "anomaly_detection",
              "anomaly_detection": {"false_alarms_no_seasonality": 0,
                                    "anomalies_unaccounted": 0,
                                    "anomalies_explained": 5}},

    # I08: golden drift watch
    "gd_drift": {"analysis": "golden_drift_watch",
                 "golden_drift_watch": {"drifted_decisions": 1,
                                        "checked_decisions": 500}},
    "gd_disabled": {"analysis": "golden_drift_watch",
                    "drift_watch_disabled": true,
                    "golden_drift_watch": {"drifted_decisions": 0,
                                           "checked_decisions": 0}},
    "gd_ok": {"analysis": "golden_drift_watch",
              "golden_drift_watch": {"drifted_decisions": 0,
                                     "checked_decisions": 500}},

    # I09: runbook-as-code
    "rb_missing": {"analysis": "runbook_as_code",
                   "runbook_as_code": {"alerts_without_runbook": 1,
                                       "runbooks_stale": 0, "alerts_total": 12}},
    "rb_stale": {"analysis": "runbook_as_code",
                 "runbook_as_code": {"alerts_without_runbook": 0,
                                     "runbooks_stale": 2, "alerts_total": 12}},
    "rb_ok": {"analysis": "runbook_as_code",
              "runbook_as_code": {"alerts_without_runbook": 0,
                                  "runbooks_stale": 0, "alerts_total": 12}},

    # I10: status page
    "sp_missing": {"analysis": "status_page",
                   "status_page": {"missing_sections": 1, "stale_days": 0}},
    "sp_stale": {"analysis": "status_page",
                 "status_page": {"missing_sections": 0, "stale_days": 3}},
    "sp_ok": {"analysis": "status_page",
              "status_page": {"missing_sections": 0, "stale_days": 0}},

    # I11: decision cost
    "dc_missing_ai": {"analysis": "decision_cost",
                      "decision_cost": {"ai_decisions_without_cost": 1,
                                        "decisions_over_cost_limit": 0}},
    "dc_over": {"analysis": "decision_cost",
                "decision_cost": {"ai_decisions_without_cost": 0,
                                  "decisions_over_cost_limit": 2}},
    "dc_ok": {"analysis": "decision_cost",
              "decision_cost": {"ai_decisions_without_cost": 0,
                                "decisions_over_cost_limit": 0}},

    # I12: benchmark regression
    "bg_regression": {"analysis": "benchmark_regression",
                      "benchmark_regression": {"regression_pct": 15}},
    "bg_no_baseline": {"analysis": "benchmark_regression",
                       "benchmark_baseline_missing": true,
                       "benchmark_regression": {"regression_pct": 0}},
    "bg_ok": {"analysis": "benchmark_regression",
              "benchmark_regression": {"regression_pct": 2}},
}

_decide(case) = d {
    d := v3_p37_obserwowalnosc.decide with input as object.union(_base, {"v3_p37": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "slo_invalid": "BLOCK_AND_ALERT", "slo_violations": "TRIAGE_QUEUE", "slo_ok": "SUGGEST",
    "lf_unverified": "BLOCK_AND_ALERT", "lf_stale": "TRIAGE_QUEUE", "lf_ok": "SUGGEST",
    "na_no_reason": "BLOCK_AND_ALERT", "na_spike": "TRIAGE_QUEUE", "na_ok": "SUGGEST",
    "lb_over2x": "BLOCK_AND_ALERT", "lb_over": "TRIAGE_QUEUE", "lb_ok": "SUGGEST",
    "ct_missing": "BLOCK_AND_ALERT", "ct_incomplete": "TRIAGE_QUEUE", "ct_ok": "SUGGEST",
    "eb_deploy_freeze": "BLOCK_AND_ALERT", "eb_exhausted": "TRIAGE_QUEUE", "eb_ok": "SUGGEST",
    "an_unaccounted": "BLOCK_AND_ALERT", "an_false": "TRIAGE_QUEUE", "an_ok": "SUGGEST",
    "gd_drift": "BLOCK_AND_ALERT", "gd_disabled": "BLOCK_AND_ALERT", "gd_ok": "SUGGEST",
    "rb_missing": "BLOCK_AND_ALERT", "rb_stale": "TRIAGE_QUEUE", "rb_ok": "SUGGEST",
    "sp_missing": "BLOCK_AND_ALERT", "sp_stale": "TRIAGE_QUEUE", "sp_ok": "SUGGEST",
    "dc_missing_ai": "BLOCK_AND_ALERT", "dc_over": "TRIAGE_QUEUE", "dc_ok": "SUGGEST",
    "bg_regression": "BLOCK_AND_ALERT", "bg_no_baseline": "BLOCK_AND_ALERT", "bg_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p37_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: SLO bez progu/akcji = BLOCK; naruszenia otwarte = TRIAGE ─────────────
test_p37_i01_invalid_slo_block {
    d := _decide("slo_invalid")
    d.slos_without_threshold_or_action == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i01_violations_triage {
    d := _decide("slo_violations")
    d._routing == "TRIAGE_QUEUE"
}

# ── I02: akt niezweryfikowany = BLOCK; stale > SLA 7 = TRIAGE ─────────────────
test_p37_i02_unverified_block {
    d := _decide("lf_unverified")
    d.acts_unverified == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i02_stale_boundary {
    d := _decide("lf_stale")
    d.acts_stale == 3
    d.freshness_sla_days == 7
    d._routing == "TRIAGE_QUEUE"
}

# ── I03: NEEDS_ADVICE bez powodu = BLOCK; skok = TRIAGE ───────────────────────
test_p37_i03_no_reason_block {
    d := _decide("na_no_reason")
    d.needs_advice_without_reason == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i03_spike_triage {
    d := _decide("na_spike")
    d.spike_ratio == 3
    d._routing == "TRIAGE_QUEUE"
}

# ── I04: p95 > 2× budżetu = BLOCK; > budżetu = TRIAGE ─────────────────────────
test_p37_i04_over2x_block {
    d := _decide("lb_over2x")
    d.domains_over_2x_budget == 1
    d.latency_p95_max_ms == 500
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i04_over_triage {
    d := _decide("lb_over")
    d.domains_over_budget == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I05: decyzja bez certyfikatu = BLOCK; niekompletny = TRIAGE ───────────────
test_p37_i05_missing_block {
    d := _decide("ct_missing")
    d.decisions_without_certificate == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i05_incomplete_triage {
    d := _decide("ct_incomplete")
    d._routing == "TRIAGE_QUEUE"
}

# ── I06: deploy w freeze = BLOCK; budżet wyczerpany = TRIAGE ──────────────────
test_p37_i06_deploy_during_freeze_block {
    d := _decide("eb_deploy_freeze")
    d.deploys_during_freeze == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i06_exhausted_triage {
    d := _decide("eb_exhausted")
    d.error_budget_exhausted == true
    d._routing == "TRIAGE_QUEUE"
}

# ── I07: anomalia nieuwzględniona = BLOCK; fałszywe alarmy = TRIAGE ───────────
test_p37_i07_unaccounted_block {
    d := _decide("an_unaccounted")
    d.anomalies_unaccounted == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i07_false_alarms_triage {
    d := _decide("an_false")
    d._routing == "TRIAGE_QUEUE"
}

# ── I08: rozjazd z golden > 0 = BLOCK; watch wyłączony = BLOCK ────────────────
test_p37_i08_drift_block {
    d := _decide("gd_drift")
    d.drifted_decisions == 1
    d.golden_drift_max == 0
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i08_disabled_block {
    d := _decide("gd_disabled")
    d.drift_watch_disabled == true
    d._routing == "BLOCK_AND_ALERT"
}

# ── I09: alarm bez runbooka = BLOCK; runbook nieświeży = TRIAGE ───────────────
test_p37_i09_missing_runbook_block {
    d := _decide("rb_missing")
    d.alerts_without_runbook == 1
    d.alerts_without_runbook_max == 0
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i09_stale_triage {
    d := _decide("rb_stale")
    d.runbooks_stale == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I10: status page bez sekcji = BLOCK; nieświeży = TRIAGE ───────────────────
test_p37_i10_missing_sections_block {
    d := _decide("sp_missing")
    d.missing_sections == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i10_stale_triage {
    d := _decide("sp_stale")
    d.stale_days == 3
    d.max_stale_days == 1
    d._routing == "TRIAGE_QUEUE"
}

# ── I11: decyzja AI bez kosztu = BLOCK; ponad limit = TRIAGE ──────────────────
test_p37_i11_missing_cost_block {
    d := _decide("dc_missing_ai")
    d.ai_decisions_without_cost == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i11_over_limit_triage {
    d := _decide("dc_over")
    d.decisions_over_cost_limit == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I12: regresja > 10% = BLOCK; brak baseline = BLOCK ────────────────────────
test_p37_i12_regression_block {
    d := _decide("bg_regression")
    d.regression_pct == 15
    d.regression_max_pct == 10
    d._routing == "BLOCK_AND_ALERT"
}

test_p37_i12_no_baseline_block {
    d := _decide("bg_no_baseline")
    d.benchmark_baseline_missing == true
    d._routing == "BLOCK_AND_ALERT"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p37_certificate_fields {
    d := _decide("slo_ok")
    d.matched == true
    d["package"] == "jdg.v3_p37_obserwowalnosc"
    d.priority == 437001
    d.threshold_version == "obserwowalnosc-v3p37-2026.09"
    d.legal_basis_version == "obserwowalnosc-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match ──────────────────────────────────────────────────
test_p37_no_match_without_flag {
    d := v3_p37_obserwowalnosc.decide with input as {"v3_p37": _cases["slo_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p37_obserwowalnosc.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p37_fail_closed_no_snapshot {
    d := v3_p37_obserwowalnosc.decide with input as object.union(_base, {"v3_p37": _cases["slo_ok"]}) with data.jdg.thresholds.v3_p37 as {}
    d.rule_id == "jdg.v3_p37_obserwowalnosc.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) ─────────────────────────────────────────────
test_p37_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p37
    s.v3_p37_law_freshness_sla_days == 7
    s.v3_p37_na_spike_ratio == 3
    s.v3_p37_latency_p95_max_ms == 500
    s.v3_p37_error_budget_min_pct == 0
    s.v3_p37_golden_drift_max == 0
    s.v3_p37_alert_without_runbook_max == 0
    s.v3_p37_status_page_max_stale_days == 1
    s.v3_p37_ai_cost_limit_per_decision == 1.0
    s.v3_p37_benchmark_regression_max_pct == 10
    s.v3_p37_threshold_version == "obserwowalnosc-v3p37-2026.09"
    s.valid_from == "2026-01-01"
}

# ── Audytowalność: reason i legal_basis w każdej decyzji; priorytety unikalne ─
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p37_routing_reasons_present {
    count(_reason_violations) == 0
}

_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p37_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 437001
    d.priority != 437002
    d.priority != 437003
    d.priority != 437004
    d.priority != 437005
    d.priority != 437006
    d.priority != 437007
    d.priority != 437008
    d.priority != 437009
    d.priority != 437010
    d.priority != 437011
    d.priority != 437012
}

test_p37_unique_priorities {
    count(_priority_violations) == 0
}
