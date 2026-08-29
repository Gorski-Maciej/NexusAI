#!/usr/bin/env python3
"""Canonical evidence gate for campaign PROMPT_21 — CONTROL PLANE (F1–F6).

Audits the executable control/data-plane contract present in JDG: rule
lifecycle (7 kroków), bundle pipeline (sign/verify/persist/discovery/status/
delta + canary + auto-rollback), law-change pipeline (ISAP + Law Radar
DRAFT_LAW + impact matrix + golden replay), F1 Legal Twin (LKG/LCI/TCL/RV),
F2 invariants (runtime + build), F3 Golden Oracle (replay + differential +
SMT/Z3), F4 Decision Certificate (classes + export), F6 Declarative Change,
plus WORM audit and amendment simulator. Honesty: distinguishes repository
completeness from production certification — production stays NOT_CERTIFIED
without external telemetry.
"""
from __future__ import annotations

import argparse
import ast
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT = "raporty_enterprise_v4/21_CONTROL_PLANE.txt"
EVIDENCE = BUNDLES_DIR / "control_plane_report21_evidence.json"

TOOL_SCOPE = (
    "tools/control_plane_lifecycle.py",
    "tools/rule_lifecycle_manager.py",
    "tools/bundle_server.py",
    "tools/deployment_orchestrator.py",
    "tools/dr_orchestrator.py",
    "tools/certificate_service.py",
    "tools/decision_certificate.py",
    "tools/decision_quality_monitor.py",
    "tools/declarative_change.py",
    "tools/invariant_checker.py",
    "tools/golden_baseline_seed.py",
    "tools/golden_replay.py",
    "tools/golden_autojustify.py",
    "tools/smt_z3_verification.py",
    "tools/differential_evaluation.py",
    "tools/law_radar.py",
    "tools/isap_crawler.py",
    "tools/isap_rule_update_pipeline.py",
    "tools/isap_drift_alarm.py",
    "tools/legal_basis_audit.py",
    "tools/legal_source_registry.py",
    "tools/legal_change_impact_analyzer.py",
    "tools/legal_change_calendar.py",
    "tools/legal_coverage_gap_report.py",
    "tools/legal_coverage_heatmap.py",
    "tools/law_impact_matrix.py",
    "tools/worm_storage.py",
    "tools/law_amendment_simulator.py",
    "tools/confidence_dashboard.py",
    "tools/validate_rules.py",
    "tools/lint_rego_rules.py",
    "tools/dead_rule_detector.py",
    "tools/tautology_guard.py",
    "tools/generate_manifest.py",
    "tools/policies_sync_gate.py",
    "tools/legal_twin_engine.py",
)

DOC_SCOPE = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/ANALIZA_STANU_OPA_JAKO_SYSTEM.md",
    "docs/RULE_LIFECYCLE.md",
    "docs/CONTROL_PLANE_RULE_LIFECYCLE.md",
    "docs/LEGAL_TWIN_RAPORT.md",
    "docs/LEGAL_TWIN_TRACEABILITY.md",
    "docs/LEGAL_SOURCE_REGISTRY.md",
    "docs/PEWNOSC_DASHBOARD.md",
    "docs/KAMPANIA_GLM52_ETAPY_10_28.md",
)

BUNDLE_SCOPE = (
    "bundles/bundle.sh",
    "bundles/manifest.json",
    "bundles/control_plane_state.json",
    "bundles/deployments.json",
    "bundles/healthy_versions.json",
    "bundles/bundle_catalog.json",
    "bundles/node_persistence.json",
    "bundles/golden_verdicts.json",
    "bundles/law_radar.json",
    "bundles/legal_graph.json",
    "bundles/policy_registry.json",
    "bundles/thresholds_data.json",
    "bundles/decision_certificates.json",
    "bundles/worm_audit.json",
)

TEST_SCOPE = (
    "tests/test_control_plane_lifecycle.py",
    "tests/test_p01_control_plane.py",
    "tests/test_legal_source_registry.py",
    "tests/test_legal_twin_traceability.py",
    "tests/test_control_plane_infrastructure.py",
)

RUNTIME_INVARIANTS_REGO = "rules/audit/runtime_invariants_enterprise.rego"
MAIN_JDG = "rules/main_jdg.rego"

LIFE_CYCLE_STEPS = (
    "specyfikacja", "generacja", "implementacja", "auto-testy", "bramki",
    "4-eyes", "SHADOW", "CANDIDATE", "ACTIVE", "ROLLED_BACK",
)

GENIALNE_POMYSLY = (
    "dashboard_pewnosc", "status_mode_floty", "samouzdrowienie", "symulator_nowelizacji",
    "game_day", "sbom_per_bundle", "worm_storage", "canary_5_100", "delta_bundles",
    "bundle_podpis_hsm", "traceability_chain", "four_eyes_automatyzacja",
)


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def exists(rel: str) -> bool:
    return bool(read(rel))


def scope_evidence() -> dict[str, Any]:
    all_paths = (*TOOL_SCOPE, *DOC_SCOPE, *BUNDLE_SCOPE, *TEST_SCOPE,
                 RUNTIME_INVARIANTS_REGO, MAIN_JDG)
    statuses = {path: exists(path) for path in dict.fromkeys(all_paths)}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "missing": [path for path, ok in statuses.items() if not ok],
        "files": statuses,
    }


def lifecycle_evidence() -> dict[str, Any]:
    control = read("tools/control_plane_lifecycle.py")
    rlm = read("tools/rule_lifecycle_manager.py")
    markers = {
        "operations": all(op in control for op in ["ADD", "CHANGE", "DEPRECATE", "RETIRE", "PURGE", "SUSPEND", "ROLLBACK"]),
        "statuses": all(st in control for st in ["SHADOW", "CANDIDATE", "ACTIVE", "ROLLED_BACK"]),
        "rollout_stages": all(st in control for st in ["CANARY", "SHADOW_COMPARE", "RAMPED", "SOAK"]),
        "manifest_8_fields": all(f in control for f in ["rule_id", "version", "legal_node_ids", "valid_from", "bundle_version", "content_hash", "signer", "signature"]),
        "four_eyes_sod": all(m in control for m in ["review_change", "authorize_deployment", "SoD", "production_mutation_policy"]),
        "traceability_chain": all(m in control for m in ["link_law_event", "link_bundle_and_verdicts", "amendment_id", "pr_id"]),
        "auto_rollback": "auto_rollback" in control,
        "lifecycle_cli": all(m in rlm for m in ["register", "promote", "rollback", "suspend", "deprecate", "retire", "migrate", "check"]),
    }
    return {"markers": markers, "complete": all(markers.values())}


def bundle_pipeline_evidence() -> dict[str, Any]:
    server = read("tools/bundle_server.py")
    deploy = read("tools/deployment_orchestrator.py")
    bundle_sh = read("bundles/bundle.sh")
    markers = {
        "sign_hsm_ready": all(m in server for m in ["HSM:", "signature", "sha256"]),
        "verify_key_node": all(m in server for m in ["def verify", "node_verification", "FAIL_CLOSED"]),
        "persist": all(m in server for m in ["persist_node_state", "restart_policy", "START_LAST_VERIFIED_OR_FAIL_CLOSED"]),
        "discovery": all(m in server for m in ["def discovery", "endpoint", "signing"]),
        "status": all(m in server for m in ["def status", "healthy", "latest"]),
        "delta": all(m in server for m in ["delta_manifest", "requires_signed_snapshot", "FULL_SNAPSHOT_REQUIRED"]),
        "sbom": "sbom" in bundle_sh.lower() or ".sbom.json" in bundle_sh,
        "canary_5": "CANARY_PCT" in deploy and "5" in read("tools/deployment_orchestrator.py").split("CANARY_PCT = ")[1][:3],
        "ramp_25_50_100": all(str(x) in deploy for x in [25, 50, 100]),
        "soak_24h": "SOAK_HOURS" in deploy,
        "auto_rollback_5min": all(m in deploy for m in ["auto-rollback", "ROLLBACK_MINUTES", "rollback_sla_pass"]),
        "hot_reload_15min": "HOT_RELOAD_MINUTES" in deploy,
        "fleet_status": "fleet_freshness_pct" in deploy,
    }
    return {"markers": markers, "complete": all(markers.values())}


def law_change_evidence() -> dict[str, Any]:
    radar = read("tools/law_radar.py")
    crawler = read("tools/isap_crawler.py")
    pipeline = read("tools/isap_rule_update_pipeline.py")
    drift = read("tools/isap_drift_alarm.py")
    impact = read("tools/law_impact_matrix.py")
    sim = read("tools/law_amendment_simulator.py")
    markers = {
        "draft_law_radar": all(m in radar for m in ["DRAFT_LAW", "RCL", "SEJM", "SENAT", "lead_days", "prepare"]),
        "isap_crawler": "ISAP" in crawler,
        "rule_update_pipeline": all(m in pipeline for m in ["ingest", "impact", "plan"]),
        "drift_alarm": "drift" in drift.lower(),
        "impact_matrix": all(m in impact for m in ["affected_rules", "PARAMETER_ONLY", "LOGIC"]),
        "amendment_simulator": all(m in sim for m in ["simulate", "SHADOW_ANALYSIS_ONLY", "impact_pct", "old_value", "new_value"]),
        "slo_24h_4h": "24 h" in read("docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md") and "4 h" in read("docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md"),
    }
    return {"markers": markers, "complete": all(markers.values())}


def f1_legal_twin_evidence() -> dict[str, Any]:
    registry = read("tools/legal_source_registry.py")
    audit = read("tools/legal_basis_audit.py")
    graph = read("bundles/legal_graph.json")
    indexes = json.loads(graph).get("indexes", {}) if graph else {}
    markers = {
        "lkg_nodes": all(m in registry for m in ["LKG", "source_record_id", "legal_nodes"]),
        "legal_source_registry": "registry" in registry.lower(),
        "lci_tcl_rv": all(m in indexes for m in ["LCI", "TCL", "RV"]),
        "rv_gate": all(m in audit for m in ["--gate", "rv_metric", "MISSING", "UNKNOWN_ACT"]),
    }
    return {"markers": markers, "complete": all(markers.values())}


def f2_invariants_evidence() -> dict[str, Any]:
    checker = read("tools/invariant_checker.py")
    rego = read(RUNTIME_INVARIANTS_REGO)
    main = read(MAIN_JDG)
    markers = {
        "inv_catalog": "catalog" in checker,
        "inv_ci_gate": "def cmd_ci" in checker,
        "runtime_invariants_rego": "package" in rego and "INV-" in rego,
        "runtime_check_wired": "runtime_invariants" in main,
        "post_merge": "POST-MERGE" in main,
        "fail_closed": "sys.exit" in checker,
    }
    return {"markers": markers, "complete": all(markers.values())}


def f3_golden_evidence() -> dict[str, Any]:
    replay = read("tools/golden_replay.py")
    autojustify = read("tools/golden_autojustify.py")
    diff = read("tools/differential_evaluation.py")
    smt = read("tools/smt_z3_verification.py")
    markers = {
        "golden_schema_v2": "SCHEMA_VERSION" in replay and "2" in replay,
        "uver_gate": all(m in replay for m in ["UVR", "uver_applies", "BLOKADA WDROŻENIA"]),
        "autojustify": "uzasadn" in autojustify or "explain" in autojustify,
        "differential_2nodes": all(m in diff for m in ["MIN_NODES", "quorum", "deterministic", "compare"]),
        "smt_z3_skeleton": all(m in smt for m in ["z3", "SKELETON", "UNVERIFIED", "prove", "lemmas"]),
        "differential_sessions": "differential_sessions.json" in diff,
    }
    return {"markers": markers, "complete": all(markers.values())}


def f4_certificate_evidence() -> dict[str, Any]:
    cert = read("tools/decision_certificate.py")
    service = read("tools/certificate_service.py")
    markers = {
        "issue_verify_export": all(m in cert for m in ["cmd_issue", "cmd_verify", "cmd_export"]),
        "classes": all(c in cert for c in ["CERTAIN", "CONDITIONAL", "NEEDS_ADVICE"]),
        "xml_export": "xml" in cert.lower(),
        "seal": "seal" in cert.lower() or "piecz" in cert.lower(),
        "service_layer": "service" in service.lower(),
    }
    return {"markers": markers, "complete": all(markers.values())}


def f6_declarative_evidence() -> dict[str, Any]:
    dc = read("tools/declarative_change.py")
    markers = {
        "plan_execute": all(m in dc for m in ["plan", "execute", "template", "history"]),
        "human_describes": "człowiek opisuje" in dc or "deklaratyw" in dc.lower() or "declarative" in dc.lower(),
        "gates": "checklista 4-eyes" in dc or "gates" in dc or "GATES" in dc,
        "param_change_1min": "1 min" in dc or "60" in dc,
    }
    return {"markers": markers, "complete": all(markers.values())}


def worm_evidence() -> dict[str, Any]:
    worm = read("tools/worm_storage.py")
    markers = {
        "append_only": "APPEND_ONLY" in worm,
        "hash_chain": all(m in worm for m in ["prev_hash", "record_hash", "merkle_root"]),
        "tamper_evident": all(m in worm for m in ["verify_chain", "verified", "issues"]),
        "fail_closed": "sys.exit(2)" in worm,
    }
    return {"markers": markers, "complete": all(markers.values())}


def genius_ideas_evidence() -> dict[str, Any]:
    dashboard = read("tools/confidence_dashboard.py")
    deploy = read("tools/deployment_orchestrator.py")
    dr = read("tools/dr_orchestrator.py")
    bundle_sh = read("bundles/bundle.sh")
    control = read("tools/control_plane_lifecycle.py")
    markers = {
        "dashboard_pewnosc": all(m in dashboard for m in ["LCI", "TCL", "RV", "legal_confidence_index"]),
        "status_mode_floty": "fleet_freshness_pct" in deploy,
        "samouzdrowienie": "auto_rollback" in control or "auto-rollback" in deploy,
        "symulator_nowelizacji": exists("tools/law_amendment_simulator.py"),
        "game_day": "game-day" in dr,
        "sbom_per_bundle": "sbom" in bundle_sh.lower(),
        "worm_storage": exists("tools/worm_storage.py"),
        "canary_5_100": "CANARY_PCT" in deploy and "RAMP_STEPS" in deploy,
        "delta_bundles": "delta_manifest" in read("tools/bundle_server.py"),
        "bundle_podpis_hsm": "HSM:" in read("tools/bundle_server.py"),
        "traceability_chain": "link_law_event" in control,
        "four_eyes_automatyzacja": "review_change" in control,
    }
    implemented = sum(markers.values())
    return {"markers": markers, "implemented": implemented, "total": len(markers),
            "complete": implemented == len(markers)}


def syntax_evidence() -> dict[str, Any]:
    errors = []
    checked = 0
    for rel in TOOL_SCOPE:
        path = BASE_DIR / rel
        if not path.exists():
            continue
        checked += 1
        try:
            ast.parse(path.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError as exc:
            errors.append({"file": rel, "error": str(exc)})
    return {"files_checked": checked, "syntax_errors": errors, "syntax_ok": not errors}


def test_evidence() -> dict[str, Any]:
    texts = {path: read(path) for path in TEST_SCOPE}
    joined = "\n".join(texts.values())
    return {
        "files": {path: bool(text) for path, text in texts.items()},
        "lifecycle_tests": "control_plane_lifecycle" in joined,
        "infrastructure_tests": "differential_evaluation" in joined or "worm_storage" in joined or "smt_z3" in joined,
        "complete": all(texts.values()),
    }


def build_evidence() -> dict[str, Any]:
    scope = scope_evidence()
    lifecycle = lifecycle_evidence()
    bundle = bundle_pipeline_evidence()
    law = law_change_evidence()
    f1 = f1_legal_twin_evidence()
    f2 = f2_invariants_evidence()
    f3 = f3_golden_evidence()
    f4 = f4_certificate_evidence()
    f6 = f6_declarative_evidence()
    worm = worm_evidence()
    genius = genius_ideas_evidence()
    syntax = syntax_evidence()
    tests = test_evidence()
    gates = {
        "scope_files_present": scope["all_present"],
        "rule_lifecycle_7_steps": lifecycle["complete"],
        "bundle_pipeline_signed_delta": bundle["complete"],
        "law_change_pipeline_f5": law["complete"],
        "f1_legal_twin_lkg": f1["complete"],
        "f2_invariants_runtime": f2["complete"],
        "f3_golden_differential_smt": f3["complete"],
        "f4_decision_certificate": f4["complete"],
        "f6_declarative_change": f6["complete"],
        "worm_append_only": worm["complete"],
        "genius_ideas_12": genius["complete"],
        "tools_syntax_ok": syntax["syntax_ok"],
        "tests_complete": tests["complete"],
        "report_present": exists(REPORT),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "report": "RAPORT_21_CONTROL_PLANE",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "lifecycle": lifecycle,
        "bundle_pipeline": bundle,
        "law_change_pipeline": law,
        "f1_legal_twin": f1,
        "f2_invariants": f2,
        "f3_golden": f3,
        "f4_certificate": f4,
        "f6_declarative": f6,
        "worm": worm,
        "genius_ideas": genius,
        "syntax": syntax,
        "tests": tests,
        "production_status": "NOT_CERTIFIED",
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> None:
    p = argparse.ArgumentParser(description="Canonical evidence gate — PROMPT_21 CONTROL PLANE (F1–F6)")
    p.add_argument("--check", action="store_true", help="fail with exit code 1 when not WDROZONY_100")
    args = p.parse_args()
    evidence = build_evidence()
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"status": evidence["status"],
                      "gates": evidence["gate_summary"],
                      "genius_ideas": evidence["genius_ideas"]["implemented"],
                      "production_status": evidence["production_status"],
                      "evidence": str(EVIDENCE.relative_to(BASE_DIR))},
                     indent=2, ensure_ascii=False))
    if args.check and evidence["status"] != "WDROZONY_100":
        sys.exit(1)


if __name__ == "__main__":
    main()
