from __future__ import annotations

import importlib.util
import sys
from datetime import datetime, timezone
from pathlib import Path


def _load_module():
    path = Path('Code/services/otel_fallback.py').resolve()
    spec = importlib.util.spec_from_file_location('otel_fallback_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_file_span_buffer_append_read_clear(tmp_path: Path) -> None:
    mod = _load_module()
    buffer = mod.FileSpanBuffer(tmp_path / 'buffer.jsonl')
    now = datetime.now(timezone.utc)
    buffer.append('trace-1', 'invoice.processed', start_ts=now, end_ts=now, attributes={'ok': True})
    records = buffer.read_all()
    assert len(records) == 1
    assert records[0]['trace_id'] == 'trace-1'
    buffer.clear()
    assert buffer.read_all() == []


def test_file_span_buffer_replay_partial_success(tmp_path: Path) -> None:
    mod = _load_module()
    buffer = mod.FileSpanBuffer(tmp_path / 'buffer.jsonl')
    now = datetime.now(timezone.utc)
    buffer.append('trace-1', 'a', start_ts=now, end_ts=now, attributes={})
    buffer.append('trace-2', 'b', start_ts=now, end_ts=now, attributes={})

    sent = buffer.replay(lambda rec: rec['trace_id'] == 'trace-1')
    assert sent == 1
    remaining = buffer.read_all()
    assert len(remaining) == 1
    assert remaining[0]['trace_id'] == 'trace-2'
