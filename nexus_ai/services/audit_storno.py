"""Audit storno -- odwracanie transakcji księgowych z TigerBeetle usando natywnych pending/void.

- Natywne pending/void zamiast osobnych transferów
- Linked chain łączący oryginał ze stornem (atomic)
- code: 7001 dla storno
- user_data_128/64 dla metadanych
- Multi-ledger support
- Append-only: storno to nowy wpis, nie DELETE
"""

from __future__ import annotations

import uuid as uuid_module
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Protocol

import pendulum
from msgspec import Struct

from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
)


class DuckDBWriter(Protocol):
    def begin(self) -> None: ...
    def commit(self) -> None: ...
    def rollback(self) -> None: ...
    def mark_invoice_voided(self, invoice_id: str) -> None: ...
    def create_draft_from_invoice(self, invoice_id: str) -> str: ...


class LedgerTransferRecord(Struct, frozen=True):
    """Record oryginalnego transferu z TB do storna."""

    tb_transfer_id: int
    debit_account: int
    credit_account: int
    amount_minor: int
    currency: str
    source_document_id: uuid_module.UUID
    ledger: int = LEDGER["PLN"]
    code: int = TRANSFER_CODE["EXPENSE_NET"]


class StornoException(Exception):
    pass


async def reverse_transaction(
    *,
    tb_client: TigerBeetleClient,
    duckdb_writer: DuckDBWriter,
    original_transfer: LedgerTransferRecord,
    invoice_id: str,
    user_data_64: int | None = None,
) -> dict[str, Any]:
    """Odwraca transakcję księgową -- native pending transfer.

    - Natywny pending/void zamiast 2 osobnych transferów
    - Odwrócone debit<->credit (expense -> revenue)
    - code: 7001 dla storno
    - user_data_128: UUID storna
    - user_data_64: timestamp (Unix ns)
    - Append-only: TB nie pozwala na DELETE

    Args:
        tb_client: Real TigerBeetle client.
        duckdb_writer: DuckDB writer (opcjonalny).
        original_transfer: Oryginalny transfer do odwrócenia.
        invoice_id: ID faktury.
        user_data_64: Opcjonalny timestamp.

    Returns:
        Dict z statusem i szczegółami storna.
    """
    if original_transfer.amount_minor <= 0:
        raise StornoException("Original transfer amount must be positive")

    reverse_source_id = uuid_module.uuid5(
        uuid_module.NAMESPACE_URL,
        f"storno:{original_transfer.tb_transfer_id}:{invoice_id}",
    )
    timestamp_ns = user_data_64 or pendulum.now("UTC").int_timestamp * 1_000_000_000

    # Debet <-> Kredyt (odwrócenie kierunku)
    pending_id = None
    try:
        pending_id = tb_client.create_pending_transfer(
            debit_account=original_transfer.credit_account,
            credit_account=original_transfer.debit_account,
            amount_minor=int(original_transfer.amount_minor),
            source_document_id=reverse_source_id,
            ledger=original_transfer.ledger,
            code=TRANSFER_CODE["STORN"],
            user_data_64=timestamp_ns,
            user_data_32=0,
            timeout=0,
        )
    except Exception as exc:
        raise StornoException(f"TigerBeetle storno pending failed: {exc}") from exc

    if pending_id is None:
        raise StornoException("TigerBeetle storno pending creation returned no ID")

    posted = tb_client.post_pending_transfer(
        pending_id,
        ledger=original_transfer.ledger,
        code=TRANSFER_CODE["STORN"],
    )
    if not posted:
        raise StornoException("TigerBeetle storno post failed")

    # DuckDB -- oznaczenie faktury jako unieważniona
    draft_id = ""
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
        "original_transfer_id": original_transfer.tb_transfer_id,
        "reverse_pending_id": pending_id,
        "code": TRANSFER_CODE["STORN"],
        "ledger": original_transfer.ledger,
        "new_draft_id": draft_id,
        "timestamp_ns": timestamp_ns,
    }


async def create_storno_linked_chain(
    *,
    tb_client: TigerBeetleClient,
    original_transfers: list[LedgerTransferRecord],
    invoice_id: str,
) -> list[dict[str, Any]]:
    """Utwórz linked chain storno transferów.

    Wszystkie storna w jednym chainie: albo wszystkie się powiodą, albo żaden.

    Args:
        tb_client: Real TigerBeetle client.
        original_transfers: Lista oryginalnych transferów do odwrócenia.
        invoice_id: ID faktury.

    Returns:
        Lista wyników storna.
    """
    results = []

    linked_specs = []
    for original in original_transfers:
        linked_specs.append(
            {
                "debit": original.credit_account,  # Odwrócone konta
                "credit": original.debit_account,  # Odwrócone konta
                "amount": int(original.amount_minor),
                "code": TRANSFER_CODE["STORN"],
                "ledger": original.ledger,
                "user_data_64": original.tb_transfer_id,
            }
        )

    if linked_specs:
        source_uuid = uuid_module.uuid5(
            uuid_module.NAMESPACE_URL,
            f"storno-chain:{invoice_id}",
        )
        transfers = tb_client.build_linked_transfers(
            linked_specs,
            source_document_id=source_uuid,
            ledger=linked_specs[0]["ledger"],
        )

        # Batch create
        tb_results = tb_client.create_transfers(transfers)

        for i, (spec, result) in enumerate(zip(linked_specs, tb_results)):
            results.append(
                {
                    "index": i,
                    "original_transfer_id": spec["user_data_64"],
                    "debit": spec["credit"],
                    "credit": spec["debit"],
                    "amount": spec["amount"],
                    "status": str(result),
                }
            )

    return results


def decimal_to_minor_units(amount: Decimal, scale: int = 2) -> int:
    """Konwertuje Decimal na grosze (int) -- dla TigerBeetle."""
    quant = Decimal("1").scaleb(-scale)
    normalized = amount.quantize(quant, rounding=ROUND_HALF_UP)
    factor = Decimal(10) ** scale
    return int((normalized * factor).to_integral_value(rounding=ROUND_HALF_UP))
