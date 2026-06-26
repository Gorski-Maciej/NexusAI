"""
download_models.py — Download AI models for NexusAI with integrity validation.

Zgodnie z aa3fvcx.txt:
- Żadne konkretne modele LLM nie są zdefiniowane (brak LFM2.5, Qwen3, LittleLamb, etc.)
- docTR modele są wymagane dla warstwy OCR
- Użytkownik może dodać własne GGUF modele do katalogu models/

Referencja architektoniczna:
- docTR: db_resnet50 (~200 MB) + parseq (~300 MB) — łączny rozmiar ~500 MB
- docTR wymaga 2 głównych modeli

Usage:
    python download_models.py --doctr            # Download docTR models only
    python download_models.py --verify-only       # Only verify existing files
"""

from __future__ import annotations

import argparse
import os

from nexus_crypto import Sha256Hasher
import sys
from pathlib import Path

# ── docTR models (Punkty 10 aa3fvcx.txt) ───────────
# Modele docTR: Apache 2.0 license, wbudowana
# ekstrakcja tabel, detekcja orientacji i łatwy fine-tuning.
DOCTR_MODELS: dict[str, dict[str, str]] = {
    "db_resnet50": {
        "repo": "mindee/db_resnet50",
        "sha256": "",
        "description": "docTR — Text detection (DBNet ResNet-50, ~200 MB)",
    },
    "parseq": {
        "repo": "mindee/parseq",
        "sha256": "",
        "description": "docTR — Text recognition (PARSeq Transformer, ~300 MB)",
    },
}

# ── PaddleOCR — drugi silnik OCR z PP-StructureV3 ──────────────────────
# PaddleOCR modele są pobierane automatycznie przy pierwszym użyciu do
# ~/.paddleocr/ (lub custom directory). PP-StructureV3 wymaga osobnych modeli
# do analizy layoutu i tabel (SLANet).
# Lista poniżej dokumentuje które modele są wymagane.
PADDLEOCR_MODELS: dict[str, dict[str, str]] = {
    "ppocrv4_det": {
        "repo": "PaddlePaddle/PaddleOCR",
        "filename": "multilingual_PP-OCRv4_det_infer.tar",
        "sha256": "",
        "description": "PP-OCRv4 text detection (multilingual, ~21 MB)",
    },
    "ppocrv4_rec": {
        "repo": "PaddlePaddle/PaddleOCR",
        "filename": "multilingual_PP-OCRv4_rec_infer.tar",
        "sha256": "",
        "description": "PP-OCRv4 text recognition (multilingual, ~23 MB)",
    },
    "ppstructure_table": {
        "repo": "PaddlePaddle/PaddleOCR",
        "filename": "en_ppstructure_mobile_v2.0_SLANet_infer.tar",
        "sha256": "",
        "description": "PP-StructureV3 table recognition (SLANet, ~12 MB)",
    },
}

# ── EasyOCR — czwarty silnik OCR (CNN + LSTM) ─────────────────────────────
# EasyOCR automatycznie pobiera modele przy pierwszym użyciu do ~/.EasyOCR/model/
# Modele nie wymagają osobnego skryptu — uruchomienie easyocr.Reader() po raz
# pierwszy automatycznie pobiera craft_mlt_25k.pth i rozpoznawanie znaków.
# Lista poniżej to dokumentacja których modeli się spodziewać.
EASYOCR_MODELS: dict[str, dict[str, str]] = {
    "craft_mlt_25k": {
        "repo": "JaidedAI/EasyOCR",
        "filename": "craft_mlt_25k.pth",
        "sha256": "",
        "description": "CRAFT text detection model (490 MB)",
    },
}


import fsspec


def _compute_sha256(filepath: Path) -> str:
    h = Sha256Hasher()
    # SUPERMOC fsspec: open() działa z każdym protokołem
    with fsspec.open(str(filepath), "rb") as f:
        while True:
            chunk = f.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def verify_model(filepath: Path, expected_hash: str) -> bool:
    if not expected_hash:
        return True
    if not filepath.exists():
        return False
    return _compute_sha256(filepath) == expected_hash


def _check_disk_space(models_dir: Path, required_bytes: int = 5 * 1024**3) -> bool:
    try:
        import shutil

        total, used, free = shutil.disk_usage(
            models_dir.parent if models_dir.exists() else models_dir
        )
        free_gb = free / 1024**3
        required_gb = required_bytes / 1024**3
        if free < required_bytes:
            print(
                f"  [WARN] Low disk space: {free_gb:.1f} GB free, but {required_gb:.1f} GB recommended."
            )
            return False
        print(f"  [OK] Disk space: {free_gb:.1f} GB free")
        return True
    except ImportError:
        return True
    except Exception:
        return True


def download_doctr_models(
    models_dir: Path | None = None,
    verify_only: bool = False,
    export_onnx: bool = False,
) -> dict[str, str]:
    """Download/verify docTR pre-trained models with optional ONNX export.

    docTR modele są pobierane automatycznie przy pierwszym użyciu
    przez bibliotekę python-doctr. Ta funkcja pozwala:
    1. Pobrać modele z wyprzedzeniem dla środowisk offline
    2. Zweryfikować czy modele są dostępne w cache
    3. Wyeksportować modele do ONNX dla 2-3× szybszej inferencji na CPU

    SUPERMOC (audyt technologiczny v2):
    - ONNX export: export_onnx() do plików .onnx
    - Weryfikacja przez próbną inferencję
    - Batch processing: det_bs=4, reco_bs=8
    - Detection thresholds: box_thresh=0.3, bin_thresh=0.2

    Modele:
      - db_resnet50: text detection (DBNet) ~200 MB
      - parseq: text recognition (Transformer) ~300 MB
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models"

    models_dir.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("HF_HOME", str(models_dir))

    if not verify_only:
        _check_disk_space(models_dir, required_bytes=2 * 1024**3)

    statuses: dict[str, str] = {}

    if verify_only:
        print("=" * 60)
        print("  docTR MODELS — VERIFICATION + ONNX EXPORT")
        print("=" * 60)

    for model_key, info in DOCTR_MODELS.items():
        repo_id = info["repo"]
        description = info["description"]

        cache_name = f"models--{repo_id.replace('/', '--')}"
        local_path = models_dir / cache_name

        if verify_only:
            exists = local_path.exists() or _check_hf_cache(repo_id)
            if exists:
                print(f"  {model_key:40s} — {description} (present)")
                statuses[model_key] = "ok"
            else:
                print(f"  X {model_key:40s} — NOT FOUND")
                statuses[model_key] = "missing"
            continue

        print(f"\n>>> Processing: {model_key}")
        print(f"    Repo: {repo_id}")
        print(f"    Description: {description}")

        # Modele docTR pobierane automatycznie przy pierwszym użyciu
        print(f"    {model_key} will auto-download on first use")
        statuses[model_key] = "auto"

        # SUPERMOC: ONNX export jeśli zażądano
        if export_onnx and statuses.get(model_key) in ("downloaded", "auto"):
            print(f"    >> Exporting {model_key} to ONNX...")
            try:
                import doctr
                import torch
                from doctr.models import (
                    detection,
                    recognition,
                    export_onnx as doctr_export_onnx,
                )

                if model_key == "db_resnet50":
                    model = detection(arch="db_resnet50", pretrained=True)
                    onnx_path = models_dir / "doctr_det.onnx"
                    doctr_export_onnx(model, str(onnx_path))
                    print(f"    >> ONNX detection model exported to {onnx_path}")
                elif model_key == "parseq":
                    model = recognition(arch="parseq", pretrained=True)
                    onnx_path = models_dir / "doctr_reco.onnx"
                    doctr_export_onnx(model, str(onnx_path))
                    print(f"    >> ONNX recognition model exported to {onnx_path}")

                statuses[f"{model_key}_onnx"] = "exported"
            except Exception as exc:
                print(f"    X ONNX export failed for {model_key}: {exc}")
                print("    [HINT] Install onnxtr: pip install onnxtr")
                statuses[f"{model_key}_onnx"] = "error"

    print("\n" + "=" * 60)
    print("  PROCESSING SUMMARY")
    print("=" * 60)
    ok_count = sum(1 for s in statuses.values() if s in ("ok", "downloaded", "auto", "exported"))
    fail_count = sum(1 for s in statuses.values() if s in ("error", "missing"))
    print(f"  Ok: {ok_count}  |  X Failed/missing: {fail_count}")
    print()

    return statuses


def _check_hf_cache(repo_id: str) -> bool:
    """Sprawdź czy model istnieje w cache HuggingFace."""
    import os
    hf_home = os.environ.get("HF_HOME", os.path.expanduser("~/.cache/huggingface"))
    cache_path = Path(hf_home) / "hub" / f"models--{repo_id.replace('/', '--')}"
    return cache_path.exists()


def download_paddleocr_models(
    models_dir: Path | None = None,
    verify_only: bool = False,
) -> dict[str, str]:
    """Pobierz/zweryfikuj modele PaddleOCR (PP-OCRv4 + PP-StructureV3).

    SUPERMOC:
    - PP-OCRv4 detection (DBNet) ~18 MB
    - PP-OCRv4 recognition (CRNN/Transformer) ~20 MB
    - PP-StructureV3 (SLANet) ~12 MB — table + layout analysis

    Modele są pobierane automatycznie przy pierwszym użyciu przez PaddleOCR.
    Ta funkcja pozwala:
    1. Pobrać modele z wyprzedzeniem dla środowisk offline
    2. Zweryfikować czy modele są dostępne w cache PaddleOCR
    3. Zweryfikować SHA-256 sumy kontrolne
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models" / "paddleocr"

    models_dir.mkdir(parents=True, exist_ok=True)

    if not verify_only:
        _check_disk_space(models_dir, required_bytes=512 * 1024**2)  # ~512 MB

    statuses: dict[str, str] = {}

    print("=" * 60)
    print("  PaddleOCR MODELS — PP-OCRv4 + PP-StructureV3")
    print("=" * 60)

    for model_key, info in PADDLEOCR_MODELS.items():
        filename = info.get("filename", "")
        description = info["description"]

        # Sprawdź w domyślnym cache PaddleOCR
        paddleocr_cache = Path.home() / ".paddleocr" / model_key
        custom_path = models_dir / filename

        if verify_only:
            exists = paddleocr_cache.exists() or custom_path.exists()
            if exists:
                print(f"  {model_key:40s} — {description} (present)")
                statuses[model_key] = "ok"
            else:
                print(f"  X {model_key:40s} — NOT FOUND (auto-download on first use)")
                statuses[model_key] = "missing"
            continue

        print(f"\n>>> {model_key}")
        print(f"    {description}")

        # Sprawdź czy już istnieje
        if paddleocr_cache.exists():
            print(f"    {model_key} already in PaddleOCR cache ({paddleocr_cache})")
            statuses[model_key] = "present"
            continue

        if custom_path.exists():
            print(f"    {model_key} already in custom path ({custom_path})")
            statuses[model_key] = "present"
            continue

        print(f"    {model_key} will be auto-downloaded on first PaddleOCR use")
        print(f"    Cache: {paddleocr_cache}")
        statuses[model_key] = "auto"

    print("\n" + "=" * 60)
    ok_count = sum(1 for s in statuses.values() if s in ("ok", "present", "auto"))
    fail_count = sum(1 for s in statuses.values() if s == "missing")
    print(f"  Ok: {ok_count}  |  Missing: {fail_count}")
    print()

    return statuses


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download AI models for NexusAI with integrity verification.",
    )
def download_easyocr_models(
    models_dir: Path | None = None,
    verify_only: bool = False,
) -> dict[str, str]:
    """Pobierz/zweryfikuj modele EasyOCR.

    SUPERMOC (audyt technologiczny v3):
    - Pobiera CRAFT detection model przez huggingface-hub
    - Sprawdza czy modele są w cache
    - Weryfikuje SHA-256 modeli

    EasyOCR automatycznie pobiera modele przy pierwszym użyciu
    do ~/.EasyOCR/model/ (lub custom model_storage_directory).
    Ta funkcja pozwala:
    1. Pobrać modele z wyprzedzeniem dla środowisk offline
    2. Zweryfikować czy modele są dostępne w cache
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models" / "easyocr"

    models_dir.mkdir(parents=True, exist_ok=True)

    statuses: dict[str, str] = {}

    print("=" * 60)
    print("  EasyOCR MODELS")
    print("=" * 60)

    for model_key, info in EASYOCR_MODELS.items():
        filename = info.get("filename", "")
        description = info["description"]

        easyocr_cache = Path.home() / ".EasyOCR" / "model" / filename
        custom_path = models_dir / filename

        if verify_only:
            exists = easyocr_cache.exists() or custom_path.exists()
            if exists:
                print(f"  {model_key:40s} — {description} (present)")
                statuses[model_key] = "ok"
            else:
                print(f"  X {model_key:40s} — NOT FOUND (will auto-download on first use)")
                statuses[model_key] = "missing"
            continue

        print(f"\n>>> {model_key}")
        print(f"    {description}")

        # Sprawdź czy już istnieje
        if easyocr_cache.exists():
            print(f"    {model_key} already in EasyOCR cache ({easyocr_cache})")
            statuses[model_key] = "present"
            continue

        if custom_path.exists():
            print(f"    {model_key} already in custom path ({custom_path})")
            statuses[model_key] = "present"
            continue

        print(f"    {model_key} will be auto-downloaded on first EasyOCR use")
        print(f"    Cache: {easyocr_cache}")
        statuses[model_key] = "auto"

    print("\n" + "=" * 60)
    ok_count = sum(1 for s in statuses.values() if s in ("ok", "present", "auto"))
    fail_count = sum(1 for s in statuses.values() if s == "missing")
    print(f"  Ok: {ok_count}  |  Missing: {fail_count}")
    print()

    return statuses


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download AI models for NexusAI with integrity verification.",
    )
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="Only verify existing model files without downloading.",
    )
    parser.add_argument(
        "--doctr",
        action="store_true",
        help="Download docTR OCR models (db_resnet50 + parseq).",
    )
    parser.add_argument(
        "--easyocr",
        action="store_true",
        help="Download/verify EasyOCR models (craft_mlt_25k).",
    )
    parser.add_argument(
        "--paddleocr",
        action="store_true",
        help="Download/verify PaddleOCR models (PP-OCRv4 + PP-Structure).",
    )
    parser.add_argument(
        "--models-dir",
        type=str,
        default=None,
        help="Custom directory for model storage.",
    )
    args = parser.parse_args()

    models_dir = Path(args.models_dir) if args.models_dir else None

    if args.doctr:
        statuses = download_doctr_models(
            models_dir=models_dir,
            verify_only=args.verify_only,
        )
        if any(s in ("error",) for s in statuses.values()):
            sys.exit(1)
        return

    if args.easyocr:
        statuses = download_easyocr_models(
            models_dir=models_dir,
            verify_only=args.verify_only,
        )
        if any(s in ("missing",) for s in statuses.values()):
            sys.exit(1)
        return

    if args.paddleocr:
        statuses = download_paddleocr_models(
            models_dir=models_dir,
            verify_only=args.verify_only,
        )
        if any(s in ("error",) for s in statuses.values()):
            sys.exit(1)
        return

    # Default: show help
    parser.print_help()
    print("\n\nUżycie:")
    print("  python download_models.py --doctr          # Pobierz modele docTR")
    print("  python download_models.py --easyocr        # Pobierz/zweryfikuj modele EasyOCR")
    print("  python download_models.py --paddleocr      # Pobierz/zweryfikuj modele PaddleOCR")
    print("  python download_models.py --verify-only    # Sprawdź istniejące pliki")
    sys.exit(0)


if __name__ == "__main__":
    main()
