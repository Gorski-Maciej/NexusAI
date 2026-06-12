"""Vision agent — ekstrakcja wizualna z faktur.

Zgodnie z aa3fvcx.txt: torch/transformers zastąpione przez LightOnOCR-1B VLM.
W międzyczasie VisionAgent używa fallbacku regexowego z OCR textu.
Qwen2.5-VL (torch/transformers) usunięty — niepotrzebny w nowej architekturze.
"""

from __future__ import annotations

import re
from msgspec import Struct
from pathlib import Path
from typing import Any

class VisionExtraction(Struct):
    """Wynik ekstrakcji wizualnej z faktury."""
    vendor_nip: str | None
    total_gross: float | None
    vat_rate: float | None
    payment_status: str
    visual_anomalies_detected: bool
    handwritten_notes_summary: str
    source: str = "ocr-fallback"

def _to_float(value: Any) -> float | None:
    if value is None:
        return None
    try:
        return float(str(value).replace(" ", "").replace(",", "."))
    except ValueError:
        return None

class VisionAgent:
    """Ekstrakcja wizualna z obrazów faktur przez heurystyki OCR.

    Docelowo: LightOnOCR-1B VLM (aa3fvcx.txt Punkt 10).
    Obecnie: fallback regexowy bez torch/transformers ani GPU.
    """

    def __init__(
        self,
        model_name: str = "",
        use_4bit: bool = True,
        max_new_tokens: int = 220,
    ) -> None:
        del model_name, use_4bit, max_new_tokens

    async def analyze(self, image_path: Path, ocr_text: str) -> VisionExtraction:
        """Analyze invoice image using OCR text heuristics.

        Args:
            image_path: Ścieżka do obrazu (ignorowana — ekstrakcja z tekstu).
            ocr_text: Tekst z OCR do analizy.

        Returns:
            VisionExtraction z wyekstrahowanymi polami.
        """
        return self._fallback_from_ocr(ocr_text)

    @staticmethod
    def _fallback_from_ocr(raw_text: str) -> VisionExtraction:
        """Extract invoice fields from OCR text using regex heuristics."""
        normalized = raw_text.replace("\n", " ")
        nip_match = re.search(r"\b\d{10}\b", normalized)
        gross_match = re.search(
            r"(?:brutto|total|razem)\D{0,12}(\d[\d\s]*[.,]\d{2})",
            normalized, re.IGNORECASE,
        )
        vat_match = re.search(
            r"(?:VAT|PTU)\D{0,6}(\d{1,2})\s?%", normalized, re.IGNORECASE,
        )
        paid = bool(re.search(
            r"\b(zapłacono|paid|opłacono)\b", normalized, re.IGNORECASE,
        ))
        anomalies = bool(re.search(
            r"\b(korekta|duplikat|anulowano)\b", normalized, re.IGNORECASE,
        ))
        handwritten_hint = (
            "possible handwritten note detected"
            if "odręcz" in normalized.lower()
            else ""
        )

        total_gross = None
        if gross_match:
            total_gross = _to_float(gross_match.group(1))

        return VisionExtraction(
            vendor_nip=nip_match.group(0) if nip_match else None,
            total_gross=total_gross,
            vat_rate=_to_float(vat_match.group(1)) if vat_match else None,
            payment_status="paid" if paid else "unknown",
            visual_anomalies_detected=anomalies,
            handwritten_notes_summary=handwritten_hint,
            source="ocr-fallback",
        )
