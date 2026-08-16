# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R16 GLM52 SYSTEM OPA (P18–P35) — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r16_system_opa_innovations
# Raport: RAPORT_16_SYSTEM_OPA.txt (Kampania GLM 5.2 — seria 16/25)
#
# Prompt 16/25 (System OPA — automatyzacja, walidacja, audyt, cykl życia):
#   R16-INN-01 rule_lifecycle_monitor — monitor cyklu życia reguły (SHADOW→
#                                     CANDIDATE→ACTIVE→DEPRECATED→RETIRED→
#                                     PURGED) z auto-rollback (p21 registry
#                                     bez monitora przejść)
#   R16-INN-02 validation_quality_monitor — monitor jakości walidacji
#                                     (tautologie, dead-rules, hardcode) z
#                                     bramką zero-defect (p22 auditor bez
#                                     monitora)
#   R16-INN-03 test_shield_monitor — monitor tarczy testów CI (mutation ≥70%,
#                                     zero defect) (p23 test_shield bez
#                                     monitora)
#   R16-INN-04 reliability_determinism_monitor — monitor niezawodności
#                                     (provenance gate, determinizm, fallback
#                                     ladder) (reliability_guarantee bez
#                                     monitora)
#   R16-INN-05 isap_pipeline_monitor — monitor pipeline ISAP→produkcja
#                                     (≤24h, P0 ≤4h) z alertami (isap_rule_
#                                     update_pipeline bez monitora SLA)
#
# Zgodność: ADR-001..009/016..021/022; filary V2 (Legal Twin / invariants /
#           Decision Certificate / Law Radar / Declarative Change);
#           thresholds.system_opa (zero hardcode); INV-018; First-Match-Wins.
# package: jdg.r16_system_opa_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r16_system_opa_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r16_system_opa_innovations.no_match", "package": "jdg.r16_system_opa_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_so := object.get(_th, "system_opa", {})

canary_percent := object.get(_th_so, "canary_percent", 5)
rollback_error_threshold := object.get(_th_so, "rollback_error_threshold", 0.01)
rollback_quality_threshold := object.get(_th_so, "rollback_quality_threshold", 0.95)
mutation_score_min := object.get(_th_so, "mutation_score_min", 70)
zero_defect_gates := object.get(_th_so, "zero_defect_gates", 7)
coverage_min_pct := object.get(_th_so, "coverage_min_pct", 90)
stub_threshold := object.get(_th_so, "stub_threshold", 10)
hardcoded_threshold := object.get(_th_so, "hardcoded_threshold", 10)
isap_sla_hours := object.get(_th_so, "isap_sla_hours", 24)
isap_p0_hours := object.get(_th_so, "isap_p0_hours", 4)
hot_reload_minutes := object.get(_th_so, "hot_reload_minutes", 15)

# ── Helper: 3 poziomy alertów ─────────────────────────────────────────────────
alert_level(pct) := "RED" if {
    pct >= 100
} else := "AMBER" if {
    pct >= 75
} else := "GREEN" if {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R16-INN-01: RULE LIFECYCLE MONITOR — monitor cyklu życia reguły z
#             auto-rollback (SHADOW→CANDIDATE→ACTIVE→DEPRECATED→RETIRED→PURGED)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza rule_lifecycle: {phase, error_rate, rollout_pct}.
rl_input := object.get(input, "rule_lifecycle", {})
rl_phase := object.get(rl_input, "phase", "CANDIDATE")
rl_error_rate := object.get(rl_input, "error_rate", 0)
rl_rollout_pct := object.get(rl_input, "rollout_pct", 0)

rl_should_rollback := rl_error_rate > rollback_error_threshold
rl_blocked := rl_should_rollback

rl_routing := "BLOCK_AND_ALERT" if {
    rl_blocked
} else := "TRIAGE_QUEUE" if {
    rl_phase == "CANDIDATE"
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r16_system_opa_innovations.rule_lifecycle_monitor",
    "_legal_basis": "ADR-016..021 (cykl życia reguły, canary, auto-rollback), V2 F3 (golden replay)",
    "package": "jdg.r16_system_opa_innovations",
    "priority": 11041,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "rl_phase": rl_phase,
    "rl_error_rate": rl_error_rate,
    "rl_rollout_pct": rl_rollout_pct,
    "rl_should_rollback": rl_should_rollback,
    "rl_rollback_error_threshold": rollback_error_threshold,
    "rl_canary_percent": canary_percent,
    "_routing": rl_routing,
    "_routing_reason": sprintf("Cykl życia — faza %s, error_rate %.4f (próg %.4f), rollout %d%%. %s", [rl_phase, rl_error_rate, rollback_error_threshold, rl_rollout_pct, "AUTO-ROLLBACK — error_rate przekroczony." if {rl_should_rollback} else "Obserwacja kandydata." if {rl_phase == "CANDIDATE"} else "Stabilny."]),
    "_legal_basis": "ADR-016..021 (cykl życia reguły, canary, auto-rollback), V2 F3 (golden replay)",
    "_warnings": [sprintf("LIFECYCLE: faza %s — %s", [rl_phase, "AUTO-ROLLBACK (error przekroczony)." if {rl_should_rollback} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r16_system_opa_check", false) == true
    object.get(input, "rule_lifecycle", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R16-INN-02: VALIDATION QUALITY MONITOR — monitor jakości walidacji
#             (tautologie, dead-rules, hardcode) z bramką zero-defect
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza validation_quality: {tautology_count, dead_rules, hardcoded_count}.
vq_input := object.get(input, "validation_quality", {})
vq_tautology := max([0, object.get(vq_input, "tautology_count", 0)])
vq_dead := max([0, object.get(vq_input, "dead_rules", 0)])
vq_hardcoded := max([0, object.get(vq_input, "hardcoded_count", 0)])

vq_defects := vq_tautology + vq_dead + vq_hardcoded
vq_zero_defect := vq_defects == 0

vq_routing := "BLOCK_AND_ALERT" if {
    not vq_zero_defect
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r16_system_opa_innovations.validation_quality_monitor",
    "_legal_basis": "ADR-016..021 (cykl życia reguły, canary, auto-rollback), V2 F3 (golden replay)",
    "package": "jdg.r16_system_opa_innovations",
    "priority": 11042,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "vq_tautology_count": vq_tautology,
    "vq_dead_rules": vq_dead,
    "vq_hardcoded_count": vq_hardcoded,
    "vq_defects": vq_defects,
    "vq_zero_defect": vq_zero_defect,
    "vq_stub_threshold": stub_threshold,
    "vq_hardcoded_threshold": hardcoded_threshold,
    "_routing": vq_routing,
    "_routing_reason": sprintf("Jakość walidacji — tautologie %d, dead-rules %d, hardcode %d (łącznie %d). %s", [vq_tautology, vq_dead, vq_hardcoded, vq_defects, "DEFEKTY — napraw przed merge." if {not vq_zero_defect} else "Zero-defect."]),
    "_legal_basis": "ADR-006 (provenance), V2 §4 (golden replay), ADR-022 (invariants)",
    "_warnings": [sprintf("WALIDACJA: %s", ["defekty — napraw przed merge." if {not vq_zero_defect} else "zero-defect."])],
} if {
    object.get(input.jdg_entrepreneur, "r16_system_opa_check", false) == true
    object.get(input, "validation_quality", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R16-INN-03: TEST SHIELD MONITOR — monitor tarczy testów CI (mutation ≥70%,
#             zero defect)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza test_shield: {mutation_pct, defects, coverage_pct}.
ts_input := object.get(input, "test_shield", {})
ts_mutation := max([0, object.get(ts_input, "mutation_pct", 0)])
ts_defects := max([0, object.get(ts_input, "defects", 0)])
ts_coverage := max([0, object.get(ts_input, "coverage_pct", 0)])

ts_mutation_ok := ts_mutation >= mutation_score_min
ts_coverage_ok := ts_coverage >= coverage_min_pct
ts_shield_ok := ts_mutation_ok and ts_coverage_ok and ts_defects == 0

ts_routing := "BLOCK_AND_ALERT" if {
    not ts_shield_ok
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r16_system_opa_innovations.test_shield_monitor",
    "_legal_basis": "ADR-016..021 (cykl życia reguły, canary, auto-rollback), V2 F3 (golden replay)",
    "package": "jdg.r16_system_opa_innovations",
    "priority": 11043,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "ts_mutation_pct": ts_mutation,
    "ts_defects": ts_defects,
    "ts_coverage_pct": ts_coverage,
    "ts_mutation_ok": ts_mutation_ok,
    "ts_coverage_ok": ts_coverage_ok,
    "ts_shield_ok": ts_shield_ok,
    "ts_mutation_min": mutation_score_min,
    "ts_coverage_min": coverage_min_pct,
    "_routing": ts_routing,
    "_routing_reason": sprintf("Tarcza CI — mutacja %.0f%% (min %d%%), pokrycie %.0f%% (min %d%%), defekty %d. %s", [ts_mutation, mutation_score_min, ts_coverage, coverage_min_pct, ts_defects, "BLOKUJ merge — bramka CI nie spełniona." if {not ts_shield_ok} else "Bramka CI spełniona."]),
    "_legal_basis": "ADR-022 (invariants), V2 §4.1 (golden replay gate), ADR-006 (provenance)",
    "_warnings": [sprintf("CI: %s", ["bramka nie spełniona." if {not ts_shield_ok} else "bramka spełniona."])],
} if {
    object.get(input.jdg_entrepreneur, "r16_system_opa_check", false) == true
    object.get(input, "test_shield", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R16-INN-04: RELIABILITY DETERMINISM MONITOR — monitor niezawodności
#             (provenance gate, determinizm, fallback ladder)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza reliability: {deterministic, provenance_ok, fallback_ready}.
rb_input := object.get(input, "reliability", {})
rb_deterministic := object.get(rb_input, "deterministic", false)
rb_provenance := object.get(rb_input, "provenance_ok", false)
rb_fallback := object.get(rb_input, "fallback_ready", false)

rb_reliable := rb_deterministic and rb_provenance and rb_fallback

rb_routing := "BLOCK_AND_ALERT" if {
    not rb_reliable
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r16_system_opa_innovations.reliability_determinism_monitor",
    "_legal_basis": "ADR-016..021 (cykl życia reguły, canary, auto-rollback), V2 F3 (golden replay)",
    "package": "jdg.r16_system_opa_innovations",
    "priority": 11044,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "rb_deterministic": rb_deterministic,
    "rb_provenance_ok": rb_provenance,
    "rb_fallback_ready": rb_fallback,
    "rb_reliable": rb_reliable,
    "_routing": rb_routing,
    "_routing_reason": sprintf("Niezawodność — determinizm=%s, provenance=%s, fallback=%s. %s", [rb_deterministic, rb_provenance, rb_fallback, "BLOKUJ — brak gwarancji niezawodności." if {not rb_reliable} else "Niezawodny."]),
    "_legal_basis": "ADR-006 (provenance gate), V2 F3 (Decision Certificate), ADR-022 (runtime invariants)",
    "_warnings": [sprintf("RELIABILITY: %s", ["brak gwarancji (determinizm/provenance/fallback)." if {not rb_reliable} else "niezawodny."])],
} if {
    object.get(input.jdg_entrepreneur, "r16_system_opa_check", false) == true
    object.get(input, "reliability", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R16-INN-05: ISAP PIPELINE MONITOR — monitor pipeline ISAP→produkcja
#             (≤24h, P0 ≤4h) z alertami
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza isap_pipeline: {hours_elapsed, priority, deployed}.
ip_input := object.get(input, "isap_pipeline", {})
ip_hours := max([0, object.get(ip_input, "hours_elapsed", 0)])
ip_priority := object.get(ip_input, "priority", "STANDARD")
ip_deployed := object.get(ip_input, "deployed", false)

ip_sla := isap_p0_hours if {
    ip_priority == "P0"
} else := isap_sla_hours if {
    true
}

ip_sla_breach := not ip_deployed and ip_hours > ip_sla

ip_routing := "BLOCK_AND_ALERT" if {
    ip_sla_breach
} else := "TRIAGE_QUEUE" if {
    not ip_deployed
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r16_system_opa_innovations.isap_pipeline_monitor",
    "_legal_basis": "ADR-016..021 (cykl życia reguły, canary, auto-rollback), V2 F3 (golden replay)",
    "package": "jdg.r16_system_opa_innovations",
    "priority": 11045,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "ip_hours_elapsed": ip_hours,
    "ip_priority": ip_priority,
    "ip_deployed": ip_deployed,
    "ip_sla_hours": ip_sla,
    "ip_sla_breach": ip_sla_breach,
    "ip_hot_reload_minutes": hot_reload_minutes,
    "_routing": ip_routing,
    "_routing_reason": sprintf("Pipeline ISAP — %.1f h (SLA %d h, priorytet %s), wdrożony=%s. %s", [ip_hours, ip_sla, ip_priority, ip_deployed, "SLA_BREACH — adaptacja przekroczyła termin." if {ip_sla_breach} else "W toku." if {not ip_deployed} else "Wdrożone."]),
    "_legal_basis": "ADR-002 (Declarative Change), V2 F5 (Law Radar), ISAP pipeline (≤24h, P0 ≤4h)",
    "_warnings": [sprintf("ISAP: %s", ["SLA breach." if {ip_sla_breach} else "w toku." if {not ip_deployed} else "wdrożone."])],
} if {
    object.get(input.jdg_entrepreneur, "r16_system_opa_check", false) == true
    object.get(input, "isap_pipeline", {}) != {}
}
