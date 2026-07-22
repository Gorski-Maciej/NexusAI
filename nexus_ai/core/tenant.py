from __future__ import annotations

import re
from contextvars import ContextVar
from pathlib import Path
import warnings

from nexus_ai.core.config import AppConfig

# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC v7.0 Security Audit: Tenant Isolation Hardening
# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT_TENANT_ID is now a sentinel requiring explicit override.
# Using the default triggers a DeprecationWarning and will be removed in v8.0.
# Each tenant MUST have a unique, explicit tenant_id to prevent accidental
# data sharing between tenants (identified as security gap in v7.0 audit).
# ═══════════════════════════════════════════════════════════════════════════════

_DEFAULT_TENANT_ID_SENTINEL = "default"
_tenant_id_ctx: ContextVar[str] = ContextVar("tenant_id", default=_DEFAULT_TENANT_ID_SENTINEL)

# Zachowaj dla kompatybilności wstecznej, ale oznacz jako DEPRECATED
def _deprecated_default_tenant() -> str:
    warnings.warn(
        "DEFAULT_TENANT_ID='default' is deprecated. "
        "Each tenant must have an explicit, unique tenant_id. "
        "Using 'default' risks accidental data sharing between tenants. "
        "Set a unique tenant ID via NEXUS_TENANT_ID or middleware. "
        "This will become an error in NexusAI v8.0.",
        DeprecationWarning,
        stacklevel=3,
    )
    return _DEFAULT_TENANT_ID_SENTINEL

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
