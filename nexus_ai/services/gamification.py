"""
Gamified Tax Optimization — Elementy grywalizacji (Pomysł #19 v7.0).

Raport v7.0 Pomysł #19:
  - "Zaoszczędziłeś 12 450 PLN w tym roku!"
  - "Lepszy niż 78% firm w Twojej branży"
  - "Osiągnij poziom 'Mistrz Optymalizacji'"
  - Odznaki za: pierwszy AUTO_POST, 100 faktur, 0 błędów
  Motywacja + edukacja przez zabawę.

Enterprise v7.0:
  - Achievement system: 20+ odznak
  - Levels: 5 poziomów (Początkujący → Mistrz Optymalizacji)
  - Yearly savings tracker: ile zaoszczędziłeś dzięki AI
  - Leaderboard: anonimizowany ranking wg branży
  - Streaks: codzienna aktywność
  - Challenges: miesięczne wyzwania
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from enum import Enum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.gamification")


class PlayerLevel(Enum):
    """Poziomy gracza."""

    BEGINNER = (1, "Początkujący", 0, "🏅")
    APPRENTICE = (2, "Praktykant", 100, "🥉")
    SPECIALIST = (3, "Specjalista", 500, "🥈")
    EXPERT = (4, "Ekspert", 2000, "🥇")
    MASTER = (5, "Mistrz Optymalizacji", 5000, "👑")

    def __init__(self, level: int, name: str, xp_required: int, icon: str):
        self.level = level
        self.name = name
        self.xp_required = xp_required
        self.icon = icon


class AchievementType(Enum):
    """Typy osiągnięć."""

    MILESTONE = "milestone"  # Kamienie milowe
    SKILL = "skill"  # Umiejętności
    CHALLENGE = "challenge"  # Wyzwania
    STREAK = "streak"  # Serie
    SPECIAL = "special"  # Specjalne


@dataclass
class Achievement:
    """Odznaka / osiągnięcie."""

    id: str
    name: str
    description: str
    icon: str
    type: AchievementType
    xp_reward: int
    secret: bool = False


@dataclass
class PlayerStats:
    """Statystyki gracza."""

    xp: int = 0
    level: int = 1
    achievements: list[str] = field(default_factory=list)
    total_invoices: int = 0
    auto_post_count: int = 0
    zero_error_streak: int = 0
    yearly_savings: float = 0.0
    login_streak: int = 0
    last_login: str = ""
    challenges_completed: int = 0
    percentile: float = 50.0  # Percentyl w branży


# ── Definicje osiągnięć ─────────────────────────────────────────────────
ACHIEVEMENTS: list[Achievement] = [
    # Milestones
    Achievement("M001", "Pierwsza faktura", "Zaksięguj pierwszą fakturę", "📄", AchievementType.MILESTONE, 50),
    Achievement("M002", "Setka", "Zaksięguj 100 faktur", "💯", AchievementType.MILESTONE, 200),
    Achievement("M003", "Tysiąc", "Zaksięguj 1 000 faktur", "🏆", AchievementType.MILESTONE, 500),
    Achievement("M004", "10k faktur", "Zaksięguj 10 000 faktur", "🌟", AchievementType.MILESTONE, 1000),

    # Auto-post
    Achievement("A001", "Auto-pilot", "Pierwszy AUTO_POST (zaufanie >= 92%)", "🤖", AchievementType.SKILL, 100),
    Achievement("A002", "Zaufany pilot", "50 AUTO_POSTów", "✈️", AchievementType.SKILL, 300),
    Achievement("A003", "Na autopilocie", "100 AUTO_POSTów — 95%+ automatyzacji", "🚀", AchievementType.SKILL, 500),

    # Zero błędów
    Achievement("Z001", "Perfekcjonista", "7 dni bez błędów księgowych", "✨", AchievementType.STREAK, 150),
    Achievement("Z002", "Nienaganny", "30 dni bez błędów", "💎", AchievementType.STREAK, 500),
    Achievement("Z003", "Księgowy Roku", "90 dni bez ani jednego błędu", "👨‍💼", AchievementType.STREAK, 1000),

    # Oszczędności
    Achievement("O001", "Oszczędny", "Zaoszczędź 1 000 PLN dzięki AI", "💰", AchievementType.SKILL, 100),
    Achievement("O002", "Inwestor", "Zaoszczędź 10 000 PLN", "📈", AchievementType.SKILL, 300),
    Achievement("O003", "Finansowy Ninja", "Zaoszczędź 50 000 PLN", "🥷", AchievementType.SKILL, 1000),

    # Codzienna aktywność
    Achievement("S001", "Regularny", "Zaloguj się 7 dni z rzędu", "📅", AchievementType.STREAK, 50),
    Achievement("S002", "Oddany", "Zaloguj się 30 dni z rzędu", "🔥", AchievementType.STREAK, 200),
    Achievement("S003", "Nexus Life", "Zaloguj się 100 dni z rzędu", "❤️", AchievementType.STREAK, 500),

    # Wyzwania
    Achievement("W001", "Szybki Bill", "Zaksięguj fakturę w < 10 sekund", "⚡", AchievementType.CHALLENGE, 100),
    Achievement("W002", "Negocjator", "Wynegocjuj lepsze warunki płatności", "🤝", AchievementType.CHALLENGE, 150),
    Achievement("W003", "Audytor", "Przeprowadź miesięczny audyt", "🔍", AchievementType.CHALLENGE, 200),

    # Specjalne (ukryte)
    Achievement("X001", "Nocny marek", "Zaksięguj fakturę o 3:00 nad ranem", "🦉", AchievementType.SPECIAL, 50, secret=True),
    Achievement("X002", "Sylwester", "Zaksięguj fakturę 31 grudnia", "🎉", AchievementType.SPECIAL, 100, secret=True),
]


class GamificationEngine:
    """Silnik grywalizacji.

    Usage:
        engine = GamificationEngine()
        engine.record_action("invoice_booked", xp=10)
        engine.record_savings(500)
        stats = engine.get_stats()
        print(f"Level: {stats.level} — {get_level(stats.xp).name}")
    """

    XP_ACTIONS: dict[str, int] = {
        "invoice_booked": 10,
        "auto_post": 25,
        "error_corrected": 5,
        "audit_completed": 50,
        "negotiation_sent": 30,
        "report_generated": 15,
        "daily_login": 5,
    }

    def __init__(self, industry: str = "general") -> None:
        self._stats = PlayerStats()
        self._industry = industry
        self._unlocked_achievements: set[str] = set()
        self._action_history: list[dict[str, Any]] = []

    # ── Action Recording ─────────────────────────────────────────────────

    def record_action(self, action: str, **extra: Any) -> int:
        """Zarejestruj akcję i przyznaj XP."""
        xp = self.XP_ACTIONS.get(action, 5)
        self._stats.xp += xp

        if action == "invoice_booked":
            self._stats.total_invoices += 1
        elif action == "auto_post":
            self._stats.auto_post_count += 1
        elif action == "daily_login":
            self._update_login_streak()

        # Sprawdź odznaki
        new_achievements = self._check_achievements(extra)
        for ach in new_achievements:
            self._stats.xp += ach.xp_reward
            xp += ach.xp_reward

        # Aktualizuj poziom
        self._stats.level = self._calculate_level(self._stats.xp)

        self._action_history.append({
            "action": action,
            "xp": xp,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **extra,
        })

        return xp

    def record_savings(self, amount: float) -> None:
        """Zarejestruj oszczędności."""
        self._stats.yearly_savings += amount

    def record_error(self) -> None:
        """Zarejestruj błąd (resetuje streak)."""
        self._stats.zero_error_streak = 0

    def record_error_free_day(self) -> None:
        """Zarejestruj dzień bez błędów."""
        self._stats.zero_error_streak += 1

    # ── Achievements ─────────────────────────────────────────────────────

    def _check_achievements(self, extra: dict[str, Any] | None = None) -> list[Achievement]:
        if extra is None:
            extra = {}
        """Sprawdź nowe osiągnięcia."""
        new: list[Achievement] = []
        s = self._stats

        checks: dict[str, bool] = {
            "M001": s.total_invoices >= 1,
            "M002": s.total_invoices >= 100,
            "M003": s.total_invoices >= 1000,
            "M004": s.total_invoices >= 10000,
            "A001": s.auto_post_count >= 1,
            "A002": s.auto_post_count >= 50,
            "A003": s.auto_post_count >= 100,
            "Z001": s.zero_error_streak >= 7,
            "Z002": s.zero_error_streak >= 30,
            "Z003": s.zero_error_streak >= 90,
            "O001": s.yearly_savings >= 1000,
            "O002": s.yearly_savings >= 10000,
            "O003": s.yearly_savings >= 50000,
            "S001": s.login_streak >= 7,
            "S002": s.login_streak >= 30,
            "S003": s.login_streak >= 100,
            "W001": extra.get("fast_invoice", False),
            "W002": extra.get("negotiation_done", False),
            "W003": extra.get("audit_done", False),
            "X001": extra.get("night_owl", False),
            "X002": extra.get("new_years_eve", False),
        }

        for ach in ACHIEVEMENTS:
            if ach.id in self._unlocked_achievements:
                continue
            if checks.get(ach.id, False):
                new.append(ach)
                self._unlocked_achievements.add(ach.id)
                self._stats.achievements.append(ach.id)
                logger.info("[GAME] Achievement unlocked: %s — %s", ach.icon, ach.name)

        return new

    # ── Level Calculation ────────────────────────────────────────────────

    def _calculate_level(self, xp: int) -> int:
        """Oblicz poziom na podstawie XP."""
        for level in sorted(PlayerLevel, key=lambda l: l.xp_required, reverse=True):
            if xp >= level.xp_required:
                return level.level
        return 1

    @staticmethod
    def get_level_info(xp: int) -> PlayerLevel:
        """Pobierz informacje o poziomie."""
        for level in sorted(PlayerLevel, key=lambda l: l.xp_required, reverse=True):
            if xp >= level.xp_required:
                return level
        return PlayerLevel.BEGINNER

    # ── Login Streak ─────────────────────────────────────────────────────

    def _update_login_streak(self) -> None:
        """Aktualizuj passę logowania."""
        today = date.today().isoformat()
        last = self._stats.last_login

        if not last:
            self._stats.login_streak = 1
        else:
            try:
                last_date = date.fromisoformat(last[:10])
                if (date.today() - last_date).days == 1:
                    self._stats.login_streak += 1
                elif (date.today() - last_date).days > 1:
                    self._stats.login_streak = 1
            except ValueError:
                self._stats.login_streak = 1

        self._stats.last_login = today

    # ── Stats & Ranking ──────────────────────────────────────────────────

    def get_stats(self) -> PlayerStats:
        """Pobierz statystyki gracza."""
        return self._stats

    def get_progress_summary(self) -> str:
        """Wygeneruj podsumowanie postępu."""
        level = self.get_level_info(self._stats.xp)
        next_level = None
        for l in sorted(PlayerLevel, key=lambda l: l.xp_required):
            if l.xp_required > self._stats.xp:
                next_level = l
                break

        lines = [
            f"{level.icon} {level.name} (Poziom {level.level})",
            f"XP: {self._stats.xp}",
        ]

        if next_level:
            xp_needed = next_level.xp_required - self._stats.xp
            lines.append(f"Do {next_level.icon} {next_level.name}: jeszcze {xp_needed} XP")

        lines.extend([
            f"",
            f"📄 Faktury: {self._stats.total_invoices}",
            f"🤖 AUTO_POST: {self._stats.auto_post_count}",
            f"✨ Dni bez błędów: {self._stats.zero_error_streak}",
            f"💰 Oszczędności: {self._stats.yearly_savings:,.0f} PLN",
            f"🔥 Logowania z rzędu: {self._stats.login_streak}",
        ])

        if self._stats.percentile > 50:
            lines.append(f"📊 Lepszy niż {self._stats.percentile:.0f}% firm w branży!")

        return "\n".join(lines)

    def get_weekly_challenge(self) -> str:
        """Wygeneruj tygodniowe wyzwanie."""
        import random
        challenges = [
            "Zaksięguj 20 faktur w tym tygodniu (+150 XP)",
            "Utrzymaj 7 dni bez błędów (+200 XP)",
            "Przygotuj raport VAT przed terminem (+100 XP)",
            "Wynegocjuj warunki płatności z 1 kontrahentem (+150 XP)",
            "Użyj AUTO_POST dla 10 faktur (+250 XP)",
        ]
        return random.choice(challenges)

    def get_unlocked_achievements(self) -> list[Achievement]:
        """Pobierz odblokowane osiągnięcia."""
        return [a for a in ACHIEVEMENTS if a.id in self._unlocked_achievements]

    def get_locked_achievements(self) -> list[Achievement]:
        """Pobierz zablokowane osiągnięcia (bez sekretnych)."""
        return [
            a for a in ACHIEVEMENTS
            if a.id not in self._unlocked_achievements and not a.secret
        ]
