"""
run_migrations.py — natywny system migracji SQLite (zastępuje Alembic).

Python 3.13t (free-threaded): synchroniczne sqlite3 + anyio.to_thread.run_sync.

System:
1. Tworzy tabelę _migrations_version jeśli nie istnieje
2. Odczytuje pliki SQL z katalogu migrations/
3. Wykonuje tylko te, które nie zostały jeszcze zastosowane
4. Loguje postęp przez structlog
5. Wspiera SQLCipher (PRAGMA key)

Usage:
    python -m migrations.run_migrations              # Wszystkie migracje
    python -m migrations.run_migrations --target 003  # Do konkretnej migracji

Zgodnie z zasadą nadrzędną: zero utraty funkcjonalności.
Każda migracja (001-004) została napisana jako czysty SQL
w plikach 001_init.sql - 004_supermoces.sql.
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import time
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.migrations")

MIGRATIONS_DIR = Path(__file__).resolve().parent

MIGRATION_FILES: list[Path] = sorted(
    [p for p in MIGRATIONS_DIR.glob("[0-9]*.sql") if p.is_file()],
    key=lambda p: p.name,
)


# ── Connection helpers ──────────────────────────────────────────────────


def get_sqlite_conn(
    db_path: str,
    sqlcipher_key: str | None = None,
) -> sqlite3.Connection:
    """Utwórz połączenie SQLite z PRAGMAMI.

    Python 3.13t (free-threaded): check_same_thread=False dla wielowątkowości.

    SQLCipher: PRAGMA key musi być PIERWSZĄ operacją po connect().
    """
    conn = sqlite3.connect(str(db_path), check_same_thread=False)
    conn.row_factory = sqlite3.Row

    # SQLCipher: PRAGMA key FIRST!
    if sqlcipher_key:
        key_hex = sqlcipher_key.encode("utf-8").hex()
        conn.execute(f"PRAGMA key = x'{key_hex}';")

    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    conn.execute("PRAGMA foreign_keys = ON;")

    return conn


# ── Migration table ─────────────────────────────────────────────────────


def ensure_migrations_table(conn: sqlite3.Connection) -> None:
    """Utwórz tabelę śledzącą zastosowane migracje."""
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS _migrations_version (
            filename    TEXT PRIMARY KEY,
            applied_at  TEXT NOT NULL DEFAULT (datetime('now')),
            duration_ms INTEGER NOT NULL DEFAULT 0
        );
    """)
    conn.commit()


def get_applied_migrations(conn: sqlite3.Connection) -> set[str]:
    """Zwróć zbiór nazw plików już zastosowanych migracji."""
    cursor = conn.execute("SELECT filename FROM _migrations_version ORDER BY filename")
    return {str(row["filename"]) for row in cursor.fetchall()}


def get_current_version(db_path: str | Path) -> str | None:
    """Pobierz aktualną wersję migracji (ostatni zastosowany plik).

    Args:
        db_path: Ścieżka do pliku bazy danych.

    Returns:
        Nazwa pliku ostatniej migracji, lub None jeśli brak.
    """
    if not Path(db_path).exists():
        return None
    try:
        conn = get_sqlite_conn(str(db_path))
        try:
            ensure_migrations_table(conn)
            cursor = conn.execute(
                "SELECT filename FROM _migrations_version ORDER BY filename DESC LIMIT 1"
            )
            row = cursor.fetchone()
            return str(row["filename"]) if row else None
        finally:
            conn.close()
    except Exception:
        return None


def get_migration_history(db_path: str | Path) -> list[dict[str, Any]]:
    """Zwróć historię zastosowanych migracji.

    Args:
        db_path: Ścieżka do pliku bazy danych.

    Returns:
        Lista słowników: filename, applied_at, duration_ms.
    """
    if not Path(db_path).exists():
        return []
    try:
        conn = get_sqlite_conn(str(db_path))
        try:
            ensure_migrations_table(conn)
            cursor = conn.execute(
                "SELECT filename, applied_at, duration_ms FROM _migrations_version ORDER BY filename"
            )
            return [dict(row) for row in cursor.fetchall()]
        finally:
            conn.close()
    except Exception:
        return []


# ── Apply migration ─────────────────────────────────────────────────────


def apply_migration(
    conn: sqlite3.Connection,
    sql_path: Path,
) -> dict[str, Any]:
    """Wykonaj pojedynczy plik migracji SQL.

    Args:
        conn: Połączenie SQLite.
        sql_path: Ścieżka do pliku SQL.

    Returns:
        Słownik z rezultatem.
    """
    sql = sql_path.read_text(encoding="utf-8")

    start = time.perf_counter()
    conn.executescript(sql)
    conn.commit()
    duration_ms = int((time.perf_counter() - start) * 1000)

    # Zapisz metadane migracji
    conn.execute(
        "INSERT INTO _migrations_version (filename, duration_ms) VALUES (?, ?)",
        (sql_path.name, duration_ms),
    )
    conn.commit()

    return {"filename": sql_path.name, "duration_ms": duration_ms}


# ── Main migration runner ───────────────────────────────────────────────


def run_migrations(
    db_path: str | Path,
    sqlcipher_key: str | None = None,
    target: str | None = None,
    dry_run: bool = False,
) -> dict[str, Any]:
    """Wykonaj wszystkie oczekujące migracje.

    Args:
        db_path: Ścieżka do pliku bazy danych SQLite.
        sqlcipher_key: Opcjonalny klucz SQLCipher.
        target: Jeśli podany, wykonaj tylko do (włącznie) tej migracji.
        dry_run: Jeśli True, tylko wypisz co zostanie wykonane.

    Returns:
        Słownik z wynikami.
    """
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)

    conn = get_sqlite_conn(str(db_path), sqlcipher_key)
    results: dict[str, Any] = {
        "applied": [],
        "skipped": [],
        "total_duration_ms": 0,
        "is_dry_run": dry_run,
    }

    try:
        ensure_migrations_table(conn)
        applied = get_applied_migrations(conn)

        for sql_file in MIGRATION_FILES:
            if target and sql_file.name > target:
                break

            if sql_file.name in applied:
                results["skipped"].append(sql_file.name)
                logger.info("[MIGRATIONS] Already applied: %s", sql_file.name)
                continue

            if dry_run:
                logger.info("[MIGRATIONS] [DRY-RUN] Would apply: %s", sql_file.name)
                results["applied"].append(sql_file.name)
                continue

            logger.info("[MIGRATIONS] Applying: %s...", sql_file.name)
            try:
                result = apply_migration(conn, sql_file)
                results["applied"].append(sql_file.name)
                results["total_duration_ms"] += result["duration_ms"]
                logger.info(
                    "[MIGRATIONS] Applied: %s (%d ms)",
                    sql_file.name, result["duration_ms"],
                )
            except Exception as exc:
                logger.error(
                    "[MIGRATIONS] FAILED: %s — %s", sql_file.name, exc
                )
                results.setdefault("errors", []).append(
                    {"file": sql_file.name, "error": str(exc)}
                )
                raise

        # PRAGMA optimize po migracjach
        try:
            conn.execute("PRAGMA optimize;")
        except Exception:
            pass

        logger.info(
            "[MIGRATIONS] Complete: %d applied, %d skipped (%d ms total)",
            len(results["applied"]),
            len(results["skipped"]),
            results["total_duration_ms"],
        )

        return results

    finally:
        conn.close()


# ── CLI ──────────────────────────────────────────────────────────────────


def resolve_db_path(db_path: str | None = None) -> str:
    """Rozwiąż ścieżkę do pliku bazy danych.

    Kolejność:
    1. Jawny argument --db-path
    2. Zmienna środowiskowa NEXUS_DB_PATH
    3. AppConfig.sqlite_path
    4. Domyślna ścieżka app_data/nexus.db

    Args:
        db_path: Jawnie podana ścieżka.

    Returns:
        Bezwzględna ścieżka do pliku DB.
    """
    if db_path:
        return str(Path(db_path).resolve())

    env_path = os.environ.get("NEXUS_DB_PATH", "")
    if env_path:
        return str(Path(env_path).resolve())

    try:
        from nexus_ai.core.config import AppConfig
        config = AppConfig()
        return str(config.sqlite_path.resolve())
    except Exception:
        pass

    return str((Path.cwd() / "app_data" / "nexus.db").resolve())


def main(argv: list[str] | None = None) -> int:
    """CLI entry point: python -m migrations.run_migrations [options]"""
    parser = argparse.ArgumentParser(
        description="NexusAI Native SQLite Migration System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Przykłady:
  python -m migrations.run_migrations
  python -m migrations.run_migrations --db-path /tmp/test.db
  python -m migrations.run_migrations --target 003_service_tables.sql
  python -m migrations.run_migrations --dry-run
  python -m migrations.run_migrations --current
  python -m migrations.run_migrations --history

Pliki migracji: {MIGRATIONS_DIR}
""",
    )
    parser.add_argument(
        "--db-path",
        default=None,
        help="Ścieżka do pliku bazy danych (domyślnie: auto-wykrywanie)",
    )
    parser.add_argument(
        "--target",
        default=None,
        help="Docelowa migracja (np. 004_supermoces.sql)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Tylko wypisz co zostanie wykonane bez zmian w DB",
    )
    parser.add_argument(
        "--current",
        action="store_true",
        help="Pokaż aktualną wersję migracji",
    )
    parser.add_argument(
        "--history",
        action="store_true",
        help="Pokaż historię migracji",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Szczegółowe logowanie",
    )

    args = parser.parse_args(argv)

    # Rozwiąż ścieżkę DB
    db_path = resolve_db_path(args.db_path)

    if args.verbose:
        import logging
        logging.basicConfig(level=logging.DEBUG)

    print(f"\n{'=' * 60}")
    print("  NEXUSAI — SYSTEM MIGRACJI BAZY DANYCH")
    print(f"  Baza: {db_path}")
    print(f"{'=' * 60}\n")

    # Pokaż aktualną wersję
    if args.current:
        ver = get_current_version(db_path)
        if ver:
            print(f"✓ Aktualna wersja migracji: {ver}")
        else:
            print("ℹ Świeża baza danych — brak migracji")
        return 0

    # Pokaż historię
    if args.history:
        history = get_migration_history(db_path)
        if history:
            print(f"Historia migracji ({len(history)} wpisów):")
            print()
            print(f"{'Plik':40s} {'Data':25s} {'Czas':>8s}")
            print(f"{'-'*40} {'-'*25} {'-'*8}")
            for h in history:
                print(f"{h['filename']:40s} {str(h['applied_at'])[:19]:25s} {h['duration_ms']:>6d}ms")
        else:
            print("ℹ Brak historii migracji")
        return 0

    # Sprawdź czy są pliki migracji
    if not MIGRATION_FILES:
        print("\n⚠ BRAK PLIKÓW MIGRACJI!")
        print(f"   Katalog: {MIGRATIONS_DIR}")
        print("   Oczekiwane pliki: [0-9]*.sql")
        return 1

    print(f"Znaleziono {len(MIGRATION_FILES)} plików migracji:")
    for f in MIGRATION_FILES:
        print(f"  • {f.name}")
    print()

    # Wykonaj migracje
    sqlcipher_key = os.environ.get("NEXUS_SQLCIPHER_KEY", "").strip() or None

    try:
        result = run_migrations(
            db_path=db_path,
            sqlcipher_key=sqlcipher_key,
            target=args.target,
            dry_run=args.dry_run,
        )
    except Exception as exc:
        print(f"\n❌ BŁĄD MIGRACJI: {exc}")
        return 1

    # Podsumowanie
    print(f"\n{'=' * 60}")
    print("  PODSUMOWANIE MIGRACJI")
    print(f"{'=' * 60}")
    print(f"  Zastosowano: {len(result['applied'])}")
    print(f"  Pominięto:   {len(result['skipped'])}")
    if not result.get("is_dry_run"):
        print(f"  Czas:        {result['total_duration_ms']} ms")
    if result.get("is_dry_run"):
        print(f"  Tryb:        DRY RUN (bez zmian)")

    errors = result.get("errors", [])
    if errors:
        print(f"  Błędy:       {len(errors)}")
        for err in errors:
            print(f"    - {err['file']}: {err['error']}")
        return 1

    print(f"\n✓ Migracje zakończone sukcesem.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
