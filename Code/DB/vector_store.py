import lancedb
import pyarrow as pa
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional

class OptimizedVectorStore:
    """Zoptymalizowany interfejs do LanceDB używający Apache Arrow.
    Rozwiązanie 24: Dodano tenant_id do schematu.
    """

    def __init__(self, db_path: str):
        self.db = lancedb.connect(db_path)
        self.schema = pa.schema([
            pa.field("invoice_id", pa.string()),
            pa.field("contractor_nip", pa.string()),
            pa.field("vector", pa.list_(pa.float32(), 384)),  # Rozmiar embeddingu
            pa.field("tenant_id", pa.string()),  # Rozwiązanie 24: izolacja tenantów
            pa.field("created_at", pa.timestamp("us", tz="UTC")),  # Rozwiązanie 24: TTL
        ])

        if "invoice_templates" not in self.db.table_names():
            self.table = self.db.create_table("invoice_templates", schema=self.schema)
        else:
            self.table = self.db.open_table("invoice_templates")

    def batch_insert(self, data: List[Dict[str, Any]], tenant_id: str = "default"):
        """Dodaje rekordy bezpośrednio jako struktura Arrow Table (Zero-Copy).
        Rozwiązanie 24: Automatycznie dodaje tenant_id i created_at.
        """
        for record in data:
            record.setdefault("tenant_id", tenant_id)
            record.setdefault("created_at", datetime.now(timezone.utc))
        # Konwersja listy słowników na macierz kolumnową Arrow
        arrow_table = pa.Table.from_pylist(data, schema=self.schema)
        self.table.add(arrow_table)

    def search_by_tenant(self, query_vector: List[float], tenant_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Wyszukiwanie wektorowe z filtrowaniem po tenant_id (Rozwiązanie 24)."""
        return (
            self.table.search(query_vector)
            .where(f"tenant_id = '{tenant_id}'")
            .limit(limit)
            .to_list()
        )
