"""Agent Emotion Detection — Detekcja emocji użytkownika.

GENIALNY POMYSŁ #10 z Raportu v7.0:
AgentAnalytics monitoruje TON komunikacji z użytkownikiem:
- Jeśli użytkownik często poprawia decyzje → frustracja
- Jeśli użytkownik szybko akceptuje → zaufanie
- Jeśli użytkownik ignoruje → brak zaangażowania
System dostosowuje poziom autonomii: sfrustrowany użytkownik dostaje WIĘCEJ auto-postów.
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.agents.emotion")


class EmotionProfile:
    """Profil emocjonalny użytkownika."""

    EMOTIONS = ["trusting", "neutral", "frustrated", "disengaged"]

    def __init__(self, user_id: str = "default") -> None:
        self.user_id = user_id
        self._correction_timestamps: list[datetime] = []
        self._accept_timestamps: list[datetime] = []
        self._ignore_timestamps: list[datetime] = []
        self._interaction_timestamps: list[datetime] = []
        self.current_emotion: str = "neutral"
        self.emotion_score: float = 0.5  # 0=frustrated, 1=trusting
        self.autonomy_adjustment: float = 0.0

    @property
    def correction_rate(self) -> float:
        total = len(self._correction_timestamps) + len(self._accept_timestamps)
        if total == 0:
            return 0.0
        return len(self._correction_timestamps) / total

    @property
    def accept_rate(self) -> float:
        total = len(self._correction_timestamps) + len(self._accept_timestamps)
        if total == 0:
            return 0.0
        return len(self._accept_timestamps) / total

    @property
    def avg_response_time_seconds(self) -> float:
        if len(self._interaction_timestamps) < 2:
            return 0.0
        sorted_ts = sorted(self._interaction_timestamps)
        intervals = [
            (sorted_ts[i + 1] - sorted_ts[i]).total_seconds()
            for i in range(len(sorted_ts) - 1)
        ]
        return sum(intervals) / len(intervals) if intervals else 0.0


class EmotionDetector:
    """Detektor emocji użytkownika.

    GENIALNY POMYSŁ #10:
    Monitoruje wzorce interakcji i dostosowuje poziom autonomii agenta.
    """

    # ── Konfiguracja ────────────────────────────────────────────────
    FRUSTRATION_CORRECTION_THRESHOLD = 3  # 3 korekty w krótkim czasie → frustracja
    FRUSTRATION_WINDOW_MINUTES = 30
    DISENGAGEMENT_DAYS = 7               # 7 dni bez interakcji → brak zaangażowania
    HIGH_TRUST_ACCEPT_THRESHOLD = 0.85    # >85% akceptacji → wysokie zaufanie

    def __init__(self) -> None:
        self._profiles: dict[str, EmotionProfile] = {}
        self._detection_stats: dict[str, int] = {
            "trusting": 0, "neutral": 0, "frustrated": 0, "disengaged": 0,
        }

    # ── Core Logic ──────────────────────────────────────────────────

    def get_profile(self, user_id: str = "default") -> EmotionProfile:
        if user_id not in self._profiles:
            self._profiles[user_id] = EmotionProfile(user_id=user_id)
        return self._profiles[user_id]

    def record_correction(
        self,
        user_id: str = "default",
        decision_id: str = "",
        original_status: str = "",
        corrected_status: str = "",
    ) -> None:
        """Zarejestruj korektę użytkownika."""
        profile = self.get_profile(user_id)
        now = datetime.utcnow()
        profile._correction_timestamps.append(now)
        profile._interaction_timestamps.append(now)

        # Ogranicz historię do 90 dni
        cutoff = now - timedelta(days=90)
        profile._correction_timestamps = [
            t for t in profile._correction_timestamps if t > cutoff
        ]
        profile._interaction_timestamps = [
            t for t in profile._interaction_timestamps if t > cutoff
        ]

        self._update_emotion(profile)

    def record_accept(
        self, user_id: str = "default", decision_id: str = ""
    ) -> None:
        """Zarejestruj akceptację decyzji."""
        profile = self.get_profile(user_id)
        now = datetime.utcnow()
        profile._accept_timestamps.append(now)
        profile._interaction_timestamps.append(now)
        self._update_emotion(profile)

    def record_ignore(
        self, user_id: str = "default", decision_id: str = ""
    ) -> None:
        """Zarejestruj ignorowanie decyzji (brak odpowiedzi)."""
        profile = self.get_profile(user_id)
        now = datetime.utcnow()
        profile._ignore_timestamps.append(now)
        self._update_emotion(profile)

    def _update_emotion(self, profile: EmotionProfile) -> None:
        """Zaktualizuj stan emocjonalny na podstawie wzorców."""
        now = datetime.utcnow()

        # Sprawdź frustrację — częste korekty w krótkim czasie
        recent_corrections = [
            t for t in profile._correction_timestamps
            if (now - t).total_seconds() < self.FRUSTRATION_WINDOW_MINUTES * 60
        ]
        if len(recent_corrections) >= self.FRUSTRATION_CORRECTION_THRESHOLD:
            old = profile.current_emotion
            profile.current_emotion = "frustrated"
            profile.emotion_score = 0.2
            profile.autonomy_adjustment = +0.10  # WIĘCEJ auto-postów
            if old != "frustrated":
                logger.info("[EMOTION] %s → frustrated | corrections=%d in %dmin",
                           profile.user_id, len(recent_corrections), self.FRUSTRATION_WINDOW_MINUTES)
            self._detection_stats["frustrated"] += 1
            return

        # Sprawdź wysokie zaufanie
        if profile.accept_rate >= self.HIGH_TRUST_ACCEPT_THRESHOLD and len(profile._accept_timestamps) >= 20:
            old = profile.current_emotion
            profile.current_emotion = "trusting"
            profile.emotion_score = 0.85
            profile.autonomy_adjustment = +0.05  # Więcej auto-postów
            if old != "trusting":
                logger.info("[EMOTION] %s → trusting | accept_rate=%.0f%%",
                           profile.user_id, profile.accept_rate * 100)
            self._detection_stats["trusting"] += 1
            return

        # Sprawdź brak zaangażowania
        if profile._interaction_timestamps:
            last_interaction = max(profile._interaction_timestamps)
            days_since_last = (now - last_interaction).days
            if days_since_last >= self.DISENGAGEMENT_DAYS:
                old = profile.current_emotion
                profile.current_emotion = "disengaged"
                profile.emotion_score = 0.3
                profile.autonomy_adjustment = +0.15  # DUŻO więcej auto-postów
                if old != "disengaged":
                    logger.info("[EMOTION] %s → disengaged | days=%d", profile.user_id, days_since_last)
                self._detection_stats["disengaged"] += 1
                return

        # Neutral
        profile.current_emotion = "neutral"
        profile.emotion_score = 0.5
        profile.autonomy_adjustment = 0.0
        self._detection_stats["neutral"] += 1

    def get_autonomy_adjustment(self, user_id: str = "default") -> float:
        """Pobierz korektę autonomii na podstawie emocji."""
        profile = self.get_profile(user_id)
        return profile.autonomy_adjustment

    def get_emotion_summary(self, user_id: str = "default") -> dict[str, Any]:
        """Pobierz podsumowanie emocjonalne."""
        profile = self.get_profile(user_id)
        return {
            "user_id": profile.user_id,
            "current_emotion": profile.current_emotion,
            "emotion_score": round(profile.emotion_score, 2),
            "autonomy_adjustment": round(profile.autonomy_adjustment, 2),
            "correction_rate": round(profile.correction_rate, 2),
            "accept_rate": round(profile.accept_rate, 2),
            "total_corrections": len(profile._correction_timestamps),
            "total_accepts": len(profile._accept_timestamps),
            "avg_response_time_s": round(profile.avg_response_time_seconds, 1),
            "days_since_last_interaction": (
                (datetime.utcnow() - max(profile._interaction_timestamps)).days
                if profile._interaction_timestamps else 0
            ),
        }

    # ── Stats ───────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        return {
            "profiles_tracked": len(self._profiles),
            "emotion_distribution": dict(self._detection_stats),
            "dominant_emotion": max(self._detection_stats, key=self._detection_stats.get, default="neutral"),
            "profiles": {
                uid: self.get_emotion_summary(uid)
                for uid in list(self._profiles.keys())[:10]
            },
        }
