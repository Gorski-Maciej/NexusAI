"""Signature validation for electronic signatures using X.509 certificates.

KSeF integration requires RSA/X.509 cryptography which is not available
in nexus-crypto (which only provides AEAD + Argon2id + SHA-256).
The `cryptography` package is used here as an optional dependency.
"""

from __future__ import annotations


class SignatureValidator:
    """Weryfikacja podpisów elektronicznych w oparciu o listę zaufaną.

    Wymaga opcjonalnego pakietu ``cryptography`` do obsługi X.509.
    Zainstaluj: pip install cryptography
    """

    def __init__(self, trusted_roots_paths: list[str]):
        # Lista zaufanych certyfikatów Root CA (np. pobranych z EUTL)
        self.trusted_roots = []
        try:
            from cryptography import x509
            for path in trusted_roots_paths:
                with open(path, "rb") as f:
                    self.trusted_roots.append(x509.load_pem_x509_certificate(f.read()))
        except ImportError:
            raise ImportError(
                "SignatureValidator requires the `cryptography` package for X.509 support. "
                "Install it with: pip install cryptography"
            ) from None

    def verify_certificate_chain(self, cert_to_verify: object) -> bool:
        """Sprawdza, czy certyfikat z faktury PDF został wystawiony
        przez jeden z urzędów z listy zaufanej.

        Args:
            cert_to_verify: Obiekt x509.Certificate do zweryfikowania.

        Returns:
            True jeśli certyfikat jest zaufany, False w przeciwnym razie.
        """
        try:
            from cryptography import x509
            from cryptography.hazmat.primitives.asymmetric import padding
        except ImportError:
            raise ImportError(
                "SignatureValidator requires the `cryptography` package. "
                "Install it with: pip install cryptography"
            ) from None

        cert = cert_to_verify
        if not isinstance(cert, x509.Certificate):
            return False

        for root in self.trusted_roots:
            try:
                # Weryfikacja podpisu certyfikatu przez Root CA
                root.public_key().verify(
                    cert.signature,
                    cert.tbs_certificate_bytes,
                    padding.PKCS1v15(),
                    cert.signature_hash_algorithm
                )
                return True
            except Exception:
                continue
        return False
