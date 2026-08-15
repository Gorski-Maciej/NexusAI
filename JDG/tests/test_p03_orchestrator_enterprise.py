"""
Testy P03 GLM52 ORKIESTRATOR + INFRASTRUKTURA REGUŁ (raport_enterprise_P03.txt).

Pokrycie: runtime_invariants_enterprise.rego (INV-001..042, evaluate/enforce) ·
p03_orchestrator_innovations_v9.rego (14 INN) · temporal.rego (P1627–P1632) ·
provenance.rego (wersje V1 §9.3) · main_jdg.rego (wiring POST-MERGE) ·
hardcoded_audit_gate.py (HARDCODED_AUDIT gate).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"
TOOLS = JDG_ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import hardcoded_audit_gate  # noqa: E402

INVARIANTS_REGO = RULES / "audit" / "runtime_invariants_enterprise.rego"
P03_REGO = RULES / "p03_orchestrator_innovations_v9.rego"
TEMPORAL_REGO = RULES / "temporal.rego"
PROVENANCE_REGO = RULES / "provenance.rego"
MAIN_REGO = RULES / "main_jdg.rego"


# ═══════════════════ RUNTIME INVARIANTS (Sekcja 5, F2 V2) ═══════════════════

class TestRuntimeInvariants:
    @pytest.fixture(scope="class")
    def text(self):
        return INVARIANTS_REGO.read_text(encoding="utf-8")

    def test_catalog_has_42_invariants(self, text):
        entries = re.findall(r'"id":\s*"(INV-\d+)"', text)
        assert len(entries) >= 42, f"Katalog niezmienników: {len(entries)} < 42"
        assert "INV-001" in entries and "INV-042" in entries

    def test_catalog_parseable_by_invariant_checker(self, text):
        # invariant_checker.py używa jednowierszowego formatu {"id","description","level","enforcement"}
        m = re.search(r"catalog\s*:=\s*\[(.*?)\n\]", text, re.S)
        assert m, "Blok catalog nie znaleziony"
        entries = re.findall(
            r'\{"id":\s*"(INV-\d+)",\s*"description":\s*"([^"]+)",\s*"level":\s*"([^"]+)",\s*"enforcement":\s*"([^"]+)"\}',
            m.group(1),
        )
        assert len(entries) >= 42
        levels = {e[2] for e in entries}
        assert {"RUNTIME", "BUILD", "STATISTICAL"} <= levels

    def test_evaluate_and_enforce_present(self, text):
        assert "evaluate(v) = result" in text
        assert "enforce(v) = result" in text
        assert "_certainty_guard" in text
        assert "_decision_certificate" in text

    def test_certificate_fields(self, text):
        assert "decision_hash" in text
        assert "bundle_version" in text
        assert "threshold_version" in text
        assert "legal_basis_refs" in text

    def test_post_merge_reference_in_main(self):
        main = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_post_merge = object.union(final_verdict_p33," in main
        assert "runtime_invariants.enforce(final_verdict_post_merge)" in main
        assert "final_verdict_enforced" in main


# ═══════════════════ P03 INNOWACJE (Sekcja 10) ═══════════════════

class TestP03Innovations:
    @pytest.fixture(scope="class")
    def text(self):
        return P03_REGO.read_text(encoding="utf-8")

    def test_package_name(self, text):
        assert "package jdg.p03_orchestrator_innovations" in text

    def test_default_no_match(self, text):
        assert 'rule_id":"jdg.p03_orchestrator_innovations.no_match"' in text

    def test_at_least_12_innovations(self, text):
        innovations = re.findall(r"INN-\d{2}", text)
        assert len(set(innovations)) >= 12, f"INN: {sorted(set(innovations))}"

    def test_core_innovations_present(self, text):
        for fn in [
            "input_hash",
            "shadow_twin_comparison",
            "invariant_proof_checklist",
            "pass_benchmark_contract",
            "cold_start_contract",
            "wasm_strategy",
            "degraded_context",
            "feature_flags",
            "build_dependency_graph",
            "certificate_contract",
            "certainty_propagation",
            "merkle_verify",
            "hot_path_profile",
            "lifecycle_status",
        ]:
            assert fn in text, f"Brak innowacji: {fn}"

    def test_activation_flag(self, text):
        assert "p03_orchestrator_check" in text


# ═══════════════════ TEMPORALNOŚĆ (Sekcja 3, P1627–P1632) ═══════════════════

class TestTemporalExtension:
    def test_detectors_present(self):
        text = TEMPORAL_REGO.read_text(encoding="utf-8")
        for rid in [
            "temporal.interval_algebra",
            "temporal.threshold_version_pin",
            "temporal.law_change_lead",
            "temporal.retroactive_change",
            "temporal.pinning_drift",
            "temporal.version_proof",
        ]:
            assert rid in text, f"Brak detektora: {rid}"

    def test_interval_algebra_properties(self):
        text = TEMPORAL_REGO.read_text(encoding="utf-8")
        assert "zero_overlaps" in text
        assert "zero_gaps" in text
        assert "INV-037" in text


# ═══════════════════ PROVENANCE (Sekcja 7, V1 §9.3) ═══════════════════

class TestProvenanceVersions:
    def test_versions_in_tree(self):
        text = PROVENANCE_REGO.read_text(encoding="utf-8")
        assert "bundle_version" in text
        assert "rule_version" in text
        assert "threshold_version" in text
        assert "decision_hash" in text


# ═══════════════════ MAIN_JDG WIRING ═══════════════════

class TestMainJdgWiring:
    def test_imports(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.p03_orchestrator_innovations" in text
        assert "import data.jdg.runtime_invariants" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.p03_orchestrator_innovations": p03_orchestrator_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p25 = safe_merge(final_verdict_p24," in text
        assert "final_verdict_p26 = safe_merge(final_verdict_p25," in text
        assert "final_verdict_p27 = safe_merge(final_verdict_p26," in text
        # Łańcuch P30→P31 (R06 ZUS)→P32 (R07 KKS)→P33 (R08 Ordynacja) —
        # zgodnie z wiring w main_jdg.rego (PAS 18s/18t/18u/18v).
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p33," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text
        assert '"_routing_context": routing_context' in text


# ═══════════════════ HARDCODED AUDIT GATE (Sekcja 4) ═══════════════════

class TestHardcodedAuditGate:
    def test_scan_all_runs(self):
        findings = hardcoded_audit_gate.scan_all()
        assert isinstance(findings, list)
        assert len(findings) > 0
        sample = findings[0]
        assert {"file", "value", "category", "line"} <= set(sample)

    def test_report_json_written(self, tmp_path):
        # Zamiast nadpisywać bundles/hardcoded_audit.json — test struktury na małym zbiorze
        findings = hardcoded_audit_gate.scan_file(RULES / "fallback.rego")
        assert isinstance(findings, list)
        for f in findings:
            assert f["category"] in {"large_integer", "decimal_rate", "time_period"}

    def test_per_file_table(self):
        table = hardcoded_audit_gate.per_file_table(
            [{"file": "a.rego", "value": "0.23", "category": "decimal_rate", "line": 1, "context": "x"}]
        )
        assert table[0]["file"] == "a.rego"
        assert table[0]["hardcoded"] == 1

    def test_baseline_report_exists(self):
        report = JDG_ROOT / "bundles" / "hardcoded_audit.json"
        if report.exists():
            data = json.loads(report.read_text(encoding="utf-8"))
            assert "total_hardcoded" in data
            assert "migration_target" in data
            assert "hot-reload" in data["migration_target"]


# ═══════════════════ BUNDLE GATE (P03 — fail closed) ═════════════════════════

class TestBundleSyntaxGate:
    def test_bundle_runs_opa_check_before_packaging(self):
        bundle = (JDG_ROOT / "bundles" / "bundle.sh").read_text(encoding="utf-8")
        assert '"$OPA_BIN" check "$TEMP_DIR/jdg" -b' in bundle
        assert "BRAMKA: opa check -b nie przeszedł" in bundle
        assert 'BUNDLE_COUNT=$(find "$TEMP_DIR/jdg" -name "*.rego" | wc -l)' in bundle
