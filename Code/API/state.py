import logging
import os
from litestar import Litestar
from sqlalchemy import text
from db.database import create_oltp_engine, consolidate_database, create_session_factory
from worker.broker import broker
from api.auth_service import hash_password
from api.shared_image_buffer import SharedImageBuffer
from db.analytics import DuckDBManager

logger = logging.getLogger("nexus.api.state")

async def on_startup(app: Litestar) -> None:
    """Inicjalizacja ciężkich zasobów przy starcie API."""
    config = app.dependencies["config"]()

    # Inicjalizacja silnika bazy danych w stanie aplikacji
    engine = create_oltp_engine(config)
    app.state.db_engine = engine
    app.state.db_session_factory = create_session_factory(engine)
    app.state.shared_image_buffer = SharedImageBuffer(max_items=128)
    admin_username = os.getenv("NEXUS_ADMIN_USERNAME", "admin")
    admin_password = os.getenv("NEXUS_ADMIN_PASSWORD", "admin")
    admin_password_hash = hash_password(admin_password)
    async with engine.begin() as conn:
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'worker',
                    tenant_id TEXT NOT NULL DEFAULT 'default',
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS outbox_events (
                    id TEXT PRIMARY KEY,
                    event_type TEXT NOT NULL,
                    aggregate_id TEXT NOT NULL,
                    payload TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'PENDING',
                    processed BOOLEAN NOT NULL DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        try:
            await conn.execute(text("ALTER TABLE invoices ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT 0"))
        except Exception:
            pass
        try:
            await conn.execute(text("ALTER TABLE invoices ADD COLUMN deleted_at TIMESTAMP NULL"))
        except Exception:
            pass

        await conn.execute(
            text(
                """
                INSERT INTO users (id, username, password_hash, role, tenant_id, is_active)
                VALUES (:id, :username, :password_hash, :role, :tenant_id, :is_active)
                ON CONFLICT(username) DO NOTHING
                """
            ),
            {
                "id": "admin",
                "username": admin_username,
                "password_hash": admin_password_hash,
                "role": "owner",
                "tenant_id": "default",
                "is_active": True,
            },
        )

    # Połączenie z brokerem Taskiq (NATS)
    if not broker.is_worker_process:
        await broker.startup()

    # Warm-up analytics materialization to reduce cold-start dashboard latency.
    try:
        duckdb_manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
        duckdb_manager.refresh_materialized_cashflow()
        duckdb_manager.close()
    except Exception as exc:
        logger.warning("DuckDB warm-up refresh failed: %s", exc)

    logger.info(">>> Nexus API: Wszystkie systemy gotowe.")

async def on_shutdown(app: Litestar) -> None:
    """Bezpieczne zamykanie i konsolidacja danych."""
    logger.info(">>> Nexus API: Rozpoczynanie procedury zamykania...")

    # Konsolidacja WAL dla SQLite (z Twojego modułu DB)
    await consolidate_database(app.state.db_engine)
    if not broker.is_worker_process:
        await broker.shutdown()
    await app.state.db_engine.dispose()
