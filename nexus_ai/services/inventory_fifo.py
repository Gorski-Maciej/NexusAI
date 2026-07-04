from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal
from typing import Any

import pendulum
from msgspec import Struct

MONEY_QUANT = Decimal("0.01")
QTY_QUANT = Decimal("0.0001")


class InventoryMismatch(Exception):  # noqa: N818
    __slots__ = ()

    pass


class DualWriteConsistencyError(InventoryMismatch):
    __slots__ = ()

    pass


class InsufficientStockError(InventoryMismatch):
    __slots__ = ()

    pass


def _to_decimal(value: Any, quant: Decimal) -> Decimal:
    return Decimal(str(value)).quantize(quant, rounding=ROUND_HALF_UP)


class InventoryBatch(Struct):
    __slots__ = ()
    batch_id: str
    product_id: str
    received_date: pendulum.Date
    remaining_qty: Decimal
    unit_cost_net: Decimal
    source_document_id: str | None = None


class FIFOConsumptionLine(Struct):
    __slots__ = ()
    batch_id: str
    product_id: str
    qty_taken: Decimal
    unit_cost_net: Decimal
    line_cogs_net: Decimal


class FIFOConsumptionResult(Struct):
    __slots__ = ()
    product_id: str
    requested_qty: Decimal
    fulfilled_qty: Decimal
    total_cogs_net: Decimal
    lines: list[FIFOConsumptionLine]


def calculate_fifo_cogs(
    product_id: str, issue_qty: Decimal | float | int, open_batches: list[InventoryBatch]
) -> FIFOConsumptionResult:
    """Consume inventory batches in FIFO order and return COGS breakdown.

    Raises InsufficientStockError when stock is insufficient.
    """

    qty_needed = _to_decimal(issue_qty, QTY_QUANT)
    if qty_needed <= Decimal("0"):
        raise InventoryMismatch("issue_qty must be greater than 0")

    fifo_batches = sorted(
        [b for b in open_batches if b.product_id == product_id and b.remaining_qty > Decimal("0")],
        key=lambda b: (b.received_date, b.batch_id),
    )

    remaining = qty_needed
    lines: list[FIFOConsumptionLine] = []
    total_cogs = Decimal("0.00")

    for batch in fifo_batches:
        if remaining <= Decimal("0"):
            break
        take_qty = min(batch.remaining_qty, remaining).quantize(QTY_QUANT, rounding=ROUND_HALF_UP)
        if take_qty <= Decimal("0"):
            continue

        line_cogs = (take_qty * batch.unit_cost_net).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)
        lines.append(
            FIFOConsumptionLine(
                batch_id=batch.batch_id,
                product_id=product_id,
                qty_taken=take_qty,
                unit_cost_net=batch.unit_cost_net,
                line_cogs_net=line_cogs,
            )
        )
        total_cogs += line_cogs
        remaining -= take_qty

    if remaining > Decimal("0"):
        raise InsufficientStockError(
            f"Insufficient inventory for product_id={product_id}; missing_qty={remaining}"
        )

    return FIFOConsumptionResult(
        product_id=product_id,
        requested_qty=qty_needed,
        fulfilled_qty=qty_needed,
        total_cogs_net=total_cogs.quantize(MONEY_QUANT, rounding=ROUND_HALF_UP),
        lines=lines,
    )


def apply_fifo_consumption(
    open_batches: list[InventoryBatch], consumption: FIFOConsumptionResult
) -> list[InventoryBatch]:
    """Return updated copies of batches after applying FIFO consumption lines."""

    updates = {line.batch_id: line.qty_taken for line in consumption.lines}
    out: list[InventoryBatch] = []
    for batch in open_batches:
        delta = updates.get(batch.batch_id, Decimal("0"))
        new_qty = (batch.remaining_qty - delta).quantize(QTY_QUANT, rounding=ROUND_HALF_UP)
        if new_qty < Decimal("0"):
            raise InventoryMismatch(f"Batch {batch.batch_id} would go negative")
        out.append(
            InventoryBatch(
                batch_id=batch.batch_id,
                product_id=batch.product_id,
                received_date=batch.received_date,
                remaining_qty=new_qty,
                unit_cost_net=batch.unit_cost_net,
                source_document_id=batch.source_document_id,
            )
        )
    return out


async def calculate_and_post_cogs(
    *,
    product_id: str,
    qty_sold: Decimal | float | int,
    open_batches: list[InventoryBatch],
    tb_client: Any,
    debit_account_731_cogs: int,
    credit_account_330_inventory: int,
    source_document_id: Any,
    duckdb_writer: Any | None = None,
) -> FIFOConsumptionResult:

    """"
    Używa code=TransferCode.COGS (5001), ledger=INVENTORY (706).
    """
    consumption = calculate_fifo_cogs(product_id, qty_sold, open_batches)
    amount_minor = int(
        (consumption.total_cogs_net * Decimal("100")).to_integral_value(rounding=ROUND_HALF_UP)
    )

    import tigerbeetle as tb

    from nexus_ai.services.tigerbeetle.client import (
        LEDGER,
        TRANSFER_CODE,
        _generate_tb_id,
        _uuid_to_u128,
    )

    source_u128 = (
        source_document_id.int
        if hasattr(source_document_id, "int")
        else _uuid_to_u128(uuid.UUID(str(source_document_id)))
    )

    transfer = tb.Transfer(
        id=_generate_tb_id(),
        debit_account_id=debit_account_731_cogs,
        credit_account_id=credit_account_330_inventory,
        amount=amount_minor,
        pending_id=0,
        user_data_128=source_u128,
        user_data_64=0,
        user_data_32=0,
        timeout=0,
        ledger=LEDGER["INVENTORY"],
        code=TRANSFER_CODE["COGS"],
        flags=0,
        timestamp=0,
    )
    results = tb_client.create_transfers([transfer])
    posted = all(r.status == 0 for r in results)

    if not posted:
        raise InventoryMismatch("Failed to post COGS transfer to TigerBeetle")

    if duckdb_writer is not None:
        try:
            if hasattr(duckdb_writer, "begin"):
                duckdb_writer.begin()
            if hasattr(duckdb_writer, "record_cogs_consumption"):
                duckdb_writer.record_cogs_consumption(consumption)
            if hasattr(duckdb_writer, "commit"):
                duckdb_writer.commit()
        except Exception as exc:
            if hasattr(duckdb_writer, "rollback"):
                duckdb_writer.rollback()
            raise DualWriteConsistencyError(
                "DuckDB write failed after TigerBeetle posting"
            ) from exc
    return consumption
