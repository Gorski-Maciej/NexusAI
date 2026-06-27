"""
image_utils.py -- SUPERMOCE Pillow + OpenCV do normalizacji i przetwarzania obrazow.

Zgodnie z audytem technologicznym (OpenCV Faza 1-3):
- OpenCV cv2.Laplacian + cv2.Canny dla oceny ostrości (10x szybsze niż Pillow Kernel)
- OpenCV cv2.adaptiveThreshold + cv2.createCLAHE dla lepszej binaryzacji OCR
- OpenCV cv2.medianBlur + cv2.filter2D dla szybszego denoising/wyostrzania
- OpenCV cv2.morphologyEx(MORPH_CLOSE) dla czyszczenia po binaryzacji
- OpenCV cv2.resize(INTER_LANCZOS4) dla wyższej jakości skalowania
- OpenCV cv2.findContours + getPerspectiveTransform dla deskew/kadrowania

Hot-plug: Wszystkie funkcje OpenCV są za HAS_CV2 guard — działają gdy cv2 jest
zainstalowane, z pełnym fallbackiem do Pillow gdy nie.
"""

from __future__ import annotations

import io
import math
from pathlib import Path
from typing import Any

import fsspec

# ── Pillow ─────────────────────────────────────────────────────────────────

try:
    from PIL import Image, ImageCms, ImageFile, ImageFilter, ImageOps, ImageStat

    HAS_PIL = True
    ImageFile.LOAD_TRUNCATED_IMAGES = True
except ImportError:
    HAS_PIL = False
    Image = None  # type: ignore

# ── OpenCV (opcjonalnie) ──────────────────────────────────────────────────

try:
    import cv2

    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False
    cv2 = None  # type: ignore


# ============================================================================
# HELPER: PIL conversion utilities
# ============================================================================


def _pil_to_grayscale_cv(image: Image.Image) -> Any | None:
    """Konwersja PIL Image do OpenCV grayscale Mat."""
    if not HAS_CV2 or not HAS_PIL:
        return None
    try:
        import io as _io
        buf = _io.BytesIO()
        pil_rgb = image.convert("RGB")
        pil_rgb.save(buf, format="PNG")
        buf.seek(0)
        file_bytes = buf.getvalue()
        arr = cv2.imdecode(
            cv2.Mat(1, len(file_bytes), cv2.CV_8UC1, file_bytes),
            cv2.IMREAD_COLOR
        )
        return cv2.cvtColor(arr, cv2.COLOR_BGR2GRAY)
    except Exception:
        return None


def _pil_from_cv(cv_img: Any) -> Image.Image | None:
    """Konwersja OpenCV Mat do PIL Image."""
    if not HAS_PIL:
        return None
    try:
        rgb = cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB)
        return Image.fromarray(rgb)
    except Exception:
        return None


# ============================================================================
# SUPERMOC: Bezpieczne otwieranie obrazow z obsluga bledow
# ============================================================================


def safe_open_image(content: bytes) -> Image.Image | None:
    """SUPERMOC: Bezpieczne otwarcie obrazu z obsluga bledow.

    SUPERMOC fsspec: Akceptuje ścieżkę (file://, s3://, http://) lub bytes.
    - Dla str/Path: otwiera przez fsspec.open()
    - Weryfikuje integralnosc przez .verify()
    - Obsluguje LOAD_TRUNCATED_IMAGES (uszkodzone obrazy)
    - Zwraca None przy bledzie (zamiast rzucac wyjatkiem)

    Returns:
        PIL.Image lub None przy bledzie.
    """
    if not HAS_PIL:
        return None
    try:
        # SUPERMOC fsspec: jeśli to ścieżka, otwórz przez fsspec
        if isinstance(content, (str, Path)):
            with fsspec.open(str(content), "rb") as f:
                content = f.read()

        img = Image.open(io.BytesIO(content))  # type: ignore
        img.verify()
        img = Image.open(io.BytesIO(content))  # type: ignore
        return img
    except Exception:
        return None


# ============================================================================
# SUPERMOC: Normalizacja obrazu do JPEG ze wszystkimi optymalizacjami
# ============================================================================


def normalize_image_to_jpeg(
    content: bytes,
    max_size: tuple[int, int] | None = (2048, 2048),
    quality: int = 85,
    apply_autocontrast: bool = False,
    icc_profile: bytes | None = None,
) -> bytes:
    """SUPERMOC: Normalizacja obrazu do JPEG ze wszystkimi optymalizacjami.

    SUPERMOCE Pillow + OpenCV:
    - ImageOps.exif_transpose() -- korekcja orientacji na podstawie EXIF
    - cv2.resize(INTER_LANCZOS4) -- wyzsza jakosc skalowania (gdy OpenCV dostepne)
    - ImageOps.autocontrast() -- automatyczne zwiekszenie kontrastu
    - progressive=True -- progresywny JPEG (lepsze UX w przegladarce)
    - optimize=True -- optymalizacja Huffman
    - ImageCms.profileToProfile() -- zarzadzanie profilami ICC

    OpenCV ulepszenie: cv2.resize z INTER_LANCZOS4 zamiast ImageOps.contain()
    dla wyższej jakości skalowania.

    Args:
        content: Surowe bajty obrazu (PNG, TIFF, WebP, BMP, itd.)
        max_size: Maksymalny rozmiar (width, height) po skalowaniu.
            None = bez skalowania.
        quality: Jakosc JPEG (0-100, domyslnie 85).
        apply_autocontrast: Wymuszenie zwiekszenia kontrastu.
        icc_profile: Opcjonalny ICC profile do konwersji kolorow.

    Returns:
        bytes: Obraz zapisany jako JPEG.
    """
    if not HAS_PIL:
        return content

    img = Image.open(io.BytesIO(content))  # type: ignore

    # SUPERMOC 1: korekcja EXIF (obrocone zdjecia z telefonow)
    img = ImageOps.exif_transpose(img) or img  # type: ignore

    # SUPERMOC 2: skalowanie z zachowaniem proporcji
    if max_size:
        if HAS_CV2:
            # OpenCV INTER_LANCZOS4 — wyższa jakość skalowania
            img = _resize_with_opencv(img, max_size)
        else:
            # Pillow fallback
            img = ImageOps.contain(img, max_size)  # type: ignore

    # SUPERMOC 3: zarzadzanie ICC profile (skanery)
    if icc_profile:
        try:
            src_profile = ImageCms.getOpenProfile(io.BytesIO(icc_profile))  # type: ignore
            dst_profile = ImageCms.createProfile("sRGB")  # type: ignore
            img = ImageCms.profileToProfile(  # type: ignore
                img, src_profile, dst_profile, outputMode="RGB"
            )
        except Exception:
            pass

    # SUPERMOC 4: konwersja do RGB + opcjonalny autocontrast
    rgb = img.convert("RGB")
    if apply_autocontrast:
        rgb = ImageOps.autocontrast(rgb, cutoff=1)  # type: ignore

    # SUPERMOC 5: zapis ze wszystkimi optymalizacjami
    buf = io.BytesIO()
    rgb.save(
        buf,
        format="JPEG",
        quality=quality,
        optimize=True,
        progressive=True,
    )
    return buf.getvalue()


def _resize_with_opencv(
    img: Image.Image, max_size: tuple[int, int]
) -> Image.Image:
    """SUPERMOC: Skalowanie obrazu przez OpenCV INTER_LANCZOS4.

    Wyższa jakość niż ImageOps.contain() — szczególnie przy
    zmniejszaniu obrazów z dużą ilością detali (tekst, tabele).

    Args:
        img: PIL Image do skalowania.
        max_size: Maksymalny rozmiar (width, height).

    Returns:
        PIL Image po skalowaniu.
    """
    try:
        import io as _io
        import cv2

        # Konwersja PIL → OpenCV
        buf = _io.BytesIO()
        img.save(buf, format="PNG")
        buf.seek(0)
        file_bytes = buf.getvalue()
        cv_img = cv2.imdecode(
            cv2.Mat(1, len(file_bytes), cv2.CV_8UC1, file_bytes),
            cv2.IMREAD_COLOR
        )
        h, w = cv_img.shape[:2]
        max_w, max_h = max_size

        # Oblicz proporcje
        scale = min(max_w / w, max_h / h) if w > 0 and h > 0 else 1.0
        if scale >= 1.0:
            return img

        new_w, new_h = int(w * scale), int(h * scale)
        resized = cv2.resize(
            cv_img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4
        )
        # Konwersja z powrotem do PIL
        rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
        return Image.fromarray(rgb)
    except Exception:
        # Fallback do Pillow
        return ImageOps.contain(img, max_size)


# ============================================================================
# SUPERMOC: Ocena jakosci obrazu — Faza 1: OpenCV Laplacian + Canny
# ============================================================================


def _clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, v))


def assess_image_quality(image: Image.Image) -> dict[str, float]:
    """SUPERMOC: Ocena jakosci obrazu przez OpenCV + Pillow.

    FAZA 1 (OpenCV audit):
    - cv2.Laplacian(CV_64F) — Variance of Laplacian (10× szybszy niż Kernel Pillow)
    - cv2.Canny() — edge detection dla lepszej oceny
    - cv2.meanStdDev() — dokładny RMS kontrast
    + Fallback do Pillow ImageStat gdy OpenCV niedostępne.

    Returns:
        dict z kluczami:
        - sharpness (0.0-1.0): ostrosc krawedzi
        - contrast (0.0-1.0): kontrast RMS
        - brightness (0.0-1.0): srednia jasnosc
        - entropy (0.0-1.0): miara informacji
        - edge_ratio (0.0-1.0): stosunek krawedzi Canny
        - has_edges (bool): czy wykryto krawedzie
        - is_blank (bool): czy obraz jest pusty
    """
    # OpenCV path — 10× szybszy, dokładniejszy
    if HAS_CV2 and HAS_PIL:
        try:
            return _assess_quality_opencv(image)
        except Exception:
            pass

    # Pillow fallback
    return _assess_quality_pillow(image)


def _assess_quality_opencv(image: Image.Image) -> dict[str, float]:
    """Ocena jakości przez OpenCV — Laplacian + Canny + meanStdDev."""
    import math

    gray_cv = _pil_to_grayscale_cv(image)
    if gray_cv is None:
        return _assess_quality_pillow(image)

    # 1. Sharpness (Variance of Laplacian)
    laplacian = cv2.Laplacian(gray_cv, cv2.CV_64F)
    lap_var = float(laplacian.var())
    sharpness = _clamp(lap_var / 500.0)

    # 2. Edge ratio (Canny)
    edges = cv2.Canny(gray_cv, 50, 150)
    edge_ratio = float(cv2.countNonZero(edges) / edges.size)
    has_edges = edge_ratio > 0.01

    # 3. Contrast (RMS)
    mean, stddev = cv2.meanStdDev(gray_cv)
    contrast = _clamp(float(stddev[0][0]) / 128.0)

    # 4. Brightness
    brightness = _clamp(float(mean[0][0]) / 255.0)

    # 5. Entropy (OpenCV histogram)
    hist = cv2.calcHist([gray_cv], [0], None, [256], [0, 256])
    hist = hist / hist.sum()
    entropy_sum = 0.0
    for val in hist.flatten():
        if val > 0:
            entropy_sum += val * math.log2(val)
    entropy = float(-entropy_sum / 8.0)

    return {
        "sharpness": round(sharpness, 4),
        "contrast": round(contrast, 4),
        "brightness": round(brightness, 4),
        "entropy": round(_clamp(entropy), 4),
        "edge_ratio": round(edge_ratio, 4),
        "has_edges": has_edges,
        "is_blank": contrast < 0.05 or sharpness < 0.01,
    }


def _assess_quality_pillow(image: Image.Image) -> dict[str, float]:
    """Ocena jakości przez Pillow — fallback gdy brak OpenCV."""
    gray = image.convert("L")
    stat = ImageStat.Stat(gray)  # type: ignore

    # Ostrosc (Variance of Laplacian przez Kernel)
    laplacian = gray.filter(
        ImageFilter.Kernel(  # type: ignore
            (3, 3),
            [-1, -1, -1, -1, 8, -1, -1, -1, -1],
            scale=1,
        )
    )
    lap_stat = ImageStat.Stat(laplacian)  # type: ignore
    sharpness = _clamp(lap_stat.stddev[0] / 128.0)

    # Kontrast
    contrast = _clamp(stat.stddev[0] / 128.0)

    # Jasnosc
    brightness = _clamp(stat.mean[0] / 255.0)

    # Entropia
    hist = gray.histogram()
    total = sum(hist) or 1
    entropy = -sum(
        (h / total) * math.log2(h / total) for h in hist if h > 0
    ) / 8.0

    return {
        "sharpness": round(sharpness, 4),
        "contrast": round(contrast, 4),
        "brightness": round(brightness, 4),
        "entropy": round(_clamp(entropy), 4),
        "edge_ratio": 0.0,
        "has_edges": False,
        "is_blank": contrast < 0.05 or sharpness < 0.01,
    }


def assess_image_quality_from_bytes(content: bytes) -> dict[str, Any]:
    """Ocena jakosci obrazu z bajtow (wrapped dla API).

    Returns:
        dict z ocenami + 'error' jesli otwarcie sie nie udalo.
    """
    if not HAS_PIL:
        return {"error": "Pillow not installed", "is_blank": True}
    try:
        img = Image.open(io.BytesIO(content))  # type: ignore
        return assess_image_quality(img)
    except Exception as exc:
        return {"error": str(exc), "is_blank": True}


# ============================================================================
# SUPERMOC: Strumieniowe ladowanie obrazow (ImageFile.Parser)
# ============================================================================


def stream_load_image(content: bytes, chunk_size: int = 65536) -> Image.Image | None:
    """SUPERMOC: Strumieniowe ladowanie obrazu przez ImageFile.Parser.

    Nie laduje calego pliku do pamieci przed dekodowaniem.
    Przydatne dla bardzo duzych obrazow (100+ MB skanow).

    Args:
        content: Bajty obrazu.
        chunk_size: Rozmiar kawalka w bajtach.

    Returns:
        PIL.Image lub None przy bledzie.
    """
    if not HAS_PIL:
        return None
    try:
        parser = ImageFile.Parser()  # type: ignore
        for offset in range(0, len(content), chunk_size):
            parser.feed(content[offset : offset + chunk_size])
        return parser.close()
    except Exception:
        return None


# ============================================================================
# SUPERMOC: Preprocessing obrazu dla OCR — Faza 1+2: OpenCV
# ============================================================================


def preprocess_for_ocr(image: Image.Image) -> Image.Image:
    """SUPERMOC: Kompletny preprocessing obrazu dla najlepszego OCR.

    FAZA 1-3 (OpenCV audit):
    Gdy OpenCV dostępne:
    1. cv2.cvtColor → grayscale
    2. cv2.createCLAHE → lokalny kontrast (lepszy niż autocontrast)
    3. cv2.adaptiveThreshold → adaptacyjna binaryzacja (lepsza niż ręczne progi)
    4. cv2.fastNlMeansDenoising → NLM denoising (lepszy niż MedianFilter)
    5. cv2.morphologyEx(MORPH_CLOSE) → łączenie fragmentów liter
    6. cv2.filter2D → sharpen (lepszy niż UnsharpMask)

    Gdy tylko Pillow (fallback):
    1. ImageOps.exif_transpose → korekcja EXIF
    2. ImageOps.autocontrast → kontrast
    3. ImageFilter.MedianFilter → denoising
    4. ImageFilter.UnsharpMask → wyostrzenie

    Returns:
        PIL.Image -- gotowy do OCR.
    """
    if HAS_CV2 and HAS_PIL:
        try:
            return _preprocess_opencv(image)
        except Exception:
            pass

    return _preprocess_pillow(image)


def _preprocess_opencv(image: Image.Image) -> Image.Image:
    """SUPERMOC: Preprocessing przez OpenCV — najlepsza jakość dla OCR.

    Pipeline:
    1. Grayscale (cv2.cvtColor)
    2. CLAHE (cv2.createCLAHE) — lokalny kontrast
    3. Denoising (cv2.fastNlMeansDenoising) — NLM
    4. Adaptive threshold (cv2.adaptiveThreshold) — binaryzacja
    5. Morphology close (cv2.morphologyEx) — łączenie liter
    6. Sharpen (cv2.filter2D) — wyostrzenie krawędzi
    """
    # 1. Konwersja PIL → OpenCV grayscale
    gray_cv = _pil_to_grayscale_cv(image)
    if gray_cv is None:
        return _preprocess_pillow(image)

    # 2. CLAHE — lokalny kontrast (lepszy niż globalny autocontrast)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray_cv)

    # 3. Denoising NLM — najlepszy dla skanów
    denoised = cv2.fastNlMeansDenoising(enhanced, h=10)

    # 4. Adaptive Gaussian threshold — lepszy niż Otsu dla dokumentów
    binary = cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31,
        2,
    )

    # 5. Morphology close — łączenie fragmentów liter
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    cleaned = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)

    # 6. Sharpen — wyostrzenie krawędzi
    s = 1.0
    sharpen_kernel = [[-s, -s, -s], [-s, 4 * s + 1, -s], [-s, -s, -s]]
    sharpened = cv2.filter2D(cleaned, -1, sharpen_kernel)

    # Konwersja z powrotem do PIL
    return _pil_from_cv(cv2.cvtColor(sharpened, cv2.COLOR_GRAY2RGB))


def _preprocess_pillow(image: Image.Image) -> Image.Image:
    """SUPERMOC: Preprocessing przez Pillow — fallback gdy brak OpenCV.

    Pipeline:
    1. ImageOps.exif_transpose — korekcja EXIF
    2. Konwersja do grayscale
    3. ImageStat — sprawdzenie jakości
    4. ImageOps.autocontrast — kontrast
    5. ImageFilter.MedianFilter — denoising
    6. ImageFilter.UnsharpMask — wyostrzenie
    """
    # 1. Korekcja orientacji
    img = ImageOps.exif_transpose(image) or image  # type: ignore

    # 2. Konwersja do szarosci
    gray = img.convert("L")

    # 3. Sprawdz czy obraz ma wystarczajaca jakosc
    stat = ImageStat.Stat(gray)  # type: ignore
    if stat.stddev[0] < 8:
        return gray  # Prawie pusty obraz -- nie ma co poprawiac

    # 4. Autocontrast (1% cutoff dla odpornosci)
    enhanced = ImageOps.autocontrast(gray, cutoff=1)  # type: ignore

    # 5. Denoising dla szumow skanera
    denoised = enhanced.filter(ImageFilter.MedianFilter(size=3))  # type: ignore

    # 6. Wyostrzenie krawedzi znakow
    sharpened = denoised.filter(
        ImageFilter.UnsharpMask(radius=1, percent=150, threshold=3)  # type: ignore
    )

    return sharpened


def preprocess_pil_or_none(image: Image.Image | None) -> Image.Image | None:
    """Safe wrapper dla preprocess_for_ocr."""
    if image is None:
        return None
    try:
        return preprocess_for_ocr(image)
    except Exception:
        return image


# ============================================================================
# SUPERMOC: Deskew + Auto-crop + ORB przez OpenCV — delegacja do opencv_pipeline
# ============================================================================


def deskew_image(image: Image.Image) -> Image.Image:
    """SUPERMOC: Korekcja przekrzywienia dokumentu przez OpenCV.

    Deleguje do OpenCVPreprocessor z opencv_pipeline.py.
    Gdy OpenCV niedostępne, zwraca oryginał.

    Args:
        image: PIL Image.

    Returns:
        PIL Image — wyprostowany, lub oryginał przy błędzie.
    """
    if not HAS_CV2 or not HAS_PIL:
        return image

    try:
        from nexus_ai.core.opencv_pipeline import (
            OpenCVPreprocessor,
            OpenCVPreprocessingConfig,
        )

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


def auto_crop_image(image: Image.Image, margin: int = 10) -> Image.Image:
    """SUPERMOC: Automatyczne przycięcie do obszaru dokumentu przez OpenCV.

    Deleguje do OpenCVPreprocessor z opencv_pipeline.py.
    Gdy OpenCV niedostępne, zwraca oryginał.

    Args:
        image: PIL Image.
        margin: Margines w pikselach (domyślnie 10).

    Returns:
        PIL Image — przycięty, lub oryginał przy błędzie.
    """
    if not HAS_CV2 or not HAS_PIL:
        return image

    try:
        from nexus_ai.core.opencv_pipeline import (
            OpenCVPreprocessor,
            OpenCVPreprocessingConfig,
        )

        preprocessor = OpenCVPreprocessor(
            OpenCVPreprocessingConfig(
                deskew=False,
                denoise=False,
                clahe=False,
                adaptive_threshold=False,
                morphology=False,
                sharpen=False,
                auto_crop=True,
                crop_margin=margin,
            )
        )
        return preprocessor.process(image)
    except Exception:
        return image


def compute_orb_fingerprint(
    image: Image.Image, nfeatures: int = 500
) -> str | None:
    """SUPERMOC: ORB feature fingerprint dla identyfikacji dokumentów.

    Deleguje do compute_orb_features z opencv_pipeline.py.
    Odporny na skalowanie, rotację i częściowe przycięcie.

    Args:
        image: PIL Image.
        nfeatures: Liczba feature points.

    Returns:
        String fingerprint lub None przy błędzie/braku OpenCV.
    """
    if not HAS_CV2 or not HAS_PIL:
        return None

    try:
        from nexus_ai.core.opencv_pipeline import compute_orb_features

        _, des = compute_orb_features(image, nfeatures=nfeatures)
        if des is None:
            return None
        # des is a cv2 mat; extract bytes safely
        return bytes(des.flatten().tolist()).hex()[:64] if hasattr(des, 'flatten') else str(des).encode().hex()[:64]
    except Exception:
        return None


# ============================================================================
# EXPORTS
# ============================================================================


__all__ = [
    "HAS_PIL",
    "HAS_CV2",
    "safe_open_image",
    "normalize_image_to_jpeg",
    "assess_image_quality",
    "assess_image_quality_from_bytes",
    "stream_load_image",
    "preprocess_for_ocr",
    "preprocess_pil_or_none",
    "deskew_image",
    "auto_crop_image",
    "compute_orb_fingerprint",
]
