"""Shared vectorization utilities and DB helpers for agent decisions.

Consolidates duplicated patterns:
- _vectorize_invoice (orchestrator.py, extraction.py → here)
- hashlib.sha256 768-dim vector (knowledge_mesh, error_handbook, orchestrator)
- anyio.to_thread.run_sync execute pattern (telemetry_store, knowledge_mesh, error_handbook)

Usage:
    from nexus_ai.core.vectorize import vectorize_invoice, execute_db, vectorize_text
"""

from __future__ import annotations

import hashlib
import json
from typing import Any

import anyio

EMBEDDING_DIM: int = 768
"""Default embedding dimension for invoice/rule vectors."""


# ── Vectorization ───────────────────────────────────────────────────────


def vectorize_invoice(invoice_data: dict[str, Any], dim: int = EMBEDDING_DIM) -> list[float]:
    """Convert invoice data to a fixed-dimension float vector via SHA-256.

    Consolidates _vectorize_invoice from orchestrator.py.

    Args:
        invoice_data: Dictionary of invoice fields.
        dim: Target embedding dimension (default 768).

    Returns:
        A normalized float vector of length `dim`.
    """
    text = json.dumps(invoice_data, sort_keys=True)
    hash_bytes = hashlib.sha256(text.encode()).digest()
    return [float(hash_bytes[i % 32]) / 255.0 for i in range(dim)]


def vectorize_text(*parts: str, dim: int = EMBEDDING_DIM) -> list[float]:
    """Convert text parts to a fixed-dimension vector.

    Consolidates _vectorize from knowledge_mesh.py, error_handbook.py.

    Args:
        *parts: Text parts to concatenate with ':' separator.
        dim: Target embedding dimension.

    Returns:
        A normalized float vector.
    """
    text = ":".join(parts)
    hash_bytes = hashlib.sha256(text.encode()).digest()
    return [float(hash_bytes[i % 32]) / 255.0 for i in range(dim)]


# ── DB Helpers ──────────────────────────────────────────────────────────


async def execute_db(conn: Any, sql: str, params: list | tuple | None = None) -> Any:
    """Execute a DuckDB/SQLite query via anyio thread, returning the result.

    Consolidates the repetitive ``await anyio.to_thread.run_sync(lambda: self._conn.execute(...))``
    pattern found in telemetry_store.py, knowledge_mesh.py, and error_handbook.py.

    Args:
        conn: DuckDB or SQLite connection object.
        sql: SQL statement.
        params: Optional bind parameters.

    Returns:
        The result of ``conn.execute(sql, params)``.
    """
    if params is not None:
        return await anyio.to_thread.run_sync(
            lambda: conn.execute(sql, params)
        )
    return await anyio.to_thread.run_sync(
        lambda: conn.execute(sql)
    )


async def execute_db_fetchall(
    conn: Any,
    sql: str,
    params: list | tuple | None = None,
) -> list[Any]:
    """Execute a query and fetch all rows.

    Args:
        conn: DB connection.
        sql: SQL statement.
        params: Optional bind parameters.

    Returns:
        List of rows.
    """
    cursor = await execute_db(conn, sql, params)
    return cursor.fetchall() if cursor else []


async def execute_db_fetchone(
    conn: Any,
    sql: str,
    params: list | tuple | None = None,
) -> Any:
    """Execute a query and fetch one row.

    Args:
        conn: DB connection.
        sql: SQL statement.
        params: Optional bind parameters.

    Returns:
        A single row or None.
    """
    cursor = await execute_db(conn, sql, params)
    return cursor.fetchone() if cursor else None


def get_columns(cursor: Any) -> list[str]:
    """Extract column names from a DB cursor/result description.

    Args:
        cursor: A DB cursor or result with a ``description`` attribute.

    Returns:
        List of column names.
    """
    return [desc[0] for desc in cursor.description] if cursor and cursor.description else []
