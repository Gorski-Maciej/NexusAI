"""File-based fallback buffer for telemetry export failures."""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass(slots=True)
class BufferedSpan:
    trace_id: str
    name: str
    start_ts: str
    end_ts: str
    attributes: dict[str, Any]


class FileSpanBuffer:
    def __init__(self, file_path: Path | str = "app_data/otel_spans_buffer.jsonl") -> None:
        self.file_path = Path(file_path)
        self.file_path.parent.mkdir(parents=True, exist_ok=True)

    def append(self, trace_id: str, name: str, *, start_ts: datetime, end_ts: datetime, attributes: dict[str, Any] | None = None) -> None:
        span = BufferedSpan(
            trace_id=trace_id,
            name=name,
            start_ts=start_ts.astimezone(timezone.utc).isoformat(),
            end_ts=end_ts.astimezone(timezone.utc).isoformat(),
            attributes=attributes or {},
        )
        with self.file_path.open("a", encoding="utf-8") as fp:
            fp.write(json.dumps(asdict(span), ensure_ascii=False) + "\n")

    def read_all(self) -> list[dict[str, Any]]:
        if not self.file_path.exists():
            return []
        records: list[dict[str, Any]] = []
        with self.file_path.open("r", encoding="utf-8") as fp:
            for line in fp:
                line = line.strip()
                if not line:
                    continue
                records.append(json.loads(line))
        return records

    def clear(self) -> None:
        self.file_path.unlink(missing_ok=True)

    def replay(self, sender) -> int:
        """Replay buffered spans using sender(record)->bool. Returns sent count."""
        records = self.read_all()
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
            with self.file_path.open("w", encoding="utf-8") as fp:
                for rec in remaining:
                    fp.write(json.dumps(rec, ensure_ascii=False) + "\n")
        else:
            self.clear()
        return sent
