"""
Performance engineering runner for NexusAI (SUPERMOC LOCUST EDITION)
=====================================================================

Zgodnie z aa3fvcx.txt: locust zastępuje k6 — testy wydajności w Pythonie
zamiast JavaScript, używając tych samych bibliotek (httpx, msgspec) co aplikacja.

SUPERMOCE:
  - FastHttpUser (geventhttpclient) — 3-5× więcej RPS
  - SequentialTaskSet — ścisła kolejność operacji biznesowych
  - LoadTestShape — customowe profile obciążenia
  - Web UI mode (--web) — obserwacja na żywo
  - Distributed mode (--master/--worker) — skalowanie na wiele maszyn
  - OTel integration — metryki do DuckDB/Parquet
  - Threshold enforcement — SLO validation
  - Regression detection (optional — calls detection script)
  - Gateway summary JSON — dla CI/CD

Usage:
    # Headless (CI/CD):
    python -m nexus_ai.scripts.performance_engineering \\
        --script tests/performance/locustfile.py \\
        --base-url http://localhost:8000 \\
        --vus 50 --duration 5m

    # Headless z threshold tolerance:
    python -m nexus_ai.scripts.performance_engineering \\
        --max-p95-ms 1500 --max-p99-ms 3000

    # Z web UI (debugging):
    python -m nexus_ai.scripts.performance_engineering \\
        --web --port 8089

    # Distributed mode (master):
    python -m nexus_ai.scripts.performance_engineering \\
        --master --expect-workers 4

    # Distributed mode (worker):
    python -m nexus_ai.scripts.performance_engineering \\
        --worker --master-host 10.0.0.1

    # Z custom shape:
    LOCUST_SHAPE=NexusSpikeShape \\
    python -m nexus_ai.scripts.performance_engineering \\
        --vus 1000 --duration 10m

    # OTel integration:
    python -m nexus_ai.scripts.performance_engineering \\
        --otel
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Any

import anyio

from nexus_ai.core.msgspec_utils import msgspec_dumps


REPORTS_DIR = Path("reports") / "performance"


async def _run(cmd: list[str]) -> int:
    print("[perf]", " ".join(cmd))
    result = await anyio.run_process(cmd)
    return result.returncode


async def run_locust(
    *,
    script: Path,
    base_url: str,
    token: str,
    vus: int,
    duration: str,
    out: Path,
    spawn_rate: int | None = None,
    shape_class: str | None = None,
    web: bool = False,
    web_host: str = "127.0.0.1",
    web_port: int = 8089,
    master: bool = False,
    worker: bool = False,
    master_host: str = "127.0.0.1",
    expect_workers: int = 0,
    otel: bool = False,
) -> int:
    """SUPERMOC: Uruchom locust load test z pełną konfiguracją.

    Args:
        script: Ścieżka do pliku locustfile.py
        base_url: Bazowy URL aplikacji
        token: Token autoryzacyjny (opcjonalnie)
        vus: Liczba wirtualnych użytkowników
        duration: Czas trwania (np. "5m", "30s", "1h")
        out: Prefiks dla plików wyjściowych (CSV, HTML, JSON)
        spawn_rate: Szybkość spawnu użytkowników/sekundę
        shape_class: Klasa LoadTestShape do użycia
        web: Tryb web UI (zamiast headless)
        web_host: Host dla web UI
        web_port: Port dla web UI
        master: Tryb master dla distributed mode
        worker: Tryb worker dla distributed mode
        master_host: Host mastera (dla workerów)
        expect_workers: Oczekiwana liczba workerów (master)
        otel: Włącz integrację z OpenTelemetry

    Returns:
        Exit code: 0=success, 1=threshold breach, 2=locust not found
    """
    locust = shutil.which("locust")
    if locust is None:
        print("[perf] ❌ locust binary not found in PATH", file=sys.stderr)
        print("[perf]   Install: pixi install --environment dev", file=sys.stderr)
        print("[perf]   Or: pip install locust", file=sys.stderr)
        return 2

    out.parent.mkdir(parents=True, exist_ok=True)

    # SUPERMOC: Budowanie komendy locust
    cmd = [
        locust,
        "-f",
        str(script),
        "--host",
        base_url,
    ]

    # Tryb: web UI vs headless
    if web:
        cmd.extend(["--web-host", web_host, "--web-port", str(web_port)])
        print(f"[perf] 🌐 Web UI: http://{web_host}:{web_port}")
    else:
        cmd.append("--headless")

    # SUPERMOC: Distributed mode
    if master:
        cmd.append("--master")
        if expect_workers > 0:
            cmd.extend(["--expect-workers", str(expect_workers)])
        print(f"[perf] 🔗 Distributed mode: MASTER (expecting {expect_workers} workers)")
    elif worker:
        cmd.extend(["--worker", "--master-host", master_host])
        print(f"[perf] 🔗 Distributed mode: WORKER (master at {master_host})")

    # SUPERMOC: Użytkownicy i czas
    if not web or master:
        cmd.extend(["-u", str(vus)])
        cmd.extend(["-r", str(spawn_rate or max(1, vus // 10))])
        cmd.extend(["-t", duration])

    # SUPERMOC: Custom shape
    if shape_class:
        cmd.extend(["--shape", shape_class])

    # SUPERMOC: Token autoryzacyjny
    if token:
        cmd.extend(["-e", f"TOKEN={token}"])

    # SUPERMOC: Wyjście — wiele formatów
    cmd.extend(["--json", str(out.with_suffix(".json"))])
    cmd.extend(["--html", str(out.with_suffix(".html"))])
    cmd.extend(["--csv", str(out.with_suffix("").with_suffix(""))])

    # SUPERMOC: OTel integration
    otel_env = {**os.environ}
    if otel:
        otel_env["LOCUST_OTEL_ENABLED"] = "1"
        print("[perf] 📊 OpenTelemetry integration enabled")

    # SUPERMOC: py-spy profiling integration — profiluj proces locust w tle
    pyspy_enabled = os.getenv("NEXUS_PERF_PYSPY_ENABLED", "").lower() in ("1", "true")
    pyspy_task: anyio.Event | None = None
    pyspy_output_path: Path | None = None

    if pyspy_enabled and not web:
        try:
            from nexus_ai.scripts.profiler import (
                profile_subprocess, ProfilerConfig, OutputFormat,
                _find_pyspy, check_pyspy_installed,
            )
            installed, _ = check_pyspy_installed()
            if installed:
                pyspy_duration = int(os.getenv("NEXUS_PERF_PYSPY_DURATION", "60"))
                pyspy_rate = int(os.getenv("NEXUS_PERF_PYSPY_RATE", "500"))
                pyspy_native = os.getenv("NEXUS_PERF_PYSPY_NATIVE", "").lower() in ("1", "true")
                output_dir = Path(out.parent) / "profiles"
                output_dir.mkdir(parents=True, exist_ok=True)
                pyspy_output_path = output_dir / f"locust_profile_{pyspy_duration}s.svg"
                print(f"[perf] 🔥 py-spy profiling enabled: {pyspy_duration}s @ {pyspy_rate} samples/sec -> {pyspy_output_path}")
            else:
                print("[perf] ⚠️ py-spy binary not found — skipping profiling")
                pyspy_enabled = False
        except ImportError:
            print("[perf] ⚠️ py-spy profiler module not found — skipping profiling")
            pyspy_enabled = False

    # SUPERMOC: Czas wykonania z timeout
    timeout_s = int(os.getenv("NEXUS_PERF_LOCUST_TIMEOUT_SEC", "3600"))

    # Uruchom locust z opcjonalnym profilem py-spy w tle
    try:
        if pyspy_enabled and pyspy_output_path is not None:
            # Uruchom locust z py-spy record jako wrapperem
            pyspy = _find_pyspy()
            if pyspy:
                pyspy_wrapper_cmd = [
                    pyspy, "record",
                    "-d", str(pyspy_duration),
                    "-r", str(pyspy_rate),
                    "-o", str(pyspy_output_path),
                    "--format", "svg",
                ]
                if pyspy_native:
                    pyspy_wrapper_cmd.append("--native")
                # py-spy record -d 60 -o profile.svg -- locust ...
                full_cmd = pyspy_wrapper_cmd + ["--"] + cmd
                result = await anyio.run_process(full_cmd, env=otel_env, timeout=timeout_s)
                print(f"[perf] 🔥 py-spy profile saved: {pyspy_output_path}")
            else:
                result = await anyio.run_process(cmd, env=otel_env, timeout=timeout_s)
        else:
            result = await anyio.run_process(cmd, env=otel_env, timeout=timeout_s)

        if result.returncode != 0:
            print(f"[perf] ❌ locust exited with code {result.returncode}")
        return result.returncode
    except TimeoutError:
        print(f"[perf] ⏰ locust timeout after {timeout_s}s", file=sys.stderr)
        return 1


def _parse_locust_csv(summary_prefix: Path) -> dict[str, float]:
    """SUPERMOC: Parsuj statystyki locust z CSV i ekstraktuj p95, p99, error rate, RPS.

    Locust CSV zawiera kolumny:
      - Type, Name, Request Count, Failure Count, Median Response Time,
        Average Response Time, Min, Max, Average Size, Requests/s,
        50%, 66%, 75%, 80%, 90%, 95%, 98%, 99%, 99.9%, 99.99%, 100%

    Args:
        summary_prefix: Prefiks pliku CSV (locust --csv <prefix>)

    Returns:
        Dykt z p95, p99, error_rate, req_rate
    """
    csv_path = summary_prefix.with_suffix("").with_suffix("_stats.csv")
    if not csv_path.exists():
        return {"p95": 0.0, "p99": 0.0, "error_rate": 1.0, "req_rate": 0.0}

    p95_vals: list[float] = []
    p99_vals: list[float] = []
    avg_vals: list[float] = []
    rps_vals: list[float] = []
    errors = 0
    total = 0

    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            name = row.get("Name", "")
            if not name or name == "Total":
                continue
            try:
                if row.get("95%"):
                    p95_vals.append(float(row["95%"]))
                if row.get("99%"):
                    p99_vals.append(float(row["99%"]))
                if row.get("Requests/s"):
                    rps_vals.append(float(row["Requests/s"]))
                if row.get("Average Response Time"):
                    avg_vals.append(float(row["Average Response Time"]))
                errors += int(row.get("Failure Count", 0))
                total += int(row.get("Request Count", 0))
            except (ValueError, KeyError):
                pass

    error_rate = errors / max(total, 1)
    avg_p95 = max(p95_vals) if p95_vals else 0.0
    avg_p99 = max(p99_vals) if p99_vals else 0.0
    avg_rps = sum(rps_vals) if rps_vals else 0.0
    avg_avg = sum(avg_vals) / len(avg_vals) if avg_vals else 0.0

    return {
        "p95": avg_p95,
        "p99": avg_p99,
        "error_rate": error_rate,
        "req_rate": avg_rps,
        "avg_response_time_ms": avg_avg,
        "total_requests": total,
        "total_failures": errors,
    }


def _parse_locust_json(summary_prefix: Path) -> dict[str, float]:
    """SUPERMOC: Parsuj statystyki locust z JSON jeśli CSV niedostępny."""
    json_paths = [
        summary_prefix.with_suffix(".json"),
        Path("reports") / "performance" / "locust_stats.json",
    ]

    json_stats = None

    for jp in json_paths:
        if jp.exists():
            try:
                data = json.loads(jp.read_text(encoding="utf-8"))
                metrics = data.get("metrics", {})
                if metrics:
                    json_stats = data
                    break
            except (json.JSONDecodeError, OSError):
                continue

    if json_stats:
        req_duration = (json_stats.get("metrics", {}).get("http_req_duration") or {}).get("values", {})
        reqs = (json_stats.get("metrics", {}).get("http_reqs") or {}).get("values", {})
        checks = (json_stats.get("metrics", {}).get("checks") or {}).get("values", {})

        return {
            "p95": float(req_duration.get("p(95)", 0)),
            "p99": float(req_duration.get("p(99)", 0)),
            "error_rate": 1.0 - float(checks.get("rate", 1.0)),
            "req_rate": float(reqs.get("rate", 0)),
            "avg_response_time_ms": float(req_duration.get("avg", 0)),
            "total_requests": int(reqs.get("count", 0)),
            "total_failures": int(checks.get("fails", 0)),
        }

    return {"p95": 0.0, "p99": 0.0, "error_rate": 1.0, "req_rate": 0.0}


def enforce_thresholds(
    summary_prefix: Path,
    max_p95_ms: float,
    max_error_rate: float,
    *,
    max_p99_ms: float | None = None,
    min_rps: float | None = None,
) -> int:
    """SUPERMOC: Sprawdź czy wyniki locust mieszczą się w SLO threshold.

    Args:
        summary_prefix: Prefiks plików locust (CSV lub JSON)
        max_p95_ms: Maksymalny dopuszczalny p95 (ms)
        max_error_rate: Maksymalny dopuszczalny error rate
        max_p99_ms: Maksymalny dopuszczalny p99 (ms)
        min_rps: Minimalny dopuszczalny RPS

    Returns:
        0 = OK, 1 = threshold breach
    """
    summary_path = Path(str(summary_prefix) + "_stats.csv")
    if not summary_path.exists():
        # Próbuj JSON
        values = _parse_locust_json(summary_prefix)
        if values["req_rate"] == 0.0 and values["p95"] == 0.0:
            print(f"[perf] ❌ locust output not found: {summary_path}", file=sys.stderr)
            return 1
    else:
        values = _parse_locust_csv(summary_prefix)

    print(
        f"[perf] 📊 p95={values['p95']:.2f}ms, "
        f"p99={values['p99']:.2f}ms, "
        f"avg={values.get('avg_response_time_ms', 0.0):.2f}ms, "
        f"error_rate={values['error_rate']:.4f}, "
        f"req_rate={values['req_rate']:.2f}/s, "
        f"requests={values.get('total_requests', 0)}, "
        f"failures={values.get('total_failures', 0)}"
    )

    breached = False

    if values["p95"] > max_p95_ms:
        print(
            f"[perf] 🔴 p95 threshold breached: "
            f"{values['p95']:.2f}ms > {max_p95_ms:.2f}ms",
            file=sys.stderr,
        )
        breached = True

    if values["error_rate"] > max_error_rate:
        print(
            f"[perf] 🔴 error rate threshold breached: "
            f"{values['error_rate']:.4f} > {max_error_rate:.4f}",
            file=sys.stderr,
        )
        breached = True

    if max_p99_ms is not None and values["p99"] > max_p99_ms:
        print(
            f"[perf] 🔴 p99 threshold breached: "
            f"{values['p99']:.2f}ms > {max_p99_ms:.2f}ms",
            file=sys.stderr,
        )
        breached = True

    if min_rps is not None and values["req_rate"] < min_rps:
        print(
            f"[perf] 🔴 throughput threshold breached: "
            f"{values['req_rate']:.2f}/s < {min_rps:.2f}/s",
            file=sys.stderr,
        )
        breached = True

    return 1 if breached else 0


def _write_gate_summary(
    rc: int,
    summary_prefix: Path,
    max_p95_ms: float,
    max_error_rate: float,
    max_p99_ms: float | None,
    min_rps: float | None,
    values: dict[str, float] | None = None,
) -> None:
    """SUPERMOC: Zapisz podsumowanie testu do JSON dla CI/CD."""
    summary_path = Path(str(summary_prefix) + "_stats.csv")
    gate = {
        "exit_code": rc,
        "summary_path": str(summary_path),
        "max_p95_ms": max_p95_ms,
        "max_error_rate": max_error_rate,
        "max_p99_ms": max_p99_ms,
        "min_rps": min_rps,
    }
    if values:
        gate["actual_p95_ms"] = values.get("p95")
        gate["actual_p99_ms"] = values.get("p99")
        gate["actual_error_rate"] = values.get("error_rate")
        gate["actual_rps"] = values.get("req_rate")
        gate["total_requests"] = values.get("total_requests")
        gate["total_failures"] = values.get("total_failures")

    gate_path = REPORTS_DIR / "perf_gate_summary.json"
    gate_path.parent.mkdir(parents=True, exist_ok=True)
    gate_path.write_text(
        msgspec_dumps(gate, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"[perf] 📋 Gate summary: {gate_path}")


async def main() -> int:
    """SUPERMOC: Główna funkcja CLI dla performance engineering.

    Returns:
        0 = success, 1 = threshold breach, 2 = locust not found
    """
    parser = argparse.ArgumentParser(
        description="NexusAI — Load Testing Runner (Locust SUPERMOC Edition)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
SUPERMOCE:
  --web              Tryb web UI (http://127.0.0.1:8089)
  --shape            Custom LoadTestShape
  --master/--worker  Distributed mode
  --otel             OpenTelemetry integration
  --regression       Performance regression detection

Przykłady:
  %(prog)s --base-url http://localhost:8000 --vus 50
  %(prog)s --web --port 8089
  %(prog)s --master --expect-workers 4
  LOCUST_SHAPE=NexusSpikeShape %(prog)s --vus 1000
        """,
    )

    # Lokalizacja
    parser.add_argument("--script", default="tests/performance/locustfile.py",
                        help="Path to locustfile.py (default: tests/performance/locustfile.py)")
    parser.add_argument("--base-url", required=False,
                        default=os.getenv("LOCUST_HOST", "http://localhost:8000"),
                        help="Base URL for load tests (default: $LOCUST_HOST or http://localhost:8000)")

    # Autoryzacja
    parser.add_argument("--token", default=os.getenv("TOKEN", ""),
                        help="Auth token (default: $TOKEN)")

    # Użytkownicy
    parser.add_argument("--vus", type=int, default=50,
                        help="Number of virtual users (default: 50)")
    parser.add_argument("--spawn-rate", type=int, default=None,
                        help="Spawn rate (default: vus/10)")
    parser.add_argument("--duration", default="5m",
                        help="Test duration (default: 5m)")

    # Wyjście
    parser.add_argument("--summary", default="reports/performance/locust_stats",
                        help="Output prefix for locust stats (default: reports/performance/locust_stats)")

    # Thresholds
    parser.add_argument("--max-p95-ms", type=float, default=1200.0,
                        help="Max p95 latency in ms (default: 1200)")
    parser.add_argument("--max-p99-ms", type=float, default=2000.0,
                        help="Max p99 latency in ms (default: 2000)")
    parser.add_argument("--max-error-rate", type=float, default=0.02,
                        help="Max error rate (default: 0.02)")
    parser.add_argument("--min-rps", type=float, default=5.0,
                        help="Min requests per second (default: 5.0)")

    # SUPERMOC: Web UI mode
    parser.add_argument("--web", action="store_true",
                        help="Run with web UI instead of headless")
    parser.add_argument("--port", type=int, default=8089,
                        help="Web UI port (default: 8089)")

    # SUPERMOC: Distributed mode
    parser.add_argument("--master", action="store_true",
                        help="Run as master (distributed mode)")
    parser.add_argument("--worker", action="store_true",
                        help="Run as worker (distributed mode)")
    parser.add_argument("--master-host", default="127.0.0.1",
                        help="Master host for workers (default: 127.0.0.1)")
    parser.add_argument("--expect-workers", type=int, default=0,
                        help="Expected number of workers (default: 0)")

    # SUPERMOC: Custom shape
    parser.add_argument("--shape", default=os.getenv("LOCUST_SHAPE", ""),
                        help="LoadTestShape class name (default: $LOCUST_SHAPE)")

    # SUPERMOC: OTel integration
    parser.add_argument("--otel", action="store_true",
                        help="Enable OpenTelemetry metrics export")

    # SUPERMOC: Regression detection
    parser.add_argument("--regression", action="store_true",
                        help="Check performance regression after test")

    args = parser.parse_args()

    # SUPERMOC: Ustaw zmienne środowiskowe dla locustfile.py
    os.environ.setdefault("LOCUST_HOST", args.base_url)
    if args.token:
        os.environ.setdefault("TOKEN", args.token)
    if args.shape:
        os.environ.setdefault("LOCUST_SHAPE", args.shape)

    summary = Path(args.summary)

    # SUPERMOC: Uruchom locust
    rc = await run_locust(
        script=Path(args.script),
        base_url=args.base_url,
        token=args.token,
        vus=args.vus,
        duration=args.duration,
        out=summary,
        spawn_rate=args.spawn_rate,
        shape_class=args.shape,
        web=args.web,
        web_port=args.port,
        master=args.master,
        worker=args.worker,
        master_host=args.master_host,
        expect_workers=args.expect_workers,
        otel=args.otel,
    )

    # SUPERMOC: Jeśli locust nie znaleziony → warning, nie błąd
    if rc == 2:
        print("[perf] ⚠️ locust not found — skipping threshold check")
        _write_gate_summary(
            rc=0, summary_prefix=summary,
            max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate,
            max_p99_ms=args.max_p99_ms, min_rps=args.min_rps,
        )
        return 0

    # SUPERMOC: Jeśli locust zwrócił błąd → zapisz gate z błędem
    if rc not in (0, 2):
        _write_gate_summary(
            rc=rc, summary_prefix=summary,
            max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate,
            max_p99_ms=args.max_p99_ms, min_rps=args.min_rps,
        )
        return rc

    # SUPERMOC: Sprawdź threshold tylko jeśli nie web UI (headless)
    if not args.web and not args.master:
        gate_rc = enforce_thresholds(
            summary,
            args.max_p95_ms,
            args.max_error_rate,
            max_p99_ms=args.max_p99_ms,
            min_rps=args.min_rps,
        )

        # SUPERMOC: Pobierz wartości dla gate summary
        csv_path = Path(str(args.summary) + "_stats.csv")
        if csv_path.exists():
            values = _parse_locust_csv(summary)
        else:
            values = _parse_locust_json(summary)

        _write_gate_summary(
            rc=gate_rc, summary_prefix=summary,
            max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate,
            max_p99_ms=args.max_p99_ms, min_rps=args.min_rps,
            values=values,
        )

        # SUPERMOC: Regression detection
        if args.regression and gate_rc == 0:
            try:
                from tests.performance.scripts.regression_detection import (
                    get_latest_locust_metrics,
                    get_historical_benchmarks,
                    detect_regression,
                )
                current = get_latest_locust_metrics()
                historical = get_historical_benchmarks()
                if current and historical:
                    regression = detect_regression(current, historical)
                    if regression.get("regression_detected"):
                        print("[perf] 🔴 Performance regression detected!")
                        for alert in regression.get("alerts", []):
                            print(f"[perf]   ⚠️  {alert}")
            except ImportError:
                print("[perf] ⚠️ Regression detection script not available")

        # SUPERMOC: Eksport do DuckDB
        if args.otel:
            try:
                from tests.performance.otel_locust_integration import export_locust_stats_to_duckdb
                export_locust_stats_to_duckdb()
            except ImportError:
                pass

        return gate_rc

    # Web UI lub master — bez threshold check
    _write_gate_summary(
        rc=0, summary_prefix=summary,
        max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate,
        max_p99_ms=args.max_p99_ms, min_rps=args.min_rps,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(anyio.run(main))
