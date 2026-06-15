"""
dependency_downloader.py — Auto-download system dependencies (NATS, TigerBeetle).

Downloads required binaries for the current platform, verifies them,
and manages their lifecycle as background processes.

Supported binaries:
  - NATS Server (nats-server) — message broker with JetStream
  - TigerBeetle — accounting ledger engine (standalone binary)
"""

from __future__ import annotations

import os
import platform
import stat

import anyio
from msgspec import Struct
from pathlib import Path
from typing import Protocol
import httpx
from structlog import get_logger

logger = get_logger("nexus.installer.dependencies")

# ── Progress callback ───────────────────────────────────────────────────────


class DependencyProgressCallback(Protocol):
    def __call__(
        self,
        *,
        current_binary: str,
        downloaded_bytes: int,
        total_bytes: int,
        speed_bps: float,
        overall_progress: float,
        status: str,  # downloading, extracting, verifying, done, error
    ) -> None: ...


# ─── Platform detection ─────────────────────────────────────────────────────


def _get_platform() -> str:
    """Return platform key: windows, linux, darwin."""
    system = platform.system().lower()
    if system == "windows":
        return "windows"
    elif system == "linux":
        return "linux"
    elif system == "darwin":
        return "darwin"
    return system


def _get_arch() -> str:
    """Return architecture: amd64, arm64, 386."""
    machine = platform.machine().lower()
    if machine in ("amd64", "x86_64", "x64"):
        return "amd64"
    elif machine in ("arm64", "aarch64"):
        return "arm64"
    elif machine in ("i386", "i686", "x86"):
        return "386"
    return "amd64"  # Default to amd64


# ── Binary definitions ──────────────────────────────────────────────────────


class BinaryDefinition(Struct):
    """Definition of a binary to download."""

    name: str
    display_name: str
    version: str
    url_template: str  # {platform}, {arch}, {version}
    filename_template: str  # Output filename
    description: str
    required: bool = True


BINARY_MANIFEST: list[BinaryDefinition] = [
    BinaryDefinition(
        name="nats-server",
        display_name="NATS Server",
        version="2.10.22",
        url_template=(
            "https://github.com/nats-io/nats-server/releases/download/"
            "v{version}/nats-server-v{version}-{platform}-{arch}.zip"
        ),
        filename_template="nats-server{ext}",
        description="Message broker with JetStream support for task queuing",
        required=True,
    ),
    BinaryDefinition(
        name="tigerbeetle",
        display_name="TigerBeetle",
        version="0.16.16",
        url_template=(
            "https://github.com/tigerbeetle/tigerbeetle/releases/download/"
            "{version}/tigerbeetle-{platform}-{arch}.zip"
        ),
        filename_template="tigerbeetle{ext}",
        description="High-performance accounting ledger engine",
        required=True,
    ),
]


def _get_ext() -> str:
    """Get executable extension for current platform."""
    return ".exe" if _get_platform() == "windows" else ""


def _is_executable(path: Path) -> bool:
    """Check if a file is executable."""
    if not path.exists():
        return False
    if _get_platform() == "windows":
        return path.suffix.lower() in (".exe", ".bat", ".cmd")
    return os.access(path, os.X_OK)


# ── URL building ────────────────────────────────────────────────────────────


def _build_download_url(binary_def: BinaryDefinition) -> str:
    """Build the download URL for a binary based on current platform.

    NATS URL format: nats-server-v{version}-{platform}-{arch}.zip
    TigerBeetle URL format: tigerbeetle-{arch}-{platform}.zip
    """
    plat = _get_platform()
    arch = _get_arch()

    # Map platform names: NATS uses "darwin", TigerBeetle uses "macos"
    plat_map = {"windows": "windows", "linux": "linux", "darwin": "darwin"}
    tb_plat_map = {"windows": "windows", "linux": "linux", "darwin": "macos"}
    tb_arch_map = {"amd64": "x86_64", "arm64": "aarch64"}

    if binary_def.name == "tigerbeetle":
        plat_key = tb_plat_map.get(plat, plat)
        arch_key = tb_arch_map.get(arch, arch)
        # TigerBeetle URL uses arch-platform order
        url = binary_def.url_template.format(
            version=binary_def.version,
            platform=arch_key,
            arch=plat_key,
        )
    else:
        plat_key = plat_map.get(plat, plat)
        arch_key = arch
        url = binary_def.url_template.format(
            version=binary_def.version,
            platform=plat_key,
            arch=arch_key,
        )

    return url


# ── ZIP extraction ───────────────────────────────────────────────────────────


def _extract_binary_from_zip(
    temp_zip: Path,
    binary_def: BinaryDefinition,
    dest_path: Path,
    ext: str,
    *,
    progress_cb: DependencyProgressCallback | None = None,
) -> bool:
    """Extract a binary from a ZIP archive to the destination path.

    Returns True on success, False on failure.
    """
    import zipfile

    try:
        with zipfile.ZipFile(temp_zip, "r") as zf:
            # Find the binary in the archive
            binary_candidates = [
                n
                for n in zf.namelist()
                if binary_def.name in n and (n.endswith(ext) or n.endswith(".exe"))
            ]
            if not binary_candidates:
                # Try to find any executable
                if ext:
                    # On Windows, look for .exe or other extension
                    binary_candidates = [
                        n for n in zf.namelist() if n.endswith(ext) or n.endswith(".exe")
                    ]
                else:
                    # On Linux/macOS, look for files without extension or .exe
                    binary_candidates = [
                        n for n in zf.namelist() if ("." not in Path(n).name) or n.endswith(".exe")
                    ]
            if not binary_candidates:
                logger.error("No binary found in %s archive", binary_def.display_name)
                if progress_cb:
                    progress_cb(
                        current_binary=binary_def.display_name,
                        downloaded_bytes=0,
                        total_bytes=100,
                        speed_bps=0,
                        overall_progress=0,
                        status="error",
                    )
                return False

            # Extract the binary
            binary_in_zip = binary_candidates[0]
            source = zf.read(binary_in_zip)
            dest_path.write_bytes(source)

        # Set executable permissions on non-Windows
        if _get_platform() != "windows":
            st = dest_path.stat()
            dest_path.chmod(st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        return True

    except zipfile.BadZipFile:
        logger.error("Corrupt ZIP file for %s", binary_def.display_name)
        return False


# ── Download and extract ────────────────────────────────────────────────────


async def download_binary(
    binary_def: BinaryDefinition,
    dest_dir: Path,
    *,
    progress_cb: DependencyProgressCallback | None = None,
    cancel_event: anyio.Event | None = None,
    http_client: httpx.AsyncClient | None = None,
) -> Path | None:
    """Download and extract a binary to the destination directory.

    If http_client is provided, it will be used instead of creating a new one.
    This allows tests to inject a controlled mock client.

    Returns path to the extracted binary, or None on failure.
    """
    ext = _get_ext()

    url = _build_download_url(binary_def)

    filename = binary_def.filename_template.format(ext=ext)
    dest_path = dest_dir / filename

    # Check if binary already exists and is executable
    if dest_path.exists() and _is_executable(dest_path):
        logger.info("%s already exists at %s", binary_def.display_name, dest_path)
        if progress_cb:
            progress_cb(
                current_binary=binary_def.display_name,
                downloaded_bytes=100,
                total_bytes=100,
                speed_bps=0,
                overall_progress=0,
                status="done",
            )
        return dest_path

    dest_dir.mkdir(parents=True, exist_ok=True)
    temp_zip = dest_dir / f"{binary_def.name}.zip"

    if progress_cb:
        progress_cb(
            current_binary=binary_def.display_name,
            downloaded_bytes=0,
            total_bytes=100,
            speed_bps=0,
            overall_progress=0,
            status="downloading",
        )

    try:
        # SUPERMOC HTTPX: async with + http2=True + Limits
        _SCOPE = locals()  # For streaming

        async def _do_download(_client: httpx.AsyncClient) -> int | None:
            """Download file and return total_size on success, None on failure."""
            async with _client.stream("GET", url) as response:
                if response.status_code != 200:
                    logger.error(
                        "Failed to download %s: HTTP %d from %s",
                        binary_def.display_name,
                        response.status_code,
                        url,
                    )
                    if progress_cb:
                        progress_cb(
                            current_binary=binary_def.display_name,
                            downloaded_bytes=0,
                            total_bytes=100,
                            speed_bps=0,
                            overall_progress=0,
                            status="error",
                        )
                    return None

                total = int(response.headers.get("content-length", 0))
                downloaded = 0
                import time as _time4

                start_time = _time4.monotonic()

                with open(temp_zip, "wb") as f:
                    async for chunk in response.aiter_bytes(chunk_size=65536):
                        if cancel_event and cancel_event.is_set():
                            temp_zip.unlink(missing_ok=True)
                            return None
                        f.write(chunk)
                        downloaded += len(chunk)
                        if progress_cb:
                            elapsed = _time4.monotonic() - start_time
                            speed = downloaded / elapsed if elapsed > 0 else 0
                            progress_cb(
                                current_binary=binary_def.display_name,
                                downloaded_bytes=downloaded,
                                total_bytes=total,
                                speed_bps=speed,
                                overall_progress=0.3,
                                status="downloading",
                            )
            return total  # return total_size for extraction progress

        if http_client is not None:
            # Injected mock client - użyj bezpośrednio
            total_size = await _do_download(http_client)
        else:
            # SUPERMOC HTTPX: własny klient z HTTP/2, Limits, Timeout
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(connect=15.0, read=120.0, write=30.0, pool=300.0),
                limits=httpx.Limits(max_connections=10, max_keepalive_connections=5, keepalive_expiry=60.0),
                http2=True,
                follow_redirects=True,
                trust_env=True,
            ) as _client:
                total_size = await _do_download(_client)

        if total_size is None:
            return None
        # total_size is now available in outer scope for extraction progress

        # Extract
        if progress_cb:
            progress_cb(
                current_binary=binary_def.display_name,
                downloaded_bytes=total_size,
                total_bytes=total_size,
                speed_bps=0,
                overall_progress=0.5,
                status="extracting",
            )

        extract_ok = _extract_binary_from_zip(
            temp_zip,
            binary_def,
            dest_path,
            ext,
            progress_cb=progress_cb,
        )
        if not extract_ok:
            temp_zip.unlink(missing_ok=True)
            return None

        # Cleanup zip
        temp_zip.unlink(missing_ok=True)

        if progress_cb:
            progress_cb(
                current_binary=binary_def.display_name,
                downloaded_bytes=100,
                total_bytes=100,
                speed_bps=0,
                overall_progress=1.0,
                status="done" if _is_executable(dest_path) else "error",
            )

        logger.info(
            "%s downloaded to %s (%d bytes)",
            binary_def.display_name,
            dest_path,
            dest_path.stat().st_size,
        )
        return dest_path

    except Exception as e:
        logger.error("Failed to download %s: %s", binary_def.display_name, e)
        temp_zip.unlink(missing_ok=True)
        if progress_cb:
            progress_cb(
                current_binary=binary_def.display_name,
                downloaded_bytes=0,
                total_bytes=100,
                speed_bps=0,
                overall_progress=0,
                status="error",
            )
        return None


# ── Binary manager (start/stop processes) ───────────────────────────────────


class BinaryManager:
    """Manages lifecycle of background binary processes."""

    def __init__(self, bin_dir: Path):
        self.bin_dir = bin_dir
        self._processes: dict[str, anyio.Process] = {}
        self._running = False

    def get_path(self, name: str) -> Path:
        """Get path to a managed binary."""
        ext = ".exe" if _get_platform() == "windows" else ""
        return self.bin_dir / f"{name}{ext}"

    def is_installed(self, name: str) -> bool:
        """Check if a binary is installed."""
        path = self.get_path(name)
        return path.exists() and _is_executable(path)

    async def start_nats(self, port: int = 4222) -> bool:
        """Start NATS Server as a background process."""
        nats_path = self.get_path("nats-server")
        if not nats_path.exists():
            logger.error("NATS Server binary not found at %s", nats_path)
            return False

        try:
            proc = await anyio.Process(
                [str(nats_path), "-p", str(port), "-js", "-m", str(port + 1000)],
                stdout=anyio.ProcessPipe.DEVNULL,
                stderr=anyio.ProcessPipe.DEVNULL,
            ).__aenter__()
            self._processes["nats-server"] = proc
            logger.info("NATS Server started (PID: %d, port: %d)", proc.pid, port)
            return True
        except Exception as e:
            logger.error("Failed to start NATS Server: %s", e)
            return False

    async def start_tigerbeetle(self, data_dir: Path, port: int = 3000) -> bool:
        """Start TigerBeetle as a background process."""
        tb_path = self.get_path("tigerbeetle")
        if not tb_path.exists():
            logger.error("TigerBeetle binary not found at %s", tb_path)
            return False

        # TigerBeetle needs to initialize the data file first
        data_file = data_dir / "nexus_ledger.tigerbeetle"
        if not data_file.exists():
            data_dir.mkdir(parents=True, exist_ok=True)
            try:
                # Initialize TigerBeetle data file
                init_result = await anyio.run_process(
                    [str(tb_path), "init", "--cluster=0", str(data_file)],
                    timeout=30,
                )
                if init_result.returncode != 0:
                    logger.error(
                        "TigerBeetle init failed: %s",
                        init_result.stderr.decode() if init_result.stderr else "",
                    )
                    return False
                logger.info("TigerBeetle data file initialized at %s", data_file)
            except Exception as e:
                logger.error("TigerBeetle init error: %s", e)
                return False

        try:
            proc = await anyio.Process(
                [str(tb_path), "start", "--addresses=0.0.0.0:" + str(port), str(data_file)],
                stdout=anyio.ProcessPipe.DEVNULL,
                stderr=anyio.ProcessPipe.DEVNULL,
            ).__aenter__()
            self._processes["tigerbeetle"] = proc
            logger.info("TigerBeetle started (PID: %d, port: %d)", proc.pid, port)
            return True
        except Exception as e:
            logger.error("Failed to start TigerBeetle: %s", e)
            return False

    async def start_all(self, data_dir: Path | None = None) -> dict[str, bool]:
        """Start all managed binaries."""
        results = {}
        results["nats-server"] = await self.start_nats()
        if data_dir:
            results["tigerbeetle"] = await self.start_tigerbeetle(data_dir)
        self._running = all(results.values())
        return results

    def stop_all(self) -> None:
        """Stop all managed processes."""
        for name, proc in self._processes.items():
            if proc and proc.returncode is None:
                logger.info("Stopping %s (PID: %d)...", name, proc.pid)
                proc.terminate()
        self._processes.clear()
        self._running = False

    async def stop_all_async(self) -> None:
        """Stop all managed processes with timeout and force-kill fallback."""
        for name, proc in self._processes.items():
            if proc and proc.returncode is None:
                logger.info("Stopping %s (PID: %d)...", name, proc.pid)
                proc.terminate()
                try:
                    with anyio.fail_after(5.0):
                        await proc.wait()
                except TimeoutError:
                    logger.warning("Force killing %s (PID: %d)", name, proc.pid)
                    proc.kill()
                    await proc.wait()
        self._processes.clear()
        self._running = False

    def is_running(self) -> bool:
        """Check if all managed processes are running."""
        if not self._processes:
            return False
        return all(p.returncode is None for p in self._processes.values() if p is not None)


# ── Check if dependencies need to be downloaded ─────────────────────────────


def check_dependencies(bin_dir: Path) -> dict:
    """Check which system dependencies are installed.

    Returns:
        dict with keys: all_installed, missing (list), bin_dir
    """
    manager = BinaryManager(bin_dir)
    missing = []

    for binary_def in BINARY_MANIFEST:
        if not manager.is_installed(binary_def.name):
            missing.append(binary_def)

    return {
        "all_installed": len(missing) == 0,
        "missing": missing,
        "bin_dir": bin_dir,
    }


# ── Main orchestrator ───────────────────────────────────────────────────────


async def download_all_dependencies(
    bin_dir: Path,
    *,
    progress_cb: DependencyProgressCallback | None = None,
    cancel_event: anyio.Event | None = None,
) -> list[tuple[str, bool]]:
    """Download all missing system dependencies.

    Returns list of (binary_name, success) tuples.
    """
    results: list[tuple[str, bool]] = []
    total = len(BINARY_MANIFEST)

    for i, binary_def in enumerate(BINARY_MANIFEST):
        if cancel_event and cancel_event.is_set():
            break

        overall_start = i / max(total, 1)

        if progress_cb:
            progress_cb(
                current_binary=binary_def.display_name,
                downloaded_bytes=0,
                total_bytes=100,
                speed_bps=0,
                overall_progress=overall_start,
                status="downloading",
            )

        result = await download_binary(
            binary_def,
            bin_dir,
            progress_cb=progress_cb,
            cancel_event=cancel_event,
        )
        success = result is not None
        results.append((binary_def.name, success))

        if progress_cb:
            overall_end = (i + 1) / max(total, 1)
            progress_cb(
                current_binary=binary_def.display_name,
                downloaded_bytes=100,
                total_bytes=100,
                speed_bps=0,
                overall_progress=overall_end,
                status="done" if success else "error",
            )

    return results
