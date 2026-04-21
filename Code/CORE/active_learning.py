# core/active_learning.py
import lancedb
import pyarrow as pa
import pandas as pd
import json
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
        self.db = lancedb.connect(self.db_path)
        if self.table_name not in self.db.table_names():
            schema = pa.schema([
                pa.field("vector", pa.list_(pa.float32(), 384)), # Zależne od modelu (dla all-MiniLM-L6-v2 to 384)
                pa.field("contractor_nip", pa.string()),
                pa.field("correction_payload", pa.string()),
                pa.field("context_hash", pa.string())
            ])
            self.db.create_table(self.table_name, schema=schema)
        self.table = self.db.open_table(self.table_name)

    def _generate_embedding(self, raw_text: str) -> list[float]:
        """Zamienia surowy tekst faktury na wektor."""
        return self.model.encode(raw_text).tolist()

    async def save_correction(self, raw_text: str, nip: str, corrections: Dict[str, Any]):
        """Zapisuje poprawkę użytkownika do bazy wektorowej."""
        vector = self._generate_embedding(raw_text)
        data = [{
            "vector": vector,
            "contractor_nip": nip,
            "correction_payload": json.dumps(corrections),
            "context_hash": str(hash(raw_text)) # Proste hashowanie
        }]
        self.table.add(data)

    async def get_suggestion(self, raw_text: str, nip: str) -> Optional[dict[str, Any]]:
        """Szuka w bazie wektorowej podobnego układu dla danego NIP-u."""
        query_vector = self._generate_embedding(raw_text)
        results = (
            self.table.search(query_vector)
            .where(f"contractor_nip = '{nip}'")
            .limit(1)
            .to_list()
        )
        if results and results[0]["_distance"] < 0.1: # Próg podobieństwa
            return json.loads(results[0]["correction_payload"])
        return None
