# NexusAI JDG — ETAP 28 FINAL CERTIFICATION / MASTER REPORT
# Reconciliation wszystkich 27 etapów: kod, testy, manifesty, Legal Twin.
# Macierz: akt → legal node → rule → test → bundle → verdict → operator.
# Certyfikacja domenowa: CERTIFIED / CONDITIONAL / BLOCKED.
# Blokery produkcji, SLO/SLA, RTO/RPO, kontrola zmian, rollback, runbooki.
# Raport „co naprawdę działa" — zero marketingowych deklaracji, tylko dowód.

package jdg.final_certification_etap28

import future.keywords.if
import future.keywords.in

decision_mode := "SUGGEST"

default decide := {
    "matched": false,
    "rule_id": "jdg.final_certification_etap28.no_match",
    "package": "jdg.final_certification_etap28",
    "priority": 999993,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et28 := object.get(_thresholds, "final_certification_etap28", {})
registry_version := object.get(_et28, "registry_version", "final-certification-etap28-2026.08")
total_etapy := object.get(_et28, "total_etapy", 28)
min_wdrozone_etapy := object.get(_et28, "min_wdrozone_etapy", 28)

ctx := object.get(input, "final_certification_etap28", {})
activated := object.get(object.get(input, "jdg_entrepreneur", {}), "final_certification_etap28_check", false)
evaluation_date := object.get(ctx, "evaluation_date", "")
run_id := object.get(ctx, "run_id", "")
evidence_refs := object.get(ctx, "evidence_refs", [])

# ── RECONCILIATION: wszystkie 28 raportów vs dowód ─────────────────────────
reconciliation := object.get(ctx, "reconciliation", {})
reports_present := object.get(reconciliation, "reports_present", 0)
reports_wdrozone := object.get(reconciliation, "reports_wdrozone", 0)
reports_incomplete := object.get(reconciliation, "reports_incomplete", 0)
reports_unproven := object.get(reconciliation, "reports_unproven", 0)
artifacts_present := object.get(reconciliation, "artifacts_present", 0)
audit_states_present := object.get(reconciliation, "audit_states_present", 0)
reconciliation_ok := reports_present >= total_etapy and
    reports_wdrozone >= min_wdrozone_etapy and
    reports_unproven == 0 and
    artifacts_present >= 100 and
    audit_states_present >= 20

# ── MATRIX: act → legal node → rule → test → bundle → verdict → operator ───
matrix := object.get(ctx, "traceability_matrix", {})
domains_covered := object.get(matrix, "domains_covered", 0)
legal_nodes_traced := object.get(matrix, "legal_nodes_traced", 0)
rules_traced := object.get(matrix, "rules_traced", 0)
tests_traced := object.get(matrix, "tests_traced", 0)
bundles_per_domain := object.get(matrix, "bundles_per_domain", 0)
operators_defined := object.get(matrix, "operators_defined", 0)
matrix_complete := domains_covered >= 20 and
    legal_nodes_traced >= 100 and
    rules_traced >= 500 and
    tests_traced >= 100 and
    operators_defined >= 5

# ── DOMAIN CERTIFICATION per warstwa ────────────────────────────────────────
domain_certs := object.get(ctx, "domain_certifications", {})
cert_vat := object.get(domain_certs, "vat", "BLOCKED")
cert_pit := object.get(domain_certs, "pit", "BLOCKED")
cert_zus := object.get(domain_certs, "zus", "BLOCKED")
cert_accounting := object.get(domain_certs, "accounting", "BLOCKED")
cert_kks_ord := object.get(domain_certs, "kks_ord", "BLOCKED")
cert_crossborder := object.get(domain_certs, "crossborder", "BLOCKED")
cert_pcc_local := object.get(domain_certs, "pcc_local", "BLOCKED")
cert_ksef_jpk := object.get(domain_certs, "ksef_jpk", "BLOCKED")
cert_rodo_aml := object.get(domain_certs, "rodo_aml", "BLOCKED")
cert_hyper := object.get(domain_certs, "hyper_contexts", "BLOCKED")
cert_ai_neural := object.get(domain_certs, "ai_neural", "BLOCKED")
cert_orchestrator := object.get(domain_certs, "orchestrator", "BLOCKED")
cert_legal_twin := object.get(domain_certs, "legal_twin", "BLOCKED")
cert_control_plane := object.get(domain_certs, "control_plane", "BLOCKED")
cert_security := object.get(domain_certs, "security", "BLOCKED")
cert_dr := object.get(domain_certs, "disaster_recovery", "BLOCKED")
cert_tests_ci := object.get(domain_certs, "tests_ci", "BLOCKED")
cert_mirror := object.get(domain_certs, "mirror_sync", "BLOCKED")

domains_certified := count({x | some x; x := [
    cert_vat, cert_pit, cert_zus, cert_accounting, cert_kks_ord,
    cert_crossborder, cert_pcc_local, cert_ksef_jpk, cert_rodo_aml,
    cert_hyper, cert_ai_neural, cert_orchestrator, cert_legal_twin,
    cert_control_plane, cert_security, cert_dr, cert_tests_ci, cert_mirror
][_]; x == "CERTIFIED"})
domains_conditional := count({x | some x; x := [
    cert_vat, cert_pit, cert_zus, cert_accounting, cert_kks_ord,
    cert_crossborder, cert_pcc_local, cert_ksef_jpk, cert_rodo_aml,
    cert_hyper, cert_ai_neural, cert_orchestrator, cert_legal_twin,
    cert_control_plane, cert_security, cert_dr, cert_tests_ci, cert_mirror
][_]; x == "CONDITIONAL"})
domains_blocked := count({x | some x; x := [
    cert_vat, cert_pit, cert_zus, cert_accounting, cert_kks_ord,
    cert_crossborder, cert_pcc_local, cert_ksef_jpk, cert_rodo_aml,
    cert_hyper, cert_ai_neural, cert_orchestrator, cert_legal_twin,
    cert_control_plane, cert_security, cert_dr, cert_tests_ci, cert_mirror
][_]; x == "BLOCKED"})

# System is production-certified only if ALL domains are at least CONDITIONAL
# and NONE are BLOCKED.
system_certified := domains_blocked == 0 and domains_certified + domains_conditional >= 15

# ── PRODUCTION BLOCKERS: absolute must-fix items ────────────────────────────
blockers := object.get(ctx, "production_blockers", {})
blocker_legal_gap := object.get(blockers, "no_critical_legal_gap", false)
blocker_temporal := object.get(blockers, "temporal_chain_complete", false)
blocker_tests := object.get(blockers, "test_gates_passing", false)
blocker_runtime := object.get(blockers, "runtime_invariants_enforced", false)
blocker_api := object.get(blockers, "openapi_implemented", false)
blocker_security := object.get(blockers, "security_fortress_active", false)
blocker_traceability := object.get(blockers, "full_traceability_chain", false)
blockers_cleared := blocker_legal_gap and blocker_temporal and
    blocker_tests and blocker_runtime and blocker_api and
    blocker_security and blocker_traceability

# ── SLO/SLA ─────────────────────────────────────────────────────────────────
slo := object.get(ctx, "slo_sla", {})
slo_bundle_verify := object.get(slo, "bundle_verify_fail_closed", false)
slo_rollback_mttr_min := object.get(slo, "rollback_mttr_min", 999)
slo_hot_reload_min := object.get(slo, "hot_reload_min", 999)
slo_rpo_min := object.get(slo, "rpo_min", 999)
slo_rto_min := object.get(slo, "rto_min", 999)
slo_opa_check_gate := object.get(slo, "opa_check_gate_active", false)
slo_sla_complete := slo_bundle_verify and slo_rollback_mttr_min <= 5 and
    slo_hot_reload_min <= 15 and slo_rpo_min <= 15 and slo_rto_min <= 30 and
    slo_opa_check_gate

# ── CHANGE CONTROL + RUNBOOKS ───────────────────────────────────────────────
change_control := object.get(ctx, "change_control", {})
change_4_eyes := object.get(change_control, "four_eyes_sod", false)
change_canary := object.get(change_control, "canary_required", false)
change_shadow_delta := object.get(change_control, "shadow_delta_threshold", false)
change_rollback_tested := object.get(change_control, "rollback_tested", false)
runbooks_present := object.get(change_control, "runbooks_present", false)
change_control_complete := change_4_eyes and change_canary and
    change_shadow_delta and change_rollback_tested and runbooks_present

# ── WHAT REALLY WORKS — brutal honesty ─────────────────────────────────────
what_works := object.get(ctx, "what_really_works", {})
works_full := object.get(what_works, "fully_working_domains", [])
works_partial := object.get(what_works, "partial_domains", [])
works_blocked := object.get(what_works, "blocked_domains", [])
honesty_declared := count(works_full) + count(works_partial) + count(works_blocked) >= 15

provenance_complete := evaluation_date != "" and run_id != "" and
    count(evidence_refs) > 0 and registry_version != ""

all_controls_complete := reconciliation_ok and matrix_complete and
    system_certified and blockers_cleared and slo_sla_complete and
    change_control_complete and honesty_declared and provenance_complete

manual_review_required := true
hard_block := not all_controls_complete
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.final_certification_etap28.system_certification",
    "package": "jdg.final_certification_etap28",
    "priority": 28001,
    "stage": "ETAP_28",
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
    "state": "CERTIFICATION_PASSED" if {all_controls_complete} else "CERTIFICATION_FAILED",
    "production_status": "NOT_CERTIFIED",
    "reconciliation_ok": reconciliation_ok,
    "matrix_complete": matrix_complete,
    "system_certified": system_certified,
    "domains_certified": domains_certified,
    "domains_conditional": domains_conditional,
    "domains_blocked": domains_blocked,
    "blockers_cleared": blockers_cleared,
    "slo_sla_complete": slo_sla_complete,
    "change_control_complete": change_control_complete,
    "honesty_declared": honesty_declared,
    "provenance_complete": provenance_complete,
    "manual_review_required": manual_review_required,
    "certification_thresholds": {
        "total_etapy": total_etapy,
        "min_wdrozone": min_wdrozone_etapy,
        "rollback_mttr_max": 5,
        "hot_reload_max": 15,
        "rpo_max": 15,
        "rto_max": 30,
    },
    "domain_breakdown": {
        "vat": cert_vat, "pit": cert_pit, "zus": cert_zus,
        "accounting": cert_accounting, "kks_ord": cert_kks_ord,
        "crossborder": cert_crossborder, "pcc_local": cert_pcc_local,
        "ksef_jpk": cert_ksef_jpk, "rodo_aml": cert_rodo_aml,
        "hyper_contexts": cert_hyper, "ai_neural": cert_ai_neural,
        "orchestrator": cert_orchestrator, "legal_twin": cert_legal_twin,
        "control_plane": cert_control_plane, "security": cert_security,
        "disaster_recovery": cert_dr, "tests_ci": cert_tests_ci,
        "mirror_sync": cert_mirror,
    },
    "evidence_chain": {
        "run_id": run_id, "evidence_refs": evidence_refs,
        "evaluation_date": evaluation_date,
        "registry_version": registry_version,
    },
    "_routing": routing,
    "_routing_reason": "ETAP 28: certyfikacja końcowa — niekompletny reconciliation, blokery produkcyjne, brakujące SLO/SLA lub nieuczciwe deklaracje = BLOCK_AND_ALERT.",
    "_legal_basis": "ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md; WIZJA_OPA_ENTERPRISE_V2.md; ADR-001..ADR-022; raporty etapów 00-27; NOT_CERTIFIED (brak dowodu produkcyjnego)",
    "_warnings": ["Brak kompletnego łańcucha traceability, krytyczna luka prawna, temporalna, testowa, runtime, API, bezpieczeństwa lub traceability = NIE certyfikować jako kompletny."],
    "valid_from": "2026-01-01",
    "valid_to": null,
} {
    activated
}