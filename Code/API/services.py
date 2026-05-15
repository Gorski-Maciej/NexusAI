"""Application services for idempotency and file storage."""
from __future__ import annotations

import hashlib
import json
import os
import sqlite3
import tempfile
import importlib.util
from io import BytesIO
from contextlib import suppress
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


def _load_fsspec_module():
    if importlib.util.find_spec("fsspec") is None:
        return None
    import fsspec
    return fsspec


fsspec = _load_fsspec_module()


@dataclass(slots=True)
class StoredUpload:
    file_hash: str
    file_path: str
    size_bytes: int


class ContentAddressableStorage:
    """File storage using SHA-256 as canonical key (dedupe-friendly)."""

    def __init__(self, root: Path) -> None:
        self.root = root
        if fsspec is not None:
            self.fs = fsspec.filesystem("file")
            self.fs.makedirs(str(self.root), exist_ok=True)
        else:
            self.fs = None
            self.root.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _sha256(payload: bytes) -> str:
        return hashlib.sha256(payload).hexdigest()

    def put(self, payload: bytes, suffix: str = ".pdf") -> StoredUpload:
        digest = self._sha256(payload)
        dir_path = self.root / digest[:2] / digest[2:4]
        (self.fs.makedirs(str(dir_path), exist_ok=True) if self.fs is not None else dir_path.mkdir(parents=True, exist_ok=True))
        file_path = dir_path / f"{digest}{suffix}"

        if self.fs is not None:
            if not self.fs.exists(str(file_path)):
                with self.fs.open(str(file_path), "wb") as f:
                    f.write(payload)
        else:
            if not file_path.exists():
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.write_bytes(payload)

        return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=len(payload))

    def create_temp_upload_file(self) -> str:
        with tempfile.NamedTemporaryFile(prefix="upload_", suffix=".tmp", dir=str(self.root), delete=False) as tmp:
            return tmp.name

    def finalize_temp_upload(self, temp_path: str, digest: str, size_bytes: int, suffix: str = ".pdf") -> StoredUpload:
        dir_path = self.root / digest[:2] / digest[2:4]
        (self.fs.makedirs(str(dir_path), exist_ok=True) if self.fs is not None else dir_path.mkdir(parents=True, exist_ok=True))
        file_path = dir_path / f"{digest}{suffix}"
        if (self.fs.exists(str(file_path)) if self.fs is not None else file_path.exists()):
            with suppress(FileNotFoundError):
                os.unlink(temp_path)
            return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=size_bytes)
        if self.fs is not None:
            self.fs.mv(temp_path, str(file_path))
        else:
            Path(temp_path).replace(file_path)
        self._save_archive_variant(file_path=file_path, suffix=suffix)
        return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=size_bytes)


    def _save_archive_variant(self, file_path: Path, suffix: str) -> None:
        """Best-effort archival compression for image uploads (non-destructive sidecar)."""
        ext = suffix.lower()
        if ext not in {".png", ".tif", ".tiff", ".bmp"}:
            return
        if file_path.with_suffix(".jpg").exists():
            return
        try:
            from PIL import Image
        except Exception:
            return
        try:
            with Image.open(file_path) as img:
                rgb = img.convert("RGB")
                rgb.save(file_path.with_suffix(".jpg"), format="JPEG", quality=80, optimize=True)
        except Exception:
            return


class IdempotencyStore:
    """SQLite-backed idempotency registry with payload hash and TTL."""

    def __init__(self, db_path: Path, ttl_minutes: int = 60) -> None:
        self.db_path = db_path
        self.ttl_minutes = ttl_minutes
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.db_path)

    def _init_db(self) -> None:
        with self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS idempotency_requests (
                    idempotency_key TEXT PRIMARY KEY,
                    payload_hash TEXT NOT NULL,
                    response_json TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )

    @staticmethod
    def hash_payload(payload: bytes) -> str:
        return hashlib.sha256(payload).hexdigest()

    @staticmethod
    def hash_chunks(chunks: Iterable[bytes]) -> str:
        hasher = hashlib.sha256()
        for chunk in chunks:
            if chunk:
                hasher.update(chunk)
        return hasher.hexdigest()

    def purge_expired(self) -> None:
        threshold = datetime.now(timezone.utc) - timedelta(minutes=self.ttl_minutes)
        with self._connect() as connection:
            connection.execute(
                "DELETE FROM idempotency_requests WHERE created_at < ?",
                (threshold.isoformat(),),
            )

    def get(self, key: str, payload_hash: str) -> dict[str, Any] | None:
        self.purge_expired()
        with self._connect() as connection:
            row = connection.execute(
                "SELECT payload_hash, response_json FROM idempotency_requests WHERE idempotency_key = ?",
                (key,),
            ).fetchone()

        if not row:
            return None

        persisted_hash, response_json = row
        if persisted_hash != payload_hash:
            raise ValueError("Idempotency-Key reused with different payload")

        return json.loads(response_json)

    def save(self, key: str, payload_hash: str, response: dict[str, Any]) -> None:
        with self._connect() as connection:
            connection.execute(
                """
                INSERT OR REPLACE INTO idempotency_requests
                (idempotency_key, payload_hash, response_json, created_at)
                VALUES (?, ?, ?, ?)
                """,
                (key, payload_hash, json.dumps(response), datetime.now(timezone.utc).isoformat()),
            )
