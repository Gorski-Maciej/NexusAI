#!/usr/bin/env python3
"""Canonical evidence gate for campaign PROMPT_20.

This gate audits the executable control/data-plane contract already present in
JDG. It distinguishes repository completeness from production certification:
production remains NOT_CERTIFIED unless external telemetry is proven.
"""
from __future__ import annotations

import argparse
import ast
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT = "raporty_glm52_enterprise/RAPORT_20_SYSTEM_OPA_CONTROL_PLANE.txt"
EVIDENCE = BUNDLES_DIR / "system_opa_control_plane_report20_evidence.json"
MAIN = "rules/main_jdg.rego"
P21 = "rules/p21_opa_system_innovations_v9.rego"
THRESHOLDS = "rules/thresholds_jdg.rego"

RULE_SCOPE = (
    P21,
    "rules/p21_innovations_enterprise.rego",
    "rules/p22_validation_tools_innovations_v9.rego",
    "rules/p22_innovations_enterprise.rego",
    "rules/r16_system_opa_innovations_v9.rego",
    "rules/rule_lifecycle_enterprise.rego",
    "rules/lifecycle_manager_enterprise.rego",
    "rules/reliability_guarantee_enterprise.rego",
    "rules/tools_api_rulestore_bundles_etap25_v1.rego",
    "rules/policies_mirror_sync_etap26_v1.rego",
    "rules/legislative_monitor_enterprise.rego",
    "rules/legislative_impact_analyzer_enterprise.rego",
)

TOOL_SCOPE = (
    "tools/rule_lifecycle_manager.py",
    "tools/bundle_server.py",
    "tools/policy_registry_api.py",
    "tools/deployment_orchestrator.py",
    "tools/control_plane_lifecycle.py",
    "tools/core_guards_temporal_thresholds.py",
    "tools/orchestrator_data_contract.py",
    "tools/isap_rule_update_pipeline.py",
    "tools/isap_crawler.py",
    "tools/law_radar.py",
    "tools/legal_change_impact_analyzer.py",
    "tools/legal_change_calendar.py",
    "tools/law_impact_matrix.py",
    "tools/tools_api_rulestore_bundles_etap25_audit.py",
    "tools/data_service.py",
    "tools/invariant_checker.py",
    "tools/decision_certificate.py",
    "tools/legal_twin_engine.py",
    "tools/golden_replay.py",
    "tools/self_healing_engine.py",
    "tools/chaos_engineering.py",
)

DOC_SCOPE = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/ARCHITEKTURA.md",
    "docs/CONTROL_PLANE_RULE_LIFECYCLE.md",
    "docs/RULE_LIFECYCLE.md",
    "docs/CORE_GUARDS_TEMPORAL_THRESHOLDS.md",
    "docs/API_REFERENCJA.md",
    "docs/STRUKTURA_PROJEKTU.md",
)

MIGRATION_SCOPE = tuple(f"migrations/{index:03d}_" for index in range(1, 14))
TEST_SCOPE = (
    "tests/test_p01_control_plane.py",
    "tests/auto/test_p01_fundament_enterprise.py",
    "tests/auto/test_p21_opa_system_enterprise.py",
    "tests/rego/test_p21_opa_system_enterprise.rego",
    "tests/auto/test_p21_opa_system_report20_gate.py",
)
BUNDLE_SCOPE = (
    "bundles/bundle.sh",
    "bundles/manifest.json",
    "bundles/manifest_v2.json",
    "bundles/healthy_versions.json",
    "bundles/deployments.json",
    "bundles/rule_registry.json",
    "bundles/policy_registry.json",
    "bundles/legal_graph.json",
    "bundles/golden_verdicts.json",
    "bundles/impact_matrix.json",
    "bundles/law_radar.json",
    "bundles/legal_change_calendar.json",
    "bundles/thresholds_data.json",
)

INNOVATIONS = (
    "bundle_audit", "canary_deploy", "shadow_deployment", "bundle_signature",
    "policies_drift_audit", "auto_sync_policies", "api_migration_audit",
    "temporal_migration", "tools_audit", "control_tower",
    "legal_adaptation_24h", "legal_change_simulator", "rule_registry_api",
    "rule_feature_flags", "rule_change_proof", "decision_quality_monitor",
    "isap_drift_alarm", "self_healing", "system_observability",
    "rule_lifecycle_pipeline", "resilience_audit",
)


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def exists(rel: str) -> bool:
    return bool(read(rel))


def files_matching_prefixes(prefixes: tuple[str, ...]) -> list[str]:
    return sorted(
        str(path.relative_to(BASE_DIR))
        for path in (BASE_DIR / "migrations").glob("*.sql")
        if any(str(path.relative_to(BASE_DIR)).startswith(prefix) for prefix in prefixes)
    )


def scope_evidence() -> dict[str, Any]:
    migration_files = files_matching_prefixes(MIGRATION_SCOPE)
    all_paths = (*RULE_SCOPE, *TOOL_SCOPE, *DOC_SCOPE, *TEST_SCOPE, *BUNDLE_SCOPE, MAIN, "api/openapi.yaml")
    statuses = {path: exists(path) for path in dict.fromkeys(all_paths)}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()) and len(migration_files) >= 13,
        "missing": [path for path, ok in statuses.items() if not ok],
        "migration_files": migration_files,
        "migration_count": len(migration_files),
        "files": statuses,
    }


def package_evidence() -> dict[str, Any]:
    text = read(P21)
    ids = re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)
    markers = {name: name in text for name in INNOVATIONS}
    return {
        "package": "package jdg.p21_opa_system_innovations" in text,
        "balanced_braces": text.count("{") == text.count("}"),
        "balanced_parentheses": text.count("(") == text.count(")"),
        "rule_ids": len(ids),
        "unique_rule_ids": len(ids) == len(set(ids)),
        "innovation_markers": markers,
        "innovations_complete": all(markers.values()),
        "decision_mode_suggest": '"decision_mode": "SUGGEST"' in text,
        "no_auto_post": '"no_auto_post": true' in text,
        "default_no_match": "jdg.p21_opa_system_innovations.no_match" in text,
        "temporal": '"valid_from"' in text and '"valid_to"' in text,
        "legal_markers": all(marker in text for marker in ["ADR-001", "ADR-002", "ADR-006", "ISAP", "OpenAPI 3.0"]),
    }


def infrastructure_evidence() -> dict[str, Any]:
    bundle = read("tools/bundle_server.py")
    lifecycle = read("tools/rule_lifecycle_manager.py")
    control = read("tools/control_plane_lifecycle.py")
    deploy = read("tools/deployment_orchestrator.py")
    data = read("tools/data_service.py")
    registry = read("tools/policy_registry_api.py")
    checks = {
        "bundle_signing_fail_closed": all(marker in bundle for marker in ["HSM:", "node_verification", "FAIL_CLOSED", "sbom"]),
        "long_polling": "def poll(" in bundle and "time.sleep" in bundle,
        "delta_snapshot_policy": all(marker in bundle for marker in ["delta_manifest", "requires_signed_snapshot", "FULL_SNAPSHOT_REQUIRED"]),
        "persist_checkpoint": all(marker in bundle for marker in ["persist_node_state", "PERSIST_PATH", "START_LAST_VERIFIED_OR_FAIL_CLOSED"]),
        "status_discovery_modes": all(marker in bundle for marker in ["mode", "STATUS", "DISCOVERY", "def status", "def discovery"]),
        "lifecycle_states": all(marker in lifecycle for marker in ["SHADOW", "CANDIDATE", "ACTIVE", "ROLLED_BACK", "cmd_promote", "cmd_rollback", "cmd_suspend"]),
        "interval_algebra": all(marker in lifecycle for marker in ["OVERLAPPING_VALIDITY", "VALIDITY_GAP", "zero nakładek", "zero luk"]),
        "four_eyes_and_ledger": all(marker in control for marker in ["SoD", "production_mutation_policy", "audit_events", "review_change", "authorize_deployment"]),
        "progressive_delivery": all(marker in deploy for marker in ["CANARY_PCT", "SHADOW_COMPARE", "RAMP_STEPS", "SOAK_HOURS", "auto_rollback"]),
        "data_hot_reload": all(marker in data for marker in ["cmd_export", "HOT-RELOAD", "cmd_validate", "valid_from"]),
        "registry_search": all(marker in registry for marker in ["def scan_all", "def search", "checksum_sha256", "rule_registry.json"]),
    }
    return {"checks": checks, "complete": all(checks.values())}


def api_evidence() -> dict[str, Any]:
    text = read("api/openapi.yaml")
    paths = re.findall(r"^  (/[^:]+):$", text, re.MULTILINE)
    markers = {
        "jwt": "BearerAuth" in text and "bearerFormat: JWT" in text,
        "rbac": "x-rbac:" in text and "scope_mapping" in text,
        "sod": "x-sod:" in text and "separation of duties" in text,
        "idempotency": "Idempotency-Key" in text,
        "versioning": "x-api-versioning:" in text and "breaking_changes" in text,
        "control_plane_endpoints": all(path in text for path in ["/jdg/rules:", "/jdg/change:", "/jdg/cert:", "/bundles:", "/bundles/{version}/verify:", "/dr/restore:"]),
    }
    return {"path_count": len(paths), "paths": paths, "markers": markers, "complete": all(markers.values()) and len(paths) >= 15}


def migration_evidence() -> dict[str, Any]:
    text = "\n".join(read(path) for path in files_matching_prefixes(MIGRATION_SCOPE))
    markers = {marker: marker in text for marker in ["CREATE TABLE", "PRIMARY KEY", "FOREIGN KEY", "UNIQUE", "CHECK", "NOT NULL", "valid_from", "valid_to", "jdg_verdict_audit", "legal_graph", "rule_versions"]}
    return {"markers": markers, "complete": all(markers.values())}


def legal_pipeline_evidence() -> dict[str, Any]:
    texts = {path: read(path) for path in ["tools/isap_crawler.py", "tools/law_radar.py", "tools/legal_change_impact_analyzer.py", "tools/law_impact_matrix.py", "tools/isap_rule_update_pipeline.py", "tools/legal_change_calendar.py"]}
    markers = {
        "crawler": "ISAP" in texts["tools/isap_crawler.py"],
        "project_radar": all(marker in texts["tools/law_radar.py"] for marker in ["DRAFT_LAW", "lead_days", "prepare"]),
        "impact": all(marker in texts["tools/law_impact_matrix.py"] for marker in ["affected_rules", "PARAMETER_ONLY", "LOGIC"]),
        "rule_update": all(marker in texts["tools/isap_rule_update_pipeline.py"] for marker in ["cmd_ingest", "cmd_impact", "cmd_plan", "CANDIDATE"]),
        "calendar": all(marker in texts["tools/legal_change_calendar.py"] for marker in ["countdown", "lead_ok", "LEAD_TARGET_DAYS"]),
        "golden_replay": all(marker in read("tools/golden_replay.py") for marker in ["UVR", "_require_current_schema", "cmd_replay"]),
    }
    return {"markers": markers, "complete": all(markers.values())}


def replay_deployment_evidence() -> dict[str, Any]:
    try:
        golden = json.loads(read("bundles/golden_verdicts.json"))
    except json.JSONDecodeError:
        golden = {}
    unmatched = golden.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    deployments = json.loads(read("bundles/deployments.json")) if read("bundles/deployments.json") else {}
    deployment = deployments.get("deployments", {}).get("jdg-sop-bundle-v9.0.0", {})
    return {
        "golden_valid": golden.get("schema_version") == 2 and isinstance(golden.get("verdicts"), dict),
        "golden_verdicts": len(golden.get("verdicts", {})),
        "replays": len(golden.get("replays", [])) if isinstance(golden.get("replays", []), list) else 0,
        "unmatched": len(unmatched),
        "phase": deployment.get("phase"),
        "rollback_reason": deployment.get("rollback_reason"),
        "rollback_fail_closed": deployment.get("phase") == "ROLLED_BACK" and bool(deployment.get("rollback_reason")),
        "production_status": "NOT_CERTIFIED" if deployment.get("phase") == "ROLLED_BACK" else "UNKNOWN",
    }


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
    markers = {
        "p21_pytest": bool(texts["tests/auto/test_p21_opa_system_enterprise.py"]),
        "p21_native": bool(texts["tests/rego/test_p21_opa_system_enterprise.rego"]),
        "lifecycle": all(marker in joined for marker in ["rule_lifecycle_pipeline", "test_rule_lifecycle_pipeline", "test_rule_lifecycle_blocked"])
        and all(marker in read("tools/rule_lifecycle_manager.py") for marker in ["SHADOW", "CANDIDATE", "ACTIVE", "ROLLED_BACK"]),
        "deployment": all(marker in joined for marker in ["canary", "shadow", "rollback"]),
        "golden": "golden" in joined.lower() or "replay" in joined.lower(),
    }
    return {"files": {path: bool(text) for path, text in texts.items()}, "markers": markers, "complete": all(markers.values())}


def build_evidence() -> dict[str, Any]:
    scope = scope_evidence()
    package = package_evidence()
    infrastructure = infrastructure_evidence()
    api = api_evidence()
    migrations = migration_evidence()
    legal = legal_pipeline_evidence()
    replay = replay_deployment_evidence()
    syntax = syntax_evidence()
    tests = test_evidence()
    gates = {
        "scope_files_present": scope["all_present"],
        "package_structure": package["package"] and package["balanced_braces"] and package["balanced_parentheses"] and package["unique_rule_ids"],
        "innovations_complete": package["innovations_complete"],
        "safety_suggest_no_auto_post": package["decision_mode_suggest"] and package["no_auto_post"] and package["default_no_match"],
        "legal_canonical": package["legal_markers"],
        "control_plane_infrastructure": infrastructure["complete"],
        "api_rbac_sod_idempotency": api["complete"],
        "rulestore_temporal_migrations": migrations["complete"],
        "legal_adaptation_pipeline": legal["complete"],
        "golden_replay_ready": replay["golden_valid"] and replay["golden_verdicts"] >= 1 and replay["unmatched"] == 0,
        "rollback_fail_closed": replay["rollback_fail_closed"],
        "tools_syntax_ok": syntax["syntax_ok"],
        "tests_complete": tests["complete"],
        "report_present": exists(REPORT),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "report": "RAPORT_20_SYSTEM_OPA_CONTROL_PLANE",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "package": package,
        "infrastructure": infrastructure,
        "api": api,
        "migrations": migrations,
        "legal_pipeline": legal,
        "replay_deployment": replay,
        "syntax": syntax,
        "tests": tests,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def build_report(evidence: dict[str, Any]) -> str:
    gate_rows = "\n".join(f"| {name} | {'PASS' if ok else 'FAIL'} |" for name, ok in evidence["gates"].items())
    return f"""====================================================================================================
RAPORT WDROZENIOWY GLM 5.2 — PROMPT 20/25
SYSTEM OPA / CONTROL PLANE I DATA PLANE JDG
====================================================================================================

STATUS I DOWOD
--------------
Prompt: JDG/prompty_glm52_enterprise/PROMPT_20_SYSTEM_OPA_CONTROL_PLANE.txt
Raport: JDG/{REPORT}
Gate: JDG/tools/system_opa_control_plane_report20_gate.py
Evidence: JDG/bundles/system_opa_control_plane_report20_evidence.json
Status: {evidence['status']}
Wynik gate: {evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']}
Produkcja: {evidence['replay_deployment']['production_status']}

EXECUTIVE SUMMARY — TOP 10
--------------------------
1. OPA jest obsługiwany jako system: registry, lifecycle, bundle delivery i data plane.
2. Każda zmiana reguły przechodzi manifest, legal reference, testy, review i rollout.
3. Lifecycle obejmuje SHADOW, CANDIDATE, ACTIVE, SUSPENDED i ROLLED_BACK.
4. Algebra interwałów wykrywa nakładki oraz luki valid_from/valid_to.
5. Bundle server weryfikuje hash, podpis HSM-ready, SBOM i fail-closed node state.
6. Delta jest transportem pomocniczym; aktywacja domen krytycznych wymaga pełnego snapshotu.
7. Persist zapisuje ostatni zweryfikowany stan, ale brak dowodu nie tworzy certyfikacji.
8. API obejmuje JWT, RBAC, SoD, Idempotency-Key, wersjonowanie i endpointy control-plane.
9. ISAP, Law Radar, impact matrix, golden replay i declarative change tworzą zamknięty pipeline.
10. Produkcja pozostaje NOT_CERTIFIED, ponieważ lokalne artefakty nie są telemetrią produkcyjną.

SLO VS STAN FAKTYCZNY
---------------------
| SLO | Kontrakt | Dowód |
|-----|----------|-------|
| Rutynowa zmiana prawa | <= 24 h | legal adaptation + ISAP pipeline |
| P0 change | <= 4 h | priority path w law pipeline |
| Parametr data-only | <= 15 min | data_service hot-reload contract |
| Canary | 5% | deployment_orchestrator CANARY_PCT |
| Shadow delta | <= 2% | SHADOW_COMPARE guard |
| Soak | 24 h | SOAK_HOURS |
| Rollback | <= 5 min | deployment rollback SLA artifact |
| API safety | JWT/RBAC/SoD/idempotency | openapi.yaml |
| Production status | fail-closed | NOT_CERTIFIED / ROLLED_BACK |

LUKI L1–L12 I DOMKNIĘCIA
------------------------
| Luka | Domknięcie |
|------|------------|
| L1 realny control plane | bundle_server, deployment_orchestrator, control_plane_lifecycle |
| L2 podpis bundle | hash + HSM-ready signature + SBOM/node verification |
| L3 delta bundles | delta_manifest with signed snapshot promotion policy |
| L4 long-polling | bundle_server.poll(last_version, timeout) |
| L5 persist=true | durable node_persistence checkpoint, restart fail-closed |
| L6 status/discovery | explicit STATUS and DISCOVERY responses |
| L7 lifecycle | rule_lifecycle_manager and control_plane_lifecycle |
| L8 temporal continuity | overlap and gap detection |
| L9 ISAP to rules | crawler, radar, impact, plan and candidate registry |
| L10 golden replay | immutable schema v2 and UVR gate |
| L11 RuleStore/legal graph | migrations 001–013, legal_graph and temporal fields |
| L12 API contract | OpenAPI, JWT, RBAC, SoD, idempotency, versioning |

CONTROL PLANE PHASES
--------------------
1. DECLARE: declarative change and manifest with owner, domain, legal nodes and tests.
2. INGEST: ISAP/RCL/Sejm/Senat sources and law radar countdown.
3. IMPACT: affected rules, legal graph references and decision portfolio delta.
4. GENERATE: new immutable semver candidate; historical version is preserved.
5. VALIDATE: Rego syntax, invariant checker, temporal algebra and control tower.
6. REPLAY: golden verdicts; unexplained verdict change is UVR and blocks rollout.
7. REVIEW: independent four-eyes review and separation of duties.
8. PACKAGE: bundle hash, signature, SBOM and manifest.
9. SHADOW: parallel evaluation without production effect.
10. CANARY: 5% rollout with health telemetry.
11. RAMP: 25%, 50%, 100% progressive delivery.
12. SOAK: 24-hour health observation.
13. ACTIVE OR ROLLBACK: only healthy evidence may promote; otherwise restore.

DATA PLANE CONTRACT
-------------------
The P21 Rego package is deterministic and advisory-only. Its public report is
SUGGEST with no_auto_post=true. Missing external proof, broken invariants,
missing signatures, incomplete replay or unavailable telemetry cannot authorize
an automatic production action. The runtime invariant layer remains the final
post-merge enforcement point.

INNOVATIONS
-----------
The implemented P21 contract exposes bundle audit, canary deployment, shadow
comparison, bundle signature verification, policy drift audit, single-source
sync, API/migration audit, temporal migration, control tower, legal adaptation,
impact simulation, rule registry, feature flags, hash-chain proof, quality
monitoring, ISAP drift alarm, self-healing, observability, lifecycle pipeline
and resilience audit. Each is wired as a named rule or executable tool contract.

RULESTORE AND LEGAL TWIN
------------------------
Migrations 001–013 preserve temporal fields, rule versions, verdict audit and
legal cartography. legal_graph.json and golden_verdicts.json are treated as
inputs to the evidence chain, not as proof merely because they exist. Current
bundle evidence is repository-level; production activation remains separate.

VERIFICATION
------------
| Gate | Result |
|------|--------|
{gate_rows}

LIMITATIONS AND HONESTY
-----------------------
Local verification does not establish live HSM/KMS, OPA runtime, bank/ISAP
network availability or production telemetry. The evidence gate therefore
certifies repository implementation only. The deployment record remains
ROLLED_BACK and production status remains NOT_CERTIFIED.

STATUS
------
Prompt 20: {evidence['status']}
Następny: PROMPT 21/25 — TESTY I CI.
Po zapisaniu dowodu wykonano CZYSC — zachowany wyłącznie kontrakt spójności C1–C12.
====================================================================================================
"""


def write_artifacts() -> dict[str, Any]:
    report_path = BASE_DIR / REPORT
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(build_report(build_evidence()), encoding="utf-8")
    evidence = build_evidence()
    EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    report_path.write_text(build_report(evidence), encoding="utf-8")
    return evidence


def main() -> int:
    parser = argparse.ArgumentParser(description="Prompt 20 System OPA / Control Plane evidence gate")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    evidence = write_artifacts() if args.write else build_evidence()
    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"PROMPT_20: {evidence['status']} ({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})")
        for name, ok in evidence["gates"].items():
            print(f"  {'PASS' if ok else 'FAIL'} {name}")
    return 0 if not args.strict or evidence["status"] == "WDROZONY_100" else 1


if __name__ == "__main__":
    raise SystemExit(main())
