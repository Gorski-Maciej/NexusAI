# core/tracing.py
import sys
import uuid
from contextvars import ContextVar

from loguru import logger

# Zmienna kontekstowa unikalna dla każdego "requestu"
correlation_id_ctx: ContextVar[str] = ContextVar("correlation_id", default="system")

def init_trace() -> str:
    """Tworzy nowe ID dla nowego dokumentu."""
    cid = uuid.uuid4().hex
    correlation_id_ctx.set(cid)
    return cid

def setup_tracing_logger():
    logger.remove()
    # Konfiguracja logera, aby zawsze wypisywał correlation_id, jeśli istnieje
    fmt = "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{extra[correlation_id]}</cyan> | <level>{message}</level>"
    logger.add(sys.stderr, format=fmt, enqueue=True)
