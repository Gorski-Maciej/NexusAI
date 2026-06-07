# core/llm_guard.py
from __future__ import annotations

import json
import re
from typing import Any

import msgspec

from nexus_ai.core.exceptions import LLMGuardrailError
from nexus_ai.core.logger import logger
from nexus_ai.core.msgspec_utils import msgspec_loads


class InvoiceLLMExtraction(msgspec.Struct):
    """Oczekiwana struktura danych od lokalnego modelu Llama/Phi-3."""

    numer_faktury: str | None = None
    data_sprzedazy: str | None = None
    kwota_netto: float | None = None
    kwota_vat: float | None = None
    kwota_brutto: float | None = None
    waluta: str = "PLN"
    nip_sprzedawcy: str | None = None


class LLMGuard:
    """Naprawia i weryfikuje 'brudne' wyjścia z lokalnych modeli LLM."""

    @staticmethod
    def parse_and_validate(raw_llm_output: str) -> dict[str, Any]:
        """Ekstrahuje JSON z markdownu LLM, naprawia błędy i waliduje przez msgspec."""
        try:
            # Próba znalezienia bloku JSON w tekście
            json_match = re.search(r'```json\s*(.*?)\s*```', raw_llm_output, re.DOTALL)
            json_str = json_match.group(1) if json_match else raw_llm_output

            data = msgspec_loads(json_str)
            validated = msgspec.convert(data, InvoiceLLMExtraction)
            # Convert to dict for serializable output
            result = msgspec.to_builtins(validated)
            return result
        except (json.JSONDecodeError, msgspec.ValidationError) as e:
            logger.error(f"Błąd LLMGuard: {e}")
            raise LLMGuardrailError(f"Niepoprawny wynik LLM: {str(e)}")
