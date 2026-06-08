from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

from nexus_ai.scripts import otel_buffer_replayer as replayer
from nexus_ai.services.otel_fallback import FileSpanBuffer


def test_replay_with_limits_sends_subset(tmp_path: Path) -> None:
    buffer = FileSpanBuffer(tmp_path / 'buf.jsonl')
    now = datetime.now(timezone.utc)
    buffer.append('t1', 'a', start_ts=now, end_ts=now, attributes={})
    buffer.append('t2', 'b', start_ts=now, end_ts=now, attributes={})

    sent_calls: list[str] = []

    def fake_send(endpoint, rec, *, timeout_sec, auth_token=None):
        sent_calls.append(rec['trace_id'])
        return rec['trace_id'] == 't1'

    replayer._send_record = fake_send  # type: ignore[attr-defined]
    sent, failed = replayer._replay_with_limits(buffer, 'http://x', timeout_sec=1, max_records=2, max_attempts=1, backoff_ms=0)
    assert sent == 1
    assert failed == 1
    remaining = buffer.read_all()
    assert any(r['trace_id'] == 't2' for r in remaining)
