# pipeline/memory.py
import json
import lancedb
import pyarrow as pa
from datetime import datetime, timezone
from core.config import AppConfig
from core.logger import logger


class PipelineMemory:
    """System RAG dla faktur – wyszukuje podobne wzorce w LanceDB."""

    def __init__(self, config: AppConfig):
        self.db = lancedb.connect(config.base_dir / "app_data" / "vector_store")
        self.table_name = "invoice_patterns"
        self._init_table()

    def _init_table(self):
        """Initialize table with tenant_id schema (Rozwiązanie 24)."""
        if self.table_name not in self.db.table_names():
            schema = pa.schema([
                pa.field("vector", pa.list_(pa.float32(), 384)),
                pa.field("vendor_nip", pa.string()),
                pa.field("pattern_payload", pa.string()),
                pa.field("tenant_id", pa.string()),
                pa.field("created_at", pa.timestamp("us", tz="UTC")),
            ])
            self.db.create_table(self.table_name, schema=schema)

    @staticmethod
    def _sanitize_lancedb(value: str) -> str:
        """Sanitize string for LanceDB where clause (Rozwiązanie 24)."""
        return value.replace("'", "''").replace(";", "")

    async def get_similar_layout(self, vendor_nip: str, tenant_id: str = "default") -> dict | None:
        """Pobiera historyczne poprawki dla danego dostawcy i tenanta.
        Rozwiązanie 24: Filtruje po tenant_id.
        """
        try:
            if self.table_name not in self.db.table_names():
                return None

            table = self.db.open_table(self.table_name)
            safe_nip = self._sanitize_lancedb(vendor_nip)
            safe_tenant = self._sanitize_lancedb(tenant_id)
            result = table.search().where(
                f"vendor_nip = '{safe_nip}' AND tenant_id = '{safe_tenant}'"
            ).limit(1).to_list()

            return result[0] if result else None

        except Exception as e:
            logger.error(f"Błąd pamięci wektorowej: {e}")
            return None

    async def save_pattern(self, vendor_nip: str, payload: dict, tenant_id: str = "default"):
        """Zapisuje wzorzec z tenant_id (Rozwiązanie 24)."""
        try:
            if self.table_name not in self.db.table_names():
                self._init_table()
            table = self.db.open_table(self.table_name)
            table.add([{
                "vector": [0.0] * 384,  # Placeholder; zastąpić embeddingiem
                "vendor_nip": vendor_nip,
                "pattern_payload": json.dumps(payload),
                "tenant_id": tenant_id,
                "created_at": datetime.now(timezone.utc),
            }])
        except Exception as e:
            logger.error(f"Błąd zapisu wzorca: {e}")
