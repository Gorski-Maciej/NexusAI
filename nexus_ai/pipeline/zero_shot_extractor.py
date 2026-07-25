"""
Zero-Shot Field Extraction — ekstrakcja pól faktur bez definiowania reguł.

Wdrożenie Innowacji 11 z Raportu OCR v7.0:
"Zamiast definiować regex dla NIP, IBAN, kwot itp., model otrzymuje obraz
faktury i prompt z listą pól do wydobycia. Zero-shot extraction działa
dla dowolnego typu faktury (w tym zagranicznych) bez kodowania reguł."

v7.0 Audit — eliminuje potrzebę ręcznego definiowania regex parserów.
"""

from __future__ import annotations

import json
import re
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.pipeline.zero_shot")


ZERO_SHOT_EXTRACTION_PROMPT = """Jesteś ekspertem od ekstrakcji danych z polskich i międzynarodowych faktur VAT.

Otrzymujesz tekst OCR z faktury. Wydobądź następujące pola:

{field_list}

Tekst faktury (OCR):
{ocr_text}

Zasady:
1. Dla NIP: tylko cyfry, usuń myślniki i spacje
2. Dla kwot: format XXXX.XX (kropka jako separator dziesiętny)
3. Dla IBAN: format bez spacji (np. PL12345678901234567890123456)
4. Dla dat: format YYYY-MM-DD
5. Jeśli pole nie występuje, zwróć null

Zwróć TYLKO JSON (bez markdown):
{{
    "fields": {{
        "vendor_nip": "...",
        "buyer_nip": "...",
        "invoice_number": "...",
        "amount_net": "...",
        "amount_gross": "...",
        "vat_rate": "...",
        "issue_date": "...",
        "sale_date": "...",
        "iban": "...",
        "currency": "..."
    }},
    "confidence": 0.XX,
    "document_type": "invoice_vat|receipt|contract|unknown"
}}"""


# Domyślne pola do ekstrakcji
DEFAULT_EXTRACTION_FIELDS = [
    "vendor_nip",
    "buyer_nip",
    "invoice_number",
    "amount_net",
    "amount_gross",
    "vat_rate",
    "issue_date",
    "sale_date",
    "iban",
    "currency",
]

# Regex fallback dla szybkiej ścieżki (bez LLM)
FAST_PATH_PATTERNS: dict[str, str] = {
    "vendor_nip": r"(?:NIP|nip)[:\s]*(\d{3}[-.\s]?\d{3}[-.\s]?\d{2}[-.\s]?\d{2})",
    "invoice_number": r"(?:Faktura|FV|INV|nr)[:\s]*([A-Za-z0-9/\-]+)",
    "amount_gross": r"(?:brutto|razem|suma|total|do\s+zapłaty)[:\s]*(\d[\d\s,.]*\d{2})",
    "amount_net": r"(?:netto|wartość\s+netto)[:\s]*(\d[\d\s,.]*\d{2})",
    "iban": r"(?:IBAN|konto|rachunek)[:\s]*(PL\d{2}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4})",
    "issue_date": r"(?:data\s+wystawienia|date)[:\s]*(\d{4}-\d{2}-\d{2})",
    "vat_rate": r"(?:VAT|vat)[:\s]*(\d{1,2}%?)",
    "currency": r"\b(PLN|EUR|USD|GBP|CHF|zł)\b",
}


class ZeroShotFieldExtractor:
    """Ekstraktor pól faktur bez definiowania reguł.

    Usage:
        extractor = ZeroShotFieldExtractor(model_manager, "granite-3.2.Q4_K_M.gguf")
        fields = await extractor.extract(ocr_text)
        # fields = {"vendor_nip": "1234567890", "amount_gross": "1230.00", ...}
    """

    __slots__ = ('_model_manager', '_model_path', '_use_ai')

    def __init__(
        self,
        model_manager: Any = None,
        model_path: str | None = None,
        use_ai: bool = False,  # False = fast path regex only
    ) -> None:
        self._model_manager = model_manager
        self._model_path = model_path
        self._use_ai = use_ai

    async def extract(
        self,
        ocr_text: str,
        fields: list[str] | None = None,
        document_context: str = "",
    ) -> dict[str, Any]:
        """Wydobądź pola z tekstu OCR.

        Args:
            ocr_text: Pełny tekst OCR z faktury.
            fields: Lista pól do ekstrakcji (None = wszystkie domyślne).
            document_context: Dodatkowy kontekst (layout, typ dokumentu).

        Returns:
            Słownik z wyekstrahowanymi polami i metadanymi.
        """
        if fields is None:
            fields = DEFAULT_EXTRACTION_FIELDS

        # ── Szybka ścieżka: regex (bez LLM) ──────────────────────
        regex_result = self._fast_path_extract(ocr_text, fields)
        regex_confidence = self._compute_regex_confidence(regex_result, fields)

        # Jeśli regex ma wysoką confidence (>0.85), zwróć natychmiast
        if regex_confidence >= 0.85:
            logger.info("[ZERO-SHOT] Fast path: regex confidence=%.3f", regex_confidence)
            return {
                "fields": regex_result,
                "confidence": regex_confidence,
                "method": "regex_fast_path",
                "document_type": self._detect_document_type(ocr_text),
            }

        # ── Ścieżka AI: LLM-based extraction ─────────────────────
        if self._use_ai and self._model_manager is not None and self._model_path is not None:
            try:
                ai_result = await self._ai_extract(ocr_text, fields, document_context)
                if ai_result and ai_result.get("confidence", 0) > regex_confidence:
                    logger.info("[ZERO-SHOT] AI path: confidence=%.3f", ai_result.get("confidence", 0))
                    return {
                        "fields": ai_result.get("fields", regex_result),
                        "confidence": ai_result.get("confidence", regex_confidence),
                        "method": "ai_zero_shot",
                        "document_type": ai_result.get("document_type", "unknown"),
                    }
            except Exception as exc:
                logger.warning("[ZERO-SHOT] AI extraction failed: %s", exc)

        # Fallback: regex result
        return {
            "fields": regex_result,
            "confidence": regex_confidence,
            "method": "regex_fallback",
            "document_type": self._detect_document_type(ocr_text),
        }

    def _fast_path_extract(self, ocr_text: str, fields: list[str]) -> dict[str, Any]:
        """Szybka ekstrakcja regex (bez LLM)."""
        result: dict[str, Any] = {}
        for field in fields:
            pattern = FAST_PATH_PATTERNS.get(field)
            if pattern:
                match = re.search(pattern, ocr_text, re.IGNORECASE)
                if match:
                    value = match.group(1).strip()
                    # Clean up
                    value = self._clean_field_value(field, value)
                    result[field] = value
                else:
                    result[field] = None
            else:
                result[field] = None
        return result

    @staticmethod
    def _clean_field_value(field: str, value: str) -> str:
        """Wyczyść wartość pola do standardowego formatu."""
        if field in ("vendor_nip", "buyer_nip"):
            return re.sub(r"[-\s.]", "", value)
        if field in ("amount_gross", "amount_net"):
            return value.replace(",", ".").replace(" ", "")
        if field in ("iban",):
            return re.sub(r"\s", "", value).upper()
        if field == "vat_rate":
            return value.replace("%", "").strip()
        if field in ("issue_date", "sale_date"):
            # Normalize date format
            return value.replace("/", "-").replace(".", "-")
        return value.strip()

    def _compute_regex_confidence(self, result: dict[str, Any], fields: list[str]) -> float:
        """Oblicz confidence na podstawie liczby znalezionych pól."""
        if not fields:
            return 0.0
        found = sum(1 for f in fields if result.get(f) is not None)
        return round(found / len(fields), 4)

    @staticmethod
    def _detect_document_type(ocr_text: str) -> str:
        """Wykryj typ dokumentu."""
        text_lower = ocr_text.lower()
        if any(kw in text_lower for kw in ("faktura", "vat", "nip:")):
            return "invoice_vat"
        if any(kw in text_lower for kw in ("paragon", "receipt")):
            return "receipt"
        if any(kw in text_lower for kw in ("agreement", "contract", "terms")):
            return "contract"
        return "unknown"

    async def _ai_extract(
        self, ocr_text: str, fields: list[str], document_context: str
    ) -> dict[str, Any] | None:
        """Ekstrakcja przez AI (LLM)."""
        field_list = "\n".join(f"- {f}" for f in fields)
        prompt = ZERO_SHOT_EXTRACTION_PROMPT.format(
            field_list=field_list,
            ocr_text=ocr_text[:3000],
        )

        result_text = await self._model_manager.chat(
            self._model_path,
            [{"role": "user", "content": prompt}],
            max_tokens=512,
            temperature=0.1,
        )

        # Parsuj JSON
        result_clean = result_text.strip()
        if "```json" in result_clean:
            result_clean = result_clean.split("```json")[1].split("```")[0]
        elif "```" in result_clean:
            result_clean = result_clean.split("```")[1].split("```")[0]

        data = json.loads(result_clean)
        return data

    async def extract_with_validation(
        self,
        ocr_text: str,
        fields: list[str] | None = None,
    ) -> dict[str, Any]:
        """Ekstrakcja z dodatkową walidacją semantyczną (NIP checksum, IBAN format)."""
        result = await self.extract(ocr_text, fields)
        fields_data = result.get("fields", {})

        # Walidacja NIP
        if "vendor_nip" in fields_data and fields_data["vendor_nip"]:
            fields_data["vendor_nip_valid"] = self._validate_nip(fields_data["vendor_nip"])

        if "buyer_nip" in fields_data and fields_data["buyer_nip"]:
            fields_data["buyer_nip_valid"] = self._validate_nip(fields_data["buyer_nip"])

        # Walidacja IBAN
        if "iban" in fields_data and fields_data["iban"]:
            fields_data["iban_valid"] = self._validate_iban(fields_data["iban"])

        result["fields"] = fields_data
        return result

    @staticmethod
    def _validate_nip(nip: str) -> bool:
        """Sprawdź sumę kontrolną NIP."""
        cleaned = re.sub(r"\D", "", nip)
        if len(cleaned) != 10:
            return False
        weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
        try:
            digits = [int(d) for d in cleaned]
            checksum = sum(d * w for d, w in zip(digits[:9], weights)) % 11
            return checksum == digits[9]
        except (ValueError, IndexError):
            return False

    @staticmethod
    def _validate_iban(iban: str) -> bool:
        """Sprawdź format IBAN."""
        cleaned = re.sub(r"\s", "", iban).upper()
        return bool(re.match(r"^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$", cleaned))


__all__ = [
    "ZeroShotFieldExtractor",
    "ZERO_SHOT_EXTRACTION_PROMPT",
    "DEFAULT_EXTRACTION_FIELDS",
    "FAST_PATH_PATTERNS",
]
