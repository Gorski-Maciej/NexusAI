import lancedb
import polars as pl
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional

# Definiujemy schemat Kolumnowy przy użyciu Polars (lżejszy niż bezpośrednie PyArrow)
_VECTOR_SCHEMA = {
    "invoice_id": pl.Utf8,
    "contractor_nip": pl.Utf8,
    "vector": pl.List(pl.Float32),
    "tenant_id": pl.Utf8,
    "created_at": pl.Datetime(time_unit="us", time_zone="UTC"),
}


class OptimizedVectorStore:
    """Zoptymalizowany interfejs do LanceDB używający Polars.
    Rozwiązanie 24: Dodano tenant_id do schematu.
    """

    def __init__(self, db_path: str):
        self.db = lancedb.connect(db_path)
        # Tworzymy pusty Polars DataFrame z żądanym schematem
        self._empty_df = pl.DataFrame({}, schema=_VECTOR_SCHEMA)
        self._arrow_schema = self._empty_df.to_arrow().schema

        if "invoice_templates" not in self.db.table_names():
            self.table = self.db.create_table("invoice_templates", schema=self._arrow_schema)
        else:
            self.table = self.db.open_table("invoice_templates")

    def batch_insert(self, data: List[Dict[str, Any]], tenant_id: str = "default"):
        """Dodaje rekordy przez Polars DataFrame (LanceDB akceptuje natywnie).
        Rozwiązanie 24: Automatycznie dodaje tenant_id i created_at.
        """
        for record in data:
            record.setdefault("tenant_id", tenant_id)
            record.setdefault("created_at", datetime.now(timezone.utc))
        # Konwersja listy słowników na Polars DataFrame
        df = pl.from_dicts(data, schema=_VECTOR_SCHEMA)
        self.table.add(df.to_arrow())

    def search_by_tenant(self, query_vector: List[float], tenant_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Wyszukiwanie wektorowe z filtrowaniem po tenant_id (Rozwiązanie 24)."""
        return (
            self.table.search(query_vector)
            .where(f"tenant_id = '{tenant_id}'")
            .limit(limit)
            .to_list()
        )
