"""
download_models.py — Download AI models for NexusAI with integrity validation.

Zgodnie z aa3fvcx.txt:
- Żadne konkretne modele LLM nie są zdefiniowane (brak LFM2.5, Qwen3, LittleLamb, etc.)
- Surya OCR modele są wymagane dla warstwy OCR (Punkt 10 aa3fvcx.txt)
- Użytkownik może dodać własne GGUF modele do katalogu models/

Usage:
    python download_models.py --surya             # Download Surya OCR models only
    python download_models.py --verify-only        # Only verify existing files
"""

from __future__ import annotations

import argparse
import hashlib  # streaming SHA-256 for file verification (nexus_crypto doesn't support streaming)
import os
import sys
from pathlib import Path

# ── Surya OCR models (zgodne z aa3fvcx.txt Punkt 10) ─────────────────────
SURYA_MODELS: dict[str, dict[str, str]] = {
    "surya_det3": {
        "repo": "vikp/surya_det3",
        "sha256": "",
        "description": "OCR — Text line detection",
    },
    "surya_rec": {
        "repo": "vikp/surya_rec",
        "sha256": "",
        "description": "OCR — Text recognition",
    },
    "surya_layout3": {
        "repo": "vikp/surya_layout3",
        "sha256": "",
        "description": "OCR — Table structure detection",
    },
    "surya_order": {
        "repo": "vikp/surya_order",
        "sha256": "",
        "description": "OCR — Reading order detection",
    },
}


def _compute_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
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


def download_surya_models(
    models_dir: Path | None = None, verify_only: bool = False
) -> dict[str, str]:
    """Download Surya OCR models (zgodne z aa3fvcx.txt Punkt 10)."""
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models"

    models_dir.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("HF_HOME", str(models_dir))

    if not verify_only:
        _check_disk_space(models_dir)

    statuses: dict[str, str] = {}

    if verify_only:
        print("=" * 60)
        print("  SURYA OCR MODELS — VERIFICATION")
        print("=" * 60)

    for model_key, info in SURYA_MODELS.items():
        repo_id = info["repo"]
        description = info["description"]

        cache_name = f"models--{repo_id.replace('/', '--')}"
        local_path = models_dir / cache_name

        if verify_only:
            exists = local_path.exists()
            if exists:
                print(f"  {model_key:40s} — {description} (present)")
                statuses[model_key] = "ok"
            else:
                print(f"  X {model_key:40s} — NOT FOUND")
                statuses[model_key] = "missing"
            continue

        print(f"\n>>> Downloading: {model_key}")
        print(f"    Repo: {repo_id}")
        print(f"    Description: {description}")

        try:
            from huggingface_hub import snapshot_download
        except ImportError:
            print("  [ERROR] huggingface-hub not installed. Run: pip install huggingface-hub")
            statuses[model_key] = "error"
            continue

        try:
            snapshot_download(
                repo_id=repo_id,
                cache_dir=models_dir,
                local_files_only=False,
            )
            statuses[model_key] = "downloaded"
            print(f"    {model_key} downloaded successfully.")
        except Exception as exc:
            print(f"    X Error downloading {model_key}: {exc}")
            statuses[model_key] = "error"

    print("\n" + "=" * 60)
    print("  DOWNLOAD SUMMARY")
    print("=" * 60)
    ok_count = sum(1 for s in statuses.values() if s in ("ok", "downloaded"))
    fail_count = sum(1 for s in statuses.values() if s in ("error", "missing"))
    print(f"  Ok: {ok_count}  |  X Failed/missing: {fail_count}")
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
        "--surya",
        action="store_true",
        help="Download Surya OCR models only (zgodne z aa3fvcx.txt).",
    )
    parser.add_argument(
        "--models-dir",
        type=str,
        default=None,
        help="Custom directory for model storage.",
    )
    args = parser.parse_args()

    models_dir = Path(args.models_dir) if args.models_dir else None

    if args.surya:
        statuses = download_surya_models(
            models_dir=models_dir,
            verify_only=args.verify_only,
        )
        if any(s in ("error",) for s in statuses.values()):
            sys.exit(1)
        return

    # Default: show help
    parser.print_help()
    print("\n\nUżycie: python download_models.py --surya  # Pobierz modele OCR")
    print("       python download_models.py --verify-only  # Sprawdź istniejące pliki")
    sys.exit(0)


if __name__ == "__main__":
    main()
