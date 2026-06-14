"""AutoDecreeEngine — automatyczne dekretowanie na ASYNC vec0.

Zgodnie z docs/SQLITE_VEC_AUDIT.md:
- FAZA 1: Konwersja z sync SQL na ASYNC AsyncVectorStore z vec0 virtual table
- FAZA 2: partition_key=["contractor_nip"] dla pre-filteringu
- Używa VEC0_SCHEMAS["invoice_templates"] z unified schema registry

Zgodnie z aa3fvcx.txt:
- sqlite-vec zamiast LanceDB (Punkt 3)
- Wszystkie operacje ASYNC — 0ms blokowania
"""

from __future__ import annotations

from typing import Any, final

import anyio
from pathlib import Path

from nexus_ai.core.config import AppConfig
from nexus_ai.core.embeddings import get_embedding_service
from nexus_ai.db.vector_store import AsyncVectorStore


@final
class AutoDecreeEngine:
    """Silnik automatycznego dekretowania faktur na ASYNC vec0.

    FAZA 1+2 SUPERMOCE:
    - vec0 virtual table z ``partition_key=["contractor_nip"]``
    - Wyszukiwanie podobieństwa wektorowego OCR_TEXT → template faktury
    - Wszystkie operacje ASYNC — 0ms blokowania async loop
    """

    def __init__(self, config: AppConfig):
        store_path = Path(config.base_dir) / "app_data" / "vector_store" / "auto_decree.db"
        store_path.parent.mkdir(parents=True, exist_ok=True)
        self._store = AsyncVectorStore(str(store_path))
        self._embedding_service = get_embedding_service()
        self._templates_initialized = False

    async def _init_vec0(self) -> None:
        """Lazy init vec0 invoice_templates table."""
        if self._templates_initialized:
            return
        await self._store.ensure_vec0_table("invoice_templates")

        # Tabela pomocnicza dla layout_features (szczegóły szablonów)
        conn = await self._store.get_conn()
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS invoice_template_details (
                rowid           TEXT PRIMARY KEY,
                contractor_nip  TEXT NOT NULL,
                layout_features TEXT,
                template_id     TEXT,
                category        TEXT DEFAULT '',
                account         TEXT DEFAULT '',
                vat_deduction   REAL DEFAULT 0.0,
                created_at      TEXT DEFAULT (datetime('now'))
            )
        """)
        await conn.commit()
        self._templates_initialized = True

    async def suggest_classification(self, contractor_nip: str, ocr_text: str) -> dict[str, Any]:
        """Sugeruje kategorię KPiR i konta księgowe na podstawie podobieństwa (ASYNC).

        FAZA 1+2 SUPERMOCE:
        - Najpierw szuka dokładnego dopasowania NIP (twarde reguły)
        - Jeśli brak, szuka wektorowo po OCR_TEXT przez vec0 z partition_key
        - Pre-filtering przez contractor_nip — tylko wzorce tego kontrahenta

        Args:
            contractor_nip: NIP kontrahenta.
            ocr_text: Tekst faktury (po OCR).

        Returns:
            Słownik z kategorią KPiR i kontem księgowym.
        """
        # 1. Twarde reguły dla znanych NIPów
        rules = {
            "5260250995": {"category": "Paliwo", "vat_deduction": 0.5, "account": "401-1"},
            "5261040567": {
                "category": "Telekomunikacja",
                "vat_deduction": 1.0,
                "account": "402-5",
            },
        }

        if contractor_nip in rules:
            return rules[contractor_nip]

        # 2. Wyszukiwanie wektorowe przez vec0
        await self._init_vec0()

        embedding = await anyio.to_thread.run_sync(self._embedding_service.embed, ocr_text)

        try:
            similar = await self._store.search_similar(
                query_vector=embedding,
                limit=1,
                table_name="invoice_templates",
                distance_threshold=0.3,
                partition={"contractor_nip": contractor_nip},
            )

            if similar:
                row_id = similar[0].get("rowid", "")
                if row_id:
                    conn = await self._store.get_conn()
                    cursor = await conn.execute(
                        """SELECT category, account, vat_deduction
                           FROM invoice_template_details WHERE rowid = ?""",
                        (row_id,),
                    )
                    row = await cursor.fetchone()
                    if row:
                        return {
                            "category": row[0] or "",
                            "account": row[1] or "",
                            "vat_deduction": float(row[2] or 0.0),
                            "source": "vec0_similarity",
                        }
        except Exception:
            pass

        return {}

    async def store_template(
        self,
        contractor_nip: str,
        ocr_text: str,
        category: str,
        account: str,
        vat_deduction: float = 0.0,
        layout_features: str = "",
        template_id: str = "",
    ) -> None:
        """Zapisz wzorzec faktury w vec0 (ASYNC).

        Args:
            contractor_nip: NIP kontrahenta.
            ocr_text: Tekst faktury (do embeddingu).
            category: Kategoria KPiR.
            account: Konto księgowe.
            vat_deduction: Procent odliczenia VAT.
            layout_features: Cechy layoutu.
            template_id: ID szablonu.
        """
        await self._init_vec0()
        embedding = await anyio.to_thread.run_sync(self._embedding_service.embed, ocr_text)

        await self._store.insert_vectors_batch(
            vectors=[(template_id or contractor_nip, embedding)],
            table_name="invoice_templates",
            metadata=[{"contractor_nip": contractor_nip}],
        )

        conn = await self._store.get_conn()
        await conn.execute(
            """INSERT OR REPLACE INTO invoice_template_details
               (rowid, contractor_nip, layout_features, template_id, category, account, vat_deduction)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                template_id or contractor_nip,
                contractor_nip,
                layout_features,
                template_id,
                category,
                account,
                vat_deduction,
            ),
        )
        await conn.commit()
