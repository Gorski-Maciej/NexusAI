"""
flaky_test_detector.py — Automated Flaky Test Detection for CI.

Enterprise v7.0 Innowacja 4: CI automatycznie wykrywa flaky testy:
  - Test fail → retry 3x → jeśli 2+/3 pass → "flaky"
  - Dashboard z historią flaky testów
  - Automatyczny Issue gdy test jest flaky >3 razy

Usage:
    python nexus_ai/services/flaky_test_detector.py --pytest-args="-x"
"""

from __future__ import annotations

import json
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.flaky.detector")

FLAKY_DB_PATH = Path("app_data/flaky_tests.json")


@dataclass
class FlakyResult:
    """Result of a single test run analysis."""

    test_name: str
    file_path: str
    attempts: int
    results: list[str]  # ["PASS", "FAIL", "PASS"]
    is_flaky: bool
    is_consistently_failing: bool
    duration_ms: float


@dataclass
class FlakyHistory:
    """Persistent history of flaky tests."""

    test_name: str
    file_path: str
    flaky_count: int = 0
    last_seen: str = ""
    last_flaky_at: list[str] = field(default_factory=list)

    @property
    def needs_issue(self) -> bool:
        return self.flaky_count >= 3


class FlakyTestDetector:
    """Detect flaky tests by running failed tests multiple times.

    Enterprise v7.0 Innowacja 4:
      - Retries failed tests up to 3 times
      - Classifies as "flaky" if 2+/3 pass
      - Classifies as "consistently failing" if all 3 fail
      - Persists history to JSON for dashboard
      - Flags tests needing GitHub Issues (flaky >3 times)
    """

    def __init__(
        self,
        max_retries: int = 3,
        flaky_threshold: int = 2,
        history_path: Path = FLAKY_DB_PATH,
    ) -> None:
        self.max_retries = max_retries
        self.flaky_threshold = flaky_threshold  # need this many passes out of retries
        self.history_path = history_path
        self.history_path.parent.mkdir(parents=True, exist_ok=True)
        self._history_cache: dict[str, FlakyHistory] = {}

    def analyze_failures(
        self, pytest_args: list[str] | None = None,
    ) -> list[FlakyResult]:
        """Run tests, retry failures, classify flaky tests."""
        args = pytest_args or ["-q", "--tb=no"]
        results: list[FlakyResult] = []

        # First pass: collect all results — use unique tempfile to avoid race conditions
        import os as _os2
        import tempfile as _tmp
        _report_fd, _report_path = _tmp.mkstemp(suffix=".json", prefix="pytest_report_")
        _os2.close(_report_fd)  # Close fd immediately, pytest writes to path
        first_results = self._run_pytest(args + ["--json-report", f"--json-report-file={_report_path}"])
        failed_tests = self._parse_failures()

        if not failed_tests:
            logger.info("[FLAKY] No test failures detected")
            return results

        logger.info("[FLAKY] %d test(s) failed — retrying up to %d times", len(failed_tests), self.max_retries)

        for test_name, file_path in failed_tests:
            attempts = ["FAIL"]
            start = time.monotonic()

            for attempt in range(self.max_retries):
                retry_args = [file_path + "::" + test_name, "-q", "--tb=no"]
                exit_code, _ = self._run_pytest_raw(retry_args)
                attempts.append("PASS" if exit_code == 0 else "FAIL")

            duration = (time.monotonic() - start) * 1000
            passes = attempts.count("PASS")
            is_flaky = passes >= self.flaky_threshold
            is_consistently_failing = passes == 0

            result = FlakyResult(
                test_name=test_name,
                file_path=file_path,
                attempts=len(attempts),
                results=attempts,
                is_flaky=is_flaky,
                is_consistently_failing=is_consistently_failing,
                duration_ms=duration,
            )
            results.append(result)
            self._update_history(test_name, file_path, is_flaky)

        self._save_history()
        return results

    def _run_pytest(self, args: list[str]) -> tuple[int, str]:
        """Run pytest and return exit code + output."""
        try:
            result = subprocess.run(
                [sys.executable, "-m", "pytest"] + args,
                capture_output=True, text=True, timeout=600,
            )
            return result.returncode, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return -1, "Timeout"

    def _run_pytest_raw(self, args: list[str]) -> tuple[int, str]:
        try:
            result = subprocess.run(
                [sys.executable, "-m", "pytest"] + args,
                capture_output=True, text=True, timeout=120,
            )
            return result.returncode, result.stdout
        except subprocess.TimeoutExpired:
            return -1, "Timeout"

    def _parse_failures(self) -> list[tuple[str, str]]:
        """Parse pytest JSON report for failed tests.
        
        NOTE: Uses the most recent temp report file created by analyze_failures.
        If pytest-json-report is not installed, falls back to empty list.
        """
        import glob as _glob
        import os as _os
        reports = sorted(
            _glob.glob("/tmp/pytest_report_*.json"),
            key=_os.path.getmtime, reverse=True,
        )
        if not reports:
            return []
        report_path = Path(reports[0])
        try:
            data = json.loads(report_path.read_text())
            failures: list[tuple[str, str]] = []
            for test in data.get("tests", []):
                if test.get("outcome") == "failed":
                    failures.append((test["nodeid"].split("::")[-1], test["nodeid"].split("::")[0]))
            return failures
        except (json.JSONDecodeError, KeyError):
            return []

    def _load_history(self) -> dict[str, FlakyHistory]:
        if not self.history_path.exists():
            return {}
        try:
            data = json.loads(self.history_path.read_text())
            return {
                k: FlakyHistory(**v) for k, v in data.items()
            }
        except (json.JSONDecodeError, TypeError):
            return {}

    def _update_history(self, test_name: str, file_path: str, is_flaky: bool) -> None:
        if not is_flaky:
            return
        history = self._load_history()
        key = f"{file_path}::{test_name}"
        now = datetime.now(timezone.utc).isoformat()
        if key in history:
            h = history[key]
            h.flaky_count += 1
            h.last_seen = now
            h.last_flaky_at.append(now)
        else:
            history[key] = FlakyHistory(
                test_name=test_name,
                file_path=file_path,
                flaky_count=1,
                last_seen=now,
                last_flaky_at=[now],
            )
        self._history_cache = history

    def _save_history(self) -> None:
        history = getattr(self, "_history_cache", {})
        if history:
            data = {
                k: {
                    "test_name": v.test_name,
                    "file_path": v.file_path,
                    "flaky_count": v.flaky_count,
                    "last_seen": v.last_seen,
                    "last_flaky_at": v.last_flaky_at,
                }
                for k, v in history.items()
            }
            self.history_path.write_text(json.dumps(data, indent=2))

    def get_tests_needing_issues(self) -> list[FlakyHistory]:
        """Get tests that need GitHub Issues (flaky >3 times)."""
        history = self._load_history()
        return [h for h in history.values() if h.needs_issue]

    def print_report(self, results: list[FlakyResult]) -> None:
        """Print flaky test report."""
        print("=" * 60)
        print("FLAKY TEST DETECTION REPORT")
        print("=" * 60)
        flaky = [r for r in results if r.is_flaky]
        failing = [r for r in results if r.is_consistently_failing]

        if not results:
            print("✅ All tests pass — no flaky tests detected")
            return

        if flaky:
            print(f"\n⚠️  FLAKY TESTS ({len(flaky)}):")
            for r in flaky:
                print(f"  {r.file_path}::{r.test_name}")
                print(f"    Results: {' → '.join(r.results)} ({r.duration_ms:.0f}ms)")

        if failing:
            print(f"\n❌ CONSISTENTLY FAILING ({len(failing)}):")
            for r in failing:
                print(f"  {r.file_path}::{r.test_name}")
                print(f"    Results: {' → '.join(r.results)}")

        needs_issue = self.get_tests_needing_issues()
        if needs_issue:
            print(f"\n🔴 TESTS NEEDING GITHUB ISSUES ({len(needs_issue)}):")
            for h in needs_issue:
                print(f"  {h.file_path}::{h.test_name} (flaky {h.flaky_count}x)")


if __name__ == "__main__":
    detector = FlakyTestDetector()
    results = detector.analyze_failures(sys.argv[1:])
    detector.print_report(results)
    # Exit 1 if any consistently failing tests
    if any(r.is_consistently_failing for r in results):
        sys.exit(1)
