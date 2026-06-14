#!/usr/bin/env python3
"""
SQLCipher Key Rotation Scheduler — harmonogram rotacji kluczy SQLCipher.

SUPERMOCE:
- Rotacja kluczy AES-256 co 90 dni (zgodne z GDPR/PCI-DSS)
- Automatyczny szyfrowany backup PRZED rotacją (inny klucz niż produkcyjny)
- Podwójna weryfikacja: przed i po rotacji
- Wsparcie dla wielu baz danych (OLTP, event store, DuckDB)
- Może być uruchamiany przez cron/systemd timer
- Status zapisywany do JSON (monitoring/widoczność)

Zgodnie z docs/SQLCIPHER_AUDIT.md:
- PCI-DSS wymaga rotacji kluczy co 90 dni
- Backupy przechowywane z innym kluczem (offline)
- Każda rotacja logowana z hashem klucza (bez raw values)

Usage:
    # Ręczne uruchomienie rotacji:
    python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler

    # Z harmonogramem (cron): 0 3 1 */3 * (co 90 dni o 3:00)
    0 3 1 1,4,7,10 * /usr/bin/python3 -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler

    # Tylko weryfikacja (bez rotacji):
    python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler --verify-only

    # Niestandardowe ścieżki baz:
    python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler \\
        --db-paths /data/nexus/oltp.db,/data/nexus/events.db \\
        --backup-dir /mnt/backups/sqlcipher \\
        --days 90
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

# Import lokalny — pozwala na import niezależny od ścieżek
try:
    from nexus_ai.db.sqlcipher_key_rotation import (
        ReKeyResult,
        create_encrypted_backup,
        get_key_hash,
        rekey_database,
        verify_sqlcipher_key,
    )
except ImportError:
    # Fallback dla bezpośredniego uruchomienia
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
    from nexus_ai.db.sqlcipher_key_rotation import (
        ReKeyResult,
        create_encrypted_backup,
        get_key_hash,
        rekey_database,
        verify_sqlcipher_key,
    )

# ── Konfiguracja ─────────────────────────────────────────────────────────

# Domyślne ścieżki baz danych (nadpisywalne przez --db-paths)
DEFAULT_DB_PATHS = [
    "app_data/databases/nexus_oltp.db",
    "app_data/databases/idempotency.sqlite",
]

# Domyślny katalog backupów (nadpisywalny przez --backup-dir)
DEFAULT_BACKUP_DIR = "app_data/backups/sqlcipher"

# Domyślny interwał rotacji w dniach (nadpisywalny przez --days)
DEFAULT_ROTATION_DAYS = 90

# Plik statusu — JSON z datą ostatniej rotacji
STATUS_FILE = "app_data/backups/sqlcipher_rotation_status.json"


# ── Główna logika ────────────────────────────────────────────────────────


class RotationStatus:
    """Stan rotacji — data ostatniej rotacji i hash klucza.

    SUPERMOC: Status przechowywany w JSON po każdej rotacji.
    Pozwala na monitoring i weryfikację czy rotacja jest wymagana.
    """

    def __init__(self, status_file: str | Path) -> None:
        self._path = Path(status_file)
        self._data: dict[str, Any] = self._load()

    def _load(self) -> dict[str, Any]:
        """Wczytaj status z pliku JSON."""
        if self._path.exists():
            try:
                with open(self._path) as f:
                    return json.load(f)
            except (json.JSONDecodeError, OSError):
                pass
        return {
            "last_rotation": None,
            "key_hashes": {},
            "rotation_count": 0,
            "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }

    def save(self) -> None:
        """Zapisz status do pliku JSON."""
        self._path.parent.mkdir(parents=True, exist_ok=True)
        with open(self._path, "w") as f:
            json.dump(self._data, f, indent=2, default=str)

    def is_rotation_due(self, days: int = DEFAULT_ROTATION_DAYS) -> bool:
        """Sprawdź czy rotacja jest wymagana.

        Returns:
            True jeśli minęło 'days' dni od ostatniej rotacji lub brak rotacji.
        """
        last = self._data.get("last_rotation")
        if not last:
            return True
        try:
            last_date = datetime.datetime.fromisoformat(last)
            delta = datetime.datetime.now(datetime.timezone.utc) - last_date
            return delta.days >= days
        except (ValueError, TypeError):
            return True

    def record_rotation(
        self,
        db_path: str,
        old_key_hash: str,
        new_key_hash: str,
        backup_path: str,
        duration_ms: float,
    ) -> None:
        """Zapisz udaną rotację w statusie."""
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        self._data["last_rotation"] = now
        self._data.setdefault("rotations", []).append({
            "timestamp": now,
            "db_path": db_path,
            "old_key_hash": old_key_hash,
            "new_key_hash": new_key_hash,
            "backup_path": backup_path,
            "duration_ms": duration_ms,
        })
        # Zachowaj tylko ostatnie 10 wpisów
        if len(self._data["rotations"]) > 10:
            self._data["rotations"] = self._data["rotations"][-10:]
        self._data["key_hashes"][db_path] = new_key_hash
        self._data["rotation_count"] = self._data.get("rotation_count", 0) + 1
        self.save()

    def needs_initial_rotation(self) -> bool:
        """Czy potrzeba pierwszej rotacji (brak zapisanej historii)."""
        return not self._data.get("last_rotation")


def verify_all_databases(db_paths: list[Path]) -> dict[str, bool]:
    """Zweryfikuj wszystkie bazy danych — sprawdź czy klucze działają.

    SUPERMOC: Weryfikacja integralności PRZED rotacją — zapobiega
    utracie danych jeśli klucz jest niepoprawny.

    Args:
        db_paths: Lista ścieżek do baz danych.

    Returns:
        Słownik: {ścieżka_bazy: czy_poprawny_klucz}
    """
    results: dict[str, bool] = {}
    for db_path in db_paths:
        if not db_path.exists():
            print(f"  ⚠️  DB nie istnieje: {db_path}")
            results[str(db_path)] = False
            continue
        valid = verify_sqlcipher_key(str(db_path))
        results[str(db_path)] = valid
        if valid:
            print(f"  ✅ {db_path.name}: klucz poprawny")
        else:
            print(f"  ❌ {db_path.name}: KLUCZ NIEPOPRAWNY!")
    return results


def rotate_database(
    db_path: Path,
    backup_dir: Path,
    status: RotationStatus,
    force: bool = False,
) -> ReKeyResult:
    """Wykonaj rotację klucza dla pojedynczej bazy danych.

    Args:
        db_path: Ścieżka do pliku DB.
        backup_dir: Katalog na backup przed rotacją.
        status: Obiekt statusu rotacji.
        force: Wymuś rotację nawet jeśli nie minął interwał.

    Returns:
        ReKeyResult z wynikiem rotacji.
    """
    print(f"\n  🔑 Rotacja klucza dla: {db_path.name}")
    print(f"  ├─ Backup → {backup_dir}/{db_path.stem}_pre_rekey_*.db")

    result = rekey_database(
        db_path=str(db_path),
        backup_dir=str(backup_dir),
    )

    if result.success:
        print(f"  ├─ Stary klucz: {result.old_key_hash}")
        print(f"  ├─ Nowy klucz:  {result.new_key_hash}")
        print(f"  ├─ Backup:      {result.backup_path or 'brak'}")
        print(f"  └─ Czas:        {result.duration_ms:.0f}ms ✅")

        # Zapisz w statusie
        status.record_rotation(
            db_path=str(db_path),
            old_key_hash=result.old_key_hash,
            new_key_hash=result.new_key_hash,
            backup_path=result.backup_path,
            duration_ms=result.duration_ms,
        )
    else:
        print(f"  └─ ❌ BŁĄD: {result.error}")

    return result


def run_scheduled_rotation(
    db_paths: list[Path],
    backup_dir: Path,
    rotation_days: int,
    force: bool = False,
    verify_only: bool = False,
) -> int:
    """Główna funkcja — wykonaj zaplanowaną rotację.

    Algorytm:
    1. Wczytaj status ostatniej rotacji
    2. Jeśli verify_only: tylko weryfikacja
    3. Sprawdź czy minął interwał (lub force)
    4. Backup wszystkich baz
    5. Rotacja klucza każdej bazy
    6. Weryfikacja po rotacji
    7. Zapisz status

    Args:
        db_paths: Lista ścieżek do baz danych.
        backup_dir: Katalog na backup.
        rotation_days: Interwał rotacji w dniach.
        force: Wymuś rotację.
        verify_only: Tylko weryfikacja, bez rotacji.

    Returns:
        0 = sukces, 1 = błąd, 2 = rotacja nie wymagana.
    """
    status = RotationStatus(STATUS_FILE)
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()

    print("=" * 60)
    print(f"  SQLCipher Key Rotation Scheduler")
    print(f"  Data: {now}")
    print(f"  Interwał: {rotation_days} dni")
    print(f"  Bazy: {[p.name for p in db_paths]}")
    print(f"  Backup: {backup_dir}")
    print("=" * 60)

    # Krok 1: Weryfikacja wszystkich baz
    print("\n📋 Krok 1: Weryfikacja kluczy przed rotacją...")
    pre_results = verify_all_databases(db_paths)

    all_valid = all(pre_results.values())
    if not all_valid:
        print("\n❌ Niektóre bazy mają niepoprawne klucze — przerywam!")
        return 1

    if verify_only:
        print("\n✅ Weryfikacja zakończona — wszystkie klucze poprawne.")
        return 0

    # Krok 2: Sprawdź czy rotacja wymagana
    print(f"\n⏰ Krok 2: Sprawdzanie interwału ({rotation_days} dni)...")
    if not force and not status.is_rotation_due(rotation_days):
        last = status._data.get("last_rotation", "nigdy")
        print(f"  ⏭️  Rotacja nie wymagana — ostatnia: {last}")
        print(f"  (użyj --force aby wymusić)")
        return 2

    if status.needs_initial_rotation():
        print(f"  🆕 Pierwsza rotacja — brak historii")
    else:
        last = status._data["last_rotation"]
        print(f"  🔄 Ostatnia rotacja: {last}")

    # Krok 3: Wykonaj rotację dla każdej bazy
    print(f"\n🔑 Krok 3: Rotacja kluczy...")
    all_success = True

    for db_path in db_paths:
        if not db_path.exists():
            print(f"  ⚠️  Pomijam — baza nie istnieje: {db_path}")
            continue

        result = rotate_database(
            db_path=db_path,
            backup_dir=backup_dir,
            status=status,
            force=force,
        )
        if not result.success:
            all_success = False

    # Krok 4: Weryfikacja po rotacji
    print(f"\n✅ Krok 4: Weryfikacja po rotacji...")
    post_results = verify_all_databases(db_paths)
    all_post_valid = all(post_results.values())

    # Krok 5: Podsumowanie
    print("\n" + "=" * 60)
    if all_success and all_post_valid:
        print("  ✅ ROTACJA ZAKOŃCZONA SUKCESEM")
        print(f"  Bazy: {len(db_paths)}")
        print(f"  Klucze: wszystkie poprawne")
        status.save()
        return 0
    else:
        print("  ❌ ROTACJA ZAKOŃCZONA Z BŁĘDAMI")
        failed = [p.name for p in db_paths if not post_results.get(str(p), False)]
        print(f"  Bazy z błędem: {failed}")
        return 1


# ── CLI ───────────────────────────────────────────────────────────────────


def create_parser() -> argparse.ArgumentParser:
    """Utwórz parser argumentów CLI."""
    parser = argparse.ArgumentParser(
        description="SQLCipher Key Rotation Scheduler — rotacja kluczy co 90 dni",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Przykłady:
  # Ręczne uruchomienie
  python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler

  # Tylko weryfikacja
  python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler --verify-only

  # Wymuś rotację natychmiast
  python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler --force

  # Rotacja co 30 dni z niestandardowymi bazami
  python -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler --days 30

  # Cron: co 90 dni o 3:00 rano (styczeń, kwiecień, lipiec, październik)
  0 3 1 1,4,7,10 * /usr/bin/python3 -m nexus_ai.scripts.sqlcipher_key_rotation_scheduler
        """,
    )
    parser.add_argument(
        "--db-paths",
        type=str,
        default=",".join(DEFAULT_DB_PATHS),
        help=f"Ścieżki do baz danych (przecinek). Default: {','.join(DEFAULT_DB_PATHS)}",
    )
    parser.add_argument(
        "--backup-dir",
        type=str,
        default=DEFAULT_BACKUP_DIR,
        help=f"Katalog backupów. Default: {DEFAULT_BACKUP_DIR}",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=DEFAULT_ROTATION_DAYS,
        help=f"Interwał rotacji w dniach. Default: {DEFAULT_ROTATION_DAYS}",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Wymuś rotację nawet jeśli nie minął interwał",
    )
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="Tylko weryfikacja kluczy, bez rotacji",
    )
    parser.add_argument(
        "--base-dir",
        type=str,
        default=".",
        help="Katalog bazowy dla ścieżek (jeśli względne). Default: .",
    )
    return parser


def main() -> int:
    """Główna funkcja — entry point dla CLI."""
    parser = create_parser()
    args = parser.parse_args()

    base_dir = Path(args.base_dir).resolve()
    db_paths = [
        (base_dir / p.strip()).resolve() if not Path(p.strip()).is_absolute()
        else Path(p.strip())
        for p in args.db_paths.split(",")
    ]
    backup_dir = (
        base_dir / args.backup_dir if not Path(args.backup_dir).is_absolute()
        else Path(args.backup_dir)
    )

    return run_scheduled_rotation(
        db_paths=db_paths,
        backup_dir=backup_dir,
        rotation_days=args.days,
        force=args.force,
        verify_only=args.verify_only,
    )


if __name__ == "__main__":
    sys.exit(main())
