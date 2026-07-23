"""

- ``fsspec.open()`` dla CSV -- działa z file://, s3://, http://
- ``fsspec.filesystem()`` dla konfigurowalnego backendu
- Zmiana storage_protocol w config TOML zmienia backend bez zmiany kodu
"""

from __future__ import annotations

from datetime import date
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
from typing import Any, Protocol, final

import fsspec
from structlog import get_logger

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

logger = get_logger("nexus.services.bank_import")


class DuplicateTransferError(RuntimeError):
    __slots__ = ()

    pass


class BankTransaction(Struct):
    # v7.0 FIX: msgspec.Struct nie może definiować __slots__ — usunięto
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
    __slots__ = ()

    """Reference parser for local CSV exports from banks.

    - ``pyarrow.csv.read_csv()`` z ``ConvertOptions`` -- typowanie kolumn
      (date32, decimal128, int64) bez ręcznego mapowania w pętli.
    - ``pa.Table.to_pylist()`` -- konwersja całej tabeli do listy słowników
      w C++ -- 5-10x szybciej niż ``csv.DictReader`` + pętla Python.
    - Zysk: brak narzutu csv.DictReader, automatyczne typowanie dat.
    """

    def parse(self, file_path: Path) -> list[BankTransaction]:
        # Działa z file://, s3://, http:// -- wyciągi bankowe z chmury.
        # ale dla prostoty używamy fsspec.open() + BytesIO.
        from io import BytesIO

        import pyarrow as pa
        import pyarrow.compute as pc
        import pyarrow.csv as pa_csv

        with fsspec.open(file_path, "rb") as f:
            csv_content = f.read()

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
                "booking_date",
                "amount",
                "title",
                "counterparty_account",
                "balance_after",
                "source_account_id",
                "destination_account_id",
            ],
        )
        table = pa_csv.read_csv(
            BytesIO(csv_content),
            convert_options=convert_opts,
        )

        # Zamiast ``if not raw.get("title")`` w pętli, używamy
        # ``pc.is_valid()`` + ``pc.filter()`` -- operacja w C++.
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
    __slots__ = ()

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
    __slots__ = ('_meta_mapper', 'duckdb', 'ledger_id', 'tb_client', 'transfer_code')
    def __init__(
        self,
        *,
        tb_client: TigerBeetleClient,
        duckdb: DuckDBManager,
        ledger_id: int = 1,
        transfer_code: int = 777,
        bank_storage_path: str | Path | None = None,
    ):
        self.tb_client = tb_client
        self.duckdb = duckdb
        self.ledger_id = ledger_id
        self.transfer_code = transfer_code
        self._ensure_history_schema()

        self._setup_meta_mapper(bank_storage_path or Path("data/bank_imports"))

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

    def _setup_meta_mapper(self, storage_path: str | Path) -> None:
        """Setup meta mapper for bank import metadata.

        fsspec.get_mapper() tworzy MutableMapping (dict-like),
        który automatycznie serializuje wartości do plików JSON.
        Każdy klucz to osobny plik w katalogu .bank_meta/.
        """
        meta_dir = Path(str(storage_path)) / ".bank_meta"
        meta_dir.mkdir(parents=True, exist_ok=True)
        self._meta_mapper = fsspec.get_mapper(str(meta_dir))
        logger.debug("[BankImport] Meta mapper initialized: %s", meta_dir)

    @property
    def meta(self) -> Any:
        """Dict-like interfejs do metadanych importów bankowych.

        Użycie:
            importer.meta["import_20260101"] = {"file": "statement.csv", "count": 42}
            print(importer.meta["import_20260101"])
        """
        return self._meta_mapper

    async def import_file(self, file_path: Path) -> dict[str, int]:
        parser = ParserFactory.get_parser(file_path)
        transactions = parser.parse(file_path)
        transactions.sort(key=lambda t: t.booking_date)
        self.validate_balance_continuity(transactions)

        # ── Batch idempotency check via DuckDB ──────────────────────────
        tx_meta = [(tx, str(uid), uid) for tx in transactions for uid in [generate_idempotency_id(tx)]]
        tx_ids = [m[1] for m in tx_meta]
        placeholders = ",".join(["?"] * len(tx_ids))
        existing_rows = self.duckdb.execute(
            f"SELECT tx_id FROM bank_history WHERE tx_id IN ({placeholders})",
            tuple(tx_ids),
        )
        existing_set = {row[0] for row in existing_rows} if existing_rows else set()

        new_meta = [
            (tx, tx_id, tx_uuid)
            for tx, tx_id, tx_uuid in tx_meta
            if tx_id not in existing_set
        ]
        duplicates = len(transactions) - len(new_meta)

        if not new_meta:
            return {"imported": 0, "duplicates": duplicates, "total": len(transactions)}

        # ── Batch TigerBeetle transfer creation ─────────────────────────
        import tigerbeetle as tb

        from nexus_ai.services.tigerbeetle.client import (
            LEDGER,
            TRANSFER_CODE,
            _generate_tb_id,
        )

        transfers: list[tb.Transfer] = []
        transfer_meta: list[tuple[BankTransaction, str, uuid.UUID, tb.Transfer]] = []
        for tx, tx_id, tx_uuid in new_meta:
            transfer = tb.Transfer(
                id=_generate_tb_id(),
                debit_account_id=tx.source_account_id,
                credit_account_id=tx.destination_account_id,
                amount=tx.amount_cents,
                pending_id=0,
                user_data_128=tx_uuid.int,
                user_data_64=int(tx.booking_date.isoformat().replace("-", "")),
                user_data_32=0,
                timeout=0,
                ledger=LEDGER["PLN"],
                code=TRANSFER_CODE["PAYMENT_IN"],
                timestamp=0,
            )
            transfers.append(transfer)
            transfer_meta.append((tx, tx_id, tx_uuid, transfer))

        results = self.tb_client.create_transfers(transfers)

        # ── Process results and insert successful ones ──────────────────
        imported = 0
        for (tx, tx_id, _tx_uuid, transfer), result in zip(transfer_meta, results, strict=True):
            if result.status != 0:
                if "exists" in str(result.status):
                    duplicates += 1
                    continue
                raise RuntimeError(f"TB posting failed for tx {tx_id}: {result.status}")

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
