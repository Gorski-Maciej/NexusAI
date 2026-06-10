# core/backup.py
"""Backup manager using nexus-crypto AEAD (ChaCha20-Poly1305).

Zgodnie z aa3fvcx.txt:
- ChaCha20-Poly1305 AEAD + Argon2id KDF (nexus-crypto, Rust+PyO3)
- Legacy NEXUSENC1 (AES-256-CBC + PBKDF2) wspierany dla kompatybilności wstecznej
"""
import io
import os
import zipfile
from pathlib import Path

import nexus_crypto
import pendulum
from structlog import get_logger

logger = get_logger("nexus.core.backup")

# ── Optional: cryptography for legacy NEXUSENC1 (AES-256-CBC) compatibility ───
try:
    from cryptography.hazmat.primitives import padding as _crypto_padding
    from cryptography.hazmat.primitives.ciphers import Cipher as _Cipher, algorithms as _algos, modes as _modes
    _HAS_CRYPTOGRAPHY = True
except ImportError:
    _HAS_CRYPTOGRAPHY = False


class BackupManager:
    """Zarządza pakowaniem i szyfrowaniem bazy danych.

    Szyfrowanie AEAD (ChaCha20-Poly1305) backupów przy użyciu klucza z konfiguracji.
    """

    def __init__(self, config):
        self.config = config
        self.backup_dir = Path(config.base_dir) / "backups"
        self.backup_dir.mkdir(exist_ok=True)

    def create_encrypted_zip(self, password: str = "") -> str:
        """Tworzy zaszyfrowany (AEAD) lub zwykły ZIP z bazami danych.

        Args:
            password: Hasło do szyfrowania. Jeśli puste, używa klucza z config.encryption_key.
        """
        if not password:
            password = getattr(self.config, "encryption_key", "") or os.getenv("NEXUS_ENCRYPTION_KEY", "")

        timestamp = pendulum.now().format("YYYYMMDD_HHmm")
        zip_buffer = io.BytesIO()

        # 1. Pakowanie plików
        files_to_backup = [
            self.config.sqlite_path,
            self.config.duckdb_path,
        ]

        # Vector store (sqlite-vec) jest włączony do sqlite_path

        with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
            for file_path in files_to_backup:
                path = Path(file_path) if not isinstance(file_path, Path) else file_path
                if path.exists():
                    zf.write(str(path), arcname=path.name)

        zip_data = zip_buffer.getvalue()

        # Szyfruj AEAD jeśli dostępne jest hasło
        if password and zip_data:
            # Derive 32-byte key using Argon2id (nexus-crypto)
            # Format: nagłówek (9B) + sól (16B) + nonce (12B) + ciphertext
            key, salt = nexus_crypto.derive_key(password)
            encrypted = nexus_crypto.encrypt(key, zip_data)
            # Header: magic (9B) + salt (16B) + encrypted (nonce+ciphertext)
            final_data = b"NEXUSAENC" + salt + encrypted
            ext = ".enc"
            logger.info(
                "[BACKUP] Encrypted backup with ChaCha20-Poly1305 (size: %d -> %d bytes)",
                len(zip_data), len(final_data),
            )
        else:
            final_data = zip_data
            ext = ".zip"
            if not password:
                logger.warning("[BACKUP] No password provided; backup is NOT encrypted")

        final_path = self.backup_dir / f"backup_{timestamp}{ext}"
        with open(final_path, "wb") as f:
            f.write(final_data)

        self.prune_old_backups(keep_days=30)
        logger.info("[BACKUP] Created backup: %s (%.2f MB)", final_path.name, len(final_data) / (1024 * 1024))
        return str(final_path)

    def decrypt_backup(self, backup_path: Path | str, password: str) -> bytes:
        """Odszyfrowuje backup AEAD (ChaCha20-Poly1305).

        Obsługuje zarówno nowy format ``NEXUSAENC`` (ChaCha20-Poly1305 + Argon2id)
        jak i legacy ``NEXUSENC1`` (AES-256-CBC + PBKDF2) dla kompatybilności wstecznej.
        """
        backup_path = Path(backup_path)
        data = backup_path.read_bytes()

        if data.startswith(b"NEXUSAENC"):
            # Nowy format: ChaCha20-Poly1305 + Argon2id
            if not password:
                raise ValueError("Password required to decrypt backup")
            salt = data[9:25]
            encrypted = data[25:]
            key, _ = nexus_crypto.derive_key(password, salt=salt)
            return nexus_crypto.decrypt(key, encrypted)

        elif data.startswith(b"NEXUSENC1"):
            # Legacy format (AES-256-CBC + PBKDF2) — wsteczna kompatybilność
            if not password:
                raise ValueError("Password required to decrypt legacy backup")
            if not _HAS_CRYPTOGRAPHY:
                raise ModuleNotFoundError(
                    "Legacy backup (NEXUSENC1) requires the `cryptography` package. "
                    "Install it with: pip install cryptography\n"
                    "Or decrypt this backup on a system that still has cryptography installed, "
                    "then re-encrypt with: python -m nexus.backup"
                )
            salt = data[9:25]
            encrypted = data[25:]
            # PBKDF2 key derivation (legacy — używane tylko dla NEXUSENC1)
            import hashlib
            key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000, dklen=32)
            # AES-256-CBC decrypt
            iv = encrypted[:16]
            ciphertext = encrypted[16:]
            cipher = _Cipher(_algos.AES(key), _modes.CBC(iv))
            decryptor = cipher.decryptor()
            padded_data = decryptor.update(ciphertext) + decryptor.finalize()
            unpadder = _crypto_padding.PKCS7(128).unpadder()
            return unpadder.update(padded_data) + unpadder.finalize()

        else:
            # Niezaszyfrowany ZIP
            return data

    def prune_old_backups(self, keep_days: int = 30) -> int:
        """Remove backups older than keep_days and return deleted count."""
        cutoff = pendulum.now().subtract(days=keep_days)
        deleted = 0
        for backup in self.backup_dir.glob("backup_*"):
            try:
                modified = pendulum.from_timestamp(backup.stat().st_mtime)
            except FileNotFoundError:
                continue
            if modified < cutoff:
                backup.unlink(missing_ok=True)
                deleted += 1
        return deleted
