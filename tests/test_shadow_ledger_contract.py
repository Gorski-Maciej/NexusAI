from __future__ import annotations

import ast
from pathlib import Path


def _parse(path: str) -> ast.Module:
    return ast.parse(Path(path).read_text(encoding="utf-8"))


def test_shadow_ledger_module_contains_tax_simulator() -> None:
    module = _parse("Roboton_Reflekton/shadow_ledger.py")
    class_names = {node.name for node in module.body if isinstance(node, ast.ClassDef)}
    assert "TaxSimulator" in class_names


def test_shadow_ledger_mentions_polars_and_duckdb() -> None:
    source = Path("Roboton_Reflekton/shadow_ledger.py").read_text(encoding="utf-8")
    assert "import polars as pl" in source
    assert "import duckdb" in source
    assert "run_shadow_simulation" in source
