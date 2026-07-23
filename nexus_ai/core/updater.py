"""
core/updater.py -- Automatic update system.
"""

from __future__ import annotations

import anyio
import httpx
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient
from nexus_ai.core.version_utils import parse_version

logger = get_logger("nexus.updater")

# ── Dynamic version from pyproject.toml (v7.0 Rec #3: Krytyczne) ──────────
try:
    import tomllib
    from pathlib import Path
    _project_root = Path(__file__).resolve().parent.parent.parent
    _pyproject = _project_root / "pyproject.toml"
    if _pyproject.exists():
        with open(_pyproject, "rb") as _f:
            _data = tomllib.load(_f)
            CURRENT_VERSION = _data.get("project", {}).get("version", "1.0.0")
    else:
        CURRENT_VERSION = "1.0.0"
except Exception:
    CURRENT_VERSION = "1.0.0"

# ── GitHub API endpoint (v7.0 Rec #3: Krytyczne) ──────────────────────────
REPO_URL = "https://api.github.com/repos/Gorski-Maciej/NexusAI/releases/latest"


async def check_for_updates() -> dict:
    """Sprawdza, czy na GitHubie jest nowsza wersja.

    v7.0 Rec #3: Używa dynamicznego CURRENT_VERSION z pyproject.toml.
    v7.0 Rec #3: Używa faktycznego REPO_URL zamiast placeholder.
    """
    client = CachedHttpClient()
    try:
        response = await client.get(
            REPO_URL,
            headers={"Accept": "application/vnd.github.v3+json"},
        )
        if response.status_code == 200:
            latest_release = response.json()
            latest_version = latest_release["tag_name"].replace("v", "")

            if parse_version(latest_version) > parse_version(CURRENT_VERSION):
                assets = latest_release.get("assets", [])
                if not assets:
                    logger.warning("[Updater] No assets in latest release")
                    return {"update_available": False}
                download_url = assets[0]["browser_download_url"]
                logger.info(
                    "[Updater] Update available: %s -> %s",
                    CURRENT_VERSION, latest_version,
                )
                return {
                    "update_available": True,
                    "version": latest_version,
                    "url": download_url,
                }
    except Exception as e:
        logger.warning("[Updater] check failed: %s", e)
    finally:
        await client.close()
    return {"update_available": False}


async def download_and_swap_update(
    download_url: str, current_exe: str, new_exe_path: str, old_exe_path: str
) -> bool:
    try:
        async with httpx.AsyncClient() as client:
            async with client.stream("GET", download_url) as response:
                async with await anyio.open_file(new_exe_path, "wb") as f:
                    async for chunk in response.aiter_bytes():
                        await f.write(chunk)

        old_path = anyio.Path(old_exe_path)
        if await old_path.exists():
            await old_path.unlink()

        current_path = anyio.Path(current_exe)
        await current_path.rename(old_exe_path)
        await anyio.Path(new_exe_path).rename(current_exe)
        return True
    except Exception as e:
        logger.error("[Updater] Swap failed: %s", e)
        return False
