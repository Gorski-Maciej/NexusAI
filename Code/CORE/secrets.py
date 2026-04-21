# core/secrets.py
import keyring
from core.logger import logger

class SecretsManager:
    """Ochrona kluczy API i haseł przy użyciu natywnego magazynu systemu operacyjnego."""
    SERVICE_NAME = "NexusAI_System"

    @staticmethod
    def save_secret(key_name: str, secret_value: str) -> None:
        try:
            keyring.set_password(SecretsManager.SERVICE_NAME, key_name, secret_value)
        except Exception as e:
            logger.error(f"Nie udało się zapisać sekretu '{key_name}' w systemie: {e}")
            raise

    @staticmethod
    def get_secret(key_name: str) -> str | None:
        try:
            return keyring.get_password(SecretsManager.SERVICE_NAME, key_name)
        except Exception as e:
            logger.error(f"Nie udało się odczytać sekretu '{key_name}': {e}")
            return None

    @staticmethod
    def delete_secret(key_name: str) -> None:
        try:
            keyring.delete_password(SecretsManager.SERVICE_NAME, key_name)
        except keyring.errors.PasswordDeleteError as e:
            logger.error(f"Nie udało się usunąć sekretu '{key_name}': {e}")
