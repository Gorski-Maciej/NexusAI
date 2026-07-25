"""
Query utilities — shared helpers for database query classification.

Used by DatabaseFirewall and DatabaseObservability to avoid code duplication.
"""

from __future__ import annotations

from typing import Literal

QueryType = Literal["SELECT", "INSERT", "UPDATE", "DELETE", "DDL", "OTHER"]


def classify_query(sql: str) -> QueryType:
    """Classify a SQL statement into a query type.

    Args:
        sql: The SQL statement to classify.

    Returns:
        QueryType enum value.
    """
    if not sql:
        return "OTHER"
    upper = sql.strip().upper()
    if upper.startswith("SELECT"):
        return "SELECT"
    if upper.startswith("INSERT"):
        return "INSERT"
    if upper.startswith("UPDATE"):
        return "UPDATE"
    if upper.startswith("DELETE"):
        return "DELETE"
    if any(
        upper.startswith(kw)
        for kw in ("CREATE", "ALTER", "DROP", "TRUNCATE", "PRAGMA", "EXPLAIN")
    ):
        return "DDL"
    return "OTHER"
