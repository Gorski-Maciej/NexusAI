from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal
from typing import Any

import pendulum
from msgspec import Struct
from structlog import get_logger

logger = get_logger("nexus.inventory_fifo")

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


# ── v7.0 AUDIT: Auto-FIFO batch creation (Raport 4.2) ──────────────────


def auto_create_batches(
    *,
    product_id: str,
    incoming_qty: Decimal | float | int,
    unit_cost_net: Decimal | float,
    source_document_id: str | None = None,
    existing_batches: list[InventoryBatch] | None = None,
) -> list[InventoryBatch]:
    """v7.0: Automatyczne tworzenie batchy FIFO.

    Eliminuje manualne tworzenie batchy — system automatycznie
    tworzy nowy batch dla każdego przyjęcia towaru.

    Args:
        product_id: ID produktu.
        incoming_qty: Ilość przyjęta.
        unit_cost_net: Cena jednostkowa netto.
        source_document_id: ID dokumentu źródłowego (faktura zakupu).
        existing_batches: Istniejące batchy (do sprawdzenia duplikatów).

    Returns:
        Lista nowych batchy (zazwyczaj jeden).
    """
    qty = _to_decimal(incoming_qty, QTY_QUANT)
    cost = _to_decimal(unit_cost_net, MONEY_QUANT)

    if qty <= Decimal("0"):
        raise InventoryMismatch("incoming_qty must be greater than 0")

    today = pendulum.now().date()

    # Sprawdź czy batch już istnieje dla tego dokumentu
    if existing_batches and source_document_id:
        for batch in existing_batches:
            if batch.source_document_id == source_document_id and batch.product_id == product_id:
                # Batch już istnieje — zwróć istniejący
                return []

    # Utwórz nowy batch
    new_batch = InventoryBatch(
        batch_id=f"BATCH-{product_id}-{today.format('YYYYMMDD')}-{source_document_id or 'DIRECT'}",
        product_id=product_id,
        received_date=today,
        remaining_qty=qty,
        unit_cost_net=cost,
        source_document_id=source_document_id,
    )

    logger.info(
        "[FIFO-AUTO] Created batch %s: qty=%s, cost=%s PLN/unit",
        new_batch.batch_id, qty, cost,
    )

    return [new_batch]


def auto_consume_fifo(
    *,
    product_id: str,
    issue_qty: Decimal | float | int,
    open_batches: list[InventoryBatch],
    tb_client: Any,
    debit_account_cogs: int,
    credit_account_inventory: int,
    source_document_id: Any,
) -> FIFOConsumptionResult:
    """v7.0: Automatyczne rozchodowanie FIFO z księgowaniem w TB.

    Łączy calculate_fifo_cogs + calculate_and_post_cogs w jednym
    wywołaniu. Eliminuje osobne wywołania.

    Args:
        product_id: ID produktu.
        issue_qty: Ilość wydawana.
        open_batches: Lista otwartych batchy.
        tb_client: Klient TigerBeetle.
        debit_account_cogs: Konto Wn kosztu własnego.
        credit_account_inventory: Konto Ma zapasów.
        source_document_id: ID dokumentu źródłowego.

    Returns:
        FIFOConsumptionResult.
    """
    import uuid as uuid_module

    # Oblicz FIFO
    consumption = calculate_fifo_cogs(product_id, issue_qty, open_batches)

    # Zaksięguj w TB
    amount_minor = int(
        (consumption.total_cogs_net * Decimal("100")).to_integral_value(rounding=ROUND_HALF_UP)
    )

    import tigerbeetle as tb

    from nexus_ai.services.tigerbeetle.client import (
        LEDGER,
        TRANSFER_CODE,
        _generate_tb_id,
    )

    # Konwersja source_document_id na u128
    if isinstance(source_document_id, str):
        try:
            src_uuid = uuid_module.UUID(source_document_id)
            source_u128 = src_uuid.int
        except (ValueError, AttributeError):
            source_u128 = 0
    else:
        source_u128 = 0

    transfer = tb.Transfer(
        id=_generate_tb_id(),
        debit_account_id=debit_account_cogs,
        credit_account_id=credit_account_inventory,
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
    if not results or results[0].status != 0:
        raise InventoryMismatch("Failed to post COGS transfer to TigerBeetle")

    logger.info(
        "[FIFO-AUTO] Consumed %s: %s units, COGS=%s PLN, batches=%d",
        product_id, consumption.fulfilled_qty,
        consumption.total_cogs_net, len(consumption.lines),
    )

    return consumption


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
