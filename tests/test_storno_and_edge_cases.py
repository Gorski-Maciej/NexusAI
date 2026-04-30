from __future__ import annotations

import asyncio
import importlib.util
import sys
import uuid
from datetime import date
from decimal import Decimal
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from Roboton_Reflekton.audit_storno import LedgerTransferRecord, decimal_to_minor_units, reverse_transaction
from Roboton_Reflekton.ledger_client import TigerBeetleClient


def _load_module(path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


fifo = _load_module(Path(__file__).resolve().parents[1] / "Code" / "SERVICES" / "inventory_fifo.py", "fifo_storno_module")
InventoryBatch = fifo.InventoryBatch
InsufficientStockError = fifo.InsufficientStockError
calculate_fifo_cogs = fifo.calculate_fifo_cogs


class FakeDuckDBWriter:
    def __init__(self) -> None:
        self.voided: list[str] = []
        self.drafts: list[str] = []
        self.tx_events: list[str] = []

    def begin(self) -> None:
        self.tx_events.append("begin")

    def commit(self) -> None:
        self.tx_events.append("commit")

    def rollback(self) -> None:
        self.tx_events.append("rollback")

    def mark_invoice_voided(self, invoice_id: str) -> None:
        self.voided.append(invoice_id)

    def create_draft_from_invoice(self, invoice_id: str) -> str:
        draft = f"draft-{invoice_id}"
        self.drafts.append(draft)
        return draft


def test_last_unit_inventory_succeeds_and_extra_unit_fails() -> None:
    batches = [InventoryBatch("b1", "SKU-X", date(2026, 2, 1), Decimal("1.0000"), Decimal("99.99"))]
    ok = calculate_fifo_cogs("SKU-X", Decimal("1.0000"), batches)
    assert ok.total_cogs_net == Decimal("99.99")

    try:
        calculate_fifo_cogs("SKU-X", Decimal("1.0001"), batches)
        raise AssertionError("Expected InsufficientStockError")
    except InsufficientStockError:
        pass


def test_currency_invoice_correction_storno_links_original_transfer() -> None:
    async def run() -> None:
        tb = TigerBeetleClient()
        writer = FakeDuckDBWriter()
        amount_minor = decimal_to_minor_units(Decimal("120.05"))
        original = LedgerTransferRecord(
            transfer_id=987654321,
            debit_account=201,
            credit_account=700,
            amount_minor=amount_minor,
            currency="PLN",
            source_document_id=uuid.uuid4(),
        )
        result = await reverse_transaction(tb_client=tb, duckdb_writer=writer, original_transfer=original, invoice_id="INV-FX-1")
        assert result["status"] == "reversed"
        assert result["user_data_128"] == str(original.transfer_id)
        assert writer.voided == ["INV-FX-1"]
        assert writer.drafts == ["draft-INV-FX-1"]
        assert writer.tx_events == ["begin", "commit"]

    asyncio.run(run())
