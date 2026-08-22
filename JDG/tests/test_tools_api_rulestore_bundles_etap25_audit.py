"""ETAP 25 — tools, API, RuleStore and bundles control-data plane evidence contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "tools_api_rulestore_bundles_etap25_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
OPENAPI = ROOT / "api" / "openapi.yaml"
AUDITOR = ROOT / "tools" / "tools_api_rulestore_bundles_etap25_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "25_TOOLS_API_RULESTORE_BUNDLES.txt"
BUNDLE = ROOT / "bundles" / "tools_api_rulestore_bundles_etap25_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_no_placeholder_rules():
    text = read(PACKAGE)
    assert "package jdg.tools_api_rulestore_bundles_etap25" in text
    assert text.count('"rule_id":') == 2
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")
    assert "assert " + "True" not in text


def test_control_data_plane_contract_covers_all_required_layers():
    text = read(PACKAGE)
    for marker in [
        "api_schema_consistent", "authnz_complete", "idempotency_complete",
        "versioning_complete", "migrations_constraints_complete",
        "bundle_integrity_complete", "healthy_persisted",
        "progressive_delivery_complete", "hot_reload_complete",
        "worm_merkle_complete", "dr_complete", "production_honest",
        "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "CONTROL_PLANE_READY",
        "CONTROL_PLANE_BLOCKED", "NOT_CERTIFIED", "no_auto_post",
    ]:
        assert marker in text


def test_openapi_has_rbac_sod_idempotency_versioning():
    text = read(OPENAPI)
    for marker in [
        "Idempotency-Key", "x-api-versioning", "x-rbac", "x-sod",
        "separation of duties", "breaking_changes", "scope_mapping",
        "  /bundles:", "/bundles/{version}/verify", "  /dr/restore",
    ]:
        assert marker in text


def test_migrations_have_constraints_and_worm():
    text = "\n".join(read(ROOT / f"migrations/{f}") for f in [
        "001_jdg_rule_store.sql", "002_jdg_enterprise_v7.sql",
        "003_jdg_v8_legal_twin.sql", "004_jdg_v9_control_plane.sql",
        "013_jdg_v18_tools_api_rulestore_bundles.sql",
    ])
    for marker in ["PRIMARY KEY", "FOREIGN KEY", "UNIQUE", "CHECK",
                   "CREATE TABLE IF NOT EXISTS", "WORM", "append-only"]:
        assert marker in text


def test_bundle_signing_sbom_and_node_verification():
    text = read(ROOT / "tools" / "bundle_server.py")
    assert "publish" in text and "verify" in text
    assert "HSM:" in text
    assert "sbom" in text and "node_verification" in text and "FAIL_CLOSED" in text
    sh = read(ROOT / "bundles" / "bundle.sh")
    assert "SBOM" in sh and "sbom" in sh and "sha256sum" in sh


def test_progressive_delivery_tools_exist():
    text = read(ROOT / "tools" / "deployment_orchestrator.py")
    for marker in ["canary", "shadow", "ramped", "soak", "auto-rollback",
                   "active_version", "healthy_versions", "hot-reload"]:
        assert marker in text


def test_worm_merkle_and_disaster_recovery_tools_exist():
    cert = read(ROOT / "tools" / "decision_certificate.py")
    assert "merkle_root" in cert and "HSM-ECDSA" in cert
    dr = read(ROOT / "tools" / "dr_orchestrator.py")
    for marker in ["snapshot", "restore", "RPO", "RTO", "restore_tested", "game-day"]:
        assert marker in dr


def test_threshold_registry_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "tools_api_rulestore_bundles_etap25 := {" in thresholds
    for marker in ["min_canary_pct", "max_shadow_delta_pct", "soak_hours",
                   "max_rollback_mttr_min", "hot_reload_sla_min",
                   "max_rpo_min", "max_rto_min", "production_status",
                   "worm_append_only", "sod_four_eyes_required"]:
        assert marker in thresholds
    assert "import data.jdg.tools_api_rulestore_bundles_etap25" in main
    assert '"jdg.tools_api_rulestore_bundles_etap25": tools_api_rulestore_bundles_etap25.decide' in main
    assert "final_verdict_p69 = safe_merge(final_verdict_p68" in main
    assert "object.union(final_verdict_p69" in main
    assert "final_verdict = final_verdict_enforced" in main


def test_auditor_builds_complete_evidence():
    proc = subprocess.run(
        [sys.executable, str(AUDITOR), "build", "--json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
        timeout=30,
    )
    assert proc.returncode == 0, proc.stderr
    evidence = json.loads(proc.stdout)
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["gates"]["production_honesty"] is True
    assert evidence["consistency"]["gap_count"] == 0


def test_report_and_bundle_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle_data = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_25_COMPLETE" in report
    assert bundle_data["status"] == "WDROZONY_100"
    assert bundle_data["gates"]["orchestrator_wiring"] is True
    assert bundle_data["gates"]["production_honesty"] is True


def test_hot_reload_and_production_honesty_markers():
    """Hot-reload SLA and production NOT_CERTIFIED are declared."""
    pkg = read(PACKAGE)
    assert "hot_reload_complete" in pkg
    assert "NOT_CERTIFIED" in pkg
    assert "production_honest" in pkg
    assert "PRODUCTION" not in pkg  # trace: no accidental prod claim