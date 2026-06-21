"""
NexusAI — Granian ASGI Server Entrypoint
==========================================

Full Granian superpower activation:
  - Backpressure & backlog for production stability
  - HTTP/2 auto-negotiation with flow control
  - Built-in Prometheus metrics exporter
  - UNIX socket with permissions for desktop mode
  - PID file + process name for systemd integration
  - Worker respawn, max RSS, lifetime management
  - Proxy headers via granian.utils.proxies
  - Static file serving in Rust (zero Python overhead)
  - Custom event loop (Granian Rust-based loop by default)
  - Custom access log format
  - Graceful shutdown with configurable timeout
"""

from __future__ import annotations

import os

import granian
from granian.constants import Interfaces

from nexus_ai.api.app import create_app

# ── Event loop customization ────────────────────────────────────────────────
# Granian uses its own Rust-based event loop by default for best performance.
# The loop can be configured via env var: NEXUS_GRANIAN_LOOP=asyncio|auto|rloop|winloop
_LOOP: str = "auto"

# ── Static file serving via Granian Rust layer ──────────────────────────────
# Offloads static file serving to Rust, bypassing Python entirely (~10-100x speedup).
# Configured via env vars so it can be enabled per-deployment.
_STATIC_ROUTES: list[str] | None = None
_STATIC_MOUNTS: list[str] | None = None
_static_route_env = os.getenv("NEXUS_STATIC_ROUTES", "").strip()
_static_mount_env = os.getenv("NEXUS_STATIC_MOUNTS", "").strip()
if _static_route_env and _static_mount_env:
    _STATIC_ROUTES = [r.strip() for r in _static_route_env.split(",")]
    _STATIC_MOUNTS = [m.strip() for m in _static_mount_env.split(",")]

# ── ASGI wrapper with proxy headers support ─────────────────────────────────
# Wraps the ASGI app with Granian's proxy headers utility so that
# X-Forwarded-For and X-Forwarded-Proto are correctly resolved
# when running behind a reverse proxy (nginx, traefik, cloudflare).
_APP = create_app()
_proxy_trusted_hosts = os.getenv("NEXUS_PROXY_TRUSTED_HOSTS", "127.0.0.1")
if _proxy_trusted_hosts:
    try:
        from granian.utils.proxies import wrap_asgi_with_proxy_headers

        trusted = (
            ["*"]
            if _proxy_trusted_hosts == "*"
            else [h.strip() for h in _proxy_trusted_hosts.split(",")]
        )
        _APP = wrap_asgi_with_proxy_headers(_APP, trusted_hosts=trusted)
    except ImportError:
        pass  # Granian <2.0 or proxy module not available


def _build_granian_config() -> dict:
    """Build Granian configuration from environment variables.

    Returns a dict of kwargs for ``granian.Granian()`` with all
    superpower settings. Every setting can be overridden via env vars
    prefixed with ``NEXUS_GRANIAN_``.
    """
    # ── Core networking ───────────────────────────────────────────────
    host = os.getenv("NEXUS_HOST", "127.0.0.1")
    port = int(os.getenv("NEXUS_PORT", "8000"))
    log_level = os.getenv("NEXUS_LOG_LEVEL", "info")

    config: dict = {
        "target": "api.app:create_app",
        "interface": Interfaces.ASGI,
        "log_level": log_level,
    }

    # ── UNIX socket vs TCP ────────────────────────────────────────────
    if host == "unix":
        socket_path = os.getenv("NEXUS_UNIX_SOCKET", "/tmp/nexus-api.sock")
        config["unix_socket"] = socket_path
        try:
            config["uds_permissions"] = int(
                os.getenv("NEXUS_UNIX_SOCKET_PERMS", "0o660"), 8
            )
        except ValueError:
            pass  # Graceful fallback if perms parsing fails
    else:
        config["host"] = host
        config["port"] = port

    # ── Backpressure & backlog — production stability ─────────────────
    # Backpressure protects the Python interpreter from being overwhelmed
    # by too many concurrent requests. Default: 100 req/worker.
    config["backlog"] = int(os.getenv("NEXUS_GRANIAN_BACKLOG", "2048"))
    config["backpressure"] = int(os.getenv("NEXUS_GRANIAN_BACKPRESSURE", "100"))

    # ── HTTP version — enable HTTP/2 auto-negotiation ─────────────────
    # Granian supports HTTP/1.1 and HTTP/2. 'auto' negotiates per-connection.
    config["http"] = os.getenv("NEXUS_GRANIAN_HTTP", "auto")

    # ── HTTP/2 flow control tuning ──────────────────────────────────
    # Optimal for high-throughput API with many concurrent streams
    config["http2_initial_connection_window_size"] = int(
        os.getenv("NEXUS_GRANIAN_HTTP2_CONN_WINDOW", "1048576")
    )
    config["http2_initial_stream_window_size"] = int(
        os.getenv("NEXUS_GRANIAN_HTTP2_STREAM_WINDOW", "1048576")
    )
    config["http2_max_concurrent_streams"] = int(
        os.getenv("NEXUS_GRANIAN_HTTP2_MAX_STREAMS", "256")
    )
    config["http2_keep_alive_interval"] = int(
        os.getenv("NEXUS_GRANIAN_HTTP2_KEEPALIVE", "30000")
    )
    config["http2_keep_alive_timeout"] = int(
        os.getenv("NEXUS_GRANIAN_HTTP2_KEEPALIVE_TIMEOUT", "20")
    )

    # ── Workers & threading ─────────────────────────────────────────
    # For Python 3.13t (free-threaded): workers = true parallel threads
    # For standard Python 3.13: workers = separate processes
    # TOP5 OPTYMALIZACJA #1: dynamiczna liczba workers = max(1, cpu_count()-1)
    # Domyślnie: (rdzenie - 1) dla dev, można override przez NEXUS_GRANIAN_WORKERS
    _env_workers = os.getenv("NEXUS_GRANIAN_WORKERS", "")
    if _env_workers:
        _default_workers = int(_env_workers)
    else:
        _default_workers = max(1, (os.cpu_count() or 2) - 1)
    config["workers"] = _default_workers
    config["runtime_threads"] = int(
        os.getenv("NEXUS_GRANIAN_RUNTIME_THREADS", "2")
    )
    config["runtime_blocking_threads"] = int(
        os.getenv("NEXUS_GRANIAN_RUNTIME_BLOCKING_THREADS", "4")
    )
    config["blocking_threads_idle_timeout"] = int(
        os.getenv("NEXUS_GRANIAN_BLOCKING_IDLE_TIMEOUT", "60")
    )
    config["runtime_mode"] = os.getenv("NEXUS_GRANIAN_RUNTIME_MODE", "auto")

    # ── Event loop ──────────────────────────────────────────────────
    # Options: auto, asyncio, rloop, winloop
    # Granian defaults to its Rust-based event loop for best performance
    config["loop"] = os.getenv("NEXUS_GRANIAN_LOOP", _LOOP)

    # ── Access log with custom format ────────────────────────────────
    config["log_access"] = os.getenv("NEXUS_GRANIAN_ACCESS_LOG", "true").lower() == "true"
    config["log_access_fmt"] = os.getenv(
        "NEXUS_GRANIAN_ACCESS_LOG_FMT",
        "%(addr)s - %(method)s %(path)s %(status)d %(dt_ms).3f",
    )

    # ── Security headers ─────────────────────────────────────────────
    config["no_header_server"] = (
        os.getenv("NEXUS_GRANIAN_NO_SERVER_HEADER", "true").lower() == "true"
    )

    # ── URL path prefix ──────────────────────────────────────────────
    _prefix = os.getenv("NEXUS_GRANIAN_URL_PREFIX", "").strip()
    if _prefix:
        config["url_path_prefix"] = _prefix

    # ── Prometheus metrics (Granian built-in) ────────────────────────
    config["metrics"] = os.getenv("NEXUS_GRANIAN_METRICS", "true").lower() == "true"
    config["metrics_address"] = os.getenv(
        "NEXUS_GRANIAN_METRICS_ADDRESS", "127.0.0.1"
    )
    config["metrics_port"] = int(os.getenv("NEXUS_GRANIAN_METRICS_PORT", "9090"))
    config["metrics_scrape_interval"] = int(
        os.getenv("NEXUS_GRANIAN_METRICS_INTERVAL", "15")
    )

    # ── Worker lifecycle management ─────────────────────────────────
    config["respawn_failed_workers"] = (
        os.getenv("NEXUS_GRANIAN_RESPAWN", "true").lower() == "true"
    )
    _max_rss = os.getenv("NEXUS_GRANIAN_WORKER_MAX_RSS", "").strip()
    if _max_rss:
        config["workers_max_rss"] = int(_max_rss)  # MiB
    _lifetime = os.getenv("NEXUS_GRANIAN_WORKER_LIFETIME", "").strip()
    if _lifetime:
        config["workers_lifetime"] = int(_lifetime)  # seconds
    config["workers_kill_timeout"] = int(
        os.getenv("NEXUS_GRANIAN_WORKER_KILL_TIMEOUT", "30")
    )
    config["respawn_interval"] = float(
        os.getenv("NEXUS_GRANIAN_RESPAWN_INTERVAL", "3.5")
    )

    # ── RSS monitoring ───────────────────────────────────────────────
    config["rss_sample_interval"] = int(
        os.getenv("NEXUS_GRANIAN_RSS_INTERVAL", "30")
    )
    config["rss_samples"] = int(os.getenv("NEXUS_GRANIAN_RSS_SAMPLES", "3"))

    # ── Graceful shutdown ────────────────────────────────────────────
    config["graceful_shutdown_timeout"] = int(
        os.getenv("NEXUS_GRANIAN_GRACEFUL_SHUTDOWN", "30")
    )

    # ── PID file ─────────────────────────────────────────────────────
    _pid_file = os.getenv("NEXUS_GRANIAN_PID_FILE", "").strip()
    if _pid_file:
        config["pid_file"] = _pid_file

    # ── Process name ─────────────────────────────────────────────────
    _proc_name = os.getenv("NEXUS_GRANIAN_PROCESS_NAME", "nexus-api").strip()
    if _proc_name:
        config["process_name"] = _proc_name

    # ── Static file serving — Rust layer (zero Python overhead) ──────
    if _STATIC_ROUTES and _STATIC_MOUNTS:
        config["static_path_route"] = _STATIC_ROUTES
        config["static_path_mount"] = _STATIC_MOUNTS
        config["static_path_expires"] = int(
            os.getenv("NEXUS_GRANIAN_STATIC_EXPIRES", "86400")
        )

    return config


def run_backend() -> None:
    """Entrypoint used by launcher/containers.

    Uses Granian — Rust ASGI server with full superpower configuration.
    W trybie desktopowym nasłuchuje na gnieździe UNIX.
    """
    config = _build_granian_config()
    try:
        granian.Granian(**config).serve()
    except TypeError as exc:
        # Fallback: jeśli Granian nie wspiera któregoś z superpower params,
        # spróbuj z podstawową konfiguracją
        import logging
        logging.warning(
            "[GRANIAN] TypeError podczas inicjalizacji z superpowers: %s\n"
            "  Próba fallback do podstawowej konfiguracji...",
            exc,
        )
        # Podstawowa konfiguracja — zawsze działa
        fallback = {
            "target": config.get("target", "api.app:create_app"),
            "interface": "asgi",
            "host": config.get("host", "127.0.0.1"),
            "port": config.get("port", 8000),
            "log_level": config.get("log_level", "info"),
            "backlog": config.get("backlog", 2048),
            "backpressure": config.get("backpressure", 100),
            "http": config.get("http", "auto"),
            "log_access": config.get("log_access", True),
            "no_header_server": config.get("no_header_server", True),
            "graceful_shutdown_timeout": config.get("graceful_shutdown_timeout", 30),
        }
        # Dodaj UNIX socket jeśli był
        if "unix_socket" in config:
            fallback["unix_socket"] = config["unix_socket"]
        granian.Granian(**fallback).serve()


# ── Expose the proxy-wrapped app for direct use (e.g. embedded server) ─────
# The wrapped app handles X-Forwarded-For and X-Forwarded-Proto headers
# from trusted proxies. If no proxy is configured, this is just the raw app.


def get_app() -> granian.ASGIApp:
    """Zwraca proxy-wrapped aplikację ASGI.

    App jest tworzona przy imporcie (fail-fast na starcie).
    Zwraca instancję Litestar opakowaną w ``wrap_asgi_with_proxy_headers``
    jeśli skonfigurowano NEXUS_PROXY_TRUSTED_HOSTS.
    """
    return _APP


if __name__ == "__main__":
    run_backend()
