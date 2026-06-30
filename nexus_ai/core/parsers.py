# core/parsers.py
import re
from decimal import Decimal, InvalidOperation
from functools import lru_cache
from typing import Any


class DataParser:
    """Narzędzia do czyszczenia danych wyjściowych z AI."""

    @staticmethod
    def to_decimal(value: Any) -> Decimal:
        """Konwertuje dowolny string/liczbę na Decimal (bezpieczny finansowo)."""
        if value is None:
            return Decimal("0.00")

        # Usuwanie spacji, walut i zamiana przecinka na kropkę -- walrus operator
        clean_val = re.sub(r"[^\d.,-]", "", str(value)).replace(",", ".")
        try:
            return Decimal(clean_val)
        except InvalidOperation:
            return Decimal("0.00")

    @staticmethod
    @lru_cache(maxsize=512)
    def clean_nip(nip: str) -> str:
        """Normalizuje NIP do formatu 10 cyfr."""
        return re.sub(r"\D", "", str(nip))
