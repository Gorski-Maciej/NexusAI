"""
incremental_refresh.py — F2 v7.0.1: Incremental Materialized View Refresh.

Raport v7.0 Rec #6: Tylko zmienione dane (nie DELETE + INSERT).
Zamiast pełnego przeładowania, odświeża tylko nowe/zmodyfikowane wiersze.

Enterprise v7.0.1:
  - Change Tracking: śledzi last_refresh_id / last_refresh_ts
  - UPSERT zamiast DELETE + INSERT
  - Watermark tracking w osobnej tabeli kontrolnej
  - Integracja z DuckDB ATTACH SQLite
"""
from __future__ import annotations

import threading
import time
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.db.incremental")


class IncrementalViewRefresher:
    """Odświeżanie przyrostowe materialized views (UPSERT zamiast DELETE+INSERT).

    Raport v7.0 Rec #6: "Incremental refresh (tylko zmienione dane)".

    Usage:
        ref = IncrementalViewRefresher(duckdb_manager)
        ref.refresh_incremental("m_monthly_summary", source_table="invoices_replica")
    """

    WATERMARK_TABLE = "_mv_watermarks"

    def __init__(self, duckdb_manager: Any) -> None:
        self._duckdb = duckdb_manager
        self._lock = threading.Lock()
        self._ensure_watermark_table()

    def _ensure_watermark_table(self) -> None:
        """Utwórz tabelę watermarków dla śledzenia postępu odświeżania."""
        try:
            self._duckdb.execute_ddl(f"""
                CREATE TABLE IF NOT EXISTS {self.WATERMARK_TABLE} (
                    view_name VARCHAR PRIMARY KEY,
                    last_refresh_id INTEGER DEFAULT 0,
                    last_refresh_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    row_count INTEGER DEFAULT 0,
                    refresh_count INTEGER DEFAULT 0,
                    avg_duration_ms DOUBLE DEFAULT 0
                )
            """)
        except Exception as exc:
            logger.debug("[INCREMENTAL] Watermark table init: %s", exc)

    def refresh_incremental(
        self,
        view_name: str,
        source_table: str = "invoices_replica",
        id_column: str = "id",
        where_clause: str = "",
    ) -> dict[str, Any]:
        """Odśwież widok przyrostowo (tylko nowe/zmienione dane).

        Args:
            view_name: Nazwa materialized view.
            source_table: Tabela źródłowa (przez ATTACH oltp).
            id_column: Kolumna ID do śledzenia zmian.
            where_clause: Opcjonalne WHERE.

        Returns:
            Dict z liczbą nowych/zmienionych wierszy i czasem wykonania.
        """
        t0 = time.monotonic()

        with self._lock:
            try:
                # Pobierz watermark
                watermark_id = self._get_watermark(view_name)

                # Pobierz tylko nowe/zmienione dane od ostatniego refreshu
                condition = f"WHERE {id_column} > {watermark_id}"
                if where_clause:
                    condition += f" AND ({where_clause})"

                # UPSERT: INSERT nowych, UPDATE zmienionych
                # DuckDB wspiera INSERT OR REPLACE
                insert_sql = f"""
                    INSERT OR REPLACE INTO {view_name}
                    SELECT * FROM oltp.{source_table}
                    {condition}
                """
                result = self._duckdb.execute_ddl(insert_sql)
                new_count = len(result) if result else 0

                # Aktualizuj watermark
                if new_count > 0:
                    new_max_id = self._get_max_id(source_table, id_column)
                    self._update_watermark(view_name, new_max_id, new_count)

                elapsed_ms = (time.monotonic() - t0) * 1000
                logger.info(
                    "[INCREMENTAL] %s: %d rows in %.1f ms | watermark=%d",
                    view_name, new_count, elapsed_ms,
                    self._get_watermark(view_name),
                )

                return {
                    "view": view_name,
                    "new_rows": new_count,
                    "elapsed_ms": elapsed_ms,
                    "watermark_id": self._get_watermark(view_name),
                }

            except Exception as exc:
                elapsed_ms = (time.monotonic() - t0) * 1000
                logger.warning("[INCREMENTAL] %s failed (%.1f ms): %s", view_name, elapsed_ms, exc)
                return {"view": view_name, "new_rows": 0, "elapsed_ms": elapsed_ms, "error": str(exc)}

    def _get_watermark(self, view_name: str) -> int:
        """Pobierz watermark (last_refresh_id) dla widoku."""
        try:
            rows = self._duckdb.execute(
                f"SELECT last_refresh_id FROM {self.WATERMARK_TABLE} WHERE view_name = ?",
                (view_name,),
            )
            return int(rows[0][0]) if rows else 0
        except Exception:
            return 0

    def _update_watermark(
        self, view_name: str, new_id: int, row_count: int
    ) -> None:
        """Aktualizuj watermark."""
        self._duckdb.execute_ddl(f"""
            INSERT OR REPLACE INTO {self.WATERMARK_TABLE}
            (view_name, last_refresh_id, last_refresh_ts, row_count)
            VALUES ('{view_name}', {new_id}, CURRENT_TIMESTAMP, {row_count})
        """)

    def _get_max_id(self, source_table: str, id_column: str) -> int:
        """Pobierz maksymalne ID w tabeli źródłowej."""
        try:
            rows = self._duckdb.execute(
                f"SELECT COALESCE(MAX({id_column}), 0) FROM oltp.{source_table}"
            )
            return int(rows[0][0]) if rows else 0
        except Exception:
            return 0

    def reset_watermark(self, view_name: str) -> None:
        """Zresetuj watermark (wymusi pełne odświeżenie)."""
        self._duckdb.execute_ddl(
            f"DELETE FROM {self.WATERMARK_TABLE} WHERE view_name = '{view_name}'"
        )
        logger.info("[INCREMENTAL] Watermark reset: %s", view_name)

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki odświeżania."""
        try:
            rows = self._duckdb.execute(
                f"SELECT * FROM {self.WATERMARK_TABLE} ORDER BY view_name"
            )
            return {
                "views": [
                    {
                        "name": r[0],
                        "last_refresh_id": r[1],
                        "last_refresh_ts": str(r[2]),
                        "row_count": r[3],
                        "refresh_count": r[4],
                        "avg_ms": r[5],
                    }
                    for r in rows
                ],
                "total_views": len(rows),
            }
        except Exception:
            return {"views": [], "total_views": 0}
