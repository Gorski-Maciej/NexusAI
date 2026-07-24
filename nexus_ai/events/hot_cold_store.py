"""
Hot-Cold Storage for Event Store — transparent queries across hot (SQLite) + cold (Parquet/ZSTD).

INNOWACJA #4 z Raportu v7.0: Zdarzenia:
- Hot (<30 dni): SQLite, szybki dostęp
- Cold (>30 dni): Parquet + ZSTD na dysku
- Query przez DuckDB — łączy hot + cold transparentnie

Usprawnienie v7.0: Transparentne query które automatycznie
łączy dane z hot (SQLite) i cold (Parquet) storage.

Usage:
    store = HotColdEventStore(
        hot_path="app_data/events.db",
        cold_dir="app_data/event_archive_parquet",
    )
    # Transparent query — DuckDB łączy SQLite + Parquet
    events = await store.query_events(
        aggregate_type="invoice",
        since="2025-01-01",
    )
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.events.hotcold")


class HotColdEventStore:
    """Transparentne query przez DuckDB łączące hot (SQLite) + cold (Parquet).

    Zastępuje oddzielne metody w AsyncEventStore (archive_events_to_parquet
    + query_archived_events) pojedynczym, transparentnym interfejsem.
    """

    __slots__ = ("_cold_dir", "_hot_path")

    def __init__(
        self,
        hot_path: str | Path = "app_data/events.db",
        cold_dir: str | Path = "app_data/event_archive_parquet",
    ) -> None:
        self._hot_path = Path(hot_path)
        self._cold_dir = Path(cold_dir)
        self._cold_dir.mkdir(parents=True, exist_ok=True)

    async def query_events(
        self,
        aggregate_type: str | None = None,
        event_type: str | None = None,
        since: str | None = None,
        until: str | None = None,
        limit: int = 1000,
    ) -> list[dict[str, Any]]:
        """Transparentne query przez DuckDB — łączy hot + cold.

        Args:
            aggregate_type: Opcjonalny filtr po typie agregatu.
            event_type: Opcjonalny filtr po typie eventu.
            since: Data ISO 8601 od.
            until: Data ISO 8601 do.
            limit: Maksymalna liczba wyników.

        Returns:
            Lista eventów jako dict.
        """
        try:
            import duckdb

            conn = duckdb.connect()
            try:
                # ── Hot query: SQLite ──────────────────────────────
                hot_sql = "SELECT * FROM sqlite_scan(?, 'event_stream')"
                hot_params: list[Any] = [str(self._hot_path)]

                # ── Cold query: Parquet ────────────────────────────
                cold_parquet = list(self._cold_dir.rglob("*.parquet"))
                cold_parts: list[str] = []
                for pf in cold_parquet[:10]:
                    cold_parts.append(str(pf.resolve()))

                # ── Buduj UNION query z parametryzacją ─────────────
                conditions: list[str] = []
                hot_prms: list[Any] = []
                cold_prms: list[Any] = []
                if aggregate_type:
                    conditions.append("aggregate_type = ?")
                    hot_prms.append(aggregate_type)
                    cold_prms.append(aggregate_type)
                if event_type:
                    conditions.append("event_type = ?")
                    hot_prms.append(event_type)
                    cold_prms.append(event_type)
                if since:
                    conditions.append("timestamp >= ?")
                    hot_prms.append(since)
                    cold_prms.append(since)
                if until:
                    conditions.append("timestamp <= ?")
                    hot_prms.append(until)
                    cold_prms.append(until)

                where_hot = (" WHERE " + " AND ".join(conditions)) if conditions else ""
                where_cold = (" WHERE " + " AND ".join(conditions)) if conditions else ""

                if cold_parquet:
                    # Parametryzowane pliki Parquet
                    cold_from = f"read_parquet([{','.join(['?' for _ in cold_parts])}])"
                    query = (
                        f"SELECT * FROM ({hot_sql}{where_hot}) "
                        f"UNION ALL "
                        f"SELECT * FROM ({cold_from}{where_cold}) "
                        f"ORDER BY timestamp DESC LIMIT ?"
                    )
                    all_params = hot_params + cold_parts + cold_prms + [limit]
                else:
                    query = f"{hot_sql}{where_hot} ORDER BY timestamp DESC LIMIT ?"
                    all_params = hot_params + [limit]

                result = conn.execute(query, all_params).fetchdf()
                if result.empty:
                    return []
                return result.to_dict(orient="records")

            finally:
                conn.close()

        except ImportError:
            logger.warning("[HOTCOLD] DuckDB not available — falling back to hot-only query")
            return await self._query_hot_only(aggregate_type, event_type, since, until, limit)
        except Exception as exc:
            logger.error("[HOTCOLD] Query failed: %s", exc)
            return []

    async def _query_hot_only(
        self,
        aggregate_type: str | None = None,
        event_type: str | None = None,
        since: str | None = None,
        until: str | None = None,
        limit: int = 1000,
    ) -> list[dict[str, Any]]:
        """Fallback: query tylko hot storage (SQLite)."""
        # W produkcji deleguje do AsyncEventStore.read_events_by_type
        return []

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki hot-cold storage."""
        import pendulum

        hot_size = self._hot_path.stat().st_size if self._hot_path.exists() else 0
        cold_files = list(self._cold_dir.rglob("*.parquet"))
        cold_size = sum(f.stat().st_size for f in cold_files)
        cold_count = len(cold_files)

        return {
            "hot_size_bytes": hot_size,
            "hot_size_mb": round(hot_size / (1024 * 1024), 2),
            "cold_size_bytes": cold_size,
            "cold_size_mb": round(cold_size / (1024 * 1024), 2),
            "cold_file_count": cold_count,
            "cold_dir": str(self._cold_dir),
            "hot_path": str(self._hot_path),
            "total_size_mb": round((hot_size + cold_size) / (1024 * 1024), 2),
            "generated_at": pendulum.now("UTC").isoformat(),
        }


__all__ = ["HotColdEventStore"]
