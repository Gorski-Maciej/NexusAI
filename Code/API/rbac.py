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
    raw_role = (connection.headers.get("X-Nexus-Role") or "owner").strip().lower()
    raw_actor = (connection.headers.get("X-Nexus-Actor") or "admin").strip().lower()

    if raw_role not in {NexusRole.OWNER, NexusRole.WORKER}:
        raise NotAuthorizedException("Unsupported role. Use X-Nexus-Role: owner|worker")

    role = NexusRole(raw_role)
    prefix = "owner:" if role == NexusRole.OWNER else "worker:"
    actor = raw_actor if raw_actor else ("admin" if role == NexusRole.OWNER else "taskiq")
    return RoleContext(role=role, actor=f"{prefix}{actor}")


def owner_only_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    if get_current_role(connection).role != NexusRole.OWNER:
        raise NotAuthorizedException("Only OWNER can execute this operation.")


def worker_only_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    if get_current_role(connection).role != NexusRole.WORKER:
        raise NotAuthorizedException("Only WORKER can execute this operation.")
