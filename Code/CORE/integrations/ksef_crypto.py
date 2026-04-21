# core/integrations/ksef_crypto.py
import base64
from datetime import datetime
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import padding

class KsefCryptoProvider:
    """Implementacja standardu bezpieczeństwa KSeF (MF)."""

    def __init__(self, public_key_path: str):
        # Klucze publiczne MF są dostarczane jako pliki .crt / .pem
        with open(public_key_path, "rb") as key_file:
            self.public_key = serialization.load_pem_public_key(key_file.read())

    def encrypt_authorization_token(self, challenge: str, auth_token: str) -> str:
        """
        Szyfruje token autoryzacyjny połączony z wyzwaniem (challenge).
        Format: challenge + '|' + auth_token + '|' + timestamp
        """
        timestamp = int(datetime.now().timestamp() * 1000)
        message = f"{challenge}|{auth_token}|{timestamp}".encode('utf-8')

        encrypted = self.public_key.encrypt(
            message,
            padding.PKCS1v15() # Obowiązkowy standard
        )
        return base64.b64encode(encrypted).decode('utf-8')
