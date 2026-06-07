from __future__ import annotations

import io
import uuid
from collections.abc import Iterable
from pathlib import Path
from typing import BinaryIO

import fsspec

from nexus_ai.core.config import AppConfig


class StorageService:
    """Unified file storage service with chunked streaming writes."""

    def __init__(self, config: AppConfig):
        self.storage_root = config.base_dir / "app_data" / "scans"
        self._ensure_storage_exists()
        self._fs = fsspec.filesystem("file")

    def _ensure_storage_exists(self) -> None:
        self.storage_root.mkdir(parents=True, exist_ok=True)

    def _destination_path(self, original_name: str | None = None) -> Path:
        suffix = Path(original_name or "").suffix
        return self.storage_root / f"{uuid.uuid4().hex}{suffix}"

    def save_invoice_stream(
        self,
        stream: BinaryIO | Iterable[bytes],
        original_name: str | None = None,
        chunk_size: int = 1024 * 1024,
    ) -> str:
        """Save file content using chunked streaming to avoid high RAM usage."""
        destination_path = self._destination_path(original_name)

        with self._fs.open(str(destination_path), "wb") as out:
            if hasattr(stream, "read"):
                file_obj = stream  # type: ignore[assignment]
                while True:
                    chunk = file_obj.read(chunk_size)
                    if not chunk:
                        break
                    out.write(chunk)
            else:
                for chunk in stream:
                    if chunk:
                        out.write(chunk)

        return str(destination_path)

    def save_invoice_file(self, source_path: str) -> str:
        """Copy file to internal storage in streaming mode."""
        source_file = Path(source_path)
        if not source_file.exists():
            raise FileNotFoundError(f"Nie znaleziono pliku: {source_path}")

        with source_file.open("rb") as src:
            return self.save_invoice_stream(src, original_name=source_file.name)

    def save_invoice_bytes(self, payload: bytes, original_name: str | None = None) -> str:
        """Compatibility helper for in-memory payloads."""
        return self.save_invoice_stream(io.BytesIO(payload), original_name=original_name)
