"""Performance engineering runner for NexusAI.

Wraps locust load tests and optionally exports JSON summaries that can be ingested
by telemetry pipelines.

Zgodnie z aa3fvcx.txt: locust zastępuje k6 — testy wydajności w Pythonie
zamiast JavaScript, używając tych samych bibliotek (httpx, msgspec) co aplikacja.
"""
from __future__ import annotations

import argparse
import csv
import os
import shutil
import subprocess
import sys
from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps


def _run(cmd: list[str]) -> int:
    print("[perf]", " ".join(cmd))
    return subprocess.run(cmd, check=False).returncode


def run_locust(script: Path, base_url: str, token: str, vus: int, duration: str, out: Path) -> int:
    """Run locust load test and export JSON summary.

    Zgodnie z aa3fvcx.txt: locust zastępuje k6.
    locust jest w Pythonie — scenariusze testowe używają httpx + msgspec.
    """
    locust = shutil.which("locust")
    if locust is None:
        print("[perf] locust binary not found in PATH", file=sys.stderr)
        return 2
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        locust,
        "-f",
        str(script),
        "--host",
        base_url,
        "--headless",
        "-u",
        str(vus),
        "-r",
        str(max(1, vus // 10)),
        "-t",
        duration,
        "--json",
        "--html",
        str(out.with_suffix(".html")),
        "--csv",
        str(out.with_suffix("")),
    ]
    if token:
        cmd.extend(["-e", f"TOKEN={token}"])
    timeout_s = int(os.getenv("NEXUS_PERF_LOCUST_TIMEOUT_SEC", "3600"))
    try:
        return subprocess.run(cmd, check=False, timeout=timeout_s).returncode
    except subprocess.TimeoutExpired:
        print(f"[perf] locust command timeout after {timeout_s}s", file=sys.stderr)
        return 1


def _parse_locust_csv(summary_path: Path) -> dict[str, float]:
    """Parse locust CSV stats and extract p95, p99, error rate, RPS."""
    csv_path = summary_path.with_suffix("_stats.csv")
    if not csv_path.exists():
        return {"p95": 0.0, "p99": 0.0, "error_rate": 1.0, "req_rate": 0.0}
    p95_vals = []
    p99_vals = []
    errors = 0
    total = 0
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            name = row.get("Name", "")
            if not name or name == "Total":
                continue
            try:
                if row.get("95%_ms"):
                    p95_vals.append(float(row["95%_ms"]))
                if row.get("99%_ms"):
                    p99_vals.append(float(row["99%_ms"]))
                errors += int(row.get("Failures", 0))
                total += int(row.get("Requests", 0))
            except (ValueError, KeyError):
                pass
    error_rate = errors / max(total, 1)
    avg_p95 = max(p95_vals) if p95_vals else 0.0
    avg_p99 = max(p99_vals) if p99_vals else 0.0
    return {"p95": avg_p95, "p99": avg_p99, "error_rate": error_rate, "req_rate": 0.0}


def enforce_thresholds(summary_path: Path, max_p95_ms: float, max_error_rate: float, *, max_p99_ms: float | None = None, min_rps: float | None = None) -> int:
    if not summary_path.exists():
        print(f"[perf] summary file not found: {summary_path}", file=sys.stderr)
        return 1
    values = _parse_locust_csv(summary_path)

    print(
        f"[perf] p95={values['p95']:.2f} ms, p99={values['p99']:.2f} ms, "
        f"error_rate={values['error_rate']:.4f}, req_rate={values['req_rate']:.2f}/s"
    )

    if values["p95"] > max_p95_ms or values["error_rate"] > max_error_rate:
        print("[perf] thresholds breached", file=sys.stderr)
        return 1
    if max_p99_ms is not None and values["p99"] > max_p99_ms:
        print("[perf] p99 threshold breached", file=sys.stderr)
        return 1
    if min_rps is not None and values["req_rate"] < min_rps:
        print("[perf] throughput threshold breached", file=sys.stderr)
        return 1
    return 0


def _write_gate_summary(*, rc: int, summary: Path, max_p95_ms: float, max_error_rate: float, max_p99_ms: float | None, min_rps: float | None) -> None:
    summary.parent.mkdir(parents=True, exist_ok=True)
    gate = {
        "exit_code": rc,
        "summary_path": str(summary),
        "max_p95_ms": max_p95_ms,
        "max_error_rate": max_error_rate,
        "max_p99_ms": max_p99_ms,
        "min_rps": min_rps,
    }
    (summary.parent / "perf_gate_summary.json").write_text(msgspec_dumps(gate, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run load tests (locust) and enforce SLO thresholds.")
    parser.add_argument("--script", default="tests/performance/locustfile.py")
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--token", default="")
    parser.add_argument("--vus", type=int, default=50)
    parser.add_argument("--duration", default="5m")
    parser.add_argument("--summary", default="reports/performance/locust_stats")
    parser.add_argument("--max-p95-ms", type=float, default=1200.0)
    parser.add_argument("--max-p99-ms", type=float, default=2000.0)
    parser.add_argument("--max-error-rate", type=float, default=0.02)
    parser.add_argument("--min-rps", type=float, default=5.0)
    args = parser.parse_args()

    summary = Path(args.summary)
    rc = run_locust(Path(args.script), args.base_url, args.token, args.vus, args.duration, summary)
    if rc not in (0, 2):
        _write_gate_summary(rc=rc, summary=summary, max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate, max_p99_ms=args.max_p99_ms, min_rps=args.min_rps)
        return rc
    if rc == 2:
        _write_gate_summary(rc=0, summary=summary, max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate, max_p99_ms=args.max_p99_ms, min_rps=args.min_rps)
        return 0

    gate_rc = enforce_thresholds(summary, args.max_p95_ms, args.max_error_rate, max_p99_ms=args.max_p99_ms, min_rps=args.min_rps)
    _write_gate_summary(rc=gate_rc, summary=summary, max_p95_ms=args.max_p95_ms, max_error_rate=args.max_error_rate, max_p99_ms=args.max_p99_ms, min_rps=args.min_rps)
    return gate_rc


if __name__ == "__main__":
    raise SystemExit(main())
