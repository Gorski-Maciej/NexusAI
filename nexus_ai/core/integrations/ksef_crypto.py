# core/integrations/ksef_crypto.py
"""KSeF cryptographic provider -- placeholder.

RSA asymmetric cryptography required for KSeF is not available
(the `cryptography` package has been removed from the project
in favor of nexus-crypto, which only supports symmetric AEAD).
"""

from __future__ import annotations


class KsefCryptoProvider:
    """Implementacja standardu bezpieczeństwa KSeF (MF).

    Uwaga: RSA encryption nie jest dostępne -- pakiet ``cryptography``
    został usunięty z projektu. KSeF integration requires the
    ``cryptography`` package to be re-added.
    """
    __slots__ = ()

    def __init__(self, public_key_path: str):
        raise ImportError(
            "KsefCryptoProvider requires the `cryptography` package for RSA support, "
            "which has been removed from the project. Re-add cryptography if KSeF "
            "integration is needed."
        )

    def encrypt_authorization_token(self, challenge: str, auth_token: str) -> str:
        raise ImportError(
            "KsefCryptoProvider requires the `cryptography` package for RSA support, "
            "which has been removed from the project."
        )
