#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P22 NARZĘDZIA WALIDACJI I JAKOŚCI — Testy pytest (enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# 1) Mirror logiki pakietu jdg.p22_validation_tools_innovations (manifest,
#    detektory, zero-defect, impact, chaos, pipeline jakości, INN-01..15).
# 2) Audyt REALNYCH narzędzi walidacji (validate_rules, dead_rule_detector,
#    zero_defect_certification, chaos_engineering, manifest.json).
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

from validation_tools_auditor import (  # noqa: E402
    CERTIFICATION_MIN_SCORE,
    CHAOS_SCENARIOS,
    COVERAGE_MIN_PCT,
    LEGAL_BASIS_CONFIDENCE_MIN,
    MANIFEST_MIN_RULES,
    SELF_HEALING_MAX_FIXES,
    ZERO_DEFECT_GATES,
    audit_detectors,
    audit_manifest,
    auto_rule_correction,
    chaos_engineering,
    ci_gate_rules,
    digital_twin,
    enterprise_certificate,
    impact_analysis_audit,
    impact_matrix,
    legal_regression_detector,
    predictive_audit_shield,
    quality_dashboard,
    quality_pipeline,
    real_time_manifest,
    rule_fuzzer,
    rule_provenance,
    self_healing,
    self_learning_legal_validator,
    semantic_detection,
    simulators_audit,
    zero_defect_audit,
)

RULES_DIR = BASE_DIR / "rules"
TOOLS_DIR = BASE_DIR / "tools"


# ── Sekcja 1: MANIFEST I POKRYCIE ──────────────────────────────────────────────
def test_manifest_audit():
    res = audit_manifest()
    assert res["audit_type"] == "MANIFEST_COVERAGE"
    assert res["unique_rule_ids"] >= 10000
    assert res["files_count"] >= 300
    assert "MANIFEST OK" in res["status"]


def test_manifest_real_file():
    assert (BASE_DIR / "bundles" / "manifest.json").exists()
    manifest = json.loads((BASE_DIR / "bundles" / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["metadata"]["rules_count"] >= 10000
    assert manifest["metadata"]["unique_rule_ids"] >= 9000


def test_ci_gate_rules():
    res = ci_gate_rules(current_rules=10509)
    assert res["gate_type"] == "RULES_COUNT_GATE"
    assert res["min_rules"] == MANIFEST_MIN_RULES
    assert res["gate_passed"] is True


def test_real_time_manifest():
    res = real_time_manifest(auto=True)
    assert res["manifest_mode"] == "REAL_TIME"
    assert res["auto_regenerate"] is True


# ── Sekcja 2: DETEKTORY (PRIORYTET ★) ─────────────────────────────────────────
def test_detectors_audit():
    res = audit_detectors()
    assert res["audit_type"] == "DETECTORS"
    assert res["detector_active"] is True
    assert res["hardcoded_values"] >= 100  # 265 hardcode'ów


def test_detectors_real_tools():
    tools = {p.name for p in TOOLS_DIR.glob("*.py")}
    for expected in ["dead_rule_detector.py", "tautology_guard.py", "hardcoded_audit.py",
                     "cross_package_conflict_detector.py", "else_chain_dead_code_detector.py",
                     "temporal_drift_detector.py"]:
        assert expected in tools, f"brakuje narzędzia: {expected}"


def test_semantic_detection():
    res = semantic_detection(dataflow=True, pbt=True, fuzzing=True)
    assert res["detection_mode"] == "SEMANTIC"
    assert res["property_based_testing"] is True


def test_rule_fuzzer():
    res = rule_fuzzer(iterations=10000, crashes=0, unexpected=0)
    assert res["fuzz_iterations"] == 10000
    assert res["crashes_found"] == 0


# ── Sekcja 3: ZERO-DEFECT I SELF-HEALING ──────────────────────────────────────
def test_zero_defect_audit():
    res = zero_defect_audit(gates_passed=7, score=100)
    assert res["audit_type"] == "ZERO_DEFECT"
    assert res["certification_gates"] == ZERO_DEFECT_GATES
    assert res["enterprise_certified"] is True
    assert "ENTERPRISE-CERTIFIED" in res["status"]


def test_zero_defect_not_certified():
    res = zero_defect_audit(gates_passed=5, score=80)
    assert res["enterprise_certified"] is False
    assert "NIE ZCERTYFIKOWANY" in res["status"]
    assert CERTIFICATION_MIN_SCORE == 100


def test_zero_defect_real_tool():
    assert (TOOLS_DIR / "zero_defect_certification.py").exists()


def test_enterprise_certificate():
    res = enterprise_certificate(certified=10878, total=10878)
    assert res["certificate_type"] == "ENTERPRISE-CERTIFIED"
    assert res["per_rule"] is True
    assert res["certification_coverage_pct"] == 100.0


def test_self_healing():
    res = self_healing(fixed=4, escalated=1)
    assert res["healing_mode"] == "AUTO_CORRECT"
    assert res["max_fixes_per_cycle"] == SELF_HEALING_MAX_FIXES


def test_self_learning_legal_validator():
    res = self_learning_legal_validator(confidence=0.95)
    assert res["validator_passed"] is True
    assert res["confidence_min"] == LEGAL_BASIS_CONFIDENCE_MIN


# ── Sekcja 4: ANALIZA WPŁYWU ZMIAN PRAWA ──────────────────────────────────────
def test_impact_analysis():
    res = impact_analysis_audit(rules_affected=12)
    assert res["audit_type"] == "LEGAL_IMPACT"
    assert "ŚREDNI WPŁYW" in res["status"]


def test_impact_matrix():
    res = impact_matrix(rules_affected=25, act="Ustawa o VAT")
    assert res["matrix_type"] == "LEGAL_CHANGE"
    assert "WYSOKI WPŁYW" in res["priority"]


def test_legal_regression_detector():
    res = legal_regression_detector(drift=False, new_regs=0, amended=0)
    assert res["regression_mode"] == "ISAP_DRIFT"
    assert res["isap_drift_detected"] is False


def test_impact_real_tools():
    tools = {p.name for p in TOOLS_DIR.glob("*.py")}
    for expected in ["legal_change_impact_analyzer.py", "isap_drift_alarm.py",
                     "migration_impact_analyzer.py", "judgment_predictor.py"]:
        assert expected in tools, f"brakuje narzędzia: {expected}"


# ── Sekcja 5: SYMULATORY I CHAOS ENGINEERING ──────────────────────────────────
def test_simulators_audit():
    res = simulators_audit(scenarios_covered=8)
    assert res["audit_type"] == "SIMULATORS_CHAOS"
    assert "POKRYCIE KOMPLETNE" in res["status"]
    assert res["chaos_scenarios_total"] == CHAOS_SCENARIOS


def test_digital_twin():
    res = digital_twin(match_rate=0.97)
    assert res["twin_mode"] == "DIGITAL_TWIN"
    assert res["twin_drift_detected"] is False


def test_chaos_engineering():
    res = chaos_engineering(scenarios_covered=8, recovery_ms=120)
    assert res["chaos_mode"] == "FAULT_INJECTION"
    assert "POKRYCIE KOMPLETNE" in res["status"]


def test_predictive_audit_shield():
    res = predictive_audit_shield(risk=0.8, likelihood=0.3)
    assert res["high_risk_flagged"] is True


def test_simulators_real_tools():
    tools = {p.name for p in TOOLS_DIR.glob("*.py")}
    for expected in ["digital_twin_simulator.py", "rule_impact_simulator.py",
                     "chaos_engineering.py", "predictive_audit_shield.py"]:
        assert expected in tools, f"brakuje narzędzia: {expected}"


# ── Sekcja 6: PIPELINE JAKOŚCI ────────────────────────────────────────────────
def test_quality_pipeline():
    res = quality_pipeline(gates_passed=8)
    assert len(res["pipeline"]) == 9
    assert res["pipeline"][0] == "LINT"
    assert res["pipeline"][-1] == "PRODUCTION"
    assert "PIPELINE ZIELONY" in res["status"]


def test_quality_pipeline_blocked():
    res = quality_pipeline(gates_passed=5)
    assert "PIPELINE BLOKADA" in res["status"]


# ── Sekcja 7: INN-13..INN-15 ───────────────────────────────────────────────────
def test_auto_rule_correction():
    res = auto_rule_correction(applied=4, reviewed=4)
    assert res["correction_mode"] == "FROM_REPORTS"
    assert len(res["reports_source"]) == 4


def test_quality_dashboard():
    res = quality_dashboard(real_time=True, alerting=True)
    assert len(res["metrics"]) == 6
    assert res["alerting"] is True


def test_rule_provenance():
    res = rule_provenance(tracked=10878)
    assert res["provenance_mode"] == "RULE_DNA"
    assert res["lineage_chain"] is True


# ── WIRING: P22 wpięty w main_jdg.rego ────────────────────────────────────────
def test_p22_wiring_in_main():
    main = (RULES_DIR / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p22_validation_tools_innovations" in main
    assert '"jdg.p22_validation_tools_innovations": p22_validation_tools_innovations.decide' in main
    assert "final_verdict_p22 = safe_merge(final_verdict_p21," in main


# ── KOMPLETNOŚĆ PLIKÓW ────────────────────────────────────────────────────────
def test_p22_files_exist():
    expected = [
        RULES_DIR / "p22_validation_tools_innovations_v9.rego",
        TOOLS_DIR / "validation_tools_auditor.py",
        BASE_DIR / "tests" / "rego" / "test_p22_validation_tools_enterprise.rego",
        BASE_DIR / "docs" / "NARZEDZIA_WALIDACJI_P22.md",
        BASE_DIR.parent / "raporty_jdg_enterprise" / "R22_Narzedzia_Walidacji.txt",
    ]
    for path in expected:
        assert path.exists(), f"brakuje pliku: {path}"


def test_p22_rego_package_name():
    text = (RULES_DIR / "p22_validation_tools_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p22_validation_tools_innovations" in text
    assert "INN-01" in text and "INN-15" in text
    assert "quality_pipeline" in text
    assert "zero_defect_audit" in text


def test_p22_no_collision_with_old():
    old = (RULES_DIR / "p22_innovations_enterprise.rego").read_text(encoding="utf-8") if (RULES_DIR / "p22_innovations_enterprise.rego").exists() else ""
    new = (RULES_DIR / "p22_validation_tools_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p22_innovations" not in new
    assert "package jdg.p22_validation_tools_innovations" in new
    assert old  # stary pakiet v7 nadal istnieje


def test_p22_smoke_cli():
    proc = subprocess.run(
        [sys.executable, str(TOOLS_DIR / "validation_tools_auditor.py"), "--audit", "--ci-gate", "--pipeline"],
        capture_output=True, text=True, cwd=BASE_DIR.parent, timeout=60,
    )
    assert proc.returncode == 0, proc.stderr
    out = json.loads(proc.stdout)
    assert "manifest" in out["audit"]
    assert "MANIFEST_COVERAGE" == out["audit"]["manifest"]["audit_type"]
    assert out["ci_gate_rules"]["gate_passed"] is True
    assert "PIPELINE ZIELONY" in out["quality_pipeline"]["status"]
