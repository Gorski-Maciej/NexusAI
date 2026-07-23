"""
regulatory_radar_service.py — F3.5 v7.0 Audit: Regulatory Radar Service Wrapper.

Raport v7.0 Pomysł #15: Regulatory Radar — automatyczny monitoring zmian
w prawie podatkowym i automatyczne generowanie PR do reguł OPA.

Enterprise v7.0:
  - Wrapper wokół tools/regulatory_radar.py
  - Background monitoring (co 24h)
  - Impact assessment na reguły OPA
  - Auto-PR generation z opisem zmian
  - Integracja z MCP Server (get_regulatory_changes)
  - Alerty o krytycznych zmianach (stawki, progi, limity)
"""
from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.regulatory_radar")


@dataclass
class RegulatoryAlert:
    """Alert o zmianie legislacyjnej."""
    alert_id: str
    title: str
    source: str
    date_published: str
    date_effective: str
    severity: str  # CRITICAL, HIGH, MEDIUM, LOW
    affected_rules: list[str] = field(default_factory=list)
    numeric_changes: list[dict[str, Any]] = field(default_factory=list)
    action_required: str = "REVIEW_RULES"
    auto_pr_generated: bool = False


class RegulatoryRadarService:
    """Serwis monitoringu zmian legislacyjnych — wrapper wokół RegulatoryRadar.

    Enterprise v7.0 Pomysł #15:
    Automatycznie sprawdza Dz.U., MF i RCL pod kątem zmian w prawie podatkowym.
    Porównuje z istniejącymi regułami OPA i generuje PR z aktualizacją.
    """

    # Krytyczne słowa kluczowe do natychmiastowego alertu
    CRITICAL_KEYWORDS: list[str] = [
        "stawka vat", "stawka pit", "kwota wolna", "próg podatkowy",
        "limit", "składka zdrowotna", "zryczałtowany", "podatek liniowy",
        "ulga", "zwolnienie", "odliczenie", "amortyzacja",
    ]

    def __init__(
        self,
        policies_dir: str = "policies",
        rego_dir: str = "policies",
        check_interval_hours: int = 24,
    ) -> None:
        self._policies_dir = Path(policies_dir)
        self._rego_dir = Path(rego_dir)
        self._check_interval = check_interval_hours
        self._alerts: list[RegulatoryAlert] = []
        self._last_check: str = ""
        self._monitoring: bool = False
        self._monitor_task: asyncio.Task | None = None

    async def start_monitoring(self) -> None:
        """Rozpocznij background monitoring zmian legislacyjnych."""
        self._monitoring = True
        self._monitor_task = asyncio.create_task(self._monitor_loop())
        logger.info("[REG-RADAR] Monitoring started | interval=%dh", self._check_interval)

    async def stop_monitoring(self) -> None:
        """Zatrzymaj monitoring."""
        self._monitoring = False
        if self._monitor_task:
            self._monitor_task.cancel()
        logger.info("[REG-RADAR] Monitoring stopped")

    async def _monitor_loop(self) -> None:
        """Główna pętla monitoringu."""
        while self._monitoring:
            try:
                await self.check_now()
            except Exception as exc:
                logger.warning("[REG-RADAR] Check failed: %s", exc)
            await asyncio.sleep(self._check_interval * 3600)

    async def check_now(self) -> list[RegulatoryAlert]:
        """Sprawdź zmiany legislacyjne natychmiast.

        Returns:
            Lista alertów o zmianach wymagających aktualizacji reguł OPA.
        """
        self._last_check = datetime.now().isoformat()

        try:
            from tools.regulatory_radar import RegulatoryRadar
            radar = RegulatoryRadar(
                plan_dir=str(self._policies_dir),
                rego_dir=str(self._rego_dir),
            )
            impacts = radar.check_now()
        except ImportError:
            logger.warning("[REG-RADAR] tools.regulatory_radar not available — using fallback")
            impacts = self._fallback_check()

        alerts: list[RegulatoryAlert] = []
        for impact in impacts:
            alert = RegulatoryAlert(
                alert_id=f"reg-{impact.change.date_published}-{hash(impact.change.title) & 0xFFFF:04x}",
                title=impact.change.title,
                source=impact.change.source,
                date_published=impact.change.date_published,
                date_effective=impact.change.date_effective,
                severity=impact.severity,
                affected_rules=impact.affected_rules,
                numeric_changes=impact.change.numeric_changes,
                action_required=impact.action_required,
                auto_pr_generated=False,
            )
            alerts.append(alert)

            # Generuj auto-PR dla zmian HIGH/CRITICAL
            if alert.severity in ("HIGH", "CRITICAL"):
                try:
                    pr_path = self._rego_dir / "data" / f"auto_pr_{alert.date_published}.md"
                    pr_content = impact.to_pr_description()
                    pr_path.parent.mkdir(parents=True, exist_ok=True)
                    pr_path.write_text(pr_content)
                    alert.auto_pr_generated = True
                    logger.info(
                        "[REG-RADAR] Auto-PR generated | severity=%s | rules=%d | path=%s",
                        alert.severity, len(impact.affected_rules), pr_path,
                    )
                except Exception as exc:
                    logger.warning("[REG-RADAR] Auto-PR generation failed: %s", exc)

        self._alerts = alerts
        logger.info(
            "[REG-RADAR] Check complete | alerts=%d | critical=%d",
            len(alerts),
            sum(1 for a in alerts if a.severity == "CRITICAL"),
        )
        return alerts

    def _fallback_check(self) -> list[Any]:
        """Fallback: symulowane sprawdzenie gdy RegulatoryRadar niedostępny."""
        from unittest.mock import MagicMock

        mock_impact = MagicMock()
        mock_impact.change.title = "Fallback — RegulatoryRadar offline"
        mock_impact.change.source = "NexusAI Fallback"
        mock_impact.change.date_published = datetime.now().strftime("%Y-%m-%d")
        mock_impact.change.date_effective = (datetime.now() + timedelta(days=14)).strftime("%Y-%m-%d")
        mock_impact.change.numeric_changes = []
        mock_impact.severity = "LOW"
        mock_impact.affected_rules = []
        mock_impact.action_required = "NO_ACTION"
        mock_impact.to_pr_description = lambda: "# Fallback — no real changes detected"
        return [mock_impact]

    def get_recent_alerts(self, limit: int = 10) -> list[dict[str, Any]]:
        """Pobierz ostatnie alerty."""
        return [
            {
                "alert_id": a.alert_id,
                "title": a.title,
                "severity": a.severity,
                "date_published": a.date_published,
                "date_effective": a.date_effective,
                "affected_rules_count": len(a.affected_rules),
                "action_required": a.action_required,
                "auto_pr_generated": a.auto_pr_generated,
            }
            for a in self._alerts[-limit:]
        ]

    def get_critical_alerts(self) -> list[dict[str, Any]]:
        """Pobierz tylko krytyczne alerty."""
        return [
            alert for alert in self.get_recent_alerts()
            if alert["severity"] in ("CRITICAL", "HIGH")
        ]

    def get_impact_summary(self) -> dict[str, Any]:
        """Podsumowanie wpływu zmian na reguły OPA."""
        all_rules: set[str] = set()
        for alert in self._alerts:
            all_rules.update(alert.affected_rules)

        return {
            "last_check": self._last_check,
            "total_alerts": len(self._alerts),
            "critical_count": sum(1 for a in self._alerts if a.severity == "CRITICAL"),
            "high_count": sum(1 for a in self._alerts if a.severity == "HIGH"),
            "affected_rules_count": len(all_rules),
            "affected_rules": sorted(all_rules),
            "monitoring_active": self._monitoring,
            "check_interval_hours": self._check_interval,
        }

    def _check_critical_keywords(self, description: str) -> bool:
        """Sprawdź czy opis zawiera krytyczne słowa kluczowe."""
        desc_lower = description.lower()
        return any(keyword in desc_lower for keyword in self.CRITICAL_KEYWORDS)
