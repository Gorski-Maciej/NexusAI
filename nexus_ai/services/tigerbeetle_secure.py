from __future__ import annotations

from sqlalchemy.orm import Session

from nexus_ai.api.rbac import NexusRole, RoleContext
from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import SecurityAlert
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient


class TigerBeetleSecurityException(PermissionError):  # noqa: N818
    pass


class SecureTigerBeetleClient:
    """RBAC-aware wrapper that blocks WORKER from posting committed transfers."""

    def __init__(self, inner: TigerBeetleClient) -> None:
        self._inner = inner

    def create_pending_transfer(self, **kwargs):
        return self._inner.create_two_phase_transfer(**kwargs)

    def create_transfer(
        self,
        *,
        role_ctx: RoleContext,
        session: Session,
        post: bool,
        pending_id: int | None = None,
        **kwargs,
    ):
        if post and role_ctx.role != NexusRole.OWNER:
            self._log_security_alert(
                session,
                actor=role_ctx.actor,
                operation="create_transfer(post=true)",
                details={"pending_id": pending_id, "kwargs": kwargs},
            )
            raise TigerBeetleSecurityException("WORKER cannot execute posted TigerBeetle transfers")

        if post:
            if pending_id is None:
                raise ValueError("pending_id is required to post a pending transfer")
            return self._inner.post_pending_transfer(pending_id)

        return self._inner.create_two_phase_transfer(**kwargs)

    def _log_security_alert(
        self, session: Session, *, actor: str, operation: str, details: dict
    ) -> None:
        session.add(
            SecurityAlert(
                actor=actor,
                operation=operation,
                details=msgspec_dumps(details, default=str),
            )
        )
        session.commit()
