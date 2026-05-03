"""DAST/SAST orchestration helper for staging security checks.

Usage:
    python Code/SKRIPTS/security_scan.py --target http://localhost:8000 --mode baseline
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
    print("[security-scan]", " ".join(cmd))
    timeout_s = int(os.getenv("NEXUS_SECURITY_SCAN_TIMEOUT_SEC", "1800"))
    try:
        proc = subprocess.run(cmd, check=False, timeout=timeout_s)
        return proc.returncode
    except subprocess.TimeoutExpired:
        print(f"[security-scan] command timeout after {timeout_s}s", file=sys.stderr)
        return 1


def run_zap(target: str, mode: str, *, strict_tools: bool = False) -> int:
    zap = shutil.which("zap-baseline.py")
    if zap is None:
        print("[security-scan] zap-baseline.py not found in PATH", file=sys.stderr)
        return 1 if strict_tools else 2
    report = Path("reports")
    report.mkdir(parents=True, exist_ok=True)
    html = report / f"zap_{mode}.html"
    js = report / f"zap_{mode}.json"

    cmd = [zap, "-t", target, "-r", str(html), "-J", str(js)]
    if mode == "full":
        cmd.append("-a")
    return _run(cmd)


def run_semgrep(*, strict_tools: bool = False) -> int:
    semgrep = shutil.which("semgrep")
    if semgrep is None:
        print("[security-scan] semgrep not found in PATH", file=sys.stderr)
        return 1 if strict_tools else 2
    return _run([semgrep, "scan", "--config", "auto", "Code/"])


def run_codeql(*, strict_tools: bool = False) -> int:
    codeql = shutil.which("codeql")
    if codeql is None:
        print("[security-scan] codeql not found in PATH", file=sys.stderr)
        return 1 if strict_tools else 2
    report = Path("reports")
    report.mkdir(parents=True, exist_ok=True)
    sarif = report / "codeql.sarif"
    query_suite = "codeql/python-queries:codeql-suites/python-security-and-quality.qls"
    return _run([codeql, "database", "analyze", "--format=sarif-latest", f"--output={sarif}", "codeql-db", query_suite])




def _write_summary(*, zap_rc: int, semgrep_rc: int, codeql_rc: int, strict_tools: bool) -> None:
    report = Path("reports")
    report.mkdir(parents=True, exist_ok=True)
    payload = {
        "strict_tools": strict_tools,
        "zap_rc": zap_rc,
        "semgrep_rc": semgrep_rc,
        "codeql_rc": codeql_rc,
    }
    (report / "security_scan_summary.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run security checks (DAST + SAST).")
    parser.add_argument("--target", required=True, help="Staging API URL, e.g. http://localhost:8000")
    parser.add_argument("--mode", choices=["baseline", "full"], default="baseline")
    parser.add_argument("--skip-semgrep", action="store_true")
    parser.add_argument("--skip-zap", action="store_true")
    parser.add_argument("--run-codeql", action="store_true")
    parser.add_argument("--strict-tools", action="store_true", help="Fail when required scanner binaries are missing")
    args = parser.parse_args()

    zap_rc = 0 if args.skip_zap else run_zap(target=args.target, mode=args.mode, strict_tools=args.strict_tools)
    semgrep_rc = 0 if args.skip_semgrep else run_semgrep(strict_tools=args.strict_tools)
    codeql_rc = run_codeql(strict_tools=args.strict_tools) if args.run_codeql else 0

    _write_summary(zap_rc=zap_rc, semgrep_rc=semgrep_rc, codeql_rc=codeql_rc, strict_tools=args.strict_tools)

    if args.strict_tools:
        return 1 if zap_rc != 0 or semgrep_rc != 0 or codeql_rc != 0 else 0

    # Non-strict mode: code 2 means tool unavailable and is treated as warning.
    bad = [rc for rc in (zap_rc, semgrep_rc, codeql_rc) if rc not in (0, 2)]
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
