from __future__ import annotations

from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.scripts.performance_engineering import enforce_thresholds


def test_enforce_thresholds_p99_breach(tmp_path: Path) -> None:
    summary = tmp_path / 'summary.json'
    summary.write_text(msgspec_dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 100.0, 'p(99)': 2500.0}},
            'checks': {'values': {'rate': 0.99}},
            'http_reqs': {'values': {'rate': 30.0}},
        }
    }), encoding='utf-8')
    assert enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02, max_p99_ms=2000.0) == 1


def test_enforce_thresholds_min_rps_breach(tmp_path: Path) -> None:
    summary = tmp_path / 'summary2.json'
    summary.write_text(msgspec_dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 100.0, 'p(99)': 110.0}},
            'checks': {'values': {'rate': 0.99}},
            'http_reqs': {'values': {'rate': 1.0}},
        }
    }), encoding='utf-8')
    assert enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02, min_rps=5.0) == 1
