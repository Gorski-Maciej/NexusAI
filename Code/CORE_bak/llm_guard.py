# core/llm_guard.py
import json
import re
from pydantic import BaseModel, ValidationError
from decimal import Decimal
from typing import Optional
from core.exceptions import LLMGuardrailError
from core.logger import logger

class InvoiceLLMExtraction(BaseModel):
    """Oczekiwana struktura danych od lokalnego modelu Llama/Phi-3."""
    numer_faktury: Optional[str] = None
    data_sprzedazy: Optional[str] = None
    kwota_netto: Optional[Decimal] = None
    kwota_vat: Optional[Decimal] = None
    kwota_brutto: Optional[Decimal] = None
    waluta: str = "PLN"
    nip_sprzedawcy: Optional[str] = None

class LLMGuard:
    """Naprawia i weryfikuje 'brudne' wyjścia z lokalnych modeli LLM."""

    @staticmethod
    def parse_and_validate(raw_llm_output: str) -> dict:
        """Ekstrahuje JSON z markdownu LLM, naprawia błędy i waliduje przez Pydantic."""
        try:
            # Próba znalezienia bloku JSON w tekście
            json_match = re.search(r'```json\s*(.*?)\s*```', raw_llm_output, re.DOTALL)
            json_str = json_match.group(1) if json_match else raw_llm_output

            data = json.loads(json_str)
            validated = InvoiceLLMExtraction(**data)
            return validated.dict()
        except (json.JSONDecodeError, ValidationError) as e:
            logger.error(f"Błąd LLMGuard: {e}")
            raise LLMGuardrailError(f"Niepoprawny wynik LLM: {str(e)}")
