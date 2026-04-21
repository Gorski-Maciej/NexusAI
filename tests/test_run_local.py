from __future__ import annotations

import sys
import types
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

import run_local


def test_parser_supports_bootstrap_flag() -> None:
    args = run_local._build_parser().parse_args(["--bootstrap", "--host", "0.0.0.0", "--port", "9000"])
    assert args.bootstrap is True
    assert args.host == "0.0.0.0"
    assert args.port == "9000"


def test_main_returns_error_without_bootstrap_when_missing_dependencies(monkeypatch) -> None:
    monkeypatch.setattr(run_local, "_check_dependencies", lambda: ["uvicorn"])
    code = run_local.main([])
    assert code == 1


def test_main_bootstrap_path_installs_dependencies(monkeypatch) -> None:
    calls: list[str] = []

    def fake_check_dependencies() -> list[str]:
        calls.append("check")
        return ["uvicorn"] if len(calls) == 1 else []

    monkeypatch.setattr(run_local, "_check_dependencies", fake_check_dependencies)
    monkeypatch.setattr(run_local, "_install_dependencies", lambda: 0)

    fake_server = types.ModuleType("api.server")
    fake_server.run_backend = lambda: calls.append("run")
    monkeypatch.setitem(sys.modules, "api.server", fake_server)

    code = run_local.main(["--bootstrap"])

    assert code == 0
    assert calls == ["check", "check", "run"]
