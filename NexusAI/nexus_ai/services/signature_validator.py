"""Signature validation placeholder.

X.509 certificate validation is not available (the `cryptography` package
has been removed from the project in favor of nexus-crypto, which does not
support asymmetric cryptography).
"""

from __future__ import annotations

from typing import final


@final
class SignatureValidator:
    """Weryfikacja podpisów elektronicznych w oparciu o listę zaufaną.

    Uwaga: X.509 certificate validation is not available — the ``cryptography``
    package has been removed. This class is a placeholder for future implementation.
    """

    def __init__(self, trusted_roots_paths: list[str]):
        raise ImportError(
            "SignatureValidator requires the `cryptography` package for X.509 support, "
            "which has been removed from the project. Re-add cryptography if X.509 "
            "certificate validation is needed."
        )

    def verify_certificate_chain(self, cert_to_verify: object) -> bool:
        raise ImportError(
            "SignatureValidator requires the `cryptography` package for X.509 support, "
            "which has been removed from the project."
        )
