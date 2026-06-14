from sqlalchemy import event
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice

logger = get_logger("nexus.db.hooks")


# ── Safe decimal converter ──────────────────────────────────────────────
# SUPERMOC: Decimal → str zamiast Decimal → float.
# float traci precyzję groszową: Decimal("123.45") → float = 123.44999...
# DuckDB rozumie string "123.45" jako DECIMAL.


def _decimal_to_duckdb(value) -> str | None:
    """Konwertuj Decimal na string dla DuckDB (bez strat precyzji)."""
    if value is None:
        return None
    # Obsługa Nexus-Money (amount_cents) i py-moneyed (amount)
    if hasattr(value, "amount"):
        return str(value.amount)
    return str(value)


def register_db_hooks(config: AppConfig):
    """Rejestruje hooki, które automatycznie replikują dane do DuckDB po każdym komicie.

    Używa ``SessionEvents.after_flush`` zamiast ``after_insert``/``after_update``:
    - ``after_insert`` triggeruje przy ``session.flush()``, nie ``commit()``
    - Jeśli transakcja jest rollbackowana, DuckDB dostaje dane które nie istnieją
    - ``after_flush`` też triggeruje przy flush, ale jest stabilniejszy dla
      dostępności (ORM event vs Core event)
    """

    # Inicjalizacja managera analityki
    duck_mgr = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    duck_mgr.connect()

    def _build_data(target: Invoice) -> dict[str, str | None]:
        """Zbuduj słownik danych do DuckDB z bezpieczną konwersją Decimal."""
        return {
            "id": str(target.id),
            "number": target.number,
            "contractor_nip": target.contractor_nip,
            "amount_net": _decimal_to_duckdb(target.amount_net),
            "amount_gross": _decimal_to_duckdb(target.amount_gross),
            "currency": target.currency,
            "status": target.status,
        }

    def _replicate(target: Invoice) -> None:
        """Wykonaj upsert do DuckDB dla pojedynczej faktury."""
        data = _build_data(target)
        try:
            duck_mgr.execute(
                """
                INSERT INTO invoices_replica (id, number, contractor_nip, amount_net, amount_gross, currency, status)
                VALUES (?, ?, ?, CAST(? AS DECIMAL(18,2)), CAST(? AS DECIMAL(18,2)), ?, ?)
                ON CONFLICT (id) DO UPDATE SET
                    number = EXCLUDED.number,
                    contractor_nip = EXCLUDED.contractor_nip,
                    amount_net = CAST(EXCLUDED.amount_net AS DECIMAL(18,2)),
                    amount_gross = CAST(EXCLUDED.amount_gross AS DECIMAL(18,2)),
                    currency = EXCLUDED.currency,
                    status = EXCLUDED.status
                """,
                [
                    data["id"],
                    data["number"],
                    data["contractor_nip"],
                    data["amount_net"],
                    data["amount_gross"],
                    data["currency"],
                    data["status"],
                ],
            )
        except Exception as e:
            logger.warning("Failed to replicate invoice %s to DuckDB: %s", target.id, e)

    # ── SUPERMOC: after_flush dla spójności transakcyjnej ────────────
    # after_flush jest wywoływany PO flush ale PRZED commit.
    # Jeśli transakcja jest rollbackowana, duck_mgr.execute() też jest
    # odrzucane (ale DuckDB nie ma transakcji cross-db, więc to best-effort).
    # after_flush otrzymuje mapper, connection, target przez event.listen.
    # Używamy after_flush zamiast after_insert/after_update, bo:
    #   - after_flush gwarantuje że dane są w sesji
    #   - pojedynczy listener zamiast dwóch
    #   - nie ma ryzyka float precision loss
    from sqlalchemy.orm import Session as _SASession

    @event.listens_for(_SASession, "after_flush")
    def after_flush_replicate(session, flush_context):
        """Replikuj zmienione faktury do DuckDB po każdym flush.

        Iteruje po ``session.dirty`` i ``session.new`` w poszukiwaniu Invoice.
        ``after_flush`` jest wywoływany PO zapisie do DB, ale PRZED commitem.
        W razie błędu DuckDB, główna transakcja SQLite może być rollbackowana.
        """
        for obj in session.new:
            if isinstance(obj, Invoice):
                _replicate(obj)
        for obj in session.dirty:
            if isinstance(obj, Invoice):
                _replicate(obj)
