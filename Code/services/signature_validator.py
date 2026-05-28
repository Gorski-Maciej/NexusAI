from typing import List

from cryptography import x509
from cryptography.hazmat.primitives.asymmetric import padding


class SignatureValidator:
    """Weryfikacja podpisów elektronicznych w oparciu o listę zaufaną."""

    def __init__(self, trusted_roots_paths: List[str]):
        # Lista zaufanych certyfikatów Root CA (np. pobranych z EUTL)
        self.trusted_roots = []
        for path in trusted_roots_paths:
            with open(path, "rb") as f:
                self.trusted_roots.append(x509.load_pem_x509_certificate(f.read()))

    def verify_certificate_chain(self, cert_to_verify: x509.Certificate) -> bool:
        """
        Sprawdza, czy certyfikat z faktury PDF został wystawiony
        przez jeden z urzędów z listy zaufanej.
        """
        for root in self.trusted_roots:
            try:
                # Weryfikacja podpisu certyfikatu przez Root CA
                root.public_key().verify(
                    cert_to_verify.signature,
                    cert_to_verify.tbs_certificate_bytes,
                    padding.PKCS1v15(),
                    cert_to_verify.signature_hash_algorithm
                )
                return True
            except Exception:
                continue
        return False
