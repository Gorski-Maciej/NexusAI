"""Acceptance tests for AD-01/AD-02 — Canonical Coverage Unifier (coverage_unifier.py)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))

import coverage_unifier as cu  # noqa: E402


def test_scan_finds_all_rules_and_verdict_fields():
    """scan_rules() zwraca bloki z rule_id, matched, _legal_basis, priority."""
    rules = cu.scan_rules()
    assert len(rules) > 1000, "silnik ma tysiące bloków decide/else"
    sample = [r for r in rules if r["matched"] and r["legal_basis"]][0]
    assert sample["rule_id"].startswith("jdg.")
    assert sample["priority"] >= 0
    assert sample["file"].startswith("rules/")


def test_no_match_and_skeleton_classification():
    """no_match/fallback i szkielety są odróżniane od reguł dowodnych."""
    rules = cu.scan_rules()
    no_match = [r for r in rules if cu.is_no_match_rule(r)]
    actionable = [r for r in rules if not cu.is_no_match_rule(r)]
    skeletons = [r for r in actionable if cu.is_skeleton(r)]
    evidence = [r for r in actionable if cu.is_evidence_backed(r)]
    assert len(no_match) + len(skeletons) + len(evidence) == len(rules)
    assert len(evidence) > len(skeletons)


def test_metrics_have_explicit_denominators():
    """Metryki kanoniczne mają jawne mianowniki i są spójne wewnętrznie."""
    rules = cu.scan_rules()
    graph = cu.load_graph()
    m = cu.compute_metrics(rules, graph)
    d = m["denominators"]
    assert d["rules_total"] == len(rules)
    assert d["rules_no_match"] + d["rules_skeleton"] + d["rules_evidence_backed"] == d["rules_total"]
    assert 0 <= m["metrics"]["LCI"] <= 100
    assert 0 <= m["metrics"]["TCL"] <= 100
    assert 0 <= m["metrics"]["RV"] <= 100
    assert m["metrics"]["UVR"] >= 0
    assert m["metrics"]["DOC50"] is None or 0 <= m["metrics"]["DOC50"] <= 100


def test_canon_json_written_and_consistent():
    """build() zapisuje coverage_canon.json spójny z policzonymi metrykami."""
    cu.CANON_PATH = JDG_ROOT / "bundles" / "coverage_canon.json"
    m = cu.build()
    assert cu.CANON_PATH.exists()
    saved = json.loads(cu.CANON_PATH.read_text(encoding="utf-8"))
    assert saved["metrics"]["LCI"] == m["metrics"]["LCI"]
    assert saved["denominators"]["rules_total"] == m["denominators"]["rules_total"]


def test_report_render_contains_reconciliation():
    """Raport kanoniczny tłumaczy rozjazd metryk (DOC50 vs LCI vs STRUCT)."""
    rules = cu.scan_rules()
    graph = cu.load_graph()
    m = cu.compute_metrics(rules, graph)
    md = cu.render_report(m)
    assert "LCI" in md and "TCL" in md and "RV" in md and "UVR" in md
    assert "Rekoncyliacja" in md
    assert "inny byt" in md


def test_doc50_and_manifest_loaders():
    """Loadery DOC50/STRUCT są odporne na brak plików."""
    d50 = cu.load_doc50()
    man = cu.load_manifest()
    assert d50 is None or isinstance(d50["coverage_pct"], int)
    assert man is None or isinstance(man["completeness_score"], int)


def test_ad02_lkg_domain_fix():
    """AD-02: węzły 'PIT, art. 26e'/'Ustawa o VAT, art. 99' nie są już 'other'."""
    graph = cu.load_graph()
    nodes = graph.get("nodes", [])
    for n in nodes:
        act = (n.get("act") or "").lower()
        if "pit, art." in act or "ustawa o pit" in act:
            assert n.get("domain") == "pit", f"{n['legal_node_id']} powinien być pit"
        if "ustawa o vat" in act:
            assert n.get("domain") == "vat", f"{n['legal_node_id']} powinien być vat"
        if "kodeks karny skarbowy" in act:
            assert n.get("domain") != "other", f"{n['legal_node_id']} nie może być other"


def test_ad02_vat_a109_legal_basis():
    """AD-02: reguły a109 (ewidencja VAT) mają podstawę 'Art. 109' — traceability."""
    rules = cu.scan_rules()
    a109 = [r for r in rules if r["rule_id"].startswith("jdg.micro.vat.a109")]
    assert len(a109) >= 10
    assert all("Art. 109" in r["legal_basis"] for r in a109)
    fin = [r for r in rules if r["rule_id"].startswith("jdg.final.a109")]
    assert all("Art. 109" in r["legal_basis"] for r in fin)


def test_ad02_lci_closure_100():
    """AD-02: po naprawie domen i podstaw prawnych LCI = 100% (70/70)."""
    rules = cu.scan_rules()
    graph = cu.load_graph()
    m = cu.compute_metrics(rules, graph)
    assert m["metrics"]["LCI"] == 100.0
    assert m["denominators"]["lkg_material_nodes"] == 70
    assert m["denominators"]["lkg_covered_material_nodes"] == 70
