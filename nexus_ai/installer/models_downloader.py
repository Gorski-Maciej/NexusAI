"""
models_downloader.py -- Download AI models with resume, progress reporting,
and SHA-256 integrity verification.

Designed for first-run experience in the Windows installer context.
Supports:
  - Resume via HTTP Range headers
  - Progress callbacks for UI integration
  - SHA-256 verification against manifest
  - Cancellation via anyio.Event
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any, Protocol

import anyio
import msgspec
from fsspec.implementations.cached import CachingFileSystem
from msgspec import Struct
from nexus_crypto import Sha256Hasher
from structlog import get_logger

logger = get_logger("nexus.installer.models_downloader")

# ── Progress callback type ──────────────────────────────────────────────────


class ProgressCallback(Protocol):
    def __call__(
        self,
        *,
        current_file: str,
        downloaded_bytes: int,
        total_bytes: int,
        speed_bps: float,
        overall_progress: float,
        status: str,
    ) -> None: ...


# ── Data types ──────────────────────────────────────────────────────────────


class ModelEntry(Struct):
    """A single model entry from the manifest."""

    key: str
    url: str
    sha256: str
    description: str
    size_mb: int
    required: bool


class DownloadResult(Struct):
    """Result of downloading a single model."""

    key: str
    success: bool
    error: str | None = None
    sha256_match: bool | None = None
    bytes_downloaded: int = 0


# ── Manifest loader ─────────────────────────────────────────────────────────


def load_manifest(manifest_path: str | Path | None = None) -> list[ModelEntry]:
    """Load model manifest from JSON file.

    Looks for the manifest in:
    1. Provided path
    2. config/models_manifest.json relative to project root
    3. config/models_manifest.json (w katalogu aplikacji)
    """
    if manifest_path is None:
        # Try to find the manifest
        candidates = [
            Path("config/models_manifest.json"),
            Path(__file__).resolve().parent.parent.parent / "config" / "models_manifest.json",
        ]
        if getattr(sys, "frozen", False):
            candidates.insert(0, Path(sys._MEIPASS) / "config" / "models_manifest.json")

        for cand in candidates:
            if cand.exists():
                manifest_path = cand
                break

    if manifest_path is None or not Path(manifest_path).exists():
        logger.warning("Model manifest not found at any expected location")
        return []

    # Działa z file://, s3://, http:// -- manifest może być zdalny
    with fsspec.open(manifest_path, "rb") as f:
        data: dict[str, Any] = msgspec.json.decode(f.read())

    if isinstance(data, dict) and "models" in data:
        raw_models = data["models"]
    else:
        raw_models = data

    if isinstance(raw_models, dict):
        items = raw_models.items()
    elif isinstance(raw_models, list):
        items = [(m.get("name", str(i)), m) for i, m in enumerate(raw_models)]
    else:
        return []

    entries: list[ModelEntry] = []
    for key, info in items:
        entries.append(
            ModelEntry(
                key=key,
                url=info.get("url", ""),
                sha256=info.get("sha256", ""),
                description=info.get("description", info.get("role", "")),
                size_mb=info.get("size_mb", 0),
                required=info.get("required", False),
            )
        )

    return entries


# ── SHA-256 verification ────────────────────────────────────────────────────


def compute_sha256(filepath: Path) -> str:
    """Compute SHA-256 checksum of a file (streaming via Sha256Hasher).

    z każdym protokołem (file://, s3://, http://).
    """
    sha = Sha256Hasher()
    with fsspec.open(filepath, "rb") as f:
        while True:
            chunk = f.read(65536)  # 64 KB
            if not chunk:
                break
            sha.update(chunk)
    return sha.hexdigest()


def verify_file(filepath: Path, expected_hash: str) -> bool:
    """Verify a file's SHA-256 checksum. Returns True if match or no hash provided."""
    if not expected_hash:
        # No reference checksum -- skip verification
        return True
    if not filepath.exists():
        return False
    actual = compute_sha256(filepath)
    return actual == expected_hash


# ── HuggingFace download with resume ────────────────────────────────────────


async def download_file(
    url: str,
    dest_path: Path,
    *,
    progress_cb: ProgressCallback | None = None,
    cancel_event: anyio.Event | None = None,
    chunk_size: int = 8192,
) -> tuple[bool, str | None]:
    """Download a file with resume support via HTTP Range headers.

    Returns (success, error_message).
    """
    import httpx

    dest_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = dest_path.with_suffix(dest_path.suffix + ".part")

    # Determine existing bytes for resume
    resume_bytes = temp_path.stat().st_size if temp_path.exists() else 0
    headers = {"Range": f"bytes={resume_bytes}-"} if resume_bytes > 0 else {}

    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=15.0, read=120.0, write=30.0, pool=300.0),
            limits=httpx.Limits(
                max_connections=10, max_keepalive_connections=5, keepalive_expiry=60.0
            ),
            http2=True,
            follow_redirects=True,
        ) as client:
            response = await client.get(url, headers=headers)

            if response.status_code == 416:  # Range Not Satisfiable -- file is complete
                temp_path.rename(dest_path)
                return True, None

            if response.status_code not in (200, 206):
                return False, f"HTTP {response.status_code}: {response.reason_phrase}"

            total_size: int | None = None
            content_range = response.headers.get("content-range", "")
            if content_range:
                # Parse "bytes X-Y/TOTAL"
                try:
                    total_size = int(content_range.split("/")[1])
                except (IndexError, ValueError):
                    pass
            else:
                content_length = response.headers.get("content-length")
                if content_length:
                    total_size = int(content_length)
                else:
                    total_size = None

            if total_size is None:
                total_size = resume_bytes + int(response.headers.get("content-length", 0))

            # Write to temp file (append if resuming)
            mode = "ab" if resume_bytes > 0 and response.status_code == 206 else "wb"
            downloaded = resume_bytes if mode == "ab" else 0
            import time as _time5

            start_time = _time5.monotonic()

            with open(temp_path, mode) as f:
                async for chunk in response.aiter_bytes(chunk_size):
                    if cancel_event and cancel_event.is_set():
                        return False, "Cancelled by user"

                    f.write(chunk)
                    downloaded += len(chunk)

                    if progress_cb and total_size and total_size > 0:
                        elapsed = _time5.monotonic() - start_time
                        speed = downloaded / elapsed if elapsed > 0 else 0
                        progress_cb(
                            current_file=dest_path.name,
                            downloaded_bytes=downloaded,
                            total_bytes=total_size,
                            speed_bps=speed,
                            overall_progress=0.0,  # Updated by caller
                            status="downloading",
                        )

            # Verify download size
            if total_size and downloaded < total_size:
                return False, f"Incomplete download: {downloaded} of {total_size} bytes"

            # Rename temp to final
            temp_path.rename(dest_path)
            return True, None

    except httpx.TimeoutException as e:
        return False, f"Connection timeout: {e}"
    except httpx.NetworkError as e:
        return False, f"Network error: {e}"
    except Exception as e:
        return False, f"Download failed: {e}"


# ── Main download orchestrator ──────────────────────────────────────────────


async def download_all_models(
    models_dir: str | Path,
    manifest_path: str | Path | None = None,
    *,
    progress_cb: ProgressCallback | None = None,
    cancel_event: anyio.Event | None = None,
    only_required: bool = True,
) -> list[DownloadResult]:
    """Download all required AI models.

    Args:
        models_dir: Directory to store downloaded models.
        manifest_path: Optional path to the manifest JSON file.
        progress_cb: Optional callback for progress updates.
        cancel_event: Optional event to signal cancellation.
        only_required: If True, only download required models.

    Returns:
        List of DownloadResult for each model.
    """
    models_dir = Path(models_dir)
    models_dir.mkdir(
        parents=True, exist_ok=True)
    # CachingFileSystem owija bazowy filesystem ("file") i cache'uje odczyty.
    # Następne uruchomienie: jeśli plik jest w cache, nie wymaga ponownego I/O.
    cache_storage = models_dir / ".fsspec_cache"
    cache_storage.mkdir(parents=True, exist_ok=True)
    caching_fs = CachingFileSystem(
        target_protocol="file",
        target={"auto_mkdir": True},
        cache_storage=str(cache_storage),
        maxsize=5 * 1024 * 1024 * 1024,  # 5 GB cache
        same_names=True,
    )

    entries = load_manifest(manifest_path)
    if not entries:
        logger.warning("No models found in manifest -- nothing to download")
        return []

    if only_required:
        entries = [e for e in entries if e.required]

    total_bytes = sum(e.size_mb * 1024 * 1024 for e in entries)
    downloaded_bytes_all = 0
    results: list[DownloadResult] = []

    for i, entry in enumerate(entries):
        if cancel_event and cancel_event.is_set():
            results.append(DownloadResult(key=entry.key, success=False, error="Cancelled by user"))
            break

        dest_path = models_dir / entry.key

        # Używamy caching_fs.open() z prawdziwą ścieżką zamiast sztucznego URL
        dest_url = str(dest_path)
        if caching_fs.exists(dest_url):
            # CachingFileSystem zwrócił True -- plik jest w cache lub na dysku
            logger.info("[Models] Found in fsspec cache: %s", entry.key)

        # Check if already exists and is valid
        if dest_path.exists():
            if verify_file(dest_path, entry.sha256):
                model_size = dest_path.stat().st_size
                downloaded_bytes_all += model_size
                results.append(
                    DownloadResult(
                        key=entry.key,
                        success=True,
                        sha256_match=True,
                        bytes_downloaded=model_size,
                    )
                )
                if progress_cb:
                    progress_cb(
                        current_file=entry.key,
                        downloaded_bytes=model_size,
                        total_bytes=model_size,
                        speed_bps=0,
                        overall_progress=downloaded_bytes_all / max(total_bytes, 1),
                        status="verified",
                    )
                continue
            else:
                # Hash mismatch -- remove and re-download
                logger.warning("SHA-256 mismatch for %s -- re-downloading", entry.key)
                dest_path.unlink(missing_ok=True)

        # Check for partial download
        temp_path = dest_path.with_suffix(dest_path.suffix + ".part")
        resume_bytes = temp_path.stat().st_size if temp_path.exists() else 0

        # Report starting
        if progress_cb:
            progress_cb(
                current_file=entry.key,
                downloaded_bytes=resume_bytes,
                total_bytes=entry.size_mb * 1024 * 1024,
                speed_bps=0,
                overall_progress=downloaded_bytes_all / max(total_bytes, 1),
                status="starting",
            )

        # Download model from URL in manifest
        url = entry.url

        def make_progress_for_entry(
            entry_key: str,
            entry_size: int,
            total_all: int,
            prev_downloaded: int,
        ) -> ProgressCallback:
            _prev = prev_downloaded

            def cb(
                *, current_file, downloaded_bytes, total_bytes, speed_bps, overall_progress, status
            ):
                nonlocal _prev
                # Calculate overall progress including previously downloaded models
                this_progress = _prev + downloaded_bytes
                overall = this_progress / max(total_all, 1)
                if progress_cb:
                    progress_cb(
                        current_file=current_file,
                        downloaded_bytes=downloaded_bytes,
                        total_bytes=total_bytes,
                        speed_bps=speed_bps,
                        overall_progress=overall,
                        status=status,
                    )

            return cb

        entry_progress_cb = make_progress_for_entry(
            entry.key,
            entry.size_mb * 1024 * 1024,
            total_bytes,
            downloaded_bytes_all,
        )

        success, error = await download_file(
            url,
            dest_path,
            progress_cb=entry_progress_cb,
            cancel_event=cancel_event,
        )

        if success:
            # Przy następnym uruchomieniu, caching_fs.exists() zwróci True
            # bez dotykania dysku (jeśli plik jest w cache)
            try:
                with caching_fs.open(dest_url, "rb") as _:
                    pass  # Odczyta przez CachingFileSystem -- wypełnia cache
                logger.info("[Models] Cached in fsspec: %s", entry.key)
            except Exception as cache_err:
                logger.warning("[Models] Failed to cache %s: %s", entry.key, cache_err)

            # Verify integrity
            sha256_ok = verify_file(dest_path, entry.sha256) if entry.sha256 else True
            file_size = dest_path.stat().st_size
            downloaded_bytes_all += file_size

            results.append(
                DownloadResult(
                    key=entry.key,
                    success=True,
                    sha256_match=sha256_ok,
                    bytes_downloaded=file_size,
                )
            )

            if progress_cb:
                progress_cb(
                    current_file=entry.key,
                    downloaded_bytes=file_size,
                    total_bytes=file_size,
                    speed_bps=0,
                    overall_progress=downloaded_bytes_all / max(total_bytes, 1),
                    status="completed" if sha256_ok else "hash_mismatch",
                )
        else:
            results.append(
                DownloadResult(
                    key=entry.key,
                    success=False,
                    error=error,
                )
            )

    return results


# ── First-run detection ─────────────────────────────────────────────────────


def check_models_present(models_dir: str | Path, manifest_path: str | Path | None = None) -> dict:
    """Check which models are present and valid.

    Returns a dict with:
      - all_present: True if all required models are present and valid
      - missing: list of missing model keys
      - mismatched: list of model keys with hash mismatch
      - total_required: number of required models
      - total_present: number of present and valid models
    """
    models_dir = Path(models_dir)
    entries = load_manifest(manifest_path)
    required = [e for e in entries if e.required]

    missing = []
    mismatched = []
    present = 0

    for entry in required:
        filepath = models_dir / entry.key
        if not filepath.exists():
            missing.append(entry.key)
        elif entry.sha256 and not verify_file(filepath, entry.sha256):
            mismatched.append(entry.key)
        else:
            present += 1

    return {
        "all_present": present == len(required) and not mismatched,
        "missing": missing,
        "mismatched": mismatched,
        "total_required": len(required),
        "total_present": present,
    }
