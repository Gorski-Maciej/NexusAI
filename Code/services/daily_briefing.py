"""
Daily Briefing Service — generator codziennych podsumowań finansowych.

Odpowiedzialności:
  1. Generowanie podsumowania dnia (auto_post, blocked, pending, alerts, trust trend)
  2. Wysyłka przez NotificationService (zapisywanie do SQLite)
  3. Integracja z PLE (statystyki STM/LTM/FM)
  4. Integracja z DecisionLogger (trend trust score, statystyki korekt)

Współpracuje z:
  - DailyBriefingGenerator (w notification_service.py) — agregacja danych
  - NotificationService — wysyłka powiadomień
  - PLEEngine — statystyki pamięci
  - DecisionLogger — trend trust score
"""

from __future__ import annotations

import asyncio
import json
import logging
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone, date
from typing import Any

from core.config import AppConfig

logger = logging.getLogger("nexus.services.daily_briefing")


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class DailyBriefing:
    """Struktura codziennego podsumowania finansowego."""

    user_id: str
    date: str  # ISO date
    total_processed: int = 0
    auto_posted: dict[str, Any] = field(default_factory=lambda: {"count": 0, "total_amount": 0.0})
    pending_review: int = 0
    blocked: dict[str, Any] = field(default_factory=lambda: {"count": 0, "total_amount": 0.0})
    total_amount_auto: float = 0.0
    top_contractors: list[dict[str, Any]] = field(default_factory=list)
    alerts: list[dict[str, Any]] = field(default_factory=list)
    trust_trend: str = "stable"
    ple_stats: dict[str, Any] = field(default_factory=dict)
    correction_rate: float = 0.0
    decisions: list[dict[str, Any]] = field(default_factory=list)
    generated_at: str = ""

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), ensure_ascii=False, default=str)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "DailyBriefing":
        return cls(**data)


# ---------------------------------------------------------------------------
# DailyBriefingService
# ---------------------------------------------------------------------------

class DailyBriefingService:
    """
    Serwis do generowania i wysyłki codziennych podsumowań finansowych.

    Używa DailyBriefingGenerator do agregacji danych oraz NotificationService
    do zapisywania i dystrybucji powiadomień.

    Obsługuje 3 kanały wysyłki:
      - in_app: powiadomienie w aplikacji (SQLite)
      - push:   (placeholder — przyszła implementacja)
      - email:  (placeholder — przyszła implementacja)
    """

    def __init__(
        self,
        config: AppConfig | None = None,
        notification_service: Any = None,
        ple_engine: Any = None,
        decision_logger: Any = None,
        duckdb_manager: Any = None,
    ) -> None:
        self._config = config or AppConfig()
        self._notification = notification_service
        self._ple = ple_engine
        self._logger = decision_logger
        self._duckdb = duckdb_manager
        self._generator: Any = None

        # Lazy init DailyBriefingGenerator
        if self._duckdb or self._ple or self._logger:
            self._ensure_generator()

    def _ensure_generator(self) -> None:
        """Lazy-init DailyBriefingGenerator."""
        if self._generator is not None:
            return
        from services.notification_service import DailyBriefingGenerator

        self._generator = DailyBriefingGenerator(
            config=self._config,
            duckdb_manager=self._duckdb,
            ple_engine=self._ple,
            decision_logger=self._logger,
        )
        # Podłącz generator do NotificationService
        if self._notification and hasattr(self._notification, "set_briefing_generator"):
            self._notification.set_briefing_generator(self._generator)

    async def generate_and_send(
        self,
        user_id: str,
        channels: list[str] | None = None,
    ) -> dict[str, Any]:
        """
        Główna metoda: generuje briefing i wysyła przez wskazane kanały.

        Args:
            user_id: ID użytkownika
            channels: lista kanałów (domyślnie ["in_app"])

        Returns:
            dict z briefingiem i statusem wysyłki
        """
        channels = channels or ["in_app"]

        # 1. Generuj briefing
        briefing = await self.generate(user_id)

        # 2. Wyślij przez każdy kanał
        send_results: dict[str, Any] = {}
        for channel in channels:
            try:
                result = await self._send_to_channel(channel, briefing)
                send_results[channel] = result
            except Exception as exc:
                logger.error("[DailyBriefing] channel=%s failed: %s", channel, exc)
                send_results[channel] = {"status": "error", "error": str(exc)}

        all_success = all(
            r.get("status") == "sent" for r in send_results.values()
        )

        return {
            "briefing": briefing.to_dict(),
            "channels_used": channels,
            "send_results": send_results,
            "status": "sent" if all_success else "partial",
        }

    async def generate(self, user_id: str) -> DailyBriefing:
        """
        Generuj DailyBriefing z wszystkich dostępnych źródeł danych.

        Wykorzystuje DailyBriefingGenerator (jeśli dostępny) lub
        generuje podstawowe podsumowanie z samego NotificationService.
        """
        now = datetime.now(timezone.utc)
        today = date.today().isoformat()

        # Użyj DailyBriefingGenerator jeśli dostępny
        if self._generator:
            try:
                raw = await self._generator.generate(user_id)
                briefing = DailyBriefing(
                    user_id=raw.get("user_id", user_id),
                    date=raw.get("date", today),
                    total_processed=raw.get("total_processed", 0),
                    auto_posted=raw.get("auto_posted", {"count": 0, "total_amount": 0.0}),
                    pending_review=raw.get("pending_review", 0),
                    blocked=raw.get("blocked", {"count": 0, "total_amount": 0.0}),
                    total_amount_auto=raw.get("total_amount_auto", 0.0),
                    top_contractors=raw.get("top_contractors", []),
                    alerts=raw.get("alerts", []),
                    trust_trend=raw.get("trust_trend", "stable"),
                    ple_stats=raw.get("ple_stats", {}),
                    generated_at=now.isoformat(),
                )
            except Exception as exc:
                logger.warning("[DailyBriefing] generator failed, using fallback: %s", exc)
                briefing = self._fallback_briefing(user_id, today, now)
        else:
            briefing = self._fallback_briefing(user_id, today, now)

        # Wzbogać o pending decisions z NotificationService
        if self._notification:
            try:
                decisions = await asyncio.to_thread(
                    self._notification._fetch_pending_decisions, user_id
                )
                briefing.decisions = decisions
                briefing.pending_review = len(decisions)
            except Exception:
                pass

        # Wzbogać o correction rate z DecisionLogger
        if self._logger:
            try:
                stats = await asyncio.to_thread(
                    self._logger.get_user_correction_stats
                )
                briefing.correction_rate = stats.get("correction_rate", 0.0)
            except Exception:
                pass

        # Wzbogać o statystyki PLE
        if self._ple:
            try:
                ple_data = await self._ple.get_briefing_data()
                briefing.ple_stats = ple_data
            except Exception:
                pass

        # Generuj alerty jeśli brak
        if not briefing.alerts:
            briefing.alerts = self._generate_alerts(briefing)

        return briefing

    async def send_existing(
        self,
        user_id: str,
        briefing: DailyBriefing | dict[str, Any],
        channels: list[str] | None = None,
    ) -> dict[str, Any]:
        """
        Wyślij istniejący briefing (już wygenerowany) przez wskazane kanały.
        """
        channels = channels or ["in_app"]

        if isinstance(briefing, dict):
            briefing = DailyBriefing.from_dict(briefing)

        send_results: dict[str, Any] = {}
        for channel in channels:
            try:
                result = await self._send_to_channel(channel, briefing)
                send_results[channel] = result
            except Exception as exc:
                logger.error("[DailyBriefing] resend channel=%s failed: %s", channel, exc)
                send_results[channel] = {"status": "error", "error": str(exc)}

        return {
            "briefing": briefing.to_dict(),
            "channels_used": channels,
            "send_results": send_results,
        }

    async def _send_to_channel(
        self,
        channel: str,
        briefing: DailyBriefing,
    ) -> dict[str, Any]:
        """
        Wyślij briefing przez pojedynczy kanał.
        """
        if channel == "in_app":
            return await self._send_in_app(briefing)
        elif channel == "push":
            return await self._send_push(briefing)
        elif channel == "email":
            return await self._send_email(briefing)
        else:
            logger.warning("[DailyBriefing] unknown channel=%s", channel)
            return {"status": "error", "error": f"Unknown channel: {channel}"}

    async def _send_in_app(self, briefing: DailyBriefing) -> dict[str, Any]:
        """
        Zapisz briefing jako powiadomienie in-app przez NotificationService.
        """
        if not self._notification:
            return {"status": "error", "error": "NotificationService not available"}

        pending_count = briefing.pending_review
        blocked_count = briefing.blocked.get("count", 0)
        auto_count = briefing.auto_posted.get("count", 0)

        # Zbuduj tytuł z podsumowaniem
        if pending_count > 0:
            title = f"📋 Codzienne podsumowanie — {pending_count} decyzji"
        elif blocked_count > 0:
            title = f"⚠️ Codzienne podsumowanie — {blocked_count} zablokowanych"
        else:
            title = f"✅ Codzienne podsumowanie — {auto_count} zaksięgowanych"

        message = json.dumps(briefing.to_dict(), ensure_ascii=False, default=str)

        try:
            notification_id = await asyncio.to_thread(
                self._notification._add_notification,
                user_id=briefing.user_id,
                title=title,
                message=message,
                notification_type="daily_briefing",
                reference_type="daily_briefing",
                reference_id=briefing.date,
            )
            logger.info(
                "[DailyBriefing] in-app sent user=%s date=%s notification_id=%s",
                briefing.user_id, briefing.date, notification_id,
            )
            return {"status": "sent", "notification_id": notification_id}
        except Exception as exc:
            logger.error("[DailyBriefing] in-app failed: %s", exc)
            return {"status": "error", "error": str(exc)}

    async def _send_push(self, briefing: DailyBriefing) -> dict[str, Any]:
        """
        Wyślij push notification (placeholder — wymaga integracji z FCM/APNs).
        """
        logger.info(
            "[DailyBriefing] push placeholder user=%s date=%s",
            briefing.user_id, briefing.date,
        )
        # TODO: Integracja z Firebase Cloud Messaging lub Apple Push Notification Service
        return {
            "status": "not_implemented",
            "message": "Push notifications not yet configured",
        }

    async def _send_email(self, briefing: DailyBriefing) -> dict[str, Any]:
        """
        Wyślij email z podsumowaniem (placeholder — wymaga konfiguracji SMTP).
        """
        logger.info(
            "[DailyBriefing] email placeholder user=%s date=%s",
            briefing.user_id, briefing.date,
        )
        # TODO: Integracja z SMTP / SendGrid / SES
        return {
            "status": "not_implemented",
            "message": "Email notifications not yet configured",
        }

    def _fallback_briefing(
        self,
        user_id: str,
        today: str,
        now: datetime,
    ) -> DailyBriefing:
        """Generuj podstawowe podsumowanie gdy DailyBriefingGenerator nie jest dostępny."""
        pending = 0
        if self._notification:
            try:
                pending = self._notification.get_unread_count(user_id)
            except Exception:
                pass

        alerts = []
        if pending > 5:
            alerts.append({
                "type": "backlog",
                "severity": "medium",
                "message": f"{pending} powiadomień oczekuje na przeczytanie",
            })

        return DailyBriefing(
            user_id=user_id,
            date=today,
            pending_review=pending,
            alerts=alerts,
            generated_at=now.isoformat(),
        )

    @staticmethod
    def _generate_alerts(briefing: DailyBriefing) -> list[dict[str, Any]]:
        """Generuj alerty na podstawie danych briefingowych."""
        alerts: list[dict[str, Any]] = []

        if briefing.blocked.get("count", 0) > 0:
            alerts.append({
                "type": "blocked_invoices",
                "severity": "high",
                "message": (
                    f"{briefing.blocked['count']} faktur zostało zablokowanych "
                    f"(kwota: {briefing.blocked.get('total_amount', 0):.2f} PLN)"
                ),
            })

        if briefing.pending_review > 5:
            alerts.append({
                "type": "backlog",
                "severity": "medium",
                "message": f"{briefing.pending_review} faktur oczekuje na Twoją decyzję",
            })

        if briefing.correction_rate > 0.2:
            alerts.append({
                "type": "high_correction_rate",
                "severity": "medium",
                "message": (
                    f"Wysoki wskaźnik korekt ({briefing.correction_rate:.1%}) — "
                    f"rozważ dostrojenie progów decyzyjnych"
                ),
            })

        if briefing.auto_posted.get("count", 0) == 0 and briefing.pending_review == 0:
            alerts.append({
                "type": "no_activity",
                "severity": "info",
                "message": "Brak aktywności — żadne faktury nie zostały dzisiaj przetworzone",
            })

        return alerts

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki serwisu."""
        return {
            "generator_available": self._generator is not None,
            "notification_available": self._notification is not None,
            "ple_available": self._ple is not None,
            "logger_available": self._logger is not None,
            "duckdb_available": self._duckdb is not None,
        }
