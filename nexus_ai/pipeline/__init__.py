# pipeline/__init__.py
"""Pipeline modules -- OCR consensus, preprocessing, supervisor, cross-validation.

v7.0 Audit: KOMPLETNY zestaw 15+ nowych komponentów:
OCRSupervisor, CrossValidationEngine, ZeroShotFieldExtractor,
CrossEngineAttention, MultiModalDocumentUnderstanding, OCRSecurity,
FederatedOCRAdapter, OCRBlockchainAnchor.
"""

from .ocr_base import BaseOCREngine, catch_ocr_errors
from .ocr_consensus import (
    DocTREngine, EasyOCREngine, OCRAmountResult, OCRConsensusDecision,
    OCRFieldResult, PaddleOCREngine, TesseractEngine,
    decide_amount_consensus, decide_amount_consensus_legacy,
    decide_field_consensus, pdf_to_images,
    run_ocr_pipeline, run_ocr_pipeline_with_confidence, run_ocr_pipeline_adaptive,
    merge_cross_page_text, SUPPORTED_IMAGE_FORMATS,
    SUPPORTED_DOCUMENT_FORMATS, DOCUMENT_TYPE_CONFIGS, ENGINE_WEIGHTS,
)
from .parser import InvoiceParser, ParsedInvoice
from .ocr_supervisor import OCRSupervisor
from .cross_validation_engine import (
    CrossValidationEngine, CrossValidationResult, CrossValidationVerdict,
    LayerResult, LayerStatus,
)
from .zero_shot_extractor import (
    ZeroShotFieldExtractor, ZERO_SHOT_EXTRACTION_PROMPT, DEFAULT_EXTRACTION_FIELDS,
)
from .cross_engine_attention import (
    cross_engine_attention_correction, apply_cross_engine_attention_batch,
)
from .multi_modal_understanding import (
    MultiModalDocumentUnderstanding, MultiModalResult,
)
from .ocr_security import (
    OCRRateLimiter, SecureTempFileManager, get_ocr_rate_limiter,
)
from .ocr_federated import FederatedOCRAdapter
from .ocr_blockchain_anchor import OCRBlockchainAnchor, OCRResultAnchor

__all__ = [
    "BaseOCREngine", "catch_ocr_errors",
    "OCRConsensusDecision", "OCRAmountResult", "OCRFieldResult",
    "decide_amount_consensus", "decide_amount_consensus_legacy",
    "decide_field_consensus", "run_ocr_pipeline",
    "run_ocr_pipeline_with_confidence", "run_ocr_pipeline_adaptive",
    "pdf_to_images", "ENGINE_WEIGHTS", "DOCUMENT_TYPE_CONFIGS",
    "merge_cross_page_text", "SUPPORTED_IMAGE_FORMATS", "SUPPORTED_DOCUMENT_FORMATS",
    "TesseractEngine", "PaddleOCREngine", "DocTREngine", "EasyOCREngine",
    "InvoiceParser", "ParsedInvoice",
    "OCRSupervisor",
    "CrossValidationEngine", "CrossValidationResult", "CrossValidationVerdict",
    "LayerResult", "LayerStatus",
    "ZeroShotFieldExtractor", "ZERO_SHOT_EXTRACTION_PROMPT", "DEFAULT_EXTRACTION_FIELDS",
    "cross_engine_attention_correction", "apply_cross_engine_attention_batch",
    "MultiModalDocumentUnderstanding", "MultiModalResult",
    "OCRRateLimiter", "SecureTempFileManager", "get_ocr_rate_limiter",
    "FederatedOCRAdapter", "OCRBlockchainAnchor", "OCRResultAnchor",
]
