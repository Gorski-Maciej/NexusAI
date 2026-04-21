import logging
from litestar.connection import Request
from litestar.response import Response
from litestar.exceptions import HTTPException

logger = logging.getLogger("nexus.api.errors")

def global_exception_handler(request: Request, exc: Exception) -> Response:
    """Przechwytuje wszystkie nieobsłużone błędy i zwraca czytelny JSON."""
    if isinstance(exc, HTTPException):
        return Response(
            content={"error": exc.detail, "status_code": exc.status_code},
            status_code=exc.status_code
        )

    # Logujemy pełny ślad błędu do pliku
    logger.error(f"Nieoczekiwany błąd API na ścieżce {request.url.path}: {str(exc)}", exc_info=True)

    return Response(
        content={
            "error": "Wewnętrzny błąd serwera. Zespół techniczny został powiadomiony.",
            "status_code": 500
        },
        status_code=500
    )
