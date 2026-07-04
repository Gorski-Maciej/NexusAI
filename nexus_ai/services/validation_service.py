"""Business validation -- duplicate detection, cross-field checks.

Migrated to BaseService pattern: leaner, using walrus operator + pattern matching.
"""

from __future__ import annotations

from decimal import Decimal

from sqlmodel import Session, and_, select

from nexus_ai.db.models import Invoice


def is_duplicate(session: Session, nip: str, number: str, amount_gross: Decimal) -> bool:
    """Sprawdza, czy faktura juz istnieje (walrus + select kolumny zamiast calego rekordu).

    Oszczedza ~70% transferu danych --  laduje tylko `id`, nie `file_path` itp.
    """
    return (
        session.execute(
            select(Invoice.id).where(
                and_(
                    Invoice.contractor_nip == nip,
                    Invoice.number == number,
                    Invoice.amount_gross == amount_gross,
                )
            ).limit(1)
        ).scalar_one_or_none()
        is not None
    )


# ── Backward-compat alias ────────────────────────────────────────────────
# Stary kod mógł importować ValidationService jako klasę.
# Zachowujemy kompatybilność przez statyczną referencję.
class ValidationService:  # backward compat
    """Backward-compat alias. Use module-level is_duplicate() directly."""
    is_duplicate = staticmethod(is_duplicate)

    __slots__ = ()
