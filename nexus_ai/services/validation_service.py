
from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from nexus_ai.db.models import Invoice
from nexus_ai.services.currency_converter import Money


class ValidationService:
    """Zaawansowana walidacja biznesowa zapobiegająca duplikatom i błędom."""

    @staticmethod
    def is_duplicate(
            session: Session,
            nip: str,
            number: str,
            amount_gross: Money
    ) -> bool:
        """Sprawdza, czy w bazie istnieje już taka faktura dla tego dostawcy."""
        query = select(Invoice).where(
            and_(
                Invoice.contractor_nip == nip,
                Invoice.number == number,
                Invoice.amount_gross == amount_gross
            )
        )
        result = session.execute(query)
        return result.scalar_one_or_none() is not None

    @staticmethod
    def detect_anomaly(avg_amount: float, current_amount: float) -> bool:
        """Prosta detekcja anomalii - flaga, jeśli kwota znacznie odbiega od średniej."""
        pass
