"""
delta_updater.py — F3.3 v7.0 Audit: Delta Updates OTA (bsdiff4).

Raport v7.0 Rec #13: Delta Updates z bsdiff4 — redukcja downloadu 80-95%.
Zamiast pobierać pełny instalator (~100MB), pobieramy tylko diff między
obecną a nową wersją (~5-20MB).

Enterprise v7.0:
  - bsdiff4 do generowania i aplikowania patchy
  - SHA-256 weryfikacja przed i po patchowaniu
  - Rollback: backup obecnego pliku przed patchowaniem
  - Resume: partial download wznawiany przez HTTP Range
"""

from __future__ import annotations

import hashlib
import os
import tempfile
from pathlib import Path
from typing import Any

import httpx
from structlog import get_logger

logger = get_logger("nexus.installer.delta_updater")

# ── Try bsdiff4 import ────────────────────────────────────────────────────────
try:
    import bsdiff4
    HAS_BSDIFF = True
except ImportError:
    HAS_BSDIFF = False
    logger.warning("[DELTA] bsdiff4 not available — delta updates disabled")

# ── Constants ─────────────────────────────────────────────────────────────────
CHUNK_SIZE = 64 * 1024  # 64KB streaming
DELTA_EXTENSION = ".delta"
BACKUP_EXTENSION = ".bak"


def compute_sha256(filepath: Path) -> str:
    """Compute SHA-256 of a file (streaming)."""
    sha = hashlib.sha256()
    with open(filepath, "rb") as f:
        while True:
            chunk = f.read(CHUNK_SIZE)
            if not chunk:
                break
            sha.update(chunk)
    return sha.hexdigest()


def generate_delta(old_file: Path, new_file: Path, output: Path) -> bool:
    """Generate a bsdiff4 delta between old and new binaries.

    Returns True if delta was created successfully.
    """
    if not HAS_BSDIFF:
        logger.error("[DELTA] bsdiff4 not installed — cannot generate delta")
        return False

    if not old_file.exists():
        logger.error("[DELTA] Old file not found: %s", old_file)
        return False

    if not new_file.exists():
        logger.error("[DELTA] New file not found: %s", new_file)
        return False

    try:
        old_data = old_file.read_bytes()
        new_data = new_file.read_bytes()
        delta = bsdiff4.diff(old_data, new_data)
        output.write_bytes(delta)

        old_size = old_file.stat().st_size
        new_size = new_file.stat().st_size
        delta_size = output.stat().st_size
        reduction = (1 - delta_size / new_size) * 100

        logger.info(
            "[DELTA] Generated delta: old=%dKB new=%dKB delta=%dKB (%.0f%% reduction)",
            old_size // 1024, new_size // 1024, delta_size // 1024, reduction,
        )
        return True
    except Exception as exc:
        logger.error("[DELTA] Failed to generate delta: %s", exc)
        return False


def apply_delta(old_file: Path, delta_file: Path, output: Path) -> bool:
    """Apply a bsdiff4 delta to an old binary, producing the new binary.

    Returns True if patching succeeded.
    """
    if not HAS_BSDIFF:
        logger.error("[DELTA] bsdiff4 not installed — cannot apply delta")
        return False

    if not old_file.exists() or not delta_file.exists():
        return False

    try:
        old_data = old_file.read_bytes()
        delta_data = delta_file.read_bytes()
        new_data = bsdiff4.patch(old_data, delta_data)
        output.write_bytes(new_data)
        logger.info("[DELTA] Patch applied: %s → %s (%d bytes)", old_file.name, output.name, output.stat().st_size)
        return True
    except Exception as exc:
        logger.error("[DELTA] Failed to apply delta: %s", exc)
        return False


async def download_delta(
    delta_url: str,
    dest_dir: Path,
    *,
    expected_sha256: str = "",
    cancel_event: Any = None,
    progress_cb: Any = None,
) -> Path | None:
    """Download a delta file with resume support.

    Args:
        delta_url: URL to download the delta from
        dest_dir: Directory to save the delta file
        expected_sha256: Expected SHA-256 hash for verification
        cancel_event: Optional cancellation event
        progress_cb: Optional progress callback

    Returns:
        Path to downloaded delta file, or None on failure
    """
    if not delta_url:
        return None

    dest_dir.mkdir(parents=True, exist_ok=True)
    filename = delta_url.split("/")[-1] or "update.delta"
    dest_path = dest_dir / filename
    temp_path = dest_path.with_suffix(dest_path.suffix + ".part")

    # Resume support
    resume_bytes = temp_path.stat().st_size if temp_path.exists() else 0
    headers = {"Range": f"bytes={resume_bytes}-"} if resume_bytes > 0 else {}

    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=15.0, read=300.0, write=30.0),
            http2=True,
            follow_redirects=True,
        ) as client:
            response = await client.get(delta_url, headers=headers)

            if response.status_code == 416:
                temp_path.rename(dest_path)
                return dest_path

            if response.status_code not in (200, 206):
                logger.error("[DELTA] Download failed: HTTP %d", response.status_code)
                return None

            mode = "ab" if resume_bytes > 0 and response.status_code == 206 else "wb"
            downloaded = resume_bytes if mode == "ab" else 0
            import time as _time
            start = _time.monotonic()

            with open(temp_path, mode) as f:
                async for chunk in response.aiter_bytes(8192):
                    if cancel_event and cancel_event.is_set():
                        return None
                    f.write(chunk)
                    downloaded += len(chunk)

                    if progress_cb:
                        elapsed = _time.monotonic() - start
                        speed = downloaded / elapsed if elapsed > 0 else 0
                        progress_cb(
                            downloaded=downloaded,
                            speed=speed,
                            status="downloading_delta",
                        )

            # Verify SHA-256
            temp_path.rename(dest_path)
            if expected_sha256:
                actual = compute_sha256(dest_path)
                if actual != expected_sha256:
                    logger.error("[DELTA] SHA-256 mismatch! Expected=%s Got=%s", expected_sha256[:16], actual[:16])
                    dest_path.unlink()
                    return None

            logger.info("[DELTA] Downloaded delta: %s (%d bytes)", dest_path.name, dest_path.stat().st_size)
            return dest_path

    except Exception as exc:
        logger.error("[DELTA] Download failed: %s", exc)
        return None


async def delta_update_flow(
    current_exe: Path,
    delta_url: str,
    expected_sha256: str = "",
    expected_new_sha256: str = "",
    progress_cb: Any = None,
    cancel_event: Any = None,
) -> bool:
    """Complete delta update flow: download delta → verify → patch → verify → replace.

    Enterprise v7.0 Rec #13: 80-95% reduction in download size.
    With rollback support: creates .bak before patching.

    Returns True if update was applied successfully.
    """
    if not HAS_BSDIFF:
        logger.error("[DELTA] bsdiff4 required for delta updates")
        return False

    if not current_exe.exists():
        logger.error("[DELTA] Current executable not found: %s", current_exe)
        return False

    tmp_dir = Path(tempfile.gettempdir()) / "NexusAI_Delta"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    # Step 1: Download delta
    if progress_cb:
        progress_cb(downloaded=0, speed=0, status="downloading_delta")
    delta_file = await download_delta(
        delta_url, tmp_dir,
        expected_sha256=expected_sha256,
        cancel_event=cancel_event,
        progress_cb=progress_cb,
    )
    if delta_file is None:
        return False

    # Step 2: Backup current executable
    backup_path = current_exe.with_suffix(current_exe.suffix + BACKUP_EXTENSION)
    backup_path.unlink(missing_ok=True)
    current_exe.rename(backup_path)
    logger.info("[DELTA] Backup created: %s", backup_path)

    # Step 3: Apply delta to produce new executable
    new_exe = tmp_dir / f"NexusAI_new{current_exe.suffix}"
    if progress_cb:
        progress_cb(downloaded=0, speed=0, status="applying_delta")

    if not apply_delta(backup_path, delta_file, new_exe):
        # Rollback: restore backup
        backup_path.rename(current_exe)
        logger.error("[DELTA] Patch failed — rolled back")
        return False

    # Step 4: Verify new executable SHA-256
    if expected_new_sha256:
        actual = compute_sha256(new_exe)
        if actual != expected_new_sha256:
            new_exe.unlink()
            backup_path.rename(current_exe)
            logger.error("[DELTA] New binary SHA-256 mismatch — rolled back")
            return False

    # Step 5: Replace current executable
    new_exe.rename(current_exe)
    os.chmod(current_exe, 0o755)

    # Step 6: Cleanup
    delta_file.unlink(missing_ok=True)
    backup_path.unlink(missing_ok=True)

    if progress_cb:
        progress_cb(downloaded=0, speed=0, status="complete")
    logger.info("[DELTA] Update complete! New binary: %s (%d bytes)", current_exe.name, current_exe.stat().st_size)
    return True
