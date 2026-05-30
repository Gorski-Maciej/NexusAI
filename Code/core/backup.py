# core/backup.py
import zipfile
import io
import os
import base64
import hashlib
import logging
from datetime import datetime, timedelta
from pathlib import Path

logger = logging.getLogger("nexus.core.backup")

# Próbuj zaimportować cryptography (opcjonalne)
try:
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.primitives import padding
    HAS_CRYPTOGRAPHY = True
except ImportError:
    HAS_CRYPTOGRAPHY = False
    logger.warning("[BACKUP] cryptography not available; using plain ZIP (no encryption)")


class BackupManager:
    """Zarządza pakowaniem i szyfrowaniem bazy danych.
    Rozwiązanie 18: Szyfrowanie AES-256 backupów przy użyciu klucza z konfiguracji.
    """

    def __init__(self, config):
        self.config = config
        self.backup_dir = Path(config.base_dir) / "backups"
        self.backup_dir.mkdir(exist_ok=True)

    def _derive_encryption_key(self, password: str, salt: bytes | None = None) -> tuple[bytes, bytes]:
        """Derivuje 32-bajtowy klucz AES z hasła przy użyciu PBKDF2 z losową solą (Rozwiązanie 18).
        Zwraca (klucz, sól). Sól jest przechowywana razem z danymi.
        """
        if salt is None:
            salt = os.urandom(16)
        key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000, dklen=32)
        return key, salt

    def _encrypt_aes_cbc(self, data: bytes, key: bytes) -> bytes:
        """Szyfruje dane AES-256-CBC z losowym IV. Zwraca sól (16B) + IV (16B) + ciphertext."""
        iv = os.urandom(16)
        padder = padding.PKCS7(128).padder()
        padded_data = padder.update(data) + padder.finalize()
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(padded_data) + encryptor.finalize()
        return iv + ciphertext

    def _decrypt_aes_cbc(self, data: bytes, key: bytes) -> bytes:
        """Odszyfrowuje dane AES-256-CBC. Oczekuje IV (16B) + ciphertext."""
        iv = data[:16]
        ciphertext = data[16:]
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
        decryptor = cipher.decryptor()
        padded_data = decryptor.update(ciphertext) + decryptor.finalize()
        unpadder = padding.PKCS7(128).unpadder()
        return unpadder.update(padded_data) + unpadder.finalize()

    def create_encrypted_zip(self, password: str = "") -> str:
        """Tworzy zaszyfrowany (AES-256-CBC) lub zwykły ZIP z bazami danych.

        Args:
            password: Hasło do szyfrowania. Jeśli puste, używa klucza z config.encryption_key.
        """
        if not password:
            password = getattr(self.config, "encryption_key", "") or os.getenv("NEXUS_ENCRYPTION_KEY", "")

        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        zip_buffer = io.BytesIO()

        # 1. Pakowanie plików
        files_to_backup = [
            self.config.sqlite_path,
            self.config.duckdb_path,
        ]

        # Dodaj ścieżkę do LanceDB (vector store) jeśli istnieje
        lancedb_path = Path(self.config.base_dir) / "nexus_lancedb"
        if lancedb_path.exists():
            files_to_backup.append(lancedb_path)

        with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
            for file_path in files_to_backup:
                path = Path(file_path) if not isinstance(file_path, Path) else file_path
                if path.exists():
                    zf.write(str(path), arcname=path.name)

        zip_data = zip_buffer.getvalue()

        # Szyfruj AES-256-CBC jeśli dostępne jest cryptography i hasło
        if HAS_CRYPTOGRAPHY and password:
            # Deriwacja z losową solą (Rozwiązanie 18 - bezpieczeństwo)
            key, salt = self._derive_encryption_key(password, salt=None)
            encrypted_data = self._encrypt_aes_cbc(zip_data, key)
            # Format: nagłówek (9B) + sól (16B) + IV (16B) + ciphertext
            final_data = b"NEXUSENC1" + salt + encrypted_data
            ext = ".enc"
            logger.info("[BACKUP] Encrypted backup with AES-256-CBC (size: %d -> %d bytes)", len(zip_data), len(final_data))
        else:
            final_data = zip_data
            ext = ".zip"
            if not HAS_CRYPTOGRAPHY:
                logger.warning("[BACKUP] cryptography not installed; backup is NOT encrypted")

        final_path = self.backup_dir / f"backup_{timestamp}{ext}"
        with open(final_path, "wb") as f:
            f.write(final_data)

        self.prune_old_backups(keep_days=30)
        logger.info("[BACKUP] Created backup: %s (%.2f MB)", final_path.name, len(final_data) / (1024 * 1024))
        return str(final_path)

    def decrypt_backup(self, backup_path: Path | str, password: str) -> bytes:
        """Odszyfrowuje backup AES-256-CBC."""
        backup_path = Path(backup_path)
        data = backup_path.read_bytes()

        if data.startswith(b"NEXUSENC1"):
            if not HAS_CRYPTOGRAPHY:
                raise RuntimeError("Cannot decrypt: cryptography library not available")
            if not password:
                raise ValueError("Password required to decrypt backup")
            # Format: nagłówek (9B) + sól (16B) + IV (16B) + ciphertext
            salt = data[9:25]  # 16 bajtów soli
            encrypted = data[25:]  # IV + ciphertext
            key, _ = self._derive_encryption_key(password, salt=salt)
            return self._decrypt_aes_cbc(encrypted, key)
        else:
            # Niezaszyfrowany ZIP
            return data

    def prune_old_backups(self, keep_days: int = 30) -> int:
        """Remove backups older than keep_days and return deleted count."""
        cutoff = datetime.now() - timedelta(days=keep_days)
        deleted = 0
        for backup in self.backup_dir.glob("backup_*"):
            try:
                modified = datetime.fromtimestamp(backup.stat().st_mtime)
            except FileNotFoundError:
                continue
            if modified < cutoff:
                backup.unlink(missing_ok=True)
                deleted += 1
        return deleted
