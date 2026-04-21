# pipeline/llm_extractor.py
import msgspec
from typing import Optional
from decimal import Decimal
from core.logger import logger

class ExtractedInvoice(msgspec.Struct):
    """Docelowy schemat danych, który musi zwrócić model LLM."""
    number: Optional[str]
    contractor_nip: Optional[str]
    contractor_name: Optional[str]
    amount_net: Decimal
    amount_gross: Decimal
    currency: str = "PLN"
    issue_date: Optional[str]
    iban: Optional[str]

class VisionDataExtractor:
    """Zastępuje stary InvoiceParser oparty na regexach."""

    def __init__(self, llm_engine):
        self.llm = llm_engine # Np. Twój załadowany Phi-3-Vision lub Hermes

    async def extract(self, full_text: str) -> ExtractedInvoice:
        """Wykorzystuje LLM do inteligentnej interpretacji tekstu faktury."""
        prompt = f"""
        Jesteś ekspertem księgowym. Wyciągnij dane z poniższego tekstu faktury OCR.
        Zwróć TYLKO czysty JSON zgodny ze strukturą.
        {{
            "number": "",
            "contractor_nip": "",
            "contractor_name": "",
            "amount_net": 0.0,
            "amount_gross": 0.0,
            "currency": "PLN",
            "issue_date": "",
            "iban": ""
        }}
        Tekst: {full_text}
        """
        # Pseudo kod komunikacji z llm
        # response_text = await self.llm.generate(prompt)
        # return msgspec.json.decode(response_text, type=ExtractedInvoice)
        return None
