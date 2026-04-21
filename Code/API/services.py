"""Application services for idempotency and file storage."""
from __future__ import annotations

import hashlib
import json
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


@dataclass(slots=True)
class StoredUpload:
    file_hash: str
    file_path: str
    size_bytes: int


class ContentAddressableStorage:
    """File storage using SHA-256 as canonical key (dedupe-friendly)."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.root.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _sha256(payload: bytes) -> str:
        return hashlib.sha256(payload).hexdigest()

    def put(self, payload: bytes, suffix: str = ".pdf") -> StoredUpload:
        digest = self._sha256(payload)
        dir_path = self.root / digest[:2] / digest[2:4]
        dir_path.mkdir(parents=True, exist_ok=True)
        file_path = dir_path / f"{digest}{suffix}"

        if not file_path.exists():
            file_path.write_bytes(payload)

        return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=len(payload))


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
