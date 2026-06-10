"""Signature validation for electronic signatures using X.509 certificates.

KSeF integration requires RSA/X.509 cryptography which is not available
in nexus-crypto (which only provides AEAD + Argon2id + SHA-256).
The `cryptography` package is used here as an optional dependency.
"""

from __future__ import annotations


# ── Optional: cryptography for X.509 certificates (niedostępne w nexus-crypto) ─
try:
    from cryptography import x509 as _x509
    from cryptography.hazmat.primitives.asymmetric import padding as _asym_padding
    _HAS_CRYPTOGRAPHY = True
except ImportError:
    _HAS_CRYPTOGRAPHY = False


class SignatureValidator:
    """Weryfikacja podpisów elektronicznych w oparciu o listę zaufaną.

    Wymaga opcjonalnego pakietu ``cryptography`` do obsługi X.509.
    Zainstaluj: pip install cryptography
    """

    def __init__(self, trusted_roots_paths: list[str]):
        if not _HAS_CRYPTOGRAPHY:
            raise ImportError(
                "SignatureValidator requires the `cryptography` package for X.509 support. "
                "Install it with: pip install cryptography"
            )
        # Lista zaufanych certyfikatów Root CA (np. pobranych z EUTL)
        self.trusted_roots = []
        for path in trusted_roots_paths:
            with open(path, "rb") as f:
                self.trusted_roots.append(_x509.load_pem_x509_certificate(f.read()))

    def verify_certificate_chain(self, cert_to_verify: object) -> bool:
        """Sprawdza, czy certyfikat z faktury PDF został wystawiony
        przez jeden z urzędów z listy zaufanej.

        Args:
            cert_to_verify: Obiekt x509.Certificate do zweryfikowania.

        Returns:
            True jeśli certyfikat jest zaufany, False w przeciwnym razie.
        """
        if not _HAS_CRYPTOGRAPHY:
            raise ImportError(
                "SignatureValidator requires the `cryptography` package. "
                "Install it with: pip install cryptography"
            )

        cert = cert_to_verify
        if not isinstance(cert, _x509.Certificate):
            return False

        for root in self.trusted_roots:
            try:
                # Weryfikacja podpisu certyfikatu przez Root CA
                root.public_key().verify(
                    cert.signature,
                    cert.tbs_certificate_bytes,
                    _asym_padding.PKCS1v15(),
                    cert.signature_hash_algorithm
                )
                return True
            except Exception:
                continue
        return False
