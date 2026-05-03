"""Replay locally buffered OTEL spans using a simple HTTP OTLP endpoint."""
from __future__ import annotations

import argparse
import json
import time
import urllib.request
from pathlib import Path

import importlib.util


def _load_buffer_class():
    try:
        from services.otel_fallback import FileSpanBuffer as cls
        return cls
    except ModuleNotFoundError:
        module_path = Path(__file__).resolve().parents[1] / "SERVICES" / "otel_fallback.py"
        spec = importlib.util.spec_from_file_location("otel_fallback_local", module_path)
        assert spec and spec.loader
        import sys
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module.FileSpanBuffer


FileSpanBuffer = _load_buffer_class()



def _send_record(endpoint: str, record: dict, *, timeout_sec: float, auth_token: str | None = None) -> bool:
    data = json.dumps(record).encode('utf-8')
    headers = {'Content-Type': 'application/json'}
    if auth_token:
        headers['Authorization'] = f'Bearer {auth_token}'
    req = urllib.request.Request(endpoint, data=data, method='POST', headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            return 200 <= resp.status < 300
    except Exception:
        return False


def _replay_with_limits(
    buffer: FileSpanBuffer,
    endpoint: str,
    *,
    timeout_sec: float,
    max_records: int,
    max_attempts: int,
    backoff_ms: int,
    auth_token: str | None = None,
) -> tuple[int, int]:
    records = buffer.read_all()
    if not records:
        return 0, 0

    target = records[:max_records] if max_records > 0 else records
    sent = 0
    failed = 0

    for rec in target:
        ok = False
        for attempt in range(1, max_attempts + 1):
            if _send_record(endpoint, rec, timeout_sec=timeout_sec, auth_token=auth_token):
                ok = True
                break
            if attempt < max_attempts:
                time.sleep(max(0, backoff_ms) / 1000.0)
        if ok:
            sent += 1
        else:
            failed += 1

    # Remove only successfully sent subset using replay predicate semantics.
    sent_ids = set()
    for rec in target[:sent]:
        trace_id = rec.get('trace_id')
        if trace_id:
            sent_ids.add(str(trace_id))

    if sent_ids:
        buffer.replay(lambda rec: str(rec.get('trace_id', '')) in sent_ids)

    return sent, failed


def main() -> int:
    parser = argparse.ArgumentParser(description='Replay OTEL buffered spans.')
    parser.add_argument('--buffer-path', default='app_data/otel_spans_buffer.jsonl')
    parser.add_argument('--endpoint', required=True, help='HTTP endpoint accepting JSON span records')
    parser.add_argument('--timeout-sec', type=float, default=5.0)
    parser.add_argument('--max-records', type=int, default=1000)
    parser.add_argument('--max-attempts', type=int, default=3)
    parser.add_argument('--backoff-ms', type=int, default=200)
    parser.add_argument('--auth-token', help='Optional bearer token for secured collectors')
    args = parser.parse_args()

    buffer = FileSpanBuffer(Path(args.buffer_path))
    sent, failed = _replay_with_limits(
        buffer,
        args.endpoint,
        timeout_sec=args.timeout_sec,
        max_records=args.max_records,
        max_attempts=max(1, args.max_attempts),
        backoff_ms=args.backoff_ms,
        auth_token=args.auth_token,
    )
    print(f'[otel-replay] sent={sent} failed={failed}')
    return 0 if failed == 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
