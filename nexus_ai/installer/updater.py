"""
updater.py -- Automatic update system for NexusAI.

Checks a remote version.json endpoint, compares with local version,
and if a newer version is available, prompts the user to download
and install the update.

Flow:
  1. On startup, check version.json (async HTTP)
  2. Compare with local CURRENT_VERSION
  3. If update available -> show notification + Flet dialog
  4. If user accepts -> download new installer in background
  5. SHA-256 integrity verification (KRYTYCZNE — Rec #1 v7.0)
  6. After verification -> prompt to close and run installer

Enterprise Security (v7.0):
  - SHA-256 checksum verification before install
  - Rollback support via .bak file
  - Expected hash from version.json (sha256 field)
"""

from __future__ import annotations

import platform
import tempfile
from collections.abc import Callable
from pathlib import Path
from typing import Any, Protocol

import anyio
import httpx
import msgspec
from msgspec import Struct
from structlog import get_logger

try:
    from nexus_crypto import Sha256Hasher
    _HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib
    _HAS_NEXUS_CRYPTO = False
    Sha256Hasher = None  # type: ignore

logger = get_logger("nexus.installer.updater")

# ── Local version ───────────────────────────────────────────────────────────

# Read from pyproject.toml or hardcoded
try:
    import tomllib

    _project_root = Path(__file__).resolve().parent.parent.parent
    _pyproject = _project_root / "pyproject.toml"
    if _pyproject.exists():
        with open(_pyproject, "rb") as _f:
            _data = tomllib.load(_f)
            CURRENT_VERSION = _data.get("project", {}).get("version", "0.1.0")
    else:
        CURRENT_VERSION = "0.1.0"
except Exception:
    CURRENT_VERSION = "0.1.0"

# ── Data types ──────────────────────────────────────────────────────────────


class UpdateInfo(Struct):
    """Information about an available update."""

    version: str
    release_notes: str
    download_url: str
    download_size_mb: int
    release_date: str
    minimum_version: str
    critical: bool
    sha256: str = ""  # KRYTYCZNE Rec #1 v7.0: SHA-256 checksum for integrity verification
    rollout_percentage: int = 100  # v7.0 Innowacja 2: Phased Rollout (0-100)


class UpdateCheckResult(Struct):
    """Result of checking for updates."""

    update_available: bool
    current_version: str = CURRENT_VERSION
    latest_version: str = CURRENT_VERSION
    info: UpdateInfo | None = None
    error: str | None = None


class UpdateProgressCallback(Protocol):
    def __call__(
        self,
        *,
        downloaded_bytes: int,
        total_bytes: int,
        speed_bps: float,
        status: str,
    ) -> None: ...


# ── Version endpoint URLs (tried in order) ──────────────────────────────────

UPDATE_ENDPOINTS = [
    # Production endpoint
    "https://nexusai.app/version.json",
    # GitHub Pages fallback
    "https://your-org.github.io/NexusAI/version.json",
    # Local development
    "http://127.0.0.1:8000/version.json",
]

LOCAL_VERSION_FILE = None  # Path to local version.json for testing

# ── Version comparison ──────────────────────────────────────────────────────


def _parse_version(version_str: str) -> tuple[int, ...]:
    """Parse version string like '1.2.3' into tuple of ints."""
    try:
        return tuple(int(x) for x in version_str.split("."))
    except (ValueError, AttributeError):
        return (0, 0, 0)


def _is_newer(latest: str, current: str) -> bool:
    """Check if latest version > current version."""
    return _parse_version(latest) > _parse_version(current)


# ── Check for updates ───────────────────────────────────────────────────────


async def check_for_updates(
    custom_url: str | None = None,
    timeout: int = 10,
) -> UpdateCheckResult:
    """Check remote version endpoint for available updates.

    Args:
        custom_url: Optional custom version.json URL (overrides defaults)
        timeout: HTTP request timeout in seconds

    Returns:
        UpdateCheckResult with update availability info.
    """
    # Try local version.json first (for testing/development)
    if LOCAL_VERSION_FILE and Path(LOCAL_VERSION_FILE).exists():
        try:
            with open(LOCAL_VERSION_FILE, "rb") as f:
                data: dict[str, Any] = msgspec.json.decode(f.read())
            latest = data.get("version", CURRENT_VERSION)
            if _is_newer(latest, CURRENT_VERSION):
                return UpdateCheckResult(
                    update_available=True,
                    latest_version=latest,
                    info=UpdateInfo(
                        version=latest,
                        release_notes=data.get("release_notes", ""),
                        download_url=data.get("download_url", ""),
                        download_size_mb=data.get("download_size_mb", 0),
                        release_date=data.get("release_date", ""),
                        minimum_version=data.get("minimum_version", "1.0.0"),
                        critical=data.get("critical", False),
                        rollout_percentage=data.get("rollout_percentage", 100),
                    ),
                )
            return UpdateCheckResult(update_available=False, latest_version=latest)
        except Exception as e:
            logger.debug("Local version.json check failed: %s", e)

    # Try remote endpoints
    urls = [custom_url] if custom_url else UPDATE_ENDPOINTS

    async with httpx.AsyncClient(
        timeout=httpx.Timeout(connect=10.0, read=timeout, write=10.0, pool=300.0),
        limits=httpx.Limits(max_connections=5, max_keepalive_connections=3),
        http2=True,
        follow_redirects=True,
        trust_env=True,
    ) as client:
        for url in urls:
            if not url:
                continue
            try:
                response = await client.get(url)
                if response.status_code != 200:
                    logger.debug("Update check %s returned %d", url, response.status_code)
                    continue
                content = await response.aread()
                data: dict[str, Any] = msgspec.json.decode(content)

                latest = data.get("version", CURRENT_VERSION)

                if not _is_newer(latest, CURRENT_VERSION):
                    return UpdateCheckResult(
                        update_available=False,
                        latest_version=latest,
                    )

                return UpdateCheckResult(
                    update_available=True,
                    latest_version=latest,
                    info=UpdateInfo(
                        version=latest,
                        release_notes=data.get("release_notes", ""),
                        download_url=data.get("download_url", ""),
                        download_size_mb=data.get("download_size_mb", 0),
                        release_date=data.get("release_date", ""),
                        minimum_version=data.get("minimum_version", "1.0.0"),
                        critical=data.get("critical", False),
                        rollout_percentage=data.get("rollout_percentage", 100),
                    ),
                )

            except httpx.TimeoutException:
                logger.debug("Update check timed out for %s", url)
            except httpx.NetworkError as e:
                logger.debug("Network error for %s: %s", url, e)
            except msgspec.ValidationError as e:
                logger.debug("Invalid JSON from %s: %s", url, e)
            except Exception as e:
                logger.debug("Update check failed for %s: %s", url, e)

    return UpdateCheckResult(
        update_available=False,
        error="Could not reach update server",
    )


# ── SHA-256 verification (Rec #1 v7.0: KRYTYCZNE) ────────────────────────────


def compute_file_sha256(filepath: Path) -> str:
    """Compute SHA-256 checksum of a file (streaming, 64KB chunks).

    Enterprise v7.0 Rec #1: Weryfikacja integralności pobranego instalatora.
    Zapobiega atakom Man-in-the-Middle podczas OTA update.

    Uses nexus_crypto.Sha256Hasher (Rust) for performance when available,
    falls back to Python hashlib.
    """
    if _HAS_NEXUS_CRYPTO and Sha256Hasher is not None:
        sha = Sha256Hasher()
        with open(filepath, "rb") as f:
            while True:
                chunk = f.read(65536)
                if not chunk:
                    break
                sha.update(chunk)
        return sha.hexdigest()
    else:
        import hashlib as _hashlib
        sha = _hashlib.sha256()
        with open(filepath, "rb") as f:
            while True:
                chunk = f.read(65536)
                if not chunk:
                    break
                sha.update(chunk)
        return sha.hexdigest()


def verify_installer_sha256(filepath: Path, expected_hash: str) -> bool:
    """Verify installer file SHA-256 checksum — HARD BLOCK (v7.0.1 Rec #1).

    Enterprise v7.0.1: SHA-256 verification is MANDATORY.
    If no hash provided or mismatch → installer is DISCARDED.
    This is a CRITICAL security control against MITM attacks.

    Returns True ONLY if hash matches.
    Raises ValueError if hash is missing (config error).
    """
    if not expected_hash:
        logger.critical(
            "SHA-256 HASH MISSING for update! This is a CONFIGURATION ERROR. "
            "The update server MUST provide a sha256 field in version.json. "
            "Update BLOCKED for security."
        )
        raise ValueError(
            "SHA-256 hash is REQUIRED for OTA updates. "
            "Add 'sha256' field to version.json on the update server."
        )
    if not filepath.exists():
        logger.error("Installer file not found: %s", filepath)
        return False
    actual = compute_file_sha256(filepath)
    if actual != expected_hash:
        logger.critical(
            "SHA-256 MISMATCH! Expected=%s, Got=%s — DISCARDING installer. "
            "Possible MITM attack or corrupted download.",
            expected_hash[:16], actual[:16],
        )
        return False
    logger.info("SHA-256 HARD VERIFICATION PASSED: %s", expected_hash[:16])
    return True


# ── Download update ─────────────────────────────────────────────────────────


async def download_update(
    update_info: UpdateInfo,
    *,
    progress_cb: UpdateProgressCallback | None = None,
    cancel_event: anyio.Event | None = None,
) -> Path | None:
    """Download the new installer to a temporary location.

    Args:
        update_info: Update info with download URL
        progress_cb: Optional progress callback
        cancel_event: Optional cancellation event

    Returns:
        Path to downloaded installer, or None on failure.
    """
    if not update_info.download_url:
        logger.error("No download URL in update info")
        return None

    # Create temp directory
    temp_dir = Path(tempfile.gettempdir()) / "NexusAI_Update"
    temp_dir.mkdir(parents=True, exist_ok=True)

    # Determine filename from URL
    url_path = update_info.download_url.split("/")[-1]
    if not url_path.endswith(".exe"):
        url_path = "NexusAI_Update.exe"

    dest_path = temp_dir / url_path
    temp_path = dest_path.with_suffix(dest_path.suffix + ".part")

    # Check for partial download (resume)
    resume_bytes = temp_path.stat().st_size if temp_path.exists() else 0
    headers = {"Range": f"bytes={resume_bytes}-"} if resume_bytes > 0 else {}

    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=15.0, read=120.0, write=30.0, pool=300.0),
            limits=httpx.Limits(max_connections=5, max_keepalive_connections=3),
            http2=True,
            follow_redirects=True,
        ) as client:
            response = await client.get(update_info.download_url, headers=headers)

            if response.status_code == 416:  # Already complete
                temp_path.rename(dest_path)
                return dest_path

            if response.status_code not in (200, 206):
                logger.error("Download failed: HTTP %d", response.status_code)
                return None

            # Get total size
            total_size: int | None = None
            content_range = response.headers.get("content-range", "")
            if content_range:
                try:
                    total_size = int(content_range.split("/")[1])
                except (IndexError, ValueError):
                    pass
            if total_size is None:
                content_length = response.headers.get("content-length")
                if content_length:
                    total_size = int(content_length)

            total_size = total_size or update_info.download_size_mb * 1024 * 1024

            # Write to file
            mode = "ab" if resume_bytes > 0 and response.status_code == 206 else "wb"
            downloaded = resume_bytes if mode == "ab" else 0
            import time as _time3

            start_time = _time3.monotonic()
            chunk_size = 8192

            with open(temp_path, mode) as f:
                async for chunk in response.aiter_bytes(chunk_size):
                    if cancel_event and cancel_event.is_set():
                        logger.info("Update download cancelled")
                        return None

                    f.write(chunk)
                    downloaded += len(chunk)

                    if progress_cb:
                        elapsed = _time3.monotonic() - start_time
                        speed = downloaded / elapsed if elapsed > 0 else 0
                        progress_cb(
                            downloaded_bytes=downloaded,
                            total_bytes=total_size,
                            speed_bps=speed,
                            status="downloading",
                        )

            # Rename temp to final
            temp_path.rename(dest_path)
            logger.info("Update downloaded to %s (%d bytes)", dest_path, downloaded)

            # ── KRYTYCZNE Rec #1 v7.0: SHA-256 integrity verification ──
            if not verify_installer_sha256(dest_path, update_info.sha256):
                logger.error("SHA-256 verification FAILED — discarding installer")
                dest_path.unlink(missing_ok=True)
                return None

            return dest_path

    except Exception as e:
        logger.error("Update download failed: %s", e)
        return None


# ── Install update ──────────────────────────────────────────────────────────


async def install_update(installer_path: Path) -> None:
    """Launch the downloaded installer and exit the current application.

    On Windows, runs the installer with silent flag.
    The current application will close after launching the installer.

    Enterprise v7.0: Creates .bak rollback backup before installing.
    """
    if not installer_path.exists():
        logger.error("Installer not found: %s", installer_path)
        return

    if platform.system() != "Windows":
        logger.warning("Auto-update only supported on Windows")
        return

    logger.info("Launching installer: %s", installer_path)

    try:
        # ── Rollback support (Rec #1 v7.0): backup current .exe ──
        import sys
        if getattr(sys, "frozen", False):
            current_exe = Path(sys.executable)
            backup_path = current_exe.with_suffix(current_exe.suffix + ".bak")
            if current_exe.exists():
                backup_path.unlink(missing_ok=True)
                current_exe.rename(backup_path)
                logger.info("Rollback backup created: %s", backup_path)

        # Launch the installer with silent flag (fire-and-forget -- must outlive the app)
        # /S = silent install (NSIS), /VERYSILENT = silent (Inno Setup)
        proc = await anyio.run_process(
            [str(installer_path), "/S", "/CLOSEAPPLICATIONS"],
            stdout=anyio.ProcessPipe.DEVNULL,
            stderr=anyio.ProcessPipe.DEVNULL,
        )
        logger.info("Installer launched (PID: %s)", proc.pid)

        # Schedule cleanup of temp files (fire-and-forget)
        temp_dir = installer_path.parent
        cleanup_script = temp_dir / "cleanup.bat"
        with open(cleanup_script, "w") as f:
            f.write("@echo off\n")
            f.write("timeout /t 30 /nobreak >nul\n")
            f.write(f'rmdir /s /q "{temp_dir}"\n')
            f.write('del "%~f0"\n')
        await anyio.run_process(["cmd", "/c", str(cleanup_script)])

    except Exception as e:
        logger.error("Failed to launch installer: %s", e)


# ── Flet update dialog ──────────────────────────────────────────────────────


def build_update_dialog(
    page,
    update_info: UpdateInfo,
    on_update: Callable,
    on_skip: Callable,
    on_remind_later: Callable,
):
    """Build a Flet dialog to show update availability.

    Args:
        page: Flet Page instance
        update_info: UpdateInfo with version details
        on_update: Callback when user clicks Update
        on_skip: Callback when user clicks Skip
        on_remind_later: Callback when user clicks Remind Later

    Returns:
        The AlertDialog instance
    """
    import flet as ft

    notes_preview = update_info.release_notes[:200]
    if len(update_info.release_notes) > 200:
        notes_preview += "..."

    dialog = ft.AlertDialog(
        title=ft.Row(
            [
                ft.Icon(
                    ft.icons.SYSTEM_UPDATE_ALT,
                    color=ft.colors.AMBER if not update_info.critical else ft.colors.RED,
                    size=28,
                ),
                ft.Text(
                    f"Update Available -- v{update_info.version}",
                    size=18,
                    weight=ft.FontWeight.BOLD,
                ),
            ],
        ),
        content=ft.Column(
            [
                ft.Text(
                    "A new version of NexusAI is available!",
                    size=14,
                ),
                ft.Container(height=8),
                ft.Text(
                    f"Current version: {CURRENT_VERSION}\n"
                    f"New version: v{update_info.version}\n"
                    f"Released: {update_info.release_date}",
                    size=13,
                    color=ft.colors.GREY_600,
                ),
                ft.Container(height=8),
                ft.Text(
                    "What's new:",
                    size=14,
                    weight=ft.FontWeight.BOLD,
                ),
                ft.Text(
                    notes_preview,
                    size=12,
                    color=ft.colors.GREY_600,
                ),
                ft.Container(height=8),
                ft.Text(
                    f"Download size: ~{update_info.download_size_mb} MB",
                    size=12,
                    color=ft.colors.GREY_500,
                ),
            ],
            tight=True,
            width=400,
        ),
        actions=[
            ft.TextButton(
                "Skip This Version",
                on_click=lambda _: on_skip(),
            ),
            ft.TextButton(
                "Remind Me Later",
                on_click=lambda _: on_remind_later(),
            ),
            ft.ElevatedButton(
                "Update Now",
                icon=ft.icons.DOWNLOAD,
                color=ft.colors.WHITE,
                bgcolor=ft.colors.BLUE_700 if not update_info.critical else ft.colors.RED_700,
                on_click=lambda _: on_update(),
            ),
        ],
        actions_alignment=ft.MainAxisAlignment.END,
    )

    return dialog


# ── Update progress dialog ──────────────────────────────────────────────────


def build_update_progress_dialog(page):
    """Build a Flet dialog showing update download progress.

    Returns (dialog, progress_bar, status_text, progress_text).
    """
    import flet as ft

    progress_bar = ft.ProgressBar(
        value=0.0,
        width=350,
        bar_height=8,
        color=ft.colors.BLUE,
        bgcolor=ft.colors.GREY_300,
    )
    status_text = ft.Text(
        "Downloading update...",
        size=13,
    )
    progress_text = ft.Text(
        "",
        size=12,
        color=ft.colors.GREY_600,
    )

    dialog = ft.AlertDialog(
        title=ft.Text("Downloading Update"),
        content=ft.Column(
            [
                status_text,
                ft.Container(height=8),
                progress_bar,
                ft.Container(height=4),
                progress_text,
            ],
            tight=True,
            width=380,
        ),
        actions=[],  # No actions during download
    )

    return dialog, progress_bar, status_text, progress_text
