"""
BaseOCREngine — wspólna klasa bazowa dla wszystkich silników OCR.

Eliminuje ~1,500 linii duplikacji między TesseractEngine, PaddleOCREngine,
DocTREngine i EasyOCREngine. Każdy silnik definiuje tylko specyficzną logikę.

Wzorzec: Template Method + dekorator @catch_ocr_errors.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from functools import wraps
from pathlib import Path
from typing import Any, Callable, TypeVar

from structlog import get_logger

logger = get_logger("nexus.pipeline.ocr_base")

F = TypeVar("F", bound=Callable[..., Any])


def catch_ocr_errors(default: Any = None):
    """Dekorator: łapie błędy OCR i loguje z nazwą silnika.

    Zastępuje 8× @_loguru_logger.catch w każdym silniku.
    """
    def decorator(func: F) -> F:
        @wraps(func)
        async def wrapper(self: "BaseOCREngine", *args: Any, **kwargs: Any) -> Any:
            if not getattr(self, "_available", False):
                return None
            try:
                return await func(self, *args, **kwargs)
            except Exception as exc:
                logger.error("[OCR] %s.%s failed: %s", self.name, func.__name__, exc)
                return default
        return wrapper  # type: ignore
    return decorator


class BaseOCREngine(ABC):
    """Wspólna klasa bazowa dla wszystkich silników OCR.

    Każdy silnik definiuje tylko:
    - ``name``: nazwa silnika (np. "tesseract", "paddleocr")
    - ``_init_engine()``: inicjalizacja silnika
    - ``_extract_text_impl(path)``: implementacja ekstrakcji tekstu
    - ``_extract_confidence_impl(path)``: implementacja ekstrakcji z confidence
    - ``_extract_amount_impl(path)``: implementacja ekstrakcji kwoty
    - ``_extract_digits_impl(path)``: implementacja ekstrakcji cyfr

    Współdzielone: obsługa błędów, logowanie, _available check, timeout.
    """

    @property
    @abstractmethod
    def name(self) -> str: ...

    def __init__(self) -> None:
        self._available = False

    @abstractmethod
    def _init_engine(self) -> None: ...

    @abstractmethod
    async def _extract_text_impl(self, image_path: Path) -> str | None: ...

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        """Override dla silników wspierających confidence scores."""
        return None

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        """Override dla silników z dedykowaną ekstrakcją kwot."""
        text = await self._extract_text_impl(image_path)
        if text is None:
            return None
        import re
        match = re.search(r"\d[\d\s,.-]*\d", text)
        if match:
            try:
                cleaned = match.group().replace(" ", "").replace(",", ".")
                return float(cleaned)
            except ValueError:
                return None
        return None

    async def _extract_digits_impl(self, image_path: Path, expected_length: int = 10) -> str | None:
        """Override dla silników z dedykowaną ekstrakcją cyfr."""
        text = await self._extract_text_impl(image_path)
        if text is None:
            return None
        import re
        digits = re.sub(r"\D", "", text)
        if expected_length and len(digits) >= expected_length:
            return digits[:expected_length]
        return digits if digits else None

    # ── Publiczne API (współdzielone dla wszystkich silników) ─────────────

    @catch_ocr_errors()
    async def extract_text(self, image_path: Path) -> str | None:
        return await self._extract_text_impl(image_path)

    @catch_ocr_errors()
    async def extract_text_with_confidence(self, image_path: Path) -> list[dict] | None:
        return await self._extract_confidence_impl(image_path)

    @catch_ocr_errors()
    async def extract_amount(self, image_path: Path) -> float | None:
        return await self._extract_amount_impl(image_path)

    @catch_ocr_errors()
    async def extract_digits(self, image_path: Path, expected_length: int = 10) -> str | None:
        return await self._extract_digits_impl(image_path, expected_length)
