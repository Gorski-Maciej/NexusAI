"""Tests for nexus_ai/core/image_utils.py -- Pillow superpowers.

Testuje:
- normalize_image_to_jpeg(): EXIF transpose, progressive, optimize
- safe_open_image(): bezpieczne otwieranie, LOAD_TRUNCATED_IMAGES
- assess_image_quality(): ImageStat + ImageFilter dla oceny jakosci
- preprocess_for_ocr(): pipeline preprocessingu dla OCR
- stream_load_image(): ImageFile.Parser

UWAGA: PIL jest zmockowane globalnie w conftest.py (sys.modules['PIL'] = MagicMock).
Testy z HAS_PIL=True nie moga testowac rzeczywistej logiki PIL -- weryfikuja tylko
ze funkcje nie rzucaja wyjatkami. Testy HAS_PIL=False testuja poprawnie.
"""

from __future__ import annotations

import struct
import zlib
from unittest.mock import MagicMock, patch

from nexus_ai.core.image_utils import (
    safe_open_image,
    normalize_image_to_jpeg,
    assess_image_quality_from_bytes,
    stream_load_image,
    preprocess_pil_or_none,
)


# ---- Helper: minimalne PNG w surowych bajtach ------------------------------


def _create_minimal_png(width: int = 50, height: int = 50) -> bytes:
    """Create a minimal valid PNG without PIL (works with mocked PIL)."""
    def _make_chunk(chunk_type: bytes, data: bytes) -> bytes:
        chunk = chunk_type + data
        crc = struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)
        return struct.pack(">I", len(data)) + chunk + crc

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    raw_data = b""
    for _ in range(height):
        raw_data += b"\x00"  # Filter byte (None)
        for _ in range(width):
            raw_data += bytes([255, 0, 0])  # Red pixel
    compressed = zlib.compress(raw_data)

    return (
        signature
        + _make_chunk(b"IHDR", ihdr_data)
        + _make_chunk(b"IDAT", compressed)
        + _make_chunk(b"IEND", b"")
    )


# ---- normalize_image_to_jpeg -----------------------------------------------


class TestNormalizeImageToJPEG:
    """Testy dla normalize_image_to_jpeg."""

    def test_return_bytes_when_no_pil(self) -> None:
        """Bez PIL zwraca oryginalny content."""
        original = b"fake_image_data"
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = normalize_image_to_jpeg(original)
        assert result == original

    def test_return_original_when_no_pil_with_params(self) -> None:
        """Bez PIL zwraca oryginalny content mimo parametrow."""
        original = b"test_data"
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = normalize_image_to_jpeg(
                original, max_size=(100, 100), quality=50, apply_autocontrast=True
            )
        assert result == original

    def test_empty_bytes_no_pil(self) -> None:
        """Puste dane bez PIL -- zwraca puste."""
        result = normalize_image_to_jpeg(b"")
        assert result == b""

    @patch("nexus_ai.core.image_utils.HAS_PIL", True)
    def test_basic_conversion_with_mocked_pil(self) -> None:
        """Z PIL zmockowanym, normalize_image_to_jpeg nie rzuca wyjatku.
        Uwaga: PIL jest zmockowane w conftest.py, wiec Image.open() zwraca MagicMock.
        Test weryfikuje tylko ze funkcja nie crashuje.
        """
        png_bytes = _create_minimal_png(50, 50)
        result = normalize_image_to_jpeg(png_bytes)
        # Z mockiem PIL, buf.getvalue() zwraca b"" (save jest na MagicMock)
        assert isinstance(result, bytes)

    @patch("nexus_ai.core.image_utils.HAS_PIL", True)
    def test_autocontrast_flag_no_crash(self) -> None:
        """Flaga apply_autocontrast=True nie powoduje bledu z mockiem PIL."""
        png_bytes = _create_minimal_png(10, 10)
        result = normalize_image_to_jpeg(png_bytes, apply_autocontrast=True)
        assert isinstance(result, bytes)

    @patch("nexus_ai.core.image_utils.HAS_PIL", True)
    def test_icc_profile_no_crash(self) -> None:
        """ICC profile nie powoduje bledu z mockiem PIL."""
        png_bytes = _create_minimal_png(10, 10)
        result = normalize_image_to_jpeg(png_bytes, icc_profile=b"fake_icc")
        assert isinstance(result, bytes)

    @patch("nexus_ai.core.image_utils.HAS_PIL", True)
    def test_no_max_size_no_crash(self) -> None:
        """max_size=None nie powoduje bledu."""
        png_bytes = _create_minimal_png(50, 50)
        result = normalize_image_to_jpeg(png_bytes, max_size=None)
        assert isinstance(result, bytes)

    def test_integration_imports(self) -> None:
        """Sprawdza ze modul importuje sie poprawnie."""
        from nexus_ai.core.image_utils import (
            HAS_PIL as hp,
            safe_open_image as soi,
            normalize_image_to_jpeg as nitj,
            assess_image_quality as aiq,
            assess_image_quality_from_bytes as aiqfb,
            stream_load_image as sli,
            preprocess_for_ocr as pfo,
            preprocess_pil_or_none as ppon,
        )
        assert hp is not None
        assert callable(soi)
        assert callable(nitj)
        assert callable(aiq)
        assert callable(aiqfb)
        assert callable(sli)
        assert callable(pfo)
        assert callable(ppon)


# ---- safe_open_image -------------------------------------------------------


class TestSafeOpenImage:
    """Testy dla safe_open_image z obsluga bledow."""

    def test_open_invalid_data_no_pil(self) -> None:
        """Bez PIL, nieprawidlowe dane -> None."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = safe_open_image(b"not_an_image_at_all")
        assert result is None

    def test_open_empty_data_no_pil(self) -> None:
        """Bez PIL, puste dane -> None."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = safe_open_image(b"")
        assert result is None

    def test_open_valid_no_pil(self) -> None:
        """Bez PIL, poprawne dane -> None (bo PIL nie dziala)."""
        png_bytes = _create_minimal_png(50, 50)
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = safe_open_image(png_bytes)
        assert result is None

    @patch("nexus_ai.core.image_utils.HAS_PIL", True)
    def test_open_with_mocked_pil(self) -> None:
        """Z PIL zmockowanym, safe_open_image nie crashuje.
        Poniewaz PIL.Image.open() zwraca MagicMock, verify() nie rzuca wyjatku,
        wiec funkcja zwraca MagicMock zamiast None.
        """
        result = safe_open_image(b"some_bytes")
        # Z mockiem PIL, Image.open().verify() nie rzuca wyjatku, wiec zwraca MagicMock
        assert result is not None or isinstance(result, MagicMock)


# ---- assess_image_quality --------------------------------------------------


class TestAssessImageQuality:
    """Testy dla assess_image_quality."""

    def test_from_bytes_invalid_no_pil(self) -> None:
        """Bez PIL, nieprawidlowe bajty -> error + is_blank=True."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = assess_image_quality_from_bytes(b"bad_data")
        assert "error" in result
        assert result["is_blank"] is True

    def test_from_bytes_empty_no_pil(self) -> None:
        """Bez PIL, puste bajty -> error."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = assess_image_quality_from_bytes(b"")
        assert "error" in result

    def test_not_installed_message(self) -> None:
        """Komunikat 'Pillow not installed' gdy brak PIL."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = assess_image_quality_from_bytes(b"data")
        assert result["error"] == "Pillow not installed"

    def test_from_bytes_valid_no_pil(self) -> None:
        """Bez PIL, poprawne bajty -> error (bo PIL nie dziala)."""
        png_bytes = _create_minimal_png(50, 50)
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = assess_image_quality_from_bytes(png_bytes)
        assert "error" in result
        assert result["is_blank"] is True

    def test_return_dict_structure(self) -> None:
        """Nawet z mockiem PIL, slownik ma oczekiwana strukture."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = assess_image_quality_from_bytes(b"x")
        assert isinstance(result, dict)
        assert "error" in result


# ---- preprocess_for_ocr ----------------------------------------------------


class TestPreprocessForOCR:
    """Testy dla preprocess_for_ocr."""

    def test_preprocess_pil_or_none_none(self) -> None:
        """None input -> None output."""
        result = preprocess_pil_or_none(None)
        assert result is None

    def test_preprocess_pil_or_none_callable(self) -> None:
        """Sprawdzamy ze preprocess_pil_or_none jest wywolywalne."""
        assert callable(preprocess_pil_or_none)


# ---- stream_load_image -----------------------------------------------------


class TestStreamLoadImage:
    """Testy dla stream_load_image."""

    def test_stream_load_invalid_no_pil(self) -> None:
        """Bez PIL, nieprawidlowe dane -> None."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = stream_load_image(b"invalid")
        assert result is None

    def test_stream_load_empty_no_pil(self) -> None:
        """Bez PIL, puste dane -> None."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = stream_load_image(b"")
        assert result is None

    def test_stream_load_valid_no_pil(self) -> None:
        """Bez PIL, poprawne dane -> None (bo PIL nie dziala)."""
        png_bytes = _create_minimal_png(10, 10)
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            result = stream_load_image(png_bytes)
        assert result is None

    def test_stream_load_chunk_size_no_pil(self) -> None:
        """Rozne chunk_size nie zmieniaja wyniku z HAS_PIL=False."""
        with patch("nexus_ai.core.image_utils.HAS_PIL", False):
            r1 = stream_load_image(b"data", chunk_size=1)
            r2 = stream_load_image(b"data", chunk_size=65536)
        assert r1 is None
        assert r2 is None
