#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P23 TESTY REGO + PYTEST + CI — Testy pytest (enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# 1) Mirror logiki pakietu jdg.p23_test_rego_ci_innovations (pokrycie,
#    else-chain, property/fuzz, temporalne/E2E, CI/CD, tarcza testowa).
# 2) Audyt REALNYCH testów i CI (tests/rego, tests/auto, .github/workflows,
#    .pre-commit-config.yaml).
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

from test_rego_ci_auditor import (  # noqa: E402
    CI_GATES_TOTAL,
    COVERAGE_MIN_PCT,
    ELSE_CHAIN_TEST_MIN,
    E2E_SCENARIOS_MIN,
    FUZZ_ITERATIONS,
    LAW_TEST_MIN,
    MUTATION_SCORE_MIN,
    TEMPORAL_TEST_MIN,
    boundary_grosze_tests,
    ci_cd_audit,
    ci_quality_gates,
    coverage_audit,
    coverage_dashboard,
    decision_fuzzer,
    else_chain_audit,
    else_chain_generator,
    e2e_decision_tests,
    fraud_priority_tests,
    indestructible_shield,
    law_change_simulator,
    mutation_analysis,
    negative_tests,
    order_regression_detector,
    property_audit,
    regression_gate,
    shadow_canary_tests,
    temporal_e2e_audit,
    test_generator,
    test_shield,
)

TESTS_REGO_DIR = BASE_DIR / "tests" / "rego"
TESTS_AUTO_DIR = BASE_DIR / "tests" / "auto"
WORKFLOWS_DIR = BASE_DIR.parent / ".github" / "workflows"


# ── Sekcja 1: POKRYCIE TESTAMI ─────────────────────────────────────────────────
def test_coverage_audit():
    res = coverage_audit()
    assert res["audit_type"] == "TEST_COVERAGE"
    assert res["rego_files"] >= 300
    assert res["rego_tests"] >= 50
    assert res["pytest_files"] >= 50
    assert res["auto_block_tests"] >= 20


def test_coverage_real_dirs():
    assert TESTS_REGO_DIR.exists()
    assert TESTS_AUTO_DIR.exists()
    assert len(list(TESTS_REGO_DIR.glob("*.rego"))) >= 50
    assert len(list(TESTS_AUTO_DIR.glob("test_*.py"))) >= 50


def test_test_generator():
    res = test_generator(rules_with_tests=10509, generated=500)
    assert res["generator_mode"] == "FROM_RULE_ID"
    assert res["auto_generate_active"] is True


def test_mutation_analysis():
    res = mutation_analysis(killed=85, total=100)
    assert res["mutation_score"] == 85.0
    assert "MUTACJE NEUTRALIZOWANE" in res["status"]
    assert MUTATION_SCORE_MIN == 70


def test_decision_fuzzer():
    res = decision_fuzzer(crashes=0, inconsistent=0)
    assert res["fuzz_iterations"] == FUZZ_ITERATIONS
    assert res["crashes_found"] == 0


# ── Sekcja 2: ELSE-CHAIN (PRIORYTET ★) ────────────────────────────────────────
def test_else_chain_audit():
    res = else_chain_audit()
    assert res["audit_type"] == "ELSE_CHAIN"
    assert "ELSE-CHAIN" in res["status"]


def test_else_chain_gap():
    # niska liczba testów kolejności → LUKA
    assert ELSE_CHAIN_TEST_MIN == 90.0


def test_else_chain_generator():
    res = else_chain_generator(chains=420, generated=380)
    assert res["generator_mode"] == "ORDER_TEST"
    assert res["auto_generate_active"] is True


def test_order_regression_detector():
    res = order_regression_detector(changes=0)
    assert res["detector_mode"] == "ORDER_REGRESSION"
    assert res["regression_blocked"] is True


# ── Sekcja 3: PROPERTY I FUZZING ───────────────────────────────────────────────
def test_property_audit():
    res = property_audit(property_tests=40, boundary=60, grosze=25, currency=12)
    assert res["audit_type"] == "PROPERTY_FUZZ"
    assert res["grosze_tests"] >= 20


def test_boundary_grosze():
    res = boundary_grosze_tests(verified=True)
    assert "0.005" in res["grosze_cases"]
    assert "EUR" in res["currency_cases"]
    assert res["grosze_rounding_verified"] is True


def test_negative_tests():
    res = negative_tests(packages_with=20, total=24)
    assert res["no_match_coverage_pct"] == 83.33


# ── Sekcja 4: TEMPORALNE I E2E ─────────────────────────────────────────────────
def test_temporal_e2e():
    res = temporal_e2e_audit(temporal=35, e2e=15, law=6)
    assert res["audit_type"] == "TEMPORAL_E2E"
    assert "REGRESJE PRAWNE AKTYWNE" in res["status"]
    assert res["e2e_scenarios_min"] == E2E_SCENARIOS_MIN


def test_law_change_simulator():
    res = law_change_simulator(law_tests=6, verified=True)
    assert res["simulator_mode"] == "LAW_REGRESSION"
    assert res["impact_verified"] is True
    assert res["law_tests_min"] == LAW_TEST_MIN


def test_fraud_priority_tests():
    res = fraud_priority_tests(fraud=18, priority=22, facts=14)
    assert res["fraud_graph_tests"] == 18
    assert res["fraud_scenarios_covered"] is True


def test_temporal_real_files():
    tests = {p.name for p in (BASE_DIR / "tests").glob("test_*.py")}
    for expected in ["test_temporal_validity.py", "test_tax_pipeline.py",
                     "test_fraud_graph_scanner.py", "test_priority_engine.py"]:
        assert expected in tests, f"brakuje testu: {expected}"


# ── Sekcja 5: CI/CD I QUALITY-GATES ───────────────────────────────────────────
def test_ci_cd_audit():
    res = ci_cd_audit()
    assert res["audit_type"] == "CI_CD"
    assert res["workflows_count"] >= 5
    assert res["quality_gates_total"] == CI_GATES_TOTAL
    assert res["precommit_active"] is True


def test_ci_real_workflows():
    workflows = {p.name for p in WORKFLOWS_DIR.glob("*.yml")}
    for expected in ["ci.yml", "jdg-quality-gates-blocking.yml", "opa-ci.yml"]:
        assert expected in workflows, f"brakuje workflow: {expected}"


def test_ci_quality_gates():
    res = ci_quality_gates(gates_passed=6)
    assert len(res["gates"]) == 6
    assert "CI ZIELONY" in res["status"]
    assert res["block_on_fail"] is True


def test_precommit_exists():
    assert (BASE_DIR.parent / ".pre-commit-config.yaml").exists()


def test_shadow_canary_tests():
    res = shadow_canary_tests(match_rate=0.98)
    assert res["shadow_mode"] == "PROD_SHADOW"
    assert res["shadow_match_rate"] == 0.98


# ── Sekcja 6: TARCZA TESTOWA ───────────────────────────────────────────────────
def test_test_shield():
    res = test_shield(active=True)
    assert res["shield_mode"] == "LEGAL_REGRESSION"
    assert res["first_line_defense"] is True
    assert res["regression_gate_active"] is True


# ── Sekcja 7: INN-12..INN-15 ───────────────────────────────────────────────────
def test_coverage_dashboard():
    res = coverage_dashboard(real_time=True, alerting=True)
    assert len(res["metrics"]) == 6
    assert res["alerting"] is True


def test_regression_gate():
    res = regression_gate(blocked=False)
    assert res["gate_mode"] == "CI_REGRESSION"
    assert res["gate_on_every_pr"] is True


def test_e2e_decision_tests():
    res = e2e_decision_tests(scenarios=15)
    assert res["e2e_scenarios"] >= E2E_SCENARIOS_MIN
    assert res["provenance_checked"] is True


def test_indestructible_shield():
    res = indestructible_shield(active=True)
    assert len(res["shield_chain"]) == 6
    assert res["shield_chain"][-1] == "regression"
    assert res["chain_min_coverage"] == COVERAGE_MIN_PCT


# ── WIRING: P23 wpięty w main_jdg.rego ────────────────────────────────────────
def test_p23_wiring_in_main():
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p23_test_rego_ci_innovations" in main
    assert '"jdg.p23_test_rego_ci_innovations": p23_test_rego_ci_innovations.decide' in main
    assert "final_verdict_p23 = safe_merge(final_verdict_p22," in main


# ── KOMPLETNOŚĆ PLIKÓW ────────────────────────────────────────────────────────
def test_p23_files_exist():
    expected = [
        BASE_DIR / "rules" / "p23_test_rego_ci_innovations_v9.rego",
        BASE_DIR / "tools" / "test_rego_ci_auditor.py",
        TESTS_REGO_DIR / "test_p23_test_rego_ci_enterprise.rego",
        BASE_DIR / "docs" / "TESTY_REGO_CI_P23.md",
        BASE_DIR.parent / "raporty_jdg_enterprise" / "R23_Testy_Rego_CI.txt",
    ]
    for path in expected:
        assert path.exists(), f"brakuje pliku: {path}"


def test_p23_rego_package_name():
    text = (BASE_DIR / "rules" / "p23_test_rego_ci_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p23_test_rego_ci_innovations" in text
    assert "INN-01" in text and "INN-15" in text
    assert "indestructible_shield" in text
    assert "else_chain_audit" in text


def test_p23_no_collision_with_old():
    old = (BASE_DIR / "rules" / "p23_innovations_enterprise.rego").read_text(encoding="utf-8") if (BASE_DIR / "rules" / "p23_innovations_enterprise.rego").exists() else ""
    new = (BASE_DIR / "rules" / "p23_test_rego_ci_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p23_innovations" not in new
    assert "package jdg.p23_test_rego_ci_innovations" in new
    assert old  # stary pakiet v7 nadal istnieje


def test_p23_smoke_cli():
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "test_rego_ci_auditor.py"), "--audit", "--mutation", "--ci-gates"],
        capture_output=True, text=True, cwd=BASE_DIR.parent, timeout=60,
    )
    assert proc.returncode == 0, proc.stderr
    out = json.loads(proc.stdout)
    assert "coverage" in out["audit"]
    assert "TEST_COVERAGE" == out["audit"]["coverage"]["audit_type"]
    assert "MUTACJE NEUTRALIZOWANE" in out["mutation_analysis"]["status"]
    assert "CI ZIELONY" in out["ci_quality_gates"]["status"]
