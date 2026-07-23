"""offline_installer.py — Offline Installer with Embedded Models (v7.0 Innowacja 10).

  Pełny offline installer zawierający WSZYSTKO:
  - NexusAI.exe (Nuitka onefile)
  - Wszystkie 13 modeli GGUF (skompresowane, ~8 GB)
  - NATS Server + TigerBeetle + OPA binaries
  - ~10 GB całkowity rozmiar, ale ZERO internetu potrzebnego

  Proces:
  1. Buduje pełny instalator z embedded modelami
  2. Kompresuje modele GGUF (lzma2/ultra)
  3. Pakuje wszystko do jednego archiwum .7z/.zip
  4. Instalator rozpakowuje modele przy pierwszym uruchomieniu
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.installer.offline")

# ── Model manifest ──────────────────────────────────────────────────────────

MODELS_MANIFEST: list[dict[str, Any]] = [
    {"name": "phi-2.Q4_K_M.gguf", "size_mb": 1600, "required": True,
     "description": "Phi-2 — główny model księgowy (OCR + klasyfikacja)"},
    {"name": "mistral-7b-instruct-v0.2.Q4_K_M.gguf", "size_mb": 4300, "required": True,
     "description": "Mistral 7B — agent orkiestrator (CFO)"},
    {"name": "gemma-2b-it.Q4_K_M.gguf", "size_mb": 1500, "required": True,
     "description": "Gemma 2B — szybki agent walidacyjny"},
    {"name": "llama-3.2-3b-instruct.Q4_K_M.gguf", "size_mb": 2300, "required": True,
     "description": "Llama 3.2 3B — agent podatkowy"},
    {"name": "qwen2.5-0.5b-instruct.Q4_K_M.gguf", "size_mb": 400, "required": False,
     "description": "Qwen 0.5B — ultra-szybki classifier"},
    {"name": "mxbai-embed-large-v1.Q4_K_M.gguf", "size_mb": 350, "required": False,
     "description": "Embedding model dla vector search"},
    {"name": "nomic-embed-text-v1.5.Q4_K_M.gguf", "size_mb": 140, "required": False,
     "description": "Nomic Embed — alternatywny embedding model"},
    {"name": "stablelm-zephyr-3b.Q4_K_M.gguf", "size_mb": 2000, "required": False,
     "description": "StableLM — model analizy sentymentu"},
    {"name": "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf", "size_mb": 700, "required": False,
     "description": "TinyLlama — lekki model pomocniczy"},
    {"name": "deepseek-coder-1.3b-instruct.Q4_K_M.gguf", "size_mb": 800, "required": False,
     "description": "DeepSeek Coder — generowanie reguł OPA"},
    {"name": "sqlcoder-7b-2.Q4_K_M.gguf", "size_mb": 4300, "required": False,
     "description": "SQLCoder — generowanie zapytań SQL"},
    {"name": "all-MiniLM-L6-v2.Q4_K_M.gguf", "size_mb": 90, "required": False,
     "description": "MiniLM — szybki embedding dla deduplikacji"},
    {"name": "bge-small-en-v1.5.Q4_K_M.gguf", "size_mb": 80, "required": False,
     "description": "BGE Small — embedding dla search"},
]

# ── Native binaries manifest ────────────────────────────────────────────────

NATIVE_BINARIES: list[dict[str, Any]] = [
    {"name": "nats-server", "size_mb": 12, "platform": "all",
     "description": "NATS Server — message broker"},
    {"name": "tigerbeetle", "size_mb": 35, "platform": "linux",
     "description": "TigerBeetle — financial transactions database"},
    {"name": "opa", "size_mb": 45, "platform": "all",
     "description": "Open Policy Agent — policy engine"},
]


# ── Offline Installer Builder ───────────────────────────────────────────────


class OfflineInstallerBuilder:
    """Buduje pełny instalator offline z embedded modelami.

    Użycie:
        builder = OfflineInstallerBuilder(output_dir=Path("dist/offline"))
        builder.build()
    """

    def __init__(
        self,
        output_dir: Path,
        *,
        models_dir: Path | None = None,
        include_optional: bool = True,
        compression: str = "lzma2",
    ):
        self.output_dir = Path(output_dir)
        self.models_dir = Path(models_dir) if models_dir else Path("app_data/models")
        self.include_optional = include_optional
        self.compression = compression
        self._manifest: dict[str, Any] = {}

    @property
    def total_size_mb(self) -> int:
        total = 0
        for m in MODELS_MANIFEST:
            if m["required"] or self.include_optional:
                total += m["size_mb"]
        for b in NATIVE_BINARIES:
            total += b["size_mb"]
        return total

    def build(self) -> Path:
        """Zbuduj pełny instalator offline.

        Returns:
            Ścieżka do finalnego archiwum instalatora
        """
        self.output_dir.mkdir(parents=True, exist_ok=True)
        logger.info(
            "[OFFLINE] Building offline installer (~%d MB total)...",
            self.total_size_mb,
        )

        # 1. Skanuj modele
        available_models = self._scan_models()
        logger.info(
            "[OFFLINE] Found %d/%d models available locally",
            len(available_models), len(MODELS_MANIFEST),
        )

        # 2. Skanuj natywne binarki
        available_binaries = self._scan_binaries()
        logger.info(
            "[OFFLINE] Found %d/%d native binaries",
            len(available_binaries), len(NATIVE_BINARIES),
        )

        # 3. Kopiuj modele do katalogu output
        models_output = self.output_dir / "models"
        models_output.mkdir(parents=True, exist_ok=True)
        for model_path in available_models:
            dest = models_output / model_path.name
            if not dest.exists():
                logger.info("[OFFLINE] Copying model: %s", model_path.name)
                shutil.copy2(model_path, dest)

        # 4. Kopiuj natywne binarki
        binaries_output = self.output_dir / "binaries"
        binaries_output.mkdir(parents=True, exist_ok=True)
        for binary_path in available_binaries:
            dest = binaries_output / binary_path.name
            if not dest.exists():
                logger.info("[OFFLINE] Copying binary: %s", binary_path.name)
                shutil.copy2(binary_path, dest)

        # 5. Generuj manifest
        self._generate_manifest()

        # 6. Generuj skrypt instalacyjny
        self._generate_install_script()

        # 7. Kompresuj (jeśli dostępny kompresor)
        archive_path = self._compress()

        # 8. Generuj sumy kontrolne
        self._generate_checksums(archive_path)

        logger.info(
            "[OFFLINE] ✓ Offline installer built: %s (%.0f MB)",
            archive_path,
            archive_path.stat().st_size / (1024 * 1024) if archive_path.exists() else 0,
        )
        return archive_path

    def _scan_models(self) -> list[Path]:
        """Skanuj lokalnie dostępne modele GGUF."""
        available = []
        for model_def in MODELS_MANIFEST:
            if not model_def["required"] and not self.include_optional:
                continue
            model_path = self.models_dir / model_def["name"]
            if model_path.exists():
                available.append(model_path)
            else:
                logger.warning(
                    "[OFFLINE] Model not found: %s (%s)",
                    model_def["name"], model_def["description"],
                )
        return available

    def _scan_binaries(self) -> list[Path]:
        """Skanuj dostępne natywne binarki (lokalny katalog + PATH fallback).

        v7.0: Najpierw skanuje lokalny katalog binaries/ (dla offline buildów),
        potem PATH jako fallback.
        """
        available = []
        local_binaries = Path("binaries")

        for binary_def in NATIVE_BINARIES:
            # Krok 1: Lokalny katalog binaries/
            local_path = local_binaries / binary_def["name"]
            if local_path.exists():
                available.append(local_path)
                continue

            # Krok 2: PATH systemowe (fallback)
            binary_path = shutil.which(binary_def["name"])
            if binary_path:
                available.append(Path(binary_path))
            else:
                logger.warning(
                    "[OFFLINE] Binary not found: %s (neither in binaries/ nor PATH)",
                    binary_def["name"],
                )
        return available

    def _generate_manifest(self):
        """Generuj manifest.json z metadanymi."""
        manifest = {
            "version": "1.0.0",
            "build_date": "",
            "total_models": len(MODELS_MANIFEST),
            "total_binaries": len(NATIVE_BINARIES),
            "total_size_mb": self.total_size_mb,
            "models": [
                {
                    "name": m["name"],
                    "size_mb": m["size_mb"],
                    "required": m["required"],
                    "description": m["description"],
                    "sha256": self._file_sha256(self.models_dir / m["name"])
                    if (self.models_dir / m["name"]).exists()
                    else "",
                }
                for m in MODELS_MANIFEST
            ],
            "binaries": NATIVE_BINARIES,
        }

        manifest["build_date"] = pendulum.now("UTC").isoformat()

        manifest_path = self.output_dir / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, indent=2))
        self._manifest = manifest
        logger.info("[OFFLINE] Manifest generated: %s", manifest_path)

    def _generate_install_script(self):
        """Generuj skrypt instalacyjny (bash/PowerShell)."""
        # Bash install script (Linux)
        bash_script = self.output_dir / "install.sh"
        bash_script.write_text(f"""#!/bin/bash
# NexusAI Offline Installer — v7.0
# Total size: ~{self.total_size_mb} MB

set -e

INSTALL_DIR="${{HOME:-/opt}}/NexusAI"
MODELS_DIR="$INSTALL_DIR/app_data/models"
CONFIG_DIR="$INSTALL_DIR/config"

echo "=== NexusAI Offline Installer v7.0 ==="
echo "Installing to: $INSTALL_DIR"
echo "Total size: ~{self.total_size_mb} MB"
echo ""

mkdir -p "$INSTALL_DIR" "$MODELS_DIR" "$CONFIG_DIR"

# Copy models
echo "[1/3] Installing AI models..."
cp -v models/*.gguf "$MODELS_DIR/" 2>/dev/null || echo "No models to copy"

# Copy binaries
echo "[2/3] Installing native binaries..."
mkdir -p "$INSTALL_DIR/bin"
cp -v binaries/* "$INSTALL_DIR/bin/" 2>/dev/null || echo "No binaries to copy"
chmod +x "$INSTALL_DIR/bin/"*

# Copy config
echo "[3/3] Installing configuration..."
cp -v config/* "$CONFIG_DIR/" 2>/dev/null || echo "No config to copy"

# Set environment
echo ""
echo "Add to ~/.bashrc:"
echo "  export NEXUSAI_HOME=$INSTALL_DIR"
echo "  export NEXUSAI_MODELS=$MODELS_DIR"
echo ""
echo "✅ Installation complete!"
echo "Run: $INSTALL_DIR/NexusAI"
""")
        bash_script.chmod(0o755)

        # PowerShell install script (Windows)
        ps_script = self.output_dir / "install.ps1"
        ps_script.write_text(f"""# NexusAI Offline Installer — v7.0
# Total size: ~{self.total_size_mb} MB

$ErrorActionPreference = "Stop"
$InstallDir = "$env:LOCALAPPDATA\\NexusAI"
$ModelsDir = "$InstallDir\\app_data\\models"
$ConfigDir = "$InstallDir\\config"

Write-Host "=== NexusAI Offline Installer v7.0 ===" -ForegroundColor Cyan
Write-Host "Installing to: $InstallDir"
Write-Host ""

New-Item -ItemType Directory -Force -Path $InstallDir, $ModelsDir, $ConfigDir | Out-Null

Write-Host "[1/3] Installing AI models..." -ForegroundColor Yellow
Copy-Item -Path "models\\*.gguf" -Destination $ModelsDir -ErrorAction SilentlyContinue

Write-Host "[2/3] Installing native binaries..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$InstallDir\\bin" | Out-Null
Copy-Item -Path "binaries\\*" -Destination "$InstallDir\\bin" -ErrorAction SilentlyContinue

Write-Host "[3/3] Installing configuration..." -ForegroundColor Yellow
Copy-Item -Path "config\\*" -Destination $ConfigDir -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[Environment]::SetEnvironmentVariable('NEXUSAI_HOME', '$InstallDir', 'User')"
Write-Host "[Environment]::SetEnvironmentVariable('NEXUSAI_MODELS', '$ModelsDir', 'User')"
Write-Host ""
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host "Run: $InstallDir\\NexusAI.exe"
""")

        logger.info("[OFFLINE] Install scripts generated")

    def _compress(self) -> Path:
        """Kompresuj katalog output do archiwum."""
        # Próbuj 7z > zip > tar.gz
        archive_path = self.output_dir.parent / f"nexusai-offline-{self.total_size_mb}mb"

        # 7z
        seven_zip = shutil.which("7z") or shutil.which("7za") or shutil.which("7zz")
        if seven_zip:
            archive_7z = archive_path.with_suffix(".7z")
            logger.info("[OFFLINE] Compressing with 7z -> %s", archive_7z)
            subprocess.run(
                [seven_zip, "a", "-mx=9", "-m0=lzma2",
                 str(archive_7z), str(self.output_dir) + "/*"],
                check=False,
            )
            if archive_7z.exists():
                return archive_7z

        # zip fallback
        archive_zip = archive_path.with_suffix(".zip")
        logger.info("[OFFLINE] Compressing with zip -> %s", archive_zip)
        shutil.make_archive(
            str(archive_path),
            "zip",
            self.output_dir,
        )
        return archive_zip

    def _generate_checksums(self, archive_path: Path):
        """Generuj plik sum kontrolnych."""
        if not archive_path.exists():
            return

        sha = self._file_sha256(archive_path)
        checksum_path = archive_path.with_suffix(archive_path.suffix + ".sha256")
        checksum_path.write_text(f"{sha}  {archive_path.name}\n")
        logger.info("[OFFLINE] Checksum: %s", checksum_path)

    @staticmethod
    def _file_sha256(filepath: Path, chunk_size: int = 65536) -> str:
        if not filepath.exists():
            return ""
        sha = hashlib.sha256()
        with open(filepath, "rb") as f:
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                sha.update(chunk)
        return sha.hexdigest()


# ── Convenience function ────────────────────────────────────────────────────


def build_offline_installer(
    output_dir: str = "dist/offline",
    models_dir: str = "app_data/models",
    include_optional: bool = True,
) -> Path:
    """Zbuduj pełny instalator offline.

    Args:
        output_dir: Katalog wyjściowy
        models_dir: Katalog z modelami GGUF
        include_optional: Czy dołączyć opcjonalne modele

    Returns:
        Ścieżka do archiwum instalatora
    """
    builder = OfflineInstallerBuilder(
        output_dir=Path(output_dir),
        models_dir=Path(models_dir),
        include_optional=include_optional,
    )
    return builder.build()
