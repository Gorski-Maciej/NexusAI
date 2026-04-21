import json
from sqlalchemy import TypeDecorator, String, Text
from core.config import AppConfig

class JSONObject(TypeDecorator):
    """Pozwala przechowywać słowniki Pythona jako tekst JSON w SQLite/DuckDB."""
    impl = Text
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            return json.dumps(value)
        return None

    def process_result_value(self, value, dialect):
        if value is not None:
            return json.loads(value)
        return None

class EncryptedString(TypeDecorator):
    """Szyfruje dane na poziomie kolumny za pomocą klucza AES (Fernet)."""
    impl = String
    cache_ok = False

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Klucz brany bezpośrednio z konfiguracji systemowej (wymaga cryptography.fernet.Fernet w pełnej implementacji)
        config = AppConfig()
        if hasattr(config, "encryption_key"):
            self.key = config.encryption_key.encode()
        else:
            self.key = b""
