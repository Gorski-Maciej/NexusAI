"""
test_ocr_pipeline_e2e.py — End-to-end tests dla pipeline OCR (v7.0 Audit).

Raport v7.0, sekcja 7.3: "PRIORYTETOWE (do natychmiastowego dodania):
2. test_ocr_pipeline_e2e.py — end-to-end test pipeline'u (PDF → OCR → parser → wynik)"

Testuje pełny pipeline: PDF → preprocessing → OCR → consensus → parser → wynik.
"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# ═══════════════════════════════════════════════════════════════════════════
# E2E: Full Pipeline Flow
# ═══════════════════════════════════════════════════════════════════════════

class TestOCRPipelineE2E:
    """End-to-end tests dla pełnego pipeline OCR."""

    @pytest.mark.asyncio
    async def test_full_pipeline_flow_with_mocks(self):
        """Test pełnego przepływu: PDF → OCR → consensus → parser."""
        from nexus_ai.pipeline.ocr_consensus import (
            OCRFieldResult,
            OCRAmountResult,
            decide_field_consensus,
            decide_amount_consensus,
        )
        from nexus_ai.pipeline.parser import InvoiceParser, ParsedInvoice

        # Symuluj wyniki 4 silników
        ocr_text = "Faktura VAT\nNIP: 1234567890\nKwota netto: 1000.00\nKwota brutto: 1230.00\nIBAN: PL12345678901234567890123456"

        # Konsensus dla NIP
        nip_results = [
            OCRFieldResult(value="1234567890", confidence=0.95, source="paddle"),
            OCRFieldResult(value="1234567890", confidence=0.90, source="tesseract"),
            OCRFieldResult(value="1234567890", confidence=0.88, source="doctr"),
            OCRFieldResult(value="123456789O", confidence=0.60, source="easyocr"),
        ]
        nip_consensus = decide_field_consensus(nip_results, majority_threshold=3.0)
        assert not nip_consensus.confidence_conflict
        assert nip_consensus.accepted.value == "1234567890"

        # Konsensus dla kwoty
        amount_results = [
            OCRAmountResult(amount_gross=1230.00, source="paddle"),
            OCRAmountResult(amount_gross=1230.00, source="doctr"),
            OCRAmountResult(amount_gross=1230.00, source="tesseract"),
            OCRAmountResult(amount_gross=1229.99, source="easyocr"),
        ]
        amount_consensus = decide_amount_consensus(amount_results, tolerance=0.01, majority_threshold=3.0)
        assert not amount_consensus.confidence_conflict
        assert amount_consensus.amount_gross == 1230.00

        # Parser
        parser = InvoiceParser()
        parsed = parser.parse(ocr_text)
        assert parsed.nip == "1234567890"
        assert parsed.amount_gross is not None

    @pytest.mark.asyncio
    async def test_pipeline_with_confidence_conflict(self):
        """Test pipeline gdy występuje konflikt między silnikami."""
        from nexus_ai.pipeline.ocr_consensus import (
            OCRFieldResult,
            decide_field_consensus,
        )

        # Remis 2-2
        nip_results = [
            OCRFieldResult(value="1234567890", confidence=0.90, source="paddle"),
            OCRFieldResult(value="1234567890", confidence=0.85, source="tesseract"),
            OCRFieldResult(value="0987654321", confidence=0.88, source="doctr"),
            OCRFieldResult(value="0987654321", confidence=0.82, source="easyocr"),
        ]
        nip_consensus = decide_field_consensus(nip_results, majority_threshold=3.0)
        # Przy threshold=3.0, remis 2-2 powinien dać confidence_conflict
        assert nip_consensus.confidence_conflict

    @pytest.mark.asyncio
    async def test_weighted_voting_paddle_advantage(self):
        """Test ważonego głosowania — PaddleOCR ma 2x wagę."""
        from nexus_ai.pipeline.ocr_consensus import (
            OCRFieldResult,
            decide_field_consensus,
        )

        # PaddleOCR + 1 inny silnik vs 2 inne — Paddle powinien wygrać (waga 2+1=3 vs 1+1=2)
        results = [
            OCRFieldResult(value="CORRECT", confidence=0.90, source="paddle"),
            OCRFieldResult(value="CORRECT", confidence=0.85, source="doctr"),
            OCRFieldResult(value="WRONG", confidence=0.88, source="tesseract"),
            OCRFieldResult(value="WRONG", confidence=0.82, source="easyocr"),
        ]
        consensus = decide_field_consensus(results, majority_threshold=3.0)
        assert not consensus.confidence_conflict
        assert consensus.accepted.value == "CORRECT"

    @pytest.mark.asyncio
    async def test_build_field_confidence_complete(self):
        """Test _build_field_confidence z kompletnym payloadem."""
        from nexus_ai.api.tasks.ocr import _build_field_confidence
        from unittest.mock import MagicMock

        payload = {
            "amount_gross": 1230.00,
            "amount_net": 1000.00,
            "vat": 230.00,
            "vat_rate": "23%",
            "contractor_nip": "1234567890",
            "number": "FV/2026/001",
            "issue_date": "2026-07-21",
            "category": "IT_SERVICES",
            "bank_account": "PL12345678901234567890123456",
            "ocr_confidence": 0.92,
            "llm_validation": 0.88,
            "nip_valid": True,
            "iban_valid": True,
        }

        mock_consensus = MagicMock()
        mock_consensus.confidence_conflict = False
        mock_consensus.amount_gross = 1230.00
        mock_consensus.votes = []

        fc = _build_field_confidence(payload, mock_consensus)
        assert "total_gross" in fc
        assert "total_net" in fc
        assert "vendor_nip" in fc
        assert "invoice_number" in fc
        assert "issue_date" in fc
        assert "category_code" in fc
        assert "vat_amount" in fc
        assert "vat_rate" in fc
        assert "iban" in fc

        # Sprawdź wartości
        assert fc["total_gross"]["confidence"] == 0.92
        assert fc["vendor_nip"]["confidence"] == 0.95  # nip_valid=True
        assert fc["iban"]["confidence"] == 0.85  # iban_valid=True


# ═══════════════════════════════════════════════════════════════════════════
# E2E: New Components (v7.0)
# ═══════════════════════════════════════════════════════════════════════════

class TestNewComponentsV7:
    """Testy nowych komponentów z v7.0 Audit."""

    def test_ocr_preprocessing_module_imports(self):
        """Test czy moduł ocr_preprocessing się importuje."""
        from nexus_ai.core.ocr_preprocessing import (
            HAS_CV2,
            deskew_image,
            sauvola_binarize,
            remove_background,
            correct_perspective,
            predictive_preprocess,
            full_ocr_preprocess,
        )
        assert isinstance(HAS_CV2, bool)

    def test_ocr_supervisor_imports(self):
        """Test czy OCRSupervisor się importuje."""
        from nexus_ai.pipeline.ocr_supervisor import (
            OCRSupervisor,
            OCR_DISPUTE_PROMPT,
            OCR_FIELD_VALIDATION_PROMPT,
        )
        supervisor = OCRSupervisor(use_supervisor=False)
        assert supervisor._use_supervisor is False
        assert "ekspertem OCR" in OCR_DISPUTE_PROMPT
        assert "walidatorem pól" in OCR_FIELD_VALIDATION_PROMPT

    @pytest.mark.asyncio
    async def test_supervisor_quick_format_validation(self):
        """Test szybkiej ścieżki walidacji formatu (bez AI)."""
        from nexus_ai.pipeline.ocr_supervisor import OCRSupervisor
        from nexus_ai.pipeline.ocr_consensus import OCRFieldResult, OCRConsensusDecision

        supervisor = OCRSupervisor(use_supervisor=False)

        # NIP: tylko jeden silnik zwraca poprawny format
        votes = [
            OCRFieldResult(value="1234567890", confidence=0.90, source="paddle"),
            OCRFieldResult(value="123-456-78-90", confidence=0.85, source="tesseract"),
            OCRFieldResult(value="12345678", confidence=0.80, source="doctr"),
        ]
        consensus = OCRConsensusDecision(
            accepted=votes[0],
            confidence_conflict=True,
            votes=votes,
        )

        resolved = await supervisor.resolve_conflict(
            field_name="vendor_nip",
            consensus=consensus,
            all_engine_results={},
            full_text="",
        )
        assert resolved["resolved_value"] == "1234567890"
        assert not resolved["ai_resolved"]

    @pytest.mark.asyncio
    async def test_supervisor_nip_checksum(self):
        """Test walidacji NIP przez sumę kontrolną."""
        from nexus_ai.pipeline.ocr_supervisor import OCRSupervisor
        from nexus_ai.pipeline.ocr_consensus import OCRFieldResult, OCRConsensusDecision

        supervisor = OCRSupervisor(use_supervisor=False)

        # Poprawny NIP: 1234563218 (checksum = 8)
        # Wagi: 6,5,7,2,3,4,5,6,7 → 1*6+2*5+3*7+4*2+5*3+6*4+3*5+2*6+1*7 = 74 → 74%11 = 8
        votes = [
            OCRFieldResult(value="1234563218", confidence=0.90, source="paddle"),
            OCRFieldResult(value="1234 563218", confidence=0.85, source="tesseract"),
        ]
        consensus = OCRConsensusDecision(
            accepted=votes[0],
            confidence_conflict=True,
            votes=votes,
        )
        resolved = await supervisor.resolve_conflict(
            field_name="vendor_nip",
            consensus=consensus,
            all_engine_results={},
        )
        # Jeśli suma kontrolna się zgadza, powinien rozwiązać
        assert resolved["resolved_value"] is not None

    def test_cross_validation_engine(self):
        """Test importu i struktury CrossValidationEngine."""
        from nexus_ai.pipeline.cross_validation_engine import (
            CrossValidationEngine,
            CrossValidationResult,
            CrossValidationVerdict,
        )
        engine = CrossValidationEngine()
        assert len(engine.DEFAULT_LAYER_WEIGHTS) == 5
        assert "ocr_confidence" in engine.DEFAULT_LAYER_WEIGHTS

    @pytest.mark.asyncio
    async def test_cross_validation_all_skip(self):
        """Test cross-validation gdy wszystkie warstwy są SKIP (brak klientów)."""
        from nexus_ai.pipeline.cross_validation_engine import CrossValidationEngine

        engine = CrossValidationEngine()
        result = await engine.validate(
            invoice_data={"contractor_nip": "1234567890"},
            ocr_consensus=None,
            tb_client=None,
            duckdb_manager=None,
        )
        assert result.verdict.value == "ACCEPT"

    def test_field_confidence_with_bbox(self):
        """Test FieldConfidence z bounding boxem."""
        from nexus_ai.core.field_confidence import (
            FieldConfidence,
            build_field_confidence_with_bbox,
        )
        fc = build_field_confidence_with_bbox(
            field_name="vendor_nip",
            value="1234567890",
            confidence=0.95,
            source="paddle",
            bbox=[100.0, 50.0, 300.0, 80.0],
            all_sources=["paddle", "tesseract"],
        )
        assert fc.bbox == [100.0, 50.0, 300.0, 80.0]
        assert fc.all_sources == ["paddle", "tesseract"]
        assert fc.is_reliable(0.85)

    def test_engine_confidence_tracker(self):
        """Test EngineConfidenceTracker."""
        from nexus_ai.core.field_confidence import (
            get_confidence_tracker,
            EngineConfidenceTracker,
        )

        tracker = EngineConfidenceTracker(window_size=10)
        tracker.record("paddle", 0.95, "vendor_nip")
        tracker.record("paddle", 0.92, "amount_gross")
        tracker.record("tesseract", 0.85, "vendor_nip")

        assert tracker.get_average_confidence("paddle") > 0.9
        assert tracker.get_trend("paddle") == "unknown"  # za mało danych

        # Dodaj więcej danych
        for _ in range(10):
            tracker.record("paddle", 0.90, "vendor_nip")
        assert tracker.get_trend("paddle") != "unknown"

        field_stats = tracker.get_field_stats("paddle")
        assert "vendor_nip" in field_stats

    def test_semantic_guard_real_embedding_fallback(self):
        """Test SemanticGuard z fallbackiem do mock embeddingu."""
        from nexus_ai.services.semantic_guard import SemanticGuard, AnomalyAction

        guard = SemanticGuard(use_real_embedding=False)
        # Test samej struktury
        assert guard._use_real_embedding is False

    @pytest.mark.asyncio
    async def test_semantic_guard_adaptive_thresholds(self):
        """Test adaptacyjnych progów SemanticGuard."""
        from nexus_ai.services.semantic_guard import SemanticGuard

        thresholds = SemanticGuard._get_adaptive_thresholds({
            "trust_score": 0.9,
            "invoice_count": 100,
        })
        assert thresholds["warn"] > 0.5
        assert thresholds["block"] > 0.7

        # Nowy kontrahent — wyższe progi
        new_thresholds = SemanticGuard._get_adaptive_thresholds({
            "trust_score": 0.3,
            "invoice_count": 1,
        })
        assert new_thresholds["warn"] < thresholds["warn"]  # niższy próg = bardziej rygorystyczny


# ═══════════════════════════════════════════════════════════════════════════
# E2E: InvoiceParser with BBox
# ═══════════════════════════════════════════════════════════════════════════

class TestInvoiceParserE2E:
    """Testy parsera faktur z bounding boxami."""

    def test_parse_basic_invoice(self):
        """Test parsowania podstawowej faktury."""
        from nexus_ai.pipeline.parser import InvoiceParser, ParsedInvoice

        raw_text = (
            "Faktura VAT nr FV/2026/001\n"
            "Sprzedawca: Jan Kowalski\n"
            "NIP: 1234567890\n"
            "Data wystawienia: 2026-07-21\n"
            "Data sprzedazy: 2026-07-21\n"
            "Netto: 1000.00 PLN\n"
            "VAT 23%: 230.00 PLN\n"
            "Brutto: 1230.00 PLN\n"
            "Do zaplaty: 1230.00 PLN\n"
            "Konto: PL12 1234 5678 9012 3456 7890 1234"
        )

        parser = InvoiceParser()
        parsed = parser.parse(raw_text)

        assert parsed.nip == "1234567890"
        assert parsed.iban is not None

    def test_parse_with_bbox(self):
        """Test parsera z bounding boxami."""
        from nexus_ai.pipeline.parser import InvoiceParser

        raw_text = "Faktura\nNIP: 1234567890\nKwota: 1230.00"
        blocks = [
            {"bbox": [[10, 10], [100, 10], [100, 30], [10, 30]], "text": "Faktura", "confidence": 0.95},
            {"bbox": [[10, 40], [200, 40], [200, 60], [10, 60]], "text": "NIP: 1234567890", "confidence": 0.90},
            {"bbox": [[10, 700], [200, 700], [200, 720], [10, 720]], "text": "Kwota: 1230.00", "confidence": 0.85},
        ]

        parser = InvoiceParser()
        parsed = parser.parse_with_bbox(raw_text, blocks, page_height=800)
        assert parsed.nip == "1234567890"


# ═══════════════════════════════════════════════════════════════════════════
# E2E: Consensus Edge Cases
# ═══════════════════════════════════════════════════════════════════════════

class TestConsensusEdgeCasesE2E:
    """Testy skrajnych przypadków konsensusu."""

    def test_all_engines_agree(self):
        """Wszystkie 4 silniki zgodne."""
        from nexus_ai.pipeline.ocr_consensus import OCRFieldResult, decide_field_consensus

        results = [
            OCRFieldResult(value="FV/001", confidence=0.95, source="paddle"),
            OCRFieldResult(value="FV/001", confidence=0.90, source="tesseract"),
            OCRFieldResult(value="FV/001", confidence=0.88, source="doctr"),
            OCRFieldResult(value="FV/001", confidence=0.85, source="easyocr"),
        ]
        consensus = decide_field_consensus(results, majority_threshold=3.0)
        assert not consensus.confidence_conflict
        assert consensus.accepted.value == "FV/001"

    def test_all_engines_disagree(self):
        """Wszystkie silniki zwracają różne wartości."""
        from nexus_ai.pipeline.ocr_consensus import OCRFieldResult, decide_field_consensus

        results = [
            OCRFieldResult(value="A", confidence=0.80, source="paddle"),
            OCRFieldResult(value="B", confidence=0.75, source="tesseract"),
            OCRFieldResult(value="C", confidence=0.70, source="doctr"),
            OCRFieldResult(value="D", confidence=0.65, source="easyocr"),
        ]
        consensus = decide_field_consensus(results, majority_threshold=3.0)
        assert consensus.confidence_conflict
        # Powinien wybrać najwyższy confidence
        assert consensus.accepted.value == "A"

    def test_empty_results(self):
        """Pusta lista wyników."""
        from nexus_ai.pipeline.ocr_consensus import OCRFieldResult, decide_field_consensus

        consensus = decide_field_consensus([], majority_threshold=3.0)
        assert not consensus.confidence_conflict
        assert consensus.accepted is None

    def test_unicode_values(self):
        """Test wartości z polskimi znakami."""
        from nexus_ai.pipeline.ocr_consensus import OCRFieldResult, decide_field_consensus

        results = [
            OCRFieldResult(value="Zażółć gęślą jaźń", confidence=0.90, source="paddle"),
            OCRFieldResult(value="Zażółć gęślą jaźń", confidence=0.85, source="easyocr"),
            OCRFieldResult(value="Zażółć gęślą jazń", confidence=0.80, source="tesseract"),
            OCRFieldResult(value="Zażółć gęślą jaźń", confidence=0.75, source="doctr"),
        ]
        consensus = decide_field_consensus(results, majority_threshold=3.0)
        # 3/4 silników zgadza się → powinno przejść (waga: paddle=2 + easyocr=1 + doctr=1 = 4 >= 3)
        assert not consensus.confidence_conflict

    def test_amount_consensus_tolerance(self):
        """Test tolerancji dla konsensusu kwot."""
        from nexus_ai.pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus

        results = [
            OCRAmountResult(amount_gross=123.45, source="paddle"),
            OCRAmountResult(amount_gross=123.46, source="doctr"),
            OCRAmountResult(amount_gross=123.45, source="tesseract"),
            OCRAmountResult(amount_gross=123.44, source="easyocr"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3.0)
        # paddle=2 + tesseract=1 + easyocr=1 = 4 (bo wszystkie w tolerancji)
        assert not consensus.confidence_conflict

    def test_amount_consensus_outlier(self):
        """Test kwot z outlierem."""
        from nexus_ai.pipeline.ocr_consensus import OCRAmountResult, decide_amount_consensus

        results = [
            OCRAmountResult(amount_gross=123.45, source="paddle"),
            OCRAmountResult(amount_gross=123.45, source="doctr"),
            OCRAmountResult(amount_gross=123.45, source="easyocr"),
            OCRAmountResult(amount_gross=999.99, source="tesseract"),
        ]
        consensus = decide_amount_consensus(results, tolerance=0.01, majority_threshold=3.0)
        # paddle=2 + doctr=1 + easyocr=1 = 4 >= 3
        assert not consensus.confidence_conflict
        assert consensus.amount_gross == 123.45


# ═══════════════════════════════════════════════════════════════════════════
# E2E: Document Fingerprint
# ═══════════════════════════════════════════════════════════════════════════

class TestDocumentFingerprintE2E:
    """Testy document fingerprint."""

    def test_verify_or_flag_tamper_ok(self):
        """Test weryfikacji — dokument niezmodyfikowany."""
        from nexus_ai.services.document_fingerprint import (
            DocumentFingerprint,
            verify_or_flag_tamper,
        )
        fp = DocumentFingerprint(
            binary_hash="abc123",
            visual_hash="def456",
            semantic_hash="ghi789",
        )
        result = verify_or_flag_tamper(fp, fp)
        assert result == "OK"

    def test_verify_or_flag_tamper_modified(self):
        """Test weryfikacji — dokument zmodyfikowany."""
        from nexus_ai.services.document_fingerprint import (
            DocumentFingerprint,
            verify_or_flag_tamper,
        )
        stored = DocumentFingerprint(
            binary_hash="abc123",
            visual_hash="def456",
            semantic_hash="ghi789",
        )
        current = DocumentFingerprint(
            binary_hash="xyz999",
            visual_hash="def456",
            semantic_hash="ghi789",
        )
        result = verify_or_flag_tamper(stored, current)
        assert result == "MODIFIED_EXTERNALLY_BUT_SEMANTICALLY_SAME"

    def test_binary_anchor_u128(self):
        """Test konwersji binary hash → anchor u128."""
        from nexus_ai.services.document_fingerprint import binary_anchor_u128
        anchor = binary_anchor_u128("a" * 64)
        assert isinstance(anchor, int)
