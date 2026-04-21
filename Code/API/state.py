import logging
from litestar import Litestar
from db.database import create_oltp_engine, consolidate_database
from worker.broker import broker

logger = logging.getLogger("nexus.api.state")

async def on_startup(app: Litestar) -> None:
    """Inicjalizacja ciężkich zasobów przy starcie API."""
    config = app.dependencies["config"]()

    # Inicjalizacja silnika bazy danych w stanie aplikacji
    engine = create_oltp_engine(config)
    app.state.db_engine = engine

    # Połączenie z brokerem Taskiq (NATS)
    if not broker.is_worker_process:
        await broker.startup()

    logger.info(">>> Nexus API: Wszystkie systemy gotowe.")

async def on_shutdown(app: Litestar) -> None:
    """Bezpieczne zamykanie i konsolidacja danych."""
    logger.info(">>> Nexus API: Rozpoczynanie procedury zamykania...")

    # Konsolidacja WAL dla SQLite (z Twojego modułu DB)
    await consolidate_database(app.state.db_engine)
