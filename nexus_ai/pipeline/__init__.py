# pipeline/__init__.py
"""Pipeline modules — pozostałe po czyszczeniu starych technologii.

Usunięto: ocr_engine (fitz), preprocessor (cv2), coordinator, factory, manager,
active_learning (przeniesione do core/active_learning.py).
"""
from .ocr_consensus import OCRAmountResult, OCRConsensusDecision, decide_amount_consensus
from .parser import InvoiceParser, ParsedInvoice

__all__ = [
    "OCRConsensusDecision",
    "OCRAmountResult",
    "decide_amount_consensus",
    "InvoiceParser",
    "ParsedInvoice",
]
