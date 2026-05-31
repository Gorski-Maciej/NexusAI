# core/active_learning.py
import lancedb
import pyarrow as pa
import pandas as pd
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, Any
from sentence_transformers import SentenceTransformer

class ActiveLearningEngine:
    def __init__(self, db_path: str = "./data/vector_db"):
        self.db_path = db_path
        self.table_name = "ocr_corrections"
        self._init_db()
        self.model = SentenceTransformer('all-MiniLM-L6-v2')

    def _init_db(self):
        """Inicjalizuje bazę i tabelę, jeśli nie istnieją."""
        self.db = lancedb.connect(self.db_path, mode="file")
        if self.table_name not in self.db.table_names():
            schema = pa.schema([
                pa.field("vector", pa.list_(pa.float32(), 384)), # Zależne od modelu (dla all-MiniLM-L6-v2 to 384)
                pa.field("contractor_nip", pa.string()),
                pa.field("correction_payload", pa.string()),
                pa.field("context_hash", pa.string()),
                pa.field("tenant_id", pa.string()),  # Rozwiązanie 24: izolacja tenantów
                pa.field("created_at", pa.timestamp("us", tz="UTC")),  # Rozwiązanie 24: TTL
            ])
            self.db.create_table(self.table_name, schema=schema)
        self.table = self.db.open_table(self.table_name, index_cache_size=100 * 1024 * 1024)

    def _generate_embedding(self, raw_text: str) -> list[float]:
        """Zamienia surowy tekst faktury na wektor."""
        return self.model.encode(raw_text).tolist()

    async def save_correction(self, raw_text: str, nip: str, corrections: Dict[str, Any], tenant_id: str = "default"):
        """Zapisuje poprawkę użytkownika do bazy wektorowej."""
        vector = self._generate_embedding(raw_text)
        data = [{
            "vector": vector,
            "contractor_nip": nip,
            "correction_payload": json.dumps(corrections),
            "context_hash": str(hash(raw_text)),
            "tenant_id": tenant_id,  # Rozwiązanie 24: izolacja tenantów
            "created_at": datetime.now(timezone.utc).isoformat(),  # Rozwiązanie 24: TTL
        }]
        self.table.add(data)

    @staticmethod
    def _sanitize_lancedb(value: str) -> str:
        """Sanitize string for LanceDB where clause (Rozwiązanie 24)."""
        return value.replace("'", "''").replace(";", "")

    async def get_suggestion(self, raw_text: str, nip: str, tenant_id: str = "default") -> Optional[dict[str, Any]]:
        """Szuka w bazie wektorowej podobnego układu dla danego NIP-u i tenanta."""
        query_vector = self._generate_embedding(raw_text)
        safe_nip = self._sanitize_lancedb(nip)
        safe_tenant = self._sanitize_lancedb(tenant_id)
        results = (
            self.table.search(query_vector)
            .where(f"contractor_nip = '{safe_nip}' AND tenant_id = '{safe_tenant}'")
            .limit(1)
            .to_list()
        )
        if results and results[0]["_distance"] < 0.1: # Próg podobieństwa
            return json.loads(results[0]["correction_payload"])
        return None
