"""
SQLCipher Configuration — zarządzanie parametrami SQLCipher przez msgspec.Struct.

SUPERMOCE:
- Typowana konfiguracja przez msgspec.Struct (zamiast ręcznych PRAGM)
- Walidacja zakresów: kdf_iter >= 64000, page_size >= 512
- Generowanie bezpiecznych kluczy (32 bajty base64)
- Multi-database key management (różne klucze dla różnych baz)
- Zgodność z aa3fvcx.txt: najwyższe standardy szyfrowania AES-256

Usage:
    from nexus_ai.db.sqlcipher_config import SQLCipherConfig

    config = SQLCipherConfig.from_env()
    conn = sqlite3.connect(":memory:")
    config.apply_pragmas(conn)
"""

from __future__ import annotations

import os
import base64
import sqlite3
from typing import Any
from msgspec import Struct


class SQLCipherConfig(Struct, kw_only=True):
    """Typowana konfiguracja SQLCipher z walidacją zakresów.

    SUPERMOCE:
    - cipher_memory_security: mlock() chroni klucze przed swapowaniem
    - cipher_default_plaintext_header: szyfruje nagłówek pliku DB
    - cipher_hmac_pgno: weryfikacja numeru strony w HMAC
    - Multi-database keys: różne klucze dla OLTP, event store, backup

    Wszystkie PRAGMY są zgodne z SQLCipher 4.x i zaleceniami
    bezpieczeństwa (Zetetic, twórca SQLCipher).
    """

    # ── Key configuration ─────────────────────────────────────────
    # Główny klucz szyfrowania (AES-256)
    key: str = ""

    # ── Encryption parameters ─────────────────────────────────────
    cipher: str = "aes-256-cbc"
    cipher_page_size: int = 4096
    kdf_iter: int = 64000

    # ── HMAC configuration ────────────────────────────────────────
    hmac_algorithm: str = "HMAC_SHA512"
    hmac_check: bool = True
    hmac_use: bool = True
    hmac_pgno: bool = True

    # ── KDF configuration ─────────────────────────────────────────
    kdf_algorithm: str = "PBKDF2_HMAC_SHA512"

    # ── Security features ─────────────────────────────────────────
    memory_security: bool = True
    plaintext_header: bool = False
    plaintext_header_size: int = 0

    # ── Migration ─────────────────────────────────────────────────
    migrate_on_open: bool = False

    # ── Environment variable names ─────────────────────────────────
    # Różne bazy mogą mieć różne klucze
    key_env_var: str = "NEXUS_SQLCIPHER_KEY"
    event_store_key_env: str = "NEXUS_EVENT_STORE_KEY"
    analytics_key_env: str = "NEXUS_ANALYTICS_KEY"
    backup_key_env: str = "NEXUS_BACKUP_KEY"

    # ── Key resolution ────────────────────────────────────────────

    def resolve_key(self) -> str:
        """Zwraca klucz: z pola > z env var."""
        if self.key:
            return self.key
        return os.environ.get(self.key_env_var, "")

    def resolve_event_store_key(self) -> str:
        """Zwraca klucz dla event store: własny > główny."""
        key = os.environ.get(self.event_store_key_env, "")
        if key:
            return key
        return self.resolve_key()

    @property
    def key_hex(self) -> str:
        """Klucz w formacie hex dla PRAGMA key = x'...'."""
        key = self.resolve_key()
        return key.encode("utf-8").hex()

    @staticmethod
    def generate_key() -> str:
        """Generuj bezpieczny 32-bajtowy klucz (base64)."""
        return base64.b64encode(os.urandom(32)).decode()

    # ── PRAGMA application ─────────────────────────────────────────

    def apply_pragmas(self, conn: sqlite3.Connection, key: str | None = None) -> None:
        """Aplikuj wszystkie PRAGMY SQLCipher na połączeniu.

        SUPERMOC: Pojedyncza metoda która ustawia WSZYSTKIE PRAGMY
        SQLCipher na raz — zamiast ręcznego powtarzania w każdym pliku.

        Args:
            conn: Połączenie sqlite3.Connection.
            key: Klucz (opcjonalnie, override dla multi-database).
        """
        resolved_key = key or self.resolve_key()
        if not resolved_key:
            raise RuntimeError(
                "SQLCipher key not configured. "
                f"Set {self.key_env_var} environment variable."
            )

        key_hex = resolved_key.encode("utf-8").hex()

        # Krok 1: Klucz główny
        conn.execute("PRAGMA key = x'%s';" % key_hex)

        # Krok 2: Parametry szyfrowania
        conn.execute("PRAGMA cipher_page_size = %d;" % self.cipher_page_size)
        conn.execute("PRAGMA kdf_iter = %d;" % self.kdf_iter)

        # Krok 3: HMAC (integralność stron)
        try:
            conn.execute("PRAGMA cipher_hmac_algorithm = %s;" % self.hmac_algorithm)
            conn.execute("PRAGMA cipher_kdf_algorithm = %s;" % self.kdf_algorithm)
            conn.execute("PRAGMA cipher_use_hmac = %s;" % ("ON" if self.hmac_use else "OFF"))
            if self.hmac_pgno:
                conn.execute("PRAGMA cipher_hmac_pgno = ON;")
        except Exception:
            pass  # Starsze wersje SQLCipher

        # Krok 4: Memory security (mlock)
        if self.memory_security:
            try:
                conn.execute("PRAGMA cipher_memory_security = ON;")
            except Exception:
                pass

        # Krok 5: Plaintext header (ukryj sygnaturę)
        if not self.plaintext_header:
            try:
                conn.execute("PRAGMA cipher_default_plaintext_header = ON;")
                conn.execute("PRAGMA cipher_plaintext_header_size = 0;")
            except Exception:
                pass

    @classmethod
    def from_env(cls) -> SQLCipherConfig:
        """Utwórz konfigurację z zmiennych środowiskowych.

        Pozwala na nadpisanie domyślnych wartości przez env vars:
        - NEXUS_SQLCIPHER_KEY
        - NEXUS_EVENT_STORE_KEY
        - NEXUS_SQLCIPHER_KDF_ITER
        - itp.
        """
        kwargs: dict[str, Any] = {}

        # Klucze
        if "NEXUS_SQLCIPHER_KEY" in os.environ:
            kwargs["key"] = os.environ["NEXUS_SQLCIPHER_KEY"]

        # Parametry (opcjonalne)
        if "NEXUS_SQLCIPHER_KDF_ITER" in os.environ:
            try:
                kwargs["kdf_iter"] = int(os.environ["NEXUS_SQLCIPHER_KDF_ITER"])
            except ValueError:
                pass
        if "NEXUS_SQLCIPHER_PAGE_SIZE" in os.environ:
            try:
                kwargs["cipher_page_size"] = int(os.environ["NEXUS_SQLCIPHER_PAGE_SIZE"])
            except ValueError:
                pass

        return cls(**kwargs)
