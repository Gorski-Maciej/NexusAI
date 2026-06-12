from sqlalchemy import select
from sqlalchemy.orm import Session

from nexus_ai.db.models import Invoice


class ExportService:
    """Zarządza eksportem faktur do zewnętrznych systemów ERP."""

    @staticmethod
    def generate_export_payload(
        session: Session, invoice_ids: list[str], system_name: str = "INSERT_EPP"
    ) -> str:
        """Pobiera faktury i generuje plik tekstowy dla systemu księgowego."""
        # 1. Pobieramy faktury z bazy
        query = select(Invoice).where(Invoice.id.in_(invoice_ids))
        result = session.execute(query)
        invoices = result.scalars().all()

        if not invoices:
            raise ValueError("Nie znaleziono faktur do eksportu.")

        # 2. Pobieramy konfigurację eksportu...
        # Dalsza implementacja logiki eksportu
