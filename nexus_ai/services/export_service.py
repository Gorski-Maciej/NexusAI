from __future__ import annotations

from sqlmodel import select, Session

from nexus_ai.db.models import Invoice


def generate_export_payload(
    session: Session, invoice_ids: list[str], /, system_name: str = "INSERT_EPP"
) -> str:
    """Generuje plik eksportu faktur dla systemu ERP.

    Args:
        session: Sesja DB.
        invoice_ids: Lista ID faktur do eksportu.
        system_name: Nazwa systemu docelowego (domyslnie INSERT_EPP).

    Returns:
        Plik tekstowy z danymi do eksportu.

    Raises:
        ValueError: Gdy nie znaleziono zadnych faktur.
    """
    # Uzycie walrus operator + select kolumn zamiast calego rekordu
    if not (invoices := session.execute(
        select(Invoice).where(Invoice.id.in_(invoice_ids))
    ).scalars().all()):
        raise ValueError("Nie znaleziono faktur do eksportu.")

    # Dalsza implementacja logiki eksportu
    return ""  # TODO: implement export logic


class ExportService:  # backward compat
    """Backward-compat alias. Use module-level generate_export_payload() directly."""
    generate_export_payload = staticmethod(generate_export_payload)
