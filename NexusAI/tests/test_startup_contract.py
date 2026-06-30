from __future__ import annotations

import ast
from pathlib import Path


def _parse(path: str) -> ast.Module:
    return ast.parse(Path(path).read_text(encoding="utf-8"))


def test_single_create_app_factory_exists() -> None:
    module = _parse("nexus_ai/api/app.py")
    create_app_defs = [n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == "create_app"]
    assert len(create_app_defs) == 1


def test_server_uses_unified_create_app() -> None:
    source = Path("nexus_ai/api/server.py").read_text(encoding="utf-8")
    assert "from nexus_ai.api.app import create_app" in source
    assert "granian.Granian" in source


def test_v1_and_v2_paths_defined() -> None:
    source = Path("nexus_ai/api/app.py").read_text(encoding="utf-8")
    assert "/api/v2/health" in source
    assert "InvoiceController" in source


def test_no_old_tech_imports() -> None:
    """Verify no old technology imports remain in source code."""
    api_source = Path("nexus_ai/api/app.py").read_text(encoding="utf-8")
    assert "fastapi" not in api_source.lower()
    assert "starlette" not in api_source.lower()
