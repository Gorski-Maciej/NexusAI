from __future__ import annotations

import uuid
from typing import Any, final

import pendulum

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.db.analytics import DuckDBManager

# ── SHA-256 przez nexus-crypto (Rust+PyO3) zgodnie z aa3fvcx.txt ─────────
try:
    from nexus_crypto import sha256 as _sha256

    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib

    HAS_NEXUS_CRYPTO = False

    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()


def ensure_forensic_audit_schema(duckdb: DuckDBManager) -> None:
    """Creates immutable-ish audit table used for cryptographic hash chaining."""
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS audit_log (
            id UUID PRIMARY KEY,
            timestamp TIMESTAMP NOT NULL,
            event_type VARCHAR NOT NULL,
            data_payload JSON NOT NULL,
            previous_hash VARCHAR NOT NULL,
            current_hash VARCHAR NOT NULL
        )
        """
    )
    duckdb.execute("CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp)")


@final
class AuditLogger:
    """Hash-chained audit logger backed by DuckDB."""

    GENESIS_HASH = "0"

    def __init__(self, duckdb: DuckDBManager):
        self.duckdb = duckdb
        ensure_forensic_audit_schema(self.duckdb)

    @staticmethod
    def _canonical_payload(data_payload: dict[str, Any]) -> str:
        return msgspec_dumps(
            data_payload, sort_keys=True, ensure_ascii=False, separators=(",", ":")
        )

    @classmethod
    def _compute_hash(cls, previous_hash: str, payload_json: str) -> str:
        base = f"{previous_hash}{payload_json}".encode()
        return _sha256(base)

    def append_event(self, event_type: str, data_payload: dict[str, Any]) -> str:
        """Appends new audit event with chained hash; returns current hash."""
        connection = self.duckdb.connect()
        payload_json = self._canonical_payload(data_payload)
        timestamp = pendulum.now("UTC").replace(microsecond=0).isoformat()

        connection.execute("BEGIN TRANSACTION")
        try:
            row = connection.execute(
                "SELECT current_hash FROM audit_log ORDER BY timestamp DESC, id DESC LIMIT 1"
            ).fetchone()
            previous_hash = row[0] if row else self.GENESIS_HASH
            current_hash = self._compute_hash(previous_hash, payload_json)

            connection.execute(
                """
                INSERT INTO audit_log (id, timestamp, event_type, data_payload, previous_hash, current_hash)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    uuid.uuid4().hex,
                    timestamp,
                    event_type,
                    payload_json,
                    previous_hash,
                    current_hash,
                ),
            )
            connection.execute("COMMIT")
            return current_hash
        except Exception:
            connection.execute("ROLLBACK")
            raise

    def verify_chain(self) -> tuple[bool, str | None]:
        """Verifies full chain integrity. Returns (is_valid, first_broken_event_id)."""
        rows = self.duckdb.execute(
            """
            SELECT id, data_payload, previous_hash, current_hash
            FROM audit_log
            ORDER BY timestamp ASC, id ASC
            """
        )

        expected_previous = self.GENESIS_HASH
        for event_id, payload, previous_hash, current_hash in rows:
            if previous_hash != expected_previous:
                return False, str(event_id)

            payload_json = self._canonical_payload(
                payload if isinstance(payload, dict) else msgspec_loads(payload)
            )
            expected_current = self._compute_hash(previous_hash, payload_json)
            if current_hash != expected_current:
                return False, str(event_id)

            expected_previous = current_hash

        return True, None
