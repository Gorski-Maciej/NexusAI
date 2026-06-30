from __future__ import annotations

import re
from contextvars import ContextVar
from pathlib import Path

from nexus_ai.core.config import AppConfig

DEFAULT_TENANT_ID = "default"
_tenant_id_ctx: ContextVar[str] = ContextVar("tenant_id", default=DEFAULT_TENANT_ID)


class TenantManager:
    """Resolves and creates per-tenant local storage layout."""

    _allowed_tenant_pattern = re.compile(r"^[a-zA-Z0-9_-]+$")

    def __init__(self, config: AppConfig, root_dir_name: str = "local_data") -> None:
        self._config = config
        self._root = config.base_dir / root_dir_name
        self._root.mkdir(parents=True, exist_ok=True)

    def sanitize_tenant_id(self, tenant_id: str | None) -> str:
        candidate = (tenant_id or "").strip() or DEFAULT_TENANT_ID
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
