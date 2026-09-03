#!/usr/bin/env python3
"""Tests for V3 P03 (KONTRAKT WERDYKTU) — the 12 enterprise innovations.

Covers V3-P03-I01..I12 delivered by P03:
  * I01 contract version matrix (25-field canon vs OpenAPI vs tool contract)
  * I02 certainty class engine (CERTAIN/CONDITIONAL/NEEDS_ADVICE, closed list)
  * I03 empty-semantics schema (null vs absent vs N/A)
  * I04 golden hash in verdict (deterministic, sensitive to changes)
  * I05 contract diff CI gate (spec change without test change = fail)
  * I06 legal refs completeness guard (no material verdict without _legal_basis)
  * I07 verdict as evidence object (seal, merkle, retention)
  * I08 scoring telemetry (class distribution alarms)
  * I09 client compatibility suite (golden replay, UVR=0)
  * I10 degradation contract patterns (no short contract on degradation)
  * I11 AUTO_POST gate contract (fail-closed by type)
  * I12 error taxonomy DSL (codes + docs from one definition)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P03_KONTRAKT_WERDYKTU.txt"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def _run_tool(name: str, *args: str) -> str:
    return subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / name), *args],
        capture_output=True, text=True, cwd=str(BASE_DIR), check=True,
    ).stdout


def test_report_exists_and_is_complete():
    assert REPORT.exists()
    txt = REPORT.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in txt
    for marker in ("9.01 EXECUTIVE SUMMARY", "9.06 REJESTR LUK",
                   "9.07 INNOWACJE ENTERPRISE", "9.08 KONTRAKT WYJŚCIOWY",
                   "V3-P03-I01", "V3-P03-I12", "V3-P03-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_contract_version_matrix():
    d = _load_bundle("v3_p03_contract_version_matrix.json")
    assert d["canonical_field_count"] == 25
    assert d["openapi_field_count"] == 19
    # Real drift: 11 canonical fields missing from OpenAPI VerdictResponse.
    assert d["drift_count"] == 11
    drift = {r["field"] for r in d["drift_fields"]}
    assert {"package", "priority", "rounding_level", "gtu_code", "procedure",
            "pit_bracket", "pit_annual_return_type", "kus_percent",
            "ceidg_registration_required", "valid_from", "valid_to"} == drift
    assert d["gate"]["pass"] is False


def test_i02_certainty_class_engine():
    d = _load_bundle("v3_p03_certainty_class_engine.json")
    assert len(d["certain_conditions"]) >= 4
    assert d["determinism_property_test"]["deterministic"] is True
    s = d["samples_classified"]
    assert s["full_evidence"]["certainty_class"] == "CERTAIN"
    assert s["no_match"]["certainty_class"] == "NEEDS_ADVICE"
    assert s["degraded"]["certainty_class"] == "NEEDS_ADVICE"
    assert s["invariant_failure"]["certainty_class"] == "NEEDS_ADVICE"
    assert s["requires_interpretation"]["certainty_class"] == "CONDITIONAL"
    assert d["gate"]["pass"] is True


def test_i03_empty_semantics_schema():
    d = _load_bundle("v3_p03_empty_semantics_schema.json")
    assert len(d["fields"]) == 25
    assert d["fields_without_docs"] == []
    # Required non-empty: fields where empty means contract silence.
    assert d["required_non_empty_count"] > 0
    names = {f["field"] for f in d["required_non_empty"]}
    assert "vat_rate" in names and "pit_form" in names and "_legal_basis" in names
    assert d["gate"]["pass"] is True


def test_i04_golden_hash_verdict():
    d = _load_bundle("v3_p03_golden_hash_verdict.json")
    assert d["golden_hash"].startswith("sha256:")
    assert d["probes_ok"] is True
    assert all(p["ok"] for p in d["probes"])
    assert d["gate"]["pass"] is True


def test_i05_contract_diff_gate():
    d = _load_bundle("v3_p03_contract_diff_gate.json")
    assert d["spec_hash"].startswith("sha256:")
    assert d["tests_hash"].startswith("sha256:")
    # Baseline registered on first run; gate must not fail on NO_CHANGE.
    assert d["state"] in ("BASELINE_REGISTERED", "NO_CHANGE", "CORRELATED_CHANGE")
    assert d["gate"]["pass"] is True


def test_i06_legal_refs_guard():
    d = _load_bundle("v3_p03_legal_refs_guard.json")
    # Structural scan finds no material verdict without _legal_basis.
    assert d["findings_count"] == 0
    assert d["gate"]["pass"] is True


def test_i07_verdict_evidence_object():
    d = _load_bundle("v3_p03_verdict_evidence_object.json")
    sv = d["seal_verification"]
    assert sv["payload_hash_matches"] is True
    assert sv["merkle_derivable"] is True
    assert d["evidence_object"]["seal"]["signed_by"] == "PENDING_4EYES"
    assert d["evidence_object"]["retention"]["required_years"] == 5
    assert "WERDYKT PODATKOWY JDG" in d["paper_verdict"]
    assert d["gate"]["pass"] is True


def test_i08_scoring_telemetry():
    d = _load_bundle("v3_p03_scoring_telemetry.json")
    assert d["total_verdicts"] == 1000
    assert sum(d["distribution"].values()) == 1000
    names = {m["name"] for m in d["metrics_to_p37"]}
    assert "jdg_verdict_certain_pct" in names
    assert "jdg_verdict_needs_advice_pct" in names
    # Model distribution triggers 1 alarm (NEEDS_ADVICE 20% > 15%) — documented.
    assert d["alarm_count"] == 1
    assert d["gate"]["pass"] is False


def test_i09_client_compatibility():
    d = _load_bundle("v3_p03_client_compatibility.json")
    assert d["compatible_count"] == 3
    assert d["uvr_count"] == 0
    assert all(d["client_paths_in_openapi"].values())
    assert d["gate"]["pass"] is True


def test_i10_degradation_contract():
    d = _load_bundle("v3_p03_degradation_contract.json")
    assert d["all_patterns_complete"] is True
    # 4 real degradation paths return short contracts (missing temporal fields).
    assert d["short_contract_count"] == 4
    assert d["gate"]["pass"] is False


def test_i11_auto_post_gate():
    d = _load_bundle("v3_p03_auto_post_gate.json")
    assert d["fail_closed"] is True
    assert d["results"]["AUTO"]["allowed"] is True
    for k in ("needs_advice_class", "guard_manual", "routing_triage",
              "degraded", "incomplete_contract", "no_match"):
        assert d["results"][k]["allowed"] is False, k
    assert d["gate"]["pass"] is True


def test_i12_error_taxonomy():
    d = _load_bundle("v3_p03_error_taxonomy.json")
    assert d["error_count"] == 10
    codes = [e["code"] for e in d["errors"]]
    assert len(codes) == len(set(codes))
    assert "JDG-ERROR-BLOCKED-001" in codes
    # Degradation errors are WARNING with retry semantics — never silent.
    assert any(e["domain"] == "degradation" and e["severity"] == "WARNING" for e in d["errors"])
    assert d["gate"]["pass"] is True


def test_tools_cli_run_clean():
    for t in (
        "v3_p03_certainty_class_engine.py", "v3_p03_golden_hash_verdict.py",
        "v3_p03_auto_post_gate.py", "v3_p03_error_taxonomy.py",
        "v3_p03_verdict_evidence_object.py",
    ):
        out = _run_tool(t)
        assert "gate_pass" in out, t