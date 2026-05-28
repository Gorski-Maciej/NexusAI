from __future__ import annotations

import json

from sqlalchemy.ext.asyncio import AsyncSession

from api.rbac import NexusRole, RoleContext
from db.models import SecurityAlert
from Roboton_Reflekton.ledger_client import TigerBeetleClient


class TigerBeetleSecurityException(PermissionError):
    pass


class SecureTigerBeetleClient:
    """RBAC-aware wrapper that blocks WORKER from posting committed transfers."""

    def __init__(self, inner: TigerBeetleClient) -> None:
        self._inner = inner

    async def create_pending_transfer(self, **kwargs):
        return await self._inner.create_two_phase_transfer(**kwargs)

    async def create_transfer(
        self,
        *,
        role_ctx: RoleContext,
        session: AsyncSession,
        post: bool,
        pending_id: int | None = None,
        **kwargs,
    ):
        if post and role_ctx.role != NexusRole.OWNER:
            await self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="create_transfer(post=true)",
                details={"pending_id": pending_id, "kwargs": kwargs},
            )
            raise TigerBeetleSecurityException("WORKER cannot execute posted TigerBeetle transfers")

        if post:
            if pending_id is None:
                raise ValueError("pending_id is required to post a pending transfer")
            return await self._inner.post_pending_transfer(pending_id)

        return await self._inner.create_two_phase_transfer(**kwargs)

    async def _log_security_alert(self, session: AsyncSession, *, actor: str, operation: str, details: dict) -> None:
        session.add(
            SecurityAlert(
                actor=actor,
                operation=operation,
                details=json.dumps(details, default=str),
            )
        )
        await session.commit()
