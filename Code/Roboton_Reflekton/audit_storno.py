from __future__ import annotations

import uuid
from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Protocol


class DuckDBWriter(Protocol):
    def begin(self) -> None: ...
    def commit(self) -> None: ...
    def rollback(self) -> None: ...
    def mark_invoice_voided(self, invoice_id: str) -> None: ...
    def create_draft_from_invoice(self, invoice_id: str) -> str: ...


@dataclass(slots=True, frozen=True)
class LedgerTransferRecord:
    transfer_id: int
    debit_account: int
    credit_account: int
    amount_minor: int
    currency: str
    source_document_id: uuid.UUID


class StornoException(Exception):
    pass


async def reverse_transaction(
    *,
    tb_client: Any,
    duckdb_writer: DuckDBWriter,
    original_transfer: LedgerTransferRecord,
    invoice_id: str,
) -> dict[str, Any]:
    if original_transfer.amount_minor <= 0:
        raise StornoException("Original transfer amount must be positive")

    reverse_source_id = uuid.uuid5(uuid.NAMESPACE_URL, f"storno:{original_transfer.transfer_id}:{invoice_id}")
    pending = await tb_client.create_two_phase_transfer(
        debit_account=original_transfer.credit_account,
        credit_account=original_transfer.debit_account,
        amount_minor=int(original_transfer.amount_minor),
        source_document_id=reverse_source_id,
    )
    posted = await tb_client.post_pending_transfer(pending.pending_id)
    if not posted:
        raise StornoException("TigerBeetle storno posting failed")

    # TigerBeetle success first; only then OLAP metadata mutation.
    try:
        duckdb_writer.begin()
        duckdb_writer.mark_invoice_voided(invoice_id)
        draft_id = duckdb_writer.create_draft_from_invoice(invoice_id)
        duckdb_writer.commit()
    except Exception as exc:
        duckdb_writer.rollback()
        raise StornoException("DuckDB storno mutation failed after TigerBeetle posting") from exc

    return {
        "status": "reversed",
        "original_transfer_id": original_transfer.transfer_id,
        "reverse_pending_id": pending.pending_id,
        "user_data_128": str(original_transfer.transfer_id),
        "new_draft_id": draft_id,
    }


def decimal_to_minor_units(amount: Decimal, scale: int = 2) -> int:
    quant = Decimal("1").scaleb(-scale)
    normalized = amount.quantize(quant, rounding=ROUND_HALF_UP)
    factor = Decimal(10) ** scale
    return int((normalized * factor).to_integral_value(rounding=ROUND_HALF_UP))
