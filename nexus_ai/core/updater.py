"""
core/updater.py — Automatic update system with HTTP cache (hishel).

SUPERMOCE HISHEL:
  - check_for_updates() używa CachedHttpClient — GitHub API odpowiedzi cache'owane
  - download_and_swap_update() używa httpx z stream (bez cache — pliki binarne)
  - Manifest version.json cache'owany przez hishel (Cache-Control, ETag)
  - Ochrona przed GitHub API rate limiting (60 req/h bez auth)
"""

from __future__ import annotations

import anyio
import httpx
from packaging import version
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.updater")

CURRENT_VERSION = "1.0.0"
REPO_URL = "https://api.github.com/repos/TwojLogin/NexusAccounting/releases/latest"


async def check_for_updates() -> dict:
    """Sprawdza, czy na GitHubie jest nowsza wersja.

    SUPERMOC HISHEL:
      - Używa CachedHttpClient zamiast surowego httpx.AsyncClient
      - GitHub API odpowiedzi są cache'owane przez hishel (SQLite)
      - Przy kolejnych wywołaniach: cache HIT zamiast HTTP request
      - Ochrona przed GitHub API rate limiting

    Returns:
        dict z kluczami update_available, version, url lub update_available=False.
    """
    client = CachedHttpClient(record_stats=False)
    try:
        response = await client.get(REPO_URL)
        if response.status_code == 200:
            latest_release = response.json()
            latest_version = latest_release["tag_name"].replace("v", "")

            if version.parse(latest_version) > version.parse(CURRENT_VERSION):
                download_url = latest_release["assets"][0]["browser_download_url"]
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
    """Pobiera nowy plik wykonywalny i podmienia go.

    Używa surowego httpx.AsyncClient (streaming) — duże pliki binarne
    nie są cache'owane przez hishel (nie ma sensu).

    Args:
        download_url: URL do nowej wersji.
        current_exe: Ścieżka do obecnego pliku wykonywalnego.
        new_exe_path: Ścieżka tymczasowa dla nowego pliku.
        old_exe_path: Ścieżka dla kopii zapasowej starego pliku.

    Returns:
        True jeśli operacja się powiodła.
    """
    try:
        async with httpx.AsyncClient() as client:
            async with client.stream("GET", download_url) as response:
                async with await anyio.open_file(new_exe_path, "wb") as f:
                    async for chunk in response.aiter_bytes():
                        await f.write(chunk)

        # Podmiana nazw (Swap)
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
