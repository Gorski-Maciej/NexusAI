"""Performance engineering runner for NexusAI.

Wraps k6 load tests and optionally exports JSON summaries that can be ingested
by telemetry pipelines.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def _run(cmd: list[str]) -> int:
    print("[perf]", " ".join(cmd))
    return subprocess.run(cmd, check=False).returncode


def run_k6(script: Path, base_url: str, token: str, vus: int, duration: str, out: Path) -> int:
    k6 = shutil.which("k6")
    if k6 is None:
        print("[perf] k6 binary not found in PATH", file=sys.stderr)
        return 2
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        k6,
        "run",
        str(script),
        "-e",
        f"BASE_URL={base_url}",
        "-e",
        f"TOKEN={token}",
        "-e",
        f"VUS={vus}",
        "-e",
        f"DURATION={duration}",
        "--summary-export",
        str(out),
    ]
    timeout_s = int(os.getenv("NEXUS_PERF_K6_TIMEOUT_SEC", "3600"))
    try:
        return subprocess.run(cmd, check=False, timeout=timeout_s).returncode
    except subprocess.TimeoutExpired:
        print(f"[perf] k6 command timeout after {timeout_s}s", file=sys.stderr)
        return 1


def _extract_metrics(summary_path: Path) -> dict[str, float]:
    data = json.loads(summary_path.read_text(encoding="utf-8"))
    metrics = data.get("metrics", {})
    http_req_duration = metrics.get("http_req_duration", {})
    checks = metrics.get("checks", {})
    rps = metrics.get("http_reqs", {})

    p95 = float(http_req_duration.get("values", {}).get("p(95)", 0.0))
    p99 = float(http_req_duration.get("values", {}).get("p(99)", 0.0))
    pass_rate = float(checks.get("values", {}).get("rate", 1.0))
    error_rate = max(0.0, 1.0 - pass_rate)
    req_rate = float(rps.get("values", {}).get("rate", 0.0))
    return {"p95": p95, "p99": p99, "error_rate": error_rate, "req_rate": req_rate}


def enforce_thresholds(summary_path: Path, max_p95_ms: float, max_error_rate: float, *, max_p99_ms: float | None = None, min_rps: float | None = None) -> int:
    if not summary_path.exists():
        print(f"[perf] summary file not found: {summary_path}", file=sys.stderr)
        return 1
    try:
        values = _extract_metrics(summary_path)
    except json.JSONDecodeError:
        print(f"[perf] invalid summary JSON: {summary_path}", file=sys.stderr)
        return 1

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
    (summary.parent / "perf_gate_summary.json").write_text(json.dumps(gate, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run load tests and enforce SLO thresholds.")
    parser.add_argument("--script", default="tests/performance/k6_invoice_upload.js")
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--vus", type=int, default=50)
    parser.add_argument("--duration", default="5m")
    parser.add_argument("--summary", default="reports/performance/k6_summary.json")
    parser.add_argument("--max-p95-ms", type=float, default=1200.0)
    parser.add_argument("--max-p99-ms", type=float, default=2000.0)
    parser.add_argument("--max-error-rate", type=float, default=0.02)
    parser.add_argument("--min-rps", type=float, default=5.0)
    args = parser.parse_args()

    summary = Path(args.summary)
    rc = run_k6(Path(args.script), args.base_url, args.token, args.vus, args.duration, summary)
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
