# pipeline/memory.py
import lancedb
import pyarrow as pa
from core.config import AppConfig
from core.logger import logger

class PipelineMemory:
    """System RAG dla faktur – wyszukuje podobne wzorce w LanceDB."""

    def __init__(self, config: AppConfig):
        self.db = lancedb.connect(config.base_dir / "app_data" / "vector_store")
        self.table_name = "invoice_patterns"

    async def get_similar_layout(self, vendor_nip: str) -> dict | None:
        """Pobiera historyczne poprawki dla danego dostawcy."""
        try:
            if self.table_name not in self.db.table_names():
                return None

            table = self.db.open_table(self.table_name)
            result = table.search().where(f"vendor_nip = '{vendor_nip}'").limit(1).to_list()

            return result[0] if result else None

        except Exception as e:
            logger.error(f"Błąd pamięci wektorowej: {e}")
            return None

    async def save_pattern(self, vendor_nip: str, payload: dict):
        pass # Logika zapisu wektora
