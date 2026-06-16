# pipeline/__init__.py
"""Pipeline modules — pozostałe po czyszczeniu starych technologii.

Usunięto: ocr_engine (fitz), preprocessor (cv2), coordinator, factory, manager,
active_learning (przeniesione do core/active_learning.py).
"""

from .ocr_consensus import (
    OCRAmountResult,
    OCRConsensusDecision,
    OCRFieldResult,
    decide_amount_consensus,
    decide_amount_consensus_legacy,
    decide_field_consensus,
    run_ocr_pipeline,
    run_ocr_pipeline_with_confidence,
    pdf_to_images,
    # Engines
    TesseractEngine,
    PaddleOCREngine,
    DocTREngine,
    EasyOCREngine,
)
from .parser import InvoiceParser, ParsedInvoice

__all__ = [
    "OCRConsensusDecision",
    "OCRAmountResult",
    "OCRFieldResult",
    "decide_amount_consensus",
    "decide_amount_consensus_legacy",
    "decide_field_consensus",
    "run_ocr_pipeline",
    "run_ocr_pipeline_with_confidence",
    "pdf_to_images",
    "TesseractEngine",
    "PaddleOCREngine",
    "DocTREngine",
    "EasyOCREngine",
    "InvoiceParser",
    "ParsedInvoice",
]
