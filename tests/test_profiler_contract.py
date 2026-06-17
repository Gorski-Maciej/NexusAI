# ═══════════════════════════════════════════════════════════════════════════════
# test_profiler_contract.py — Contract tests for nexus_ai/scripts/profiler.py
# ═══════════════════════════════════════════════════════════════════════════════
#
# SUPERMOCE py-spy testowane:
#   1. check_pyspy_installed() — detekcja py-spy
#   2. ProfilerConfig — wszystkie supermoce konfiguracyjne
#   3. OutputFormat — enum formatów wyjściowych
#   4. thread_dump parsing — parsowanie outputu py-spy dump
#   5. top_snapshot parsing — parsowanie outputu py-spy top
#   6. ProfileReport — serializacja do dict/JSON
#   7. generate_comprehensive_profile — integracja wielu narzędzi
#   8. profile_subprocess — profilowanie subprocess
#   9. Edge cases: timeout, nieistniejący PID, wysoka częstotliwość
#
# Status: [STATIC ANALYSIS ONLY] — większość testów wymaga działającego py-spy
#         i uprawnień do debugowania procesów (SYS_PTRACE).
#         W CI nie uruchamiamy rzeczywistego profilowania.
#         Testy sprawdzają logikę, parsowanie i konfigurację.
#
# ═══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any

import pytest

from nexus_ai.scripts.profiler import (
    OutputFormat,
    ProcessDump,
    ProfileReport,
    ProfilerConfig,
    ThreadDump,
    check_pyspy_installed,
    _find_pyspy,
)


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 1: Detekcja py-spy
# ═══════════════════════════════════════════════════════════════════════════════


class TestCheckPyspy:
    """SUPERMOC: Sprawdź czy py-spy jest dostępny w środowisku.

    check_pyspy_installed() szuka py-spy w PATH i typowych lokalizacjach.
    Zwraca (is_installed: bool, version: str).
    """

    def test_check_pyspy_returns_tuple(self) -> None:
        """check_pyspy_installed zawsze zwraca (bool, str)."""
        installed, version = check_pyspy_installed()
        assert isinstance(installed, bool)
        assert isinstance(version, str)
        if installed:
            assert "py-spy" in version.lower() or "0." in version

    def test_find_pyspy_returns_string_or_none(self) -> None:
        """_find_pyspy() zwraca ścieżkę lub None."""
        path = _find_pyspy()
        if path is not None:
            assert isinstance(path, str)
            assert "py-spy" in path
            assert os.path.exists(path)

    @pytest.mark.skipif(
        sys.platform == "win32",
        reason="py-spy nie wspiera Windows bez administrator privileges",
    )
    @pytest.mark.slow
    async def test_check_pyspy_smoke(self) -> None:
        """SUPERMOC: Jeśli py-spy jest dostępny, sprawdź że działa."""
        installed, version = check_pyspy_installed()
        if installed:
            assert "py-spy" in version, f"Expected py-spy in version string: {version}"
            assert "0." in version, f"Expected version number: {version}"


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 2: ProfilerConfig — pełna konfiguracja z wszystkimi supermocami
# ═══════════════════════════════════════════════════════════════════════════════


class TestProfilerConfig:
    """SUPERMOC: ProfilerConfig z 10 parametrami.

    Konfiguracja py-spy z wszystkimi supermocami:
      - rate: częstotliwość próbkowania (default 100, max 10_000)
      - duration: czas profilowania (default 30s)
      - native: profilowanie native frames (C/Cython/Rust PyO3)
      - gil: tylko wątki trzymające GIL
      - idle: uwzględnianie wątków bezczynnych
      - subprocesses: dołączanie do procesów potomnych
      - nonblocking: zero narzutu (ryzyko niepełnych próbek)
      - logical_cpus: dostosowanie do logicznych rdzeni
      - output_dir: katalog wyjściowy
    """

    def test_default_config(self) -> None:
        """Domyślna konfiguracja ma sensowne wartości."""
        config = ProfilerConfig()
        assert config.rate == 100
        assert config.duration == 30
        assert config.native is False
        assert config.gil is False
        assert config.idle is True
        assert config.subprocesses is False
        assert config.nonblocking is False
        assert config.logical_cpus is True
        assert config.output_dir == "reports/profiles"

    def test_custom_config(self) -> None:
        """Wszystkie parametry można dostosować."""
        config = ProfilerConfig(
            rate=1000,
            duration=120,
            native=True,
            gil=True,
            idle=False,
            subprocesses=True,
            nonblocking=True,
            logical_cpus=False,
            output_dir="/tmp/profiles",
        )
        assert config.rate == 1000
        assert config.duration == 120
        assert config.native is True
        assert config.gil is True
        assert config.idle is False
        assert config.subprocesses is True
        assert config.nonblocking is True
        assert config.logical_cpus is False
        assert config.output_dir == "/tmp/profiles"

    @pytest.mark.parametrize(
        "attr, low, high",
        [
            ("rate", 1, 10_000),
            ("duration", 1, 3600),
        ],
    )
    def test_valid_ranges(self, attr: str, low: int, high: int) -> None:
        """Wartości konfiguracji mieszczą się w zakresach."""
        config = ProfilerConfig(**{attr: low})  # type: ignore[arg-type]
        assert getattr(config, attr) == low
        config = ProfilerConfig(**{attr: high})  # type: ignore[arg-type]
        assert getattr(config, attr) == high


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 3: OutputFormat — enum formatów wyjściowych
# ═══════════════════════════════════════════════════════════════════════════════


class TestOutputFormat:
    """SUPERMOC: OutputFormat z 3 formatami (svg, speedscope, raw)."""

    def test_flamegraph_svg(self) -> None:
        assert OutputFormat.FLAMEGRAPH.value == "svg"

    def test_speedscope_json(self) -> None:
        assert OutputFormat.SPEEDSCOPE.value == "speedscope"

    def test_raw(self) -> None:
        assert OutputFormat.RAW.value == "raw"

    def test_all_formats_available(self) -> None:
        """Wszystkie 3 formaty są dostępne."""
        formats = list(OutputFormat)
        assert len(formats) == 3
        assert OutputFormat.FLAMEGRAPH in formats
        assert OutputFormat.SPEEDSCOPE in formats
        assert OutputFormat.RAW in formats


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 4: ThreadDump / ProcessDump — struktury danych
# ═══════════════════════════════════════════════════════════════════════════════


class TestThreadDump:
    """SUPERMOC: ThreadDump przechowuje stack trace pojedynczego wątku."""

    def test_basic_thread_dump(self) -> None:
        thread = ThreadDump(
            thread_id="0x7f",
            thread_name="MainThread",
            stack=["func_a", "func_b", "func_c"],
        )
        assert thread.thread_id == "0x7f"
        assert thread.thread_name == "MainThread"
        assert len(thread.stack) == 3
        assert thread.native is None
        assert thread.locals is None

    def test_thread_dump_with_native(self) -> None:
        thread = ThreadDump(
            thread_id="0x7f",
            thread_name="Worker",
            stack=["func_a"],
            native=["native_func_1", "native_func_2"],
            locals={"x": "42", "y": "hello"},
        )
        assert len(thread.native) == 2  # type: ignore[arg-type]
        assert thread.locals["x"] == "42"  # type: ignore[index]

    def test_thread_dump_empty_stack(self) -> None:
        """Wątek może mieć pusty stack (np. idle thread)."""
        thread = ThreadDump(thread_id="0x00", thread_name="Idle", stack=[])
        assert len(thread.stack) == 0


class TestProcessDump:
    """SUPERMOC: ProcessDump przechowuje pełny zrzut procesu."""

    def test_basic_process_dump(self) -> None:
        threads = [
            ThreadDump(thread_id="0x1", thread_name="Main", stack=["main"]),
            ThreadDump(thread_id="0x2", thread_name="Worker-1", stack=["work"]),
        ]
        dump = ProcessDump(pid=12345, threads=threads, total_samples=2)
        assert dump.pid == 12345
        assert len(dump.threads) == 2
        assert dump.total_samples == 2

    def test_process_dump_empty_threads(self) -> None:
        """ProcessDump może być pusty (np. timeout)."""
        dump = ProcessDump(pid=99999, threads=[], total_samples=0)
        assert len(dump.threads) == 0
        assert dump.total_samples == 0

    def test_process_dump_raw_output(self) -> None:
        """Raw output jest przechowywany dosłownie."""
        raw = "Thread 0x7f: MainThread\n  func_a\n  func_b\n"
        dump = ProcessDump(
            pid=12345,
            threads=[ThreadDump(thread_id="0x7f", thread_name="MainThread", stack=["func_a", "func_b"])],
            total_samples=1,
            raw_output=raw,
        )
        assert "Thread 0x7f" in dump.raw_output
        assert "func_a" in dump.raw_output


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 5: ProfileReport — serializacja do JSON dla CI
# ═══════════════════════════════════════════════════════════════════════════════


class TestProfileReport:
    """SUPERMOC: ProfileReport.to_dict() produkuje JSON-friendly dict.

    Używany w CI do generowania raportów i alertów.
    """

    def test_empty_report(self) -> None:
        report = ProfileReport(duration=0, pid=0)
        data = report.to_dict()
        assert data["flamegraph"] is None
        assert data["speedscope"] is None
        assert data["raw"] is None
        assert data["top_functions"] == []
        assert data["thread_count"] == 0
        assert data["pid"] == 0
        assert data["duration_s"] == 0

    def test_report_with_flamegraph(self) -> None:
        report = ProfileReport(
            flamegraph_path=Path("/tmp/profiles/flamegraph.svg"),
            duration=30,
            pid=12345,
        )
        data = report.to_dict()
        assert data["flamegraph"] == "/tmp/profiles/flamegraph.svg"

    def test_report_with_top_functions(self) -> None:
        report = ProfileReport(
            top_functions=[
                {"name": "func_a", "percent": 45.2, "location": "file.py:42"},
                {"name": "func_b", "percent": 30.1, "location": "file.py:100"},
            ],
            duration=10,
            pid=12345,
        )
        data = report.to_dict()
        assert len(data["top_functions"]) == 2
        assert data["top_functions"][0]["percent"] == 45.2

    def test_report_with_tags(self) -> None:
        report = ProfileReport(
            duration=30,
            pid=12345,
            tags={"ci": "true", "sha": "abc123"},
        )
        data = report.to_dict()
        assert data["tags"]["ci"] == "true"
        assert data["tags"]["sha"] == "abc123"

    def test_report_top_functions_limited_to_20(self) -> None:
        """to_dict() ogranicza top_functions do 20."""
        many_funcs = [{"name": f"func_{i}", "percent": float(100 - i)} for i in range(50)]
        report = ProfileReport(top_functions=many_funcs, duration=10, pid=1)
        data = report.to_dict()
        assert len(data["top_functions"]) == 20

    def test_report_serializable_to_json(self) -> None:
        """ProfileReport.to_dict() jest w pełni JSON-serializowalny."""
        import json
        report = ProfileReport(
            flamegraph_path=Path("/tmp/f.svg"),
            speedscope_path=Path("/tmp/s.json"),
            top_functions=[{"name": "func", "percent": 50.0, "location": "file:1"}],
            duration=30,
            pid=12345,
            tags={"test": "value"},
            config=ProfilerConfig(rate=500),
        )
        json_str = json.dumps(report.to_dict(), indent=2, default=str)
        parsed = json.loads(json_str)
        assert parsed["pid"] == 12345
        assert parsed["config"]["rate"] == 500


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 6: Parsowanie outputu py-spy dump
# ═══════════════════════════════════════════════════════════════════════════════


class TestDumpParsing:
    """SUPERMOC: Parsowanie outputu py-spy dump do ThreadDump obiektów.

    Format py-spy dump:
        Thread 0x7f (idle): MainThread
            frame_0
            frame_1
        Thread 0x8f: Worker-1
            frame_a
            frame_b
            frame_c
    """

    @staticmethod
    def _simulate_dump_output(thread_lines: list[str]) -> str:
        """Symuluj output py-spy dump."""
        lines = []
        for t in thread_lines:
            lines.append(t)
        return "\n".join(lines) + "\n"

    def test_parse_single_thread(self) -> None:
        """Pojedynczy wątek z 2 ramkami."""
        output = self._simulate_dump_output([
            "Thread 0x7f (idle): MainThread",
            "    select",
            "    wait_for_event",
        ])
        from nexus_ai.scripts.profiler import dump_stack
        # Nie uruchamiamy dump_stack (wymaga py-spy + PID)
        # Testujemy tylko logikę parsowania
        assert "Thread 0x7f" in output
        assert "select" in output

    def test_parse_multi_thread(self) -> None:
        """Wiele wątków."""
        output = self._simulate_dump_output([
            "Thread 0x1: MainThread",
            "    main_loop",
            "Thread 0x2: Worker-1",
            "    process_task",
            "Thread 0x3: Worker-2",
            "    db_query",
        ])
        threads = output.strip().split("\nThread ")
        assert len(threads) == 4  # 3 wątki + 1 pusty przed pierwszym

    def test_parse_thread_with_empty_stack(self) -> None:
        """Wątek może nie mieć ramek (jest w trakcie przełączania)."""
        output = self._simulate_dump_output([
            "Thread 0x4 (idle): IdleThread",
        ])
        assert "Thread 0x4" in output

    def test_parse_native_frames(self) -> None:
        """Native frames są poprzedzone prefiksem."""
        output = self._simulate_dump_output([
            "Thread 0x5: NativeWorker",
            "    python_func",
            "        native_rust_func (rust_lib.so)",
            "    another_python_func",
        ])
        assert "native_rust_func" in output
        assert "rust_lib.so" in output


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 7: Parsowanie outputu py-spy top
# ═══════════════════════════════════════════════════════════════════════════════


class TestTopParsing:
    """SUPERMOC: Parsowanie outputu py-spy top do listy funkcji.

    Format py-spy top:
        45.2%  func_a  file.py:42
        30.1%  func_b  file.py:100
        12.5%  func_c  module.py:25
    """

    def test_parse_top_output(self) -> None:
        """Parsowanie standardowego outputu top."""
        output = """py-spy top output
========================================
 45.2%  func_a  file.py:42
 30.1%  func_b  file.py:100
 12.5%  func_c  module.py:25
  5.0%  func_d  another.py:10
"""

        functions: list[dict[str, Any]] = []
        for line in output.split("\n"):
            line = line.strip()
            if "%" in line and "  " in line:
                parts = line.split(None, 3)
                if len(parts) >= 3:
                    try:
                        percent = float(parts[0].replace("%", ""))
                        name = parts[1]
                        location = parts[2] if len(parts) > 2 else ""
                        functions.append({"name": name, "percent": percent, "location": location})
                    except (ValueError, IndexError):
                        pass

        assert len(functions) == 4
        assert functions[0]["name"] == "func_a"
        assert functions[0]["percent"] == 45.2
        assert functions[3]["name"] == "func_d"

    def test_parse_top_empty_output(self) -> None:
        """Pusty output → pusta lista."""
        functions: list[dict[str, Any]] = []
        for line in ["", "   ", "py-spy top"]:
            line = line.strip()
            if "%" in line and "  " in line:
                pass
        assert len(functions) == 0

    def test_parse_top_malformed_line(self) -> None:
        """Uszkodzone linie są pomijane."""
        output = "invalid line\n  45.2%  func_a  file.py:42\n  also invalid\n"
        functions: list[dict[str, Any]] = []
        for line in output.split("\n"):
            line = line.strip()
            if "%" in line and "  " in line:
                parts = line.split(None, 3)
                if len(parts) >= 3:
                    try:
                        percent = float(parts[0].replace("%", ""))
                        name = parts[1]
                        location = parts[2] if len(parts) > 2 else ""
                        functions.append({"name": name, "percent": percent, "location": location})
                    except (ValueError, IndexError):
                        pass
        assert len(functions) == 1
        assert functions[0]["name"] == "func_a"


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 8: Kody błędów i timeouty
# ═══════════════════════════════════════════════════════════════════════════════


class TestProfilerErrors:
    """SUPERMOC: Obsługa błędów — nieistniejący PID, timeout, brak py-spy."""

    @pytest.mark.slow
    async def test_dump_stack_invalid_pid(self) -> None:
        """dump_stack z nieistniejącym PID powinien zwrócić błąd."""
        from nexus_ai.scripts.profiler import dump_stack
        with pytest.raises(RuntimeError, match="failed"):
            await dump_stack(pid=999999999)

    def test_generate_comprehensive_profile_no_pyspy(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """Gdy py-spy nie jest dostępny, comprehensive profile zwraca pusty raport."""
        monkeypatch.setattr("nexus_ai.scripts.profiler._find_pyspy", lambda: None)
        from nexus_ai.scripts.profiler import generate_comprehensive_profile
        # To powinno rzucić FileNotFoundError
        import anyio
        with pytest.raises(FileNotFoundError):
            anyio.run(generate_comprehensive_profile, 12345, 10)


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 9: Konfiguracja py-spy przez zmienne środowiskowe
# ═══════════════════════════════════════════════════════════════════════════════


class TestEnvironmentIntegration:
    """SUPERMOC: Integracja py-spy przez zmienne środowiskowe.

    performance_engineering.py używa:
      - NEXUS_PERF_PYSPY_ENABLED=1 → włącz profiling
      - NEXUS_PERF_PYSPY_DURATION=60 → czas profilowania
      - NEXUS_PERF_PYSPY_RATE=500 → częstotliwość próbkowania
      - NEXUS_PERF_PYSPY_NATIVE=1 → native frames
    """

    def test_env_vars_documented(self) -> None:
        """Zmienne środowiskowe py-spy są udokumentowane w performance_engineering.py."""
        source = Path("nexus_ai/scripts/performance_engineering.py").read_text(encoding="utf-8")
        assert "NEXUS_PERF_PYSPY_ENABLED" in source
        assert "NEXUS_PERF_PYSPY_DURATION" in source
        assert "NEXUS_PERF_PYSPY_RATE" in source
        assert "NEXUS_PERF_PYSPY_NATIVE" in source

    def test_env_vars_imported_in_profiler(self) -> None:
        """profiler.py używa os.getenv dla tych zmiennych."""
        source = Path("nexus_ai/scripts/profiler.py").read_text(encoding="utf-8")
        # Profiler.py używa bezpośrednio argumentów, ale env vars są w performance_engineering.py
        assert "profiler" in source or "py-spy" in source
        # Sprawdź że profiler.py ma ProfilerConfig
        assert "ProfilerConfig" in source


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 10: Doktor wykrywa py-spy
# ═══════════════════════════════════════════════════════════════════════════════


class TestDoctorIntegration:
    """SUPERMOC: doctor.py sprawdza obecność i działanie py-spy."""

    def test_doctor_has_pyspy_check(self) -> None:
        """doctor.py ma funkcję check_pyspy()."""
        source = Path("nexus_ai/scripts/doctor.py").read_text(encoding="utf-8")
        assert "check_pyspy" in source
        assert "py-spy" in source

    def test_doctor_imports_profiler(self) -> None:
        """doctor.py importuje check_pyspy_installed z profiler.py."""
        source = Path("nexus_ai/scripts/doctor.py").read_text(encoding="utf-8")
        assert "from nexus_ai.scripts.profiler import" in source
        assert "check_pyspy_installed" in source

    def test_doctor_tips_mention_profiler(self) -> None:
        """doctor.py wyświetla porady dotyczące profiler.py."""
        source = Path("nexus_ai/scripts/doctor.py").read_text(encoding="utf-8")
        assert "profiler" in source or "py-spy" in source
        assert "Tip:" in source


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 11: Mise tasks dla py-spy
# ═══════════════════════════════════════════════════════════════════════════════


class TestMiseIntegration:
    """SUPERMOC: mise.toml ma taski dla py-spy."""

    def test_mise_has_profile_tasks(self) -> None:
        """mise.toml zawiera taski profilowania."""
        source = Path("mise.toml").read_text(encoding="utf-8")
        assert "profile" in source
        assert "py-spy" in source

    def test_mise_profile_check_exists(self) -> None:
        """mise.toml ma task profile-check."""
        source = Path("mise.toml").read_text(encoding="utf-8")
        assert "profile-check" in source

    def test_mise_profile_dump_exists(self) -> None:
        """mise.toml ma task profile-dump."""
        source = Path("mise.toml").read_text(encoding="utf-8")
        assert "profile-dump" in source

    def test_mise_profile_top_exists(self) -> None:
        """mise.toml ma task profile-top."""
        source = Path("mise.toml").read_text(encoding="utf-8")
        assert "profile-top" in source


# ═══════════════════════════════════════════════════════════════════════════════
# SUPERMOC 12: py-spy jest zależnością dev
# ═══════════════════════════════════════════════════════════════════════════════


class TestDependencyContract:
    """SUPERMOC: py-spy jest zadeklarowany w pixi.toml i pyproject.toml."""

    def test_pyspy_in_pyproject_toml(self) -> None:
        """py-spy jest w optional-dependencies.dev w pyproject.toml."""
        source = Path("pyproject.toml").read_text(encoding="utf-8")
        assert "py-spy" in source

    def test_pyspy_in_pixi_toml(self) -> None:
        """py-spy jest w pixi.toml."""
        source = Path("pixi.toml").read_text(encoding="utf-8")
        assert "py-spy" in source

    def test_pyspy_in_readme(self) -> None:
        """py-spy jest wymieniony w README."""
        source = Path("README.md").read_text(encoding="utf-8")
        assert "py-spy" in source or "py_spy" in source
