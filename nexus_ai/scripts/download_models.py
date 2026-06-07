"""
download_models.py — Download AI models for NexusAI with integrity validation.

Usage:
    python download_models.py                          # Download all models
    python download_models.py --verify-only            # Only verify existing files
    python download_models.py --model alpha            # Download specific model

Supported models with expected SHA-256 checksums (for integrity verification).
"""

from __future__ import annotations

import argparse
import hashlib
import os
import sys
from pathlib import Path

# ── Known model files with SHA-256 checksums ──────────────────────────────
# These are reference checksums for the model files used by the Council of LLMs.
# Actual checksums should be updated when models are known to be correct.
MODEL_MANIFEST: dict[str, dict[str, str]] = {
    # ── Council of LLMs: GGUF models ──────────────────────────────────────────
    "LFM2.5-1.2B-Q4_K_M.gguf": {
        "repo": "lmstudio-community/LFM-2.5-1.2B-GGUF",
        "sha256": "",  # Fill after first verified download
        "description": "Alpha Agent — Primary invoice classification",
    },
    "Qwen3-0.6B-Q4_K_M.gguf": {
        "repo": "lmstudio-community/Qwen3-0.6B-GGUF",
        "sha256": "",
        "description": "Beta Agent — Secondary validation",
    },
    "LittleLamb-0.3B-Q4_K_M.gguf": {
        "repo": "lmstudio-community/LittleLamb-0.3B-GGUF",
        "sha256": "",
        "description": "Gamma / Orchestrator Agent — Tiebreaker + reasoning",
    },
    "granite-4.0-1b-nano-Q4_K_M.gguf": {
        "repo": "lmstudio-community/granite-4.0-1b-nano-GGUF",
        "sha256": "",
        "description": "Rules / Decision Agent — Business rule enforcement",
    },
    "qwen2.5-1.5b-instruct-Q4_K_M.gguf": {
        "repo": "lmstudio-community/Qwen2.5-1.5B-Instruct-GGUF",
        "sha256": "",
        "description": "Analytics Agent — Anomaly detection",
    },
    "Jamba-Reasoning-3B-Q4_K_M.gguf": {
        "repo": "lmstudio-community/Jamba-Reasoning-3B-GGUF",
        "sha256": "",
        "description": "Decision Agent (Jamba) — Complex reasoning",
    },
    # ── Sentence transformers ─────────────────────────────────────────────────
    "all-MiniLM-L6-v2": {
        "repo": "sentence-transformers/all-MiniLM-L6-v2",
        "sha256": "",
        "description": "Active Learning / Semantic Search embeddings",
    },
    # ── Surya OCR models ──────────────────────────────────────────────────────
    "surya_det3": {
        "repo": "vikp/surya_det3",
        "sha256": "",
        "description": "OCR — Text line detection",
    },
    "surya_rec3": {
        "repo": "vikp/surya_rec3",
        "sha256": "",
        "description": "OCR — Text recognition",
    },
    "surya_layout3": {
        "repo": "vikp/surya_layout3",
        "sha256": "",
        "description": "OCR — Table structure detection",
    },
    "surya_order3": {
        "repo": "vikp/surya_order3",
        "sha256": "",
        "description": "OCR — Reading order detection",
    },
}


# ── Utilities ────────────────────────────────────────────────────────────────


def _compute_sha256(filepath: Path) -> str:
    """Compute SHA-256 checksum of a file, reading in chunks for memory efficiency."""
    sha = hashlib.sha256()
    with open(filepath, "rb") as f:
        while True:
            chunk = f.read(65536)  # 64 KB
            if not chunk:
                break
            sha.update(chunk)
    return sha.hexdigest()


def verify_model(filepath: Path, expected_hash: str) -> bool:
    """Verify a model file's integrity against its expected SHA-256 checksum.

    Returns True if:
      - expected_hash is empty (no reference checksum available)
      - the computed checksum matches expected_hash

    Returns False if there is a mismatch.
    """
    if not expected_hash:
        # No reference checksum — skip verification
        return True

    if not filepath.exists():
        return False

    actual_hash = _compute_sha256(filepath)
    if actual_hash == expected_hash:
        return True

    print(f"  [WARN] SHA-256 mismatch for {filepath.name}")
    print(f"    Expected: {expected_hash}")
    print(f"    Actual:   {actual_hash}")
    return False


def find_gguf_files(models_dir: Path, repo_id: str) -> list[Path]:
    """Find downloaded GGUF files for a given HuggingFace repo."""
    # HF cache structure: models--<org>--<repo>/snapshots/<hash>/*.gguf
    cache_name = repo_id.replace("/", "--")
    cache_path = models_dir / f"models--{cache_name}"
    if not cache_path.exists():
        return []

    results: list[Path] = []
    for snapshot_dir in cache_path.iterdir():
        if snapshot_dir.is_dir():
            for f in snapshot_dir.rglob("*.gguf"):
                results.append(f)
    return results


# ── Main logic ───────────────────────────────────────────────────────────────


def _check_disk_space(models_dir: Path, required_bytes: int = 10 * 1024**3) -> bool:
    """Check if there is enough free disk space for model downloads.

    Args:
        models_dir: Target directory for downloads.
        required_bytes: Minimum required free space (default: 10 GB).

    Returns:
        True if enough space is available, False otherwise.
    """
    try:
        import shutil

        total, used, free = shutil.disk_usage(models_dir.parent if models_dir.exists() else models_dir)
        free_gb = free / 1024**3
        required_gb = required_bytes / 1024**3

        if free < required_bytes:
            print(f"  [WARN] Low disk space: {free_gb:.1f} GB free, but {required_gb:.1f} GB recommended.")
            print("         Model downloads may fail. Please free up space and try again.")
            return False

        print(f"  [OK] Disk space: {free_gb:.1f} GB free (recommended: {required_gb:.1f} GB)")
        return True
    except ImportError:
        print("  [WARN] shutil not available — skipping disk space check")
        return True
    except Exception as exc:
        print(f"  [WARN] Could not check disk space: {exc}")
        return True


def download_all_models(models_dir: Path | None = None, verify_only: bool = False, model_filter: str | None = None) -> dict[str, str]:
    """Download (or verify) AI models required by NexusAI.

    Args:
        models_dir: Directory to store models. Defaults to project_root/models/.
        verify_only: If True, only verify existing files without downloading.
        model_filter: Optional model key to download (e.g. "alpha", "beta").

    Returns:
        Dict mapping model keys to status strings ("ok", "missing", "mismatch", "skipped").
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models"

    models_dir.mkdir(parents=True, exist_ok=True)

    os.environ.setdefault("HF_HOME", str(models_dir))

    # Check disk space before downloading
    if not verify_only:
        _check_disk_space(models_dir)

    statuses: dict[str, str] = {}

    manifest_items = list(MODEL_MANIFEST.items())

    if model_filter:
        manifest_items = [
            (key, info) for key, info in manifest_items
            if model_filter.lower() in key.lower() or model_filter.lower() in info["description"].lower()
        ]
        if not manifest_items:
            print(f"[!] No models match filter '{model_filter}'.")
            available = ", ".join(MODEL_MANIFEST.keys())
            print(f"    Available: {available}")
            return statuses

    if verify_only:
        print("=" * 60)
        print("  MODEL INTEGRITY VERIFICATION")
        print("=" * 60)

    for model_key, info in manifest_items:
        repo_id = info["repo"]
        expected_hash = info["sha256"]
        description = info["description"]

        # Determine the expected local path
        if model_key.endswith(".gguf"):
            # GGUF files are downloaded into HF cache structure
            gguf_files = find_gguf_files(models_dir, repo_id)
            if gguf_files:
                local_path = gguf_files[0]
            else:
                local_path = models_dir / model_key
        else:
            # Non-GGUF repos (transformers, sentence-transformers) are directories
            local_path = models_dir / f"models--{repo_id.replace('/', '--')}"

        if verify_only:
            exists = local_path.exists()
            if exists and model_key.endswith(".gguf"):
                integrity_ok = verify_model(local_path, expected_hash) if expected_hash else True
                if integrity_ok:
                    print(f"  {model_key:40s} — {description}")
                    statuses[model_key] = "ok"
                else:
                    print(f"  X {model_key:40s} — CHECKSUM MISMATCH")
                    statuses[model_key] = "mismatch"
            elif exists:
                print(f"  {model_key:40s} — {description} (directory present)")
                statuses[model_key] = "ok"
            else:
                print(f"  X {model_key:40s} — NOT FOUND")
                statuses[model_key] = "missing"
            continue

        # ── Download mode ─────────────────────────────────────────────────
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

            # Verify integrity if checksum is available
            if model_key.endswith(".gguf") and expected_hash:
                gguf_files = find_gguf_files(models_dir, repo_id)
                if gguf_files:
                    if verify_model(gguf_files[0], expected_hash):
                        print("    Integrity check PASSED.")
                    else:
                        print(f"    X Integrity check FAILED for {model_key}!")
                        statuses[model_key] = "mismatch"
        except Exception as exc:
            print(f"    X Error downloading {model_key}: {exc}")
            statuses[model_key] = "error"

    # ── Summary ───────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("  DOWNLOAD SUMMARY")
    print("=" * 60)
    ok_count = sum(1 for s in statuses.values() if s in ("ok", "downloaded"))
    fail_count = sum(1 for s in statuses.values() if s in ("error", "mismatch", "missing"))
    print(f"  Ok: {ok_count}  |  X Failed/missing: {fail_count}")
    print()

    # ── Auto-compute SHA-256 checksums after successful download ──────────
    # If any models were actually downloaded (not verify-only), compute and
    # display their checksums so the user can copy them into MODEL_MANIFEST.
    if not verify_only and ok_count > 0:
        _compute_checksums(models_dir)

    return statuses


def get_missing_models(models_dir: Path | None = None) -> list[dict[str, str]]:
    """Return list of models that are missing or have integrity issues.

    Returns a list of dicts with 'key', 'description', and 'status' fields.
    Useful for the --doctor diagnostic command.
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models"

    missing: list[dict[str, str]] = []

    for model_key, info in MODEL_MANIFEST.items():
        repo_id = info["repo"]
        expected_hash = info["sha256"]

        if model_key.endswith(".gguf"):
            gguf_files = find_gguf_files(models_dir, repo_id)
            exists = len(gguf_files) > 0
            local_path = gguf_files[0] if gguf_files else models_dir / model_key
        else:
            cache_name = f"models--{repo_id.replace('/', '--')}"
            exists = (models_dir / cache_name).exists()
            local_path = models_dir / cache_name

        if not exists:
            missing.append({
                "key": model_key,
                "description": info["description"],
                "status": "missing",
            })
        elif expected_hash and model_key.endswith(".gguf"):
            if not verify_model(local_path, expected_hash):
                missing.append({
                    "key": model_key,
                    "description": info["description"],
                    "status": "checksum_mismatch",
                })

    return missing


def _compute_checksums(models_dir: Path | None = None) -> None:
    """
    Compute SHA-256 checksums for downloaded model files.

    Scans the models directory (or HF cache) for each model in MODEL_MANIFEST,
    computes its SHA-256 checksum, and prints the results in a format suitable
    for copying into the MODEL_MANIFEST dict in this file.

    Only computes checksums for files that already exist on disk.
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent.parent
        models_dir = project_root / "models"

    if not models_dir.exists():
        print(f"[!] Models directory not found: {models_dir}")
        print("    Download models first with: python download_models.py")
        return

    print("=" * 70)
    print("  SHA-256 CHECKSUM COMPUTATION")
    print("=" * 70)
    print()
    print("  Computing checksums for downloaded model files...")
    print(f"  Scanning: {models_dir}")
    print()

    found_any = False
    checksum_output: list[str] = []
    missing_count = 0

    for model_key, info in MODEL_MANIFEST.items():
        repo_id = info["repo"]
        description = info["description"]

        # Locate the actual file on disk
        if model_key.endswith(".gguf"):
            gguf_files = find_gguf_files(models_dir, repo_id)
            if gguf_files:
                local_path = gguf_files[0]
            else:
                # Fallback: look for the filename directly
                direct_match = list(models_dir.rglob(model_key))
                local_path = direct_match[0] if direct_match else models_dir / model_key
        else:
            cache_name = f"models--{repo_id.replace('/', '--')}"
            local_path = models_dir / cache_name

        if not local_path.exists():
            print(f"  - {model_key:45s} — NOT FOUND (download first)")
            missing_count += 1
            continue

        found_any = True
        size_mb = local_path.stat().st_size / (1024 * 1024)

        if local_path.is_dir():
            # For directory-based models (sentence-transformers, surya)
            print(f"  - {model_key:45s} — directory, {size_mb:.0f} MB (skipping SHA-256 for directories)")
            checksum_output.append(
                '    "' + model_key + '": {'
                '\n        "repo": "' + repo_id + '",'
                '\n        "sha256": "",  # Directory'
                '\n        "description": "' + description + '",'
                '\n    },'
            )
        else:
            # Compute SHA-256 for single files (GGUF)
            print(f"  Computing SHA-256 for {model_key} ({size_mb:.0f} MB)...", end=" ", flush=True)
            sha256 = _compute_sha256(local_path)
            print(f"OK {sha256[:16]}...{sha256[-16:]}")

            checksum_output.append(
                '    "' + model_key + '": {'
                '\n        "repo": "' + repo_id + '",'
                '\n        "sha256": "' + sha256 + '",'
                '\n        "description": "' + description + '",'
                '\n    },'
            )

    print()
    print("=" * 70)

    if not found_any:
        print("  No model files found on disk.")
        print("  Download models first with: python download_models.py")
        return

    # Print output ready for MODEL_MANIFEST
    print()
    print("  Copy-paste the following into MODEL_MANIFEST in this file:")
    print()
    print('MODEL_MANIFEST: dict[str, dict[str, str]] = {')
    for line in checksum_output:
        print(line)
    print('}')
    print()

    if missing_count > 0:
        print(f"  Note: {missing_count} model(s) not found — download them first.")
    print()


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
        "--model",
        type=str,
        default=None,
        help="Download a specific model by name (partial match).",
    )
    parser.add_argument(
        "--models-dir",
        type=str,
        default=None,
        help="Custom directory for model storage.",
    )
    parser.add_argument(
        "--compute-checksums",
        action="store_true",
        help="Compute SHA-256 checksums for downloaded models and print them for inclusion in MODEL_MANIFEST.",
    )
    args = parser.parse_args()

    models_dir = Path(args.models_dir) if args.models_dir else None

    # --compute-checksums and --verify-only don't need huggingface_hub
    if args.compute_checksums:
        _compute_checksums(models_dir)
        return

    # Verify huggingface-hub is available for actual downloads
    try:
        import huggingface_hub  # noqa: F401
    except ImportError:
        print("[!] huggingface-hub not installed. Run: pip install huggingface-hub")
        print("    Or install all AI dependencies with: pip install nexus-ai[ai]")
        sys.exit(1)

    statuses = download_all_models(
        models_dir=models_dir,
        verify_only=args.verify_only,
        model_filter=args.model,
    )

    # Exit with error code if any downloads failed
    if any(s in ("error", "mismatch") for s in statuses.values()):
        sys.exit(1)


if __name__ == "__main__":
    main()
