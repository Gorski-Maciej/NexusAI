"""canary_deployments.py — Canary Deployments (v7.0 Innowacja 8).

  Każda nowa wersja jest najpierw wdrażana jako "canary":
  - Równoległe instancje starej i nowej wersji
  - Monitoring: error rate, response time, crash rate
  - Automatyczny rollback przy regresji
  - Zero-downtime deployment

  Mechanizm:
  - version.json zawiera pole `canary: true/false` i `canary_percentage: 5`
  - Klient sprawdza `hash(user_id) % 100 < canary_percentage`
  - Canary users dostają nową wersję, reszta starą
  - Jeśli error_rate > threshold → auto-rollback przez version.json update
  - Po 24h bez błędów → canary promowane do full rollout
"""

from __future__ import annotations

import hashlib
import time as _time
from typing import Any

import httpx
import pendulum
from structlog import get_logger

logger = get_logger("nexus.deploy.canary")


# ── Canary Manager ──────────────────────────────────────────────────────────


class CanaryDeploymentManager:
    """Zarządza stopniowym wdrażaniem nowych wersji (canary deployments).

    Użycie:
        manager = CanaryDeploymentManager(user_id="user-123")
        if manager.is_canary_user("v2.1.0"):
            # Pobierz i uruchom wersję canary
            ...
    """

    ERROR_RATE_THRESHOLD = 0.02   # 2% — powyżej → rollback
    CANARY_PROMOTION_HOURS = 24   # Po 24h bez błędów → full rollout

    def __init__(
        self,
        user_id: str = "",
        version_endpoint: str = "https://nexusai.app/version.json",
    ):
        self.user_id = user_id
        self.version_endpoint = version_endpoint
        self._canary_state: dict[str, Any] = {}
        self._error_counts: dict[str, int] = {}
        self._last_check: float = 0

    async def fetch_version_info(self) -> dict[str, Any] | None:
        """Pobierz informacje o wersji (w tym canary status)."""
        try:
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(10.0),
                http2=True,
            ) as client:
                resp = await client.get(self.version_endpoint)
                if resp.status_code == 200:
                    self._canary_state = resp.json()
                    self._last_check = _time.time()
                    return self._canary_state
        except Exception as exc:
            logger.debug("[CANARY] Version fetch failed: %s", exc)
        return None

    def is_canary_user(self, version: str) -> bool:
        """Sprawdź czy użytkownik powinien dostać wersję canary.

        Args:
            version: Wersja do sprawdzenia

        Returns:
            True jeśli użytkownik kwalifikuje się do canary
        """
        canary_config = self._canary_state.get("canary", {})
        if not canary_config:
            return False

        canary_version = canary_config.get("version", "")
        if canary_version != version:
            return False

        percentage = canary_config.get("percentage", 0)
        if percentage <= 0:
            return False
        if percentage >= 100:
            return True

        # Deterministyczny podział użytkowników (v7.0: fallback dla pustego user_id)
        uid = self.user_id or "unknown"
        hash_val = int(
            hashlib.md5((uid + version).encode()).hexdigest()[:8], 16
        )
        return (hash_val % 100) < percentage

    def record_error(self, version: str):
        """Zarejestruj błąd dla wersji canary.

        Args:
            version: Wersja która wygenerowała błąd
        """
        key = f"canary:{version}"
        self._error_counts[key] = self._error_counts.get(key, 0) + 1

        count = self._error_counts[key]
        if count >= 3:
            logger.warning(
                "[CANARY] High error count for canary %s: %d errors",
                version, count,
            )

    def get_error_rate(self, version: str, total_requests: int = 0) -> float:
        """Oblicz error rate dla wersji canary.

        Args:
            version: Wersja canary
            total_requests: Całkowita liczba requestów (domyślnie 0)

        Returns:
            Error rate 0.0-1.0
        """
        key = f"canary:{version}"
        errors = self._error_counts.get(key, 0)
        if total_requests <= 0:
            return 1.0 if errors > 0 else 0.0
        return errors / total_requests

    def should_rollback(self, version: str, total_requests: int = 0) -> bool:
        """Sprawdź czy powinien nastąpić rollback wersji canary.

        Args:
            version: Wersja canary
            total_requests: Całkowita liczba requestów

        Returns:
            True jeśli error_rate > 2% lub 3+ crashy
        """
        # 3+ crashy → natychmiastowy rollback
        key = f"canary:{version}"
        if self._error_counts.get(key, 0) >= 3:
            logger.critical(
                "[CANARY] Rollback triggered: %d errors for %s",
                self._error_counts[key], version,
            )
            return True

        # Error rate > 2% → rollback
        if total_requests > 100:
            rate = self.get_error_rate(version, total_requests)
            if rate > self.ERROR_RATE_THRESHOLD:
                logger.critical(
                    "[CANARY] Rollback triggered: error rate %.1f%% for %s",
                    rate * 100, version,
                )
                return True

        return False

    def can_promote(self, version: str) -> bool:
        """Sprawdź czy wersja canary może być promowana do full rollout.

        Warunki:
        - Minęło >= 24h od deploymentu
        - Brak krytycznych błędów

        Args:
            version: Wersja canary

        Returns:
            True jeśli można promować
        """
        canary_config = self._canary_state.get("canary", {})
        deployed_at = canary_config.get("deployed_at", "")

        if not deployed_at:
            return False

        try:
            deployed = pendulum.parse(deployed_at)
            now = pendulum.now("UTC")
            hours_elapsed = (now - deployed).in_hours()

            if hours_elapsed < self.CANARY_PROMOTION_HOURS:
                logger.debug(
                    "[CANARY] Not ready for promotion: %d/%d hours",
                    hours_elapsed, self.CANARY_PROMOTION_HOURS,
                )
                return False
        except Exception:
            return False

        # Sprawdź error count
        key = f"canary:{version}"
        errors = self._error_counts.get(key, 0)
        if errors > 0:
            logger.warning(
                "[CANARY] Cannot promote: %d errors for %s",
                errors, version,
            )
            return False

        logger.info(
            "[CANARY] ✓ Version %s ready for promotion!", version,
        )
        return True

    def get_canary_report(self) -> dict[str, Any]:
        """Wygeneruj raport canary dla dashboardu.

        Returns:
            Dict z metrykami canary
        """
        canary_config = self._canary_state.get("canary", {})
        version = canary_config.get("version", "none")
        key = f"canary:{version}"

        return {
            "active": bool(canary_config),
            "version": version,
            "percentage": canary_config.get("percentage", 0),
            "deployed_at": canary_config.get("deployed_at", ""),
            "is_canary_user": self.is_canary_user(version),
            "error_count": self._error_counts.get(key, 0),
            "ready_for_promotion": self.can_promote(version) if canary_config else False,
        }
