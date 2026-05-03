from __future__ import annotations

import importlib.util
import sys
from datetime import datetime, timezone
from pathlib import Path


def _load_module():
    path = Path('Code/SERVICES/otel_fallback.py').resolve()
    spec = importlib.util.spec_from_file_location('otel_fallback_mod_v2', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_corrupted_json_line_is_skipped(tmp_path: Path) -> None:
    mod = _load_module()
    buffer_path = tmp_path / 'buf.jsonl'
    buffer_path.write_text('{"trace_id":"ok"}\n{broken\n', encoding='utf-8')
    buffer = mod.FileSpanBuffer(buffer_path)
    recs = buffer.read_all()
    assert len(recs) == 1


def test_retention_by_max_bytes(tmp_path: Path) -> None:
    mod = _load_module()
    buffer = mod.FileSpanBuffer(tmp_path / 'buf.jsonl', max_records=100, max_bytes=250)
    now = datetime.now(timezone.utc)
    for i in range(10):
        buffer.append(f'trace-{i}', 'span', start_ts=now, end_ts=now, attributes={'payload': 'x' * 50})
    recs = buffer.read_all()
    assert len(recs) < 10
