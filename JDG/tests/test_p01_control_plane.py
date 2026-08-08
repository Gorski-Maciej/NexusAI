"""
Testy P01 FUNDAMENT ŚWIĘTY — control plane jako infrastruktura (V1 §2/§3/§4/§6/§7/§9, V2 F1–F6).

Pokrycie: manifest_v2 · policies_sync_gate · rule_lifecycle_manager v2 ·
policy_registry_api · data_service · deployment_orchestrator · law_impact_matrix ·
golden_replay · legal_twin · invariant_checker · decision_certificate · law_radar ·
declarative_change · confidence_dashboard.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
TOOLS = JDG_ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import manifest_v2  # noqa: E402
import policies_sync_gate  # noqa: E402
import rule_lifecycle_manager as rlm  # noqa: E402
import policy_registry_api as pra  # noqa: E402
import data_service  # noqa: E402
import deployment_orchestrator as do  # noqa: E402
import law_impact_matrix as lim  # noqa: E402
import golden_replay  # noqa: E402
import legal_twin  # noqa: E402
import invariant_checker  # noqa: E402
import decision_certificate as dc  # noqa: E402
import law_radar  # noqa: E402
import declarative_change as dec  # noqa: E402
import confidence_dashboard as cd  # noqa: E402


# ══════════════════════ MANIFEST 2.0 (L2) ══════════════════════

class TestManifestV2:
    def test_compute_manifest_structure(self):
        m = manifest_v2.compute_manifest()
        assert m["manifest_version"] == "2.0"
        assert m["rules"]["rego_files"] > 0
        assert m["rules"]["unique_rule_ids"] > 0
        assert m["tools"]["python_tools"] > 50
        assert "declared_sources" in m
        assert "slo_targets" in m

    def test_declared_sources_present(self):
        assert set(manifest_v2.DECLARED["rego_files"]) == {"README.md", "MANIFEST.md", "COVERAGE_REPORT.md"}
        assert set(manifest_v2.DECLARED["tools"]) == {"README.md", "OPA_JAKO_SYSTEM_P21.md", "KATALOG_NARZEDZI.md"}

    def test_sha256_deterministic(self):
        p = TOOLS / "manifest_v2.py"
        assert manifest_v2.sha256(p) == manifest_v2.sha256(p)
        assert len(manifest_v2.sha256(p)) == 64


# ══════════════════════ SINGLE SOURCE OF TRUTH (L5) ══════════════════════

class TestPoliciesSyncGate:
    def test_walk_rego_counts(self):
        files = policies_sync_gate.walk_rego(manifest_v2.RULES_DIR)
        assert len(files) == manifest_v2.scan_rules()["rego_files"]

    def test_drift_detection_math(self, tmp_path):
        src = tmp_path / "rules"
        dst = tmp_path / "policies"
        (src / "a").mkdir(parents=True)
        (dst / "a").mkdir(parents=True)
        (src / "a" / "x.rego").write_text("package a\np := true\n")
        (dst / "a" / "x.rego").write_text("package a\np := true\n")
        (src / "a" / "y.rego").write_text("package a\nq := true\n")  # brak w policies
        rules = policies_sync_gate.walk_rego(src)
        pol = policies_sync_gate.walk_rego(dst)
        missing = set(rules) - set(pol)
        assert len(missing) == 1 and "a/y.rego" in missing


# ══════════════════════ RULE LIFECYCLE v2 (V1 §3) ══════════════════════

class TestRuleLifecycleV2:
    def test_manifest_validation(self):
        good = {"rule_id": "x.r1", "title": "t", "legal_basis": "Art. 1", "valid_from": "2026-01-01",
                "valid_to": None, "severity": "BLOCKER", "owner": "o", "domain": "vat"}
        assert rlm._validate_manifest(good) == []
        bad = dict(good, severity="XXX")
        assert rlm._validate_manifest(bad) != []

    def test_semver_enforced(self):
        rlm._parse_semver("2.0.0")  # ok
        with pytest.raises(ValueError):
            rlm._parse_semver("v2")

    def test_register_suspend_check(self, tmp_path):
        old = rlm.REGISTRY_PATH
        rlm.REGISTRY_PATH = tmp_path / "rule_registry.json"
        try:
            args = argparse_stub(rule_id="jdg.vat.a113.r1", version="1.0.0", manifest=None,
                                 title="T", legal_basis="Art. 113 ustawy o VAT", severity="BLOCKER",
                                 owner="vat-team", domain="vat", valid_from="2026-01-01",
                                 valid_to=None, status="ACTIVE", rollout=100, error_rate=0.0,
                                 supersedes=None)
            rlm.cmd_register(args)
            rlm.cmd_suspend(argparse_stub(rule_id="jdg.vat.a113.r1", reason="test"))
            reg = rlm.load_registry()
            assert reg["jdg.vat.a113.r1"]["versions"][0]["status"] == "SUSPENDED"
            # algebra interwałów: pojedyncza wersja = zero luk/nakładek
            rlm.cmd_check(argparse_stub())
        finally:
            rlm.REGISTRY_PATH = old

    def test_overlap_detected(self, tmp_path):
        old = rlm.REGISTRY_PATH
        rlm.REGISTRY_PATH = tmp_path / "rule_registry.json"
        try:
            rlm.save_registry({"r.x": {"versions": [
                {"version": "1.0.0", "valid_from": "2026-01-01", "valid_to": "2026-06-30", "status": "ACTIVE"},
                {"version": "1.0.1", "valid_from": "2026-06-01", "valid_to": None, "status": "ACTIVE"},
            ]}})
            with pytest.raises(SystemExit):
                rlm.cmd_check(argparse_stub())
        finally:
            rlm.REGISTRY_PATH = old


# ══════════════════════ POLICY REGISTRY (L1) ══════════════════════

class TestPolicyRegistry:
    def test_package_of(self, tmp_path):
        rego = tmp_path / "sample.rego"
        rego.write_text("package jdg.test\n\np := true\n", encoding="utf-8")
        assert pra.package_of(rego) == "jdg.test"
        # plik bez pakietu → unknown, bez crasha
        assert pra.package_of(TOOLS / "manifest_v2.py") == "unknown"

    def test_scan_rules_entries(self):
        entries = pra.scan_all()
        assert len(entries) > 100
        assert all("rule_id" in e and "file" in e for e in entries)


# ══════════════════════ DATA SERVICE (V1 §7) ══════════════════════

class TestDataService:
    def test_parse_value_types(self):
        assert data_service._parse_value("0.23", "number") == 0.23
        assert data_service._parse_value("true", "bool") is True

    def test_time_travel_get(self, tmp_path):
        old = data_service.DATA_PATH
        data_service.DATA_PATH = tmp_path / "thresholds.json"
        try:
            data_service.save({"parameters": {"vat.standard_rate": {"versions": [
                {"value": 0.23, "type": "number", "valid_from": "2026-01-01", "valid_to": "2026-12-31"},
                {"value": 0.24, "type": "number", "valid_from": "2027-01-01", "valid_to": None},
            ]}}})
            data_service.cmd_get(argparse_stub(key="vat.standard_rate", as_of="2026-06-01"))
            data_service.cmd_get(argparse_stub(key="vat.standard_rate", as_of="2027-03-01"))
        finally:
            data_service.DATA_PATH = old

    def test_validate_gap_detected(self, tmp_path):
        old = data_service.DATA_PATH
        data_service.DATA_PATH = tmp_path / "thresholds.json"
        try:
            data_service.save({"parameters": {"p": {"versions": [
                {"value": 1, "type": "number", "valid_from": "2026-01-01", "valid_to": "2026-06-30"},
                {"value": 2, "type": "number", "valid_from": "2026-09-01", "valid_to": None},
            ]}}})
            with pytest.raises(SystemExit):
                data_service.cmd_validate(argparse_stub())
        finally:
            data_service.DATA_PATH = old


# ══════════════════════ DEPLOYMENT ORCHESTRATOR (V1 §9) ══════════════════════

class TestDeploymentOrchestrator:
    def test_progressive_delivery(self, tmp_path):
        old = do.STATE_PATH
        do.STATE_PATH = tmp_path / "deployments.json"
        try:
            do.cmd_init(argparse_stub(version="jdg-bundle-v9.0.0"))
            do.cmd_canary(argparse_stub(version="jdg-bundle-v9.0.0"))
            do.cmd_shadow_compare(argparse_stub(version="jdg-bundle-v9.0.0", delta=1.0))
            do.cmd_ramped(argparse_stub(version="jdg-bundle-v9.0.0"))
            do.cmd_promote(argparse_stub(version="jdg-bundle-v9.0.0"))
            state = do.load_state()
            assert state["deployments"]["jdg-bundle-v9.0.0"]["phase"] == "FULL_SOAK"
            assert state["deployments"]["jdg-bundle-v9.0.0"]["rollout_pct"] == 100
            # auto-rollback
            do.cmd_auto_rollback(argparse_stub(version="jdg-bundle-v9.0.0", reason="test"))
            assert do.load_state()["deployments"]["jdg-bundle-v9.0.0"]["phase"] == "ROLLED_BACK"
        finally:
            do.STATE_PATH = old

    def test_shadow_delta_above_threshold_blocks(self, tmp_path):
        old = do.STATE_PATH
        do.STATE_PATH = tmp_path / "deployments.json"
        try:
            do.cmd_init(argparse_stub(version="b1"))
            with pytest.raises(SystemExit):
                do.cmd_shadow_compare(argparse_stub(version="b1", delta=5.0))
        finally:
            do.STATE_PATH = old


# ══════════════════════ LAW IMPACT MATRIX (V1 §4.2) ══════════════════════

class TestLawImpactMatrix:
    def test_impact_classification(self):
        assert lim._impact("STAWKA") == "PARAMETER_ONLY"
        assert lim._impact("DEFINICJA") == "LOGIC"
        assert lim._impact("TERMIN") == "PARAMETER_AND_LOGIC"

    def test_scan_rules(self):
        rules = lim.scan_rules()
        assert len(rules) > 100
        assert all("rule_id" in r for r in rules)


# ══════════════════════ GOLDEN ORACLE (V2 F3) ══════════════════════

class TestGoldenReplay:
    def test_replay_unchanged_and_uver(self, tmp_path):
        old = golden_replay.GOLDEN_PATH
        golden_replay.GOLDEN_PATH = tmp_path / "golden.json"
        try:
            golden_replay.cmd_record(argparse_stub(
                input_hash="h1", verdict='{"matched": true, "vat_rate": 0.23}',
                bundle="b1", legal_refs="LKG-0001"))
            # ten sam werdykt — brak zmiany
            golden_replay.cmd_replay(argparse_stub(
                input_hash="h1", verdict='{"matched": true, "vat_rate": 0.23}',
                reason=None))
            # inny werdykt bez uzasadnienia → UVR blokada
            with pytest.raises(SystemExit):
                golden_replay.cmd_replay(argparse_stub(
                    input_hash="h1", verdict='{"matched": true, "vat_rate": 0.08}',
                    reason=None))
        finally:
            golden_replay.GOLDEN_PATH = old


# ══════════════════════ LEGAL TWIN / LKG (V2 F1) ══════════════════════

class TestLegalTwin:
    def test_parse_acts_finds_articles(self):
        acts = legal_twin.parse_acts()
        assert len(acts) > 5
        assert all(a["articles"] for a in acts)

    def test_build_lkg_structure(self):
        lkg = legal_twin.build_lkg()
        assert lkg["nodes_count"] > 50
        assert set(lkg["indexes"]) == {"LCI", "TCL", "RV"}
        assert "slo" in lkg


# ══════════════════════ RUNTIME INVARIANTS (V2 F2) ══════════════════════

class TestInvariantChecker:
    def test_catalog_full(self):
        catalog = invariant_checker.parse_catalog()
        assert len(catalog) >= 30
        ids = {c[0] for c in catalog}
        assert "INV-001" in ids and "INV-030" in ids

    def test_verdict_violations(self):
        bad = {"matched": True, "vat_rate": 0.12, "net_amount": -5, "_legal_basis": []}
        issues = invariant_checker.check_verdict(bad)
        assert any("INV-001" in i for i in issues)
        assert any("INV-002" in i for i in issues)
        assert any("INV-009" in i for i in issues)

    def test_verdict_clean(self):
        good = {"matched": True, "vat_rate": 0.23, "net_amount": 100, "vat_amount": 23.00,
                "gross_amount": 123.00, "_legal_basis": ["Art. 41"], "_provenance_tree": {"bundle_version": "b1"}}
        assert invariant_checker.check_verdict(good) == []


# ══════════════════════ DECISION CERTIFICATE (V2 F4) ══════════════════════

class TestDecisionCertificate:
    def test_certainty_classes(self):
        assert dc.certainty_class_of({"matched": True, "_legal_basis": ["Art. 1"]}) == "CERTAIN"
        assert dc.certainty_class_of({"matched": True, "_warnings": ["REQUIRES_INTERPRETATION"]}) == "CONDITIONAL"
        assert dc.certainty_class_of({"matched": True}) == "NEEDS_ADVICE"
        assert dc.certainty_class_of({"matched": True, "_legal_basis": ["Art. 1"]}, ["INV-001"]) == "NEEDS_ADVICE"

    def test_issue_verify(self, tmp_path):
        old = dc.CERT_PATH
        dc.CERT_PATH = tmp_path / "certs.json"
        try:
            dc.cmd_issue(argparse_stub(verdict='{"matched": true, "rule_id": "r1", "_legal_basis": ["Art. 1"]}',
                                       input_hash="h", date="2026-08-08", invariants=None))
            certs = dc.load()
            cert_id = list(certs["certificates"])[0]
            with pytest.raises(SystemExit) as ei:
                dc.cmd_verify(argparse_stub(certificate=cert_id))
            assert ei.value.code == 0
        finally:
            dc.CERT_PATH = old


# ══════════════════════ LAW RADAR (V2 F5) ══════════════════════

class TestLawRadar:
    def test_track_and_radar(self, tmp_path):
        old = law_radar.RADAR_PATH
        law_radar.RADAR_PATH = tmp_path / "radar.json"
        try:
            law_radar.cmd_track(argparse_stub(source="RCL", title="Nowelizacja VAT",
                                              enactment="2099-01-01", confidence=0.8, diff=None))
            data = law_radar.load()
            d = list(data["drafts"].values())[0]
            assert d["status"] == "DRAFT_LAW"
            assert d["lead_days"] > 30
            assert data["kpi"]["lead_time_avg_days"] > 30
        finally:
            law_radar.RADAR_PATH = old


# ══════════════════════ DECLARATIVE CHANGE (V2 F6) ══════════════════════

class TestDeclarativeChange:
    def test_parse_rate_change(self):
        parsed = dec.parse_change("Stawka VAT na usługi IT od 2027-01-01: 23% -> 8%")
        assert parsed and parsed["kind"] == "RATE_CHANGE" and parsed["target"] == "data.thresholds"

    def test_parse_legal_change(self):
        parsed = dec.parse_change("Nowelizacja ustawy o VAT: art. 113")
        assert parsed and parsed["kind"] == "LEGAL_CHANGE"

    def test_plan_steps(self):
        parsed = dec.parse_change("Limit zwolnienia od 2027-01-01: 2000000 -> 2400000 zł")
        assert parsed and parsed["target"] == "data.thresholds"


# ══════════════════════ DASHBOARD PEWNOŚĆ (V2 §11.2) ══════════════════════

class TestConfidenceDashboard:
    def test_compute_structure(self):
        d = cd.compute()
        assert "legal_confidence_index" in d
        assert set(d["indexes"]) == {"LCI", "TCL", "RV"}
        assert "decision_confidence" in d and "uver_pct" in d


# ── helper: stub argparse ────────────────────────────────────────────────

def argparse_stub(**kwargs):
    class NS:
        pass
    ns = NS()
    for k, v in kwargs.items():
        setattr(ns, k, v)
    return ns
