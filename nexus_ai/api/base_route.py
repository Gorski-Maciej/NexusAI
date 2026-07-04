"""Shared route utilities — async error handler, pagination, response helpers.

Eliminates repetitive try/except/log/raise patterns across 32 route files.
Usage:
    from nexus_ai.api.base_route import route_handler, parse_pagination, ok_response
"""
from __future__ import annotations

import logging
from collections.abc import Awaitable, Callable
from typing import Any, TypeVar

from litestar.exceptions import HTTPException
from litestar.response import Response
from structlog import get_logger

_T = TypeVar("_T")
_log = get_logger("nexus.api.base")


def route_handler(
    logger: logging.Logger | None = None,
    status_code: int = 500,
    error_message: str = "Operation failed",
) -> Callable[[Callable[..., Awaitable[_T]]], Callable[..., Awaitable[_T]]]:
    """Decorator wrapping an async route handler with try/except/log/raise.

    HTTPException is re-raised as-is (preserves status code and detail).
    All other exceptions are caught, logged, and wrapped in a new HTTPException.

    Args:
        logger: Logger instance. If None, uses a default module logger.
        status_code: HTTP status for unhandled exceptions.
        error_message: Message template for unhandled exceptions.

    Example:
        @get("/items")
        @route_handler(logger=my_logger, error_message="Failed to list items")
        async def list_items(self, request: Request) -> dict:
            ...
    """
    log = logger or _log

    def decorator(func: Callable[..., Awaitable[_T]]) -> Callable[..., Awaitable[_T]]:
        async def wrapper(*args: Any, **kwargs: Any) -> _T:
            try:
                return await func(*args, **kwargs)
            except HTTPException:
                raise  # preserve HTTP errors as-is
            except Exception as exc:
                log.error("[%s] %s: %s", func.__name__, error_message, exc)
                raise HTTPException(
                    status_code=status_code,
                    detail=f"{error_message}: {exc}",
                ) from exc

        return wrapper

    return decorator


class Pagination:
    """Parsed pagination parameters from request query string.

    Attributes:
        limit: Items per page (clamped to [1, 1000]).
        offset: Number of items to skip.
        page: Page number (1-indexed, derived from limit/offset).
    """
    __slots__ = ("limit", "offset", "page")

    def __init__(self, limit: int = 50, offset: int = 0) -> None:
        self.limit = max(1, min(limit, 1000))
        self.offset = max(0, offset)
        self.page = (offset // self.limit) + 1 if self.limit > 0 else 1


def parse_pagination(
    query_params: dict[str, str] | Any,
    default_limit: int = 50,
    max_limit: int = 1000,
) -> Pagination:
    """Parse limit/offset/page from request query params.

    Args:
        query_params: Request query params dict or object with .get().
        default_limit: Default items per page.
        max_limit: Maximum items per page (clamped).

    Returns:
        Pagination object with limit, offset, page.
    """
    try:
        raw_limit = query_params.get("limit", str(default_limit))
        limit = int(str(raw_limit))
    except (ValueError, TypeError, AttributeError):
        limit = default_limit
    limit = max(1, min(limit, max_limit))

    try:
        raw_offset = query_params.get("offset", "0")
        offset = int(str(raw_offset))
    except (ValueError, TypeError, AttributeError):
        offset = 0
    offset = max(0, offset)

    return Pagination(limit, offset)


def ok_response(
    data: dict[str, Any] | None = None,
    message: str = "ok",
    status_code: int = 200,
) -> Response[dict[str, Any]]:
    """Standard success response.

    Args:
        data: Optional data dict (merged into response).
        message: Success message.
        status_code: HTTP status code.

    Returns:
        Litestar Response with status and optional data.
    """
    body: dict[str, Any] = {"status": "ok", "message": message}
    if data:
        body.update(data)
    return Response(content=body, status_code=status_code)


def paginated_response(
    items: list[dict[str, Any]],
    total: int,
    pagination: Pagination,
) -> dict[str, Any]:
    """Standard paginated response body."""
    return {
        "items": items,
        "total": total,
        "limit": pagination.limit,
        "offset": pagination.offset,
        "page": pagination.page,
    }


def parse_bool_filter(raw: str | None) -> bool | None:
    """Parse a boolean query parameter (None, 'true'/'1', 'false'/'0')."""
    if raw is None:
        return None
    return raw.lower() in ("true", "1", "yes")
