from __future__ import annotations

import pendulum
from pathlib import Path

from nexus_ai.services.otel_fallback import FileSpanBuffer


def test_file_span_buffer_append_read_clear(tmp_path: Path) -> None:
    buffer = FileSpanBuffer(tmp_path / 'buffer.jsonl')
    now = pendulum.now("UTC")
    buffer.append('trace-1', 'invoice.processed', start_ts=now, end_ts=now, attributes={'ok': True})
    records = buffer.read_all()
    assert len(records) == 1
    assert records[0]['trace_id'] == 'trace-1'
    buffer.clear()
    assert buffer.read_all() == []


def test_file_span_buffer_replay_partial_success(tmp_path: Path) -> None:
    mod = _load_module()
    buffer = mod.FileSpanBuffer(tmp_path / 'buffer.jsonl')
    now = pendulum.now("UTC")
    buffer.append('trace-1', 'a', start_ts=now, end_ts=now, attributes={})
    buffer.append('trace-2', 'b', start_ts=now, end_ts=now, attributes={})

    sent = buffer.replay(lambda rec: rec['trace_id'] == 'trace-1')
    assert sent == 1
    remaining = buffer.read_all()
    assert len(remaining) == 1
    assert remaining[0]['trace_id'] == 'trace-2'
