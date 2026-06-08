from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

from nexus_ai.services.otel_fallback import FileSpanBuffer


def test_corrupted_json_line_is_skipped(tmp_path: Path) -> None:
    buffer_path = tmp_path / 'buf.jsonl'
    buffer = FileSpanBuffer(buffer_path)
    buffer_path.write_text('{"trace_id":"ok"}\n{broken\n', encoding='utf-8')
    recs = buffer.read_all()
    assert len(recs) == 1


def test_retention_by_max_bytes(tmp_path: Path) -> None:
    buffer = FileSpanBuffer(tmp_path / 'buf.jsonl', max_records=100, max_bytes=250)
    now = datetime.now(timezone.utc)
    for i in range(10):
        buffer.append(f'trace-{i}', 'span', start_ts=now, end_ts=now, attributes={'payload': 'x' * 50})
    recs = buffer.read_all()
    assert len(recs) < 10
