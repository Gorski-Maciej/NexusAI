# core/prompts.py
from enum import Enum

class PromptTemplate(str, Enum):
    """Zbiór systemowych instrukcji dla modeli lokalnych (Phi/Llama)."""

    INVOICE_EXTRACTOR = (
        "Jesteś ekspertem księgowym. Twoim zadaniem jest wyodrębnienie danych z tekstu OCR faktury. "
        "Zwróć WYŁĄCZNIE czysty JSON bez komentarzy. Pola: numer, data, nip_sprzedawcy, kwota_brutto, waluta."
    )

    CLASSIFIER = (
        "Na podstawie tekstu określ typ dokumentu: [FAKTURA, PARAGON, NOTA, INNE]. "
        "Zwróć tylko jedno słowo."
    )

    def format(self, content: str) -> str:
        """Łączy instrukcję z treścią dokumentu."""
        return f"{self.value}\n\nTreść dokumentu:\n{content}"
