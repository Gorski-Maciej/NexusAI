"""Agent Swarm Optimization — Dynamiczny Dobór Agentów.

GENIALNY POMYSŁ #1 z Raportu v7.0:
Zamiast sztywno 5 agentów, system dynamicznie dobiera liczbę i typ
agentów w zależności od złożoności faktury.
Redukcja zużycia RAM o 60% dla 80% faktur.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.agents.swarm")


class SwarmConfig:
    """Konfiguracja roju agentów dla danego poziomu złożoności."""

    def __init__(
        self,
        name: str,
        agents: list[str],
        ram_estimate_mb: float,
        time_estimate_ms: float,
        requires_4eyes: bool = False,
    ) -> None:
        self.name = name
        self.agents = agents
        self.ram_estimate_mb = ram_estimate_mb
        self.time_estimate_ms = time_estimate_ms
        self.requires_4eyes = requires_4eyes


# ── Predefiniowane konfiguracje roju ──────────────────────────────────
SWARM_CONFIGS: dict[str, SwarmConfig] = {
    "minimal": SwarmConfig(
        name="minimal",
        agents=["orchestrator"],
        ram_estimate_mb=2100,
        time_estimate_ms=2000,
    ),
    "light": SwarmConfig(
        name="light",
        agents=["orchestrator", "extraction"],
        ram_estimate_mb=2600,
        time_estimate_ms=3500,
    ),
    "standard": SwarmConfig(
        name="standard",
        agents=["orchestrator", "extraction", "quality-validator"],
        ram_estimate_mb=4700,
        time_estimate_ms=8000,
    ),
    "full": SwarmConfig(
        name="full",
        agents=[
            "orchestrator", "extraction", "quality-validator",
            "analytics", "fixed-assets",
        ],
        ram_estimate_mb=5900,
        time_estimate_ms=15000,
    ),
    "enterprise": SwarmConfig(
        name="enterprise",
        agents=[
            "orchestrator", "extraction", "quality-validator",
            "analytics", "fixed-assets",
        ],
        ram_estimate_mb=5900,
        time_estimate_ms=15000,
        requires_4eyes=True,
    ),
}


class SwarmOptimizer:
    """Optymalizator roju agentów — dynamiczny dobór liczby agentów.

    GENIALNY POMYSŁ #1:
    - Prosta faktura (1 pozycja, znany kontrahent) → 1 agent (Orchestrator)
    - Średnia (3-5 pozycji) → 3 agenty
    - Złożona (>10 pozycji, nowy kontrahent) → wszystkie 5 agentów + 4-Eyes
    """

    # ── Progi złożoności ────────────────────────────────────────────
    SIMPLE_MAX_POSITIONS = 2
    SIMPLE_MAX_AMOUNT = 2_000     # PLN
    MEDIUM_MAX_POSITIONS = 5
    MEDIUM_MAX_AMOUNT = 20_000    # PLN
    COMPLEX_MIN_POSITIONS = 10
    COMPLEX_MIN_AMOUNT = 50_000   # PLN

    def __init__(
        self,
        ram_budget_mb: float = 6000.0,
        configs: dict[str, SwarmConfig] | None = None,
    ) -> None:
        self._ram_budget_mb = ram_budget_mb
        self._configs = configs or dict(SWARM_CONFIGS)
        self._swarm_stats: dict[str, int] = {
            "minimal": 0, "light": 0, "standard": 0, "full": 0, "enterprise": 0,
        }
        self._ram_saved_mb: float = 0.0
        self._total_decisions: int = 0

    # ── Core Logic ──────────────────────────────────────────────────

    def determine_swarm(
        self,
        invoice_data: dict[str, Any],
        vendor_trust: float = 0.5,
        vendor_known: bool = False,
        current_ram_mb: float = 0.0,
    ) -> SwarmConfig:
        """Określ optymalny rój agentów dla faktury.

        Args:
            invoice_data: Dane faktury.
            vendor_trust: Trust Score kontrahenta.
            vendor_known: Czy kontrahent jest znany.
            current_ram_mb: Aktualne zużycie RAM.

        Returns:
            Optymalna konfiguracja roju.
        """
        positions = len(invoice_data.get("items", invoice_data.get("line_items", [])))
        amount = float(invoice_data.get("amount_gross", 0))
        available_ram = self._ram_budget_mb - current_ram_mb

        # ── Określ poziom złożoności ──
        if (
            positions <= self.SIMPLE_MAX_POSITIONS
            and amount <= self.SIMPLE_MAX_AMOUNT
            and vendor_known
            and vendor_trust >= 0.85
        ):
            config = self._select_with_ram("minimal", available_ram)
            if config:
                return self._record_swarm(config, "simple")
            return self._configs["minimal"]

        elif (
            positions <= self.MEDIUM_MAX_POSITIONS
            and amount <= self.MEDIUM_MAX_AMOUNT
        ):
            if vendor_known and vendor_trust >= 0.75:
                config = self._select_with_ram("light", available_ram)
                if config:
                    return self._record_swarm(config, "medium_known")
            config = self._select_with_ram("standard", available_ram)
            if config:
                return self._record_swarm(config, "medium")
            return self._configs["standard"]

        elif (
            positions >= self.COMPLEX_MIN_POSITIONS
            or amount >= self.COMPLEX_MIN_AMOUNT
        ):
            if not vendor_known or vendor_trust < 0.50:
                config = self._select_with_ram("enterprise", available_ram)
                if config:
                    return self._record_swarm(config, "complex_untrusted")
                return self._configs["enterprise"]
            config = self._select_with_ram("full", available_ram)
            if config:
                return self._record_swarm(config, "complex")
            return self._configs["full"]

        else:
            # Domyślnie standard
            config = self._select_with_ram("standard", available_ram)
            if config:
                return self._record_swarm(config, "default")
            return self._configs["standard"]

    def _select_with_ram(
        self, preferred: str, available_ram_mb: float
    ) -> SwarmConfig | None:
        """Wybierz konfigurację mieszcząca się w budżecie RAM."""
        config = self._configs.get(preferred)
        if config and config.ram_estimate_mb <= available_ram_mb:
            return config

        # Spróbuj lżejszej konfiguracji
        fallback_order = ["minimal", "light", "standard", "full", "enterprise"]
        try:
            idx = fallback_order.index(preferred)
            for fb in fallback_order[:idx][::-1]:  # od lżejszych
                fb_config = self._configs.get(fb)
                if fb_config and fb_config.ram_estimate_mb <= available_ram_mb:
                    return fb_config
        except ValueError:
            pass
        return None

    def _record_swarm(self, config: SwarmConfig, reason: str) -> SwarmConfig:
        """Zarejestruj wybór roju i oblicz oszczędności."""
        self._swarm_stats[config.name] = self._swarm_stats.get(config.name, 0) + 1
        self._total_decisions += 1

        # Oszczędność vs pełny rój (enterprise = 5900 MB)
        full_ram = self._configs.get("enterprise", SwarmConfig("e", [], 5900, 15000)).ram_estimate_mb
        self._ram_saved_mb += full_ram - config.ram_estimate_mb

        logger.info(
            "[SWARM] 🐝 Swarm: %s | agents=%d | ram=%.0fMB | reason=%s",
            config.name, len(config.agents), config.ram_estimate_mb, reason,
        )
        return config

    # ── Stats ────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        total = self._total_decisions
        full_ram = self._configs.get("enterprise", SwarmConfig("e", [], 5900, 15000)).ram_estimate_mb

        return {
            "total_decisions": total,
            "swarm_distribution": dict(self._swarm_stats),
            "minimal_pct": round(self._swarm_stats.get("minimal", 0) / max(total, 1) * 100, 1),
            "light_pct": round(self._swarm_stats.get("light", 0) / max(total, 1) * 100, 1),
            "standard_pct": round(self._swarm_stats.get("standard", 0) / max(total, 1) * 100, 1),
            "ram_saved_total_mb": round(self._ram_saved_mb, 0),
            "ram_saved_avg_per_decision_mb": round(self._ram_saved_mb / max(total, 1), 1),
            "ram_efficiency_pct": round(
                (1 - (self._ram_saved_mb / max(total * full_ram, 1))) * 100, 1
            ),
        }
