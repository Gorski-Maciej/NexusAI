# core/crypto.py
import os
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from core.config import AppConfig

class Vault:
    """Moduł do bezpiecznego szyfrowania danych aplikacyjnych w locie."""

    def __init__(self, config: AppConfig):
        # Tworzy mocny klucz Fernet na podstawie zmiennej środowiskowej
        configured_key = config.encryption_key.strip()
        if configured_key:
            master_key = configured_key.encode()
        else:
            env_key = os.getenv(config.sqlcipher_key_env, "").strip()
            master_key = env_key.encode() if env_key else os.urandom(32)

        # Deriwacja klucza (KDF) dla zwiększonego bezpieczeństwa
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=b"nexus-offline-ai-salt-v1",
            iterations=480000,
        )
        self._fernet = Fernet(base64.urlsafe_b64encode(kdf.derive(master_key)))

    def encrypt(self, plain_text: str) -> str:
        """Szyfruje tekst (np. hasła do ERP, API keys)."""
        if not plain_text:
            return plain_text
        return self._fernet.encrypt(plain_text.encode()).decode()

    def decrypt(self, encrypted_text: str) -> str:
        if not encrypted_text:
            return encrypted_text
        return self._fernet.decrypt(encrypted_text.encode()).decode()
