from __future__ import annotations

import importlib.util
import json
from pathlib import Path


def _load_perf_module():
    module_path = Path('Code/SKRIPTS/performance_engineering.py')
    spec = importlib.util.spec_from_file_location('perf_module', module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


def test_enforce_thresholds_passes_for_good_summary(tmp_path: Path) -> None:
    mod = _load_perf_module()
    summary = tmp_path / 'summary.json'
    summary.write_text(json.dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 100.0}},
            'checks': {'values': {'rate': 0.99}},
        }
    }), encoding='utf-8')
    assert mod.enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02) == 0


def test_enforce_thresholds_fails_for_bad_summary(tmp_path: Path) -> None:
    mod = _load_perf_module()
    summary = tmp_path / 'summary_bad.json'
    summary.write_text(json.dumps({
        'metrics': {
            'http_req_duration': {'values': {'p(95)': 2200.0}},
            'checks': {'values': {'rate': 0.90}},
        }
    }), encoding='utf-8')
    assert mod.enforce_thresholds(summary, max_p95_ms=1200.0, max_error_rate=0.02) == 1
