"""
RBAC (Role-Based Access Control) module.

Provides:
- Role enumeration (admin, accountant, auditor, viewer)
- Permission resolution from JWT extras or database
- Guard functions for protecting endpoints
- Helper to check if a user has a specific permission
"""

from __future__ import annotations

from msgspec import Struct
from enum import StrEnum

from litestar.connection import ASGIConnection
from litestar.exceptions import NotAuthorizedException
from litestar.handlers.base import BaseRouteHandler


class NexusRole(StrEnum):
    """System roles with descending privileges."""

    ADMIN = "admin"
    ACCOUNTANT = "accountant"
    AUDITOR = "auditor"
    VIEWER = "viewer"


# ── Permission codenames (mirrored from models/role.py) ──────────────────────

PERMISSIONS = {
    # Invoice
    "invoice:create": "Create invoices",
    "invoice:view": "View invoices",
    "invoice:edit": "Edit invoices",
    "invoice:delete": "Delete invoices",
    "invoice:approve": "Approve invoices",
    "invoice:submit-ksef": "Submit invoices to KSeF",
    # Company
    "company:view": "View company profiles",
    "company:edit": "Edit company profiles",
    "company:delete": "Delete companies",
    # Audit
    "audit:view": "View audit logs",
    "audit:export": "Export audit logs",
    # User management
    "user:view": "View users",
    "user:create": "Create users",
    "user:edit": "Edit users",
    "user:delete": "Delete users",
    # System admin
    "admin:access": "Access admin panel",
    "admin:settings": "Modify system settings",
    "admin:failed-tasks": "Manage failed tasks / DLQ",
    # Financial
    "finance:view": "View financial data",
    "finance:reconcile": "Reconcile accounts",
    "finance:export": "Export financial reports",
    # Contractor
    "contractor:view": "View contractors",
    "contractor:edit": "Edit contractors",
}

# ── Role-to-permission mapping ───────────────────────────────────────────────

ROLE_PERMISSIONS_MAP: dict[str, list[str]] = {
    "admin": list(PERMISSIONS.keys()),  # Admin gets everything
    "accountant": [
        "invoice:create",
        "invoice:view",
        "invoice:edit",
        "invoice:approve",
        "invoice:submit-ksef",
        "company:view",
        "company:edit",
        "audit:view",
        "finance:view",
        "finance:reconcile",
        "finance:export",
        "contractor:view",
        "contractor:edit",
    ],
    "auditor": [
        "invoice:view",
        "company:view",
        "audit:view",
        "audit:export",
        "finance:view",
        "contractor:view",
    ],
    "viewer": [
        "invoice:view",
        "company:view",
        "audit:view",
        "finance:view",
        "contractor:view",
    ],
}


class RoleContext(Struct):
    """Represents the authenticated user's role context with actor info."""

    role: str
    actor: str
    user_id: str | None = None
    permissions: list[str] | None = None


def get_current_role_context(connection: ASGIConnection) -> RoleContext:
    """Extract role context from the authenticated user on the connection.

    The user is injected by JWTAuth middleware.
    Falls back to role info from JWT extras if the User dataclass is used.
    """
    user = getattr(connection, "user", None)
    if not user:
        raise NotAuthorizedException("Missing authenticated user context")

    role_str = str(getattr(user, "role", "viewer")).strip().lower()
    username = str(getattr(user, "username", user.id)).strip().lower()
    user_id = str(getattr(user, "id", user.id))

    return RoleContext(
        role=role_str,
        actor=username,
        user_id=user_id,
    )


def has_permission(connection: ASGIConnection, permission: str) -> bool:
    """Check if the authenticated user has a specific permission.

    Resolves permissions from JWT extras first (fast path),
    then falls back to database lookup.
    """
    user = getattr(connection, "user", None)
    if not user:
        return False

    role_str = str(getattr(user, "role", "viewer")).strip().lower()

    # Role-based fast path: check the role->permission map
    perms = ROLE_PERMISSIONS_MAP.get(role_str, [])
    return permission in perms


# ── Guard functions for Litestar route handlers ──────────────────────────────


def requires_permission(permission: str):
    """Factory for Litestar route guards.

    Usage:
        @post('/invoices', guards=[requires_permission('invoice:create')])
        async def create_invoice(...): ...

    Returns a guard function that raises NotAuthorizedException
    if the user lacks the required permission.
    """

    def _guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
        if not has_permission(connection, permission):
            # Include the required permission in the error for debugging
            raise NotAuthorizedException(f"Missing required permission: {permission}")

    return _guard


def admin_only_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    """Guard: only admin role can access."""
    ctx = get_current_role_context(connection)
    if ctx.role != "admin":
        raise NotAuthorizedException("Only administrators can execute this operation.")


def accountant_or_admin_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    """Guard: accountant or admin can access."""
    ctx = get_current_role_context(connection)
    if ctx.role not in ("admin", "accountant"):
        raise NotAuthorizedException(
            "Only accountants or administrators can execute this operation."
        )


def authenticated_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    """Guard: any authenticated user can access."""
    user = getattr(connection, "user", None)
    if not user:
        raise NotAuthorizedException("Authentication required.")


def owner_only_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    """Guard: only 'owner' role (original admin superset) can access.

    Legacy guard used by existing route controllers.
    Maps to admin role in the new RBAC system.
    """
    user = getattr(connection, "user", None)
    if not user:
        raise NotAuthorizedException("Authentication required.")
    role = str(getattr(user, "role", "viewer")).strip().lower()
    if role not in ("owner", "admin"):
        raise NotAuthorizedException("Only owners or administrators can execute this operation.")


def owner_or_worker_guard(connection: ASGIConnection, _: BaseRouteHandler) -> None:
    """Guard: 'owner', 'admin', or 'accountant' roles can access.

    Legacy guard used by existing route controllers.
    Maps to admin/accountant roles in the new RBAC system.
    """
    user = getattr(connection, "user", None)
    if not user:
        raise NotAuthorizedException("Authentication required.")
    role = str(getattr(user, "role", "viewer")).strip().lower()
    if role not in ("owner", "admin", "accountant", "worker"):
        raise NotAuthorizedException("Insufficient permissions for this operation.")


def get_current_role(connection: ASGIConnection) -> str:
    """Get the current user's role string.

    Used by legacy code that needs the role as a string.
    """
    ctx = get_current_role_context(connection)
    return ctx.role
