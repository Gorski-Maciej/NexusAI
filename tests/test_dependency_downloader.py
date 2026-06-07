"""
Tests for Code/installer/dependency_downloader.py

Covers:
  - Platform detection (Linux, Windows, macOS, unknown)
  - Architecture detection (amd64, arm64, 386, fallback)
  - _is_executable helper
  - URL generation for NATS and TigerBeetle on all platforms
  - ZIP extraction (_extract_binary_from_zip) with success, no binary, corrupt ZIP
  - download_binary already-exists skip path
  - BinaryManager (paths, is_installed, start_nats, start_tigerbeetle)
  - check_dependencies orchestrator
  - download_all_dependencies orchestrator (with mocked download_binary)
"""

from __future__ import annotations

import asyncio
import io
import stat
import zipfile
from pathlib import Path
import httpx
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from nexus_ai.installer.dependency_downloader import (
    BINARY_MANIFEST,
    BinaryDefinition,
    BinaryManager,
    DependencyProgressCallback,
    _build_download_url,
    _extract_binary_from_zip,
    _get_arch,
    _get_ext,
    _get_platform,
    _is_executable,
    check_dependencies,
    download_all_dependencies,
    download_binary,
)


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def temp_dir(tmp_path: Path) -> Path:
    """Temporary directory for test artifacts."""
    return tmp_path / "nexus_test_bin"


@pytest.fixture
def nats_def() -> BinaryDefinition:
    """NATS Server binary definition."""
    for b in BINARY_MANIFEST:
        if b.name == "nats-server":
            return b
    raise AssertionError("nats-server not in BINARY_MANIFEST")


@pytest.fixture
def tb_def() -> BinaryDefinition:
    """TigerBeetle binary definition."""
    for b in BINARY_MANIFEST:
        if b.name == "tigerbeetle":
            return b
    raise AssertionError("tigerbeetle not in BINARY_MANIFEST")


@pytest.fixture
def cancel_event() -> asyncio.Event:
    """Fresh cancel event (not set)."""
    return asyncio.Event()


def make_progress_cb(tracker: dict) -> DependencyProgressCallback:
    """Create a progress callback that records calls."""
    def cb(*, current_binary, downloaded_bytes, total_bytes,
           speed_bps, overall_progress, status):
        tracker["calls"].append({
            "binary": current_binary,
            "downloaded": downloaded_bytes,
            "total": total_bytes,
            "speed": speed_bps,
            "progress": overall_progress,
            "status": status,
        })
        if status == "done":
            tracker["done"] = True
    return cb


@pytest.fixture
def in_memory_zip() -> bytes:
    """Create a valid ZIP file containing a fake binary."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("nats-server.exe", b"fake nats binary content")
        zf.writestr("README.txt", b"some docs")
    return buf.getvalue()


@pytest.fixture
def no_binary_zip() -> bytes:
    """Create a valid ZIP file without any executable."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("docs/readme.txt", b"no binary here")
    return buf.getvalue()


# =============================================================================
# Platform detection
# =============================================================================

class TestGetPlatform:
    """_get_platform() should detect the correct OS key."""

    def test_windows(self):
        with patch("platform.system", return_value="Windows"):
            assert _get_platform() == "windows"

    def test_linux(self):
        with patch("platform.system", return_value="Linux"):
            assert _get_platform() == "linux"

    def test_macos(self):
        with patch("platform.system", return_value="Darwin"):
            assert _get_platform() == "darwin"

    def test_unknown(self):
        with patch("platform.system", return_value="FreeBSD"):
            assert _get_platform() == "freebsd"


class TestGetArch:
    """_get_arch() should detect CPU architecture."""

    def test_amd64(self):
        for m in ("AMD64", "x86_64", "x64"):
            with patch("platform.machine", return_value=m):
                assert _get_arch() == "amd64", f"Failed for {m}"

    def test_arm64(self):
        for m in ("arm64", "aarch64"):
            with patch("platform.machine", return_value=m):
                assert _get_arch() == "arm64", f"Failed for {m}"

    def test_386(self):
        for m in ("i386", "i686", "x86"):
            with patch("platform.machine", return_value=m):
                assert _get_arch() == "386", f"Failed for {m}"

    def test_fallback_to_amd64(self):
        with patch("platform.machine", return_value="some_weird_cpu"):
            assert _get_arch() == "amd64"


# =============================================================================
# _get_ext helper
# =============================================================================

class TestGetExt:
    def test_windows_exe(self):
        with patch("installer.dependency_downloader._get_platform", return_value="windows"):
            assert _get_ext() == ".exe"

    def test_linux_no_ext(self):
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            assert _get_ext() == ""

    def test_macos_no_ext(self):
        with patch("installer.dependency_downloader._get_platform", return_value="darwin"):
            assert _get_ext() == ""


# =============================================================================
# _is_executable
# =============================================================================

class TestIsExecutable:
    def test_not_exists(self, temp_dir):
        assert _is_executable(temp_dir / "nonexistent.exe") is False

    def test_windows_exe_ext(self, temp_dir):
        exe = temp_dir / "test.exe"
        temp_dir.mkdir(parents=True, exist_ok=True)
        exe.write_bytes(b"fake")
        with patch("installer.dependency_downloader._get_platform", return_value="windows"):
            assert _is_executable(exe) is True

    def test_windows_no_exe_ext(self, temp_dir):
        txt = temp_dir / "test.txt"
        temp_dir.mkdir(parents=True, exist_ok=True)
        txt.write_bytes(b"fake")
        with patch("installer.dependency_downloader._get_platform", return_value="windows"):
            assert _is_executable(txt) is False

    def test_linux_executable(self, temp_dir):
        exe = temp_dir / "test"
        temp_dir.mkdir(parents=True, exist_ok=True)
        exe.write_bytes(b"fake")
        exe.chmod(exe.stat().st_mode | stat.S_IXUSR)
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            assert _is_executable(exe) is True

    def test_linux_not_executable(self, temp_dir):
        exe = temp_dir / "test"
        temp_dir.mkdir(parents=True, exist_ok=True)
        exe.write_bytes(b"fake")
        exe.chmod(0o644)
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            assert _is_executable(exe) is False


# =============================================================================
# URL generation (via _build_download_url — no HTTP needed)
# =============================================================================

class TestURLGeneration:
    """Verify correct URL templates for NATS and TigerBeetle."""

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    def test_nats_url_linux_amd64(self, mock_arch, mock_plat, nats_def):
        """NATS URL on Linux/amd64."""
        url = _build_download_url(nats_def)
        assert "nats-server-v2.10.22-linux-amd64.zip" in url
        assert url.startswith("https://github.com/nats-io/nats-server/releases/download/")

    @patch("installer.dependency_downloader._get_platform", return_value="darwin")
    @patch("installer.dependency_downloader._get_arch", return_value="arm64")
    def test_nats_url_macos_arm64(self, mock_arch, mock_plat, nats_def):
        """NATS URL on macOS/arm64 — uses 'darwin' platform key."""
        url = _build_download_url(nats_def)
        assert "nats-server-v2.10.22-darwin-arm64.zip" in url

    @patch("installer.dependency_downloader._get_platform", return_value="windows")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    def test_nats_url_windows_amd64(self, mock_arch, mock_plat, nats_def):
        """NATS URL on Windows/amd64."""
        url = _build_download_url(nats_def)
        assert "nats-server-v2.10.22-windows-amd64.zip" in url

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    def test_tigerbeetle_url_linux_amd64(self, mock_arch, mock_plat, tb_def):
        """TigerBeetle URL on Linux/amd64 — arch-platform order: x86_64-linux."""
        url = _build_download_url(tb_def)
        assert "tigerbeetle-x86_64-linux.zip" in url
        assert "0.16.16" in url  # version is in the path, not filename

    @patch("installer.dependency_downloader._get_platform", return_value="darwin")
    @patch("installer.dependency_downloader._get_arch", return_value="arm64")
    def test_tigerbeetle_url_macos_arm64(self, mock_arch, mock_plat, tb_def):
        """TigerBeetle URL on macOS/arm64 — uses 'macos' (not darwin), 'aarch64'."""
        url = _build_download_url(tb_def)
        assert "tigerbeetle-aarch64-macos.zip" in url


# =============================================================================
# ZIP extraction (_extract_binary_from_zip)
# =============================================================================

class TestExtractBinaryFromZip:
    """Test the standalone ZIP extraction function."""

    def test_successful_extraction(self, temp_dir, nats_def, in_memory_zip):
        """Extract binary from valid ZIP."""
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_zip = temp_dir / "nats-server.zip"
        temp_zip.write_bytes(in_memory_zip)

        ext = ""
        dest_path = temp_dir / "nats-server"

        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            result = _extract_binary_from_zip(temp_zip, nats_def, dest_path, ext)

        assert result is True
        assert dest_path.exists()
        assert dest_path.read_bytes() == b"fake nats binary content"

    def test_no_binary_in_zip(self, temp_dir, nats_def, no_binary_zip):
        """ZIP with no matching binary returns False."""
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_zip = temp_dir / "nats-server.zip"
        temp_zip.write_bytes(no_binary_zip)

        ext = ""
        dest_path = temp_dir / "nats-server"

        result = _extract_binary_from_zip(temp_zip, nats_def, dest_path, ext)
        assert result is False
        assert not dest_path.exists()

    def test_corrupt_zip(self, temp_dir, nats_def):
        """Corrupt ZIP file returns False."""
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_zip = temp_dir / "nats-server.zip"
        temp_zip.write_bytes(b"not a zip file at all")

        ext = ""
        dest_path = temp_dir / "nats-server"

        result = _extract_binary_from_zip(temp_zip, nats_def, dest_path, ext)
        assert result is False

    def test_windows_exe_extraction(self, temp_dir, nats_def, in_memory_zip):
        """Extract on Windows uses .exe extension."""
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_zip = temp_dir / "nats-server.zip"
        temp_zip.write_bytes(in_memory_zip)

        ext = ".exe"
        dest_path = temp_dir / "nats-server.exe"

        with patch("installer.dependency_downloader._get_platform", return_value="windows"):
            result = _extract_binary_from_zip(temp_zip, nats_def, dest_path, ext)

        assert result is True
        assert dest_path.exists()
        assert dest_path.suffix == ".exe"
        assert dest_path.read_bytes() == b"fake nats binary content"


# =============================================================================
# download_binary — already-exists skip path
# =============================================================================

class TestDownloadBinaryAlreadyExists:
    """When binary already exists, download_binary should skip HTTP."""

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_skip_if_exists_and_executable(
        self, mock_arch, mock_plat, nats_def, temp_dir,
    ):
        """If binary already exists and is executable, return it immediately."""
        temp_dir.mkdir(parents=True, exist_ok=True)
        existing = temp_dir / "nats-server"
        existing.write_bytes(b"existing binary")
        existing.chmod(existing.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        with patch("httpx.AsyncClient") as mock_http:
            result = await download_binary(nats_def, temp_dir)

        assert result == existing
        mock_http.assert_not_called()


# =============================================================================
# download_binary — HTTP mocking via injected http_client
# =============================================================================

def _make_mock_client(
    status_code: int = 200,
    content: bytes = b"",
    *,
    side_effect: Exception | None = None,
) -> MagicMock:
    """Create a mock httpx.AsyncClient with controlled streaming response.

    Note: spec is intentionally omitted because conftest.py mocks httpx
    as a _MockModule, making spec=httpx.AsyncClient fail with InvalidSpecError.
    """
    # Create a real async generator for aiter_bytes
    async def _iter_bytes(*args, **kwargs):
        yield content

    mock_response = AsyncMock()
    mock_response.status_code = status_code
    mock_response.headers = {"content-length": str(len(content))}
    mock_response.aiter_bytes = _iter_bytes

    mock_stream = AsyncMock()
    mock_stream.__aenter__.return_value = mock_response

    mock_client = MagicMock()
    if side_effect:
        mock_client.stream.side_effect = side_effect
    else:
        mock_client.stream.return_value = mock_stream

    return mock_client


class TestDownloadBinaryHttpMocking:
    """HTTP mocking tests: inject a controlled http_client to simulate scenarios."""

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_http_404_returns_none(
        self, mock_arch, mock_plat, nats_def, temp_dir,
    ):
        """HTTP 404 should return None with error progress callback."""
        mock_client = _make_mock_client(status_code=404)
        result = await download_binary(
            nats_def, temp_dir, http_client=mock_client,
        )
        assert result is None
        mock_client.stream.assert_called_once()

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_http_404_fires_error_callback(
        self, mock_arch, mock_plat, nats_def, temp_dir,
    ):
        """Progress callback should report 'error' on HTTP 404."""
        tracker: dict = {"calls": []}
        cb = make_progress_cb(tracker)

        mock_client = _make_mock_client(status_code=404)
        await download_binary(
            nats_def, temp_dir, progress_cb=cb, http_client=mock_client,
        )

        assert tracker["calls"]
        assert tracker["calls"][-1]["status"] == "error"

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_http_exception_returns_none(
        self, mock_arch, mock_plat, nats_def, temp_dir,
    ):
        """Exception during HTTP should return None."""
        mock_client = _make_mock_client(
            side_effect=httpx.ConnectError("Connection refused")
        )
        result = await download_binary(
            nats_def, temp_dir, http_client=mock_client,
        )
        assert result is None

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_full_download_flow_with_progress(
        self, mock_arch, mock_plat, nats_def, temp_dir, in_memory_zip,
    ):
        """Full flow: HTTP 200 → ZIP download → extraction → ready."""
        mock_client = _make_mock_client(status_code=200, content=in_memory_zip)

        result = await download_binary(
            nats_def, temp_dir, http_client=mock_client,
        )

        assert result is not None
        assert result.name == "nats-server"
        assert result.exists()
        assert result.read_bytes() == b"fake nats binary content"

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_full_flow_progress_callbacks(
        self, mock_arch, mock_plat, nats_def, temp_dir, in_memory_zip,
    ):
        """Progress callbacks fire: downloading → extracting → done."""
        tracker: dict = {"calls": []}
        cb = make_progress_cb(tracker)

        mock_client = _make_mock_client(status_code=200, content=in_memory_zip)
        await download_binary(
            nats_def, temp_dir, progress_cb=cb, http_client=mock_client,
        )

        statuses = [c["status"] for c in tracker["calls"]]
        assert "downloading" in statuses
        assert "extracting" in statuses
        assert "done" in statuses
        assert statuses[-1] == "done"
        assert tracker["calls"][-1]["progress"] == 1.0

    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_cancel_mid_download(
        self, mock_arch, mock_plat, nats_def, temp_dir,
    ):
        """Cancel event set during streaming should abort."""
        cancel = asyncio.Event()

        # Create a response that yields slowly so cancel can take effect
        async def slow_chunks():
            for i in range(5):
                await asyncio.sleep(0.02)
                if cancel.is_set():
                    return
                yield f"chunk{i}".encode()

        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.headers = {"content-length": "100"}
        mock_response.aiter_bytes = slow_chunks

        mock_stream = AsyncMock()
        mock_stream.__aenter__.return_value = mock_response

        mock_client = MagicMock()  # No spec — conftest mocks httpx
        mock_client.stream.return_value = mock_stream

        async def do_cancel():
            await asyncio.sleep(0.03)
            cancel.set()

        result, _ = await asyncio.gather(
            download_binary(nats_def, temp_dir, cancel_event=cancel, http_client=mock_client),
            do_cancel(),
            return_exceptions=True,
        )
        assert result is None


# =============================================================================
# BinaryManager
# =============================================================================

class TestBinaryManager:
    """BinaryManager lifecycle tests."""

    def test_get_path(self, temp_dir):
        mgr = BinaryManager(temp_dir)
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            path = mgr.get_path("nats-server")
            assert path == temp_dir / "nats-server"

    def test_get_path_windows(self, temp_dir):
        mgr = BinaryManager(temp_dir)
        with patch("installer.dependency_downloader._get_platform", return_value="windows"):
            path = mgr.get_path("nats-server")
            assert path == temp_dir / "nats-server.exe"

    def test_is_installed_false(self, temp_dir):
        mgr = BinaryManager(temp_dir)
        assert mgr.is_installed("nats-server") is False

    def test_is_installed_true(self, temp_dir):
        temp_dir.mkdir(parents=True, exist_ok=True)
        (temp_dir / "nats-server").write_bytes(b"fake")
        (temp_dir / "nats-server").chmod(
            (temp_dir / "nats-server").stat().st_mode | stat.S_IXUSR
        )
        mgr = BinaryManager(temp_dir)
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            assert mgr.is_installed("nats-server") is True

    def test_start_nats_binary_not_found(self, temp_dir):
        """start_nats returns False if binary doesn't exist."""
        mgr = BinaryManager(temp_dir)
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            result = mgr.start_nats()
            assert result is False

    def test_start_tigerbeetle_binary_not_found(self, temp_dir):
        """start_tigerbeetle returns False if binary doesn't exist."""
        mgr = BinaryManager(temp_dir)
        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            result = mgr.start_tigerbeetle(temp_dir)
            assert result is False

    def test_stop_all_empty(self, temp_dir):
        """stop_all with no processes should not raise."""
        mgr = BinaryManager(temp_dir)
        mgr.stop_all()
        assert mgr.is_running() is False


# =============================================================================
# check_dependencies
# =============================================================================

class TestCheckDependencies:
    """check_dependencies orchestrator."""

    def test_all_missing(self, temp_dir):
        """With empty bin_dir, all deps should be missing."""
        result = check_dependencies(temp_dir)
        assert result["all_installed"] is False
        assert len(result["missing"]) == 2
        assert result["bin_dir"] == temp_dir

    def test_all_installed(self, temp_dir):
        """With binaries present, all_installed should be True."""
        temp_dir.mkdir(parents=True, exist_ok=True)
        for name in ("nats-server", "tigerbeetle"):
            path = temp_dir / name
            path.write_bytes(b"fake")
            path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        with patch("installer.dependency_downloader._get_platform", return_value="linux"):
            result = check_dependencies(temp_dir)
        assert result["all_installed"] is True
        assert len(result["missing"]) == 0


# =============================================================================
# download_all_dependencies orchestrator
# =============================================================================

class TestDownloadAllDependencies:
    """download_all_dependencies orchestrator (download_binary is mocked)."""

    @patch("installer.dependency_downloader.download_binary", new_callable=AsyncMock)
    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_downloads_all(
        self, mock_arch, mock_plat, mock_download, temp_dir,
    ):
        """download_all_dependencies should download each binary in manifest."""
        mock_download.side_effect = [
            temp_dir / "nats-server",
            temp_dir / "tigerbeetle",
        ]

        results = await download_all_dependencies(temp_dir)
        assert len(results) == 2
        assert all(success for _, success in results)
        assert mock_download.call_count == 2

    @patch("installer.dependency_downloader.download_binary", new_callable=AsyncMock)
    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_download_all_progress(
        self, mock_arch, mock_plat, mock_download, temp_dir,
    ):
        """download_all_dependencies should fire progress callbacks."""
        tracker: dict = {"calls": []}
        cb = make_progress_cb(tracker)

        mock_download.side_effect = [
            temp_dir / "nats-server",
            temp_dir / "tigerbeetle",
        ]

        await download_all_dependencies(temp_dir, progress_cb=cb)

        binaries_seen = {c["binary"] for c in tracker["calls"]}
        assert "NATS Server" in binaries_seen
        assert "TigerBeetle" in binaries_seen

    @patch("installer.dependency_downloader.download_binary", new_callable=AsyncMock)
    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_second_binary_fails(
        self, mock_arch, mock_plat, mock_download, temp_dir,
    ):
        """When one binary fails, results should reflect partial success."""
        mock_download.side_effect = [
            temp_dir / "nats-server",
            None,
        ]

        results = await download_all_dependencies(temp_dir)
        assert results[0] == ("nats-server", True)
        assert results[1] == ("tigerbeetle", False)

    @patch("installer.dependency_downloader.download_binary", new_callable=AsyncMock)
    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_cancel_aborts_remaining(
        self, mock_arch, mock_plat, mock_download, temp_dir,
    ):
        """Setting cancel event should skip remaining downloads."""
        cancel = asyncio.Event()

        # Simulate a slow first download to let cancel event propagate
        async def slow_download(*args, **kwargs):
            await asyncio.sleep(0.05)
            if cancel.is_set():
                return None
            return temp_dir / "nats-server"

        mock_download.side_effect = slow_download

        async def do_cancel():
            await asyncio.sleep(0.01)
            cancel.set()

        results_coro = download_all_dependencies(temp_dir, cancel_event=cancel)
        _, results = await asyncio.gather(do_cancel(), results_coro)

        # After cancel, only the first binary should have been attempted
        assert len(results) == 1
        assert mock_download.call_count == 1

    @patch("installer.dependency_downloader.download_binary", new_callable=AsyncMock)
    @patch("installer.dependency_downloader._get_platform", return_value="linux")
    @patch("installer.dependency_downloader._get_arch", return_value="amd64")
    async def test_progress_callback_cancelled(
        self, mock_arch, mock_plat, mock_download, temp_dir,
    ):
        """Cancelled operation should not produce 'done' callbacks."""
        cancel = asyncio.Event()
        tracker: dict = {"calls": []}
        cb = make_progress_cb(tracker)

        mock_download.side_effect = [temp_dir / "nats-server"]
        cancel.set()

        await download_all_dependencies(temp_dir, progress_cb=cb, cancel_event=cancel)

        assert not tracker["calls"]
