"""DAST/SAST orchestration helper for staging security checks.

Usage:
    python Code/SKRIPTS/security_scan.py --target http://localhost:8000 --mode baseline
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def _run(cmd: list[str]) -> int:
    print("[security-scan]", " ".join(cmd))
    proc = subprocess.run(cmd, check=False)
    return proc.returncode


def run_zap(target: str, mode: str) -> int:
    zap = shutil.which("zap-baseline.py")
    if zap is None:
        print("[security-scan] zap-baseline.py not found in PATH", file=sys.stderr)
        return 2
    report = Path("reports")
    report.mkdir(parents=True, exist_ok=True)
    html = report / f"zap_{mode}.html"
    json = report / f"zap_{mode}.json"

    cmd = [zap, "-t", target, "-r", str(html), "-J", str(json)]
    if mode == "full":
        cmd.append("-a")
    return _run(cmd)


def run_semgrep() -> int:
    semgrep = shutil.which("semgrep")
    if semgrep is None:
        print("[security-scan] semgrep not found in PATH", file=sys.stderr)
        return 2
    return _run([semgrep, "scan", "--config", "auto", "Code/"])


def run_codeql() -> int:
    codeql = shutil.which("codeql")
    if codeql is None:
        print("[security-scan] codeql not found in PATH", file=sys.stderr)
        return 2
    report = Path("reports")
    report.mkdir(parents=True, exist_ok=True)
    sarif = report / "codeql.sarif"
    query_suite = "codeql/python-queries:codeql-suites/python-security-and-quality.qls"
    return _run([codeql, "database", "analyze", "--format=sarif-latest", f"--output={sarif}", "codeql-db", query_suite])


def main() -> int:
    parser = argparse.ArgumentParser(description="Run security checks (DAST + SAST).")
    parser.add_argument("--target", required=True, help="Staging API URL, e.g. http://localhost:8000")
    parser.add_argument("--mode", choices=["baseline", "full"], default="baseline")
    parser.add_argument("--skip-semgrep", action="store_true")
    parser.add_argument("--skip-zap", action="store_true")
    parser.add_argument("--run-codeql", action="store_true")
    args = parser.parse_args()

    zap_rc = 0 if args.skip_zap else run_zap(target=args.target, mode=args.mode)
    semgrep_rc = 0 if args.skip_semgrep else run_semgrep()
    codeql_rc = run_codeql() if args.run_codeql else 0
    return 1 if zap_rc not in (0, 2) or semgrep_rc not in (0, 2) or codeql_rc not in (0, 2) else 0


if __name__ == "__main__":
    raise SystemExit(main())
