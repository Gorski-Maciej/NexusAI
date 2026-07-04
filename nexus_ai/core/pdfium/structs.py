"""
msgspec.Struct — wszystkie DTO dla operacji PDF.
Wyodrębnione z pdfium.py (~200 LOC) dla przejrzystości.
"""

from __future__ import annotations

from typing import Any

import msgspec


class PDFTextRange(msgspec.Struct):
    """Pojedynczy zakres tekstu z pozycją."""
    text: str
    left: float
    top: float
    right: float
    bottom: float
    font_size: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "left": round(self.left, 2),
            "top": round(self.top, 2),
            "right": round(self.right, 2),
            "bottom": round(self.bottom, 2),
            "font_size": round(self.font_size, 2),
        }


class PDFPageInfo(msgspec.Struct):
    """Informacja o stronie PDF z zakresami tekstu."""
    page_num: int
    width: float
    height: float
    text_ranges: list[PDFTextRange]

    @property
    def text_count(self) -> int:
        return len(self.text_ranges)

    def to_dict(self) -> dict[str, Any]:
        return {
            "page_num": self.page_num,
            "width": round(self.width, 2),
            "height": round(self.height, 2),
            "text_count": len(self.text_ranges),
            "text_ranges": [t.to_dict() for t in self.text_ranges],
        }


class PDFSignature(msgspec.Struct):
    """Podpis cyfrowy w dokumencie PDF."""
    author: str = ""
    reason: str = ""
    location: str = ""
    is_verified: bool = False
    signed_at: str = ""
    field_name: str = ""
    page_num: int = 0


class PDFFormField(msgspec.Struct):
    """Pole formularza AcroForm."""
    name: str = ""
    type: str = ""
    value: str = ""
    is_readonly: bool = False
    is_required: bool = False
    max_length: int = 0
    options: list[str] = []
    page_num: int = 0
    rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)


class PDFRenderCacheEntry(msgspec.Struct):
    """Wpis w cache'u renderowanych stron."""
    png_bytes: bytes
    cached_at: float = 0.0


class PDFProgressInfo(msgspec.Struct):
    """Informacja o postępie renderowania."""
    current_page: int = 0
    total_pages: int = 0
    percent: float = 0.0
    page_dpi: int = 0


class PDFAnnotation(msgspec.Struct):
    """Adnotacja na stronie PDF."""
    type: str = ""
    rect: tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)
    content: str = ""
    color: tuple[int, int, int] = (255, 255, 0)
    author: str = ""
    modified_at: str = ""
    flags: int = 0
    page_num: int = 0


class PDFAttachment(msgspec.Struct):
    """Załącznik osadzony w dokumencie PDF."""
    name: str = ""
    data: bytes = b""
    size: int = 0
    index: int = 0


class PDFBookmark(msgspec.Struct):
    """Zakładka (bookmark/outline) w dokumencie PDF."""
    title: str = ""
    page_index: int = 0
    level: int = 0
    children: list[PDFBookmark] = []


class PDFSearchResult(msgspec.Struct):
    """Wynik wyszukiwania tekstu w PDF."""
    text: str = ""
    left: float = 0.0
    top: float = 0.0
    right: float = 0.0
    bottom: float = 0.0
    char_index: int = 0
    count: int = 1


class PDFACompliance(msgspec.Struct):
    """Wynik sprawdzenia zgodności z PDF/A."""
    is_pdfa: bool = False
    pdfa_version: int = 0
    pdfa_version_str: str = "none"


class PDFFormFillData(msgspec.Struct):
    """DTO dla wypełniania formularza."""
    field_name: str
    value: str


class PDFFormFillBatch(msgspec.Struct):
    """DTO dla wsadowego wypełniania formularza."""
    fields: list[PDFFormFillData]


__all__ = [
    "PDFTextRange", "PDFPageInfo", "PDFSignature", "PDFFormField",
    "PDFRenderCacheEntry", "PDFProgressInfo", "PDFAnnotation", "PDFAttachment",
    "PDFBookmark", "PDFSearchResult", "PDFACompliance", "PDFFormFillData",
    "PDFFormFillBatch",
]
