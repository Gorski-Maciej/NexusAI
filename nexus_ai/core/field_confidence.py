"""
Field Confidence — structured per-field confidence metadata from OCR/AI.

v7.0 Audit — rozszerzenia:
- Historia confidence per silnik (EngineConfidenceTracker)
- Bounding box metadata dla pól (bbox per pole)
- Multi-source tracking (które silniki zgodziły się na wartość)
- Degradacja silnika w czasie (trend analysis)
"""

from __future__ import annotations

import time
from collections import defaultdict
from decimal import Decimal
from typing import Any

import msgspec
from msgspec import Struct, field as msgspec_field


class FieldConfidence(Struct, frozen=True):
    __slots__ = ()
    """Per-field OCR confidence (value + confidence + source + bbox)."""

    value: Any
    confidence: float
    source: str = "unknown"
    # v7.0: bounding box metadata
    bbox: list[float] | None = None
    # v7.0: wszystkie źródła które głosowały na tę wartość
    all_sources: list[str] = msgspec_field(default_factory=list)

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

    def with_bbox(self, bbox: list[float] | None) -> FieldConfidence:
        return msgspec.structs.replace(self, bbox=bbox)

    def with_all_sources(self, all_sources: list[str]) -> FieldConfidence:
        return msgspec.structs.replace(self, all_sources=all_sources)

    def to_dict(self) -> dict[str, Any]:
        result = {
            "value": self._to_json_value(),
            "confidence": self.confidence,
            "source": self.source,
        }
        if self.bbox is not None:
            result["bbox"] = self.bbox
        if self.all_sources:
            result["all_sources"] = self.all_sources
        return result

    def _to_json_value(self) -> Any:
        return str(self.value) if isinstance(self.value, Decimal) else self.value


FieldConfidenceDict = dict[str, FieldConfidence]


# ═══════════════════════════════════════════════════════════════════════════
# Engine Confidence Tracker — historia confidence per silnik (v7.0)
# ═══════════════════════════════════════════════════════════════════════════

class EngineConfidenceTracker:
    """Śledzi historyczną confidence per silnik OCR.

    Raport v7.0: "Brak trackowania historii confidence per silnik —
    nie można wykryć degradacji silnika w czasie"

    Usage:
        tracker = EngineConfidenceTracker()
        tracker.record("paddle", 0.95, "vendor_nip")
        trend = tracker.get_trend("paddle")  # "stable", "degrading", "improving"
    """

    __slots__ = ('_history', '_window_size', '_degradation_threshold')

    def __init__(self, window_size: int = 100, degradation_threshold: float = 0.05) -> None:
        self._history: dict[str, list[tuple[float, float, str]]] = defaultdict(list)
        # engine_name -> [(timestamp, confidence, field_name), ...]
        self._window_size = window_size
        self._degradation_threshold = degradation_threshold

    def record(self, engine: str, confidence: float, field_name: str = "unknown") -> None:
        """Zapisz pomiar confidence dla silnika."""
        self._history[engine].append((time.time(), confidence, field_name))
        # Przycinaj historię
        if len(self._history[engine]) > self._window_size:
            self._history[engine] = self._history[engine][-self._window_size:]

    def get_average_confidence(self, engine: str, last_n: int = 20) -> float:
        """Średnia confidence z ostatnich N pomiarów."""
        entries = self._history.get(engine, [])
        if not entries:
            return 0.0
        recent = entries[-min(last_n, len(entries)):]
        return sum(c for _, c, _ in recent) / len(recent)

    def get_trend(self, engine: str) -> str:
        """Wykryj trend confidence: 'stable', 'degrading', 'improving', 'unknown'."""
        entries = self._history.get(engine, [])
        if len(entries) < 10:
            return "unknown"

        # Porównaj pierwszą połowę z drugą
        mid = len(entries) // 2
        first_half = sum(c for _, c, _ in entries[:mid]) / mid
        second_half = sum(c for _, c, _ in entries[mid:]) / (len(entries) - mid)

        diff = second_half - first_half
        if diff > self._degradation_threshold:
            return "improving"
        elif diff < -self._degradation_threshold:
            return "degrading"
        return "stable"

    def get_field_stats(self, engine: str) -> dict[str, dict[str, float]]:
        """Statystyki confidence per typ pola."""
        entries = self._history.get(engine, [])
        field_stats: dict[str, list[float]] = defaultdict(list)
        for _, conf, field_name in entries:
            field_stats[field_name].append(conf)

        return {
            field: {
                "avg": sum(confs) / len(confs),
                "min": min(confs),
                "max": max(confs),
                "count": len(confs),
            }
            for field, confs in field_stats.items()
        }

    def to_dict(self) -> dict[str, Any]:
        """Eksport do formatu JSON."""
        return {
            engine: {
                "trend": self.get_trend(engine),
                "avg_confidence": round(self.get_average_confidence(engine), 4),
                "samples": len(entries),
                "field_stats": self.get_field_stats(engine),
            }
            for engine, entries in self._history.items()
        }

    def clear(self) -> None:
        """Wyczyść historię."""
        self._history.clear()


# Globalny tracker (w produkcji powinien być wstrzykiwany przez DI)
_global_confidence_tracker = EngineConfidenceTracker()


def get_confidence_tracker() -> EngineConfidenceTracker:
    """Zwróć globalny tracker confidence."""
    return _global_confidence_tracker


# ═══════════════════════════════════════════════════════════════════════════
# Helper functions
# ═══════════════════════════════════════════════════════════════════════════

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


def build_field_confidence_with_bbox(
    field_name: str,
    value: Any,
    confidence: float,
    source: str,
    bbox: list[float] | None = None,
    all_sources: list[str] | None = None,
) -> FieldConfidence:
    """Buduje FieldConfidence z bounding boxem i multi-source (v7.0)."""
    return FieldConfidence(
        value=value,
        confidence=confidence,
        source=source,
        bbox=bbox,
        all_sources=all_sources or [],
    )


__all__ = [
    "FieldConfidence",
    "FieldConfidenceDict",
    "EngineConfidenceTracker",
    "get_confidence_tracker",
    "field_confidence_from_dict",
    "field_confidence_to_dict",
    "minimum_confidence",
    "fields_below_threshold",
    "extract_fields_with_confidence",
    "build_field_confidence_with_bbox",
]
