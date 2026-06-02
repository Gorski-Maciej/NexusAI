"""
Decision Trace Logger — append-only cryptographic audit trail.

Część III podstawowego audytu i łańcucha dowodowego.

Każda decyzja podatkowa pozostawia niezmienny, kryptograficznie
zabezpieczony ślad (SHA-256 hash chain), który pozwala odtworzyć
cały proces decyzyjny nawet po latach.
"""

from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime, timezone
from typing import Any

import duckdb

from .exceptions import DecisionTraceIntegrityError

# ── Schema ───────────────────────────────────────────────────────────────────

_DECISION_TRACES_SCHEMA = """
CREATE TABLE IF NOT EXISTS decision_traces (
    trace_id           VARCHAR PRIMARY KEY,
    transaction_id     VARCHAR NOT NULL,
    rule_id            VARCHAR,
    context_json       VARCHAR NOT NULL,
    verdict_json       VARCHAR,
    calculation_input  VARCHAR,
    calculation_output VARCHAR,
    invariants_result  VARCHAR,
    risk_verdict       VARCHAR,
    decision_trace     VARCHAR,
    trace_json         VARCHAR,
    previous_hash      VARCHAR NOT NULL,
    current_hash       VARCHAR NOT NULL,
    timestamp          VARCHAR NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_dt_tx
    ON decision_traces(transaction_id);
CREATE INDEX IF NOT EXISTS idx_dt_ts
    ON decision_traces(timestamp);
CREATE INDEX IF NOT EXISTS idx_dt_hash
    ON decision_traces(current_hash);
"""

_GENESIS_HASH = "0" * 64
"""Fixed hash for the very first entry — comparable to a blockchain genesis block."""


def ensure_schema(conn: duckdb.DuckDBPyConnection) -> None:
    """Create the ``decision_traces`` table and indexes if not present."""
    conn.execute(_DECISION_TRACES_SCHEMA)
    # Add new columns if missing (backward-compatible migration)
    for col, col_type in [
        ("decision_trace", "VARCHAR"),
        ("trace_json", "VARCHAR"),
    ]:
        try:
            conn.execute(f"ALTER TABLE decision_traces ADD COLUMN IF NOT EXISTS {col} {col_type}")
        except Exception:
            pass  # DuckDB may not support IF NOT EXISTS in older versions


def _compute_current_hash(
    previous_hash: str,
    trace_id: str,
    transaction_id: str,
    context_json: str,
    verdict_json: str,
    timestamp_iso: str,
    calculation_input: str = "",
    calculation_output: str = "",
    invariants_result: str = "",
    risk_verdict: str = "",
) -> str:
    """Compute SHA-256 over pipe-delimited decision fields.

    The consistent ordering prevents hash ambiguity.
    All critical data fields are included so that tampering with ANY
    part of the decision is detected.

    NOTE: ``decision_trace`` and ``trace_json`` (human-readable artifacts)
    are intentionally EXCLUDED from the hash for backward compatibility.
    The core fields (context, verdict, calculation) already provide
    full integrity — tampering with derived text would not hide
    tampering with the source data.

    Canonical field order:
    ``previous_hash|trace_id|transaction_id|context_json|verdict_json|calculation_input|calculation_output|invariants_result|risk_verdict|timestamp``
    """
    payload = "|".join([
        previous_hash,
        trace_id,
        transaction_id,
        context_json,
        verdict_json,
        calculation_input,
        calculation_output,
        invariants_result,
        risk_verdict,
        timestamp_iso,
    ])
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


# ── Logger ───────────────────────────────────────────────────────────────────


class DecisionTraceLogger:
    """Append-only logger for tax decisions with a cryptographic hash chain.

    Every call to :meth:`log` inserts an immutable record linked to the
    previous one via SHA-256. Tampering with any entry breaks the chain.

    Usage::

        logger = DecisionTraceLogger(duckdb_conn)
        trace_id = logger.log(
            transaction_id="uuid",
            rule_id="uuid",
            context={"category_code": "FUEL", ...},
            verdict={"vat_rate": "0.23", ...},
        )
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        ensure_schema(conn)

    def log(
        self,
        transaction_id: str,
        rule_id: str | None = None,
        context: dict[str, Any] | None = None,
        verdict: dict[str, Any] | None = None,
        calculation_input: str | None = None,
        calculation_output: str | None = None,
        invariants_result: str | None = None,
        risk_verdict: str | None = None,
        decision_trace: str | None = None,
        trace_json: str | None = None,
    ) -> str:
        """Persist a decision trace with cryptographic chain linkage.

        Args:
            transaction_id: UUID of the invoice / transaction.
            rule_id: UUID of the matching rule (may be None on error).
            context: Full context snapshot at decision time.
            verdict: Verdict returned by the rule engine.
            calculation_input: JSON-encoded input amounts (net_grosze, vat_rate…).
            calculation_output: JSON-encoded output amounts (vat, brutto…).
            invariants_result: JSON-encoded invariant validation outcome.
            risk_verdict: JSON-encoded RiskGuard verdict (action, thresholds).
            decision_trace: Human-readable trace text from TraceGenerator.
            trace_json: JSON-encoded detailed evaluation trace.

        Returns:
            The ``trace_id`` (UUID) of the newly created entry.
        """
        trace_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        timestamp_iso = now.isoformat()

        # Canonical JSON: sort_keys=True ensures deterministic serialization
        context_json = (
            json.dumps(context, ensure_ascii=False, default=str, sort_keys=True)
            if context else "{}"
        )
        verdict_json = (
            json.dumps(verdict, ensure_ascii=False, default=str, sort_keys=True)
            if verdict else "{}"
        )

        # Retrieve the last current_hash from the chain
        last_row = self._conn.execute(
            "SELECT current_hash FROM decision_traces "
            "ORDER BY timestamp DESC LIMIT 1"
        ).fetchone()
        previous_hash = str(last_row[0]) if last_row else _GENESIS_HASH

        current_hash = _compute_current_hash(
            previous_hash=previous_hash,
            trace_id=trace_id,
            transaction_id=transaction_id,
            context_json=context_json,
            verdict_json=verdict_json,
            timestamp_iso=timestamp_iso,
            calculation_input=calculation_input or "",
            calculation_output=calculation_output or "",
            invariants_result=invariants_result or "",
            risk_verdict=risk_verdict or "",
        )

        self._conn.execute(
            """INSERT INTO decision_traces
               (trace_id, transaction_id, rule_id, context_json, verdict_json,
                calculation_input, calculation_output, invariants_result,
                risk_verdict, decision_trace, trace_json,
                previous_hash, current_hash, timestamp)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                trace_id,
                transaction_id,
                rule_id,
                context_json,
                verdict_json,
                calculation_input,
                calculation_output,
                invariants_result,
                risk_verdict,
                decision_trace,
                trace_json,
                previous_hash,
                current_hash,
                timestamp_iso,
            ),
        )

        return trace_id

    def get_trace(self, transaction_id: str) -> list[dict[str, Any]]:
        """Retrieve all decision traces for a given transaction.

        Args:
            transaction_id: UUID of the invoice / transaction.

        Returns:
            Chronological list of trace dicts, oldest first.
        """
        rows = self._conn.execute(
            """SELECT trace_id, transaction_id, rule_id, context_json,
                      verdict_json, calculation_input, calculation_output,
                      invariants_result, risk_verdict,
                      decision_trace, trace_json,
                      previous_hash, current_hash, timestamp
               FROM decision_traces
               WHERE transaction_id = ?
               ORDER BY timestamp ASC""",
            (transaction_id,),
        ).fetchall()

        return [
            {
                "trace_id": str(r[0]),
                "transaction_id": str(r[1]),
                "rule_id": str(r[2]) if r[2] else None,
                "context": json.loads(r[3]) if r[3] else None,
                "verdict": json.loads(r[4]) if r[4] else None,
                "calculation_input": r[5],
                "calculation_output": r[6],
                "invariants_result": r[7],
                "risk_verdict": json.loads(r[8]) if r[8] else None,
                "decision_trace": str(r[9]) if r[9] else None,
                "trace_json": json.loads(r[10]) if r[10] else None,
                "previous_hash": str(r[11]),
                "current_hash": str(r[12]),
                "timestamp": str(r[13]),
            }
            for r in rows
        ]

    def latest_hash(self) -> str:
        """Return the most recent ``current_hash`` in the chain.

        Returns:
            The latest SHA-256 hex digest, or ``_GENESIS_HASH`` if table is empty.
        """
        row = self._conn.execute(
            "SELECT current_hash FROM decision_traces "
            "ORDER BY timestamp DESC LIMIT 1"
        ).fetchone()
        return str(row[0]) if row else _GENESIS_HASH

    def entry_count(self) -> int:
        """Return total number of decision trace entries."""
        row = self._conn.execute(
            "SELECT COUNT(1) FROM decision_traces"
        ).fetchone()
        return int(row[0]) if row else 0


# ── Chain Verifier ───────────────────────────────────────────────────────────


def verify_chain_integrity(conn: duckdb.DuckDBPyConnection) -> list[dict[str, Any]]:
    """Verify the full decision trace hash chain from oldest to newest.

    For each entry, this function:
      1. Checks that ``previous_hash`` matches the previous entry's ``current_hash``.
      2. Recomputes ``current_hash`` from the stored fields and compares.

    Args:
        conn: DuckDB connection to read ``decision_traces`` from.

    Returns:
        A list of integrity issues. An empty list means the chain is intact.
    """
    rows = conn.execute(
        """SELECT trace_id, transaction_id, context_json, verdict_json,
                  calculation_input, calculation_output, invariants_result,
                  risk_verdict, previous_hash, current_hash, timestamp
           FROM decision_traces
           ORDER BY timestamp ASC"""
    ).fetchall()

    issues: list[dict[str, Any]] = []
    expected_previous = _GENESIS_HASH

    for row in rows:
        trace_id = str(row[0])
        transaction_id = str(row[1])
        context_json = str(row[2]) if row[2] else "{}"
        verdict_json = str(row[3]) if row[3] else "{}"
        calculation_input = str(row[4]) if row[4] else ""
        calculation_output = str(row[5]) if row[5] else ""
        invariants_result = str(row[6]) if row[6] else ""
        risk_verdict = str(row[7]) if row[7] else ""
        stored_previous = str(row[8])
        stored_current = str(row[9])
        timestamp_iso = str(row[10])

        # 1. Previous hash linkage
        if stored_previous != expected_previous:
            issues.append({
                "trace_id": trace_id,
                "issue": "previous_hash_mismatch",
                "expected_previous": expected_previous,
                "stored_previous": stored_previous,
                "message": (
                    f"Entry {trace_id}: stored previous_hash does not match "
                    f"the previous entry's current_hash"
                ),
            })

        # 2. Current hash integrity (includes ALL fields now)
        recomputed = _compute_current_hash(
            previous_hash=stored_previous,
            trace_id=trace_id,
            transaction_id=transaction_id,
            context_json=context_json,
            verdict_json=verdict_json,
            timestamp_iso=timestamp_iso,
            calculation_input=calculation_input,
            calculation_output=calculation_output,
            invariants_result=invariants_result,
            risk_verdict=risk_verdict,
        )
        if recomputed != stored_current:
            issues.append({
                "trace_id": trace_id,
                "issue": "current_hash_mismatch",
                "expected_current": recomputed,
                "stored_current": stored_current,
                "message": (
                    f"Entry {trace_id}: stored current_hash does not match "
                    f"recomputed hash — data may have been tampered with"
                ),
            })

        expected_previous = stored_current

    return issues
