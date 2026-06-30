"""
Tests for TesseractEngine — Tesseract OCR engine with full superpowers.

Testuje:
  - TesseractEngine initialisation (mock, bez prawdziwego tesseracta)
  - TesseractEngine.extract_text (mock)
  - TesseractEngine.extract_text_with_confidence (mock przez TSV)
  - TesseractEngine.extract_amount (mock z whitelist)
  - TesseractEngine.extract_digits (mock z whitelist)
  - Supremo: PSM, OEM, whitelist, config params
  - Validacja PSM/OEM
  - 4-way consensus (Tesseract + PaddleOCR + docTR + EasyOCR)
"""

from __future__ import annotations

from pathlib import Path
from typing import Any
from unittest.mock import ANY, MagicMock, patch

import pytest

from nexus_ai.pipeline.ocr_consensus import (
    OCRAmountResult,
    OCRConsensusDecision,
    TesseractEngine,
    OCREngine,
    decide_amount_consensus,
)


# ═══════════════════════════════════════════════════════════════════════════════
# TesseractEngine — podstawowe testy
# ═══════════════════════════════════════════════════════════════════════════════


class TestTesseractEngine:
    """Testy jednostkowe dla TesseractEngine z supermocami."""

    def test_enum_value(self) -> None:
        """OCREngine.TESSERACT ma poprawną wartość."""
        assert OCREngine.TESSERACT.value == "tesseract"

    def test_init_default_params(self) -> None:
        """TesseractEngine init z domyślnymi parametrami supermoc."""
        engine = TesseractEngine()
        assert engine.lang == "pol"
        assert engine.psm == 4
        assert engine.oem == 1
        assert engine.dpi is None
        assert engine.tessdata_dir is None
        assert engine.user_words_path is None
        assert engine.user_patterns_path is None
        assert engine.char_whitelist is None
        assert engine.char_blacklist is None
        assert engine.preserve_interword_spaces is False
        # Tesseract nie jest zainstalowany w testach
        assert engine._available is False

    def test_init_custom_params(self) -> None:
        """TesseractEngine init z własnymi parametrami (wszystkie supermoce)."""
        engine = TesseractEngine(
            lang="eng",
            psm=6,
            oem=0,
            dpi=300,
            tessdata_dir="/custom/tessdata",
            user_words_path="/custom/words",
            user_patterns_path="/custom/patterns",
            char_whitelist="0123456789",
            char_blacklist="O0l1",
            preserve_interword_spaces=True,
        )
        assert engine.lang == "eng"
        assert engine.psm == 6
        assert engine.oem == 0
        assert engine.dpi == 300
        assert engine.tessdata_dir == "/custom/tessdata"
        assert engine.user_words_path == "/custom/words"
        assert engine.user_patterns_path == "/custom/patterns"
        assert engine.char_whitelist == "0123456789"
        assert engine.char_blacklist == "O0l1"
        assert engine.preserve_interword_spaces is True

    def test_init_invalid_psm(self) -> None:
        """Nieprawidłowy PSM rzuca ValueError."""
        with pytest.raises(ValueError, match="Invalid PSM 99"):
            TesseractEngine(psm=99)

    def test_init_invalid_oem(self) -> None:
        """Nieprawidłowy OEM rzuca ValueError."""
        with pytest.raises(ValueError, match="Invalid OEM 99"):
            TesseractEngine(oem=99)

    @patch("shutil.which")
    def test_check_available_true(self, mock_which: MagicMock) -> None:
        """Gdy tesseract jest w PATH, _available jest True."""
        mock_which.return_value = "/usr/bin/tesseract"
        engine = TesseractEngine()
        assert engine._available is True

    @patch("shutil.which")
    def test_check_available_false(self, mock_which: MagicMock) -> None:
        """Gdy tesseract nie jest w PATH, _available jest False."""
        mock_which.return_value = None
        engine = TesseractEngine()
        assert engine._available is False

    # ════════════════════════════════════════════════════════════════════════
    # extract_text — podstawowe testy
    # ════════════════════════════════════════════════════════════════════════

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_success(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text zwraca tekst z Tesseract."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "Line 1\nLine 2\nLine 3\n"
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_text(Path("test.png")))

        assert result == "Line 1\nLine 2\nLine 3"
        # Sprawdź że args zawierają supermoce
        call_args = mock_run.call_args[0][0]
        assert "--psm" in call_args
        assert "--oem" in call_args
        assert "4" in call_args  # PSM
        assert "1" in call_args  # OEM

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_not_available(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text zwraca None gdy engine nie dostępny."""
        mock_which.return_value = None
        engine = TesseractEngine()
        result = anyio_run(engine.extract_text(Path("test.png")))
        assert result is None
        mock_run.assert_not_called()

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_empty(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text zwraca None gdy wynik pusty."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = ""
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_text(Path("test.png")))

        assert result is None

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_failure(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text zwraca None gdy returncode != 0."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 1
        mock_result.stdout = ""
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_text(Path("test.png")))

        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_amount — whitelist dla kwot
    # ════════════════════════════════════════════════════════════════════════

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_amount_success(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_amount wyciąga kwotę z whitelist cyfr."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "1230.00\n"
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_amount(Path("test.png")))

        assert result == 1230.00
        # Sprawdź że whitelist i PSM 6 są przekazane
        call_args = mock_run.call_args[0][0]
        assert "tessedit_char_whitelist=0123456789.,-" in call_args
        assert "--psm" in call_args
        assert "6" in call_args  # PSM 6 dla bloku kwoty

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_amount_not_available(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_amount zwraca None gdy engine nie dostępny."""
        mock_which.return_value = None
        engine = TesseractEngine()
        result = anyio_run(engine.extract_amount(Path("test.png")))
        assert result is None

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_amount_no_number(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_amount zwraca None gdy brak liczby w wyniku."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "ABC DEF\n"
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_amount(Path("test.png")))

        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_digits — whitelist dla NIP/IBAN
    # ════════════════════════════════════════════════════════════════════════

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_digits_success(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_digits wyciąga NIP z whitelist cyfr."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "1234567890\n"
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_digits(Path("test.png"), expected_length=10))

        assert result == "1234567890"
        call_args = mock_run.call_args[0][0]
        assert "tessedit_char_whitelist=0123456789" in call_args
        assert "--psm" in call_args
        assert "7" in call_args  # PSM 7 dla pojedynczej linii

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_digits_not_available(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_digits zwraca None gdy engine nie dostępny."""
        mock_which.return_value = None
        engine = TesseractEngine()
        result = anyio_run(engine.extract_digits(Path("test.png")))
        assert result is None

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_digits_no_digits(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_digits zwraca None gdy brak cyfr."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "ABC DEF\n"
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_digits(Path("test.png")))

        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # extract_text_with_confidence — TSV confidence parsing
    # ════════════════════════════════════════════════════════════════════════

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_with_confidence_success(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text_with_confidence parsuje TSV z Tesseract."""
        mock_which.return_value = "/usr/bin/tesseract"

        tsv_output = (
            "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n"
            "1\t1\t0\t0\t0\t0\t0\t0\t100\t100\t-1\t\n"
            "2\t1\t1\t0\t0\t0\t10\t10\t80\t20\t-1\t\n"
            "3\t1\t1\t1\t0\t0\t10\t10\t80\t20\t-1\t\n"
            "4\t1\t1\t1\t1\t0\t10\t10\t80\t20\t-1\t\n"
            "5\t1\t1\t1\t1\t1\t10\t10\t40\t20\t92\tHello\n"
            "5\t1\t1\t1\t1\t2\t50\t10\t40\t20\t88\tWorld\n"
        )
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = tsv_output
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))

        assert result is not None
        assert len(result) == 2
        assert result[0]["text"] == "Hello"
        assert result[0]["confidence"] == 0.92
        assert result[0]["bbox"] == [10, 10, 50, 30]
        assert result[1]["text"] == "World"
        assert result[1]["confidence"] == 0.88
        assert result[1]["bbox"] == [50, 10, 90, 30]

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_with_confidence_not_available(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text_with_confidence zwraca None gdy engine nie dostępny."""
        mock_which.return_value = None
        engine = TesseractEngine()
        result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))
        assert result is None

    @patch("shutil.which")
    @patch("anyio.run_process")
    def test_extract_text_with_confidence_empty_tsv(
        self, mock_run: MagicMock, mock_which: MagicMock
    ) -> None:
        """extract_text_with_confidence zwraca None gdy TSV tylko z nagłówkiem."""
        mock_which.return_value = "/usr/bin/tesseract"

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n"
        mock_run.return_value = mock_result

        engine = TesseractEngine()
        engine._available = True

        with patch("builtins.open", new_callable=MagicMock) as mock_file:
            mock_file.return_value.__enter__.return_value.read.return_value = b"fake_image"
            result = anyio_run(engine.extract_text_with_confidence(Path("test.png")))

        assert result is None

    # ════════════════════════════════════════════════════════════════════════
    # 4-way consensus z Tesseract
    # ════════════════════════════════════════════════════════════════════════

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

    def test_4way_tesseract_disagrees(self) -> None:
        """Tesseract się nie zgadza — consensus z 3/4 bez niego."""
        results = [
            OCRAmountResult(amount_gross=9999.00, source="tesseract"),  # Outlier
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=1230.00, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3)
        assert consensus.confidence_conflict is False
        assert consensus.accepted is not None


# ═══════════════════════════════════════════════════════════════════════════════
# Helper: run async function synchronously
# ═══════════════════════════════════════════════════════════════════════════════


def anyio_run(coro: Any) -> Any:
    """Run an anyio coroutine synchronously."""
    import anyio

    return anyio.run(coro)
