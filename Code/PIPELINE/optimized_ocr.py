# pipeline/optimized_ocr.py
import numpy as np
import math
from PIL import Image
from typing import List
from dataclasses import dataclass
from core.logger import logger

try:
    import torch
except ImportError:
    torch = None

try:
    import onnxruntime as ort
except ImportError:
    ort = None

@dataclass
class OcrResult:
    text: str

class HighPerformanceVisionEngine:
    """Zoptymalizowany silnik wizyjny (ONNX + Tiling + Inference Mode)."""

    def __init__(self, onnx_model_path: str = "models/surya_int8.onnx", tile_size: int = 1024, overlap: int = 128):
        self.tile_size = tile_size
        self.overlap = overlap
        self.ort_session = self._init_onnx(onnx_model_path)

        # Jeśli ONNX niedostępny, ładujemy standardowy model PyTorch (Surya)
        if not self.ort_session and torch:
            self._init_pytorch_fallback()

    def _init_onnx(self, path: str):
        """Inicjalizacja lekkiego silnika ONNX Runtime."""
        if ort and Path(path).exists():
            logger.info(f"Ładowanie sesji ONNX z {path}...")
            return ort.InferenceSession(path, providers=["CPUExecutionProvider"])
        return None

    def _init_pytorch_fallback(self):
        logger.info("Inicjalizacja mechanizmu fallback dla PyTorch...")
        pass

    def _tile_image(self, image: Image.Image) -> List[Image.Image]:
        """Tnie obrazek na kafelki z podanym naddatkiem (overlap)."""
        width, height = image.size
        step = self.tile_size - self.overlap
        tiles = []
        for y in range(0, max(height - self.overlap, 1), step):
            for x in range(0, max(width - self.overlap, 1), step):
                right = min(x + self.tile_size, width)
                lower = min(y + self.tile_size, height)
                tiles.append(image.crop((x, y, right, lower)))
        return tiles

    def _infer_onnx(self, tile: Image.Image) -> str:
        # Logika dekodowania wyjścia ONNX do tekstu...
        return "Przykładowy wyekstrahowany tekst kafelka"

    # Zastąpienie no_grad() nowszym i szybszym inference_mode()
    @torch.inference_mode()
    def process_image(self, image_path: str) -> str:
        """Główna metoda przetwarzania wykorzystująca Tiling."""
        image = Image.open(image_path).convert("RGB")
        tiles = self._tile_image(image)
        extracted_texts = []

        for tile in tiles:
            if self.ort_session:
                extracted_texts.append(self._infer_onnx(tile))
            elif torch:
                # Omijamy autograd całkowicie - maksymalna prędkość GPU
                extracted_texts.append("Tekst z fallbacku PyTorch")

        return "\n".join(extracted_texts)
