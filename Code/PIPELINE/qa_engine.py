# pipeline/qa_engine.py
from decimal import Decimal

class QualityAssuranceEngine:
    """Oblicza 'Confidence Score' dla przetworzonego dokumentu."""

    @staticmethod
    def calculate_score(data: dict, ocr_confidence: float) -> float:
        """
        Ocena spójności:
        - Czy wszystkie kluczowe pola są obecne? (+40%)
        - Czy matematyka się zgadza? (+30%)
        - Wynik OCR? (+30%)
        """
        score = 0.0
        required_fields = ["number", "contractor_nip", "amount_gross"]

        # 1. Sprawdzenie kompletności
        found_fields = [f for f in required_fields if data.get(f)]
        score += (len(found_fields) / len(required_fields)) * 40

        # 2. Sprawdzenie matematyki
        try:
            net = Decimal(str(data.get("amount_net", 0)))
            vat = Decimal(str(data.get("amount_vat", 0)))
            gross = Decimal(str(data.get("amount_gross", 0)))

            if gross > 0 and abs((net + vat) - gross) < 0.05:
                score += 30
        except Exception:
            pass

        # 3. Zaufanie do modelu bazowego
        score += (ocr_confidence * 30)

        return min(score, 100.0)
