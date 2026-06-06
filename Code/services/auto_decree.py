from __future__ import annotations

from pathlib import Path

from core.config import AppConfig
from db.vector_store import VectorStore


class AutoDecreeEngine:
    """Silnik automatycznego dekretowania faktur.

    Używa sqlite-vec zamiast LanceDB (zgodnie z aa3fvcx.txt).
    """

    def __init__(self, config: AppConfig):
        store_path = Path(config.base_dir) / "app_data" / "vector_store" / "auto_decree.db"
        store_path.parent.mkdir(parents=True, exist_ok=True)
        self._store = VectorStore(str(store_path))
        self._init_table()

    def _init_table(self):
        conn = self._store._get_conn()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS invoice_templates (
                id               TEXT PRIMARY KEY,
                vector           BLOB,
                contractor_nip   TEXT NOT NULL,
                layout_features  TEXT,
                template_id      TEXT,
                created_at       TEXT DEFAULT (datetime('now'))
            )
        """)
        conn.commit()

    async def suggest_classification(self, contractor_nip: str, ocr_text: str) -> dict:
        """Sugeruje kategorię KPiR i konta księgowe na podstawie podobieństwa."""

        # 1. Najpierw szukamy po NIP (dokładne dopasowanie historyczne)
        # 2. Jeśli brak, szukamy wektorowo po OCR_TEXT (podobieństwo branżowe)

        # Przykładowa logika "twardych reguł" dla popularnych NIPów:
        rules = {
            "5260250995": {"category": "Paliwo", "vat_deduction": 0.5, "account": "401-1"},  # Orlen
            "5261040567": {"category": "Telekomunikacja", "vat_deduction": 1.0, "account": "402-5"},  # Orange
        }

        if contractor_nip in rules:
            return rules[contractor_nip]

        return {}
