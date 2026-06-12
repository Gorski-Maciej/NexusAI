"""File-based fallback buffer for telemetry export failures."""

from __future__ import annotations

import os
from collections.abc import Iterator
from contextlib import contextmanager
from msgspec import Struct
from msgspec.structs import asdict
from pathlib import Path
from typing import Any

import pendulum

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_dumps, msgspec_loads


class BufferedSpan(Struct):
    trace_id: str
    name: str
    start_ts: str
    end_ts: str
    attributes: dict[str, Any]


class FileSpanBuffer:
    def __init__(
        self,
        file_path: Path | str = "app_data/otel_spans_buffer.jsonl",
        max_records: int = 10_000,
        max_bytes: int = 10 * 1024 * 1024,
    ) -> None:
        self.file_path = Path(file_path)
        self.max_records = max_records
        self.max_bytes = max_bytes
        self.lock_path = self.file_path.with_suffix(self.file_path.suffix + ".lock")
        self.file_path.parent.mkdir(parents=True, exist_ok=True)

    @contextmanager
    def _file_lock(self) -> Iterator[None]:
        fd = os.open(self.lock_path, os.O_CREAT | os.O_RDWR)
        try:
            try:
                import fcntl

                fcntl.flock(fd, fcntl.LOCK_EX)
            except Exception:
                pass
            yield
        finally:
            try:
                import fcntl

                fcntl.flock(fd, fcntl.LOCK_UN)
            except Exception:
                pass
            os.close(fd)

    def _read_all_unlocked(self) -> list[dict[str, Any]]:
        if not self.file_path.exists():
            return []
        records: list[dict[str, Any]] = []
        with self.file_path.open("r", encoding="utf-8") as fp:
            for line in fp:
                line = line.strip()
                if not line:
                    continue
                try:
                    records.append(msgspec_loads(line))
                except DecodeError:
                    continue
        return records

    def append(
        self,
        trace_id: str,
        name: str,
        *,
        start_ts: pendulum.DateTime,
        end_ts: pendulum.DateTime,
        attributes: dict[str, Any] | None = None,
    ) -> None:
        span = BufferedSpan(
            trace_id=trace_id,
            name=name,
            start_ts=start_ts.in_tz("UTC").isoformat(),
            end_ts=end_ts.in_tz("UTC").isoformat(),
            attributes=attributes or {},
        )
        with self._file_lock():
            with self.file_path.open("a", encoding="utf-8") as fp:
                fp.write(msgspec_dumps(msgspec.structs.asdict(span), ensure_ascii=False) + "\n")
            self._enforce_retention_locked()

    def read_all(self) -> list[dict[str, Any]]:
        with self._file_lock():
            return self._read_all_unlocked()

    def clear(self) -> None:
        with self._file_lock():
            self.file_path.unlink(missing_ok=True)

    def _enforce_retention_locked(self) -> None:
        if not self.file_path.exists():
            return
        records = self._read_all_unlocked()
        trim_required = len(records) > self.max_records
        size_required = self.file_path.stat().st_size > self.max_bytes
        if not trim_required and not size_required:
            return
        while records and (
            len(records) > self.max_records or self._estimate_bytes(records) > self.max_bytes
        ):
            records.pop(0)
        tmp = self.file_path.with_suffix(self.file_path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8") as fp:
            for rec in records:
                fp.write(msgspec_dumps(rec, ensure_ascii=False) + "\n")
        tmp.replace(self.file_path)

    @staticmethod
    def _estimate_bytes(records: list[dict[str, Any]]) -> int:
        return sum(len(msgspec_dumps(rec, ensure_ascii=False)) + 1 for rec in records)

    def replay(self, sender) -> int:
        """Replay buffered spans using sender(record)->bool. Returns sent count."""
        with self._file_lock():
            records = self._read_all_unlocked()
            if not records:
                return 0
            sent = 0
            remaining: list[dict[str, Any]] = []
            for record in records:
                try:
                    ok = bool(sender(record))
                except Exception:
                    ok = False
                if ok:
                    sent += 1
                else:
                    remaining.append(record)
            if remaining:
                tmp = self.file_path.with_suffix(self.file_path.suffix + ".tmp")
                with tmp.open("w", encoding="utf-8") as fp:
                    for rec in remaining:
                        fp.write(msgspec_dumps(rec, ensure_ascii=False) + "\n")
                tmp.replace(self.file_path)
            else:
                self.file_path.unlink(missing_ok=True)
            return sent
