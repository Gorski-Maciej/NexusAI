"""
VectorStore — sqlite-vec wrapper for vector similarity search.

Zgodnie z aa3fvcx.txt: LanceDB → sqlite-vec.
Wektory przechowywane w SQLite z extension sqlite-vec (v0.1.9).
"""

from __future__ import annotations

import sqlite3
from typing import Any

import sqlite_vec


class VectorStore:
    """Wrapper around sqlite-vec for vector similarity search.

    Zastępuje dawny OptimizedVectorStore (LanceDB + Polars).
    Przechowuje wektory w SQLite z extension sqlite-vec.
    """

    def __init__(self, db_path: str) -> None:
        self._db_path = db_path
        self._conn: sqlite3.Connection | None = None

    def _get_conn(self) -> sqlite3.Connection:
        """Leniwe otwarcie połączenia z załadowanym sqlite-vec."""
        if self._conn is None:
            self._conn = sqlite3.connect(self._db_path)
            self._conn.row_factory = sqlite3.Row
            self._conn.enable_load_extension(True)
            sqlite_vec.load(self._conn)
        return self._conn

    @staticmethod
    def _vector_to_blob(vector: list[float]) -> bytes:
        """Konwertuje listę floatów na binarny blob (sqlite-vec format).

        Args:
            vector: Lista wartości zmiennoprzecinkowych.

        Returns:
            Bajty w formacie float32, gotowe do zapisu w kolumnie BLOB.
        """
        return sqlite_vec.serialize_float32(vector)

    def search_similar(
        self,
        query_vector: list[float],
        limit: int = 10,
        distance_threshold: float | None = None,
    ) -> list[dict[str, Any]]:
        """Wyszukuje najbliższych sąsiadów wektorowych w tabeli invoice_templates.

        Tabela invoice_templates musi istnieć przed wywołaniem.

        Args:
            query_vector: Wektor zapytania.
            limit: Maksymalna liczba wyników.
            distance_threshold: Maksymalna odległość cosinusowa (opcjonalnie).

        Returns:
            Lista słowników z dopasowaniami.
        """
        conn = self._get_conn()
        query_blob = self._vector_to_blob(query_vector)

        sql = """
            SELECT *, vec_distance_cosine(vector, ?) AS _distance
            FROM invoice_templates
        """
        params: list[Any] = [query_blob]

        if distance_threshold is not None:
            sql += " WHERE _distance <= ?"
            params.append(distance_threshold)

        sql += " ORDER BY _distance ASC LIMIT ?"
        params.append(limit)

        rows = conn.execute(sql, params).fetchall()
        return [dict(row) for row in rows]

    def close(self) -> None:
        """Zamyka połączenie z bazą."""
        if self._conn is not None:
            try:
                self._conn.close()
            except Exception:
                pass
            self._conn = None

    def __enter__(self) -> VectorStore:
        """Context manager support."""
        return self

    def __exit__(self, *args: Any) -> None:
        """Context manager cleanup."""
        self.close()
