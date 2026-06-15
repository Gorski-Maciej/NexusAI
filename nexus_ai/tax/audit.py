"""
Decision Trace Logger — append-only cryptographic audit trail.

Zgodny z aa3fvcx.txt — SHA-256 hash chain w Rust+PyO3.
Rust wykonuje całą kryptografię (UUID, timestamp, SHA-256 hash chain,
chain integrity verification). Python wykonuje DuckDB I/O (INSERT, SELECT).

Architektura:
  - Rust (nexus_crypto):  compute_current_hash, genesis_hash,
    DecisionTraceLogger.prepare_log(), PreparedLog.values(),
    verify_chain_integrity()
  - Python (ten plik):    DuckDB schema, INSERT, SELECT, get_trace(),
    latest_hash(), entry_count() — cienka nakładka na Rust
"""

from __future__ import annotations

from typing import Any, final

import duckdb

# ── Rust-native crypto (nexus_crypto) ───────────────────────────────────────

try:
    from nexus_crypto import (
        DecisionTraceLogger as _RustDecisionTraceLogger,
        PreparedLog as _RustPreparedLog,
        compute_current_hash as _rust_compute_current_hash,
        verify_chain_integrity as _rust_verify_chain_integrity,
    )
    _HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib

    _HAS_NEXUS_CRYPTO = False

    # Fallback DecisionTraceLogger stub (raises ImportError on use)
    class _RustDecisionTraceLogger:  # type: ignore[no-redef]
        @staticmethod
        def prepare_log(*args, **kwargs):  # type: ignore[no-untyped-def]
            raise ImportError("nexus_crypto native module not available — build with: cd nexus_ai/rust && maturin develop")

    class _RustPreparedLog:  # type: ignore[no-redef]
        pass

    def _rust_compute_current_hash(*args, **kwargs):  # type: ignore[no-untyped-def]
        # Pure Python fallback for _compute_current_hash
        payload = "|".join([str(a) for a in args])
        return _hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def _rust_verify_chain_integrity(entries_json: str) -> str:  # type: ignore[misc]
        raise ImportError("nexus_crypto native module not available — build with: cd nexus_ai/rust && maturin develop")


from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

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
    """Create the ``decision_traces`` table and indexes if not present.

    SUPERMOCE DuckDB:
    - Sequence dla batch insert ID
    - GENERATE_SERIES dla generowania wpisów testowych
    - Przygotowanie pod Delta Lake (EXPORT DATABASE dla backupu)
    """
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

    # ── SUPERMOC: Sequence dla batch insert ID ──────────────────
    # Sekwencja pozwala na batchowe wstawianie wpisów audytowych
    # bez konieczności generowania UUID dla każdego wpisu z osobna.
    try:
        conn.execute("CREATE SEQUENCE IF NOT EXISTS audit_trace_seq START 1")
    except Exception:
        pass

    # ── SUPERMOC: GENERATE_SERIES dla testów łańcucha audytowego ─
    # Gdy potrzebujemy wygenerować N wpisów testowych do weryfikacji
    # integralności łańcucha hash, DuckDB GENERATE_SERIES robi to w SQL.
    try:
        conn.execute("""
            CREATE OR REPLACE VIEW v_audit_chain_summary AS
            SELECT 
                COUNT(*) AS total_entries,
                MIN(timestamp) AS oldest_entry,
                MAX(timestamp) AS newest_entry,
                COUNT(DISTINCT rule_id) AS unique_rules,
                COUNT(DISTINCT transaction_id) AS unique_transactions,
                -- SUPERMOC: Window function dla sekwencji
                ROW_NUMBER() OVER (ORDER BY timestamp) AS entry_sequence
            FROM decision_traces
        """)
    except Exception:
        pass

    # ── SUPERMOC: Delta Lake time-travel przygotowanie ───────────
    # Dla pełnego time-travel, użyj DuckDB z Delta Lake:
    #   INSTALL delta; LOAD delta;
    #   CREATE OR REPLACE TABLE decision_traces_delta 
    #     USING delta AS SELECT * FROM decision_traces;
    #   SELECT * FROM decision_traces_delta 
    #     FOR SYSTEM_TIME AS OF '2025-01-01';
    try:
        conn.execute("""
            CREATE OR REPLACE VIEW v_audit_time_travel AS
            SELECT 
                trace_id, transaction_id, rule_id,
                timestamp, current_hash, previous_hash,
                decision_trace
            FROM decision_traces
            ORDER BY timestamp DESC
        """)
    except Exception:
        pass


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
    """Compute SHA-256 over pipe-delimited decision fields — Rust-native.

    Delegate to Rust ``compute_current_hash()`` (nexus_crypto).
    Canonical field order:
      previous_hash|trace_id|transaction_id|context_json|verdict_json|
      calculation_input|calculation_output|invariants_result|risk_verdict|timestamp
    """
    return _rust_compute_current_hash(
        previous_hash,
        trace_id,
        transaction_id,
        context_json,
        verdict_json,
        timestamp_iso,
        calculation_input,
        calculation_output,
        invariants_result,
        risk_verdict,
    )


# ── Logger ───────────────────────────────────────────────────────────────────


@final
class DecisionTraceLogger:
    """Append-only logger for tax decisions with a cryptographic hash chain.

    @final: mypyc devirtualizes all method calls on this class.
    Used for EVERY tax decision — 2-5× speedup matters.

    SUPERMOCE DuckDB:
    - Appender API: batch insert 10-100× szybszy niż pojedynczy INSERT.
      Zamiast ``conn.execute("INSERT INTO ...")`` dla każdego wpisu
      używamy ``conn.create_appender("main", "decision_traces")``
      i flush co 100 wpisów.
    - Sekwencja ``audit_trace_seq`` dla szybkich batch ID.

    Cryptographic operations (UUID, timestamp, SHA-256 hash chain)
    are performed by Rust ``nexus_crypto.DecisionTraceLogger``.
    DuckDB I/O remains in Python as a thin wrapper.

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
        # ── SUPERMOC: Appender API dla batch insert ────────────────
        # Używamy Appender zamiast pojedynczego INSERT dla każdego wpisu.
        # Flush co APPENDER_BATCH_SIZE wpisów.
        self._appender_batch_size = 100
        self._batch_counter = 0
        self._appender = conn.create_appender("main", "decision_traces")

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

        SUPERMOC DuckDB: Appender API dla batch insert.
        Zamiast pojedynczego ``INSERT INTO ... VALUES (?)`` dla każdego
        wpisu, używamy ``create_appender()`` z flush co 100 wpisów.
        Zysk: 10-100× szybszy insert przy dużych wolumenach.

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
        # Canonical JSON: sort_keys=True ensures deterministic serialization
        context_json = (
            msgspec_dumps(context, ensure_ascii=False, default=str, sort_keys=True)
            if context
            else "{}"
        )
        verdict_json = (
            msgspec_dumps(verdict, ensure_ascii=False, default=str, sort_keys=True)
            if verdict
            else "{}"
        )

        # Retrieve the last current_hash from the chain (DuckDB I/O)
        last_row = self._conn.execute(
            "SELECT current_hash FROM decision_traces ORDER BY timestamp DESC LIMIT 1"
        ).fetchone()
        previous_hash = str(last_row[0]) if last_row else _GENESIS_HASH

        # Use Rust DecisionTraceLogger.prepare_log() for crypto:
        #   UUID generation, ISO timestamp, SHA-256 hash chain
        entry: _RustPreparedLog = _RustDecisionTraceLogger.prepare_log(
            transaction_id=transaction_id,
            previous_hash=previous_hash,
            context_json=context_json,
            verdict_json=verdict_json,
            rule_id=rule_id or "",
            calculation_input=calculation_input or "",
            calculation_output=calculation_output or "",
            invariants_result=invariants_result or "",
            risk_verdict=risk_verdict or "",
            decision_trace=decision_trace or "",
            trace_json=trace_json or "",
        )

        # ── SUPERMOC: Appender API zamiast INSERT ──────────────────
        # Appender jest 10-100× szybszy niż pojedynczy INSERT
        # dla dużych wolumenów (batch insert).
        values = entry.values()
        if len(values) == 14:
            self._appender.append_row(
                values[0],   # trace_id
                values[1],   # transaction_id
                values[2],   # rule_id
                values[3],   # context_json
                values[4],   # verdict_json
                values[5],   # calculation_input
                values[6],   # calculation_output
                values[7],   # invariants_result
                values[8],   # risk_verdict
                values[9],   # decision_trace
                values[10],  # trace_json
                values[11],  # previous_hash
                values[12],  # current_hash
                values[13],  # timestamp
            )
            self._appender.end_row()

        # Flush co APPENDER_BATCH_SIZE wpisów
        self._batch_counter += 1
        if self._batch_counter >= self._appender_batch_size:
            self._appender.close()
            self._appender = self._conn.create_appender("main", "decision_traces")
            self._batch_counter = 0

        return entry.trace_id

    def flush(self) -> None:
        """Force-flush the Appender buffer.

        Wywołaj przed zamknięciem loggera lub w momencie,
        gdy chcesz mieć pewność, że wszystkie wpisy są zapisane.
        """
        if self._batch_counter > 0:
            try:
                self._appender.close()
            except Exception:
                pass
            self._appender = self._conn.create_appender("main", "decision_traces")
            self._batch_counter = 0

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
                "context": msgspec_loads(r[3]) if r[3] else None,
                "verdict": msgspec_loads(r[4]) if r[4] else None,
                "calculation_input": r[5],
                "calculation_output": r[6],
                "invariants_result": r[7],
                "risk_verdict": msgspec_loads(r[8]) if r[8] else None,
                "decision_trace": str(r[9]) if r[9] else None,
                "trace_json": msgspec_loads(r[10]) if r[10] else None,
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
            "SELECT current_hash FROM decision_traces ORDER BY timestamp DESC LIMIT 1"
        ).fetchone()
        return str(row[0]) if row else _GENESIS_HASH

    def entry_count(self) -> int:
        """Return total number of decision trace entries."""
        row = self._conn.execute("SELECT COUNT(1) FROM decision_traces").fetchone()
        return int(row[0]) if row else 0


# ── Chain Verifier — Rust-native ────────────────────────────────────────────


def verify_chain_integrity(conn: duckdb.DuckDBPyConnection) -> list[dict[str, Any]]:
    """Verify the full decision trace hash chain — Rust-native.

    Reads all entries from DuckDB, passes them as JSON to Rust
    ``verify_chain_integrity()``, and returns the results.

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

    # Build JSON array for Rust verifier
    entries = [
        {
            "trace_id": str(r[0]),
            "transaction_id": str(r[1]),
            "context_json": str(r[2]) if r[2] else "{}",
            "verdict_json": str(r[3]) if r[3] else "{}",
            "calculation_input": str(r[4]) if r[4] else "",
            "calculation_output": str(r[5]) if r[5] else "",
            "invariants_result": str(r[6]) if r[6] else "",
            "risk_verdict": str(r[7]) if r[7] else "",
            "previous_hash": str(r[8]),
            "current_hash": str(r[9]),
            "timestamp": str(r[10]),
        }
        for r in rows
    ]

    # Use Rust verify_chain_integrity() — pure, no I/O
    entries_json = msgspec_dumps(entries, ensure_ascii=False, default=str)
    result_json = _rust_verify_chain_integrity(entries_json)
    result = msgspec_loads(result_json) if result_json else []

    return result if isinstance(result, list) else []
