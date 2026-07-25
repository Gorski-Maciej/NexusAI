"""
Cross-Engine Attention — mechanizm korekcji między silnikami OCR.

Wdrożenie Innowacji 2 z Raportu OCR v7.0:
"Zamiast prostego głosowania, zaimplementować mechanizm Cross-Engine
Attention, gdzie każdy silnik otrzymuje wyniki pozostałych jako kontekst
i może skorygować swoje predykcje. Może zwiększyć dokładność o 2-5pp."

v7.0 Audit — unikalny mechanizm na rynku open-source.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.pipeline.cross_engine_attention")


def cross_engine_attention_correction(
    results: dict[str, Any],
    field_name: str,
    consensus_value: str,
    consensus_confidence: float,
    correction_threshold: float = 0.3,
) -> dict[str, Any]:
    """Mechanizm Cross-Engine Attention — każdy silnik może skorygować predykcję.

    Jeśli konsensus wybrał wartość X, ale silnik Y ma bardzo niską confidence
    dla swojej wartości i widzi, że X jest bardziej prawdopodobne w kontekście
    pozostałych silników, może "przegłosować" swoją wartość.

    Args:
        results: Wyniki wszystkich silników {engine_name: {text, confidence, ...}}.
        field_name: Nazwa pola.
        consensus_value: Wartość wybrana przez konsensus.
        consensus_confidence: Confidence konsensusu.
        correction_threshold: Próg różnicy confidence do korekcji.

    Returns:
        Zaktualizowane wyniki z ewentualnymi korekcjami.
    """
    corrected_results: dict[str, Any] = {}
    corrections_applied = 0

    for engine_name, engine_data in results.items():
        engine_value = engine_data.get("text") if isinstance(engine_data, dict) else engine_data
        engine_conf = _extract_confidence(engine_data, field_name)

        # Sprawdź czy silnik powinien skorygować swoją wartość
        if (
            engine_value is not None
            and engine_value != consensus_value
            and engine_conf < consensus_confidence - correction_threshold
            and consensus_confidence > 0.7
        ):
            # Silnik ma niską confidence, a konsensus jest silny → korekta
            logger.debug(
                "[CROSS-ATTN] %s corrected '%s' → '%s' (conf %.2f → consensus %.2f)",
                engine_name, engine_value, consensus_value,
                engine_conf, consensus_confidence,
            )
            if isinstance(engine_data, dict):
                corrected = dict(engine_data)
                corrected["text"] = consensus_value
                corrected["cross_engine_corrected"] = True
                corrected["original_value"] = engine_value
                corrected_results[engine_name] = corrected
            else:
                corrected_results[engine_name] = consensus_value
            corrections_applied += 1
        else:
            corrected_results[engine_name] = engine_data

    if corrections_applied > 0:
        logger.info("[CROSS-ATTN] Applied %d cross-engine corrections for field '%s'",
                     corrections_applied, field_name)

    return corrected_results


def _extract_confidence(engine_data: Any, field_name: str) -> float:
    """Wyciągnij confidence z danych silnika."""
    if isinstance(engine_data, dict):
        conf_list = engine_data.get("confidence")
        if isinstance(conf_list, list) and conf_list:
            # Średnia confidence z listy
            confs = [w.get("confidence", 0.0) for w in conf_list if isinstance(w, dict)]
            return sum(confs) / len(confs) if confs else 0.5
        return float(engine_data.get("confidence", 0.5))
    return 0.5


def apply_cross_engine_attention_batch(
    field_results: dict[str, list[dict[str, Any]]],
    consensus_decisions: dict[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    """Zastosuj Cross-Engine Attention do wszystkich pól.

    Args:
        field_results: {field_name: [{engine: ..., value: ..., confidence: ...}, ...]}
        consensus_decisions: {field_name: OCRConsensusDecision}

    Returns:
        Zaktualizowane field_results z korekcjami.
    """
    for field_name, field_votes in field_results.items():
        consensus = consensus_decisions.get(field_name)
        if consensus is None or not consensus.confidence_conflict:
            continue

        # Próbuj skorygować outlier engine
        corrected = cross_engine_attention_correction(
            {v.get("engine", f"unknown_{i}"): v for i, v in enumerate(field_votes)},
            field_name,
            consensus.accepted.value if consensus.accepted else "",
            0.85 if not consensus.confidence_conflict else 0.7,
        )

        # Aktualizuj wyniki
        for i, vote in enumerate(field_votes):
            engine_key = vote.get("engine", f"unknown_{i}")
            if engine_key in corrected:
                updated = corrected[engine_key]
                if isinstance(updated, dict) and updated.get("cross_engine_corrected"):
                    field_votes[i] = {**vote, **updated}

    return field_results


__all__ = [
    "cross_engine_attention_correction",
    "apply_cross_engine_attention_batch",
]
