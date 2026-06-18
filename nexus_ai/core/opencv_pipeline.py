"""
opencv_pipeline.py -- SUPERMOCE OpenCV do zaawansowanego preprocessingu obrazów.

Zgodnie z audytem technologicznym OpenCV (Faza 1-3):
- Deskew (Hough Lines + rotation)
- CLAHE + Adaptive threshold
- Denoising (NLM - Non-Local Means)
- Morphological operations
- Line removal (tabele)
- Stamp/Seal removal (inpainting)
- Auto-crop do konturu dokumentu
- Super-resolution (ESPCN przez DNN)
- Auto-detect OCR mode (digits vs text vs mixed)
- Page orientation detection
"""

from __future__ import annotations

import io
from pathlib import Path
from typing import Any

import fsspec
from msgspec import Struct
from structlog import get_logger

logger = get_logger("nexus.core.opencv_pipeline")

# ── OpenCV availability check ──────────────────────────────────────────────

try:
    import cv2
    import numpy as np

    HAS_CV2 = True
    CV2_VERSION = cv2.__version__
except ImportError:
    HAS_CV2 = False
    cv2 = None  # type: ignore
    np = None  # type: ignore
    CV2_VERSION = ""


# ── Configuration ──────────────────────────────────────────────────────────


class OpenCVPreprocessingConfig(Struct, kw_only=True):
    """SUPERMOC: Konfiguracja wszystkich supermocy OpenCV preprocessing pipeline.

    Każda operacja jest opcjonalna i konfigurowalna per-dokument.
    Domyślne wartości są zoptymalizowane dla faktur/faktur.
    """

    # ── Deskew ──
    deskew: bool = True
    deskew_min_line_length: int = 100
    deskew_max_angle: float = 45.0

    # ── Denoising ──
    denoise: bool = True
    denoise_h: float = 10.0  # Filter strength (NLM)

    # ── CLAHE ──
    clahe: bool = True
    clahe_clip_limit: float = 3.0
    clahe_tile_grid_size: int = 8

    # ── Adaptive Threshold ──
    adaptive_threshold: bool = True
    adaptive_block_size: int = 31
    adaptive_c: float = 2.0

    # ── Morphology ──
    morphology: bool = True
    morphology_kernel_size: int = 3
    morphology_operation: str = "close"  # close, open, dilate, erode

    # ── Sharpen ──
    sharpen: bool = True
    sharpen_strength: float = 1.0  # 1.0 = standard, >1 = stronger

    # ── Line Removal (tabele) ──
    remove_lines: bool = False
    line_horizontal_length: int = 40
    line_vertical_length: int = 40

    # ── Stamp Removal (pieczątki) ──
    remove_stamps: bool = False
    stamp_min_area: int = 500
    stamp_max_area: int = 50000

    # ── Auto-crop ──
    auto_crop: bool = True
    crop_margin: int = 10

    # ── Super-Resolution ──
    super_resolution: bool = False
    sr_model_path: str | None = None  # Path to ESPCN/Tensorflow model

    # ── Orientation Detection ──
    auto_rotate: bool = True

    # ── OCR Mode ──
    ocr_mode: str = "auto"  # auto, text, digits, amounts, mixed


class OpenCVPreprocessor:
    """SUPERMOC: Kompletny preprocessing OpenCV dla OCR.

    Wykorzystuje OpenCV do zaawansowanych operacji na obrazach,
    z pełnym fallbackiem gdy OpenCV nie jest dostępne.

    Użycie:
        preprocessor = OpenCVPreprocessor()
        processed = preprocessor.process(pil_image)
        # lub z własną konfiguracją
        preprocessor = OpenCVPreprocessor(OpenCVPreprocessingConfig(deskew=True, denoise=True))
    """

    def __init__(
        self, config: OpenCVPreprocessingConfig | None = None
    ) -> None:
        self.config = config or OpenCVPreprocessingConfig()
        self._available = HAS_CV2

        if self._available:
            logger.info(
                "[OpenCV] Preprocessor initialized (cv2=%s, config=%s)",
                CV2_VERSION,
                self.config,
            )
        else:
            logger.warning(
                "[OpenCV] cv2 not available — preprocessing disabled. "
                "Install: pip install opencv-python-headless"
            )

    # ══════════════════════════════════════════════════════════════════════
    # Główna metoda — kompletny pipeline
    # ══════════════════════════════════════════════════════════════════════

    def process(self, image: Any) -> Any:
        """SUPERMOC: Kompletny pipeline przetwarzania obrazu przez OpenCV.

        Kolejność operacji (optymalna dla OCR):
        1. Auto-rotate (orientation detection)
        2. Deskew (Hough Lines)
        3. Auto-crop (największy kontur)
        4. Denoising (NLM)
        5. CLAHE (lokalny kontrast)
        6. Adaptive threshold (binaryzacja)
        7. Morphology (czyszczenie)
        8. Line removal (opcjonalnie)
        9. Stamp removal (opcjonalnie)
        10. Sharpen (wyostrzenie)
        11. Auto OCR mode detection

        Args:
            image: PIL Image lub numpy array.

        Returns:
            PIL Image (przetworzony) lub oryginał przy błędzie/braku OpenCV.
        """
        if not self._available:
            return image

        try:
            import cv2
            import numpy as np

            # Konwersja PIL → numpy jeśli potrzeba
            if hasattr(image, "convert"):
                arr = np.array(image.convert("RGB"))
                gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
            elif isinstance(image, np.ndarray):
                if image.ndim == 3:
                    gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
                else:
                    gray = image
                arr = image
            else:
                return image

            # 1. Auto-rotate (orientation)
            if self.config.auto_rotate:
                gray = self._detect_and_rotate(gray)

            # 2. Deskew
            if self.config.deskew:
                gray = self._deskew(gray)

            # 3. Auto-crop
            if self.config.auto_crop:
                gray = self._auto_crop(gray)

            # 4. Denoising
            if self.config.denoise:
                gray = cv2.fastNlMeansDenoising(
                    gray, h=self.config.denoise_h
                )

            # 5. CLAHE
            if self.config.clahe:
                clahe_obj = cv2.createCLAHE(
                    clipLimit=self.config.clahe_clip_limit,
                    tileGridSize=(
                        self.config.clahe_tile_grid_size,
                        self.config.clahe_tile_grid_size,
                    ),
                )
                gray = clahe_obj.apply(gray)

            # 6. Adaptive threshold
            if self.config.adaptive_threshold:
                binary = cv2.adaptiveThreshold(
                    gray,
                    255,
                    cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                    cv2.THRESH_BINARY,
                    self.config.adaptive_block_size,
                    self.config.adaptive_c,
                )
            else:
                binary = gray

            # 7. Morphology
            if self.config.morphology:
                kernel = cv2.getStructuringElement(
                    cv2.MORPH_RECT,
                    (self.config.morphology_kernel_size,) * 2,
                )
                op_map = {
                    "close": cv2.MORPH_CLOSE,
                    "open": cv2.MORPH_OPEN,
                    "dilate": cv2.MORPH_DILATE,
                    "erode": cv2.MORPH_ERODE,
                }
                morph_op = op_map.get(
                    self.config.morphology_operation, cv2.MORPH_CLOSE
                )
                binary = cv2.morphologyEx(binary, morph_op, kernel)

            # 8. Line removal
            if self.config.remove_lines:
                binary = self._remove_table_lines(binary)

            # 9. Stamp removal
            if self.config.remove_stamps:
                binary = self._remove_stamps(binary)

            # 10. Sharpen
            if self.config.sharpen:
                binary = self._sharpen(binary)

            # 11. Auto OCR mode detection
            if self.config.ocr_mode == "auto":
                detected_mode = self._detect_ocr_mode(binary)
                if detected_mode == "digits":
                    # Digits mode — dodatkowe wzmocnienie
                    _, binary = cv2.threshold(
                        binary, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
                    )

            from PIL import Image as PILImage

            return PILImage.fromarray(binary)

        except Exception as exc:
            logger.warning("[OpenCV] Processing failed, returning original: %s", exc)
            return image

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Deskew (korekcja przekrzywienia)
    # ══════════════════════════════════════════════════════════════════════

    def _deskew(self, gray: Any) -> Any:
        """SUPERMOC: Korekcja przekrzywienia dokumentu przez Hough Lines.

        1. Detekcja krawędzi Canny
        2. Hough Lines Probabilistic
        3. Obliczenie mediany kąta linii
        4. Rotacja przez warpAffine

        Returns:
            Wyprostowany obraz numpy array.
        """
        import cv2
        import numpy as np

        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLinesP(
            edges,
            1,
            np.pi / 180,
            100,
            minLineLength=self.config.deskew_min_line_length,
            maxLineGap=10,
        )
        if lines is None:
            return gray

        angles = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            angle = np.degrees(np.arctan2(y2 - y1, x2 - x1))
            if abs(angle) < self.config.deskew_max_angle:
                angles.append(angle)

        if not angles:
            return gray

        median_angle = float(np.median(angles))
        if abs(median_angle) < 0.5:
            return gray  # Skip if almost straight

        h, w = gray.shape
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
        rotated = cv2.warpAffine(
            gray,
            M,
            (w, h),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )
        logger.debug("[OpenCV] Deskew applied: angle=%.2f°", median_angle)
        return rotated

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Auto-crop (kadrowanie do konturu dokumentu)
    # ══════════════════════════════════════════════════════════════════════

    def _auto_crop(self, gray: Any) -> Any:
        """SUPERMOC: Automatyczne kadrowanie do największego konturu.

        1. Binaryzacja Otsu
        2. Znajdź kontury (RETR_EXTERNAL)
        3. Sortuj według pola
        4. Jeśli największy kontur > 30% obrazu, wytnij go

        Returns:
            Przycięty obraz numpy array.
        """
        import cv2
        import numpy as np

        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        contours, _ = cv2.findContours(
            binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        if not contours:
            return gray

        largest = max(contours, key=cv2.contourArea)
        h, w = gray.shape
        area_ratio = cv2.contourArea(largest) / (h * w)

        if area_ratio < 0.3:
            return gray  # Kontur za mały, ignoruj

        x, y, cw, ch = cv2.boundingRect(largest)
        margin = min(self.config.crop_margin, min(x, y, w - x - cw, h - y - ch))
        cropped = gray[
            max(0, y - margin) : min(h, y + ch + margin),
            max(0, x - margin) : min(w, x + cw + margin),
        ]
        logger.debug(
            "[OpenCV] Auto-crop: (x=%d, y=%d, w=%d, h=%d) → (%d, %d)",
            x, y, cw, ch, cropped.shape[1], cropped.shape[0],
        )
        return cropped

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Line removal (usuwanie linii tabel)
    # ══════════════════════════════════════════════════════════════════════

    def _remove_table_lines(self, binary: Any) -> Any:
        """SUPERMOC: Usuwanie linii tabel przez morph open + inpainting.

        1. Wykryj poziome linie (morph open z horyzontalnym kernelem)
        2. Wykryj pionowe linie (morph open z wertykalnym kernelem)
        3. Połącz maski
        4. Inpaint przez TELEA

        Returns:
            Obraz bez linii tabel.
        """
        import cv2
        import numpy as np

        # Horizontal lines
        h_kernel = cv2.getStructuringElement(
            cv2.MORPH_RECT, (self.config.line_horizontal_length, 1)
        )
        horizontal = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)

        # Vertical lines
        v_kernel = cv2.getStructuringElement(
            cv2.MORPH_RECT, (1, self.config.line_vertical_length)
        )
        vertical = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel)

        # Combine masks
        mask = cv2.bitwise_or(horizontal, vertical)
        _, mask = cv2.threshold(mask, 200, 255, cv2.THRESH_BINARY)

        # Inpaint
        result = cv2.inpaint(binary, mask, 3, cv2.INPAINT_TELEA)
        logger.debug("[OpenCV] Table lines removed")
        return result

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Stamp removal (usuwanie pieczątek/stempli)
    # ══════════════════════════════════════════════════════════════════════

    def _remove_stamps(self, gray: Any) -> Any:
        """SUPERMOC: Usuwanie pieczątek przez contour detection + inpainting.

        1. Wykryj okrągłe/owalne kontury (pieczątki)
        2. Stwórz maskę dla wykrytych pieczątek
        3. Inpaint przez TELEA

        Returns:
            Obraz bez pieczątek.
        """
        import cv2
        import numpy as np

        # Binaryzacja
        _, binary = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY_INV)

        # Znajdź kontury
        contours, _ = cv2.findContours(
            binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        mask = np.zeros_like(gray)
        for contour in contours:
            area = cv2.contourArea(contour)
            if self.config.stamp_min_area < area < self.config.stamp_max_area:
                # Sprawdź czy kontur jest okrągły
                perimeter = cv2.arcLength(contour, True)
                if perimeter > 0:
                    circularity = 4 * np.pi * area / (perimeter * perimeter)
                    if circularity > 0.5:  # Okrągły/prawie okrągły
                        cv2.drawContours(mask, [contour], -1, 255, -1)

        if np.count_nonzero(mask) > 0:
            result = cv2.inpaint(gray, mask, 3, cv2.INPAINT_TELEA)
            logger.debug("[OpenCV] Stamps removed: %d contours", len(contours))
            return result

        return gray

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Sharpen (wyostrzanie krawędzi)
    # ══════════════════════════════════════════════════════════════════════

    def _sharpen(self, gray: Any) -> Any:
        """SUPERMOC: Wyostrzanie krawędzi przez filter2D.

        Używa kernela wyostrzającego z konfigurowalną siłą.
        """
        import cv2
        import numpy as np

        s = self.config.sharpen_strength
        kernel = np.array(
            [[-s, -s, -s], [-s, 4 * s + 1, -s], [-s, -s, -s]],
            dtype=np.float32,
        )
        return cv2.filter2D(gray, -1, kernel)

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Orientation detection (detekcja orientacji strony)
    # ══════════════════════════════════════════════════════════════════════

    def _detect_and_rotate(self, gray: Any) -> Any:
        """SUPERMOC: Automatyczna detekcja i korekcja orientacji strony.

        Analizuje dominant angle tekstu przez Hough Lines.
        Jeśli tekst jest odwrócony (>45°), obraca do 0°.

        Returns:
            Prawidłowo zorientowany obraz.
        """
        import cv2
        import numpy as np

        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLines(edges, 1, np.pi / 180, 100)
        if lines is None:
            return gray

        angles = []
        for rho, theta in lines[:, 0]:
            angle = np.degrees(theta) % 180
            if angle > 90:
                angle -= 180
            angles.append(angle)

        if not angles:
            return gray

        median_angle = float(np.median(angles))
        h, w = gray.shape

        # Jeśli obraz jest obrócony o ~90°, obróć
        if abs(median_angle) > 45:
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, -90, 1.0)
            rotated = cv2.warpAffine(
                gray, M, (h, w),
                flags=cv2.INTER_CUBIC,
                borderMode=cv2.BORDER_REPLICATE,
            )
            logger.debug("[OpenCV] Orientation corrected: 90°")
            return rotated

        # Jeśli obraz jest odwrócony (180°)
        if abs(median_angle) > 135:
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, 180, 1.0)
            rotated = cv2.warpAffine(
                gray, M, (w, h),
                flags=cv2.INTER_CUBIC,
                borderMode=cv2.BORDER_REPLICATE,
            )
            logger.debug("[OpenCV] Orientation corrected: 180°")
            return rotated

        return gray

    # ══════════════════════════════════════════════════════════════════════
    # SUPERMOC: Auto OCR mode detection
    # ══════════════════════════════════════════════════════════════════════

    def _detect_ocr_mode(self, binary: Any) -> str:
        """SUPERMOC: Automatyczne wykrywanie trybu OCR na podstawie obrazu.

        Analizuje:
        - Gęstość białych pikseli (text coverage)
        - Liczba i rozmiar konturów
        - Proporcje konturów (wys/szer)

        Returns:
            "text", "digits", "amounts", lub "mixed".
        """
        import cv2
        import numpy as np

        h, w = binary.shape
        total_pixels = h * w
        white_pixels = np.count_nonzero(binary)
        coverage = white_pixels / total_pixels

        # Znajdź kontury (znaki)
        contours, _ = cv2.findContours(
            ~binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        if not contours:
            return "text"

        areas = [cv2.contourArea(c) for c in contours]
        aspect_ratios = []
        for c in contours:
            x, y, cw, ch = cv2.boundingRect(c)
            if ch > 0:
                aspect_ratios.append(cw / ch)

        if not aspect_ratios:
            return "text"

        mean_area = float(np.mean(areas))
        median_aspect = float(np.median(aspect_ratios))

        # Digits: małe, wąskie znaki, duża gęstość
        if coverage > 0.3 and median_aspect > 0.5 and median_aspect < 1.5:
            return "text"

        # Amounts: średnie znaki, specyficzne proporcje
        if mean_area > 100 and median_aspect > 2.0:
            return "amounts"

        # Digits: małe, proporcjonalne znaki
        if mean_area < 200 and 0.3 < median_aspect < 0.8:
            return "digits"

        return "mixed"


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC: Image Quality Assessment przez OpenCV
# ═══════════════════════════════════════════════════════════════════════════


def assess_image_quality_cv2(
    image: Any,
) -> dict[str, Any]:
    """SUPERMOC: Ocena jakości obrazu przez OpenCV.

    Wykorzystuje:
    - cv2.Laplacian → Variance of Laplacian (ostrość)
    - cv2.Canny → Edge ratio (detekcja krawędzi)
    - cv2.meanStdDev → Kontrast RMS
    - cv2.calcHist → Entropia

    Args:
        image: PIL Image lub numpy array.

    Returns:
        dict z kluczami: sharpness, contrast, brightness, entropy,
        edge_ratio, is_blank, has_edges.
    """
    if not HAS_CV2:
        return {"error": "OpenCV not installed", "is_blank": True}

    try:
        import cv2
        import numpy as np

        # Konwersja do numpy
        if hasattr(image, "convert"):
            arr = np.array(image.convert("RGB"))
            gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
        elif isinstance(image, np.ndarray):
            if image.ndim == 3:
                gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
            else:
                gray = image
        else:
            return {"error": "Invalid input type", "is_blank": True}

        # 1. Sharpness (Variance of Laplacian)
        laplacian = cv2.Laplacian(gray, cv2.CV_64F)
        lap_var = laplacian.var()
        sharpness = min(lap_var / 500.0, 1.0)

        # 2. Edge ratio (Canny)
        edges = cv2.Canny(gray, 50, 150)
        edge_ratio = float(np.count_nonzero(edges) / edges.size)
        has_edges = edge_ratio > 0.01

        # 3. Contrast (RMS)
        mean, stddev = cv2.meanStdDev(gray)
        contrast = min(float(stddev[0][0]) / 128.0, 1.0)

        # 4. Brightness
        brightness = min(float(mean[0][0]) / 255.0, 1.0)

        # 5. Entropy (histogram)
        hist = cv2.calcHist([gray], [0], None, [256], [0, 256])
        hist = hist / hist.sum()
        hist_nonzero = hist[hist > 0]
        entropy = float(-(hist_nonzero * np.log2(hist_nonzero)).sum() / 8.0)

        return {
            "sharpness": round(sharpness, 4),
            "contrast": round(contrast, 4),
            "brightness": round(brightness, 4),
            "entropy": round(min(entropy, 1.0), 4),
            "edge_ratio": round(edge_ratio, 4),
            "has_edges": has_edges,
            "is_blank": contrast < 0.05 or sharpness < 0.01,
            "laplacian_var": round(lap_var, 2),
        }
    except Exception as exc:
        return {"error": str(exc), "is_blank": True}


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC: Deskew wrapper (prosta funkcja dla pojedynczego obrazu)
# ═══════════════════════════════════════════════════════════════════════════


def deskew_image(image: Any) -> Any:
    """SUPERMOC: Wyprostowanie przekrzywionego obrazu przez OpenCV.

    Używa Hough Line Transform + warpAffine.

    Args:
        image: PIL Image.

    Returns:
        PIL Image — wyprostowany, lub oryginał przy błędzie.
    """
    if not HAS_CV2:
        return image

    try:
        preprocessor = OpenCVPreprocessor(
            OpenCVPreprocessingConfig(
                deskew=True,
                denoise=False,
                clahe=False,
                adaptive_threshold=False,
                morphology=False,
                sharpen=False,
                auto_crop=False,
                auto_rotate=True,
            )
        )
        return preprocessor.process(image)
    except Exception:
        return image


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC: Auto-crop wrapper
# ═══════════════════════════════════════════════════════════════════════════


def auto_crop_image(image: Any) -> Any:
    """SUPERMOC: Przycięcie obrazu do obszaru dokumentu przez OpenCV.

    Args:
        image: PIL Image.

    Returns:
        PIL Image — przycięty, lub oryginał przy błędzie.
    """
    if not HAS_CV2:
        return image

    try:
        import numpy as np
        import cv2

        if hasattr(image, "convert"):
            arr = np.array(image.convert("RGB"))
            gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
        else:
            return image

        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        contours, _ = cv2.findContours(
            binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        if not contours:
            return image

        largest = max(contours, key=cv2.contourArea)
        h, w = gray.shape
        area_ratio = cv2.contourArea(largest) / (h * w)
        if area_ratio < 0.3:
            return image

        x, y, cw, ch = cv2.boundingRect(largest)
        margin = 10
        cropped = arr[
            max(0, y - margin) : min(h, y + ch + margin),
            max(0, x - margin) : min(w, x + cw + margin),
        ]
        from PIL import Image as PILImage

        return PILImage.fromarray(cropped)
    except Exception:
        return image


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC: Feature-based document matching (ORB)
# ═══════════════════════════════════════════════════════════════════════════


def compute_orb_features(
    image: Any, nfeatures: int = 500
) -> tuple[list | None, Any]:
    """SUPERMOC: Obliczenie ORB features dla matchowania dokumentów.

    Używa ORB (Oriented FAST and Rotated BRIEF) — darmowy, bez patentów.
    Odporny na skalowanie, rotację i częściowe przycięcie.

    Args:
        image: PIL Image.
        nfeatures: Liczba feature points (domyślnie 500).

    Returns:
        Tuple (keypoints, descriptors) lub (None, None) przy błędzie.
    """
    if not HAS_CV2:
        return None, None

    try:
        import cv2
        import numpy as np

        if hasattr(image, "convert"):
            gray = np.array(image.convert("L"))
        else:
            return None, None

        orb = cv2.ORB_create(nfeatures=nfeatures)
        kp, des = orb.detectAndCompute(gray, None)
        return kp, des
    except Exception:
        return None, None


def match_documents(
    des1: Any, des2: Any, min_matches: int = 10
) -> dict[str, Any]:
    """SUPERMOC: Porównanie dwóch dokumentów przez ORB feature matching.

    Args:
        des1: Descriptors z pierwszego dokumentu.
        des2: Descriptors z drugiego dokumentu.
        min_matches: Minimalna liczba dopasowań dla uznania za duplikat.

    Returns:
        dict: {matched, match_count, total_features1, total_features2, score}.
    """
    import numpy as np

    if des1 is None or des2 is None or not HAS_CV2:
        return {
            "matched": False,
            "match_count": 0,
            "total_features1": 0,
            "total_features2": 0,
            "score": 0.0,
        }

    try:
        import cv2

        bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        matches = bf.match(des1, des2)
        matches = sorted(matches, key=lambda x: x.distance)

        total = max(len(des1), len(des2))
        score = len(matches) / total if total > 0 else 0.0

        return {
            "matched": len(matches) >= min_matches,
            "match_count": len(matches),
            "total_features1": len(des1),
            "total_features2": len(des2),
            "score": round(float(score), 4),
        }
    except Exception:
        return {
            "matched": False,
            "match_count": 0,
            "total_features1": len(des1) if des1 is not None else 0,
            "total_features2": len(des2) if des2 is not None else 0,
            "score": 0.0,
        }


__all__ = [
    "HAS_CV2",
    "CV2_VERSION",
    "OpenCVPreprocessingConfig",
    "OpenCVPreprocessor",
    "assess_image_quality_cv2",
    "deskew_image",
    "auto_crop_image",
    "compute_orb_features",
    "match_documents",
]
