"""SecurityService -- retencja danych i bezpieczne usuwanie dokumentow.

Funkcje kryptograficzne (AEAD, Argon2id, SHA-256) przeniesione do nexus_crypto (Rust).
JWT i RBAC w nexus_ai/core/security.py. Skanowanie PII w log_pii_monitor.py.
"""

from __future__ import annotations

from pathlib import Path
from typing import final

import pendulum
from sqlmodel import Session, text

_ARCHIVE_TABLES: frozenset[str] = frozenset({"archived_invoices", "archived_ledger_entries"})


@final
class SecurityService:
    """Zarzadza retencja danych i bezpiecznym usuwaniem dokumentow."""
    __slots__ = ()

    @staticmethod
    async def cleanup_old_scans(session: Session, years: int = 5) -> dict:
        """Usuwa fizyczne pliki i wpisy faktur starszych niz X lat."""
        cutoff = pendulum.now().subtract(years=years)
        result = await session.execute(
            text(
                "DELETE FROM invoices WHERE issue_date < :cutoff AND status IN ('ARCHIVED', 'REJECTED')"
            ),
            {"cutoff": cutoff.date().isoformat()},
        )
        deleted = result.rowcount
        if deleted:
            await session.commit()
        return {"deleted": deleted, "cutoff": cutoff.date().isoformat()}

    @staticmethod
    async def archive_old_invoices(session: Session, archive_table: str = "archived_invoices") -> dict:
        """Archiwizuje faktury REJECTED/FAILED do tabeli archiwalnej."""
        if archive_table not in _ARCHIVE_TABLES:
            raise ValueError(f"Niedozwolona tabela archiwalna: {archive_table}")
        result = await session.execute(
            text(
                f"INSERT INTO {archive_table} SELECT * FROM invoices "
                "WHERE status IN ('REJECTED', 'FAILED') "
                "AND updated_at < datetime('now', '-90 days')"
            )
        )
        archived = result.rowcount
        if archived:
            await session.execute(
                text(
                    "DELETE FROM invoices WHERE status IN ('REJECTED', 'FAILED') "
                    "AND updated_at < datetime('now', '-90 days')"
                )
            )
            await session.commit()
        return {"archived": archived}

    @staticmethod
    def secure_delete_file(file_path: str) -> None:
        """Nadpisuje plik zerami przed usunieciem (bezpieczne niszczenie danych)."""
        path = Path(file_path)
        if path.exists():
            path.write_bytes(b"\x00" * path.stat().st_size)
            path.unlink()
