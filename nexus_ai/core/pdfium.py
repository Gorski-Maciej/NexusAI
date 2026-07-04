"""
PDFium — compatibility shim, delegates to services/pdfium/.

Enterprise refactoring: core/ → services/ for better modularity.
New code should import from ``nexus_ai.services.pdfium`` directly.
"""

from __future__ import annotations

# Re-export all symbols from the new services/pdfium/ package
from nexus_ai.services.pdfium import *  # noqa: F401, F403
