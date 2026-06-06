from __future__ import annotations

from pathlib import Path


def test_kore_closure_controller_registered() -> None:
    source = Path("Code/api/app.py").read_text(encoding="utf-8")
    assert "KoreClosureController" in source


def test_kore_closure_endpoint_exists() -> None:
    source = Path("Code/api/routes/kore_closure.py").read_text(encoding="utf-8")
    assert 'path = "/api/v1/system/kore"' in source
    assert '@get("/closure")' in source
    assert "kore_delivery_audit.py" in source
    assert "security_scan_summary.json" in source
    assert "runtime_counters" in source
    assert "from sqlalchemy import text" in source
    assert "__import__(\"sqlalchemy\")" not in source
