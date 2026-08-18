# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P17 ENTERPRISE AI + SYSTEM OPA (CONTROL PLANE) — pytest (GLM52 P17)
# ═══════════════════════════════════════════════════════════════════════════════
import json
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(JDG_ROOT / "tools"))

import bundle_server  # noqa: E402
import rollout_orchestrator  # noqa: E402
import runtime_invariants_check  # noqa: E402
import legal_twin_engine  # noqa: E402
import certificate_service  # noqa: E402


# ── BUNDLE SERVER (V1 §9.1 — podpis, wersje, long-polling) ────────────────────
class TestBundleServer:
    def setup_method(self):
        # izolacja: czysty katalog testowy
        self._orig_cat = bundle_server.CATALOG_PATH
        self._orig_health = bundle_server.HEALTHY_PATH
        bundle_server.CATALOG_PATH = JDG_ROOT / "bundles" / "_test_bundle_catalog.json"
        bundle_server.HEALTHY_PATH = JDG_ROOT / "bundles" / "_test_healthy.json"
        bundle_server.CATALOG_PATH.unlink(missing_ok=True)
        bundle_server.HEALTHY_PATH.unlink(missing_ok=True)

    def teardown_method(self):
        bundle_server.CATALOG_PATH.unlink(missing_ok=True)
        bundle_server.HEALTHY_PATH.unlink(missing_ok=True)
        bundle_server.CATALOG_PATH = self._orig_cat
        bundle_server.HEALTHY_PATH = self._orig_health

    def test_publish(self):
        e = bundle_server.publish("v9.2.0-p17-test", rules_count=11476)
        assert e["version"] == "v9.2.0-p17-test"
        assert e["status"] == "CANDIDATE"
        assert e["sha256"]
        assert e["signature"].startswith("HSM:")

    def test_verify_ok(self):
        bundle_server.publish("v9.2.0-p17-test2", rules_count=10)
        r = bundle_server.verify("v9.2.0-p17-test2")
        assert r["verified"] is True

    def test_verify_unknown(self):
        r = bundle_server.verify("nieznana")
        assert r["verified"] is False

    def test_status_and_discovery(self):
        bundle_server.publish("v9.2.0-p17-test3")
        st = bundle_server.status()
        assert st["latest"] == "v9.2.0-p17-test3"
        d = bundle_server.discovery()
        assert d["service"] == "jdg-bundle-server"
        assert d["signing"] == "HSM-SHA256-Merkle"


# ── ROLLOUT ORCHESTRATOR (V2 §8 — canary/shadow/auto-rollback) ────────────────
class TestRolloutOrchestrator:
    def setup_method(self):
        self._orig = rollout_orchestrator.STATE_PATH
        rollout_orchestrator.STATE_PATH = JDG_ROOT / "bundles" / "_test_rollout_state.json"
        rollout_orchestrator.STATE_PATH.unlink(missing_ok=True)

    def teardown_method(self):
        rollout_orchestrator.STATE_PATH.unlink(missing_ok=True)
        rollout_orchestrator.STATE_PATH = self._orig

    def test_full_pipeline(self):
        rollout_orchestrator.init("v9.2.0", "v9.1.0")
        r = rollout_orchestrator.canary("v9.2.0", delta_pct=1.0)
        assert r["stage"] == "CANARY"
        assert r["pct"] == 5
        assert r["shadow"]["passed"] is True
        r = rollout_orchestrator.ramped("v9.2.0", step=50)
        assert r["pct"] == 50
        r = rollout_orchestrator.promote("v9.2.0", soak_hours=24)
        assert r["stage"] == "ACTIVE"
        assert r["pct"] == 100

    def test_canary_high_delta_rolls_back(self):
        rollout_orchestrator.init("v9.3.0", "v9.1.0")
        r = rollout_orchestrator.canary("v9.3.0", delta_pct=5.0)
        assert r["stage"] == "ROLLED_BACK"
        assert r["rollback"]["triggered"] is True

    def test_health_error_rolls_back(self):
        rollout_orchestrator.init("v9.4.0", "v9.1.0")
        r = rollout_orchestrator.health("v9.4.0", error_rate=0.05)
        assert r["stage"] == "ROLLED_BACK"
        assert "error_rate" in r["rollback"]["reason"]

    def test_health_ok_no_rollback(self):
        rollout_orchestrator.init("v9.5.0", "v9.1.0")
        r = rollout_orchestrator.health("v9.5.0", error_rate=0.001, quality=0.99)
        assert r["stage"] == "INIT"
        assert r["rollback"]["triggered"] is False

    def test_unknown_rollout(self):
        r = rollout_orchestrator.canary("nieznana")
        assert "error" in r

    def test_rollback_mttr(self):
        rollout_orchestrator.init("v9.6.0", "v9.1.0")
        r = rollout_orchestrator.auto_rollback("v9.6.0", reason="test")
        assert r["rollback"]["mttr_s"] == 300
        assert r["rollback"]["target"] == "v9.1.0"


# ── RUNTIME INVARIANTS CHECK (V2 F2 — INV-001..042) ───────────────────────────
class TestRuntimeInvariantsCheck:
    def test_catalog_42(self):
        cat = runtime_invariants_check.catalog()
        assert len(cat) == 42
        assert cat[0]["id"] == "INV-001"

    def test_ci_gate_pass(self):
        r = runtime_invariants_check.ci_gate()
        assert r["gate"] == "PASS"
        assert r["missing"] == []

    def test_check_ok_verdict(self):
        r = runtime_invariants_check.check(
            {"matched": True, "rule_id": "jdg.vat.r1", "package": "jdg.vat",
             "_routing": "OK", "_legal_basis": ["Art. 41 ustawy o VAT"]})
        assert r["blocked"] is False

    def test_check_missing_fields_blocks(self):
        r = runtime_invariants_check.check({"matched": True})
        assert r["blocked"] is True
        assert any(x["inv"] == "INV-002" for x in r["violations"])

    def test_check_certainty_blocked_auto_post(self):
        r = runtime_invariants_check.check(
            {"matched": True, "rule_id": "jdg.r1", "package": "jdg",
             "_certainty_guard": "CERTAINTY_BLOCKED", "_post_mode": "AUTO_POST"})
        assert r["blocked"] is True
        assert any(x["inv"] == "INV-035" for x in r["violations"])

    def test_certainty_class(self):
        ok = {"matched": True, "rule_id": "jdg.r1", "package": "jdg", "_routing": "OK"}
        assert runtime_invariants_check.certainty_class(ok) == "CERTAIN"
        assert runtime_invariants_check.certainty_class(
            {**ok, "_routing": "BLOCK_AND_ALERT"}) == "CONDITIONAL"
        assert runtime_invariants_check.certainty_class(
            {**ok, "_certainty_class": "NEEDS_ADVICE"}) == "NEEDS_ADVICE"


# ── LEGAL TWIN ENGINE (V2 F1 — LCI/TCL/RV) ────────────────────────────────────
class TestLegalTwinEngine:
    def test_metrics_reads_lkg(self):
        m = legal_twin_engine.metrics()
        assert "lci" in m and "tcl" in m and "rv" in m
        assert m["total_nodes"] >= 100
        assert m["targets"]["lci_target"] == 99.0

    def test_traceability(self):
        r = legal_twin_engine.traceability("LKG-0001")
        assert r["found"] is True
        assert r["act"]

    def test_traceability_unknown(self):
        r = legal_twin_engine.traceability("LKG-9999")
        assert r["found"] is False

    def test_time_travel(self):
        r = legal_twin_engine.time_travel("2025 poz. 123", "4-5", "2026-01-01")
        assert r["exists"] is True

    def test_time_travel_unknown(self):
        r = legal_twin_engine.time_travel("0000 poz. 0", "X", "2026-01-01")
        assert r["exists"] is False

    def test_desert_alert(self):
        d = legal_twin_engine.desert()
        assert isinstance(d, list)


# ── CERTIFICATE SERVICE (V2 F4 — PDF/XML + pieczęć) ───────────────────────────
class TestCertificateService:
    def setup_method(self):
        import decision_certificate
        self._orig_path = decision_certificate.CERT_PATH
        decision_certificate.CERT_PATH = JDG_ROOT / "bundles" / "_test_certificates.json"
        decision_certificate.CERT_PATH.unlink(missing_ok=True)
        # certificate_service współdzieli load/save z decision_certificate

    def teardown_method(self):
        import decision_certificate
        decision_certificate.CERT_PATH.unlink(missing_ok=True)
        decision_certificate.CERT_PATH = self._orig_path

    def test_issue_certificate(self):
        cert = certificate_service.issue(
            {"rule_id": "jdg.vat.r1", "matched": True, "tax_due": 12345.5,
             "_legal_basis": ["Art. 41 ustawy o VAT"]})
        assert cert["certificate_id"].startswith("CS-")
        assert cert["certainty_class"] == "CERTAIN"
        assert cert["seal"]["payload_hash"]

    def test_issue_with_invariants_needs_advice(self):
        cert = certificate_service.issue(
            {"rule_id": "jdg.vat.r1", "matched": True,
             "_legal_basis": ["Art. 41 ustawy o VAT"]},
            invariants=["INV-006"])
        assert cert["certainty_class"] == "NEEDS_ADVICE"

    def test_to_xml(self):
        cert = certificate_service.issue(
            {"rule_id": "jdg.vat.r1", "matched": True, "_legal_basis": ["X"]})
        xml = certificate_service.to_xml(cert)
        assert "<DecisionCertificate" in xml
        assert "CertaintyClass" in xml

    def test_to_pdf_text(self):
        cert = certificate_service.issue(
            {"rule_id": "jdg.vat.r1", "matched": True, "tax_due": 9999.99,
             "_legal_basis": ["X"]})
        pdf = certificate_service.to_pdf_text(cert)
        assert "CERTIFIKAT DECYZYJNY" in pdf
        assert "HSM-ECDSA" in pdf

    def test_verify(self):
        cert = certificate_service.issue(
            {"rule_id": "jdg.vat.r1", "matched": True, "_legal_basis": ["X"]})
        r = certificate_service.verify(cert)
        assert r["verified"] is True


# ── WIRING CONTROL PLANE (main_jdg.rego + migracja 004 + openapi) ─────────────
class TestWiringControlPlane:
    def test_main_jdg_invariants_post_merge(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "import data.jdg.runtime_invariants" in text
        assert "runtime_invariants.enforce(final_verdict_post_merge)" in text

    def test_runtime_invariants_rego_catalog(self):
        f = JDG_ROOT / "rules" / "audit" / "runtime_invariants_enterprise.rego"
        text = f.read_text(encoding="utf-8")
        for inv in ["INV-001", "INV-018", "INV-031", "INV-035", "INV-042"]:
            assert inv in text
        assert "enforce(v) = result" in text

    def test_migration_004_exists(self):
        f = JDG_ROOT / "migrations" / "004_jdg_v9_control_plane.sql"
        text = f.read_text(encoding="utf-8")
        assert "runtime_invariants" in text
        assert "decision_certificates" in text
        assert "bundle_rollouts" in text
        assert "rule_shadow_preparations" in text
        assert "INV-042" in text

    def test_openapi_control_plane_endpoints(self):
        f = JDG_ROOT / "api" / "openapi.yaml"
        text = f.read_text(encoding="utf-8")
        assert "  /jdg/rules:" in text
        assert "  /jdg/change:" in text
        assert "  /jdg/cert:" in text
        assert "ControlPlane" in text

    def test_tools_exist(self):
        for name in ["bundle_server.py", "rollout_orchestrator.py",
                     "legal_twin_engine.py", "runtime_invariants_check.py",
                     "certificate_service.py"]:
            assert (JDG_ROOT / "tools" / name).exists()
