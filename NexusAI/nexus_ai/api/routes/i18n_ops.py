from __future__ import annotations

from pathlib import Path

from litestar import Controller, get

from nexus_ai.api.dto import I18nStatusDTO, TAG_I18N
from nexus_ai.api.rbac import owner_only_guard


class I18nOpsController(Controller):
    """Operational i18n visibility for API/UI/prompts."""

    path = "/system/i18n"
    guards = [owner_only_guard]
    tags = [TAG_I18N]

    @get(
        "/status",
        return_dto=I18nStatusDTO,
        summary="Get i18n status",
        description="Returns available API and prompt language translations.",
        operation_id="getI18nStatus",
    )
    async def status(self) -> dict:
        _api_dir = Path(__file__).resolve().parent.parent  # nexus_ai/api/
        api_locales = _api_dir / "locales"  # nexus_ai/api/locales
        core_prompts = _api_dir.parent / "core" / "prompts"  # nexus_ai/core/prompts
        api_languages = (
            sorted([p.stem for p in api_locales.glob("*.json")]) if api_locales.exists() else []
        )
        prompt_languages = (
            sorted([p.stem for p in core_prompts.glob("*.json")]) if core_prompts.exists() else []
        )
        return {
            "api_languages": api_languages,
            "prompt_languages": prompt_languages,
            "api_locale_dir": str(api_locales),
            "prompt_dir": str(core_prompts),
        }
