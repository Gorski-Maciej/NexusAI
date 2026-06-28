# core/ipc/shm_manager.py
"""Shared memory buffer for zero-copy IPC using raw bytes.

Replaces previous numpy-based implementation with raw memoryview/bytes
operations for compatibility with PIL Images.
"""

from __future__ import annotations

from multiprocessing import shared_memory
from typing import Any


class SharedImageBuffer:
    """Klasa do obsługi Zero-Copy IPC dla obrazów (raw bytes)."""

    @staticmethod
    def create(data: bytes) -> dict:
        """Tworzy blok w pamięci RAM i kopiuje do niego dane obrazu.

        Args:
            data: Raw bytes obrazu (np. z PIL Image.tobytes()).

        Returns:
            Dict z metadanymi do późniejszego odtworzenia.
        """
        shm = shared_memory.SharedMemory(create=True, size=len(data))

        # Kopiujemy dane do współdzielonego bloku przez memoryview
        buf = memoryview(shm.buf)
        buf[: len(data)] = data

        return {
            "shm_name": shm.name,
            "size": len(data),
        }

    @staticmethod
    def attach(metadata: dict) -> bytes:
        """Podłącza się do istniejącego bloku pamięci i zwraca dane.

        Args:
            metadata: Dict z poprzedniego wywołania create().

        Returns:
            bytes — dane obrazu.
        """
        shm = shared_memory.SharedMemory(name=metadata["shm_name"])
        buf = memoryview(shm.buf)
        return bytes(buf[: metadata["size"]])
