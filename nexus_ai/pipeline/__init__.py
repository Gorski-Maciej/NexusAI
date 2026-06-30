# pipeline/__init__.py
"""Pipeline modules -- pozostałe po czyszczeniu starych technologii.

Usunięto: ocr_engine (pypdfium2), preprocessor (cv2), coordinator, factory, manager,
active_learning (przeniesione do core/active_learning.py).
"""

from .ocr_consensus import (
    DocTREngine,
    EasyOCREngine,
    OCRAmountResult,
    OCRConsensusDecision,
    OCRFieldResult,
    PaddleOCREngine,
    # Engines
    TesseractEngine,
    decide_amount_consensus,
    decide_amount_consensus_legacy,
    decide_field_consensus,
    pdf_to_images,
    run_ocr_pipeline,
    run_ocr_pipeline_with_confidence,
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
