"""
Field Confidence — structured per-field confidence metadata from OCR/AI.

Zgodnie z dokumentacją, struktura ``field_confidence`` przechowuje
poziom pewności odczytu każdego pola faktury przez OCR/AI.

Struktura (zgodna z tfgxzd.txt):
    {
        "total_gross": {"value": 1230.00, "confidence": 0.88},
        "vat_rate": {"value": 0.23, "confidence": 0.99},
        "vendor_nip": {"value": "1234567890", "confidence": 0.95}
    }

Zastosowania:
  - RiskGuard: per-field confidence thresholds
  - Rule Engine: reguły blokujące przy niskiej pewności
  - Audit: zapis pewności każdego pola w decision_traces
  - Active Learning: identyfikacja pól wymagających ręcznej korekty
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import msgspec
from msgspec import Struct

# ── Data Structures ──────────────────────────────────────────────────────────


class FieldConfidence(Struct, frozen=True):
    """Pewność odczytu pojedynczego pola faktury.

    Attributes:
        value: Wartość pola (może być str, Decimal, float, int, bool).
        confidence: Poziom pewności od 0.0 do 1.0.
        source: Źródło odczytu (np. "surya_ocr", "paddle_ocr", "llm", "regex").
    """

    value: Any
    confidence: float
    source: str = "unknown"

    def __post_init__(self) -> None:
        """Validate confidence range."""
        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError(f"Confidence must be in [0.0, 1.0], got {self.confidence}")

    def is_reliable(self, threshold: float = 0.85) -> bool:
        """Czy pole można uznać za wiarygodne powyżej zadanego progu."""
        return self.confidence >= threshold

    def with_confidence(self, confidence: float) -> FieldConfidence:
        """Zwróć nowy FieldConfidence z podmienionym confidence (frozen → replace).

        Używa ``msgspec.structs.replace()`` zamiast ręcznego kopiowania pól.
        Dzięki ``frozen=True``, oryginalny obiekt pozostaje niezmieniony.

        Args:
            confidence: Nowa wartość confidence (0.0–1.0).

        Returns:
            Nowy FieldConfidence z tym samym value/source ale nowym confidence.

        Example:
            >>> fc = FieldConfidence(value=100.0, confidence=0.5)
            >>> fc2 = fc.with_confidence(0.95)
            >>> fc2.confidence
            0.95
            >>> fc.confidence  # oryginał niezmieniony
            0.5
        """
        return msgspec.structs.replace(self, confidence=confidence)

    def with_value(self, value: Any) -> FieldConfidence:
        """Zwróć nowy FieldConfidence z podmienioną wartością (frozen → replace).

        Args:
            value: Nowa wartość.

        Returns:
            Nowy FieldConfidence z tym samym confidence/source ale nowym value.
        """
        return msgspec.structs.replace(self, value=value)

    def with_source(self, source: str) -> FieldConfidence:
        """Zwróć nowy FieldConfidence z podmienionym źródłem (frozen → replace).

        Args:
            source: Nowa nazwa źródła (np. "surya_ocr", "manual").

        Returns:
            Nowy FieldConfidence z tym samym value/confidence ale nowym source.
        """
        return msgspec.structs.replace(self, source=source)

    def to_dict(self) -> dict[str, Any]:
        """Serialize to dict for JSON storage."""
        return {
            "value": self._serialize_value(),
            "confidence": self.confidence,
            "source": self.source,
        }

    def _serialize_value(self) -> Any:
        """Serialize value for JSON (Decimal → str)."""
        if isinstance(self.value, Decimal):
            return str(self.value)
        return self.value


# ── Typ pomocniczy dla słownika field_confidence ────────────────────────────

FieldConfidenceDict = dict[str, FieldConfidence]
"""Słownik mapujący nazwę pola faktury na jego FieldConfidence.

Typowe klucze:
  - ``total_gross`` — kwota brutto
  - ``total_net`` — kwota netto
  - ``vat_rate`` — stawka VAT
  - ``vat_amount`` — kwota VAT
  - ``vendor_nip`` — NIP kontrahenta
  - ``vendor_name`` — nazwa kontrahenta
  - ``invoice_number`` — numer faktury
  - ``issue_date`` — data wystawienia
  - ``iban`` — numer konta bankowego
  - ``category_code`` — kategoria wydatku
"""

# ── Factory functions ────────────────────────────────────────────────────────


def field_confidence_from_dict(data: dict[str, dict[str, Any]]) -> FieldConfidenceDict:
    """Utwórz FieldConfidenceDict z surowego słownika przez msgspec.convert.

    Używa ``msgspec.convert(..., strict=True)`` zamiast ręcznej walidacji —
    msgspec sam rzuca ValidationError jeśli brak wymaganych pól lub typy
    się nie zgadzają. Eliminuje ~10 linii ręcznej walidacji.

    Oczekiwany format wejściowy:
    .. code-block:: json

        {
            "total_gross": {"value": 1230.00, "confidence": 0.88, "source": "surya_ocr"},
            "vat_rate": {"value": 0.23, "confidence": 0.99}
        }

    ``source`` jest opcjonalny (domyślnie ``"unknown"`` w FieldConfidence).

    Args:
        data: Surowe dane z OCR (słownik słowników).

    Returns:
        FieldConfidenceDict z walidacją przez msgspec.

    Raises:
        msgspec.ValidationError: Jeśli struktura jest nieprawidłowa.
    """
    return {
        field_name: msgspec.convert(item, FieldConfidence, strict=True)
        for field_name, item in data.items()
    }


def field_confidence_to_dict(fc: FieldConfidenceDict) -> dict[str, dict[str, Any]]:
    """Skonwertuj FieldConfidenceDict na słownik do JSON.

    Args:
        fc: FieldConfidenceDict do serializacji.

    Returns:
        Słownik gotowy do zapisu JSON.
    """
    return {name: conf.to_dict() for name, conf in fc.items()}


# ── Helpers ──────────────────────────────────────────────────────────────────


def minimum_confidence(fc: FieldConfidenceDict) -> float:
    """Zwróć najniższy confidence spośród wszystkich pól.

    Args:
        fc: FieldConfidenceDict do analizy.

    Returns:
        Minimalna wartość confidence (1.0 jeśli słownik pusty).
    """
    if not fc:
        return 1.0
    return min(conf.confidence for conf in fc.values())


def fields_below_threshold(
    fc: FieldConfidenceDict,
    threshold: float = 0.85,
) -> list[tuple[str, float]]:
    """Zwróć listę pól, których confidence jest poniżej progu.

    Args:
        fc: FieldConfidenceDict do analizy.
        threshold: Próg ufności (domyślnie 0.85).

    Returns:
        Lista (nazwa_pola, confidence) dla pól poniżej progu.
    """
    return [(name, conf.confidence) for name, conf in fc.items() if conf.confidence < threshold]


def extract_fields_with_confidence(
    fc: FieldConfidenceDict,
) -> dict[str, float]:
    """Wyodrębnij mapę {nazwa_pola: confidence} dla RiskGuard.

    Args:
        fc: FieldConfidenceDict.

    Returns:
        Słownik {nazwa_pola: confidence} gotowy do przekazania
        do ``RiskGuard.evaluate()``.
    """
    return {name: conf.confidence for name, conf in fc.items()}
