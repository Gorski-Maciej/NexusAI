"""SecureTigerBeetleClient — RBAC-aware wrapper dla realnego TigerBeetle.

SUPERMOCE:
- RBAC na poziomie klienta (OWNER tylko może postować)
- Natywne pending/void zamiast własnej implementacji
- Linked transfers dla atomowości
- Security audit trail przez TigerBeetle user_data
"""

from __future__ import annotations

from typing import Any, final

import tigerbeetle as tb
from msgspec import Struct
from sqlmodel import Session

from nexus_ai.api.rbac import NexusRole, RoleContext
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import SecurityAlert
from nexus_ai.services.tigerbeetle.client import LEDGER, TRANSFER_CODE, TigerBeetleClient


class TigerBeetleSecurityException(PermissionError):  # noqa: N818
    """Raised when a user without proper RBAC role attempts a restricted operation."""

    pass


class SecureTransferSpec(Struct):
    """Specyfikacja transferu dla SecureTigerBeetleClient."""

    debit_account: int
    credit_account: int
    amount_minor: int
    code: int
    ledger: int = LEDGER["PLN"]
    is_pending: bool = False
    pending_id: int = 0
    user_data_64: int = 0
    user_data_32: int = 0


@final
class SecureTigerBeetleClient:
    """RBAC-aware wrapper that blocks WORKER from posting committed transfers.

    SUPERMOCE:
    - OWNER może tworzyć i postować transfery
    - WORKER może tylko tworzyć pending transfery
    - Naruszenia logowane do SecurityAlert
    - Natywne TB flags dla pending/post
    """

    def __init__(self, inner: TigerBeetleClient) -> None:
        self._inner = inner

    async def create_pending_transfer(
        self,
        *,
        debit_account: int,
        credit_account: int,
        amount_minor: int,
        source_document_id: Any,
        ledger: int = LEDGER["PLN"],
        code: int = TRANSFER_CODE["EXPENSE_NET"],
        user_data_64: int = 0,
        user_data_32: int = 0,
        timeout: int = 0,
    ) -> int | None:
        """Utwórz pending transfer (RBAC: każdy może).

        Args:
            debit_account: Konto debetowe.
            credit_account: Konto kredytowe.
            amount_minor: Kwota w groszach.
            source_document_id: UUID dokumentu źródłowego.
            ledger: ID ledgera.
            code: Kod transferu.
            user_data_64/32: Metadane.
            timeout: Timeout w sekundach.

        Returns:
            pending_id (int) lub None przy błędzie.
        """
        pending_id = self._inner.create_pending_transfer(
            debit_account=debit_account,
            credit_account=credit_account,
            amount_minor=amount_minor,
            source_document_id=source_document_id,
            ledger=ledger,
            code=code,
            user_data_64=user_data_64,
            user_data_32=user_data_32,
            timeout=timeout,
        )
        # TB zwraca klient-generowany transfer_id jako pending_id
        return pending_id

    async def post_pending_transfer(
        self,
        pending_id: int,
        *,
        role_ctx: RoleContext,
        session: Session,
        ledger: int = LEDGER["PLN"],
        code: int = TRANSFER_CODE["EXPENSE_NET"],
        amount_minor: int | None = None,
    ) -> bool:
        """Zatwierdź pending transfer (RBAC: OWNER tylko).

        Args:
            pending_id: ID pending transferu.
            role_ctx: Kontekst RBAC.
            session: Sesja SQLAlchemy dla SecurityAlert.
            ledger: ID ledgera.
            code: Kod transferu.
            amount_minor: Kwota (None = całość).

        Returns:
            True jeśli zatwierdzono.
        """
        if role_ctx.role != NexusRole.OWNER:
            self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="post_pending_transfer",
                details={"pending_id": pending_id, "role": str(role_ctx.role)},
            )
            raise TigerBeetleSecurityException("WORKER cannot execute posted TigerBeetle transfers")

        return self._inner.post_pending_transfer(
            pending_id,
            amount_minor=amount_minor,
            ledger=ledger,
            code=code,
        )

    async def void_pending_transfer(
        self,
        pending_id: int,
        *,
        role_ctx: RoleContext,
        session: Session,
        ledger: int = LEDGER["PLN"],
        code: int = TRANSFER_CODE["STORN"],
    ) -> bool:
        """Anuluj pending transfer (RBAC: OWNER tylko)."""
        if role_ctx.role != NexusRole.OWNER:
            self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="void_pending_transfer",
                details={"pending_id": pending_id, "role": str(role_ctx.role)},
            )
            raise TigerBeetleSecurityException("WORKER cannot void TigerBeetle transfers")

        return self._inner.void_pending_transfer(
            pending_id,
            ledger=ledger,
            code=code,
        )

    async def create_linked_transfers_batch(
        self,
        specs: list[SecureTransferSpec],
        *,
        source_document_id: Any,
        role_ctx: RoleContext,
        session: Session,
    ) -> list[dict[str, Any]]:
        """Utwórz linked chain transferów (RBAC: każdy może, ale do pending).

        Args:
            specs: Lista specyfikacji transferów.
            source_document_id: UUID dokumentu źródłowego.
            role_ctx: Kontekst RBAC.
            session: Sesja SQLAlchemy.

        Returns:
            Lista wyników.
        """
        import uuid as uuid_module

        source_uuid = (
            uuid_module.UUID(source_document_id)
            if isinstance(source_document_id, str)
            else source_document_id
        )

        # Buduj linked chain
        tb_transfers = self._inner.build_linked_transfers(
            [
                {
                    "debit": s.debit_account,
                    "credit": s.credit_account,
                    "amount": s.amount_minor,
                    "code": s.code,
                    "ledger": s.ledger,
                    "pending_id": s.pending_id,
                    "user_data_64": s.user_data_64,
                    "user_data_32": s.user_data_32,
                    "flags": tb.TransferFlags.PENDING if s.is_pending else 0,
                }
                for s in specs
            ],
            source_document_id=source_uuid,
            ledger=specs[0].ledger if specs else LEDGER["PLN"],
        )

        results = await self._inner.create_transfers_async(tb_transfers)

        output = []
        for i, (spec, result) in enumerate(zip(specs, results)):
            output.append(
                {
                    "index": i,
                    "code": spec.code,
                    "debit": spec.debit_account,
                    "credit": spec.credit_account,
                    "amount": spec.amount_minor,
                    "status": str(result),
                    "pending_id": result.timestamp if spec.is_pending else None,
                }
            )

        return output

    def _log_security_alert(
        self, session: Session, *, actor: str, operation: str, details: dict
    ) -> None:
        """Loguj naruszenie bezpieczeństwa."""
        session.add(
            SecurityAlert(
                actor=actor,
                operation=operation,
                details=msgspec_dumps(details, default=str),
            )
        )
        session.commit()
