"""
image_utils.py -- SUPERMOCE Pillow do normalizacji i przetwarzania obrazow.

Kompletny zestaw narzedzi wykorzystujacych pelnie mozliwosci Pillow:
- ImageOps: exif_transpose, autocontrast, contain, equalize
- ImageFile: LOAD_TRUNCATED_IMAGES, Parser (strumieniowe ladowanie)
- ImageCms: zarzadzanie profilami ICC
- ImageStat: ocena jakosci obrazu
- ImageFilter: wygladzanie, wyostrzanie

Zgodnie z audytem technologicznym Pillow (Faza 2):
- Eliminacja duplikacji kodu Image->JPEG w 3 plikach
- Dodanie EXIF transpose, skalowania, kontrastu
- Obsluga profili ICC dla skanerow biurowych
"""

from __future__ import annotations

import io
import math
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageCms, ImageFile, ImageFilter, ImageOps, ImageStat

    HAS_PIL = True
    # SUPERMOC: Wlacz obsluge uszkodzonych/niekompletnych obrazow
    ImageFile.LOAD_TRUNCATED_IMAGES = True
except ImportError:
    HAS_PIL = False
    Image = None  # type: ignore


# ============================================================================
# SUPERMOC: Bezpieczne otwieranie obrazow z obsluga bledow
# ============================================================================


def safe_open_image(content: bytes) -> Image.Image | None:
    """SUPERMOC: Bezpieczne otwarcie obrazu z obsluga bledow.

    - Otwiera obraz z bytes
    - Weryfikuje integralnosc przez .verify()
    - Obsluguje LOAD_TRUNCATED_IMAGES (uszkodzone obrazy)
    - Zwraca None przy bledzie (zamiast rzucac wyjatkiem)

    Returns:
        PIL.Image lub None przy bledzie.
    """
    if not HAS_PIL:
        return None
    try:
        img = Image.open(io.BytesIO(content))
        img.verify()  # Weryfikacja integralnosci
        # Ponowne otwarcie po verify (verify zamyka plik)
        img = Image.open(io.BytesIO(content))
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

    SUPERMOCE Pillow:
    - ImageOps.exif_transpose() -- korekcja orientacji na podstawie EXIF
    - ImageOps.contain() -- skalowanie z zachowaniem proporcji
    - ImageOps.autocontrast() -- automatyczne zwiekszenie kontrastu
    - progressive=True -- progresywny JPEG (lepsze UX w przegladarce)
    - optimize=True -- optymalizacja Huffman
    - ImageCms.profileToProfile() -- zarzadzanie profilami ICC

    Eliminuje duplikacje kodu Image -> JPEG w shared_image_buffer.py
    i services.py (3 miejsca -> 1 wywolanie).

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

    img = Image.open(io.BytesIO(content))

    # SUPERMOC 1: korekcja EXIF (obrocone zdjecia z telefonow)
    img = ImageOps.exif_transpose(img) or img

    # SUPERMOC 2: skalowanie z zachowaniem proporcji
    if max_size:
        img = ImageOps.contain(img, max_size)

    # SUPERMOC 3: zarzadzanie ICC profile (skanery)
    if icc_profile:
        try:
            src_profile = ImageCms.getOpenProfile(io.BytesIO(icc_profile))
            dst_profile = ImageCms.createProfile("sRGB")
            img = ImageCms.profileToProfile(
                img, src_profile, dst_profile, outputMode="RGB"
            )
        except Exception:
            pass

    # SUPERMOC 4: konwersja do RGB + opcjonalny autocontrast
    rgb = img.convert("RGB")
    if apply_autocontrast:
        rgb = ImageOps.autocontrast(rgb, cutoff=1)

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


# ============================================================================
# SUPERMOC: Ocena jakosci obrazu przez ImageStat
# ============================================================================


def _clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, v))


def assess_image_quality(image: Image.Image) -> dict[str, float]:
    """SUPERMOC: Ocena jakosci obrazu przez ImageStat + ImageFilter.

    Wykorzystuje:
    - ImageStat.stddev -- kontrast (RMS)
    - ImageStat.mean -- jasnosc
    - ImageFilter.Kernel + ImageStat -- ostrosc (Laplacian variance)
    - Histogram -- entropia (miara informacji)

    Returns:
        dict z kluczami:
        - sharpness (0.0-1.0): ostrosc krawedzi
        - contrast (0.0-1.0): kontrast RMS
        - brightness (0.0-1.0): srednia jasnosc
        - entropy (0.0-1.0): miara informacji
        - is_blank (bool): czy obraz jest pusty
    """
    gray = image.convert("L")
    stat = ImageStat.Stat(gray)

    # Ostrosc (Variance of Laplacian przez Kernel)
    laplacian = gray.filter(
        ImageFilter.Kernel(
            (3, 3),
            [-1, -1, -1, -1, 8, -1, -1, -1, -1],
            scale=1,
        )
    )
    lap_stat = ImageStat.Stat(laplacian)
    sharpness = _clamp(lap_stat.stddev[0] / 128.0)

    # Kontrast
    contrast = _clamp(stat.stddev[0] / 128.0)

    # Jasnosc (0 = czarny, 1 = bialy, 0.5 = idealny)
    brightness = _clamp(stat.mean[0] / 255.0)

    # Entropia (miara informacji)
    hist = gray.histogram()
    total = sum(hist) or 1
    entropy = -sum(
        (h / total) * math.log2(h / total) for h in hist if h > 0
    ) / 8.0  # 8 = max entropy dla 8-bit

    return {
        "sharpness": round(sharpness, 4),
        "contrast": round(contrast, 4),
        "brightness": round(brightness, 4),
        "entropy": round(_clamp(entropy), 4),
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
        img = Image.open(io.BytesIO(content))
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
        parser = ImageFile.Parser()
        for offset in range(0, len(content), chunk_size):
            parser.feed(content[offset : offset + chunk_size])
        return parser.close()
    except Exception:
        return None


# ============================================================================
# SUPERMOC: Preprocessing obrazu dla OCR
# ============================================================================


def preprocess_for_ocr(image: Image.Image) -> Image.Image:
    """SUPERMOC: Kompletny preprocessing obrazu dla najlepszego OCR.

    Kolejnosc operacji:
    1. ImageOps.exif_transpose() -- korekcja orientacji
    2. Konwersja do grayscale ('L')
    3. ImageStat.stddev -- sprawdzenie jakosci
    4. ImageOps.autocontrast(cutoff=1) -- zwiekszenie kontrastu
    5. ImageFilter.MedianFilter(3) -- denoising salt & pepper
    6. ImageFilter.UnsharpMask -- wyostrzenie krawedzi znakow

    Returns:
        PIL.Image -- gotowy do OCR.
    """
    # 1. Korekcja orientacji
    img = ImageOps.exif_transpose(image) or image

    # 2. Konwersja do szarosci
    gray = img.convert("L")

    # 3. Sprawdz czy obraz ma wystarczajaca jakosc
    stat = ImageStat.Stat(gray)
    if stat.stddev[0] < 8:
        return gray  # Prawie pusty obraz -- nie ma co poprawiac

    # 4. Autocontrast (1% cutoff dla odpornosci)
    enhanced = ImageOps.autocontrast(gray, cutoff=1)

    # 5. Denoising dla szumow skanera
    denoised = enhanced.filter(ImageFilter.MedianFilter(size=3))

    # 6. Wyostrzenie krawedzi znakow
    sharpened = denoised.filter(
        ImageFilter.UnsharpMask(radius=1, percent=150, threshold=3)
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


__all__ = [
    "HAS_PIL",
    "safe_open_image",
    "normalize_image_to_jpeg",
    "assess_image_quality",
    "assess_image_quality_from_bytes",
    "stream_load_image",
    "preprocess_for_ocr",
    "preprocess_pil_or_none",
]
