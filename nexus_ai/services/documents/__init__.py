"""Documents domain -- przechowywanie, fingerprinting, OCR, wzbogacanie kontekstu.

Re-exports from flat service files for backward compatibility.
"""

from nexus_ai.services.context_enricher import ContextEnricher, ensure_cache_schema  # noqa: F401
from nexus_ai.services.document_fingerprint import ensure_fingerprint_schema  # noqa: F401
from nexus_ai.services.file_system_service import FileSystemService  # noqa: F401
from nexus_ai.services.storage import StorageService  # noqa: F401
