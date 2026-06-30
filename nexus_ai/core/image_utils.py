"""
"""

from __future__ import annotations

import io
import math
from functools import lru_cache
from pathlib import Path
from typing import Any

import fsspec

try:
    from PIL import Image, ImageCms, ImageFile, ImageFilter, ImageOps, ImageStat

    HAS_PIL = True
    ImageFile.LOAD_TRUNCATED_IMAGES = True
except ImportError:
    HAS_PIL = False
    Image = None  # type: ignore


# ============================================================================
# ============================================================================


def safe_open_image(content: bytes) -> Image.Image | None:
    """Bezpieczne otwarcie obrazu z obsluga bledow."""
    if not HAS_PIL:
        return None
    try:
        if isinstance(content, (str, Path)):
            with fsspec.open(str(content), "rb") as f:
                content = f.read()
        img = Image.open(io.BytesIO(content))  # type: ignore
        img.verify()
        img = Image.open(io.BytesIO(content))  # type: ignore
        return img
    except Exception:
        return None


def normalize_image_to_jpeg(
    content: bytes,
    max_size: tuple[int, int] | None = (2048, 2048),
    quality: int = 85,
    apply_autocontrast: bool = False,
    icc_profile: bytes | None = None,
) -> bytes:
    """Normalizacja obrazu do JPEG ze wszystkimi optymalizacjami."""
    if not HAS_PIL:
        return content

    img = Image.open(io.BytesIO(content))  # type: ignore
    img = ImageOps.exif_transpose(img) or img  # type: ignore

    if max_size:
        img = ImageOps.contain(img, max_size)  # type: ignore

    if icc_profile:
        try:
            src_profile = ImageCms.getOpenProfile(io.BytesIO(icc_profile))  # type: ignore
            dst_profile = ImageCms.createProfile("sRGB")  # type: ignore
            img = ImageCms.profileToProfile(  # type: ignore
                img, src_profile, dst_profile, outputMode="RGB"
            )
        except Exception:
            pass

    rgb = img.convert("RGB")
    if apply_autocontrast:
        rgb = ImageOps.autocontrast(rgb, cutoff=1)  # type: ignore

    buf = io.BytesIO()
    rgb.save(buf, format="JPEG", quality=quality, optimize=True, progressive=True)
    return buf.getvalue()


# ============================================================================
# ============================================================================


def _clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, v))


def assess_image_quality(image: Image.Image) -> dict[str, float]:
    """Ocena jakosci obrazu przez Pillow."""
    gray = image.convert("L")
    stat = ImageStat.Stat(gray)  # type: ignore

    laplacian = gray.filter(
        ImageFilter.Kernel(  # type: ignore
            (3, 3),
            [-1, -1, -1, -1, 8, -1, -1, -1, -1],
            scale=1,
        )
    )
    lap_stat = ImageStat.Stat(laplacian)  # type: ignore
    sharpness = _clamp(lap_stat.stddev[0] / 128.0)
    contrast = _clamp(stat.stddev[0] / 128.0)
    brightness = _clamp(stat.mean[0] / 255.0)

    hist = gray.histogram()
    total = sum(hist) or 1
    entropy = -sum((h / total) * math.log2(h / total) for h in hist if h > 0) / 8.0

    return {
        "sharpness": round(sharpness, 4),
        "contrast": round(contrast, 4),
        "brightness": round(brightness, 4),
        "entropy": round(_clamp(entropy), 4),
        "edge_ratio": 0.0,
        "has_edges": False,
        "is_blank": contrast < 0.05 or sharpness < 0.01,
    }


@lru_cache(maxsize=64)
def assess_image_quality_from_bytes(content: bytes) -> dict[str, Any]:
    """Ocena jakosci obrazu z bajtow."""
    if not HAS_PIL:
        return {"error": "Pillow not installed", "is_blank": True}
    try:
        img = Image.open(io.BytesIO(content))  # type: ignore
        return assess_image_quality(img)
    except Exception as exc:
        return {"error": str(exc), "is_blank": True}


# ============================================================================
# ============================================================================


def preprocess_for_ocr(image: Image.Image) -> Image.Image:
    """Preprocessing obrazu przez Pillow dla najlepszego OCR."""
    img = ImageOps.exif_transpose(image) or image  # type: ignore
    gray = img.convert("L")

    stat = ImageStat.Stat(gray)  # type: ignore
    if stat.stddev[0] < 8:
        return gray

    enhanced = ImageOps.autocontrast(gray, cutoff=1)  # type: ignore
    denoised = enhanced.filter(ImageFilter.MedianFilter(size=3))  # type: ignore
    sharpened = denoised.filter(
        ImageFilter.UnsharpMask(radius=1, percent=150, threshold=3)  # type: ignore
    )
    return sharpened


def preprocess_pil_or_none(image: Image.Image | None) -> Image.Image | None:
    if image is None:
        return None
    try:
        return preprocess_for_ocr(image)
    except Exception:
        return image


# ============================================================================
# EXPORTS
# ============================================================================


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
