"""PeriodCloser — zamykanie okresów finansowych z CLOSING_DEBIT/CREDIT.

- TransferFlags.CLOSING_DEBIT (64) — automatyczne zerowanie debetu na koncie
- TransferFlags.CLOSING_CREDIT (128) — automatyczne zerowanie kredytu na koncie
- Linked transfers — atomowe zamknięcie wielu kont
- Batch — wszystkie closing transfery w jednym wywołaniu
- Append-only — zamknięcie to nowe transfery, nie DELETE
"""

from __future__ import annotations

import uuid
from typing import Any, final

import pendulum
import tigerbeetle as tb
from structlog import get_logger

from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
    _generate_tb_id,
)

logger = get_logger("nexus.services.period_closer")


@final
class PeriodCloser:
    """Zamyka okres finansowy używając CLOSING_DEBIT/CREDIT.

    - CLOSING_DEBIT (64): zamyka konto debetowe — TB zeruje debits_posted
    - CLOSING_CREDIT (128): zamyka konto kredytowe — TB zeruje credits_posted
    - Linked chain: atomowe zamknięcie wszystkich kont okresu
    - Batch: jeden create_transfers() dla całego closingu
    """

    def __init__(
        self,
        tb_client: TigerBeetleClient,
        *,
        retained_earnings_account: int | None = None,
        default_ledger: int = LEDGER["PLN"],
    ) -> None:
        self._tb_client = tb_client
        self._retained_earnings = retained_earnings_account or 82000  # Wynik finansowy
        self._default_ledger = default_ledger
        if period_id is not None:
            logger.info(
                "[PERIOD-CLOSER] Closing period=%s (based on %s)",
                period_id,
                pendulum.yesterday().start_of("month").format("YYYY-MM-DD"),
            )

    def close_expense_accounts(
        self,
        expense_accounts: list[dict[str, Any]],
        *,
        period_id: str,
        source_document_id: uuid.UUID | None = None,
    ) -> bool:
        """Zamknij konta kosztowe na koniec okresu.

        na koncie kosztowym i przenosi saldo na retained_earnings.

        Args:
            expense_accounts: Lista kont do zamknięcia:
                [{"account_id": int, "ledger": int, "code": int}, ...]
            period_id: ID okresu (np. "2026-06").
            source_document_id: UUID dokumentu źródłowego.

        Returns:
            True jeśli wszystkie closing transfery się powiodły.
        """
        if not expense_accounts:
            return True

        doc_id = source_document_id or uuid.uuid5(uuid.NAMESPACE_URL, f"period-close:{period_id}")

        transfers = []
        for i, acct in enumerate(expense_accounts):
            is_last = i == len(expense_accounts) - 1
            transfer_id = _generate_tb_id()

            transfer = tb.Transfer(
                id=transfer_id,
                debit_account_id=acct["account_id"],  # Konto kosztowe (debet)
                credit_account_id=self._retained_earnings,  # Wynik finansowy
                amount=tb.AMOUNT_MAX,  # Całe saldo
                pending_id=0,
                user_data_128=doc_id.int,
                user_data_64=int(period_id.replace("-", "")),
                user_data_32=0,
                timeout=0,
                ledger=acct.get("ledger", self._default_ledger),
                code=acct.get("code", TRANSFER_CODE["TRANSFER_INTERNAL"]),
                flags=tb.TransferFlags.CLOSING_DEBIT | (0 if is_last else tb.TransferFlags.LINKED),
                timestamp=0,
            )
            transfers.append(transfer)

        results = self._tb_client.create_transfers(transfers)
        all_ok = all(r.status == 0 for r in results)

        if not all_ok:
            logger.error(
                "[PERIOD-CLOSER] Expense closing failed for period=%s: %s",
                period_id,
                [r.status for r in results],
            )

        return all_ok

    def close_revenue_accounts(
        self,
        revenue_accounts: list[dict[str, Any]],
        *,
        period_id: str,
        source_document_id: uuid.UUID | None = None,
    ) -> bool:
        """Zamknij konta przychodowe na koniec okresu.

        na koncie przychodowym.
        """
        if not revenue_accounts:
            return True

        doc_id = source_document_id or uuid.uuid5(
            uuid.NAMESPACE_URL, f"period-close-revenue:{period_id}"
        )

        transfers = []
        for i, acct in enumerate(revenue_accounts):
            is_last = i == len(revenue_accounts) - 1
            transfer_id = _generate_tb_id()

            transfer = tb.Transfer(
                id=transfer_id,
                debit_account_id=self._retained_earnings,  # Wynik finansowy
                credit_account_id=acct["account_id"],  # Konto przychodowe (kredyt)
                amount=tb.AMOUNT_MAX,  # Całe saldo
                pending_id=0,
                user_data_128=doc_id.int,
                user_data_64=int(period_id.replace("-", "")),
                user_data_32=1,  # user_data_32=1 oznacza revenue close
                timeout=0,
                ledger=acct.get("ledger", self._default_ledger),
                code=acct.get("code", TRANSFER_CODE["TRANSFER_INTERNAL"]),
                flags=tb.TransferFlags.CLOSING_CREDIT | (0 if is_last else tb.TransferFlags.LINKED),
                timestamp=0,
            )
            transfers.append(transfer)

        results = self._tb_client.create_transfers(transfers)
        all_ok = all(r.status == 0 for r in results)

        if not all_ok:
            logger.error(
                "[PERIOD-CLOSER] Revenue closing failed for period=%s: %s",
                period_id,
                [r.status for r in results],
            )

        return all_ok

    def close_full_period(
        self,
        *,
        expense_accounts: list[dict[str, Any]],
        revenue_accounts: list[dict[str, Any]],
        period_id: str,
    ) -> dict[str, Any]:
        """Zamknij pełny okres — expense + revenue w dwóch batchach.

        Args:
            expense_accounts: Lista kont kosztowych.
            revenue_accounts: Lista kont przychodowych.
            period_id: ID okresu.

        Returns:
            Dict z wynikami zamknięcia.
        """
        doc_id = uuid.uuid5(uuid.NAMESPACE_URL, f"full-close:{period_id}")

        expense_ok = self.close_expense_accounts(
            expense_accounts,
            period_id=period_id,
            source_document_id=doc_id,
        )
        revenue_ok = self.close_revenue_accounts(
            revenue_accounts,
            period_id=period_id,
            source_document_id=doc_id,
        )

        return {
            "period_id": period_id,
            "expense_closed": expense_ok,
            "revenue_closed": revenue_ok,
            "overall": expense_ok and revenue_ok,
            "expense_accounts_count": len(expense_accounts),
            "revenue_accounts_count": len(revenue_accounts),
        }
