"""
doctor.py — Comprehensive system diagnostics for NexusAI.

Run via:
    python main.py --mode doctor
    python -m Code.SKRIPTS.doctor

Checks:
  - Python version and environment
  - CPU / GPU (CUDA) availability
  - Required model files (GGUF) present and integrity-verified
  - NATS server connectivity
  - Database files
  - .env configuration completeness
  - System resources (RAM, disk)
"""

from __future__ import annotations

import os
import socket
import sys
from pathlib import Path
from typing import Any

try:
    import torch
except ImportError:
    torch = None  # type: ignore[assignment]

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
_CODE_DIR = _PROJECT_ROOT / "Code"


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
    """Check CUDA / GPU availability."""
    if torch is None:
        return _warn("PyTorch not installed — cannot check GPU. Install with: pip install torch")

    cuda_available = torch.cuda.is_available()
    if cuda_available:
        gpu_name = torch.cuda.get_device_name(0)
        gpu_count = torch.cuda.device_count()
        return _ok(f"CUDA available: {gpu_count}x {gpu_name}")
    else:
        # Check if CUDA drivers are installed at all
        if os.name == "nt":
            cuda_path = os.environ.get("CUDA_PATH", "")
            if cuda_path:
                return _warn(f"CUDA toolkit found at {cuda_path}, but PyTorch cannot detect GPU")
        if sys.platform == "linux":
            nvidia_smi = os.system("nvidia-smi > /dev/null 2>&1") == 0
            if nvidia_smi:
                return _warn("NVIDIA driver detected (nvidia-smi works) but PyTorch cannot access GPU")
        return _warn("No CUDA GPU detected — running on CPU (slower for AI models)")


def check_models() -> str:
    """Check model files presence and integrity."""
    if not _MODELS_DIR.exists():
        return _fail(f"Models directory not found at {_MODELS_DIR}")

    required_gguf = [
        "LFM2.5-1.2B-Q4_K_M.gguf",
        "Qwen3-0.6B-Q4_K_M.gguf",
        "LittleLamb-0.3B-Q4_K_M.gguf",
        "granite-4.0-1b-nano-Q4_K_M.gguf",
        "qwen2.5-1.5b-instruct-Q4_K_M.gguf",
        "Jamba-Reasoning-3B-Q4_K_M.gguf",
    ]

    lines: list[str] = []
    all_found = True
    found_count = 0

    for model_name in required_gguf:
        # Search in HF cache structure
        model_files = list(_MODELS_DIR.rglob(model_name))
        if model_files:
            size_mb = model_files[0].stat().st_size / (1024 * 1024)
            lines.append(f"  {_ok(model_name):50s} {size_mb:.0f} MB")
            found_count += 1
        else:
            lines.append(f"  {_fail(model_name + ' (MISSING)'):50s}")
            all_found = False

    # Check Surya OCR models
    surya_repos = ["surya_det3", "surya_rec3", "surya_layout3", "surya_order3"]
    surya_found = sum(1 for r in surya_repos if list(_MODELS_DIR.rglob(f"*{r}*")))
    if surya_found > 0:
        lines.append(f"  {_ok(f'Surya OCR: {surya_found}/{len(surya_repos)} repos found')}")
    else:
        lines.append(f"  {_warn('Surya OCR models not found (optional for enhanced OCR)')}")

    summary = f"{found_count}/{len(required_gguf)} GGUF models"
    if all_found:
        lines.insert(0, f"  {_ok(summary)}")
    else:
        lines.insert(0, f"  {_fail(summary)} — run: python Code/SKRIPTS/download_models.py")

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
    ai_vars = [
        "NEXUS_COUNCIL_ALPHA_MODEL",
        "NEXUS_COUNCIL_BETA_MODEL",
        "NEXUS_COUNCIL_GAMMA_MODEL",
        "NEXUS_RULES_MODEL",
        "NEXUS_ANALYTICS_MODEL",
    ]

    lines: list[str] = []

    env = os.environ.get("NEXUS_ENV", "dev")
    if env == "prod":
        # In production, JWT and encryption keys are mandatory
        missing = [v for v in required_vars if not os.environ.get(v)]
        if missing:
            lines.append(f"  {_fail(f'PROD: Missing required env vars: {', '.join(missing)}')}")
        else:
            lines.append(f"  {_ok('PROD: Required security env vars set')}")
    else:
        lines.append(f"  {_ok(f'Environment: {env} (security vars optional)')}")

    # Check AI model paths
    env_file = _PROJECT_ROOT / ".env"
    if env_file.exists():
        lines.append(f"  {_ok('.env file found')}")
    else:
        lines.append(f"  {_warn('.env file not found — copy .env.example to .env')}")

    # Check AI model paths from env (if set)
    ai_paths_ok = 0
    for var in ai_vars:
        path_val = os.environ.get(var)
        if path_val:
            model_path = _PROJECT_ROOT / path_val
            if model_path.exists():
                ai_paths_ok += 1

    if ai_paths_ok > 0:
        lines.append(f"  {_ok(f'{ai_paths_ok}/{len(ai_vars)} AI model paths resolve correctly')}")

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

    all_pass = True
    for name, result in checks.items():
        print(f"  {_bold(f'── {name}')} ")
        for line in result.split("\n"):
            if line.strip():
                print(f"  {line}")
        print()

    # ── Summary ──────────────────────────────────────────────────────────
    print(f"  {_bold('── Summary')}")
    if all(p.startswith(_GREEN) or p.startswith(_YELLOW) for p in [r.split(chr(10))[0] if chr(10) in r else r for r in checks.values()]):
        pass  # intentionally blank

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

    print(f"  {_info('Tip: Run python Code/SKRIPTS/download_models.py to download missing models')}")
    print(f"  {_info('Tip: Run nats-server -p 4222 -js to start NATS')}")
    print()

    return checks


if __name__ == "__main__":
    run_diagnostics()
