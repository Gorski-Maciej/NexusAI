from __future__ import annotations

import io
import time
from collections import deque
from dataclasses import dataclass, field
from threading import Lock

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


@dataclass(slots=True)
class SharedFrame:
    doc_id: str
    mime_type: str
    payload: bytes
    timestamp: float = field(default_factory=time.time)
    size_bytes: int = 0

    def __post_init__(self) -> None:
        self.size_bytes = len(self.payload)


class SharedImageBuffer:
    """In-memory frame buffer for live OCR previews with global memory limits and TTL.

    Rozwiązanie 12: Zabezpieczenia przed przeciążeniem pamięci:
    - Globalny limit pamięci (domyślnie 256 MB)
    - TTL dla ramek (domyślnie 5 minut)
    - clear_doc(doc_id) do usuwania ramek po zakończeniu przetwarzania
    - Opcjonalna kompresja JPEG dla obrazów
    """

    def __init__(
        self,
        max_items: int = 64,
        max_total_memory_mb: int = 256,
        ttl_seconds: int = 300,
    ) -> None:
        self._frames: dict[str, deque[SharedFrame]] = {}
        self._max_items = max_items
        self._max_total_memory_bytes = max_total_memory_mb * 1024 * 1024
        self._ttl_seconds = ttl_seconds
        self._lock = Lock()
        self._total_bytes = 0

    def push(self, frame: SharedFrame, compress_jpeg: bool = True) -> None:
        """Dodaje ramkę z opcjonalną kompresją JPEG i kontrolą globalnego limitu pamięci."""
        with self._lock:
            # Opcjonalna kompresja JPEG dla obrazów
            if compress_jpeg and HAS_PIL and frame.mime_type in ("image/png", "image/tiff", "image/bmp", "image/webp"):
                try:
                    img = Image.open(io.BytesIO(frame.payload))
                    rgb = img.convert("RGB")
                    buf = io.BytesIO()
                    rgb.save(buf, format="JPEG", quality=70, optimize=True)
                    compressed = buf.getvalue()
                    if len(compressed) < len(frame.payload) * 0.9:  # Tylko jeśli faktycznie mniejsze
                        frame.payload = compressed
                        frame.mime_type = "image/jpeg"
                        frame.size_bytes = len(compressed)
                except Exception:
                    pass  # W razie błędu użyj oryginalnych danych

            q = self._frames.setdefault(frame.doc_id, deque(maxlen=self._max_items))
            q.append(frame)
            self._total_bytes += frame.size_bytes

            # Jeśli przekroczono globalny limit pamięci, usuń najstarsze ramki
            self._evict_if_needed()

    def latest(self, doc_id: str) -> SharedFrame | None:
        """Zwraca najnowszą ramkę dla danego dokumentu."""
        with self._lock:
            self._purge_expired_frames()
            q = self._frames.get(doc_id)
            if not q or len(q) == 0:
                return None
            # Sprawdź TTL najnowszej ramki
            latest_frame = q[-1]
            if time.time() - latest_frame.timestamp > self._ttl_seconds:
                return None
            return latest_frame

    def clear_doc(self, doc_id: str) -> int:
        """Usuwa wszystkie ramki dla danego dokumentu. Zwraca liczbę usuniętych bajtów."""
        with self._lock:
            q = self._frames.pop(doc_id, None)
            if not q:
                return 0
            freed = sum(frame.size_bytes for frame in q)
            self._total_bytes -= freed
            q.clear()
            return freed

    def get_total_memory_bytes(self) -> int:
        """Zwraca całkowity rozmiar pamięci używanej przez bufor."""
        with self._lock:
            return self._total_bytes

    def get_total_memory_mb(self) -> float:
        """Zwraca całkowity rozmiar pamięci w MB."""
        return self.get_total_memory_bytes() / (1024 * 1024)

    def _evict_if_needed(self) -> None:
        """Usuwa najstarsze ramki, jeśli przekroczono globalny limit pamięci."""
        if self._total_bytes <= self._max_total_memory_bytes:
            return

        # Posortuj dokumenty według czasu najstarszej ramki
        doc_oldest: dict[str, float] = {}
        for doc_id, q in self._frames.items():
            if q:
                doc_oldest[doc_id] = q[0].timestamp

        # Usuwaj ramki od najstarszych dokumentów
        sorted_docs = sorted(doc_oldest.items(), key=lambda x: x[1])
        while self._total_bytes > self._max_total_memory_bytes and sorted_docs:
            oldest_doc_id, _ = sorted_docs.pop(0)
            q = self._frames.get(oldest_doc_id)
            if q and len(q) > 0:
                removed = q.popleft()
                self._total_bytes -= removed.size_bytes

            # Jeśli dokument nie ma już ramek, usuń go
            if q and len(q) == 0:
                self._frames.pop(oldest_doc_id, None)

    def _purge_expired_frames(self) -> None:
        """Usuwa ramki starsze niż TTL."""
        now = time.time()
        expired_docs: list[str] = []
        for doc_id, q in self._frames.items():
            # Usuń tylko jeśli wszystkie ramki są wygasłe
            if q and (now - q[-1].timestamp) > self._ttl_seconds:
                expired_docs.append(doc_id)

        for doc_id in expired_docs:
            q = self._frames.pop(doc_id, None)
            if q:
                freed = sum(frame.size_bytes for frame in q)
                self._total_bytes -= freed
                q.clear()

    def periodic_cleanup(self) -> int:
        """Okresowe czyszczenie (do wywołania przez cron). Usuwa wygasłe ramki i zwalnia pamięć.
        Returns: liczba usuniętych dokumentów.
        """
        with self._lock:
            before = self._total_bytes
            self._purge_expired_frames()
            self._evict_if_needed()
            freed = before - self._total_bytes
            return freed
