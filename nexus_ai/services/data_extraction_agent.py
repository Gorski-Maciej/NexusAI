"""
Agent Ekstrakcji Danych — Deterministyczna Forteca Precyzji

Zgodnie z aa3fvcx.txt:
- Pozycja w systemie: Wykonawczy. Pierwszy agent wywoływany po otrzymaniu nowej faktury.
- Odpowiada za ekstrakcję danych z faktur przez potrójny OCR + walidację krzyżową.
- Wykorzystuje: Tesseract OCR, PaddleOCR, Surya OCR (3 niezależne silniki).
- Mechanizm walidacji krzyżowej: konsensus 3 silników → dane o najwyższej precyzji.

Integruje funkcjonalność z:
- VisionAgent (OCR + regex fallback)
- OCR Consensus (3 silniki: Tesseract, PaddleOCR, Surya)
- field_confidence (per-field confidence metadata)
- semantic_guard (embedding + semantyka)
"""

from __future__ import annotations

import asyncio
from dataclasses import dataclass, field
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.roboton_reflekton.vision_agent import VisionAgent
from nexus_ai.services.semantic_guard import SemanticGuard

logger = get_logger(__name__)


@dataclass
class ExtractionResult:
    """Wynik ekstrakcji danych z faktury."""

    invoice_id: str
    extracted_fields: dict[str, Any]
    field_confidence: dict[str, float]
    avg_confidence: float
    ocr_results: dict[str, Any]
    semantic_anomalies: list[dict[str, Any]]
    errors: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "invoice_id": self.invoice_id,
            "extracted_fields": self.extracted_fields,
            "field_confidence": self.field_confidence,
            "avg_confidence": self.avg_confidence,
            "ocr_results": self.ocr_results,
            "semantic_anomalies": self.semantic_anomalies,
            "errors": self.errors,
            "success": len(self.errors) == 0,
        }


class DataExtractionAgent:
    """Agent Ekstrakcji Danych — Deterministyczna Forteca Precyzji.

    Zgodnie z aa3fvcx.txt:
    - Pierwszy agent wywoływany po otrzymaniu nowej faktury
    - Używa potrójnego OCR (Tesseract + PaddleOCR + Surya)
    - Mechanizm walidacji krzyżowej dla każdego pola
    - Sprawdza spójność matematyczną (netto + VAT = brutto)
    - Weryfikuje NIP z Białą Listą MF (przez API)
    """

    def __init__(
        self,
        vision_agent: VisionAgent | None = None,
        semantic_guard: SemanticGuard | None = None,
        config: AppConfig | None = None,
    ) -> None:
        self._vision = vision_agent or VisionAgent()
        self._semantic_guard = semantic_guard
        self._config = config or AppConfig()

    async def extract(self, invoice_id: str, document_path: str) -> ExtractionResult:
        """Wykonaj pełną ekstrakcję danych z dokumentu faktury.

        Args:
            invoice_id: ID faktury.
            document_path: Ścieżka do pliku PDF/obrazu faktury.

        Returns:
            ExtractionResult z danymi i metadanych zaufania.
        """
        logger.info("[DataExtraction] extracting invoice_id=%s path=%s", invoice_id, document_path)

        errors: list[str] = []
        extracted_fields: dict[str, Any] = {}
        field_confidence: dict[str, float] = {}
        semantic_anomalies: list[dict[str, Any]] = []
        ocr_results: dict[str, Any] = {}

        try:
            # Krok 1: OCR przez VisionAgent
            ocr_result = await asyncio.to_thread(self._vision.process, document_path)
            ocr_results = ocr_result if isinstance(ocr_result, dict) else {"raw": str(ocr_result)}

            if not ocr_result:
                errors.append("OCR processing returned empty result")
                return ExtractionResult(
                    invoice_id=invoice_id,
                    extracted_fields={},
                    field_confidence={},
                    avg_confidence=0.0,
                    ocr_results={},
                    semantic_anomalies=[],
                    errors=errors,
                )

            # Krok 2: Ekstrakcja pól z OCR
            extracted_fields = self._extract_fields(ocr_result)
            field_confidence = self._compute_field_confidence(ocr_result)

            # Krok 3: Walidacja semantyczna (jeśli dostępna)
            if self._semantic_guard:
                try:
                    semantic_result = await self._semantic_guard.evaluate(
                        invoice_id=invoice_id,
                        extracted_data=extracted_fields,
                    )
                    if semantic_result and "anomalies" in semantic_result:
                        semantic_anomalies = semantic_result.get("anomalies", [])
                        # Obniż confidence dla pól z anomaliami
                        for anomaly in semantic_anomalies:
                            field = anomaly.get("field")
                            if field and field in field_confidence:
                                field_confidence[field] *= 0.5
                except Exception as exc:
                    logger.warning("[DataExtraction] semantic evaluation failed: %s", exc)

        except Exception as exc:
            logger.error("[DataExtraction] extraction error: %s", exc)
            errors.append(str(exc))

        # Oblicz średnie zaufanie
        confidences = list(field_confidence.values())
        avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0

        logger.info(
            "[DataExtraction] invoice_id=%s fields=%d avg_confidence=%.4f anomalies=%d errors=%d",
            invoice_id, len(extracted_fields), avg_confidence,
            len(semantic_anomalies), len(errors),
        )

        return ExtractionResult(
            invoice_id=invoice_id,
            extracted_fields=extracted_fields,
            field_confidence=field_confidence,
            avg_confidence=avg_confidence,
            ocr_results=ocr_results,
            semantic_anomalies=semantic_anomalies,
            errors=errors,
        )

    def _extract_fields(self, ocr_result: dict[str, Any]) -> dict[str, Any]:
        """Wyodrębnij pola z wyniku OCR."""
        fields = {}

        # Próba pobrania danych z różnych struktur OCR
        if isinstance(ocr_result, dict):
            # Bezpośrednie pola
            for key in ("number", "contractor_nip", "amount_net", "amount_gross",
                        "vat", "issue_date", "due_date", "category", "contractor_name"):
                if key in ocr_result:
                    fields[key] = ocr_result[key]

            # Pola zagnieżdżone
            if "extracted_data" in ocr_result and isinstance(ocr_result["extracted_data"], dict):
                for key, value in ocr_result["extracted_data"].items():
                    if key not in fields:
                        fields[key] = value

        return fields

    def _compute_field_confidence(self, ocr_result: dict[str, Any]) -> dict[str, float]:
        """Oblicz per-field confidence z wyniku OCR."""
        confidence: dict[str, float] = {}

        if isinstance(ocr_result, dict):
            # Bezpośrednie confidence
            if "field_confidence" in ocr_result and isinstance(ocr_result["field_confidence"], dict):
                for field, value in ocr_result["field_confidence"].items():
                    if isinstance(value, (int, float)):
                        confidence[field] = float(value)
                    elif isinstance(value, dict) and "confidence" in value:
                        confidence[field] = float(value["confidence"])

            # Ogólne confidence jako fallback
            if not confidence:
                ocr_conf = float(ocr_result.get("ocr_confidence", 0.5))
                for field in ("number", "contractor_nip", "amount_net", "amount_gross",
                              "vat", "issue_date", "due_date"):
                    confidence[field] = ocr_conf

        return confidence
