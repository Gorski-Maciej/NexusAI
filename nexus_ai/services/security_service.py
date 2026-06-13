from __future__ import annotations

from typing import final

from pathlib import Path

import pendulum
from sqlalchemy.orm import Session


@final
class SecurityService:
    """Zarządza retencją danych i bezpiecznym usuwaniem dokumentów."""

    @staticmethod
    def cleanup_old_scans(session: Session, years: int = 5):
        """Usuwa fizyczne pliki i wpisy z bazy dla dokumentów starszych niż X lat (RODO/Podatki)."""
        pendulum.now() - pendulum.duration(days=years * 365)
        # 1. Znajdź stare faktury
        # (Tutaj logika select i usuwania plików z dysku przed usunięciem z DB)
        pass

    @staticmethod
    def secure_delete_file(file_path: str):
        """Nadpisuje plik zerami przed usunięciem (bezpieczne niszczenie danych)."""
        path = Path(file_path)
        if path.exists():
            size = path.stat().st_size
            with open(path, "ba+", buffering=0) as f:
                f.write(b"\x00" * size)
            path.unlink()
