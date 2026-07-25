"""
OCR Preprocessing Pipeline — deskew, binarization, background removal, perspective.

Wdrożenie rekomendacji z Raportu Analitycznego Enterprise Pipeline OCR v7.0:
- Sekcja 2.2: "Brak explicit deskew — to istotna luka!"
- Sekcja 2.2: "Brak binaryzacji adaptacyjnej (Sauvola)"
- Sekcja 5.1: "Brak korekcji perspektywy dla zdjęć pod kątem"
- Sekcja 8.9: "Predictive Preprocessing — adaptacyjne parametry"

v7.0 Audit — wszystkie krytyczne luki preprocessing załatane.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.ocr_preprocessing")

try:
    import cv2
    import numpy as np

    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False
    cv2 = None  # type: ignore
    np = None  # type: ignore

try:
    from PIL import Image, ImageFilter, ImageOps

    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    Image = None  # type: ignore


# ═══════════════════════════════════════════════════════════════════════════
# Deskew — korekcja pochylenia (Hough Line Detection)
# ═══════════════════════════════════════════════════════════════════════════

def deskew_image(image: "np.ndarray", max_angle: float = 45.0) -> "np.ndarray":
    """Korekcja pochylenia dokumentu przez wykrycie kątów linii Hougha.

    Raport v7.0: "Dokumenty skanowane często są pochylone o 1-5 stopni"

    Args:
        image: Obraz OpenCV (BGR lub grayscale).
        max_angle: Maksymalny kąt korekcji w stopniach.

    Returns:
        Obraz po korekcji pochylenia (lub oryginał jeśli nie wykryto).
    """
    if not HAS_CV2 or image is None:
        return image

    try:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image
        # Invert if light background (most documents)
        if np.mean(gray) > 127:
            gray = cv2.bitwise_not(gray)

        # Wykryj krawędzie
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)

        # Hough Lines
        lines = cv2.HoughLines(edges, 1, np.pi / 180, 200)
        if lines is None:
            return image

        # Zbierz kąty
        angles: list[float] = []
        for line in lines:
            rho, theta = line[0]
            angle = theta * 180.0 / np.pi - 90.0
            # Filtruj kąty bliskie poziomym i pionowym
            if abs(angle) < max_angle and abs(angle) > 0.1:
                angles.append(angle)

        if not angles:
            return image

        median_angle = float(np.median(angles))
        if abs(median_angle) < 0.3:
            return image  # Pomijalne pochylenie

        # Rotacja
        (h, w) = image.shape[:2]
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
        rotated = cv2.warpAffine(
            image, M, (w, h),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )
        logger.debug("[PREPROC] Deskew applied: angle=%.2f°", median_angle)
        return rotated

    except Exception as exc:
        logger.warning("[PREPROC] Deskew failed: %s", exc)
        return image


# ═══════════════════════════════════════════════════════════════════════════
# Sauvola Binarization — adaptacyjna binaryzacja
# ═══════════════════════════════════════════════════════════════════════════

def sauvola_binarize(
    image: "np.ndarray",
    window_size: int = 25,
    k: float = 0.2,
    r: float = 128.0,
) -> "np.ndarray":
    """Binaryzacja Sauvola dla dokumentów o niskim kontraście.

    Raport v7.0: "szczególnie ważne dla paragonów na papierze termicznym"

    Args:
        image: Obraz OpenCV (BGR lub grayscale).
        window_size: Rozmiar okna (nieparzysty, minimum 3).
        k: Współczynnik czułości (0.2-0.5, niższy = więcej tekstu).
        r: Maksymalne odchylenie standardowe (domyślnie 128 dla 8-bit).

    Returns:
        Obraz binarny (0/255).
    """
    if not HAS_CV2 or image is None:
        return image

    try:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image
        gray_f = gray.astype(np.float32)

        # Upewnij się, że window_size jest nieparzyste
        if window_size % 2 == 0:
            window_size += 1
        window_size = max(3, window_size)

        # Średnia lokalna
        mean = cv2.boxFilter(gray_f, cv2.CV_32F, (window_size, window_size))

        # Odchylenie standardowe lokalne
        sqmean = cv2.boxFilter(gray_f * gray_f, cv2.CV_32F, (window_size, window_size))
        variance = np.maximum(sqmean - mean * mean, 0)
        stddev = np.sqrt(variance)

        # Próg Sauvola: T = mean * (1 + k * (stddev / R - 1))
        threshold = mean * (1.0 + k * (stddev / r - 1.0))

        binary = (gray_f > threshold).astype(np.uint8) * 255
        logger.debug("[PREPROC] Sauvola binarization: window=%d, k=%.2f", window_size, k)
        return binary

    except Exception as exc:
        logger.warning("[PREPROC] Sauvola binarization failed: %s", exc)
        return image


# ═══════════════════════════════════════════════════════════════════════════
# Background Removal — usuwanie tła dla zdjęć z telefonu
# ═══════════════════════════════════════════════════════════════════════════

def remove_background(image: "np.ndarray", blur_kernel: int = 21) -> "np.ndarray":
    """Usuń tło z dokumentu przez adaptive threshold + morphological ops.

    Raport v7.0: "Usuwanie tła (background removal) dla zdjęć z telefonu"

    Args:
        image: Obraz OpenCV (BGR lub grayscale).
        blur_kernel: Rozmiar kernela rozmycia (nieparzysty).

    Returns:
        Obraz z usuniętym tłem.
    """
    if not HAS_CV2 or image is None:
        return image

    try:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image
        if blur_kernel % 2 == 0:
            blur_kernel += 1

        # Adaptive threshold
        blurred = cv2.GaussianBlur(gray, (blur_kernel, blur_kernel), 0)
        binary = cv2.adaptiveThreshold(
            blurred, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            max(11, blur_kernel),
            2,
        )

        # Morphological close — usuń szum
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        cleaned = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)

        logger.debug("[PREPROC] Background removed: kernel=%d", blur_kernel)
        return cleaned

    except Exception as exc:
        logger.warning("[PREPROC] Background removal failed: %s", exc)
        return image


# ═══════════════════════════════════════════════════════════════════════════
# Perspective Correction — korekcja perspektywy dla zdjęć pod kątem
# ═══════════════════════════════════════════════════════════════════════════

def correct_perspective(
    image: "np.ndarray",
    min_contour_area: float = 0.1,
) -> "np.ndarray":
    """Korekcja perspektywy — wykryj dokument i wyprostuj.

    Raport v7.0: "Korekcje perspektywy (perspective transform) dla zdjęć pod kątem"

    Args:
        image: Obraz OpenCV (BGR).
        min_contour_area: Minimalny obszar konturu jako proporcja obrazu.

    Returns:
        Obraz po korekcji perspektywy.
    """
    if not HAS_CV2 or image is None:
        return image

    try:
        h, w = image.shape[:2]
        total_area = h * w
        min_area = total_area * min_contour_area

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image

        # Wykryj krawędzie
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edged = cv2.Canny(blurred, 75, 200)

        # Znajdź kontury
        contours, _ = cv2.findContours(edged.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Znajdź największy kontur (dokument)
        doc_contour = None
        max_area = 0.0
        for c in contours:
            area = cv2.contourArea(c)
            if area > max_area and area > min_area:
                # Aproksymuj do czworokąta
                peri = cv2.arcLength(c, True)
                approx = cv2.approxPolyDP(c, 0.02 * peri, True)
                if len(approx) == 4:
                    doc_contour = approx
                    max_area = area

        if doc_contour is None:
            return image

        # Uporządkuj punkty: top-left, top-right, bottom-right, bottom-left
        pts = doc_contour.reshape(4, 2)
        rect = np.zeros((4, 2), dtype=np.float32)

        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]  # top-left
        rect[2] = pts[np.argmax(s)]  # bottom-right

        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)]  # top-right
        rect[3] = pts[np.argmax(diff)]  # bottom-left

        # Oblicz wymiary docelowe
        (tl, tr, br, bl) = rect
        width_a = np.linalg.norm(br - bl)
        width_b = np.linalg.norm(tr - tl)
        max_width = max(int(width_a), int(width_b))

        height_a = np.linalg.norm(tr - br)
        height_b = np.linalg.norm(tl - bl)
        max_height = max(int(height_a), int(height_b))

        dst = np.array([
            [0, 0],
            [max_width - 1, 0],
            [max_width - 1, max_height - 1],
            [0, max_height - 1],
        ], dtype=np.float32)

        M = cv2.getPerspectiveTransform(rect, dst)
        warped = cv2.warpPerspective(image, M, (max_width, max_height))

        logger.debug("[PREPROC] Perspective corrected: %dx%d → %dx%d", w, h, max_width, max_height)
        return warped

    except Exception as exc:
        logger.warning("[PREPROC] Perspective correction failed: %s", exc)
        return image


# ═══════════════════════════════════════════════════════════════════════════
# Predictive Preprocessing — adaptacyjne dostosowanie parametrów
# ═══════════════════════════════════════════════════════════════════════════

def predictive_preprocess(
    image: "np.ndarray",
    quality_assessment: dict[str, float] | None = None,
) -> "np.ndarray":
    """Predykcyjny preprocessing na podstawie oceny jakości obrazu.

    Raport v7.0, Innowacja 13:
    - Sharpness < 0.3 → zwiększ UnsharpMask (radius=2, percent=200)
    - Contrast < 0.2 → zastosuj CLAHE (OpenCV)
    - Brightness < 0.3 lub > 0.7 → Gamma correction
    - Entropy < 0.3 → obraz prawdopodobnie pusty → pomiń

    Args:
        image: Obraz OpenCV (BGR lub grayscale).
        quality_assessment: Wynik assess_image_quality (sharpness, contrast, brightness, entropy).

    Returns:
        Obraz po predykcyjnym preprocessingu.
    """
    if not HAS_CV2 or image is None:
        return image

    try:
        result = image.copy()
        gray = cv2.cvtColor(result, cv2.COLOR_BGR2GRAY) if len(result.shape) == 3 else result

        if quality_assessment is None:
            # Szybka ocena jakości
            sharpness = min(float(cv2.Laplacian(gray, cv2.CV_64F).var()) / 500.0, 1.0)
            mean_val, stddev_val = cv2.meanStdDev(gray)
            contrast = min(float(stddev_val[0][0]) / 80.0, 1.0)
            brightness = float(mean_val[0][0]) / 255.0
            entropy_val = _estimate_entropy(gray)
        else:
            sharpness = quality_assessment.get("sharpness", 0.5)
            contrast = quality_assessment.get("contrast", 0.5)
            brightness = quality_assessment.get("brightness", 0.5)
            entropy_val = quality_assessment.get("entropy", 0.5)

        # Entropy < 0.3 → obraz prawdopodobnie pusty
        if entropy_val < 0.3:
            logger.debug("[PREPROC] Low entropy (%.3f) — likely blank, skipping heavy preprocessing", entropy_val)
            return result

        # Sharpness < 0.3 → UnsharpMask
        if sharpness < 0.3 and HAS_PIL:
            try:
                pil_img = Image.fromarray(cv2.cvtColor(result, cv2.COLOR_BGR2RGB) if len(result.shape) == 3 else result)
                sharpened = pil_img.filter(ImageFilter.UnsharpMask(radius=2, percent=200, threshold=3))
                result = cv2.cvtColor(np.array(sharpened), cv2.COLOR_RGB2BGR) if len(result.shape) == 3 else np.array(sharpened)
                logger.debug("[PREPROC] Low sharpness (%.3f) → UnsharpMask applied", sharpness)
            except Exception:
                pass

        # Contrast < 0.2 → CLAHE
        if contrast < 0.2:
            try:
                clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
                if len(result.shape) == 3:
                    lab = cv2.cvtColor(result, cv2.COLOR_BGR2LAB)
                    l, a, b = cv2.split(lab)
                    l = clahe.apply(l)
                    result = cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
                else:
                    result = clahe.apply(result)
                logger.debug("[PREPROC] Low contrast (%.3f) → CLAHE applied", contrast)
            except Exception:
                pass

        # Brightness < 0.3 lub > 0.7 → Gamma correction
        if brightness < 0.3 or brightness > 0.7:
            try:
                target_brightness = 0.5
                gamma = math.log(target_brightness) / math.log(max(brightness, 0.01))
                gamma = max(0.2, min(5.0, gamma))
                look_up_table = np.array([
                    ((i / 255.0) ** (1.0 / gamma)) * 255 for i in range(256)
                ], dtype=np.uint8)
                result = cv2.LUT(result, look_up_table)
                logger.debug("[PREPROC] Brightness (%.3f) → Gamma %.2f applied", brightness, gamma)
            except Exception:
                pass

        return result

    except Exception as exc:
        logger.warning("[PREPROC] Predictive preprocessing failed: %s", exc)
        return image


# ═══════════════════════════════════════════════════════════════════════════
# Full preprocessing pipeline
# ═══════════════════════════════════════════════════════════════════════════

def full_ocr_preprocess(
    image: "np.ndarray",
    *,
    apply_deskew: bool = True,
    apply_sauvola: bool = True,
    apply_background_removal: bool = False,
    apply_perspective_correction: bool = False,
    apply_predictive: bool = True,
    quality_assessment: dict[str, float] | None = None,
    sauvola_k: float = 0.2,
    sauvola_window: int = 25,
) -> "np.ndarray":
    """Pełny pipeline preprocessing OCR (v7.0).

    Kolejność operacji (zoptymalizowana):
    1. Korekcja perspektywy (jeśli zdjęcie pod kątem)
    2. Usuwanie tła
    3. Deskew (korekcja pochylenia)
    4. Predictive preprocessing (CLAHE, gamma, unsharp)
    5. Binaryzacja Sauvola

    Args:
        image: Obraz OpenCV.
        apply_deskew: Włącz korekcję pochylenia.
        apply_sauvola: Włącz binaryzację Sauvola.
        apply_background_removal: Włącz usuwanie tła.
        apply_perspective_correction: Włącz korekcję perspektywy.
        apply_predictive: Włącz predykcyjny preprocessing.
        quality_assessment: Opcjonalna ocena jakości.
        sauvola_k: Parametr k Sauvola.
        sauvola_window: Rozmiar okna Sauvola.

    Returns:
        Obraz OpenCV po pełnym preprocessingu.
    """
    if not HAS_CV2 or image is None:
        return image

    result = image.copy()

    if apply_perspective_correction:
        result = correct_perspective(result)

    if apply_background_removal:
        result = remove_background(result)

    if apply_deskew:
        result = deskew_image(result)

    if apply_predictive:
        result = predictive_preprocess(result, quality_assessment)

    if apply_sauvola:
        result = sauvola_binarize(result, window_size=sauvola_window, k=sauvola_k)

    logger.info(
        "[PREPROC] Full OCR preprocessing: deskew=%s, sauvola=%s, bg_removal=%s, perspective=%s, predictive=%s",
        apply_deskew, apply_sauvola, apply_background_removal,
        apply_perspective_correction, apply_predictive,
    )
    return result


# ═══════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════

def _estimate_entropy(gray: "np.ndarray") -> float:
    """Szybkie oszacowanie entropii obrazu."""
    try:
        hist = cv2.calcHist([gray], [0], None, [256], [0, 256])
        hist = hist / hist.sum()
        hist = hist[hist > 0]
        entropy_val = -float(np.sum(hist * np.log2(hist)))
        return min(entropy_val / 8.0, 1.0)
    except Exception:
        return 0.5


def preprocess_image_file(
    image_path: Path,
    output_dir: Path | None = None,
    **kwargs: Any,
) -> Path:
    """Preprocessing pliku obrazu z zapisem wyniku.

    Args:
        image_path: Ścieżka do pliku wejściowego.
        output_dir: Katalog wyjściowy (domyślnie: obok pliku wejściowego + '_preprocessed').
        **kwargs: Argumenty dla full_ocr_preprocess.

    Returns:
        Ścieżka do przetworzonego pliku.
    """
    if not HAS_CV2:
        return image_path

    img = cv2.imread(str(image_path))
    if img is None:
        logger.warning("[PREPROC] Cannot read image: %s", image_path)
        return image_path

    processed = full_ocr_preprocess(img, **kwargs)

    if output_dir is None:
        output_dir = image_path.parent / f"{image_path.stem}_preprocessed"
    output_dir.mkdir(parents=True, exist_ok=True)

    out_path = output_dir / f"{image_path.stem}_proc.png"
    cv2.imwrite(str(out_path), processed)
    logger.info("[PREPROC] Preprocessed image saved: %s", out_path)
    return out_path


__all__ = [
    "HAS_CV2",
    "deskew_image",
    "sauvola_binarize",
    "remove_background",
    "correct_perspective",
    "predictive_preprocess",
    "full_ocr_preprocess",
    "preprocess_image_file",
    "_estimate_entropy",
]
