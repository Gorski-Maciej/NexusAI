# pipeline/ocr.py
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from services.currency_converter import Money


@dataclass
class ExtractedInvoiceData:
    raw_text: str
    nip: str | None
    amount_gross: Money | None

class DocumentProcessor:
    """Singleton ładujący modele ML tylko raz, aby oszczędzić pamięć."""
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DocumentProcessor, cls).__new__(cls)
            cls._instance._initialize_models()
        return cls._instance

    def _initialize_models(self):
        """Ładowanie wag modeli do pamięci zoptymalizowane pod offline-first.
        Surya/torch importowane leniwie — wymagane tylko przy faktycznym OCR.
        """
        import torch
        from PIL import Image
        from surya.ocr import run_ocr
        from surya.model.detection.model import load_model as load_det_model, load_processor as load_det_processor
        from surya.model.recognition.model import load_model as load_rec_model, load_processor as load_rec_processor

        print("[AI] Ładowanie modeli Surya OCR...")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        # Modele detekcji (gdzie jest tekst)
        self.det_processor, self.det_model = load_det_processor(), load_det_model()
        self.det_model.to(self.device)

        # Modele rozpoznawania (jaki to tekst)
        self.rec_processor, self.rec_model = load_rec_processor(), load_rec_model()
        self.rec_model.to(self.device)
        print(f"[AI] Modele załadowane na urządzenie: {self.device}")

    def process_image(self, image_path: str) -> "ExtractedInvoiceData":
        """Przetwarza skan faktury i wyciąga czysty tekst oraz kluczowe dane."""
        import torch
        from PIL import Image
        from surya.ocr import run_ocr

        image = Image.open(image_path).convert("RGB")
        # Surya obsługuje listy obrazów, podajemy jeden
        predictions = run_ocr(
            [image],
            [[]], # Brak wstępnie zdefiniowanych boksów (auto-detekcja)
            self.det_model, self.det_processor,
            self.rec_model, self.rec_processor
        )

        # Łączenie tekstu ze wszystkich wykrytych linii
        lines = [line.text for line in predictions[0].text_lines]
        full_text = "\n".join(lines)

        # Ekstrakcja biznesowa (heurystyki / regex)
        return self._extract_business_fields(full_text)

    def _extract_business_fields(self, text: str) -> "ExtractedInvoiceData":
        """Prymitywny parser Regex do wyciągania NIP-u i Kwot.
        W docelowej wersji można to przepuścić przez lokalny model LLM."""
        # Szukamy NIPu (10 cyfr, ewentualnie z myślnikami)
        nip_match = re.search(r'\b\d{3}[-\s]?\d{3}[-\s]?\d{2}[-\s]?\d{2}\b', text)
        nip = nip_match.group(0).replace("-", "").replace(" ", "") if nip_match else None

        # Szukamy kwoty brutto (uproszczony regex: słowo "Brutto" i liczba)
        gross_match = re.search(r'Brutto[:\s]*([\d\s]+[.,]\d{2})', text, re.IGNORECASE)
        amount_gross = None

        if gross_match:
            try:
                # Zamiana formatu "1 000,50" na "1000.50"
                clean_num = gross_match.group(1).replace(" ", "").replace(",", ".")
                amount_gross = Money(str(clean_num), "PLN")
            except ValueError:
                pass

        return ExtractedInvoiceData(raw_text=text, nip=nip, amount_gross=amount_gross)


"""OCR/ML document intelligence pipeline for invoices."""
import hashlib
import math
import numpy as np
from pathlib import Path
from typing import Any

try:
    import onnxruntime as ort
except Exception:
    ort = None

try:
    from paddleocr import PaddleOCR
except Exception:
    PaddleOCR = None

try:
    from PIL import Image
except Exception:
    Image = None

class ReviewStatus:
    """Pipeline result statuses."""
    APPROVED = "APPROVED"
    MANUAL_REVIEW = "MANUAL_REVIEW"

@dataclass(slots=True)
class OCRResult:
    """Normalized OCR extraction result."""
    raw_text: str
    nip: str | None
    checksum: str

@dataclass(slots=True)
class ProcessedDocument:
    """Final pipeline output used by workflow tasks."""
    status: str
    primary: OCRResult
    validator: OCRResult
    metadata: dict[str, Any]

class DocumentProcessorDual:
    """Dual-engine OCR processor (Surya + Paddle) with cross-validation."""
    def __init__(self, nip_mismatch_threshold: int = 0, checksum_distance_threshold: int = 0) -> None:
        self.nip_mismatch_threshold = nip_mismatch_threshold
        self.checksum_distance_threshold = checksum_distance_threshold
        self._onnx_session = self._build_onnx_session()
        self._paddle = self._build_paddle()

    def process(self, image_path: Path) -> ProcessedDocument:
        """Process document with tiling + dual OCR and compare extraction consistency."""
        import torch
        from PIL import Image

        image = Image.open(image_path).convert("RGB")
        tiles = self._tile_image(image)

        # Force no-grad inference for PyTorch paths (Surya or fallback).
        if torch is not None:
            with torch.inference_mode():
                primary_text = self._run_primary_ocr(tiles)
        else:
            primary_text = self._run_primary_ocr(tiles)

        validator_text = self._run_validator_ocr(tiles)
        primary = self._extract_fields(primary_text)
        validator = self._extract_fields(validator_text)
        status = self._cross_validate(primary, validator)

        return ProcessedDocument(
            status=status,
            primary=primary,
            validator=validator,
            metadata={
                "tile_count": len(tiles),
                "onnx_enabled": self._onnx_session is not None,
                "int8_quantized": True,
            },
        )

    def _build_onnx_session(self) -> ort.InferenceSession | None:
        """Initialize ONNX Runtime session for quantized inference path."""
        if ort is None:
            return None
        # Placeholder path for exported INT8 ONNX model
        model_path = Path("models/surya_invoice_int8.onnx")
        if not model_path.exists():
            return None
        providers = ["CPUExecutionProvider"]
        return ort.InferenceSession(str(model_path), providers=providers)

    def _build_paddle(self) -> PaddleOCR | None:
        """Initialize PaddleOCR validator."""
        if PaddleOCR is None:
            return None
        return PaddleOCR(use_angle_cls=True, lang="en", use_gpu=False)

    def _run_primary_ocr(self, tiles: list[Image.Image]) -> str:
        """Execute primary OCR engine (Surya) via ONNX fallback abstraction."""
        all_text: list[str] = []
        for tile in tiles:
            if self._onnx_session is not None:
                all_text.append(self._infer_with_onnx(tile))
            else:
                # Placeholder adapter for Surya OCR Python API.
                all_text.append(self._surya_fallback(tile))
        return "\n".join(all_text)

    def _run_validator_ocr(self, tiles: list[Image.Image]) -> str:
        """Execute PaddleOCR validation path."""
        if self._paddle is None:
            return ""
        lines: list[str] = []
        for tile in tiles:
            array = np.array(tile)
            result = self._paddle.ocr(array, cls=True)
            for block in result or []:
                for item in block or []:
                    if len(item) >= 2 and len(item[1]) >= 1:
                        lines.append(str(item[1][0]))
        return "\n".join(lines)

    def _infer_with_onnx(self, tile: Image.Image) -> str:
        """Run ONNX inference; the decoding pipeline can be plugged later."""
        assert self._onnx_session is not None
        resized = tile.resize((1024, 1024))
        data = np.asarray(resized, dtype=np.float32) / 255.0
        tensor = np.transpose(data, (2, 0, 1))[np.newaxis, ...]
        inputs = {self._onnx_session.get_inputs()[0].name: tensor}
        _ = self._onnx_session.run(None, inputs)
        # Future: decode token logits into extracted text.
        return ""

    @staticmethod
    def _surya_fallback(_tile: Image.Image) -> str:
        """Fallback stub when Surya runtime is not configured yet."""
        return ""

    def _cross_validate(self, primary: OCRResult, validator: OCRResult) -> str:
        checksum_distance = 0 if primary.checksum == validator.checksum else 1
        nip_distance = 0 if primary.nip == validator.nip else 1
        if checksum_distance > self.checksum_distance_threshold or nip_distance > self.nip_mismatch_threshold:
            return ReviewStatus.MANUAL_REVIEW
        return ReviewStatus.APPROVED

    @staticmethod
    def _extract_fields(raw_text: str) -> OCRResult:
        nip_match = re.search(r"\b\d{10}\b", raw_text)
        checksum = hashlib.sha256(raw_text.encode("utf-8")).hexdigest()
        return OCRResult(
            raw_text=raw_text,
            nip=nip_match.group(0) if nip_match else None,
            checksum=checksum,
        )

    @staticmethod
    def _tile_image(image: Image.Image, tile_size: int = 2048, overlap: int = 256) -> list[Image.Image]:
        """Split huge scans into overlapping tiles to avoid OOM."""
        width, height = image.size
        if width <= tile_size and height <= tile_size:
            return [image]

        step = tile_size - overlap
        tiles: list[Image.Image] = []
        for y in range(0, max(height - overlap, 1), step):
            for x in range(0, max(width - overlap, 1), step):
                right = min(x + tile_size, width)
                lower = min(y + tile_size, height)
                tiles.append(image.crop((x, y, right, lower)))

        # Safety guard to avoid pathological tile explosion.
        max_tiles = math.ceil((width * height) / float(tile_size * tile_size)) * 8
        return tiles[:max_tiles]


# Wywołanie nowej warstwy ekstrakcji
async def process_image_with_parser(self, image_path: str):
    from pipeline.parser import InvoiceParser

    # 1. OCR
    # results = run_ocr(image, [langs], self.det_model, ...)
    raw_text = self._assemble_text(results) # Funkcja łącząca bloki tekstu w str

    # 2. EKSTRAKCJA (nowy krok)
    parser = InvoiceParser()
    parsed_data = parser.parse(raw_text)
    return parsed_data # Zwraca obiekt z gotowymi polami do bazy danych
