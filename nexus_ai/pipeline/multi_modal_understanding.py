"""
Multi-Modal Document Understanding — rozumienie dokumentów przez wiele modalności.

Wdrożenie Innowacji 12 z Raportu OCR v7.0:
"Połączenie OCR (tekst) + layout analysis (PP-Structure) + vision model
(Granite 3.2 Vision) + semantic (SemanticGuard) w jedną predykcję."

4 modalności:
1. OCR (tekst) — rozpoznanie znaków
2. Layout analysis (PP-Structure) — struktura wizualna
3. Vision model (Granite 3.2 Vision) — rozumienie kontekstu wizualnego
4. Semantic (SemanticGuard) — rozumienie znaczenia biznesowego

v7.0 Audit — unikalna fuzja 4 modalności dla maksymalnej dokładności.
"""

from __future__ import annotations

from typing import Any

from msgspec import Struct, field as msgspec_field
from structlog import get_logger

logger = get_logger("nexus.pipeline.multi_modal")


class MultiModalResult(Struct, kw_only=True):
    """Wynik multi-modalnego rozumienia dokumentu."""
    field_name: str
    ocr_value: str | None = None
    ocr_confidence: float = 0.0
    layout_position: str | None = None  # "header", "body", "footer"
    layout_confidence: float = 0.0
    vision_value: str | None = None
    vision_confidence: float = 0.0
    semantic_valid: bool = False
    semantic_confidence: float = 0.0
    # Fuzja
    fused_value: str | None = None
    fused_confidence: float = 0.0
    modality_weights: dict[str, float] = msgspec_field(default_factory=dict)
    reasoning: str = ""


class MultiModalDocumentUnderstanding:
    """Silnik multi-modalnego rozumienia dokumentów.

    Łączy 4 modalności w jedną predykcję dla każdego pola faktury.
    """

    __slots__ = ('_modal_weights',)

    # Domyślne wagi modalności (suma = 1.0)
    DEFAULT_MODAL_WEIGHTS: dict[str, float] = {
        "ocr": 0.35,      # OCR — podstawa
        "layout": 0.20,   # Layout — struktura wizualna
        "vision": 0.25,   # Vision — kontekst wizualny
        "semantic": 0.20, # Semantic — znaczenie biznesowe
    }

    def __init__(self, modal_weights: dict[str, float] | None = None) -> None:
        self._modal_weights = dict(modal_weights) if modal_weights else dict(self.DEFAULT_MODAL_WEIGHTS)

    def fuse(
        self,
        field_name: str,
        ocr_value: str | None,
        ocr_confidence: float,
        layout_blocks: list[dict[str, Any]] | None = None,
        vision_result: dict[str, Any] | None = None,
        semantic_context: dict[str, Any] | None = None,
    ) -> MultiModalResult:
        """Fuza 4 modalności w jedną predykcję.

        Args:
            field_name: Nazwa pola (np. "vendor_nip", "amount_gross").
            ocr_value: Wartość z konsensusu OCR.
            ocr_confidence: Confidence OCR.
            layout_blocks: Bloki layout z PP-Structure.
            vision_result: Wynik analizy wizualnej (Granite 3.2 Vision).
            semantic_context: Kontekst semantyczny (SemanticGuard).

        Returns:
            MultiModalResult z sfuzowaną wartością i confidence.
        """
        result = MultiModalResult(field_name=field_name)

        # ── Modalność 1: OCR ─────────────────────────────────────
        result.ocr_value = ocr_value
        result.ocr_confidence = ocr_confidence

        # ── Modalność 2: Layout ──────────────────────────────────
        if layout_blocks:
            layout_info = self._analyze_layout(field_name, ocr_value, layout_blocks)
            result.layout_position = layout_info.get("position", "unknown")
            result.layout_confidence = layout_info.get("confidence", 0.5)
        else:
            result.layout_position = "unknown"
            result.layout_confidence = 0.3

        # ── Modalność 3: Vision ──────────────────────────────────
        if vision_result:
            result.vision_value = vision_result.get("value")
            result.vision_confidence = float(vision_result.get("confidence", 0.0))
        else:
            result.vision_confidence = 0.0

        # ── Modalność 4: Semantic ────────────────────────────────
        if semantic_context:
            result.semantic_valid = self._validate_semantic(field_name, ocr_value, semantic_context)
            result.semantic_confidence = 0.9 if result.semantic_valid else 0.3
        else:
            result.semantic_confidence = 0.5

        # ── Fuzja ────────────────────────────────────────────────
        fused = self._compute_fusion(result)
        result.fused_value = fused["value"]
        result.fused_confidence = fused["confidence"]
        result.modality_weights = self._modal_weights
        result.reasoning = self._build_reasoning(result)

        logger.info(
            "[MULTI-MODAL] %s: fused=%.3f (ocr=%.3f, layout=%.3f, vision=%.3f, semantic=%.3f)",
            field_name, result.fused_confidence,
            result.ocr_confidence, result.layout_confidence,
            result.vision_confidence, result.semantic_confidence,
        )

        return result

    def _analyze_layout(
        self, field_name: str, value: str | None, blocks: list[dict[str, Any]]
    ) -> dict[str, Any]:
        """Analiza layout — gdzie na stronie znajduje się pole?"""
        if not value or not blocks:
            return {"position": "unknown", "confidence": 0.5}

        # Szukaj bloku zawierającego wartość
        for block in blocks:
            block_text = block.get("text", "")
            if value in block_text or block_text in (value or ""):
                bbox = block.get("bbox", [])
                if bbox and len(bbox) > 0:
                    y_center = sum(p[1] for p in bbox) / len(bbox) if isinstance(bbox[0], (list, tuple)) else bbox[1]
                    return {
                        "position": "header" if y_center < 0.3 else ("footer" if y_center > 0.7 else "body"),
                        "confidence": block.get("confidence", 0.7),
                    }

        return {"position": "unknown", "confidence": 0.3}

    @staticmethod
    def _validate_semantic(
        field_name: str, value: str | None, context: dict[str, Any]
    ) -> bool:
        """Walidacja semantyczna pola."""
        if value is None:
            return False

        if field_name == "vendor_nip":
            # Sprawdź czy NIP istnieje w kontekście
            return context.get("vendor_vat_status") != "inactive"

        if field_name == "amount_gross":
            # Sprawdź czy kwota nie przekracza progu
            try:
                amount = float(value)
                if amount > 999999999.99:
                    return False
            except (ValueError, TypeError):
                return False

        if field_name == "iban":
            # Sprawdź czy konto jest na białej liście
            return context.get("vendor_account_on_whitelist", False)

        return True

    def _compute_fusion(self, result: MultiModalResult) -> dict[str, Any]:
        """Oblicz sfuzowaną wartość przez ważoną średnią confidence."""
        values: list[tuple[str, float]] = []

        if result.ocr_value:
            values.append((result.ocr_value, result.ocr_confidence * self._modal_weights.get("ocr", 0.35)))

        if result.vision_value:
            values.append((result.vision_value, result.vision_confidence * self._modal_weights.get("vision", 0.25)))

        # Grupuj wartości i sumuj wagi
        weighted: dict[str, float] = {}
        for val, weight in values:
            weighted[val] = weighted.get(val, 0.0) + weight

        if not weighted:
            return {"value": None, "confidence": 0.0}

        best_value = max(weighted, key=weighted.get)
        total_confidence = weighted[best_value]

        # Dodaj bonus za layout i semantic
        layout_bonus = result.layout_confidence * self._modal_weights.get("layout", 0.20) * 0.5
        semantic_bonus = result.semantic_confidence * self._modal_weights.get("semantic", 0.20) * 0.5

        # Ważona fuzja
        ocr_w = self._modal_weights.get("ocr", 0.35)
        layout_w = self._modal_weights.get("layout", 0.20)
        vision_w = self._modal_weights.get("vision", 0.25)
        semantic_w = self._modal_weights.get("semantic", 0.20)

        fused_confidence = min(1.0,
            result.ocr_confidence * ocr_w +
            result.layout_confidence * layout_w +
            result.vision_confidence * vision_w +
            result.semantic_confidence * semantic_w
        )

        return {
            "value": best_value,
            "confidence": round(fused_confidence, 4),
        }

    @staticmethod
    def _build_reasoning(result: MultiModalResult) -> str:
        """Zbuduj uzasadnienie decyzji."""
        parts = []
        if result.ocr_confidence >= 0.8:
            parts.append(f"OCR high confidence ({result.ocr_confidence:.2f})")
        if result.layout_position != "unknown":
            parts.append(f"layout in {result.layout_position}")
        if result.vision_value:
            parts.append(f"vision confirmed: {result.vision_value}")
        if result.semantic_valid:
            parts.append("semantic validation passed")
        return "; ".join(parts) if parts else "no strong signal"


__all__ = [
    "MultiModalDocumentUnderstanding",
    "MultiModalResult",
]
