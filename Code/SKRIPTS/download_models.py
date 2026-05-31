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

try:
    from huggingface_hub import snapshot_download
except ImportError:
    print("[!] huggingface-hub not installed. Run: pip install huggingface-hub")
    sys.exit(1)

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
        project_root = Path(__file__).resolve().parent.parent
        models_dir = project_root / "models"

    models_dir.mkdir(parents=True, exist_ok=True)

    os.environ.setdefault("HF_HOME", str(models_dir))

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
                    print(f"  ✓ {model_key:40s} — {description}")
                    statuses[model_key] = "ok"
                else:
                    print(f"  ✗ {model_key:40s} — CHECKSUM MISMATCH")
                    statuses[model_key] = "mismatch"
            elif exists:
                print(f"  ✓ {model_key:40s} — {description} (directory present)")
                statuses[model_key] = "ok"
            else:
                print(f"  ✗ {model_key:40s} — NOT FOUND")
                statuses[model_key] = "missing"
            continue

        # ── Download mode ─────────────────────────────────────────────────
        print(f"\n>>> Downloading: {model_key}")
        print(f"    Repo: {repo_id}")
        print(f"    Description: {description}")

        try:
            snapshot_download(
                repo_id=repo_id,
                cache_dir=models_dir,
                local_files_only=False,
            )
            statuses[model_key] = "downloaded"
            print(f"    ✓ {model_key} downloaded successfully.")

            # Verify integrity if checksum is available
            if model_key.endswith(".gguf") and expected_hash:
                gguf_files = find_gguf_files(models_dir, repo_id)
                if gguf_files:
                    if verify_model(gguf_files[0], expected_hash):
                        print(f"    ✓ Integrity check PASSED.")
                    else:
                        print(f"    ✗ Integrity check FAILED for {model_key}!")
                        statuses[model_key] = "mismatch"
        except Exception as exc:
            print(f"    ✗ Error downloading {model_key}: {exc}")
            statuses[model_key] = "error"

    # ── Summary ───────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("  DOWNLOAD SUMMARY")
    print("=" * 60)
    ok_count = sum(1 for s in statuses.values() if s in ("ok", "downloaded"))
    fail_count = sum(1 for s in statuses.values() if s in ("error", "mismatch", "missing"))
    print(f"  ✓ Ok: {ok_count}  |  ✗ Failed/missing: {fail_count}")
    print()

    return statuses


def get_missing_models(models_dir: Path | None = None) -> list[dict[str, str]]:
    """Return list of models that are missing or have integrity issues.

    Returns a list of dicts with 'key', 'description', and 'status' fields.
    Useful for the --doctor diagnostic command.
    """
    if models_dir is None:
        project_root = Path(__file__).resolve().parent.parent
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
    args = parser.parse_args()

    models_dir = Path(args.models_dir) if args.models_dir else None
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
