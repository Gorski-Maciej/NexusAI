# pipeline/normalizer.py
import dateparser
from decimal import Decimal
import re

class DataNormalizer:
    """Czyści i standaryzuje dane wyjściowe z AI pod formaty DB/ERP."""

    @staticmethod
    def normalize_date(raw_date: str) -> str:
        """Konwertuje dowolny format daty na ISO (YYYY-MM-DD)."""
        if not raw_date: return ""
        dt = dateparser.parse(raw_date, settings={'DATE_ORDER': 'DMY'})
        return dt.strftime("%Y-%m-%d") if dt else raw_date

    @staticmethod
    def normalize_nip(nip: str) -> str:
        """Usuwa myślniki i prefiksy krajowe (np. PL)."""
        clean = re.sub(r'[^0-9]', '', str(nip))
        if len(clean) > 10: clean = clean[-10:] # Obsługa prefiksu PL
        return clean

    @staticmethod
    def clean_currency(value: str) -> str:
        """Mapuje popularne symbole na kody ISO (np. € -> EUR)."""
        mapping = {"zł": "PLN", "pln": "PLN", "$": "USD", "€": "EUR", "euro": "EUR"}
        val_lower = value.lower().strip()
        return mapping.get(val_lower, "PLN")
