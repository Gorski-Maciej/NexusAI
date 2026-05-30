"""
Role & Permission models for RBAC.

Roles: admin, accountant, auditor, viewer
Each role has a set of Permission codenames (e.g. invoice:create, audit:view, company:delete)
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import TYPE_CHECKING, List
import uuid

from sqlalchemy import DateTime, String, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from db.database import Base

if TYPE_CHECKING:
    from .user import UserAccount


class Role(Base):
    """System role (admin, accountant, auditor, viewer)."""
    __tablename__ = "roles"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String(32), unique=True, nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    is_system: Mapped[bool] = mapped_column(default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    users: Mapped[List[UserAccount]] = relationship(
        "UserAccount", secondary="user_roles", back_populates="roles", lazy="selectin"
    )
    permissions: Mapped[List["Permission"]] = relationship(
        "Permission", secondary="role_permissions", back_populates="roles", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Role(name={self.name})>"


class Permission(Base):
    """Granular permission codename (e.g. invoice:create, audit:view)."""
    __tablename__ = "permissions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    codename: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    resource: Mapped[str] = mapped_column(String(32), nullable=False)  # e.g. "invoice", "audit", "company"
    action: Mapped[str] = mapped_column(String(32), nullable=False)    # e.g. "create", "view", "delete"
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    roles: Mapped[List[Role]] = relationship(
        "Role", secondary="role_permissions", back_populates="permissions", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Permission(codename={self.codename})>"


class UserRole(Base):
    """Many-to-many link between UserAccount and Role."""
    __tablename__ = "user_roles"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    role_id: Mapped[str] = mapped_column(
        String, ForeignKey("roles.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self) -> str:
        return f"<UserRole(user={self.user_id}, role={self.role_id})>"


class RolePermission(Base):
    """Many-to-many link between Role and Permission."""
    __tablename__ = "role_permissions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    role_id: Mapped[str] = mapped_column(
        String, ForeignKey("roles.id", ondelete="CASCADE"), nullable=False, index=True
    )
    permission_id: Mapped[str] = mapped_column(
        String, ForeignKey("permissions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self) -> str:
        return f"<RolePermission(role={self.role_id}, perm={self.permission_id})>"


# ── Permission codenames inventory ───────────────────────────────────────────

PERMISSION_REGISTRY: dict[str, dict[str, str]] = {
    # Invoice permissions
    "invoice:create": {"resource": "invoice", "action": "create", "description": "Create invoices"},
    "invoice:view": {"resource": "invoice", "action": "view", "description": "View invoices"},
    "invoice:edit": {"resource": "invoice", "action": "edit", "description": "Edit invoices"},
    "invoice:delete": {"resource": "invoice", "action": "delete", "description": "Delete invoices"},
    "invoice:approve": {"resource": "invoice", "action": "approve", "description": "Approve invoices"},
    "invoice:submit-ksef": {"resource": "invoice", "action": "submit-ksef", "description": "Submit invoices to KSeF"},

    # Company permissions
    "company:view": {"resource": "company", "action": "view", "description": "View company profiles"},
    "company:edit": {"resource": "company", "action": "edit", "description": "Edit company profiles"},
    "company:delete": {"resource": "company", "action": "delete", "description": "Delete companies"},

    # Audit permissions
    "audit:view": {"resource": "audit", "action": "view", "description": "View audit logs"},
    "audit:export": {"resource": "audit", "action": "export", "description": "Export audit logs"},

    # User management
    "user:view": {"resource": "user", "action": "view", "description": "View users"},
    "user:create": {"resource": "user", "action": "create", "description": "Create users"},
    "user:edit": {"resource": "user", "action": "edit", "description": "Edit users"},
    "user:delete": {"resource": "user", "action": "delete", "description": "Delete users"},

    # System admin
    "admin:access": {"resource": "admin", "action": "access", "description": "Access admin panel"},
    "admin:settings": {"resource": "admin", "action": "settings", "description": "Modify system settings"},
    "admin:failed-tasks": {"resource": "admin", "action": "failed-tasks", "description": "Manage failed tasks / DLQ"},

    # Financial permissions
    "finance:view": {"resource": "finance", "action": "view", "description": "View financial data"},
    "finance:reconcile": {"resource": "finance", "action": "reconcile", "description": "Reconcile accounts"},
    "finance:export": {"resource": "finance", "action": "export", "description": "Export financial reports"},

    # Contractor permissions
    "contractor:view": {"resource": "contractor", "action": "view", "description": "View contractors"},
    "contractor:edit": {"resource": "contractor", "action": "edit", "description": "Edit contractors"},
}

# ── Role-to-permission mapping ───────────────────────────────────────────────

ROLE_PERMISSIONS: dict[str, list[str]] = {
    "admin": [
        "invoice:create", "invoice:view", "invoice:edit", "invoice:delete", "invoice:approve", "invoice:submit-ksef",
        "company:view", "company:edit", "company:delete",
        "audit:view", "audit:export",
        "user:view", "user:create", "user:edit", "user:delete",
        "admin:access", "admin:settings", "admin:failed-tasks",
        "finance:view", "finance:reconcile", "finance:export",
        "contractor:view", "contractor:edit",
    ],
    "accountant": [
        "invoice:create", "invoice:view", "invoice:edit", "invoice:approve", "invoice:submit-ksef",
        "company:view", "company:edit",
        "audit:view",
        "finance:view", "finance:reconcile", "finance:export",
        "contractor:view", "contractor:edit",
    ],
    "auditor": [
        "invoice:view",
        "company:view",
        "audit:view", "audit:export",
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
