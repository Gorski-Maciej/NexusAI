"""
Weryfikacja — sprawdzanie dostępności i wersji pypdfium2.
"""

from __future__ import annotations


def verify_pdfium_available() -> bool:
    try:
        import pypdfium2 as pdfium  # noqa: F401
        return True
    except ImportError:
        return False


def verify_pdfium_version() -> str:
    try:
        import pypdfium2 as pdfium
        return getattr(pdfium, "__version__", "unknown")
    except ImportError:
        return "not installed"


__all__ = ["verify_pdfium_available", "verify_pdfium_version"]
