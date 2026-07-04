"""Decision structs -- shared structs used by DecisionLogger and FactsAggregator.

Extracted from decision_logger.py to reduce file size (340→~260 LOC)
and avoid circular dependency between FactsAggregator and DecisionLogger.
"""

from __future__ import annotations

from typing import Any

from msgspec import Struct, field

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads


class GlobalDecision(Struct, kw_only=True):
    """Global decision from trust_score_cache (cross-contractor)."""
    __slots__ = ()
    contractor_nip: str = ""
    category: str = ""
    decision: str = ""
    trust_score: float = 0.0
    ai_confidence: float = 0.0
    timestamp: str = ""


class TrustTrend(Struct, kw_only=True):
    """Trend analysis result for a contractor's trust score."""
    __slots__ = ()
    known: bool = False
    records: int = 0
    avg_trust: float = 0.0
    min_trust: float = 0.0
    max_trust: float = 0.0
    trend: str = "stable"
    decisions_breakdown: dict[str, int] = field(default_factory=dict)
    component_averages: dict[str, float] = field(default_factory=dict)


class CorrectionStats(Struct, kw_only=True):
    """Aggregated correction statistics for adaptive weight tuning."""
    __slots__ = ()
    total_decisions: int = 0
    total_corrected: int = 0
    correction_rate: float = 0.0
    decision_breakdown: dict[str, int] = field(default_factory=dict)
    level_breakdown: dict[str, int] = field(default_factory=dict)
    correction_breakdown: list[dict[str, str | int]] = field(default_factory=list)
    ai_confidence_correction_rate: float = 0.0
    vendor_reliability_correction_rate: float = 0.0
    data_consistency_correction_rate: float = 0.0
    context_trust_correction_rate: float = 0.0


def _safe_loads(raw: object, default: object = None) -> Any:
    """Bezpiecznie deserializuj JSON string lub zwróć domyślny."""
    if isinstance(raw, str):
        try:
            return msgspec_loads(raw)
        except (DecodeError, TypeError):
            return default
    if isinstance(raw, dict):
        return raw
    return default


__all__ = ["CorrectionStats", "GlobalDecision", "TrustTrend", "_safe_loads"]
