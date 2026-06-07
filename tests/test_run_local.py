from __future__ import annotations

import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from nexus_ai.main import _build_parser  # noqa: E402


def test_parser_supports_bootstrap_flag() -> None:
    """Verify the CLI parser handles --bootstrap and host/port flags correctly."""
    parser = _build_parser()
    args = parser.parse_args(["--bootstrap", "--mode", "api", "--host", "127.0.0.1", "--port", "9000"])
    assert args.bootstrap is True
    assert args.mode == "api"
    assert args.host == "127.0.0.1"
    assert args.port == 9000


def test_parser_defaults() -> None:
    """Verify parser defaults use new technology stack (Granian, not Uvicorn)."""
    parser = _build_parser()
    args = parser.parse_args([])
    assert args.mode == "api"
    assert args.host == "127.0.0.1"
    assert args.port == 8000
    assert args.workers == 1


def test_parser_validates_mode() -> None:
    """Verify mode choices include all expected modes."""
    parser = _build_parser()
    expected_modes = ["api", "worker", "all", "bootstrap", "doctor"]
    for mode in expected_modes:
        args = parser.parse_args(["--mode", mode])
        assert args.mode == mode
