from __future__ import annotations

from collections import defaultdict

from litestar import Controller, get, post

from api.rbac import owner_only_guard
from core.config import AppConfig
from core.model_retention import list_model_versions, prune_model_versions


class ModelRegistryController(Controller):
    """Operational model lifecycle endpoints (retention/governance)."""

    path = "/api/v1/system/models"
    guards = [owner_only_guard]

    @get("/retention-status")
    async def retention_status(self) -> dict:
        config = AppConfig()
        models_root = config.base_dir / "models"
        grouped: dict[str, list[str]] = defaultdict(list)
        for item in list_model_versions(models_root):
            grouped[item.name].append(item.version)
        return {
            "models": {name: sorted(versions) for name, versions in grouped.items()},
            "models_scanned": len(grouped),
        }

    @post("/retention-prune")
    async def retention_prune(self) -> dict:
        config = AppConfig()
        models_root = config.base_dir / "models"
        archive_root = config.base_dir / "models_archive"
        return prune_model_versions(models_root, keep_last=3, archive_root=archive_root)
