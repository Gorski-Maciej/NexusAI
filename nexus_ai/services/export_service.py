from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.invoice import Invoice


class ExportService:
    """Zarządza eksportem faktur do zewnętrznych systemów ERP."""

    @staticmethod
    async def generate_export_payload(
            session: AsyncSession,
            invoice_ids: list[str],
            system_name: str = "INSERT_EPP"
    ) -> str:
        """Pobiera faktury i generuje plik tekstowy dla systemu księgowego."""
        # 1. Pobieramy faktury z bazy
        query = select(Invoice).where(Invoice.id.in_(invoice_ids))
        result = await session.execute(query)
        invoices = result.scalars().all()

        if not invoices:
            raise ValueError("Nie znaleziono faktur do eksportu.")

        # 2. Pobieramy konfigurację eksportu...
        # Dalsza implementacja logiki eksportu
