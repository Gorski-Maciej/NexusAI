from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "docs_quality_v3_20_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p80_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_legal_twin_traceability():
    evidence = run_gate()
    assert evidence["gates"]["legal_twin_complete"]
    twin = evidence["legal_twin"]
    assert twin["trace_chain_article_rule_test"]
    assert twin["amendment_chain"]
    assert twin["evidence_present"]


def test_harmonization_manifest_v3_packages():
    evidence = run_gate()
    assert evidence["gates"]["harmonization_complete"]
    harm = evidence["harmonization"]
    assert harm["manifest_v3_packages_count"] >= 7
    assert harm["manifest_v3_packages"]["quality_v3_20"]
    assert harm["glossary_sources_registered"]


def test_user_docs_and_campaign_certified():
    evidence = run_gate()
    gate = evidence["user_docs_and_certification"]
    assert evidence["gates"]["user_docs_and_campaign_certified"]
    assert gate["decision_narrative_pl"]
    assert gate["campaign_parts_wdrozone"] >= 20
    assert gate["all_registered_parts_wdrozone"]


def test_router_wired_p80():
    evidence = run_gate()
    assert evidence["gates"]["router_wired"]
    assert evidence["contract"]["post_merge_anchor_current"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    bundle = ROOT / "bundles" / "docs_v3_audit_20.json"
    evidence = json.loads(bundle.read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert bundle.exists()
