# core/integrations/ksef_crypto.py
"""KSeF cryptographic provider using RSA-OAEP/PKCS1v15 encryption.

KSeF integration requires RSA asymmetric cryptography which is not available
in nexus-crypto (AEAD + Argon2id + SHA-256 only).
The `cryptography` package is used here as an optional dependency.
"""

from __future__ import annotations

import base64

import pendulum

# ── Optional: cryptography for RSA (niedostępne w nexus-crypto) ──────────────
try:
    from cryptography.hazmat.primitives import serialization as _serialization
    from cryptography.hazmat.primitives.asymmetric import padding as _asym_padding
    _HAS_CRYPTOGRAPHY = True
except ImportError:
    _HAS_CRYPTOGRAPHY = False


class KsefCryptoProvider:
    """Implementacja standardu bezpieczeństwa KSeF (MF).

    Wymaga opcjonalnego pakietu ``cryptography`` do obsługi RSA.
    Zainstaluj: pip install cryptography
    """

    def __init__(self, public_key_path: str):
        """Load RSA public key from PEM file.

        Args:
            public_key_path: Ścieżka do pliku .crt / .pem z kluczem publicznym MF.

        Raises:
            ImportError: Jeśli cryptography nie jest zainstalowane.
        """
        if not _HAS_CRYPTOGRAPHY:
            raise ImportError(
                "KsefCryptoProvider requires the `cryptography` package for RSA support. "
                "Install it with: pip install cryptography"
            )

        with open(public_key_path, "rb") as key_file:
            self.public_key = _serialization.load_pem_public_key(key_file.read())

    def encrypt_authorization_token(self, challenge: str, auth_token: str) -> str:
        """Szyfruje token autoryzacyjny połączony z wyzwaniem (challenge).

        Format: challenge + '|' + auth_token + '|' + timestamp

        Args:
            challenge: Wyzwanie z KSeF API.
            auth_token: Token autoryzacyjny.

        Returns:
            Zaszyfrowany token w base64.
        """
        if not _HAS_CRYPTOGRAPHY:
            raise ImportError(
                "KsefCryptoProvider requires the `cryptography` package. "
                "Install it with: pip install cryptography"
            )

        timestamp = int(pendulum.now().timestamp() * 1000)
        message = f"{challenge}|{auth_token}|{timestamp}".encode()

        encrypted = self.public_key.encrypt(
            message,
            _asym_padding.PKCS1v15(),  # Obowiązkowy standard KSeF
        )
        return base64.b64encode(encrypted).decode('utf-8')
