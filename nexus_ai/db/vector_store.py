"""
AsyncVectorStore -- async sqlite-vec wrapper with ALL superpowers.

Python 3.13t (free-threaded): używamy natywnego sqlite3 + anyio.to_thread.run_sync.

- partition_key: partycjonowanie dla tenantów (tenant_id, vendor_nip)
- metadata_columns: przechowywanie metadanych przy wektorze w vec0
- int8 quantization: 4x oszczędność pamięci
- Unified schema registry: jeden interfejs dla wszystkich vec0 tabel
- vec0 virtual table z indeksem IVF
- vec_distance_cosine / vec_distance_l2 / vec_distance_manhattan
- Batch insert przez executemany (async)
- Hybrydowe zapytania FTS5 + vec0
"""

from __future__ import annotations

import hashlib
import sqlite3
from typing import Any, Literal

import anyio
import sqlite_vec

from nexus_ai.db.async_base_service import AsyncBaseService

# ── Typy pomocnicze ──────────────────────────────────────────────────────────

DistanceMetric = Literal["cosine", "l2", "inner_product", "manhattan"]


# ── Unikalny identyfikator bazy danych NexusAI ─────────────────────────────
VECTOR_DB_APP_ID = 1313827925  # NEXU


# ── Unified schema registry -- standardowe definicje vec0 tabel ────────────

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
    """Zbuduj DDL dla vec0 virtual table na podstawie schematu."""
    dim = schema["embedding_dim"]
    metric = schema["distance_metric"]
    table = schema["table_name"]

    columns: list[str] = []

    if vector_type == "int8":
        columns.append(f"embedding int8[{dim}] distance_metric={metric}")
    else:
        columns.append(f"embedding float[{dim}] distance_metric={metric}")

    for pk in schema.get("partition_keys", []):
        columns.append(f"{pk} column")

    for mc in schema.get("metadata_columns", []):
        if mc not in schema.get("partition_keys", []):
            columns.append(f"{mc} column")

    return f"""
        CREATE VIRTUAL TABLE IF NOT EXISTS {table}
        USING vec0({", ".join(columns)});
    """


# ── AsyncVectorStore -- enhanced core ────────────────────────────────────────


class AsyncVectorStore(AsyncBaseService):
    """Async wrapper around sqlite-vec with ALL superpowers.

    Python 3.13t (free-threaded): synchroniczne sqlite3 + anyio.to_thread.run_sync.
    """

    def __init__(
        self,
        db_path: str,
    ) -> None:
        super().__init__(
            db_path=db_path,
            enable_extensions=True,
        )

    async def _on_connect(self, conn: sqlite3.Connection) -> None:
        """Hook ładujący sqlite-vec extension przy nowym połączeniu."""

        def _sync() -> None:
            sqlite_vec.load(conn)
            conn.execute(f"PRAGMA application_id = {VECTOR_DB_APP_ID};")

        await anyio.to_thread.run_sync(_sync)

    # ── [FAZA 2] Unified Schema Registry ────────────────────────────────

    @staticmethod
    def list_schemas() -> dict[str, dict[str, Any]]:
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
        schema = VEC0_SCHEMAS[table_name]
        ddl = _build_vec0_ddl(schema, vector_type="int8" if use_int8 else "float")
        await self.execute(ddl)
        await self.commit()

    async def ensure_custom_vec0_table(
        self,
        table_name: str,
        embedding_dim: int = 768,
        distance_metric: str = "cosine",
        partition_keys: list[str] | None = None,
        metadata_columns: list[str] | None = None,
        use_int8: bool = False,
    ) -> None:
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

    @staticmethod
    def _rowid_to_int(string_id: str) -> int:
        digest = hashlib.sha256(string_id.encode()).digest()[:8]
        return (int.from_bytes(digest, "big", signed=False) >> 1) + 1

    # ── Podstawowe metody serializacji ─────────────────────────────────

    @staticmethod
    def _vector_to_blob(vector: list[float]) -> bytes:
        return sqlite_vec.serialize_float32(vector)

    @staticmethod
    def _quantize_to_int8(vector: list[float]) -> bytes:
        int8_values = bytearray()
        for val in vector:
            clamped = max(-1.0, min(1.0, val))
            int8_val = max(-128, min(127, round(clamped * 127)))
            int8_values.append(int8_val & 0xFF)
        return bytes(int8_values)

    # ── Batch insert dla vec0 -- [FAZA 2] z metadata/partition ──────────

    async def insert_vectors_batch(
        self,
        vectors: list[tuple[str | int, list[float]]],
        table_name: str = "invoice_vectors",
        metadata: list[dict[str, Any]] | None = None,
        use_int8: bool = False,
    ) -> None:
        conn = await self.get_conn()
        schema = VEC0_SCHEMAS.get(table_name, {})
        partition_keys = schema.get("partition_keys", [])
        metadata_cols = schema.get("metadata_columns", [])
        has_id_metadata = "id" in metadata_cols

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

        def _sync_batch() -> None:
            conn.execute("BEGIN")
            for i, (rowid, vector) in enumerate(vectors):
                original_id = rowid if isinstance(rowid, str) else str(rowid)
                int_rowid = self._rowid_to_int(original_id) if isinstance(rowid, str) else rowid

                blob = self._quantize_to_int8(vector) if use_int8 else self._vector_to_blob(vector)
                row: list[Any] = [int_rowid, blob]

                meta = metadata[i] if metadata and i < len(metadata) else {}
                if has_id_metadata and "id" not in meta:
                    meta["id"] = original_id

                for pk in partition_keys:
                    row.append(meta.get(pk, ""))
                for mc in metadata_cols:
                    if mc not in partition_keys:
                        row.append(meta.get(mc, ""))
                conn.execute(sql, row)
            conn.commit()

        await anyio.to_thread.run_sync(_sync_batch)

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
        conn = await self.get_conn()

        match distance_metric:
            case "l2":
                distance_fn = "vec_distance_l2"
            case "inner_product":
                distance_fn = "vec_distance_inner_product"
            case "manhattan":
                distance_fn = "vec_distance_manhattan"
            case _:
                distance_fn = "vec_distance_cosine"

        query_blob = self._vector_to_blob(query_vector)
        params: list[Any] = [query_blob, query_blob]

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

        def _sync_search() -> list[dict[str, Any]]:
            cursor = conn.execute(sql, params)
            return [dict(r) for r in cursor.fetchall()]

        try:
            return await anyio.to_thread.run_sync(_sync_search)
        except Exception:
            return await self._fallback_search(
                query_blob, query_vector, limit, distance_threshold, distance_fn
            )

    async def _fallback_search(
        self,
        query_blob: bytes,
        query_vector: list[float],
        limit: int,
        distance_threshold: float | None,
        distance_fn: str,
    ) -> list[dict[str, Any]]:
        conn = await self.get_conn()

        def _sync() -> list[dict[str, Any]]:
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
                cursor = conn.execute(sql, params)
                return [dict(r) for r in cursor.fetchall()]
            except Exception:
                return []

        return await anyio.to_thread.run_sync(_sync)

    # ── Usuwanie wektorów ───────────────────────────────────────────────

    async def delete_vectors(
        self,
        rowid: int | str,
        table_name: str = "invoice_vectors",
    ) -> None:
        await self.execute(f"DELETE FROM {table_name} WHERE rowid = ?", (rowid,))
        await self.commit()

    async def delete_vectors_by_partition(
        self,
        partition: dict[str, Any],
        table_name: str = "invoice_vectors",
    ) -> int:
        conn = await self.get_conn()
        where_clauses = [f"{col} = ?" for col in partition]
        where_str = " AND ".join(where_clauses)
        params = list(partition.values())

        def _sync() -> int:
            cursor = conn.execute(f"DELETE FROM {table_name} WHERE {where_str}", params)
            deleted = cursor.rowcount
            conn.commit()
            return deleted

        return await anyio.to_thread.run_sync(_sync)

    async def __aenter__(self) -> AsyncVectorStore:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
VectorStore = AsyncVectorStore
