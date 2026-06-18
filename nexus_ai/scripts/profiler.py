"""
py-spy profiler wrapper — sampling profiling dla NexusAI.

Zgodnie z aa3fvcx.txt: py-spy zastępuje cProfile jako domyślny profiler.
py-spy to sampling profiler w Rust — podpina się do działającego procesu
bez restartu, narzut <1%.

SUPERMOCE py-spy:
  - py-spy record     — Generuj flamegraphy (SVG) i speedscope (JSON)
  - py-spy top        — Interaktywny top-like widok funkcji (live)
  - py-spy dump       — Zrzut stosu wszystkich wątków (debugowanie hangów)
  - --native          — Profiluj także native frames (C/Cython/Rust)
  - --gil             — Tylko wątki trzymające GIL
  - --idle            — Uwzględnij wątki bezczynne
  - --subprocesses    — Automatyczne dołączanie do procesów potomnych
  - -r (rate)         — Częstotliwość próbkowania (default 100, max 10000)
  - -d (duration)     — Czas trwania profilowania
  - -p (pid)          — Dołącz do działającego procesu po PID
  - --nonblocking     — Zero narzutu (ale mogą być niepełne stack trace)
  - -o (output)       — Format: svg (flamegraph), speedscope, raw
  - --logical-cpus    — Dostosuj liczbę wątków do logicznych rdzeni

Użycie:
    from nexus_ai.scripts.profiler import (
        profile_process,
        profile_subprocess,
        generate_flamegraph,
        dump_stack,
        ProfilerConfig,
    )

    # Profiluj działający proces przez 30 sekund
    flamegraph = await profile_process(
        pid=12345,
        duration=30,
        output="reports/profiles/cpu_flamegraph.svg"
    )

    # Profiluj podczas uruchamiania komendy
    result = await profile_subprocess(
        cmd=["pytest", "tests/"],
        output="reports/profiles/test_flamegraph.svg",
        rate=500,
    )

    # Zrzut stosu dla zawieszonego procesu
    stack = await dump_stack(pid=12345)
"""

from __future__ import annotations

import os
import shutil
import signal
import sys
import tempfile
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any

import anyio
from structlog import get_logger

logger = get_logger("nexus.scripts.profiler")


# ── Konfiguracja ─────────────────────────────────────────────────────────────


class OutputFormat(str, Enum):
    """Format wyjściowy py-spy record."""
    FLAMEGRAPH = "svg"        # Klasyczny flamegraph SVG (perl script)
    FLAMEGRAPH_INVERTED = "flamegraph"  # Iced flamegraph (odwrócony)
    SPEEDSCOPE = "speedscope" # JSON dla speedscope.app
    RAW = "raw"              # Surowe próbki do własnej analizy


@dataclass
class ProfilerConfig:
    """Konfiguracja profilera z wszystkimi supermocami py-spy.

    Attributes:
        rate: Częstotliwość próbkowania (samples/sec). Default 100.
        duration: Czas profilowania w sekundach. Default 30.
        native: Profiluj native frames (C/Cython/Rust). Default False.
        gil: Tylko wątki trzymające GIL. Default False.
        idle: Uwzględnij wątki bezczynne. Default True.
        subprocesses: Automatyczne dołączanie do subprocessów. Default False.
        nonblocking: Zero narzutu (ryzyko niekompletnych próbek). Default False.
        logical_cpus: Dostosuj wątki do logicznych rdzeni. Default True.
        output_dir: Katalog dla plików wyjściowych. Default "reports/profiles".
    """
    rate: int = 100
    duration: int = 30
    native: bool = False
    gil: bool = False
    idle: bool = True
    subprocesses: bool = False
    nonblocking: bool = False
    logical_cpus: bool = True
    output_dir: str = "reports/profiles"


# ── Detekcja py-spy ─────────────────────────────────────────────────────────


def _find_pyspy() -> str | None:
    """Znajdź ścieżkę do py-spy binary."""
    pyspy = shutil.which("py-spy")
    if pyspy:
        return pyspy
    # Sprawdź w typowych lokalizacjach pixi/uv
    for candidate in [
        Path(sys.executable).parent / "py-spy",
        Path.home() / ".pixi/envs/default/bin/py-spy",
        Path.home() / ".local/bin/py-spy",
        Path("/usr/local/bin/py-spy"),
        Path("/usr/bin/py-spy"),
    ]:
        if candidate.exists():
            return str(candidate)
    return None


def check_pyspy_installed() -> tuple[bool, str]:
    """Sprawdź czy py-spy jest zainstalowany.

    Returns:
        (is_installed, version_or_error)
    """
    pyspy = _find_pyspy()
    if pyspy is None:
        return False, "py-spy not found in PATH or common locations"
    try:
        import subprocess as _sp
        result = _sp.run(
            [pyspy, "--version"],
            capture_output=True, text=True, timeout=10
        )
        version = result.stdout.strip() or result.stderr.strip()
        return True, version or py-spy
    except Exception as exc:
        return False, str(exc)


# ── SUPERMOC: py-spy record — Flamegraph / Speedscope ─────────────────────


async def profile_process(
    pid: int,
    duration: int = 30,
    output: str | None = None,
    *,
    config: ProfilerConfig | None = None,
    output_format: OutputFormat = OutputFormat.FLAMEGRAPH,
    tags: dict[str, str] | None = None,
) -> Path:
    """SUPERMOC py-spy #1: Profiluj działający proces.

    Używa ``py-spy record`` do próbkowania stosu procesu o podanym PID.
    Generuje flamegraph SVG (lub speedscope JSON).

    SUPERMOCE:
    - --rate: regulacja częstotliwości próbkowania (domyślnie 100/s)
    - --native: profilowanie native frames (C/Cython/Rust PyO3)
    - --gil: tylko wątki trzymające GIL (dla diagnostyki GIL contention)
    - --idle: kontrola czy uwzględniać wątki bezczynne
    - --subprocesses: dołączanie do procesów potomnych

    Args:
        pid: PID procesu do profilowania.
        duration: Czas profilowania w sekundach.
        output: Ścieżka pliku wyjściowego (domyślnie reports/profiles/).
        config: Konfiguracja profilera (używa domyślnej jeśli None).
        format: Format wyjściowy (svg, speedscope, raw).
        tags: Tagi do nazwy pliku (np. {"test": "load", "user": "50"}).

    Returns:
        Ścieżka do wygenerowanego pliku.

    Raises:
        FileNotFoundError: Jeśli py-spy nie jest zainstalowany.
        RuntimeError: Jeśli profilowanie się nie powiedzie.
    """
    pyspy = _find_pyspy()
    if pyspy is None:
        raise FileNotFoundError(
            "py-spy not found. Install: pixi install --environment dev "
            "or pip install py-spy"
        )

    cfg = config or ProfilerConfig()
    out_dir = Path(cfg.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Generuj nazwę pliku jeśli nie podana
    if output is None:
        tag_suffix = ""
        if tags:
            tag_suffix = "_" + "_".join(f"{k}-{v}" for k, v in tags.items())
        ext = output_format.value
        output = str(out_dir / f"profile_pid-{pid}{tag_suffix}_{duration}s.{ext}")

    output_path = Path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Buduj komendę py-spy record z wszystkimi supermocami
    cmd = [
        pyspy, "record",
        "-p", str(pid),
        "-d", str(cfg.duration),
        "-r", str(cfg.rate),
        "-o", str(output_path),
        "--format", output_format.value,
    ]

    # SUPERMOC: Native frames
    if cfg.native:
        cmd.append("--native")

    # SUPERMOC: GIL-only
    if cfg.gil:
        cmd.append("--gil")

    # SUPERMOC: Idle threads
    if cfg.idle:
        cmd.append("--idle")

    # SUPERMOC: Subprocesses
    if cfg.subprocesses:
        cmd.append("--subprocesses")

    # SUPERMOC: Non-blocking mode
    if cfg.nonblocking:
        cmd.append("--nonblocking")

    if cfg.logical_cpus:
        cmd.append("--logical-cpus")

    logger.info(
        "[PY-SPY] Profiling PID=%d for %ds at %d samples/sec (native=%s, gil=%s, idle=%s)",
        pid, cfg.duration, cfg.rate, cfg.native, cfg.gil, cfg.idle,
    )

    try:
        async with anyio.fail_after(cfg.duration + 30):
            result = await anyio.run_process(cmd)
        if result.returncode != 0:
            stderr = result.stderr.decode() if result.stderr else ""
            raise RuntimeError(
                f"py-spy record failed (exit={result.returncode}): {stderr}"
            )
        logger.info("[PY-SPY] Profile saved: %s", output_path)
        return output_path
    except TimeoutError:
        logger.warning("[PY-SPY] Profile timed out, partial data may exist at %s", output_path)
        return output_path


async def profile_subprocess(
    cmd: list[str],
    output: str | None = None,
    *,
    config: ProfilerConfig | None = None,
    output_format: OutputFormat = OutputFormat.FLAMEGRAPH,
    tags: dict[str, str] | None = None,
    cwd: str | Path | None = None,
) -> tuple[Path, int]:
    """SUPERMOC py-spy #2: Profiluj podczas uruchamiania komendy.

    Uruchamia komendę jako subprocess i profiluje ją od startu.
    Idealne do profilowania testów, skryptów, jednorazowych zadań.

    SUPERMOCE:
    - Automatyczne dołączanie do procesu od pierwszego ticka
    - Wsparcie dla --subprocesses do profilowania procesów potomnych
    - Speedscope export dla nowoczesnych narzędzi wizualizacji

    Args:
        cmd: Komenda do uruchomienia (np. ["pytest", "tests/"]).
        output: Ścieżka pliku wyjściowego.
        config: Konfiguracja profilera.
        format: Format wyjściowy.
        tags: Tagi do nazwy pliku.
        cwd: Katalog roboczy dla komendy.

    Returns:
        (ścieżka_do_profila, exit_code_komendy)
    """
    pyspy = _find_pyspy()
    if pyspy is None:
        raise FileNotFoundError("py-spy not found")

    cfg = config or ProfilerConfig()
    out_dir = Path(cfg.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    if output is None:
        tag_suffix = ""
        if tags:
            tag_suffix = "_" + "_".join(f"{k}-{v}" for k, v in tags.items())
        # Użyj nazwy komendy jako podstawy
        cmd_name = Path(cmd[0]).stem if cmd else "unknown"
        ext = output_format.value
        output = str(out_dir / f"profile_{cmd_name}{tag_suffix}_{cfg.duration}s.{ext}")

    output_path = Path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # SUPERMOC: py-spy record -o output -- pytest tests/
    record_cmd = [
        pyspy, "record",
        "-d", str(cfg.duration),
        "-r", str(cfg.rate),
        "-o", str(output_path),
        "--format", output_format.value,
    ]

    if cfg.native:
        record_cmd.append("--native")
    if cfg.gil:
        record_cmd.append("--gil")
    if cfg.idle:
        record_cmd.append("--idle")
    if cfg.subprocesses:
        record_cmd.append("--subprocesses")
    if cfg.nonblocking:
        record_cmd.append("--nonblocking")
    if cfg.logical_cpus:
        record_cmd.append("--logical-cpus")

    # Komenda do profilowania: py-spy record -- pytest tests/
    full_cmd = record_cmd + ["--"] + cmd

    logger.info(
        "[PY-SPY] Profiling subprocess: %s -> %s",
        " ".join(cmd), output_path,
    )

    env = {**os.environ}
    try:
        async with anyio.fail_after(cfg.duration + 60):
            result = await anyio.run_process(
                full_cmd,
                env=env,
                cwd=str(cwd) if cwd else None,
            )
        logger.info("[PY-SPY] Subprocess profile saved: %s (exit=%d)", output_path, result.returncode)
        return output_path, result.returncode
    except TimeoutError:
        logger.warning("[PY-SPY] Subprocess profile timed out")
        return output_path, -1


# ── SUPERMOC: py-spy dump — Stack trace wszystkich wątków ─────────────────


@dataclass
class ThreadDump:
    """Zrzut stosu pojedynczego wątku z py-spy dump."""
    thread_id: str
    thread_name: str
    stack: list[str]
    native: list[str] | None = None
    locals: dict[str, str] | None = None  # --locals (wymaga sudo)


@dataclass
class ProcessDump:
    """Pełny zrzut procesu z py-spy dump."""
    pid: int
    threads: list[ThreadDump]
    total_samples: int
    raw_output: str = ""


async def dump_stack(
    pid: int,
    *,
    native: bool = False,
    locals: bool = False,
) -> ProcessDump:
    """SUPERMOC py-spy #3: Zrzut stosu wszystkich wątków procesu.

    Używa ``py-spy dump`` do pobrania aktualnego stosu wszystkich wątków.
    Idealne do debugowania "zawieszonych" procesów — pokazuje co robi
    każdy wątek w danej chwili.

    SUPERMOCE:
    - --native: dołącz native frames (C/Cython/Rust)
    - --locals: dołącz zmienne lokalne (wymaga sudo/root na Linux)
    - Bez zatrzymywania procesu — zero narzutu

    Args:
        pid: PID procesu.
        native: Czy dołączyć native frames.
        locals: Czy dołączyć zmienne lokalne (wymaga root).

    Returns:
        ProcessDump z wszystkimi wątkami.

    Raises:
        FileNotFoundError: Jeśli py-spy nie jest zainstalowany.
        RuntimeError: Jeśli dump nie powiedzie się.
    """
    pyspy = _find_pyspy()
    if pyspy is None:
        raise FileNotFoundError("py-spy not found")

    cmd = [pyspy, "dump", "-p", str(pid)]
    if native:
        cmd.append("--native")
    if locals:
        cmd.append("--locals")

    try:
        async with anyio.fail_after(30):
            result = await anyio.run_process(cmd)
        output = result.stdout.decode() if result.stdout else ""
        stderr = result.stderr.decode() if result.stderr else ""

        if result.returncode != 0:
            raise RuntimeError(
                f"py-spy dump failed (exit={result.returncode}): {stderr}"
            )

        # Parsuj wyjście py-spy dump
        threads: list[ThreadDump] = []
        current_thread: dict[str, Any] = {}
        current_stack: list[str] = []

        for line in output.split("\n"):
            if line.startswith("Thread "):
                if current_thread:
                    threads.append(ThreadDump(
                        thread_id=current_thread.get("id", "?"),
                        thread_name=current_thread.get("name", "?"),
                        stack=current_stack,
                    ))
                # Parsuj: "Thread 0x7f (idle): thread_name"
                parts = line.split(":")
                header = parts[0] if parts else ""
                thread_id = header.replace("Thread ", "").strip()
                thread_name = parts[1].strip() if len(parts) > 1 else "?"
                current_thread = {"id": thread_id, "name": thread_name}
                current_stack = []
            elif line.strip() and current_thread:
                current_stack.append(line.strip())

        # Dodaj ostatni wątek
        if current_thread:
            threads.append(ThreadDump(
                thread_id=current_thread.get("id", "?"),
                thread_name=current_thread.get("name", "?"),
                stack=current_stack,
            ))

        return ProcessDump(
            pid=pid,
            threads=threads,
            total_samples=len(threads),
            raw_output=output,
        )

    except TimeoutError:
        logger.warning("[PY-SPY] dump_stack timed out for PID=%d", pid)
        return ProcessDump(pid=pid, threads=[], total_samples=0)


# ── SUPERMOC: py-spy top — Live monitoring ───────────────────────────────


async def top_snapshot(
    pid: int,
    *,
    duration: int = 5,
    rate: int = 100,
    native: bool = False,
    gil: bool = False,
) -> list[dict[str, Any]]:
    """SUPERMOC py-spy #4: Zrzut top-like widoku funkcji.

    Uruchamia ``py-spy top`` na krótki czas i parsuje wyniki.
    Zwraca listę funkcji posortowanych według % CPU.

    Args:
        pid: PID procesu.
        duration: Czas zbierania próbek (sekund).
        rate: Częstotliwość próbkowania.
        native: Czy dołączyć native frames.
        gil: Tylko wątki trzymające GIL.

    Returns:
        Lista dictów: {name, percent, num_samples, own_time, filename}
    """
    pyspy = _find_pyspy()
    if pyspy is None:
        raise FileNotFoundError("py-spy not found")

    cmd = [
        pyspy, "top",
        "-p", str(pid),
        "-d", str(duration),
        "-r", str(rate),
    ]
    if native:
        cmd.append("--native")
    if gil:
        cmd.append("--gil")

    try:
        async with anyio.fail_after(duration + 15):
            result = await anyio.run_process(cmd)
        output = result.stdout.decode() if result.stdout else ""

        # Parsuj wyjście top (proste parsowanie)
        functions: list[dict[str, Any]] = []
        for line in output.split("\n"):
            line = line.strip()
            # Format: "  12.3%  function_name  file.py:42"
            if "%" in line and "  " in line:
                parts = line.split(None, 3)
                if len(parts) >= 3:
                    try:
                        percent = float(parts[0].replace("%", ""))
                        name = parts[1]
                        location = parts[2] if len(parts) > 2 else ""
                        functions.append({
                            "name": name,
                            "percent": percent,
                            "location": location,
                        })
                    except (ValueError, IndexError):
                        pass

        return sorted(functions, key=lambda x: x["percent"], reverse=True)

    except Exception as exc:
        logger.warning("[PY-SPY] top_snapshot failed: %s", exc)
        return []


# ── SUPERMOC: Raportowanie ────────────────────────────────────────────────


@dataclass
class ProfileReport:
    """Pełny raport profilowania."""
    flamegraph_path: Path | None = None
    speedscope_path: Path | None = None
    raw_path: Path | None = None
    top_functions: list[dict[str, Any]] = field(default_factory=list)
    dump: ProcessDump | None = None
    config: ProfilerConfig = field(default_factory=ProfilerConfig)
    duration: int = 0
    pid: int = 0
    tags: dict[str, str] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        """Serialize raport do dict (dla JSON/CI)."""
        return {
            "flamegraph": str(self.flamegraph_path) if self.flamegraph_path else None,
            "speedscope": str(self.speedscope_path) if self.speedscope_path else None,
            "raw": str(self.raw_path) if self.raw_path else None,
            "top_functions": self.top_functions[:20],  # top 20
            "thread_count": len(self.dump.threads) if self.dump else 0,
            "pid": self.pid,
            "duration_s": self.duration,
            "config": {
                "rate": self.config.rate,
                "native": self.config.native,
                "gil": self.config.gil,
                "idle": self.config.idle,
            },
            "tags": self.tags,
        }


async def generate_comprehensive_profile(
    pid: int,
    duration: int = 60,
    *,
    output_dir: str | Path = "reports/profiles",
    tags: dict[str, str] | None = None,
    native: bool = False,
    gil: bool = False,
) -> ProfileReport:
    """SUPERMOC py-spy #5: Kompleksowe profilowanie — flamegraph + dump + top.

    Uruchamia sekwencyjnie:
    1. py-spy record → flamegraph SVG
    2. py-spy record → speedscope JSON (jeśli py-spy wspiera)
    3. py-spy dump → stack trace
    4. py-spy top → top functions snapshot

    Args:
        pid: PID procesu.
        duration: Czas profilowania dla flamegrapha.
        output_dir: Katalog wyjściowy.
        tags: Tagi do nazw plików.
        native: Profiluj native frames.
        gil: Tylko GIL threads.

    Returns:
        ProfileReport z wszystkimi wynikami.
    """
    cfg = ProfilerConfig(
        rate=100,
        duration=duration,
        native=native,
        gil=gil,
        idle=True,
    )
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    report = ProfileReport(
        config=cfg,
        duration=duration,
        pid=pid,
        tags=tags or {},
    )

    # 1. Flamegraph SVG
    try:
        svg_path = await profile_process(
            pid=pid,
            duration=duration,
            output=str(out / f"profile_pid-{pid}_flamegraph.svg"),
            config=cfg,
            output_format=OutputFormat.FLAMEGRAPH,
            tags=tags,
        )
        report.flamegraph_path = svg_path
    except Exception as exc:
        logger.warning("[PY-SPY] Flamegraph generation failed: %s", exc)

    # 2. Speedscope JSON (krótszy czas)
    try:
        speed_cfg = ProfilerConfig(rate=100, duration=min(15, duration))
        speed_path = await profile_process(
            pid=pid,
            duration=min(15, duration),
            output=str(out / f"profile_pid-{pid}_speedscope.json"),
            config=speed_cfg,
            output_format=OutputFormat.SPEEDSCOPE,
            tags=tags,
        )
        report.speedscope_path = speed_path
    except Exception as exc:
        logger.warning("[PY-SPY] Speedscope generation failed: %s", exc)

    # 3. Dump stack
    try:
        report.dump = await dump_stack(pid=pid, native=native)
    except Exception as exc:
        logger.warning("[PY-SPY] Stack dump failed: %s", exc)

    # 4. Top snapshot
    try:
        report.top_functions = await top_snapshot(
            pid=pid, duration=5, rate=100, native=native
        )
    except Exception as exc:
        logger.warning("[PY-SPY] Top snapshot failed: %s", exc)

    return report


# ── CLI entry point ────────────────────────────────────────────────────────


def _parse_args() -> dict[str, Any]:
    """Parsuj argumenty CLI dla profiler.py."""
    import argparse
    parser = argparse.ArgumentParser(
        description="NexusAI — py-spy Profiler Wrapper",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--pid", type=int, help="PID procesu do profilowania")
    parser.add_argument("--duration", type=int, default=30, help="Czas profilowania (s)")
    parser.add_argument("--rate", type=int, default=100, help="Próbkowanie na sekundę")
    parser.add_argument("--output", "-o", help="Ścieżka pliku wyjściowego")
    parser.add_argument("--output-dir", default="reports/profiles", help="Katalog wyjściowy")
    parser.add_argument("--native", action="store_true", help="Profiluj native frames")
    parser.add_argument("--gil", action="store_true", help="Tylko GIL threads")
    parser.add_argument("--no-idle", action="store_false", dest="idle", default=True, help="Wyklucz wątki bezczynne (domyślnie: uwzględnione)")
    parser.add_argument("--format", choices=["svg", "speedscope", "raw"], default="svg")
    parser.add_argument("--dump", action="store_true", help="Tylko dump stack (bez flamegraph)")
    parser.add_argument("--top", action="store_true", help="Tylko top snapshot (bez flamegraph)")
    parser.add_argument("--cmd", nargs="+", help="Komenda do profilowania (zamiast --pid)")
    parser.add_argument("--check", action="store_true", help="Sprawdź czy py-spy jest dostępny")

    args = parser.parse_args()
    return vars(args)


async def main() -> int:
    """CLI entry point dla profiler.py."""
    args = _parse_args()

    if args.get("check"):
        installed, version = check_pyspy_installed()
        if installed:
            print(f"✅ py-spy available: {version}")
            return 0
        print(f"❌ py-spy not available: {version}")
        return 1

    pyspy = _find_pyspy()
    if pyspy is None:
        print("❌ py-spy not found. Install: pixi install --environment dev", file=sys.stderr)
        return 2

    config = ProfilerConfig(
        rate=args.get("rate", 100),
        duration=args.get("duration", 30),
        native=args.get("native", False),
        gil=args.get("gil", False),
        idle=args.get("idle", True),
        output_dir=args.get("output_dir", "reports/profiles"),
    )

    # Tryb: dump stack only
    if args.get("dump"):
        pid = args.get("pid") or os.getpid()
        dump_result = await dump_stack(pid=pid, native=config.native)
        print(f"\n{'='*60}")
        print(f"Thread Dump for PID {pid}")
        print(f"{'='*60}\n")
        for thread in dump_result.threads:
            print(f"Thread {thread.thread_id}: {thread.thread_name}")
            print("-" * 40)
            for frame in thread.stack[:20]:  # top 20 frames
                print(f"  {frame}")
            print()
        return 0

    # Tryb: top snapshot only
    if args.get("top"):
        pid = args.get("pid") or os.getpid()
        functions = await top_snapshot(
            pid=pid, duration=config.duration, rate=config.rate,
            native=config.native, gil=config.gil,
        )
        print(f"\n{'='*60}")
        print(f"Top Functions for PID {pid} ({config.duration}s)")
        print(f"{'='*60}\n")
        print(f"{'% CPU':>8}  {'Function':40s}  {'Location'}")
        print("-" * 60)
        for func in functions[:30]:
            print(f"{func['percent']:>7.1f}%  {func['name']:40s}  {func.get('location', '')}")
        return 0

    # Tryb: profile subprocess
    cmd = args.get("cmd")
    if cmd:
        output = args.get("output")
        out_fmt = OutputFormat(args.get("format", "svg"))
        profile_path, exit_code = await profile_subprocess(
            cmd=cmd,
            output=output,
            config=config,
            output_format=out_fmt,
        )
        print(f"✅ Profile: {profile_path}")
        print(f"✅ Exit code: {exit_code}")
        return exit_code

    # Tryb: profile by PID
    pid = args.get("pid") or os.getpid()
    output = args.get("output")
    out_fmt = OutputFormat(args.get("format", "svg"))

    try:
        profile_path = await profile_process(
            pid=pid,
            duration=config.duration,
            output=output,
            config=config,
            output_format=out_fmt,
        )
        print(f"✅ Profile: {profile_path}")
        print(f"📊 Open flamegraph: {profile_path}")
        return 0
    except (FileNotFoundError, RuntimeError) as exc:
        print(f"❌ {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(anyio.run(main))
