# ui/validators.py
import re
from decimal import Decimal, InvalidOperation


class FormValidator:
    """Zestaw reguł walidacji dla faktur i kontrahentów."""

    @staticmethod
    def validate_nip(nip: str) -> bool:
        """Walidacja polskiego NIP (10 cyfr, bez myślników)."""
        if not nip:
            return False
        clean_nip = re.sub(r"\D", "", nip)
        if len(clean_nip) != 10:
            return False

        # Wagi dla sumy kontrolnej NIP
        weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
        try:
            checksum = sum(int(clean_nip[i]) * weights[i] for i in range(9))
            return (checksum % 11) == int(clean_nip[9])
        except (ValueError, IndexError):
            return False

    @staticmethod
    def validate_currency_amount(value: str) -> tuple[bool, str]:
        """Sprawdza czy kwota jest poprawną liczbą finansową."""
        if not value:
            return False, "Pole wymagane"
        try:
            # Obsługa przecinka i kropki
            val = Decimal(value.replace(",", "."))
            if val < 0:
                return False, "Kwota nie może być ujemna"
            return True, ""
        except InvalidOperation:
            return False, "Nieprawidłowy format kwoty"
