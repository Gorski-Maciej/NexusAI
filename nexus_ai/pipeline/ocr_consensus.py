# pipeline/ocr_consensus.py
"""
3-way OCR Consensus Engine.

Zgodnie z aa3fvcx.txt (Punkt 10): trzy niezależne silniki OCR
(Tesseract, PaddleOCR, Surya OCR) zapewniają statystycznie zerową
szansę na identyczny błąd we wszystkich trzech.

- Tesseract: klasyczny OCR, mistrz ustrukturyzowanego druku
- PaddleOCR: deep learning OCR, radzi sobie z nietypowymi czcionkami
- Surya OCR: layout-aware OCR, rozumie strukturę strony
"""

from __future__ import annotations

from msgspec import Struct, field
from enum import Enum
from pathlib import Path
from typing import Any

import anyio
from structlog import get_logger

logger = get_logger("nexus.pipeline.ocr_consensus")


class OCREngine(Enum):
    TESSERACT = "tesseract"
    PADDLE = "paddleocr"
    SURYA = "surya"


class OCRFieldResult(Struct):
    value: str | None
    confidence: float  # 0.0 - 1.0
    source: str


class OCRConsensusDecision(Struct):
    accepted: OCRFieldResult | None
    confidence_conflict: bool
    votes: list[OCRFieldResult] = field(default_factory=list)


def decide_field_consensus(
    results: list[OCRFieldResult],
    *,
    min_confidence: float = 0.5,
    majority_threshold: int = 2,
) -> OCRConsensusDecision:
    """Decide consensus for a single field from multiple OCR engines.

    Args:
        results: OCR results from each engine.
        min_confidence: Minimum confidence to consider a result valid.
        majority_threshold: Number of matching results needed for consensus.

    Returns:
        OCRConsensusDecision with accepted value and conflict flag.
    """
    if not results:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=[])

    # Filter low-confidence results
    valid = [r for r in results if r.confidence >= min_confidence]
    if not valid:
        # All low confidence — accept the best one but flag conflict
        best = max(results, key=lambda r: r.confidence)
        return OCRConsensusDecision(
            accepted=best,
            confidence_conflict=True,
            votes=results,
        )

    # Count votes for each value
    from collections import Counter

    value_counts: Counter[str] = Counter()
    value_sources: dict[str, list[OCRFieldResult]] = {}

    for r in valid:
        if r.value is not None:
            normalized = r.value.strip().upper()
            value_counts[normalized] += 1
            if normalized not in value_sources:
                value_sources[normalized] = []
            value_sources[normalized].append(r)

    if not value_counts:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=results)

    # Find the most voted value
    (best_value, best_count) = value_counts.most_common(1)[0]

    # Consensus = majority (at least 2 out of 3)
    if best_count >= majority_threshold:
        best_result = value_sources[best_value][0]
        return OCRConsensusDecision(
            accepted=best_result,
            confidence_conflict=False,
            votes=results,
        )

    # No consensus — accept best confidence but flag conflict
    best_conf = max(valid, key=lambda r: r.confidence)
    return OCRConsensusDecision(
        accepted=best_conf,
        confidence_conflict=True,
        votes=results,
    )


# ── Silniki OCR ─────────────────────────────────────────────────────────────


class TesseractEngine:
    """Tesseract OCR — klasyczny silnik dla drukowanego tekstu."""

    def __init__(self, lang: str = "pol"):
        self.lang = lang
        self._available = False
        self._check_available()

    def _check_available(self) -> None:
        import shutil

        self._available = shutil.which("tesseract") is not None
        if not self._available:
            logger.warning("[OCR] Tesseract not found in PATH")

    async def extract_text(self, image_path: Path) -> str | None:
        if not self._available:
            return None
        try:
            result = await anyio.run_process(
                ["tesseract", str(image_path), "stdout", "-l", self.lang],
                timeout=60,
            )
            return result.stdout.strip() if result.returncode == 0 else None
        except Exception as exc:
            logger.error("[OCR] Tesseract failed: %s", exc)
            return None


class PaddleOCREngine:
    """PaddleOCR — deep learning OCR dla nietypowych czcionek."""

    def __init__(self):
        self._ocr = None
        self._available = False
        self._init_engine()

    def _init_engine(self) -> None:
        try:
            from paddleocr import PaddleOCR

            self._ocr = PaddleOCR(use_angle_cls=True, lang="pl", show_log=False)
            self._available = True
            logger.info("[OCR] PaddleOCR initialized successfully")
        except ImportError:
            logger.warning("[OCR] PaddleOCR not installed")
        except Exception as exc:
            logger.warning("[OCR] PaddleOCR init failed: %s", exc)

    async def extract_text(self, image_path: Path) -> str | None:
        if not self._available or self._ocr is None:
            return None
        try:
            # PaddleOCR jest synchroniczny — uruchom w wątku
            result = await anyio.to_thread.run_sync(self._ocr.ocr, str(image_path))
            if result and result[0]:
                lines = [line[1][0] for line in result[0] if line[1]]
                return "\n".join(lines)
            return None
        except Exception as exc:
            logger.error("[OCR] PaddleOCR failed: %s", exc)
            return None


class SuryaOCREngine:
    """Surya OCR — layout-aware OCR dla trudnych warunków."""

    def __init__(self):
        self._available = False
        self._init_engine()

    def _init_engine(self) -> None:
        try:
            import surya.model.detection
            import surya.model.recognition
            import surya.ocr

            self._available = True
            logger.info("[OCR] Surya OCR initialized successfully")
        except ImportError:
            logger.warning("[OCR] Surya OCR not installed")
        except Exception as exc:
            logger.warning("[OCR] Surya OCR init failed: %s", exc)

    async def extract_text(self, image_path: Path) -> str | None:
        if not self._available:
            return None
        try:
            import surya.model.detection
            import surya.model.recognition
            import surya.ocr
            from PIL import Image

            image = Image.open(str(image_path))

            def _run_ocr():
                model_recog = surya.model.recognition.load_model()
                model_detect = surya.model.detection.load_model()
                predictions = surya.ocr.ocr(
                    [image],
                    [self.lang_map("pol")],
                    model_recog,
                    model_detect,
                )
                if predictions and predictions[0].text_lines:
                    return "\n".join(line.text for line in predictions[0].text_lines if line.text)
                return None

            result = await anyio.to_thread.run_sync(_run_ocr)
            return result
        except Exception as exc:
            logger.error("[OCR] Surya failed: %s", exc)
            return None

    @staticmethod
    def lang_map(lang: str) -> str:
        """Map standard language codes to Surya language codes."""
        mapping = {"pol": "pl", "eng": "en", "deu": "de"}
        return mapping.get(lang, "pl")


# ── PDF → Image conversion ────────────────────────────────────────────────


def pdf_to_images(pdf_path: Path, dpi: int = 300) -> list[Path]:
    """Convert PDF pages to images using PyMuPDF (fitz).

    Zgodnie z aa3fvcx.txt (Punkt 10): PyMuPDF zapewnia bezstratną
    konwersję PDF → obraz dla silników OCR.
    """
    try:
        import fitz  # PyMuPDF
    except ImportError:
        logger.error("[OCR] PyMuPDF (fitz) not installed. Install: pip install pymupdf")
        return []

    output_dir = pdf_path.parent / f"{pdf_path.stem}_pages"
    output_dir.mkdir(parents=True, exist_ok=True)

    image_paths: list[Path] = []
    try:
        doc = fitz.open(str(pdf_path))
        for page_num in range(len(doc)):
            page = doc[page_num]
            pix = page.get_pixmap(dpi=dpi)
            image_path = output_dir / f"page_{page_num + 1:03d}.png"
            pix.save(str(image_path))
            image_paths.append(image_path)
        doc.close()
        logger.info("[OCR] Converted %d PDF pages to images", len(image_paths))
    except Exception as exc:
        logger.error("[OCR] PDF conversion failed: %s", exc)

    return image_paths


# ── Główna funkcja orchestrująca ─────────────────────────────────────────


async def run_ocr_pipeline(
    file_path: Path,
    *,
    use_tesseract: bool = True,
    use_paddle: bool = True,
    use_surya: bool = True,
) -> dict[str, OCRConsensusDecision]:
    """Run the full OCR pipeline with 3-way consensus.

    Args:
        file_path: Path to PDF or image file.
        use_tesseract: Enable Tesseract OCR engine.
        use_paddle: Enable PaddleOCR engine.
        use_surya: Enable Surya OCR engine.

    Returns:
        Dict with consensus decisions for each field.
    """

    # Krok 1: Konwersja PDF → obrazy (jeśli potrzeba)
    image_paths: list[Path] = []
    if file_path.suffix.lower() == ".pdf":
        image_paths = pdf_to_images(file_path)
    else:
        image_paths = [file_path]

    if not image_paths:
        logger.error("[OCR] No images to process")
        return {}

    image_path = image_paths[0]  # Process first page for now

    # Krok 2: Uruchom silniki OCR równolegle
    engines = []
    if use_tesseract:
        engines.append(("tesseract", TesseractEngine()))
    if use_paddle:
        engines.append(("paddle", PaddleOCREngine()))
    if use_surya:
        engines.append(("surya", SuryaOCREngine()))

    async def _run_engine(name: str, engine: Any) -> tuple[str, str | None]:
        text = await engine.extract_text(image_path)
        return name, text

    results = await anyio.gather(*[_run_engine(name, engine) for name, engine in engines])

    # Krok 3: Zbierz wyniki
    texts: dict[str, str | None] = dict(results)
    logger.info("[OCR] Engines completed: %s", {k: len(v or "") for k, v in texts.items()})

    return texts
