"""
doctor.py — Comprehensive system diagnostics for NexusAI.

Run via:
    python main.py --mode doctor
    python -m nexus_ai.scripts.doctor

Checks:
  - Python version and environment
  - CPU / GPU (CUDA) availability
  - Required model files (GGUF) present and integrity-verified
  - NATS server connectivity
  - Database files
  - TOML configuration completeness
  - System resources (RAM, disk)
  - py-spy profiler availability
  - mimalloc memory allocator status
"""

from __future__ import annotations

from nexus_ai.core.msgspec_utils import msgspec_loads as _msgspec_loads
import os
import re
import socket
import sys
from pathlib import Path
from typing import Any

import ctypes

import anyio
import pendulum

try:
    import psutil
except ImportError:
    psutil = None  # type: ignore[assignment]


# ── ANSI colors ──────────────────────────────────────────────────────────────

_GREEN = "\033[92m"
_YELLOW = "\033[93m"
_RED = "\033[91m"
_CYAN = "\033[96m"
_BOLD = "\033[1m"
_RESET = "\033[0m"


def _ok(text: str) -> str:
    return f"{_GREEN}✓{_RESET} {text}"


def _warn(text: str) -> str:
    return f"{_YELLOW}⚠{_RESET} {text}"


def _fail(text: str) -> str:
    return f"{_RED}✗{_RESET} {text}"


def _info(text: str) -> str:
    return f"{_CYAN}{text}{_RESET}"


def _bold(text: str) -> str:
    return f"{_BOLD}{text}{_RESET}"


# ── Project paths ────────────────────────────────────────────────────────────

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_MODELS_DIR = _PROJECT_ROOT / "models"
_CODE_DIR = _PROJECT_ROOT / "nexus_ai"


# ── Checks ───────────────────────────────────────────────────────────────────


def check_python_version() -> str:
    py_ver = sys.version_info
    if py_ver.major >= 3 and py_ver.minor >= 11:
        return _ok(f"Python {py_ver.major}.{py_ver.minor}.{py_ver.micro} (>=3.11)")
    return _fail(f"Python {py_ver.major}.{py_ver.minor}.{py_ver.micro} (<3.11)")


def check_pyspy() -> str:
    """SUPERMOC py-spy: Sprawdź czy py-spy sampling profiler jest dostępny.

    py-spy to natywny profiler w Rust — podpina się do działającego procesu
    bez restartu, narzut <1%. Idealny do diagnostyki wydajności w produkcji.

    Sprawdza:
      - Czy py-spy jest zainstalowany w PATH
      - Wersję py-spy
      - Czy może próbkować obecny proces (self-attach)
    """
    try:
        from nexus_ai.scripts.profiler import check_pyspy_installed
        installed, version = check_pyspy_installed()
        if installed:
            # Spróbuj zrobić szybki self-dump (własny proces)
            try:
                import shutil
                pyspy = shutil.which("py-spy")
                if pyspy:
                    import subprocess as _sp
                    result = _sp.run(
                        [pyspy, "dump", "-p", str(os.getpid()), "--nonblocking"],
                        capture_output=True, text=True, timeout=5,
                    )
                    if result.returncode == 0:
                        return _ok(f"py-spy ACTIVE: {version}")
                    return _ok(f"py-spy installed: {version}")
            except Exception:
                pass
            return _ok(f"py-spy: {version}")
        return _warn(f"py-spy not installed: {version}")
    except ImportError:
        # Fallback: sprawdź bezpośrednio przez shutil
        import shutil
        pyspy = shutil.which("py-spy")
        if pyspy:
            return _ok(f"py-spy binary found at: {pyspy}")
        return _info("py-spy: run pixi install --environment dev (py-spy>=0.3.0)")


def check_system() -> str:
    """SUPERMOC psutil: Pełny audyt systemu — CPU, RAM, swap, dysk, sieć, sensory, boot.

    Używa:
      - virtual_memory() → RAM z available/buffers/cached
      - swap_memory() → swap usage + sin/sout
      - cpu_freq() → częstotliwość CPU
      - cpu_count(logical=False/True) → fizyczne/logiczne rdzenie
      - getloadavg() → load average (1/5/15 min)
      - disk_usage('/') → użycie dysku
      - disk_io_counters(perdisk=True) → I/O per dysk
      - net_io_counters(pernic=True) → I/O per interfejs
      - sensors_temperatures() → temperatury CPU/GPU
      - sensors_fans() → wentylatory
      - boot_time() → czas od boota
      - users() → aktywni użytkownicy
    """
    if psutil is None:
        return _warn("psutil not installed — skipping system resource checks")

    lines: list[str] = [
        _ok(f"Platform: {sys.platform}"),
    ]

    # ── CPU ────────────────────────────────────────────────────────────
    cpu_count_phys = psutil.cpu_count(logical=False) or psutil.cpu_count() or 1
    cpu_count_log = psutil.cpu_count() or cpu_count_phys
    cpu_freq_data = psutil.cpu_freq(percpu=False)
    load_avg = psutil.getloadavg()
    cpu_pct = psutil.cpu_percent(interval=0.1)

    freq_str = ""
    if cpu_freq_data:
        freq_str = f" @ {cpu_freq_data.current:.0f} MHz (min={cpu_freq_data.min:.0f}, max={cpu_freq_data.max:.0f})"
    lines.append(_ok(
        f"CPU: {cpu_count_phys} physical / {cpu_count_log} logical cores{freq_str}"
    ))
    lines.append(_ok(
        f"CPU Usage: {cpu_pct:.1f}% | Load Avg: {load_avg[0]:.2f} / {load_avg[1]:.2f} / {load_avg[2]:.2f}"
    ))

    # ── RAM ────────────────────────────────────────────────────────────
    ram = psutil.virtual_memory()
    buffers_str = f""
    cached_str = f""
    if hasattr(ram, "buffers") and ram.buffers:
        buffers_str = f" buffers={ram.buffers/1024**3:.1f}GB"
    if hasattr(ram, "cached") and ram.cached:
        cached_str = f" cached={ram.cached/1024**3:.1f}GB"
    lines.append(_ok(
        f"RAM: {ram.available/1024**3:.1f} GB / {ram.total/1024**3:.1f} GB "
        f"({ram.percent:.0f}% used){buffers_str}{cached_str}"
    ))

    # ── SWAP ───────────────────────────────────────────────────────────
    swap = psutil.swap_memory()
    sin_str = f""
    sout_str = f""
    if hasattr(swap, "sin") and swap.sin:
        sin_str = f" IN={swap.sin/1024**3:.1f}GB"
    if hasattr(swap, "sout") and swap.sout:
        sout_str = f" OUT={swap.sout/1024**3:.1f}GB"
    lines.append(_ok(
        f"SWAP: {swap.used/1024**3:.1f} GB / {swap.total/1024**3:.1f} GB ({swap.percent:.0f}%){sin_str}{sout_str}"
    ))

    # ── DISK ───────────────────────────────────────────────────────────
    disk = psutil.disk_usage("/")
    lines.append(_ok(
        f"Disk: {disk.free/1024**3:.1f} GB / {disk.total/1024**3:.1f} GB free ({disk.percent:.0f}% used)"
    ))

    # SUPERMOC: disk_io_counters(perdisk=True) — I/O per dysk
    try:
        disk_io = psutil.disk_io_counters(perdisk=True)
        if disk_io:
            for dev, io in sorted(disk_io.items())[:3]:
                lines.append(_ok(
                    f"  {dev}: R={io.read_bytes/1024**2:.1f}MB W={io.write_bytes/1024**2:.1f}MB "
                    f"({io.read_count} reads, {io.write_count} writes)"
                ))
            if len(disk_io) > 3:
                lines.append(_info(f"  ... and {len(disk_io)-3} more devices"))
    except Exception:
        pass

    # ── NETWORK ─────────────────────────────────────────────────────────
    try:
        net_io = psutil.net_io_counters(pernic=True)
        if net_io:
            for iface, io in sorted(net_io.items()):
                if io.bytes_sent > 0 or io.bytes_recv > 0:
                    lines.append(_ok(
                        f"  {iface}: TX={io.bytes_sent/1024**2:.1f}MB RX={io.bytes_recv/1024**2:.1f}MB "
                        f"(errors: {io.errin+io.errout})"
                    ))
                    break
            if len(net_io) > 1:
                total_sent = sum(io.bytes_sent for io in net_io.values())
                total_recv = sum(io.bytes_recv for io in net_io.values())
                lines.append(_ok(f"  Total: TX={total_sent/1024**2:.1f}MB RX={total_recv/1024**2:.1f}MB"))
    except Exception:
        pass

    # ── SENSORS ─────────────────────────────────────────────────────────
    try:
        temps = psutil.sensors_temperatures()
        if temps:
            for name, entries in sorted(temps.items())[:2]:
                for entry in entries:
                    marker = _warn if entry.current > 80 else _ok
                    lines.append(marker(f"{name}: {entry.current:.1f}°C (high={entry.high}, critical={entry.critical})"))
    except (NotImplementedError, AttributeError, OSError):
        pass

    try:
        fans = psutil.sensors_fans()
        if fans:
            for name, entries in sorted(fans.items()):
                for entry in entries[:2]:
                    lines.append(_ok(f"Fan {name}: {entry.current} RPM"))
    except (NotImplementedError, AttributeError, OSError):
        pass

    # ── SYSTEM INFO ─────────────────────────────────────────────────────
    try:
        boot = psutil.boot_time()
        import time as _time
        uptime_days = (_time.time() - boot) / 86400
        lines.append(_ok(f"Uptime: {uptime_days:.1f} days (since {pendulum.from_timestamp(boot).format('YYYY-MM-DD HH:mm')})"))
    except Exception:
        pass

    try:
        users = psutil.users()
        if users:
            lines.append(_ok(f"Active users: {', '.join(u.name for u in users[:3])}"))
            if len(users) > 3:
                lines.append(_info(f"  ... and {len(users)-3} more"))
    except Exception:
        pass

    try:
        conns = psutil.net_connections(kind="inet")
        if conns:
            established = sum(1 for c in conns if c.status == "ESTABLISHED")
            listening = sum(1 for c in conns if c.status == "LISTEN")
            lines.append(_ok(f"Network: {established} established, {listening} listening connections"))
    except (psutil.AccessDenied, NotImplementedError, OSError):
        pass

    return "\n".join(lines)


async def check_gpu() -> str:
    """Check CUDA / GPU availability via nvidia-smi."""
    try:
        result = await anyio.run_process(["nvidia-smi", "-L"], timeout=10)
        res = result.stdout.decode()
        gpu_count = res.strip().count("GPU ")
        if gpu_count > 0:
            name_match = re.search(r"GPU \d+: ([^(]+)", res)
            gpu_name = name_match.group(1).strip() if name_match else "NVIDIA"
            return _ok(f"CUDA available: {gpu_count}x {gpu_name}")
    except (TimeoutError, FileNotFoundError):
        pass
    return _warn("No CUDA GPU detected — running on CPU (slower for AI models)")


def check_models() -> str:
    """Check GGUF model files presence."""
    if not _MODELS_DIR.exists():
        return _fail(f"Models directory not found at {_MODELS_DIR}")

    gguf_files = list(_MODELS_DIR.rglob("*.gguf"))
    lines: list[str] = []

    if gguf_files:
        total_mb = sum(f.stat().st_size for f in gguf_files) / (1024 * 1024)
        lines.append(f"  {_ok(f'{len(gguf_files)} GGUF model(s) found ({total_mb:.0f} MB total)')}")
        for f in gguf_files[:5]:
            size_mb = f.stat().st_size / (1024 * 1024)
            lines.append(f"    {_ok(f.name):40s} {size_mb:.0f} MB")
        if len(gguf_files) > 5:
            lines.append(f"    ... and {len(gguf_files) - 5} more")
    else:
        lines.append(f"  {_warn('No GGUF model files found. Place .gguf files in models/')}")

    try:
        import doctr
        doctr_version = getattr(doctr, "__version__", "installed")
        lines.append(f"  {_ok(f'docTR {doctr_version} — modular OCR engine (DBNet + PARSeq)')}")
    except ImportError:
        lines.append(f"  {_info('docTR: run pixi install (python-doctr>=0.9.0)')}")

    return "\n".join(lines)


def check_nats() -> str:
    """Check NATS server connectivity."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2.0)
        result = s.connect_ex(("127.0.0.1", 4222))
        s.close()
        if result == 0:
            return _ok("NATS server is running on localhost:4222")
        else:
            return _warn(
                "NATS server not detected on localhost:4222 — start with: nats-server -p 4222 -js"
            )
    except Exception as exc:
        return _fail(f"NATS check failed: {exc}")


def check_env() -> str:
    """Check environment configuration."""
    required_vars = ["NEXUS_JWT_SECRET", "NEXUS_ENCRYPTION_KEY"]
    lines: list[str] = []

    env = os.environ.get("NEXUS_ENV", "dev")
    if env == "prod":
        missing = [v for v in required_vars if not os.environ.get(v)]
        if missing:
            missing_str = ", ".join(missing)
            lines.append(f"  {_fail(f'PROD: Missing required env vars: {missing_str}')}")
        else:
            lines.append(f"  {_ok('PROD: Required security env vars set')}")
    else:
        lines.append(f"  {_ok(f'Environment: {env} (security vars optional)')}")

    config_dir = _PROJECT_ROOT / "config"
    config_file = config_dir / f"{env}.toml"
    if config_file.exists():
        lines.append(f"  {_ok(f'TOML config found: config/{env}.toml')}")
    else:
        lines.append(f"  {_warn(f'TOML config not found: config/{env}.toml — using defaults')}")

    try:
        import doctr
        lines.append(f"  {_ok('docTR available — DBNet + PARSeq engine')}")
    except ImportError:
        lines.append(f"  {_info('docTR not installed — run pixi install')}")

    return "\n".join(lines)


def check_database() -> str:
    """Check database files."""
    oltp_db = _PROJECT_ROOT / "nexus_oltp.db"
    olap_db = _PROJECT_ROOT / "nexus_olap.duckdb"

    lines: list[str] = []
    if oltp_db.exists():
        size_mb = oltp_db.stat().st_size / (1024 * 1024)
        lines.append(f"  {_ok(f'OLTP DB (SQLite): {size_mb:.1f} MB')}")
    else:
        lines.append(f"  {_warn('OLTP DB not found — will be created on first run')}")

    if olap_db.exists():
        size_mb = olap_db.stat().st_size / (1024 * 1024)
        lines.append(f"  {_ok(f'OLAP DB (DuckDB): {size_mb:.1f} MB')}")
    else:
        lines.append(f"  {_warn('OLAP DB not found — will be created on first run')}")

    return "\n".join(lines)


# ── Main runner ──────────────────────────────────────────────────────────────


def check_mimalloc() -> str:
    """Check if mimalloc is the active memory allocator with live stats."""
    try:
        lib = ctypes.CDLL(None)
        lib.mi_malloc  # type: ignore[attr-defined]

        lines: list[str] = []

        try:
            from nexus_ai.core.mimalloc_bridge import stats_as_dict
            stats = stats_as_dict()
            rss = stats.get("process_rss_bytes")
            if rss is not None:
                rss_mb = rss / (1024 * 1024)
                lines.append(f"    {_ok(f'RSS: {rss_mb:.1f} MB')}")
        except (ImportError, Exception):
            lines.append(f"    {_info('Live stats: bridge not available')}")

        lines.append(f"  {_bold('Config:')}")
        env_vars = {
            "MIMALLOC_LARGE_OS_PAGES": "Huge OS pages",
            "MIMALLOC_RESERVE_HUGE_OS_PAGES": "Reserve huge pages",
            "MIMALLOC_EAGER_COMMIT_DELAY": "Eager commit delay",
            "MIMALLOC_PAGE_RESET": "Page reset",
            "MIMALLOC_PURGE_DELAY": "Purge delay",
        }
        for var, desc in env_vars.items():
            val = os.environ.get(var, "0")
            marker = _ok if val == "1" else _info
            lines.append(f"    {marker(f'{desc} ({var}={val})')}")

        return (
            _ok("mimalloc ACTIVE — Microsoft allocator") + "\n"
            + "  " + "\n  ".join(lines)
        )
    except (OSError, AttributeError):
        return _warn(
            "mimalloc NOT ACTIVE — using system allocator (glibc malloc)\n"
            "    Fix: Ensure LD_PRELOAD includes libmimalloc.so or\n"
            "    run: pixi install (if mimalloc is in system deps)"
        )


async def run_diagnostics() -> dict[str, Any]:
    """Run all diagnostics and print results.

    Returns a dict of check_name -> result string for programmatic use.
    """
    print()
    print(f"  {_bold('╔══════════════════════════════════════════════════╗')}")
    print(f"  {_bold('║        NEXUSAI SYSTEM DIAGNOSTICS              ║')}")
    print(f"  {_bold('╚══════════════════════════════════════════════════╝')}")
    print()

    checks: dict[str, str] = {
        "Python": check_python_version(),
        "Profiler": check_pyspy(),
        "mimalloc": check_mimalloc(),
        "System": check_system(),
        "GPU": await check_gpu(),
        "Models": check_models(),
        "NATS": check_nats(),
        "Environment": check_env(),
        "Database": check_database(),
    }

    for name, result in checks.items():
        print(f"  {_bold(f'── {name}')} ")
        for line in result.split("\n"):
            if line.strip():
                print(f"  {line}")
        print()

    # ── Summary ──────────────────────────────────────────────────────────
    print(f"  {_bold('── Summary')}")

    pass_count = 0
    warn_count = 0
    fail_count = 0
    for result in checks.values():
        first_line = result.split("\n")[0]
        if _GREEN in first_line:
            pass_count += 1
        elif _YELLOW in first_line:
            warn_count += 1
        elif _RED in first_line:
            fail_count += 1

    if fail_count == 0:
        print(f"  {_ok(f'{pass_count} passed, {warn_count} warnings')}")
    else:
        print(f"  {_fail(f'{pass_count} passed, {warn_count} warnings, {fail_count} FAILED')}")

    print(f"  {_info('Tip: Run python -m nexus_ai.scripts.profiler --check to verify py-spy')}")
    print(f"  {_info('Tip: Run python -m nexus_ai.scripts.profiler --pid $(pgrep nexus-api) to profile API')}")
    print(f"  {_info('Tip: Run nats-server -p 4222 -js to start NATS')}")
    print()

    return checks


# ── SUPERMOC Loguru: logger.parse() — analiza logow ─────────────────────


def parse_logs(log_path: str | Path | None = None) -> dict[str, Any]:
    """SUPERMOC Loguru: Analiza plikow logow za pomoca logger.parse()."""
    from loguru import logger as _loguru_logger
    from collections import Counter

    if log_path is None:
        log_dir = _PROJECT_ROOT / "app_data/logs"
        json_logs = sorted(log_dir.glob("*_json.log*")) if log_dir.exists() else []
        text_logs = sorted(log_dir.glob("nexusai.log*")) if log_dir.exists() else []

        if json_logs:
            log_path = json_logs[-1]
        elif text_logs:
            log_path = text_logs[-1]
        else:
            log_path = log_dir / "nexusai.log"

    log_file = Path(str(log_path))
    if not log_file.exists():
        return {"error": f"Log file not found: {log_file}", "total": 0}

    stats: dict[str, Any] = {
        "file": str(log_file),
        "size_bytes": log_file.stat().st_size,
        "total": 0,
        "levels": {},
        "top_errors": [],
        "top_warnings": [],
        "top_loggers": [],
        "time_range": None,
    }

    level_count: Counter[str] = Counter()
    error_msgs: Counter[str] = Counter()
    warning_msgs: Counter[str] = Counter()
    logger_names: Counter[str] = Counter()
    timestamps: list[str] = []

    try:
        with open(log_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    record = _msgspec_loads(line)
                    stats["total"] += 1
                    level = record.get("level", "UNKNOWN")
                    level_count[level] += 1
                    msg = record.get("message", "")
                    logger_name = record.get("logger", record.get("module", "unknown"))
                    logger_names[logger_name] += 1
                    ts = record.get("timestamp", "")
                    if ts:
                        timestamps.append(ts)
                    if level in ("ERROR", "CRITICAL"):
                        error_msgs[msg[:100]] += 1
                    elif level == "WARNING":
                        warning_msgs[msg[:100]] += 1
                except Exception:
                    pass
    except Exception:
        pass

    if stats["total"] == 0:
        try:
            pattern = r"(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| (?P<level>\w+) \| (?P<message>.*)"
            cast = {"time": str, "level": str, "message": str}
            parsed = _loguru_logger.parse(str(log_file), pattern, cast=cast)
            for record in parsed:
                stats["total"] += 1
                level_count[record.get("level", "UNKNOWN")] += 1
                if "time" in record:
                    timestamps.append(record["time"])
        except Exception as exc:
            stats["parse_error"] = str(exc)

    stats["levels"] = dict(level_count.most_common())
    stats["top_loggers"] = [
        {"name": name, "count": count}
        for name, count in logger_names.most_common(10)
    ]
    stats["top_errors"] = [
        {"message": msg, "count": count}
        for msg, count in error_msgs.most_common(10)
    ]
    stats["top_warnings"] = [
        {"message": msg, "count": count}
        for msg, count in warning_msgs.most_common(10)
    ]
    if timestamps:
        stats["time_range"] = {
            "first": min(timestamps),
            "last": max(timestamps),
        }

    return stats


def print_log_stats(stats: dict[str, Any]) -> None:
    """Wyswietl statystyki logow z ANSI kolorowaniem."""
    print()
    print(f"  {_bold('Log Analysis')}")
    print(f"  {_info('───────────────────────────────────────────')}")

    if "error" in stats:
        print(f"  {_fail(stats['error'])}")
        return

    print(f"  {_ok('File:')} {stats['file']}")
    size_mb = stats['size_bytes'] / (1024 * 1024)
    print(f"  {_ok('Size:')} {size_mb:.2f} MB")
    print(f"  {_ok('Total:')} {stats['total']} log records")

    if stats['time_range']:
        print(f"  {_ok('From:')} {stats['time_range']['first']}")
        print(f"  {_ok('To:')}   {stats['time_range']['last']}")

    if stats['levels']:
        print(f"\n  {_bold('Level Distribution')}")
        for level, count in stats['levels'].items():
            if level in ("ERROR", "CRITICAL"):
                marker = _fail
            elif level == "WARNING":
                marker = _warn
            else:
                marker = _ok
            pct = count / max(stats['total'], 1) * 100
            bar = "#" * int(pct / 5) + "-" * (20 - int(pct / 5))
            print(f"    {marker(f'{level:10s}')} {count:6d} ({pct:5.1f}%) |{bar}|")

    if stats['top_errors']:
        print(f"\n  {_bold('Top Errors')}")
        for i, err in enumerate(stats['top_errors'][:5], 1):
            count = err.get("count", "?")
            print(f"    {_fail(f'{i}. [{count}x]')} {err['message'][:80]}")

    if stats['top_warnings']:
        print(f"\n  {_bold('Top Warnings')}")
        for i, warn in enumerate(stats['top_warnings'][:5], 1):
            count = warn.get("count", "?")
            print(f"    {_warn(f'{i}. [{count}x]')} {warn['message'][:80]}")

    if stats['top_loggers']:
        print(f"\n  {_bold('Top Loggers')}")
        for entry in stats['top_loggers'][:5]:
            print(f"    {_ok(entry['name']):50s} {entry['count']:6d} calls")

    print()


if __name__ == "__main__":
    if "--parse-logs" in sys.argv:
        log_path = None
        idx = sys.argv.index("--parse-logs")
        if idx + 1 < len(sys.argv) and not sys.argv[idx + 1].startswith("--"):
            log_path = sys.argv[idx + 1]
        stats = parse_logs(log_path)
        print_log_stats(stats)
    else:
        anyio.run(run_diagnostics)
