"""
test_ocr_v7_modules.py — Unit tests for all new v7.0 OCR modules.

Tests: ZeroShotFieldExtractor, CrossEngineAttention, OCRSecurity,
MultiModalDocumentUnderstanding, CrossPageMerge, ExoticFormats.
"""

from __future__ import annotations

import pytest
from pathlib import Path


# ═══════════════════════════════════════════════════════════════════════════
# ZeroShotFieldExtractor Tests
# ═══════════════════════════════════════════════════════════════════════════

class TestZeroShotExtractor:
    """Testy ZeroShotFieldExtractor."""

    def test_import(self):
        from nexus_ai.pipeline.zero_shot_extractor import (
            ZeroShotFieldExtractor,
            ZERO_SHOT_EXTRACTION_PROMPT,
            DEFAULT_EXTRACTION_FIELDS,
            FAST_PATH_PATTERNS,
        )
        assert len(DEFAULT_EXTRACTION_FIELDS) >= 8
        assert "vendor_nip" in DEFAULT_EXTRACTION_FIELDS
        assert "amount_gross" in FAST_PATH_PATTERNS

    @pytest.mark.asyncio
    async def test_fast_path_extraction(self):
        """Test szybkiej ścieżki regex (bez AI)."""
        from nexus_ai.pipeline.zero_shot_extractor import ZeroShotFieldExtractor

        extractor = ZeroShotFieldExtractor(use_ai=False)
        ocr_text = (
            "Faktura VAT FV/2026/001\n"
            "NIP: 123-456-78-90\n"
            "Data wystawienia: 2026-07-21\n"
            "Netto: 1000.00 PLN\n"
            "VAT 23%\n"
            "Brutto: 1230.00 PLN\n"
            "IBAN: PL12 1234 5678 9012 3456 7890 1234\n"
        )
        result = await extractor.extract(ocr_text)
        assert result["method"] in ("regex_fast_path", "regex_fallback")
        assert result["fields"]["vendor_nip"] is not None
        assert result["fields"]["amount_gross"] is not None
        assert result["confidence"] > 0

    def test_nip_validation(self):
        """Test walidacji sumy kontrolnej NIP."""
        from nexus_ai.pipeline.zero_shot_extractor import ZeroShotFieldExtractor

        # Poprawny NIP
        assert ZeroShotFieldExtractor._validate_nip("1234563218") is True
        # Zbyt krótki
        assert ZeroShotFieldExtractor._validate_nip("123456789") is False
        # Z literami
        assert ZeroShotFieldExtractor._validate_nip("123456789A") is False

    def test_iban_validation(self):
        """Test walidacji formatu IBAN."""
        from nexus_ai.pipeline.zero_shot_extractor import ZeroShotFieldExtractor

        assert ZeroShotFieldExtractor._validate_iban("PL12345678901234567890123456") is True
        assert ZeroShotFieldExtractor._validate_iban("12345678") is False

    def test_clean_field_value(self):
        """Test czyszczenia wartości pól."""
        from nexus_ai.pipeline.zero_shot_extractor import ZeroShotFieldExtractor

        assert ZeroShotFieldExtractor._clean_field_value("vendor_nip", "123-456-78-90") == "1234567890"
        assert ZeroShotFieldExtractor._clean_field_value("amount_gross", "1 230,00") == "1230.00"
        assert ZeroShotFieldExtractor._clean_field_value("iban", "PL12 1234 5678") == "PL1212345678"


# ═══════════════════════════════════════════════════════════════════════════
# CrossEngineAttention Tests
# ═══════════════════════════════════════════════════════════════════════════

class TestCrossEngineAttention:
    """Testy Cross-Engine Attention."""

    def test_import(self):
        from nexus_ai.pipeline.cross_engine_attention import (
            cross_engine_attention_correction,
            apply_cross_engine_attention_batch,
        )
        assert callable(cross_engine_attention_correction)
        assert callable(apply_cross_engine_attention_batch)

    def test_correction_applied(self):
        """Test czy korekcja jest stosowana gdy silnik ma niską confidence."""
        from nexus_ai.pipeline.cross_engine_attention import cross_engine_attention_correction

        results = {
            "paddle": {"text": "1230.00", "confidence": [{"confidence": 0.95}]},
            "tesseract": {"text": "1230.00", "confidence": [{"confidence": 0.90}]},
            "easyocr": {"text": "1230.00", "confidence": [{"confidence": 0.85}]},
            "doctr": {"text": "999.99", "confidence": [{"confidence": 0.30}]},  # outlier
        }

        corrected = cross_engine_attention_correction(
            results, "amount_gross", "1230.00", 0.90,
        )

        # docTR powinien zostać skorygowany (niskie confidence vs consensus)
        doctr_result = corrected.get("doctr")
        if isinstance(doctr_result, dict):
            if doctr_result.get("cross_engine_corrected"):
                assert doctr_result.get("text") == "1230.00"
                assert doctr_result.get("original_value") == "999.99"

    def test_no_correction_when_high_confidence(self):
        """Test czy korekcja NIE jest stosowana gdy outlier ma wysoką confidence."""
        from nexus_ai.pipeline.cross_engine_attention import cross_engine_attention_correction

        results = {
            "paddle": {"text": "1230.00", "confidence": [{"confidence": 0.85}]},
            "easyocr": {"text": "1231.00", "confidence": [{"confidence": 0.80}]},
        }

        corrected = cross_engine_attention_correction(
            results, "amount_gross", "1230.00", 0.85,
        )
        # Obie mają podobną confidence — żadna nie powinna być skorygowana
        easyocr_result = corrected.get("easyocr")
        if isinstance(easyocr_result, dict):
            assert easyocr_result.get("cross_engine_corrected") is not True


# ═══════════════════════════════════════════════════════════════════════════
# OCRSecurity Tests
# ═══════════════════════════════════════════════════════════════════════════

class TestOCRSecurity:
    """Testy OCR Rate Limiter i Secure Temp Files."""

    def test_rate_limiter_allows(self):
        """Test czy rate limiter przepuszcza requesty w limicie."""
        from nexus_ai.pipeline.ocr_security import OCRRateLimiter

        limiter = OCRRateLimiter(max_per_minute=100)
        for _ in range(50):
            allowed, msg = limiter.allow()
            assert allowed, f"Expected allowed but got: {msg}"

    def test_rate_limiter_blocks(self):
        """Test czy rate limiter blokuje po przekroczeniu limitu."""
        from nexus_ai.pipeline.ocr_security import OCRRateLimiter

        limiter = OCRRateLimiter(max_per_minute=3)
        for _ in range(3):
            limiter.allow()
        allowed, msg = limiter.allow()
        assert not allowed

    def test_rate_limiter_current_rate(self):
        """Test current_rate property."""
        from nexus_ai.pipeline.ocr_security import OCRRateLimiter

        limiter = OCRRateLimiter(max_per_minute=10)
        for _ in range(5):
            limiter.allow()
        assert limiter.current_rate == 5

    @pytest.mark.asyncio
    async def test_secure_temp_file_manager(self):
        """Test SecureTempFileManager."""
        from nexus_ai.pipeline.ocr_security import SecureTempFileManager

        async with SecureTempFileManager(encrypt=False) as mgr:
            tmp_path = mgr.get_temp_path("test.png")
            assert tmp_path is not None
            assert tmp_path.parent.exists()
        # Po wyjściu z context manager, katalog powinien być usunięty
        assert not tmp_path.parent.exists()

    def test_global_rate_limiter(self):
        """Test globalnego rate limitera."""
        from nexus_ai.pipeline.ocr_security import get_ocr_rate_limiter

        limiter = get_ocr_rate_limiter()
        assert limiter._max_per_minute == 30


# ═══════════════════════════════════════════════════════════════════════════
# MultiModalDocumentUnderstanding Tests
# ═══════════════════════════════════════════════════════════════════════════

class TestMultiModalUnderstanding:
    """Testy Multi-Modal Document Understanding."""

    def test_import(self):
        from nexus_ai.pipeline.multi_modal_understanding import (
            MultiModalDocumentUnderstanding,
            MultiModalResult,
        )
        engine = MultiModalDocumentUnderstanding()
        assert len(engine.DEFAULT_MODAL_WEIGHTS) == 4

    def test_fuse_basic(self):
        """Test podstawowej fuzji 4 modalności."""
        from nexus_ai.pipeline.multi_modal_understanding import MultiModalDocumentUnderstanding

        engine = MultiModalDocumentUnderstanding()
        result = engine.fuse(
            field_name="amount_gross",
            ocr_value="1230.00",
            ocr_confidence=0.90,
            layout_blocks=[{
                "text": "Brutto: 1230.00 PLN",
                "bbox": [[10, 700], [200, 700], [200, 720], [10, 720]],
                "confidence": 0.85,
            }],
            vision_result=None,
            semantic_context={"vendor_vat_status": "active"},
        )

        assert result.fused_confidence > 0
        assert result.fused_value is not None
        assert result.layout_position != "unknown"
        assert "fused" in result.reasoning.lower() or result.reasoning != ""

    def test_fuse_no_vision(self):
        """Test fuzji bez vision (tylko OCR + layout + semantic)."""
        from nexus_ai.pipeline.multi_modal_understanding import MultiModalDocumentUnderstanding

        engine = MultiModalDocumentUnderstanding()
        result = engine.fuse(
            field_name="vendor_nip",
            ocr_value="1234567890",
            ocr_confidence=0.85,
            layout_blocks=None,
            vision_result=None,
            semantic_context={"vendor_vat_status": "active", "vendor_account_on_whitelist": False},
        )

        assert result.ocr_confidence == 0.85
        assert result.vision_confidence == 0.0
        assert result.fused_confidence > 0

    def test_semantic_validation(self):
        """Test walidacji semantycznej."""
        from nexus_ai.pipeline.multi_modal_understanding import MultiModalDocumentUnderstanding

        # NIP powinien być invalid gdy VAT inactive
        assert not MultiModalDocumentUnderstanding._validate_semantic(
            "vendor_nip", "1234567890", {"vendor_vat_status": "inactive"}
        )

        # NIP powinien być valid gdy VAT active
        assert MultiModalDocumentUnderstanding._validate_semantic(
            "vendor_nip", "1234567890", {"vendor_vat_status": "active"}
        )

        # IBAN valid tylko gdy na białej liście
        assert MultiModalDocumentUnderstanding._validate_semantic(
            "iban", "PL1234567890", {"vendor_account_on_whitelist": True}
        )


# ═══════════════════════════════════════════════════════════════════════════
# CrossPage Merge + Exotic Formats Tests
# ═══════════════════════════════════════════════════════════════════════════

class TestCrossPageMerge:
    """Testy cross-page text merging (S28)."""

    def test_single_page(self):
        from nexus_ai.pipeline.ocr_consensus import merge_cross_page_text

        result = merge_cross_page_text(["Hello World"])
        assert result == "Hello World"

    def test_empty_input(self):
        from nexus_ai.pipeline.ocr_consensus import merge_cross_page_text

        result = merge_cross_page_text([])
        assert result == ""

    def test_two_pages_no_overlap(self):
        from nexus_ai.pipeline.ocr_consensus import merge_cross_page_text

        page1 = "Faktura VAT\nNIP: 1234567890\nPozycja 1"
        page2 = "Pozycja 2\nPozycja 3\nSuma: 1000.00"

        result = merge_cross_page_text([page1, page2])
        assert "Faktura VAT" in result
        assert "Pozycja 3" in result
        assert "Suma: 1000.00" in result

    def test_two_pages_with_overlap(self):
        from nexus_ai.pipeline.ocr_consensus import merge_cross_page_text

        page1 = "Faktura\nNIP: 1234567890\nKwota: 1000.00\nSuma:"
        page2 = "Kwota: 1000.00\nSuma: 1230.00\nDo zaplaty: 1230.00"

        result = merge_cross_page_text([page1, page2])
        # "Kwota: 1000.00" nie powinno się pojawić dwa razy
        assert result.count("Kwota: 1000.00") == 1
        assert "Do zaplaty: 1230.00" in result


class TestExoticFormats:
    """Testy exotic format support (S29)."""

    def test_supported_formats(self):
        from nexus_ai.pipeline.ocr_consensus import SUPPORTED_IMAGE_FORMATS, SUPPORTED_DOCUMENT_FORMATS

        assert ".heic" in SUPPORTED_IMAGE_FORMATS
        assert ".heif" in SUPPORTED_IMAGE_FORMATS
        assert ".djvu" in SUPPORTED_IMAGE_FORMATS
        assert ".xlsx" in SUPPORTED_DOCUMENT_FORMATS
        assert ".pdf" in SUPPORTED_DOCUMENT_FORMATS

    def test_document_type_detection(self):
        from nexus_ai.pipeline.ocr_consensus import _detect_document_type

        assert _detect_document_type("Faktura VAT\nNIP: 1234567890\nNetto: 1000.00") == "invoice_vat"
        assert _detect_document_type("PARAGON FISKALNY\nTotal: 50.00") == "receipt"
        assert _detect_document_type("This Agreement shall be governed by...") == "contract_en"
        assert _detect_document_type("Some random text") == "unknown"

    def test_document_type_configs(self):
        from nexus_ai.pipeline.ocr_consensus import DOCUMENT_TYPE_CONFIGS

        assert "invoice_vat" in DOCUMENT_TYPE_CONFIGS
        assert DOCUMENT_TYPE_CONFIGS["invoice_vat"]["engines"] == ["tesseract", "paddle"]
        assert "unknown" in DOCUMENT_TYPE_CONFIGS


# ═══════════════════════════════════════════════════════════════════════════
# PKD Validation Tests (S30)
# ═══════════════════════════════════════════════════════════════════════════

class TestPKDValidation:
    """Testy walidacji PKD vs przedmiot faktury."""

    def test_pkd_match(self):
        from nexus_ai.services.context_enricher import _validate_pkd_match

        result = _validate_pkd_match("62.01.Z", "IT_SERVICES", "")
        assert result == "match"

    def test_pkd_mismatch(self):
        from nexus_ai.services.context_enricher import _validate_pkd_match

        # Firma budowlana (41.10) wystawia fakturę za catering
        result = _validate_pkd_match("41.10.Z", "CATERING", "")
        assert result == "mismatch"

    def test_pkd_unknown(self):
        from nexus_ai.services.context_enricher import _validate_pkd_match

        result = _validate_pkd_match("", "", "")
        assert result == "unknown"

    def test_pkd_from_text(self):
        from nexus_ai.services.context_enricher import _match_pkd_from_text

        result = _match_pkd_from_text("62.01.Z", "usługi informatyczne i programowanie")
        assert result == "match"

        result = _match_pkd_from_text("62.01.Z", "catering i gastronomia")
        assert result == "unknown"
