from __future__ import annotations

import importlib.util
import sys
import types
from pathlib import Path

import pytest


def _load_ui_state_module():
    root = Path(__file__).resolve().parents[1]
    module_path = root / "Code" / "api" / "routes" / "ui_state.py"
    spec = importlib.util.spec_from_file_location("api_ui_state", module_path)
    assert spec and spec.loader

    if "api" not in sys.modules:
        sys.modules["api"] = types.ModuleType("api")
    if "api.rbac" not in sys.modules:
        rbac_mod = types.ModuleType("api.rbac")
        rbac_mod.owner_or_worker_guard = lambda *args, **kwargs: None
        sys.modules["api.rbac"] = rbac_mod

    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def test_ui_state_validation_helpers_runtime() -> None:
    mod = _load_ui_state_module()

    assert mod.validate_draft_key("  invoice-form  ") == "invoice-form"
    with pytest.raises(Exception):
        mod.validate_draft_key("")

    payload = {"k": "v"}
    dumped = mod.serialize_draft_payload(payload)
    assert '"k": "v"' in dumped

    too_large = {"blob": "x" * (mod.MAX_DRAFT_BYTES + 10)}
    with pytest.raises(Exception):
        mod.serialize_draft_payload(too_large)
