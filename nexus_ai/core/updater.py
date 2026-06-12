# core/updater.py
import os

import httpx
from packaging import version

CURRENT_VERSION = "1.0.0"
REPO_URL = "[https://api.github.com/repos/TwojLogin/NexusAccounting/releases/latest](https://api.github.com/repos/TwojLogin/NexusAccounting/releases/latest)"


async def check_for_updates() -> dict:
    """Sprawdza, czy na GitHubie jest nowsza wersja."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
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
        print(f"[Updater] Błąd: {e}")
    return {"update_available": False}


async def download_and_swap_update(
    download_url: str, current_exe: str, new_exe_path: str, old_exe_path: str
) -> bool:
    try:
        async with httpx.AsyncClient() as client:
            async with client.stream("GET", download_url) as response:
                with open(new_exe_path, "wb") as f:
                    for chunk in response.iter_bytes():
                        f.write(chunk)

        # Podmiana nazw (Swap)
        if os.path.exists(old_exe_path):
            os.remove(old_exe_path)

        os.rename(current_exe, old_exe_path)
        os.rename(new_exe_path, current_exe)
        return True
    except Exception as e:
        print(f"[Updater] Błąd aktualizacji: {e}")
        return False
