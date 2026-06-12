# core/integrations/ksef/crypto.py
"""KSeF cryptographic operations (RSA encryption).

KSeF integration requires RSA asymmetric cryptography which is not available
in nexus-crypto (AEAD + Argon2id + SHA-256 only).
The `cryptography` package is used here as an optional dependency.
"""

from __future__ import annotations

import base64


class KsefCrypto:
    """Obsługa operacji kryptograficznych zgodnych ze specyfikacją MF.

    Wymaga opcjonalnego pakietu ``cryptography`` do obsługi RSA.
    Zainstaluj: pip install cryptography
    """

    @staticmethod
    def encrypt_challenge(challenge: str, timestamp: str, public_key_pem: bytes) -> str:
        """Szyfruje challenge + timestamp zgodnie z wymogami KSeF.

        Format: challenge + "|" + timestamp_iso_8601

        Args:
            challenge: Wyzwanie z KSeF API.
            timestamp: Znacznik czasu ISO 8601.
            public_key_pem: Klucz publiczny MF w formacie PEM.

        Returns:
            Zaszyfrowany challenge w base64.
        """
        try:
            from cryptography.hazmat.primitives import serialization
            from cryptography.hazmat.primitives.asymmetric import padding
        except ImportError:
            raise ImportError(
                "KsefCrypto requires the `cryptography` package for RSA support. "
                "Install it with: pip install cryptography"
            ) from None

        public_key = serialization.load_pem_public_key(public_key_pem)

        # Łączymy dane zgodnie ze specyfikacją
        payload = f"{challenge}|{timestamp}".encode()

        encrypted = public_key.encrypt(
            payload,
            padding.PKCS1v15(),  # KLUCZOWE: MF nie akceptuje OAEP
        )
        return base64.b64encode(encrypted).decode("utf-8")

    @staticmethod
    def build_auth_xml(nip: str, encrypted_token: str) -> str:
        """Buduje XML żądania InitSessionToken dla KSeF.

        Args:
            nip: NIP podatnika.
            encrypted_token: Zaszyfrowany token autoryzacyjny.

        Returns:
            String XML zgodny ze schematem KSeF.
        """
        xml = f"""
        <ns2:InitSessionTokenRequest>
            <ns2:Context>
                <DocumentType>
                    <FormCode>FA</FormCode>
                </DocumentType>
                <Token>{encrypted_token}</Token>
            </ns2:Context>
        </ns2:InitSessionTokenRequest>
        """
        return xml
