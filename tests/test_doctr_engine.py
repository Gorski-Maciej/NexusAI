"""
Tests for DocTREngine — docTR OCR engine integration in 4-way OCR consensus pipeline.

Testuje:
  - DocTREngine initialisation (mock, bez prawdziwego modelu)
  - DocTREngine.extract_text (mock)
  - DocTREngine.extract_tables (mock)
  - DocTREngine.extract_structured (mock)
  - 4-way consensus (Tesseract + PaddleOCR + docTR + EasyOCR)
  - OCREngine.DOCTR enum value
"""

from __future__ import annotations

from pathlib import Path
from typing import Any
from unittest.mock import MagicMock, patch

import pytest

from nexus_ai.pipeline.ocr_consensus import (
    OCRAmountResult,
    OCRConsensusDecision,
    DocTREngine,
    OCREngine,
    decide_amount_consensus,
    decide_field_consensus,
)


# ═══════════════════════════════════════════════════════════════════════════════
# DocTREngine — podstawowe testy
# ═══════════════════════════════════════════════════════════════════════════════


class TestDocTREngine:
    """Testy jednostkowe dla DocTREngine."""

    def test_enum_value(self) -> None:
        """OCREngine.DOCTR ma poprawną wartość."""
        assert OCREngine.DOCTR.value == "doctr"

    def test_init_default_params(self) -> None:
        """DocTREngine init z domyślnymi parametrami."""
        engine = DocTREngine()
        assert engine.det_arch == "db_resnet50"
        assert engine.reco_arch == "parseq"
        assert engine.detect_orientation is True
        assert engine._predictor is None  # Not initialized (no doctr installed)
        assert engine._available is False

    def test_init_custom_params(self) -> None:
        """DocTREngine init z własnymi parametrami."""
        engine = DocTREngine(
            det_arch="db_mobilenet_v3",
            reco_arch="crnn_vgg16_bn",
            detect_orientation=False,
            use_gpu=False,
        )
        assert engine.det_arch == "db_mobilenet_v3"
        assert engine.reco_arch == "crnn_vgg16_bn"
        assert engine.detect_orientation is False
        assert engine.use_gpu is False

    def test_init_fallback_when_import_fails(self) -> None:
        """Gdy doctr nie jest zainstalowane, engine nie jest dostępny."""
        engine = DocTREngine()
        assert engine._available is False
        assert engine._predictor is None
        assert engine._table_predictor is None

    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_init_success(
        self, mock_table_predictor: MagicMock, mock_ocr_predictor: MagicMock
    ) -> None:
        """Gdy doctr jest zainstalowane, engine jest dostępny z oboma predictorami."""
        mock_ocr = MagicMock()
        mock_table = MagicMock()
        mock_ocr_predictor.return_value = mock_ocr
        mock_table_predictor.return_value = mock_table

        engine = DocTREngine(detect_orientation=True)
        assert engine._available is True
        assert engine._predictor is not None
        assert engine._table_predictor is not None

        mock_ocr_predictor.assert_called_once_with(
            det_arch="db_resnet50",
            reco_arch="parseq",
            pretrained=True,
            detect_orientation=True,
        )
        mock_table_predictor.assert_called_once_with(
            arch="td_resnet50",
            pretrained=True,
        )

    @patch("doctr.models.ocr_predictor")
    def test_extract_text_not_available(self, mock_predictor: MagicMock) -> None:
        """Gdy engine nie jest dostępny, extract_text zwraca None."""
        engine = DocTREngine()
        engine._available = False
        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None

    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_text_success(
        self, mock_table_predictor: MagicMock, mock_ocr_predictor: MagicMock
    ) -> None:
        """extract_text zwraca sformatowany tekst z docTR."""
        mock_instance = MagicMock()
        mock_instance.return_value.render.return_value = "Line 1\nLine 2\nLine 3"
        mock_ocr_predictor.return_value = mock_instance
        mock_table_predictor.return_value = MagicMock()

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        from doctr.io import DocumentFile
        with patch("doctr.io.DocumentFile.from_images") as mock_doc:
            mock_doc.return_value = ["page1"]
            result = anyio_run(engine.extract_text(Path("test.png")))

        assert result == "Line 1\nLine 2\nLine 3"
        mock_instance.assert_called_once()

    @patch("doctr.models.ocr_predictor")
    def test_extract_text_empty(self, mock_predictor: MagicMock) -> None:
        """extract_text zwraca None gdy wynik pusty."""
        mock_instance = MagicMock()
        mock_instance.return_value.render.return_value = ""
        mock_predictor.return_value = mock_instance

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        with patch("doctr.io.DocumentFile.from_images") as mock_doc:
            mock_doc.return_value = ["page1"]
            result = anyio_run(engine.extract_text(Path("test.png")))

        assert result is None

    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_tables_success(
        self, mock_table_predictor: MagicMock, mock_ocr_predictor: MagicMock
    ) -> None:
        """extract_tables zwraca listę tabel z JSON."""
        mock_ocr = MagicMock()
        mock_table = MagicMock()
        mock_ocr_predictor.return_value = mock_ocr
        mock_table_predictor.return_value = mock_table

        mock_table.return_value.export.return_value = {
            "pages": [{"tables": [{"headers": ["Name", "Price"], "rows": [["Item1", "100"]]}]}]
        }

        engine = DocTREngine()
        engine._table_predictor = mock_table
        engine._available = True

        with patch("doctr.io.DocumentFile.from_images") as mock_doc:
            mock_doc.return_value = ["page1"]
            result = anyio_run(engine.extract_tables(Path("test.png")))

        assert result is not None
        assert len(result) == 1
        assert result[0]["headers"] == ["Name", "Price"]

    @patch("doctr.models.ocr_predictor")
    def test_extract_tables_not_available(self, mock_predictor: MagicMock) -> None:
        """extract_tables zwraca None gdy table_predictor nie jest dostępny."""
        engine = DocTREngine()
        engine._table_predictor = None
        result = anyio_run(engine.extract_tables(Path("test.png")))
        assert result is None

    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_structured_success(
        self, mock_table_predictor: MagicMock, mock_ocr_predictor: MagicMock
    ) -> None:
        """extract_structured zwraca pełny export JSON z docTR."""
        mock_instance = MagicMock()
        expected_export = {
            "pages": [{"page_idx": 0, "blocks": [{"type": "text", "words": []}]}]
        }
        mock_instance.return_value.export.return_value = expected_export
        mock_ocr_predictor.return_value = mock_instance
        mock_table_predictor.return_value = MagicMock()

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        with patch("doctr.io.DocumentFile.from_images") as mock_doc:
            mock_doc.return_value = ["page1"]
            result = anyio_run(engine.extract_structured(Path("test.png")))

        assert result == expected_export

    @patch("doctr.models.ocr_predictor")
    def test_extract_structured_not_available(self, mock_predictor: MagicMock) -> None:
        """extract_structured zwraca status unavailable gdy engine nie dostępny."""
        engine = DocTREngine()
        engine._available = False
        result = anyio_run(engine.extract_structured(Path("test.png")))
        assert result == {"status": "unavailable"}

    # ════════════════════════════════════════════════════════════════════════
    # SUPERMOCE v2: nowe metody z audytu technologicznego
    # ════════════════════════════════════════════════════════════════════════

    def test_init_with_superpowers(self) -> None:
        """DocTREngine init z nowymi supermocami (assume_straight_pages, det_bs, etc)."""
        engine = DocTREngine(
            assume_straight_pages=True,
            straighten_pages=True,
            det_bs=4,
            reco_bs=8,
            box_thresh=0.3,
            bin_thresh=0.2,
            use_onnx=False,
        )
        assert engine.assume_straight_pages is True
        assert engine.straighten_pages is True
        assert engine.det_bs == 4
        assert engine.reco_bs == 8
        assert engine.box_thresh == 0.3
        assert engine.bin_thresh == 0.2
        assert engine.use_onnx is False
        assert engine._kie_predictor is None  # No doctr installed

    @patch("doctr.io.DocumentFile.from_pdf")
    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_text_from_pdf(
        self, mock_table: MagicMock, mock_ocr: MagicMock, mock_from_pdf: MagicMock
    ) -> None:
        """extract_text_from_pdf używa DocumentFile.from_pdf()."""
        mock_instance = MagicMock()
        mock_instance.return_value.render.return_value = "PDF Text Content"
        mock_ocr.return_value = mock_instance
        mock_table.return_value = MagicMock()
        mock_from_pdf.return_value = ["page1", "page2"]

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_text_from_pdf(Path("test.pdf")))
        assert result == "PDF Text Content"
        mock_from_pdf.assert_called_once_with("test.pdf")

    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_key_fields_not_available(
        self, mock_table: MagicMock, mock_ocr: MagicMock
    ) -> None:
        """extract_key_fields zwraca None gdy kie_predictor nie dostępny."""
        engine = DocTREngine()
        engine._kie_predictor = None
        result = anyio_run(engine.extract_key_fields(Path("test.png")))
        assert result is None

    @patch("doctr.io.DocumentFile.from_images")
    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_text_with_confidence_doctr(
        self, mock_table: MagicMock, mock_ocr: MagicMock, mock_from_images: MagicMock
    ) -> None:
        """extract_text_with_confidence wyciąga per-word confidence z export()."""
        mock_instance = MagicMock()
        mock_instance.return_value.export.return_value = {
            "pages": [{
                "blocks": [{
                    "type": "text",
                    "lines": [{
                        "words": [
                            {"value": "Hello", "confidence": 0.95, "geometry": [[0,0],[1,1]]},
                            {"value": "World", "confidence": 0.88, "geometry": [[1,0],[2,1]]},
                        ]
                    }]
                }]
            }]
        }
        mock_ocr.return_value = mock_instance
        mock_table.return_value = MagicMock()
        mock_from_images.return_value = ["page1"]

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))
        assert result is not None
        assert len(result) == 2
        assert result[0]["text"] == "Hello"
        assert result[0]["confidence"] == 0.95
        assert result[1]["text"] == "World"
        assert result[1]["confidence"] == 0.88
        assert result[0]["block_type"] == "text"

    # ════════════════════════════════════════════════════════════════════════
    # SUPERMOCE v3: Layout analysis (Faza 3 audytu)
    # ════════════════════════════════════════════════════════════════════════

    @patch("doctr.io.DocumentFile.from_images")
    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_layout(
        self, mock_table: MagicMock, mock_ocr: MagicMock, mock_from_images: MagicMock
    ) -> None:
        """extract_layout zwraca bloki layoutu posortowane według reading_order."""
        mock_instance = MagicMock()
        mock_instance.return_value.export.return_value = {
            "pages": [{
                "blocks": [
                    {
                        "type": "title",
                        "geometry": [[0.1, 0.0], [0.9, 0.1]],
                        "reading_order": 1,
                        "lines": [{"words": []}],
                        "confidence": 0.95,
                    },
                    {
                        "type": "table",
                        "geometry": [[0.0, 0.3], [1.0, 0.7]],
                        "reading_order": 2,
                        "lines": [{"words": []}, {"words": []}],
                        "confidence": 0.88,
                    },
                    {
                        "type": "text",
                        "geometry": [[0.0, 0.1], [1.0, 0.2]],
                        "reading_order": 0,
                        "lines": [{"words": []}],
                        "confidence": 0.92,
                    },
                ]
            }]
        }
        mock_ocr.return_value = mock_instance
        mock_table.return_value = MagicMock()
        mock_from_images.return_value = ["page1"]

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_layout(Path("test.png")))
        assert result is not None
        assert len(result) == 3
        # Sprawdź sortowanie po reading_order
        assert result[0]["type"] == "text"  # reading_order=0
        assert result[1]["type"] == "title"  # reading_order=1
        assert result[2]["type"] == "table"  # reading_order=2
        # Sprawdź strukturę bloku
        assert "geometry" in result[0]
        assert result[0]["confidence"] == 0.92
        assert result[1]["lines"] == 1
        assert result[2]["lines"] == 2

    @patch("doctr.models.ocr_predictor")
    def test_extract_layout_not_available(self, mock_predictor: MagicMock) -> None:
        """extract_layout zwraca None gdy engine nie dostępny."""
        engine = DocTREngine()
        engine._available = False
        result = anyio_run(engine.extract_layout(Path("test.png")))
        assert result is None

    @patch("doctr.io.DocumentFile.from_images")
    @patch("doctr.models.ocr_predictor")
    @patch("doctr.models.table_predictor")
    def test_extract_layout_empty_blocks(
        self, mock_table: MagicMock, mock_ocr: MagicMock, mock_from_images: MagicMock
    ) -> None:
        """extract_layout zwraca None gdy brak bloków w dokumencie."""
        mock_instance = MagicMock()
        mock_instance.return_value.export.return_value = {
            "pages": [{"blocks": []}]
        }
        mock_ocr.return_value = mock_instance
        mock_table.return_value = MagicMock()
        mock_from_images.return_value = ["page1"]

        engine = DocTREngine()
        engine._predictor = mock_instance
        engine._available = True

        result = anyio_run(engine.extract_layout(Path("test.png")))
        assert result is None


# ═══════════════════════════════════════════════════════════════════════════════
# 4-way consensus z docTR (zastępuje Surya)
# ═══════════════════════════════════════════════════════════════════════════════


class TestDecideAmountConsensus4WayWithDocTR:
    """Testy dla 4-way amount consensus z docTR (Tesseract + PaddleOCR + docTR + EasyOCR)."""

    def test_4way_all_agree(self) -> None:
        """4/4 engines agree (w tym docTR) — consensus."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=1230.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False
        assert consensus.accepted is not None

    def test_4way_doctr_in_majority(self) -> None:
        """docTR zgadza się z 2 innymi — consensus z 3/4."""
        results = [
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=9999.00, source="easyocr"),  # Outlier
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False

    def test_4way_doctr_as_tiebreaker(self) -> None:
        """docTR jako tiebreaker gdy 2 silniki się nie zgadzają."""
        results = [
            OCRAmountResult(amount_gross=1000.00, source="tesseract"),
            OCRAmountResult(amount_gross=1000.00, source="paddle"),
            OCRAmountResult(amount_gross=2000.00, source="doctr"),  # docTR z tesseract+paddle
            OCRAmountResult(amount_gross=2000.00, source="easyocr"),
        ]
        # 2+2 split — threshold 3 → no consensus
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is True


# ═══════════════════════════════════════════════════════════════════════════════
# Helper: run async function synchronously
# ═══════════════════════════════════════════════════════════════════════════════


def anyio_run(coro: Any) -> Any:
    """Run an anyio coroutine synchronously."""
    import anyio

    return anyio.run(coro)
