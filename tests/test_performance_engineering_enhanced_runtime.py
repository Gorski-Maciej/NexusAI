from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
from __future__ import annotations

import importlib.util
import json
from pathlib import Path


def _load_perf_module():
    module_path = Path('Code/scripts/performance_engineering.py')
    spec = importlib.util.spec_from_file_location('perf_module_v2', module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


def test_enforce_thresholds_p99_breach(tmp_path: Path) -> None:
    mod = _load_perf_module()
    summary = tmp_path / 'summary.json'
    summary.write_text(msgspec_dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 100.0, 'p(99)': 2500.0}},
            'checks': {'values': {'rate': 0.99}},
            'http_reqs': {'values': {'rate': 30.0}},
        }
    }), encoding='utf-8')
    assert mod.enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02, max_p99_ms=2000.0) == 1


def test_enforce_thresholds_min_rps_breach(tmp_path: Path) -> None:
    mod = _load_perf_module()
    summary = tmp_path / 'summary2.json'
    summary.write_text(msgspec_dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 100.0, 'p(99)': 110.0}},
            'checks': {'values': {'rate': 0.99}},
            'http_reqs': {'values': {'rate': 1.0}},
        }
    }), encoding='utf-8')
    assert mod.enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02, min_rps=5.0) == 1
