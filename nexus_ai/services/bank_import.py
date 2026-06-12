from __future__ import annotations

import csv
import uuid
from msgspec import Struct

# ── SHA-256 przez nexus-crypto (Rust+PyO3) zgodnie z aa3fvcx.txt ─────────
try:
    from nexus_crypto import sha256 as _sha256
    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib
    HAS_NEXUS_CRYPTO = False

    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()
from decimal import Decimal
from pathlib import Path
from typing import Protocol

import pendulum

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

class DuplicateTransferError(RuntimeError):
    pass

class BankTransaction(Struct):
    booking_date: date
    amount: Decimal
    title: str
    counterparty_account: str
    balance_after: Decimal
    source_account_id: int
    destination_account_id: int

    @property
    def amount_cents(self) -> int:
        return int((self.amount * 100).quantize(Decimal("1")))

class StatementParser(Protocol):
    def parse(self, file_path: Path) -> list[BankTransaction]: ...

class CSVStatementParser:
    """Reference parser for local CSV exports from banks."""

    def parse(self, file_path: Path) -> list[BankTransaction]:
        rows: list[BankTransaction] = []
        with file_path.open("r", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for raw in reader:
                rows.append(
                    BankTransaction(
                        booking_date=pendulum.strptime(raw["booking_date"], "%Y-%m-%d").date(),
                        amount=Decimal(raw["amount"]),
                        title=raw.get("title", "").strip(),
                        counterparty_account=raw.get("counterparty_account", "").strip(),
                        balance_after=Decimal(raw["balance_after"]),
                        source_account_id=int(raw["source_account_id"]),
                        destination_account_id=int(raw["destination_account_id"]),
                    )
                )
        return rows

class ParserFactory:
    @staticmethod
    def get_parser(file_path: Path) -> StatementParser:
        if file_path.suffix.lower() == ".csv":
            return CSVStatementParser()
        raise ValueError(f"Unsupported statement format: {file_path.suffix}")

def generate_idempotency_id(tx: BankTransaction) -> uuid.UUID:
    raw = f"{tx.booking_date.isoformat()}|{tx.amount}|{tx.title}|{tx.counterparty_account}|{tx.balance_after}"
    digest = _sha256(raw.encode("utf-8"))
    return uuid.uuid5(uuid.NAMESPACE_DNS, digest)

class StatementContinuityError(RuntimeError):
    pass

class IdempotentBankImporter:
    def __init__(self, *, tb_client: TigerBeetleClient, duckdb: DuckDBManager, ledger_id: int = 1, transfer_code: int = 777):
        self.tb_client = tb_client
        self.duckdb = duckdb
        self.ledger_id = ledger_id
        self.transfer_code = transfer_code
        self._ensure_history_schema()

    def _ensure_history_schema(self) -> None:
        self.duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS bank_history (
                tx_id VARCHAR PRIMARY KEY,
                booking_date DATE,
                amount DECIMAL(18, 2),
                title VARCHAR,
                counterparty_account VARCHAR,
                balance_after DECIMAL(18, 2),
                source_account_id BIGINT,
                destination_account_id BIGINT,
                imported_at TIMESTAMP DEFAULT now()
            )
            """
        )

    def validate_balance_continuity(self, transactions: list[BankTransaction]) -> None:
        if not transactions:
            return
        last = self.duckdb.execute("SELECT balance_after FROM bank_history ORDER BY booking_date DESC, imported_at DESC LIMIT 1")
        if not last:
            return
        expected_opening = Decimal(str(last[0][0]))
        if transactions[0].balance_after - transactions[0].amount != expected_opening:
            raise StatementContinuityError(
                f"Balance continuity check failed. Expected opening {expected_opening}, got {(transactions[0].balance_after - transactions[0].amount)}"
            )

    async def import_file(self, file_path: Path) -> dict[str, int]:
        parser = ParserFactory.get_parser(file_path)
        transactions = parser.parse(file_path)
        transactions.sort(key=lambda t: t.booking_date)
        self.validate_balance_continuity(transactions)

        imported = 0
        duplicates = 0
        for tx in transactions:
            tx_uuid = generate_idempotency_id(tx)
            tx_id = str(tx_uuid)
            exists = self.duckdb.execute("SELECT 1 FROM bank_history WHERE tx_id = ? LIMIT 1", (tx_id,))
            if exists:
                duplicates += 1
                continue

            try:
                await self.tb_client.create_two_phase_transfer(
                    debit_account=tx.source_account_id,
                    credit_account=tx.destination_account_id,
                    amount_minor=tx.amount_cents,
                    source_document_id=tx_uuid,
                )
            except Exception as exc:
                if "exists" in str(exc).lower():
                    duplicates += 1
                    continue
                raise

            self.duckdb.execute(
                """
                INSERT INTO bank_history
                (tx_id, booking_date, amount, title, counterparty_account, balance_after, source_account_id, destination_account_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    tx_id,
                    tx.booking_date,
                    tx.amount,
                    tx.title,
                    tx.counterparty_account,
                    tx.balance_after,
                    tx.source_account_id,
                    tx.destination_account_id,
                ),
            )
            imported += 1

        return {"imported": imported, "duplicates": duplicates, "total": len(transactions)}
