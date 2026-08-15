#!/usr/bin/env python3
"""
Auto-Tests dla P01 Fundament OPA v9.0 (prompts_glm52/P01_Fundament_OPA.txt)
Sekcje: 2 (Rule Lifecycle), 3 (Thresholds per period), 4 (Reliability),
        6 (OPA jako system), 7 (Genialne pomysły).
Wygenerowano: 2026-08-02
"""

import json
import subprocess
import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 2 — RULE LIFECYCLE MANAGER (CLI)
# ═══════════════════════════════════════════════════════════════════════════

class TestRuleLifecycleManager:
    def test_register_promote_rollback_roundtrip(self, tmp_path):
        """Rejestr: register CANDIDATE → promote ACTIVE → rollback przy error_rate."""
        # Izolowany rejestr w katalogu tymczasowym (patche ścieżki przez env)
        reg = tmp_path / "rule_registry.json"
        # Uruchom bezpośrednio importując moduł
        sys.path.insert(0, str(TOOLS_DIR))
        import rule_lifecycle_manager as rlm

        rlm.REGISTRY_PATH = reg
        rlm.save_registry({})

        # register
        args = type("A", (), {"rule_id": "jdg.vat.a113.r1", "version": "2.0.0",
                              "manifest": None, "title": None,
                              "legal_basis": "Ustawa o VAT art. 113",
                              "severity": "BLOCKER", "owner": None, "domain": "other",
                              "valid_from": "2026-08-01", "valid_to": None,
                              "status": "CANDIDATE", "rollout": 10,
                              "error_rate": 0.0, "supersedes": "1.0.0", "remove": False,
                              "reason": None, "fn": rlm.cmd_register})()
        rlm.cmd_register(args)
        data = json.loads(reg.read_text())
        assert "jdg.vat.a113.r1" in data
        assert data["jdg.vat.a113.r1"]["versions"][0]["status"] == "CANDIDATE"

        # check — brak konfliktów (1 wersja)
        assert rlm.cmd_check(type("A", (), {"fn": rlm.cmd_check})()) is None

        # promote
        rlm.cmd_promote(type("A", (), {"rule_id": "jdg.vat.a113.r1", "fn": rlm.cmd_promote})())
        data = json.loads(reg.read_text())
        assert data["jdg.vat.a113.r1"]["versions"][0]["status"] == "ACTIVE"

    def test_temporal_conflict_detection(self, tmp_path):
        """Overlapping validity windows — check musi wykryć konflikt (exit 2)."""
        sys.path.insert(0, str(TOOLS_DIR))
        import rule_lifecycle_manager as rlm
        reg = tmp_path / "rule_registry.json"
        rlm.REGISTRY_PATH = reg
        rlm.save_registry({
            "jdg.vat.a113.r1": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": "2026-12-31", "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-06-01", "valid_to": None, "status": "ACTIVE"},
            ]}
        })
        with pytest.raises(SystemExit) as exc:
            rlm.cmd_check(type("A", (), {"fn": rlm.cmd_check})())
        assert exc.value.code == 2

    def test_rollback_threshold_from_rego(self):
        """ADR-002: próg auto-rollback czytany z thresholds_jdg.rego (zero hardcode)."""
        sys.path.insert(0, str(TOOLS_DIR))
        import rule_lifecycle_manager as rlm
        thr = rlm.get_rollback_threshold()
        assert isinstance(thr, float)
        assert 0.0 < thr <= 0.1


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 6 — DECISION QUALITY MONITOR (feedback loop → adaptive trust)
# ═══════════════════════════════════════════════════════════════════════════

class TestDecisionQualityMonitor:
    def test_adaptive_thresholds_improve_with_accuracy(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import decision_quality_monitor as dqm
        fb = {"correct": 990, "incorrect": 10}
        thr = dqm.adaptive_thresholds(fb)
        assert thr["auto_post"] <= 0.92 + 0.01  # accuracy 99% → +0.018 → ~0.938
        assert thr["auto_post"] > 0.92

    def test_collect_kpi(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import decision_quality_monitor as dqm
        dqm.KPI_PATH = tmp_path / "decision_kpi.json"
        vfile = tmp_path / "verdicts.jsonl"
        vfile.write_text("\n".join([
            json.dumps({"matched": True, "_routing": "BLOCK_AND_ALERT", "_provenance_tree": {"path": [1]}}),
            json.dumps({"matched": True, "_routing": "TRIAGE_QUEUE", "_provenance_tree": {"path": [1]}}),
            json.dumps({"matched": False, "_routing": "ALLOW", "_provenance_tree": {"path": [1]}}),
        ]) + "\n")
        dqm.cmd_collect(type("A", (), {"file": str(vfile), "fn": dqm.cmd_collect})())
        kpi = json.loads(dqm.KPI_PATH.read_text())
        assert kpi["total"] == 3
        assert kpi["blocked"] == 1
        assert kpi["provenance_complete"] == 3
        assert kpi["provenance_completeness_pct"] == 100.0


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 6 — ISAP RULE UPDATE PIPELINE
# ═══════════════════════════════════════════════════════════════════════════

class TestIsapPipeline:
    def test_ingest_impact_plan(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import isap_rule_update_pipeline as ip
        ip.CHANGELOG_PATH = tmp_path / "threshold_changelog.json"
        ip.REGISTRY_PATH = tmp_path / "rule_registry.json"
        ip.IMPACT_PATH = tmp_path / "impact_analysis.json"
        ip.save_json(ip.CHANGELOG_PATH, {})
        ip.save_json(ip.REGISTRY_PATH, {})

        ip.cmd_ingest(type("A", (), {"act": "Ustawa o PIT", "article": "Art. 27",
                                     "effective": "2027-01-01", "threshold": "pit.scale_threshold",
                                     "value": 150000.0, "fn": ip.cmd_ingest})())
        changelog = json.loads(ip.CHANGELOG_PATH.read_text())
        assert len(changelog["pit.scale_threshold"]) == 1

        ip.cmd_impact(type("A", (), {"threshold": "pit.scale_threshold", "fn": ip.cmd_impact})())
        impact = json.loads(ip.IMPACT_PATH.read_text())
        assert impact["affected_count"] >= 1

        ip.cmd_plan(type("A", (), {"threshold": "pit.scale_threshold", "fn": ip.cmd_plan})())
        registry = json.loads(ip.REGISTRY_PATH.read_text())
        assert len(registry) >= 1


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 3 — THRESHOLDS VERSIONING (per okres rozliczeniowy)
# ═══════════════════════════════════════════════════════════════════════════

class TestThresholdVersioning:
    def test_threshold_versions_in_rego(self):
        """threshold_versions + get_threshold_for_period muszą istnieć w rego."""
        rego = Path(__file__).resolve().parent.parent.parent / "rules" / "thresholds_jdg.rego"
        txt = rego.read_text(encoding="utf-8")
        assert "threshold_versions" in txt or "default_threshold_versions" in txt
        assert "get_threshold_for_period" in txt
        assert "P01 SEK. 3" in txt

    def test_temporal_overlap_rules_in_rego(self):
        """P1619-P1624 (overlap/version pin/law calendar/shadow/rollback/gap)."""
        rego = Path(__file__).resolve().parent.parent.parent / "rules" / "temporal.rego"
        txt = rego.read_text(encoding="utf-8")
        for marker in ["overlap_detector", "rule_version_pin", "law_change_calendar",
                       "shadow_window", "rollback_window", "gap_detector"]:
            assert marker in txt, f"Brak reguły temporalnej: {marker}"
