"""
Field Confidence — structured per-field confidence metadata from OCR/AI.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import msgspec
from msgspec import Struct


class FieldConfidence(Struct, frozen=True):
    """Per-field OCR confidence (value + confidence + source)."""

    value: Any
    confidence: float
    source: str = "unknown"

    def __post_init__(self) -> None:
        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError(f"Confidence must be in [0.0, 1.0], got {self.confidence}")

    def is_reliable(self, threshold: float = 0.85) -> bool:
        return self.confidence >= threshold

    def with_confidence(self, confidence: float) -> FieldConfidence:
        return msgspec.structs.replace(self, confidence=confidence)

    def with_value(self, value: Any) -> FieldConfidence:
        return msgspec.structs.replace(self, value=value)

    def with_source(self, source: str) -> FieldConfidence:
        return msgspec.structs.replace(self, source=source)

    def to_dict(self) -> dict[str, Any]:
        return {"value": self._to_json_value(), "confidence": self.confidence, "source": self.source}

    def _to_json_value(self) -> Any:
        return str(self.value) if isinstance(self.value, Decimal) else self.value


FieldConfidenceDict = dict[str, FieldConfidence]


def field_confidence_from_dict(data: dict[str, dict[str, Any]]) -> FieldConfidenceDict:
    """Create FieldConfidenceDict from raw dict via msgspec.convert."""
    return {k: msgspec.convert(v, FieldConfidence, strict=True) for k, v in data.items()}


def field_confidence_to_dict(fc: FieldConfidenceDict) -> dict[str, dict[str, Any]]:
    """Convert FieldConfidenceDict to JSON-safe dict."""
    return {name: conf.to_dict() for name, conf in fc.items()}


def minimum_confidence(fc: FieldConfidenceDict) -> float:
    """Minimum confidence across all fields (1.0 if empty)."""
    return min((c.confidence for c in fc.values()), default=1.0)


def fields_below_threshold(fc: FieldConfidenceDict, threshold: float = 0.85) -> list[tuple[str, float]]:
    """Fields with confidence below threshold."""
    return [(n, c.confidence) for n, c in fc.items() if c.confidence < threshold]


def extract_fields_with_confidence(fc: FieldConfidenceDict) -> dict[str, float]:
    """Extract {field: confidence} map for RiskGuard.evaluate()."""
    return {n: c.confidence for n, c in fc.items()}
