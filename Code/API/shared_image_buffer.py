from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from threading import Lock


@dataclass(slots=True)
class SharedFrame:
    doc_id: str
    mime_type: str
    payload: bytes


class SharedImageBuffer:
    """In-memory zero-copy-ish frame buffer for live OCR previews."""

    def __init__(self, max_items: int = 64) -> None:
        self._frames: dict[str, deque[SharedFrame]] = {}
        self._max_items = max_items
        self._lock = Lock()

    def push(self, frame: SharedFrame) -> None:
        with self._lock:
            q = self._frames.setdefault(frame.doc_id, deque(maxlen=self._max_items))
            q.append(frame)

    def latest(self, doc_id: str) -> SharedFrame | None:
        with self._lock:
            q = self._frames.get(doc_id)
            if not q:
                return None
            return q[-1]
