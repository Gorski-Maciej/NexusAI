import lancedb
from core.config import AppConfig


class AutoDecreeEngine:
    def __init__(self, config: AppConfig):
        self.db = lancedb.connect(config.base_dir / "app_data" / "vector_store")
        self.table = self.db.open_table("invoice_templates")

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
