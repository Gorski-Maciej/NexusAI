"""
RASP (Runtime Application Self-Protection) — INNOWACJA #9 v7.0 Security Audit.

Raport v7.0 INNOWACJA #9:
  Monitorowac aplikacje w runtime pod katem:
  - nieautoryzowanych zapytan SQL
  - nadmiernego zuzycia CPU/RAM
  - podejrzanych wzorcow dostepu
  Zatrzymywac ataki zanim osiagna cel.

Enterprise v7.0:
  - SQL injection detection: podejrzane wzorce w zapytaniach
  - Resource monitoring: CPU/RAM thresholds
  - Access pattern analysis: nietypowe godziny, czestotliwosc
  - Auto-block: IP blokada po przekroczeniu progow
  - Alert escalation: log → warning → block → notify admin
"""

from __future__ import annotations

import re
import time as _time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.rasp")


class RASPAlertLevel:
    """Poziomy eskalacji alertow RASP."""

    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"
    BLOCK = "block"


@dataclass
class RASPEvent:
    """Zdarzenie RASP."""

    event_type: str  # sql_injection, resource_spike, suspicious_access
    level: str
    detail: str
    source_ip: str = ""
    user_id: str = ""
    timestamp: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    auto_blocked: bool = False


class RASPMonitor:
    """Monitor RASP — Runtime Application Self-Protection.

    Usage:
        rasp = RASPMonitor()
        
        # Monitoruj zapytanie SQL
        rasp.check_sql_query("SELECT * FROM users WHERE id = 1 OR 1=1")
        
        # Monitoruj zuzycie zasobow
        rasp.check_resource_usage(cpu_percent=85, ram_mb=3500)
        
        # Monitoruj wzorce dostepu
        rasp.check_access_pattern(ip="192.168.1.1", user_id="admin", hour=3)
    """

    # ── SQL Injection Patterns ──────────────────────────────────────────

    SQL_INJECTION_PATTERNS: list[re.Pattern] = [
        re.compile(r"(?:'|\")\s*(?:OR|AND)\s*(?:'|\")\s*\d+\s*=\s*\d+", re.IGNORECASE),
        re.compile(r"UNION\s+SELECT", re.IGNORECASE),
        re.compile(r"DROP\s+TABLE", re.IGNORECASE),
        re.compile(r"INSERT\s+INTO.*VALUES\s*\(.*SELECT", re.IGNORECASE),
        re.compile(r"--\s*$", re.MULTILINE),
        re.compile(r"/\*.*\*/", re.DOTALL),
        re.compile(r"EXEC\s*(?:sp_|xp_)", re.IGNORECASE),
        re.compile(r"1\s*=\s*1", re.IGNORECASE),
        re.compile(r"';?\s*--", re.IGNORECASE),
    ]

    # ── Resource Thresholds ──────────────────────────────────────────────

    CPU_CRITICAL_THRESHOLD: float = 90.0  # % — krytyczne
    CPU_WARNING_THRESHOLD: float = 75.0   # % — ostrzezenie
    RAM_CRITICAL_MB: int = 5500           # MB — krytyczne (>90% z 6GB)
    RAM_WARNING_MB: int = 4500            # MB — ostrzezenie

    # ── Access Pattern Thresholds ────────────────────────────────────

    SUSPICIOUS_HOURS: tuple[int, ...] = (0, 1, 2, 3, 4)  # 00:00-04:59
    MAX_REQUESTS_PER_MINUTE: int = 100
    MAX_FAILED_LOGINS: int = 5

    def __init__(self, auto_block: bool = True) -> None:
        self._auto_block = auto_block
        self._events: list[RASPEvent] = []
        self._blocked_ips: set[str] = set()
        self._access_counts: dict[str, list[float]] = {}  # ip → timestamps
        self._failed_logins: dict[str, int] = {}  # ip → count
        self._block_count: int = 0

    # ── SQL Injection Detection ────────────────────────────────────────

    def check_sql_query(self, query: str, *, source_ip: str = "", user_id: str = "") -> list[RASPEvent]:
        """Sprawdz zapytanie SQL pod katem SQL injection.

        Returns:
            Lista zdarzen RASP (pusta = czyste zapytanie).
        """
        events: list[RASPEvent] = []

        for i, pattern in enumerate(self.SQL_INJECTION_PATTERNS):
            if pattern.search(query):
                event = RASPEvent(
                    event_type="sql_injection",
                    level=RASPAlertLevel.CRITICAL,
                    detail=f"SQL injection pattern #{i+1} detected: {pattern.pattern[:80]}",
                    source_ip=source_ip,
                    user_id=user_id,
                    auto_blocked=self._auto_block,
                )
                events.append(event)
                self._events.append(event)

                if self._auto_block and source_ip:
                    self._blocked_ips.add(source_ip)
                    self._block_count += 1
                    logger.error(
                        "[RASP] BLOCKED SQL injection from %s: %s",
                        source_ip, pattern.pattern[:60],
                    )

        return events

    # ── Resource Monitoring ─────────────────────────────────────────────

    def check_resource_usage(
        self,
        cpu_percent: float = 0.0,
        ram_mb: float = 0.0,
    ) -> list[RASPEvent]:
        """Monitoruj zuzycie CPU i RAM.

        Returns:
            Lista zdarzen RASP dla przekroczonych progow.
        """
        events: list[RASPEvent] = []

        if cpu_percent > self.CPU_CRITICAL_THRESHOLD:
            events.append(RASPEvent(
                event_type="resource_spike",
                level=RASPAlertLevel.CRITICAL,
                detail=f"CPU usage {cpu_percent:.1f}% exceeds critical threshold {self.CPU_CRITICAL_THRESHOLD}%",
            ))
        elif cpu_percent > self.CPU_WARNING_THRESHOLD:
            events.append(RASPEvent(
                event_type="resource_spike",
                level=RASPAlertLevel.WARNING,
                detail=f"CPU usage {cpu_percent:.1f}% exceeds warning threshold {self.CPU_WARNING_THRESHOLD}%",
            ))

        if ram_mb > self.RAM_CRITICAL_MB:
            events.append(RASPEvent(
                event_type="resource_spike",
                level=RASPAlertLevel.CRITICAL,
                detail=f"RAM usage {ram_mb:.0f} MB exceeds critical threshold {self.RAM_CRITICAL_MB} MB",
            ))
        elif ram_mb > self.RAM_WARNING_MB:
            events.append(RASPEvent(
                event_type="resource_spike",
                level=RASPAlertLevel.WARNING,
                detail=f"RAM usage {ram_mb:.0f} MB exceeds warning threshold {self.RAM_WARNING_MB} MB",
            ))

        self._events.extend(events)
        return events

    # ── Access Pattern Analysis ─────────────────────────────────────────

    def check_access_pattern(
        self,
        *,
        ip: str,
        user_id: str = "",
        hour: int | None = None,
        endpoint: str = "",
    ) -> list[RASPEvent]:
        """Analizuj wzorzec dostepu pod katem anomalii.

        Sprawdza:
        - Nietypowe godziny (00:00-04:59)
        - Zbyt duza czestotliwosc (>100 req/min)
        - Zbyt wiele nieudanych logowan (>5)
        """
        events: list[RASPEvent] = []

        # 1. Nietypowe godziny
        if hour is None:
            hour = datetime.now().hour
        if hour in self.SUSPICIOUS_HOURS:
            events.append(RASPEvent(
                event_type="suspicious_access",
                level=RASPAlertLevel.WARNING,
                detail=f"Access at suspicious hour: {hour:02d}:00",
                source_ip=ip,
                user_id=user_id,
            ))

        # 2. Czestotliwosc
        now = _time.monotonic()
        self._access_counts.setdefault(ip, []).append(now)
        # Usun wpisy starsze niz 60 sekund
        self._access_counts[ip] = [
            t for t in self._access_counts[ip]
            if now - t <= 60.0
        ]

        if len(self._access_counts[ip]) > self.MAX_REQUESTS_PER_MINUTE:
            event = RASPEvent(
                event_type="suspicious_access",
                level=RASPAlertLevel.CRITICAL,
                detail=f"Rate limit exceeded: {len(self._access_counts[ip])} req/min from {ip}",
                source_ip=ip,
                user_id=user_id,
                auto_blocked=self._auto_block,
            )
            events.append(event)

            if self._auto_block:
                self._blocked_ips.add(ip)
                self._block_count += 1

        self._events.extend(events)
        return events

    # ── Failed Login Tracking ───────────────────────────────────────────

    def track_failed_login(self, ip: str) -> RASPEvent | None:
        """Sledz nieudane proby logowania."""
        self._failed_logins[ip] = self._failed_logins.get(ip, 0) + 1

        if self._failed_logins[ip] >= self.MAX_FAILED_LOGINS:
            event = RASPEvent(
                event_type="brute_force",
                level=RASPAlertLevel.CRITICAL,
                detail=f"Brute force detected: {self._failed_logins[ip]} failed logins from {ip}",
                source_ip=ip,
                auto_blocked=self._auto_block,
            )
            self._events.append(event)

            if self._auto_block:
                self._blocked_ips.add(ip)
                self._block_count += 1

            return event
        return None

    def reset_failed_logins(self, ip: str) -> None:
        """Resetuj licznik po udanym logowaniu."""
        self._failed_logins.pop(ip, None)

    # ── Block Management ────────────────────────────────────────────────

    @property
    def blocked_ips(self) -> set[str]:
        """Lista zablokowanych IP."""
        return set(self._blocked_ips)

    def is_blocked(self, ip: str) -> bool:
        """Czy IP jest zablokowane?"""
        return ip in self._blocked_ips

    def unblock(self, ip: str) -> None:
        """Odblokuj IP."""
        self._blocked_ips.discard(ip)

    # ── Statistics ──────────────────────────────────────────────────────

    @property
    def stats(self) -> dict[str, Any]:
        """Statystyki RASP."""
        return {
            "total_events": len(self._events),
            "blocked_ips_count": len(self._blocked_ips),
            "total_blocks": self._block_count,
            "events_by_type": self._events_by_type(),
            "auto_block_enabled": self._auto_block,
        }

    def _events_by_type(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for e in self._events:
            counts[e.event_type] = counts.get(e.event_type, 0) + 1
        return counts

    def get_recent_events(self, limit: int = 20) -> list[RASPEvent]:
        """Ostatnie zdarzenia RASP."""
        return self._events[-limit:]
