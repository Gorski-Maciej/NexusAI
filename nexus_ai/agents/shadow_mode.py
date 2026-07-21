"""Shadow Mode — Równoległe porównywanie zestawów agentów.

GENIALNY POMYSŁ #11 z Raportu v7.0:
Uruchom DWA zestawy agentów równolegle:
- Production: obecny zestaw (podejmuje rzeczywiste decyzje)
- Shadow: nowy model/konfiguracja (tylko porównuje wyniki)
Jeśli Shadow jest lepszy przez 30 dni → automatyczna migracja.
Zero-ryzyko testowania nowych modeli w produkcji.
"""

from __future__ import annotations

import hashlib
import pendulum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.agents.shadow")


class ShadowConfig:
    """Konfiguracja zestawu Shadow."""

    def __init__(
        self,
        name: str,
        model_overrides: dict[str, str] | None = None,
        prompt_overrides: dict[str, str] | None = None,
        threshold_overrides: dict[str, float] | None = None,
    ) -> None:
        self.name = name
        self.model_overrides = model_overrides or {}
        self.prompt_overrides = prompt_overrides or {}
        self.threshold_overrides = threshold_overrides or {}
        self.activated_at: str = ""


class ShadowResult:
    """Wynik porównania Production vs Shadow."""

    def __init__(self) -> None:
        self.decision_id: str = ""
        self.production_status: str = ""
        self.shadow_status: str = ""
        self.production_trust: float = 0.0
        self.shadow_trust: float = 0.0
        self.agreement: bool = False
        self.production_better: bool = False
        self.shadow_better: bool = False
        self.user_correction: str = ""  # Korekta użytkownika (ground truth)
        self.production_correct: bool = False
        self.shadow_correct: bool = False


class ShadowMode:
    """Shadow Mode — porównywanie zestawów agentów.

    GENIALNY POMYSŁ #11:
    Shadow działa w tle — NIGDY nie wpływa na rzeczywiste decyzje.
    Tylko porównuje wyniki. Jeśli Shadow jest lepszy przez 30 dni → auto-migracja.
    """

    # ── Konfiguracja ────────────────────────────────────────────────
    MIN_SHADOW_DAYS = 30            # Minimum dni przed migracją
    MIN_DECISIONS_FOR_MIGRATION = 500  # Minimum decyzji
    SHADOW_WIN_THRESHOLD = 0.03     # 3% lepszy by rozważyć migrację
    AUTO_MIGRATE = True             # Czy automatycznie migrować

    def __init__(
        self,
        production_config: dict[str, Any] | None = None,
    ) -> None:
        self._production_config = production_config or {}
        self._shadow_configs: dict[str, ShadowConfig] = {}
        self._active_shadow: ShadowConfig | None = None
        self._results: list[ShadowResult] = []
        self._daily_stats: dict[str, list[dict[str, float]]] = {}
        self._migration_history: list[dict[str, Any]] = []

    # ── Lifecycle ───────────────────────────────────────────────────

    def start_shadow(self, config: ShadowConfig) -> str:
        """Uruchom nowy Shadow zestaw agentów."""
        shadow_id = hashlib.md5(config.name.encode()).hexdigest()[:12]
        config.activated_at = pendulum.now("UTC").isoformat()
        self._shadow_configs[shadow_id] = config
        self._active_shadow = config
        logger.info("[SHADOW] 🕶️ Started shadow: %s | models=%s",
                    config.name, list(config.model_overrides.keys()))
        return shadow_id

    def stop_shadow(self, shadow_id: str) -> bool:
        """Zatrzymaj Shadow zestaw."""
        if shadow_id in self._shadow_configs:
            self._shadow_configs.pop(shadow_id)
            if self._active_shadow and self._active_shadow.name == self._shadow_configs.get(shadow_id, ShadowConfig("")).name:
                self._active_shadow = None
            logger.info("[SHADOW] Stopped: %s", shadow_id)
            return True
        return False

    # ── Decision Recording ──────────────────────────────────────────

    def record_comparison(
        self,
        decision_id: str,
        production_status: str,
        shadow_status: str,
        production_trust: float,
        shadow_trust: float,
    ) -> ShadowResult:
        """Zarejestruj wynik porównania Production vs Shadow."""
        result = ShadowResult()
        result.decision_id = decision_id
        result.production_status = production_status
        result.shadow_status = shadow_status
        result.production_trust = production_trust
        result.shadow_trust = shadow_trust
        result.agreement = production_status == shadow_status
        result.production_better = production_trust > shadow_trust
        result.shadow_better = shadow_trust > production_trust

        self._results.append(result)

        # Ogranicz historię
        if len(self._results) > 10000:
            self._results = self._results[-5000:]

        logger.debug(
            "[SHADOW] Compare | %s: Prod=%s(%.2f) Shadow=%s(%.2f) agree=%s",
            decision_id, production_status, production_trust,
            shadow_status, shadow_trust, result.agreement,
        )

        return result

    def record_user_correction(
        self, decision_id: str, user_correction: str
    ) -> None:
        """Zarejestruj korektę użytkownika (ground truth)."""
        for result in self._results:
            if result.decision_id == decision_id:
                result.user_correction = user_correction
                result.production_correct = result.production_status == user_correction
                result.shadow_correct = result.shadow_status == user_correction
                break

    # ── Analysis ────────────────────────────────────────────────────

    def get_comparison_stats(self, days: int = 30) -> dict[str, Any]:
        """Pobierz statystyki porównania za ostatnie N dni."""
        if not self._results:
            return {"status": "no_data"}

        recent = self._results[-min(len(self._results), days * 20):]  # ~20 decyzji/dzień

        prod_correct = sum(1 for r in recent if r.production_correct)
        shadow_correct = sum(1 for r in recent if r.shadow_correct)
        total_with_corrections = sum(1 for r in recent if r.user_correction)

        prod_accuracy = prod_correct / max(total_with_corrections, 1)
        shadow_accuracy = shadow_correct / max(total_with_corrections, 1)
        agreement_rate = sum(1 for r in recent if r.agreement) / max(len(recent), 1)

        avg_prod_trust = sum(r.production_trust for r in recent) / max(len(recent), 1)
        avg_shadow_trust = sum(r.shadow_trust for r in recent) / max(len(recent), 1)

        return {
            "total_comparisons": len(recent),
            "total_with_corrections": total_with_corrections,
            "agreement_rate_pct": round(agreement_rate * 100, 1),
            "production": {
                "accuracy": round(prod_accuracy, 4),
                "avg_trust": round(avg_prod_trust, 4),
            },
            "shadow": {
                "accuracy": round(shadow_accuracy, 4),
                "avg_trust": round(avg_shadow_trust, 4),
            },
            "shadow_wins": shadow_accuracy - prod_accuracy > self.SHADOW_WIN_THRESHOLD,
            "ready_for_migration": self.should_migrate(),
        }

    def should_migrate(self) -> bool:
        """Sprawdź czy Shadow jest gotowy do migracji."""
        if not self._active_shadow:
            return False

        total_with_corrections = sum(1 for r in self._results if r.user_correction)
        if total_with_corrections < self.MIN_DECISIONS_FOR_MIGRATION:
            return False

        # Sprawdź czy shadow działa wystarczająco długo
        if self._active_shadow.activated_at:
            start = pendulum.parse(self._active_shadow.activated_at)
            days_active = (pendulum.now("UTC") - start).days
            if days_active < self.MIN_SHADOW_DAYS:
                return False

        stats = self.get_comparison_stats()
        if stats["shadow_wins"]:
            logger.info("[SHADOW] 🏆 Shadow wins! Ready for migration.")
            return True

        return False

    def migrate_to_shadow(self) -> dict[str, Any]:
        """Migruj produkcję do Shadow zestawu."""
        if not self._active_shadow:
            return {"status": "error", "reason": "no_active_shadow"}

        migration = {
            "timestamp": pendulum.now("UTC").isoformat(),
            "shadow_config": {
                "name": self._active_shadow.name,
                "model_overrides": self._active_shadow.model_overrides,
                "prompt_overrides": self._active_shadow.prompt_overrides,
            },
            "stats": self.get_comparison_stats(),
        }
        self._migration_history.append(migration)

        # Podmień produkcję
        self._production_config.update(self._active_shadow.model_overrides)
        self._active_shadow = None

        logger.info("[SHADOW] ✅ Migrated to shadow config!")
        return migration

    # ── Stats ───────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        return {
            "active_shadow": self._active_shadow.name if self._active_shadow else None,
            "total_comparisons": len(self._results),
            "migrations": len(self._migration_history),
            "last_migration": self._migration_history[-1] if self._migration_history else None,
            **self.get_comparison_stats(),
        }
