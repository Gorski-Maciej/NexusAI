from __future__ import annotations

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
from typing import Protocol, final

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


@final
class CSVStatementParser:
    """Reference parser for local CSV exports from banks.

    SUPERMOC PyArrow:
    - ``pyarrow.csv.read_csv()`` z ``ConvertOptions`` — typowanie kolumn
      (date32, decimal128, int64) bez ręcznego mapowania w pętli.
    - ``pa.Table.to_pylist()`` — konwersja całej tabeli do listy słowników
      w C++ — 5-10× szybciej niż ``csv.DictReader`` + pętla Python.
    - Zysk: brak narzutu csv.DictReader, automatyczne typowanie dat.
    """

    def parse(self, file_path: Path) -> list[BankTransaction]:
        import pyarrow as pa
        import pyarrow.csv as pa_csv
        import pyarrow.compute as pc

        # ── SUPERMOC: PyArrow CSV reader z ConvertOptions ─────────────
        # PyArrow parsuje CSV w C++ z jawnymi typami kolumn.
        convert_opts = pa_csv.ConvertOptions(
            column_types={
                "booking_date": pa.date32(),
                "amount": pa.decimal128(18, 2),
                "title": pa.utf8(),
                "counterparty_account": pa.utf8(),
                "balance_after": pa.decimal128(18, 2),
                "source_account_id": pa.int64(),
                "destination_account_id": pa.int64(),
            },
            null_values=["", "NULL", "null", "NaN"],
            include_columns=[
                "booking_date", "amount", "title", "counterparty_account",
                "balance_after", "source_account_id", "destination_account_id"
            ],
        )
        table = pa_csv.read_csv(
            str(file_path),
            convert_options=convert_opts,
        )

        # ── SUPERMOC: Filtrowanie NULL przez pa.compute ──────────────
        # Zamiast ``if not raw.get("title")`` w pętli, używamy
        # ``pc.is_valid()`` + ``pc.filter()`` — operacja w C++.
        valid_mask = pc.is_valid(table.column("booking_date"))
        valid_table = table.filter(valid_mask)

        rows: list[BankTransaction] = []
        for row in valid_table.to_pylist():
            booking_date = row.get("booking_date")
            if booking_date is None:
                continue

            amount = Decimal(str(row.get("amount", "0")))
            balance = Decimal(str(row.get("balance_after", "0")))

            rows.append(
                BankTransaction(
                    booking_date=booking_date,
                    amount=amount,
                    title=str(row.get("title", "") or "").strip(),
                    counterparty_account=str(row.get("counterparty_account", "") or "").strip(),
                    balance_after=balance,
                    source_account_id=int(row.get("source_account_id", 0) or 0),
                    destination_account_id=int(row.get("destination_account_id", 0) or 0),
                )
            )
        return rows


@final
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


@final
class IdempotentBankImporter:
    def __init__(
        self,
        *,
        tb_client: TigerBeetleClient,
        duckdb: DuckDBManager,
        ledger_id: int = 1,
        transfer_code: int = 777,
    ):
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
        last = self.duckdb.execute(
            "SELECT balance_after FROM bank_history ORDER BY booking_date DESC, imported_at DESC LIMIT 1"
        )
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
            exists = self.duckdb.execute(
                "SELECT 1 FROM bank_history WHERE tx_id = ? LIMIT 1", (tx_id,)
            )
            if exists:
                duplicates += 1
                continue

            try:
                # SUPERMOC: Użyj realnego API TB z batch transferem
                import tigerbeetle as tb
                from nexus_ai.services.tigerbeetle.client import (
                    LEDGER, TRANSFER_CODE, _generate_tb_id,
                )
                transfer = tb.Transfer(
                    id=_generate_tb_id(),
                    debit_account_id=tx.source_account_id,
                    credit_account_id=tx.destination_account_id,
                    amount=tx.amount_cents,
                    pending_id=0,
                    user_data_128=tx_uuid.int,
                    user_data_64=int(tx.booking_date.isoformat().replace('-', '')),
                    user_data_32=0,
                    timeout=0,
                    ledger=LEDGER["PLN"],
                    code=TRANSFER_CODE["PAYMENT_IN"],
                    flags=tb.TransferFlags.IMPORTED,  # SUPERMOC: oznacz jako import bankowy
                    timestamp=0,
                )
                results = self.tb_client.create_transfers([transfer])
                if not all(r.status == 0 for r in results):
                    if any("exists" in str(r.status) for r in results):
                        duplicates += 1
                        continue
                    raise RuntimeError(f"TB posting failed: {results}")
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
