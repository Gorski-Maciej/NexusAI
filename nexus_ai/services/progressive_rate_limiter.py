"""
ProgressiveRateLimiter — Progressive Rate Limiting z exponential backoff (v7.0 Audit).

Raport v7.0, sekcja 2.4:
  - "Brak progressive rate limiting (zwiększanie czasu blokady)"
  - "Brak IP blacklist po przekroczeniu limitu"

Enterprise v7.0:
  - Exponential backoff: 1min → 5min → 15min → 60min → IP ban
  - IP blacklist po wielokrotnym przekroczeniu
  - Per-endpoint tracking
  - Auto-reset po cooldown period
"""

from __future__ import annotations

import time as _time
from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.rate_limit")


@dataclass
class RateLimitEntry:
    """Wpis rate limitu dla adresu IP/identyfikatora."""

    identifier: str
    first_violation: float  # timestamp pierwszego naruszenia
    violation_count: int = 1
    current_backoff_seconds: float = 60.0  # Start: 1 minuta
    blocked_until: float = 0.0
    permanently_banned: bool = False


class ProgressiveRateLimiter:
    """Progresywny rate limiter z exponential backoff.

    Usage:
        limiter = ProgressiveRateLimiter()
        if limiter.is_blocked("192.168.1.1"):
            return "Too many requests — try again later"
        if limiter.check_violation("192.168.1.1"):
            limiter.record_violation("192.168.1.1")
    """

    # ── Backoff tiers ──────────────────────────────────────────────

    BACKOFF_TIERS: list[tuple[int, float]] = [
        (3, 60.0),     # 3 naruszenia → 1 min
        (6, 300.0),    # 6 naruszeń → 5 min
        (10, 900.0),   # 10 naruszeń → 15 min
        (15, 3600.0),  # 15 naruszeń → 60 min
    ]
    PERMANENT_BAN_THRESHOLD: int = 20  # 20 naruszeń → permanent ban
    COOLDOWN_RESET_SECONDS: float = 3600.0  # 1h bez naruszeń → reset
    MAX_ENTRIES: int = 10000  # Maksymalna liczba śledzonych IP

    def __init__(self) -> None:
        self._entries: dict[str, RateLimitEntry] = {}
        self._permanent_bans: set[str] = set()
        self._total_blocks: int = 0

    def record_violation(self, identifier: str) -> RateLimitEntry:
        """Zarejestruj naruszenie rate limitu.

        Returns:
            Zaktualizowany wpis z nowym czasem blokady.
        """
        now = _time.monotonic()

        entry = self._entries.get(identifier)
        if entry is None:
            entry = RateLimitEntry(
                identifier=identifier,
                first_violation=now,
            )
            self._entries[identifier] = entry
        else:
            # Sprawdź czy minął cooldown — jeśli tak, zresetuj
            if now - entry.first_violation > self.COOLDOWN_RESET_SECONDS:
                entry.violation_count = 0
                entry.first_violation = now
            entry.violation_count += 1

        # Oblicz nowy backoff
        for threshold, backoff in self.BACKOFF_TIERS:
            if entry.violation_count <= threshold:
                entry.current_backoff_seconds = backoff
                break
        else:
            if entry.violation_count >= self.PERMANENT_BAN_THRESHOLD:
                entry.permanently_banned = True
                self._permanent_bans.add(identifier)
                entry.current_backoff_seconds = float("inf")
            else:
                entry.current_backoff_seconds = self.BACKOFF_TIERS[-1][1]

        entry.blocked_until = now + entry.current_backoff_seconds
        self._total_blocks += 1

        # Trim do maksymalnego rozmiaru
        if len(self._entries) > self.MAX_ENTRIES:
            oldest = sorted(self._entries.keys(), key=lambda k: self._entries[k].first_violation)
            for key in oldest[: len(oldest) // 10]:
                del self._entries[key]

        logger.warning(
            "[RATE-LIMIT] Violation %d for %s — blocked for %.0fs (tier %s)",
            entry.violation_count,
            identifier,
            entry.current_backoff_seconds,
            "PERMANENT" if entry.permanently_banned else "temporary",
        )

        return entry

    def is_blocked(self, identifier: str) -> bool:
        """Czy identyfikator jest obecnie zablokowany?"""
        # Permanent ban
        if identifier in self._permanent_bans:
            return True

        entry = self._entries.get(identifier)
        if entry is None:
            return False

        if entry.permanently_banned:
            return True

        now = _time.monotonic()
        if now < entry.blocked_until:
            return True

        # Blokada wygasła — usuń wpis
        del self._entries[identifier]
        return False

    def get_block_time_remaining(self, identifier: str) -> float:
        """Pozostały czas blokady w sekundach (0 = nie zablokowany)."""
        if identifier in self._permanent_bans:
            return float("inf")

        entry = self._entries.get(identifier)
        if entry is None:
            return 0.0

        remaining = entry.blocked_until - _time.monotonic()
        return max(0.0, remaining)

    def unblock(self, identifier: str) -> None:
        """Ręcznie odblokuj identyfikator."""
        self._entries.pop(identifier, None)
        self._permanent_bans.discard(identifier)
        logger.info("[RATE-LIMIT] Manually unblocked %s", identifier)

    @property
    def permanent_bans(self) -> set[str]:
        """Zbiór permanentnie zablokowanych identyfikatorów."""
        return set(self._permanent_bans)

    @property
    def stats(self) -> dict[str, Any]:
        """Statystyki rate limitera."""
        blocked_now = sum(1 for e in self._entries.values() if _time.monotonic() < e.blocked_until)
        return {
            "total_entries": len(self._entries),
            "blocked_now": blocked_now,
            "permanent_bans": len(self._permanent_bans),
            "total_blocks": self._total_blocks,
        }
