from datetime import date
from decimal import Decimal
from pathlib import Path
import importlib.util
import sys
import types


def _load_module(path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


fifo = _load_module(Path(__file__).resolve().parents[1] / "Code" / "SERVICES" / "inventory_fifo.py", "fifo_module")
InventoryBatch = fifo.InventoryBatch
calculate_fifo_cogs = fifo.calculate_fifo_cogs
apply_fifo_consumption = fifo.apply_fifo_consumption


def test_calculate_fifo_cogs_consumes_oldest_batches_first() -> None:
    batches = [
        InventoryBatch("b1", "SKU-1", date(2026, 1, 1), Decimal("3.0000"), Decimal("10.00")),
        InventoryBatch("b2", "SKU-1", date(2026, 1, 5), Decimal("5.0000"), Decimal("12.00")),
    ]

    result = calculate_fifo_cogs("SKU-1", Decimal("6.0000"), batches)

    assert result.total_cogs_net == Decimal("66.00")
    assert [(l.batch_id, l.qty_taken) for l in result.lines] == [
        ("b1", Decimal("3.0000")),
        ("b2", Decimal("3.0000")),
    ]


def test_apply_fifo_consumption_updates_remaining_quantities() -> None:
    batches = [
        InventoryBatch("b1", "SKU-1", date(2026, 1, 1), Decimal("3.0000"), Decimal("10.00")),
        InventoryBatch("b2", "SKU-1", date(2026, 1, 5), Decimal("5.0000"), Decimal("12.00")),
    ]
    consumed = calculate_fifo_cogs("SKU-1", Decimal("6.0000"), batches)

    updated = apply_fifo_consumption(batches, consumed)

    assert updated[0].remaining_qty == Decimal("0.0000")
    assert updated[1].remaining_qty == Decimal("2.0000")


def test_calculate_fifo_cogs_raises_on_insufficient_stock() -> None:
    batches = [InventoryBatch("b1", "SKU-1", date(2026, 1, 1), Decimal("1.0000"), Decimal("10.00"))]

    try:
        calculate_fifo_cogs("SKU-1", Decimal("2.0000"), batches)
        raise AssertionError("Expected ValueError")
    except ValueError as exc:
        assert "Insufficient inventory" in str(exc)


def test_inventory_schema_creates_batches_table() -> None:
    db_module = types.ModuleType("db")
    analytics_module = types.ModuleType("db.analytics")
    analytics_module.DuckDBManager = object
    db_module.analytics = analytics_module
    sys.modules.setdefault("db", db_module)
    sys.modules.setdefault("db.analytics", analytics_module)

    telemetry = types.ModuleType("services.telemetry")
    telemetry.ensure_telemetry_schema = lambda _: None
    sys.modules.setdefault("services.telemetry", telemetry)

    fingerprint = types.ModuleType("services.document_fingerprint")
    fingerprint.ensure_fingerprint_schema = lambda _: None
    sys.modules.setdefault("services.document_fingerprint", fingerprint)

    zpk = types.ModuleType("db.zpk_schema")
    zpk.ensure_zpk_schema = lambda _: None
    sys.modules.setdefault("db.zpk_schema", zpk)

    schema = _load_module(Path(__file__).resolve().parents[1] / "Code" / "DB" / "analytics_schema.py", "schema_module")

    class FakeMgr:
        def __init__(self):
            self.queries = []

        def execute(self, query: str):
            self.queries.append(query)
            return []

    mgr = FakeMgr()
    schema.ensure_inventory_schema(mgr)

    sql = "\n".join(mgr.queries)
    assert "CREATE TABLE IF NOT EXISTS inventory_batches" in sql
    assert "CREATE TABLE IF NOT EXISTS inventory_consumption_lines" in sql
