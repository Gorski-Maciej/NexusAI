"""Acceptance tests for PROMPT_24 Legal Twin infrastructure (F1)."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
import sys

sys.path.insert(0, str(JDG_ROOT / "tools"))

import lkg_generator as lkg  # noqa: E402
import reverse_coverage_detector as rcd  # noqa: E402


def test_lkg_generator_parses_bbb_and_dedups(tmp_path):
    """F1: Bbb.md → węzły LKG; dedup po (act, article); węzły materialne."""
    rows = lkg.parse_bbb()
    assert len(rows) >= 10, "Bbb.md powinien zawierać co najmniej 10 aktów"
    acts = [r["act"] for r in rows]
    assert any("VAT" in a or "towarów i usług" in a for a in acts)

    # build na kopii ścieżek (bez zapisu do repo)
    lkg.BBB_MD = JDG_ROOT / "docs" / "Bbb.md"
    nodes, added = lkg.build_nodes()
    assert added >= 0
    # dedup: brak dwóch węzłów o tym samym (act, article)
    keys = [(n["act"], n["article"]) for n in nodes]
    assert len(keys) == len(set(keys))
    material = [n for n in nodes if n.get("material")]
    assert len(material) > 0
    for n in material:
        assert n["node_type"] == "ARTICLE"
        assert n["valid_from"]
        assert n["domain"]


def test_lkg_seed_sql_has_inserts(tmp_path):
    """F1: seed SQL do DuckDB (tabela legal_graph)."""
    graph = {"nodes": [
        {"legal_node_id": "LKG-0001", "act": "Ustawa o VAT", "article": "113",
         "node_type": "ARTICLE", "domain": "vat", "material": True,
         "valid_from": "2004-01-01", "valid_to": None, "version": 1,
         "status": "OBOWIAZUJACY", "source": "Bbb.md", "rules": []},
    ]}
    lkg.GRAPH_PATH = tmp_path / "legal_graph.json"
    lkg.SEED_PATH = tmp_path / "legal_graph_seed.sql"
    lkg.GRAPH_PATH.write_text(json.dumps(graph), encoding="utf-8")
    lkg.cmd_seed(type("A", (), {})())
    sql = lkg.SEED_PATH.read_text(encoding="utf-8")
    assert "CREATE TABLE IF NOT EXISTS legal_graph" in sql
    assert "INSERT INTO legal_graph" in sql
    assert "LKG-0001" in sql


def test_reverse_coverage_scans_and_flags_uncovered(tmp_path):
    """F1: reverse coverage — artykuł bez reguły = luka, pokryty = rules list."""
    # zapisujemy testowy graf do tmp (żeby nie ruszać repo)
    lkg_bak = rcd.GRAPH_PATH
    gaps_bak = rcd.GAPS_PATH
    rcd.GRAPH_PATH = tmp_path / "legal_graph.json"
    rcd.GAPS_PATH = tmp_path / "legal_coverage_gaps.json"
    rcd.RULES_DIR = tmp_path / "rules"
    (rcd.RULES_DIR / "vat").mkdir(parents=True)
    (rcd.RULES_DIR / "vat" / "test.rego").write_text(
        '"rule_id": "jdg.vat.test.r1", "_legal_basis": "Art. 113 ustawy o VAT"',
        encoding="utf-8")
    graph = {"schema_version": "2.0.0", "nodes": [
        {"legal_node_id": "LKG-0001", "act": "Ustawa z dnia 11 marca 2004 r. o podatku od towarów i usług",
         "article": "113", "node_type": "ARTICLE", "domain": "vat", "material": True,
         "valid_from": "2004-01-01", "rules": []},
        {"legal_node_id": "LKG-0002", "act": "Ustawa z dnia 11 marca 2004 r. o podatku od towarów i usług",
         "article": "43", "node_type": "ARTICLE", "domain": "vat", "material": True,
         "valid_from": "2004-01-01", "rules": []},
    ], "indexes": {"LCI": 0.0, "TCL": 0.0, "RV": 0.0}}
    rcd.GRAPH_PATH.write_text(json.dumps(graph), encoding="utf-8")
    try:
        result = rcd.scan()
        assert result["rules_scanned"] == 1
        assert result["covered_nodes"] == 1
        gaps = rcd.gaps()
        assert gaps["by_status"]["UNCOVERED"] == 1
        assert gaps["reverse_coverage"]["gaps"][0]["article"] == "43"
        assert gaps["reverse_coverage"]["gaps"][0]["priority"] == "P1"
    finally:
        rcd.GRAPH_PATH = lkg_bak
        rcd.GAPS_PATH = gaps_bak
        rcd.RULES_DIR = JDG_ROOT / "rules"


def test_report24_gate_produces_evidence_and_full_gates():
    """Bramka raportu 24: 11/11 bramek i status WDROZONY_100."""
    import legal_twin_report24_gate as gate

    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100", evidence["gate_summary"]
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"] == 11
    assert evidence["production_status"] == "NOT_CERTIFIED"
    assert evidence["scope"]["all_present"] is True
    assert evidence["syntax"]["syntax_ok"] is True
    assert evidence["lkg"]["has_material_nodes"] is True
    assert evidence["metric_gates"]["TCL_100"] is True
