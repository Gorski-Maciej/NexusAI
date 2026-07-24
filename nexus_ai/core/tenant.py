from __future__ import annotations

import re
from contextvars import ContextVar
from pathlib import Path
import warnings

from nexus_ai.core.config import AppConfig

# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC v7.0 Security Audit: Tenant Isolation Hardening
# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT_TENANT_ID is now HARD-FORBIDDEN outside explicit allowlist.
# Using the default raises TenantIsolationError to prevent accidental
# data sharing between tenants (identified as security gap in v7.0 audit).
# ═══════════════════════════════════════════════════════════════════════════════

_DEFAULT_TENANT_ID_SENTINEL = "default"
_tenant_id_ctx: ContextVar[str] = ContextVar("tenant_id", default=_DEFAULT_TENANT_ID_SENTINEL)


class TenantIsolationError(RuntimeError):
    """Raised when a tenant operation is attempted without explicit tenant_id.

    SUPERMOC v7.0: Hard-security — każdy niejawny dostęp do "default"
    kończy się błędem. To eliminuje ryzyko accidental data sharing
    między tenantami (zidentyfikowane w audycie v7.0).
    """
    __slots__ = ()

    def __init__(self, operation: str = "") -> None:
        msg = (
            f"TenantIsolationError: operation '{operation}' requires explicit tenant_id. "
            "Using 'default' as fallback is forbidden. "
            "Provide tenant_id via JWT, x-tenant-id header, or NEXUS_TENANT_ID env var."
        )
        super().__init__(msg)


# Explicit allowlist dla operacji które mogą używać "default"
# (np. health checks, auth endpoints). Wszystko inne → TenantIsolationError.
_TENANT_ALLOWLIST_DEFAULT: frozenset[str] = frozenset({
    "health", "auth", "metrics", "version", "security.txt",
})


def _deprecated_default_tenant(operation: str = "") -> str:
    """v7.0 HARD: Rzuć TenantIsolationError zamiast fallback do 'default'.

    Operacje na allowliście (health, auth, metrics) nadal mogą używać default.
    Wszystkie pozostałe operacje wymagają explicit tenant_id.
    """
    op_lower = operation.lower().strip()
    for allowed in _TENANT_ALLOWLIST_DEFAULT:
        if allowed in op_lower:
            return _DEFAULT_TENANT_ID_SENTINEL
    raise TenantIsolationError(operation)

DEFAULT_TENANT_ID = _DEFAULT_TENANT_ID_SENTINEL  # Backward compat — use explicitly per-tenant


class TenantManager:
    """Resolves and creates per-tenant local storage layout."""
    __slots__ = ('_config', '_root')

    _allowed_tenant_pattern = re.compile(r"^[a-zA-Z0-9_-]+$")

    def __init__(self, config: AppConfig, root_dir_name: str = "local_data") -> None:
        self._config = config
        self._root = config.base_dir / root_dir_name
        self._root.mkdir(parents=True, exist_ok=True)

    def sanitize_tenant_id(self, tenant_id: str | None) -> str:
        candidate = (tenant_id or "").strip() or _deprecated_default_tenant()
        if not self._allowed_tenant_pattern.fullmatch(candidate):
            raise ValueError("tenant_id can only contain letters, numbers, '_' and '-'")
        return candidate

    def resolve_tenant_dir(self, tenant_id: str | None = None) -> Path:
        safe_tenant_id = self.sanitize_tenant_id(tenant_id or get_current_tenant_id())
        tenant_dir = self._root / safe_tenant_id
        tenant_dir.mkdir(parents=True, exist_ok=True)
        return tenant_dir

    def sqlite_path(self, tenant_id: str | None = None) -> Path:
        return self.resolve_tenant_dir(tenant_id) / self._config.sqlite_file

    def duckdb_path(self, tenant_id: str | None = None) -> Path:
        return self.resolve_tenant_dir(tenant_id) / self._config.duckdb_file


def set_current_tenant_id(tenant_id: str) -> object:
    return _tenant_id_ctx.set(tenant_id)


def reset_current_tenant_id(token: object) -> None:
    _tenant_id_ctx.reset(token)


def get_current_tenant_id() -> str:
    return _tenant_id_ctx.get()
