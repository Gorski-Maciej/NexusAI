"""
Tests that all 3 CLI entry points can be imported without errors.

These are quick smoke tests — they verify the import chain works,
not the actual command execution.
"""
import pytest
import sys
from pathlib import Path


@pytest.fixture(autouse=True)
def setup_paths():
    """Ensure Code/ is on sys.path for import resolution."""
    code_dir = str(Path(__file__).resolve().parent.parent / "Code")
    if code_dir not in sys.path:
        sys.path.insert(0, code_dir)
    yield


class TestNexusEntryPoint:
    """Entry point: nexus = main:main"""

    def test_nexus_help(self):
        """nexus --help should display usage without errors."""
        import main as nexus_main
        # --help uses argparse which calls sys.exit(0), so we catch SystemExit
        with pytest.raises(SystemExit) as exc:
            nexus_main.main(["--help"])
        assert exc.value.code == 0

    def test_nexus_invalid_mode(self):
        """nexus should reject an invalid mode with SystemExit(2)."""
        import main as nexus_main
        with pytest.raises(SystemExit) as exc:
            nexus_main.main(["--mode=invalid_mode_xyz"])
        assert exc.value.code == 2


class TestNexusApiEntryPoint:
    """Entry point: nexus-api = api.server:run_backend"""

    def test_api_server_import(self):
        """api.server should import and create a Litestar app."""
        from api.server import app
        assert app is not None
        # Litestar apps have a 'debug' attribute
        assert hasattr(app, "debug")


class TestNexusWorkerEntryPoint:
    """Entry point: nexus-worker = luz.worker:main"""

    def test_worker_main_import(self):
        """luz.worker should import and expose a callable main."""
        from luz.worker import main
        assert callable(main)
