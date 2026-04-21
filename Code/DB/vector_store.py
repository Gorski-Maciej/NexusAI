import lancedb
import pyarrow as pa
from typing import List, Dict, Any

class OptimizedVectorStore:
    """Zoptymalizowany interfejs do LanceDB używający Apache Arrow."""

    def __init__(self, db_path: str):
        self.db = lancedb.connect(db_path)
        self.schema = pa.schema([
            pa.field("invoice_id", pa.string()),
            pa.field("contractor_nip", pa.string()),
            pa.field("vector", pa.list_(pa.float32(), 384)), # Rozmiar embeddingu
        ])

        if "invoice_templates" not in self.db.table_names():
            self.table = self.db.create_table("invoice_templates", schema=self.schema)
        else:
            self.table = self.db.open_table("invoice_templates")

    def batch_insert(self, data: List[Dict[str, Any]]):
        """Dodaje rekordy bezpośrednio jako struktura Arrow Table (Zero-Copy)."""
        # Konwersja listy słowników na macierz kolumnową Arrow
        arrow_table = pa.Table.from_pylist(data, schema=self.schema)
        self.table.add(arrow_table)
