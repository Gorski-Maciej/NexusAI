"""Replay locally buffered OTEL spans using a simple HTTP OTLP endpoint."""
from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path

from services.otel_fallback import FileSpanBuffer


def _send_record(endpoint: str, record: dict) -> bool:
    data = json.dumps(record).encode('utf-8')
    req = urllib.request.Request(endpoint, data=data, method='POST', headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return 200 <= resp.status < 300
    except Exception:
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description='Replay OTEL buffered spans.')
    parser.add_argument('--buffer-path', default='app_data/otel_spans_buffer.jsonl')
    parser.add_argument('--endpoint', required=True, help='HTTP endpoint accepting JSON span records')
    args = parser.parse_args()

    buffer = FileSpanBuffer(Path(args.buffer_path))
    sent = buffer.replay(lambda rec: _send_record(args.endpoint, rec))
    print(f'[otel-replay] sent={sent}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
