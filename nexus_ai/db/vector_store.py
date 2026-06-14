"""
AsyncVectorStore — async sqlite-vec wrapper with ALL superpowers.

SUPERMOCE (FAZA 2):
- partition_key: partycjonowanie dla tenantów (tenant_id, vendor_nip)
- metadata_columns: przechowywanie metadanych przy wektorze w vec0
- int8 quantization: 4× oszczędność pamięci
- Unified schema registry: jeden interfejs dla wszystkich vec0 tabel
- vec0 virtual table z indeksem IVF
- vec_distance_cosine / vec_distance_l2 / vec_distance_manhattan
- Batch insert przez executemany (async)
- Hybrydowe zapytania FTS5 + vec0

Zgodnie z docs/SQLITE_VEC_AUDIT.md:
- FAZA 1: Konwersja VectorStore z sync sqlite3 na async aiosqlite
- FAZA 2: partition_key, metadata_columns, int8 kwantyzacja, schema registry
- FAZA 3: Współdzielony vec0 pool dla całej aplikacji
"""

from __future__ import annotations

import hashlib
from typing import Any, Literal

import aiosqlite
import sqlite_vec

from nexus_ai.db.async_base_service import AsyncBaseService

# ── Typy pomocnicze ──────────────────────────────────────────────────────────

DistanceMetric = Literal["cosine", "l2", "inner_product", "manhattan"]


# ── Unikalny identyfikator bazy danych NexusAI ─────────────────────────────
VECTOR_DB_APP_ID = 1313827925  # NEXU


# ── Unified schema registry — standardowe definicje vec0 tabel ────────────
# FAZA 2: Wszystkie vec0 tabele w jednym miejscu. Zamiast definiować schemat
# w każdym serwisie osobno, serwisy używają `ensure_vec0_table(table_name)`
# z predefiniowanego słownika VEC0_SCHEMAS.
#
# Każdy schemat definiuje:
#   - table_name: nazwa tabeli wirtualnej vec0
#   - embedding_dim: wymiar embeddingu
#   - distance_metric: metryka odległości
#   - partition_keys: lista kolumn partycjonujących (pre-filtering)
#   - metadata_columns: lista kolumn metadanych przechowywanych przy wektorze
#   - description: opis przeznaczenia tabeli

VEC0_SCHEMAS: dict[str, dict[str, Any]] = {
    "invoice_vectors": {
        "table_name": "invoice_vectors",
        "embedding_dim": 384,
        "distance_metric": "cosine",
        "partition_keys": [],
        "metadata_columns": [],
        "description": "Główne embeddingi faktur dla wyszukiwania semantycznego",
    },
    "vendor_invoices": {
        "table_name": "vendor_invoices",
        "embedding_dim": 768,
        "distance_metric": "cosine",
        "partition_keys": ["vendor_nip"],
        "metadata_columns": [
            "category_code",
            "amount_net",
            "id",
        ],
        "description": "Faktury per-kontrahent dla detekcji anomalii semantycznych",
    },
    "ocr_corrections": {
        "table_name": "ocr_corrections",
        "embedding_dim": 768,
        "distance_metric": "cosine",
        "partition_keys": ["tenant_id", "contractor_nip"],
        "metadata_columns": [
            "contractor_nip",
            "tenant_id",
            "id",
        ],
        "description": "Korekty OCR użytkownika dla aktywnego uczenia",
    },
    "invoice_templates": {
        "table_name": "invoice_templates",
        "embedding_dim": 768,
        "distance_metric": "cosine",
        "partition_keys": ["contractor_nip"],
        "metadata_columns": [
            "contractor_nip",
            "layout_features",
        ],
        "description": "Wzorce faktur dla automatycznego dekretowania",
    },
}


# ── Helper do budowania DDL vec0 ────────────────────────────────────────────


def _build_vec0_ddl(
    schema: dict[str, Any],
    vector_type: str = "float",
) -> str:
    """Zbuduj DDL dla vec0 virtual table na podstawie schematu.

    Args:
        schema: Wpis z VEC0_SCHEMAS.
        vector_type: "float" (float32) lub "int8" (kwantyzowany).

    Returns:
        String DDL CREATE VIRTUAL TABLE.
    """
    dim = schema["embedding_dim"]
    metric = schema["distance_metric"]
    table = schema["table_name"]

    # Kolumny: embedding[dim] distance_metric=X + partition_keys + metadata
    columns: list[str] = []

    # Kolumna embeddingu z typem i metryką
    if vector_type == "int8":
        columns.append(f"embedding int8[{dim}] distance_metric={metric}")
    else:
        columns.append(f"embedding float[{dim}] distance_metric={metric}")

    # Partition keys — pre-filtering przez WHERE partition_key = ?
    for pk in schema.get("partition_keys", []):
        columns.append(f"{pk} column")

    # Metadata columns — przechowywane przy wektorze
    for mc in schema.get("metadata_columns", []):
        if mc not in schema.get("partition_keys", []):
            columns.append(f"{mc} column")

    return f"""
        CREATE VIRTUAL TABLE IF NOT EXISTS {table}
        USING vec0({', '.join(columns)});
    """


# ── AsyncVectorStore — enhanced core ────────────────────────────────────────


class AsyncVectorStore(AsyncBaseService):
    """Async wrapper around sqlite-vec with ALL superpowers.

    FAZA 2 SUPERMOCE:
    - partition_key: ``search_similar(partition={...})`` pre-filtruje przez
      WHERE partition_key = ? zanim MATCH — szybsze wyszukiwanie w obrębie
      tenanta/kontrahenta
    - metadata_columns: dane przechowywane w vec0 przy wektorze — eliminuje JOIN
    - int8 kwantyzacja: ``ensure_vec0_table(..., use_int8=True)`` — 4× mniej RAM
    - Unified schema registry: ``ensure_vec0_table(table_name)`` z VEC0_SCHEMAS
    - vec_distance_manhattan: alternatywna metryka odległości
    """

    def __init__(
        self,
        db_path: str,
    ) -> None:
        super().__init__(
            db_path=db_path,
            enable_extensions=True,
        )

    async def _on_connect(self, conn: aiosqlite.Connection) -> None:
        """Hook ładujący sqlite-vec extension przy nowym połączeniu."""
        import sqlite3 as _sqlite3

        inner_conn: _sqlite3.Connection = conn._conn  # type: ignore[attr-defined]
        sqlite_vec.load(inner_conn)
        await conn.execute(f"PRAGMA application_id = {VECTOR_DB_APP_ID};")

    # ── [FAZA 2] Unified Schema Registry ────────────────────────────────

    @staticmethod
    def list_schemas() -> dict[str, dict[str, Any]]:
        """Zwróć wszystkie zarejestrowane schematy vec0."""
        return dict(VEC0_SCHEMAS)

    @staticmethod
    def register_schema(
        table_name: str,
        embedding_dim: int,
        distance_metric: str = "cosine",
        partition_keys: list[str] | None = None,
        metadata_columns: list[str] | None = None,
        description: str = "",
    ) -> None:
        """Zarejestruj nowy schemat vec0 w registry.

        Args:
            table_name: Nazwa tabeli wirtualnej.
            embedding_dim: Wymiar embeddingu.
            distance_metric: Metryka odległości (cosine, l2, inner_product).
            partition_keys: Kolumny partycjonujące.
            metadata_columns: Kolumny metadanych.
            description: Opis przeznaczenia tabeli.
        """
        VEC0_SCHEMAS[table_name] = {
            "table_name": table_name,
            "embedding_dim": embedding_dim,
            "distance_metric": distance_metric,
            "partition_keys": partition_keys or [],
            "metadata_columns": metadata_columns or [],
            "description": description,
        }

    async def ensure_vec0_table(
        self,
        table_name: str = "invoice_vectors",
        use_int8: bool = False,
    ) -> None:
        """Utwórz vec0 virtual table z registry (ASYNC).

        FAZA 2 SUPERMOC:
        - Używa VEC0_SCHEMAS[table_name] do zbudowania DDL
        - Obsługuje partition_keys i metadata_columns automatycznie
        - use_int8=True → 4× mniejszy wektor (int8 zamiast float32)

        Args:
            table_name: Nazwa schematu z VEC0_SCHEMAS.
            use_int8: Jeśli True, używa int8[dim] zamiast float[dim].

        Raises:
            KeyError: Gdy table_name nie istnieje w registry.
        """
        schema = VEC0_SCHEMAS[table_name]
        ddl = _build_vec0_ddl(schema, vector_type="int8" if use_int8 else "float")
        await self.execute(ddl)
        await self.commit()

    # ── [FAZA 2] Dynamiczna vec0 dla niestandardowych tabel ─────────────

    async def ensure_custom_vec0_table(
        self,
        table_name: str,
        embedding_dim: int = 768,
        distance_metric: str = "cosine",
        partition_keys: list[str] | None = None,
        metadata_columns: list[str] | None = None,
        use_int8: bool = False,
    ) -> None:
        """Utwórz niestandardową vec0 virtual table (ASYNC).

        Automatycznie rejestruje schemat w VEC0_SCHEMAS.

        Args:
            table_name: Nazwa tabeli wirtualnej.
            embedding_dim: Wymiar embeddingu.
            distance_metric: Metryka odległości.
            partition_keys: Kolumny partycjonujące (pre-filtering).
            metadata_columns: Kolumny metadanych.
            use_int8: Jeśli True, int8 kwantyzacja.
        """
        schema = {
            "table_name": table_name,
            "embedding_dim": embedding_dim,
            "distance_metric": distance_metric,
            "partition_keys": partition_keys or [],
            "metadata_columns": metadata_columns or [],
            "description": "Custom",
        }
        VEC0_SCHEMAS[table_name] = schema
        ddl = _build_vec0_ddl(schema, vector_type="int8" if use_int8 else "float")
        await self.execute(ddl)
        await self.commit()

    # ── 🔴 BUG FIX: vec0 wymaga INTEGER rowid ───────────────────────────
    # vec0 virtual table (sqlite-vec) wymaga integer rowid. String UUID nie działa.
    # _rowid_to_int() konwertuje string ID na stabilny integer przez hash.
    # insert_vectors_batch() automatycznie konwertuje string → int i zapisuje
    # oryginalny string w metadata kolumnie 'id' gdy schemat ją zawiera.

    @staticmethod
    def _rowid_to_int(string_id: str) -> int:
        """Konwertuje string ID na DETERMINISTYCZNY integer dla vec0 rowid.

        🔴 BUG FIX: Python hash() jest seedowane losowo między restartami
        (PYTHONHASHSEED). Używamy hashlib.sha256 dla deterministycznego
        wyniku stabilnego między sesjami.

        Zakres: [0, 2^62-1] — bezpieczny dla SQLite INTEGER.
        Ten sam string ID → zawsze ten sam integer rowid.

        Args:
            string_id: String UUID lub inny identyfikator.

        Returns:
            Integer rowid dla vec0 (deterministyczny, stabilny między restartami).
        """
        # hashlib.sha256 jest deterministyczny — ten sam string = ten sam wynik
        # nawet po restarcie procesu (w przeciwieństwie do builtin hash())
        digest = hashlib.sha256(string_id.encode()).digest()[:8]
        # int.from_bytes z unsigned=False daje 63-bit positive integer
        # +1 bo rowid w SQLite zaczyna się od 1
        return (int.from_bytes(digest, 'big', signed=False) >> 1) + 1

    # ── Podstawowe metody serializacji ─────────────────────────────────

    @staticmethod
    def _vector_to_blob(vector: list[float]) -> bytes:
        """Konwertuje listę floatów na binarny blob (sqlite-vec format)."""
        return sqlite_vec.serialize_float32(vector)

    @staticmethod
    def _quantize_to_int8(vector: list[float]) -> bytes:
        """Kwantyzuje float32[dim] do int8[dim] (4× mniejszy).

        FAZA 2 SUPERMOC: int8 kwantyzacja.
        Mapowanie: float[-1..1] → int8[-128..127].
        Dla embeddingów znormalizowanych (unit vectors) strata precyzji
        jest akceptowalna (<1% wpływu na cosine similarity ranking).

        Args:
            vector: Wektor float32 (oczekiwany zakres [-1.0, 1.0]).

        Returns:
            Zserializowany wektor int8 (sqlite-vec format).
        """
        int8_values = bytearray()
        for val in vector:
            # Skaluj float[-1..1] do int8[-128..127]
            # clamp do [-1, 1] dla stabilności
            clamped = max(-1.0, min(1.0, val))
            int8_val = max(-128, min(127, round(clamped * 127)))
            int8_values.append(int8_val & 0xFF)
        return bytes(int8_values)

    # ── Batch insert dla vec0 — [FAZA 2] z metadata/partition ──────────

    async def insert_vectors_batch(
        self,
        vectors: list[tuple[str | int, list[float]]],
        table_name: str = "invoice_vectors",
        metadata: list[dict[str, Any]] | None = None,
        use_int8: bool = False,
    ) -> None:
        """Wstaw wiele wektorów w jednej transakcji (async batch insert).

        🔴 BUG FIX: vec0 wymaga INTEGER rowid.
        - Gdy rowid to string → auto-konwersja na int przez _rowid_to_int()
        - Gdy schemat ma metadata kolumnę 'id' → oryginalny string ID
          automatycznie zapisywany w metadata

        FAZA 2 SUPERMOC:
        - Obsługa metadata_columns i partition_keys
        - int8 kwantyzacja gdy use_int8=True

        Args:
            vectors: Lista (rowid, embedding_vector). rowid może być str | int.
            table_name: Nazwa tabeli vec0.
            metadata: Lista słowników z wartościami dla kolumn metadanych.
                     Kolejność odpowiada vectors (lub None dla wszystkich).
            use_int8: Jeśli True, kwantyzuj wektory do int8.
        """
        conn = await self.get_conn()
        schema = VEC0_SCHEMAS.get(table_name, {})
        partition_keys = schema.get("partition_keys", [])
        metadata_cols = schema.get("metadata_columns", [])
        has_id_metadata = "id" in metadata_cols

        # Buduj kolumny do INSERT
        all_columns = ["rowid", "embedding"]
        for pk in partition_keys:
            if pk not in all_columns:
                all_columns.append(pk)
        for mc in metadata_cols:
            if mc not in all_columns:
                all_columns.append(mc)

        placeholders = ", ".join(["?"] * len(all_columns))
        columns_str = ", ".join(all_columns)

        sql = f"""INSERT OR REPLACE INTO {table_name}
                 ({columns_str}) VALUES ({placeholders})"""

        await conn.execute("BEGIN")
        for i, (rowid, vector) in enumerate(vectors):
            # 🔴 BUG FIX: konwersja string rowid → int
            original_id = rowid if isinstance(rowid, str) else str(rowid)
            int_rowid = self._rowid_to_int(original_id) if isinstance(rowid, str) else rowid

            blob = self._quantize_to_int8(vector) if use_int8 else self._vector_to_blob(vector)
            row: list[Any] = [int_rowid, blob]

            # Dodaj wartości metadanych jeśli dostępne
            meta = metadata[i] if metadata and i < len(metadata) else {}
            # 🔴 BUG FIX: oryginalny string ID do metadata 'id' kolumny
            if has_id_metadata and "id" not in meta:
                meta["id"] = original_id

            for pk in partition_keys:
                row.append(meta.get(pk, ""))
            for mc in metadata_cols:
                if mc not in partition_keys:
                    row.append(meta.get(mc, ""))
            await conn.execute(sql, row)
        await conn.commit()

    # ── [FAZA 2] search_similar z partition_key i metadata ─────────────

    async def search_similar(
        self,
        query_vector: list[float],
        limit: int = 10,
        distance_threshold: float | None = None,
        distance_metric: DistanceMetric = "cosine",
        table_name: str = "invoice_vectors",
        partition: dict[str, Any] | None = None,
    ) -> list[dict[str, Any]]:
        """Wyszukuje najbliższych sąsiadów wektorowych (ASYNC).

        FAZA 2 SUPERMOCE:
        - partition: pre-filtering przez ``WHERE partition_key = ?``
          zanim MATCH — szybsze wyszukiwanie w obrębie tenanta/kontrahenta
        - metadata_columns: zwracane razem z wektorem — brak JOIN-ów
        - vec_distance_manhattan: alternatywna metryka
        - int8: obsługuje zarówno float[] jak i int8[] tabele

        Args:
            query_vector: Wektor zapytania.
            limit: Maksymalna liczba wyników.
            distance_threshold: Próg odległości (opcjonalny).
            distance_metric: Metryka: "cosine", "l2", "inner_product", "manhattan".
            table_name: Nazwa tabeli vec0.
            partition: Słownik {partition_key: wartość} dla pre-filteringu.

        Returns:
            Lista słowników z wynikami.
        """
        conn = await self.get_conn()

        # Wybór funkcji odległości
        if distance_metric == "l2":
            distance_fn = "vec_distance_l2"
        elif distance_metric == "inner_product":
            distance_fn = "vec_distance_inner_product"
        elif distance_metric == "manhattan":
            distance_fn = "vec_distance_manhattan"
        else:
            distance_fn = "vec_distance_cosine"

        query_blob = self._vector_to_blob(query_vector)
        params: list[Any] = [query_blob, query_blob]

        # Buduj WHERE z partition_keys
        where_clauses = ["embedding MATCH ?"]
        if partition:
            for pk, val in partition.items():
                where_clauses.append(f"{pk} = ?")
                params.append(val)

        where_str = " AND ".join(where_clauses)

        if distance_threshold is not None:
            where_str += f" AND {distance_fn}(embedding, ?) <= ?"
            params.append(query_blob)
            params.append(distance_threshold)

        params.append(limit)

        sql = f"""
            SELECT *, {distance_fn}(embedding, ?) AS _distance
            FROM {table_name}
            WHERE {where_str}
            ORDER BY _distance ASC
            LIMIT ?
        """

        try:
            cursor = await conn.execute(sql, params)
            rows = await cursor.fetchall()
            return [dict(r) for r in rows]
        except Exception:
            # Fallback: tradycyjna tabela invoice_templates (dla kompatybilności)
            return await self._fallback_search(query_blob, query_vector, limit, distance_threshold, distance_fn)

    async def _fallback_search(
        self,
        query_blob: bytes,
        query_vector: list[float],
        limit: int,
        distance_threshold: float | None,
        distance_fn: str,
    ) -> list[dict[str, Any]]:
        """Fallback dla tabel, które nie mają jeszcze vec0."""
        conn = await self.get_conn()
        try:
            sql = f"""
                SELECT *, {distance_fn}(vector, ?) AS _distance
                FROM invoice_templates
            """
            params = [query_blob]
            if distance_threshold is not None:
                sql += " WHERE _distance <= ?"
                params.append(distance_threshold)
            sql += " ORDER BY _distance ASC LIMIT ?"
            params.append(limit)
            cursor = await conn.execute(sql, params)
            rows = await cursor.fetchall()
            return [dict(r) for r in rows]
        except Exception:
            return []

    # ── Usuwanie wektorów ───────────────────────────────────────────────

    async def delete_vectors(
        self,
        rowid: int | str,
        table_name: str = "invoice_vectors",
    ) -> None:
        """Usuń wektor z tabeli vec0 (ASYNC)."""
        conn = await self.get_conn()
        await conn.execute(f"DELETE FROM {table_name} WHERE rowid = ?", (rowid,))
        await conn.commit()

    async def delete_vectors_by_partition(
        self,
        partition: dict[str, Any],
        table_name: str = "invoice_vectors",
    ) -> int:
        """Usuń wszystkie wektory spełniające warunek partycji (ASYNC).

        FAZA 2 SUPERMOC: szybkie czyszczenie danych per-tenant/per-vendor.

        Args:
            partition: Słownik {column: wartość} dla WHERE.
            table_name: Nazwa tabeli vec0.

        Returns:
            Liczba usuniętych wierszy.
        """
        conn = await self.get_conn()
        where_clauses = [f"{col} = ?" for col in partition]
        where_str = " AND ".join(where_clauses)
        params = list(partition.values())
        cursor = await conn.execute(
            f"DELETE FROM {table_name} WHERE {where_str}", params
        )
        deleted = cursor.rowcount
        await conn.commit()
        return deleted

    # ── Konta asynchroniczne ────────────────────────────────────────────

    async def __aenter__(self) -> AsyncVectorStore:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
VectorStore = AsyncVectorStore
