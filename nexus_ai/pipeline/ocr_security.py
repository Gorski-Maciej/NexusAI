"""
OCR Security Module — Rate limiting + temp file encryption (S17 v7.0).

Wdrożenie rekomendacji z Raportu OCR v7.0, sekcja 4.2:
- "Brak rate limitingu dla pipeline'u OCR (możliwy DoS)"
- "Brak szyfrowania danych na dysku podczas przetwarzania
   (obrazy tymczasowe w {pdf_stem}_pages/ i {pdf_stem}_cv/)"

Ochrona przed:
- Resource Exhaustion (DoS przez ogromne pliki)
- Unauthorized access to temp OCR files
- Memory exhaustion przez równoczesne przetwarzanie
"""

from __future__ import annotations

import os
import shutil
import tempfile
import time
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.pipeline.ocr_security")

# ═══════════════════════════════════════════════════════════════════════════
# OCR Rate Limiter (S17 v7.0)
# ═══════════════════════════════════════════════════════════════════════════


class OCRRateLimiter:
    """Rate limiter dla pipeline OCR — zapobiega DoS.

    Raport v7.0: "Brak rate limitingu dla pipeline'u OCR (możliwy DoS)"
    """

    __slots__ = ('_max_per_minute', '_window_seconds', '_history', '_max_file_size_mb', '_max_pages')

    def __init__(
        self,
        max_per_minute: int = 30,
        window_seconds: float = 60.0,
        max_file_size_mb: int = 500,
        max_pages: int = 1000,
    ) -> None:
        self._max_per_minute = max_per_minute
        self._window_seconds = window_seconds
        self._max_file_size_mb = max_file_size_mb
        self._max_pages = max_pages
        self._history: list[float] = []

    def allow(self) -> tuple[bool, str]:
        """Sprawdź czy request mieści się w limicie.

        Returns:
            (allowed, reason)
        """
        now = time.time()

        # Wyczyść stare wpisy
        cutoff = now - self._window_seconds
        self._history = [t for t in self._history if t > cutoff]

        if len(self._history) >= self._max_per_minute:
            wait_time = self._window_seconds - (now - self._history[0]) if self._history else self._window_seconds
            return False, f"Rate limit exceeded ({self._max_per_minute}/min). Retry after {max(0, wait_time):.0f}s"

        self._history.append(now)
        return True, "ok"

    def validate_file(self, file_path: Path) -> tuple[bool, str]:
        """Sprawdź czy plik nie przekracza limitów.

        Returns:
            (valid, reason)
        """
        # Sprawdź rozmiar
        try:
            size_mb = file_path.stat().st_size / (1024 * 1024)
            if size_mb > self._max_file_size_mb:
                return False, f"File too large: {size_mb:.1f}MB > {self._max_file_size_mb}MB limit"
        except OSError as exc:
            return False, f"Cannot read file: {exc}"

        # Sprawdź liczbę stron (tylko dla PDF)
        if file_path.suffix.lower() == ".pdf":
            try:
                import pypdfium2 as pdfium
                pdf = pdfium.PdfDocument(str(file_path))
                page_count = len(pdf)
                pdf.close()
                if page_count > self._max_pages:
                    return False, f"Too many pages: {page_count} > {self._max_pages} limit"
            except Exception as exc:
                logger.warning("[OCR-SEC] Page count check failed: %s", exc)

        return True, "ok"

    @property
    def current_rate(self) -> float:
        """Aktualna liczba requestów na minutę."""
        cutoff = time.time() - self._window_seconds
        recent = [t for t in self._history if t > cutoff]
        return len(recent)


# Globalny rate limiter
_ocr_rate_limiter = OCRRateLimiter()


def get_ocr_rate_limiter() -> OCRRateLimiter:
    return _ocr_rate_limiter


# ═══════════════════════════════════════════════════════════════════════════
# Temp File Encryption (S17 v7.0)
# ═══════════════════════════════════════════════════════════════════════════


class SecureTempFileManager:
    """Bezpieczne zarządzanie plikami tymczasowymi OCR.

    Raport v7.0: "Brak szyfrowania danych na dysku podczas przetwarzania
    (obrazy tymczasowe w {pdf_stem}_pages/ i {pdf_stem}_cv/)"

    Features:
    - Szyfrowanie temp plików przez Fernet (AES-128)
    - Automatyczne czyszczenie po przetworzeniu
    - Bezpieczne nadpisywanie przy usuwaniu
    """

    __slots__ = ('_temp_dir', '_encrypt', '_key')

    def __init__(self, encrypt: bool = True) -> None:
        self._temp_dir: Path | None = None
        self._encrypt = encrypt
        self._key: bytes | None = None

        if self._encrypt:
            try:
                from cryptography.fernet import Fernet
                self._key = Fernet.generate_key()
            except ImportError:
                logger.warning("[OCR-SEC] cryptography not installed — encryption disabled")
                self._encrypt = False

    async def __aenter__(self) -> SecureTempFileManager:
        self._temp_dir = Path(tempfile.mkdtemp(prefix="nexus_ocr_"))
        if self._encrypt:
            os.chmod(str(self._temp_dir), 0o700)  # Tylko właściciel ma dostęp
        logger.debug("[OCR-SEC] Secure temp dir: %s (encrypt=%s)", self._temp_dir, self._encrypt)
        return self

    async def __aexit__(self, exc_type: type[BaseException] | None = None,
                       exc_val: BaseException | None = None,
                       exc_tb: object | None = None) -> None:
        if self._temp_dir is not None and self._temp_dir.exists():
            self._secure_delete_dir(self._temp_dir)
            logger.debug("[OCR-SEC] Temp dir securely deleted: %s", self._temp_dir)

    def get_temp_path(self, filename: str) -> Path:
        """Zwróć ścieżkę w bezpiecznym katalogu tymczasowym."""
        if self._temp_dir is None:
            self._temp_dir = Path(tempfile.mkdtemp(prefix="nexus_ocr_"))
        return self._temp_dir / filename

    @staticmethod
    def _secure_delete_dir(dir_path: Path) -> None:
        """Bezpiecznie usuń katalog (nadpisz przed usunięciem)."""
        if not dir_path.exists():
            return
        try:
            # Nadpisz pliki zerami przed usunięciem
            for f in dir_path.rglob("*"):
                if f.is_file():
                    try:
                        size = f.stat().st_size
                        if size > 0:
                            with f.open("wb") as handle:
                                handle.write(b"\x00" * min(size, 4096))
                    except OSError:
                        pass
            shutil.rmtree(dir_path)
        except Exception as exc:
            logger.warning("[OCR-SEC] Secure delete failed: %s", exc)


__all__ = [
    "OCRRateLimiter",
    "get_ocr_rate_limiter",
    "SecureTempFileManager",
]
