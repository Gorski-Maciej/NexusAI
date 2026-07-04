# core/integrations/ksef/crypto.py
"""KSeF cryptographic operations -- placeholder.

RSA asymmetric cryptography required for KSeF is not available
(the `cryptography` package has been removed).
"""

from __future__ import annotations


class KsefCrypto:
    """Obsługa operacji kryptograficznych zgodnych ze specyfikacją MF.

    Uwaga: RSA encryption nie jest dostępne -- pakiet ``cryptography``
    został usunięty z projektu.
    """
    __slots__ = ()

    @staticmethod
    def encrypt_challenge(challenge: str, timestamp: str, public_key_pem: bytes) -> str:
        raise ImportError(
            "KsefCrypto requires the `cryptography` package for RSA support, "
            "which has been removed from the project. Re-add cryptography if KSeF "
            "integration is needed."
        )

    @staticmethod
    def build_auth_xml(nip: str, encrypted_token: str) -> str:
        """Builds KSeF InitSessionToken XML."""
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
