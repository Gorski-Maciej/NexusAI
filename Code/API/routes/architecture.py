from __future__ import annotations

from litestar import Controller, get

from ..architecture_blueprint import architecture_blueprint


class ArchitectureController(Controller):
    path = "/api/v2/architecture"
    tags = ["Architecture"]

    @get("/blueprint")
    async def get_blueprint(self) -> dict[str, object]:
        """Expose full blueprint with required technologies and UML."""
        return architecture_blueprint()
