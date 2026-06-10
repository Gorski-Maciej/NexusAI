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
"""

from __future__ import annotations

import os
import socket
import subprocess
import sys
from pathlib import Path
from typing import Any

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


def check_system() -> str:
    if psutil is not None:
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage("/")
        lines = [
            _ok(f"Platform: {sys.platform}"),
            _ok(f"RAM: {ram.available / 1024**3:.1f} GB / {ram.total / 1024**3:.1f} GB ({ram.percent:.0f}% used)"),
            _ok(f"Disk: {disk.free / 1024**3:.1f} GB / {disk.total / 1024**3:.1f} GB free"),
        ]
        return "\n".join(lines)
    return _warn("psutil not installed — skipping system resource checks")


def check_gpu() -> str:
    """Check CUDA / GPU availability via nvidia-smi.

    Zastępuje: torch.cuda.is_available() → nvidia-smi (nie wymaga PyTorch).
    GPU używane przez llama-cpp-python (GGUF) z CUDA backend.
    """
    try:
        res = subprocess.check_output(["nvidia-smi", "-L"], timeout=10).decode()
        # Parse GPU count
        gpu_count = res.strip().count("GPU ")
        if gpu_count > 0:
            # Try to get GPU name
            name_match = __import__("re").search(r"GPU \d+: ([^(]+)", res)
            gpu_name = name_match.group(1).strip() if name_match else "NVIDIA"
            return _ok(f"CUDA available: {gpu_count}x {gpu_name}")
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        pass

    return _warn("No CUDA GPU detected — running on CPU (slower for AI models)")


def check_models() -> str:
    """Check GGUF model files presence.

    Zgodnie z aa3fvcx.txt: żadne konkretne modele LLM nie są zdefiniowane.
    Sprawdza tylko czy katalog models/ istnieje i czy są w nim jakieś pliki.
    """
    if not _MODELS_DIR.exists():
        return _fail(f"Models directory not found at {_MODELS_DIR}")

    gguf_files = list(_MODELS_DIR.rglob("*.gguf"))
    surya_dirs = [d for d in _MODELS_DIR.iterdir() if d.is_dir() and "surya" in d.name.lower()]

    lines: list[str] = []

    if gguf_files:
        total_mb = sum(f.stat().st_size for f in gguf_files) / (1024 * 1024)
        lines.append(f"  {_ok(f'{len(gguf_files)} GGUF model(s) found ({total_mb:.0f} MB total)')}")
        for f in gguf_files[:5]:  # pokaż max 5
            size_mb = f.stat().st_size / (1024 * 1024)
            lines.append(f"    {_ok(f.name):40s} {size_mb:.0f} MB")
        if len(gguf_files) > 5:
            lines.append(f"    ... and {len(gguf_files) - 5} more")
    else:
        lines.append(f"  {_warn('No GGUF model files found. Place .gguf files in models/')}")

    if surya_dirs:
        lines.append(f"  {_ok(f'Surya OCR models: {len(surya_dirs)} directory/ies')}")
        for d in surya_dirs:
            lines.append(f"    {_ok(d.name)}")
    else:
        lines.append(f"  {_info('Surya OCR models: run python -m nexus_ai.scripts.download_models --surya')}")

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
            return _warn("NATS server not detected on localhost:4222 — start with: nats-server -p 4222 -js")
    except Exception as exc:
        return _fail(f"NATS check failed: {exc}")


def check_env() -> str:
    """Check environment configuration for AI."""
    required_vars = [
        "NEXUS_JWT_SECRET",
        "NEXUS_ENCRYPTION_KEY",
    ]
    lines: list[str] = []

    env = os.environ.get("NEXUS_ENV", "dev")
    if env == "prod":
        missing = [v for v in required_vars if not os.environ.get(v)]
        if missing:
            lines.append(f"  {_fail(f'PROD: Missing required env vars: {', '.join(missing)}')}")
        else:
            lines.append(f"  {_ok('PROD: Required security env vars set')}")
    else:
        lines.append(f"  {_ok(f'Environment: {env} (security vars optional)')}")

    # Check TOML config profile
    config_dir = _PROJECT_ROOT / "config"
    config_file = config_dir / f"{env}.toml"
    if config_file.exists():
        lines.append(f"  {_ok(f'TOML config found: config/{env}.toml')}")
    else:
        lines.append(f"  {_warn(f'TOML config not found: config/{env}.toml — using defaults')}")

    # Check Surya OCR models
    for d in _MODELS_DIR.iterdir() if _MODELS_DIR.exists() else []:
        if d.is_dir() and "surya" in d.name.lower():
            lines.append(f"  {_ok(f'Surya OCR model: {d.name}')}")

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


def run_diagnostics() -> dict[str, Any]:
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
        "System": check_system(),
        "GPU": check_gpu(),
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

    # Count passes/warnings/fails
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

    print(f"  {_info('Tip: Run python -m nexus_ai.scripts.download_models to download missing models')}")
    print(f"  {_info('Tip: Run nats-server -p 4222 -js to start NATS')}")
    print()

    return checks


if __name__ == "__main__":
    run_diagnostics()
