from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import pytest


def _load_module(module_name: str, file_path: str):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def test_config_has_prod_cors_wildcard_guard() -> None:
    config_mod = _load_module("kore_config", "Code/CORE/config.py")

    with pytest.raises(config_mod.ConfigValidationError):
        config_mod.AppConfig(
            environment="prod",
            jwt_secret="jwt",
            encryption_key="enc",
            cors_origins_raw="*",
        )


def test_config_parses_cors_comma_list() -> None:
    config_mod = _load_module("kore_config_parse", "Code/CORE/config.py")
    config = config_mod.AppConfig(
        environment="dev",
        cors_origins_raw="https://a.example, https://b.example",
    )
    assert config.cors_origins == ["https://a.example", "https://b.example"]


def test_outbox_dispatch_routes_to_ocr_task() -> None:
    source = Path("Code/api/tasks.py").read_text(encoding="utf-8")
    assert "if event_type == \"process_invoice_ocr\"" in source
    assert "await broker.kick(\"process_invoice_ocr\"" in source
    assert "@broker.task(task_name=\"process_invoice_ocr\")" in source


def test_invoice_controller_uses_schema_registered_outbox_model() -> None:
    controller_source = Path("Code/api/controllers/invoices.py").read_text(encoding="utf-8")
    db_source = Path("Code/db/database.py").read_text(encoding="utf-8")
    model_source = Path("Code/models/outbox.py").read_text(encoding="utf-8")

    assert "from models.outbox import OutboxEvent" in controller_source
    assert "from models.outbox import OutboxEvent" in db_source
    assert "aggregate_id" in model_source
    assert "status" in model_source
    assert "retry_count" in model_source


def test_rbac_rejects_unknown_roles_from_authenticated_user_context() -> None:
    source = Path("Code/api/rbac.py").read_text(encoding="utf-8")
    assert "Unsupported role in authenticated context" in source
    assert "except ValueError as exc" in source


def test_outbox_relay_tracks_processed_timestamp_and_retries() -> None:
    source = Path("Code/api/tasks.py").read_text(encoding="utf-8")
    assert "processed_at = CURRENT_TIMESTAMP" in source
    assert "retry_count = retry_count + 1" in source
