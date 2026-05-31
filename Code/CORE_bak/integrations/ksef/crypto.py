# core/integrations/ksef/crypto.py
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
import base64
from datetime import datetime

class KsefCrypto:
    """Obsługa operacji kryptograficznych zgodnych ze specyfikacją MF."""

    @staticmethod
    def encrypt_challenge(challenge: str, timestamp: str, public_key_pem: bytes) -> str:
        """
        Szyfruje challenge + timestamp zgodnie z wymogami KSeF.
        Format: challenge + "|" + timestamp_iso_8601
        """
        public_key = serialization.load_pem_public_key(public_key_pem)

        # Łączymy dane zgodnie ze specyfikacją
        payload = f"{challenge}|{timestamp}".encode('utf-8')

        encrypted = public_key.encrypt(
            payload,
            padding.PKCS1v15() # KLUCZOWE: MF nie akceptuje OAEP
        )
        return base64.b64encode(encrypted).decode('utf-8')

    @staticmethod
    def build_auth_xml(nip: str, encrypted_token: str) -> str:
        # Poniżej placeholder generatora XML
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
