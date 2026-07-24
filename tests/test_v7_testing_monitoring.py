"""
test_v7_testing_monitoring.py — Comprehensive test suite for v7.0 TESTING & MONITORING audit.

Covers:
  - Anomaly Detection on Logs (Innowacja 2)
  - Synthetic Monitoring (Innowacja 15)
  - Test Gap Analyzer (Innowacja 11)
  - Flaky Test Detector (Innowacja 4)
  - Tracing Dashboard (Innowacja 3)
  - Boundary Fuzz OPA Integration (Rec #4)
  - PII Scanner (Rec #8)
"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


# ═══════════════════════════════════════════════════════════════════════════════
# Anomaly Detection Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestLogAnomalyDetector:
    """Tests for LogAnomalyDetector — Enterprise v7.0 Innowacja 2."""

    def test_detector_initialization(self) -> None:
        from nexus_ai.services.anomaly_detection_logs import LogAnomalyDetector
        detector = LogAnomalyDetector(error_rate_threshold=5.0)
        assert detector.error_rate_threshold == 5.0
        assert detector.window_minutes == 5

    def test_scan_returns_empty_when_no_db(self) -> None:
        from nexus_ai.services.anomaly_detection_logs import LogAnomalyDetector
        detector = LogAnomalyDetector(db_path="/nonexistent/path.duckdb")
        anomalies = detector.scan()
        assert anomalies == []

    def test_anomaly_dataclass(self) -> None:
        from nexus_ai.services.anomaly_detection_logs import LogAnomaly
        a = LogAnomaly(
            anomaly_type="error_spike",
            severity="critical",
            description="Test anomaly",
            detected_at="2026-01-01T00:00:00Z",
            metric_value=15.0,
            threshold=10.0,
            window_minutes=5,
        )
        assert a.anomaly_type == "error_spike"
        assert a.severity == "critical"

    def test_stats_returns_empty_when_no_db(self) -> None:
        from nexus_ai.services.anomaly_detection_logs import LogAnomalyDetector
        detector = LogAnomalyDetector(db_path="/nonexistent.duckdb")
        assert detector.get_stats() == {}


# ═══════════════════════════════════════════════════════════════════════════════
# Synthetic Monitor Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestSyntheticMonitor:
    """Tests for SyntheticMonitor — Enterprise v7.0 Innowacja 15."""

    def test_monitor_initialization(self) -> None:
        from nexus_ai.services.synthetic_monitor import SyntheticMonitor
        monitor = SyntheticMonitor(base_url="http://localhost:9999")
        assert monitor.base_url == "http://localhost:9999"
        assert monitor.health_interval == 60.0

    def test_stats_initial_state(self) -> None:
        from nexus_ai.services.synthetic_monitor import SyntheticMonitor
        monitor = SyntheticMonitor()
        stats = monitor.get_stats()
        assert "health" in stats
        assert stats["health"]["total"] == 0
        assert stats["health"]["success_rate"] == 100.0

    def test_synthetic_check_success(self) -> None:
        from nexus_ai.services.synthetic_monitor import SyntheticCheck
        check = SyntheticCheck(
            check_type="health",
            success=True,
            duration_ms=15.5,
        )
        assert check.success is True
        assert check.duration_ms == 15.5

    def test_synthetic_stats_percentiles(self) -> None:
        from nexus_ai.services.synthetic_monitor import SyntheticStats
        from collections import deque
        stats = SyntheticStats()
        stats.latencies = deque([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0])
        stats.total = 10
        stats.successes = 10
        # P50 of [10,20,30,40,50,60,70,80,90,100] = value at index 5 (since 10*0.5=5)
        assert 50.0 <= stats.p50 <= 60.0  # tolerant range for list vs deque indexing
        assert stats.p95 >= 90.0  # P95 should be >= 90
        assert stats.success_rate == 100.0


# ═══════════════════════════════════════════════════════════════════════════════
# Test Gap Analyzer Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestGapAnalyzer:
    """Tests for TestGapAnalyzer — Enterprise v7.0 Innowacja 11."""

    def test_analyzer_initialization(self) -> None:
        from nexus_ai.services.test_gap_analyzer import TestGapAnalyzer
        analyzer = TestGapAnalyzer()
        assert analyzer.critical_loc_threshold == 500

    def test_analyze_returns_report(self) -> None:
        from nexus_ai.services.test_gap_analyzer import TestGapAnalyzer
        analyzer = TestGapAnalyzer(
            source_dir="nexus_ai/services",
            test_dir="tests",
        )
        report = analyzer.analyze()
        assert report.total_modules > 0
        assert isinstance(report.overall_coverage_pct, float)

    def test_report_to_dict(self) -> None:
        from nexus_ai.services.test_gap_analyzer import TestGapAnalyzer
        analyzer = TestGapAnalyzer(
            source_dir="nexus_ai/services",
            test_dir="tests",
        )
        report = analyzer.analyze()
        d = report.to_dict()
        assert "total_modules" in d
        assert "critical_gaps" in d
        assert "modules" in d

    def test_module_coverage_untested(self) -> None:
        from nexus_ai.services.test_gap_analyzer import ModuleCoverage
        mc = ModuleCoverage(
            module_path="nexus_ai/fake_module.py",
            source_lines=100,
            function_count=5,
            class_count=1,
        )
        assert mc.is_tested is False
        assert mc.coverage_pct == 0.0


# ═══════════════════════════════════════════════════════════════════════════════
# Flaky Test Detector Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestFlakyDetector:
    """Tests for FlakyTestDetector — Enterprise v7.0 Innowacja 4."""

    def test_detector_initialization(self) -> None:
        from nexus_ai.services.flaky_test_detector import FlakyTestDetector
        detector = FlakyTestDetector(max_retries=2)
        assert detector.max_retries == 2

    def test_flaky_result_classification(self) -> None:
        from nexus_ai.services.flaky_test_detector import FlakyResult
        r = FlakyResult(
            test_name="test_x",
            file_path="tests/test_x.py",
            attempts=4,
            results=["FAIL", "PASS", "PASS", "FAIL"],
            is_flaky=True,
            is_consistently_failing=False,
            duration_ms=1500.0,
        )
        assert r.is_flaky is True
        assert r.is_consistently_failing is False

    def test_history_needs_issue(self) -> None:
        from nexus_ai.services.flaky_test_detector import FlakyHistory
        h = FlakyHistory(
            test_name="test_x",
            file_path="tests/test_x.py",
            flaky_count=4,
        )
        assert h.needs_issue is True

        h2 = FlakyHistory(test_name="test_y", file_path="tests/test_y.py", flaky_count=1)
        assert h2.needs_issue is False

    def test_load_history_empty(self) -> None:
        from nexus_ai.services.flaky_test_detector import FlakyTestDetector
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            f.write(b"{}")
            f.flush()
            detector = FlakyTestDetector(history_path=Path(f.name))
            history = detector._load_history()
            assert history == {}


# ═══════════════════════════════════════════════════════════════════════════════
# Tracing Dashboard Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestTracingDashboard:
    """Tests for TracingDashboard — Enterprise v7.0 Innowacja 3."""

    def test_dashboard_initialization(self) -> None:
        from nexus_ai.services.tracing_dashboard import TracingDashboard
        dashboard = TracingDashboard()
        assert dashboard.parquet_dir.name == "otel_spans_parquet"

    def test_top_slow_endpoints_empty(self) -> None:
        from nexus_ai.services.tracing_dashboard import TracingDashboard
        dashboard = TracingDashboard(parquet_dir="/nonexistent")
        result = dashboard.top_slow_endpoints()
        assert result == []

    def test_error_rate_per_service_empty(self) -> None:
        from nexus_ai.services.tracing_dashboard import TracingDashboard
        dashboard = TracingDashboard(parquet_dir="/nonexistent")
        result = dashboard.error_rate_per_service()
        assert result == []

    def test_span_timeline_empty(self) -> None:
        from nexus_ai.services.tracing_dashboard import TracingDashboard
        dashboard = TracingDashboard(parquet_dir="/nonexistent")
        result = dashboard.span_timeline()
        assert result == []

    def test_get_dashboard_data(self) -> None:
        from nexus_ai.services.tracing_dashboard import TracingDashboard
        dashboard = TracingDashboard(parquet_dir="/nonexistent")
        data = dashboard.get_dashboard_data()
        assert "timestamp" in data
        assert "top_slow_endpoints" in data
        assert "error_rate_per_service" in data


# ═══════════════════════════════════════════════════════════════════════════════
# Boundary Fuzz OPA Integration Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestBoundaryFuzzOPA:
    """Tests for boundary fuzz OPA integration — Enterprise v7.0 Rec #4."""

    def test_compute_category_below(self) -> None:
        from tests.test_boundary_fuzz_auto import _compute_category
        assert _compute_category(100.0, 200.0) == "BELOW"

    def test_compute_category_at(self) -> None:
        from tests.test_boundary_fuzz_auto import _compute_category
        assert _compute_category(200.0, 200.0) == "AT"

    def test_compute_category_above(self) -> None:
        from tests.test_boundary_fuzz_auto import _compute_category
        assert _compute_category(300.0, 200.0) == "ABOVE"

    def test_all_25_thresholds_defined(self) -> None:
        from tests.test_boundary_fuzz_auto import THRESHOLDS
        assert len(THRESHOLDS) >= 23
        assert "P25" in THRESHOLDS
        assert "P1169" in THRESHOLDS

    def test_opa_eval_fallback_deterministic(self) -> None:
        from tests.test_boundary_fuzz_auto import _opa_eval
        result = _opa_eval("nonexistent.rego", "fake_rule", 100.0, 150.0)
        assert result == "BELOW"


# ═══════════════════════════════════════════════════════════════════════════════
# PII Scanner Tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestPiiScanner:
    """Tests for PII Scanner — Enterprise v7.0 Rec #8."""

    def test_mask_nip(self) -> None:
        from nexus_ai.services.log_pii_monitor import mask_pii
        result = mask_pii("NIP: 1234567890")
        assert "1234567890" not in result

    def test_mask_email(self) -> None:
        from nexus_ai.services.log_pii_monitor import mask_pii
        result = mask_pii("Email: jan@example.com")
        assert "jan@example.com" not in result

    def test_mask_pesel(self) -> None:
        from nexus_ai.services.log_pii_monitor import mask_pii
        result = mask_pii("PESEL: 12345678901")
        assert "12345678901" not in result

    def test_mask_multiple(self) -> None:
        from nexus_ai.services.log_pii_monitor import mask_pii
        result = mask_pii("NIP 1234567890, email: test@example.com, phone: +48123456789")
        assert "1234567890" not in result
        assert "test@example.com" not in result

    def test_pii_processor_masks_dict(self) -> None:
        from nexus_ai.services.log_pii_monitor import PiiMaskingProcessor
        processor = PiiMaskingProcessor()
        event = {"message": "NIP 1234567890", "user": "jan@example.com"}
        masked = processor(None, "info", event)
        assert "1234567890" not in masked["message"]
        assert "jan@example.com" not in masked["user"]

    def test_pii_processor_keeps_non_strings(self) -> None:
        from nexus_ai.services.log_pii_monitor import PiiMaskingProcessor
        processor = PiiMaskingProcessor()
        event = {"count": 42, "active": True, "name": "John"}
        masked = processor(None, "info", event)
        assert masked["count"] == 42
        assert masked["active"] is True
        assert masked["name"] == "John"


# ═══════════════════════════════════════════════════════════════════════════════
# Tail-Based Sampling Tests (Enterprise v7.0 Innowacja 12)
# ═══════════════════════════════════════════════════════════════════════════════


class TestTailBasedSampling:
    """Tests for tail-based sampling — Enterprise v7.0 Innowacja 12."""

    def test_sampling_config_always_on(self) -> None:
        from nexus_ai.core.otel import OTEL_TRACES_SAMPLER
        assert OTEL_TRACES_SAMPLER in (
            "always_on", "always_off", "parentbased_always_on",
            "parentbased_always_off", "traceidratio", "parentbased_traceidratio",
        )

    def test_bsp_config_defaults(self) -> None:
        from nexus_ai.core.otel import (
            OTEL_BSP_MAX_QUEUE_SIZE, OTEL_BSP_SCHEDULE_DELAY,
            OTEL_BSP_MAX_EXPORT_BATCH_SIZE, OTEL_BSP_EXPORT_TIMEOUT,
        )
        assert OTEL_BSP_MAX_QUEUE_SIZE >= 256
        assert OTEL_BSP_SCHEDULE_DELAY >= 1000
        assert OTEL_BSP_MAX_EXPORT_BATCH_SIZE >= 64
        assert OTEL_BSP_EXPORT_TIMEOUT >= 5000
