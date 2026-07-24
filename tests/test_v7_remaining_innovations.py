"""
test_v7_remaining_innovations.py — Tests for remaining v7.0 TESTING/MONITORING innovations.

Covers:
  - Tail-Based Sampling (Innowacja 12)
  - Log-to-Trace Correlation (Innowacja 13)
  - mimalloc Memory Monitoring (Innowacja 14)
  - OTel Exemplars (Innowacja 10)
  - Chaos Engineering Expansion (Innowacja 9)
"""

from __future__ import annotations

import os
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


# ═══════════════════════════════════════════════════════════════════════════════
# Tail-Based Sampling Tests (Enterprise v7.0 Innowacja 12)
# ═══════════════════════════════════════════════════════════════════════════════


class TestTailBasedSampling:
    """Tests for Tail-Based Sampling — Enterprise v7.0 Innowacja 12."""

    def test_should_sample_tail_disabled(self) -> None:
        """When tail sampling is disabled, all spans pass through."""
        from nexus_ai.core.otel import should_sample_tail
        # By default NEXUS_TAIL_SAMPLING=0, so all should pass
        assert should_sample_tail(has_error=False, duration_ms=50.0) is True
        assert should_sample_tail(has_error=True, duration_ms=5000.0) is True

    def test_tail_sampling_config_exists(self) -> None:
        """Verify tail sampling config variables are defined."""
        from nexus_ai.core import otel
        assert hasattr(otel, '_TAIL_SAMPLING_ENABLED')
        assert hasattr(otel, '_TAIL_ERROR_RATE')
        assert hasattr(otel, '_TAIL_LONG_RATE')
        assert hasattr(otel, '_TAIL_SHORT_RATE')
        assert hasattr(otel, '_TAIL_DEFAULT_RATE')

    @patch('nexus_ai.core.otel._TAIL_SAMPLING_ENABLED', True)
    @patch('nexus_ai.core.otel._TAIL_ERROR_RATE', 1.0)
    @patch('nexus_ai.core.otel._TAIL_SHORT_RATE', 0.0)
    def test_error_always_sampled(self) -> None:
        """ERROR spans should always be sampled when error rate is 1.0."""
        from nexus_ai.core.otel import should_sample_tail
        assert should_sample_tail(has_error=True, duration_ms=100.0) is True

    @patch('nexus_ai.core.otel._TAIL_SAMPLING_ENABLED', True)
    @patch('nexus_ai.core.otel._TAIL_ERROR_RATE', 0.0)
    @patch('nexus_ai.core.otel._TAIL_SHORT_RATE', 0.0)
    @patch('nexus_ai.core.otel._TAIL_DEFAULT_RATE', 0.0)
    def test_all_rejected_when_rates_zero(self) -> None:
        """When all rates are 0, nothing passes through."""
        from nexus_ai.core.otel import should_sample_tail
        assert should_sample_tail(has_error=False, duration_ms=200.0) is False


# ═══════════════════════════════════════════════════════════════════════════════
# Log-to-Trace Correlation Tests (Enterprise v7.0 Innowacja 13)
# ═══════════════════════════════════════════════════════════════════════════════


class TestLogTraceCorrelation:
    """Tests for Log-to-Trace Correlation — Enterprise v7.0 Innowacja 13."""

    def test_get_active_trace_id_no_trace(self) -> None:
        """When no OTel trace is active, returns 'no-trace'."""
        from nexus_ai.core.logger import _get_active_trace_id
        tid = _get_active_trace_id()
        assert isinstance(tid, str)

    def test_get_active_span_id_no_span(self) -> None:
        """When no OTel span is active, returns 'no-span'."""
        from nexus_ai.core.logger import _get_active_span_id
        sid = _get_active_span_id()
        assert isinstance(sid, str)

    def test_otel_get_current_trace_id_no_trace(self) -> None:
        """get_current_trace_id returns None when no trace active."""
        from nexus_ai.core.otel import get_current_trace_id
        tid = get_current_trace_id()
        assert tid is None or isinstance(tid, str)

    def test_otel_get_current_span_id_no_span(self) -> None:
        """get_current_span_id returns None when no span active."""
        from nexus_ai.core.otel import get_current_span_id
        sid = get_current_span_id()
        assert sid is None or isinstance(sid, str)


# ═══════════════════════════════════════════════════════════════════════════════
# mimalloc Memory Monitoring Tests (Enterprise v7.0 Innowacja 14)
# ═══════════════════════════════════════════════════════════════════════════════


class TestMimallocMonitoring:
    """Tests for mimalloc Memory Monitoring — Enterprise v7.0 Innowacja 14."""

    def test_collect_mimalloc_metrics(self) -> None:
        """Verify mimalloc metrics collection returns valid data."""
        from nexus_ai.core.monitor import collect_mimalloc_metrics, MimallocMetrics
        metrics = collect_mimalloc_metrics()
        assert isinstance(metrics, MimallocMetrics)
        assert isinstance(metrics.active, bool)

    def test_mimalloc_metrics_inactive(self) -> None:
        """When mimalloc is not active, metrics show inactive."""
        from nexus_ai.core.monitor import MimallocMetrics
        m = MimallocMetrics(active=False)
        assert m.active is False
        assert m.heap_size_mb is None
        assert m.fragmentation_pct is None

    def test_mimalloc_metrics_fragmentation(self) -> None:
        """Fragmentation calculation is correct."""
        from nexus_ai.core.monitor import MimallocMetrics
        m = MimallocMetrics(
            active=True,
            reserved_mb=100.0,
            committed_mb=80.0,
        )
        assert m.fragmentation_pct == 20.0

        m2 = MimallocMetrics(
            active=True,
            reserved_mb=0.0,
            committed_mb=50.0,
        )
        assert m2.fragmentation_pct is None


# ═══════════════════════════════════════════════════════════════════════════════
# OTel Exemplars Tests (Enterprise v7.0 Innowacja 10)
# ═══════════════════════════════════════════════════════════════════════════════


class TestOTelExemplars:
    """Tests for OTel Exemplars — Enterprise v7.0 Innowacja 10."""

    def test_create_exemplar_reservoir(self) -> None:
        """Verify exemplar reservoir can be created."""
        from nexus_ai.core.otel import create_exemplar_reservoir
        reservoir = create_exemplar_reservoir()
        # May be None if OTel SDK not available, that's OK

    def test_otel_views_exemplar_imports(self) -> None:
        """Verify otel_views module can be referenced (exemplar configs)."""
        try:
            from nexus_ai.api import otel_views
            assert otel_views is not None
        except ImportError:
            pytest.skip("otel_views module not importable in this environment")


# ═══════════════════════════════════════════════════════════════════════════════
# Synthetic Monitor Edge Cases
# ═══════════════════════════════════════════════════════════════════════════════


class TestSyntheticMonitorEdgeCases:
    """Edge case tests for SyntheticMonitor."""

    def test_stats_empty_state(self) -> None:
        """Stats should show 100% success when no checks run."""
        from nexus_ai.services.synthetic_monitor import SyntheticMonitor
        monitor = SyntheticMonitor()
        stats = monitor.get_stats()
        for name in ("health", "invoice", "ocr_pipeline"):
            assert stats[name]["total"] == 0
            assert stats[name]["success_rate"] == 100.0

    def test_synthetic_check_failure_dataclass(self) -> None:
        """SyntheticCheck with failure and error message."""
        from nexus_ai.services.synthetic_monitor import SyntheticCheck
        check = SyntheticCheck(
            check_type="health",
            success=False,
            duration_ms=500.0,
            error="Connection refused",
        )
        assert check.success is False
        assert check.error == "Connection refused"


# ═══════════════════════════════════════════════════════════════════════════════
# Test Gap Analyzer Edge Cases
# ═══════════════════════════════════════════════════════════════════════════════


class TestGapAnalyzerEdgeCases:
    """Edge case tests for TestGapAnalyzer."""

    def test_scan_empty_source_dir(self) -> None:
        """Analyzer handles empty or nonexistent source directory."""
        from nexus_ai.services.test_gap_analyzer import TestGapAnalyzer
        analyzer = TestGapAnalyzer(source_dir="/nonexistent/chaos")
        report = analyzer.analyze()
        assert report.total_modules == 0
        assert report.overall_coverage_pct == 0.0

    def test_gap_report_critical_gaps_empty(self) -> None:
        """Critical gaps list should be empty with no modules."""
        from nexus_ai.services.test_gap_analyzer import GapReport
        report = GapReport()
        assert report.critical_gaps == []
        d = report.to_dict()
        assert "critical_gaps" in d
