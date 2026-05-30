import logging
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger("nexus.security.retention")


class SecurityService:
    """Zarządza retencją danych i bezpiecznym usuwaniem dokumentów."""

    @staticmethod
    async def cleanup_old_scans(session: AsyncSession, years: int = 5) -> dict[str, int]:
        """
        Usuwa fizyczne pliki i wpisy z bazy dla dokumentów starszych niż X lat (RODO/Podatki).
        Rozwiązanie 27: Fizyczne usuwanie soft-deleted invoices po okresie retencji.

        Returns dict z liczbą usuniętych rekordów i plików.
        """
        limit_date = datetime.now(timezone.utc) - timedelta(days=years * 365)
        deleted_rows = 0
        deleted_files = 0

        try:
            # Znajdź faktury do fizycznego usunięcia:
            # 1. Soft-deleted (is_deleted=TRUE) ORAZ
            # 2. deleted_at + retention_period_years <= NOW()
            result = await session.execute(
                text(
                    """
                    SELECT id, file_path FROM invoices
                    WHERE is_deleted = 1
                      AND deleted_at IS NOT NULL
                      AND datetime(deleted_at, '+' || retention_period_years || ' years') <= datetime('now')
                    LIMIT 1000
                    """
                )
            )
            rows = result.fetchall()

            for row in rows:
                invoice_id, file_path = row
                try:
                    # Bezpieczne usunięcie pliku PDF z dysku
                    if file_path:
                        SecurityService.secure_delete_file(str(file_path))
                        deleted_files += 1
                except Exception as exc:
                    logger.warning(
                        "[RETENTION] Failed to delete file for invoice_id=%s: %s",
                        invoice_id, exc,
                    )

                # Fizyczne usunięcie z bazy danych
                await session.execute(
                    text("DELETE FROM invoices WHERE id = :id"),
                    {"id": invoice_id},
                )
                deleted_rows += 1

            await session.commit()

            logger.info(
                "[RETENTION] cleanup_old_scans: deleted_rows=%d, deleted_files=%d, years=%d",
                deleted_rows, deleted_files, years,
            )
        except Exception as exc:
            await session.rollback()
            logger.error("[RETENTION] cleanup_old_scans failed: %s", exc)

        return {"deleted_rows": deleted_rows, "deleted_files": deleted_files}

    @staticmethod
    async def archive_old_invoices(session: AsyncSession, archive_table: str = "archived_invoices") -> dict[str, int]:
        """
        Przenieś REJECTED/FAILED invoices starsze niż 1 rok do tabeli archiwalnej.
        Rozwiązanie 27: Poprawa wydajności głównej tabeli invoices.
        """
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=365)
        archived = 0

        try:
            # Upewnij się, że tabela archiwalna istnieje
            await session.execute(
                text(
                    f"""
                    CREATE TABLE IF NOT EXISTS {archive_table} (
                        LIKE invoices INCLUDING ALL
                    )
                    """
                )
            )

            # Przenieś do archiwum: INSERT INTO archive + DELETE FROM main
            rows = await session.execute(
                text(
                    """
                    SELECT * FROM invoices
                    WHERE status IN ('REJECTED', 'FAILED')
                      AND updated_at < :cutoff
                      AND is_deleted = 0
                    LIMIT 500
                    """
                ),
                {"cutoff": cutoff_date},
            )
            invoices_to_archive = rows.fetchall()

            if not invoices_to_archive:
                return {"archived": 0}

            for row in invoices_to_archive:
                invoice_dict = dict(row._mapping)
                columns = ", ".join(invoice_dict.keys())
                placeholders = ", ".join([f":{k}" for k in invoice_dict.keys()])

                await session.execute(
                    text(
                        f"INSERT INTO {archive_table} ({columns}) VALUES ({placeholders})"
                    ),
                    invoice_dict,
                )
                await session.execute(
                    text("DELETE FROM invoices WHERE id = :id"),
                    {"id": invoice_dict["id"]},
                )
                archived += 1

            await session.commit()
            logger.info(
                "[RETENTION] archive_old_invoices: archived=%d, table=%s",
                archived, archive_table,
            )
        except Exception as exc:
            await session.rollback()
            logger.error("[RETENTION] archive_old_invoices failed: %s", exc)

        return {"archived": archived}

    @staticmethod
    def secure_delete_file(file_path: str) -> None:
        """Nadpisuje plik zerami przed usunięciem (bezpieczne niszczenie danych)."""
        path = Path(file_path)
        if path.exists():
            try:
                size = path.stat().st_size
                with open(path, "ba+", buffering=0) as f:
                    f.write(b'\x00' * size)
                path.unlink()
                logger.debug("[RETENTION] Secure deleted file: %s", file_path)
            except Exception as exc:
                logger.warning("[RETENTION] Failed to secure delete file %s: %s", file_path, exc)
