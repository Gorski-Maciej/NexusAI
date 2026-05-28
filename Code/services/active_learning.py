import json

from models.invoice import ActiveLearningPattern
from sqlalchemy.ext.asyncio import AsyncSession


class ActiveLearningService:
    """Usługa ucząca system na podstawie ręcznych poprawek księgowej."""

    @staticmethod
    async def register_correction(
            session: AsyncSession,
            nip: str,
            field_name: str,
            ai_guess: str,
            human_correction: str
    ) -> None:
        """Zapisuje, że AI się pomyliło i użytkownik musiał ręcznie poprawić wartość."""
        # Jeśli nie ma NIPu, nie możemy stworzyć wzorca
        if not nip:
            return

        correction_payload = {
            "field": field_name,
            "ai_guess": ai_guess,
            "human_correction": human_correction
        }

        pattern = ActiveLearningPattern(
            contractor_nip=nip,
            correction_payload=json.dumps(correction_payload)
        )
        session.add(pattern)

    async def find_similar_layout(self, ocr_text: str):
        """Szuka w bazie wektorowej podobnego układu faktury."""
        vector = self.get_embedding(ocr_text)
        table = self.db.open_table("invoice_templates")

        # Wyszukiwanie wektorowe (ANN - Approximate Nearest Neighbor)
        results = table.search(vector).limit(1).to_list()

        if results and results[0]['_distance'] < 0.4:  # Próg podobieństwa
            return results[0]
        return None

    def learn_new_template(self, nip: str, ocr_text: str):
        """Zapisuje nowy wzorzec do bazy wektorowej."""
        vector = self.get_embedding(ocr_text)
        table = self.db.open_table("invoice_templates")
        table.add([{"vector": vector, "contractor_nip": nip, "layout_features": ocr_text[:200]}])
