from __future__ import annotations

import importlib.util
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    mod_path = root / "Code" / "scripts" / "kore_delivery_audit.py"
    spec = importlib.util.spec_from_file_location("kore_delivery_audit", mod_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_kore_delivery_audit_passes_contracts() -> None:
    module = _load_module()
    report = module.build_report()
    assert report["overall_ok"] is True
    for section, info in report.items():
        if section == "overall_ok":
            continue
        assert info["ok"] is True
        assert info["failed"] == {}
