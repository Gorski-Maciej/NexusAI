"""
Tests for EasyOCR engine integration in 4-way OCR consensus pipeline.

Testuje:
  - EasyOCREngine initialisation (mock, bez prawdziwego modelu)
  - EasyOCREngine.extract_text (mock)
  - EasyOCREngine.extract_text_with_confidence (mock)
  - 4-way consensus (Tesseract + PaddleOCR + docTR + EasyOCR)
  - decide_amount_consensus z N silnikami
  - run_ocr_pipeline z EasyOCR
  - Integrację z api/tasks.py (decide_amount_consensus dla 4 engine)
"""

from __future__ import annotations

from pathlib import Path
from typing import Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from nexus_ai.pipeline.ocr_consensus import (
    OCRAmountResult,
    OCRConsensusDecision,
    OCRFieldResult,
    decide_amount_consensus,
    decide_amount_consensus_legacy,
    decide_field_consensus,
    EasyOCREngine,
    OCREngine,
)


# ═══════════════════════════════════════════════════════════════════════════════
# EasyOCREngine — podstawowe testy
# ═══════════════════════════════════════════════════════════════════════════════


class TestEasyOCREngine:
    """Testy jednostkowe dla EasyOCREngine."""

    def test_enum_value(self) -> None:
        """OCREngine.EASY ma poprawną wartość."""
        assert OCREngine.EASY.value == "easyocr"

    def test_init_default_params(self) -> None:
        """EasyOCREngine init z domyślnymi parametrami."""
        engine = EasyOCREngine()
        assert engine.lang == "pl"
        assert engine.use_gpu is True
        assert engine.batch_size == 4
        assert engine.workers == 2
        assert engine.text_threshold == 0.5
        assert engine.link_threshold == 0.3
        assert engine.low_text == 0.3
        assert engine.paragraph_mode is True
        assert engine._reader is None  # Not initialized (no easyocr installed)
        assert engine._available is False

    def test_init_custom_params(self) -> None:
        """EasyOCREngine init z własnymi parametrami (wszystkie supermoce)."""
        engine = EasyOCREngine(
            lang="en",
            use_gpu=False,
            batch_size=8,
            workers=4,
            text_threshold=0.3,
            link_threshold=0.2,
            low_text=0.2,
            rotation_info=[90, 180, 270],
            min_size=3,
            canvas_size=1280,
            mag_ratio=2.0,
            decoder="wordbeamsearch",
            model_storage_directory="/tmp/easyocr_models",
            paragraph_mode=False,
            allowlist="0123456789",
        )
        assert engine.lang == "en"
        assert engine.use_gpu is False
        assert engine.batch_size == 8
        assert engine.workers == 4
        assert engine.text_threshold == 0.3
        assert engine.link_threshold == 0.2
        assert engine.low_text == 0.2
        assert engine.rotation_info == [90, 180, 270]
        assert engine.min_size == 3
        assert engine.canvas_size == 1280
        assert engine.mag_ratio == 2.0
        assert engine.decoder == "wordbeamsearch"
        assert engine.model_storage_directory == "/tmp/easyocr_models"
        assert engine.paragraph_mode is False
        assert engine.allowlist == "0123456789"

    def test_init_fallback_when_import_fails(self) -> None:
        """Gdy easyocr nie jest zainstalowane, engine nie jest dostępny."""
        engine = EasyOCREngine()
        assert engine._available is False
        assert engine._reader is None

    @patch("easyocr.Reader")
    def test_init_success(self, mock_reader: MagicMock) -> None:
        """Gdy easyocr jest zainstalowane, engine jest dostępny z supermocami."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        assert engine._available is True
        assert engine._reader is not None
        mock_reader.assert_called_once_with(
            ["pl", "en"],
            gpu=False,
            verbose=False,
        )

    @patch("easyocr.Reader")
    def test_init_with_model_storage(self, mock_reader: MagicMock) -> None:
        """EasyOCREngine init z model_storage_directory."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance

        engine = EasyOCREngine(
            lang="pl",
            use_gpu=False,
            model_storage_directory="/custom/path",
        )
        assert engine.model_storage_directory == "/custom/path"
        mock_reader.assert_called_once_with(
            ["pl", "en"],
            gpu=False,
            verbose=False,
            model_storage_directory="/custom/path",
        )

    @patch("easyocr.Reader")
    def test_extract_text_not_available(self, mock_reader: MagicMock) -> None:
        """Gdy engine nie jest dostępny, extract_text zwraca None."""
        engine = EasyOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_text_success(self, mock_reader: MagicMock) -> None:
        """extract_text zwraca połączony tekst z linii z supermocami."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = ["Line 1", "Line 2", "Line 3"]

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result == "Line 1\nLine 2\nLine 3"
        mock_instance.readtext.assert_called_once_with(
            "test.png",
            detail=0,
            paragraph=True,
            batch_size=4,
            workers=2,
            text_threshold=0.5,
            link_threshold=0.3,
            low_text=0.3,
            min_size=5,
            canvas_size=2560,
            mag_ratio=1.0,
            decoder="greedy",
        )

    @patch("easyocr.Reader")
    def test_extract_text_empty(self, mock_reader: MagicMock) -> None:
        """extract_text zwraca None gdy brak wyników."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = []

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_text_exception(self, mock_reader: MagicMock) -> None:
        """extract_text zwraca None przy błędzie."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.side_effect = RuntimeError("OCR failed")

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_text_with_confidence_success(self, mock_reader: MagicMock) -> None:
        """extract_text_with_confidence zwraca listę dictów z confidence z supermocami."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = [
            ([[10, 10], [100, 10], [100, 50], [10, 50]], "Line 1", 0.95),
            ([[10, 60], [100, 60], [100, 100], [10, 100]], "Line 2", 0.88),
        ]

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))
        assert result is not None
        assert len(result) == 2
        assert result[0]["text"] == "Line 1"
        assert result[0]["confidence"] == 0.95
        assert "bbox" in result[0]
        # Sprawdź że readtext dostał wszystkie supermoce
        call_kwargs = mock_instance.readtext.call_args.kwargs
        assert call_kwargs["batch_size"] == 4
        assert call_kwargs["workers"] == 2
        assert call_kwargs["detail"] == 1

    @patch("easyocr.Reader")
    def test_extract_text_with_confidence_not_available(
        self, mock_reader: MagicMock
    ) -> None:
        """extract_text_with_confidence zwraca None gdy engine nie dostępny."""
        engine = EasyOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))
        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # SUPERMOCE v3: nowe metody z audytu technologicznego
    # ════════════════════════════════════════════════════════════════════════

    @patch("easyocr.Reader")
    def test_extract_amount_success(self, mock_reader: MagicMock) -> None:
        """extract_amount wyciąga kwotę z allowlist='0123456789.,'."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = ["1230.00"]

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result == 1230.00
        # Sprawdź że allowlist został przekazany
        call_kwargs = mock_instance.readtext.call_args.kwargs
        assert call_kwargs["allowlist"] == "0123456789.,"

    @patch("easyocr.Reader")
    def test_extract_amount_not_available(self, mock_reader: MagicMock) -> None:
        """extract_amount zwraca None gdy engine nie dostępny."""
        engine = EasyOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_amount_no_result(self, mock_reader: MagicMock) -> None:
        """extract_amount zwraca None gdy brak wyników."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = []

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_digits_success(self, mock_reader: MagicMock) -> None:
        """extract_digits wyciąga NIP z allowlist='0123456789'."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = ["1234567890"]

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_digits(Path("test.png"), expected_length=10))
        assert result == "1234567890"
        call_kwargs = mock_instance.readtext.call_args.kwargs
        assert call_kwargs["allowlist"] == "0123456789"

    @patch("easyocr.Reader")
    def test_extract_digits_not_available(self, mock_reader: MagicMock) -> None:
        """extract_digits zwraca None gdy engine nie dostępny."""
        engine = EasyOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_digits(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_digits_no_digits(self, mock_reader: MagicMock) -> None:
        """extract_digits zwraca None gdy brak cyfr w wyniku."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = ["ABC DEF"]

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_digits(Path("test.png")))
        assert result is None

    @patch("easyocr.Reader")
    def test_extract_text_adaptive_success(self, mock_reader: MagicMock) -> None:
        """extract_text_adaptive działa z adaptacyjnymi progami."""
        mock_instance = MagicMock()
        mock_reader.return_value = mock_instance
        mock_instance.readtext.return_value = ["Line 1", "Line 2"]

        engine = EasyOCREngine(lang="pl", use_gpu=False)
        engine._reader = mock_instance
        engine._available = True

        # IMG = None → _assess_image_quality zwróci 0.5 → threshold=0.5, low=0.3
        result = anyio_run(engine.extract_text_adaptive(Path("test.png")))
        assert result == "Line 1\nLine 2"
        call_kwargs = mock_instance.readtext.call_args.kwargs
        assert call_kwargs["text_threshold"] == 0.5
        assert call_kwargs["low_text"] == 0.3


# ═══════════════════════════════════════════════════════════════════════════════
# Helper: ocena jakości obrazu
# ═══════════════════════════════════════════════════════════════════════════════


def test_image_quality_default() -> None:
    """_assess_image_quality zwraca 0.5 gdy obraz nie istnieje."""
    from nexus_ai.pipeline.ocr_consensus import _assess_image_quality
    result = _assess_image_quality(Path("nonexistent.png"))
    assert result == 0.5


# ═══════════════════════════════════════════════════════════════════════════════
# 4-way consensus — decide_amount_consensus z N silnikami
# ═══════════════════════════════════════════════════════════════════════════════


class TestDecideAmountConsensus4Way:
    """Testy dla 4-way amount consensus (Tesseract + PaddleOCR + docTR + EasyOCR)."""

    def test_4way_all_agree(self) -> None:
        """4/4 engines agree — consensus, no conflict."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=1230.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False
        assert consensus.accepted is not None

    def test_4way_3_agree(self) -> None:
        """3/4 engines agree — consensus (supermajority), no conflict."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=9999.00, source="easyocr"),  # Outlier
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False
        assert consensus.accepted is not None
        # The accepted value should be 1230.00 (3 votes)
        assert "1230.0" in str(consensus.accepted.value)

    def test_4way_2_agree_2_disagree(self) -> None:
        """2/4 engines agree — no consensus, conflict flagged."""
        results = [
            OCRAmountResult(amount_gross=1000.00, source="tesseract"),
            OCRAmountResult(amount_gross=1000.00, source="paddle"),
            OCRAmountResult(amount_gross=2000.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is True

    def test_4way_2_agree_1_missing_1_disagree(self) -> None:
        """2/3 available engines agree (1 None) — consensus."""
        results = [
            OCRAmountResult(amount_gross=1000.00, source="tesseract"),
            OCRAmountResult(amount_gross=1000.00, source="paddle"),
            OCRAmountResult(amount_gross=None, source="doctr"),  # Engine failed
            OCRAmountResult(amount_gross=2000.00, source="easyocr"),  # Outlier
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=2)
        assert consensus.confidence_conflict is False

    def test_4way_none(self) -> None:
        """All engines return None — no consensus."""
        results = [
            OCRAmountResult(amount_gross=None, source="tesseract"),
            OCRAmountResult(amount_gross=None, source="paddle"),
            OCRAmountResult(amount_gross=None, source="doctr"),
            OCRAmountResult(amount_gross=None, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.accepted is None
        assert consensus.confidence_conflict is False

    def test_4way_empty_list(self) -> None:
        """Empty results list — returns empty consensus."""
        consensus = decide_amount_consensus([], tolerance=0.01, majority_threshold=3)
        assert consensus.accepted is None
        assert consensus.confidence_conflict is False

    def test_4way_with_tolerance_close_values(self) -> None:
        """Values within tolerance are considered matching."""
        results = [
            OCRAmountResult(amount_gross=1000.00, source="tesseract"),
            OCRAmountResult(amount_gross=1000.01, source="paddle"),  # Within 0.01 tolerance
            OCRAmountResult(amount_gross=1000.02, source="doctr"),
            OCRAmountResult(amount_gross=1000.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.02, majority_threshold=3)
        # 1000.00, 1000.01, 1000.02 are all within 0.02 tolerance of each other
        # But grouping based on initial comparison: 1000.00 matches 1000.01 (diff=0.01 <= 0.02)
        # 1000.00 matches 1000.02 (diff=0.02 <= 0.02) so all 4 should group together
        assert consensus.confidence_conflict is False


# ═══════════════════════════════════════════════════════════════════════════════
# Legacy 2-way consensus (backward compatibility)
# ═══════════════════════════════════════════════════════════════════════════════


class TestDecideAmountConsensusLegacy:
    """Testy dla legacy 2-way amount consensus."""

    def test_2way_agree(self) -> None:
        """2/2 engines agree — consensus."""
        primary = OCRAmountResult(amount_gross=1000.00, source="doctr")
        secondary = OCRAmountResult(amount_gross=1000.01, source="paddle")
        consensus = decide_amount_consensus_legacy(primary, secondary, tolerance=0.02)
        assert consensus.confidence_conflict is False

    def test_2way_disagree(self) -> None:
        """2/2 engines disagree — conflict."""
        primary = OCRAmountResult(amount_gross=1000.00, source="doctr")
        secondary = OCRAmountResult(amount_gross=2000.00, source="paddle")
        consensus = decide_amount_consensus_legacy(primary, secondary, tolerance=0.01)
        assert consensus.confidence_conflict is True


# ═══════════════════════════════════════════════════════════════════════════════
# decide_field_consensus — 4-way field consensus
# ═══════════════════════════════════════════════════════════════════════════════


class TestDecideFieldConsensus4Way:
    """Testy decide_field_consensus z 4 silnikami."""

    def test_4way_majority_3_of_4(self) -> None:
        """3/4 engines agree on same value — consensus."""
        results = [
            OCRFieldResult(value="1234567890", confidence=0.95, source="tesseract"),
            OCRFieldResult(value="1234567890", confidence=0.90, source="paddle"),
            OCRFieldResult(value="1234567890", confidence=0.92, source="doctr"),
            OCRFieldResult(value="0987654321", confidence=0.88, source="easyocr"),
        ]
        decision = decide_field_consensus(results, min_confidence=0.5, majority_threshold=3)
        assert decision.confidence_conflict is False
        assert decision.accepted is not None
        assert decision.accepted.value == "1234567890"

    def test_4way_no_majority(self) -> None:
        """2/4 engines agree — no consensus, conflict."""
        results = [
            OCRFieldResult(value="1234567890", confidence=0.95, source="tesseract"),
            OCRFieldResult(value="1234567890", confidence=0.90, source="paddle"),
            OCRFieldResult(value="0987654321", confidence=0.92, source="doctr"),
            OCRFieldResult(value="1111111111", confidence=0.88, source="easyocr"),
        ]
        decision = decide_field_consensus(results, min_confidence=0.5, majority_threshold=3)
        assert decision.confidence_conflict is True


# ═══════════════════════════════════════════════════════════════════════════════
# Helper: run async function synchronously
# ═══════════════════════════════════════════════════════════════════════════════


def anyio_run(coro: Any) -> Any:
    """Run an anyio coroutine synchronously."""
    import anyio

    return anyio.run(coro)
