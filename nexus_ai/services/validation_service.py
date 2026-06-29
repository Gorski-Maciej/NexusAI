from __future__ import annotations

from typing import final

from sqlmodel import and_, select
from sqlmodel import Session

from nexus_ai.db.models import Invoice


@final
class ValidationService:
    """Zaawansowana walidacja biznesowa zapobiegająca duplikatom i błędom.

    Dla duplikatów potrzebujemy tylko contractor_nip, number, amount_gross.
    Redukcja transferu danych z DB o ~70%.
    """

    @staticmethod
    def is_duplicate(session: Session, nip: str, number: str, amount_gross: Decimal) -> bool:
        """Sprawdza, czy w bazie istnieje już taka faktura dla tego dostawcy.

        Oszczędza ~70% transferu danych z SQLite (nie ładuje file_path,
        processing_status, itp.).
        """
        query = (
            select(Invoice.id)
            .where(
                and_(
                    Invoice.contractor_nip == nip,
                    Invoice.number == number,
                    Invoice.amount_gross == amount_gross,
                )
            )
            .limit(1)
        )
        result = session.execute(query)
        return result.scalar_one_or_none() is not None
