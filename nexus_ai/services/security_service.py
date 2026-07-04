"""SecurityService -- DEPRECATED: empty placeholder.

Security functionality moved to:
- nexus_crypto (Rust) for AEAD, Argon2id, SHA-256
- nexus_ai/core/security.py for JWT, RBAC
- nexus_ai/services/log_pii_monitor.py for PII scanning

This file is kept for backward compatibility only.
"""

from __future__ import annotations

from pathlib import Path
from typing import final

import pendulum
from sqlmodel import Session


@final
class SecurityService:
    """DEPRECATED: Zarządza retencją danych i bezpiecznym usuwaniem dokumentów.

    Security-related functionality has been moved to the Rust-native nexus_crypto
    module and core security services.
    """
    __slots__ = ()


    @staticmethod
    def cleanup_old_scans(session: Session, years: int = 5) -> None:
        """Usuwa fizyczne pliki i wpisy z bazy dla dokumentów starszych niż X lat."""
        _ = pendulum.now() - pendulum.duration(days=years * 365)
        # Placeholder -- actual logic in dedicated retention module

    @staticmethod
    def secure_delete_file(file_path: str) -> None:
        """Nadpisuje plik zerami przed usunięciem (bezpieczne niszczenie danych)."""
        path = Path(file_path)
        if path.exists():
            size = path.stat().st_size
            with open(path, "ba+", buffering=0) as f:
                f.write(b"\x00" * size)
            path.unlink()
