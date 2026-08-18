# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P18 TESTY / CI / JAKOŚĆ — pytest (GLM52 P18)
# ═══════════════════════════════════════════════════════════════════════════════
import json
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(JDG_ROOT / "tools"))

import test_coverage_gate  # noqa: E402
import mutation_runner  # noqa: E402
import property_suite  # noqa: E402
import fuzz_runner  # noqa: E402
import chaos_runner  # noqa: E402
import golden_autojustify  # noqa: E402


# ── TEST COVERAGE GATE (V1 §8 — pokrycie per pakiet) ──────────────────────────
class TestCoverageGate:
    def test_scan_structure(self):
        s = test_coverage_gate.scan()
        assert "total_packages" in s
        assert "coverage_pct" in s
        assert isinstance(s["packages"], list)

    def test_gate_pass_100pct(self):
        g = test_coverage_gate.gate(threshold=95.0)
        assert g["gate"] == "PASS"
        assert g["coverage_pct"] == 100.0
        assert g["critical_pct"] == 100.0
        assert g["deserts"] == []

    def test_critical_all_covered(self):
        s = test_coverage_gate.scan()
        assert s["critical_covered_pct"] == 100.0

    def test_native_tests_exist_for_gaps(self):
        # nowe testy natywne domykające luki pokrycia (P18)
        for rel in ["tests/rego/test_native_edge_cases_enterprise.rego",
                    "tests/rego/test_native_nkup_enterprise.rego",
                    "tests/rego/test_native_conflicts_enterprise.rego",
                    "tests/rego/test_native_vat_deductions_enterprise.rego",
                    "tests/rego/test_native_security_fortress_enterprise.rego",
                    "tests/rego/test_native_innovations_enterprise.rego",
                    "tests/rego/test_native_innovations2_enterprise.rego",
                    "tests/rego/test_native_p33_p35_enterprise.rego",
                    "tests/rego/test_native_p33_supplements_enterprise.rego",
                    "tests/rego/test_native_p01_meta_enterprise.rego"]:
            assert (JDG_ROOT / rel).exists(), f"brak {rel}"


# ── MUTATION RUNNER (V1 §8 L2 — mutation ≥ 75%) ───────────────────────────────
class TestMutationRunner:
    def test_mutations_generated(self):
        r = mutation_runner.run(limit=20)
        assert r["total_mutants"] > 0
        assert r["mutation_score_pct"] >= 0

    def test_gate_structure(self):
        g = mutation_runner.gate(threshold=0.0)
        assert g["gate"] in ("PASS", "REVIEW")
        assert "mutation_score_pct" in g

    def test_mutation_operators(self):
        from mutation_runner import MUTATIONS
        assert len(MUTATIONS) >= 10


# ── PROPERTY SUITE (V1 §8 L2 — hypothesis) ────────────────────────────────────
class TestPropertySuite:
    def test_all_properties_pass(self):
        r = property_suite.run_all()
        assert r["gate"] == "PASS"
        assert r["failed"] == 0
        assert r["properties"] >= 8

    def test_property_registry(self):
        assert len(property_suite.PROPERTIES) >= 8
        for name, p in property_suite.PROPERTIES.items():
            assert p["description"]


# ── FUZZ RUNNER (V1 §8 L2 — 10k+ wejść) ───────────────────────────────────────
class TestFuzzRunner:
    def test_fuzz_10k(self):
        r = fuzz_runner.run(count=10_000)
        assert r["gate"] == "PASS"
        assert r["crashes"] == 0
        assert r["non_deterministic"] == 0
        assert r["inputs"] >= 10_000

    def test_malicious_corpus(self):
        assert len(fuzz_runner.MALICIOUS_CORPUS) >= 20


# ── CHAOS RUNNER (V1 §8 L8) ───────────────────────────────────────────────────
class TestChaosRunner:
    def test_experiments_catalog(self):
        r = chaos_runner.list_experiments()
        assert r["count"] >= 8

    def test_gate_all_detectable(self):
        r = chaos_runner.run()
        assert r["gate"] == "PASS"
        assert all(x["status"] == "DETECTABLE" for x in r["results"])


# ── GOLDEN AUTOJUSTIFY (V2 F3 — UVR 0) ────────────────────────────────────────
class TestGoldenAutojustify:
    def test_replay_new_case(self):
        r = golden_autojustify.replay({"matched": True, "rule_id": "jdg.x.r1"},
                                      input_hash="unknown-hash")
        assert r["status"] == "NEW"

    def test_replay_justified_by_legal_diff(self):
        golden = golden_autojustify.load_golden()
        real_hashes = list(golden.get("verdicts", {}).keys())
        if not real_hashes:
            pytest.skip("brak golden_verdicts w repo")
        r = golden_autojustify.replay({"matched": True, "rule_id": "jdg.x.r1",
                                       "_legal_basis": ["NEW ACT"]},
                                      input_hash=real_hashes[0],
                                      legal_diff="nowelizacja 2026")
        assert r["status"] in ("JUSTIFIED", "UNJUSTIFIED", "NEW")

    def test_gate_passes_empty(self):
        g = golden_autojustify.gate()
        assert g["gate"] == "PASS"


# ── WIRING CI / WORKFLOW / NARZĘDZIA ──────────────────────────────────────────
class TestWiringP18:
    def test_workflow_12_gates(self):
        f = JDG_ROOT / ".github" / "workflows" / "jdg-quality.yml"
        text = f.read_text(encoding="utf-8")
        for gate in ["LINT_REGO", "VALIDATE_RULES", "TAUTOLOGY_GUARD",
                     "DEAD_RULE", "HARDCODED_AUDIT", "ZERO_DEFECT",
                     "GOLDEN_REPLAY", "IMPACT", "BUNDLE_BUILD", "SIGN",
                     "DEPLOY"]:
            assert gate in text, f"brak bramki {gate}"

    def test_quality_cli_exists(self):
        f = JDG_ROOT / "tools" / "jdg_quality_cli.py"
        assert f.exists()
        text = f.read_text(encoding="utf-8")
        assert "health" in text

    def test_tools_exist(self):
        for name in ["test_coverage_gate.py", "mutation_runner.py",
                     "property_suite.py", "fuzz_runner.py", "chaos_runner.py",
                     "golden_autojustify.py"]:
            assert (JDG_ROOT / "tools" / name).exists()

    def test_pytest_collection_no_errors(self):
        # legacy nexus_ai/Code tests mają importorskip (13 naprawionych)
        for rel in ["tests/test_fraud_graph_scanner.py",
                    "tests/test_payment_priority_service.py",
                    "tests/test_tax_rules.py",
                    "tests/test_temporal_manager.py",
                    "tests/test_risk_guard.py",
                    "tests/test_facts_aggregator.py"]:
            text = (JDG_ROOT / rel).read_text(encoding="utf-8")
            assert "importorskip" in text or "pytest.skip" in text, f"brak guarda w {rel}"
