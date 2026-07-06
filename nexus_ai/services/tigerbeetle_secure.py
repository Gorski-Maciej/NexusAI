"""SecureTigerBeetleClient -- RBAC-aware wrapper dla realnego TigerBeetle.

- Dynamiczne permissions z ROLE_PERMISSIONS_MAP (nie hardcoded OWNER)
- Natywne pending/void zamiast własnej implementacji
- Linked transfers dla atomowości
- Security audit trail przez TigerBeetle user_data
"""

from __future__ import annotations

from typing import Any, final

import tigerbeetle as tb
from msgspec import Struct
from sqlmodel import Session

from nexus_ai.api.rbac import ROLE_PERMISSIONS_MAP, RoleContext
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import SecurityAlert
from nexus_ai.services.tigerbeetle.client import LEDGER, TRANSFER_CODE, TigerBeetleClient


class TigerBeetleSecurityException(PermissionError):  # noqa: N818
    """Raised when user lacks required permission for a restricted operation."""
    pass


class SecureTransferSpec(Struct):
    """Specyfikacja transferu dla SecureTigerBeetleClient."""
    __slots__ = ()
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
    """RBAC-aware wrapper — permissions z ROLE_PERMISSIONS_MAP (bez hardcoded OWNER).

    - ``tigerbeetle:create-pending``: każdy accountant/auditor może tworzyć pending
    - ``tigerbeetle:post``: tylko admin może postować committed (logowane do SecurityAlert)
    - ``tigerbeetle:void``: tylko admin może voidować (logowane do SecurityAlert)
    """

    def __init__(self, inner: TigerBeetleClient) -> None:
        self._inner = inner

    @staticmethod
    def _has_permission(role: str, permission: str) -> bool:
        """Sprawdź czy rola ma dane permission z ROLE_PERMISSIONS_MAP."""
        perms = ROLE_PERMISSIONS_MAP.get(role, [])
        return permission in perms

    @staticmethod
    def _check_permission(role_ctx: RoleContext, permission: str) -> bool:
        """Sprawdź permission, najpierw z contextu, potem z mapy."""
        if role_ctx.permissions is not None:
            return permission in role_ctx.permissions
        return SecureTigerBeetleClient._has_permission(role_ctx.role, permission)

    async def create_pending_transfer(
        self,
        *,
        debit_account: int,
        credit_account: int,
        amount_minor: int,
        source_document_id: Any,
        role_ctx: RoleContext | None = None,
        session: Session | None = None,
        ledger: int = LEDGER["PLN"],
        code: int = TRANSFER_CODE["EXPENSE_NET"],
        user_data_64: int = 0,
        user_data_32: int = 0,
        timeout: int = 0,
    ) -> int | None:
        """Utwórz pending transfer (opcjonalnie sprawdza ``tigerbeetle:create-pending``).

        Jeśli ``role_ctx`` i ``session`` są podane, sprawdzane jest permission.
        W przeciwnym razie transfer jest tworzony bez sprawdzenia (backward compat).
        """
        if role_ctx is not None and session is not None:
            if not self._check_permission(role_ctx, "tigerbeetle:create-pending"):
                self._log_security_alert(
                    session,
                    actor=role_ctx.actor,
                    operation="create_pending_transfer",
                    details={"role": role_ctx.role, "lack": "tigerbeetle:create-pending"},
                )
                raise TigerBeetleSecurityException(
                    f"Role {role_ctx.role} lacks tigerbeetle:create-pending permission"
                )

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
        """Zatwierdź pending transfer (wymaga ``tigerbeetle:post``)."""
        if not self._check_permission(role_ctx, "tigerbeetle:post"):
            self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="post_pending_transfer",
                details={"pending_id": pending_id, "role": role_ctx.role, "lack": "tigerbeetle:post"},
            )
            raise TigerBeetleSecurityException(
                f"Role {role_ctx.role} lacks tigerbeetle:post permission"
            )

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
        """Anuluj pending transfer (wymaga ``tigerbeetle:void``)."""
        if not self._check_permission(role_ctx, "tigerbeetle:void"):
            self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="void_pending_transfer",
                details={"pending_id": pending_id, "role": role_ctx.role, "lack": "tigerbeetle:void"},
            )
            raise TigerBeetleSecurityException(
                f"Role {role_ctx.role} lacks tigerbeetle:void permission"
            )

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
        """Utwórz linked chain transferów (wymaga ``tigerbeetle:create-pending``)."""
        if not self._check_permission(role_ctx, "tigerbeetle:create-pending"):
            self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="create_linked_transfers_batch",
                details={"specs_count": len(specs), "role": role_ctx.role, "lack": "tigerbeetle:create-pending"},
            )
            raise TigerBeetleSecurityException(
                f"Role {role_ctx.role} lacks tigerbeetle:create-pending permission"
            )

        import uuid as uuid_module

        source_uuid = (
            uuid_module.UUID(source_document_id)
            if isinstance(source_document_id, str)
            else source_document_id
        )

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
        for i, (spec, result) in enumerate(zip(specs, results, strict=True)):
            output.append({
                "index": i,
                "code": spec.code,
                "debit": spec.debit_account,
                "credit": spec.credit_account,
                "amount": spec.amount_minor,
                "status": str(result),
                "pending_id": result.timestamp if spec.is_pending else None,
            })

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
