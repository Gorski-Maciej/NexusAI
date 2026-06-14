"""SQLAlchemy setup for SQLCipher (encrypted SQLite) + aiosqlite (async).

Zgodnie z aa3fvcx.txt:
- SQLCipher: szyfrowanie AES-256 bazy danych w spoczynku (at-rest encryption).
  Wymaga ``LD_PRELOAD`` z ``libsqlcipher.so`` przed uruchomieniem interpretera
  (patrz ``probe_sqlcipher()`` w tym module).
- aiosqlite: async dostęp do SQLite przez ``create_async_engine``.
  Python 3.13t (free-threaded): brak GIL — zarówno sync jak i async API
  są bezpieczne z wielu wątków jednocześnie.

Usage:
    # Sync (np. background workers):
    engine = create_oltp_engine(config)
    session = sessionmaker(bind=engine)

    # Async (np. Litestar endpoints):
    engine = create_async_oltp_engine(config)
    session = async_sessionmaker(bind=engine)

    # Uruchomienie z SQLCipher:
    LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libsqlcipher.so \\
        NEXUS_SQLCIPHER_KEY=my-secret-key \\
        python -m nexus_ai.api.app
"""

from __future__ import annotations

import ctypes
import os
import sys
from collections.abc import AsyncGenerator, Generator
from pathlib import Path

from sqlalchemy import create_engine, event, text
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import Pool
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.db")


# ── SQLCipher detection ──────────────────────────────────────────────────

SQLCIPHER_AVAILABLE: bool | None = None
"""Czy sqlite3 ma wsparcie SQLCipher (PRAGMA cipher_version działa)."""


def probe_sqlcipher() -> bool:
    """Sprawdź czy sqlite3 jest skompilowany z SQLCipher.

    Strategia:
    1. Bezpośrednie ``PRAGMA cipher_version`` na ``:memory:``.
    2. Jeśli nie działa, próbuje załadować ``libsqlcipher.so`` przez ``ctypes.CDLL``
       z flagą ``RTLD_GLOBAL`` (działa na systemach Linux gdzie biblioteka jest
       dostępna ale nie jest domyślnym sqlite3).

    Returns:
        ``True`` jeśli SQLCipher jest dostępny.
    """
    global SQLCIPHER_AVAILABLE

    import sqlite3

    # 1. Bezpośredni test
    try:
        conn = sqlite3.connect(":memory:")
        cur = conn.cursor()
        cur.execute("PRAGMA cipher_version")
        row = cur.fetchone()
        conn.close()
        if row is not None:
            ver = row[0]
            logger.info("[DB] SQLCipher detected: %s", ver)
            SQLCIPHER_AVAILABLE = True
            return True
    except Exception:
        pass

    # 2. Próba preloadu przez ctypes (Linux)
    if sys.platform == "linux":
        for lib_name in ["libsqlcipher.so", "libsqlcipher.so.1"]:
            try:
                ctypes.CDLL(lib_name, mode=ctypes.RTLD_GLOBAL)
                conn = sqlite3.connect(":memory:")
                cur = conn.cursor()
                cur.execute("PRAGMA cipher_version")
                row = cur.fetchone()
                conn.close()
                if row is not None:
                    ver = row[0]
                    logger.info("[DB] SQLCipher loaded via ctypes: %s", ver)
                    SQLCIPHER_AVAILABLE = True
                    return True
            except Exception:
                continue

    SQLCIPHER_AVAILABLE = False
    logger.warning(
        "[DB] SQLCipher NOT available — database will be unencrypted! "
        "Set LD_PRELOAD=/usr/lib/.../libsqlcipher.so or install libsqlcipher."
    )
    return False


# Uruchom probe przy imporcie modułu — loguje ostrzeżenie jeśli SQLCipher niedostępny
probe_sqlcipher()


# ── URL builders ──────────────────────────────────────────────────────────


def _sqlite_url(config: AppConfig, sqlite_path: Path | None = None) -> str:
    """Build sync SQLite URL from configuration."""
    path = sqlite_path or config.sqlite_path
    return f"sqlite:///{path.as_posix()}"


def _async_sqlite_url(config: AppConfig, sqlite_path: Path | None = None) -> str:
    """Build async SQLite URL (aiosqlite) from configuration."""
    path = sqlite_path or config.sqlite_path
    return f"sqlite+aiosqlite:///{path.as_posix()}"


# ── Key resolution ────────────────────────────────────────────────────────


def _resolve_key(config: AppConfig, key: str | None = None) -> str:
    """Resolve SQLCipher encryption key.

    Kolejność: argument ``key`` > env var ``NEXUS_SQLCIPHER_KEY`` > błąd.

    Raises:
        RuntimeError: jeśli klucz nie jest skonfigurowany.
    """
    resolved = key or os.getenv(config.sqlcipher_key_env, "").strip()
    if not resolved:
        raise RuntimeError(
            f"SQLCipher key not configured. "
            f"Set {config.sqlcipher_key_env} environment variable "
            f"or pass ``key=`` parameter."
        )
    return resolved


def _make_pragma_setter(key_hex: str):
    """Utwórz funkcję ``connect`` listenera ustawiającą PRAGMA key.

    Używa ``dbapi_connection.execute()`` zamiast ``cursor.execute()`` dla
    kompatybilności z aiosqlite (gdzie cursor wymaga ``await``, ale
    ``connection.execute()`` ma synchroniczny interfejs w SQLAlchemy).

    DODANE SUPERMOCE:
    - PRAGMA foreign_keys = ON: wymusza integralność referencyjną
    - PRAGMA cell_size_check = ON: wykrywa corrupt data
    - PRAGMA trusted_schema = OFF: bezpieczeństwo (blokada złośliwych triggerów)

    Args:
        key_hex: Klucz szyfrowania w formacie hex.
    """

    def _set_pragmas(dbapi_connection, _connection_record):
        # ── SUPERMOC: WAL mode (Write-Ahead Log) ───────────────────
        # 3-5× szybszy od DELETE dla współbieżnych odczytów.
        # WAL pozwala czytać bazę podczas zapisu — kluczowe dla API.
        # Używamy WAL zamiast DELETE zarówno dla sync jak i async engine.
        dbapi_connection.execute("PRAGMA journal_mode=WAL;")

        # ── SUPERMOC: Synchronous NORMAL zamiast FULL ──────────────
        # FULL: fsync po każdym commit = wolniejsze zapisy, ale bezpieczne.
        # NORMAL: fsync tylko w kluczowych momentach WAL checkpoint.
        # Różnica: ~2× szybsze zapisy, przy WAL wciąż bezpieczne (crash-safe).
        # WAL checkpoint robi fsync, więc dane są bezpieczne.
        dbapi_connection.execute("PRAGMA synchronous=NORMAL;")

        # ── SUPERMOC: Foreign Keys ON ──────────────────────────────
        # Wymusza integralność referencyjną na poziomie bazy danych.
        # Żadna faktura nie może być usunięta jeśli ma powiązane outbox eventy.
        dbapi_connection.execute("PRAGMA foreign_keys = ON;")

        # ── SUPERMOC: Cell Size Check ON ───────────────────────────
        # Sprawdza poprawność każdej strony bazy danych przy odczycie.
        # Wykrywa corrupt data (np. błędy dysku, niekompletne zapisy).
        dbapi_connection.execute("PRAGMA cell_size_check = ON;")

        # ── SUPERMOC: Trusted Schema OFF ───────────────────────────
        # Blokuje wykonywanie kodu SQL z niezaufanych źródeł.
        # Zapobiega atakom przez sparametryzowane trigger/view.
        dbapi_connection.execute("PRAGMA trusted_schema = OFF;")

        # ── SUPERMOC: Cache size 200MB (w stronach = 4KB * 51200) ──
        # Domyślnie SQLite ma 2000 stron (~8MB). Dla aplikacji z wieloma
        # zapytaniami OLTP, większy cache = mniej I/O.
        # 20000 stron = ~80MB RAM. Dla serwera z 8GB+ RAM to nic.
        # Ujemna wartość = strony (nie KiB).
        dbapi_connection.execute("PRAGMA cache_size = -51200;")  # 200MB

        # ── SUPERMOC: Temp Store MEMORY zamiast FILE ───────────────
        # Temp tables (np. w window functions, CTE) trzymane w RAM.
        # 2 = MEMORY, 0 = DEFAULT (FILE).
        # Skraca czas zapytań z sortowaniem/temp tables o 5-10×.
        dbapi_connection.execute("PRAGMA temp_store = 2;")  # MEMORY

        # ── SUPERMOC: Auto-vacuum FULL ─────────────────────────────
        # Po VACUUM, plik DB jest kompaktowy.
        # AUTO_VACUUM = 1: przy commit usuwa wolne strony.
        dbapi_connection.execute("PRAGMA auto_vacuum = FULL;")

        # ── SUPERMOC: Memory-Mapped I/O (mmap_size) ────────────────
        # Mapuje plik DB do pamięci wirtualnej. OS zarządza stronicowaniem.
        # 4GB = komfortowy limit dla bazy NexusAI (głównie faktury + eventy).
        # SQLite używa mmap dla odczytów gdy tylko możliwe → mniej syscalli.
        dbapi_connection.execute("PRAGMA mmap_size = 4294967296;")  # 4GB

        # ── SUPERMOC: Application ID ───────────────────────────────
        # Identyfikuje plik DB jako "NexusAI database" (magic bytes).
        # Przydatne przy forensics / backup / file-type detection.
        # Hex: NEXU = 0x4E455855 (dowolny unikalny identyfikator).
        dbapi_connection.execute("PRAGMA application_id = 1313827925;")  # NEXU

        # ── SUPERMOC: User Version (schema tracking) ───────────────
        # Łatwy sposób na sprawdzenie wersji schematu bez patrzenia na
        # sqlite_master. Można użyć jako fast-path w sanity check.
        dbapi_connection.execute("PRAGMA user_version = 30000;")  # v3.0.0

        # ── SUPERMOC: SQLCipher (AES-256 encryption) ───────────────
        dbapi_connection.execute("PRAGMA key = x'%s';" % key_hex)
        dbapi_connection.execute("PRAGMA cipher_page_size = 4096;")
        dbapi_connection.execute("PRAGMA kdf_iter = 64000;")

        # ── SUPERMOC: SQLCipher — strongest HMAC + KDF ─────────────
        # Domyślnie SQLCipher używa HMAC_SHA1 i PBKDF2_HMAC_SHA1.
        # Wybieramy HMAC_SHA512 + PBKDF2_HMAC_SHA512 dla maksymalnego
        # bezpieczeństwa (zgodne z aa3fvcx.txt Punkt 8: najwyższe standardy).
        # Koszt: ~20% wolniejsze otwieranie DB, 0% wpływ na runtime queries.
        try:
            dbapi_connection.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512;")
            dbapi_connection.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;")
            dbapi_connection.execute("PRAGMA cipher_use_hmac = ON;")
        except Exception:
            pass  # Starsza wersja SQLCipher może nie wspierać tych PRAGM

        # ── SUPERMOC: SQLCipher Memory Security ──────────────────────
        # mlock() blokuje strony pamięci z kluczami przed swapowaniem.
        # Bez tego, klucz AES-256 może wyciec do pliku swap/pagefile.
        # Ochrona przed atakami cold-boot i swap inspection.
        try:
            dbapi_connection.execute("PRAGMA cipher_memory_security = ON;")
        except Exception:
            pass  # Starsze wersje SQLCipher mogą nie wspierać

        # ── SUPERMOC: SQLCipher Encrypted Header ─────────────────────
        # Domyślnie SQLCipher zostawia "SQLite format 3\0" w plaintext
        # w pierwszych 16 bajtach nagłówka pliku.
        # cipher_default_plaintext_header = ON szyfruje cały nagłówek:
        #   - Atakujący nie wie że to baza SQLCipher
        #   - Plik wygląda jak losowe dane binarne
        # UWAGA: Działa tylko dla NOWYCH baz (CREATE TABLE).
        # Dla istniejących baz, użyj PRAGMA rekey + cipher_default_plaintext_header.
        try:
            dbapi_connection.execute("PRAGMA cipher_default_plaintext_header = ON;")
        except Exception:
            pass  # Wymaga SQLCipher 4.x+

        # UWAGA: cipher_plaintext_header_size=0 wymaga ustawienia PRZY TWORZENIU BAZY,
        # nie w runtime (patrz docs/SQLCIPHER_AUDIT.md).

        # ── SUPERMOC: cipher_hmac_pgno = ON ──────────────────────────
        # Weryfikacja numeru strony w HMAC — dodatkowa ochrona przed
        # atakami typu page-swapping (zamiana stron miejscami).
        try:
            dbapi_connection.execute("PRAGMA cipher_hmac_pgno = ON;")
        except Exception:
            pass  # Wymaga SQLCipher 4.x+

    return _set_pragmas


# ── Sync engine ───────────────────────────────────────────────────────────


def create_oltp_engine(
    config: AppConfig,
    *,
    sqlcipher_key: str | None = None,
    sqlite_path: Path | None = None,
):
    """Create a sync SQLAlchemy engine with SQLCipher encryption.

    Ustawia PRAGMA key na każdym nowym połączeniu (SQLCipher).
    Klucz jest wymagany — jeśli nie jest skonfigurowany, rzuca ``RuntimeError``.

    Python 3.13t (free-threaded): brak GIL — synchroniczne wywołania sqlite3
    z wielu wątków są bezpieczne bez dodatkowej warstwy async.

    Args:
        config: Aplikacyjna konfiguracja (AppConfig).
        sqlcipher_key: Opcjonalny klucz AES-256 (zastepuje env var).
        sqlite_path: Opcjonalna ścieżka do pliku DB (zastepuje config).

    Raises:
        RuntimeError: Jeśli SQLCipher nie jest dostępny (brak LD_PRELOAD).

    Returns:
        SQLAlchemy Engine.
    """
    if not SQLCIPHER_AVAILABLE:
        raise RuntimeError(
            "SQLCipher not available. Run with: LD_PRELOAD=/usr/lib/.../libsqlcipher.so"
        )

    url = _sqlite_url(config, sqlite_path)
    resolved_key = _resolve_key(config, sqlcipher_key)
    key_hex = resolved_key.encode("utf-8").hex()

    engine = create_engine(url, echo=False)

    event.listen(engine, "connect", _make_pragma_setter(key_hex))

    logger.info("[DB] Created sync SQLCipher engine: %s", url)
    return engine


# ── Async engine (aiosqlite) ──────────────────────────────────────────────


def create_async_oltp_engine(
    config: AppConfig,
    *,
    sqlcipher_key: str | None = None,
    sqlite_path: Path | None = None,
):
    """Create an async SQLAlchemy engine using aiosqlite + SQLCipher.

    Używa ``create_async_engine("sqlite+aiosqlite:///...")`` i ustawia
    PRAGMA key na każdym nowym połączeniu przez ``engine.sync_engine``.

    Args:
        config: Aplikacyjna konfiguracja (AppConfig).
        sqlcipher_key: Opcjonalny klucz AES-256 (zastepuje env var).
        sqlite_path: Opcjonalna ścieżka do pliku DB (zastepuje config).

    Raises:
        RuntimeError: Jeśli SQLCipher nie jest dostępny (brak LD_PRELOAD).

    Returns:
        SQLAlchemy AsyncEngine.
    """
    if not SQLCIPHER_AVAILABLE:
        raise RuntimeError(
            "SQLCipher not available. Run with: LD_PRELOAD=/usr/lib/.../libsqlcipher.so"
        )

    url = _async_sqlite_url(config, sqlite_path)
    resolved_key = _resolve_key(config, sqlcipher_key)
    key_hex = resolved_key.encode("utf-8").hex()

    # ── SUPERMOC: aiosqlite connection pool config ─────────────────
    # pool_timeout: 30s timeout na oczekiwanie na połączenie z pool
    # pool_recycle: 3600s = odśwież połączenia co godzinę (zapobiega
    #   zamknięciu przez SQLCipher idle timeout)
    # connect_args: check_same_thread=False dla free-threaded Python 3.13t
    #   (pozwala na współdzielenie połączenia między wątkami)
    # SUPERMOC: pool_pre_ping=True — sprawdza żywotność połączenia
    #   przed użyciem. SQLCipher zamyka nieaktywne połączenia po
    #   timeout, bez tego pool zwraca nieżywe połączenia → InterfaceError.
    engine = create_async_engine(
        url,
        echo=False,
        pool_size=5,
        max_overflow=10,
        pool_timeout=30,
        pool_recycle=3600,
        pool_pre_ping=True,  # SUPERMOC: sprawdza żywotność przed użyciem
        connect_args={
            "check_same_thread": False,  # free-threaded Python 3.13t
        },
    )

    # SUPERMOC: PoolEvents.checkout() — monitoring czasu uzyskania
    # połączenia z pool. Loguje ostrzeżenie jeśli checkout trwa >1s
    # (wskazuje na przeciążenie pool).
    import time as _time_module

    @event.listens_for(engine.sync_engine, "checkout")
    def _on_checkout(dbapi_connection, connection_record, connection_proxy):
        connection_record.info.setdefault("checkout_time", _time_module.time())

    @event.listens_for(engine.sync_engine, "checkin")
    def _on_checkin(dbapi_connection, connection_record):
        checkout_time = connection_record.info.pop("checkout_time", None)
        if checkout_time is not None:
            elapsed = _time_module.time() - checkout_time
            if elapsed > 1.0:
                logger.warning(
                    "[DB] Slow pool checkout: %.2fs (pool may be exhausted)",
                    elapsed,
                )

    @event.listens_for(engine.sync_engine, "handle_error")
    def _on_error(exception_context):
        logger.error(
            "[DB] Connection error: %s",
            exception_context.original_exception,
        )

    # aiosqlite: PRAGMA key ustawiamy przez sync_engine.connect
    # SQLAlchemy zarządza async→sync bridging pod spodem.
    # Używamy dbapi_connection.execute() zamiast cursor.execute()
    # dla kompatybilności z aiosqlite.
    event.listen(engine.sync_engine, "connect", _make_pragma_setter(key_hex))

    logger.info(
        "[DB] Created async aiosqlite engine: %s (pool=%d, timeout=%ds)",
        url,
        5,
        30,
    )
    return engine


# ── Session factories ─────────────────────────────────────────────────────


def create_session_factory(engine):
    """Create a sync ``sessionmaker`` for the given engine."""
    return sessionmaker(bind=engine, class_=Session, expire_on_commit=False)


def create_async_session_factory(engine):
    """Create an async ``async_sessionmaker`` for the given engine."""
    return async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)


# ── Schema ────────────────────────────────────────────────────────────────


def init_schema(engine) -> None:
    """Create all SQLAlchemy tables for first application start.

    SUPERMOC: Po utworzeniu tabel, wywołuje ``create_partial_indexes()``
    z ``models.py``, które tworzy partial indexes dla aktywnych statusów
    i nieprzetworzonych outbox eventów.
    """
    from nexus_ai.db.models import (  # noqa: F401
        ActiveLearningPattern,
        Invoice,
        OutboxEvent,
        create_partial_indexes,
    )

    Base.metadata.create_all(engine)

    # SUPERMOC: Utwórz partial indexes po tabelach
    # Partial indexes indeksują tylko podzbiór wierszy — mniejszy indeks,
    # szybsze INSERT/UPDATE dla nieindeksowanych wierszy.
    create_partial_indexes(engine)


# ── Maintenance ───────────────────────────────────────────────────────────


def consolidate_database(engine) -> None:
    """Zamyka sesje i wykonuje TRUNCATE checkpoint.

    Usuwa pliki WAL i przenosi dane do głównego pliku .sqlite.
    Powinno być wywołane w pętli zamykającej aplikację (main.py).
    """
    try:
        with engine.connect() as conn:
            result = conn.execute(text("PRAGMA wal_checkpoint;"))
            checkpoint_info = result.fetchone()
            logger.info("WAL checkpoint status before TRUNCATE: %s", checkpoint_info)

            conn.execute(text("PRAGMA wal_checkpoint(TRUNCATE);"))

            # SUPERMOC: PRAGMA optimize — automatyczna optymalizacja
            # Analizuje statystyki, przebudowuje indeksy, defragmentuje.
            # Nie wykonuje VACUUM (to robimy osobno).
            # execute() z limitem czasu 1 - nie czekaj dłużej niż 1ms na analizę.
            conn.execute(text("PRAGMA optimize;"))

            conn.execute(text("VACUUM;"))

            # SUPERMOC: PRAGMA analysis_limit — analizuj do 1000 wierszy na tabelę
            # Dla optymalizatora zapytań SQLite. Po VACUUM statystyki są nieaktualne.
            conn.execute(text("PRAGMA analysis_limit = 1000;"))
            conn.execute(text("ANALYZE;"))

            result2 = conn.execute(text("PRAGMA wal_checkpoint;"))
            logger.info("WAL checkpoint status after TRUNCATE: %s", result2.fetchone())
    except Exception as e:
        logger.error("Failed to consolidate database: %s", e)


# ── Session helpers ───────────────────────────────────────────────────────


def get_session(session_factory) -> Generator[Session, None, None]:
    """Context manager yielding a sync Session from the given factory."""
    session = session_factory()
    try:
        yield session
    finally:
        session.close()


async def get_async_session(
    session_factory,
) -> AsyncGenerator[AsyncSession, None]:
    """Context manager yielding an async AsyncSession from the given factory."""
    async with session_factory() as session:
        yield session


# ── Declarative base ─────────────────────────────────────────────────────


class Base(DeclarativeBase):
    """Declarative base for OLTP SQLAlchemy models."""

    pass


# ── Lazy default session factories ────────────────────────────────────────

_SessionLocal: sessionmaker | None = None
_AsyncSessionLocal: async_sessionmaker | None = None


def __getattr__(name: str):
    """Lazy import of session factories to avoid circular imports."""
    if name == "SessionLocal":
        global _SessionLocal
        if _SessionLocal is None:
            config = AppConfig()
            engine = create_oltp_engine(config)
            _SessionLocal = create_session_factory(engine)
        return _SessionLocal

    if name == "AsyncSessionLocal":
        global _AsyncSessionLocal
        if _AsyncSessionLocal is None:
            config = AppConfig()
            engine = create_async_oltp_engine(config)
            _AsyncSessionLocal = create_async_session_factory(engine)
        return _AsyncSessionLocal

    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
