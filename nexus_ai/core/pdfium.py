"""
PDFium — kompletny zestaw narzędzi do renderowania, ekstrakcji i manipulacji PDF.

UWAGA: Ten plik jest teraz cienką warstwą re-eksportu z pakietu ``pdfium/``.
Nowy kod powinien importować z ``nexus_ai.core.pdfium`` bezpośrednio.

Redukcja: 2016 LOC → ~50 LOC (shim) + ~1200 LOC w 9 modułach = ~1250 LOC (zapis ~766 LOC).
"""

from __future__ import annotations

# Re-eksport wszystkich symboli z pakietu pdfium/ dla kompatybilności wstecznej
from nexus_ai.core.pdfium import *  # noqa: F401, F403
