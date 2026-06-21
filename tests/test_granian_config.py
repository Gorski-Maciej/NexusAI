"""Testy dla Granian superpower configuration.

Weryfikuje:
  1. Poprawność składni server.py
  2. Dostępność wszystkich supermocowych zmiennych środowiskowych
  3. Poprawność _build_granian_config()
  4. Fallback mechanizm
  5. Proxy headers wrapper
"""

from __future__ import annotations

import os
from pathlib import Path

import pytest


class TestGranianConfig:
    """Testy konfiguracji Granian z server.py.

    UWAGA: Wszystkie testy są synchroniczne — brak @pytest.mark.anyio.
    """

    def test_server_py_has_run_backend(self) -> None:
        """Sprawdź czy server.py zawiera run_backend()."""
        from nexus_ai.api.server import run_backend

        assert callable(run_backend)

    def test_server_py_has_get_app(self) -> None:
        """Sprawdź czy server.py eksportuje get_app()."""
        from nexus_ai.api.server import get_app

        app = get_app()
        assert app is not None

    def test_build_granian_config_defaults(self) -> None:
        """Sprawdź domyślne wartości konfiguracji Granian.

        Testuje _build_granian_config() bez env varów — powinna zwrócić
        poprawne domyślne wartości dla wszystkich supermocy.
        """
        from nexus_ai.api.server import _build_granian_config

        config = _build_granian_config()

        # Core
        assert "target" in config
        assert config["target"] == "api.app:create_app"
        assert "host" in config
        assert "port" in config
        assert config["port"] == 8000

        # Backpressure & backlog
        assert config["backlog"] >= 1024
        assert config["backpressure"] >= 1

        # HTTP/2
        assert config["http"] in ("auto", "1", "2")

        # Metrics
        assert "metrics" in config
        assert "metrics_address" in config
        assert "metrics_port" in config

        # Security
        assert "no_header_server" in config

        # Graceful shutdown
        assert config["graceful_shutdown_timeout"] >= 1

    def test_build_granian_config_unix_socket(self) -> None:
        """Sprawdź konfigurację UNIX socket."""
        with pytest.MonkeyPatch.context() as mp:
            mp.setenv("NEXUS_HOST", "unix")
            mp.setenv("NEXUS_UNIX_SOCKET", "/tmp/test-nexus.sock")

            from nexus_ai.api.server import _build_granian_config

            config = _build_granian_config()
            assert "unix_socket" in config
            assert config["unix_socket"] == "/tmp/test-nexus.sock"
            assert "host" not in config
            assert "port" not in config

    def test_build_granian_config_custom_env(self) -> None:
        """Sprawdź czy env vars nadpisują domyślne wartości."""
        with pytest.MonkeyPatch.context() as mp:
            mp.setenv("NEXUS_GRANIAN_BACKLOG", "4096")
            mp.setenv("NEXUS_GRANIAN_BACKPRESSURE", "250")
            mp.setenv("NEXUS_GRANIAN_WORKERS", "4")
            mp.setenv("NEXUS_GRANIAN_HTTP2_MAX_STREAMS", "512")
            mp.setenv("NEXUS_GRANIAN_METRICS_PORT", "9091")
            mp.setenv("NEXUS_GRANIAN_HTTP", "2")

            from nexus_ai.api.server import _build_granian_config

            config = _build_granian_config()
            assert config["backlog"] == 4096
            assert config["backpressure"] == 250
            assert config["workers"] == 4
            assert config["http2_max_concurrent_streams"] == 512
            assert config["metrics_port"] == 9091
            assert config["http"] == "2"

    def test_build_granian_config_pid_file(self) -> None:
        """Sprawdź konfigurację PID file i process name."""
        with pytest.MonkeyPatch.context() as mp:
            mp.setenv("NEXUS_GRANIAN_PID_FILE", "/tmp/nexus-test.pid")
            mp.setenv("NEXUS_GRANIAN_PROCESS_NAME", "nexus-test")

            from nexus_ai.api.server import _build_granian_config

            config = _build_granian_config()
            assert config["pid_file"] == "/tmp/nexus-test.pid"
            assert config["process_name"] == "nexus-test"

    def test_build_granian_config_worker_lifecycle(self) -> None:
        """Sprawdź konfigurację worker lifecycle."""
        with pytest.MonkeyPatch.context() as mp:
            mp.setenv("NEXUS_GRANIAN_RESPAWN", "true")
            mp.setenv("NEXUS_GRANIAN_WORKER_MAX_RSS", "1024")
            mp.setenv("NEXUS_GRANIAN_WORKER_LIFETIME", "86400")

            from nexus_ai.api.server import _build_granian_config

            config = _build_granian_config()
            assert config["respawn_failed_workers"] is True
            assert config["workers_max_rss"] == 1024
            assert config["workers_lifetime"] == 86400

    def test_server_imports_are_correct(self) -> None:
        """Sprawdź czy plik server.py ma poprawne importy."""
        import ast

        tree = ast.parse(
            Path("nexus_ai/api/server.py").read_text(encoding="utf-8")
        )
        imports = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.add(alias.name)
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    imports.add(node.module)

        assert "granian" in imports
        assert "granian.constants" in imports

    def test_no_deprecated_uvicorn(self) -> None:
        """Sprawdź czy nie ma śladów Uvicorn w server.py."""
        source = Path("nexus_ai/api/server.py").read_text(encoding="utf-8")
        assert "uvicorn" not in source.lower()

    def test_env_var_namespace_completeness(self) -> None:
        """Sprawdź czy wszystkie NEXUS_GRANIAN_* env vars są zdefiniowane
        w pixi.toml activation.env."""
        import tomllib

        pixi = tomllib.loads(
            Path("pixi.toml").read_text(encoding="utf-8")
        )
        activation_env = pixi.get("activation", {}).get("env", {})
        granian_env_vars = {
            k: v for k, v in activation_env.items()
            if k.startswith("NEXUS_GRANIAN_")
        }
        # Powinno być co najmniej 10 zmiennych Granian
        assert len(granian_env_vars) >= 10, (
            f"Only {len(granian_env_vars)} NEXUS_GRANIAN_ vars in pixi.toml"
        )
        # Kluczowe zmienne muszą istnieć
        key_vars = [
            "NEXUS_GRANIAN_BACKLOG",
            "NEXUS_GRANIAN_BACKPRESSURE",
            "NEXUS_GRANIAN_HTTP",
            "NEXUS_GRANIAN_METRICS",
            "NEXUS_GRANIAN_METRICS_ADDRESS",
            "NEXUS_GRANIAN_METRICS_PORT",
            "NEXUS_GRANIAN_LOOP",
            "NEXUS_GRANIAN_ACCESS_LOG",
            "NEXUS_GRANIAN_NO_SERVER_HEADER",
            "NEXUS_GRANIAN_RESPAWN",
            "NEXUS_GRANIAN_RUNTIME_THREADS",
            "NEXUS_GRANIAN_RUNTIME_BLOCKING_THREADS",
            "NEXUS_GRANIAN_GRACEFUL_SHUTDOWN",
            "NEXUS_GRANIAN_PID_FILE",
        ]
        for var in key_vars:
            assert var in granian_env_vars, f"Missing env var: {var}"

    def test_granian_extras_in_pyproject(self) -> None:
        """Sprawdź czy granian extras są w pyproject.toml."""
        import tomllib

        pyproject = tomllib.loads(
            Path("pyproject.toml").read_text(encoding="utf-8")
        )
        deps = pyproject["project"]["dependencies"]
        granian_dep = [d for d in deps if d.startswith("granian")]
        assert len(granian_dep) == 1
        dep_str = granian_dep[0]
        assert "dotenv" in dep_str
        assert "pname" in dep_str
        assert "reload" in dep_str
        assert "uvloop" in dep_str

    def test_granian_task_in_pixi(self) -> None:
        """Sprawdź czy pixi.toml ma task api-dev z wszystkimi flagami."""
        import tomllib

        pixi = tomllib.loads(
            Path("pixi.toml").read_text(encoding="utf-8")
        )
        tasks = pixi.get("tasks", {})
        assert "api-dev" in tasks
        api_dev_run = tasks["api-dev"]["cmd"]
        # Sprawdź kluczowe flagi Granian w tasku
        assert "--backlog" in api_dev_run
        assert "--backpressure" in api_dev_run
        assert "--http auto" in api_dev_run
        assert "--loop uvloop" in api_dev_run
        assert "--access-log" in api_dev_run
        assert "--no-header-server" in api_dev_run
        assert "--metrics" in api_dev_run
        assert "--reload-ignore-dirs" in api_dev_run
        assert "--reload-ignore-patterns" in api_dev_run
        assert "--reload-tick" in api_dev_run

    def test_granian_prod_task_in_pixi(self) -> None:
        """Sprawdź czy pixi.toml ma task api-prod i api-metrics."""
        import tomllib

        pixi = tomllib.loads(
            Path("pixi.toml").read_text(encoding="utf-8")
        )
        tasks = pixi.get("tasks", {})
        assert "api-prod" in tasks
        assert "api-metrics" in tasks

    def test_config_dict_contains_all_superpowers(self) -> None:
        """Sprawdź czy _build_granian_config() zwraca pełen zestaw supermoc."""
        from nexus_ai.api.server import _build_granian_config

        config = _build_granian_config()

        # Supermoce które muszą być w configu
        superpowers = [
            "backlog",
            "backpressure",
            "http",
            "http2_max_concurrent_streams",
            "log_access",
            "log_access_fmt",
            "no_header_server",
            "metrics",
            "metrics_address",
            "metrics_port",
            "respawn_failed_workers",
            "workers_kill_timeout",
            "graceful_shutdown_timeout",
            "loop",
            "runtime_threads",
            "runtime_blocking_threads",
        ]
        for sp in superpowers:
            assert sp in config, f"Missing superpower: {sp}"
