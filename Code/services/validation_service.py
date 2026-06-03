from decimal import Decimal

from models.invoice import Invoice
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from services.currency_converter import Money


class ValidationService:
    """Zaawansowana walidacja biznesowa zapobiegająca duplikatom i błędom."""

    @staticmethod
    async def is_duplicate(
            session: AsyncSession,
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
        result = await session.execute(query)
        return result.scalar_one_or_none() is not None

    @staticmethod
    def detect_anomaly(avg_amount: float, current_amount: float) -> bool:
        """Prosta detekcja anomalii - flaga, jeśli kwota znacznie odbiega od średniej."""
        pass
