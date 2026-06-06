from __future__ import annotations

import ast
from pathlib import Path


def test_auth_service_has_hash_and_verify() -> None:
    source = Path("Code/api/auth_service.py").read_text(encoding="utf-8")
    module = ast.parse(source)
    fn_names = {n.name for n in module.body if isinstance(n, ast.FunctionDef)}
    assert "hash_password" in fn_names
    assert "verify_password" in fn_names


def test_login_uses_verify_password() -> None:
    source = Path("Code/api/routes/auth.py").read_text(encoding="utf-8")
    assert "verify_password(" in source
    assert "password_hash" in source
