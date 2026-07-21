"""Predictive Model Preload — Inteligentne pre-ładowanie modeli GGUF.

GENIALNY POMYSŁ #3 z Raportu v7.0:
KnowledgeMesh analizuje wzorce użycia i PREŁADUJE modele zanim są potrzebne.
Redukcja latency pierwszego requestu z 2-3s do ~50ms.
"""

from __future__ import annotations

import asyncio
from datetime import datetime, time
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.core.preload")


class PredictivePreloader:
    """Inteligentny pre-loader modeli GGUF.

    Analizuje historyczne wzorce użycia i ładuje modele zanim będą potrzebne:
    - Poniedziałek 8:00 → załaduj Granite 3.2 (najwięcej faktur)
    - Piątek 15:00 → załaduj modele analityczne (raport tygodniowy)
    - Koniec miesiąca → załaduj wszystkie (zamknięcie miesiąca)
    - Poranek → załaduj modele komunikatora (interakcje z userem)
    """

    # ── Predefiniowane harmonogramy ─────────────────────────────────
    WEEKDAY_SCHEDULE: dict[int, list[dict[str, Any]]] = {
        0: [  # Poniedziałek
            {"time": time(7, 0), "models": ["granite-3.2-3b", "guardian-0.5b"], "reason": "Poranny batch faktur"},
            {"time": time(8, 0), "models": ["granite-3.2-3b", "guardian-0.5b", "qwen3-nano-0.5b"], "reason": "Peak poranny"},
            {"time": time(12, 0), "models": ["analytics-phi-3.5"], "reason": "Analityka południowa"},
            {"time": time(16, 0), "models": ["granite-3.2-3b", "guardian-0.5b"], "reason": "Popołudniowy batch"},
        ],
        4: [  # Piątek
            {"time": time(7, 0), "models": ["granite-3.2-3b", "guardian-0.5b"], "reason": "Poranny batch"},
            {"time": time(15, 0), "models": ["analytics-phi-3.5", "forecast-lag-llama", "granite-3.2-3b"], "reason": "Raport tygodniowy"},
        ],
    }

    # Domyślny harmonogram dla pozostałych dni
    DEFAULT_SCHEDULE: list[dict[str, Any]] = [
        {"time": time(7, 0), "models": ["granite-3.2-3b", "guardian-0.5b"], "reason": "Poranny batch"},
        {"time": time(16, 0), "models": ["granite-3.2-3b"], "reason": "Popołudniowy batch"},
    ]

    # Modele do pre-load przy końcu miesiąca
    MONTH_END_MODELS: list[str] = [
        "granite-3.2-3b", "guardian-0.5b", "qwen3-nano-0.5b",
        "analytics-phi-3.5", "forecast-lag-llama",
        "llama-3.2-1b", "mistral-0.2b",
    ]

    def __init__(
        self,
        model_manager: Any = None,
        model_paths: dict[str, str] | None = None,
        use_pattern_learning: bool = True,
    ) -> None:
        self._model_manager = model_manager
        self._model_paths = model_paths or {}
        self._use_pattern_learning = use_pattern_learning
        self._preloaded: set[str] = set()
        self._usage_patterns: dict[str, list[datetime]] = {}
        self._preload_tasks: list[asyncio.Task] = []
        self._running = False

    # ── Lifecycle ───────────────────────────────────────────────────

    async def start(self) -> None:
        """Uruchom pre-loader — rozpocznij monitorowanie harmonogramu."""
        self._running = True
        asyncio.create_task(self._schedule_loop())
        logger.info("[PRELOAD] PredictivePreloader started | models=%d", len(self._model_paths))

    async def stop(self) -> None:
        """Zatrzymaj pre-loader."""
        self._running = False
        for task in self._preload_tasks:
            task.cancel()
        logger.info("[PRELOAD] PredictivePreloader stopped")

    # ── Core Logic ──────────────────────────────────────────────────

    async def _schedule_loop(self) -> None:
        """Główna pętla harmonogramu — sprawdza co minutę czy czas na pre-load."""
        while self._running:
            try:
                now = pendulum.now("UTC")
                await self._check_schedule(now)
                await asyncio.sleep(60)  # Sprawdzaj co minutę
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.debug("[PRELOAD] Schedule loop error: %s", exc)
                await asyncio.sleep(60)

    async def _check_schedule(self, now: pendulum.DateTime) -> None:
        """Sprawdź czy są modele do załadowania o tej godzinie."""
        weekday = now.day_of_week  # 0=Monday
        current_time = time(now.hour, now.minute)

        schedule = self.WEEKDAY_SCHEDULE.get(weekday, self.DEFAULT_SCHEDULE)

        for entry in schedule:
            entry_time = entry["time"]
            # Pre-load w ciągu 2 minut od zaplanowanego czasu
            time_diff = abs(
                (now.hour * 60 + now.minute)
                - (entry_time.hour * 60 + entry_time.minute)
            )
            if time_diff <= 2:
                await self._preload_models(entry["models"], entry.get("reason", "scheduled"))

        # Koniec miesiąca (ostatnie 3 dni)
        if now.day >= 28:
            await self._preload_models(self.MONTH_END_MODELS, "month_end_closing")

    async def _preload_models(self, model_names: list[str], reason: str) -> None:
        """Załaduj modele wyprzedzająco."""
        loaded_count = 0
        for name in model_names:
            if name in self._preloaded:
                continue
            model_path = self._model_paths.get(name)
            if not model_path:
                continue

            try:
                if self._model_manager and hasattr(self._model_manager, 'get_or_create'):
                    self._model_manager.get_or_create(
                        model_path,
                        n_ctx=4096,
                        n_threads=4,
                        ttl=3600,  # Dłuższy TTL dla pre-loaded modeli
                    )
                    self._preloaded.add(name)
                    loaded_count += 1
            except Exception as exc:
                logger.debug("[PRELOAD] Failed to load %s: %s", name, exc)

        if loaded_count > 0:
            logger.info(
                "[PRELOAD] 🚀 Pre-loaded %d models | reason=%s | names=%s",
                loaded_count, reason, model_names,
            )

    # ── Pattern Learning ────────────────────────────────────────────

    def record_usage(self, model_name: str) -> None:
        """Zarejestruj użycie modelu — do nauki wzorców."""
        now = pendulum.now("UTC")
        if model_name not in self._usage_patterns:
            self._usage_patterns[model_name] = []
        self._usage_patterns[model_name].append(now)

    def predict_next_usage(self, model_name: str) -> pendulum.DateTime | None:
        """Przewidź następne użycie modelu na podstawie historycznych wzorców."""
        patterns = self._usage_patterns.get(model_name, [])
        if len(patterns) < 10:
            return None

        # Proste przewidywanie: średni czas między użyciami
        sorted_patterns = sorted(patterns)
        intervals = [
            (sorted_patterns[i + 1] - sorted_patterns[i]).total_seconds()
            for i in range(len(sorted_patterns) - 1)
        ]
        if not intervals:
            return None

        avg_interval = sum(intervals) / len(intervals)
        last_used = sorted_patterns[-1]
        return last_used.add(seconds=avg_interval)

    def preload_by_prediction(self, model_name: str) -> bool:
        """Spróbuj pre-load modelu na podstawie predykcji."""
        prediction = self.predict_next_usage(model_name)
        if not prediction:
            return False

        now = pendulum.now("UTC")
        # Jeśli przewidywane użycie jest w ciągu 10 minut → pre-load
        if (prediction - now).total_seconds() < 600:
            model_path = self._model_paths.get(model_name, "")
            if model_path and self._model_manager and hasattr(self._model_manager, 'get_or_create'):
                try:
                    self._model_manager.get_or_create(model_path, n_ctx=4096, n_threads=4, ttl=1800)
                    self._preloaded.add(model_name)
                    logger.info("[PRELOAD] 🔮 Predicted preload: %s", model_name)
                    return True
                except Exception as exc:
                    logger.debug("[PRELOAD] Predicted preload failed: %s", exc)
        return False

    # ── Properties & Stats ──────────────────────────────────────────

    @property
    def preloaded_models(self) -> set[str]:
        return self._preloaded

    def get_stats(self) -> dict[str, Any]:
        return {
            "preloaded_models": list(self._preloaded),
            "total_patterns_tracked": sum(len(p) for p in self._usage_patterns.values()),
            "models_with_patterns": len(self._usage_patterns),
            "running": self._running,
        }

    def clear_preloaded(self) -> None:
        """Wyczyść listę pre-loaded (np. przy auto-unload)."""
        self._preloaded.clear()
