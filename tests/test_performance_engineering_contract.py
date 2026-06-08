from __future__ import annotations

from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.scripts.performance_engineering import enforce_thresholds


def test_enforce_thresholds_passes_for_good_summary(tmp_path: Path) -> None:
    summary = tmp_path / 'summary.json'
    summary.write_text(msgspec_dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 100.0}},
            'checks': {'values': {'rate': 0.99}},
        }
    }), encoding='utf-8')
    assert enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02) == 0


def test_enforce_thresholds_fails_for_bad_summary(tmp_path: Path) -> None:
    summary = tmp_path / 'summary_bad.json'
    summary.write_text(msgspec_dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 2200.0}},
            'checks': {'values': {'rate': 0.90}},
        }
    }), encoding='utf-8')
    assert enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02) == 1
