#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P21 OPA JAKO SYSTEM — Testy pytest (enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# 1) Mirror logiki pakietu jdg.p21_opa_system_innovations (bundle, policies,
#    API, migracje, cykl życia reguły, odporność, INN-01..15).
# 2) Audyt REALNYCH plików infrastruktury OPA (bundle.sh, manifest.json,
#    policies/jdg, policies/tax, openapi.yaml, migracje SQL, narzędzia).
# ═══════════════════════════════════════════════════════════════════════════════
import json
import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

from opa_system_auditor import (  # noqa: E402
    CANARY_PERCENT,
    DRIFT_ALERT_PERCENT,
    LEGISLATIVE_ADAPT_HOURS,
    ROLLBACK_ERROR_THRESHOLD,
    ROLLBACK_QUALITY_THRESHOLD,
    TEMPORAL_VERSIONS_KEEP,
    audit_api_migrations,
    audit_bundle,
    audit_policies,
    audit_tools,
    auto_sync_policies,
    bundle_signature,
    canary_deploy,
    control_tower,
    decision_quality_monitor,
    isap_drift_alarm,
    legal_adaptation_24h,
    legal_change_simulator,
    resilience_audit,
    rule_change_proof,
    rule_feature_flags,
    rule_lifecycle_pipeline,
    rule_registry_api,
    self_healing,
    shadow_deployment,
    system_observability,
    temporal_migration,
)

RULES_DIR = BASE_DIR / "rules"
POLICIES_DIR = BASE_DIR.parent / "policies"


# ── Sekcja 1: BUNDLE I DEPLOYMENT ──────────────────────────────────────────────
def test_bundle_audit_ok():
    res = audit_bundle()
    assert res["audit_type"] == "BUNDLE_DEPLOYMENT"
    assert res["name_collisions"] == 0  # fix R1 — struktura katalogów
    assert res["files_count"] >= 100
    assert "BUNDLE OK" in res["status"]


def test_bundle_real_files():
    assert (BASE_DIR / "bundles" / "bundle.sh").exists()
    assert (BASE_DIR / "bundles" / "manifest.json").exists()


def test_bundle_manifest_counts():
    manifest = json.loads((BASE_DIR / "bundles" / "manifest.json").read_text(encoding="utf-8"))
    meta = manifest["metadata"]
    assert meta["rules_count"] >= 10000
    assert meta["files_count"] >= 100
    assert meta["unique_rule_ids"] >= 9000


def test_canary_deploy_approved():
    res = canary_deploy(canary_active=True, quality_score=0.98, error_rate=0.001)
    assert res["deploy_mode"] == "CANARY_ZERO_DOWNTIME"
    assert "DEPLOY ZATWIERDZONY" in res["status"]
    assert res["canary_percent"] == CANARY_PERCENT


def test_canary_auto_rollback():
    res = canary_deploy(canary_active=True, quality_score=0.90, error_rate=0.02)
    assert "AUTO-ROLLBACK" in res["status"]


def test_canary_thresholds():
    assert ROLLBACK_QUALITY_THRESHOLD == 0.95
    assert ROLLBACK_ERROR_THRESHOLD == 0.01


def test_shadow_deployment_delta():
    res = shadow_deployment(match_production=0.97, shadow_match=0.96)
    assert res["verdict_delta"] == 0.01
    assert res["shadow_accepted"] is True


def test_bundle_signature():
    res = bundle_signature(verified=True)
    assert res["signature_verified"] is True
    assert res["algorithm"] == "SHA256"


# ── Sekcja 2: POLICIES DRIFT ───────────────────────────────────────────────────
def test_policies_drift_ok():
    res = audit_policies()
    assert res["audit_type"] == "POLICIES_DRIFT"
    assert "SYNC OK" in res["status"]
    assert res["drift_percent"] < DRIFT_ALERT_PERCENT


def test_policies_real_files():
    assert (POLICIES_DIR / "jdg").exists()
    assert (POLICIES_DIR / "tax").exists()
    assert (POLICIES_DIR / "data" / "thresholds_sc.rego").exists()
    assert (POLICIES_DIR / "Makefile").exists()
    assert (POLICIES_DIR / "bundle.sh").exists()


def test_auto_sync_policies():
    res = auto_sync_policies(enabled=True)
    assert res["source_of_truth"] == "JDG/rules"
    assert "policies/jdg" in res["sync_targets"]
    assert res["sync_interval_hours"] == 24


# ── Sekcja 3: API I MIGRACJE ───────────────────────────────────────────────────
def test_api_migration_audit():
    res = audit_api_migrations()
    assert res["api_endpoints_count"] >= 3
    assert res["docs_sync_ok"] is True
    assert res["migrations_count"] >= 2
    assert res["rule_versions_table"] is True
    assert res["verdict_audit_table"] is True


def test_api_real_files():
    assert (BASE_DIR / "api" / "openapi.yaml").exists()
    assert (BASE_DIR / "docs" / "api.md").exists()
    assert (BASE_DIR / "migrations" / "001_jdg_rule_store.sql").exists()
    assert (BASE_DIR / "migrations" / "002_jdg_enterprise_v7.sql").exists()


def test_migration_sql_tables():
    sql1 = (BASE_DIR / "migrations" / "001_jdg_rule_store.sql").read_text(encoding="utf-8")
    assert "jdg_tax_thresholds" in sql1
    assert "rule_versions" in sql1
    assert "jdg_verdict_audit" in sql1
    assert "isap_history" in sql1
    sql2 = (BASE_DIR / "migrations" / "002_jdg_enterprise_v7.sql").read_text(encoding="utf-8")
    assert "jdg_prediction_history" in sql2


def test_temporal_migration_ok():
    res = temporal_migration(versions_kept=3)
    assert "MIGRACJA TEMPORALNA OK" in res["status"]
    assert res["max_versions"] == TEMPORAL_VERSIONS_KEEP


def test_temporal_migration_truncate():
    res = temporal_migration(versions_kept=7)
    assert "TRUNCATE TEMPORAL" in res["status"]


# ── Sekcja 4: CONTROL TOWER ────────────────────────────────────────────────────
def test_tools_audit():
    res = audit_tools()
    assert res["tools_count"] >= 50
    assert res["tools_passed"] == res["tools_count"]
    assert res["tools_failed"] == 0
    assert res["control_tower_active"] is True


def test_tools_real_validation_tools():
    tools = {p.name for p in (BASE_DIR / "tools").glob("*.py")}
    for expected in ["validate_rules.py", "lint_rego_rules.py", "cross_ref_validator.py",
                     "dead_rule_detector.py", "tautology_guard.py", "hardcoded_audit.py",
                     "zero_defect_certification.py", "self_healing_engine.py",
                     "adaptive_trust_score.py", "isap_drift_alarm.py"]:
        assert expected in tools, f"brakuje narzędzia: {expected}"


def test_control_tower():
    res = control_tower(gates_passed=7, gates_total=7)
    assert len(res["quality_gates"]) == 7
    assert res["zero_defect_certified"] is True
    assert res["block_on_fail"] is True


# ── Sekcja 5: CYKL ŻYCIA REGUŁY ────────────────────────────────────────────────
def test_rule_lifecycle_pipeline():
    res = rule_lifecycle_pipeline(current_step="MONITORING", blocked=False)
    assert len(res["pipeline"]) == 11
    assert res["pipeline"][0] == "ISAP"
    assert res["pipeline"][-1] == "ROLLBACK"
    assert "PIPELINE AKTYWNY" in res["status"]


def test_rule_lifecycle_blocked():
    res = rule_lifecycle_pipeline(current_step="WALIDACJA_SKLADNI", blocked=True)
    assert "BLOKADA PIPELINE" in res["status"]


# ── Sekcja 6: ODPORNOŚĆ ────────────────────────────────────────────────────────
def test_resilience_primary():
    res = resilience_audit(fallback_active=False, retry=0)
    assert "PRIMARY OK" in res["status"]
    assert res["circuit_breaker"] is True


def test_resilience_fallback():
    res = resilience_audit(fallback_active=True, retry=3)
    assert "FALLBACK AKTYWNY" in res["status"]


# ── Sekcja 7: INN-01..INN-15 ───────────────────────────────────────────────────
def test_legal_adaptation_24h():
    res = legal_adaptation_24h(bundle_rebuilt=True)
    assert res["target_hours"] == LEGISLATIVE_ADAPT_HOURS
    assert res["rules_regenerated"] is True
    assert res["bundle_rebuilt"] is True


def test_legal_change_simulator():
    res = legal_change_simulator(rules_affected=12, portfolio=1000)
    assert res["affected_share_pct"] == 1.2
    assert res["severity_high"] is False


def test_rule_registry_api():
    res = rule_registry_api(rules_exposed=10878)
    assert res["registry_endpoint"] == "/v1/rules"
    assert res["rules_exposed"] >= 10000


def test_rule_feature_flags():
    res = rule_feature_flags(flags_count=15, shadow_rules=2)
    assert res["flag_default"] == "ON"
    assert res["kill_switch_available"] is True


def test_rule_change_proof():
    res = rule_change_proof(prev="0x0000", current="0xabcd")
    assert res["proof_mode"] == "HASH_CHAIN"
    assert res["chain_integrity"] is True


def test_decision_quality_monitor():
    res = decision_quality_monitor(quality=0.97, decisions=5000, anomalies=0)
    assert res["quality_score"] == 0.97
    assert res["quality_threshold"] == ROLLBACK_QUALITY_THRESHOLD


def test_isap_drift_alarm():
    res = isap_drift_alarm(new_regs=1, amended=0)
    assert res["drift_detected"] is True


def test_self_healing():
    res = self_healing(fixed=3, escalated=0)
    assert res["healing_mode"] == "AUTO"
    assert res["healing_active"] is True


def test_system_observability():
    res = system_observability(latency_ms=5.0, fallback_rate=0.001, rollbacks=0)
    assert res["latency_p95_ms"] == 5.0
    assert res["fallback_rate"] == 0.001


# ── WIRING: P21 wpięty w main_jdg.rego ────────────────────────────────────────
def test_p21_wiring_in_main():
    main = (RULES_DIR / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p21_opa_system_innovations" in main
    assert '"jdg.p21_opa_system_innovations": p21_opa_system_innovations.decide' in main
    assert "final_verdict_p21 = safe_merge(final_verdict_p20," in main


# ── KOMPLETNOŚĆ PLIKÓW ────────────────────────────────────────────────────────
def test_p21_files_exist():
    expected = [
        RULES_DIR / "p21_opa_system_innovations_v9.rego",
        BASE_DIR / "tools" / "opa_system_auditor.py",
        BASE_DIR / "tests" / "rego" / "test_p21_opa_system_enterprise.rego",
        BASE_DIR / "docs" / "OPA_JAKO_SYSTEM_P21.md",
        BASE_DIR.parent / "raporty_jdg_enterprise" / "R21_OPA_jako_System.txt",
    ]
    for path in expected:
        assert path.exists(), f"brakuje pliku: {path}"


def test_p21_rego_package_name():
    text = (RULES_DIR / "p21_opa_system_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p21_opa_system_innovations" in text
    assert "INN-01" in text and "INN-15" in text
    assert "rule_lifecycle_pipeline" in text
    assert "resilience_audit" in text


def test_p21_no_collision_with_old():
    old = (RULES_DIR / "p21_innovations_enterprise.rego").read_text(encoding="utf-8") if (RULES_DIR / "p21_innovations_enterprise.rego").exists() else ""
    new = (RULES_DIR / "p21_opa_system_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p21_innovations" not in new
    assert "package jdg.p21_opa_system_innovations" in new
    assert old  # stary pakiet v7 nadal istnieje


def test_p21_smoke_cli():
    import subprocess
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "opa_system_auditor.py"), "--audit", "--canary", "--pipeline"],
        capture_output=True, text=True, cwd=BASE_DIR.parent, timeout=60,
    )
    assert proc.returncode == 0, proc.stderr
    out = json.loads(proc.stdout)
    assert "bundle" in out["audit"]
    assert "POLICIES_DRIFT" == out["audit"]["policies"]["audit_type"]
    assert "DEPLOY ZATWIERDZONY" in out["canary_deploy"]["status"]
