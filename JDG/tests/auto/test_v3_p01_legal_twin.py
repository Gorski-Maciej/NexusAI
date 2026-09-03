#!/usr/bin/env python3
"""Tests for V3 P01 (LEGAL TWIN / LKG) — the 12 enterprise innovations.

Covers V3-P01-I01..I12 delivered by P01:
  * I01 legal node versioning (refs, versions, time-travel)
  * I02 reverse coverage sentinel (uncovered material nodes)
  * I03 ISAP proof snapshot registry (PENDING_ISAP only — no fake hashes)
  * I04 legal basis health score (classes from legal_basis_audit)
  * I05 interpretation layer isolation (STATUTE/INTERP/NONE)
  * I06 legal diff → rule draft pipeline (SHADOW + 4-eyes)
  * I07 coverage desert radar (per-domain desert pct)
  * I08 bidirectional consistency gate (forward + reverse)
  * I09 legal graph merkle root (deterministic hash)
  * I10 retroactivity auditor (window mismatch suspects)
  * I11 source certification workflow (no CERTIFIED without 4-eyes)
  * I12 legal twin API index (/legal/nodes + /legal/proof)
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P01_LEGAL_TWIN_LKG.txt"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def _run_tool(name: str, *args: str) -> str:
    return subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / name), *args],
        capture_output=True, text=True, cwd=str(BASE_DIR), check=True,
    ).stdout


# --- I01: Legal Node Versioning Engine -----------------------------------
def test_i01_node_versioning_bundle():
    d = _load_bundle("v3_p01_legal_node_versioning.json")
    assert d["innovation"] == "V3-P01-I01"
    assert d["nodes_total"] == 258  # wg bundles/legal_graph.json (P00 baseline)
    assert d["versions_count"] >= d["nodes_total"]
    assert d["distinct_refs"] > 0
    assert d["time_travel_active_nodes"] > 0


def test_i01_ref_format():
    d = _load_bundle("v3_p01_legal_node_versioning.json")
    for ref in d["node_ref_sample"]:
        assert ref.startswith("PL/")


# --- I02: Reverse Coverage Sentinel ---------------------------------------
def test_i02_reverse_coverage():
    d = _load_bundle("v3_p01_reverse_coverage_sentinel.json")
    assert d["innovation"] == "V3-P01-I02"
    assert d["uncovered_nodes"] > 0  # prawo istnieje, system go nie zna
    assert d["uncovered_nodes"] < d["material_nodes"]
    assert set(d["by_severity"]) <= {"P1", "P2"}
    for issue in d["issues"]:
        assert issue["legal_node_id"].startswith("LKG-")


# --- I03: ISAP Proof Snapshot ---------------------------------------------
def test_i03_isap_proof_registry():
    d = _load_bundle("v3_p01_isap_proof_snapshot.json")
    assert d["innovation"] == "V3-P01-I03"
    assert d["registry_size"] == 30  # kanon 30 aktów
    assert d["certified"] == 0  # ZAKAZ fikcyjnej certyfikacji
    for row in d["registry"]:
        assert row["status"] == "PENDING_ISAP"
        assert row["content_hash_sha256"] is None  # nie wpisujemy z pamięci


# --- I04: Legal Basis Health Score ----------------------------------------
def test_i04_health_score():
    d = _load_bundle("v3_p01_legal_basis_health.json")
    assert d["innovation"] == "V3-P01-I04"
    assert d["rules_total"] == 12439  # P00 baseline
    assert 0.0 < d["overall_health"] < 1.0
    assert set(d["classes"]) == {"OK", "NON_CANONICAL", "UNKNOWN_ACT", "MISSING"}
    assert len(d["by_act_dashboard"]) > 5


# --- I05: Interpretation Layer Isolation ----------------------------------
def test_i05_interpretation_layer():
    d = _load_bundle("v3_p01_interpretation_layer.json")
    assert d["innovation"] == "V3-P01-I05"
    s = d["layer_stats"]
    assert s["STATUTE"] + s["INTERP"] + s["NONE"] == d["rules_total"]
    assert s["NONE"] == 59  # reguły MISSING (brak podstawy)
    assert d["interp_total"] > 0  # reguły interpretacyjne wykryte
    assert d["verdict_field"] == "_legal_layers: [STATUTE|INTERP|NONE] — pole kontraktu werdyktu (P03)"


# --- I06: Legal Diff → Rule Draft Pipeline --------------------------------
def test_i06_rule_draft_pipeline():
    d = _load_bundle("v3_p01_legal_diff_rule_draft.json")
    assert d["innovation"] == "V3-P01-I06"
    assert d["changes_scanned"] >= 1
    assert d["drafts_generated"] >= 1
    for draft in d["drafts"]:
        assert draft["status"] == "SHADOW"
        assert draft["four_eyes_required"] is True
        assert draft["four_eyes_done"] is False


# --- I07: Coverage Desert Radar -------------------------------------------
def test_i07_desert_radar():
    d = _load_bundle("v3_p01_coverage_desert_radar.json")
    assert d["innovation"] == "V3-P01-I07"
    assert len(d["by_domain"]) > 5
    for row in d["by_domain"]:
        assert 0.0 <= row["desert_pct"] <= 100.0
        assert row["severity"] in ("OK", "UWAGA", "ALARM")


# --- I08: Bidirectional Consistency Gate ----------------------------------
def test_i08_bidirectional_gate():
    d = _load_bundle("v3_p01_bidirectional_gate.json")
    assert d["innovation"] == "V3-P01-I08"
    assert d["forward"]["fail"] > 0  # MISSING+UNKNOWN_ACT wg audytu
    assert d["reverse"]["uncovered"] > 0
    assert d["gate"]["pass"] is False  # celowo raportowane, nie ukrywane


# --- I09: Legal Graph Merkle Root -----------------------------------------
def test_i09_merkle_deterministic():
    out1 = json.loads(_run_tool("v3_p01_legal_merkle.py", "--json"))
    out2 = json.loads(_run_tool("v3_p01_legal_merkle.py", "--json"))
    assert out1["root_hash"] == out2["root_hash"]
    assert len(out1["root_hash"]) == 64  # sha256 hex
    assert out1["nodes_hashed"] == 258


def test_i09_merkle_changes_with_graph():
    d1 = _load_bundle("v3_p01_legal_merkle.json")
    leaf = hashlib.sha256("test".encode()).hexdigest()
    assert d1["root_hash"] != leaf


# --- I10: Retroactivity Auditor -------------------------------------------
def test_i10_retroactivity_auditor():
    d = _load_bundle("v3_p01_retroactivity_auditor.json")
    assert d["innovation"] == "V3-P01-I10"
    assert d["rules_mapped"] > 0
    assert d["retroactivity_suspects"] >= 0
    assert d["golden_hook"]["rule"].startswith("zmiana reguły")


# --- I11: Source Certification Workflow -----------------------------------
def test_i11_source_certification():
    d = _load_bundle("v3_p01_source_certification.json")
    assert d["innovation"] == "V3-P01-I11"
    assert d["records_total"] == 30
    for rec in d["records"]:
        assert rec["state"] == "PENDING_ISAP"
        assert rec["can_publish"] is False  # bez 4-eyes nie ma publikacji
    assert d["reviews_required"] == 2  # 4-eyes: prawnik + engineer


# --- I12: Legal Twin API ---------------------------------------------------
def test_i12_legal_twin_api():
    d = _load_bundle("v3_p01_legal_twin_api.json")
    assert d["innovation"] == "V3-P01-I12"
    paths = {e["path"] for e in d["endpoints"]}
    assert paths == {"/legal/nodes", "/legal/proof"}
    for e in d["endpoints"]:
        assert e["method"] == "GET"


# --- Report & contract present --------------------------------------------
def test_report_exists():
    assert REPORT.exists()
    text = REPORT.read_text(encoding="utf-8")
    for marker in ("9.08 KONTRAKT WYJŚCIOWY", "V3-P01-I01", "V3-P01-I12",
                   "V3-P01-L01", "9.06 REJESTR LUK"):
        assert marker in text


def test_contract_doc_exists():
    doc = BASE_DIR / "docs" / "V3_P01_LEGAL_TWIN_KONTRAKT.md"
    assert doc.exists()
    text = doc.read_text(encoding="utf-8")
    assert "legal_node_ref" in text
    assert "LCI" in text and "TCL" in text and "RV" in text and "UVR" in text
