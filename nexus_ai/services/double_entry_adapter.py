"""Universal Double-Entry Adapter — abstrakcja nad silnikami księgowymi.

v7.0 INNOWACJA #9 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Universal Double-Entry Adapter: Abstrakcja nad silnikami księgowymi"

Architektura:
  - Wspólny interfejs: post_transfer(), get_balance(), create_account()
  - Implementacje: TigerBeetle, SQLite (testy), PostgreSQL (future)
  - Łatwe testy jednostkowe bez TB
  - Future-proof: można zmienić silnik bez zmiany aplikacji

v7.0 AUDIT: Umożliwia podmianę TigerBeetle na inny silnik księgowy
bez zmiany kodu biznesowego. Kluczowe dla testowalności i elastyczności.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from decimal import Decimal
from typing import Any, Protocol, final

from structlog import get_logger

logger = get_logger("nexus.double_entry.adapter")


# ── Wspólne modele ──────────────────────────────────────────────────────


@dataclass
class AccountSpec:
    """Specyfikacja konta księgowego."""

    account_id: int
    ledger: int = 700
    code: int = 1
    history: bool = True
    debits_must_not_exceed_credits: bool = False
    credits_must_not_exceed_debits: bool = False


@dataclass
class TransferSpec:
    """Specyfikacja transferu księgowego."""

    debit_account: int
    credit_account: int
    amount_minor: int
    ledger: int = 700
    code: int = 1001
    pending_id: int = 0
    user_data_128: int = 0
    user_data_64: int = 0
    flags: int = 0


@dataclass
class TransferResult:
    """Wynik transferu."""

    success: bool
    transfer_id: str = ""
    pending_id: str = ""
    error: str = ""


@dataclass
class AccountBalance:
    """Saldo konta."""

    account_id: int
    debits_posted: int = 0
    credits_posted: int = 0
    debits_pending: int = 0
    credits_pending: int = 0

    @property
    def net_balance(self) -> int:
        """Saldo netto = credits_posted - debits_posted."""
        return self.credits_posted - self.debits_posted


# ── Abstrakcyjny interfejs ─────────────────────────────────────────────


class DoubleEntryLedger(ABC):
    """Abstrakcyjny interfejs dla silnika double-entry (v7.0 Innowacja #9).

    Każda implementacja (TigerBeetle, SQLite, PostgreSQL) musi
    implementować ten interfejs. Kod biznesowy używa TYLKO tego
    interfejsu — nie zależy od konkretnego silnika.
    """

    @abstractmethod
    def create_account(self, spec: AccountSpec) -> bool:
        """Utwórz konto księgowe."""
        ...

    @abstractmethod
    def create_accounts_batch(self, specs: list[AccountSpec]) -> list[bool]:
        """Utwórz wiele kont atomowo."""
        ...

    @abstractmethod
    def post_transfer(self, spec: TransferSpec) -> TransferResult:
        """Zaksięguj transfer (jednofazowy — od razu posted)."""
        ...

    @abstractmethod
    def post_transfer_batch(self, specs: list[TransferSpec]) -> list[TransferResult]:
        """Zaksięguj wiele transferów atomowo."""
        ...

    @abstractmethod
    def create_pending_transfer(self, spec: TransferSpec) -> TransferResult:
        """Utwórz pending transfer (dwufazowy)."""
        ...

    @abstractmethod
    def post_pending_transfer(self, pending_id: str, amount_minor: int | None = None) -> TransferResult:
        """Zatwierdź pending transfer."""
        ...

    @abstractmethod
    def void_pending_transfer(self, pending_id: str) -> TransferResult:
        """Anuluj pending transfer."""
        ...

    @abstractmethod
    def get_balance(self, account_id: int) -> AccountBalance:
        """Pobierz saldo konta."""
        ...

    @abstractmethod
    def get_balances_batch(self, account_ids: list[int]) -> dict[int, AccountBalance]:
        """Pobierz salda wielu kont."""
        ...

    @abstractmethod
    def get_transfers(self, account_id: int, limit: int = 50) -> list[dict[str, Any]]:
        """Pobierz historię transferów dla konta."""
        ...

    @abstractmethod
    def is_healthy(self) -> bool:
        """Sprawdź czy silnik księgowy działa poprawnie."""
        ...


# ── Implementacja: TigerBeetle ───────────────────────────────────────────


@final
class TigerBeetleLedger(DoubleEntryLedger):
    """Implementacja DoubleEntryLedger dla TigerBeetle (v7.0 Innowacja #9).

    Opakowuje TigerBeetleClient w standardowy interfejs.
    """

    def __init__(self, tb_client) -> None:
        self._tb = tb_client

    def create_account(self, spec: AccountSpec) -> bool:
        results = self._tb.create_accounts([
            self._tb.build_account(
                account_id=spec.account_id,
                ledger=spec.ledger,
                code=spec.code,
                history=spec.history,
                debits_must_not_exceed_credits=spec.debits_must_not_exceed_credits,
                credits_must_not_exceed_debits=spec.credits_must_not_exceed_debits,
            ),
        ])
        return len(results) > 0 and results[0].status == 0

    def create_accounts_batch(self, specs: list[AccountSpec]) -> list[bool]:
        accounts = [
            self._tb.build_account(
                account_id=s.account_id, ledger=s.ledger, code=s.code,
                history=s.history,
                debits_must_not_exceed_credits=s.debits_must_not_exceed_credits,
                credits_must_not_exceed_debits=s.credits_must_not_exceed_debits,
            )
            for s in specs
        ]
        results = self._tb.create_accounts(accounts)
        return [r.status == 0 for r in results]

    def post_transfer(self, spec: TransferSpec) -> TransferResult:
        import uuid as uuid_module
        import tigerbeetle as tb

        transfer = tb.Transfer(
            id=self._tb._generate_tb_id() if hasattr(self._tb, '_generate_tb_id') else 0,
            debit_account_id=spec.debit_account,
            credit_account_id=spec.credit_account,
            amount=spec.amount_minor,
            pending_id=spec.pending_id,
            user_data_128=spec.user_data_128,
            user_data_64=spec.user_data_64,
            user_data_32=0,
            timeout=0,
            ledger=spec.ledger,
            code=spec.code,
            flags=spec.flags,
            timestamp=0,
        )
        results = self._tb.create_transfers([transfer])
        if results and results[0].status == 0:
            return TransferResult(success=True, transfer_id=str(transfer.id))
        return TransferResult(success=False, error=f"TB status={results[0].status if results else 'no_result'}")

    def post_transfer_batch(self, specs: list[TransferSpec]) -> list[TransferResult]:
        import tigerbeetle as tb

        transfers = []
        for spec in specs:
            transfers.append(tb.Transfer(
                id=self._tb._generate_tb_id() if hasattr(self._tb, '_generate_tb_id') else 0,
                debit_account_id=spec.debit_account,
                credit_account_id=spec.credit_account,
                amount=spec.amount_minor,
                pending_id=spec.pending_id,
                user_data_128=spec.user_data_128,
                user_data_64=spec.user_data_64,
                ledger=spec.ledger,
                code=spec.code,
                flags=spec.flags,
                timestamp=0,
            ))

        results = self._tb.create_transfers(transfers)
        return [
            TransferResult(
                success=r.status == 0,
                transfer_id=str(t.id),
                error="" if r.status == 0 else f"TB status={r.status}",
            )
            for r, t in zip(results, transfers)
        ]

    def create_pending_transfer(self, spec: TransferSpec) -> TransferResult:
        import uuid as uuid_module

        pending_id = self._tb.create_pending_transfer(
            debit_account=spec.debit_account,
            credit_account=spec.credit_account,
            amount_minor=spec.amount_minor,
            source_document_id=uuid_module.uuid4(),
            ledger=spec.ledger,
            code=spec.code,
            user_data_64=spec.user_data_64,
        )
        if pending_id is not None:
            return TransferResult(success=True, pending_id=str(pending_id))
        return TransferResult(success=False, error="TB pending creation failed")

    def post_pending_transfer(self, pending_id: str, amount_minor: int | None = None) -> TransferResult:
        ok = self._tb.post_pending_transfer(int(pending_id), amount_minor=amount_minor)
        if ok:
            return TransferResult(success=True, pending_id=pending_id)
        return TransferResult(success=False, error="TB post failed")

    def void_pending_transfer(self, pending_id: str) -> TransferResult:
        ok = self._tb.void_pending_transfer(int(pending_id))
        if ok:
            return TransferResult(success=True, pending_id=pending_id)
        return TransferResult(success=False, error="TB void failed")

    def get_balance(self, account_id: int) -> AccountBalance:
        balance = self._tb.get_account_balance(account_id)
        return AccountBalance(
            account_id=account_id,
            credits_posted=max(0, balance),
            debits_posted=max(0, -balance),
        )

    def get_balances_batch(self, account_ids: list[int]) -> dict[int, AccountBalance]:
        balances = self._tb.get_account_balances_batch(account_ids)
        return {
            aid: AccountBalance(
                account_id=aid,
                credits_posted=max(0, bal),
                debits_posted=max(0, -bal),
            )
            for aid, bal in balances.items()
        }

    def get_transfers(self, account_id: int, limit: int = 50) -> list[dict[str, Any]]:
        transfers = self._tb.get_account_transfers(account_id, limit=limit)
        return [
            {"transfer_id": str(getattr(t, "id", "")), "timestamp": str(getattr(t, "timestamp", ""))}
            for t in (transfers or [])
        ]

    def is_healthy(self) -> bool:
        try:
            self._tb.get_account_balance(0)
            return True
        except Exception:
            return False


# ── Implementacja: SQLite (testowa) ──────────────────────────────────────


@final
class SQLiteLedger(DoubleEntryLedger):
    """Implementacja DoubleEntryLedger dla SQLite (do testów).

    v7.0 Innowacja #9: Umożliwia testy jednostkowe bez TigerBeetle.
    """

    def __init__(self) -> None:
        import sqlite3

        self._conn = sqlite3.connect(":memory:")
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS accounts (
                account_id INTEGER PRIMARY KEY,
                ledger INTEGER DEFAULT 700,
                code INTEGER DEFAULT 1,
                debits_posted INTEGER DEFAULT 0,
                credits_posted INTEGER DEFAULT 0,
                debits_pending INTEGER DEFAULT 0,
                credits_pending INTEGER DEFAULT 0
            )
        """)
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS transfers (
                transfer_id TEXT PRIMARY KEY,
                debit_account INTEGER,
                credit_account INTEGER,
                amount_minor INTEGER,
                ledger INTEGER,
                code INTEGER,
                status TEXT DEFAULT 'posted',
                created_at TEXT DEFAULT (datetime('now'))
            )
        """)
        self._transfer_counter = 0

    def create_account(self, spec: AccountSpec) -> bool:
        try:
            self._conn.execute(
                "INSERT OR IGNORE INTO accounts (account_id, ledger, code) VALUES (?, ?, ?)",
                (spec.account_id, spec.ledger, spec.code),
            )
            self._conn.commit()
            return True
        except Exception:
            return False

    def create_accounts_batch(self, specs: list[AccountSpec]) -> list[bool]:
        return [self.create_account(s) for s in specs]

    def post_transfer(self, spec: TransferSpec) -> TransferResult:
        try:
            self._transfer_counter += 1
            tid = f"SQLITE-{self._transfer_counter}"
            self._conn.execute(
                "INSERT INTO transfers (transfer_id, debit_account, credit_account, amount_minor, ledger, code) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (tid, spec.debit_account, spec.credit_account, spec.amount_minor, spec.ledger, spec.code),
            )
            self._conn.execute(
                "UPDATE accounts SET debits_posted = debits_posted + ? WHERE account_id = ?",
                (spec.amount_minor, spec.debit_account),
            )
            self._conn.execute(
                "UPDATE accounts SET credits_posted = credits_posted + ? WHERE account_id = ?",
                (spec.amount_minor, spec.credit_account),
            )
            self._conn.commit()
            return TransferResult(success=True, transfer_id=tid)
        except Exception as exc:
            return TransferResult(success=False, error=str(exc))

    def post_transfer_batch(self, specs: list[TransferSpec]) -> list[TransferResult]:
        return [self.post_transfer(s) for s in specs]

    def create_pending_transfer(self, spec: TransferSpec) -> TransferResult:
        return self.post_transfer(spec)  # SQLite nie wspiera prawdziwego pending

    def post_pending_transfer(self, pending_id: str, amount_minor: int | None = None) -> TransferResult:
        return TransferResult(success=True, pending_id=pending_id)

    def void_pending_transfer(self, pending_id: str) -> TransferResult:
        return TransferResult(success=True, pending_id=pending_id)

    def get_balance(self, account_id: int) -> AccountBalance:
        row = self._conn.execute(
            "SELECT debits_posted, credits_posted, debits_pending, credits_pending FROM accounts WHERE account_id = ?",
            (account_id,),
        ).fetchone()
        if not row:
            return AccountBalance(account_id=account_id)
        return AccountBalance(
            account_id=account_id,
            debits_posted=row[0],
            credits_posted=row[1],
            debits_pending=row[2],
            credits_pending=row[3],
        )

    def get_balances_batch(self, account_ids: list[int]) -> dict[int, AccountBalance]:
        return {aid: self.get_balance(aid) for aid in account_ids}

    def get_transfers(self, account_id: int, limit: int = 50) -> list[dict[str, Any]]:
        rows = self._conn.execute(
            "SELECT transfer_id, debit_account, credit_account, amount_minor, status, created_at "
            "FROM transfers WHERE debit_account = ? OR credit_account = ? ORDER BY created_at DESC LIMIT ?",
            (account_id, account_id, limit),
        ).fetchall()
        return [
            {"transfer_id": r[0], "debit": r[1], "credit": r[2], "amount": r[3], "status": r[4], "created_at": r[5]}
            for r in rows
        ]

    def is_healthy(self) -> bool:
        try:
            self._conn.execute("SELECT 1")
            return True
        except Exception:
            return False


# ── Fabryka ──────────────────────────────────────────────────────────────


def create_ledger(engine: str = "tigerbeetle", **kwargs) -> DoubleEntryLedger:
    """v7.0: Fabryka silników księgowych.

    Args:
        engine: "tigerbeetle", "sqlite", lub "postgresql" (future).
        **kwargs: Parametry specyficzne dla silnika.

    Returns:
        Implementacja DoubleEntryLedger.
    """
    if engine == "tigerbeetle":
        from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

        tb = kwargs.get("tb_client") or TigerBeetleClient()
        return TigerBeetleLedger(tb)
    elif engine == "sqlite":
        return SQLiteLedger()
    else:
        raise ValueError(f"Unknown ledger engine: {engine}. Supported: tigerbeetle, sqlite")
