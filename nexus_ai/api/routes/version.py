"""API version information endpoint (Rozwiązanie 22)."""

from __future__ import annotations

from typing import Any

from litestar import Controller, get

from nexus_ai.api.dto import TAG_SYSTEM, VersionInfoDTO


class VersionController(Controller):
    """API version information endpoint."""

    path = "/version"
    tags = (TAG_SYSTEM,)

    @get(
        "/",
        return_dto=VersionInfoDTO,
        summary="Get API version info",
        description="Returns current API version, deprecated versions, and migration paths.",
        operation_id="getApiVersion",
        cache=3600,
    )
    async def get_version(self) -> dict[str, Any]:
        """Return current API version and deprecation info."""
        return {
            "current_version": "v2",
            "current_version_path": "/api/v2",
            "deprecated_versions": [
                {
                    "version": "v1",
                    "path": "/api/v1",
                    "deprecated": True,
                    "sunset": "2026-12-31T23:59:59Z",
                    "migration_url": "/api/v2",
                }
            ],
            "unversioned_endpoints": [
                {
                    "path": "/api/triage",
                    "migrated_to": "/api/v2/triage",
                    "deprecated": True,
                    "sunset": "2026-12-31T23:59:59Z",
                },
                {
                    "path": "/api/analytics",
                    "migrated_to": "/api/v2/analytics",
                    "deprecated": True,
                    "sunset": "2026-12-31T23:59:59Z",
                },
            ],
            "supported_versions": {
                "v1": {
                    "status": "deprecated",
                    "sunset": "2026-12-31T23:59:59Z",
                    "successor": "/api/v2",
                },
                "v2": {
                    "status": "current",
                    "sunset": None,
                    "successor": None,
                },
            },
        }
