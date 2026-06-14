"""
conftest.py — Integration test configuration for NexusAI.

Sets up:
- A temporary SQLite database
- An async SQLAlchemy engine + session
- A test Litestar app client (via `AsyncTestClient`)
- Fixtures for common test data
"""

from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path
from typing import AsyncGenerator

import pytest
from litestar.testing import AsyncTestClient
from sqlalchemy import text
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

# Ensure Code/ is on sys.path
import sys

_CODE_DIR = Path(__file__).resolve().parents[1] / "Code"
if str(_CODE_DIR) not in sys.path:
    sys.path.insert(0, str(_CODE_DIR))

# ── Global test config ───────────────────────────────────────────────────────

# Use a unique temp file per session to avoid conflicts with concurrent test runs
TEST_DB_DIR = tempfile.mkdtemp(prefix="nexus_test_")
TEST_DB_FILE = str(Path(TEST_DB_DIR) / "test_integration.db")

# ── Session-scoped fixtures ──────────────────────────────────────────────────


@pytest.fixture(scope="session")
def db_engine():
    """Create a test database engine with all tables."""
    from db.database import Base

    # Use a unique temporary file database for the session
    db_path = Path(TEST_DB_FILE)
    db_url = f"sqlite:///{db_path.as_posix()}"

    engine = create_engine(db_url, echo=False)
    Base.metadata.create_all(engine)

    # Also create runtime tables used by on_startup
    with engine.begin() as conn:
        for ddl in _RUNTIME_TABLES:
            conn.execute(text(ddl))

    yield engine

    # Cleanup: close engine and remove test DB + temp directory
    engine.dispose()
    db_path.unlink(missing_ok=True)
    shutil.rmtree(TEST_DB_DIR, ignore_errors=True)


_RUNTIME_TABLES = [
    """CREATE TABLE IF NOT EXISTS refresh_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        token_hash TEXT UNIQUE NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        is_revoked BOOLEAN NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )""",
    """CREATE TABLE IF NOT EXISTS task_status (
        task_id TEXT PRIMARY KEY,
        task_name TEXT NOT NULL,
        user_id TEXT,
        status TEXT NOT NULL DEFAULT 'QUEUED',
        progress REAL DEFAULT 0.0,
        result TEXT,
        error_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )""",
]


@pytest.fixture(scope="session")
def db_session_factory(db_engine):
    """Provide session factory bound to the test engine."""
    return sessionmaker(bind=db_engine, class_=Session, expire_on_commit=False)


@pytest.fixture(autouse=True)
def clean_tables(db_session_factory):
    """Clean all tables between tests (run before each test)."""
    yield

    # Clean up after the test
    with db_session_factory() as session:
        for table_name in [
            "outbox_events",
            "audit_logs",
            "invoices",
            "contractors",
            "users",
            "fx_rates",
            "task_status",
            "refresh_tokens",
            "active_learning_patterns",
            "processed_events",
            "ui_drafts",
        ]:
            try:
                session.execute(text(f"DELETE FROM {table_name}"))
            except Exception:
                pass  # Table might not exist in test schema
        session.commit()


@pytest.fixture(scope="session")
def test_app(db_engine):
    """
    Create a test Litestar app with a mock database engine.
    The actual `create_app()` may require NATS, DuckDB etc.
    Instead we create a minimal version for integration testing.
    """
    from litestar import Litestar
    from litestar.config.cors import CORSConfig
    from litestar.openapi.config import OpenAPIConfig
    from litestar.openapi.plugins import SwaggerRenderPlugin
    from litestar.di import Provide

    # Minimal set of controllers for integration tests
    from api.routes.health import HealthController, HealthControllerV2
    from api.routes.auth import AuthController
    from api.routes.version import VersionController
    from api.dependencies import provide_config

    app = Litestar(
        route_handlers=[
            HealthController,
            HealthControllerV2,
            AuthController,
            VersionController,
        ],
        on_startup=[],
        on_shutdown=[],
        dependencies={
            "config": provide_config,
        },
        cors_config=CORSConfig(allow_origins=["*"]),
        openapi_config=OpenAPIConfig(
            title="Nexus AI API (Test)",
            version="2.0.0",
            render_plugins=[SwaggerRenderPlugin()],
        ),
        debug=False,
    )
    yield app


@pytest.fixture(scope="session")
async def async_client(test_app) -> AsyncGenerator[AsyncTestClient, None]:
    """Provide an HTTP client for integration testing via Litestar's AsyncTestClient.

    Zastępuje: httpx.ASGITransport + AsyncClient → Litestar AsyncTestClient.
    AsyncTestClient zapewnia tę samą API (get, post, put, delete) co httpx,
    ale jest w pełni zintegrowany z lifecyclem Litestar (on_startup/on_shutdown).
    """
    async with AsyncTestClient(app=test_app) as client:
        yield client


@pytest.fixture
def db_session(db_session_factory):
    """Provide a fresh session for each test."""
    with db_session_factory() as session:
        yield session


# ── Test data fixtures ───────────────────────────────────────────────────────


@pytest.fixture
def sample_user(db_session: Session) -> dict:
    """Create a sample user and return its data."""
    from api.auth_service import hash_password
    from sqlalchemy import text

    user_id = "test-user-001"
    username = "testuser"
    password = "testpass123"
    pwd_hash = hash_password(password)

    db_session.execute(
        text(
            """\
            INSERT INTO users (id, username, password_hash, role, tenant_id, is_active)
            VALUES (:id, :username, :password_hash, :role, :tenant_id, :is_active)
            """
        ),
        {
            "id": user_id,
            "username": username,
            "password_hash": pwd_hash,
            "role": "accountant",
            "tenant_id": "default",
            "is_active": True,
        },
    )
    db_session.commit()

    return {"id": user_id, "username": username, "password": password, "role": "accountant"}


@pytest.fixture
def sample_contractor(db_session: Session) -> dict:
    """Create a sample contractor and return its data."""
    from sqlalchemy import text
    from datetime import datetime, timezone
    import uuid

    contractor_id = uuid.uuid4().hex
    now = datetime.now(timezone.utc).isoformat()

    db_session.execute(
        text(
            """\
            INSERT INTO contractors (id, name, nip, address, bank_account, created_at, updated_at)
            VALUES (:id, :name, :nip, :address, :bank_account, :created_at, :updated_at)
            """
        ),
        {
            "id": contractor_id,
            "name": "Test Contractor Sp. z o.o.",
            "nip": "5213456789",
            "address": "ul. Testowa 1, 00-001 Warszawa",
            "bank_account": "PL10105000997603123456789123",
            "created_at": now,
            "updated_at": now,
        },
    )
    db_session.commit()

    return {"id": contractor_id, "nip": "5213456789"}


@pytest.fixture
def sample_invoice(db_session: Session, sample_contractor: dict) -> dict:
    """Create a sample invoice linked to a contractor."""
    from sqlalchemy import text
    from datetime import datetime, timezone
    import uuid

    inv_id = uuid.uuid4().hex
    now = datetime.now(timezone.utc).isoformat()

    db_session.execute(
        text(
            """\
            INSERT INTO invoices (
                id, number, amount_net, amount_gross, currency,
                issue_date, contractor_nip, contractor_id, status,
                file_path, tenant_id, created_at, updated_at,
                created_by, updated_by, version_id
            ) VALUES (
                :id, :number, :net, :gross, :currency,
                :issue_date, :nip, :contractor_id, :status,
                :file_path, 'default', :now, :now,
                'test', 'test', 1
            )
            """
        ),
        {
            "id": inv_id,
            "number": "FV/TEST/001",
            "net": 1000.00,
            "gross": 1230.00,
            "currency": "PLN",
            "issue_date": "2026-05-15",
            "nip": sample_contractor["nip"],
            "contractor_id": sample_contractor["id"],
            "status": "NEW",
            "file_path": "test/fv_test_001.pdf",
            "now": now,
        },
    )
    db_session.commit()

    return {"id": inv_id, "number": "FV/TEST/001"}
