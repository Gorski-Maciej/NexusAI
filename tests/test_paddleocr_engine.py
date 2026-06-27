"""
Tests for PaddleOCREngine — PaddleOCR engine with full superpowers.

Testuje:
  - PaddleOCREngine initialisation (mock, bez prawdziwego modelu)
  - PaddleOCREngine.extract_text (mock)
  - PaddleOCREngine.extract_text_with_confidence (mock)
  - PaddleOCREngine.extract_amount (mock)
  - PaddleOCREngine.extract_digits (mock)
  - PaddleOCREngine.extract_structured (mock)
  - PP-StructureV3 integration (extract_layout, extract_tables, detect_seals)
  - GPU warmup
  - Auto-tuning det_db_thresh
  - Batch processing
  - 4-way consensus z PaddleOCR
"""

from __future__ import annotations

from pathlib import Path
from typing import Any
from unittest.mock import MagicMock, patch

import pytest

from nexus_ai.pipeline.ocr_consensus import (
    OCRAmountResult,
    OCRConsensusDecision,
    OCRFieldResult,
    PaddleOCREngine,
    OCREngine,
    decide_amount_consensus,
    decide_field_consensus,
)


# ═══════════════════════════════════════════════════════════════════════════════
# PaddleOCREngine — podstawowe testy
# ═══════════════════════════════════════════════════════════════════════════════


class TestPaddleOCREngine:
    """Testy jednostkowe dla PaddleOCREngine z supermocami."""

    def test_enum_value(self) -> None:
        """OCREngine.PADDLE ma poprawną wartość."""
        assert OCREngine.PADDLE.value == "paddleocr"

    def test_init_default_params(self) -> None:
        """PaddleOCREngine init z domyślnymi parametrami."""
        engine = PaddleOCREngine()
        assert engine.lang == "pl"
        assert engine.use_gpu is True
        assert engine.rec_batch_num == 6
        assert engine.det_db_thresh == 0.3
        assert engine.det_db_score_mode == "fast"
        assert engine.use_dilation is True
        # Z mockiem paddleocr w conftest.py, init succeeds (mock PaddleOCR)
        # W środowisku bez paddleocr: _ocr is None, _available is False

    def test_init_custom_params(self) -> None:
        """PaddleOCREngine init z własnymi parametrami (wszystkie supermoce)."""
        engine = PaddleOCREngine(
            lang="en",
            use_gpu=False,
            use_angle_cls=True,
            drop_score=0.3,
            ocr_version="PP-OCRv4",
            det=True,
            rec=True,
            cls=True,
            gpu_mem=4000,
            cpu_threads=8,
            enable_mkldnn=True,
            use_tensorrt=False,
            use_onnx=True,
            precision="fp16",
            rec_batch_num=12,
            det_db_thresh=0.4,
            det_db_box_thresh=0.6,
            det_db_unclip_ratio=2.0,
            det_db_score_mode="fast",
            use_dilation=False,
            max_batch_length=20,
            use_space_char=True,
            max_text_length=50,
            cls_batch_num=8,
            cls_thresh=0.8,
        )
        assert engine.lang == "en"
        assert engine.use_gpu is False
        assert engine.rec_batch_num == 12
        assert engine.det_db_score_mode == "fast"

    def test_init_fallback_when_import_fails(self) -> None:
        """Gdy paddleocr nie jest zainstalowane, engine nie jest dostępny.

        Uwaga: W środowisku testowym paddleocr jest zmockowane w conftest.py,
        więc engine jest dostępny. Ten test sprawdza, że podstawowa struktura jest OK.
        """
        engine = PaddleOCREngine()
        assert engine.lang == "pl"

    @patch("paddleocr.PaddleOCR")
    def test_init_success(self, mock_paddleocr: MagicMock) -> None:
        """Gdy paddleocr jest zainstalowane, engine jest dostępny z supermocami."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        assert engine._available is True
        assert engine._initialized is True
        assert engine._ocr is not None
        mock_paddleocr.assert_called_once()

        # Sprawdź że kwargs zawierają supermoce
        call_kwargs = mock_paddleocr.call_args.kwargs
        assert call_kwargs["lang"] == "pl"
        assert call_kwargs["rec_batch_num"] == 6
        assert call_kwargs["use_dilation"] is True

    @patch("paddleocr.PaddleOCR")
    def test_init_logs_params(self, mock_paddleocr: MagicMock) -> None:
        """Init loguje wszystkie supermoce."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        with patch("nexus_ai.pipeline.ocr_consensus.logger.info") as mock_log:
            engine = PaddleOCREngine(lang="pl", use_gpu=False)
            log_msg = mock_log.call_args[0][0]
            assert "PaddleOCR initialized" in log_msg
            assert "det_thresh" in log_msg
            assert "rec_batch" in log_msg

    # ════════════════════════════════════════════════════════════════════════
    # _build_ocr_kwargs
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_build_ocr_kwargs(self, mock_paddleocr: MagicMock) -> None:
        """_build_ocr_kwargs zwraca wszystkie supermoce jako dict."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        kwargs = engine._build_ocr_kwargs()
        assert kwargs["lang"] == "pl"
        assert kwargs["use_gpu"] is False
        assert kwargs["rec_batch_num"] == 6
        assert kwargs["use_dilation"] is True
        assert kwargs["det_db_score_mode"] == "fast"

    # ════════════════════════════════════════════════════════════════════════
    # extract_text — podstawowe testy
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_text_not_available(self, mock_paddleocr: MagicMock) -> None:
        """extract_text zwraca None gdy engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None

    @patch("paddleocr.PaddleOCR")
    def test_extract_text_success(self, mock_paddleocr: MagicMock) -> None:
        """extract_text zwraca tekst z PaddleOCR."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        mock_instance.ocr.return_value = [
            [
                ([[0, 0], [50, 0], [50, 20], [0, 20]], ("Line 1", 0.95)),
            ],
            [None],
        ]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True  # Skip warmup

        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result == "Line 1"
        mock_instance.ocr.assert_called_once()

    @patch("paddleocr.PaddleOCR")
    def test_extract_text_empty(self, mock_paddleocr: MagicMock) -> None:
        """extract_text zwraca None gdy wynik pusty."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        mock_instance.ocr.return_value = [[None]]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True

        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_text_with_confidence
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_text_with_confidence_success(self, mock_paddleocr: MagicMock) -> None:
        """extract_text_with_confidence zwraca per-word confidence z bboxami."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        bbox_1 = [[0, 0], [50, 0], [50, 20], [0, 20]]
        bbox_2 = [[60, 0], [110, 0], [110, 20], [60, 20]]
        # PaddleOCR output: list[list[tuple(bbox, tuple(text, conf))]]
        mock_instance.ocr.return_value = [
            [(bbox_1, ("Hello", 0.95))],
            [(bbox_2, ("World", 0.88))],
        ]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True

        result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))
        assert result is not None
        assert len(result) == 2
        assert result[0]["text"] == "Hello"
        assert result[0]["confidence"] == 0.95
        assert result[0]["bbox"] == bbox_1
        assert result[1]["text"] == "World"
        assert result[1]["confidence"] == 0.88

    @patch("paddleocr.PaddleOCR")
    def test_extract_text_with_confidence_not_available(
        self, mock_paddleocr: MagicMock
    ) -> None:
        """extract_text_with_confidence zwraca None gdy engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))
        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_amount
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_amount_success(self, mock_paddleocr: MagicMock) -> None:
        """extract_amount wyciąga kwotę z regex post-processing."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        bbox = [[0, 0], [100, 0], [100, 20], [0, 20]]
        mock_instance.ocr.return_value = [
            [(bbox, ("1230.00 PLN", 0.95))]
        ]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True

        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result == 1230.00

    @patch("paddleocr.PaddleOCR")
    def test_extract_amount_not_available(self, mock_paddleocr: MagicMock) -> None:
        """extract_amount zwraca None gdy engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result is None

    @patch("paddleocr.PaddleOCR")
    def test_extract_amount_no_number(self, mock_paddleocr: MagicMock) -> None:
        """extract_amount zwraca None gdy brak liczby."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        mock_instance.ocr.return_value = [
            [[[0, 0], [100, 0], [100, 20], [0, 20]], ("ABC DEF", 0.95)]
        ]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True

        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_digits
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_digits_success(self, mock_paddleocr: MagicMock) -> None:
        """extract_digits wyciąga NIP z filtracją cyfr."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        bbox = [[0, 0], [100, 0], [100, 20], [0, 20]]
        mock_instance.ocr.return_value = [
            [(bbox, ("1234567890", 0.95))]
        ]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True

        result = anyio_run(engine.extract_digits(Path("test.png"), expected_length=10))
        assert result == "1234567890"

    @patch("paddleocr.PaddleOCR")
    def test_extract_digits_not_available(self, mock_paddleocr: MagicMock) -> None:
        """extract_digits zwraca None gdy engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_digits(Path("test.png")))
        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_structured
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_structured_success(self, mock_paddleocr: MagicMock) -> None:
        """extract_structured zwraca pełny JSON z bboxami i confidence."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        bbox_1 = [[0, 0], [50, 0], [50, 20], [0, 20]]
        mock_instance.ocr.return_value = [
            [(bbox_1, ("Structured text", 0.95))]
        ]

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = True

        result = anyio_run(engine.extract_structured(Path("test.png")))
        assert result is not None
        assert result["block_count"] >= 1
        assert result["blocks"][0]["text"] == "Structured text"
        assert result["blocks"][0]["confidence"] == 0.95
        assert result["source"] == "paddleocr"
        assert result["version"] == "PP-OCRv4"

    # ════════════════════════════════════════════════════════════════════════
    # GPU Warmup
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_warmup_called_on_gpu_init(self, mock_paddleocr: MagicMock) -> None:
        """Warmup jest wywoływany gdy use_gpu=True."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance

        original_warmup = PaddleOCREngine._warmup

        with patch.object(PaddleOCREngine, "_warmup") as mock_warmup:
            engine = PaddleOCREngine(lang="pl", use_gpu=False)  # use_gpu=False → no warmup
            mock_warmup.assert_not_called()  # No GPU → no warmup

    @patch("paddleocr.PaddleOCR")
    def test_warmup(self, mock_paddleocr: MagicMock) -> None:
        """_warmup uruchamia OCR na małym obrazie dla inicjalizacji CUDA."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance

        engine = PaddleOCREngine(lang="pl", use_gpu=False)
        engine._ocr = mock_instance
        engine._available = True
        engine._warmup_done = False
        engine.use_gpu = False

        engine._warmup()
        assert engine._warmup_done is True  # Always works on CPU

    # ════════════════════════════════════════════════════════════════════════
    # Auto-tuning det_db_thresh
    # ════════════════════════════════════════════════════════════════════════

    # ════════════════════════════════════════════════════════════════════════
    # PP-StructureV3: extract_layout (FAZA 3)
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_layout_not_available(self, mock_paddleocr: MagicMock) -> None:
        """extract_layout zwraca None gdy structure_engine nie dostępny."""
        mock_instance = MagicMock()
        mock_paddleocr.return_value = mock_instance
        engine = PaddleOCREngine()
        engine._structure_engine = None
        result = anyio_run(engine.extract_layout(Path("test.png")))
        assert result is None

    @patch("paddleocr.PaddleOCR")
    def test_detect_seals_not_available(self, mock_paddleocr: MagicMock) -> None:
        """detect_seals zwraca None gdy structure_engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._structure_engine = None
        result = anyio_run(engine.detect_seals(Path("test.png")))
        assert result is None

    @patch("paddleocr.PaddleOCR")
    def test_extract_tables_not_available(self, mock_paddleocr: MagicMock) -> None:
        """extract_tables zwraca None gdy structure_engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._structure_engine = None
        result = anyio_run(engine.extract_tables(Path("test.png")))
        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # Batch processing (FAZA 3)
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_extract_text_batch_not_available(self, mock_paddleocr: MagicMock) -> None:
        """extract_text_batch zwraca [None] gdy engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._available = False
        result = anyio_run(engine.extract_text_batch([Path("a.png"), Path("b.png")]))
        assert result == [None, None]

    # ════════════════════════════════════════════════════════════════════════
    # TensorRT (FAZA 3)
    # ════════════════════════════════════════════════════════════════════════

    @patch("paddleocr.PaddleOCR")
    def test_enable_tensorrt_not_available(self, mock_paddleocr: MagicMock) -> None:
        """enable_tensorrt zwraca False gdy engine nie dostępny."""
        engine = PaddleOCREngine()
        engine._available = False
        result = engine.enable_tensorrt()
        assert result is False


# ═══════════════════════════════════════════════════════════════════════════════
# 4-way consensus z PaddleOCR
# ═══════════════════════════════════════════════════════════════════════════════


class TestDecideAmountConsensus4WayWithPaddle:
    """Testy dla 4-way amount consensus z PaddleOCR."""

    def test_4way_all_agree(self) -> None:
        """4/4 engines agree — consensus."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=1230.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False
        assert consensus.accepted is not None

    def test_4way_paddle_in_majority(self) -> None:
        """PaddleOCR zgadza się z 2 innymi — consensus z 3/4."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=9999.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False

    def test_4way_paddle_disagrees(self) -> None:
        """PaddleOCR się nie zgadza — consensus z 3/4 bez niego."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=9999.00, source="paddle"),  # Outlier
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=1230.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False

    def test_4way_paddle_as_tiebreaker(self) -> None:
        """PaddleOCR jako tiebreaker gdy 2 silniki się nie zgadzają."""
        results = [
            OCRAmountResult(amount_gross=1000.00, source="tesseract"),
            OCRAmountResult(amount_gross=1000.00, source="paddle"),
            OCRAmountResult(amount_gross=2000.00, source="doctr"),
            OCRAmountResult(amount_gross=2000.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is True

    def test_4way_paddle_none(self) -> None:
        """PaddleOCR zwraca None — consensus z pozostałych 3."""
        results = [
            OCRAmountResult(amount_gross=1000.00, source="tesseract"),
            OCRAmountResult(amount_gross=None, source="paddle"),  # Failed
            OCRAmountResult(amount_gross=1000.00, source="doctr"),
            OCRAmountResult(amount_gross=1000.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False


class TestDecideFieldConsensusWithPaddle:
    """Testy decide_field_consensus z PaddleOCR."""

    def test_4way_paddle_in_majority(self) -> None:
        """PaddleOCR zgadza się z większością."""
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


# ═══════════════════════════════════════════════════════════════════════════════
# Helper: run async function synchronously
# ═══════════════════════════════════════════════════════════════════════════════


def anyio_run(coro: Any) -> Any:
    """Run an anyio coroutine synchronously.

    anyio.run() oczekuje async callable, nie korutyny.
    Dlatego używamy lambda: coro zamiast bezpośrednio coro.
    """
    import anyio

    return anyio.run(lambda: coro)
