from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from litestar.connection import ASGIConnection
from litestar.exceptions import NotAuthorizedException
from litestar.handlers.base import BaseRouteHandler


class NexusRole(StrEnum):
    OWNER = "owner"
    WORKER = "worker"


@dataclass(slots=True)
class RoleContext:
    role: NexusRole
    actor: str


def get_current_role(connection: ASGIConnection) -> RoleContext:
    user = getattr(connection, "user", None)
    if not user:
        raise NotAuthorizedException("Missing authenticated user context")

    try:
        role = NexusRole(str(user.role).strip().lower())
    except ValueError as exc:
        raise NotAuthorizedException("Unsupported role in authenticated context") from exc
    actor = str(getattr(user, "username", user.id)).strip().lower()
    prefix = "owner:" if role == NexusRole.OWNER else "worker:"
    return RoleContext(role=role, actor=f"{prefix}{actor}")


def owner_only_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    if get_current_role(connection).role != NexusRole.OWNER:
        raise NotAuthorizedException("Only OWNER can execute this operation.")


def worker_only_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    if get_current_role(connection).role != NexusRole.WORKER:
        raise NotAuthorizedException("Only WORKER can execute this operation.")
